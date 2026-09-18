class_name Island
extends RefCounted
## A landmass, divided into provinces, worth a bonus to whoever holds all of
## it. The Risk "continent", and the reason holding ground is worth more than
## the sum of its parts.

var id: String
var name: String
## Reinforcements per turn for holding every province on the island.
var bonus: int
var provinces: PackedStringArray


func _init(
	island_id: String, island_name: String, island_bonus: int, province_ids: PackedStringArray
) -> void:
	id = island_id
	name = island_name
	bonus = island_bonus
	provinces = province_ids


func size() -> int:
	return provinces.size()
