class_name PlayerAttackEvent
extends RefCounted

var source
var targets: Array = []
var spell: SpellData
var perfect_count: int = 0
var attribute_id: StringName
var calculated_damage: int = 0

func _init(
	p_source = null,
	p_targets: Array = [],
	p_spell: SpellData = null,
	p_perfect_count: int = 0
) -> void:
	source = p_source
	targets = p_targets
	spell = p_spell
	perfect_count = p_perfect_count

	if spell != null:
		attribute_id = spell.attribute_id
