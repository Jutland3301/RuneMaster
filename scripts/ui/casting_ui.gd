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
var perfect_label: Label
var enter_label: Label
var parry_label: Label


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

	gauge_background = ColorRect.new()
	gauge_background.position = Vector2(50, 50)
	gauge_background.size = Vector2(600, 34)
	gauge_background.color = Color(0.06, 0.06, 0.07)
	add_child(gauge_background)

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

	judgement_label = Label.new()
	judgement_label.position = Vector2(0, 95)
	judgement_label.size = Vector2(700, 32)
	judgement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(judgement_label)

	combo_label = Label.new()
	combo_label.position = Vector2(0, 135)
	combo_label.size = Vector2(700, 30)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.text = "[ empty ]  [ empty ]"
	add_child(combo_label)

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
	judgement_label.text = ""
	cursor.visible = true

	modulate.a = 1.0


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

		&"normal":
			judgement_label.text = "NORMAL"

		&"miss":
			judgement_label.text = "MISS"

		_:
			judgement_label.text = ""

	cursor.visible = false


func show_miss() -> void:
	judgement_label.text = "MISS"
	cursor.visible = false


func update_combo(
	combo: Array[RuneData],
	perfect_count: int,
	max_combo: int
) -> void:
	var slots: Array[String] = []

	for i in range(max_combo):
		if i < combo.size():
			slots.append(
				"[ %s ]" % combo[i].display_name
			)
		else:
			slots.append("[ empty ]")

	combo_label.text = "  ".join(slots)

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
