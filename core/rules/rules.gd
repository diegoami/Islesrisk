class_name Rules
extends RefCounted
## The engine. One way in:
##
##     Rules.apply(state, action) -> ActionResult
##
## Total, deterministic, no I/O, no ambient randomness. Every source of chance
## draws from the generator inside the state, so a game is its seed, its rule
## set and its action list — which is what makes a save, a replay and a bug
## report the same small object.
##
## Nothing here reads a constant that is not in `state.rules`.


static func new_game(
	map: GameMap, rule_set: RuleSet, players: Array[Player], seed_value: int
) -> GameState:
	return GameSetup.new_game(map, rule_set, players, seed_value)


static func apply(state: GameState, action: Action) -> ActionResult:
	if state.phase == GameState.Phase.FINISHED:
		return ActionResult.rejected("the game is over")
	var mover := state.active_player()
	if mover == null:
		return ActionResult.rejected("no player to act")

	var next := state.clone()
	var result := _dispatch(next, action)
	if result.ok():
		result.state.history.append(action)
	return result


static func _dispatch(next: GameState, action: Action) -> ActionResult:
	match action.kind:
		Action.Kind.PLACE:
			return _place(next, action)
		Action.Kind.ATTACK:
			return _attack(next, action)
		Action.Kind.REDEPLOY:
			return _redeploy(next, action)
		Action.Kind.END_PHASE:
			return _end_phase(next)
		Action.Kind.CONCEDE:
			return _concede(next)
	return ActionResult.rejected("unknown action")


## What the reinforce phase pays this player: provinces, island bonuses, and
## the production centres they hold.
static func reinforcements_for(state: GameState, player_id: String) -> int:
	var rules := state.rules.reinforcement
	var owned := state.provinces_of(player_id).size()
	if owned == 0:
		return 0
	var divisor := maxi(1, rules.per_province_divisor)
	var total := maxi(rules.minimum, owned / divisor)
	if rules.island_bonus != "off":
		for island: Island in state.islands_held(player_id):
			total += island.size() if rules.island_bonus == "bySize" else island.bonus
	total += rules.centre_bonus * state.centres_held(player_id)
	return total


## Every attack the active player could declare. Used by the tests, and by the
## AI and the UI later — so all three agree on what is legal.
static func legal_attacks(state: GameState) -> Array[Action]:
	var found: Array[Action] = []
	if state.phase != GameState.Phase.ATTACK:
		return found
	var mover := state.active_player()
	if mover == null:
		return found
	for province_id: String in state.provinces_of(mover.id):
		var province := state.map.province(province_id)
		if province == null:
			continue
		for target_id: String in province.neighbours():
			if CombatResolver.why_not(state, province_id, target_id).is_empty():
				found.append(Action.attack(province_id, target_id))
	return found


# --- phases -----------------------------------------------------------------


static func _place(state: GameState, action: Action) -> ActionResult:
	var mover := state.active_player()
	if state.phase != GameState.Phase.SETUP and state.phase != GameState.Phase.REINFORCE:
		return ActionResult.rejected("armies can only be placed in setup or reinforce")
	if not state.owns(mover.id, action.to_id):
		return ActionResult.rejected("you do not hold that province")
	var remaining := int(state.to_place.get(mover.id, 0))
	if remaining <= 0:
		return ActionResult.rejected("you have no armies left to place")
	if action.count < 1:
		return ActionResult.rejected("place at least one army")

	# Setup is one army at a time, in turn order, so the opening is a
	# negotiation rather than four players filling in a form.
	if state.phase == GameState.Phase.SETUP and action.count != 1:
		return ActionResult.rejected("setup places one army at a time")
	if action.count > remaining:
		return ActionResult.rejected("you have only %d armies left to place" % remaining)

	state.armies[action.to_id] = state.army_count(action.to_id) + action.count
	state.to_place[mover.id] = remaining - action.count

	if state.phase == GameState.Phase.SETUP:
		_advance_setup(state)
	elif int(state.to_place.get(mover.id, 0)) == 0:
		state.phase = GameState.Phase.ATTACK
	return ActionResult.new(state)


static func _attack(state: GameState, action: Action) -> ActionResult:
	if state.phase != GameState.Phase.ATTACK:
		return ActionResult.rejected("attacks happen in the attack phase")
	var refusal := CombatResolver.why_not(state, action.from_id, action.to_id)
	if not refusal.is_empty():
		return ActionResult.rejected(refusal)

	var outcome := CombatResolver.resolve(state, action.from_id, action.to_id)
	outcome["turn"] = state.turn_number
	state.note(outcome)
	if bool(outcome.get("captured", false)):
		state.captured_this_turn = true
		_check_elimination(state)
		if _check_victory(state):
			return ActionResult.new(state)
	if bool(outcome.get("ends_phase", false)):
		_to_redeploy(state)
	return ActionResult.new(state)


static func _redeploy(state: GameState, action: Action) -> ActionResult:
	if state.phase != GameState.Phase.REDEPLOY:
		return ActionResult.rejected("redeploys happen in the redeploy phase")
	if state.redeploys_left <= 0:
		return ActionResult.rejected("no redeploys left this turn")
	var mover := state.active_player()
	if not state.owns(mover.id, action.from_id) or not state.owns(mover.id, action.to_id):
		return ActionResult.rejected("you must hold both provinces")
	if action.from_id == action.to_id:
		return ActionResult.rejected("that is the same province")
	var from := state.map.province(action.from_id)
	if from == null or not from.neighbours().has(action.to_id):
		return ActionResult.rejected("those provinces do not connect")
	if action.count < 1:
		return ActionResult.rejected("move at least one army")
	if action.count > state.army_count(action.from_id) - 1:
		return ActionResult.rejected("one army must stay behind")

	state.armies[action.from_id] = state.army_count(action.from_id) - action.count
	state.armies[action.to_id] = state.army_count(action.to_id) + action.count
	state.redeploys_left -= 1
	(
		state
		. note(
			{
				"event": "redeploy",
				"from": action.from_id,
				"to": action.to_id,
				"count": action.count,
				"turn": state.turn_number,
			}
		)
	)
	return ActionResult.new(state)


static func _end_phase(state: GameState) -> ActionResult:
	var mover := state.active_player()
	match state.phase:
		GameState.Phase.SETUP:
			return ActionResult.rejected("every opening army must be placed")
		GameState.Phase.REINFORCE:
			if int(state.to_place.get(mover.id, 0)) > 0:
				return ActionResult.rejected("place your reinforcements first")
			state.phase = GameState.Phase.ATTACK
		GameState.Phase.ATTACK:
			_to_redeploy(state)
		GameState.Phase.REDEPLOY:
			_end_turn(state)
		_:
			return ActionResult.rejected("nothing to end")
	return ActionResult.new(state)


static func _concede(state: GameState) -> ActionResult:
	var mover := state.active_player()
	mover.eliminated = true
	for province_id: String in state.provinces_of(mover.id):
		state.owner_of.erase(province_id)
		state.armies[province_id] = 0
	state.note({"event": "conceded", "player": mover.id, "turn": state.turn_number})
	if not _check_victory(state):
		_next_player(state)
	return ActionResult.new(state)


# --- turn machinery ---------------------------------------------------------


static func _advance_setup(state: GameState) -> void:
	for i: int in state.players.size():
		state.current_player = (state.current_player + 1) % state.players.size()
		if int(state.to_place.get(state.active_player().id, 0)) > 0:
			return
	# Everyone has placed: the game proper begins with the first seat.
	state.current_player = 0
	state.phase = GameState.Phase.REINFORCE
	state.to_place[state.active_player().id] = reinforcements_for(state, state.active_player().id)


static func _to_redeploy(state: GameState) -> void:
	state.phase = GameState.Phase.REDEPLOY
	state.redeploys_left = state.rules.redeploy.moves_per_turn


## Hazards resolve here, at the end of the turn, so a player always sees the
## board they are about to act on.
static func _end_turn(state: GameState) -> void:
	state.phase = GameState.Phase.HAZARDS
	HazardResolver.resolve_end_of_turn(state)
	if _check_victory(state):
		return
	_next_player(state)


static func _next_player(state: GameState) -> void:
	var seats := state.players.size()
	for i: int in seats:
		state.current_player = (state.current_player + 1) % seats
		if state.current_player == 0:
			state.turn_number += 1
		if not state.active_player().eliminated:
			break
	state.phase = GameState.Phase.REINFORCE
	state.captured_this_turn = false
	state.redeploys_left = 0
	state.to_place[state.active_player().id] = reinforcements_for(state, state.active_player().id)


static func _check_elimination(state: GameState) -> void:
	for candidate: Player in state.players:
		if not candidate.eliminated and state.provinces_of(candidate.id).is_empty():
			candidate.eliminated = true
			state.note({"event": "eliminated", "player": candidate.id, "turn": state.turn_number})


## Conquest only for now. The condition catalogue — domination, objectives,
## survival, turn limit — plugs in here in Iteration 7 (SCENARIOS.md).
static func _check_victory(state: GameState) -> bool:
	if not state.rules.victory.has("conquest"):
		return false
	var alive := state.living_players()
	if alive.size() > 1:
		return false
	state.phase = GameState.Phase.FINISHED
	state.winner = alive[0].id if alive.size() == 1 else ""
	state.note({"event": "victory", "player": state.winner, "turn": state.turn_number})
	return true
