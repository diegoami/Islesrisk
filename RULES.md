# Islesrisk — Game specification

The authoritative description of how a game plays, and the contract
`packages/rules` must satisfy. Written to be read by a person and
testable line by line: every rule below should end up as at least one
Vitest case.

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
below is a starting point chosen to make a five-minute game work, to be
tuned by playing. Do not let a future reader mistake these for the
original's values, and do not "restore" them to something a wiki claims.

## Players and victory

Four players: one human, three AI in the default game (hot-seat swaps
humans in for any of them). A player is **eliminated** when they own no
isles. The last player standing wins.

A player may **concede** at any time. When a human holds more than half
the board *and* more than half the total armies, the AI players offer a
collective surrender, which the human may accept for an immediate win or
decline to play it out. This is lifted directly from *Isle Wars Pro*'s
best idea: the endgame of a conquest game is a foregone conclusion long
before it is over, and making the player grind it out is the single most
common way these games waste their players' time.

## Setup

1. Isles are dealt round-robin from a shuffled order until every isle
   has an owner. With 14 isles and 4 players the split is 4/4/3/3; the
   two players short get one extra starting army as compensation.
2. Every isle starts with **1** army.
3. Each player distributes **10** further armies across the isles they
   own, one at a time, in turn order. AI players do this with their
   normal placement policy.

Setup draws entirely from the seeded RNG. Same seed, same deal.

## A turn

Four phases, always in this order: **reinforce → attack → redeploy →
hazards**.

### 1. Reinforce

The player receives:

- `floor(islesOwned / 3)`, minimum **3**; plus
- the `bonus` of every archipelago they hold **entirely**; plus
- **+2** per production centre they own (see Hazards).

They place those armies on isles they own, any distribution.

### 2. Attack

Any number of attacks, in any order, or none.

An attack is declared from an isle the player owns holding **at least 2
armies**, against an adjacent isle owned by someone else.

> **The match rule.** The attacking isle must hold **at least as many
> armies as the defending isle**. An isle with 4 armies may not attack an
> isle with 5.

This is the rule the combat model is built around. It removes the
dogpile: you cannot grind a strong isle down with a stream of hopeless
1-army pokes, so stacking a border isle actually defends it, and the
interesting question becomes *where* to spend a stack rather than *how
many* attacks to make.

It is **not** the game's differentiator, and an earlier draft of this
document wrongly said it was. Antiyoy — free, open source, on Android —
inherits an equivalent rank rule from *Slay*. The hazards and the
roaming centres below are the part nobody else is doing. See
[DECISIONS.md](DECISIONS.md), "Mobile competitors".

Resolution, one round per declared attack:

- Attacker rolls `min(3, attackingArmies - 1)` dice; defender rolls
  `min(2, defendingArmies)` dice. Both sorted descending, paired up, one
  army lost per pair by the lower roll; **defender wins ties**.
- If the defending isle reaches 0 armies, the attacker captures it and
  must move at least the number of dice they rolled, leaving at least 1
  army behind.
- **Failure penalty.** If an attack leaves the *attacking* isle with
  exactly 1 army and the defender still holds theirs, the attacking isle
  is **lost to the defender** (they garrison it with 1 army) and the
  attacker's attack phase ends immediately.

That penalty is the second borrowed idea and it is what makes the match
rule bite: an attack is a commitment with a real downside, not a free
roll of the dice.

A player who captured at least one isle this turn draws **one card** at
the end of the phase (see Cards). Maximum hand size **5**; a draw into a
full hand is discarded.

### 3. Redeploy

One move: any number of armies from one owned isle to an adjacent owned
isle, leaving at least 1 behind. One move per turn, not a chain.

### 4. Hazards

**This phase is the product.** A scan of what's actually shipping on
mobile (DECISIONS.md, "Mobile competitors") found the match rule
already taken and short-session conquest well served, but nothing
current doing either of the things below: hazards that deliberately lean
on the leader, and objectives that move on their own. Everything else
here is table stakes; this is the reason to build it.

Rolled at the end of the turn, resolved in this order, all from the
seeded RNG. Together they should fire roughly **once every other turn**
in the early game and be rare enough not to feel arbitrary.

- **Flood** (8%): one random isle loses half its armies, rounded down,
  minimum 1 remaining.
- **Earthquake** (5%): one random isle with 4+ armies loses 2.
- **Revolt** (6%): the largest isle owned by the player with the most
  isles loses a third of its armies, rounded down, minimum 1. Hazards
  are a rubber band, and this is the one that does the work — it is
  deliberately aimed at the leader, and the player should be able to see
  that it is.
- **Centres move** (every turn): each production centre has a 25% chance
  of moving to a random adjacent isle, whoever owns it.

Hazards never eliminate a player and never leave an isle at 0 armies.
Ownership only changes through attack, never through a hazard.

**Production centres.** Three isles carry a centre, placed at setup on
isles nobody starts adjacent to where possible. A centre is worth +2
reinforcements per turn to whoever owns it, and it wanders. They are the
map's moving objectives: they make a board of otherwise interchangeable
rocks have *places worth wanting*, and they keep wanting them from being
a one-time land grab. Of everything in this spec they are the single
most distinctive mechanic — no current mobile conquest game has an
objective that relocates itself — so if a tuning pass has to choose what
to protect, it protects these.

## Cards

Three kinds, drawn on a turn where the player captured an isle. Played
during their own attack phase, one per turn.

| Card | Effect |
|---|---|
| **Bombard** | Remove 2 armies from any enemy isle. Cannot capture. |
| **Shield** | Until the player's next turn, one owned isle cannot be bombarded and wins ties even when attacked at a disadvantage. |
| **Airlift** | Move any number of armies between two *non-adjacent* owned isles, leaving 1 behind. |

Deck: 8 Bombard, 6 Shield, 6 Airlift, reshuffled from the discard when
empty. No set-collection, no escalating trade-in bonus — that mechanic
is the main engine of Risk's famous forty-minute midgame, and a
five-minute game does not want it.

## Time budget

The design target is a **complete four-player game in under five
minutes** on the 14-isle starter map, with the human taking around 10-15
turns. If playtesting shows games running long, the levers in order of
preference are: reinforcement rate up, map smaller, hazard frequency up.
Adding rules is not on the list.

## The starter map: `small-sea`

14 isles in 4 archipelagos, hand-authored, tuned so no archipelago is
trivially defensible:

| Archipelago | Isles | Bonus | Note |
|---|---|---|---|
| North Reach | 4 | 3 | Two entrances, a long line |
| The Chain | 4 | 3 | Strung out, hard to hold whole |
| Warm Shoals | 3 | 2 | Compact, the natural first target |
| The Teeth | 3 | 4 | Three entrances, worth more because it bleeds |

Adjacency is authored as an explicit symmetric sea-lane graph and must
be connected. The board is a single SVG `viewBox` designed portrait-first
for a phone, with tap targets no smaller than 44px at the default zoom.

Exact isle names, paths and lanes are Iteration 1's deliverable, not
this document's.

## Rules the engine must enforce (test checklist)

- An attack from an isle with 1 army is rejected.
- An attack against a stronger isle is rejected — the match rule, at
  equality *and* one either side of it.
- A non-adjacent attack is rejected.
- Attacking your own isle is rejected.
- Defender wins ties.
- The failure penalty transfers the isle and ends the phase.
- Capture moves at least the dice-count, leaves at least 1 behind.
- Reinforcement floor of 3 applies to a player down to one isle.
- Archipelago bonus requires *every* isle in it.
- One redeploy per turn; one card per turn; hand caps at 5.
- No hazard ever takes an isle to 0 or changes an owner.
- Eliminating the last opponent ends the game immediately, mid-phase.
- Same seed + same actions ⇒ identical final state (the property test
  that guards everything above).
