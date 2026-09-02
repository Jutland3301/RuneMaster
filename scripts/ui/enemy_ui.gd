class_name EnemyUI
extends Control

var enemy: BattleEnemy
var knowledge: ResistanceKnowledge

var hp_trail: ProgressBar
var hp_bar: ProgressBar
var body: Control
var body_color: ColorRect
var target_frame: Panel
var hover_ui: EnemyHoverUI
var status_marks: HBoxContainer

const UI_WIDTH := 260.0
const BODY_FLOOR_Y := 380.0
const BODY_SCALE := 1.5

const SPRITE_BASE_SIZE := Vector2(200, 210)
const COLOR_BODY_BASE_SIZE := Vector2(154, 174)

func setup(p_enemy: BattleEnemy, p_knowledge: ResistanceKnowledge) -> void:
	enemy = p_enemy
	knowledge = p_knowledge
	custom_minimum_size = Vector2(
	UI_WIDTH,
	BODY_FLOOR_Y
	)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

	hp_bar.max_value = enemy.data.max_hp
	hp_bar.value = enemy.hp
	hp_trail.max_value = enemy.data.max_hp
	hp_trail.value = enemy.hp

	enemy.hp_changed.connect(_on_hp_changed)
	enemy.died.connect(_on_died)
	enemy.status_controller.effects_changed.connect(_refresh_status_marks)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if knowledge != null:
		knowledge.knowledge_changed.connect(_on_knowledge_changed)

	_start_idle_motion()


func _process(_delta: float) -> void:
	if hover_ui != null and hover_ui.visible and enemy != null:
		hover_ui.show_enemy(enemy, knowledge)


func _build() -> void:
	hp_trail = ProgressBar.new()
	hp_trail.position = Vector2(20, 20)
	hp_trail.size = Vector2(220, 16)
	hp_trail.show_percentage = false
	hp_trail.modulate = Color(0.82, 0.46, 0.22)
	add_child(hp_trail)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(20, 20)
	hp_bar.size = Vector2(220, 16)
	hp_bar.show_percentage = false
	add_child(hp_bar)

	status_marks = HBoxContainer.new()
	status_marks.position = Vector2(20, 40)
	status_marks.size = Vector2(220, 22)
	status_marks.alignment = BoxContainer.ALIGNMENT_CENTER
	status_marks.add_theme_constant_override("separation", 4)
	add_child(status_marks)

	target_frame = Panel.new()

	var sprite_size := (
		SPRITE_BASE_SIZE * BODY_SCALE
	)

	var sprite_position := Vector2(
		(UI_WIDTH - sprite_size.x) * 0.5,
		BODY_FLOOR_Y - sprite_size.y
	)

	target_frame.position = (
		sprite_position - Vector2(6, 6)
	)
	target_frame.size = (
		sprite_size + Vector2(12, 12)
	)
	target_frame.visible = false

	var outline := StyleBoxFlat.new()
	outline.bg_color = Color(0, 0, 0, 0)
	outline.border_color = Color(
		0.75,
		0.12,
		0.12,
		0.72
	)
	outline.set_border_width_all(2)

	target_frame.add_theme_stylebox_override(
		"panel",
		outline
	)
	add_child(target_frame)

	if enemy.data.sprite != null:
		var sprite := TextureRect.new()

		sprite.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)
		sprite.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		sprite.texture = enemy.data.sprite
		sprite.position = sprite_position
		sprite.size = sprite_size

		body = sprite

	else:
		var color_body_size := (
			COLOR_BODY_BASE_SIZE * BODY_SCALE
		)

		body_color = ColorRect.new()
		body_color.color = (
			enemy.data.presentation_color
		)
		body_color.position = Vector2(
			(UI_WIDTH - color_body_size.x) * 0.5,
			BODY_FLOOR_Y - color_body_size.y
		)
		body_color.size = color_body_size

		body = body_color

	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	move_child(
		target_frame,
		get_child_count() - 1
	)

	hover_ui = EnemyHoverUI.new()
	hover_ui.position = Vector2(-5, 68)
	hover_ui.visible = false
	add_child(hover_ui)


func set_targeted(value: bool) -> void:
	target_frame.visible = value


func flash_attack() -> void:
	_flash(Color(1.0, 0.45, 0.12), 0.18)


func flash_hit() -> void:
	_flash(Color.WHITE, 0.12)
	var start_x := body.position.x
	var tween := create_tween()
	tween.tween_property(body, "position:x", start_x + 7.0, 0.035)
	tween.tween_property(body, "position:x", start_x - 5.0, 0.045)
	tween.tween_property(body, "position:x", start_x, 0.045)


func flash_parry() -> void:
	var old := body.modulate
	body.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_interval(0.075)
	tween.tween_property(body, "modulate", old, 0.12)


func pulse_status(color: Color, intensity: float = 1.0) -> void:
	var overlay := ColorRect.new()
	overlay.position = body.position - Vector2(8, 8)
	overlay.size = body.size + Vector2(16, 16)
	overlay.color = Color(color, clampf(0.22 * intensity, 0.18, 0.75))
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.18 + 0.06 * intensity)
	tween.tween_callback(overlay.queue_free)


func show_damage_number(
	text: String,
	color: Color,
	scale_amount: float = 1.0
) -> void:
	var number := Label.new()
	number.text = text
	number.position = Vector2(88, 105)
	number.size = Vector2(120, 38)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", int(24.0 * scale_amount))
	number.add_theme_color_override("font_color", color)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(number)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - 52.0, 0.7)
	tween.tween_property(number, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(number.queue_free)


func _flash(color: Color, duration: float) -> void:
	var old := body.modulate
	body.modulate = color
	create_tween().tween_property(body, "modulate", old, duration)


func _on_hp_changed(_changed_enemy: BattleEnemy, current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_trail.max_value = max_hp
	hp_bar.value = current_hp

	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(hp_trail, "value", current_hp, 0.25)
	flash_hit()

	if hover_ui.visible:
		hover_ui.show_enemy(enemy, knowledge)


func _on_died(_dead_enemy: BattleEnemy) -> void:
	target_frame.visible = false
	hover_ui.visible = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "scale", Vector2(1.28, 0.04), 0.22)
	tween.tween_property(body, "rotation", 0.16, 0.22)
	tween.tween_property(body, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(func(): visible = false)


func _on_mouse_entered() -> void:
	if enemy.is_alive():
		hover_ui.show_enemy(enemy, knowledge)
		hover_ui.visible = true


func _on_mouse_exited() -> void:
	hover_ui.visible = false


func _on_knowledge_changed(enemy_id: StringName, _attribute_id: StringName) -> void:
	if enemy.data.id == enemy_id and hover_ui.visible:
		hover_ui.show_enemy(enemy, knowledge)


func _refresh_status_marks() -> void:
	for child in status_marks.get_children():
		child.queue_free()

	for entry in enemy.status_controller.get_debug_entries():
		var mark := Label.new()
		mark.text = String(entry["id"]).substr(0, 1).to_upper()
		mark.tooltip_text = String(entry["id"])
		status_marks.add_child(mark)


func _start_idle_motion() -> void:
	var base_y := body.position.y

	# 敵ごとに一度だけ抽選する。
	# 毎フレーム乱数を使わないため、動きは滑らか。
	var rise_amount := randf_range(3.2, 5.0)
	var fall_amount := randf_range(1.2, 2.8)

	var rise_duration := randf_range(1.05, 1.38)
	var fall_duration := randf_range(1.08, 1.42)

	# 全員が同じ瞬間から同じ位相で動くのを防ぐ。
	body.position.y = (
		base_y
		+ randf_range(
			-rise_amount * 0.45,
			fall_amount * 0.45
		)
	)

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(
		body,
		"position:y",
		base_y - rise_amount,
		rise_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		body,
		"position:y",
		base_y + fall_amount,
		fall_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)
