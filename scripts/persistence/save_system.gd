class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://rune_master_save.json"


static func save_player(
	data: PlayerPersistentData
) -> bool:
	var payload := {
		"max_hp": data.max_hp,
		"current_hp": data.current_hp,
		"magic_power": data.magic_power,
		"max_combo": data.max_combo,
		"owned_runes": _string_name_array_to_strings(
			data.owned_runes
		),
		"loadout": _string_name_array_to_strings(
			data.loadout
		),
		"keybinds": data.keybinds,
		"resistance_knowledge":
			data.resistance_knowledge
	}

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("Could not open save file.")
		return false

	file.store_string(
		JSON.stringify(
			payload,
			"\t"
		)
	)

	file.close()

	return true


static func load_player() -> PlayerPersistentData:
	var data := PlayerPersistentData.new()

	if not FileAccess.file_exists(SAVE_PATH):
		return data

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		return data

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning(
			"Invalid save file. Defaults loaded."
		)
		return data

	var payload: Dictionary = parsed

	data.max_hp = int(
		payload.get(
			"max_hp",
			data.max_hp
		)
	)

	data.current_hp = int(
		payload.get(
			"current_hp",
			data.current_hp
		)
	)

	data.magic_power = float(
		payload.get(
			"magic_power",
			data.magic_power
		)
	)

	data.max_combo = int(
		payload.get(
			"max_combo",
			data.max_combo
		)
	)

	data.owned_runes = _to_string_name_array(
		payload.get(
			"owned_runes",
			[]
		)
	)

	data.loadout = _to_string_name_array(
		payload.get(
			"loadout",
			[]
		)
	)

	var loaded_keybinds = payload.get(
		"keybinds",
		{}
	)

	if typeof(loaded_keybinds) == TYPE_DICTIONARY:
		data.keybinds = loaded_keybinds

	var loaded_knowledge = payload.get(
		"resistance_knowledge",
		{}
	)

	if typeof(loaded_knowledge) == TYPE_DICTIONARY:
		data.resistance_knowledge = (
			loaded_knowledge
		)

	return data


static func _string_name_array_to_strings(
	values: Array[StringName]
) -> Array[String]:
	var result: Array[String] = []

	for value in values:
		result.append(String(value))

	return result


static func _to_string_name_array(
	values: Array
) -> Array[StringName]:
	var result: Array[StringName] = []

	for value in values:
		result.append(
			StringName(String(value))
		)

	return result
