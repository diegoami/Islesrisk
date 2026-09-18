# Malpaco — Scenarios, maps and victory conditions

How a game is *configured*: where the board comes from, what the players
are trying to do, and how a set-up is saved, shared and replayed. The
rules themselves are in [RULES.md](RULES.md); this document covers
everything around them.

Keep this current the same way as the other docs: when the generator
gains a parameter, a victory condition is added, or the scenario schema
changes, record it here as part of that change.

## A scenario is one JSON object

Everything needed to start a specific game, serializable, with no
functions in it:

```
Scenario {
  schema      1                      // bumped on breaking changes
  id, name, description

  map         { kind: 'authored', id: 'small-sea' }
            | { kind: 'generated', params: MapGenParams }

  rules       RuleSetId
            | { extends: RuleSetId, overrides: DeepPartial<RuleSet> }
            | RuleSet                // inline, fully specified

  players     [{ id, name, colour,
                 kind: 'human' | 'ai',
                 policy?, difficulty?,
                 objectives?: VictoryCondition[] }]

  start?      { owner: Record<IsleId, PlayerId>,
                armies: Record<IsleId, number>,
                centres: IsleId[] }  // omit ⇒ the rules' setup runs

  victory     VictoryCondition[]     // global; per-player ones live on players
}
```

Three properties this shape is chosen for:

- **A scenario plus a seed is a whole game.** No hidden inputs. The same
  pair replays identically forever, which is what makes save files, bug
  reports and shared links the same object (ARCHITECTURE.md).
- **`extends` keeps presets readable.** A scenario that only turns off
  hazards says exactly that, in three lines, instead of restating 40
  fields — and it inherits later changes to its base preset.
- **`start` is optional.** Omit it for a normal game; supply it for a
  hand-built situation, which is what "authored scenario" really means.

## Maps: authored and generated are the same thing

A `GameMap` (ARCHITECTURE.md) is a set of **islands**, each divided into
**provinces**, plus the two kinds of crossing between them: land
**borders** within an island and **sea lanes** across water. A province
polygon is plain geometry — it feeds rendering, hit-testing and the art
system alike, and there is no per-province artwork anywhere in the data,
because the generator invents provinces no artist will ever see. **The
generator is one producer of that structure, not a parallel system.**
Generated and hand-drawn maps are the same type, pass the same
validator, and are indistinguishable to the engine, the AI and the
renderer.

This is not a contradiction of "adjacency is authored, never derived
from geometry": the generator derives borders and lanes *once*, at
generation time, and writes them into the map as data. Nothing
downstream ever infers adjacency from coordinates.

### `MapGenParams`

| Key | Meaning |
|---|---|
| `seed` | Everything below is deterministic given this |
| `islands` | How many landmasses |
| `provincesPerIsland` | A range, e.g. 3-6. Total province count follows |
| `layout` | `'scatter'` \| `'ring'` \| `'chain'` \| `'clusters'` — how the islands sit in the sea |
| `laneDensity` | 0-1. Sea lanes beyond the minimum needed to connect the islands; low is chokepoints, high is open water |
| `symmetry` | `'none'` \| `'mirror'` \| `'rotational'` — for scenarios where equal starts matter |
| `centres` | Production centres to place |
| `bonusRule` | How island bonuses are computed: by size, or by size and sea-entrance count |

### Generation, in outline

The order matters: **islands first, then their provinces.** Generating
provinces first and grouping them afterwards is what produces a scatter
of one-province islands rather than landmasses.

1. **Island sites.** Place `islands` centres in the board rect, shaped by
   `layout`, spaced so no two landmasses touch.
2. **Coastlines.** Give each island an outline — a rounded, jittered blob.
   It must be good enough to *draw*: the art system's coastline treatment
   has nothing else to work with (ARCHITECTURE.md, "Looking good").
3. **Provinces.** Scatter `provincesPerIsland` seeds inside the outline,
   spread by farthest-point selection so cells come out comparable rather
   than one large one and a sliver, then clip the outline by the
   perpendicular bisector of every seed pair — clipped Voronoi. The cells
   tile the island exactly, so province shapes and their shared borders
   come from one construction and can never disagree.
4. **Borders.** Two provinces on an island border each other when their
   cells share an edge — read off the construction, then written into the
   map as data.
5. **Sea lanes.** Connect the islands: a spanning tree first, so
   connectivity is guaranteed by construction rather than by retrying,
   then extra crossings up to `laneDensity`. Each lane joins the nearest
   coastal province on either side.
6. **Centres.** Place `centres` on high-betweenness provinces, spread
   apart, away from likely starts.
7. **Validate.** The same validator every authored map passes.
8. **Symmetry**, when asked, by generating one sector and transforming
   it — applied before validation, not after.

### The validator is the contract

Both sources must satisfy it, and it runs in the test gate so a broken
map fails CI rather than the game:

- Borders and sea lanes symmetric; nothing adjacent to itself; no
  duplicate ids; no crossing listed twice
- **A border always joins provinces on the same island; a sea lane never
  does.** Getting this backwards is what turns an archipelago of
  provinces back into a scatter of one-province islands
- **Each island is one landmass** — its provinces reachable from each
  other by land alone
- The whole board is connected, by land and water together
- Every province belongs to exactly one island, with the island's list
  and the province's own claim agreeing; no island empty
- Enough provinces for the scenario's players, and `centres ≤ provinces`
- Every province has a simple (non-self-intersecting) polygon, a label
  point inside it, and a non-degenerate area
- **Provinces that claim a border have shapes that actually meet** —
  within float tolerance, since clipped cells meet exactly only in theory
- **Fairness checks** for generated maps: no island that is a single
  province worth a bonus, no island unreachable by sea, and starting
  positions with comparable degree

A generator that can emit a map failing this is a bug in the generator,
not a reason to relax the validator.

## Victory conditions

A `VictoryCondition` is a tagged, serializable predicate over the game
state, evaluated at the end of each turn. The list is ordered and the
first satisfied wins; a player's own `objectives` are checked before the
global list, which is what makes asymmetric scenarios possible.

| Kind | Parameters | Satisfied when |
|---|---|---|
| `conquest` | — | Every other player is eliminated. The default |
| `domination` | `share`, `forTurns` | Holding ≥ `share` of provinces for `forTurns` consecutive turns |
| `objectives` | `provinces[]` / `islands[]`, `forTurns` | Holding all of them for `forTurns` |
| `economy` | `income`, `forTurns` | Reinforcement income ≥ `income` |
| `survival` | `untilTurn` | Still alive at `untilTurn`. The defender's condition |
| `turnLimit` | `atTurn`, `score` | At `atTurn`, the best `score` wins — `'provinces'`, `'armies'` or `'provinces+armies'` |
| `regicide` | `target` | A named player is eliminated |

`turnLimit` is special: it is the only condition that can end a game
nobody has won, so a scenario with no `conquest` and no `turnLimit` can
run forever and the validator rejects it.

Asymmetric example, and the reason `objectives` sits on the player:

```
players: [
  { id: 'p1', kind: 'human',
    objectives: [{ kind: 'objectives', islands: ['teeth'], forTurns: 3 }] },
  { id: 'p2', kind: 'ai', difficulty: 'hard',
    objectives: [{ kind: 'survival', untilTurn: 20 }] }
]
```

One side must take and hold ground; the other only has to not die. That
is a scenario, as opposed to a map with different numbers on it.

## Presets

Named, versioned `RuleSet`s. Player-facing surface: the start screen
offers presets and a size slider, not a wall of toggles.

| Preset | Shape |
|---|---|
| **Classic** | The defaults in RULES.md. 14 provinces, 4 players, conquest, five minutes. The tuning target |
| **Blitz** | Higher reinforcement, hazards up, ~10 provinces, `turnLimit` at 15 |
| **Open Sea** | `attackRule: 'classic'`, `failurePenalty: 'none'` — Risk-shaped, for players who want the familiar game |
| **Island** | 30-50 provinces, cards on, `domination` at 60% for 3 turns. A long game, explicitly not five minutes |
| **Still Waters** | Hazards and centres off. Exists to make the difference obvious — and as the A/B that tells us whether they are actually the product |
| **Last Stand** | Asymmetric: one player boxed in with `survival`, three attackers with `objectives` |

Still Waters earns its place as an experiment, not a mode: if players
prefer it, the central claim in DECISIONS.md is wrong and we should want
to know early.

## Sharing

Scenarios are files. Export writes one JSON document; import reads one,
validates it, and either loads it or refuses with a reason. A **share
code** — a short string encoding a preset id, generator params and a
seed — covers the common case of "play the board I just played" without
moving a file at all, and is short enough to paste into a chat.

The URL-fragment scheme an earlier draft specified died with the web
build (DECISIONS.md, "Godot and the desktop"). Files and share codes are
what a desktop game can offer instead; it is less frictionless and
that loss is recorded rather than glossed.

**An imported scenario is untrusted input**, and in Godot that is
sharper than it sounds:

- **JSON only, `JSON.parse` only.** Never `ResourceLoader`, never
  `.tres`/`.res`, never `load()` on a path from a file. Godot resource
  files can carry embedded scripts, so importing one from a stranger is
  arbitrary code execution — and scenario sharing is exactly the path an
  attacker would use.
- Validate fully before use; cap sizes, province counts and string lengths.
- Reject unknown fields and unknown `kind` tags rather than ignoring
  them — a silently dropped victory condition is a game that cannot end.
- A file that fails validation loads nothing and says why. Never start a
  half-configured game.

## Versioning

`schema` on the scenario, `version` on the rule set. Loading a newer
`schema` than the build knows is refused with a clear message, never
guessed at. Migrations are written when the first breaking change
happens and not before, but the field exists from day one so that
migration is possible at all.

Presets are versioned with the app, and a saved game stores its rule set
**inline, resolved** — so a tuning change to Classic can never silently
alter a game already in progress.
