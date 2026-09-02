class_name KeybindManager
extends RefCounted

signal binding_changed(
	action: StringName,
	keycode: Key
)

signal binding_rejected(
	action: StringName,
	reason: String
)

const SLOT_ACTIONS: Array[StringName] = [
	&"rune_slot_1",
	&"rune_slot_2",
	&"rune_slot_3",
	&"rune_slot_4",
	&"rune_slot_5",
	&"rune_slot_6",
	&"rune_slot_7",
	&"rune_slot_8"
]

const DEFAULT_KEYS: Array[Key] = [
	KEY_Q,
	KEY_A,
	KEY_S,
	KEY_D,
	KEY_F,
	KEY_Z,
	KEY_C,
	KEY_V
]

const RESERVED_KEYS: Array[Key] = [
	KEY_ENTER,
	KEY_KP_ENTER,
	KEY_X,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_UP,
	KEY_DOWN,
	KEY_ESCAPE,
	KEY_TAB,
	KEY_F3
]


func ensure_actions_exist() -> void:
	for action in SLOT_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func apply_saved_bindings(
	keybinds: Dictionary
) -> void:
	ensure_actions_exist()

	for i in range(SLOT_ACTIONS.size()):
		var action := SLOT_ACTIONS[i]
		var keycode: Key = DEFAULT_KEYS[i]

		var key_name := String(action)

		if keybinds.has(key_name):
			keycode = int(
				keybinds[key_name]
			) as Key

		_apply_binding_direct(
			action,
			keycode
		)


func try_rebind(
	action: StringName,
	keycode: Key
) -> bool:
	if not SLOT_ACTIONS.has(action):
		binding_rejected.emit(
			action,
			"Unknown rune slot."
		)
		return false

	if RESERVED_KEYS.has(keycode):
		binding_rejected.emit(
			action,
			"Reserved battle key."
		)
		return false

	for other_action in SLOT_ACTIONS:
		if other_action == action:
			continue

		if _action_uses_key(
			other_action,
			keycode
		):
			binding_rejected.emit(
				action,
				"Key already used by another rune slot."
			)
			return false

	_apply_binding_direct(
		action,
		keycode
	)

	binding_changed.emit(
		action,
		keycode
	)

	return true


func reset_defaults() -> void:
	ensure_actions_exist()

	for i in range(SLOT_ACTIONS.size()):
		_apply_binding_direct(
			SLOT_ACTIONS[i],
			DEFAULT_KEYS[i]
		)

		binding_changed.emit(
			SLOT_ACTIONS[i],
			DEFAULT_KEYS[i]
		)


func export_bindings() -> Dictionary:
	var result: Dictionary = {}

	for action in SLOT_ACTIONS:
		var keycode := get_action_key(
			action
		)

		result[String(action)] = int(
			keycode
		)

	return result


func get_action_key(
	action: StringName
) -> Key:
	if not InputMap.has_action(action):
		return KEY_NONE

	for event in InputMap.action_get_events(
		action
	):
		if event is InputEventKey:
			var key_event := (
				event as InputEventKey
			)

			if (
				key_event.physical_keycode
				!= KEY_NONE
			):
				return key_event.physical_keycode

			return key_event.keycode

	return KEY_NONE


func _apply_binding_direct(
	action: StringName,
	keycode: Key
) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	InputMap.action_erase_events(
		action
	)

	var event := InputEventKey.new()

	event.physical_keycode = keycode

	InputMap.action_add_event(
		action,
		event
	)


func _action_uses_key(
	action: StringName,
	keycode: Key
) -> bool:
	return (
		get_action_key(action)
		== keycode
	)
