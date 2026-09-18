extends Node2D
## The shell: start screen, board, result screen, and the save between them.

const DEFAULT_MAP := "small-sea"
const SEAT_NAMES: Array[String] = ["Blue", "Amber", "Green", "Violet"]

var _start: StartScreen
var _play: PlayScreen
var _result: ResultScreen
var _layer: CanvasLayer


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 2
	add_child(_layer)

	_start = StartScreen.new()
	_start.set_anchors_preset(Control.PRESET_FULL_RECT)
	_start.new_game_requested.connect(_on_new_game)
	_start.resume_requested.connect(_on_resume)
	_layer.add_child(_start)

	_result = ResultScreen.new()
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result.restart_requested.connect(_on_back_to_start)
	_result.visible = false
	_layer.add_child(_result)

	_play = PlayScreen.new()
	_play.visible = false
	_play.game_finished.connect(_on_finished)
	_play.state_changed.connect(_on_state_changed)
	add_child(_play)


func _on_new_game(players: int) -> void:
	var map_result := MapRepository.load_map(DEFAULT_MAP)
	if not map_result.ok():
		push_error("could not load %s: %s" % [DEFAULT_MAP, ", ".join(map_result.errors)])
		return
	var seats: Array[Player] = []
	for i: int in players:
		seats.append(Player.new(SEAT_NAMES[i].to_lower(), SEAT_NAMES[i]))
	var seed_value := int(Time.get_unix_time_from_system())
	_enter_game(Rules.new_game(map_result.map, RuleSet.classic(), seats, seed_value))


func _on_resume() -> void:
	var problems: Array[String] = []
	var state := GameArchive.load_saved(problems)
	if state == null:
		push_warning("could not resume: %s" % ", ".join(problems))
		return
	_enter_game(state)


func _enter_game(state: GameState) -> void:
	_start.visible = false
	_result.visible = false
	_play.visible = true
	_play.start(state)


func _on_state_changed(state: GameState) -> void:
	GameArchive.save(state)


func _on_finished(state: GameState) -> void:
	GameArchive.clear()
	_play.visible = false
	_result.visible = true
	_result.show_result(state)


func _on_back_to_start() -> void:
	_result.visible = false
	_play.visible = false
	_start.visible = true
