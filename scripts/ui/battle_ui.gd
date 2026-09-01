class_name BattleUI
extends CanvasLayer

var root: Control

var world_panel: ColorRect
var lower_panel: ColorRect

var enemy_layer: Control

var player_hp_bar: ProgressBar
var player_hp_label: Label

var casting_ui: CastingUI

var fusion_panel: Panel
var fusion_title: Label
var fusion_spell: Label
var fusion_components: Label

var telegraph_layer: Control

var enemy_uis: Dictionary = {}
var telegraphs: Dictionary = {}
var result_overlay: ColorRect
var result_label: Label
var retry_button: Button


func setup(test_battle) -> void:
	_build()

	test_battle.player.hp_changed.connect(
		_on_player_hp_changed
	)

	test_battle.rune_caster.casting_started.connect(
		_on_casting_started
	)

	test_battle.rune_caster.casting_updated.connect(
		_on_casting_updated
	)

	test_battle.rune_caster.rune_success.connect(
		_on_rune_success
	)

	test_battle.rune_caster.cast_missed.connect(
		_on_cast_missed
	)

	test_battle.rune_caster.combo_changed.connect(
		_on_combo_changed.bind(test_battle)
	)

	test_battle.player.parry_changed.connect(
		_on_parry_changed
	)

	test_battle.player.parry_cleared.connect(
		_on_parry_cleared
	)

	test_battle.spell_executor.damage_applied.connect(
		_on_spell_damage
	)

	test_battle.spell_executor.dot_damage_applied.connect(
		_on_dot_damage
	)

	test_battle.spell_executor.immune.connect(
		_on_immune
	)

	for enemy in test_battle.enemies:
		_create_enemy_ui(enemy)

		enemy.attack_started.connect(
			_on_enemy_attack_started
		)

		enemy.attack_progressed.connect(
			_on_enemy_attack_progressed
		)

		enemy.attack_cancelled.connect(
			_on_enemy_attack_cancelled
		)

		enemy.attack_impacted.connect(
			_on_enemy_attack_impacted
		)

	_refresh_targets(test_battle)

	_on_player_hp_changed(
		test_battle.player.hp,
		test_battle.player.max_hp
	)


func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(root)

	world_panel = ColorRect.new()
	world_panel.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	world_panel.anchor_bottom = 0.60
	world_panel.color = Color(
		0.07,
		0.08,
		0.10
	)
	root.add_child(world_panel)

	lower_panel = ColorRect.new()
	lower_panel.anchor_left = 0.0
	lower_panel.anchor_top = 0.60
	lower_panel.anchor_right = 1.0
	lower_panel.anchor_bottom = 1.0
	lower_panel.offset_left = 0
	lower_panel.offset_top = 0
	lower_panel.offset_right = 0
	lower_panel.offset_bottom = 0
	lower_panel.color = Color(
		0.035,
		0.035,
		0.04
	)
	root.add_child(lower_panel)

	enemy_layer = Control.new()
	enemy_layer.anchor_right = 1.0
	enemy_layer.anchor_bottom = 0.60
	root.add_child(enemy_layer)

	telegraph_layer = Control.new()
	telegraph_layer.anchor_right = 1.0
	telegraph_layer.anchor_bottom = 0.60
	root.add_child(telegraph_layer)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.anchor_left = 0.03
	player_hp_bar.anchor_top = 0.68
	player_hp_bar.anchor_right = 0.25
	player_hp_bar.anchor_bottom = 0.72
	player_hp_bar.show_percentage = false
	root.add_child(player_hp_bar)

	player_hp_label = Label.new()
	player_hp_label.anchor_left = 0.03
	player_hp_label.anchor_top = 0.73
	player_hp_label.anchor_right = 0.25
	player_hp_label.anchor_bottom = 0.77
	player_hp_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	root.add_child(player_hp_label)

	casting_ui = CastingUI.new()
	casting_ui.anchor_left = 0.31
	casting_ui.anchor_top = 0.65
	casting_ui.anchor_right = 0.69
	casting_ui.anchor_bottom = 0.98
	root.add_child(casting_ui)

	fusion_panel = Panel.new()
	fusion_panel.anchor_left = 0.75
	fusion_panel.anchor_top = 0.64
	fusion_panel.anchor_right = 0.97
	fusion_panel.anchor_bottom = 0.96
	root.add_child(fusion_panel)

	fusion_title = Label.new()
	fusion_title.anchor_right = 1.0
	fusion_title.anchor_bottom = 0.15
	fusion_title.text = "FUSION"
	fusion_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	fusion_panel.add_child(fusion_title)

	fusion_spell = Label.new()
	fusion_spell.anchor_top = 0.45
	fusion_spell.anchor_right = 1.0
	fusion_spell.anchor_bottom = 0.62
	fusion_spell.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	fusion_panel.add_child(fusion_spell)

	fusion_components = Label.new()
	fusion_components.anchor_top = 0.65
	fusion_components.anchor_right = 1.0
	fusion_components.anchor_bottom = 0.85
	fusion_components.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	fusion_panel.add_child(fusion_components)
	result_overlay = ColorRect.new()
	result_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	result_overlay.color = Color(
		0.0,
		0.0,
		0.0,
		0.72
	)
	result_overlay.visible = false
	root.add_child(result_overlay)

	result_label = Label.new()
	result_label.anchor_left = 0.25
	result_label.anchor_top = 0.32
	result_label.anchor_right = 0.75
	result_label.anchor_bottom = 0.48
	result_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	result_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	result_label.add_theme_font_size_override(
		"font_size",
		54
	)
	result_overlay.add_child(result_label)

	retry_button = Button.new()
	retry_button.anchor_left = 0.42
	retry_button.anchor_top = 0.54
	retry_button.anchor_right = 0.58
	retry_button.anchor_bottom = 0.62
	retry_button.text = "Retry"
	retry_button.pressed.connect(
		_on_retry_pressed
	)
	result_overlay.add_child(retry_button)

func _create_enemy_ui(enemy: BattleEnemy) -> void:
	var ui := EnemyUI.new()

	enemy_layer.add_child(ui)
	ui.setup(enemy)

	var index := enemy_uis.size()

	var x_positions := [
		0.18,
		0.50,
		0.82
	]

	var x_ratio: float = x_positions[
		mini(index, 2)
	]

	ui.anchor_left = x_ratio
	ui.anchor_right = x_ratio
	ui.anchor_top = 0.28
	ui.anchor_bottom = 0.28

	ui.position = Vector2(
		-130,
		0
	)

	enemy_uis[enemy] = ui


func refresh_targets(test_battle) -> void:
	_refresh_targets(test_battle)


func _refresh_targets(test_battle) -> void:
	var selected = (
		test_battle._get_selected_target()
	)

	var show_target : bool = (
		test_battle.rune_caster.has_combo()
	)

	for enemy in enemy_uis:
		var ui: EnemyUI = enemy_uis[enemy]

		ui.set_targeted(
			show_target
			and enemy == selected
		)


func _on_player_hp_changed(
	current_hp: int,
	max_hp: int
) -> void:
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = current_hp

	player_hp_label.text = "%d / %d" % [
		current_hp,
		max_hp
	]


func _on_casting_started(
	rune: RuneData
) -> void:
	casting_ui.show_cast_start(rune)


func _on_casting_updated(
	position: float,
	region: StringName
) -> void:
	casting_ui.update_cursor(
		position,
		region
	)


func _on_rune_success(
	_rune: RuneData,
	judgement: StringName
) -> void:
	casting_ui.show_judgement(
		judgement
	)


func _on_cast_missed() -> void:
	casting_ui.show_miss()


func _on_combo_changed(
	combo: Array[RuneData],
	perfect_count: int,
	test_battle
) -> void:
	casting_ui.update_combo(
		combo,
		perfect_count,
		test_battle.rune_caster.max_combo
	)

	var spell : SpellData = (
		test_battle.rune_caster.get_current_spell()
	)

	if spell == null:
		fusion_spell.text = ""
	else:
		fusion_spell.text = spell.display_name

	var names: Array[String] = []

	for rune in combo:
		names.append(rune.display_name)

	fusion_components.text = (
		" + ".join(names)
	)

	casting_ui.set_spell_ready(
		spell != null,
		test_battle.spell_executor.activation_locked
	)

	_refresh_targets(test_battle)


func _on_parry_changed(
	direction: int
) -> void:
	var direction_name : String = (
		EnemyAttackEvent.ParryDirection.keys()[
			direction
		]
	)

	casting_ui.show_parry(
		true,
		direction_name
	)


func _on_parry_cleared() -> void:
	casting_ui.show_parry(
		false,
		""
	)


func _on_spell_damage(
	target,
	_amount: int,
	_resistance: float,
	_perfect_count: int,
	_attribute_id: StringName
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()


func _on_dot_damage(
	target,
	_amount: int
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()


func _on_immune(
	target,
	_attribute_id: StringName
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()


func _on_enemy_attack_started(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	if enemy_uis.has(enemy):
		var ui: EnemyUI = enemy_uis[enemy]
		ui.flash_attack()

	_create_telegraph(
		enemy,
		event
	)


func _create_telegraph(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	var label := Label.new()

	label.text = "!"
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.size = Vector2(48, 48)

	match event.resolved_direction:
		EnemyAttackEvent.ParryDirection.UP:
			label.position = Vector2(
				936,
				30
			)

		EnemyAttackEvent.ParryDirection.DOWN:
			label.position = Vector2(
				936,
				560
			)

		EnemyAttackEvent.ParryDirection.LEFT:
			label.position = Vector2(
				40,
				300
			)

		EnemyAttackEvent.ParryDirection.RIGHT:
			label.position = Vector2(
				1832,
				300
			)

		EnemyAttackEvent.ParryDirection.FRONT:
			label.position = Vector2(
				936,
				110
			)

	label.modulate = Color(
		1.0,
		0.35,
		0.08,
		0.45
	)

	telegraph_layer.add_child(label)

	telegraphs[event] = label


func _on_enemy_attack_progressed(
	_enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	if not telegraphs.has(event):
		return

	var label: Label = telegraphs[event]

	var alpha := lerpf(
		0.4,
		1.0,
		event.telegraph_progress
	)

	if event.parry_window_active:
		label.modulate = Color(
			1.0,
			0.55,
			0.12,
			1.0
		)
	else:
		label.modulate.a = alpha

	var scale_value := lerpf(
		1.0,
		1.25,
		event.telegraph_progress
	)

	label.scale = Vector2.ONE * scale_value


func _on_enemy_attack_cancelled(
	_enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	_remove_telegraph(event)


func _on_enemy_attack_impacted(
	_enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	_remove_telegraph(event)


func _remove_telegraph(
	event: EnemyAttackEvent
) -> void:
	if not telegraphs.has(event):
		return

	var label = telegraphs[event]

	telegraphs.erase(event)

	if is_instance_valid(label):
		label.queue_free()
func show_result(
	victory: bool
) -> void:
	result_overlay.visible = true

	if victory:
		result_label.text = "VICTORY"
	else:
		result_label.text = "DEFEAT"


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
