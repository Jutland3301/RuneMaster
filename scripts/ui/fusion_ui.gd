class_name FusionUI
extends Control

var spell_label: Label
var component_label: Label
var base_texture_rect: TextureRect
var symbol_layer: Control

var rune_symbols: Array[Control] = []

@export var style: FusionUIStyle


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	base_texture_rect = TextureRect.new()

	base_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if style != null:
		base_texture_rect.anchor_left = style.base_left
		base_texture_rect.anchor_top = style.base_top
		base_texture_rect.anchor_right = style.base_right
		base_texture_rect.anchor_bottom = style.base_bottom

		base_texture_rect.texture = style.base_texture
		base_texture_rect.modulate = style.base_modulate

	base_texture_rect.offset_left = 0.0
	base_texture_rect.offset_top = 0.0
	base_texture_rect.offset_right = 0.0
	base_texture_rect.offset_bottom = 0.0

	base_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base_texture_rect)

	symbol_layer = Control.new()
	symbol_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	symbol_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(symbol_layer)

	spell_label = Label.new()
	spell_label.anchor_left = 0.02
	spell_label.anchor_top = 0.72
	spell_label.anchor_right = 0.98
	spell_label.anchor_bottom = 0.82
	spell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spell_label.add_theme_font_size_override("font_size", 22)
	add_child(spell_label)

	component_label = Label.new()
	component_label.anchor_left = 0.02
	component_label.anchor_top = 0.83
	component_label.anchor_right = 0.98
	component_label.anchor_bottom = 0.96
	component_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	component_label.add_theme_color_override(
		"font_color",
		Color(0.08, 0.08, 0.09)
	)
	add_child(component_label)


func update_combo(
	combo: Array[RuneData],
	spell: SpellData
) -> void:
	for symbol in rune_symbols:
		symbol.queue_free()

	rune_symbols.clear()

	var names: Array[String] = []

	for rune in combo:
		names.append(rune.display_name)
		_add_rune_symbol(rune)

	spell_label.text = (
		spell.display_name
		if spell != null
		else ""
	)

	component_label.text = "  •  ".join(names)

	if combo.is_empty():
		return

	var fused_color := _get_fused_color(combo)

	_flash_fusion_color(fused_color)

func flash_fire() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0.65)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(
		flash,
		"color:a",
		0.0,
		0.18
	)
	tween.tween_callback(flash.queue_free)


func _add_rune_symbol(
	rune: RuneData
) -> void:
	var symbol: Control

	if rune.texture != null:
		var texture_rect := TextureRect.new()

		texture_rect.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		texture_rect.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		texture_rect.texture = rune.texture
		texture_rect.modulate = Color.WHITE

		symbol = texture_rect

	else:
		var label := Label.new()

		label.text = (
			String(rune.id)
			.substr(0, 1)
			.to_upper()
		)

		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		label.add_theme_font_size_override(
			"font_size",
			58
		)

		label.add_theme_color_override(
			"font_color",
			rune.rune_color.lightened(0.35)
		)

		symbol = label

	if style != null:
		var center_x := (
			style.base_left + style.base_right
		) * 0.5

		var center_y := (
			style.base_top + style.base_bottom
		) * 0.5

		var half_width := style.symbol_width_ratio * 0.5
		var half_height := style.symbol_height_ratio * 0.5

		symbol.anchor_left = center_x - half_width
		symbol.anchor_right = center_x + half_width

		symbol.anchor_top = center_y - half_height
		symbol.anchor_bottom = center_y + half_height

	else:
		symbol.anchor_left = 0.30
		symbol.anchor_top = 0.08
		symbol.anchor_right = 0.70
		symbol.anchor_bottom = 0.60

	symbol.offset_left = 0.0
	symbol.offset_top = 0.0
	symbol.offset_right = 0.0
	symbol.offset_bottom = 0.0

	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE

	symbol_layer.add_child(symbol)
	rune_symbols.append(symbol)

func _get_fused_color(combo: Array[RuneData]) -> Color:
	if combo.is_empty():
		return Color.WHITE

	var r := 0.0
	var g := 0.0
	var b := 0.0

	for rune in combo:
		r += rune.rune_color.r
		g += rune.rune_color.g
		b += rune.rune_color.b

	var max_component := maxf(r, maxf(g, b))

	# RGB比率を壊さず、範囲内へ正規化
	if max_component > 1.0:
		r /= max_component
		g /= max_component
		b /= max_component

	var fused := Color(r, g, b, 1.0)

	# 最終融合色を少しだけ明るく
	return fused.lightened(0.18)

func _flash_fusion_color(
	fused_color: Color
) -> void:
	for symbol in rune_symbols:
		symbol.modulate = Color.WHITE

	var tween := create_tween()

	tween.tween_interval(0.2)

	tween.tween_callback(
		func():
			for symbol in rune_symbols:
				if is_instance_valid(symbol):
					symbol.modulate = fused_color
	)
