# Islesrisk — Game specification

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
| `startingArmies` | `1` | Armies on every isle after the deal |
| `distributionPool` | `10` | Extra armies each player places, one at a time, in turn order |
| `shortStackBonus` | `1` | Extra armies for players dealt fewer isles than the leader |

Setup draws entirely from the seeded RNG. Same seed, same deal.

### `reinforcement`

| Key | Default | Meaning |
|---|---|---|
| `perIsleDivisor` | `3` | `floor(islesOwned / divisor)` |
| `minimum` | `3` | Floor, applied after the divisor |
| `archipelagoBonus` | `'authored'` | `'authored'` (map supplies it) \| `'bySize'` \| `'off'` |
| `centreBonus` | `2` | Per production centre owned |

### `combat`

| Key | Default | Meaning |
|---|---|---|
| `attackRule` | `'match'` | `'match'`: attacker must hold **≥** the defender. `'classic'`: any attack allowed. `'threshold'`: attacker ≥ defender × `attackRatio` |
| `attackRatio` | `1.0` | Only read when `attackRule === 'threshold'` |
| `minArmiesToAttack` | `2` | Armies required on the attacking isle |
| `attackerDice` | `{ max: 3, minus: 1 }` | `min(max, armies − minus)` |
| `defenderDice` | `{ max: 2, minus: 0 }` | `min(max, armies − minus)` |
| `ties` | `'defender'` | Who wins an equal pair |
| `failurePenalty` | `'loseIsle'` | `'loseIsle'`: a failed attack that leaves the attacker on 1 army hands the isle to the defender and ends the phase. `'endPhase'` \| `'none'` |
| `capture` | `'diceCount'` | Minimum armies that must advance: `'diceCount'` \| `'all'` \| `'one'` |

> **The match rule.** With the default `attackRule`, the attacking isle
> must hold **at least as many armies as the defending isle**. An isle
> with 4 armies may not attack an isle with 5.

This is the rule the combat model is built around. It removes the
dogpile: you cannot grind a strong isle down with a stream of hopeless
1-army pokes, so stacking a border isle actually defends it, and the
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
| `movesPerTurn` | `1` | Moves between adjacent owned isles, 1 army left behind |
| `chain` | `false` | Whether a moved stack may move again |

### `hazards`

**This block is the product.** A scan of what's shipping on mobile
(DECISIONS.md, "Mobile competitors") found the match rule already taken
and short-session conquest well served, but nothing current doing either
of these: hazards that deliberately lean on the leader, and objectives
that move on their own. Everything else in this spec is table stakes.

Resolved at the end of a turn, in listed order, from the seeded RNG.

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Master switch |
| `flood` | `{ chance: 0.08, lose: 'half' }` | A random isle loses half its armies, rounded down |
| `quake` | `{ chance: 0.05, minArmies: 4, lose: 2 }` | A random isle of at least `minArmies` loses `lose` |
| `revolt` | `{ chance: 0.06, target: 'leader', lose: 'third' }` | The leader's largest isle loses a third |

`revolt.target` may be `'leader'`, `'random'` or `'none'`. Hazards are a
rubber band and the revolt is the one that does the work — it is
deliberately aimed at whoever is winning, and the player should be able
to see that it is. A rubber band the player can't perceive reads as the
game being arbitrary; one they can read as the game having an opinion.

**Invariants, true under every configuration**: a hazard never takes an
isle below 1 army, never eliminates a player, and never changes an
owner. Ownership changes through attack only.

### `centres`

| Key | Default | Meaning |
|---|---|---|
| `count` | `3` | Production centres on the board |
| `bonus` | `2` | Reinforcements per turn to the owner |
| `wanderChance` | `0.25` | Per centre, per turn, to move to a random adjacent isle |

Placed at setup on isles nobody starts adjacent to where possible. They
are the map's moving objectives: they give a board of otherwise
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
| **Bombard** | Remove 2 armies from any enemy isle. Cannot capture. |
| **Shield** | Until the player's next turn, one owned isle cannot be bombarded and wins ties even when attacked at a disadvantage. |
| **Airlift** | Move armies between two *non-adjacent* owned isles, leaving 1 behind. |

No set-collection and no escalating trade-in bonus. That mechanic is the
main engine of Risk's famous forty-minute midgame, and Classic does not
want it — a preset that does can add it later behind a `sets` key.

### `victory` and `surrender`

`victory` is an ordered list of conditions, evaluated at the end of each
turn; the first satisfied ends the game. Classic is a single
`{ kind: 'conquest' }`. The full catalogue — domination, objectives,
economy, survival, turn limit, regicide — and per-player asymmetric
objectives are in [SCENARIOS.md](SCENARIOS.md).

`surrender.offer` (default on, at half the isles *and* half the armies)
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

A player who captured at least one isle draws a card, per `cards.drawOn`.

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
a 14-isle board, with the human taking 10-15 turns. If playtesting runs
long, the levers in order of preference are: reinforcement rate up, map
smaller, hazard frequency up. Adding rules is not on the list.

Other presets set their own targets, and larger boards are explicitly
allowed to be long games — but **Classic is the preset the project is
tuned against**, and a change that improves a large scenario at
Classic's expense is a regression.

## The Classic board: `small-sea`

14 isles in 4 archipelagos, hand-authored, tuned so no archipelago is
trivially defensible:

| Archipelago | Isles | Bonus | Note |
|---|---|---|---|
| North Reach | 4 | 3 | Two entrances, a long line |
| The Chain | 4 | 3 | Strung out, hard to hold whole |
| Warm Shoals | 3 | 2 | Compact, the natural first target |
| The Teeth | 3 | 4 | Three entrances, worth more because it bleeds |

Adjacency is an explicit symmetric sea-lane graph and must be connected.
The board is laid out in its own coordinate space and framed by the
camera, so it is resolution-independent and a window resize reframes
rather than reflows. Hit targets stay generous from the start — a cheap
habit now, an expensive retrofit when Android arrives. Exact isle names,
polygons and lanes are Iteration 1's deliverable, not this document's.

Generated boards use the same `GameMap` structure and pass the same
validator — see [SCENARIOS.md](SCENARIOS.md).

## Rules the engine must enforce (test checklist)

Under Classic:

- An attack from an isle below `minArmiesToAttack` is rejected.
- An attack against a stronger isle is rejected — at equality *and* one
  either side of it.
- A non-adjacent attack, and an attack on your own isle, are rejected.
- Defender wins ties.
- The failure penalty transfers the isle and ends the phase.
- Capture advances at least the dice count and leaves at least 1 behind.
- The reinforcement floor applies to a player down to one isle.
- An archipelago bonus requires *every* isle in it.
- One redeploy per turn; one card per turn; hand caps at `handMax`.
- Eliminating the last opponent ends the game immediately, mid-phase.

Across configurations:

- **No hazard, under any configuration, takes an isle below 1 army,
  eliminates a player, or changes an owner.**
- `attackRule: 'classic'` permits the attacks `'match'` rejects, and
  changes nothing else.
- Disabling a subsystem (`hazards`, `centres`, `cards`) removes it
  entirely: no phase, no draw, no UI affordance, no crash.
- Every preset in SCENARIOS.md plays 100 headless games to a legal
  terminal state without throwing.
- **Determinism**: same seed + same rule set + same map + same actions ⇒
  identical final state. The property test that guards everything above.
