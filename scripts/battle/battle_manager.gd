class_name BattleManager
extends Node

enum BattleState {
	STARTING,
	ACTIVE,
	VICTORY,
	DEFEAT
}

signal battle_state_changed(new_state: BattleState)
signal battle_finished(victory: bool)

const STARTING_DURATION := 0.5

var state: BattleState = BattleState.STARTING
var battle_time: float = 0.0
var starting_remaining: float = STARTING_DURATION

var enemies: Array = []
var player = null


func _ready() -> void:
	change_state(BattleState.STARTING)


func _process(delta: float) -> void:
	if state == BattleState.VICTORY or state == BattleState.DEFEAT:
		return

	battle_time += delta

	if state == BattleState.STARTING:
		starting_remaining -= delta

		if starting_remaining <= 0.0:
			change_state(BattleState.ACTIVE)


func change_state(new_state: BattleState) -> void:
	if state == new_state:
		return

	state = new_state
	battle_state_changed.emit(state)


func register_player(player_node) -> void:
	player = player_node


func register_enemy(enemy_node) -> void:
	if enemy_node == null:
		return

	if not enemies.has(enemy_node):
		enemies.append(enemy_node)


func unregister_enemy(enemy_node) -> void:
	enemies.erase(enemy_node)
	check_victory()


func get_living_enemies() -> Array:
	var living: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			living.append(enemy)

	return living


func check_victory() -> void:
	if state == BattleState.VICTORY or state == BattleState.DEFEAT:
		return

	if get_living_enemies().is_empty():
		change_state(BattleState.VICTORY)
		battle_finished.emit(true)


func notify_player_death() -> void:
	if state == BattleState.VICTORY or state == BattleState.DEFEAT:
		return

	change_state(BattleState.DEFEAT)
	battle_finished.emit(false)


func enemy_timers_allowed() -> bool:
	return state == BattleState.ACTIVE


func player_input_allowed() -> bool:
	return (
		state == BattleState.STARTING
		or state == BattleState.ACTIVE
	)
