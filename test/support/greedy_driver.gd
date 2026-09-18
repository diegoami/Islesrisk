class_name GreedyDriver
extends RefCounted
## Concentrates force and attacks where it has the biggest advantage.
##
## Test infrastructure, **not** an opponent — the AI is Iteration 4 and lives
## in core/ai. This exists because measuring game length needs a mover with
## some purpose: under purely arbitrary play no Classic game finishes at all,
## which says more about arbitrary play than about the rules.

const MAX_ATTACKS_PER_TURN := 12


static func play(state: GameState, max_turns: int = 300) -> GameState:
	var attacks := 0
	var last_turn := state.turn_number
	var guard := 0
	while state.phase != GameState.Phase.FINISHED and state.turn_number <= max_turns:
		guard += 1
		if guard > 200000:
			break
		if state.turn_number != last_turn:
			last_turn = state.turn_number
			attacks = 0

		var action := Action.end_phase()
		if state.phase == GameState.Phase.SETUP:
			action = Action.place(_front(state), 1)
		elif state.phase == GameState.Phase.REINFORCE:
			var pool := int(state.to_place.get(state.active_player().id, 0))
			action = Action.place(_front(state), pool) if pool > 0 else Action.end_phase()
		elif state.phase == GameState.Phase.ATTACK:
			var best := _best_attack(state)
			if best != null and attacks < MAX_ATTACKS_PER_TURN:
				action = best
				attacks += 1

		var result := Rules.apply(state, action)
		if not result.ok():
			var fallback := Rules.apply(state, Action.end_phase())
			if not fallback.ok():
				break
			state = fallback.state
			continue
		state = result.state
	return state


## The biggest owned stack that touches an enemy — reinforcements go where the
## fighting is.
static func _front(state: GameState) -> String:
	var best := ""
	var score := -1
	for province_id: String in state.provinces_of(state.active_player().id):
		var province := state.map.province(province_id)
		if province == null:
			continue
		var touches_enemy := false
		for neighbour_id: String in province.neighbours():
			if state.owner(neighbour_id) != state.active_player().id:
				touches_enemy = true
				break
		var here := state.army_count(province_id) + (100 if touches_enemy else 0)
		if here > score:
			score = here
			best = province_id
	return best


static func _best_attack(state: GameState) -> Action:
	var best: Action = null
	var margin := -999
	for action: Action in Rules.legal_attacks(state):
		var gap := state.army_count(action.from_id) - state.army_count(action.to_id)
		if gap > margin:
			margin = gap
			best = action
	return best
