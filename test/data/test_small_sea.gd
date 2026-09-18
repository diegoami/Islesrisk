extends GdUnitTestSuite
## The shipped board, checked against the table in RULES.md.
##
## This is the "a broken map fails CI, not the game" half of the validator:
## whatever anyone edits in data/maps/, the gates notice.

const EXPECTED := {
	"north_reach": {"provinces": 4, "bonus": 3},
	"the_spine": {"provinces": 4, "bonus": 3},
	"warm_shoals": {"provinces": 3, "bonus": 2},
	"the_teeth": {"provinces": 3, "bonus": 4},
}


func test_small_sea_loads_and_validates() -> void:
	var result := MapRepository.load_map("small-sea")
	assert_array(result.errors).is_empty()
	assert_bool(result.ok()).is_true()


func test_small_sea_matches_the_specification() -> void:
	var map := MapRepository.load_map("small-sea").map
	assert_object(map).is_not_null()
	assert_int(map.size()).is_equal(14)
	assert_int(map.islands.size()).is_equal(4)

	for island_id: String in EXPECTED.keys():
		var island := map.island(island_id)
		(
			assert_object(island)
			. override_failure_message(
				"RULES.md names island '%s' but the map has no such island" % island_id
			)
			. is_not_null()
		)
		var wanted: Dictionary = EXPECTED[island_id]
		(
			assert_int(island.size())
			. override_failure_message(
				"%s should hold %d provinces" % [island_id, int(wanted["provinces"])]
			)
			. is_equal(int(wanted["provinces"]))
		)
		(
			assert_int(island.bonus)
			. override_failure_message("%s should be worth %d" % [island_id, int(wanted["bonus"])])
			. is_equal(int(wanted["bonus"]))
		)


## The flavour text in RULES.md makes a claim about the board. If the map stops
## honouring it, one of the two is wrong and someone should decide which.
func test_the_teeth_bleed_from_three_sea_entrances() -> void:
	var map := MapRepository.load_map("small-sea").map
	assert_int(_sea_entrances(map, "the_teeth")).is_equal(3)


func test_every_island_is_reachable_by_sea() -> void:
	var map := MapRepository.load_map("small-sea").map
	for island: Island in map.islands:
		(
			assert_int(_sea_entrances(map, island.id))
			. override_failure_message("island '%s' has no sea lane at all" % island.id)
			. is_greater(0)
		)


func test_every_province_fits_inside_the_board() -> void:
	var map := MapRepository.load_map("small-sea").map
	for province: Province in map.provinces:
		for point: Vector2 in province.polygon:
			(
				assert_bool(map.bounds.has_point(point))
				. override_failure_message(
					"province '%s' has a point outside the board: %s" % [province.id, str(point)]
				)
				. is_true()
			)


func test_a_missing_map_fails_with_a_reason() -> void:
	var result := MapRepository.load_map("no-such-map")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("no map file")


func _sea_entrances(map: GameMap, island_id: String) -> int:
	var total := 0
	for province: Province in map.provinces_of(island_id):
		total += province.sea_lanes.size()
	return total
