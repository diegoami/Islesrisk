extends GdUnitTestSuite
## The property the whole engine rests on: the same seed, rule set, map and
## actions produce the same game, every time. Save files, replays, bug reports
## and AI search all depend on it (ARCHITECTURE.md).


func test_the_same_seed_plays_the_same_game() -> void:
	for seed_value: int in [1, 17, 4242, 99999]:
		var first := _digest(GreedyDriver.play(RandomDriver.classic_game(seed_value), 60))
		var second := _digest(GreedyDriver.play(RandomDriver.classic_game(seed_value), 60))
		(
			assert_str(second)
			. override_failure_message("seed %d produced two different games" % seed_value)
			. is_equal(first)
		)


func test_different_seeds_produce_different_games() -> void:
	var one := _digest(GreedyDriver.play(RandomDriver.classic_game(1), 60))
	var two := _digest(GreedyDriver.play(RandomDriver.classic_game(2), 60))
	assert_str(one).is_not_equal(two)


func test_a_game_can_be_resumed_from_a_snapshot_mid_play() -> void:
	var state := RandomDriver.classic_game(31337)
	state = GreedyDriver.play(state, 8)

	var resumed := state.clone()
	(
		assert_str(_digest(GreedyDriver.play(resumed, 40)))
		. override_failure_message("a cloned state did not continue into the same game")
		. is_equal(_digest(GreedyDriver.play(state, 40)))
	)


func test_cloning_carries_the_generator_position_not_just_the_seed() -> void:
	var state := RandomDriver.classic_game(5)
	for i: int in 25:
		state.rng.next_int(0, 1000)
	var copy := state.clone()
	assert_int(copy.rng.next_int(0, 1000)).is_equal(state.rng.next_int(0, 1000))


## Everything that decides what a game looks like, in one string.
func _digest(state: GameState) -> String:
	var parts := PackedStringArray()
	parts.append("turn=%d phase=%d winner=%s" % [state.turn_number, state.phase, state.winner])
	for province: Province in state.map.provinces:
		parts.append(
			"%s:%s:%d" % [province.id, state.owner(province.id), state.army_count(province.id)]
		)
	parts.append("centres=%s" % ",".join(state.centres))
	parts.append("log=%d" % state.log.size())
	return "|".join(parts)
