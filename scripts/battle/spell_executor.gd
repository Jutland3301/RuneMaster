class_name SpellExecutor
extends Node

signal activation_started(event: PlayerAttackEvent)
signal enemy_effect_started(event: PlayerAttackEvent)
signal spell_finished(event: PlayerAttackEvent)
signal activation_lock_changed(locked: bool)

signal damage_applied(
	target,
	amount: int,
	resistance: float,
	perfect_count: int,
	attribute_id: StringName
)

signal dot_damage_applied(
	target,
	amount: int
)

signal immune(
	target,
	attribute_id: StringName
)
signal impact_pulse(target, color: Color, intensity: float, spell_id: StringName)

var player: PlayerCombat

var battle_manager: BattleManager
var battle_status: StatusEffectController
var player_status: StatusEffectController

var activation_locked: bool = false

var active_event: PlayerAttackEvent = null
var activation_remaining: float = 0.0

var effect_handlers: Dictionary = {}

var rng := RandomNumberGenerator.new()

var active_burns: Dictionary = {}
var damage_sequences: Array[Dictionary] = []


func setup(
	p_player: PlayerCombat,
	p_battle_manager: BattleManager,
	p_battle_status: StatusEffectController,
	p_player_status: StatusEffectController
) -> void:
	player = p_player
	battle_manager = p_battle_manager
	battle_status = p_battle_status
	player_status = p_player_status

	if player_status != null:
		player_status.effect_removed.connect(
			_on_player_effect_removed
		)

	add_to_group("spell_executor")

	register_effect(
		&"direct_damage",
		DirectDamageEffect.new()
	)

	register_effect(
		&"mist",
		MistEffect.new()
	)

	register_effect(
		&"plasma",
		PlasmaEffect.new()
	)

	register_effect(
		&"burning_spores",
		BurningSporesEffect.new()
	)

	register_effect(
		&"electric_whip",
		ElectricWhipEffect.new()
	)

	register_effect(
		&"algae_guard",
		AlgaeGuardEffect.new()
	)

	register_effect(
		&"paralysis",
		ParalysisEffect.new()
	)


func register_effect(
	effect_id: StringName,
	handler: SpellEffect
) -> void:
	effect_handlers[effect_id] = handler


func can_activate() -> bool:
	if activation_locked:
		return false

	if battle_manager == null:
		return false

	return (
		battle_manager.state
		== BattleManager.BattleState.STARTING
		or battle_manager.state
		== BattleManager.BattleState.ACTIVE
	)


func activate(event: PlayerAttackEvent) -> bool:
	if event == null or event.spell == null:
		return false

	if not can_activate():
		return false

	activation_locked = true
	activation_lock_changed.emit(true)
	active_event = event

	activation_remaining = maxf(
		0.0,
		event.spell.activation_time
	)

	activation_started.emit(event)

	if activation_remaining <= 0.0:
		_begin_enemy_effect()

	return true


func _process(delta: float) -> void:
	_update_burns(delta)
	_update_damage_sequences(delta)

	if not activation_locked:
		return

	if active_event == null:
		activation_locked = false
		return

	if battle_manager != null:
		if (
			battle_manager.state
			== BattleManager.BattleState.DEFEAT
			or battle_manager.state
			== BattleManager.BattleState.VICTORY
		):
			cancel_activation()
			return

	activation_remaining -= delta

	if activation_remaining <= 0.0:
		_begin_enemy_effect()


func _begin_enemy_effect() -> void:
	if active_event == null:
		activation_locked = false
		return

	var event := active_event

	# Hand-side activation ends here.
	# The next completed spell may now be fired.
	activation_locked = false
	activation_lock_changed.emit(false)
	active_event = null
	activation_remaining = 0.0

	enemy_effect_started.emit(event)

	_execute_effect(event)

	spell_finished.emit(event)


func _execute_effect(event: PlayerAttackEvent) -> void:
	var spell := event.spell

	if spell == null:
		return

	if spell.effect_script != null:
		var scripted_handler = spell.effect_script.new()

		if scripted_handler is SpellEffect:
			(scripted_handler as SpellEffect).execute(event, self)
			return

	var effect_id := spell.id

	if effect_handlers.has(effect_id):
		var handler: SpellEffect = effect_handlers[
			effect_id
		]

		handler.execute(event, self)
		return

	# Fire / Water / Lightning / Grass currently share
	# the reusable direct-damage handler.
	if effect_handlers.has(&"direct_damage"):
		var direct: SpellEffect = effect_handlers[
			&"direct_damage"
		]

		direct.execute(event, self)


func apply_direct_spell_damage(
	event: PlayerAttackEvent,
	target,
	base_damage: float,
	impact_intensity: float = 1.0
) -> int:
	if event == null or event.spell == null:
		return 0

	if not is_instance_valid(target):
		return 0

	if not target.is_alive():
		return 0

	var resistance: float = target.get_resistance(
		event.attribute_id
	)

	if resistance <= 0.0:
		impact_pulse.emit(
			target,
			event.spell.effect_color,
			1.0,
			event.spell.id
		)
		immune.emit(
			target,
			event.attribute_id
		)
		return 0
	var amount := CombatMath.calculate_magic_damage(
		base_damage,
		player.magic_power,
		event.perfect_count,
		resistance
	)

	target.apply_damage(amount)
	impact_pulse.emit(
		target,
		event.spell.effect_color,
		impact_intensity + float(event.perfect_count) * 0.18,
		event.spell.id
	)

	damage_applied.emit(
		target,
		amount,
		resistance,
		event.perfect_count,
		event.attribute_id
	)

	return amount


func start_burn(
	target,
	perfect_count: int,
	base_damage: float,
	ticks: int,
	interval: float
) -> bool:
	if not is_instance_valid(target):
		return false

	var key: float = target.get_instance_id()

	# Burning Spores:
	# re-cast does not stack or refresh existing DoT.
	if active_burns.has(key):
		return false

	var burn := BurnRuntime.new()

	burn.setup(
		target,
		perfect_count,
		base_damage,
		ticks,
		interval
	)

	active_burns[key] = burn

	if target is BattleEnemy:
		var enemy := target as BattleEnemy
		enemy.status_controller.add_effect(
			&"burn",
			float(ticks) * interval,
			StatusEffectController.StackRule.IGNORE
		)

	return true


func _update_burns(delta: float) -> void:
	if active_burns.is_empty():
		return

	if battle_manager != null:
		if (
			battle_manager.state
			== BattleManager.BattleState.VICTORY
			or battle_manager.state
			== BattleManager.BattleState.DEFEAT
		):
			active_burns.clear()
			return

	var finished_keys: Array = []

	for key in active_burns:
		var burn: BurnRuntime = active_burns[key]

		if (
			not is_instance_valid(burn.target)
			or not burn.target.is_alive()
		):
			finished_keys.append(key)
			continue

		if not burn.update(delta):
			continue

		_apply_burn_tick(burn)
		burn.consume_tick()

		if burn.finished():
			finished_keys.append(key)

	for key in finished_keys:
		active_burns.erase(key)


func _apply_burn_tick(
	burn: BurnRuntime
) -> void:
	if player == null:
		return

	if not is_instance_valid(burn.target):
		return

	if not burn.target.is_alive():
		return

	# Burn snapshots Perfect from the original cast.
	#
	# MP applies normally.
	# Enemy elemental resistance deliberately does NOT
	# apply to Burning Spores DoT ticks.
	var amount := CombatMath.calculate_magic_damage(
		burn.base_damage,
		player.magic_power,
		burn.perfect_count,
		1.0
	)

	burn.target.apply_damage(amount)

	dot_damage_applied.emit(
		burn.target,
		amount
	)
	impact_pulse.emit(
		burn.target,
		Color(0.9, 0.34, 0.1),
		0.55,
		&"burn"
	)


func queue_damage_sequence(
	event: PlayerAttackEvent,
	target,
	base_damages: Array[float],
	delays: Array[float]
) -> void:
	for i in range(base_damages.size()):
		damage_sequences.append({
			"event": event,
			"target": target,
			"base_damage": base_damages[i],
			"remaining": delays[i] if i < delays.size() else 0.0,
			"intensity": 0.75 + float(i) * 0.35
		})


func _update_damage_sequences(delta: float) -> void:
	for i in range(damage_sequences.size() - 1, -1, -1):
		var entry: Dictionary = damage_sequences[i]
		entry["remaining"] = float(entry["remaining"]) - delta

		if float(entry["remaining"]) > 0.0:
			continue

		var event := entry["event"] as PlayerAttackEvent
		var target = entry["target"]

		if is_instance_valid(target) and target.is_alive():
			apply_direct_spell_damage(
				event,
				target,
				float(entry["base_damage"]),
				float(entry["intensity"])
			)

		damage_sequences.remove_at(i)


func cancel_activation() -> void:
	var was_locked := activation_locked
	activation_locked = false
	active_event = null
	activation_remaining = 0.0

	if was_locked:
		activation_lock_changed.emit(false)


func clear_runtime_effects() -> void:
	cancel_activation()
	active_burns.clear()
	damage_sequences.clear()

	if player != null:
		player.guard_damage_multiplier = 1.0


func set_rng_seed(seed_value: int) -> void:
	rng.seed = seed_value


func _on_player_effect_removed(
	effect_id: StringName
) -> void:
	if effect_id == &"algae_guard":
		if player != null:
			player.guard_damage_multiplier = 1.0


func get_mist_parry_bonus() -> float:
	if battle_status == null:
		return 0.0

	if not battle_status.has_effect(&"mist"):
		return 0.0

	var metadata := battle_status.get_metadata(
		&"mist"
	)

	return float(
		metadata.get(
			"parry_window_bonus",
			0.0
		)
	)
