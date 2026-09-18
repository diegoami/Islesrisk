# Malpaco — Roadmap

Self-contained iterations toward a beautiful desktop conquest game built
on the engine described in [ARCHITECTURE.md](ARCHITECTURE.md). Each
iteration should leave the repo in a working, demo-able state so work
can resume cleanly from any point. Check items off as they land; update
"Status" as iterations complete.

## Status

- **Done**: Iterations 0-3 — the Godot project and five quality gates,
  the map and validator, the rules engine, and a playable hot-seat game
  with save and resume. 88 tests green, including 100 full games a run.
- **Played, 2026-09-18**: the product owner played a hot-seat game and
  reported that attacking is never worth it and the board was heading
  for a stalemate. Both confirmed by measurement, and Classic's economy
  was retuned in response, ahead of Iteration 10 — see DECISIONS.md,
  "The floor was the stalemate". Four-player games went from 59.8 rounds
  to 18.7 against a 10-15 target. **The verdict on whether chasing the
  centres is fun is still owed** — it was not what the session answered.
- **Open and unscheduled**: about one Classic game in six ends with no
  winner, at every economy setting tried. Structural, not tuning. Needs
  a turn limit and a drawn state (RULES.md, "Games that do not end");
  picked up as the first item of Iteration 4 because the tournament has
  no way to report the outcome otherwise.
- **Next up**: Iteration 4 — the opponent, and the project's go/no-go.
- **Note on the specs-first start**: the repository held nothing but
  documents for its first four commits, and two pivots arrived in that
  window — web to Godot, and fixed game to configurable engine. Neither
  threw away code.
- **Retargeted (2026-09-15)**: Godot 4 on the desktop, painterly 2D,
  Android later, no browser (DECISIONS.md, "Godot and the desktop",
  "Gorgeous, and what that costs"). The previous web stack is gone;
  RULES.md and SCENARIOS.md carried over nearly unchanged.
- **Decision point**: Iteration 5 produces the vertical slice, and the
  commercial question (portfolio vs Steam) is answered there.
- **Named (2026-09-17)**: **Malpaco** — Esperanto for "un-peace"
  (DECISIONS.md, "Name, art and IP posture"). The working title
  "Islesrisk" is retired; the repository is renamed to match.

## Ordering principle

Four risks, front-loaded in the order they can kill the project.

**The AI is the delivery risk** — a single-player conquest game is its
opponent. **The hazards and roaming centres are the product risk** — the
only part not already free elsewhere. **Genericity is the architecture
risk** — nearly free designed in, a rewrite retrofitted, so the rule set
is data from the first line and stays invisible until Iteration 6.
**The look is now a first-class risk too**: "gorgeous" is a stated goal,
and art left until last is art that never happens.

The resolution for the look is a **spike, not a polish phase**.
Iteration 5 proves the whole visual register on one board, immediately
after the AI gate and before the expensive generality. Together,
Iterations 0-5 are the vertical slice: a real game, a real opponent, and
a real look, on one board. That artifact answers the Steam question.
Everything costly — the full art system, cards, the editor — waits
behind it.

## Iteration 0 — Godot project & gates — **DONE (2026-09-17)**

Shipped as v0.0.1. Every item verified on Godot 4.7.2 before the push.

- [x] Godot 4.7.x project; `core/`, `game/`, `data/`, `test/`, `tools/`
- [x] Typed GDScript, enforced by `project.godot` warnings-as-errors
      rather than by review; `gdlint` and `gdformat --check` clean
- [x] gdUnit4 6.2.1 vendored at `addons/gdUnit4`, running headless with
      no virtual display needed. Exits 0 green, 100 red
- [x] **The purity guard** — `test/guard/test_core_purity.gd` scans
      `core/` for scene-tree and `Resource` inheritance, `get_tree`,
      signals, global RNG, `load`/`preload`, `FileAccess`, `Time.`,
      `OS.` and `Input.`, reporting file, line and reason. Verified by
      planting violations and watching it catch every one
- [x] `tools/gates.sh` (format, lint, test, export) on a committed
      `.githooks/pre-push`; the same four in GitHub Actions
- [x] Export presets for Linux and Windows; the Linux build was produced
      and run
- [x] `.gitignore`, `.gitattributes`, and the `ASSETS.md` ledger started
- **Done when**: a clean clone passes the gates and produces a desktop
  build that opens a window. **It does** — 7 tests green and a 73 MB
  Linux binary that starts, opens a window and exits cleanly.
- **Carried slightly ahead of scope**: `core/rules/deterministic_rng.gd`,
  the seeded generator every later system draws from. Scaffolding needs
  something real to guard and to test, and this is the piece the
  determinism guarantee rests on.

## Iteration 1 — Map data, validator, the Classic board — **DONE (2026-09-18)**

Shipped, then corrected the same week: the first board made every
territory its own island. The board is islands divided into provinces
(DECISIONS.md, "The board is islands with provinces"). What follows is
the corrected state.

- [x] `Province`, `Island`, `GameMap` in `core/rules`, plain `RefCounted`,
      with borders and sea lanes stored separately
- [x] `MapValidator` in `core/validate` — identity, membership, both kinds
      of crossing, geometry, island contiguity and whole-board
      connectivity, returning *every* problem rather than the first
- [x] `MapReader`: JSON text to a `GameMap`, pure, with untrusted-input
      hardening — schema check, unknown fields rejected rather than
      ignored, caps on provinces, polygon points and string lengths.
      Reading validates too, so a caller cannot forget to
- [x] `MapRepository` in `game/` does the file reading. `core/` may not
      touch `FileAccess` (the purity guard enforces it), which also puts
      I/O at the edge and leaves the parser testable with a string
- [x] `small-sea`: 4 islands, 14 provinces, 16 land borders and 5 sea
      lanes, matching RULES.md's table including the sea-entrance counts.
      Provinces are clipped-Voronoi cells that tile each island exactly
- [x] `BoardView` renders any map at any size: provinces filled and
      outlined, the coastline drawn from the edges no neighbour shares,
      sea lanes as the shortest hop between two shores
- [x] **A fifth gate, `smoke`** — runs the game and fails on any script
      error. Added because a refactor deleted a method still called from
      `_ready` and format, lint, test and export all stayed green while
      the game opened to a blank screen. Verified by breaking the game on
      purpose
- **Done when**: the board renders at any map size, and a deliberately
  broken map fails the gates. **Both hold** — 42 tests green, of which 19
  are validator rules each breaking exactly one thing.
- **Temporary**: land is tinted per island so the grouping can be checked
  by eye. Ownership colour replaces it in Iteration 3.

## Iteration 2 — Rules engine, headless — **DONE (2026-09-18)**

- [x] `RuleSet` and the Classic preset — every table in RULES.md, as data
- [x] `GameState` (rule set resolved inline), `Action`, seeded RNG in state
- [x] Setup, reinforce, attack, redeploy — every constant read from the
      rule set, integer arithmetic throughout
- [x] Hazards: floods, earthquakes, revolts. Centres: placement spread
      across the board, the bonus, the wander
- [x] `conquest` victory and the condition hook the rest plug into
- [x] The Classic checklist from RULES.md, the cross-configuration tests,
      and the determinism property test over (seed, rules, map, actions)
- [x] A headless 100-game harness reporting game length and hazard rates
- [x] GDScript vs C# revisited and settled (DECISIONS.md)
- **Done when**: a scripted game plays start to finish, every listed rule
  has a failing-case test, a rules-toggled variant plays without
  special-casing, and the harness numbers are in DECISIONS.md. **All
  hold** — 79 tests green.
- **What the numbers said**: Classic runs ~4x longer than its target and
  hazards fire ~5x less often than intended, and the lever list in
  RULES.md pointed the wrong way and is corrected. See DECISIONS.md,
  "What a hundred games say". Tuning stays Iteration 10's job.
- **Not built**: cards. The `RuleSet` carries their configuration so a
  preset can already switch them off, but no card is drawn or played
  until Iteration 9.

## Iteration 3 — Hot-seat, playable — **DONE (2026-09-18)**

- [x] Click a province to select, click a red-ringed neighbour to attack.
      Illegal targets are never offered, and when one is clicked anyway the
      engine's own reason is shown
- [x] Phase bar, reinforcement placement, redeploy, end turn, concede
- [x] Hazards and centre moves flash on the province they hit and are named
      in the event log — a rubber band nobody can perceive reads as the game
      being arbitrary
- [x] Start screen: preset and player count, nothing else
- [x] Result screen with the standings and the seed
- [x] Save and resume: the save is the seed, the rule set and the list of
      moves, and loading replays them
- **Done when**: two humans can play a complete game on one device —
  **they can** — and the product owner can say whether chasing the centres
  is fun. **That verdict is still owed**, and it is the point of this
  iteration; the rest is plumbing.
- **All seats are human.** The AI is Iteration 4, so a four-player game is
  four people taking turns at one keyboard.
- **Programmer art.** Flat ownership colours, an owner's initial on every
  province so colour is never the only cue, a gold dot for a production
  centre. The look is Iteration 5.

## Iteration 4 — The opponent (go/no-go)

Timeboxed, judged on **Classic only** — see DECISIONS.md.

- [ ] **A turn limit and a drawn terminal state**, in the rule set and in
      the victory catalogue. First, because one game in six does not end
      and the tournament below cannot report a result it has no name for
- [ ] `AiPolicy`, taking the rule set and active victory conditions as
      inputs; `core/ai` depends only on `core/rules`
- [ ] **The turtle test, before the real policy**: a policy that never
      attacks, run against the greedy one. If refusing to attack wins,
      the rules have no engine and no amount of AI work hides it. Cheap,
      and it can invalidate the iteration in an afternoon
- [ ] Move `RandomDriver` and `GreedyDriver` out of `test/support` and
      behind `AiPolicy`, so the harness and the game share one notion of
      a mover
- [ ] A baseline policy good enough to be irritating: island
      progress, current and likely-future centre positions, border
      pressure; respects the match rule when choosing where to stack
- [ ] Three difficulty levels; any cheating declared in the open
- [ ] Headless tournament harness in `tools/` — policies against each
      other over N seeds, reporting win rate, game length, **draw rate**,
      and always which policies produced the numbers
- [ ] Verified by the product owner actually playing it
- **Go/no-go**: if the opponent isn't tolerable on Classic within the
  timebox, stop and reassess rather than extending. Recorded either way.

## Iteration 5 — Art direction spike → the vertical slice

One board, one look, end to end. Throwaway code is acceptable here;
throwaway *decisions* are not — what this iteration settles is the
visual register the whole game commits to.

- [ ] Water shader: swell, caustics, foam reading the coastline
- [ ] Coastline treatment — inset shore band, noise-offset edge, so a
      machine-made polygon reads as drawn
- [ ] Palette and type: the illustrated-chart register; a
      colour-blind-safe ownership palette plus a non-colour ownership cue
- [ ] One hazard as a real set piece — the storm — proving the design
      differentiator and the art direction reinforce each other
- [ ] Capture, reinforcement and turn-change juice; ambience and a
      handful of sfx
- [ ] Screenshots and a short capture, kept in the repo
- **Done when**: it is beautiful on `small-sea` — and **the product
  owner decides portfolio vs Steam** on the evidence (DECISIONS.md,
  "Commercial intent").

## Iteration 6 — Map generation

Where the engine's generality and the art system meet, and the first
real test of both.

- [ ] `core/mapgen`: points → cells → lanes → islands → centres,
      per SCENARIOS.md, all seeded
- [ ] `MapGenParams`: size, island count, layout, lane density,
      symmetry; output passes the Iteration 1 validator including the
      fairness checks
- [ ] Property test: 1000 seeds across the parameter space, every map
      valid, no retry loops
- [ ] **The art system survives arbitrary polygons** — thin provinces, fat
      provinces, long coastlines, 50-province boards. Anything that only looked
      right on `small-sea` is found and fixed here, not assumed
- [ ] Re-validate the AI across generated boards; a pass at Iteration 4
      is provisional until this runs
- **Done when**: a fresh board every game at any supported size, all
  valid, still beautiful, with AI win rates recorded.

## Iteration 7 — Victory conditions and scenarios

- [ ] The remaining six conditions from SCENARIOS.md, per-player
      objectives, and the "no way to end" validator rule
- [ ] Scenario JSON: schema version, `extends` resolution, full
      validation of untrusted input, no `ResourceLoader`
- [ ] The built-in presets — Classic, Blitz, Open Sea, Island,
      Still Waters, Last Stand
- [ ] Import/export a scenario file; a short share code for a seed
- [ ] AI reads the active victory conditions — at minimum it plays
      `survival` differently from `conquest`
- **Done when**: every preset plays 100 headless games to a legal
  terminal state, and a scenario file opens the same game elsewhere.

## Iteration 8 — The look, for real

The spike proved the register on one board; this builds it as a system.

- [ ] Weather and time-of-day; every hazard as its own set piece
- [ ] 2D lights, paper grain, parallax, depth
- [ ] Full audio pass: ambience, stingers, music
- [ ] Menus, settings, accessibility (colour-blind modes, reduced
      motion, text scale)
- [ ] Performance budget honoured at the largest supported board
- **Done when**: any generated board at any size looks like the spike
  promised, at frame rate.

## Iteration 9 — Cards

- [ ] Bombard, Shield, Airlift; deck, draw-on-capture, hand cap, reshuffle
- [ ] Hand UI; one card per turn; AI plays them or declares that it doesn't
- **Done when**: each card has a test proving it can't break an
  invariant (Bombard can't capture, Airlift can't strand an province).

## Iteration 10 — Tuning

- [ ] Re-measure game length on Classic against a *real* opponent. The
      economy was already retuned on 2026-09-18 (floor 3 -> 1, divisor
      3 -> 4) to unblock Iteration 4, but every figure behind it came
      from the greedy driver, so the constants are provisional
- [ ] Hazard frequency, deliberately deferred from that retune: they
      fire at about a fifth of the intended rate, and how often they
      *should* fire is a question about feel that wants the product
      owner playing the result, not a length target
- [ ] Tune hazard rates and centre movement against real games — protect
      the centres first if something has to give
- [ ] Play Still Waters against Classic. If hazards and centres don't
      win that comparison, the central claim in DECISIONS.md is wrong
      and we should want to know here, not after release
- [ ] The surrender offer
- **Done when**: ten consecutive Classic games land under five minutes
  and the product owner wants to play another one.

## Iteration 11 — Release

- [ ] Store/release naming consistent with **Malpaco** everywhere
- [ ] ASSETS.md complete: provenance and licence for every asset and font
- [ ] Windows/Linux/macOS builds on a public releases page; `CHANGELOG.md`;
      `v0.1.0` tagged
- [ ] If Steam: store page, capsule art, the paperwork
- [ ] Optional: the courtesy email to Soleau

## Post-POC — not scoped

**Android** — the port the architecture already avoids blocking, but not
before the desktop game is worth installing. **The scenario editor** —
visual map editing, hand-placed starts, an objectives builder; large,
self-contained, and the JSON format already makes scenarios possible
without it. Promote either if the product owner wants it sooner; neither
blocks anything. Also: online multiplayer, more presets and authored
maps, fog of war.
