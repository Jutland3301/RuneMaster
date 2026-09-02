class_name CastingUI
extends Control

var gauge_background: ColorRect
var miss_left: ColorRect
var normal_left: ColorRect
var perfect_band: ColorRect
var normal_right: ColorRect
var miss_right: ColorRect

var cursor: ColorRect

var rune_label: Label
var judgement_label: Label
var combo_label: Label
var combo_slots: HBoxContainer
var perfect_label: Label
var enter_label: Label
var parry_label: Label
var rune_texture: TextureRect
var gauge_parts: Array[CanvasItem] = []


func _ready() -> void:
	_build()


func _build() -> void:
	custom_minimum_size = Vector2(700, 300)

	rune_label = Label.new()
	rune_label.position = Vector2(0, 0)
	rune_label.size = Vector2(700, 30)
	rune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_label.text = ""
	add_child(rune_label)

	rune_texture = TextureRect.new()
	rune_texture.position = Vector2(8, 35)
	rune_texture.size = Vector2(36, 52)
	rune_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rune_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(rune_texture)

	gauge_background = ColorRect.new()
	gauge_background.position = Vector2(50, 50)
	gauge_background.size = Vector2(600, 34)
	gauge_background.color = Color(0.06, 0.06, 0.07)
	add_child(gauge_background)
	gauge_parts.append(gauge_background)

	miss_left = _make_band(
		Vector2(50, 50),
		Vector2(120, 34),
		Color(0.20, 0.05, 0.05)
	)

	normal_left = _make_band(
		Vector2(170, 50),
		Vector2(162, 34),
		Color(0.23, 0.23, 0.25)
	)

	perfect_band = _make_band(
		Vector2(332, 50),
		Vector2(36, 34),
		Color(0.80, 0.72, 0.25)
	)

	normal_right = _make_band(
		Vector2(368, 50),
		Vector2(162, 34),
		Color(0.23, 0.23, 0.25)
	)

	miss_right = _make_band(
		Vector2(530, 50),
		Vector2(120, 34),
		Color(0.20, 0.05, 0.05)
	)

	cursor = ColorRect.new()
	cursor.position = Vector2(50, 44)
	cursor.size = Vector2(4, 46)
	cursor.color = Color.WHITE
	cursor.visible = false
	add_child(cursor)
	gauge_parts.append(cursor)

	for band in [miss_left, normal_left, perfect_band, normal_right, miss_right]:
		gauge_parts.append(band)

	_set_gauge_alpha(0.18)

	judgement_label = Label.new()
	judgement_label.position = Vector2(0, 95)
	judgement_label.size = Vector2(700, 32)
	judgement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(judgement_label)

	combo_slots = HBoxContainer.new()
	combo_slots.position = Vector2(0, 130)
	combo_slots.size = Vector2(700, 42)
	combo_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	combo_slots.add_theme_constant_override("separation", 8)
	add_child(combo_slots)

	perfect_label = Label.new()
	perfect_label.position = Vector2(0, 170)
	perfect_label.size = Vector2(700, 30)
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(perfect_label)

	enter_label = Label.new()
	enter_label.position = Vector2(0, 205)
	enter_label.size = Vector2(700, 30)
	enter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_label.text = ""
	add_child(enter_label)

	parry_label = Label.new()
	parry_label.position = Vector2(0, 240)
	parry_label.size = Vector2(700, 30)
	parry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parry_label.text = ""
	add_child(parry_label)


func _make_band(
	p_position: Vector2,
	p_size: Vector2,
	p_color: Color
) -> ColorRect:
	var band := ColorRect.new()

	band.position = p_position
	band.size = p_size
	band.color = p_color

	add_child(band)

	return band


func show_cast_start(rune: RuneData) -> void:
	rune_label.text = rune.display_name
	rune_texture.texture = rune.texture
	judgement_label.text = ""
	cursor.visible = true
	_set_gauge_alpha(1.0)


func update_cursor(
	normalized_position: float,
	_region: StringName
) -> void:
	cursor.visible = true

	cursor.position.x = (
		50.0
		+ clampf(
			normalized_position,
			0.0,
			1.0
		) * 600.0
	)


func show_judgement(
	judgement: StringName
) -> void:
	match judgement:
		&"perfect":
			judgement_label.text = "PERFECT"
			judgement_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

		&"normal":
			judgement_label.text = "NORMAL"
			judgement_label.add_theme_color_override("font_color", Color.WHITE)

		&"miss":
			judgement_label.text = "MISS"

		_:
			judgement_label.text = ""

	cursor.visible = false
	_fade_gauge_idle()


func show_miss() -> void:
	judgement_label.text = "MISS"
	judgement_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.18))
	cursor.visible = false
	_fade_gauge_idle()


func show_rejection() -> void:
	judgement_label.text = "INVALID"
	judgement_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_property(judgement_label, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func():
		judgement_label.text = ""
		judgement_label.modulate.a = 1.0
	)


func update_combo(
	combo: Array[RuneData],
	perfect_count: int,
	max_combo: int
) -> void:
	while combo_slots.get_child_count() < max_combo:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(108, 40)
		combo_slots.add_child(panel)

	while combo_slots.get_child_count() > max_combo:
		var extra := combo_slots.get_child(combo_slots.get_child_count() - 1)
		combo_slots.remove_child(extra)
		extra.queue_free()

	for i in range(max_combo):
		var panel := combo_slots.get_child(i) as Panel
		for child in panel.get_children():
			panel.remove_child(child)
			child.queue_free()

		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = combo[i].display_name if i < combo.size() else "○"
		label.add_theme_font_size_override("font_size", 13)
		if i < combo.size():
			label.add_theme_color_override("font_color", combo[i].rune_color.lightened(0.25))
		panel.add_child(label)

	if perfect_count >= 2:
		perfect_label.text = (
			"PERFECT x%d" % perfect_count
		)
	else:
		perfect_label.text = ""


func set_spell_ready(
	ready: bool,
	locked: bool
) -> void:
	if not ready:
		enter_label.text = ""
		return

	if locked:
		enter_label.text = "[ ENTER LOCKED ]"
	else:
		enter_label.text = "[ ENTER : CAST ]"


func show_parry(
	active: bool,
	direction_name: String
) -> void:
	if not active:
		parry_label.text = ""
		return

	parry_label.text = (
		"ALGIZ : " + direction_name
	)


func _set_gauge_alpha(value: float) -> void:
	for part in gauge_parts:
		part.modulate.a = value


func _fade_gauge_idle() -> void:
	var tween := create_tween()

	for part in gauge_parts:
		tween.parallel().tween_property(part, "modulate:a", 0.18, 0.16)
