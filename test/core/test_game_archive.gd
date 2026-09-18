extends GdUnitTestSuite
## A save is the seed, the rule set and the list of moves. Loading replays
## them, which only works because the engine is deterministic over exactly
## those inputs — so these tests are really a second check on determinism.


func test_a_game_survives_a_save_and_a_replay() -> void:
	var played := GreedyDriver.play(RandomDriver.classic_game(24601), 25)
	var problems: Array[String] = []
	var restored := GameArchive.from_dict(
		JSON.parse_string(JSON.stringify(GameArchive.to_dict(played))) as Dictionary, problems
	)
	assert_array(problems).is_empty()
	assert_object(restored).is_not_null()
	(
		assert_str(_digest(restored))
		. override_failure_message("a saved game did not replay into the same position")
		. is_equal(_digest(played))
	)


func test_a_replayed_game_carries_on_identically() -> void:
	var played := GreedyDriver.play(RandomDriver.classic_game(4242), 12)
	var problems: Array[String] = []
	var restored := GameArchive.from_dict(GameArchive.to_dict(played), problems)
	assert_object(restored).is_not_null()
	assert_str(_digest(GreedyDriver.play(restored, 30))).is_equal(
		_digest(GreedyDriver.play(played, 30))
	)


func test_the_save_is_small_and_holds_only_what_it_needs() -> void:
	var played := GreedyDriver.play(RandomDriver.classic_game(5), 20)
	var saved := GameArchive.to_dict(played)
	assert_array(saved.keys()).contains(["schema", "map", "seed", "rules", "players", "actions"])
	assert_int((saved["actions"] as Array).size()).is_equal(played.history.size())
	# No board position in the file: the moves are the game.
	assert_bool(saved.has("armies")).is_false()
	assert_bool(saved.has("owner")).is_false()


func test_a_save_from_another_schema_is_refused() -> void:
	var problems: Array[String] = []
	assert_object(GameArchive.from_dict({"schema": 99}, problems)).is_null()
	assert_str(problems[0]).contains("schema")


func test_a_save_with_an_unknown_map_is_refused() -> void:
	var saved := GameArchive.to_dict(RandomDriver.classic_game(1))
	saved["map"] = "atlantis"
	var problems: Array[String] = []
	assert_object(GameArchive.from_dict(saved, problems)).is_null()
	assert_str(problems[0]).contains("map")


## If the engine refuses a move it once allowed, the save and this build
## disagree about the rules. Better to say so than to resume a game that has
## quietly become a different one.
func test_a_move_the_engine_now_refuses_fails_the_load_with_a_reason() -> void:
	var saved := GameArchive.to_dict(GreedyDriver.play(RandomDriver.classic_game(9), 6))
	var actions: Array = saved["actions"]
	actions.insert(
		3, {"kind": int(Action.Kind.ATTACK), "from": "nowhere", "to": "elsewhere", "n": 0}
	)
	var problems: Array[String] = []
	assert_object(GameArchive.from_dict(saved, problems)).is_null()
	assert_str(problems[0]).contains("replaying action 4")


func _digest(state: GameState) -> String:
	var parts := PackedStringArray()
	parts.append("turn=%d phase=%d winner=%s" % [state.turn_number, state.phase, state.winner])
	for province: Province in state.map.provinces:
		parts.append(
			"%s:%s:%d" % [province.id, state.owner(province.id), state.army_count(province.id)]
		)
	parts.append("centres=%s" % ",".join(state.centres))
	return "|".join(parts)
