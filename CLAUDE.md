# Islesrisk — working notes for Claude

Turn-based island-conquest game for the browser, on a configurable
engine. See [ARCHITECTURE.md](ARCHITECTURE.md) for system design,
[RULES.md](RULES.md) for the game specification, the `RuleSet` surface
and the engine's contract, [SCENARIOS.md](SCENARIOS.md) for scenarios,
map generation, victory conditions and presets, [ROADMAP.md](ROADMAP.md)
for the iteration plan and current status, and
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
  before changing either.
- Keep SCENARIOS.md current whenever the generator gains a parameter, a
  victory condition is added, or the scenario schema changes — same
  as-part-of-the-change rule as the other docs.
- Roles: the user is Product Manager, Claude is Developer. When a
  deliverable is complete, don't just declare it done — give concrete
  steps to verify it (what to run, click, or look at, and what to
  expect).
- Treat "test locally" and "test the deployment" as two separate,
  explicitly labelled steps whenever both apply, so a deploy problem
  never reads as a feature problem or vice versa.
- Don't go down debugging rabbit holes when the user can fix it in a
  couple of clicks (a dashboard setting, a manual deploy trigger). Try
  the direct route once or twice, then hand it back.

## Hard rules for the engine

- **No rule is a compiled-in assumption.** Every one is a field of
  `state.rules`. Code that assumes the match rule is on, that hazards
  exist, or that victory means conquest is a bug — the AI's code most of
  all. The cross-configuration tests in RULES.md exist to catch it.
- **Presets, not toggles**, on anything a new player sees. The start
  screen offers a preset, a size and an opponent count; the rest is
  reachable through scenarios.
- **Classic is the tuning target.** A change that improves a large
  scenario at Classic's expense is a regression.
- Generated and authored maps are one type and pass one validator.

## Stack

- SvelteKit + TypeScript, `adapter-static` (app shell)
- Inline SVG for the board — **no MapLibre/PMTiles**, deliberately;
  see DECISIONS.md
- `packages/rules` — pure TS, deterministic, seeded RNG *and the
  resolved rule set* in the state
- `packages/mapgen` — pure TS, seeded, produces `GameMap`
- `packages/ai` — pure TS, depends only on `packages/rules`
- Vitest, ESLint + Prettier; four gates (`check`, `test`, `lint`,
  `build`) on a committed pre-push hook
- Netlify static deploy; no backend, no accounts
- Web only for now — Tauri/Capacitor deferred, additive when wanted

## Tuning constants

Every number in RULES.md is ours and provisional (the originals are
closed-source binaries). Tune by playing; never "restore" a value
because a fan wiki asserts it.
