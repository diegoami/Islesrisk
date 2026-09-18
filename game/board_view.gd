class_name BoardView
extends Node2D
## The board: draws a game state and turns clicks into province ids.
##
## Everything is drawn in one `_draw()` rather than built as nodes, so a
## repaint after every action is one call and selection, hover and hazard
## flashes cost nothing to add. Flat colour on purpose — the look is
## Iteration 5, and an art idea that only works on a hand-placed board is not
## usable anyway (ARCHITECTURE.md, "Looking good").

signal province_clicked(province_id: String)

const SEA := Color("#1b4a63")
const COAST := Color("#2b241a")
const BORDER := Color("#6f6455")
const LANE := Color("#4a8099")
const SELECTED := Color("#f4e4bc")
const TARGET := Color("#e2705a")
const CENTRE := Color("#f0c674")
const TEXT := Color("#1c1710")
const TEXT_LIGHT := Color("#f6efe0")

const COAST_WIDTH := 4.0
const BORDER_WIDTH := 1.6
const LANE_WIDTH := 2.2
const EDGE_TOLERANCE := 2.0
const VIEW_MARGIN := 1.08
const LABEL_SIZE := 20
const ISLAND_LABEL_SIZE := 17
const FLASH_SECONDS := 1.2

var _state: GameState
var _selected := ""
var _targets := PackedStringArray()
var _hovered := ""
## province id -> {colour, remaining}. Hazards must be *seen*: a rubber band
## the player cannot perceive reads as the game being arbitrary.
var _flashes: Dictionary = {}
var _coast_cache: Array[PackedVector2Array] = []
var _camera: Camera2D


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.enabled = true
	add_child(_camera)
	set_process(true)


func show_state(state: GameState) -> void:
	var first := _state == null or _state.map != state.map
	_state = state
	if first:
		_rebuild_coastlines()
		_frame_camera()
	queue_redraw()


func set_selection(province_id: String, targets: PackedStringArray) -> void:
	_selected = province_id
	_targets = targets
	queue_redraw()


func flash(province_id: String, colour: Color) -> void:
	_flashes[province_id] = {"colour": colour, "remaining": FLASH_SECONDS}
	queue_redraw()


func _process(delta: float) -> void:
	if _flashes.is_empty():
		return
	for province_id: String in _flashes.keys():
		var entry: Dictionary = _flashes[province_id]
		entry["remaining"] = float(entry["remaining"]) - delta
		if float(entry["remaining"]) <= 0.0:
			_flashes.erase(province_id)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _state == null:
		return
	if event is InputEventMouseMotion:
		var under := _province_at(get_local_mouse_position())
		if under != _hovered:
			_hovered = under
			queue_redraw()
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			var hit := _province_at(get_local_mouse_position())
			if not hit.is_empty():
				province_clicked.emit(hit)
				get_viewport().set_input_as_handled()


func _province_at(point: Vector2) -> String:
	for province: Province in _state.map.provinces:
		if Geometry2D.is_point_in_polygon(point, province.polygon):
			return province.id
	return ""


func _draw() -> void:
	if _state == null:
		return
	var bounds := _state.map.bounds
	draw_rect(bounds, SEA, true)
	_draw_sea_lanes()

	for province: Province in _state.map.provinces:
		draw_colored_polygon(province.polygon, _fill_for(province))
	for province: Province in _state.map.provinces:
		draw_polyline(_closed(province.polygon), BORDER, BORDER_WIDTH, true)
	for segment: PackedVector2Array in _coast_cache:
		draw_polyline(segment, COAST, COAST_WIDTH, true)

	for island: Island in _state.map.islands:
		_draw_island_name(island)
	for province: Province in _state.map.provinces:
		_draw_marks(province)


func _fill_for(province: Province) -> Color:
	var base := PlayerPalette.for_player(_state, _state.owner(province.id))
	if _flashes.has(province.id):
		var entry: Dictionary = _flashes[province.id]
		var strength: float = clampf(float(entry["remaining"]) / FLASH_SECONDS, 0.0, 1.0)
		base = base.lerp(entry["colour"] as Color, strength * 0.85)
	if province.id == _hovered:
		base = base.lightened(0.12)
	return base


func _draw_marks(province: Province) -> void:
	var centre := province.label_at

	if province.id == _selected:
		draw_polyline(_closed(province.polygon), SELECTED, 5.0, true)
	elif _targets.has(province.id):
		draw_polyline(_closed(province.polygon), TARGET, 4.0, true)

	# A production centre: the thing worth chasing, so it is drawn as a mark on
	# the land rather than hidden in a tooltip.
	if _state.centres.has(province.id):
		draw_circle(centre + Vector2(0, -26), 9.0, CENTRE)
		draw_arc(centre + Vector2(0, -26), 9.0, 0.0, TAU, 20, COAST, 2.0, true)

	var font := ThemeDB.fallback_font
	var owner_id := _state.owner(province.id)
	var label := "%s %d" % [PlayerPalette.initial(owner_id), _state.army_count(province.id)]
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	draw_string(
		font,
		centre - Vector2(width * 0.5, -6.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		LABEL_SIZE,
		TEXT if _fill_for(province).get_luminance() > 0.45 else TEXT_LIGHT
	)

	var name_size := font.get_string_size(province.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(
		font,
		centre - Vector2(name_size * 0.5, -24.0),
		province.name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color(TEXT_LIGHT, 0.75)
	)


## An island's name and what holding all of it pays, above its coastline.
## Without this the bonus groups are invisible: the coast shows *which*
## provinces make a landmass, but not what it is called or what it is worth.
func _draw_island_name(island: Island) -> void:
	var members := _state.map.provinces_of(island.id)
	if members.is_empty():
		return
	var extent := Rect2(members[0].polygon[0], Vector2.ZERO)
	for province: Province in members:
		for point: Vector2 in province.polygon:
			extent = extent.expand(point)

	var holder := _island_holder(members)
	var label := "%s  +%d" % [island.name, island.bonus]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, ISLAND_LABEL_SIZE).x
	var colour := TEXT_LIGHT if holder.is_empty() else PlayerPalette.for_player(_state, holder)
	draw_string(
		font,
		Vector2(extent.get_center().x - width * 0.5, extent.position.y - 12.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ISLAND_LABEL_SIZE,
		Color(colour, 1.0 if not holder.is_empty() else 0.65)
	)


## Whoever holds every province on it — and therefore collects the bonus.
func _island_holder(members: Array[Province]) -> String:
	var holder := _state.owner(members[0].id)
	if holder.is_empty():
		return ""
	for province: Province in members:
		if _state.owner(province.id) != holder:
			return ""
	return holder


## Coast to coast, not centre to centre: a lane between centroids runs over
## whatever land is in the way.
func _draw_sea_lanes() -> void:
	for province: Province in _state.map.provinces:
		for other_id: String in province.sea_lanes:
			if province.id >= other_id:
				continue
			var other := _state.map.province(other_id)
			if other == null:
				continue
			var crossing := _shortest_crossing(province.polygon, other.polygon)
			draw_line(crossing[0], crossing[1], LANE, LANE_WIDTH, true)


## An island's coastline is every province edge no neighbour on the same island
## shares. Comparing edges is exact; a boolean union of the polygons is not,
## and drew a coastline through the middle of an island when it was tried.
func _rebuild_coastlines() -> void:
	_coast_cache = []
	for island: Island in _state.map.islands:
		var members := _state.map.provinces_of(island.id)
		for province: Province in members:
			var count := province.polygon.size()
			for i: int in count:
				var from := province.polygon[i]
				var to := province.polygon[(i + 1) % count]
				if not _edge_is_shared(members, province, from, to):
					_coast_cache.append(PackedVector2Array([from, to]))


func _edge_is_shared(
	members: Array[Province], owner_province: Province, from: Vector2, to: Vector2
) -> bool:
	for other: Province in members:
		if other.id == owner_province.id:
			continue
		var count := other.polygon.size()
		for i: int in count:
			var a := other.polygon[i]
			var b := other.polygon[(i + 1) % count]
			if (_near(from, a) and _near(to, b)) or (_near(from, b) and _near(to, a)):
				return true
	return false


func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_squared_to(b) <= EDGE_TOLERANCE * EDGE_TOLERANCE


func _shortest_crossing(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var best_from := Vector2.ZERO
	var best_to := Vector2.ZERO
	var best := INF
	for from: Vector2 in a:
		for to: Vector2 in b:
			var distance := from.distance_squared_to(to)
			if distance < best:
				best = distance
				best_from = from
				best_to = to
	return PackedVector2Array([best_from, best_to])


static func _closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var ring := PackedVector2Array(polygon)
	if ring.size() > 0:
		ring.append(ring[0])
	return ring


## Fits the board's own coordinate space to the window, so a map of any size
## arrives framed and a resize reframes rather than reflows.
func _frame_camera() -> void:
	var bounds := _state.map.bounds
	_camera.position = bounds.get_center()
	var viewport := get_viewport_rect().size
	if viewport.x > 0.0 and viewport.y > 0.0 and bounds.size.x > 0.0:
		var fit := minf(
			viewport.x / (bounds.size.x * VIEW_MARGIN), viewport.y / (bounds.size.y * VIEW_MARGIN)
		)
		_camera.zoom = Vector2(fit, fit)
