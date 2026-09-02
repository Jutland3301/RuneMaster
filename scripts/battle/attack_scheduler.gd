class_name AttackScheduler
extends Node

var last_attack_start_time: float = -9999.0

var category_last_start: Dictionary = {}

var default_minimum_spacing: float = 0.35
var category_minimum_spacing: Dictionary = {&"normal": 0.35}


func can_start_attack(
	attack: AttackData,
	current_battle_time: float,
	enemy_data: EnemyData = null
) -> bool:
	if attack == null:
		return false

	if attack.bypass_spacing:
		return true

	var required_spacing := maxf(
		default_minimum_spacing,
		attack.minimum_spacing
	)
	required_spacing = maxf(
		required_spacing,
		float(category_minimum_spacing.get(attack.spacing_category, 0.0))
	)

	if enemy_data != null:
		required_spacing = maxf(required_spacing, enemy_data.minimum_attack_spacing)

	if current_battle_time - last_attack_start_time < required_spacing:
		return false

	if category_last_start.has(attack.spacing_category):
		var category_time := float(
			category_last_start[attack.spacing_category]
		)

		if current_battle_time - category_time < required_spacing:
			return false

	return true


func notify_attack_started(
	attack: AttackData,
	current_battle_time: float
) -> void:
	if attack == null:
		return

	last_attack_start_time = current_battle_time
	category_last_start[attack.spacing_category] = current_battle_time


func get_spacing_remaining(
	attack: AttackData,
	current_battle_time: float
) -> float:
	if attack == null or attack.bypass_spacing:
		return 0.0

	var required_spacing := maxf(
		default_minimum_spacing,
		attack.minimum_spacing
	)

	return maxf(
		0.0,
		required_spacing - (
			current_battle_time - last_attack_start_time
		)
	)
