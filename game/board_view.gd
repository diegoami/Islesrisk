class_name BoardView
extends Node2D
## Draws whatever map it is given, at whatever size.
##
## Iteration 1: flat colour, deliberately. The look — water, coastlines,
## weather — is Iteration 5, and an art idea that only works on a hand-placed
## board is not usable anyway (ARCHITECTURE.md, "Looking good"), so this stage
## proves the renderer is indifferent to what the generator will later invent.

const SEA := Color("#1b4a63")
const LAND := Color("#d9c9a3")
## Temporary: tints land by archipelago so the grouping can be checked by eye
## against RULES.md. Ownership colour replaces this in Iteration 3 — these are
## deliberately muted variations of one sand, not a player palette.
const GROUP_TINTS: Array[Color] = [
	Color("#d9c9a3"),
	Color("#b5c4a1"),
	Color("#d6b39b"),
	Color("#a9bcc4"),
]
const COAST := Color("#3a2f22")
const LANE := Color("#2d6480")
const LABEL := Color("#3a2f22")

const COAST_WIDTH := 2.5
const LANE_WIDTH := 2.0
const VIEW_MARGIN := 1.06

var _map: GameMap
var _tint_by_archipelago: Dictionary = {}


func show_map(map: GameMap) -> void:
	_map = map
	_tint_by_archipelago.clear()
	for index: int in map.archipelagos.size():
		_tint_by_archipelago[map.archipelagos[index].id] = GROUP_TINTS[index % GROUP_TINTS.size()]
	for child: Node in get_children():
		child.queue_free()
	_draw_sea()
	_draw_lanes()
	for isle: Isle in map.isles:
		_draw_isle(isle)
	_frame_camera()


func _draw_sea() -> void:
	var sea := Polygon2D.new()
	sea.polygon = PackedVector2Array(
		[
			_map.bounds.position,
			_map.bounds.position + Vector2(_map.bounds.size.x, 0.0),
			_map.bounds.end,
			_map.bounds.position + Vector2(0.0, _map.bounds.size.y),
		]
	)
	sea.color = SEA
	add_child(sea)


## One line per lane, drawn once rather than twice — the graph is symmetric, so
## only the half where the ids sort ascending is drawn.
func _draw_lanes() -> void:
	for isle: Isle in _map.isles:
		for neighbour_id: String in isle.neighbours:
			if isle.id >= neighbour_id:
				continue
			var other := _map.isle(neighbour_id)
			if other == null:
				continue
			var lane := Line2D.new()
			lane.points = PackedVector2Array([isle.label_at, other.label_at])
			lane.width = LANE_WIDTH
			lane.default_color = LANE
			add_child(lane)


func _draw_isle(isle: Isle) -> void:
	var fill := Polygon2D.new()
	fill.polygon = isle.polygon
	fill.color = _tint_by_archipelago.get(isle.archipelago, LAND)
	add_child(fill)

	var coast := Line2D.new()
	coast.points = isle.polygon
	coast.closed = true
	coast.width = COAST_WIDTH
	coast.default_color = COAST
	coast.antialiased = true
	add_child(coast)

	var label := Label.new()
	label.text = isle.name
	label.add_theme_color_override("font_color", LABEL)
	label.position = isle.label_at - Vector2(60.0, 10.0)
	label.size = Vector2(120.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


## Fits the board's own coordinate space to the window, so a map of any size
## arrives framed and a resize reframes rather than reflows.
func _frame_camera() -> void:
	var camera := Camera2D.new()
	camera.position = _map.bounds.get_center()
	var viewport := get_viewport_rect().size
	if viewport.x > 0.0 and viewport.y > 0.0 and _map.bounds.size.x > 0.0:
		var scale_to_fit := minf(
			viewport.x / (_map.bounds.size.x * VIEW_MARGIN),
			viewport.y / (_map.bounds.size.y * VIEW_MARGIN)
		)
		camera.zoom = Vector2(scale_to_fit, scale_to_fit)
	camera.enabled = true
	add_child(camera)
