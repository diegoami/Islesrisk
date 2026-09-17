extends GdUnitTestSuite
## The purity guard.
##
## core/ is the pure, headless, deterministic engine (ARCHITECTURE.md): plain
## RefCounted classes with no scene tree, no I/O and no ambient randomness.
## In a game engine that boundary erodes by accident — reaching for the tree
## from rule code is one autocomplete away — so it is checked rather than
## trusted. This is the cheapest test in the project and it protects
## replayability, AI search and the whole test suite.
##
## If this fails, the fix is to move the offending code into game/, not to
## weaken the rule.

const CORE_DIR := "res://core"

## Regex, human-readable reason. Comments are stripped before matching, so
## prose may name these freely.
const FORBIDDEN: Array = [
	[
		"^extends\\s+(Node|CanvasItem|Control|Window|Resource)\\b",
		"core must not extend scene-tree or Resource types"
	],
	["\\bget_tree\\s*\\(", "core must not touch the scene tree"],
	["\\bsignal\\s+\\w+", "core must not define signals — return state instead"],
	["(?<![\\w.])randi\\s*\\(", "core must use DeterministicRng, not the global RNG"],
	["(?<![\\w.])randf\\s*\\(", "core must use DeterministicRng, not the global RNG"],
	["\\brandomize\\s*\\(", "core must use DeterministicRng, not the global RNG"],
	["(?<![\\w.])(pre)?load\\s*\\(", "core must not load resources — data is passed in"],
	["\\bResourceLoader\\b", "core must not load resources; scenario data is JSON"],
	["\\bFileAccess\\b", "core must not do file I/O"],
	["\\bTime\\.", "core must not read the clock"],
	["\\bOS\\.", "core must not talk to the OS"],
	["\\bInput\\b\\s*\\.", "core must not read input"],
]


func test_core_contains_no_forbidden_symbols() -> void:
	var files: PackedStringArray = _gd_files_under(CORE_DIR)
	(
		assert_int(files.size())
		. override_failure_message(
			"No .gd files found under %s — the guard would pass vacuously." % CORE_DIR
		)
		. is_greater(0)
	)

	var violations: Array[String] = []
	for path: String in files:
		violations.append_array(_violations_in(path))

	(
		assert_array(violations)
		. override_failure_message("core/ purity violated:\n  %s" % "\n  ".join(violations))
		. is_empty()
	)


func _violations_in(path: String) -> Array[String]:
	var found: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		found.append("%s: could not be opened" % path)
		return found

	var line_number := 0
	while not file.eof_reached():
		line_number += 1
		var code: String = _strip_comment(file.get_line())
		if code.strip_edges().is_empty():
			continue
		for rule: Array in FORBIDDEN:
			var pattern := RegEx.create_from_string(str(rule[0]))
			if pattern != null and pattern.search(code) != null:
				found.append("%s:%d — %s" % [path, line_number, str(rule[1])])
	file.close()
	return found


## Cuts a line at its first '#'. Approximate: a '#' inside a string literal
## would truncate early, which can only cause a missed detection, never a
## false failure. core/ has no such strings; revisit if it ever does.
func _strip_comment(line: String) -> String:
	var hash_at: int = line.find("#")
	return line if hash_at == -1 else line.substr(0, hash_at)


func _gd_files_under(directory: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = "%s/%s" % [directory, entry]
		if dir.current_is_dir():
			if not entry.begins_with("."):
				found.append_array(_gd_files_under(full))
		elif entry.ends_with(".gd"):
			found.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
