# Islesrisk — Architecture

Islesrisk is a turn-based conquest game: a small archipelago map, four
players, one sitting. The ruleset descends from Soleau Software's *Isle
Wars* (1994) — see [RULES.md](RULES.md) for the specification and
[DECISIONS.md](DECISIONS.md) for why it is a re-take rather than a port.
Portfolio project, not commercial. First milestone is a playable
hot-seat game in a browser.

## Strategy: one web core, one shell for now

Same shape as Geoclick — a single web app as the source of truth,
packageable later — but deliberately **web only** at this stage. Tauri
(desktop) and Capacitor (mobile) slot into an npm-workspace monorepo
without disturbing what's already there, so scaffolding them before
there is a game to install buys nothing. The pitch is "a phone browser,
five minutes, no install"; the browser build *is* the product.

**Framework: SvelteKit + TypeScript**, `adapter-static`, deployed to
Netlify. Not a judgement call so much as an inheritance: it's the stack
the developer already runs, already has gates for, and already knows the
failure modes of.

## What is *not* inherited from Geoclick

**No MapLibre GL JS, no PMTiles, no Natural Earth.** Geoclick needs a
real vector-tile renderer because it teaches real geography at arbitrary
zoom. Islesrisk has one hand-authored fictional map of ~14 shapes that
must be legible at a single fixed zoom on a phone. That is an inline
**SVG** — `<path>` per isle, CSS fill for ownership, a `<text>` for the
army count, pointer events for free. A tile renderer here would be
several megabytes of dependency to solve a problem the platform already
solves.

Consequence worth stating: the map is a *game board*, not a map. Isles
have no coordinates in any real projection; adjacency is authored data
(a sea-lane graph), never derived from geometry.

## Domain model

**Isle** — one territory. Holds armies, has an owner, belongs to an
archipelago, and connects to other isles by explicit sea lanes.

```
Isle {
  id            IsleId              // stable string key
  name          string
  archipelago   ArchipelagoId
  neighbours    IsleId[]            // authored, symmetric, never derived
  path          string              // SVG path data, board coordinates
  labelAt       { x, y }            // where the army count is drawn
}

Archipelago {
  id      ArchipelagoId
  name    string
  isles   IsleId[]
  bonus   number                    // reinforcements for holding all of it
}

GameMap {
  id, name
  isles         Isle[]
  archipelagos  Archipelago[]
  viewBox       string              // the SVG board extent
}
```

**GameState** — everything needed to render a game and to continue it.
Ownership and army counts are keyed by isle rather than nested in it, so
the map stays immutable data that several games can share.

```
GameState {
  map        GameMap
  players    Player[]               // colour, kind: 'human' | 'ai'
  owner      Record<IsleId, PlayerId>
  armies     Record<IsleId, number>
  turn       { player: PlayerId, phase: Phase, ... }
  hands      Record<PlayerId, Card[]>
  centres    IsleId[]               // production centres, they move
  rng        RngState               // seeded, part of the state
  log        Event[]
}
```

Phases per turn: `reinforce → attack → redeploy → hazards`. Hazards
(floods, quakes, revolts, centre movement) resolve at the *end* of a
turn, so a player always sees the board they are about to act on.
[RULES.md](RULES.md) is the authority on each.

## The engine is pure, and the game is a fold

`packages/rules` is framework-agnostic TypeScript with one entry point:

```
applyAction(state: GameState, action: Action): GameState
```

Total, deterministic, no I/O, no `Math.random`, no `Date.now`. Every
source of chance — dice, hazard rolls, card draws, initial placement —
draws from the seeded `rng` carried *inside* the state. Three things
fall out of that, and they are the reason for the constraint:

- **A game is its seed plus its action list.** Save files, bug reports
  and replays are the same small object. "It let me attack with 3 into
  4" arrives as something reproducible.
- **The AI can search.** An opponent that wants to evaluate a move plays
  it against a copy of the state. With hidden I/O or ambient randomness
  it cannot.
- **Tests are cheap.** The whole ruleset is exercised without a DOM, in
  Vitest, in milliseconds.

`packages/ai` depends on `packages/rules` and nothing else — it consumes
the same public API a player does, and cannot reach into state the rules
don't expose. `app/` owns rendering, input and persistence, and holds no
rule logic: if a check can be written in the engine, it belongs there,
with the UI merely declining to offer illegal actions.

## Repo layout (planned — nothing exists yet)

```
/app                    SvelteKit web app: board, turn UI, game shell
/packages/rules         pure TS: state, actions, combat, hazards, victory
/packages/ai            pure TS: opponent policies, built on /rules
/data                   map definitions + authoring scripts
```

Matching Geoclick's `app` + `packages/*` npm workspaces, root scripts
delegating with `--workspaces --if-present`, and the same four gates
(`check`, `test`, `lint`, `build`) behind a committed `.githooks/pre-push`.

## Screens

Small on purpose — this is a game, not an app.

| Route | View |
|---|---|
| `/` | Start: pick map, opponents, difficulty; resume a game in progress |
| `/play` | The board. One screen, phase bar, end-turn button |
| `/play/result` | Outcome, a replayable seed, back to start |

The board is the product; everything else is a door into it.

## Storage

Local-first, no accounts, no backend — same posture as Geoclick, for the
same reason (nothing here needs a server, and a server is a thing to
run, pay for and secure). One in-progress `GameState` plus a short
results history in `localStorage`, behind a small repository interface
so a Tauri/Capacitor SQLite backend can replace it later without the app
noticing.

## Hosting

Netlify, static build from `main`, config at the repo root so
`npm install` resolves the workspace. Directly copied from Geoclick's
`netlify.toml`, including the reasoning recorded there.
