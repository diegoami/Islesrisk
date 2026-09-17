extends Control
## Iteration 0 title card. Deliberately plain: the board arrives in
## Iteration 1 and the look in Iteration 5 (ROADMAP.md).

const SEA := Color("#1b4a63")
const SAND := Color("#d9c9a3")


func _ready() -> void:
	var background := ColorRect.new()
	background.color = SEA
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	var lines := PackedStringArray(
		[
			"MALPACO",
			"",
			'Esperanto: "un-peace". Nothing you hold stays held.',
			"",
			(
				"v%s — Iteration 0, scaffolding. Godot %s"
				% [version, Engine.get_version_info()["string"]]
			),
		]
	)

	var label := Label.new()
	label.text = "\n".join(lines)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", SAND)
	add_child(label)
