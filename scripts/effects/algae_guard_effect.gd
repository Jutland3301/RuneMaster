class_name AlgaeGuardEffect
extends SpellEffect

const DURATION := 15.0
const DAMAGE_MULTIPLIER := 0.8


func execute(
	_event: PlayerAttackEvent,
	executor
) -> void:
	if executor.player == null:
		return

	var controller: StatusEffectController = (
		executor.player_status
	)

	if controller == null:
		return

	var applied := controller.add_effect(
		&"algae_guard",
		DURATION,
		StatusEffectController.StackRule.IGNORE,
		{
			"direct_damage_multiplier":
				DAMAGE_MULTIPLIER
		}
	)

	if applied:
		executor.player.guard_damage_multiplier = (
			DAMAGE_MULTIPLIER
		)
