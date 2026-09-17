class_name DeterministicRng
extends RefCounted
## Seeded randomness, carried as data.
##
## Every source of chance in the rules draws from one of these: dice, hazard
## rolls, card draws, map generation. The seed and the current state are plain
## integers, so a game can be serialised, replayed and compared exactly — a
## save file, a replay and a bug report are the same small object.
##
## Integers only, deliberately. Godot's generator reproduces integer draws
## identically across platforms; float accumulation does not, and a replay
## that desynced between the Windows and Linux builds would void every
## guarantee the engine rests on.

var _rng: RandomNumberGenerator


func _init(initial_seed: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = initial_seed


## Restores a generator mid-sequence, so a loaded game continues the exact
## sequence it would have had if it were never saved.
static func from_snapshot(snapshot: Dictionary) -> DeterministicRng:
	var restored := DeterministicRng.new(int(snapshot["seed"]))
	restored._rng.state = int(snapshot["state"])
	return restored


## The pair that, with the action list, reproduces a game exactly.
func snapshot() -> Dictionary:
	return {"seed": _rng.seed, "state": _rng.state}


## Inclusive on both ends.
func next_int(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func roll_die(sides: int) -> int:
	return _rng.randi_range(1, sides)


## Fisher-Yates, drawing only from this generator. Returns a new array; the
## input is left alone.
func shuffled(items: Array) -> Array:
	var out: Array = items.duplicate()
	for i: int in range(out.size() - 1, 0, -1):
		var j: int = next_int(0, i)
		var held: Variant = out[i]
		out[i] = out[j]
		out[j] = held
	return out
