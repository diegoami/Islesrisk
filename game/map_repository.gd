class_name MapRepository
extends RefCounted
## Reads map files from disk and hands the text to core.
##
## The I/O edge. core/ may not touch FileAccess (the purity guard enforces it),
## which is also the right shape: parsing and validation stay testable with a
## string, and everything that can fail for an environmental reason — missing
## file, unreadable file — fails here.
##
## JSON only. Never ResourceLoader, never load() on a path: Godot resource
## files can carry embedded scripts, so loading one from a stranger is
## arbitrary code execution (ARCHITECTURE.md, "Loading data is a security
## boundary").

const MAPS_DIR := "res://data/maps"


static func load_map(map_id: String) -> MapReadResult:
	return load_from_path("%s/%s.json" % [MAPS_DIR, map_id.replace("-", "_")])


static func load_from_path(path: String) -> MapReadResult:
	if not FileAccess.file_exists(path):
		return MapReadResult.failure(["no map file at %s" % path])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return MapReadResult.failure(
			["could not open %s (error %d)" % [path, FileAccess.get_open_error()]]
		)
	var text := file.get_as_text()
	file.close()
	return MapReader.read(text)
