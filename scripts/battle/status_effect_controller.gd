class_name StatusEffectController
extends Node

signal effect_added(effect_id: StringName)
signal effect_removed(effect_id: StringName)
signal effects_changed

enum StackRule {
	IGNORE,
	REFRESH,
	STACK
}

var effects: Dictionary = {}
var battle_running: bool = true


func _process(delta: float) -> void:
	if not battle_running:
		return

	var emptied: Array[StringName] = []

	for effect_id in effects.keys():
		var entries: Array = effects[effect_id]

		for i in range(entries.size() - 1, -1, -1):
			var entry: Dictionary = entries[i]
			entry["remaining"] = maxf(
				0.0,
				float(entry["remaining"]) - delta
			)

			if float(entry["remaining"]) <= 0.0:
				entries.remove_at(i)

		if entries.is_empty():
			emptied.append(effect_id)

	for effect_id in emptied:
		effects.erase(effect_id)
		effect_removed.emit(effect_id)
		effects_changed.emit()


func add_effect(
	effect_id: StringName,
	duration: float,
	stack_rule: StackRule = StackRule.IGNORE,
	metadata: Dictionary = {}
) -> bool:
	if effects.has(effect_id):
		match stack_rule:
			StackRule.IGNORE:
				return false

			StackRule.REFRESH:
				var entries: Array = effects[effect_id]

				if not entries.is_empty():
					entries[0]["remaining"] = duration
					entries[0]["duration"] = duration
					entries[0]["metadata"] = metadata

				effects_changed.emit()
				return true

			StackRule.STACK:
				pass

	var entry := {
		"duration": duration,
		"remaining": duration,
		"metadata": metadata.duplicate(true)
	}

	if not effects.has(effect_id):
		effects[effect_id] = []

	effects[effect_id].append(entry)

	effect_added.emit(effect_id)
	effects_changed.emit()
	return true


func remove_effect(effect_id: StringName) -> void:
	if not effects.has(effect_id):
		return

	effects.erase(effect_id)
	effect_removed.emit(effect_id)
	effects_changed.emit()


func has_effect(effect_id: StringName) -> bool:
	return effects.has(effect_id)


func get_remaining(effect_id: StringName) -> float:
	if not effects.has(effect_id):
		return 0.0

	var entries: Array = effects[effect_id]

	if entries.is_empty():
		return 0.0

	return float(entries[0]["remaining"])


func get_metadata(effect_id: StringName) -> Dictionary:
	if not effects.has(effect_id):
		return {}

	var entries: Array = effects[effect_id]

	if entries.is_empty():
		return {}

	return entries[0]["metadata"]


func get_debug_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for effect_id in effects:
		for entry in effects[effect_id]:
			result.append({
				"id": effect_id,
				"remaining": float(entry["remaining"]),
				"duration": float(entry["duration"])
			})

	return result


func clear_all() -> void:
	var ids := effects.keys()

	for effect_id in ids:
		remove_effect(effect_id)


func set_battle_running(value: bool) -> void:
	battle_running = value
