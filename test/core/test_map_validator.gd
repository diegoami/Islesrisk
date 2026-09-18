extends GdUnitTestSuite
## One test per rule, each breaking exactly one thing in an otherwise valid
## map. A validator nobody has watched reject anything is a validator that
## might not work.


func test_the_reference_map_is_valid() -> void:
	assert_array(MapValidator.problems(_valid_map())).is_empty()


# --- crossings --------------------------------------------------------------


func test_a_border_to_itself_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").borders = PackedStringArray(["west_north", "west_south"])
	assert_str(_report(map)).contains("border to itself")


func test_an_unreturned_border_is_caught() -> void:
	var map := _valid_map()
	map.province("west_south").borders = PackedStringArray([])
	assert_str(_report(map)).contains("is not returned")


func test_a_border_to_nowhere_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").borders = PackedStringArray(["west_south", "atlantis"])
	assert_str(_report(map)).contains("unknown province 'atlantis'")


func test_a_duplicated_crossing_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").borders = PackedStringArray(["west_south", "west_south"])
	assert_str(_report(map)).contains("twice")


## The mistake that turns an archipelago of provinces back into a scatter of
## one-province islands.
func test_a_land_border_between_islands_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").borders = PackedStringArray(["west_south", "east_north"])
	map.province("east_north").borders = PackedStringArray(["east_south", "west_north"])
	assert_str(_report(map)).contains("different islands")


func test_a_sea_lane_within_one_island_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").sea_lanes = PackedStringArray(["east_north", "west_south"])
	map.province("west_south").sea_lanes = PackedStringArray(["west_north"])
	assert_str(_report(map)).contains("same island")


# --- structure --------------------------------------------------------------


func test_an_island_split_in_two_by_land_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").borders = PackedStringArray([])
	map.province("west_south").borders = PackedStringArray([])
	assert_str(_report(map)).contains("not one landmass")


func test_a_board_in_two_pieces_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").sea_lanes = PackedStringArray([])
	map.province("east_north").sea_lanes = PackedStringArray([])
	assert_str(_report(map)).contains("not connected")


func test_a_duplicate_province_id_is_caught() -> void:
	var map := _valid_map()
	map.provinces[3].id = "west_north"
	assert_str(_report(map)).contains("duplicate province id")


func test_a_province_on_no_island_list_is_caught() -> void:
	var map := _valid_map()
	map.islands[0].provinces = PackedStringArray(["west_north"])
	assert_str(_report(map)).contains("on no island's list")


func test_an_unknown_island_is_caught() -> void:
	var map := _valid_map()
	map.province("west_south").island = "elsewhere"
	assert_str(_report(map)).contains("unknown island")


func test_an_island_with_no_provinces_is_caught() -> void:
	var map := _valid_map()
	map.islands.append(Island.new("ghost", "Ghost", 1, PackedStringArray()))
	assert_str(_report(map)).contains("no provinces")


func test_a_negative_bonus_is_caught() -> void:
	var map := _valid_map()
	map.islands[0].bonus = -1
	assert_str(_report(map)).contains("negative bonus")


# --- geometry ---------------------------------------------------------------


func test_a_border_between_shapes_that_do_not_meet_is_caught() -> void:
	var map := _valid_map()
	var stray := map.province("west_south")
	stray.polygon = PackedVector2Array(
		[Vector2(2000, 2000), Vector2(2100, 2000), Vector2(2100, 2100), Vector2(2000, 2100)]
	)
	stray.label_at = Vector2(2050, 2050)
	assert_str(_report(map)).contains("shapes do not meet")


func test_a_degenerate_polygon_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").polygon = PackedVector2Array(
		[Vector2(0, 0), Vector2(0.1, 0), Vector2(0.1, 0.1)]
	)
	assert_str(_report(map)).contains("degenerate area")


func test_too_few_polygon_points_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").polygon = PackedVector2Array([Vector2(0, 0), Vector2(10, 10)])
	assert_str(_report(map)).contains("fewer than 3")


func test_a_self_intersecting_polygon_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").polygon = PackedVector2Array(
		[Vector2(0, 0), Vector2(100, 100), Vector2(100, 0), Vector2(0, 100)]
	)
	assert_str(_report(map)).contains("self-intersecting")


func test_a_label_outside_its_province_is_caught() -> void:
	var map := _valid_map()
	map.province("west_north").label_at = Vector2(-500, -500)
	assert_str(_report(map)).contains("label point outside")


func test_an_empty_map_is_caught() -> void:
	var empty := GameMap.new(
		"none", "None", Rect2(0, 0, 10, 10), [] as Array[Province], [] as Array[Island]
	)
	assert_str(_report(empty)).contains("no provinces")


func _report(map: GameMap) -> String:
	var problems := MapValidator.problems(map)
	(
		assert_array(problems)
		. override_failure_message(
			"expected the validator to reject this map, but it found nothing"
		)
		. is_not_empty()
	)
	return "\n".join(problems)


## Two islands of two provinces each, stacked squares sharing an exact edge,
## linked by one sea lane.
func _valid_map() -> GameMap:
	var provinces: Array[Province] = [
		_province("west_north", "west", ["west_south"], ["east_north"], 60, 60),
		_province("west_south", "west", ["west_north"], [], 60, 160),
		_province("east_north", "east", ["east_south"], ["west_north"], 400, 60),
		_province("east_south", "east", ["east_north"], [], 400, 160),
	]
	var islands: Array[Island] = [
		Island.new("west", "West", 2, PackedStringArray(["west_north", "west_south"])),
		Island.new("east", "East", 1, PackedStringArray(["east_north", "east_south"])),
	]
	return GameMap.new("test-sea", "Test Sea", Rect2(0, 0, 600, 300), provinces, islands)


func _province(
	province_id: String, island: String, borders: Array, lanes: Array, x: float, y: float
) -> Province:
	var polygon := PackedVector2Array(
		[Vector2(x, y), Vector2(x + 100, y), Vector2(x + 100, y + 100), Vector2(x, y + 100)]
	)
	return Province.new(
		province_id,
		province_id.capitalize(),
		island,
		PackedStringArray(borders),
		PackedStringArray(lanes),
		polygon,
		Vector2(x + 50, y + 50)
	)
