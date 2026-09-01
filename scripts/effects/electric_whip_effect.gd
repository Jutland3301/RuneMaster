class_name ElectricWhipEffect
extends SpellEffect

const MAIN_BASE_DAMAGE := 100.0
const SECONDARY_BASE_DAMAGE := 40.0


func execute(
	event: PlayerAttackEvent,
	executor
) -> void:
	if event.targets.is_empty():
		return

	var main_target = event.targets[0]

	if (
		not is_instance_valid(main_target)
		or not main_target.is_alive()
	):
		return

	executor.apply_direct_spell_damage(
		event,
		main_target,
		MAIN_BASE_DAMAGE
	)

	var candidates: Array = []

	for enemy in executor.battle_manager.get_living_enemies():
		if enemy != main_target:
			candidates.append(enemy)

	if candidates.is_empty():
		return

	var secondary = candidates[
		executor.rng.randi_range(
			0,
			candidates.size() - 1
		)
	]

	# Secondary resolves its own resistance.
	executor.apply_direct_spell_damage(
		event,
		secondary,
		SECONDARY_BASE_DAMAGE
	)
