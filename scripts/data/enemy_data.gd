class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String = ""

@export var sprite: Texture2D
@export var presentation_color: Color = Color(0.32, 0.30, 0.34)

@export var max_hp: int = 1000

@export var attack_interval_min: float = 1.5
@export var attack_interval_max: float = 3.0

@export var parry_stun_duration: float = 1.0
@export var minimum_attack_spacing: float = 0.0

@export var attacks: Array[AttackData] = []

# Example:
# {
#   &"fire": 1.5,
#   &"water": 0.5,
#   &"plasma": 0.0
# }
@export var resistances: Dictionary = {}


func get_resistance(attribute_id: StringName) -> float:
	if resistances.has(attribute_id):
		return float(resistances[attribute_id])

	return 1.0
