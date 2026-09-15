# Islesrisk — Roadmap

Self-contained iterations toward the playable hot-seat POC described in
[ARCHITECTURE.md](ARCHITECTURE.md). Each iteration should leave the repo
in a working, demo-able state so work can resume cleanly from any point.
Check items off as they land; update "Status" as iterations complete.

## Status

- **Done**: nothing is built. This repository currently holds
  specifications and decisions only — [ARCHITECTURE.md](ARCHITECTURE.md),
  [RULES.md](RULES.md), [DECISIONS.md](DECISIONS.md) and this file. No
  `package.json`, no code, no build. Deliberate: the product owner asked
  for the specs to be reviewable before any scaffolding lands.
- **Next up**: Iteration 0, on the product owner's go-ahead.
- **Open before Iteration 8**: a final name (see DECISIONS.md, "Name,
  art and IP posture"). "Islesrisk" is provisional.

## Ordering principle

The AI is the project's real risk ([DECISIONS.md](DECISIONS.md)), so the
plan front-loads everything needed to attempt it and defers everything
that would be expensive to throw away. Rules engine and a clickable
board come first; map art, hazards, cards and polish come after the
opponent has proved workable. Iteration 4 is a genuine go/no-go.

## Iteration 0 — Repo & tooling scaffolding

Copy Geoclick's setup rather than re-deriving it.

- [ ] Root `package.json`: npm workspaces (`app`, `packages/*`), scripts
      delegating with `--workspaces --if-present`, `.nvmrc` pinned to the
      Node major Geoclick uses
- [ ] `app/` — SvelteKit + TypeScript + `adapter-static`, Vite
- [ ] `packages/rules`, `packages/ai` — empty pure-TS packages, `types`
      pointing at `src/index.ts`, Vitest wired
- [ ] ESLint + Prettier, shared config, same shape as Geoclick's
- [ ] `npm run gates` (`check`, `test`, `lint`, `build`) and a committed
      `.githooks/pre-push` that runs them; `npm run setup-hooks`
- [ ] `netlify.toml` at the repo root, build from `app/`
- [ ] `.gitignore`, `.gitattributes`
- **Done when**: `npm install && npm run gates` passes from a clean
  clone, and `npm run dev` serves a page.

## Iteration 1 — Map format and the starter board

- [ ] `GameMap` / `Isle` / `Archipelago` types in `packages/rules`
- [ ] `small-sea`: 14 isles, 4 archipelagos, per [RULES.md](RULES.md) —
      SVG paths, label points, authored sea lanes
- [ ] Validator: adjacency symmetric, graph connected, every isle in
      exactly one archipelago, no duplicate ids. Runs in the test gate,
      because a broken map should fail CI, not the game
- [ ] A static Svelte board component: renders the map, no interaction
- **Done when**: the board renders in the browser, portrait, legible on
  a phone viewport, and a deliberately broken map fails the gates.

## Iteration 2 — Rules engine, headless

The core of the project. No UI work in this iteration at all.

- [ ] `GameState`, `Action`, seeded RNG carried in state
- [ ] Setup: deal, starting armies, distribution, centre placement
- [ ] Reinforce: count, archipelago bonus, centre bonus, floor of 3
- [ ] Attack: adjacency, **the match rule**, dice, ties to defender,
      capture, **the failure penalty**
- [ ] Redeploy; turn/phase advance; elimination; victory
- [ ] The full test checklist at the end of [RULES.md](RULES.md), plus
      the determinism property test (same seed + actions ⇒ same state)
- **Done when**: a scripted game plays start to finish in Vitest, and
  every listed rule has a failing-case test.

## Iteration 3 — Hot-seat, playable

- [ ] Click an isle to select, click an adjacent enemy isle to attack;
      illegal targets are not offered, and the reason is visible
- [ ] Phase bar, reinforcement placement, redeploy, end turn
- [ ] Result screen with the seed
- [ ] Local persistence: resume an in-progress game, behind the
      repository interface from ARCHITECTURE.md
- **Done when**: two humans can play a complete game on one device, on a
  phone, without the console open.

## Iteration 4 — The opponent (go/no-go)

Timeboxed. See [DECISIONS.md](DECISIONS.md), "The AI is the project's
real risk".

- [ ] `AiPolicy` interface; `packages/ai` depends only on `packages/rules`
- [ ] A baseline policy good enough to be irritating: value isles by
      archipelago progress, centres and border pressure; respect the
      match rule when picking where to stack
- [ ] Three difficulty levels; any cheating declared in the open
- [ ] Headless tournament harness — policies played against each other
      over N seeds, win rates reported. The only honest way to tell
      whether a change made the AI better
- [ ] Verified by the product owner actually playing it
- **Go/no-go**: if the opponent isn't tolerable within the timebox, stop
  and reassess the project rather than extending. Recorded either way.

## Iteration 5 — Hazards and production centres

- [ ] Floods, earthquakes, revolts, at the frequencies in RULES.md
- [ ] Centres: placement, +2 reinforcement, 25% wander
- [ ] Hazards shown as they happen — a rubber band the player can't
      perceive reads as the game being arbitrary
- [ ] AI updated to value centres
- **Done when**: hazards fire at roughly the intended rate over a
  scripted 100-game run, and never take an isle to 0 or change an owner.

## Iteration 6 — Cards

- [ ] Bombard, Shield, Airlift; deck, draw-on-capture, hand cap, reshuffle
- [ ] Hand UI; one card per turn
- [ ] AI plays cards, or declares that it doesn't yet
- **Done when**: each card has a test proving it can't be used to break
  an invariant (Bombard can't capture, Airlift can't strand an isle).

## Iteration 7 — Tuning

The iteration that decides whether the game is any good.

- [ ] Measure real game length; tune toward the five-minute target using
      the levers in RULES.md, **in their stated order**
- [ ] The surrender offer
- [ ] Touch pass: 44px targets, no hover-dependent affordances
- [ ] Record what changed and why in DECISIONS.md
- **Done when**: ten consecutive games land under five minutes and the
  product owner wants to play another one.

## Iteration 8 — Public deploy

- [ ] Final name decided, applied, DECISIONS.md amended
- [ ] Netlify deploy from `main`; verify locally *and* on the live site
      as two separately labelled steps
- [ ] README with a play link; `CHANGELOG.md`; `v0.1.0` tagged
- [ ] Optional: the courtesy email to Soleau

## Post-POC — not scoped

Online multiplayer (the big one — see DECISIONS.md on why it's last),
more maps, a map editor, Tauri desktop and Capacitor Android shells,
sound and animation. None of it before Iteration 7 says the game is
worth installing.
