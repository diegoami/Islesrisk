extends GdUnitTestSuite
## No rule is a compiled-in assumption (ARCHITECTURE.md). These hold the engine
## to that: turn a rule off or change it, and the engine plays the other game
## rather than the same one with a dead setting.


func test_the_classic_attack_rule_permits_what_the_match_rule_refuses() -> void:
	var weaker := TestPositions.standoff(3, 7)
	assert_str(CombatResolver.why_not(weaker, "west_north", "east_north")).is_not_empty()

	var rules := RuleSet.classic()
	rules.combat.attack_rule = "classic"
	var permissive := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 3],
				"west_south": ["blue", 1],
				"east_north": ["red", 7],
				"east_south": ["red", 1],
			},
			rules
		)
	)
	assert_str(CombatResolver.why_not(permissive, "west_north", "east_north")).is_empty()


func test_the_classic_rule_still_enforces_the_minimum_garrison_and_adjacency() -> void:
	var rules := RuleSet.classic()
	rules.combat.attack_rule = "classic"
	var state := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 1],
				"west_south": ["blue", 9],
				"east_north": ["red", 1],
				"east_south": ["red", 1],
			},
			rules
		)
	)
	assert_str(CombatResolver.why_not(state, "west_north", "east_north")).contains("at least")
	assert_str(CombatResolver.why_not(state, "west_south", "east_south")).contains("does not reach")


func test_the_threshold_rule_scales_what_an_attacker_needs() -> void:
	var rules := RuleSet.classic()
	rules.combat.attack_rule = "threshold"
	rules.combat.attack_ratio = 2.0
	var holdings := {
		"west_north": ["blue", 6],
		"west_south": ["blue", 1],
		"east_north": ["red", 4],
		"east_south": ["red", 1],
	}
	(
		assert_str(
			CombatResolver.why_not(
				TestPositions.position(holdings, rules), "west_north", "east_north"
			)
		)
		. is_not_empty()
	)

	holdings["west_north"] = ["blue", 8]
	(
		assert_str(
			CombatResolver.why_not(
				TestPositions.position(holdings, rules), "west_north", "east_north"
			)
		)
		. is_empty()
	)


func test_ties_can_be_given_to_the_attacker() -> void:
	var rules := RuleSet.classic()
	rules.combat.ties = "attacker"
	var swung := false
	for seed_value: int in range(1, 120):
		var classic_state := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 5],
					"west_south": ["blue", 1],
					"east_north": ["red", 5],
					"east_south": ["red", 1],
				},
				null,
				seed_value
			)
		)
		var swapped := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 5],
					"west_south": ["blue", 1],
					"east_north": ["red", 5],
					"east_south": ["red", 1],
				},
				rules,
				seed_value
			)
		)
		var a := Rules.apply(classic_state, Action.attack("west_north", "east_north")).state
		var b := Rules.apply(swapped, Action.attack("west_north", "east_north")).state
		if a.army_count("east_north") != b.army_count("east_north"):
			swung = true
			assert_int(b.army_count("east_north")).is_less(a.army_count("east_north"))
			break
	(
		assert_bool(swung)
		. override_failure_message(
			"no tie ever came up in 120 attacks, so the setting was never exercised"
		)
		. is_true()
	)


func test_island_bonuses_can_be_sized_or_switched_off() -> void:
	var holdings := {
		"west_north": ["blue", 1],
		"west_south": ["blue", 1],
		"east_north": ["red", 1],
		"east_south": ["red", 1],
	}
	var authored := TestPositions.position(holdings)

	var by_size := RuleSet.classic()
	by_size.reinforcement.island_bonus = "bySize"
	var off := RuleSet.classic()
	off.reinforcement.island_bonus = "off"

	# West is worth 2 as authored, and has 2 provinces, so the two agree here;
	# what matters is that "off" pays neither.
	(
		assert_int(Rules.reinforcements_for(TestPositions.position(holdings, by_size), "blue"))
		. is_equal(Rules.reinforcements_for(authored, "blue"))
	)
	assert_int(Rules.reinforcements_for(TestPositions.position(holdings, off), "blue")).is_equal(
		authored.rules.reinforcement.minimum
	)


func test_centres_can_be_switched_off_entirely() -> void:
	var rules := RuleSet.classic()
	rules.centres.count = 0
	var map := MapRepository.load_map("small-sea").map
	var players: Array[Player] = [Player.new("blue", "Blue"), Player.new("red", "Red", true)]
	var state := Rules.new_game(map, rules, players, 11)
	assert_int(state.centres.size()).is_equal(0)
	assert_int(state.centres_held("blue")).is_equal(0)


func test_the_capture_rule_decides_how_many_armies_advance() -> void:
	for mode: String in ["diceCount", "all", "one"]:
		var rules := RuleSet.classic()
		rules.combat.capture = mode
		for seed_value: int in range(1, 120):
			var state := (
				TestPositions
				. position(
					{
						"west_north": ["blue", 12],
						"west_south": ["blue", 1],
						"east_north": ["red", 1],
						"east_south": ["red", 1],
					},
					rules,
					seed_value
				)
			)
			var result := Rules.apply(state, Action.attack("west_north", "east_north"))
			var entry: Dictionary = result.state.log[result.state.log.size() - 1]
			if not bool(entry["captured"]):
				continue
			var moved := int(entry["moved"])
			if mode == "one":
				assert_int(moved).is_equal(1)
			elif mode == "all":
				assert_int(result.state.army_count("west_north")).is_equal(1)
			else:
				assert_int(moved).is_equal((entry["attacker_rolls"] as Array).size())
			break


func test_the_setup_pool_can_be_resized() -> void:
	var rules := RuleSet.classic()
	rules.setup.distribution_pool = 2
	rules.setup.short_stack_bonus = 0
	var map := MapRepository.load_map("small-sea").map
	var players: Array[Player] = [Player.new("blue", "Blue"), Player.new("red", "Red", true)]
	var state := Rules.new_game(map, rules, players, 4)
	assert_int(int(state.to_place["blue"])).is_equal(2)
