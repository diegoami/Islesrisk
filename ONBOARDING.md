# Malpaco — onboarding

How to pick this project up on a new machine or in a new session,
written for whoever arrives next: a human, or Claude in a fresh session
with no memory of how the repo got here. Everything needed is in this
repository — there is no state anywhere else.

Day-to-day conventions live in [CLAUDE.md](CLAUDE.md); this file is
about *starting*, and about the things that are only learned by trying.

## Where the project actually is

**Iteration 0 is done.** There is a Godot project, four working quality
gates, a test suite and a desktop build. There is not yet a game: the
main scene is a title card, and the only engine code is the seeded RNG
everything else will draw from. Iteration 1 (map data, validator, the
Classic board) is next — see [ROADMAP.md](ROADMAP.md).

Before that, the repository held nothing but specifications for a while,
deliberately, and it paid for itself twice: the target changed from a
web app to a Godot desktop game, and the scope from a fixed small game
to a configurable engine. Both arrived while there was no code to throw
away.

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

1. **Godot 4.7.2** — <https://godotengine.org/download>. The standard
   build is the one to pick; the .NET build also runs this project
   perfectly well, because nothing here is C# (verified on Windows,
   2026-09-18). Either way it is a single portable executable: unzip and
   run. Unzipping does **not** put it on `PATH` — see "Running it".
2. **gdtoolkit** for the lint and format gates:
   `pip install "gdtoolkit==4.*"` — provides `gdformat` and `gdlint`.
3. **Clone and enable the hook**:
   ```
   git clone https://github.com/diegoami/Malpaco.git
   cd Malpaco
   git config core.hooksPath .githooks   # once per clone, from Iteration 0 on
   ```
4. **Export templates** are only needed to build installers. Godot
   offers to fetch them the first time you export.

## Running it

```
godot --path .        # run the game (or open the project and press F5)
./tools/gates.sh      # all five gates: format, lint, test, smoke, export
```

Neither works until Godot is findable. `tools/gates.sh` looks for
`GODOT_BIN` first and falls back to `godot` on `PATH`, so setting that
one variable fixes both:

```
export GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64
```

On **Windows**, set it once per user and reach it from PowerShell or Git
Bash alike — and point it at the `_console.exe`, for the reason in the
gotchas:

```powershell
[Environment]::SetEnvironmentVariable('GODOT_BIN',
  'C:\Program Files\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe',
  'User')   # new terminals pick it up; the current one does not
```

Running the tests directly, if you want the raw output:

```
godot --path . --headless --import                       # warm-up, see gotchas
godot --path . --headless -s -d --remote-debug tcp://127.0.0.1:0 \
      res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a test --ignoreHeadlessMode -c
```

The runner exits 0 on success and 100 on failure, which is what makes the
gate real. Reports land in `reports/` (gitignored) as JUnit XML and HTML.

**The export gate is skipped** when export templates aren't installed, so
working on `core/` doesn't force a 1 GB download. CI sets
`MALPACO_REQUIRE_EXPORT=1` to make it mandatory there. To install them
locally: Godot → Editor → Manage Export Templates.

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
- **On Windows, use the `_console.exe`.** A Godot zip ships two
  executables. The plain one detaches from the terminal, so you get no
  `print`, no script errors and no gate output — the command looks like
  it did nothing. The `_console.exe` beside it keeps stdout attached and
  is what `GODOT_BIN` should point at. The windowed one is only worth
  double-clicking.
- **gdtoolkit lags the engine.** The linter is 4.5.0 against a 4.7.2
  engine, so it may flag valid 4.7 syntax. If a gate fails on something
  that is plainly correct, suspect the linter before the code — and pin
  or disable the specific rule rather than contorting the source. So far
  it has been clean; the only rule that has bitten is a 100-character
  line limit.
- **Typing is enforced by the engine, not by review.**
  `project.godot` sets `untyped_declaration`, `unsafe_property_access`
  and `unsafe_method_access` to *error*, with `exclude_addons=true` so
  the vendored gdUnit4 is not held to it. Untyped code fails to parse,
  which is the point.
- **gdUnit4 detects that it is under test** and skips activating its own
  editor plugin during a headless run. The "GdUnit4 plugin will not be
  executed" line in the output is expected, not a problem.
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

- ~~The name.~~ **Settled 2026-09-17: Malpaco.** See DECISIONS.md,
  "Name, art and IP posture".
- **An Esperantist's eye over the board.** Every name in the game is
  Esperanto now — the four nations, the islands, the provinces, the map
  itself. The grammar is straightforward and the words are dictionary
  words, but whether they *read* naturally to someone who speaks the
  language is their call, not ours. Worth an hour of someone's time
  before any of it reaches a store page.
- **Portfolio or commercial.** Answered at the vertical slice, Iteration
  5. Until then the project is built *as if* commercial, which in
  practice means only: track asset provenance in ASSETS.md from the
  first asset, and use a name that is genuinely ours.
