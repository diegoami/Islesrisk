# Malpaco — Game specification

The authoritative description of how a game plays, and the contract
`core/rules` must satisfy. Written to be read by a person and testable
line by line: every rule below should end up as at least one gdUnit4
case.

Scenario structure, map generation and the victory-condition catalogue
have their own document: [SCENARIOS.md](SCENARIOS.md).

## Provenance, and an honest warning about the numbers

The *shape* of this ruleset comes from Soleau Software's **Isle Wars**
(1994) and its Win9x sequel **Isle Wars Pro** — the match rule, the
hazards, the production centres, the three-card idea. Game mechanics
aren't copyrightable and this is a re-take, not a reproduction (see
[DECISIONS.md](DECISIONS.md), "Name, art and IP posture").

**The constants here are ours.** The originals are closed-source
binaries; their exact reinforcement formula, bonus table, hazard
frequencies and card triggers are not published anywhere verifiable, and
nothing in this document was reverse-engineered from them. Every number
below is a starting point, to be tuned by playing. Do not let a future
reader mistake these for the original's values, and do not "restore"
them to something a wiki claims.

## How to read this document: everything here is a default

The engine is **data-driven**. There is no rule below that is compiled
in: each one is a field of a `RuleSet`, and a game is played by handing
the engine a `RuleSet` alongside the map and the players. What this
document describes is the **Classic** preset — the defaults, the tuning
target, and the configuration every example uses.

That has one consequence worth stating up front, because it constrains
every line of engine code: **no rule may be expressed as an assumption.**
"The attacker needs at least as many armies" is not a fact about the
game, it is `combat.attackRule === 'match'`. Code that assumes otherwise
— including the AI's — is a bug, and the property tests exist to catch
it (see "Rules the engine must enforce").

## The RuleSet

One serializable object, versioned, with no functions in it, so a rule
set can live in a scenario file, a URL or a save game. Defaults shown
are Classic.

### `setup`

| Key | Default | Meaning |
|---|---|---|
| `deal` | `'roundRobin'` | `'roundRobin'` \| `'random'` \| `'authored'` (scenario supplies ownership) |
| `startingArmies` | `1` | Armies on every province after the deal |
| `distributionPool` | `10` | Extra armies each player places, one at a time, in turn order |
| `shortStackBonus` | `1` | Extra armies for players dealt fewer provinces than the leader |

Setup draws entirely from the seeded RNG. Same seed, same deal.

### `reinforcement`

| Key | Default | Meaning |
|---|---|---|
| `perProvinceDivisor` | `3` | `floor(provincesOwned / divisor)` |
| `minimum` | `3` | Floor, applied after the divisor |
| `islandBonus` | `'authored'` | `'authored'` (map supplies it) \| `'bySize'` \| `'off'` |
| `centreBonus` | `2` | Per production centre owned |

### `combat`

| Key | Default | Meaning |
|---|---|---|
| `attackRule` | `'match'` | `'match'`: attacker must hold **≥** the defender. `'classic'`: any attack allowed. `'threshold'`: attacker ≥ defender × `attackRatio` |
| `attackRatio` | `1.0` | Only read when `attackRule === 'threshold'` |
| `minArmiesToAttack` | `2` | Armies required on the attacking province |
| `attackerDice` | `{ max: 3, minus: 1 }` | `min(max, armies − minus)` |
| `defenderDice` | `{ max: 2, minus: 0 }` | `min(max, armies − minus)` |
| `ties` | `'defender'` | Who wins an equal pair |
| `failurePenalty` | `'loseProvince'` | `'loseProvince'`: a failed attack that leaves the attacker on 1 army hands the province to the defender and ends the phase. `'endPhase'` \| `'none'` |
| `capture` | `'diceCount'` | Minimum armies that must advance: `'diceCount'` \| `'all'` \| `'one'` |

> **The match rule.** With the default `attackRule`, the attacking province
> must hold **at least as many armies as the defending province**. An province
> with 4 armies may not attack a province with 5.

This is the rule the combat model is built around. It removes the
dogpile: you cannot grind a strong province down with a stream of hopeless
1-army pokes, so stacking a border province actually defends it, and the
interesting question becomes *where* to spend a stack rather than *how
many* attacks to make.

It is **not** the game's differentiator, and an earlier draft of this
document wrongly said it was. Antiyoy — free, open source, on Android —
inherits an equivalent rank rule from *Slay*. The hazards and the
roaming centres are the part nobody else is doing. See
[DECISIONS.md](DECISIONS.md), "Mobile competitors".

The failure penalty is what makes the match rule bite: an attack is a
commitment with a real downside, not a free roll of the dice. Turning
`attackRule` to `'classic'` without also turning the penalty off
produces a harsher game than Risk, not a gentler one — a legitimate
preset, but not an accident to stumble into.

### `redeploy`

| Key | Default | Meaning |
|---|---|---|
| `movesPerTurn` | `1` | Moves between adjacent owned provinces, 1 army left behind |
| `chain` | `false` | Whether a moved stack may move again |

### `hazards`

**This block is the product.** A scan of what's shipping on mobile
(DECISIONS.md, "Mobile competitors") found the match rule already taken
and short-session conquest well served, but nothing current doing either
of these: hazards that deliberately lean on the leader, and objectives
that move on their own. Everything else in this spec is table stakes.

Resolved at the end of a turn, in listed order, from the seeded RNG.

**Measured, Iteration 2**: 0.105 hazards per player-turn, against the
"roughly once every other turn" this section asks for — about five times
too rare. The three chances sum to 0.19 before the no-ops (a quake needs a
province of four armies, a revolt needs a leader with more than one).
Another number for Iteration 10.

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Master switch |
| `flood` | `{ chance: 0.08, lose: 'half' }` | A random province loses half its armies, rounded down |
| `quake` | `{ chance: 0.05, minArmies: 4, lose: 2 }` | A random province of at least `minArmies` loses `lose` |
| `revolt` | `{ chance: 0.06, target: 'leader', lose: 'third' }` | The leader's largest province loses a third |

`revolt.target` may be `'leader'`, `'random'` or `'none'`. Hazards are a
rubber band and the revolt is the one that does the work — it is
deliberately aimed at whoever is winning, and the player should be able
to see that it is. A rubber band the player can't perceive reads as the
game being arbitrary; one they can read as the game having an opinion.

**Invariants, true under every configuration**: a hazard never takes an
province below 1 army, never eliminates a player, and never changes an
owner. Ownership changes through attack only.

### `centres`

| Key | Default | Meaning |
|---|---|---|
| `count` | `3` | Production centres on the board |
| `bonus` | `2` | Reinforcements per turn to the owner |
| `wanderChance` | `0.25` | Per centre, per turn, to move to a random adjacent province |

Placed at setup on provinces spread as far apart as the board allows,
chosen from the seeded RNG. They are the map's moving objectives: they give a board of otherwise
interchangeable rocks *places worth wanting*, and stop the wanting from
being a one-time land grab. Of everything in this spec they are the
single most distinctive mechanic — no current mobile conquest game has
an objective that relocates itself — so if a tuning pass has to choose
what to protect, it protects these.

### `cards`

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Master switch |
| `deck` | `{ bombard: 8, shield: 6, airlift: 6 }` | Composition; reshuffled from the discard when empty |
| `drawOn` | `'capture'` | `'capture'` \| `'turn'` \| `'never'` |
| `handMax` | `5` | A draw into a full hand is discarded |
| `perTurn` | `1` | Cards playable per turn |

| Card | Effect |
|---|---|
| **Bombard** | Remove 2 armies from any enemy province. Cannot capture. |
| **Shield** | Until the player's next turn, one owned province cannot be bombarded and wins ties even when attacked at a disadvantage. |
| **Airlift** | Move armies between two *non-adjacent* owned provinces, leaving 1 behind. |

No set-collection and no escalating trade-in bonus. That mechanic is the
main engine of Risk's famous forty-minute midgame, and Classic does not
want it — a preset that does can add it later behind a `sets` key.

### `victory` and `surrender`

`victory` is an ordered list of conditions, evaluated at the end of each
turn; the first satisfied ends the game. Classic is a single
`{ kind: 'conquest' }`. The full catalogue — domination, objectives,
economy, survival, turn limit, regicide — and per-player asymmetric
objectives are in [SCENARIOS.md](SCENARIOS.md).

`surrender.offer` (default on, at half the provinces *and* half the armies)
makes the AI players collectively offer to concede when the human's win
is obvious. Lifted from *Isle Wars Pro*'s best idea: a conquest game is
decided long before it is over, and making the player grind it out is
the commonest way these games waste their players' time.

## A turn

Four phases, always in this order: **reinforce → attack → redeploy →
hazards**. Hazards resolve at the *end* of a turn, so a player always
sees the board they are about to act on. Phases the configuration
empties (no cards, no hazards) are skipped, not shown as empty.

Attack resolution, one round per declared attack:

- Attacker and defender roll per `combat.attackerDice` /
  `defenderDice`. Both sorted descending, paired, one army lost per pair
  by the lower roll; `combat.ties` breaks equals.
- At 0 defending armies the attacker captures, advancing at least
  `combat.capture` armies and leaving at least 1 behind.
- `combat.failurePenalty` applies as described above.

A player who captured at least one province draws a card, per `cards.drawOn`.

## The board: islands divided into provinces

A board is a handful of **islands**, each divided into **provinces**. The
province is the unit of ownership — armies sit on it and it changes hands —
and the island is the bonus group. That is the shape of *Isle Wars* (46
countries across 9 continents), and of Risk and Imperialism 2: a few
landmasses, subdivided. It is not a scatter of one-province islands.

Adjacency comes in two kinds, and they are kept apart:

- a **border** is land, and always joins two provinces on the same island;
- a **sea lane** crosses water to a province on another island.

Both are authored data, never derived from the shapes. The rules treat
them alike for now — an attack is an attack — but the distinction is
carried in the map because crossing water is the obvious thing a preset
might one day want to make harder, and a map that has lost the
distinction cannot get it back.

## Players

Two to eight, any mix of human and AI, each with a colour, an optional
AI policy and difficulty, and optionally their own victory conditions.
The default game is one human and three AI, which is Classic's shape and
*Isle Wars*'.

Hot-seat swaps humans in for any seat. Nothing in the engine knows the
difference between a human and an AI seat; both submit actions through
the same API.

## Time budget

Classic targets a **complete four-player game in under five minutes** on
a 14-province board, with the human taking 10-15 turns.

**Measured, Iteration 2**: 55.8 rounds on average, with 78% of games
resolving at all within 300 (100 games, greedy play — DECISIONS.md, "What
a hundred games say"). That is roughly four times the target. The numbers
in this document have always been declared guesses; these are the first
measurements, and they say the guesses are wrong. Tuning is Iteration 10's
job, not something to patch here piecemeal.

If a game runs long, the levers in order of preference are: **reinforcement
rate down**, map smaller, hazard frequency up. Adding rules is not on the
list.

> An earlier draft of this section said *reinforcement rate **up***, by
> analogy with Risk, where more armies means faster resolution. Measurement
> says the opposite holds here, and the match rule is why: more armies means
> bigger stacks, and a stack an attacker must match is a stack that cannot
> be attacked. Raising reinforcement lengthens a Malpaco game. Corrected
> because a lever list is an instruction, and this one pointed the wrong
> way.

Other presets set their own targets, and larger boards are explicitly
allowed to be long games — but **Classic is the preset the project is
tuned against**, and a change that improves a large scenario at
Classic's expense is a regression.

## The Classic board: `small-sea`

Four islands, 14 provinces, tuned so no island is trivially defensible.
**Malgranda Maro**, the Small Sea.

| Island | Provinces | Bonus | Sea entrances | Note |
|---|---|---|---|---|
| Norda Vasto | 4 | 3 | 2 | The largest; a long way round by land |
| La Spino | 4 | 3 | 2 | Narrow, easily cut in half |
| Varmaj Sabloj | 3 | 2 | 3 | Small and cheap — the natural first target |
| La Dentoj | 3 | 4 | 3 | Worth more because it bleeds from three sides |

**Every name on the board is Esperanto**, as the game's own name is. All of
them happen to be diacritic-free, so a province's id is simply its name
lowercased — there is no transliteration step to get wrong. The four
nations are **Blua**, **Sukcena**, **Verda** and **Purpura**; their
initials B, S, V and P are the non-colour ownership cue, which is why the
violet seat is *Purpura* and not *Viola* — that would have collided with
*Verda*.

| Island | | Provinces |
|---|---|---|
| **Norda Vasto** | the northern expanse | Sulo (gannet), Frostkabo (frost cape), Longa Strando (long strand), Ventflanko (windward) |
| **La Spino** | the spine | Amboso (anvil), Hoko (hook), Spindelo (spindle), Vosto (tail) |
| **Varmaj Sabloj** | the warm sands | Sablobenko (sandbar), Laguno (lagoon), Konko (shell) |
| **La Dentoj** | the teeth | Dentego (fang), Splito (splinter), Akrigilo (whetstone) |

**Sea entrances** — the number of lanes reaching an island from elsewhere
— is what actually decides how defensible it is. A large bonus behind
three crossings is a trap worth setting, which is why The Teeth pay best.

Borders and sea lanes are both explicit, symmetric and validated. The
board is laid out in its own coordinate space and framed by the camera,
so it is resolution-independent and a window resize reframes rather than
reflows. Hit targets stay generous from the start — a cheap habit now, an
expensive retrofit when Android arrives.

Generated boards use the same `GameMap` structure and pass the same
validator — see [SCENARIOS.md](SCENARIOS.md).

## Rules the engine must enforce (test checklist)

Under Classic:

- An attack from a province below `minArmiesToAttack` is rejected.
- An attack against a stronger province is rejected — at equality *and* one
  either side of it.
- A non-adjacent attack, and an attack on your own province, are rejected.
- Defender wins ties.
- The failure penalty transfers the province and ends the phase.
- Capture advances at least the dice count and leaves at least 1 behind.
- The reinforcement floor applies to a player down to one province.
- An island bonus requires *every* province in it.
- One redeploy per turn; one card per turn; hand caps at `handMax`.
- Eliminating the last opponent ends the game immediately, mid-phase.

Across configurations:

- **No hazard, under any configuration, takes a province below 1 army,
  eliminates a player, or changes an owner.**
- `attackRule: 'classic'` permits the attacks `'match'` rejects, and
  changes nothing else.
- Disabling a subsystem (`hazards`, `centres`, `cards`) removes it
  entirely: no phase, no draw, no UI affordance, no crash.
- Every preset in SCENARIOS.md plays 100 headless games to a legal
  terminal state without throwing.
- **Determinism**: same seed + same rule set + same map + same actions ⇒
  identical final state. The property test that guards everything above.
