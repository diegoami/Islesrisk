# Islesrisk — Roadmap

Self-contained iterations toward a beautiful desktop conquest game built
on the engine described in [ARCHITECTURE.md](ARCHITECTURE.md). Each
iteration should leave the repo in a working, demo-able state so work
can resume cleanly from any point. Check items off as they land; update
"Status" as iterations complete.

## Status

- **Done**: nothing is built. This repository holds specifications and
  decisions only — [ARCHITECTURE.md](ARCHITECTURE.md),
  [RULES.md](RULES.md), [SCENARIOS.md](SCENARIOS.md),
  [DECISIONS.md](DECISIONS.md) and this file. No Godot project, no code.
  Deliberate: the product owner asked for the specs to be reviewable
  before any scaffolding lands, and two pivots have since arrived that
  would have thrown away working code.
- **Next up**: Iteration 0, on the product owner's go-ahead.
- **Retargeted (2026-09-15)**: Godot 4 on the desktop, painterly 2D,
  Android later, no browser (DECISIONS.md, "Godot and the desktop",
  "Gorgeous, and what that costs"). The previous web stack is gone;
  RULES.md and SCENARIOS.md carried over nearly unchanged.
- **Decision point**: Iteration 5 produces the vertical slice, and the
  commercial question (portfolio vs Steam) is answered there.
- **Open before release**: a final name (DECISIONS.md, "Name, art and IP
  posture"). "Islesrisk" is provisional and more urgent now that a
  commercial release is possible.

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

## Iteration 0 — Godot project & gates

- [ ] Godot 4.7.x project; `core/`, `game/`, `data/`, `test/`, `tools/`
- [ ] Typed GDScript everywhere; `gdlint` + `gdformat --check` clean
- [ ] gdUnit4 wired, running headless via `godot --headless`
- [ ] **The purity guard**: a test that greps `core/` for `Node`,
      `get_tree`, `randi(`, `randf(`, `Time.`, `load(`, `preload(` and
      fails on a hit
- [ ] `tools/gates.sh` — format, lint, test, export — on a committed
      pre-push hook; the same four in GitHub Actions
- [ ] Export presets for Windows and Linux producing a runnable binary
- **Done when**: a clean clone passes the gates and produces a desktop
  build that opens a window.

## Iteration 1 — Map data, validator, the Classic board

- [ ] `GameMap` / `Isle` / `Archipelago` in `core/rules`
- [ ] The validator from [SCENARIOS.md](SCENARIOS.md), in `core/validate`
- [ ] JSON loading with full validation and no `ResourceLoader`
- [ ] `small-sea`: 14 isles, 4 archipelagos, per RULES.md
- [ ] A board scene that renders any map — `Polygon2D` per isle, flat
      colour, army counts. Deliberately ugly
- **Done when**: the board renders at any map size, and a deliberately
  broken map fails the gates.

## Iteration 2 — Rules engine, headless

The core of the project: data-driven from the start, hazards and centres
included, Classic as the default `RuleSet`. No UI work at all.

- [ ] `RuleSet` and the Classic preset — every table in RULES.md
- [ ] `GameState` (rules resolved inline), `Action`, seeded RNG in state
- [ ] Setup, reinforce, attack, redeploy — constants read from the rule
      set, never from a literal; integer arithmetic only
- [ ] Hazards: floods, earthquakes, revolts. Centres: placement, bonus,
      wander
- [ ] `conquest` victory, plus the condition-evaluation hook the rest
      plug into at Iteration 7
- [ ] The Classic checklist from RULES.md, the cross-configuration
      tests, and the determinism property test over (seed, rules, map,
      actions)
- [ ] A headless 100-game harness reporting hazard rates and game length
- [ ] **Revisit GDScript vs C#** while `core/` is still small — record
      the outcome either way (ARCHITECTURE.md)
- **Done when**: a scripted game plays start to finish under gdUnit4,
  every listed rule has a failing-case test, a rules-toggled variant
  plays without special-casing, and the harness numbers are in
  DECISIONS.md.

## Iteration 3 — Hot-seat, playable

- [ ] Click an isle to select, click an adjacent enemy isle to attack;
      illegal targets are not offered, and the reason is visible
- [ ] Phase bar, reinforcement placement, redeploy, end turn; an empty
      phase is skipped, not shown empty
- [ ] Hazards and centre moves shown as they happen, even as programmer
      art — a rubber band the player can't perceive reads as the game
      being arbitrary
- [ ] Start screen: preset and opponent count. No toggles
- [ ] Save, resume, result screen with the seed
- **Done when**: two humans can play a complete game — **and the product
  owner can say whether chasing the centres is fun.** That verdict is
  the point of this iteration; the rest is plumbing.

## Iteration 4 — The opponent (go/no-go)

Timeboxed, judged on **Classic only** — see DECISIONS.md.

- [ ] `AiPolicy`, taking the rule set and active victory conditions as
      inputs; `core/ai` depends only on `core/rules`
- [ ] A baseline policy good enough to be irritating: archipelago
      progress, current and likely-future centre positions, border
      pressure; respects the match rule when choosing where to stack
- [ ] Three difficulty levels; any cheating declared in the open
- [ ] Headless tournament harness — policies against each other over N
      seeds, win rates reported
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

- [ ] `core/mapgen`: points → cells → lanes → archipelagos → centres,
      per SCENARIOS.md, all seeded
- [ ] `MapGenParams`: size, archipelago count, layout, lane density,
      symmetry; output passes the Iteration 1 validator including the
      fairness checks
- [ ] Property test: 1000 seeds across the parameter space, every map
      valid, no retry loops
- [ ] **The art system survives arbitrary polygons** — thin isles, fat
      isles, long coastlines, 50-isle boards. Anything that only looked
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
- [ ] The built-in presets — Classic, Blitz, Open Sea, Archipelago,
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
  invariant (Bombard can't capture, Airlift can't strand an isle).

## Iteration 10 — Tuning

- [ ] Measure real game length on Classic; tune with the levers in
      RULES.md, **in their stated order**
- [ ] Tune hazard rates and centre movement against real games — protect
      the centres first if something has to give
- [ ] Play Still Waters against Classic. If hazards and centres don't
      win that comparison, the central claim in DECISIONS.md is wrong
      and we should want to know here, not after release
- [ ] The surrender offer
- **Done when**: ten consecutive Classic games land under five minutes
  and the product owner wants to play another one.

## Iteration 11 — Release

- [ ] Final name decided, applied, DECISIONS.md amended
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
