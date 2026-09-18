class_name PlayScreen
extends Node2D
## The playable board: turns clicks into actions and shows what the engine did.
##
## Holds no rules. Every legality question goes to the engine, so the screen
## and the AI cannot disagree about what is allowed — the UI declines to
## *offer* an illegal action, and the engine would reject it anyway
## (ARCHITECTURE.md).

signal game_finished(state: GameState)
signal state_changed(state: GameState)

const HAZARD_COLOURS := {
	"flood": Color("#5fa8d3"),
	"quake": Color("#b5651d"),
	"revolt": Color("#c23b22"),
	"centre_moved": Color("#f0c674"),
}
const EVENT_LINES := 6

var _state: GameState
var _board: BoardView
var _selected := ""

var _title: Label
var _instruction: Label
var _message: Label
var _events: Label
var _end_phase: Button
var _concede: Button


func _ready() -> void:
	_board = BoardView.new()
	add_child(_board)
	_board.province_clicked.connect(_on_province_clicked)
	_build_hud()


func start(state: GameState) -> void:
	_state = state
	_selected = ""
	_refresh()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 24)
	top.add_child(bar)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	bar.add_child(_title)

	_instruction = Label.new()
	_instruction.add_theme_font_size_override("font_size", 14)
	bar.add_child(_instruction)

	_end_phase = Button.new()
	_end_phase.text = "End phase"
	_end_phase.pressed.connect(_on_end_phase)
	bar.add_child(_end_phase)

	_concede = Button.new()
	_concede.text = "Concede"
	_concede.pressed.connect(_on_concede)
	bar.add_child(_concede)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 15)
	_message.add_theme_color_override("font_color", Color("#e2705a"))
	_message.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_message.position = Vector2(0, -80)
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_message)

	_events = Label.new()
	_events.add_theme_font_size_override("font_size", 13)
	_events.add_theme_color_override("font_color", Color("#d9c9a3"))
	_events.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_events.position = Vector2(16, -140)
	_events.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_events)


# --- input ------------------------------------------------------------------


func _on_province_clicked(province_id: String) -> void:
	if _state == null or _state.phase == GameState.Phase.FINISHED:
		return
	match _state.phase:
		GameState.Phase.SETUP, GameState.Phase.REINFORCE:
			_apply(Action.place(province_id, 1))
		GameState.Phase.ATTACK:
			_click_in_attack(province_id)
		GameState.Phase.REDEPLOY:
			_click_in_redeploy(province_id)


func _click_in_attack(province_id: String) -> void:
	var mover := _state.active_player()
	if _selected.is_empty() or _state.owns(mover.id, province_id):
		_select(province_id)
		return
	var refusal := CombatResolver.why_not(_state, _selected, province_id)
	if not refusal.is_empty():
		_say(refusal)
		return
	_apply(Action.attack(_selected, province_id))


func _click_in_redeploy(province_id: String) -> void:
	var mover := _state.active_player()
	if not _state.owns(mover.id, province_id):
		_say("that is not yours")
		return
	if _selected.is_empty() or _selected == province_id:
		_select(province_id)
		return
	# One move per turn, so it is a single decision: everything but the
	# garrison goes. The instruction line says so before the click.
	_apply(Action.redeploy(_selected, province_id, maxi(1, _state.army_count(_selected) - 1)))


func _select(province_id: String) -> void:
	var mover := _state.active_player()
	if not _state.owns(mover.id, province_id):
		_selected = ""
		_board.set_selection("", PackedStringArray())
		return
	_selected = province_id
	_board.set_selection(province_id, _targets_from(province_id))
	_say("")


func _targets_from(province_id: String) -> PackedStringArray:
	var targets := PackedStringArray()
	var province := _state.map.province(province_id)
	if province == null:
		return targets
	for neighbour_id: String in province.neighbours():
		if _state.phase == GameState.Phase.ATTACK:
			if CombatResolver.why_not(_state, province_id, neighbour_id).is_empty():
				targets.append(neighbour_id)
		elif _state.phase == GameState.Phase.REDEPLOY:
			if _state.owns(_state.active_player().id, neighbour_id):
				targets.append(neighbour_id)
	return targets


func _on_end_phase() -> void:
	_apply(Action.end_phase())


func _on_concede() -> void:
	_apply(Action.concede())


# --- engine -----------------------------------------------------------------


func _apply(action: Action) -> void:
	var before := _state.log.size()
	var result := Rules.apply(_state, action)
	if not result.ok():
		_say(result.error)
		return
	_state = result.state
	_selected = ""
	_show_new_events(before)
	_refresh()
	state_changed.emit(_state)
	if _state.phase == GameState.Phase.FINISHED:
		game_finished.emit(_state)


## Hazards and centre moves must be *seen* as they happen. A rubber band the
## player cannot perceive reads as the game being arbitrary.
func _show_new_events(from_index: int) -> void:
	for i: int in range(from_index, _state.log.size()):
		var entry: Dictionary = _state.log[i]
		var event := str(entry.get("event", ""))
		if HAZARD_COLOURS.has(event):
			var where := str(entry.get("province", entry.get("to", "")))
			if not where.is_empty():
				_board.flash(where, HAZARD_COLOURS[event] as Color)


func _refresh() -> void:
	_board.show_state(_state)
	_board.set_selection(
		_selected, _targets_from(_selected) if not _selected.is_empty() else PackedStringArray()
	)
	_update_hud()


func _update_hud() -> void:
	var mover := _state.active_player()
	if mover == null:
		return
	_title.text = "%s  ·  round %d" % [mover.name, _state.turn_number]
	_title.add_theme_color_override("font_color", PlayerPalette.for_player(_state, mover.id))

	var pool := int(_state.to_place.get(mover.id, 0))
	match _state.phase:
		GameState.Phase.SETUP:
			_instruction.text = "Opening armies — click a province to place one (%d left)" % pool
		GameState.Phase.REINFORCE:
			_instruction.text = "Reinforce — click your provinces to place (%d left)" % pool
		GameState.Phase.ATTACK:
			var attacks := Rules.legal_attacks(_state).size()
			if attacks == 0:
				_instruction.text = "Attack — nothing can be attacked from here; end the phase"
			elif _selected.is_empty():
				_instruction.text = (
					"Attack — click one of your provinces (%d attacks available)" % attacks
				)
			else:
				_instruction.text = "Attack — click a red-ringed province, or another of yours"
		GameState.Phase.REDEPLOY:
			if _state.redeploys_left <= 0:
				_instruction.text = "Redeploy — used; end the turn"
			elif _selected.is_empty():
				_instruction.text = "Redeploy — click a province to move armies from (1 move)"
			else:
				_instruction.text = "Redeploy — click a neighbour; all but one army will move"
	_end_phase.disabled = _state.phase == GameState.Phase.SETUP
	_concede.disabled = _state.phase == GameState.Phase.SETUP

	var lines := PackedStringArray()
	var start := maxi(0, _state.log.size() - EVENT_LINES)
	for i: int in range(start, _state.log.size()):
		lines.append(_describe(_state.log[i]))
	_events.text = "\n".join(lines)


func _describe(entry: Dictionary) -> String:
	var event := str(entry.get("event", ""))
	var where := _name_of(str(entry.get("province", "")))
	var line := ""
	match event:
		"attack":
			line = _describe_attack(entry)
		"flood":
			line = "A flood struck %s" % where
		"quake":
			line = "An earthquake shook %s" % where
		"revolt":
			line = "%s rose in revolt" % where
		"centre_moved":
			line = "A production centre moved to %s" % _name_of(str(entry.get("to", "")))
		"redeploy":
			line = (
				"Moved %d to %s" % [int(entry.get("count", 0)), _name_of(str(entry.get("to", "")))]
			)
		"eliminated":
			line = "%s is out" % str(entry.get("player", ""))
		"victory":
			line = "%s wins" % str(entry.get("player", ""))
	return line


func _describe_attack(entry: Dictionary) -> String:
	var from := _name_of(str(entry.get("from", "")))
	var to := _name_of(str(entry.get("to", "")))
	if bool(entry.get("penalty", false)):
		return "%s attacked %s, failed, and lost the province" % [from, to]
	if bool(entry.get("captured", false)):
		return "%s took %s" % [from, to]
	return (
		"%s attacked %s — %d lost, %d taken"
		% [
			from,
			to,
			int(entry.get("attacker_losses", 0)),
			int(entry.get("defender_losses", 0)),
		]
	)


func _name_of(province_id: String) -> String:
	var province := _state.map.province(province_id)
	return province.name if province != null else province_id


func _say(message: String) -> void:
	_message.text = message
