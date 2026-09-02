class_name EnemyAttackEvent
extends RefCounted

enum ParryDirection {
	FRONT,
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var source_enemy
var attack_data
var resolved_direction: ParryDirection = ParryDirection.FRONT
# Dormant extension point for future multi-parry events. Normal attacks use
# exactly one entry and no current system consumes this as a gimmick.
var resolved_directions: Array[ParryDirection] = []
var damage: int = 0

var elapsed: float = 0.0
var telegraph_progress: float = 0.0
var parry_window_active: bool = false
var resolved: bool = false

func _init(
	p_source_enemy = null,
	p_attack_data = null,
	p_direction: ParryDirection = ParryDirection.FRONT,
	p_damage: int = 0
) -> void:
	source_enemy = p_source_enemy
	attack_data = p_attack_data
	resolved_direction = p_direction
	resolved_directions.clear()
	resolved_directions.append(p_direction)
	damage = p_damage
