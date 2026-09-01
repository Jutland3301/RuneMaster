class_name ParalysisEffect
extends SpellEffect

const DURATION := 1.0


func execute(
	event: PlayerAttackEvent,
	executor
) -> void:
	if event.targets.is_empty():
		return

	var target = event.targets[0]

	if not is_instance_valid(target):
		return

	if not target.is_alive():
		return

	# Direct damage still happens on every cast.
	executor.apply_direct_spell_damage(
		event,
		target,
		event.spell.base_damage
	)

	# Enemy itself enforces non-refresh/non-stack.
	target.apply_paralysis(DURATION)
