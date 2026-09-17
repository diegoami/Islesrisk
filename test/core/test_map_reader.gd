extends GdUnitTestSuite
## Map JSON is untrusted input: it has to fail loudly, not partially.


func test_a_valid_map_reads() -> void:
	var result := MapReader.read(JSON.stringify(_valid_doc()))
	assert_array(result.errors).is_empty()
	assert_bool(result.ok()).is_true()
	assert_int(result.map.size()).is_equal(3)
	assert_str(result.map.name).is_equal("Test Sea")
	assert_int(result.map.archipelago("g").bonus).is_equal(2)


func test_geometry_survives_the_round_trip() -> void:
	var result := MapReader.read(JSON.stringify(_valid_doc()))
	var isle := result.map.isle("b")
	assert_int(isle.polygon.size()).is_equal(4)
	assert_vector(isle.label_at).is_equal(Vector2(200, 60))
	assert_array(Array(isle.neighbours)).contains(["a", "c"])


func test_text_that_is_not_json_is_refused() -> void:
	assert_bool(MapReader.read("this is not json").ok()).is_false()


func test_a_json_array_at_the_top_level_is_refused() -> void:
	var result := MapReader.read("[1, 2, 3]")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("top level")


func test_an_unknown_schema_is_refused_rather_than_guessed_at() -> void:
	var doc := _valid_doc()
	doc["schema"] = 99
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("unsupported schema")


func test_unknown_fields_are_refused_rather_than_ignored() -> void:
	var doc := _valid_doc()
	doc["colour_scheme"] = "nautical"
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("colour_scheme")


func test_a_missing_field_is_named() -> void:
	var doc := _valid_doc()
	doc.erase("isles")
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("isles")


func test_a_malformed_point_is_refused() -> void:
	var doc := _valid_doc()
	var isles: Array = doc["isles"]
	var first: Dictionary = isles[0]
	first["label_at"] = [1, 2, 3]
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("exactly two numbers")


func test_a_failed_read_returns_no_map_at_all() -> void:
	var doc := _valid_doc()
	doc["schema"] = 99
	assert_object(MapReader.read(JSON.stringify(doc)).map).is_null()


func _valid_doc() -> Dictionary:
	return {
		"schema": 1,
		"id": "test-sea",
		"name": "Test Sea",
		"bounds": {"x": 0, "y": 0, "width": 400, "height": 200},
		"archipelagos": [{"id": "g", "name": "Group", "bonus": 2, "isles": ["a", "b", "c"]}],
		"isles":
		[
			_isle("a", ["b"], 60, 60),
			_isle("b", ["a", "c"], 200, 60),
			_isle("c", ["b"], 340, 60),
		],
	}


func _isle(isle_id: String, neighbours: Array, cx: float, cy: float) -> Dictionary:
	return {
		"id": isle_id,
		"name": isle_id.to_upper(),
		"archipelago": "g",
		"neighbours": neighbours,
		"polygon": [[cx - 30, cy - 30], [cx + 30, cy - 30], [cx + 30, cy + 30], [cx - 30, cy + 30]],
		"label_at": [cx, cy],
	}
