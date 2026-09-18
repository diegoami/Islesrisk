class_name PlayerPalette
extends RefCounted
## Ownership colours.
##
## Colour identifies a player and nothing may compromise that
## (ARCHITECTURE.md, "Looking good"). These four are chosen to stay apart for
## the common colour-blindness types, and every province also carries its
## owner's initial, so colour is never the only cue. Programmer art — the real
## palette is Iteration 5's business.

const SEATS: Array[Color] = [
	Color("#3d7ab8"),  # blue
	Color("#d98c3f"),  # amber
	Color("#4f9e6a"),  # green
	Color("#9a6bb0"),  # violet
]
const NEUTRAL := Color("#8d8578")


static func for_seat(index: int) -> Color:
	if index < 0:
		return NEUTRAL
	return SEATS[index % SEATS.size()]


static func for_player(state: GameState, player_id: String) -> Color:
	for i: int in state.players.size():
		if state.players[i].id == player_id:
			return for_seat(i)
	return NEUTRAL


## The non-colour cue: a letter on every province.
static func initial(player_id: String) -> String:
	return player_id.substr(0, 1).to_upper() if not player_id.is_empty() else "-"
