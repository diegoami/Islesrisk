class_name ActionResult
extends RefCounted
## What came back from applying an action: a new state, or the reason there
## isn't one. The engine never mutates the state it was given.

var state: GameState
var error: String


func _init(next_state: GameState, failure: String = "") -> void:
	state = next_state
	error = failure


func ok() -> bool:
	return error.is_empty()


static func rejected(reason: String) -> ActionResult:
	return ActionResult.new(null, reason)
