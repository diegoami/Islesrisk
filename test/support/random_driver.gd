class_name RandomDriver
extends RefCounted
## Plays a game to the end with legal, arbitrary moves.
##
## Test infrastructure, not an opponent — it has no strategy whatsoever. Its
## job is to drive thousands of games through the engine so the invariants can
## be checked against real play rather than hand-built positions. The actual
## AI is Iteration 4 and lives in core/ai.

const MAX_ATTACKS_PER_TURN := 8


static func play(state: GameState, max_turns: int = 200) -> GameState:
	var attacks_this_turn := 0
	var last_turn := state.turn_number
	var guard := 0
	while state.phase != GameState.Phase.FINISHED and state.turn_number <= max_turns:
		guard += 1
		if guard > 200000:
			break
		if state.turn_number != last_turn:
			last_turn = state.turn_number
			attacks_this_turn = 0

		var action := _choose(state, attacks_this_turn)
		if action.kind == Action.Kind.ATTACK:
			attacks_this_turn += 1
		var result := Rules.apply(state, action)
		if not result.ok():
			# An arbitrary mover can pick an illegal move; ending the phase is
			# always legal from here, and keeps the game moving.
			var fallback := Rules.apply(state, Action.end_phase())
			if not fallback.ok():
				break
			state = fallback.state
			continue
		state = result.state
	return state


static func _choose(state: GameState, attacks_this_turn: int) -> Action:
	match state.phase:
		GameState.Phase.SETUP:
			return Action.place(_random_owned(state), 1)
		GameState.Phase.REINFORCE:
			var pool := int(state.to_place.get(state.active_player().id, 0))
			if pool <= 0:
				return Action.end_phase()
			return Action.place(_random_owned(state), pool)
		GameState.Phase.ATTACK:
			var options := Rules.legal_attacks(state)
			if options.is_empty() or attacks_this_turn >= MAX_ATTACKS_PER_TURN:
				return Action.end_phase()
			# Press the attack most of the time, so games actually resolve.
			if state.rng.next_int(1, 100) <= 80:
				return options[state.rng.next_int(0, options.size() - 1)]
			return Action.end_phase()
		GameState.Phase.REDEPLOY:
			return Action.end_phase()
	return Action.end_phase()


static func _random_owned(state: GameState) -> String:
	var owned := state.provinces_of(state.active_player().id)
	if owned.is_empty():
		return ""
	return owned[state.rng.next_int(0, owned.size() - 1)]


## A standard four-player Classic game, for tests that just need one.
static func classic_game(seed_value: int) -> GameState:
	var map := MapRepository.load_map("small-sea").map
	var players: Array[Player] = [
		Player.new("blua", "Blua"),
		Player.new("sukcena", "Sukcena", true),
		Player.new("verda", "Verda", true),
		Player.new("purpura", "Purpura", true),
	]
	return Rules.new_game(map, RuleSet.classic(), players, seed_value)
