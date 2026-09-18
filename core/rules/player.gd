class_name Player
extends RefCounted
## A seat at the table. Nothing in the engine knows the difference between a
## human and an AI: both submit actions through the same API.
##
## No colour here. Colour is presentation, and core/ has no opinion about how
## a game looks.

var id: String
var name: String
var is_ai: bool
var eliminated: bool = false


func _init(player_id: String, player_name: String, ai: bool = false) -> void:
	id = player_id
	name = player_name
	is_ai = ai


func clone() -> Player:
	var copy := Player.new(id, name, is_ai)
	copy.eliminated = eliminated
	return copy
