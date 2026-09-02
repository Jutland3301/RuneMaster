class_name DebugHub
extends Control

# 現在project.godotのmain_sceneに指定されているTestBattle。
const STANDARD_TEST_BATTLE: PackedScene = preload(
	"uid://dpmmsgmmfi1g2"
)

var fight_list: VBoxContainer
var settings_container: VBoxContainer
var launch_button: Button

var selected_fight: StringName = &"standard_test_battle"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_select_fight(&"standard_test_battle")


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.028, 0.04)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_bottom", 45)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 24)
	margin.add_child(page)

	var header := _build_header()
	page.add_child(header)

	var divider := HSeparator.new()
	page.add_child(divider)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 28)
	page.add_child(body)

	var fight_panel := _build_fight_panel()
	fight_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fight_panel.size_flags_stretch_ratio = 0.42
	body.add_child(fight_panel)

	var settings_panel := _build_settings_panel()
	settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_panel.size_flags_stretch_ratio = 0.58
	body.add_child(settings_panel)

	var footer := _build_footer()
	page.add_child(footer)


func _build_header() -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "DEBUG HUB"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override(
		"font_color",
		Color(0.82, 0.72, 1.0)
	)
	container.add_child(title)

	var subtitle := Label.new()
	subtitle.text = (
		"RuneMaster development and battle testing"
	)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override(
		"font_color",
		Color(0.58, 0.60, 0.68)
	)
	container.add_child(subtitle)

	return container


func _build_fight_panel() -> PanelContainer:
	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "DEBUG FIGHTS"
	heading.add_theme_font_size_override("font_size", 22)
	content.add_child(heading)

	var description := Label.new()
	description.text = "Select a battle configuration."
	description.add_theme_color_override(
		"font_color",
		Color(0.65, 0.67, 0.72)
	)
	content.add_child(description)

	var separator := HSeparator.new()
	content.add_child(separator)

	fight_list = VBoxContainer.new()
	fight_list.add_theme_constant_override("separation", 10)
	content.add_child(fight_list)

	_add_fight_button(
		"STANDARD TEST BATTLE",
		&"standard_test_battle",
		false
	)

	_add_fight_button(
		"DIRECTIONAL PARRY TEST",
		&"directional_parry_test",
		true
	)

	_add_fight_button(
		"MULTI-ENEMY TEST",
		&"multi_enemy_test",
		true
	)

	_add_fight_button(
		"SPELL FUSION TEST",
		&"spell_fusion_test",
		true
	)

	return panel


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	settings_container = VBoxContainer.new()
	settings_container.add_theme_constant_override("separation", 12)
	margin.add_child(settings_container)

	return panel


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var quit_button := Button.new()
	quit_button.text = "QUIT"
	quit_button.custom_minimum_size = Vector2(150, 48)
	quit_button.pressed.connect(_on_quit_pressed)
	footer.add_child(quit_button)

	launch_button = Button.new()
	launch_button.text = "LAUNCH TEST"
	launch_button.custom_minimum_size = Vector2(220, 48)
	launch_button.pressed.connect(_on_launch_pressed)
	footer.add_child(launch_button)

	return footer


func _add_fight_button(
	text: String,
	fight_id: StringName,
	disabled: bool
) -> void:
	var button := Button.new()
	button.text = (
		text + "  [COMING SOON]"
		if disabled
		else text
	)
	button.custom_minimum_size = Vector2(0, 58)
	button.disabled = disabled
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_select_fight.bind(fight_id))
	fight_list.add_child(button)


func _select_fight(fight_id: StringName) -> void:
	selected_fight = fight_id

	for child in settings_container.get_children():
		child.queue_free()

	match selected_fight:
		&"standard_test_battle":
			_build_standard_test_settings()

		_:
			_build_unavailable_settings()


func _build_standard_test_settings() -> void:
	var heading := Label.new()
	heading.text = "STANDARD TEST BATTLE"
	heading.add_theme_font_size_override("font_size", 24)
	settings_container.add_child(heading)

	var description := Label.new()
	description.text = (
		"Launches the existing TestBattle unchanged.\n"
		+ "It continues to use the shared RuneMaster battle system."
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override(
		"font_color",
		Color(0.68, 0.70, 0.76)
	)
	settings_container.add_child(description)

	var separator := HSeparator.new()
	settings_container.add_child(separator)

	_add_information_row(
		"Battle system",
		"Shared Battle"
	)

	_add_information_row(
		"Configuration",
		"Current TestBattle defaults"
	)

	_add_information_row(
		"Status",
		"Available"
	)

	var notice := Label.new()
	notice.text = (
		"Additional settings will be attached here through "
		+ "BattleSetup configurations. No separate battle "
		+ "system will be created."
	)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override(
		"font_color",
		Color(0.82, 0.72, 1.0)
	)
	settings_container.add_child(notice)

	launch_button.disabled = false


func _build_unavailable_settings() -> void:
	var label := Label.new()
	label.text = "This debug fight is not configured yet."
	settings_container.add_child(label)
	launch_button.disabled = true


func _add_information_row(
	key_text: String,
	value_text: String
) -> void:
	var row := HBoxContainer.new()

	var key_label := Label.new()
	key_label.text = key_text
	key_label.custom_minimum_size.x = 180
	key_label.add_theme_color_override(
		"font_color",
		Color(0.58, 0.60, 0.68)
	)
	row.add_child(key_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)

	settings_container.add_child(row)


func _on_launch_pressed() -> void:
	match selected_fight:
		&"standard_test_battle":
			get_tree().change_scene_to_packed(
				STANDARD_TEST_BATTLE
			)


func _on_quit_pressed() -> void:
	get_tree().quit()
