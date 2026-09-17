extends GdUnitTestSuite
## The shipped board, checked against the table in RULES.md.
##
## This is the "a broken map fails CI, not the game" half of the validator:
## whatever anyone edits in data/maps/, the gates notice.


func test_small_sea_loads_and_validates() -> void:
	var result := MapRepository.load_map("small-sea")
	assert_array(result.errors).is_empty()
	assert_bool(result.ok()).is_true()


func test_small_sea_matches_the_specification() -> void:
	var map := MapRepository.load_map("small-sea").map
	assert_object(map).is_not_null()
	assert_int(map.size()).is_equal(14)
	assert_int(map.archipelagos.size()).is_equal(4)

	var expected := {
		"north_reach": {"isles": 4, "bonus": 3},
		"the_chain": {"isles": 4, "bonus": 3},
		"warm_shoals": {"isles": 3, "bonus": 2},
		"the_teeth": {"isles": 3, "bonus": 4},
	}
	for group_id: String in expected.keys():
		var archipelago := map.archipelago(group_id)
		(
			assert_object(archipelago)
			. override_failure_message(
				"RULES.md names archipelago '%s' but the map has no such group" % group_id
			)
			. is_not_null()
		)
		var wanted: Dictionary = expected[group_id]
		(
			assert_int(archipelago.isles.size())
			. override_failure_message("%s should hold %d isles" % [group_id, int(wanted["isles"])])
			. is_equal(int(wanted["isles"]))
		)
		(
			assert_int(archipelago.bonus)
			. override_failure_message("%s should be worth %d" % [group_id, int(wanted["bonus"])])
			. is_equal(int(wanted["bonus"]))
		)


func test_every_isle_fits_inside_the_board() -> void:
	var map := MapRepository.load_map("small-sea").map
	for isle: Isle in map.isles:
		for point: Vector2 in isle.polygon:
			(
				assert_bool(map.bounds.has_point(point))
				. override_failure_message(
					"isle '%s' has a point outside the board bounds: %s" % [isle.id, str(point)]
				)
				. is_true()
			)


func test_a_missing_map_fails_with_a_reason() -> void:
	var result := MapRepository.load_map("no-such-map")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("no map file")
