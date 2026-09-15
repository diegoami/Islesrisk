# Islesrisk — Architecture

Islesrisk is a turn-based conquest **engine** with a game on top of it.
The rules descend from Soleau Software's *Isle Wars* (1994) — see
[RULES.md](RULES.md) for the specification and [DECISIONS.md](DECISIONS.md)
for why it is a re-take rather than a port. Portfolio project, not
commercial. First milestone is a playable hot-seat game in a browser.

"Engine" is meant literally and it is the central architectural
commitment: the board is generated or authored at any size, the rules
are a data object, the number and kind of players is configuration, and
victory is a list of predicates. What a player sees is a **preset** —
Classic, Blitz, Archipelago — which is nothing but a named rule set with
a map source attached. Scenario structure, map generation and the
victory catalogue are in [SCENARIOS.md](SCENARIOS.md).

The reasoning for paying that cost up front is in DECISIONS.md
("Generic engine, Classic preset"): genericity in the *data model* is
nearly free if it is designed in at the start and very expensive to
retrofit, while genericity in the *UI* is the reverse — so the engine is
fully general from Iteration 2 and the scenario editor is the last thing
built, if it is built at all.

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
zoom. Islesrisk draws fictional shapes — a dozen on a Classic board, up
to around sixty on the largest generated ones — at one zoom per screen.
That is an inline **SVG**: `<path>` per isle, CSS fill for ownership, a
`<text>` for the army count, pointer events for free. A tile renderer
here would be megabytes of dependency to solve a problem the platform
already solves.

Sixty interactive paths is comfortable for SVG; several hundred would
not be, and that — not the rules — is what actually caps map size. If a
preset ever wants a thousand isles, the renderer is what gets replaced,
behind the same `GameMap`, and nothing else moves.

Consequence worth stating: the map is a *game board*, not a map. Isles
have no coordinates in any real projection; adjacency is authored data
(a sea-lane graph), never derived from geometry.

## Domain model

**Isle** — one territory. Holds armies, has an owner, belongs to an
archipelago, and connects to other isles by explicit sea lanes. Whether
a map was drawn by hand or produced by the generator, it is this same
structure and passes the same validator.

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
  rules      RuleSet                 // resolved and inline, never a reference
  players    Player[]                // colour, kind: 'human' | 'ai', objectives
  owner      Record<IsleId, PlayerId>
  armies     Record<IsleId, number>
  turn       { player: PlayerId, phase: Phase, number, ... }
  hands      Record<PlayerId, Card[]>
  centres    IsleId[]                // production centres, they move
  rng        RngState                // seeded, part of the state
  log        Event[]
}
```

`rules` sits **inside** the state, resolved from any `extends` chain and
stored in full. A game therefore carries its own rules: tuning Classic
next month cannot retroactively change a save file, and a bug report
arrives with the exact configuration that produced it. The cost is a few
hundred bytes per save, which is the cheapest thing in this document.

**Scenario** — the serializable set-up that *produces* a `GameState`:
map source, rule set, players, optional hand-placed starting position,
victory conditions. It is the unit that gets saved, shared by URL and
replayed. Fully specified in [SCENARIOS.md](SCENARIOS.md).

Phases per turn: `reinforce → attack → redeploy → hazards`. Hazards
(floods, quakes, revolts, centre movement) resolve at the *end* of a
turn, so a player always sees the board they are about to act on. A
phase the configuration empties is skipped rather than shown empty.
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

**No rule may be a compiled-in assumption**, in any package. Every rule
is a field of `state.rules`, and code that assumes the match rule is on,
that hazards exist, or that victory means conquest is a bug — the AI's
code most of all, since it is the easiest place for such an assumption
to hide and the hardest place to notice it. The cross-configuration
tests at the end of RULES.md exist to catch exactly this.

`packages/ai` depends on `packages/rules` and nothing else — it consumes
the same public API a player does, reads the same `RuleSet`, and cannot
reach into state the rules don't expose. `packages/mapgen` likewise
produces `GameMap`s and knows nothing about play. `app/` owns rendering,
input and persistence and holds no rule logic: if a check can be written
in the engine it belongs there, with the UI merely declining to offer
illegal actions.

## Repo layout (planned — nothing exists yet)

```
/app                    SvelteKit web app: board, turn UI, game shell
/packages/rules         pure TS: RuleSet, state, actions, combat, hazards,
                        victory conditions, the map validator
/packages/mapgen        pure TS: seeded map generation → GameMap
/packages/ai            pure TS: opponent policies, built on /rules
/data                   authored maps, presets, built-in scenarios
```

`mapgen` depends on `rules` only for the `GameMap` type and the
validator, never the other way round: the engine must not know that
procedural generation exists.

Matching Geoclick's `app` + `packages/*` npm workspaces, root scripts
delegating with `--workspaces --if-present`, and the same four gates
(`check`, `test`, `lint`, `build`) behind a committed `.githooks/pre-push`.

## Screens

Small on purpose — this is a game, not an app.

| Route | View |
|---|---|
| `/` | Start: preset, board size, opponents, difficulty; resume a game |
| `/play` | The board. One screen, phase bar, end-turn button |
| `/play/result` | Outcome, a replayable seed and link, back to start |

The board is the product; everything else is a door into it. The start
screen's job is to keep the engine's generality *out* of the player's
way: a preset, a size, a number of opponents — not a wall of toggles.
Everything else a `RuleSet` can express is reachable by loading a
scenario, and later by an editor, but is never the first thing a new
player meets. A `#s=…` URL fragment opens a shared scenario directly,
validated before anything is rendered (SCENARIOS.md, "Sharing").

## Storage

Local-first, no accounts, no backend — same posture as Geoclick, for the
same reason (nothing here needs a server, and a server is a thing to
run, pay for and secure). One in-progress `GameState`, a short results
history and any scenarios the player has saved or opened from a link,
all in `localStorage`, behind a small repository interface so a
Tauri/Capacitor SQLite backend can replace it later without the app
noticing.

Because the state carries its resolved rule set and its seed, a save is
also a replay and a bug report — one small JSON object that reproduces
the game exactly.

## Hosting

Netlify, static build from `main`, config at the repo root so
`npm install` resolves the workspace. Directly copied from Geoclick's
`netlify.toml`, including the reasoning recorded there.
