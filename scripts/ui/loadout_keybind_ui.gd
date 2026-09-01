class_name LoadoutKeybindUI
extends Control

signal closed

var persistent_data: PlayerPersistentData
var keybind_manager: KeybindManager

var panel: Panel
var title_label: Label
var rows: VBoxContainer

var message_label: Label
var reset_button: Button
var close_button: Button

var waiting_action: StringName = &""
var buttons: Dictionary = {}


func setup(
	p_data: PlayerPersistentData,
	p_manager: KeybindManager
) -> void:
	persistent_data = p_data
	keybind_manager = p_manager

	_build()
	_refresh()

	keybind_manager.binding_changed.connect(
		_on_binding_changed
	)

	keybind_manager.binding_rejected.connect(
		_on_binding_rejected
	)


func _build() -> void:
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	backdrop.color = Color(
		0.0,
		0.0,
		0.0,
		0.75
	)
	add_child(backdrop)

	panel = Panel.new()
	panel.anchor_left = 0.25
	panel.anchor_top = 0.08
	panel.anchor_right = 0.75
	panel.anchor_bottom = 0.92
	add_child(panel)

	title_label = Label.new()
	title_label.anchor_left = 0.05
	title_label.anchor_top = 0.03
	title_label.anchor_right = 0.95
	title_label.anchor_bottom = 0.09
	title_label.text = "RUNE LOADOUT / KEYBINDS"
	title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	panel.add_child(title_label)

	rows = VBoxContainer.new()
	rows.anchor_left = 0.08
	rows.anchor_top = 0.13
	rows.anchor_right = 0.92
	rows.anchor_bottom = 0.70
	rows.add_theme_constant_override(
		"separation",
		8
	)
	panel.add_child(rows)

	for i in range(8):
		_create_slot_row(i)

	message_label = Label.new()
	message_label.anchor_left = 0.08
	message_label.anchor_top = 0.73
	message_label.anchor_right = 0.92
	message_label.anchor_bottom = 0.80
	message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	panel.add_child(message_label)

	reset_button = Button.new()
	reset_button.anchor_left = 0.15
	reset_button.anchor_top = 0.84
	reset_button.anchor_right = 0.45
	reset_button.anchor_bottom = 0.91
	reset_button.text = "Reset Defaults"
	reset_button.pressed.connect(
		_on_reset_pressed
	)
	panel.add_child(reset_button)

	close_button = Button.new()
	close_button.anchor_left = 0.55
	close_button.anchor_top = 0.84
	close_button.anchor_right = 0.85
	close_button.anchor_bottom = 0.91
	close_button.text = "Close"
	close_button.pressed.connect(
		_on_close_pressed
	)
	panel.add_child(close_button)


func _create_slot_row(
	index: int
) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 46
	rows.add_child(row)

	var slot_label := Label.new()
	slot_label.custom_minimum_size.x = 110

	if index == 0:
		slot_label.text = (
			"Slot 1  [LOCK]"
		)
	else:
		slot_label.text = (
			"Slot %d" % (index + 1)
		)

	row.add_child(slot_label)

	var rune_label := Label.new()
	rune_label.custom_minimum_size.x = 220

	var rune_id: StringName = &""

	if index < persistent_data.loadout.size():
		rune_id = (
			persistent_data.loadout[index]
		)

	if rune_id == &"":
		rune_label.text = "Empty"
	else:
		rune_label.text = String(rune_id)

	row.add_child(rune_label)

	var action := KeybindManager.SLOT_ACTIONS[
		index
	]

	var button := Button.new()
	button.custom_minimum_size.x = 160
	button.text = "Bind"

	button.pressed.connect(
		_on_bind_pressed.bind(
			action
		)
	)

	row.add_child(button)

	buttons[action] = button


func _refresh() -> void:
	for action in buttons:
		var button: Button = buttons[action]

		var keycode := (
			keybind_manager.get_action_key(
				action
			)
		)

		if keycode == KEY_NONE:
			button.text = "Unbound"
		else:
			button.text = OS.get_keycode_string(
				keycode
			)


func _on_bind_pressed(
	action: StringName
) -> void:
	waiting_action = action

	message_label.text = (
		"Press a new key for "
		+ String(action)
	)


func _unhandled_key_input(
	event: InputEvent
) -> void:
	if waiting_action == &"":
		return

	if not event is InputEventKey:
		return

	var key_event := (
		event as InputEventKey
	)

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	var keycode: Key = (
		key_event.physical_keycode
	)

	if keycode == KEY_NONE:
		keycode = key_event.keycode

	var action := waiting_action
	waiting_action = &""

	if keybind_manager.try_rebind(
		action,
		keycode
	):
		message_label.text = "Binding saved."

		persistent_data.keybinds = (
			keybind_manager.export_bindings()
		)

		SaveSystem.save_player(
			persistent_data
		)


func _on_binding_changed(
	_action: StringName,
	_keycode: Key
) -> void:
	_refresh()


func _on_binding_rejected(
	_action: StringName,
	reason: String
) -> void:
	message_label.text = reason


func _on_reset_pressed() -> void:
	keybind_manager.reset_defaults()

	persistent_data.keybinds = (
		keybind_manager.export_bindings()
	)

	SaveSystem.save_player(
		persistent_data
	)

	message_label.text = (
		"Default bindings restored."
	)


func _on_close_pressed() -> void:
	waiting_action = &""
	visible = false
	closed.emit()
