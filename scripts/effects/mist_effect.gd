class_name MistEffect
extends SpellEffect

const DURATION := 15.0
const PARRY_BONUS := 0.3


func execute(
	_event: PlayerAttackEvent,
	executor
) -> void:
	var controller: StatusEffectController = (
		executor.battle_status
	)

	if controller == null:
		return

	var applied := controller.add_effect(
		&"mist",
		DURATION,
		StatusEffectController.StackRule.IGNORE,
		{
			"parry_window_bonus": PARRY_BONUS
		}
	)

	# Re-cast is still a successful spell,
	# but does not refresh or stack.
	if not applied:
		return
