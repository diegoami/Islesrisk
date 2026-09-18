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
