class_name CombatResolver
extends RefCounted
## One attack, resolved. Mutates the state it is given — `Rules.apply` has
## already cloned it, so nothing a caller handed in is touched.

const DIE_SIDES := 6


## Why this attack is not allowed, or "" if it is. Shared by the engine and,
## later, by the UI: the UI declines to *offer* an illegal action, the engine
## rejects it anyway.
static func why_not(state: GameState, from_id: String, to_id: String) -> String:
	var attacker := state.map.province(from_id)
	var defender := state.map.province(to_id)
	if attacker == null:
		return "no such province '%s'" % from_id
	if defender == null:
		return "no such province '%s'" % to_id

	var mover := state.active_player()
	if mover == null or not state.owns(mover.id, from_id):
		return "you do not hold %s" % attacker.name
	if state.owns(mover.id, to_id):
		return "%s is already yours" % defender.name
	if not attacker.neighbours().has(to_id):
		return "%s does not reach %s" % [attacker.name, defender.name]

	var rules := state.rules.combat
	var attacking := state.army_count(from_id)
	if attacking < rules.min_armies_to_attack:
		return "%s needs at least %d armies to attack" % [attacker.name, rules.min_armies_to_attack]

	var defending := state.army_count(to_id)
	match rules.attack_rule:
		"match":
			if attacking < defending:
				return (
					"%s has %d armies and %s has %d — an attacker must match the defender"
					% [attacker.name, attacking, defender.name, defending]
				)
		"threshold":
			if float(attacking) < float(defending) * rules.attack_ratio:
				return (
					"%s needs %.1f times the defender's armies"
					% [attacker.name, rules.attack_ratio]
				)
		"classic":
			pass
		_:
			return "unknown attack rule '%s'" % rules.attack_rule
	return ""


## Resolves one round. Returns what happened, for the log and the UI.
static func resolve(state: GameState, from_id: String, to_id: String) -> Dictionary:
	var rules := state.rules.combat
	var attacker_id := state.owner(from_id)
	var defender_id := state.owner(to_id)

	var attacker_rolls := _roll(state, rules.attacker_dice.count_for(state.army_count(from_id)))
	var defender_rolls := _roll(state, rules.defender_dice.count_for(state.army_count(to_id)))

	var attacker_losses := 0
	var defender_losses := 0
	for i: int in mini(attacker_rolls.size(), defender_rolls.size()):
		var attacker_wins := attacker_rolls[i] > defender_rolls[i]
		if attacker_rolls[i] == defender_rolls[i]:
			attacker_wins = rules.ties == "attacker"
		if attacker_wins:
			defender_losses += 1
		else:
			attacker_losses += 1

	state.armies[from_id] = state.army_count(from_id) - attacker_losses
	state.armies[to_id] = state.army_count(to_id) - defender_losses

	var outcome := {
		"event": "attack",
		"from": from_id,
		"to": to_id,
		"attacker": attacker_id,
		"defender": defender_id,
		"attacker_rolls": attacker_rolls,
		"defender_rolls": defender_rolls,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses,
		"captured": false,
		"penalty": false,
		"ends_phase": false,
	}

	if state.army_count(to_id) <= 0:
		_capture(state, from_id, to_id, attacker_rolls.size(), outcome)
		return outcome

	# The failure penalty: an attack that leaves the attacker on one army,
	# against a defender still standing, is what makes an attack a commitment
	# rather than a free roll of the dice.
	if state.army_count(from_id) <= 1 and rules.failure_penalty != "none":
		outcome["ends_phase"] = true
		if rules.failure_penalty == "loseProvince":
			state.owner_of[from_id] = defender_id
			state.armies[from_id] = 1
			outcome["penalty"] = true
	return outcome


static func _capture(
	state: GameState, from_id: String, to_id: String, dice_rolled: int, outcome: Dictionary
) -> void:
	var rules := state.rules.combat
	var available := state.army_count(from_id) - 1
	var wanted := dice_rolled
	match rules.capture:
		"all":
			wanted = available
		"one":
			wanted = 1
		_:
			wanted = dice_rolled
	var moving := clampi(wanted, 1, maxi(1, available))

	state.owner_of[to_id] = state.owner(from_id)
	state.armies[from_id] = state.army_count(from_id) - moving
	state.armies[to_id] = moving
	outcome["captured"] = true
	outcome["moved"] = moving


## Descending, so the pairing is highest against highest.
static func _roll(state: GameState, count: int) -> Array[int]:
	var rolls: Array[int] = []
	for i: int in count:
		rolls.append(state.rng.roll_die(DIE_SIDES))
	rolls.sort()
	rolls.reverse()
	return rolls
