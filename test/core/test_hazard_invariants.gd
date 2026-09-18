extends GdUnitTestSuite
## The hazard invariants, held against randomised configurations rather than
## just Classic: **no hazard ever takes a province below one army, eliminates a
## player, or changes an owner.** Ownership changes through attack only.


func test_hazards_never_change_an_owner_or_starve_a_province() -> void:
	var checked := 0
	for seed_value: int in range(1, 120):
		var state := _mid_game(seed_value)
		if state.phase == GameState.Phase.FINISHED:
			continue
		var owners_before := state.owner_of.duplicate()
		var living_before := state.living_players().size()

		for turn: int in 25:
			HazardResolver.resolve_end_of_turn(state)
			for province: Province in state.map.provinces:
				(
					assert_int(state.army_count(province.id))
					. override_failure_message(
						"seed %d: %s fell below one army after a hazard" % [seed_value, province.id]
					)
					. is_greater(0)
				)
			checked += 1

		(
			assert_dict(state.owner_of)
			. override_failure_message("seed %d: a hazard changed who owns something" % seed_value)
			. is_equal(owners_before)
		)
		(
			assert_int(state.living_players().size())
			. override_failure_message("seed %d: a hazard eliminated a player" % seed_value)
			. is_equal(living_before)
		)
	assert_int(checked).is_greater(500)


func test_hazards_can_be_turned_off_entirely() -> void:
	var rules := RuleSet.classic()
	rules.hazards.enabled = false
	rules.centres.wander_chance = 0.0
	var state := _mid_game(9, rules)
	var before := state.log.size()
	for turn: int in 50:
		HazardResolver.resolve_end_of_turn(state)
	(
		assert_int(state.log.size())
		. override_failure_message("something was logged with every hazard disabled")
		. is_equal(before)
	)


func test_a_revolt_leans_on_the_leader() -> void:
	var rules := RuleSet.classic()
	rules.hazards.flood.chance = 0.0
	rules.hazards.quake.chance = 0.0
	rules.hazards.revolt.chance = 1.0
	rules.centres.wander_chance = 0.0

	# Blue is plainly ahead: three provinces to Red's one, and the big stack.
	var state := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 20],
				"west_south": ["blue", 5],
				"east_north": ["blue", 5],
				"east_south": ["red", 5],
			},
			rules
		)
	)
	HazardResolver.resolve_end_of_turn(state)
	(
		assert_int(state.army_count("west_north"))
		. override_failure_message("the revolt did not fall on the leader's largest province")
		. is_less(20)
	)
	assert_int(state.army_count("east_south")).is_equal(5)


func test_the_revolt_can_be_aimed_elsewhere_or_switched_off() -> void:
	var rules := RuleSet.classic()
	rules.hazards.flood.chance = 0.0
	rules.hazards.quake.chance = 0.0
	rules.hazards.revolt.chance = 1.0
	rules.hazards.revolt.target = "none"
	rules.centres.wander_chance = 0.0

	var state := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 20],
				"west_south": ["blue", 5],
				"east_north": ["blue", 5],
				"east_south": ["red", 5],
			},
			rules
		)
	)
	HazardResolver.resolve_end_of_turn(state)
	assert_int(state.army_count("west_north")).is_equal(20)


func test_centres_wander_and_stay_on_the_board() -> void:
	var rules := RuleSet.classic()
	rules.hazards.enabled = false
	rules.centres.wander_chance = 1.0
	var state := _mid_game(3, rules)
	var count := state.centres.size()
	assert_int(count).is_greater(0)

	var moved := false
	var before := PackedStringArray(state.centres)
	for turn: int in 20:
		HazardResolver.resolve_end_of_turn(state)
		(
			assert_int(state.centres.size())
			. override_failure_message("a centre was lost or duplicated while wandering")
			. is_equal(count)
		)
		for centre_id: String in state.centres:
			(
				assert_bool(state.map.has_province(centre_id))
				. override_failure_message("a centre wandered off the map to '%s'" % centre_id)
				. is_true()
			)
		if ",".join(state.centres) != ",".join(before):
			moved = true
	(
		assert_bool(moved)
		. override_failure_message("no centre moved in 20 turns at a wander chance of 1.0")
		. is_true()
	)


func _mid_game(seed_value: int, rules: RuleSet = null) -> GameState:
	var map := MapRepository.load_map("small-sea").map
	var players: Array[Player] = [
		Player.new("blue", "Blue"),
		Player.new("green", "Green", true),
		Player.new("red", "Red", true),
		Player.new("brown", "Brown", true),
	]
	var state := Rules.new_game(
		map, rules if rules != null else RuleSet.classic(), players, seed_value
	)
	return GreedyDriver.play(state, 6)
