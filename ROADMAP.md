# Islesrisk — Roadmap

Self-contained iterations toward the playable hot-seat POC described in
[ARCHITECTURE.md](ARCHITECTURE.md). Each iteration should leave the repo
in a working, demo-able state so work can resume cleanly from any point.
Check items off as they land; update "Status" as iterations complete.

## Status

- **Done**: nothing is built. This repository holds specifications and
  decisions only — [ARCHITECTURE.md](ARCHITECTURE.md),
  [RULES.md](RULES.md), [SCENARIOS.md](SCENARIOS.md),
  [DECISIONS.md](DECISIONS.md) and this file. No `package.json`, no
  code, no build. Deliberate: the product owner asked for the specs to
  be reviewable before any scaffolding lands.
- **Next up**: Iteration 0, on the product owner's go-ahead.
- **Reordered (2026-09-15)**: hazards and production centres were
  Iteration 5, after the AI. A scan of what's shipping on mobile
  (DECISIONS.md, "Mobile competitors") found them to be the project's
  only real differentiator, so they moved into the engine iteration.
- **Rescoped (2026-09-15)**: the engine is now data-driven — variable
  map sizes, generated maps, configurable rules, 2-8 players, seven
  victory conditions, saved and shared scenarios (DECISIONS.md, "Generic
  engine, Classic preset"). Two new iterations (5, 6) and one new
  package (`mapgen`). The scenario **editor** is deliberately post-POC;
  the scenario **format** is Iteration 6.
- **Open before the public deploy**: a final name (DECISIONS.md, "Name,
  art and IP posture"). "Islesrisk" is provisional.

## Ordering principle

Three risks, and the plan front-loads all of them.

**The AI is the delivery risk**: a single-player conquest game is its
opponent, and if that can't be made tolerable the project is over.
**The hazards and roaming centres are the product risk**: they are the
only part of this not already free on a phone, so if they aren't fun, a
good AI just means a competent game nobody needs. **Genericity is the
architecture risk**: it is nearly free designed in and a rewrite
retrofitted, so the rule set is a data object from the first line of the
engine — but it is deliberately *invisible* until Iteration 5, because
generality that nobody has played yet is speculation.

So: engine general from the start, presets as the only surface, one
authored board and one preset carrying the project until the AI gate is
passed. Everything expensive to throw away — map art, cards, the editor,
polish — waits behind all three. Iteration 4 is a genuine go/no-go.

## Iteration 0 — Repo & tooling scaffolding

Copy Geoclick's setup rather than re-deriving it.

- [ ] Root `package.json`: npm workspaces (`app`, `packages/*`), scripts
      delegating with `--workspaces --if-present`, `.nvmrc` pinned to the
      Node major Geoclick uses
- [ ] `app/` — SvelteKit + TypeScript + `adapter-static`, Vite
- [ ] `packages/rules`, `packages/mapgen`, `packages/ai` — empty pure-TS
      packages, `types` at `src/index.ts`, Vitest wired
- [ ] ESLint + Prettier, shared config, same shape as Geoclick's
- [ ] `npm run gates` (`check`, `test`, `lint`, `build`) and a committed
      `.githooks/pre-push` that runs them; `npm run setup-hooks`
- [ ] `netlify.toml` at the repo root, build from `app/`
- [ ] `.gitignore`, `.gitattributes`
- **Done when**: `npm install && npm run gates` passes from a clean
  clone, and `npm run dev` serves a page.

## Iteration 1 — Map format, validator, the Classic board

- [ ] `GameMap` / `Isle` / `Archipelago` types in `packages/rules`
- [ ] The validator from [SCENARIOS.md](SCENARIOS.md) — symmetric lanes,
      connected graph, archipelago membership, geometry sanity. Runs in
      the test gate, because a broken map should fail CI, not the game
- [ ] `small-sea`: 14 isles, 4 archipelagos, per RULES.md — SVG paths,
      label points, authored sea lanes
- [ ] A static Svelte board component: renders a map at any size, no
      interaction
- **Done when**: the board renders in the browser, portrait, legible on
  a phone viewport, and a deliberately broken map fails the gates.

## Iteration 2 — Rules engine, headless

The core of the project: data-driven from the start, hazards and centres
included, Classic as the default `RuleSet`. No UI work at all.

- [ ] `RuleSet` type and the Classic preset — every table in RULES.md
- [ ] `GameState` (rules resolved inline), `Action`, seeded RNG in state
- [ ] Setup, reinforce, attack, redeploy — each reading its constants
      from the rule set, never from a literal
- [ ] Hazards: floods, earthquakes, revolts. Production centres:
      placement, bonus, wander
- [ ] `conquest` victory; the `VictoryCondition` evaluation hook that
      the rest plug into in Iteration 6
- [ ] The Classic test checklist from RULES.md, plus the
      cross-configuration tests: `attackRule: 'classic'`, every
      subsystem disabled, the hazard invariants
- [ ] The determinism property test over (seed, rules, map, actions)
- [ ] A scripted 100-game harness reporting hazard rates and game length
- **Done when**: a scripted game plays start to finish in Vitest, every
  listed rule has a failing-case test, a rules-toggled variant plays
  without special-casing, and the harness numbers are in DECISIONS.md.

## Iteration 3 — Hot-seat, playable

- [ ] Click an isle to select, click an adjacent enemy isle to attack;
      illegal targets are not offered, and the reason is visible
- [ ] Phase bar, reinforcement placement, redeploy, end turn; a phase
      the configuration empties is skipped, not shown empty
- [ ] Hazards and centre moves shown as they happen — a rubber band the
      player can't perceive reads as the game being arbitrary, and a
      centre that teleports silently is a bug report waiting to happen
- [ ] Start screen: preset and opponent count only. No toggles
- [ ] Result screen with the seed; local persistence and resume
- **Done when**: two humans can play a complete game on one device, on a
  phone, without the console open — **and the product owner can say
  whether chasing the centres is fun.** That verdict is the point of
  this iteration; the rest is plumbing.

## Iteration 4 — The opponent (go/no-go)

Timeboxed, and judged on **Classic only** — see DECISIONS.md.

- [ ] `AiPolicy` interface, taking the rule set and the active victory
      conditions as inputs; `packages/ai` depends only on `packages/rules`
- [ ] A baseline policy good enough to be irritating: value isles by
      archipelago progress, current and likely-future centre positions,
      and border pressure; respect the match rule when picking where to
      stack
- [ ] Three difficulty levels; any cheating declared in the open
- [ ] Headless tournament harness — policies played against each other
      over N seeds, win rates reported. The only honest way to tell
      whether a change made the AI better
- [ ] Verified by the product owner actually playing it
- **Go/no-go**: if the opponent isn't tolerable on Classic within the
  timebox, stop and reassess rather than extending. Recorded either way.

## Iteration 5 — Map generation

The first iteration where the engine's generality becomes visible.

- [ ] `packages/mapgen`: points → Voronoi cells → lanes → archipelagos →
      centres, per SCENARIOS.md, all seeded
- [ ] `MapGenParams`: size, archipelago count, layout, lane density,
      symmetry. Output passes the Iteration 1 validator, including the
      fairness checks
- [ ] Property test: 1000 seeds across the parameter space, every map
      valid, no retry loops
- [ ] Start screen gains a size slider and a re-roll
- [ ] **Re-validate the AI across generated boards** — a policy tuned on
      one hand-made map is overfitted, and the tournament harness now
      has varied boards to say so. A pass at Iteration 4 is provisional
      until this runs
- **Done when**: a fresh board every game at any size in the supported
  range, all valid, and the AI's win rates across generated boards are
  recorded.

## Iteration 6 — Victory conditions and scenarios

- [ ] The remaining six conditions from SCENARIOS.md, plus per-player
      objectives and the "no way to end" validator rule
- [ ] `Scenario` JSON: schema version, `extends` resolution, full
      validation of untrusted input
- [ ] The built-in presets — Classic, Blitz, Open Sea, Archipelago,
      Still Waters, Last Stand
- [ ] Share by URL fragment, with the size fallback and a clear failure
      when a fragment doesn't validate
- [ ] AI reads the active victory conditions — at minimum, it plays
      `survival` differently from `conquest`
- **Done when**: every preset plays 100 headless games to a legal
  terminal state, and a scenario link opens the same game on another
  device.

## Iteration 7 — Cards

- [ ] Bombard, Shield, Airlift; deck, draw-on-capture, hand cap, reshuffle
- [ ] Hand UI; one card per turn
- [ ] AI plays cards, or declares that it doesn't yet
- **Done when**: each card has a test proving it can't be used to break
  an invariant (Bombard can't capture, Airlift can't strand an isle).

## Iteration 8 — Tuning

The iteration that decides whether the game is any good.

- [ ] Measure real game length on Classic; tune toward five minutes with
      the levers in RULES.md, **in their stated order**
- [ ] Tune hazard rates and centre movement against real games rather
      than the guesses in RULES.md — and protect the centres first if
      something has to give
- [ ] Play Still Waters against Classic. If hazards and centres don't
      win that comparison, the central claim in DECISIONS.md is wrong
      and we should want to know here, not after launch
- [ ] The surrender offer; touch pass (44px targets, no hover-only
      affordances)
- [ ] Record what changed and why in DECISIONS.md
- **Done when**: ten consecutive Classic games land under five minutes
  and the product owner wants to play another one.

## Iteration 9 — Public deploy

- [ ] Final name decided, applied, DECISIONS.md amended
- [ ] Netlify deploy from `main`; verify locally *and* on the live site
      as two separately labelled steps
- [ ] README with a play link; `CHANGELOG.md`; `v0.1.0` tagged
- [ ] Optional: the courtesy email to Soleau

## Post-POC — not scoped

**The scenario editor** — visual map editing, hand-placed starting
armies, an objectives builder, save and share. Deliberately here rather
than in the POC (DECISIONS.md): it is a large, self-contained pile of UI
that nothing else depends on, and the JSON format plus built-in
scenarios already make scenarios *possible* by Iteration 6. Promote it
if the product owner wants authoring in the POC — it does not block
anything, and nothing blocks it.

Also: online multiplayer (see DECISIONS.md on why it's last), more
presets and authored maps, fog of war, Tauri desktop and Capacitor
Android shells, sound and animation. None of it before Iteration 8 says
the game is worth installing.
