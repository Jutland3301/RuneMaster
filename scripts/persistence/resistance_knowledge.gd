class_name ResistanceKnowledge
extends RefCounted

signal knowledge_changed(
	enemy_id: StringName,
	attribute_id: StringName
)

var knowledge: Dictionary = {}

var reveal_all: bool = false


func setup(
	p_knowledge: Dictionary
) -> void:
	knowledge = p_knowledge


func discover(
	enemy_id: StringName,
	attribute_id: StringName,
	multiplier: float
) -> void:
	var enemy_key := String(enemy_id)
	var attribute_key := String(attribute_id)

	if not knowledge.has(enemy_key):
		knowledge[enemy_key] = {}

	var enemy_knowledge: Dictionary = (
		knowledge[enemy_key]
	)

	if enemy_knowledge.has(attribute_key):
		return

	enemy_knowledge[attribute_key] = multiplier

	knowledge_changed.emit(
		enemy_id,
		attribute_id
	)


func is_known(
	enemy_id: StringName,
	attribute_id: StringName
) -> bool:
	if reveal_all:
		return true

	var enemy_key := String(enemy_id)
	var attribute_key := String(attribute_id)

	if not knowledge.has(enemy_key):
		return false

	var enemy_knowledge: Dictionary = (
		knowledge[enemy_key]
	)

	return enemy_knowledge.has(attribute_key)


func get_display(
	enemy: EnemyData,
	attribute_id: StringName
) -> String:
	if enemy == null:
		return "???"

	if not is_known(
		enemy.id,
		attribute_id
	):
		return "???"

	var value := enemy.get_resistance(attribute_id)
	return "x%s" % String.num(value, 2)
