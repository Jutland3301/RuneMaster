class_name PlasmaEffect
extends SpellEffect

# 50 + 60 + 90 = base total 200.
const HIT_BASE_DAMAGE: Array[float] = [
	50.0,
	60.0,
	90.0
]


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

	# Current logic resolves all three logical hits here.
	# UI presentation later staggers the visible zan/zan/ZAN response.
	for base_damage in HIT_BASE_DAMAGE:
		if not is_instance_valid(target):
			break

		if not target.is_alive():
			break

		executor.apply_direct_spell_damage(
			event,
			target,
			base_damage
		)
