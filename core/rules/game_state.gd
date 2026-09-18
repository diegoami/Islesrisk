class_name GameState
extends RefCounted
## Everything needed to render a game and to continue it.
##
## The rule set sits *inside* the state, resolved and in full, so a game
## carries its own rules: tuning a preset cannot rewrite a save, and a bug
## report arrives with the exact configuration that produced it. The RNG's
## seed and position live here too, which together with the action list makes
## a game exactly reproducible.

enum Phase {
	SETUP,  ## players place their opening armies, one at a time
	REINFORCE,
	ATTACK,
	REDEPLOY,
	## No player acts in the hazards phase; ending redeploy resolves it. It is
	## a phase in RULES.md because the player watches it happen.
	HAZARDS,
	FINISHED,
}

var map: GameMap
var rules: RuleSet
var players: Array[Player]

var owner_of: Dictionary = {}  ## province_id -> player_id
var armies: Dictionary = {}  ## province_id -> int
var centres: PackedStringArray = PackedStringArray()

var current_player: int = 0
var phase: Phase = Phase.SETUP
var turn_number: int = 1
## Armies still to place this phase, by player id. Used in setup and reinforce.
var to_place: Dictionary = {}
var redeploys_left: int = 0
var captured_this_turn: bool = false

var rng: DeterministicRng
var log: Array[Dictionary] = []
## Every action that has been applied, in order. With the seed and the rule
## set this *is* the game: a save file is these three things, and loading one
## replays them. See game/game_archive.gd.
var history: Array[Action] = []
var winner: String = ""


func player(player_id: String) -> Player:
	for candidate: Player in players:
		if candidate.id == player_id:
			return candidate
	return null


func active_player() -> Player:
	if current_player < 0 or current_player >= players.size():
		return null
	return players[current_player]


func owner(province_id: String) -> String:
	return str(owner_of.get(province_id, ""))


func army_count(province_id: String) -> int:
	return int(armies.get(province_id, 0))


func owns(player_id: String, province_id: String) -> bool:
	return owner(province_id) == player_id


func provinces_of(player_id: String) -> PackedStringArray:
	var found := PackedStringArray()
	for province: Province in map.provinces:
		if owner(province.id) == player_id:
			found.append(province.id)
	return found


func army_total(player_id: String) -> int:
	var total := 0
	for province_id: String in provinces_of(player_id):
		total += army_count(province_id)
	return total


## Islands where the player holds every province. What the bonus is paid for.
func islands_held(player_id: String) -> Array[Island]:
	var held: Array[Island] = []
	for island: Island in map.islands:
		var all_mine := island.provinces.size() > 0
		for province_id: String in island.provinces:
			if owner(province_id) != player_id:
				all_mine = false
				break
		if all_mine:
			held.append(island)
	return held


func centres_held(player_id: String) -> int:
	var total := 0
	for province_id: String in centres:
		if owner(province_id) == player_id:
			total += 1
	return total


func living_players() -> Array[Player]:
	var alive: Array[Player] = []
	for candidate: Player in players:
		if not candidate.eliminated:
			alive.append(candidate)
	return alive


func note(entry: Dictionary) -> void:
	log.append(entry)


## A deep copy, so applying an action never touches the state it was given —
## and so the AI can play a move against a throwaway copy to see what happens.
## The map and the rule set are shared: both are immutable once a game starts.
func clone() -> GameState:
	var copy := GameState.new()
	copy.map = map
	copy.rules = rules
	copy.players = []
	for each: Player in players:
		copy.players.append(each.clone())
	copy.owner_of = owner_of.duplicate()
	copy.armies = armies.duplicate()
	copy.centres = PackedStringArray(centres)
	copy.current_player = current_player
	copy.phase = phase
	copy.turn_number = turn_number
	copy.to_place = to_place.duplicate()
	copy.redeploys_left = redeploys_left
	copy.captured_this_turn = captured_this_turn
	copy.rng = DeterministicRng.from_snapshot(rng.snapshot())
	copy.log = log.duplicate()
	copy.history = history.duplicate()
	copy.winner = winner
	return copy
