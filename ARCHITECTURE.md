# Malpaco — Architecture

Malpaco is a turn-based conquest **engine** with a game on top of it,
built in **Godot 4** for the desktop, and meant to be beautiful. The
rules descend from Soleau Software's *Isle Wars* (1994) — see
[RULES.md](RULES.md) for the specification and [DECISIONS.md](DECISIONS.md)
for why it is a re-take rather than a port.

"Engine" is meant literally and it is the central architectural
commitment: the board is generated or authored at any size, the rules
are a data object, the number and kind of players is configuration, and
victory is a list of predicates. What a player sees is a **preset** —
Classic, Blitz, Archipelago — which is nothing but a named rule set with
a map source attached. Scenario structure, map generation and the
victory catalogue are in [SCENARIOS.md](SCENARIOS.md).

Target: **desktop first** (Windows, Linux, macOS), **Android later**.
No browser — see DECISIONS.md, "Godot and the desktop". Whether it ends
up on Steam is decided after the vertical slice (Iteration 5); until
then it is built *as if* commercial, which mostly means disciplined
asset provenance and a name that is genuinely ours.

## Stack

| Layer | Choice |
|---|---|
| Engine | **Godot 4.7.x** (4.7.2 stable as of 2026-08-18) |
| Language | **GDScript**, statically typed throughout |
| Rendering | Godot 2D — `Polygon2D` boards, `CanvasItem` shaders, 2D lights, GPUParticles2D |
| Tests | **gdUnit4**, run headless (`godot --headless`) |
| Lint/format | **gdtoolkit** — `gdlint`, `gdformat --check` |
| CI | GitHub Actions (gdUnit4 has an official action); the same gates on a pre-push hook |
| Data | JSON for maps, presets and scenarios — never Godot `Resource` files (see "Loading data is a security boundary") |
| Distribution | Godot export templates → desktop builds on a GitHub releases page |

**Why GDScript, not C#**: typed GDScript is now within noise of C# for
game logic, it wins on editor integration and iteration speed, and it is
what 84% of the ecosystem's addons and answers assume. C# would win on a
codebase past ~10k lines and on external tooling, which is a real
argument for an engine-heavy project like this one — but not enough to
give up the iteration loop on a solo 2D game. The decision is cheap to
revisit only while `core/` is small, so it is worth revisiting *at*
Iteration 2's end and not after.

## What did not survive the pivots

Recorded because half of this document used to say otherwise: SvelteKit,
TypeScript, npm workspaces, inline SVG, Netlify, and the whole
"no-install, five-minute phone browser" pitch are gone. So is sharing a
scenario by URL. [RULES.md](RULES.md) and [SCENARIOS.md](SCENARIOS.md)
survived the move nearly intact, which is the payoff for having written
them as data specifications rather than as descriptions of a program.

## The core is pure, headless, and deterministic

`core/` is plain GDScript — classes extending `RefCounted`, never
`Node`. It does not touch the scene tree, does not load scenes, does not
read files, does not use `get_tree()`, signals, `Time`, or the global
`randi()`. One entry point:

```gdscript
Rules.apply_action(state: GameState, action: Action) -> GameState
```

Total, deterministic, no I/O. Every source of chance draws from a
`RandomNumberGenerator` whose seed and state live *inside* `GameState`.

Three things depend on this, which is why it is a rule and not a
preference: a save file, a replay and a bug report become the same small
object (a seed, a rule set and an action list); the AI can evaluate a
move by playing it against a copy of the state; and the whole ruleset is
testable headlessly in milliseconds, with no window and no frames.

**Purity is enforced, not trusted.** A test greps `core/` for `Node`,
`get_tree`, `randi(`, `randf(`, `Time.`, `load(`, `preload(` and fails
the gates on a hit. Without that, the boundary erodes in a week — this
is the cheapest test in the project and the one that protects everything
else.

**Integer arithmetic in the rules.** Combat, reinforcement and hazard
maths stay on integers; floats appear only in presentation. Godot's
`RandomNumberGenerator` (PCG32) reproduces integer draws identically
across platforms, and float accumulation does not reliably do so. A
replay that desyncs between a Windows and a Linux build would invalidate
every guarantee above.

## Domain model

**Isle** — one territory. Holds armies, has an owner, belongs to an
archipelago, and connects to others by explicit sea lanes. Whether a map
was drawn by hand or produced by the generator, it is this same
structure and passes the same validator.

```
Isle {
  id            String
  name          String
  archipelago   String
  neighbours    Array[String]      // authored, symmetric, never derived
  polygon       PackedVector2Array // board coordinates
  label_at      Vector2
}
```

The polygon is plain geometry, not a drawing: it feeds `Polygon2D`,
`Line2D` coastlines, hit-testing and the art system alike. There is no
per-isle artwork anywhere in the data, because the generator invents
isles the artist will never see (see "Looking good").

**GameState** — everything needed to render a game and continue it.

```
GameState {
  map        GameMap
  rules      RuleSet            // resolved and inline, never a reference
  players    Array[Player]      // colour, kind, objectives
  owner      Dictionary         // isle_id -> player_id
  armies     Dictionary         // isle_id -> int
  turn       { player, phase, number }
  hands      Dictionary
  centres    Array[String]
  rng        { seed, state }
  log        Array[Event]
}
```

`rules` sits inside the state, resolved from any `extends` chain and
stored in full, so tuning a preset next month cannot rewrite a save.

**Scenario** — the serializable set-up that *produces* a `GameState`.
The unit that is saved, shared and replayed. See SCENARIOS.md.

Phases per turn: `reinforce → attack → redeploy → hazards`. Hazards
resolve at the *end* of a turn, so a player always sees the board they
are about to act on. A phase the configuration empties is skipped.

**No rule may be a compiled-in assumption**, in any file. Every rule is
a field of `state.rules`; code assuming the match rule is on, that
hazards exist, or that victory means conquest is a bug — the AI's code
most of all, where it is easiest to hide and hardest to notice.

## Project layout

```
/project.godot
/core/            pure GDScript, headless, no Node
  /rules/         RuleSet, GameState, actions, combat, hazards, victory
  /mapgen/        seeded generation -> GameMap
  /ai/            opponent policies, built on /rules only
  /validate/      the map + scenario validator, shared by both sources
/game/            scenes: board rendering, UI, input, effects, audio
/art/             shaders, materials, palettes, fonts, sfx
/data/            authored maps, presets, built-in scenarios (JSON)
/test/            gdUnit4 suites — unit, property, and the purity guard
/tools/           gates script, export helpers
```

`game/` may call into `core/`. `core/` must not know `game/` exists, and
`mapgen` must not know how play works.

## Looking good

The goal is a beautiful game, and the single most important constraint
comes from pairing that with procedural maps:

> **The beauty has to be a system, not artwork.** The generator invents
> boards at runtime, so nothing can be hand-illustrated per map. Every
> gorgeous thing must be procedural — shaders, materials, coastline
> treatment, lighting, weather, motion — applied to arbitrary polygons.

This is how the reference points do it: *Bad North* and *ISLANDERS*
both look superb with procedurally arranged islands because their look
is a lighting-and-material system, not bespoke per-level art. The same
route, in 2D:

- **Water first.** An animated `CanvasItem` shader under everything —
  swell, caustics, foam that reads the coastline's distance field. Water
  is most of the screen and most of the impression.
- **Coastlines, not outlines.** Each isle's polygon gets an inset shore
  band, a sand/rock gradient and a hand-drawn-feeling edge (a noise
  offset along the `Line2D`), so a machine-made polygon reads as drawn.
- **Chart, not board.** The visual register is an illustrated nautical
  chart that has come alive: paper grain, ink linework, a restrained
  palette, generous type. It flatters flat colour, which is what
  ownership needs anyway.
- **Ownership must stay readable.** Colour identifies a player, and no
  atmospheric effect may compromise that. A colour-blind-safe palette
  and a non-colour ownership cue are requirements, not polish.
- **Hazards are the set piece**, and this is where the art direction and
  the design differentiator finally meet: a flood is a storm crossing
  the map, a quake shakes the isle and cracks its shore, a revolt raises
  a flag and a smoke plume. These are the moments a player will screenshot.
- **Juice.** Tweened army counts, a satisfying capture, camera nudges,
  layered ambience. Cheap, and most of what separates "clean" from
  "gorgeous".

The renderer draws whatever the generator emits. An art idea that only
works on a hand-placed board is not usable — that is the test every
visual decision has to pass, and the reason the art system is validated
against generated maps in Iteration 6 rather than assumed to survive.

## Loading data is a security boundary

Maps, presets and scenarios are **JSON**, loaded with `JSON.parse` and
validated before use. They are explicitly **never** Godot `Resource`
files: `.tres`/`.res` can carry embedded scripts, so `ResourceLoader` on
a file from a stranger is arbitrary code execution, and scenario sharing
is exactly that path. Unknown fields and unknown `kind` tags are
rejected rather than ignored, sizes are capped, and a file that fails
validation loads nothing and says why.

## Storage

Local, no accounts, no backend. `user://` holds the in-progress game, a
short results history, and saved or imported scenarios. A save carries
its resolved rule set and its seed, so it is simultaneously a replay and
a reproducible bug report.

## Platforms

Desktop is the design target: mouse, keyboard, a window that resizes,
and GPU headroom for the water. Android comes after the game is worth
installing — which mainly constrains the UI, so hit targets stay
generous and nothing depends on hover from the start. Those are cheap
habits now and expensive retrofits later; nothing else about the
architecture is bent for a platform that isn't shipping yet.
