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


static func problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	found.append_array(_identity_problems(map))
	found.append_array(_membership_problems(map))
	found.append_array(_lane_problems(map))
	found.append_array(_geometry_problems(map))
	found.append_array(_connectivity_problems(map))
	return found


static func is_valid(map: GameMap) -> bool:
	return problems(map).is_empty()


static func _identity_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	if map.isles.is_empty():
		found.append("map has no isles")
	var seen_isles: Dictionary = {}
	for isle: Isle in map.isles:
		if isle.id.is_empty():
			found.append("an isle has an empty id")
		elif seen_isles.has(isle.id):
			found.append("duplicate isle id '%s'" % isle.id)
		seen_isles[isle.id] = true
	var seen_groups: Dictionary = {}
	for archipelago: Archipelago in map.archipelagos:
		if archipelago.id.is_empty():
			found.append("an archipelago has an empty id")
		elif seen_groups.has(archipelago.id):
			found.append("duplicate archipelago id '%s'" % archipelago.id)
		seen_groups[archipelago.id] = true
		if archipelago.bonus < 0:
			found.append("archipelago '%s' has a negative bonus" % archipelago.id)
	return found


## Every isle in exactly one archipelago, and the two directions agreeing.
## Membership stated twice is a cheap redundancy that catches hand-editing
## mistakes the moment they happen.
static func _membership_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	var claimed: Dictionary = {}
	for archipelago: Archipelago in map.archipelagos:
		if archipelago.isles.is_empty():
			found.append("archipelago '%s' is empty" % archipelago.id)
		for isle_id: String in archipelago.isles:
			if not map.has_isle(isle_id):
				found.append("archipelago '%s' lists unknown isle '%s'" % [archipelago.id, isle_id])
			elif claimed.has(isle_id):
				found.append(
					(
						"isle '%s' is claimed by both '%s' and '%s'"
						% [isle_id, str(claimed[isle_id]), archipelago.id]
					)
				)
			else:
				claimed[isle_id] = archipelago.id
	for isle: Isle in map.isles:
		if map.archipelago(isle.archipelago) == null:
			found.append("isle '%s' names unknown archipelago '%s'" % [isle.id, isle.archipelago])
		elif not claimed.has(isle.id):
			found.append("isle '%s' belongs to no archipelago's list" % isle.id)
		elif str(claimed[isle.id]) != isle.archipelago:
			found.append(
				(
					"isle '%s' says '%s' but is listed under '%s'"
					% [isle.id, isle.archipelago, str(claimed[isle.id])]
				)
			)
	return found


static func _lane_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	for isle: Isle in map.isles:
		var seen: Dictionary = {}
		for neighbour_id: String in isle.neighbours:
			if neighbour_id == isle.id:
				found.append("isle '%s' is its own neighbour" % isle.id)
				continue
			if seen.has(neighbour_id):
				found.append("isle '%s' lists '%s' twice" % [isle.id, neighbour_id])
				continue
			seen[neighbour_id] = true
			var other := map.isle(neighbour_id)
			if other == null:
				found.append("isle '%s' has a lane to unknown isle '%s'" % [isle.id, neighbour_id])
			elif not other.neighbours.has(isle.id):
				found.append("lane '%s' -> '%s' is not returned" % [isle.id, neighbour_id])
	return found


static func _geometry_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	for isle: Isle in map.isles:
		if isle.polygon.size() < 3:
			found.append("isle '%s' has fewer than 3 polygon points" % isle.id)
			continue
		if isle.area() < MIN_AREA:
			found.append("isle '%s' has a degenerate area" % isle.id)
		if _self_intersects(isle.polygon):
			found.append("isle '%s' has a self-intersecting polygon" % isle.id)
		elif not Geometry2D.is_point_in_polygon(isle.label_at, isle.polygon):
			found.append("isle '%s' has its label point outside its polygon" % isle.id)
	return found


## Flood fill from the first isle. A board in two pieces is unplayable in a
## game where the only way to reach an isle is a lane.
static func _connectivity_problems(map: GameMap) -> Array[String]:
	var found: Array[String] = []
	if map.isles.is_empty():
		return found
	var reached: Dictionary = {}
	var queue: Array[String] = [map.isles[0].id]
	reached[map.isles[0].id] = true
	while not queue.is_empty():
		var current: String = queue.pop_back()
		var isle := map.isle(current)
		if isle == null:
			continue
		for neighbour_id: String in isle.neighbours:
			if not reached.has(neighbour_id) and map.has_isle(neighbour_id):
				reached[neighbour_id] = true
				queue.append(neighbour_id)
	if reached.size() != map.isles.size():
		var stranded: Array[String] = []
		for isle: Isle in map.isles:
			if not reached.has(isle.id):
				stranded.append(isle.id)
		found.append(
			(
				"map is not connected — %d isle(s) unreachable: %s"
				% [stranded.size(), ", ".join(stranded)]
			)
		)
	return found


## O(n^2) over polygon edges. Isles have a dozen or so points, so the simple
## version is the right one; revisit only if a generator starts emitting
## hundreds.
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
