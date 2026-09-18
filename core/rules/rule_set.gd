class_name RuleSet
extends RefCounted
## Every rule, as data. The defaults here are the **Classic** preset.
##
## There is no rule in this engine that is compiled in: the engine is handed
## one of these and reads every constant from it (ARCHITECTURE.md). Code that
## assumes the match rule is on, that hazards exist, or that victory means
## conquest is a bug — the AI's code most of all, where it is easiest to hide.
##
## Serializable, with no functions in the data, so a rule set can live in a
## scenario file or a save game. A save stores its rule set **resolved and
## inline**, so tuning Classic next month cannot rewrite a game already played.


class Setup:
	extends RefCounted
	var deal: String = "roundRobin"  ## roundRobin | random | authored
	var starting_armies: int = 1
	var distribution_pool: int = 10
	## Extra armies for players dealt fewer provinces than the leader.
	var short_stack_bonus: int = 1


class Reinforcement:
	extends RefCounted
	var per_province_divisor: int = 3
	var minimum: int = 3
	var island_bonus: String = "authored"  ## authored | bySize | off
	var centre_bonus: int = 2


class Dice:
	extends RefCounted
	var max_dice: int
	var minus: int

	func _init(dice_max: int, dice_minus: int) -> void:
		max_dice = dice_max
		minus = dice_minus

	## How many dice a stack of this size rolls.
	func count_for(armies: int) -> int:
		return maxi(0, mini(max_dice, armies - minus))


class Combat:
	extends RefCounted
	## match: attacker must hold at least the defender's armies.
	## classic: any attack allowed. threshold: attacker >= defender * ratio.
	var attack_rule: String = "match"
	var attack_ratio: float = 1.0
	var min_armies_to_attack: int = 2
	var attacker_dice := Dice.new(3, 1)
	var defender_dice := Dice.new(2, 0)
	var ties: String = "defender"  ## defender | attacker
	## loseProvince | endPhase | none. The penalty is what makes the match rule
	## bite: an attack is a commitment, not a free roll.
	var failure_penalty: String = "loseProvince"
	var capture: String = "diceCount"  ## diceCount | all | one


class Redeploy:
	extends RefCounted
	var moves_per_turn: int = 1
	var chain: bool = false


class Hazard:
	extends RefCounted
	var chance: float
	var lose: String  ## half | third | a whole number as text
	var min_armies: int
	var target: String  ## leader | random | none

	func _init(
		hazard_chance: float,
		hazard_lose: String,
		hazard_min: int = 1,
		hazard_target: String = "random"
	) -> void:
		chance = hazard_chance
		lose = hazard_lose
		min_armies = hazard_min
		target = hazard_target


class Hazards:
	extends RefCounted
	var enabled: bool = true
	var flood := Hazard.new(0.08, "half")
	var quake := Hazard.new(0.05, "2", 4)
	var revolt := Hazard.new(0.06, "third", 1, "leader")


class Centres:
	extends RefCounted
	var count: int = 3
	var bonus: int = 2
	var wander_chance: float = 0.25


## Config only — card play arrives in Iteration 7. The block is here so the
## rule set's shape is complete and a preset can already turn cards off.
class Cards:
	extends RefCounted
	var enabled: bool = true
	var bombard: int = 8
	var shield: int = 6
	var airlift: int = 6
	var draw_on: String = "capture"  ## capture | turn | never
	var hand_max: int = 5
	var per_turn: int = 1


class Surrender:
	extends RefCounted
	var offer: bool = true
	var province_share: float = 0.5
	var army_share: float = 0.5


var id: String = "classic"
var name: String = "Classic"
var version: int = 1

var setup := Setup.new()
var reinforcement := Reinforcement.new()
var combat := Combat.new()
var redeploy := Redeploy.new()
var hazards := Hazards.new()
var centres := Centres.new()
var cards := Cards.new()
var surrender := Surrender.new()
## Ordered; the first satisfied ends the game. Classic is conquest alone.
## The rest of the catalogue arrives in Iteration 7 (SCENARIOS.md).
var victory: Array[String] = ["conquest"]


static func classic() -> RuleSet:
	return RuleSet.new()


## Serialisation. A save stores its rule set **inline and resolved**, so a
## tuning change to Classic can never silently alter a game already in
## progress (DECISIONS.md). Unknown keys are ignored on read rather than
## rejected — a rule set from an older build should still load, with this
## build's defaults filling the gaps.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"version": version,
		"setup":
		{
			"deal": setup.deal,
			"startingArmies": setup.starting_armies,
			"distributionPool": setup.distribution_pool,
			"shortStackBonus": setup.short_stack_bonus,
		},
		"reinforcement":
		{
			"perProvinceDivisor": reinforcement.per_province_divisor,
			"minimum": reinforcement.minimum,
			"islandBonus": reinforcement.island_bonus,
			"centreBonus": reinforcement.centre_bonus,
		},
		"combat":
		{
			"attackRule": combat.attack_rule,
			"attackRatio": combat.attack_ratio,
			"minArmiesToAttack": combat.min_armies_to_attack,
			"attackerDice":
			{"max": combat.attacker_dice.max_dice, "minus": combat.attacker_dice.minus},
			"defenderDice":
			{"max": combat.defender_dice.max_dice, "minus": combat.defender_dice.minus},
			"ties": combat.ties,
			"failurePenalty": combat.failure_penalty,
			"capture": combat.capture,
		},
		"redeploy": {"movesPerTurn": redeploy.moves_per_turn, "chain": redeploy.chain},
		"hazards":
		{
			"enabled": hazards.enabled,
			"flood": _hazard_to_dict(hazards.flood),
			"quake": _hazard_to_dict(hazards.quake),
			"revolt": _hazard_to_dict(hazards.revolt),
		},
		"centres":
		{
			"count": centres.count,
			"bonus": centres.bonus,
			"wanderChance": centres.wander_chance,
		},
		"cards":
		{
			"enabled": cards.enabled,
			"bombard": cards.bombard,
			"shield": cards.shield,
			"airlift": cards.airlift,
			"drawOn": cards.draw_on,
			"handMax": cards.hand_max,
			"perTurn": cards.per_turn,
		},
		"surrender":
		{
			"offer": surrender.offer,
			"provinceShare": surrender.province_share,
			"armyShare": surrender.army_share,
		},
		"victory": Array(victory),
	}


static func from_dict(raw: Dictionary) -> RuleSet:
	var rules := RuleSet.new()
	rules.id = str(raw.get("id", rules.id))
	rules.name = str(raw.get("name", rules.name))
	rules.version = int(raw.get("version", rules.version))

	var s: Dictionary = raw.get("setup", {})
	rules.setup.deal = str(s.get("deal", rules.setup.deal))
	rules.setup.starting_armies = int(s.get("startingArmies", rules.setup.starting_armies))
	rules.setup.distribution_pool = int(s.get("distributionPool", rules.setup.distribution_pool))
	rules.setup.short_stack_bonus = int(s.get("shortStackBonus", rules.setup.short_stack_bonus))

	var r: Dictionary = raw.get("reinforcement", {})
	rules.reinforcement.per_province_divisor = int(
		r.get("perProvinceDivisor", rules.reinforcement.per_province_divisor)
	)
	rules.reinforcement.minimum = int(r.get("minimum", rules.reinforcement.minimum))
	rules.reinforcement.island_bonus = str(r.get("islandBonus", rules.reinforcement.island_bonus))
	rules.reinforcement.centre_bonus = int(r.get("centreBonus", rules.reinforcement.centre_bonus))

	var c: Dictionary = raw.get("combat", {})
	rules.combat.attack_rule = str(c.get("attackRule", rules.combat.attack_rule))
	rules.combat.attack_ratio = float(c.get("attackRatio", rules.combat.attack_ratio))
	rules.combat.min_armies_to_attack = int(
		c.get("minArmiesToAttack", rules.combat.min_armies_to_attack)
	)
	rules.combat.attacker_dice = _dice_from(c.get("attackerDice", {}), rules.combat.attacker_dice)
	rules.combat.defender_dice = _dice_from(c.get("defenderDice", {}), rules.combat.defender_dice)
	rules.combat.ties = str(c.get("ties", rules.combat.ties))
	rules.combat.failure_penalty = str(c.get("failurePenalty", rules.combat.failure_penalty))
	rules.combat.capture = str(c.get("capture", rules.combat.capture))

	var d: Dictionary = raw.get("redeploy", {})
	rules.redeploy.moves_per_turn = int(d.get("movesPerTurn", rules.redeploy.moves_per_turn))
	rules.redeploy.chain = bool(d.get("chain", rules.redeploy.chain))

	var h: Dictionary = raw.get("hazards", {})
	rules.hazards.enabled = bool(h.get("enabled", rules.hazards.enabled))
	rules.hazards.flood = _hazard_from(h.get("flood", {}), rules.hazards.flood)
	rules.hazards.quake = _hazard_from(h.get("quake", {}), rules.hazards.quake)
	rules.hazards.revolt = _hazard_from(h.get("revolt", {}), rules.hazards.revolt)

	var m: Dictionary = raw.get("centres", {})
	rules.centres.count = int(m.get("count", rules.centres.count))
	rules.centres.bonus = int(m.get("bonus", rules.centres.bonus))
	rules.centres.wander_chance = float(m.get("wanderChance", rules.centres.wander_chance))

	var k: Dictionary = raw.get("cards", {})
	rules.cards.enabled = bool(k.get("enabled", rules.cards.enabled))
	rules.cards.bombard = int(k.get("bombard", rules.cards.bombard))
	rules.cards.shield = int(k.get("shield", rules.cards.shield))
	rules.cards.airlift = int(k.get("airlift", rules.cards.airlift))
	rules.cards.draw_on = str(k.get("drawOn", rules.cards.draw_on))
	rules.cards.hand_max = int(k.get("handMax", rules.cards.hand_max))
	rules.cards.per_turn = int(k.get("perTurn", rules.cards.per_turn))

	var u: Dictionary = raw.get("surrender", {})
	rules.surrender.offer = bool(u.get("offer", rules.surrender.offer))
	rules.surrender.province_share = float(u.get("provinceShare", rules.surrender.province_share))
	rules.surrender.army_share = float(u.get("armyShare", rules.surrender.army_share))

	var wins: Array = raw.get("victory", [])
	if not wins.is_empty():
		var listed: Array[String] = []
		for entry: Variant in wins:
			listed.append(str(entry))
		rules.victory = listed
	return rules


func _hazard_to_dict(hazard: Hazard) -> Dictionary:
	return {
		"chance": hazard.chance,
		"lose": hazard.lose,
		"minArmies": hazard.min_armies,
		"target": hazard.target,
	}


static func _hazard_from(raw: Variant, fallback: Hazard) -> Hazard:
	if not raw is Dictionary:
		return fallback
	var entry: Dictionary = raw
	return Hazard.new(
		float(entry.get("chance", fallback.chance)),
		str(entry.get("lose", fallback.lose)),
		int(entry.get("minArmies", fallback.min_armies)),
		str(entry.get("target", fallback.target))
	)


static func _dice_from(raw: Variant, fallback: Dice) -> Dice:
	if not raw is Dictionary:
		return fallback
	var entry: Dictionary = raw
	return Dice.new(
		int(entry.get("max", fallback.max_dice)), int(entry.get("minus", fallback.minus))
	)
