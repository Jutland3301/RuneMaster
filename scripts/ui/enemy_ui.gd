class_name EnemyUI
extends Control

var enemy: BattleEnemy

var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var body: ColorRect
var target_frame: Panel

var base_color := Color(0.32, 0.30, 0.34)


func setup(p_enemy: BattleEnemy) -> void:
	enemy = p_enemy

	custom_minimum_size = Vector2(260, 300)

	_build()

	hp_bar.max_value = enemy.data.max_hp
	hp_bar.value = enemy.hp

	hp_label.text = "%d / %d" % [
		enemy.hp,
		enemy.data.max_hp
	]

	# Temporary debug/test presentation.
	# Final enemy sprite can replace this body later.
	body.color = base_color

	enemy.hp_changed.connect(_on_hp_changed)
	enemy.died.connect(_on_died)


func _build() -> void:
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 0)
	name_label.size = Vector2(260, 30)
	name_label.text = enemy.data.display_name
	add_child(name_label)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(20, 34)
	hp_bar.size = Vector2(220, 18)
	hp_bar.show_percentage = false
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.position = Vector2(20, 54)
	hp_label.size = Vector2(220, 24)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hp_label)

	target_frame = Panel.new()
	target_frame.position = Vector2(45, 85)
	target_frame.size = Vector2(170, 190)
	target_frame.visible = false
	add_child(target_frame)

	body = ColorRect.new()
	body.position = Vector2(55, 95)
	body.size = Vector2(150, 170)
	add_child(body)

	# Keep frame above body.
	move_child(target_frame, get_child_count() - 1)


func set_targeted(value: bool) -> void:
	target_frame.visible = value


func flash_attack() -> void:
	if body == null:
		return

	var old := body.color
	body.color = Color(0.75, 0.35, 0.12)

	var tween := create_tween()
	tween.tween_property(
		body,
		"color",
		old,
		0.18
	)


func flash_hit() -> void:
	if body == null:
		return

	var old := body.color
	body.color = Color.WHITE

	var tween := create_tween()
	tween.tween_property(
		body,
		"color",
		old,
		0.12
	)


func _on_hp_changed(
	_changed_enemy: BattleEnemy,
	current_hp: int,
	max_hp: int
) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	hp_label.text = "%d / %d" % [
		current_hp,
		max_hp
	]

	flash_hit()


func _on_died(
	_dead_enemy: BattleEnemy
) -> void:
	target_frame.visible = false

	var tween := create_tween()

	tween.tween_property(
		body,
		"scale",
		Vector2(1.25, 0.05),
		0.18
	)

	tween.parallel().tween_property(
		body,
		"modulate:a",
		0.0,
		0.18
	)

	tween.tween_callback(
		func():
			visible = false
	)
