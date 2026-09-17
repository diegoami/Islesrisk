# Islesrisk — onboarding

How to pick this project up on a new machine or in a new session,
written for whoever arrives next: a human, or Claude in a fresh session
with no memory of how the repo got here. Everything needed is in this
repository — there is no state anywhere else.

Day-to-day conventions live in [CLAUDE.md](CLAUDE.md); this file is
about *starting*, and about the things that are only learned by trying.

## Where the project actually is

**Specifications and decisions only. No code, no Godot project yet.**
Iteration 0 in [ROADMAP.md](ROADMAP.md) is the next thing to build, and
it is the scaffolding that makes `godot` mean anything here.

That is deliberate, and it has already paid for itself twice: the target
changed from a web app to a Godot desktop game, and the scope changed
from a fixed small game to a configurable engine. Both arrived while the
repo held nothing but documents, so neither threw away working code.

## Reading order

1. [README.md](README.md) — what this is, in a page
2. [ARCHITECTURE.md](ARCHITECTURE.md) — stack, the pure-core rule, the
   art-direction constraint, project layout
3. [RULES.md](RULES.md) — the game spec and the `RuleSet` surface
4. [SCENARIOS.md](SCENARIOS.md) — maps, generation, victory conditions
5. [ROADMAP.md](ROADMAP.md) — what to build next, in order
6. [DECISIONS.md](DECISIONS.md) — *why*, including the arguments against
   building this at all. Read before proposing a change of direction;
   several plausible ideas were considered and rejected there for
   reasons that still hold.

## Setting up a desktop

1. **Godot 4.7.2**, standard build (**not** .NET) —
   <https://godotengine.org/download>. It is a single portable
   executable; unzip and run. Use .NET only if the Iteration 2 language
   revisit (ARCHITECTURE.md) has switched the project to C#.
2. **gdtoolkit** for the lint and format gates:
   `pip install "gdtoolkit==4.*"` — provides `gdformat` and `gdlint`.
3. **Clone and enable the hook**:
   ```
   git clone https://github.com/diegoami/Islesrisk.git
   cd Islesrisk
   git config core.hooksPath .githooks   # once per clone, from Iteration 0 on
   ```
4. **Export templates** are only needed to build installers. Godot
   offers to fetch them the first time you export.

## Running it, once Iteration 0 exists

```
godot --path .                  # run the game
godot --headless --import       # warm-up pass (see gotchas — do this first)
godot --headless --script ...   # headless scripts and test runs
./tools/gates.sh                # format, lint, test, export
```

## Verified environment facts

Checked directly on a Linux container on 2026-09-17, not assumed:

- Godot **4.7.2.stable.official.ed1daf0bf** runs headless with no
  display, and seeded `RandomNumberGenerator` draws reproduce exactly —
  the determinism the whole engine design depends on works.
- With `xvfb-run`, Godot renders and captures PNGs on a machine with no
  screen. This is what lets a cloud session iterate on visuals and hand
  back screenshots.
- `gdformat`/`gdlint` **4.5.0** install cleanly from PyPI.
- Export templates download fine from the `godot-builds` release.

## Gotchas, each learned the hard way

- **`class_name` globals need an import pass.** A bare
  `godot --headless --script foo.gd` fails with *Identifier "X" not
  declared in the current scope* until `godot --headless --import` has
  run once. CI must do the warm-up import before the test step, and so
  must you after a fresh clone.
- **gdtoolkit lags the engine.** The linter is 4.5.0 against a 4.7.2
  engine, so it may flag valid 4.7 syntax. If a gate fails on something
  that is plainly correct, suspect the linter before the code — and pin
  or disable the specific rule rather than contorting the source.
- **Audio fails on headless machines.** ALSA errors and a fall back to
  the dummy driver are expected and harmless in CI; it does mean sound
  cannot be evaluated anywhere but a real desktop.
- **`.NET`/`dotnet` is not installed** on the cloud container. Relevant
  only if the language revisit picks C#, which would also mean CI needs
  the .NET SDK added.

## Working across a cloud session and a desktop

The repository is the only shared state, so the rule is simply: **push
before you switch, pull when you arrive.** A conversation does not
transfer between sessions and does not need to — that is what
DECISIONS.md and ROADMAP.md are for. If something was decided in a chat
and is not written down here, it is not a decision yet.

A practical division of labour, given a cloud session cannot see your
screen and a desktop cannot run unattended:

- **Cloud session**: `core/` engine work, the map generator, AI
  policies, headless test and tournament runs, docs. All of it needs no
  display.
- **Desktop**: anything that has to be *judged* — is the board readable,
  does the water move well, is a capture satisfying, is the opponent
  irritating in the right way. Screenshots answer composition questions;
  only playing answers feel.

When something looks wrong, a screenshot is worth a paragraph — the
cloud container renders in software (llvmpipe) and a real GPU may not
agree with it.

## What the product owner still owes a decision on

- **The name.** "Islesrisk" is provisional and reads as a Risk
  derivative, which is the comparison the project is trying not to
  invite. Needed before release (DECISIONS.md, "Name, art and IP
  posture").
- **Portfolio or commercial.** Answered at the vertical slice, Iteration
  5. Until then the project is built *as if* commercial, which in
  practice means only: track asset provenance in ASSETS.md from the
  first asset, and use a name that is genuinely ours.
