class_name RuneCaster
extends Node

signal casting_started(rune: RuneData)
signal casting_updated(position: float, region: StringName)

signal rune_success(
	rune: RuneData,
	judgement: StringName
)

signal cast_missed
signal combo_changed(
	runes: Array[RuneData],
	perfect_count: int
)

signal combo_cleared
signal spell_ready(spell: SpellData)

var spell_database: SpellDatabase

var rng := RandomNumberGenerator.new()

var max_combo: int = 2

var combo: Array[RuneData] = []
var perfect_count: int = 0

var current_rune: RuneData = null
var gauge: CastingGauge = null

var recovery_remaining: float = 0.0


func setup(
	p_spell_database: SpellDatabase,
	p_max_combo: int,
	p_seed: int
) -> void:
	spell_database = p_spell_database
	max_combo = maxi(1, p_max_combo)

	rng.seed = p_seed


func _process(delta: float) -> void:
	if recovery_remaining > 0.0:
		recovery_remaining = maxf(
			0.0,
			recovery_remaining - delta
		)

	if gauge == null:
		return

	if not gauge.active:
		return

	gauge.update(delta)

	casting_updated.emit(
		gauge.cursor_position,
		gauge.judge()
	)

	if gauge.finished:
		_handle_miss()


func is_casting() -> bool:
	return (
		gauge != null
		and gauge.active
	)


func has_combo() -> bool:
	return not combo.is_empty()


func can_begin_rune(rune: RuneData) -> bool:
	if rune == null:
		return false

	if recovery_remaining > 0.0:
		return false

	if is_casting():
		return false

	if combo.size() >= max_combo:
		return false

	if not rune.is_element:
		return false

	for existing in combo:
		if existing.id == rune.id:
			return false

	# First rune only needs to exist as a valid single spell.
	var candidate_ids: Array[StringName] = []

	for existing in combo:
		candidate_ids.append(existing.id)

	candidate_ids.append(rune.id)

	# IMPORTANT:
	# Validate combination BEFORE gauge starts.
	if spell_database == null:
		return false

	if not spell_database.has_spell(candidate_ids):
		return false

	return true


func begin_rune(rune: RuneData) -> bool:
	if not can_begin_rune(rune):
		return false

	if rune.casting_pattern == null:
		return false

	current_rune = rune

	gauge = CastingGauge.new()
	gauge.begin(
		rune.casting_pattern as CastingPattern,
		rng
	)

	casting_started.emit(rune)

	return true


func judge_current_cast() -> StringName:
	if not is_casting():
		return &"none"

	var result := gauge.judge()

	if result == &"miss":
		_handle_miss()
		return result

	var accepted_rune := current_rune

	gauge.cancel()
	gauge = null
	current_rune = null

	combo.append(accepted_rune)

	if result == &"perfect":
		perfect_count += 1

	rune_success.emit(
		accepted_rune,
		result
	)

	combo_changed.emit(
		combo.duplicate(),
		perfect_count
	)

	var spell := get_current_spell()

	if spell != null:
		spell_ready.emit(spell)

	return result


func get_current_spell() -> SpellData:
	if combo.is_empty():
		return null

	var ids: Array[StringName] = []

	for rune in combo:
		ids.append(rune.id)

	return spell_database.get_spell(ids)


func consume_combo() -> Dictionary:
	var result := {
		"spell": get_current_spell(),
		"perfect_count": perfect_count,
		"runes": combo.duplicate()
	}

	clear_combo()

	return result


func clear_combo() -> void:
	if gauge != null:
		gauge.cancel()

	gauge = null
	current_rune = null

	combo.clear()
	perfect_count = 0

	combo_cleared.emit()
	combo_changed.emit(
		combo.duplicate(),
		perfect_count
	)


func _handle_miss() -> void:
	if gauge != null:
		gauge.cancel()

	gauge = null
	current_rune = null

	# MISS destroys attempted rune AND entire old combo.
	combo.clear()
	perfect_count = 0

	recovery_remaining = 0.1

	cast_missed.emit()
	combo_cleared.emit()

	combo_changed.emit(
		combo.duplicate(),
		perfect_count
	)
