class_name ResultScreen
extends Control
## How it ended, and the seed that would produce it again.

signal restart_requested

const SEA := Color("#14384c")
const SAND := Color("#d9c9a3")


func show_result(state: GameState) -> void:
	for child: Node in get_children():
		child.queue_free()

	var background := ColorRect.new()
	background.color = SEA
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.add_theme_constant_override("separation", 12)
	column.position = Vector2(-240, -120)
	column.custom_minimum_size = Vector2(480, 0)
	add_child(column)

	var champion := state.player(state.winner)
	column.add_child(_label("%s wins" % (champion.name if champion != null else "Nobody"), 32))
	column.add_child(_label("after %d rounds" % state.turn_number, 16))
	column.add_child(_label("", 8))

	for each: Player in state.players:
		var held := state.provinces_of(each.id).size()
		column.add_child(
			_label(
				(
					"%s — %d provinces, %d armies%s"
					% [
						each.name,
						held,
						state.army_total(each.id),
						" (out)" if each.eliminated else ""
					]
				),
				14
			)
		)

	column.add_child(_label("", 8))
	# The seed is the whole game: with the rule set and the moves it replays
	# exactly, which is what makes a bug report worth sending.
	column.add_child(_label("seed %d" % int(state.rng.snapshot()["seed"]), 13))

	var again := Button.new()
	again.text = "Back to the start"
	again.pressed.connect(func() -> void: restart_requested.emit())
	column.add_child(again)


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", SAND)
	return label
