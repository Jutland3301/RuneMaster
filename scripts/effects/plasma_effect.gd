class_name PlasmaEffect
extends SpellEffect

# 50 + 60 + 90 = base total 200.
const HIT_BASE_DAMAGE: Array[float] = [
	50.0,
	60.0,
	90.0
]

const HIT_DELAYS: Array[float] = [
	0.0,
	0.12,
	0.28
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

	executor.queue_damage_sequence(
		event,
		target,
		HIT_BASE_DAMAGE,
		HIT_DELAYS
	)
