# Islesrisk

A turn-based island-conquest game for the browser: take an archipelago,
hold it, and try not to lose it to a flood. A modern re-take on the
ruleset of Soleau Software's *Isle Wars* (1994) — **not** a port and not
a clone of it. Portfolio project, not commercial.

Underneath it is a **configurable engine**: boards generated or
hand-drawn at any size, rules as a data object, two to eight players,
seven victory conditions, and scenarios that save and travel as a link.
What a player picks is a *preset* — Classic, Blitz, Archipelago — which
is just a named rule set with a board attached.

**Nothing runs yet.** This repository currently contains specifications
and decisions only — no code, no build. The plan is in
[ROADMAP.md](ROADMAP.md); Iteration 0 is the scaffolding that makes
`npm run dev` mean something.

## The short pitch

Risk-likes are not a gap in the market, and neither is the match rule
that once looked like the hook — Antiyoy already ships a version of it,
free (see [DECISIONS.md](DECISIONS.md), "Mobile competitors"). What is
genuinely unoccupied is the rest of *Isle Wars*' idea: **a board that
keeps moving under you** — floods, earthquakes and revolts aimed at
whoever is winning, and production centres that wander from isle to
isle — in a five-minute game, in a phone browser, with no install.

Configurability is not the pitch; the deep end of this genre is made of
options and nobody is short of them. It is here because a data-driven
engine is the right way to *build* this, and because it makes presets
cheap to try.

That constraint is the product. A faithful 46-territory reproduction is
explicitly *not* the goal; the 1994 original already runs in a browser
tab under DOSBox, for free, and beating that on faithfulness is not a
winnable game.

## Docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — system design and stack choices
- [RULES.md](RULES.md) — the game specification: the `RuleSet` surface,
  the Classic defaults, and the contract `packages/rules` has to satisfy
- [SCENARIOS.md](SCENARIOS.md) — scenarios, map generation, the victory
  condition catalogue, presets and sharing
- [DECISIONS.md](DECISIONS.md) — the *why* behind product and design
  choices, including the case against building this
- [ROADMAP.md](ROADMAP.md) — iteration plan and current status
- [CLAUDE.md](CLAUDE.md) — working notes and repo conventions

## Stack (planned)

Inherited wholesale from [Geoclick](https://github.com/diegoami/Geoclick2027),
minus the geography: npm-workspace monorepo, SvelteKit + TypeScript,
pure-TS engine packages under `packages/` (`rules`, `mapgen`, `ai`),
Vitest, ESLint + Prettier, four quality gates on a pre-push hook, static
deploy to Netlify. The board is inline SVG, not a map renderer. Web only
for now — Tauri and Capacitor shells are additive in this layout and
cost nothing to defer.
