# Malpaco — working notes for Claude

Turn-based island-conquest game for the desktop, built in Godot 4 on a
configurable engine, and meant to be beautiful. See
[ARCHITECTURE.md](ARCHITECTURE.md) for system design, stack and the art
direction constraint, [RULES.md](RULES.md) for the game specification,
the `RuleSet` surface and the engine's contract,
[SCENARIOS.md](SCENARIOS.md) for scenarios, map generation, victory
conditions and presets, [ROADMAP.md](ROADMAP.md) for the iteration plan
and current status, [ONBOARDING.md](ONBOARDING.md) for setting up a
machine, running it, and the gotchas that cost someone an evening, and
[DECISIONS.md](DECISIONS.md) for a scannable log of *why* things work
the way they do — product and design decisions, separate from this
file's workflow rules.

## Workflow

- New features/fixes: work on a branch, not directly on `main`. Commit
  and push the branch without asking first. Test locally and report
  concrete verification steps so the user can test it themselves too.
  Only merge to `main` after the user explicitly OKs it — a review gate,
  not a cost one. Small doc-only changes can go straight to `main`.
- Keep ROADMAP.md up to date: check off tasks as they land, update the
  Status section, adjust deliverables if scope shifts mid-iteration.
- Update ARCHITECTURE.md as part of finishing each iteration — it should
  stay a real map of how the code is organized, not just the original
  design doc. This is how the user, who isn't reading the code directly,
  keeps a grasp of it.
- Record product/design decisions in DECISIONS.md as they're made — not
  what was built (ROADMAP.md's job) but *why*. When a later decision
  supersedes an earlier one, amend that entry rather than leaving a
  stale one to be found first.
- RULES.md is the spec, and the engine is judged against it. If the code
  and RULES.md disagree, one of them is a bug — decide which, in writing,
  before changing either. Same for SCENARIOS.md whenever the generator
  gains a parameter, a victory condition is added, or the schema changes.
- Keep ONBOARDING.md current too: if a change adds a gotcha, moves
  where something important lives, or changes how the project is set up
  or run, reflect it there — it goes stale the same way the other docs
  would if left alone.
- Keep **ASSETS.md** current from the first asset: source, author,
  licence, and a link, for every image, font, shader and sound. A
  licence that can't be reconstructed later is an art rewrite, and the
  commercial question is still open (DECISIONS.md, "Commercial intent").
- Roles: the user is Product Manager, Claude is Developer. When a
  deliverable is complete, don't just declare it done — give concrete
  steps to verify it (what to run, click, or look at, and what to
  expect). For anything visual, attach a screenshot: the gates cannot
  tell anyone whether the game looks good.
- Don't go down debugging rabbit holes when the user can fix it in a
  couple of clicks. Try the direct route once or twice, then hand back.

## Hard rules for the engine

- **`core/` is pure.** Plain `RefCounted` classes: no `Node`, no
  `get_tree()`, no signals, no `load`/`preload`, no `Time.`, no global
  `randi()`/`randf()`. All chance comes from the seeded RNG inside
  `GameState`. A gate greps for these — don't work around it, and don't
  weaken it.
- **Integer arithmetic in the rules.** Floats are presentation only.
  Cross-platform replay determinism depends on this.
- **No rule is a compiled-in assumption.** Every one is a field of
  `state.rules`. Code that assumes the match rule is on, that hazards
  exist, or that victory means conquest is a bug — the AI's code most of
  all. The cross-configuration tests in RULES.md exist to catch it.
- **JSON only for loaded data.** Never `ResourceLoader`, `.tres` or
  `load()` on a path from a file: Godot resources can carry scripts, and
  an imported scenario is untrusted input.
- **Presets, not toggles**, on anything a new player sees. Classic is
  the tuning target; a change that improves a large scenario at
  Classic's expense is a regression.
- Generated and authored maps are one type and pass one validator.

## Hard rules for the look

- **The beauty is a system, not artwork.** Maps are generated, so
  nothing can be hand-illustrated per map. An art idea that only works
  on a hand-placed board is not usable.
- **Ownership readability outranks atmosphere.** Colour-blind-safe
  palette plus a non-colour ownership cue; no effect may compromise
  reading who owns what.
- Hazards are the set pieces — the mechanic nobody else has is also the
  best thing on screen. Spend effort there first.

## Stack

- Godot 4.7.x, statically typed GDScript throughout
- gdUnit4, run headless (`godot --headless`); gdtoolkit (`gdlint`,
  `gdformat --check`)
- Four gates — format, lint, test, export — on a pre-push hook and in
  GitHub Actions
- Godot 2D rendering: `Polygon2D`, `CanvasItem` shaders, 2D lights,
  `GPUParticles2D`
- Desktop first (Windows, Linux, macOS), Android later, no browser
- Local storage under `user://`; no backend, no accounts
