class_name BattleResult
extends RefCounted

var victory: bool = false
var remaining_hp: int = 0

var defeated_enemy_ids: Array[StringName] = []

var battle_duration: float = 0.0

var perfect_count: int = 0
var parry_count: int = 0
var hit_count: int = 0

var spell_use_counts: Dictionary = {}
