class_name Action
extends RefCounted
## What a player can do. Every change to a game goes through one of these, so a
## game is its seed plus its action list — which is what makes a save, a replay
## and a bug report the same small object.

enum Kind {
	PLACE,  ## put reinforcements on an owned province
	ATTACK,  ## declare one attack
	REDEPLOY,  ## move armies between two owned provinces
	END_PHASE,  ## done with this phase
	CONCEDE,  ## resign
}

var kind: Kind
var from_id: String
var to_id: String
var count: int


func _init(action_kind: Kind, from: String = "", to: String = "", amount: int = 0) -> void:
	kind = action_kind
	from_id = from
	to_id = to
	count = amount


static func place(province_id: String, amount: int) -> Action:
	return Action.new(Kind.PLACE, "", province_id, amount)


static func attack(from: String, to: String) -> Action:
	return Action.new(Kind.ATTACK, from, to)


static func redeploy(from: String, to: String, amount: int) -> Action:
	return Action.new(Kind.REDEPLOY, from, to, amount)


static func end_phase() -> Action:
	return Action.new(Kind.END_PHASE)


static func concede() -> Action:
	return Action.new(Kind.CONCEDE)


func describe() -> String:
	match kind:
		Kind.PLACE:
			return "place %d on %s" % [count, to_id]
		Kind.ATTACK:
			return "attack %s from %s" % [to_id, from_id]
		Kind.REDEPLOY:
			return "move %d from %s to %s" % [count, from_id, to_id]
		Kind.END_PHASE:
			return "end phase"
		Kind.CONCEDE:
			return "concede"
	return "unknown action"
