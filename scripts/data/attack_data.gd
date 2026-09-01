class_name AttackData
extends Resource

enum DirectionMode {
	FIXED,
	WEIGHTED_RANDOM
}

@export var id: StringName
@export var display_name: String = ""

@export var damage: int = 10

@export var direction_mode: DirectionMode = DirectionMode.FIXED
@export var fixed_direction: EnemyAttackEvent.ParryDirection = EnemyAttackEvent.ParryDirection.FRONT

# FRONT, UP, DOWN, LEFT, RIGHT
@export var direction_weights: Array[float] = [
	0.2, 0.2, 0.2, 0.2, 0.2
]

@export var telegraph_duration: float = 1.0

# Seconds measured from telegraph start.
@export var parry_window_start: float = 0.65
@export var parry_window_end: float = 0.95

@export var spacing_category: StringName = &"normal"
@export var minimum_spacing: float = 0.35

# Explicit escape hatch for bosses/special attacks.
@export var bypass_spacing: bool = false


func resolve_direction(rng: RandomNumberGenerator) -> EnemyAttackEvent.ParryDirection:
	if direction_mode == DirectionMode.FIXED:
		return fixed_direction

	var weights := direction_weights.duplicate()

	while weights.size() < 5:
		weights.append(0.0)

	var total := 0.0
	for weight in weights:
		total += maxf(weight, 0.0)

	if total <= 0.0:
		return EnemyAttackEvent.ParryDirection.FRONT

	var roll := rng.randf() * total
	var accumulated := 0.0

	for i in range(5):
		accumulated += maxf(weights[i], 0.0)

		if roll <= accumulated:
			return i as EnemyAttackEvent.ParryDirection

	return EnemyAttackEvent.ParryDirection.RIGHT
