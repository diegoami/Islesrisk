class_name GameSetup
extends RefCounted
## Dealing a new game. Everything here draws from the seeded RNG, so the same
## seed deals the same board.


static func new_game(
	map: GameMap, rules: RuleSet, players: Array[Player], seed_value: int
) -> GameState:
	var state := GameState.new()
	state.map = map
	state.rules = rules
	state.players = players
	state.rng = DeterministicRng.new(seed_value)
	state.phase = GameState.Phase.SETUP
	state.turn_number = 1

	_deal(state)
	_place_centres(state)
	_fill_pools(state)
	state.current_player = 0
	state.note({"event": "game_started", "seed": seed_value, "players": players.size()})
	return state


## Round-robin from a shuffled order, so nobody is handed a neighbourhood.
static func _deal(state: GameState) -> void:
	var ids: Array = Array(state.map.province_ids())
	if state.rules.setup.deal != "authored":
		ids = state.rng.shuffled(ids)
	var seat := 0
	for province_id: Variant in ids:
		var holder := state.players[seat % state.players.size()]
		state.owner_of[str(province_id)] = holder.id
		state.armies[str(province_id)] = state.rules.setup.starting_armies
		seat += 1


## Spread as far apart as the board allows: the first centre is random, each
## next one goes to the province furthest (in crossings) from those already
## placed. Keeps them from clustering on one island.
static func _place_centres(state: GameState) -> void:
	var wanted := mini(state.rules.centres.count, state.map.size())
	if wanted <= 0:
		return
	var ids := state.map.province_ids()
	var chosen := PackedStringArray([ids[state.rng.next_int(0, ids.size() - 1)]])
	while chosen.size() < wanted:
		var best := ""
		var best_distance := -1
		for province: Province in state.map.provinces:
			if chosen.has(province.id):
				continue
			var nearest := _hops_to_nearest(state.map, province.id, chosen)
			if nearest > best_distance:
				best_distance = nearest
				best = province.id
		if best.is_empty():
			break
		chosen.append(best)
	state.centres = chosen


static func _hops_to_nearest(map: GameMap, from_id: String, targets: PackedStringArray) -> int:
	var seen: Dictionary = {from_id: true}
	var frontier := PackedStringArray([from_id])
	var distance := 0
	while not frontier.is_empty():
		var next := PackedStringArray()
		for province_id: String in frontier:
			if targets.has(province_id):
				return distance
			var province := map.province(province_id)
			if province == null:
				continue
			for neighbour_id: String in province.neighbours():
				if not seen.has(neighbour_id):
					seen[neighbour_id] = true
					next.append(neighbour_id)
		frontier = next
		distance += 1
	return distance


## The opening armies each player places by hand, one at a time. Players dealt
## fewer provinces than the leader get the short-stack bonus.
static func _fill_pools(state: GameState) -> void:
	var most := 0
	for each: Player in state.players:
		most = maxi(most, state.provinces_of(each.id).size())
	for each: Player in state.players:
		var short := most - state.provinces_of(each.id).size()
		var bonus := state.rules.setup.short_stack_bonus if short > 0 else 0
		state.to_place[each.id] = state.rules.setup.distribution_pool + bonus
