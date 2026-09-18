class_name HazardResolver
extends RefCounted
## Floods, earthquakes, revolts, and the production centres wandering.
##
## This is the product (RULES.md, "hazards"): the part no current conquest
## game does. Resolved at the end of a turn, so a player always sees the board
## they are about to act on.
##
## **Invariants, true under every configuration**: a hazard never takes a
## province below one army, never eliminates a player, and never changes an
## owner. Ownership changes through attack only. The tests hold these against
## random configurations, not just Classic.


static func resolve_end_of_turn(state: GameState) -> void:
	if state.rules.hazards.enabled:
		_maybe(state, state.rules.hazards.flood, "flood", _flood)
		_maybe(state, state.rules.hazards.quake, "quake", _quake)
		_maybe(state, state.rules.hazards.revolt, "revolt", _revolt)
	_wander_centres(state)


static func _maybe(state: GameState, hazard: RuleSet.Hazard, name: String, apply: Callable) -> void:
	if not _rolls_true(state, hazard.chance):
		return
	var province_id: String = apply.call(state, hazard)
	if not province_id.is_empty():
		state.note({"event": name, "province": province_id, "turn": state.turn_number})


static func _flood(state: GameState, hazard: RuleSet.Hazard) -> String:
	var target := _random_province(state, 1)
	if target.is_empty():
		return ""
	_take(state, target, hazard.lose)
	return target


static func _quake(state: GameState, hazard: RuleSet.Hazard) -> String:
	var target := _random_province(state, hazard.min_armies)
	if target.is_empty():
		return ""
	_take(state, target, hazard.lose)
	return target


## Aimed at whoever is winning, deliberately, and the player should be able to
## see that it is. A rubber band nobody can perceive reads as the game being
## arbitrary; one they can read as the game having an opinion.
static func _revolt(state: GameState, hazard: RuleSet.Hazard) -> String:
	if hazard.target == "none":
		return ""
	var target_player := ""
	if hazard.target == "leader":
		target_player = _leader(state)
	else:
		var alive := state.living_players()
		if alive.is_empty():
			return ""
		target_player = alive[state.rng.next_int(0, alive.size() - 1)].id
	if target_player.is_empty():
		return ""

	var biggest := ""
	var most := 0
	for province_id: String in state.provinces_of(target_player):
		var here := state.army_count(province_id)
		if here > most:
			most = here
			biggest = province_id
	if biggest.is_empty() or most <= 1:
		return ""
	_take(state, biggest, hazard.lose)
	return biggest


## Most provinces, then most armies, then id — so the leader is decided the
## same way every time, whatever order the map happens to be in.
static func _leader(state: GameState) -> String:
	var best := ""
	var best_provinces := -1
	var best_armies := -1
	for candidate: Player in state.living_players():
		var provinces := state.provinces_of(candidate.id).size()
		var armies := state.army_total(candidate.id)
		var better := provinces > best_provinces
		if provinces == best_provinces:
			better = armies > best_armies or (armies == best_armies and candidate.id < best)
		if better:
			best = candidate.id
			best_provinces = provinces
			best_armies = armies
	return best


## The centres are the map's moving objectives: they stop holding ground from
## being a one-time land grab.
static func _wander_centres(state: GameState) -> void:
	var moved := PackedStringArray()
	for centre_id: String in state.centres:
		var province := state.map.province(centre_id)
		var options := province.neighbours() if province != null else PackedStringArray()
		if options.is_empty() or not _rolls_true(state, state.rules.centres.wander_chance):
			moved.append(centre_id)
			continue
		var destination := options[state.rng.next_int(0, options.size() - 1)]
		if moved.has(destination) or state.centres.has(destination):
			moved.append(centre_id)
			continue
		moved.append(destination)
		state.note(
			{
				"event": "centre_moved",
				"from": centre_id,
				"to": destination,
				"turn": state.turn_number
			}
		)
	state.centres = moved


## Never below one army. The invariant every hazard shares.
static func _take(state: GameState, province_id: String, lose: String) -> void:
	var here := state.army_count(province_id)
	var loss := 0
	match lose:
		"half":
			loss = here / 2
		"third":
			loss = here / 3
		_:
			loss = int(lose)
	state.armies[province_id] = maxi(1, here - loss)


static func _random_province(state: GameState, min_armies: int) -> String:
	var candidates := PackedStringArray()
	for province: Province in state.map.provinces:
		if state.army_count(province.id) >= maxi(1, min_armies):
			candidates.append(province.id)
	if candidates.is_empty():
		return ""
	return candidates[state.rng.next_int(0, candidates.size() - 1)]


## Chance as an integer draw. Floats never decide anything in the rules —
## cross-platform replay determinism depends on integer arithmetic.
static func _rolls_true(state: GameState, chance: float) -> bool:
	var in_ten_thousand := int(round(clampf(chance, 0.0, 1.0) * 10000.0))
	return state.rng.next_int(1, 10000) <= in_ten_thousand
