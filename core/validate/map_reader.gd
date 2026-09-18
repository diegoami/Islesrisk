class_name MapReader
extends RefCounted
## Turns map JSON into a GameMap, or into a list of reasons why not.
##
## Pure: it takes text, never a path. File reading lives in game/ because the
## purity guard keeps FileAccess out of core/ — which is also the right shape,
## since it puts I/O at the edge and leaves the parser testable with a string.
##
## Map data is untrusted input (ARCHITECTURE.md, "Loading data is a security
## boundary"): JSON only, never a Godot resource, unknown fields rejected
## rather than ignored, and everything capped. A file that fails here loads
## nothing and says why, instead of starting a half-built game.

const SCHEMA := 1

const MAX_PROVINCES := 512
const MAX_POLYGON_POINTS := 256
const MAX_NAME_LENGTH := 64
const MAX_ID_LENGTH := 64

const MAP_KEYS := ["schema", "id", "name", "bounds", "provinces", "islands"]
const PROVINCE_KEYS := ["id", "name", "island", "borders", "sea_lanes", "polygon", "label_at"]
const ISLAND_KEYS := ["id", "name", "bonus", "provinces"]
const BOUNDS_KEYS := ["x", "y", "width", "height"]


## Parses and then validates. A result is ok() only if both passed, so callers
## never have to remember to run the validator themselves.
static func read(json_text: String) -> MapReadResult:
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		return MapReadResult.failure(["not valid JSON"])
	if not parsed is Dictionary:
		return MapReadResult.failure(["top level must be a JSON object"])

	var root: Dictionary = parsed
	var errors: Array[String] = []
	errors.append_array(_unexpected_keys(root, MAP_KEYS, "map"))

	var schema := int(root.get("schema", -1))
	if schema != SCHEMA:
		errors.append("unsupported schema %d — this build reads %d" % [schema, SCHEMA])
		return MapReadResult.failure(errors)

	var islands: Array[Island] = []
	for entry: Variant in _array_at(root, "islands", errors, "map"):
		var island := _read_island(entry, errors)
		if island != null:
			islands.append(island)

	var raw_provinces: Array = _array_at(root, "provinces", errors, "map")
	if raw_provinces.size() > MAX_PROVINCES:
		errors.append("map has %d provinces; the cap is %d" % [raw_provinces.size(), MAX_PROVINCES])
		return MapReadResult.failure(errors)
	var provinces: Array[Province] = []
	for entry: Variant in raw_provinces:
		var province := _read_province(entry, errors)
		if province != null:
			provinces.append(province)

	if not errors.is_empty():
		return MapReadResult.failure(errors)

	var map := GameMap.new(
		_string_at(root, "id", errors, "map", MAX_ID_LENGTH),
		_string_at(root, "name", errors, "map", MAX_NAME_LENGTH),
		_read_bounds(root.get("bounds"), errors),
		provinces,
		islands
	)
	if not errors.is_empty():
		return MapReadResult.failure(errors)

	var invalid := MapValidator.problems(map)
	if not invalid.is_empty():
		return MapReadResult.failure(invalid)
	return MapReadResult.new(map, [])


static func _read_province(entry: Variant, errors: Array[String]) -> Province:
	if not entry is Dictionary:
		errors.append("a province entry is not an object")
		return null
	var raw: Dictionary = entry
	errors.append_array(_unexpected_keys(raw, PROVINCE_KEYS, "province"))

	var raw_polygon: Array = _array_at(raw, "polygon", errors, "province")
	if raw_polygon.size() > MAX_POLYGON_POINTS:
		errors.append(
			(
				"a province polygon has %d points; the cap is %d"
				% [raw_polygon.size(), MAX_POLYGON_POINTS]
			)
		)
		return null
	var polygon := PackedVector2Array()
	for point: Variant in raw_polygon:
		polygon.append(_read_point(point, errors))

	return Province.new(
		_string_at(raw, "id", errors, "province", MAX_ID_LENGTH),
		_string_at(raw, "name", errors, "province", MAX_NAME_LENGTH),
		_string_at(raw, "island", errors, "province", MAX_ID_LENGTH),
		_read_ids(raw, "borders", errors, "province"),
		_read_ids(raw, "sea_lanes", errors, "province"),
		polygon,
		_read_point(raw.get("label_at"), errors)
	)


static func _read_island(entry: Variant, errors: Array[String]) -> Island:
	if not entry is Dictionary:
		errors.append("an island entry is not an object")
		return null
	var raw: Dictionary = entry
	errors.append_array(_unexpected_keys(raw, ISLAND_KEYS, "island"))

	return Island.new(
		_string_at(raw, "id", errors, "island", MAX_ID_LENGTH),
		_string_at(raw, "name", errors, "island", MAX_NAME_LENGTH),
		int(raw.get("bonus", 0)),
		_read_ids(raw, "provinces", errors, "island")
	)


static func _read_ids(
	raw: Dictionary, key: String, errors: Array[String], context: String
) -> PackedStringArray:
	var ids := PackedStringArray()
	for value: Variant in _array_at(raw, key, errors, context):
		ids.append(str(value))
	return ids


static func _read_bounds(value: Variant, errors: Array[String]) -> Rect2:
	if not value is Dictionary:
		errors.append("map bounds must be an object with x, y, width, height")
		return Rect2()
	var raw: Dictionary = value
	errors.append_array(_unexpected_keys(raw, BOUNDS_KEYS, "bounds"))
	var width := float(raw.get("width", 0.0))
	var height := float(raw.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		errors.append("map bounds must have a positive width and height")
	return Rect2(float(raw.get("x", 0.0)), float(raw.get("y", 0.0)), width, height)


static func _read_point(value: Variant, errors: Array[String]) -> Vector2:
	if not value is Array:
		errors.append("a point must be a two-number array")
		return Vector2.ZERO
	var pair: Array = value
	if pair.size() != 2:
		errors.append("a point must have exactly two numbers, got %d" % pair.size())
		return Vector2.ZERO
	return Vector2(float(pair[0]), float(pair[1]))


static func _array_at(
	raw: Dictionary, key: String, errors: Array[String], context: String
) -> Array:
	var value: Variant = raw.get(key)
	if value == null:
		errors.append("%s is missing '%s'" % [context, key])
		return []
	if not value is Array:
		errors.append("%s field '%s' must be an array" % [context, key])
		return []
	return value


static func _string_at(
	raw: Dictionary, key: String, errors: Array[String], context: String, cap: int
) -> String:
	var value: Variant = raw.get(key)
	if value == null:
		errors.append("%s is missing '%s'" % [context, key])
		return ""
	var text := str(value)
	if text.length() > cap:
		errors.append("%s field '%s' is longer than %d characters" % [context, key, cap])
		return text.substr(0, cap)
	return text


## Rejecting unknown fields rather than ignoring them is deliberate: a typo in
## a hand-edited map, or a field from a newer build, is a thing to be told
## about, not to silently drop.
static func _unexpected_keys(raw: Dictionary, allowed: Array, context: String) -> Array[String]:
	var found: Array[String] = []
	for key: Variant in raw.keys():
		if not allowed.has(str(key)):
			found.append("%s has unknown field '%s'" % [context, str(key)])
	return found
