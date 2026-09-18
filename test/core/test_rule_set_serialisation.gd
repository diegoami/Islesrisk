extends GdUnitTestSuite
## A rule set has to survive a round trip through JSON intact, because a save
## stores its rules inline — that is what stops a tuning change to Classic from
## rewriting a game already in progress.


func test_classic_survives_a_round_trip() -> void:
	var original := RuleSet.classic()
	var restored := RuleSet.from_dict(
		JSON.parse_string(JSON.stringify(original.to_dict())) as Dictionary
	)
	assert_str(_digest(restored)).is_equal(_digest(original))


func test_every_changed_field_survives() -> void:
	var tuned := RuleSet.classic()
	tuned.id = "blitz"
	tuned.setup.distribution_pool = 4
	tuned.setup.deal = "random"
	tuned.reinforcement.minimum = 1
	tuned.reinforcement.per_province_divisor = 5
	tuned.reinforcement.island_bonus = "bySize"
	tuned.combat.attack_rule = "threshold"
	tuned.combat.attack_ratio = 1.5
	tuned.combat.ties = "attacker"
	tuned.combat.failure_penalty = "none"
	tuned.combat.capture = "all"
	tuned.combat.attacker_dice = RuleSet.Dice.new(4, 2)
	tuned.hazards.flood.chance = 0.5
	tuned.hazards.revolt.target = "random"
	tuned.centres.count = 7
	tuned.centres.wander_chance = 0.9
	tuned.cards.enabled = false
	tuned.victory = ["domination"]

	var restored := RuleSet.from_dict(
		JSON.parse_string(JSON.stringify(tuned.to_dict())) as Dictionary
	)
	assert_str(_digest(restored)).is_equal(_digest(tuned))
	assert_int(restored.combat.attacker_dice.count_for(10)).is_equal(4)


## A rule set written by an older build should still load, with this build's
## defaults filling the gaps.
func test_a_partial_rule_set_falls_back_to_the_defaults() -> void:
	var restored := RuleSet.from_dict({"id": "sparse", "combat": {"ties": "attacker"}})
	assert_str(restored.id).is_equal("sparse")
	assert_str(restored.combat.ties).is_equal("attacker")
	assert_int(restored.reinforcement.minimum).is_equal(RuleSet.classic().reinforcement.minimum)
	assert_bool(restored.hazards.enabled).is_true()


func _digest(rules: RuleSet) -> String:
	return JSON.stringify(rules.to_dict())
