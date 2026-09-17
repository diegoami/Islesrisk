class_name MapReadResult
extends RefCounted
## What came back from reading a map: a map, or the reasons there isn't one.

var map: GameMap
var errors: Array[String]


func _init(read_map: GameMap, read_errors: Array[String]) -> void:
	map = read_map
	errors = read_errors


func ok() -> bool:
	return map != null and errors.is_empty()


static func failure(messages: Array[String]) -> MapReadResult:
	return MapReadResult.new(null, messages)
