# Malpaco

*Esperanto: **mal-PAH-tso**, "un-peace" — `paco` is peace, `mal-`
reverses it.*

A turn-based island-conquest game for the desktop, built in Godot 4:
take an archipelago, hold it, and try not to lose it to a storm. A
modern re-take on the ruleset of Soleau Software's *Isle Wars* (1994) —
**not** a port and not a clone of it.

The name is the design. Nothing you hold stays held: the floods and the
revolts fall on whoever is winning, the production centres wander off,
and an attack is a commitment you cannot take back. The board never
settles.

Underneath it is a **configurable engine**: boards generated or
hand-drawn at any size, rules as a data object, two to eight players,
seven victory conditions, and scenarios that save and travel as files.
What a player picks is a *preset* — Classic, Blitz, Archipelago — which
is just a named rule set with a board attached.

The goal is for it to be **beautiful**: painterly illustrated 2D, an
animated sea, coastlines that read as drawn, and weather that is also a
game mechanic.

**It runs, but there is no game yet.** Iteration 0 is done: a Godot
4.7 project, four quality gates, a headless test suite, and Linux and
Windows builds. The main scene is a title card and the only engine code
is the seeded generator everything else will draw from. Iteration 1 —
map data and the board — is next; see [ROADMAP.md](ROADMAP.md).

```
git clone https://github.com/diegoami/Malpaco.git
cd Malpaco
git config core.hooksPath .githooks   # once, so the gates run before a push
godot --path .                        # or open the project and press F5
./tools/gates.sh                      # format, lint, test, export
```

Setup, and the gotchas worth knowing before you hit them, are in
[ONBOARDING.md](ONBOARDING.md).

## The short pitch

Risk-likes are not a gap in the market, and neither is the match rule
that once looked like the hook — Antiyoy already ships a version of it,
free (see [DECISIONS.md](DECISIONS.md), "Mobile competitors"). Two
things are genuinely unoccupied:

- **A board that keeps moving under you.** Floods, earthquakes and
  revolts aimed at whoever is winning, and production centres that
  wander from isle to isle. No current conquest game does either.
- **Beauty.** Desktop Risk-likes are overwhelmingly functional-looking —
  UI over a map. A conquest game that is genuinely lovely to look at is
  a sharper differentiator than any rule, and the two arguments meet in
  the same feature: the hazards are also the best thing on screen.

Configurability is not the pitch; the deep end of this genre is made of
options and nobody is short of them. It is here because a data-driven
engine is the right way to *build* this, and because it makes presets
cheap to try.

## Docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — system design, stack, the art
  direction constraint, project layout
- [RULES.md](RULES.md) — the game specification: the `RuleSet` surface,
  the Classic defaults, and the contract `core/rules` has to satisfy
- [SCENARIOS.md](SCENARIOS.md) — scenarios, map generation, the victory
  condition catalogue, presets and sharing
- [DECISIONS.md](DECISIONS.md) — the *why* behind product and design
  choices, including the case against building this at all
- [ROADMAP.md](ROADMAP.md) — iteration plan and current status
- [ONBOARDING.md](ONBOARDING.md) — picking the project up on a new
  machine or in a new session: setup, how to run it, and the gotchas
- [ASSETS.md](ASSETS.md) — provenance and licence for everything here
  that someone else wrote
- [CLAUDE.md](CLAUDE.md) — working notes and repo conventions

## Stack (planned)

Godot 4.7.x, statically typed GDScript, gdUnit4 run headless, gdtoolkit
for lint and format, four quality gates on a pre-push hook and in GitHub
Actions. Pure engine code in `core/` — no `Node`, no scene tree, no
global RNG, enforced by a test. Rendering is Godot 2D: polygons,
`CanvasItem` shaders, 2D lights and particles.

Desktop (Windows, Linux, macOS) first; Android later; no browser.
Whether this becomes a commercial release is decided after the vertical
slice — see [DECISIONS.md](DECISIONS.md), "Commercial intent".
