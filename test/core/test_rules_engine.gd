extends GdUnitTestSuite
## The Classic checklist from RULES.md, one test per rule.

# --- the match rule ---------------------------------------------------------


func test_an_attacker_may_match_the_defender() -> void:
	var state := TestPositions.standoff(4, 4)
	assert_str(CombatResolver.why_not(state, "west_north", "east_north")).is_empty()


func test_an_attacker_may_not_be_weaker_than_the_defender() -> void:
	var state := TestPositions.standoff(4, 5)
	assert_str(CombatResolver.why_not(state, "west_north", "east_north")).contains("match")


func test_an_attacker_stronger_than_the_defender_may_attack() -> void:
	var state := TestPositions.standoff(5, 4)
	assert_str(CombatResolver.why_not(state, "west_north", "east_north")).is_empty()


func test_an_attack_below_the_minimum_garrison_is_refused() -> void:
	var state := TestPositions.standoff(1, 1)
	assert_str(CombatResolver.why_not(state, "west_north", "east_north")).contains("at least")


func test_a_non_adjacent_attack_is_refused() -> void:
	var state := TestPositions.standoff(6, 1)
	assert_str(CombatResolver.why_not(state, "west_north", "east_south")).contains("does not reach")


func test_attacking_your_own_province_is_refused() -> void:
	var state := TestPositions.standoff(6, 1)
	assert_str(CombatResolver.why_not(state, "west_north", "west_south")).contains("already yours")


func test_attacking_from_a_province_you_do_not_hold_is_refused() -> void:
	var state := TestPositions.standoff(6, 1)
	assert_str(CombatResolver.why_not(state, "east_north", "west_north")).contains("do not hold")


# --- resolution -------------------------------------------------------------


## Run many attacks and check every one against the dice it actually rolled.
## That covers ties wherever they turn up, without pretending to control the
## generator.
func test_every_resolved_attack_matches_the_dice_it_rolled() -> void:
	var checked := 0
	for seed_value: int in range(1, 60):
		var state := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 8],
					"west_south": ["blue", 1],
					"east_north": ["red", 6],
					"east_south": ["red", 1],
				},
				null,
				seed_value
			)
		)
		var before_attacker := state.army_count("west_north")
		var before_defender := state.army_count("east_north")
		var result := Rules.apply(state, Action.attack("west_north", "east_north"))
		assert_bool(result.ok()).is_true()

		var entry: Dictionary = result.state.log[result.state.log.size() - 1]
		var attacker_rolls: Array = entry["attacker_rolls"]
		var defender_rolls: Array = entry["defender_rolls"]
		var expected_attacker_losses := 0
		var expected_defender_losses := 0
		for i: int in mini(attacker_rolls.size(), defender_rolls.size()):
			# Defender wins ties under Classic.
			if int(attacker_rolls[i]) > int(defender_rolls[i]):
				expected_defender_losses += 1
			else:
				expected_attacker_losses += 1
		assert_int(int(entry["attacker_losses"])).is_equal(expected_attacker_losses)
		assert_int(int(entry["defender_losses"])).is_equal(expected_defender_losses)

		if not bool(entry["captured"]):
			assert_int(result.state.army_count("west_north")).is_equal(
				before_attacker - expected_attacker_losses
			)
			assert_int(result.state.army_count("east_north")).is_equal(
				before_defender - expected_defender_losses
			)
		checked += 1
	assert_int(checked).is_greater(50)


func test_the_attacker_rolls_at_most_three_dice_and_the_defender_two() -> void:
	var state := TestPositions.standoff(9, 9)
	var result := Rules.apply(state, Action.attack("west_north", "east_north"))
	var entry: Dictionary = result.state.log[result.state.log.size() - 1]
	assert_int((entry["attacker_rolls"] as Array).size()).is_equal(3)
	assert_int((entry["defender_rolls"] as Array).size()).is_equal(2)


func test_a_capture_takes_the_province_and_leaves_one_army_behind() -> void:
	var captured := false
	for seed_value: int in range(1, 200):
		var state := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 12],
					"west_south": ["blue", 1],
					"east_north": ["red", 1],
					"east_south": ["red", 1],
				},
				null,
				seed_value
			)
		)
		var result := Rules.apply(state, Action.attack("west_north", "east_north"))
		var entry: Dictionary = result.state.log[result.state.log.size() - 1]
		if not bool(entry["captured"]):
			continue
		captured = true
		assert_str(result.state.owner("east_north")).is_equal("blue")
		assert_int(result.state.army_count("east_north")).is_greater(0)
		assert_int(result.state.army_count("west_north")).is_greater(0)
		assert_int(result.state.army_count("east_north")).is_equal(int(entry["moved"]))
		break
	(
		assert_bool(captured)
		. override_failure_message("12 armies never took a province defended by 1 in 200 tries")
		. is_true()
	)


## The penalty is what makes the match rule bite: an attack is a commitment.
func test_a_failed_attack_down_to_one_army_loses_the_province_and_ends_the_phase() -> void:
	var seen := false
	for seed_value: int in range(1, 400):
		var state := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 2],
					"west_south": ["blue", 5],
					"east_north": ["red", 2],
					"east_south": ["red", 1],
				},
				null,
				seed_value
			)
		)
		var result := Rules.apply(state, Action.attack("west_north", "east_north"))
		var entry: Dictionary = result.state.log[result.state.log.size() - 1]
		if not bool(entry["penalty"]):
			continue
		seen = true
		assert_str(result.state.owner("west_north")).is_equal("red")
		assert_int(result.state.army_count("west_north")).is_equal(1)
		assert_int(result.state.phase).is_equal(GameState.Phase.REDEPLOY)
		break
	(
		assert_bool(seen)
		. override_failure_message("no failed attack ever triggered the penalty in 400 tries")
		. is_true()
	)


func test_the_penalty_can_be_turned_off() -> void:
	var rules := RuleSet.classic()
	rules.combat.failure_penalty = "none"
	for seed_value: int in range(1, 200):
		var state := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 2],
					"west_south": ["blue", 5],
					"east_north": ["red", 2],
					"east_south": ["red", 1],
				},
				rules,
				seed_value
			)
		)
		var result := Rules.apply(state, Action.attack("west_north", "east_north"))
		var entry: Dictionary = result.state.log[result.state.log.size() - 1]
		assert_bool(bool(entry["penalty"])).is_false()
		if result.state.army_count("west_north") <= 1 and not bool(entry["captured"]):
			assert_str(result.state.owner("west_north")).is_equal("blue")
			return


# --- reinforcement ----------------------------------------------------------


func test_the_reinforcement_floor_applies_to_a_player_down_to_one_province() -> void:
	var state := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 1],
				"west_south": ["red", 1],
				"east_north": ["red", 1],
				"east_south": ["red", 1],
			}
		)
	)
	assert_int(Rules.reinforcements_for(state, "blue")).is_equal(state.rules.reinforcement.minimum)


func test_an_island_bonus_needs_every_province_on_it() -> void:
	var partial := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 1],
				"west_south": ["red", 1],
				"east_north": ["red", 1],
				"east_south": ["red", 1],
			}
		)
	)
	var whole := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 1],
				"west_south": ["blue", 1],
				"east_north": ["red", 1],
				"east_south": ["red", 1],
			}
		)
	)
	assert_int(Rules.reinforcements_for(whole, "blue")).is_equal(
		Rules.reinforcements_for(partial, "blue") + 2
	)


func test_centres_are_worth_their_bonus() -> void:
	var without := TestPositions.standoff(1, 1)
	var with_centre := TestPositions.standoff(1, 1)
	with_centre.centres = PackedStringArray(["west_north"])
	assert_int(Rules.reinforcements_for(with_centre, "blue")).is_equal(
		Rules.reinforcements_for(without, "blue") + without.rules.reinforcement.centre_bonus
	)


# --- turn machinery ---------------------------------------------------------


func test_one_redeploy_per_turn() -> void:
	var state := TestPositions.standoff(5, 1)
	state.phase = GameState.Phase.REDEPLOY
	state.redeploys_left = state.rules.redeploy.moves_per_turn

	var first := Rules.apply(state, Action.redeploy("west_north", "west_south", 2))
	assert_bool(first.ok()).is_true()
	var second := Rules.apply(first.state, Action.redeploy("west_north", "west_south", 1))
	assert_bool(second.ok()).is_false()
	assert_str(second.error).contains("no redeploys left")


func test_a_redeploy_must_leave_one_army_behind() -> void:
	var state := TestPositions.standoff(3, 1)
	state.phase = GameState.Phase.REDEPLOY
	state.redeploys_left = 1
	var result := Rules.apply(state, Action.redeploy("west_north", "west_south", 3))
	assert_bool(result.ok()).is_false()
	assert_str(result.error).contains("one army must stay behind")


func test_taking_the_last_province_ends_the_game_at_once() -> void:
	var state := (
		TestPositions
		. position(
			{
				"west_north": ["blue", 12],
				"west_south": ["blue", 4],
				"east_north": ["red", 1],
				"east_south": ["blue", 3],
			}
		)
	)
	for attempt: int in range(1, 200):
		var attacking := (
			TestPositions
			. position(
				{
					"west_north": ["blue", 12],
					"west_south": ["blue", 4],
					"east_north": ["red", 1],
					"east_south": ["blue", 3],
				},
				null,
				attempt
			)
		)
		var result := Rules.apply(attacking, Action.attack("west_north", "east_north"))
		if result.state.owner("east_north") != "blue":
			continue
		assert_int(result.state.phase).is_equal(GameState.Phase.FINISHED)
		assert_str(result.state.winner).is_equal("blue")
		assert_bool(result.state.player("red").eliminated).is_true()
		return
	fail("blue never took the last province")


func test_actions_never_mutate_the_state_they_were_given() -> void:
	var state := TestPositions.standoff(8, 2)
	var before := state.army_count("west_north")
	var result := Rules.apply(state, Action.attack("west_north", "east_north"))
	assert_bool(result.ok()).is_true()
	(
		assert_int(state.army_count("west_north"))
		. override_failure_message(
			"apply() mutated its argument — replay and AI search both depend on it not doing that"
		)
		. is_equal(before)
	)
