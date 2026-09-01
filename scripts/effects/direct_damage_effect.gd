class_name DirectDamageEffect
extends SpellEffect

func execute(
	event: PlayerAttackEvent,
	executor
) -> void:
	if event == null:
		return

	for target in event.targets:
		if not is_instance_valid(target):
			continue

		if not target.is_alive():
			continue

		executor.apply_direct_spell_damage(
			event,
			target,
			event.spell.base_damage
		)
