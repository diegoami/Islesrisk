class_name StartScreen
extends Control
## Preset, players, go.
##
## Deliberately bare. Every option on this screen is paid for by every new
## player who has to read past it (DECISIONS.md, "Generic engine, Classic
## preset"): a preset, a number of players, and nothing else. The engine's
## generality is reachable through scenarios, not through a wall of toggles.

signal new_game_requested(players: int)
signal resume_requested

const SEA := Color("#1b4a63")
const SAND := Color("#d9c9a3")

var _players := 4


func _ready() -> void:
	var background := ColorRect.new()
	background.color = SEA
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.position = Vector2(-220, -170)
	column.custom_minimum_size = Vector2(440, 0)
	add_child(column)

	column.add_child(_label("MALPACO", 34))
	column.add_child(_label('Esperanto: "un-peace". Nothing you hold stays held.', 15))
	column.add_child(_label("", 8))
	column.add_child(_label("Preset:  Classic  —  Small Sea, 14 provinces", 15))

	var seats := HBoxContainer.new()
	seats.alignment = BoxContainer.ALIGNMENT_CENTER
	seats.add_theme_constant_override("separation", 8)
	column.add_child(seats)
	seats.add_child(_label("Players:", 15))
	for count: int in [2, 3, 4]:
		var choice := Button.new()
		choice.text = str(count)
		choice.toggle_mode = true
		choice.button_pressed = count == _players
		choice.pressed.connect(_on_player_count.bind(count, seats))
		seats.add_child(choice)

	column.add_child(
		_label("All seats are human for now — hot-seat. AI opponents arrive next.", 13)
	)
	column.add_child(_label("", 8))

	var start := Button.new()
	start.text = "New game"
	start.pressed.connect(func() -> void: new_game_requested.emit(_players))
	column.add_child(start)

	if GameArchive.has_save():
		var resume := Button.new()
		resume.text = "Resume saved game"
		resume.pressed.connect(func() -> void: resume_requested.emit())
		column.add_child(resume)


func _on_player_count(count: int, seats: HBoxContainer) -> void:
	_players = count
	for child: Node in seats.get_children():
		if child is Button:
			(child as Button).button_pressed = (child as Button).text == str(count)


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", SAND)
	return label
