class_name BoardView
extends Node2D
## Draws whatever map it is given, at whatever size.
##
## Iteration 1: flat colour, deliberately. The look — water, coastlines,
## weather — is Iteration 5, and an art idea that only works on a hand-placed
## board is not usable anyway (ARCHITECTURE.md, "Looking good"), so this stage
## only has to prove the renderer is indifferent to what the generator will
## later invent.
##
## The two kinds of crossing are drawn differently because they read
## differently to a player: a border is a line on land, a sea lane is a
## crossing of open water.

const SEA := Color("#1b4a63")
const COAST := Color("#2b241a")
const BORDER := Color("#8d7f66")
const LANE := Color("#4a8099")
const LABEL := Color("#3a2f22")

## Muted land tints, one per island. Temporary: ownership colour replaces this
## in Iteration 3. Distinct enough to check the grouping by eye, which is the
## only reason they exist.
const ISLAND_TINTS: Array[Color] = [
	Color("#d9c9a3"),
	Color("#b5c4a1"),
	Color("#d6b39b"),
	Color("#a9bcc4"),
]

const COAST_WIDTH := 4.0
const BORDER_WIDTH := 1.6
const LANE_WIDTH := 2.2
const VIEW_MARGIN := 1.06
## How close two polygon points must be to count as the same corner. Clipped
## cells meet exactly in theory, within rounding in practice.
const EDGE_TOLERANCE := 2.0

var _map: GameMap
var _tint_by_island: Dictionary = {}


func show_map(map: GameMap) -> void:
	_map = map
	for child: Node in get_children():
		child.queue_free()
	_tint_by_island.clear()
	for index: int in map.islands.size():
		_tint_by_island[map.islands[index].id] = ISLAND_TINTS[index % ISLAND_TINTS.size()]

	_draw_sea()
	_draw_sea_lanes()
	for island: Island in map.islands:
		_draw_island(island)
	for province: Province in map.provinces:
		_draw_label(province)
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


## Provinces filled and outlined thinly, then the island's silhouette drawn
## over the top — so internal borders read as lines on land and the coast reads
## as where the land stops.
func _draw_island(island: Island) -> void:
	var tint: Color = _tint_by_island.get(island.id, ISLAND_TINTS[0])
	var members := _map.provinces_of(island.id)
	for province: Province in members:
		var fill := Polygon2D.new()
		fill.polygon = province.polygon
		fill.color = tint
		add_child(fill)
	for province: Province in members:
		var edge := Line2D.new()
		edge.points = province.polygon
		edge.closed = true
		edge.width = BORDER_WIDTH
		edge.default_color = BORDER
		edge.antialiased = true
		add_child(edge)
	for segment: PackedVector2Array in _coast_edges(members):
		var coast := Line2D.new()
		coast.points = segment
		coast.width = COAST_WIDTH
		coast.default_color = COAST
		coast.antialiased = true
		coast.begin_cap_mode = Line2D.LINE_CAP_ROUND
		coast.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(coast)


## An island's coastline: every province edge that no other province on the
## same island shares.
##
## This started as a boolean union of the province polygons, which was wrong
## twice over — neighbouring cells meet within float rounding rather than
## exactly, so the merge silently returned two polygons and drew a coastline
## straight through the middle of an island. Comparing edges is exact, cheap,
## and cannot invent a stroke that is not on the shore.
func _coast_edges(members: Array[Province]) -> Array[PackedVector2Array]:
	var found: Array[PackedVector2Array] = []
	for province: Province in members:
		var count := province.polygon.size()
		for i: int in count:
			var from := province.polygon[i]
			var to := province.polygon[(i + 1) % count]
			if not _edge_is_shared(members, province, from, to):
				found.append(PackedVector2Array([from, to]))
	return found


func _edge_is_shared(members: Array[Province], owner: Province, from: Vector2, to: Vector2) -> bool:
	for other: Province in members:
		if other.id == owner.id:
			continue
		var count := other.polygon.size()
		for i: int in count:
			var a := other.polygon[i]
			var b := other.polygon[(i + 1) % count]
			var same := _near(from, a) and _near(to, b)
			var reversed := _near(from, b) and _near(to, a)
			if same or reversed:
				return true
	return false


func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_squared_to(b) <= EDGE_TOLERANCE * EDGE_TOLERANCE


func _draw_sea_lanes() -> void:
	for province: Province in _map.provinces:
		for other_id: String in province.sea_lanes:
			if province.id >= other_id:
				continue
			var other := _map.province(other_id)
			if other == null:
				continue
			var lane := Line2D.new()
			lane.points = _shortest_crossing(province.polygon, other.polygon)
			lane.width = LANE_WIDTH
			lane.default_color = LANE
			lane.antialiased = true
			add_child(lane)


## Coast to coast, not centre to centre. A lane between centroids runs straight
## over whatever land is in the way; the shortest hop between two shorelines
## reads as what it is — a crossing of open water.
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


func _draw_label(province: Province) -> void:
	var label := Label.new()
	label.text = province.name
	label.add_theme_color_override("font_color", LABEL)
	label.position = province.label_at - Vector2(60.0, 10.0)
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
