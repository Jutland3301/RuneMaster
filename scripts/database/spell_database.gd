class_name SpellDatabase
extends RefCounted

var _spells: Dictionary = {}


func register_spell(spell: SpellData) -> void:
	if spell == null:
		return

	var key := make_key(spell.required_runes)
	_spells[key] = spell


func get_spell(rune_ids: Array[StringName]) -> SpellData:
	var key := make_key(rune_ids)

	if _spells.has(key):
		return _spells[key]

	return null


func has_spell(rune_ids: Array[StringName]) -> bool:
	return _spells.has(make_key(rune_ids))


static func make_key(rune_ids: Array[StringName]) -> String:
	var normalized: Array[String] = []

	for rune_id in rune_ids:
		normalized.append(String(rune_id))

	normalized.sort()

	return "|".join(normalized)
func register_default_spells() -> void:
	_spells.clear()

	register_spell(
		_make_spell(
			&"fire",
			"Fire",
			[&"fire"],
			100.0,
			&"fire",
			0.35,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"water",
			"Water",
			[&"water"],
			70.0,
			&"water",
			0.25,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"lightning",
			"Lightning",
			[&"lightning"],
			40.0,
			&"lightning",
			0.08,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"grass",
			"Grass",
			[&"grass"],
			50.0,
			&"grass",
			0.35,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"mist",
			"Mist",
			[&"fire", &"water"],
			0.0,
			&"mist",
			0.35,
			SpellData.TargetMode.BATTLE_WIDE
		)
	)

	register_spell(
		_make_spell(
			&"plasma",
			"Plasma",
			[&"fire", &"lightning"],
			200.0,
			&"plasma",
			0.35,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"burning_spores",
			"Burning Spores",
			[&"fire", &"grass"],
			130.0,
			&"burning_spores",
			0.35,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)

	register_spell(
		_make_spell(
			&"electric_whip",
			"Electric Whip",
			[&"water", &"lightning"],
			100.0,
			&"electric_whip",
			0.08,
			SpellData.TargetMode.RANDOM_MULTI
		)
	)

	register_spell(
		_make_spell(
			&"algae_guard",
			"Algae Guard",
			[&"water", &"grass"],
			0.0,
			&"algae_guard",
			0.30,
			SpellData.TargetMode.SELF
		)
	)

	register_spell(
		_make_spell(
			&"paralysis",
			"Paralysis",
			[&"lightning", &"grass"],
			70.0,
			&"paralysis",
			0.30,
			SpellData.TargetMode.SINGLE_ENEMY
		)
	)


func _make_spell(
	p_id: StringName,
	p_display_name: String,
	p_runes: Array[StringName],
	p_base_damage: float,
	p_attribute: StringName,
	p_activation_time: float,
	p_target_mode: SpellData.TargetMode
) -> SpellData:
	var spell := SpellData.new()

	spell.id = p_id
	spell.display_name = p_display_name
	spell.required_runes = p_runes
	spell.base_damage = p_base_damage
	spell.attribute_id = p_attribute
	spell.activation_time = p_activation_time
	spell.target_mode = p_target_mode

	return spell
