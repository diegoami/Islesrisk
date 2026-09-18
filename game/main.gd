extends Node2D
## Iteration 1: load the Classic board and draw it.
##
## Flat colour on purpose. The board arrives before the look, because an art
## idea that only works on a hand-placed board is not usable (ARCHITECTURE.md).

const DEFAULT_MAP := "small-sea"
const SEA := Color("#1b4a63")
const SAND := Color("#d9c9a3")
const FAILURE := Color("#e08a7a")


func _ready() -> void:
	var result := MapRepository.load_map(DEFAULT_MAP)
	if not result.ok():
		_show_failure(result.errors)
		return

	var board := BoardView.new()
	add_child(board)
	board.show_map(result.map)
	_show_caption(
		(
			"%s — %d provinces on %d islands"
			% [result.map.name, result.map.size(), result.map.islands.size()]
		)
	)


## A map that fails validation loads nothing and says why, rather than starting
## a half-built game (ARCHITECTURE.md, "Loading data is a security boundary").
func _show_failure(errors: Array[String]) -> void:
	var background := ColorRect.new()
	background.color = SEA
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var label := Label.new()
	label.text = "Could not load the map:\n\n  %s" % "\n  ".join(errors)
	label.add_theme_color_override("font_color", FAILURE)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


func _show_caption(text: String) -> void:
	var caption := Label.new()
	var version := str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	caption.text = "MALPACO  ·  %s  ·  v%s, Iteration 1" % [text, version]
	caption.add_theme_color_override("font_color", SAND)
	caption.set_anchors_preset(Control.PRESET_TOP_WIDE)
	caption.position = Vector2(16.0, 12.0)
	add_child(caption)
