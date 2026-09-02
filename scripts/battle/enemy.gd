class_name BattleEnemy
extends Node

signal hp_changed(enemy: BattleEnemy, current_hp: int, max_hp: int)
signal died(enemy: BattleEnemy)

signal attack_started(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
)

signal attack_progressed(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
)

signal attack_cancelled(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
)

signal attack_impacted(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
)

signal parried(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
)

var data: EnemyData

var hp: int = 1
var alive: bool = true

var battle_manager: BattleManager
var scheduler: AttackScheduler
var player: PlayerCombat

var rng: RandomNumberGenerator

var next_attack_remaining: float = 0.0

var active_attack: EnemyAttackEvent = null

var stun_remaining: float = 0.0
var paralysis_remaining: float = 0.0
var debug_ai_frozen: bool = false
var status_controller: StatusEffectController
# Snapshot modifier supplied when an attack is created.
# Mist will later feed +0.3 here.
var parry_window_bonus: float = 0.0


func setup(
	p_data: EnemyData,
	p_battle_manager: BattleManager,
	p_scheduler: AttackScheduler,
	p_player: PlayerCombat,
	p_rng: RandomNumberGenerator
) -> void:
	data = p_data
	battle_manager = p_battle_manager
	scheduler = p_scheduler
	player = p_player
	rng = p_rng

	hp = data.max_hp
	alive = true

	active_attack = null
	stun_remaining = 0.0
	paralysis_remaining = 0.0

	status_controller = StatusEffectController.new()
	status_controller.name = "StatusEffects"
	add_child(status_controller)

	roll_next_attack()


func _process(delta: float) -> void:
	if not alive:
		return
	if debug_ai_frozen and active_attack == null:
		return

	if battle_manager == null:
		return

	if (
		battle_manager.state == BattleManager.BattleState.VICTORY
		or battle_manager.state == BattleManager.BattleState.DEFEAT
	):
		return

	if stun_remaining > 0.0:
		stun_remaining = maxf(0.0, stun_remaining - delta)
		return

	if active_attack != null:
		update_active_attack(delta)
		return

	# STARTING freezes enemy attack timers.
	if not battle_manager.enemy_timers_allowed():
		return

	if paralysis_remaining > 0.0:
		paralysis_remaining = maxf(
			0.0,
			paralysis_remaining - delta
		)
		return

	next_attack_remaining -= delta

	if next_attack_remaining <= 0.0:
		try_start_attack()


func try_start_attack() -> void:
	if data == null or data.attacks.is_empty():
		roll_next_attack()
		return

	var attack: AttackData = data.attacks[
		rng.randi_range(0, data.attacks.size() - 1)
	]

	if not scheduler.can_start_attack(
		attack,
		battle_manager.battle_time,
		data
	):
		# Preserve attack readiness instead of rerolling.
		next_attack_remaining = 0.05
		return

	var direction := attack.resolve_direction(rng)

	active_attack = EnemyAttackEvent.new(
		self,
		attack,
		direction,
		attack.damage
	)
	parry_window_bonus = 0.0

	var spell_executor := get_tree().get_first_node_in_group(
		"spell_executor"
	)

	if spell_executor != null:
		parry_window_bonus = (
			spell_executor.get_mist_parry_bonus()
		)

	scheduler.notify_attack_started(
		attack,
		battle_manager.battle_time
	)

	attack_started.emit(self, active_attack)


func update_active_attack(delta: float) -> void:
	if active_attack == null:
		return

	var attack: AttackData = active_attack.attack_data

	active_attack.elapsed += delta

	if attack.telegraph_duration > 0.0:
		active_attack.telegraph_progress = clampf(
			active_attack.elapsed / attack.telegraph_duration,
			0.0,
			1.0
		)
	else:
		active_attack.telegraph_progress = 1.0

	var window_start := attack.parry_window_start

	# Snapshot-style extension.
	var window_end := (
		attack.parry_window_end
		+ parry_window_bonus
	)

	active_attack.parry_window_active = (
		active_attack.elapsed >= window_start
		and active_attack.elapsed <= window_end
	)

	attack_progressed.emit(self, active_attack)

	# Matching stance at ANY point inside the valid window
	# cancels immediately.
	if (
		active_attack.parry_window_active
		and player != null
		and player.matches_parry(
			active_attack.resolved_direction
		)
	):
		resolve_parry()
		return

	if active_attack.elapsed >= attack.telegraph_duration:
		resolve_impact()


func resolve_parry() -> void:
	if active_attack == null:
		return

	var event := active_attack

	event.resolved = true
	event.parry_window_active = false

	player.clear_parry()

	active_attack = null

	# Stun does not stack/extend while already stunned.
	if stun_remaining <= 0.0:
		stun_remaining = data.parry_stun_duration

	parried.emit(self, event)
	attack_cancelled.emit(self, event)

	roll_next_attack()


func resolve_impact() -> void:
	if active_attack == null:
		return

	var event := active_attack

	event.resolved = true
	event.parry_window_active = false

	active_attack = null

	if player != null:
		player.receive_enemy_hit(event.damage)

	attack_impacted.emit(self, event)

	roll_next_attack()


func cancel_active_attack() -> void:
	if active_attack == null:
		return

	var event := active_attack

	event.resolved = true
	event.parry_window_active = false

	active_attack = null

	attack_cancelled.emit(self, event)


func roll_next_attack() -> void:
	if data == null:
		next_attack_remaining = 9999.0
		return

	next_attack_remaining = rng.randf_range(
		data.attack_interval_min,
		data.attack_interval_max
	)


func apply_paralysis(duration: float) -> bool:
	if paralysis_remaining > 0.0:
		return false

	paralysis_remaining = duration
	status_controller.add_effect(
		&"paralysis",
		duration,
		StatusEffectController.StackRule.IGNORE
	)
	return true


func apply_damage(amount: int) -> int:
	if not alive:
		return 0

	var applied := maxi(0, amount)

	hp = maxi(0, hp - applied)

	hp_changed.emit(self, hp, data.max_hp)

	if hp <= 0:
		die()

	return applied


func get_resistance(attribute_id: StringName) -> float:
	if data == null:
		return 1.0

	return data.get_resistance(attribute_id)


func die() -> void:
	if not alive:
		return

	alive = false
	status_controller.clear_all()

	cancel_active_attack()

	died.emit(self)

	if battle_manager != null:
		battle_manager.unregister_enemy(self)


func is_alive() -> bool:
	return alive

func debug_force_attack(
	attack: AttackData,
	direction: EnemyAttackEvent.ParryDirection
) -> bool:
	if not alive:
		return false

	if attack == null:
		return false

	if active_attack != null:
		cancel_active_attack()

	active_attack = EnemyAttackEvent.new(
		self,
		attack,
		direction,
		attack.damage
	)

	# Mist bonus is snapshotted at attack creation.
	parry_window_bonus = 0.0

	var spell_executor := (
		get_tree().get_first_node_in_group(
			"spell_executor"
		)
	)

	if spell_executor != null:
		parry_window_bonus = (
			spell_executor.get_mist_parry_bonus()
		)

	attack_started.emit(
		self,
		active_attack
	)

	return true


func debug_force_direction_attack(
	direction: EnemyAttackEvent.ParryDirection
) -> bool:
	if data == null:
		return false

	var attack := AttackData.new()

	attack.id = &"debug_forced_attack"
	attack.display_name = "Debug Forced Attack"
	attack.damage = 20

	attack.direction_mode = (
		AttackData.DirectionMode.FIXED
	)

	attack.fixed_direction = direction

	# Long enough to make manual parry testing easy.
	attack.telegraph_duration = 2.0
	attack.parry_window_start = 0.75
	attack.parry_window_end = 1.75

	attack.bypass_spacing = true

	return debug_force_attack(
		attack,
		direction
	)
