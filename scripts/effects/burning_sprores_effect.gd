class_name BurningSporesEffect
extends SpellEffect

const INITIAL_BASE_DAMAGE := 30.0
const DOT_BASE_DAMAGE := 20.0
const DOT_TICKS := 5
const TICK_INTERVAL := 1.0


func execute(
	event: PlayerAttackEvent,
	executor
) -> void:
	if event.targets.is_empty():
		return

	var target = event.targets[0]

	if (
		not is_instance_valid(target)
		or not target.is_alive()
	):
		return

	# Direct initial hit always happens,
	# including when target is already burning.
	executor.apply_direct_spell_damage(
		event,
		target,
		INITIAL_BASE_DAMAGE
	)

	executor.start_burn(
		target,
		event.perfect_count,
		DOT_BASE_DAMAGE,
		DOT_TICKS,
		TICK_INTERVAL
	)
