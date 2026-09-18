class_name TestPositions
extends RefCounted
## Small, hand-built boards for tests that need to know exactly what is where.
##
## Two islands of two provinces each: west_north borders west_south, east_north
## borders east_south, and west_north has a sea lane to east_north.


static func two_islands() -> GameMap:
	var provinces: Array[Province] = [
		_province("west_north", "west", ["west_south"], ["east_north"], 60, 60),
		_province("west_south", "west", ["west_north"], [], 60, 160),
		_province("east_north", "east", ["east_south"], ["west_north"], 400, 60),
		_province("east_south", "east", ["east_north"], [], 400, 160),
	]
	var islands: Array[Island] = [
		Island.new("west", "West", 2, PackedStringArray(["west_north", "west_south"])),
		Island.new("east", "East", 3, PackedStringArray(["east_north", "east_south"])),
	]
	return GameMap.new("test-sea", "Test Sea", Rect2(0, 0, 600, 300), provinces, islands)


## A two-player game in the attack phase, with ownership and armies set
## exactly. `holdings` maps province id to [player_id, armies].
static func position(holdings: Dictionary, rules: RuleSet = null, seed_value: int = 7) -> GameState:
	var state := GameState.new()
	state.map = two_islands()
	state.rules = rules if rules != null else RuleSet.classic()
	state.players = [Player.new("blue", "Blue"), Player.new("red", "Red", true)]
	state.rng = DeterministicRng.new(seed_value)
	state.phase = GameState.Phase.ATTACK
	state.current_player = 0
	state.turn_number = 1
	for province_id: String in holdings.keys():
		var pair: Array = holdings[province_id]
		state.owner_of[province_id] = str(pair[0])
		state.armies[province_id] = int(pair[1])
	return state


## Blue holds the west, Red the east, with the armies given.
static func standoff(blue_north: int, red_north: int) -> GameState:
	return position(
		{
			"west_north": ["blue", blue_north],
			"west_south": ["blue", 1],
			"east_north": ["red", red_north],
			"east_south": ["red", 1],
		}
	)


static func _province(
	province_id: String, island: String, borders: Array, lanes: Array, x: float, y: float
) -> Province:
	var polygon := PackedVector2Array(
		[Vector2(x, y), Vector2(x + 100, y), Vector2(x + 100, y + 100), Vector2(x, y + 100)]
	)
	return Province.new(
		province_id,
		province_id.capitalize(),
		island,
		PackedStringArray(borders),
		PackedStringArray(lanes),
		polygon,
		Vector2(x + 50, y + 50)
	)
