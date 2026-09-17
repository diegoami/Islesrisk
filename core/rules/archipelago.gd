class_name Archipelago
extends RefCounted
## A group of isles worth a reinforcement bonus to whoever holds all of them.

var id: String
var name: String
## Reinforcements per turn for holding every isle in the group.
var bonus: int
var isles: PackedStringArray


func _init(
	archipelago_id: String,
	archipelago_name: String,
	archipelago_bonus: int,
	isle_ids: PackedStringArray
) -> void:
	id = archipelago_id
	name = archipelago_name
	bonus = archipelago_bonus
	isles = isle_ids
