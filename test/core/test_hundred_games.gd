extends GdUnitTestSuite
## A hundred games, played end to end, headless.
##
## Two jobs. It holds the engine's invariants against real play rather than
## hand-built positions — a game that cannot corrupt itself over a hundred
## runs is worth more than any number of unit tests of single moves. And it
## measures: the numbers it prints are the first real evidence about game
## length and hazard rates, and every one of them is a guess in RULES.md until
## something like this checks it.
##
## It asserts invariants, not balance. Balance is Iteration 10's business, and
## a test that fails when a tuning knob moves is a test nobody will keep.

const GAMES := 100
const TURN_CAP := 300
const PLAYERS := 4


func test_a_hundred_games_end_legally() -> void:
	var finished := 0
	var turns_when_finished := 0
	var hazards := {"flood": 0, "quake": 0, "revolt": 0, "centre_moved": 0}
	var attacks := 0
	var captures := 0
	var turns_played := 0

	for game: int in GAMES:
		var state := GreedyDriver.play(RandomDriver.classic_game(7000 + game), TURN_CAP)
		_check_invariants(state, game)

		turns_played += state.turn_number
		if state.phase == GameState.Phase.FINISHED:
			finished += 1
			turns_when_finished += state.turn_number
		for entry: Dictionary in state.log:
			var event := str(entry.get("event", ""))
			if hazards.has(event):
				hazards[event] = int(hazards[event]) + 1
			elif event == "attack":
				attacks += 1
				if bool(entry.get("captured", false)):
					captures += 1

	# A "turn" in RULES.md is one player's turn, and hazards resolve at the end
	# of each of those. turn_number counts rounds, so the per-player figure is
	# the one to compare against the spec.
	var hazard_events := int(hazards["flood"]) + int(hazards["quake"]) + int(hazards["revolt"])
	var player_turns := maxi(1, turns_played * PLAYERS)
	print("\n--- %d games, Classic, greedy play ---" % GAMES)
	print("  finished within %d rounds   : %d%%" % [TURN_CAP, int(100.0 * finished / GAMES)])
	print("  average rounds to finish    : %.1f" % (float(turns_when_finished) / maxi(1, finished)))
	print(
		(
			"  hazards per player-turn     : %.3f  (flood %d, quake %d, revolt %d)"
			% [
				float(hazard_events) / player_turns,
				int(hazards["flood"]),
				int(hazards["quake"]),
				int(hazards["revolt"]),
			]
		)
	)
	print(
		(
			"  centre moves per player-turn: %.3f"
			% (float(int(hazards["centre_moved"])) / player_turns)
		)
	)
	print(
		(
			"  attacks per player-turn     : %.2f, %d%% captured\n"
			% [float(attacks) / player_turns, int(100.0 * captures / maxi(1, attacks))]
		)
	)

	(
		assert_int(finished)
		. override_failure_message(
			"not one game in %d reached a winner — the engine cannot resolve a game" % GAMES
		)
		. is_greater(0)
	)


func _check_invariants(state: GameState, game: int) -> void:
	var owners: Dictionary = {}
	for province: Province in state.map.provinces:
		var holder := state.owner(province.id)
		var here := state.army_count(province.id)
		if holder.is_empty():
			continue
		owners[holder] = true
		(
			assert_int(here)
			. override_failure_message(
				"game %d: %s is held by %s with %d armies" % [game, province.id, holder, here]
			)
			. is_greater(0)
		)
		(
			assert_bool(state.player(holder) != null)
			. override_failure_message(
				"game %d: %s is held by unknown player '%s'" % [game, province.id, holder]
			)
			. is_true()
		)
		(
			assert_bool(state.player(holder).eliminated)
			. override_failure_message(
				"game %d: eliminated player %s still holds %s" % [game, holder, province.id]
			)
			. is_false()
		)

	for centre_id: String in state.centres:
		(
			assert_bool(state.map.has_province(centre_id))
			. override_failure_message("game %d: a centre is not on the map" % game)
			. is_true()
		)

	if state.phase == GameState.Phase.FINISHED and not state.winner.is_empty():
		(
			assert_int(state.living_players().size())
			. override_failure_message("game %d: finished with more than one player alive" % game)
			. is_equal(1)
		)
