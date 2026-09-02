class_name TelegraphUI
extends Panel

var mark: Label
var progress: float = 0.0
var parry_window: bool = false
var blink_time: float = 0.0
var source_color := Color(1.0, 0.38, 0.08)
var panel_style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = Vector2(54, 54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.07, 0.02, 0.68)
	panel_style.border_color = source_color
	panel_style.set_border_width_all(2)
	add_theme_stylebox_override("panel", panel_style)

	mark = Label.new()
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.text = "!"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 32)
	mark.add_theme_color_override("font_color", source_color.lightened(0.3))
	add_child(mark)


func configure(color: Color) -> void:
	source_color = color


func set_progress(value: float, in_parry_window: bool) -> void:
	progress = clampf(value, 0.0, 1.0)
	parry_window = in_parry_window


func _process(delta: float) -> void:
	if mark == null:
		return

	blink_time += delta
	var frequency := lerpf(2.0, 11.0, progress)
	var pulse := 0.5 + 0.5 * sin(blink_time * frequency * TAU)
	var alpha := lerpf(0.42, 1.0, progress)

	if parry_window:
		alpha = 1.0
		panel_style.border_color = Color(1.0, 0.68, 0.18)
	else:
		panel_style.border_color = source_color

	modulate.a = clampf(alpha * lerpf(0.72, 1.0, pulse), 0.32, 1.0)
	scale = Vector2.ONE * lerpf(0.92, 1.18, progress)
