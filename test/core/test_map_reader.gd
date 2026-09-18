extends GdUnitTestSuite
## Map JSON is untrusted input: it has to fail loudly, not partially.


func test_a_valid_map_reads() -> void:
	var result := MapReader.read(JSON.stringify(_valid_doc()))
	assert_array(result.errors).is_empty()
	assert_bool(result.ok()).is_true()
	assert_int(result.map.size()).is_equal(4)
	assert_int(result.map.islands.size()).is_equal(2)
	assert_int(result.map.island("west").bonus).is_equal(2)


func test_the_two_kinds_of_crossing_survive_the_round_trip() -> void:
	var map := MapReader.read(JSON.stringify(_valid_doc())).map
	var north := map.province("west_north")
	assert_array(Array(north.borders)).is_equal(["west_south"])
	assert_array(Array(north.sea_lanes)).is_equal(["east_north"])
	assert_array(Array(north.neighbours())).contains(["west_south", "east_north"])
	assert_bool(north.is_coastal()).is_true()


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
	doc.erase("provinces")
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("provinces")


func test_a_malformed_point_is_refused() -> void:
	var doc := _valid_doc()
	var provinces: Array = doc["provinces"]
	var first: Dictionary = provinces[0]
	first["label_at"] = [1, 2, 3]
	var result := MapReader.read(JSON.stringify(doc))
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("exactly two numbers")


func test_a_failed_read_returns_no_map_at_all() -> void:
	var doc := _valid_doc()
	doc["schema"] = 99
	assert_object(MapReader.read(JSON.stringify(doc)).map).is_null()


## Two islands of two provinces each. Provinces on an island share an edge
## exactly; the islands are linked by one sea lane.
func _valid_doc() -> Dictionary:
	return {
		"schema": 1,
		"id": "test-sea",
		"name": "Test Sea",
		"bounds": {"x": 0, "y": 0, "width": 600, "height": 300},
		"islands":
		[
			{"id": "west", "name": "West", "bonus": 2, "provinces": ["west_north", "west_south"]},
			{"id": "east", "name": "East", "bonus": 1, "provinces": ["east_north", "east_south"]},
		],
		"provinces":
		[
			_province("west_north", "west", ["west_south"], ["east_north"], 60, 60),
			_province("west_south", "west", ["west_north"], [], 60, 160),
			_province("east_north", "east", ["east_south"], ["west_north"], 400, 60),
			_province("east_south", "east", ["east_north"], [], 400, 160),
		],
	}


## A 100x100 square whose top and bottom edges are shared exactly with the
## province above and below it.
func _province(
	province_id: String, island: String, borders: Array, lanes: Array, x: float, y: float
) -> Dictionary:
	return {
		"id": province_id,
		"name": province_id.capitalize(),
		"island": island,
		"borders": borders,
		"sea_lanes": lanes,
		"polygon": [[x, y], [x + 100, y], [x + 100, y + 100], [x, y + 100]],
		"label_at": [x + 50, y + 50],
	}
