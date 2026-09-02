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


func setup(p_player: PlayerCombat, p_rune_caster: RuneCaster) -> void:
	player = p_player
	rune_caster = p_rune_caster


func register_rune_action(action: StringName, rune: RuneData) -> void:
	rune_actions[action] = rune


func _process(_delta: float) -> void:
	if not _can_process_gameplay_input():
		return

	# Fixed per-frame priority prevents action order from depending on the
	# order in which Godot delivered individual key events.
	if Input.is_action_just_pressed(&"battle_confirm"):
		if rune_caster.is_casting():
			rune_caster.judge_current_cast()
			return

		if player.parry_active:
			return

		if rune_caster.has_combo():
			spell_fire_requested.emit()
			return

	var algiz_action := _find_algiz_action()

	# Algiz explicitly outranks X when both are newly pressed this frame.
	if algiz_action != &"" and Input.is_action_just_pressed(algiz_action):
		if rune_caster.is_casting() or rune_caster.has_combo():
			rune_caster.reject_input(&"algiz_requires_clear")
			return

		player.enter_parry(EnemyAttackEvent.ParryDirection.FRONT)
		parry_entered.emit(EnemyAttackEvent.ParryDirection.FRONT)
		return

	if Input.is_action_just_pressed(&"battle_cancel"):
		rune_caster.clear_combo()

		if player.parry_active:
			player.clear_parry()
			parry_cancelled.emit()

		cancel_requested.emit()
		return

	if rune_caster.is_casting():
		return

	if player.parry_active:
		if player.parry_direction == EnemyAttackEvent.ParryDirection.FRONT:
			var direction := _pressed_direction()

			if direction != -1:
				player.enter_parry(direction as EnemyAttackEvent.ParryDirection)
				parry_entered.emit(direction as EnemyAttackEvent.ParryDirection)
		return

	if Input.is_action_just_pressed(&"battle_left"):
		target_previous_requested.emit()
		return

	if Input.is_action_just_pressed(&"battle_right"):
		target_next_requested.emit()
		return

	for action in rune_actions:
		var rune: RuneData = rune_actions[action]

		if rune.id == algiz_id:
			continue

		if Input.is_action_just_pressed(action):
			rune_caster.begin_rune(rune)
			return


func _can_process_gameplay_input() -> bool:
	if not input_enabled or player == null or rune_caster == null:
		return false

	if not player.can_accept_normal_input():
		return false

	var focused := get_viewport().gui_get_focus_owner()
	return focused == null or not focused.is_visible_in_tree()


func _find_algiz_action() -> StringName:
	for action in rune_actions:
		var rune: RuneData = rune_actions[action]

		if rune.id == algiz_id:
			return action

	return &""


func _pressed_direction() -> int:
	if Input.is_action_just_pressed(&"battle_up"):
		return EnemyAttackEvent.ParryDirection.UP
	if Input.is_action_just_pressed(&"battle_down"):
		return EnemyAttackEvent.ParryDirection.DOWN
	if Input.is_action_just_pressed(&"battle_left"):
		return EnemyAttackEvent.ParryDirection.LEFT
	if Input.is_action_just_pressed(&"battle_right"):
		return EnemyAttackEvent.ParryDirection.RIGHT

	return -1
