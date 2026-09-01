class_name PlayerCombat
extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal damaged(amount: int)
signal died
signal parry_changed(direction: int)
signal parry_cleared

enum PlayerState {
	IDLE,
	CASTING,
	HITSTUN,
	DEAD
}

var max_hp: int = 100
var hp: int = 100
var magic_power: float = 10.0

var state: PlayerState = PlayerState.IDLE

var invulnerability_remaining: float = 0.0
var hitstun_remaining: float = 0.0

var god_mode: bool = false

var parry_active: bool = false
var parry_direction: EnemyAttackEvent.ParryDirection = EnemyAttackEvent.ParryDirection.FRONT

var guard_damage_multiplier: float = 1.0


func _process(delta: float) -> void:
	if state == PlayerState.DEAD:
		return

	if invulnerability_remaining > 0.0:
		invulnerability_remaining = maxf(
			0.0,
			invulnerability_remaining - delta
		)

	if hitstun_remaining > 0.0:
		hitstun_remaining = maxf(
			0.0,
			hitstun_remaining - delta
		)

		if hitstun_remaining <= 0.0:
			state = PlayerState.IDLE


func reset_for_battle(
	starting_hp: int = 100,
	p_max_hp: int = 100,
	p_magic_power: float = 10.0
) -> void:
	max_hp = maxi(1, p_max_hp)
	hp = clampi(starting_hp, 0, max_hp)
	magic_power = p_magic_power

	state = PlayerState.IDLE
	invulnerability_remaining = 0.0
	hitstun_remaining = 0.0

	clear_parry()

	hp_changed.emit(hp, max_hp)


func can_accept_normal_input() -> bool:
	return (
		state != PlayerState.HITSTUN
		and state != PlayerState.DEAD
	)


func enter_parry(
	direction: EnemyAttackEvent.ParryDirection
) -> bool:
	if not can_accept_normal_input():
		return false

	parry_active = true
	parry_direction = direction

	parry_changed.emit(parry_direction)
	return true


func clear_parry() -> void:
	if not parry_active:
		return

	parry_active = false
	parry_direction = EnemyAttackEvent.ParryDirection.FRONT

	parry_cleared.emit()


func matches_parry(
	direction: EnemyAttackEvent.ParryDirection
) -> bool:
	return (
		parry_active
		and parry_direction == direction
	)


func receive_enemy_hit(raw_damage: int) -> int:
	if state == PlayerState.DEAD:
		return 0

	# Any wrong/ordinary hit cancels the stance,
	# including a hit occurring during i-frames.
	clear_parry()

	# Crucial rule:
	# i-frame hits deal zero damage and DO NOT restart i-frames.
	if invulnerability_remaining > 0.0:
		return 0

	if god_mode:
		return 0

	var final_damage := CombatMath.calculate_direct_incoming_damage(
		float(raw_damage),
		guard_damage_multiplier
	)

	hp = maxi(0, hp - final_damage)

	# Original damaging hit establishes both timers.
	hitstun_remaining = 0.2
	invulnerability_remaining = 0.6
	state = PlayerState.HITSTUN

	damaged.emit(final_damage)
	hp_changed.emit(hp, max_hp)

	if hp <= 0:
		state = PlayerState.DEAD
		clear_parry()
		died.emit()

	return final_damage


func heal_full() -> void:
	if state == PlayerState.DEAD:
		state = PlayerState.IDLE

	hp = max_hp
	hitstun_remaining = 0.0
	invulnerability_remaining = 0.0

	hp_changed.emit(hp, max_hp)
