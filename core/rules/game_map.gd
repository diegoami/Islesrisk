class_name GameMap
extends RefCounted
## A board: isles, the sea lanes between them, and the archipelago groupings.
##
## Authored maps and generated maps are this same type and pass the same
## validator (SCENARIOS.md). Nothing downstream can tell them apart.

var id: String
var name: String
## The board's extent in its own coordinate space. The camera frames this, so
## the board is resolution-independent and a resize reframes rather than
## reflows.
var bounds: Rect2
var isles: Array[Isle]
var archipelagos: Array[Archipelago]

var _by_id: Dictionary = {}
var _archipelagos_by_id: Dictionary = {}


func _init(
	map_id: String,
	map_name: String,
	map_bounds: Rect2,
	map_isles: Array[Isle],
	map_archipelagos: Array[Archipelago]
) -> void:
	id = map_id
	name = map_name
	bounds = map_bounds
	isles = map_isles
	archipelagos = map_archipelagos
	for isle: Isle in isles:
		_by_id[isle.id] = isle
	for archipelago: Archipelago in archipelagos:
		_archipelagos_by_id[archipelago.id] = archipelago


## Null when there is no such isle. Callers in core check; the validator makes
## sure a loaded map never contains a dangling reference in the first place.
func isle(isle_id: String) -> Isle:
	return _by_id.get(isle_id) as Isle


func archipelago(archipelago_id: String) -> Archipelago:
	return _archipelagos_by_id.get(archipelago_id) as Archipelago


func has_isle(isle_id: String) -> bool:
	return _by_id.has(isle_id)


func isle_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for isle: Isle in isles:
		ids.append(isle.id)
	return ids


func size() -> int:
	return isles.size()
