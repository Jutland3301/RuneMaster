class_name BattlePlayerInput
extends Node

signal target_previous_requested
signal target_next_requested

signal spell_fire_requested
signal cancel_requested

signal parry_entered(direction: EnemyAttackEvent.ParryDirection)
signal parry_cancelled

var player: PlayerCombat
var rune_caster: RuneCaster

var rune_actions: Dictionary = {}

var algiz_id: StringName = &"algiz"
var input_enabled: bool = true

func setup(
	p_player: PlayerCombat,
	p_rune_caster: RuneCaster
) -> void:
	player = p_player
	rune_caster = p_rune_caster


func register_rune_action(
	action: StringName,
	rune: RuneData
) -> void:
	rune_actions[action] = rune


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if get_viewport().gui_get_focus_owner() != null:
		var focused := (
			get_viewport().gui_get_focus_owner()
		)

		if focused is Button:
			return
	if player == null or rune_caster == null:
		return

	if player.state == PlayerCombat.PlayerState.DEAD:
		return

	# Fresh presses only.
	if not event.is_pressed():
		return

	if event.is_echo():
		return

	# ------------------------------------------------
	# Priority 1:
	# Enter while currently CASTING judges the gauge.
	# ------------------------------------------------
	if event.is_action_pressed(&"battle_confirm"):
		if rune_caster.is_casting():
			rune_caster.judge_current_cast()
			get_viewport().set_input_as_handled()
			return

		if player.parry_active:
			get_viewport().set_input_as_handled()
			return

		if rune_caster.has_combo():
			spell_fire_requested.emit()
			get_viewport().set_input_as_handled()
			return

	# ------------------------------------------------
	# X:
	# casting/combo/parry clear
	# ------------------------------------------------
	if event.is_action_pressed(&"battle_cancel"):
		rune_caster.clear_combo()

		if player.parry_active:
			player.clear_parry()
			parry_cancelled.emit()

		cancel_requested.emit()

		get_viewport().set_input_as_handled()
		return

	# ------------------------------------------------
	# While casting:
	# other rune keys / Algiz / arrows ignored.
	# ------------------------------------------------
	if rune_caster.is_casting():
		return

	# ------------------------------------------------
	# Existing parry stance:
	#
	# FRONT can become one directional stance.
	# Once directional, arrows cannot change it.
	# Must X -> Algiz -> new direction.
	# ------------------------------------------------
	if player.parry_active:
		if (
			player.parry_direction
			== EnemyAttackEvent.ParryDirection.FRONT
		):
			var direction := _direction_from_event(event)

			if direction != -1:
				player.enter_parry(
					direction as EnemyAttackEvent.ParryDirection
				)

				parry_entered.emit(
					direction as EnemyAttackEvent.ParryDirection
				)

				get_viewport().set_input_as_handled()

		return

	# ------------------------------------------------
	# Rune actions.
	# Algiz is processed before ordinary runes.
	# ------------------------------------------------
	var algiz_action := _find_algiz_action()

	if (
		algiz_action != &""
		and event.is_action_pressed(algiz_action)
	):
		# Algiz forbidden while ANY offensive combo remains.
		if rune_caster.has_combo():
			get_viewport().set_input_as_handled()
			return

		if player.can_accept_normal_input():
			player.enter_parry(
				EnemyAttackEvent.ParryDirection.FRONT
			)

			parry_entered.emit(
				EnemyAttackEvent.ParryDirection.FRONT
			)

		get_viewport().set_input_as_handled()
		return

	# ------------------------------------------------
	# Target selection only while not casting/parrying.
	# Actual target ownership comes later.
	# ------------------------------------------------
	if event.is_action_pressed(&"battle_left"):
		target_previous_requested.emit()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"battle_right"):
		target_next_requested.emit()
		get_viewport().set_input_as_handled()
		return

	# ------------------------------------------------
	# Ordinary equipped elemental runes.
	# ------------------------------------------------
	for action in rune_actions:
		var rune: RuneData = rune_actions[action]

		if rune.id == algiz_id:
			continue

		if event.is_action_pressed(action):
			rune_caster.begin_rune(rune)
			get_viewport().set_input_as_handled()
			return


func _find_algiz_action() -> StringName:
	for action in rune_actions:
		var rune: RuneData = rune_actions[action]

		if rune.id == algiz_id:
			return action

	return &""


func _direction_from_event(event: InputEvent) -> int:
	if event.is_action_pressed(&"battle_up"):
		return EnemyAttackEvent.ParryDirection.UP

	if event.is_action_pressed(&"battle_down"):
		return EnemyAttackEvent.ParryDirection.DOWN

	if event.is_action_pressed(&"battle_left"):
		return EnemyAttackEvent.ParryDirection.LEFT

	if event.is_action_pressed(&"battle_right"):
		return EnemyAttackEvent.ParryDirection.RIGHT

	return -1
