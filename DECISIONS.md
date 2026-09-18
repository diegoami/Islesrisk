# Malpaco — Decisions

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
  **Struck the same day**: the retarget to desktop Godot gives this up
  entirely — there is no browser build, and scenarios travel as files,
  not links. It was a real advantage and it is gone; what replaces it is
  in "Gorgeous, and what that costs". The rest of this entry — the
  match rule being taken, the hazards and centres being unoccupied —
  still holds, and on desktop the competitive set changes as noted
  there.
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

## What a hundred games say (2026-09-18, Iteration 2)

The first measurements of the rules actually running. 100 Classic games,
four players, played end to end headless. Every constant in RULES.md was
declared a guess; these are the numbers that test the guesses.

| | Measured | RULES.md asks for |
|---|---|---|
| Games resolving within 300 rounds | 78% | — |
| Average rounds to a winner | 55.8 | 10-15 turns |
| Hazards per player-turn | 0.105 | "roughly once every other turn" |
| Centre moves per player-turn | 0.349 | 0.75 before no-ops |
| Attacks per player-turn | 2.16, 26% capturing | — |

- **Classic runs about four times longer than its own target.** Not a
  crisis: the target is a design intention and the constants were never
  tuned. It is recorded here so Iteration 10 starts from evidence instead
  of from the same guesses.
- **Hazards fire about five times less often than intended.** The three
  chances sum to 0.19 per turn before the no-ops — a quake needs a
  province of four armies, a revolt needs a leader holding more than one.
  Since the hazards are the differentiator, this is the number most worth
  getting right.
- **The lever list in RULES.md was backwards, and is corrected.** It said
  to raise the reinforcement rate to shorten a game, by analogy with Risk.
  Under the match rule the opposite holds: more armies means bigger stacks,
  and a stack an attacker must *match* is a stack that cannot be attacked
  at all. A probe bears it out — under arbitrary play Classic finished 0%
  of games, while dropping the reinforcement floor to 1 and the divisor to
  4 finished 55%. A wrong lever in a spec is worse than a missing one,
  because someone will follow it.
- **"It doesn't resolve" was nearly the wrong conclusion.** Under purely
  arbitrary play *no* Classic game finished, and the first reading was that
  the rules could not resolve a game. A mover that simply concentrates
  force and attacks where it is strongest finishes 78% of them. The lesson
  for Iteration 4: a measurement of the rules is only as good as the player
  driving it, and the harness numbers must always say which driver produced
  them.
- **Army inflation is the mechanism behind all of it.** With hazards off,
  the board carries ~3,400 armies by round 300; with hazards on, ~750. The
  hazards are doing most of the work of keeping the board playable, which
  is an argument for their importance and a warning about what happens in
  a preset that turns them off.

## GDScript stays, revisited on schedule (2026-09-18, Iteration 2)

ARCHITECTURE.md scheduled exactly one revisit of the language choice, at
the end of Iteration 2, while `core/` was still small enough to move. It
is done, and the answer is to stay.

- `core/` is about 1,700 lines of statically typed GDScript and has been
  comfortable to write and read. The warnings-as-errors settings caught
  real mistakes at parse time.
- The whole suite — 79 tests including 100 full games — runs headless in
  seconds. Nothing is near a performance limit, and the AI's search in
  Iteration 4 is the first thing that might be; the state is a handful of
  dictionaries and clones cheaply.
- C# would cost the editor integration and add a toolchain (the cloud
  container has no .NET SDK), for benefits that only show up in a much
  larger codebase.
- **Not revisited again.** The scheduled decision was the point; reopening
  it later without new evidence is how a project spends its budget on
  tooling instead of on the game.

## The board is islands with provinces, not a scatter of islands (2026-09-18)

Corrected by the product owner after Iteration 1 shipped the wrong shape.

- **What was wrong.** The first board made every territory its own small
  island floating in open water — fourteen of them in a ring. That is not
  *Isle Wars*, and it is not Risk or Imperialism 2 either. The research
  had already said so — "46 countries divided between 9 continents" — and
  was read as nine loose groups of separate islands rather than nine
  landmasses, each subdivided.
- **What it is.** A handful of **islands**, each divided into
  **provinces**. The province is the unit of ownership; the island is the
  bonus group, the Risk "continent". Classic is four islands and fourteen
  provinces.
- **Two kinds of adjacency, kept apart.** A **border** is land and always
  joins provinces on the same island; a **sea lane** crosses water to
  another island. The rules treat them alike today, and `neighbours()`
  returns the union so most code need not care. They are stored separately
  anyway, because making a water crossing harder is the most obvious rule
  a preset might want, and a map that has lost the distinction cannot get
  it back. The validator enforces both directions of the rule.
- **The geometry changed with it.** Provinces *tile* a landmass rather
  than floating separately, so a board is now a partition, not a scatter
  of blobs — which is why generation has to go islands-first: outline the
  landmass, then subdivide it with clipped Voronoi. Generating cells and
  grouping them afterwards is precisely the mistake that produced the
  wrong board.
- **Cost of the correction**: one day, one iteration's data and renderer,
  no rules code — the engine had not been written yet. Worth noting in
  favour of the specs-first order: this landed while there was still
  almost nothing to throw away.

## Scope: small map, short game (2026-09-15, scoped to the Classic preset the same day)

**Amended**: the product owner asked for variable map sizes, custom
rules and multiple victory conditions (see "Generic engine, Classic
preset" below). Everything in this entry still holds — but it now
describes **Classic**, the default preset and the tuning target, rather
than the only game the engine can play. Large slow boards are legal and
explicitly supported; they are simply not what the project is tuned
against.

- **14 provinces, not 46 territories.** The original's 46-across-9-continents
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

## Generic engine, Classic preset (2026-09-15)

The product owner's direction: reproduce *Isle Wars Pro*'s general
gameplay, but with random map generation, scenario creation,
configurable opponent counts, custom rules, varying sizes and different
victory conditions. That is a bigger project than the one the first
specs described, and this entry records how it is being absorbed rather
than allowed to become unbounded.

- **Generic in the data model from day one; generic in the UI last.**
  This is the whole shape of the response. A rule that lives in a
  `RuleSet` field costs a table lookup and one test; the same rule
  discovered later, compiled into a dozen call sites and an AI
  evaluation function, costs a rewrite. A *visual scenario editor*, on
  the other hand, is a self-contained pile of UI work that nothing else
  depends on — so the engine is fully data-driven from Iteration 2, and
  the editor is post-POC. "Creating scenarios" is satisfied in the POC
  by a documented JSON format, built-in scenarios and share links; the
  editor makes that pleasant, later.
- **Presets are the player-facing surface, not toggles.** The start
  screen offers a preset, a size and an opponent count. Every option
  added to that screen is paid for by every new player who has to read
  past it, and a conquest game's first thirty seconds are where it is
  won or lost. The generality is reachable through scenarios, not
  through a settings wall.
- **Classic stays the tuning target.** Five minutes, 14 provinces, four
  players. A change that improves a 50-province scenario at Classic's
  expense is a regression, and RULES.md says so. Without one preset
  holding that line, "configurable" quietly becomes "tuned for nothing".
- **No rule may be a compiled-in assumption.** Stated in RULES.md and
  ARCHITECTURE.md, enforced by cross-configuration tests. The AI is the
  likeliest place to violate this and the hardest place to notice it.
- **The AI got materially harder, and this is the real cost.** An
  opponent for one 14-province board with one rule set is a tractable
  problem. An opponent that must play acceptably at 12 provinces and 50, with
  the match rule on or off, with hazards on or off, and toward six
  different victory conditions, is a substantially bigger one — a
  `domination` game and a `survival` game want different behaviour from
  the same code. **Mitigation**: the AI reads the rule set and the active
  victory conditions as inputs; competence is *claimed* only for the
  shipped presets and measured per-preset by the tournament harness;
  other configurations are best-effort and say so. Iteration 4 remains
  the go/no-go, and its bar is Classic — a project that cannot field an
  opponent on its own default board does not get to attempt the general
  case.
- **Generated and authored maps are one type, one validator.** Two map
  systems would diverge within a month and every downstream consumer
  would grow a branch. The generator is a producer of the existing
  structure, nothing more (SCENARIOS.md).
- **Competitive note, since it cuts against the pivot**: an options
  surface is not a differentiator. War.app has thousands of community
  maps, Age of Conquest ships hundreds, Lux Delux has had pluggable AI
  for two decades — the deep end of this genre is *made of* options, and
  arriving with a configuration screen impresses nobody. Procedural
  generation paired with the hazards is less common and is worth having;
  the differentiator is still the moving board (see "Mobile
  competitors"). Genericity here is justified as an *engine* property —
  it makes the thing worth building as a piece of software, and it makes
  presets cheap to try — not as a marketing claim.
- **The honest cost**: roughly double the original scope, and one new
  failure mode — a configurable engine that is excellent at nothing.
  Classic-as-tuning-target and the Still Waters A/B preset (SCENARIOS.md)
  are the two guards against it.

## The AI is the project's real risk (2026-09-15)

- **Timeboxed as an explicit go/no-go gate**, Iteration 4. The original's
  AI is weak by modern standards, so the bar is low — but *below* that
  bar the game is dead, because a single-player conquest game is its
  opponent. If a tolerable opponent isn't working after the iteration's
  budget, that is a signal about the project, not a prompt to spend
  another month.
- **The gate is judged on Classic only.** The generic-engine pivot makes
  the full problem much larger (see that entry), and it would be easy to
  fail the gate on the general case while the actual game is fine. The
  question at Iteration 4 is the narrow one: is the opponent tolerable
  on the default board, under the default rules.
- **Find that out before drawing a map.** The order in
  [ROADMAP.md](ROADMAP.md) puts a headless rules engine and a playable
  hot-seat board first precisely so the AI can be attempted while the
  sunk cost is still small. Art and map authoring are the cheapest work
  to have wasted and so they come last.
- **The AI plays through the public rules API**, with no privileged
  access to state (`core/ai` depends only on `core/rules`). It
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

## Godot and the desktop (2026-09-15)

The product owner's direction: target the desktop, build it in Godot,
make it beautiful. This supersedes the web stack outright.

- **Godot 4.7.x, GDScript, statically typed.** 4.7.2 is current stable
  (2026-08-18). Typed GDScript is now within noise of C# for game logic;
  GDScript wins on editor integration, iteration speed, and the fact
  that most of the ecosystem's addons and answers assume it. C# would
  win past ~10k lines and on external tooling — a real argument for an
  engine-heavy project — so the decision is scheduled for one explicit
  revisit at the end of Iteration 2, while `core/` is still small enough
  to move. Not before, and not after.
- **Desktop first, Android later, no browser.** Chosen by the product
  owner. Worth noting what it costs, since earlier entries were built on
  it: the no-install pitch and URL-shared scenarios are gone, and with
  them the one axis where this project beat an installed app. Android is
  post-POC and the only concession made for it now is cheap habits —
  generous hit targets, nothing depending on hover.
- **The purity boundary is enforced by a test, not by discipline.**
  `core/` is plain `RefCounted` GDScript with no scene tree, no file I/O
  and no global RNG, and a gate greps for the forbidden symbols. In a
  game engine the temptation to reach for `get_tree()` from rule code is
  constant, and the boundary is what makes the engine testable,
  replayable and AI-searchable at all.
- **Integer arithmetic in the rules.** Godot's `RandomNumberGenerator`
  reproduces integer draws identically across platforms; float
  accumulation does not. A replay that desyncs between the Windows and
  Linux builds would void every determinism guarantee, and this is
  cheaper to decide now than to debug later.
- **JSON, never Godot `Resource` files, for anything loaded.** `.tres`
  can carry embedded scripts, so `ResourceLoader` on a shared scenario
  is arbitrary code execution. Scenario sharing is precisely that path.

## Gorgeous, and what that costs (2026-09-15)

"I want to make a gorgeous game" is now a project goal, and painterly
illustrated 2D is the register (product owner's choice over stylized 3D
and 2.5D).

- **The beauty has to be a system, not artwork.** This is the binding
  constraint, and it comes from pairing "gorgeous" with "random maps":
  the generator invents boards at runtime, so nothing can be
  hand-illustrated per map. Water shader, coastline treatment, palette,
  lighting, weather, motion — applied to arbitrary polygons. *Bad North*
  and *ISLANDERS* look superb over procedural islands for exactly this
  reason, and they are the reference points.
- **An art idea that only works on a hand-placed board is not usable.**
  Stated as the test every visual decision must pass, and enforced by
  validating the art system against generated maps in Iteration 6 rather
  than hoping it survives.
- **The look is a spike, not a polish phase.** Iteration 5, straight
  after the AI gate. Art left until last is art that never happens, and
  a "gorgeous" goal that first gets attention at Iteration 10 is a
  wish. The spike also produces the artifact the commercial decision is
  made on.
- **Hazards are where the art direction and the design differentiator
  meet**, which is the happiest accident in this project so far. The
  mechanic nobody else has is also the most spectacular thing on screen:
  a flood is a storm crossing the map, a quake cracks a shore, a revolt
  raises smoke. Both arguments now point at the same feature.
- **Ownership readability outranks atmosphere.** Colour identifies a
  player; a colour-blind-safe palette and a non-colour ownership cue are
  requirements, not polish. A beautiful board nobody can read is a
  failed board.
- **This is the first pivot that improved the market case.** Desktop
  Risk-likes are overwhelmingly functional-looking — Age of Conquest IV,
  Lux Delux, even RISK: Global Domination are UI over a map. A genuinely
  beautiful conquest game is a sharper differentiator than the ruleset
  ever was. It is also the most expensive thing to fake, which is
  exactly why it differentiates.
- **The cost, plainly**: art is now a critical path rather than a
  finishing pass, the largest single unknown in the schedule, and the
  skill least protected by the test suite. Nothing in the gates can tell
  you the game looks bad.

## Commercial intent: decide at the slice (2026-09-15)

- **Build as if commercial; decide after Iteration 5.** The product
  owner's call. Every doc previously said "portfolio project, not
  commercial"; that is now an open question answered by looking at the
  vertical slice.
- **What "as if commercial" costs now, and it is little**: asset
  provenance tracked in an ASSETS.md ledger from the first asset (a
  licence you cannot reconstruct later is a rewrite of the art), a name
  that is genuinely ours, and no borrowed-for-now placeholder that would
  be awkward to ship. That is the whole discipline.
- **What it does not mean**: no store pages, no marketing, no monetary
  scope creep before there is a game. The decision is deliberately
  scheduled for the moment there is something to judge.
- **If it does go commercial, two things get sharper**: the IP posture
  below, and the AI quality bar — a paid opponent is held to a standard
  a free one is not.

## Name, art and IP posture (2026-09-15)

- **Sharper now that a commercial release is possible** (see "Commercial
  intent"). A free portfolio piece and a paid product built on the same
  ruleset are not the same risk, and the name matters more in the second
  case than the first.
- **Not "Isle Wars", and no original assets.** Unlike the Imperial
  Conquest II work, *Isle Wars Pro* is **not abandonware** — Soleau has
  continued selling the registered version (about $12 by download, per
  the classic-games catalogues). Mechanics are not copyrightable, so the
  ruleset is fair game; the name, map and assets are not.
- **The name is "Malpaco"** (product owner's choice, 2026-09-17).
  Esperanto for "un-peace" — `paco` is peace, `mal-` is the prefix that
  reverses a word, and it is the most recognisably Esperanto thing that
  could sit on a store page. Stress falls on the penultimate syllable
  and `c` is /ts/, so: *mal-PAH-tso*. Checked clear on Steam and itch.
- **Why it beat the alternatives.** It names the *feeling* rather than
  describing the board — the state this game leaves you in, never
  settled, never consolidated, which is what the hazards and the roaming
  centres are for. The earlier candidates split into naming the setting
  (Insularo, "island") or the thesis in English (Saltcrown);
  Malpaco does the second in a language that owes nothing to the genre's
  vocabulary.
- **"Eterna Malpaco" was considered and the first word dropped.**
  *Eternal* is grand-strategy vocabulary — it promises a forty-hour
  campaign to anyone reading a store page, which is the exact
  expectation Classic's five-minute target is built to avoid. There is a
  real reading where "eternal un-peace" means *the board never settles*,
  and that reading is the design exactly; it just isn't the one a
  stranger gets in two seconds. "Eterna" is also the crowded half in
  search. Recorded here so the idea isn't re-proposed without the
  counter-argument attached.
- **"Islesrisk" is retired.** It named the comparison the project spends
  its whole design avoiding, and "Risk" is Hasbro's.
- **Still open**: a fluent Esperantist should sanity-check the name
  before it goes on a store page. The grammar is not in doubt; how it
  *reads* to someone who speaks the language is worth an hour of
  someone's time.
- **A courtesy email to Soleau is cheap and clears it properly.** They
  have historically been relaxed about their catalogue being
  redistributed. Optional, since nothing here requires permission, but
  it costs one email to remove all ambiguity.

## Stack: SvelteKit, inherited from Geoclick — SUPERSEDED (2026-09-15)

Replaced the same day by "Godot and the desktop" below. Kept as a
one-line record rather than deleted, because the reasoning that was
*wrong* here is instructive: the stack was chosen for continuity with
Geoclick2027 rather than on the merits, which is a good default right
up to the moment the product's target changes. It also carried "web
only for now", which the retarget reversed outright.

- **What survived the change**: no backend, no accounts. Nothing in a
  hot-seat game needs a server, and a server is a thing to run, pay for
  and secure.
- **What survived intact and is the real lesson**: RULES.md and
  SCENARIOS.md needed almost no edits, because they specify *data*, not
  a program. The specs that described behaviour outlived two pivots;
  the spec that described a stack did not survive one.

## The engine is pure and deterministic (2026-09-15)

- **`Rules.apply_action(state, action) -> state`, with the RNG seed *and
  the resolved rule set* carried inside the state.** No global `randi()`,
  no `Time.`, no I/O anywhere in `core/` — and a test that greps for
  them, because in a game engine this boundary erodes by accident. Determinism is over
  the quadruple (seed, rule set, map, actions) — which is why the rule
  set is stored inline in a save rather than referenced by name: a
  preset that gets tuned must not be able to change a game already
  played or in progress.
- **Three things depend on it, which is why it is a rule and not a
  preference**: a save file, a replay and a bug report become the same
  small object (a seed plus an action list); the AI can evaluate a move
  by playing it against a copy of the state, which ambient randomness
  would make impossible; and the entire ruleset is testable in
  milliseconds without a DOM.
- **Rule checks live in the engine, never in the UI.** The UI's job is
  to decline to *offer* an illegal action; the engine's job is to reject
  it anyway. Anything enforced only in a scene or a UI script is a rule
  the AI does not have to obey.
