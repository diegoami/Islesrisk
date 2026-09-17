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

const MAX_ISLES := 512
const MAX_POLYGON_POINTS := 256
const MAX_NAME_LENGTH := 64
const MAX_ID_LENGTH := 64

const MAP_KEYS := ["schema", "id", "name", "bounds", "isles", "archipelagos"]
const ISLE_KEYS := ["id", "name", "archipelago", "neighbours", "polygon", "label_at"]
const ARCHIPELAGO_KEYS := ["id", "name", "bonus", "isles"]
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

	var archipelagos: Array[Archipelago] = []
	var raw_archipelagos: Array = _array_at(root, "archipelagos", errors, "map")
	for entry: Variant in raw_archipelagos:
		var archipelago := _read_archipelago(entry, errors)
		if archipelago != null:
			archipelagos.append(archipelago)

	var isles: Array[Isle] = []
	var raw_isles: Array = _array_at(root, "isles", errors, "map")
	if raw_isles.size() > MAX_ISLES:
		errors.append("map has %d isles; the cap is %d" % [raw_isles.size(), MAX_ISLES])
		return MapReadResult.failure(errors)
	for entry: Variant in raw_isles:
		var isle := _read_isle(entry, errors)
		if isle != null:
			isles.append(isle)

	if not errors.is_empty():
		return MapReadResult.failure(errors)

	var map := GameMap.new(
		_string_at(root, "id", errors, "map", MAX_ID_LENGTH),
		_string_at(root, "name", errors, "map", MAX_NAME_LENGTH),
		_read_bounds(root.get("bounds"), errors),
		isles,
		archipelagos
	)
	if not errors.is_empty():
		return MapReadResult.failure(errors)

	var invalid := MapValidator.problems(map)
	if not invalid.is_empty():
		return MapReadResult.failure(invalid)
	return MapReadResult.new(map, [])


static func _read_isle(entry: Variant, errors: Array[String]) -> Isle:
	if not entry is Dictionary:
		errors.append("an isle entry is not an object")
		return null
	var raw: Dictionary = entry
	errors.append_array(_unexpected_keys(raw, ISLE_KEYS, "isle"))

	var polygon := PackedVector2Array()
	var raw_polygon: Array = _array_at(raw, "polygon", errors, "isle")
	if raw_polygon.size() > MAX_POLYGON_POINTS:
		errors.append(
			(
				"an isle polygon has %d points; the cap is %d"
				% [raw_polygon.size(), MAX_POLYGON_POINTS]
			)
		)
		return null
	for point: Variant in raw_polygon:
		polygon.append(_read_point(point, errors))

	var neighbours := PackedStringArray()
	for neighbour: Variant in _array_at(raw, "neighbours", errors, "isle"):
		neighbours.append(str(neighbour))

	return Isle.new(
		_string_at(raw, "id", errors, "isle", MAX_ID_LENGTH),
		_string_at(raw, "name", errors, "isle", MAX_NAME_LENGTH),
		_string_at(raw, "archipelago", errors, "isle", MAX_ID_LENGTH),
		neighbours,
		polygon,
		_read_point(raw.get("label_at"), errors)
	)


static func _read_archipelago(entry: Variant, errors: Array[String]) -> Archipelago:
	if not entry is Dictionary:
		errors.append("an archipelago entry is not an object")
		return null
	var raw: Dictionary = entry
	errors.append_array(_unexpected_keys(raw, ARCHIPELAGO_KEYS, "archipelago"))

	var members := PackedStringArray()
	for member: Variant in _array_at(raw, "isles", errors, "archipelago"):
		members.append(str(member))

	return Archipelago.new(
		_string_at(raw, "id", errors, "archipelago", MAX_ID_LENGTH),
		_string_at(raw, "name", errors, "archipelago", MAX_NAME_LENGTH),
		int(raw.get("bonus", 0)),
		members
	)


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
