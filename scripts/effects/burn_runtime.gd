class_name BurnRuntime
extends RefCounted

var target
var perfect_count: int = 0

var base_damage: float = 20.0

var ticks_remaining: int = 5
var tick_interval: float = 1.0
var tick_remaining: float = 1.0


func setup(
	p_target,
	p_perfect_count: int,
	p_base_damage: float,
	p_ticks: int,
	p_interval: float
) -> void:
	target = p_target
	perfect_count = p_perfect_count
	base_damage = p_base_damage

	ticks_remaining = p_ticks
	tick_interval = p_interval
	tick_remaining = p_interval


func update(delta: float) -> bool:
	tick_remaining -= delta

	return tick_remaining <= 0.0


func consume_tick() -> void:
	ticks_remaining -= 1
	tick_remaining += tick_interval


func finished() -> bool:
	return ticks_remaining <= 0
