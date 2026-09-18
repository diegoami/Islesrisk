class_name GameMap
extends RefCounted
## A board: islands, the provinces that divide them, and the crossings between.
##
## Authored maps and generated maps are this same type and pass the same
## validator (SCENARIOS.md). Nothing downstream can tell them apart.

var id: String
var name: String
## The board's extent in its own coordinate space. The camera frames this, so
## the board is resolution-independent and a resize reframes rather than
## reflows.
var bounds: Rect2
var provinces: Array[Province]
var islands: Array[Island]

var _provinces_by_id: Dictionary = {}
var _islands_by_id: Dictionary = {}


func _init(
	map_id: String,
	map_name: String,
	map_bounds: Rect2,
	map_provinces: Array[Province],
	map_islands: Array[Island]
) -> void:
	id = map_id
	name = map_name
	bounds = map_bounds
	provinces = map_provinces
	islands = map_islands
	for province: Province in provinces:
		_provinces_by_id[province.id] = province
	for island: Island in islands:
		_islands_by_id[island.id] = island


## Null when there is no such province. The validator makes sure a loaded map
## never contains a dangling reference in the first place.
func province(province_id: String) -> Province:
	return _provinces_by_id.get(province_id) as Province


func island(island_id: String) -> Island:
	return _islands_by_id.get(island_id) as Island


func has_province(province_id: String) -> bool:
	return _provinces_by_id.has(province_id)


func province_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for province: Province in provinces:
		ids.append(province.id)
	return ids


func provinces_of(island_id: String) -> Array[Province]:
	var found: Array[Province] = []
	for province: Province in provinces:
		if province.island == island_id:
			found.append(province)
	return found


## Province count. The number that decides whether a board is small or large.
func size() -> int:
	return provinces.size()
