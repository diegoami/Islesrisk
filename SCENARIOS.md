# Islesrisk — Scenarios, maps and victory conditions

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

A `GameMap` (ARCHITECTURE.md) is a list of isles with SVG paths, an
authored symmetric sea-lane graph, and archipelago groupings. **The
generator is one producer of that structure, not a parallel system.**
Generated and hand-drawn maps are the same type, pass the same
validator, and are indistinguishable to the engine, the AI and the
renderer.

This is not a contradiction of "adjacency is authored, never derived
from geometry": the generator derives lanes *once*, at generation time,
and writes them into the map as data. Nothing downstream ever infers
adjacency from coordinates.

### `MapGenParams`

| Key | Meaning |
|---|---|
| `seed` | Everything below is deterministic given this |
| `isles` | Isle count — Classic-sized is 12-16, up to ~60 for long games |
| `archipelagos` | Group count; sizes follow from the clustering |
| `layout` | `'scatter'` \| `'ring'` \| `'chain'` \| `'clusters'` — the board's gross shape |
| `laneDensity` | 0-1. Lanes beyond the minimum spanning structure; low is chokepoints, high is open water |
| `symmetry` | `'none'` \| `'mirror'` \| `'rotational'` — for scenarios where equal starts matter |
| `centres` | Production centres to place |
| `bonusRule` | How archipelago bonuses are computed: by size, or by size and entrance count |

### Generation, in outline

1. **Points.** Poisson-disc sample `isles` points into the board rect,
   shaped by `layout`. Even spacing, no clumps, no two isles fighting
   for the same tap target.
2. **Cells.** Voronoi over those points, then shrink and round each cell
   into an island silhouette. Isle shapes and the adjacency graph come
   from one construction, so they can never disagree.
3. **Lanes.** Start from the Delaunay edges. Take a spanning tree first
   — connectivity is guaranteed by construction, not by retrying — then
   add edges back up to `laneDensity`, preferring short ones.
4. **Archipelagos.** Cluster the graph into `archipelagos` groups
   (flood-fill from spread seeds). Bonus per `bonusRule`: bigger and
   more exposed is worth more, which is what makes The Teeth worth 4.
5. **Centres.** Place `centres` on high-betweenness isles, spread apart,
   away from likely starts.
6. **Validate.** The same validator every authored map passes.
7. **Symmetry**, when asked, by generating one sector and transforming
   it — applied before validation, not after.

### The validator is the contract

Both sources must satisfy it, and it runs in the test gate so a broken
map fails CI rather than the game:

- Sea lanes symmetric; no isle adjacent to itself; no duplicate ids
- The lane graph is connected
- Every isle belongs to exactly one archipelago; no archipelago empty
- Enough isles for the scenario's players, and `centres ≤ isles`
- Every isle has a path, a label point, and a non-degenerate area
- **Fairness checks** for generated maps: no isle with degree 1 unless
  `layout` asks for it, no archipelago that is a single isle worth a
  bonus, and starting positions with comparable degree

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
| `domination` | `share`, `forTurns` | Holding ≥ `share` of isles for `forTurns` consecutive turns |
| `objectives` | `isles[]` / `archipelagos[]`, `forTurns` | Holding all of them for `forTurns` |
| `economy` | `income`, `forTurns` | Reinforcement income ≥ `income` |
| `survival` | `untilTurn` | Still alive at `untilTurn`. The defender's condition |
| `turnLimit` | `atTurn`, `score` | At `atTurn`, the best `score` wins — `'isles'`, `'armies'` or `'isles+armies'` |
| `regicide` | `target` | A named player is eliminated |

`turnLimit` is special: it is the only condition that can end a game
nobody has won, so a scenario with no `conquest` and no `turnLimit` can
run forever and the validator rejects it.

Asymmetric example, and the reason `objectives` sits on the player:

```
players: [
  { id: 'p1', kind: 'human',
    objectives: [{ kind: 'objectives', archipelagos: ['teeth'], forTurns: 3 }] },
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
| **Classic** | The defaults in RULES.md. 14 isles, 4 players, conquest, five minutes. The tuning target |
| **Blitz** | Higher reinforcement, hazards up, ~10 isles, `turnLimit` at 15 |
| **Open Sea** | `attackRule: 'classic'`, `failurePenalty: 'none'` — Risk-shaped, for players who want the familiar game |
| **Archipelago** | 30-50 isles, cards on, `domination` at 60% for 3 turns. A long game, explicitly not five minutes |
| **Still Waters** | Hazards and centres off. Exists to make the difference obvious — and as the A/B that tells us whether they are actually the product |
| **Last Stand** | Asymmetric: one player boxed in with `survival`, three attackers with `objectives` |

Still Waters earns its place as an experiment, not a mode: if players
prefer it, the central claim in DECISIONS.md is wrong and we should want
to know early.

## Sharing

A scenario is small and it compresses well, so a game set-up travels as
a URL fragment — no account, no server, no install. `#s=<compressed>`
for the scenario, `#s=…&seed=…` to hand someone the exact game.

This is the one place the project's smallness is an advantage over the
app-store competition (DECISIONS.md, "Mobile competitors"): a link into
a specific situation is something an installed app cannot do as
cheaply. Oversized fragments fall back to a local scenario id; a
fragment that fails to parse or fails validation loads nothing and says
so, rather than starting a half-configured game.

**A shared scenario is untrusted input.** It is data from a stranger:
validate it fully before use, never `eval` any part of it, cap sizes,
and reject unknown `kind` tags rather than ignoring them.

## Versioning

`schema` on the scenario, `version` on the rule set. Loading a newer
`schema` than the build knows is refused with a clear message, never
guessed at. Migrations are written when the first breaking change
happens and not before, but the field exists from day one so that
migration is possible at all.

Presets are versioned with the app, and a saved game stores its rule set
**inline, resolved** — so a tuning change to Classic can never silently
alter a game already in progress.
