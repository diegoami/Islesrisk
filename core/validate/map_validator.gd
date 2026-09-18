class_name MapValidator
extends RefCounted
## The shared contract every map must satisfy, hand-drawn or generated.
##
## Runs in the test gate, because a broken map should fail CI rather than the
## game (SCENARIOS.md). A generator that can emit a map failing this is a bug
## in the generator, never a reason to relax a rule here.
##
## Returns every problem it finds rather than the first, so fixing a map is one
## pass instead of ten.

const MIN_AREA := 1.0
## How close two polygons must come before they count as sharing a border.
## Clipped-Voronoi cells meet exactly in theory and within rounding in
## practice, so this is float slack, not a fudge factor.
const BORDER_TOLERANCE := 2.0


static func problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	found.append_array(_identity_problems(map))
	found.append_array(_membership_problems(map))
	found.append_array(_crossing_problems(map))
	found.append_array(_geometry_problems(map))
	found.append_array(_island_contiguity_problems(map))
	found.append_array(_connectivity_problems(map))
	return found


static func is_valid(map: GameMap) -> bool:
	return problems(map).is_empty()


static func _identity_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	if map.provinces.is_empty():
		found.append("map has no provinces")
	if map.islands.is_empty():
		found.append("map has no islands")
	var seen_provinces: Dictionary = {}
	for province: Province in map.provinces:
		if province.id.is_empty():
			found.append("a province has an empty id")
		elif seen_provinces.has(province.id):
			found.append("duplicate province id '%s'" % province.id)
		seen_provinces[province.id] = true
	var seen_islands: Dictionary = {}
	for island: Island in map.islands:
		if island.id.is_empty():
			found.append("an island has an empty id")
		elif seen_islands.has(island.id):
			found.append("duplicate island id '%s'" % island.id)
		seen_islands[island.id] = true
		if island.bonus < 0:
			found.append("island '%s' has a negative bonus" % island.id)
	return found


## Every province on exactly one island, with the two directions agreeing.
## Membership stated twice is a cheap redundancy that catches the mistake a
## hand-edit actually makes.
static func _membership_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	var claimed: Dictionary = {}
	for island: Island in map.islands:
		if island.provinces.is_empty():
			found.append("island '%s' has no provinces" % island.id)
		for province_id: String in island.provinces:
			if not map.has_province(province_id):
				found.append("island '%s' lists unknown province '%s'" % [island.id, province_id])
			elif claimed.has(province_id):
				found.append(
					(
						"province '%s' is claimed by both '%s' and '%s'"
						% [province_id, str(claimed[province_id]), island.id]
					)
				)
			else:
				claimed[province_id] = island.id
	for province: Province in map.provinces:
		if map.island(province.island) == null:
			found.append("province '%s' names unknown island '%s'" % [province.id, province.island])
		elif not claimed.has(province.id):
			found.append("province '%s' is on no island's list" % province.id)
		elif str(claimed[province.id]) != province.island:
			found.append(
				(
					"province '%s' says '%s' but is listed under '%s'"
					% [province.id, province.island, str(claimed[province.id])]
				)
			)
	return found


## Borders are land and stay on one island; sea lanes cross water and never do.
## Getting this backwards is the mistake that turns an archipelago of provinces
## back into a scatter of one-province islands.
static func _crossing_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	for province: Province in map.provinces:
		found.append_array(_one_direction(map, province, province.borders, true))
		found.append_array(_one_direction(map, province, province.sea_lanes, false))
	return found


static func _one_direction(
	map: GameMap, province: Province, targets: PackedStringArray, by_land: bool
) -> Array[String]:
	var kind := "border" if by_land else "sea lane"
	var found: Array[String] = []
	var seen: Dictionary = {}
	for target_id: String in targets:
		if target_id == province.id:
			found.append("province '%s' has a %s to itself" % [province.id, kind])
			continue
		if seen.has(target_id):
			found.append("province '%s' lists %s to '%s' twice" % [province.id, kind, target_id])
			continue
		seen[target_id] = true
		var other := map.province(target_id)
		if other == null:
			found.append(
				"province '%s' has a %s to unknown province '%s'" % [province.id, kind, target_id]
			)
			continue
		var returned := (
			other.borders.has(province.id) if by_land else other.sea_lanes.has(province.id)
		)
		if not returned:
			found.append("%s '%s' -> '%s' is not returned" % [kind, province.id, target_id])
		if by_land and other.island != province.island:
			found.append(
				(
					"province '%s' borders '%s' by land but they are on different islands"
					% [province.id, target_id]
				)
			)
		if not by_land and other.island == province.island:
			found.append(
				(
					"province '%s' has a sea lane to '%s' on the same island — use a border"
					% [province.id, target_id]
				)
			)
	return found


static func _geometry_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	for province: Province in map.provinces:
		if province.polygon.size() < 3:
			found.append("province '%s' has fewer than 3 polygon points" % province.id)
			continue
		if province.area() < MIN_AREA:
			found.append("province '%s' has a degenerate area" % province.id)
		if _self_intersects(province.polygon):
			found.append("province '%s' has a self-intersecting polygon" % province.id)
		elif not Geometry2D.is_point_in_polygon(province.label_at, province.polygon):
			found.append("province '%s' has its label point outside its polygon" % province.id)

	for province: Province in map.provinces:
		for border_id: String in province.borders:
			var other := map.province(border_id)
			if other == null or province.id >= border_id:
				continue
			if not _polygons_touch(province.polygon, other.polygon):
				found.append(
					(
						"provinces '%s' and '%s' claim a land border but their shapes do not meet"
						% [province.id, border_id]
					)
				)
	return found


## Each island must be one landmass: its provinces reachable from each other
## by land alone. An island in two pieces is two islands.
static func _island_contiguity_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	for island: Island in map.islands:
		var members := map.provinces_of(island.id)
		if members.size() <= 1:
			continue
		var reached: Dictionary = {}
		var queue: Array[String] = [members[0].id]
		reached[members[0].id] = true
		while not queue.is_empty():
			var current: String = queue.pop_back()
			var province := map.province(current)
			if province == null:
				continue
			for border_id: String in province.borders:
				var other := map.province(border_id)
				if other != null and other.island == island.id and not reached.has(border_id):
					reached[border_id] = true
					queue.append(border_id)
		if reached.size() != members.size():
			found.append(
				(
					"island '%s' is not one landmass — %d of %d provinces are cut off by land"
					% [island.id, members.size() - reached.size(), members.size()]
				)
			)
	return found


## The whole board, by land and water together. A province nobody can reach is
## a province nobody can take.
static func _connectivity_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	if map.provinces.is_empty():
		return found
	var reached: Dictionary = {}
	var queue: Array[String] = [map.provinces[0].id]
	reached[map.provinces[0].id] = true
	while not queue.is_empty():
		var current: String = queue.pop_back()
		var province := map.province(current)
		if province == null:
			continue
		for neighbour_id: String in province.neighbours():
			if not reached.has(neighbour_id) and map.has_province(neighbour_id):
				reached[neighbour_id] = true
				queue.append(neighbour_id)
	if reached.size() != map.provinces.size():
		var stranded: Array[String] = []
		for province: Province in map.provinces:
			if not reached.has(province.id):
				stranded.append(province.id)
		found.append(
			(
				"map is not connected — %d province(s) unreachable: %s"
				% [stranded.size(), ", ".join(stranded)]
			)
		)
	return found


static func _polygons_touch(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for point: Vector2 in a:
		for other: Vector2 in b:
			if point.distance_squared_to(other) <= BORDER_TOLERANCE * BORDER_TOLERANCE:
				return true
	return false


## O(n^2) over polygon edges. Provinces have a few dozen points at most, so the
## simple version is the right one.
static func _self_intersects(polygon: PackedVector2Array) -> bool:
	var count := polygon.size()
	for i: int in count:
		var a1 := polygon[i]
		var a2 := polygon[(i + 1) % count]
		for j: int in range(i + 1, count):
			if j == i or (j + 1) % count == i or j == (i + 1) % count:
				continue
			var b1 := polygon[j]
			var b2 := polygon[(j + 1) % count]
			if Geometry2D.segment_intersects_segment(a1, a2, b1, b2) != null:
				return true
	return false
