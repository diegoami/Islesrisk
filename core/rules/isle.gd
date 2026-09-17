class_name Isle
extends RefCounted
## One territory: a shape on the board, a garrison, and a set of sea lanes.
##
## The polygon is plain geometry, not artwork. Generated maps produce isles no
## artist will ever see (ARCHITECTURE.md, "Looking good"), so nothing here
## describes how an isle looks — only where it is and what it touches.

var id: String
var name: String
var archipelago: String
## Authored and symmetric. Never derived from the geometry, so that a
## generated map and a drawn one behave identically.
var neighbours: PackedStringArray
var polygon: PackedVector2Array
var label_at: Vector2


func _init(
	isle_id: String,
	isle_name: String,
	archipelago_id: String,
	isle_neighbours: PackedStringArray,
	isle_polygon: PackedVector2Array,
	isle_label_at: Vector2
) -> void:
	id = isle_id
	name = isle_name
	archipelago = archipelago_id
	neighbours = isle_neighbours
	polygon = isle_polygon
	label_at = isle_label_at


## Shoelace formula. Always positive: winding order is the author's business,
## not the validator's.
func area() -> float:
	var total := 0.0
	var count := polygon.size()
	for i: int in count:
		var a := polygon[i]
		var b := polygon[(i + 1) % count]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5


func centroid() -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point: Vector2 in polygon:
		sum += point
	return sum / float(polygon.size())
