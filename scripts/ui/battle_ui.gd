class_name BattleUI
extends CanvasLayer

const ALGIZ_RUNE: RuneData = preload("res://data/runes/algiz.tres")

var root: Control

var world_panel: ColorRect
var lower_panel: ColorRect

var enemy_layer: Control

var player_hp_bar: ProgressBar
var player_hp_label: Label

var casting_ui: CastingUI

var fusion_ui: FusionUI

var telegraph_layer: Control

var enemy_uis: Dictionary = {}
var telegraphs: Dictionary = {}
var result_overlay: ColorRect
var result_label: Label
var retry_button: Button
var low_hp_vignette: ColorRect
var player_status_grid: GridContainer
var hand_effect: ColorRect
var mist_overlay: ColorRect
var guard_effect: Panel
var battle_ref
var low_hp_active: bool = false
var low_hp_time: float = 0.0


func setup(test_battle) -> void:
	battle_ref = test_battle
	_build()

	if test_battle.battle_setup.background != null:
		var background := TextureRect.new()
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.texture = test_battle.battle_setup.background
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_panel.add_child(background)

	test_battle.player.hp_changed.connect(
		_on_player_hp_changed
	)
	test_battle.player.damaged.connect(_on_player_damaged)

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
	test_battle.spell_executor.enemy_effect_started.connect(
		_on_enemy_effect_started
	)
	test_battle.spell_executor.impact_pulse.connect(
		_on_impact_pulse
	)
	test_battle.battle_status.effects_changed.connect(
		_refresh_status_presentation.bind(test_battle)
	)
	test_battle.player_status.effects_changed.connect(
		_refresh_status_presentation.bind(test_battle)
	)
	test_battle.spell_executor.activation_started.connect(
		_on_spell_activation_started
	)
	test_battle.spell_executor.activation_lock_changed.connect(
		_on_activation_lock_changed.bind(test_battle)
	)
	test_battle.rune_caster.input_rejected.connect(
		_on_cast_rejected
	)

	for enemy in test_battle.enemies:
		_create_enemy_ui(
			enemy,
			test_battle.enemies.find(enemy),
			test_battle.enemies.size(),
			test_battle.resistance_knowledge
		)

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
		enemy.parried.connect(_on_enemy_parried)

	_refresh_targets(test_battle)

	_on_player_hp_changed(
		test_battle.player.hp,
		test_battle.player.max_hp
	)
	_refresh_status_presentation(test_battle)


func _process(delta: float) -> void:
	if not low_hp_active or low_hp_vignette == null:
		return

	low_hp_time += delta
	var pulse := 0.5 + 0.5 * sin(low_hp_time * 7.0)
	low_hp_vignette.modulate.a = lerpf(0.55, 1.0, pulse)
	player_hp_bar.modulate = Color(1.0, lerpf(0.3, 0.7, pulse), lerpf(0.3, 0.7, pulse))


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

	mist_overlay = ColorRect.new()
	mist_overlay.anchor_right = 1.0
	mist_overlay.anchor_bottom = 0.60
	mist_overlay.color = Color(0.62, 0.76, 0.78, 0.0)
	mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mist_overlay)

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

	player_status_grid = GridContainer.new()
	player_status_grid.columns = 4
	player_status_grid.anchor_left = 0.03
	player_status_grid.anchor_top = 0.79
	player_status_grid.anchor_right = 0.25
	player_status_grid.anchor_bottom = 0.91
	player_status_grid.add_theme_constant_override("h_separation", 6)
	player_status_grid.add_theme_constant_override("v_separation", 6)
	root.add_child(player_status_grid)

	for _i in range(8):
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(42, 32)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.text = "·"
		player_status_grid.add_child(slot)

	guard_effect = Panel.new()
	guard_effect.anchor_left = 0.02
	guard_effect.anchor_top = 0.62
	guard_effect.anchor_right = 0.27
	guard_effect.anchor_bottom = 0.96
	guard_effect.modulate = Color(0.2, 0.85, 0.45, 0.0)
	guard_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(guard_effect)

	casting_ui = CastingUI.new()
	casting_ui.anchor_left = 0.31
	casting_ui.anchor_top = 0.65
	casting_ui.anchor_right = 0.69
	casting_ui.anchor_bottom = 0.98
	root.add_child(casting_ui)

	fusion_ui = FusionUI.new()
	fusion_ui.style = preload(
	"res://data/runes/default_base.tres"
	)
	fusion_ui.anchor_left = 0.73
	fusion_ui.anchor_top = 0.61
	fusion_ui.anchor_right = 0.98
	fusion_ui.anchor_bottom = 0.99
	root.add_child(fusion_ui)

	hand_effect = ColorRect.new()
	hand_effect.anchor_left = 0.64
	hand_effect.anchor_top = 0.51
	hand_effect.anchor_right = 0.71
	hand_effect.anchor_bottom = 0.60
	hand_effect.color = Color(0.8, 0.8, 0.86, 0.0)
	hand_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hand_effect)

	low_hp_vignette = ColorRect.new()
	low_hp_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	low_hp_vignette.color = Color(0.45, 0.0, 0.0, 0.0)
	low_hp_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(low_hp_vignette)
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

func _create_enemy_ui(
	enemy: BattleEnemy,
	index: int,
	count: int,
	knowledge: ResistanceKnowledge
) -> void:
	var ui := EnemyUI.new()

	enemy_layer.add_child(ui)
	ui.setup(enemy, knowledge)

	var x_ratio := _get_enemy_x_ratio(index, count)

	# EnemyUI の「中心」を x_ratio の位置に置く
	ui.anchor_left = x_ratio
	ui.anchor_right = x_ratio
	ui.anchor_top = 0.28
	ui.anchor_bottom = 0.28

	# EnemyUI 自身が持つ必要サイズを使う。
	# BattleUI 側では 260x300 等をハードコードしない。
	var ui_size := ui.get_combined_minimum_size()

	ui.offset_left = -ui_size.x * 0.5
	ui.offset_right = ui_size.x * 0.5
	ui.offset_top = 0.0
	ui.offset_bottom = ui_size.y

	enemy_uis[enemy] = ui


func _get_enemy_x_ratio(
	index: int,
	count: int
) -> float:
	match count:
		1:
			return 0.5

		2:
			return [0.33, 0.67][index]

		3:
			return [0.18, 0.50, 0.82][index]

		_:
			return float(index + 1) / float(count + 1)

func refresh_targets(test_battle) -> void:
	_refresh_targets(test_battle)


func _refresh_targets(test_battle) -> void:
	var selected = (
		test_battle._get_selected_target()
	)

	var show_target: bool = test_battle._current_spell_uses_selected_enemy()

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

	var ratio := float(current_hp) / float(maxi(max_hp, 1))
	low_hp_active = ratio <= 0.25 and current_hp > 0
	low_hp_vignette.color.a = clampf((0.25 - ratio) * 1.4, 0.0, 0.28)
	low_hp_vignette.modulate.a = 1.0
	if not low_hp_active:
		player_hp_bar.modulate = Color.WHITE


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

	fusion_ui.update_combo(combo, spell)

	casting_ui.set_spell_ready(
		spell != null,
		test_battle.spell_executor.activation_locked
	)

	_refresh_targets(test_battle)


func _on_spell_activation_started(_event: PlayerAttackEvent) -> void:
	fusion_ui.flash_fire()
	var event := _event
	hand_effect.color = Color(event.spell.effect_color, 0.78)
	hand_effect.position.x += 28.0
	var tween := create_tween()
	tween.tween_property(hand_effect, "position:x", hand_effect.position.x - 28.0, 0.08)


func _on_activation_lock_changed(_locked: bool, test_battle) -> void:
	var spell: SpellData = test_battle.rune_caster.get_current_spell()
	casting_ui.set_spell_ready(
		spell != null,
		test_battle.spell_executor.activation_locked
	)


func _on_cast_rejected(_reason: StringName) -> void:
	casting_ui.show_rejection()


func _on_enemy_effect_started(_event: PlayerAttackEvent) -> void:
	create_tween().tween_property(hand_effect, "color:a", 0.0, 0.12)


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

	fusion_ui.show_parry(
		ALGIZ_RUNE,
		direction as EnemyAttackEvent.ParryDirection
	)


func _on_parry_cleared() -> void:
	casting_ui.show_parry(
		false,
		""
	)

	var combo: Array[RuneData] = battle_ref.rune_caster.combo
	fusion_ui.update_combo(
		combo,
		battle_ref.rune_caster.get_current_spell()
	)


func _on_spell_damage(
	target,
	amount: int,
	resistance: float,
	perfect_count: int,
	_attribute_id: StringName
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()
		var color := Color.WHITE
		if resistance > 1.0:
			color = Color(1.0, 0.72, 0.22)
		elif resistance < 1.0:
			color = Color(0.65, 0.68, 0.72)
		ui.show_damage_number(
			str(amount),
			color,
			1.0 + float(perfect_count) * 0.16
		)


func _on_dot_damage(
	target,
	amount: int
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()
		ui.show_damage_number(str(amount), Color(0.9, 0.52, 0.25), 0.78)


func _on_immune(
	target,
	_attribute_id: StringName
) -> void:
	if enemy_uis.has(target):
		var ui: EnemyUI = enemy_uis[target]
		ui.flash_hit()
		ui.show_damage_number("IMMUNE", Color(0.62, 0.64, 0.68), 0.9)


func _on_impact_pulse(
	target,
	color: Color,
	intensity: float,
	_spell_id: StringName
) -> void:
	if enemy_uis.has(target):
		(enemy_uis[target] as EnemyUI).pulse_status(color, intensity)


func _on_player_damaged(amount: int) -> void:
	var number := Label.new()
	number.text = "-%d" % amount
	number.anchor_left = 0.09
	number.anchor_top = 0.64
	number.anchor_right = 0.19
	number.anchor_bottom = 0.69
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_color_override("font_color", Color(1.0, 0.35, 0.32))
	root.add_child(number)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", -36.0, 0.55)
	tween.tween_property(number, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(number.queue_free)
	_shake_root(5.0, 0.16)


func _on_enemy_parried(enemy: BattleEnemy, _event: EnemyAttackEvent) -> void:
	if enemy_uis.has(enemy):
		(enemy_uis[enemy] as EnemyUI).flash_parry()
	_shake_root(7.0, 0.12)


func _refresh_status_presentation(test_battle) -> void:
	var slots := player_status_grid.get_children()
	for slot in slots:
		(slot as Label).text = "·"

	var index := 0
	for entry in test_battle.player_status.get_debug_entries():
		if index >= 4:
			break
		(slots[index] as Label).text = String(entry["id"]).substr(0, 1).to_upper()
		(slots[index] as Label).tooltip_text = String(entry["id"])
		index += 1

	var mist_active: bool = test_battle.battle_status.has_effect(&"mist")
	create_tween().tween_property(mist_overlay, "color:a", 0.12 if mist_active else 0.0, 0.3)
	var guard_active: bool = test_battle.player_status.has_effect(&"algae_guard")
	create_tween().tween_property(guard_effect, "modulate:a", 0.28 if guard_active else 0.0, 0.2)


func _shake_root(strength: float, duration: float) -> void:
	var origin := root.position
	var tween := create_tween()
	var steps := 4
	for i in range(steps):
		var direction := -1.0 if i % 2 == 0 else 1.0
		tween.tween_property(root, "position:x", origin.x + strength * direction, duration / float(steps))
	tween.tween_property(root, "position", origin, duration / float(steps))


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
	var telegraph := TelegraphUI.new()
	var stack_index := 0

	for existing_event in telegraphs:
		if existing_event.resolved_direction == event.resolved_direction:
			stack_index += 1

	var source_index: int = battle_ref.enemies.find(enemy)
	var colors := [
		Color(1.0, 0.34, 0.08),
		Color(1.0, 0.52, 0.12),
		Color(0.92, 0.26, 0.18),
		Color(1.0, 0.68, 0.18)
	]
	telegraph.configure(colors[posmod(source_index, colors.size())])
	telegraph.anchor_left = 0.5
	telegraph.anchor_right = 0.5
	telegraph.anchor_top = 0.18
	telegraph.anchor_bottom = 0.18

	match event.resolved_direction:
		EnemyAttackEvent.ParryDirection.UP:
			telegraph.anchor_top = 0.03
			telegraph.anchor_bottom = 0.03

		EnemyAttackEvent.ParryDirection.DOWN:
			telegraph.anchor_top = 0.88
			telegraph.anchor_bottom = 0.88

		EnemyAttackEvent.ParryDirection.LEFT:
			telegraph.anchor_left = 0.03
			telegraph.anchor_right = 0.03
			telegraph.anchor_top = 0.48
			telegraph.anchor_bottom = 0.48

		EnemyAttackEvent.ParryDirection.RIGHT:
			telegraph.anchor_left = 0.94
			telegraph.anchor_right = 0.94
			telegraph.anchor_top = 0.48
			telegraph.anchor_bottom = 0.48

		EnemyAttackEvent.ParryDirection.FRONT:
			pass

	telegraph.offset_left = -27.0 + float(stack_index) * 34.0
	telegraph.offset_right = 27.0 + float(stack_index) * 34.0
	telegraph.offset_top = -27.0
	telegraph.offset_bottom = 27.0
	telegraph_layer.add_child(telegraph)
	telegraphs[event] = telegraph


func _on_enemy_attack_progressed(
	_enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	if not telegraphs.has(event):
		return

	var telegraph := telegraphs[event] as TelegraphUI
	telegraph.set_progress(event.telegraph_progress, event.parry_window_active)


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
	if battle_ref != null:
		battle_ref.persistent_data.current_hp = battle_ref.persistent_data.max_hp
		SaveSystem.save_player(battle_ref.persistent_data)
	get_tree().reload_current_scene()
