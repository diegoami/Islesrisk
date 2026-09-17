extends GdUnitTestSuite
## One test per rule, each breaking exactly one thing in an otherwise valid
## map. A validator nobody has watched reject anything is a validator that
## might not work.


func test_the_reference_map_is_valid() -> void:
	assert_array(MapValidator.problems(_valid_map())).is_empty()


func test_a_self_neighbour_is_caught() -> void:
	var map := _valid_map()
	map.isle("b").neighbours = PackedStringArray(["b", "a", "c"])
	assert_str(_report(map)).contains("its own neighbour")


func test_an_unreturned_lane_is_caught() -> void:
	var map := _valid_map()
	map.isle("c").neighbours = PackedStringArray([])
	assert_str(_report(map)).contains("not returned")


func test_a_lane_to_nowhere_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").neighbours = PackedStringArray(["b", "atlantis"])
	assert_str(_report(map)).contains("unknown isle 'atlantis'")


func test_a_duplicated_lane_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").neighbours = PackedStringArray(["b", "b"])
	assert_str(_report(map)).contains("twice")


func test_a_split_board_is_caught() -> void:
	var map := _valid_map()
	map.isle("b").neighbours = PackedStringArray(["a"])
	map.isle("c").neighbours = PackedStringArray([])
	assert_str(_report(map)).contains("not connected")


func test_a_duplicate_isle_id_is_caught() -> void:
	var map := _valid_map()
	map.isles[2].id = "a"
	assert_str(_report(map)).contains("duplicate isle id")


func test_an_isle_in_no_archipelago_list_is_caught() -> void:
	var map := _valid_map()
	map.archipelagos[0].isles = PackedStringArray(["a", "b"])
	assert_str(_report(map)).contains("belongs to no archipelago")


func test_disagreeing_membership_is_caught() -> void:
	var map := _valid_map()
	map.isle("c").archipelago = "elsewhere"
	assert_str(_report(map)).contains("unknown archipelago")


func test_an_empty_archipelago_is_caught() -> void:
	var map := _valid_map()
	map.archipelagos.append(Archipelago.new("ghost", "Ghost", 1, PackedStringArray()))
	assert_str(_report(map)).contains("is empty")


func test_a_negative_bonus_is_caught() -> void:
	var map := _valid_map()
	map.archipelagos[0].bonus = -1
	assert_str(_report(map)).contains("negative bonus")


func test_a_degenerate_polygon_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").polygon = PackedVector2Array([Vector2(0, 0), Vector2(0.1, 0), Vector2(0.1, 0.1)])
	assert_str(_report(map)).contains("degenerate area")


func test_too_few_polygon_points_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").polygon = PackedVector2Array([Vector2(0, 0), Vector2(10, 10)])
	assert_str(_report(map)).contains("fewer than 3")


func test_a_self_intersecting_polygon_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").polygon = PackedVector2Array(
		[Vector2(0, 0), Vector2(100, 100), Vector2(100, 0), Vector2(0, 100)]
	)
	assert_str(_report(map)).contains("self-intersecting")


func test_a_label_outside_its_isle_is_caught() -> void:
	var map := _valid_map()
	map.isle("a").label_at = Vector2(-500, -500)
	assert_str(_report(map)).contains("label point outside")


func test_an_empty_map_is_caught() -> void:
	var empty := GameMap.new(
		"none", "None", Rect2(0, 0, 10, 10), [] as Array[Isle], [] as Array[Archipelago]
	)
	assert_str(_report(empty)).contains("no isles")


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


## A minimal valid board: three isles in a line, one archipelago.
func _valid_map() -> GameMap:
	var isles: Array[Isle] = [
		_isle("a", ["b"], 60, 60),
		_isle("b", ["a", "c"], 200, 60),
		_isle("c", ["b"], 340, 60),
	]
	var archipelagos: Array[Archipelago] = [
		Archipelago.new("g", "Group", 2, PackedStringArray(["a", "b", "c"])),
	]
	return GameMap.new("test-sea", "Test Sea", Rect2(0, 0, 400, 200), isles, archipelagos)


func _isle(isle_id: String, neighbours: Array, cx: float, cy: float) -> Isle:
	var polygon := PackedVector2Array(
		[
			Vector2(cx - 30, cy - 30),
			Vector2(cx + 30, cy - 30),
			Vector2(cx + 30, cy + 30),
			Vector2(cx - 30, cy + 30),
		]
	)
	return Isle.new(
		isle_id, isle_id.to_upper(), "g", PackedStringArray(neighbours), polygon, Vector2(cx, cy)
	)
