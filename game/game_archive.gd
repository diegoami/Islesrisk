class_name GameArchive
extends RefCounted
## Saving and resuming, by writing down what happened rather than where things
## ended up.
##
## A save is the seed, the rule set, the players and the list of actions —
## nothing else. Loading replays them through the engine, which reproduces the
## game exactly because the engine is deterministic over exactly those inputs
## (ARCHITECTURE.md). The file is small, it is also a bug report, and it is
## impossible for it to describe a position the rules could not have produced.
##
## JSON, never a Godot resource: `.tres` can carry embedded scripts, so
## loading one from a stranger is arbitrary code execution.

const SCHEMA := 1
const SAVE_PATH := "user://save.json"


static func to_dict(state: GameState) -> Dictionary:
	var seats: Array = []
	for each: Player in state.players:
		seats.append({"id": each.id, "name": each.name, "ai": each.is_ai})
	var moves: Array = []
	for action: Action in state.history:
		moves.append(
			{
				"kind": int(action.kind),
				"from": action.from_id,
				"to": action.to_id,
				"n": action.count
			}
		)
	return {
		"schema": SCHEMA,
		"map": state.map.id,
		"seed": int(state.rng.snapshot()["seed"]),
		"rules": state.rules.to_dict(),
		"players": seats,
		"actions": moves,
	}


## Returns null when the save cannot be replayed, rather than a half-built
## game. A file that fails loads nothing and says why.
static func from_dict(raw: Dictionary, problems: Array[String]) -> GameState:
	if int(raw.get("schema", -1)) != SCHEMA:
		problems.append("save schema %s is not %d" % [str(raw.get("schema")), SCHEMA])
		return null

	var map_result := MapRepository.load_map(str(raw.get("map", "")))
	if not map_result.ok():
		problems.append("the save's map could not be loaded")
		return null

	var seats: Array[Player] = []
	for entry: Variant in raw.get("players", []):
		if entry is Dictionary:
			var seat: Dictionary = entry
			seats.append(
				Player.new(
					str(seat.get("id", "")), str(seat.get("name", "")), bool(seat.get("ai", false))
				)
			)
	if seats.size() < 2:
		problems.append("a saved game needs at least two players")
		return null

	var rules := RuleSet.from_dict(raw.get("rules", {}))
	var state := Rules.new_game(map_result.map, rules, seats, int(raw.get("seed", 0)))

	var index := 0
	for entry: Variant in raw.get("actions", []):
		index += 1
		if not entry is Dictionary:
			problems.append("action %d is not an object" % index)
			return null
		var move: Dictionary = entry
		var action := Action.new(
			int(move.get("kind", 0)) as Action.Kind,
			str(move.get("from", "")),
			str(move.get("to", "")),
			int(move.get("n", 0))
		)
		var result := Rules.apply(state, action)
		if not result.ok():
			# The engine refusing a move it once allowed means the save and
			# this build disagree about the rules. Better to say so than to
			# resume a game that has quietly become a different one.
			problems.append(
				"replaying action %d (%s) failed: %s" % [index, action.describe(), result.error]
			)
			return null
		state = result.state
	return state


static func save(state: GameState) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict(state)))
	file.close()
	return true


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func load_saved(problems: Array[String]) -> GameState:
	if not has_save():
		problems.append("there is no saved game")
		return null
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		problems.append("the saved game could not be opened")
		return null
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		problems.append("the saved game is not valid JSON")
		return null
	return from_dict(parsed, problems)


static func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
