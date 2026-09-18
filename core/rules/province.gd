class_name Province
extends RefCounted
## One territory: the unit of ownership, a piece of an island.
##
## Provinces tile a landmass rather than floating separately — a few islands,
## each divided into provinces, as in Isle Wars (46 countries across 9
## continents), Risk, or Imperialism 2. The polygon is geometry, not artwork.
##
## Adjacency comes in two kinds and they are kept apart deliberately:
## a **border** is land, always within the same island; a **sea lane** crosses
## water to another island. The rules may one day treat them differently —
## crossing water is the obvious thing to make harder — and a map that has
## already lost the distinction cannot get it back.

var id: String
var name: String
var island: String
## Land neighbours. Same island, shared border, authored and symmetric.
var borders: PackedStringArray
## Water neighbours. Always on a different island.
var sea_lanes: PackedStringArray
var polygon: PackedVector2Array
var label_at: Vector2


func _init(
	province_id: String,
	province_name: String,
	island_id: String,
	land_borders: PackedStringArray,
	water_lanes: PackedStringArray,
	province_polygon: PackedVector2Array,
	province_label_at: Vector2
) -> void:
	id = province_id
	name = province_name
	island = island_id
	borders = land_borders
	sea_lanes = water_lanes
	polygon = province_polygon
	label_at = province_label_at


## Everywhere an army could go from here. What the rules ask for; they do not
## care which kind of crossing it is unless a rule says they should.
func neighbours() -> PackedStringArray:
	var all := PackedStringArray(borders)
	all.append_array(sea_lanes)
	return all


func is_coastal() -> bool:
	return not sea_lanes.is_empty()


## Shoelace formula. Always positive: winding order is the author's business.
func area() -> float:
	var total := 0.0
	var count := polygon.size()
	for i: int in count:
		var a := polygon[i]
		var b := polygon[(i + 1) % count]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5
