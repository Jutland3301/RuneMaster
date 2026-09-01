class_name StatusEffectController
extends Node

signal effect_added(effect_id: StringName)
signal effect_removed(effect_id: StringName)

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

	var expired: Array[StringName] = []

	for effect_id in effects:
		var entries: Array = effects[effect_id]

		for entry in entries:
			entry["remaining"] = maxf(
				0.0,
				float(entry["remaining"]) - delta
			)

		for entry in entries:
			if float(entry["remaining"]) <= 0.0:
				expired.append(effect_id)
				break

	for effect_id in expired:
		remove_effect(effect_id)


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
	return true


func remove_effect(effect_id: StringName) -> void:
	if not effects.has(effect_id):
		return

	effects.erase(effect_id)
	effect_removed.emit(effect_id)


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


func clear_all() -> void:
	var ids := effects.keys()

	for effect_id in ids:
		remove_effect(effect_id)


func set_battle_running(value: bool) -> void:
	battle_running = value
