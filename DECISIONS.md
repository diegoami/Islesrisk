# Islesrisk — Decisions

A scannable log of *why* the project works the way it does — decisions
made along the way, with the reasoning, not the implementation detail.
For "what was built and how it was verified", see the relevant iteration
in [ROADMAP.md](ROADMAP.md); for the system description, see
[ARCHITECTURE.md](ARCHITECTURE.md); for the rules themselves, see
[RULES.md](RULES.md). Workflow rules live in [CLAUDE.md](CLAUDE.md).

Keep this updated the same way as the other docs: when a decision is
made, corrects an earlier one, or gets revisited, add or amend an entry
here as part of that change, not as an afterthought.

## Why build this at all (2026-09-15, amended the same day — see "Mobile competitors")

- **The market case is weak, and that is recorded here on purpose.** A
  market scan ran before any of this was written. Findings: *RISK:
  Global Domination* (SMG Studio, official Hasbro licence, 2-5M Steam
  owners per SteamSpy plus a much larger mobile base) is the ceiling;
  *Warzone* owns the deep end with 15+ years of community maps;
  *Conquer Club* owns async multi-day play; **territorial.io** owns the
  growth story with sub-five-minute rounds; Dice Wars, Antiyoy and Slay
  fill the simple-conquest slot. Open-source Risk engines on GitHub are
  mostly abandoned student projects and none is a base worth building
  on. Nobody is waiting for another Risk clone.
- **The decisive argument against a faithful port is emulation, not
  competition.** *Isle Wars* already runs in a browser tab today, free,
  via DOSBox builds on playdosgames.com and the Internet Archive. A
  faithful JS reproduction of a 1994 game delivers approximately nothing
  over a thing that already exists and cost nobody any work.
- **So the project is justified on two grounds only**: it is a portfolio
  project whose real output is the codebase, and there is one genuine
  product gap. **Amended the same day**: that first scan covered desktop
  and browser and concluded the gap was *Isle Wars*' rules as a whole,
  the match rule included. A follow-up scan of mobile found the match
  rule already shipping, and narrowed the gap to the hazards and the
  roaming centres — see "Mobile competitors" below, which supersedes
  this bullet on what is actually unoccupied. Whether anyone wants it is
  still untested, which is an acceptable risk for a hobby project and
  would not be for a commercial one.
- **Consequence, and the whole reason this entry exists**: the project
  must compete on what emulation cannot give — touch, a five-minute
  session, no install — and never on faithfulness. Any future proposal
  that starts "to be more like the original…" should be read against
  this entry first.

## Mobile competitors, and which differentiator survives (2026-09-15)

A second scan, this time of what is actually shipping on phones. It
changed the plan, so it gets its own entry rather than a footnote.

- **The closest current game is [Antiyoy](https://play.google.com/store/apps/details?id=yio.tro.antiyoy.android)**
  (Android, free, open source, ~7MB, no ads or IAP) — a hex conquest
  game by one developer, derived from Sean O'Connor's *Slay*, with 150+
  campaign levels, a skirmish generator, a map editor, and an explicit
  "Slay rules" toggle. It matters because the Slay lineage already has
  a rank rule: a unit takes a tile only if it outranks the defender.
  That is the same design intent as our match rule and it produces the
  same effect.
- **So the match rule is not the moat, and RULES.md was wrong to imply
  it was.** Corrected there. Keep the rule — it is good, and it is what
  makes the failure penalty bite — but stop selling the project on it.
- **What survives the scan**: hazards that deliberately lean on the
  leader, and production centres that relocate themselves. Nothing
  current on mobile does either. That is the whole differentiator, and
  it is now stated as such in RULES.md's hazards section.
- **What also survives, and is worth more than it looks**: a phone
  *browser*, no install, a shareable link. Antiyoy is an app, and the
  install is the friction. This is the one axis where being a small web
  project is an advantage rather than a handicap.
- **The rest of the mobile field, and the axis each occupies**:
  [State.io](https://play.google.com/store/apps/details?id=io.state.fight)
  (real-time hypercasual, reportedly $1M+/month at peak — proves the
  appetite for five-minute conquest, has no rules depth);
  [The Battle of Polytopia](https://www.pockettactics.com/best-mobile-strategy-games)
  (the UX quality bar for short turn-based conquest, but a 20-30 minute
  4X); [RISK: Global Domination](https://apps.apple.com/us/app/risk-global-domination/id1051334048)
  (the licensed incumbent); [War.app / Warzone](https://www.warzone.com/mobile)
  (async multi-day depth, 10k+ games a day);
  [Age of Conquest IV](https://play.google.com/store/apps/details?id=com.ageofconquest.app.user.aoc)
  (Risk x Civ, long sessions, mixed reviews of its AI);
  [territorial.io](https://play.google.com/store/apps/details?id=territorial.io)
  (real-time, 500 players). None of them is close on all three of
  turn-based, five minutes, and a moving board.
- **Consequence for the plan**: hazards and centres moved out of their
  own late iteration and into the engine iteration, so the hot-seat
  game plays with them from the first playable build and the AI is
  written against the real board once instead of twice. See
  [ROADMAP.md](ROADMAP.md)'s ordering principle.
- **Confidence, stated honestly**: this came from store listings,
  reviews and coverage, not from playing them. Antiyoy specifically
  should be played before anyone leans harder on this entry — it is
  free, and it is the one result that would change the plan again.

## Scope: small map, short game (2026-09-15)

- **14 isles, not 46 territories.** The original's 46-across-9-continents
  board is a forty-minute game and a large pile of hand-authored data
  before anything is playable. territorial.io's numbers say session
  length is what sells in this genre now. A small board also means the
  AI's search space stays tractable, and the whole map is legible on a
  phone without panning.
- **Under five minutes per game, as a hard design target**, with the
  tuning levers and their preferred order written into
  [RULES.md](RULES.md). Naming the levers in advance is deliberate: the
  reflex when a game feels flat is to add a mechanic, and that reflex is
  what turns a five-minute game into a forty-minute one.
- **Hot-seat before online.** Netcode is where hobby strategy projects
  die — it is more work than the game itself and it cannot be tested
  alone. Local multiplayer makes the game complete and shippable without
  it; online is a post-POC item with no date.

## The AI is the project's real risk (2026-09-15)

- **Timeboxed as an explicit go/no-go gate**, Iteration 4. The original's
  AI is weak by modern standards, so the bar is low — but *below* that
  bar the game is dead, because a single-player conquest game is its
  opponent. If a tolerable opponent isn't working after the iteration's
  budget, that is a signal about the project, not a prompt to spend
  another month.
- **Find that out before drawing a map.** The order in
  [ROADMAP.md](ROADMAP.md) puts a headless rules engine and a playable
  hot-seat board first precisely so the AI can be attempted while the
  sunk cost is still small. Art and map authoring are the cheapest work
  to have wasted and so they come last.
- **The AI plays through the public rules API**, with no privileged
  access to state (`packages/ai` depends only on `packages/rules`). It
  cheats only where a difficulty level says so in the open, if ever.

## Rules: ours, not reverse-engineered (2026-09-15)

- **Every constant in [RULES.md](RULES.md) is a starting point we
  chose.** The originals are closed-source binaries and their real
  formulas aren't published anywhere verifiable. Stating this loudly in
  the spec is a decision, not a disclaimer: it stops a future
  contributor (or a future Claude) from "correcting" a tuned number back
  to something a fan wiki asserts.
- **Kept from the original**: the match rule, the failed-attack penalty,
  hazards, roaming production centres, the AI's collective surrender
  offer. Each earns its place in the spec with a sentence on what it
  does for the game.
- **Dropped: Risk's escalating card trade-in.** It is the engine of the
  famous forty-minute midgame, which is the exact thing the time budget
  exists to prevent.
- **Hazards target the leader on purpose** (the revolt rule), and the
  player should be able to see that they do. A rubber band the player
  can't perceive reads as the game being arbitrary; one they can read as
  the game having an opinion.

## Name, art and IP posture (2026-09-15)

- **Not "Isle Wars", and no original assets.** Unlike the Imperial
  Conquest II work, *Isle Wars Pro* is **not abandonware** — Soleau has
  continued selling the registered version (about $12 by download, per
  the classic-games catalogues). Mechanics are not copyrightable, so the
  ruleset is fair game; the name, map and assets are not.
- **Working title "Islesrisk", from the repo name — treat it as
  provisional.** It reads as a Risk derivative, which is precisely the
  comparison the project is trying not to invite, and "Risk" is
  Hasbro's. A final name should be picked before any public deploy
  (Iteration 7) and this entry amended with it.
- **A courtesy email to Soleau is cheap and clears it properly.** They
  have historically been relaxed about their catalogue being
  redistributed. Optional, since nothing here requires permission, but
  it costs one email to remove all ambiguity.

## Stack: inherited from Geoclick, minus the geography (2026-09-15)

- **SvelteKit + TypeScript, npm workspaces, Vitest, ESLint/Prettier,
  four gates on a pre-push hook, static deploy to Netlify.** Chosen for
  continuity, not on the merits: it is the stack already running in
  Geoclick2027, with known failure modes and a working gate setup to
  copy. Re-deciding a stack per project is how hobby projects spend
  their budget on tooling.
- **No MapLibre GL JS, no PMTiles, no Natural Earth.** Geoclick needs a
  vector-tile renderer because it teaches real geography at arbitrary
  zoom. Islesrisk draws ~14 fictional shapes at one fixed zoom: that is
  an inline SVG, and a tile renderer would be megabytes of dependency
  solving a problem the browser already solves. The board is a game
  board, not a map — isles have no real-world coordinates and adjacency
  is authored, never derived from geometry.
- **Web only for now** (product owner's call, 2026-09-15). Tauri and
  Capacitor are additive in this layout, so deferring them costs
  nothing; scaffolding two more shells before there is a game to install
  costs real time. The pitch is a phone browser with no install, and the
  web build *is* that.
- **No backend, no accounts.** Nothing in a hot-seat game needs a
  server, and a server is a thing to run, pay for and secure. Same
  local-first posture as Geoclick.

## The engine is pure and deterministic (2026-09-15)

- **`applyAction(state, action) => state`, with the RNG seed carried
  inside the state.** No `Math.random`, no `Date.now`, no I/O anywhere in
  `packages/rules`.
- **Three things depend on it, which is why it is a rule and not a
  preference**: a save file, a replay and a bug report become the same
  small object (a seed plus an action list); the AI can evaluate a move
  by playing it against a copy of the state, which ambient randomness
  would make impossible; and the entire ruleset is testable in
  milliseconds without a DOM.
- **Rule checks live in the engine, never in the UI.** The UI's job is
  to decline to *offer* an illegal action; the engine's job is to reject
  it anyway. Anything enforced only in Svelte is a rule the AI does not
  have to obey.
