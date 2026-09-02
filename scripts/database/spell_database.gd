class_name SpellDatabase
extends RefCounted

const SPELL_DIRECTORY := "res://data/spells"

var _spells: Dictionary = {}


func register_spell(spell: SpellData) -> void:
	if spell == null or spell.id == &"" or spell.required_runes.is_empty():
		return

	_spells[make_key(spell.required_runes)] = spell


func get_spell(rune_ids: Array[StringName]) -> SpellData:
	return _spells.get(make_key(rune_ids)) as SpellData


func has_spell(rune_ids: Array[StringName]) -> bool:
	return _spells.has(make_key(rune_ids))


func get_all_spells() -> Array[SpellData]:
	var result: Array[SpellData] = []

	for spell in _spells.values():
		result.append(spell as SpellData)

	return result


static func make_key(rune_ids: Array[StringName]) -> String:
	var normalized: Array[String] = []

	for rune_id in rune_ids:
		normalized.append(String(rune_id))

	normalized.sort()
	return "|".join(normalized)


func register_default_spells() -> void:
	_spells.clear()

	var files := DirAccess.get_files_at(SPELL_DIRECTORY)
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue

		var resource := load(SPELL_DIRECTORY.path_join(file_name))

		if resource is SpellData:
			register_spell(resource as SpellData)
		else:
			push_error("Invalid SpellData resource: %s" % file_name)

	if _spells.size() != 10:
		push_error("Expected 10 active spells, loaded %d." % _spells.size())
