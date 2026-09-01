class_name CastingGauge
extends RefCounted

var pattern: CastingPattern

var elapsed: float = 0.0
var cursor_position: float = 0.0

var active: bool = false
var finished: bool = false

var start_phase: float = 0.0


func begin(
	p_pattern: CastingPattern,
	rng: RandomNumberGenerator
) -> void:
	pattern = p_pattern

	elapsed = 0.0
	active = true
	finished = false

	# Start randomly inside a MISS region.
	if rng.randf() < 0.5:
		start_phase = rng.randf_range(
			0.0,
			pattern.miss_edge
		)
	else:
		start_phase = rng.randf_range(
			1.0 - pattern.miss_edge,
			1.0
		)

	cursor_position = start_phase


func update(delta: float) -> void:
	if not active or pattern == null:
		return

	elapsed += delta

	var duration := maxf(
		pattern.total_duration,
		0.001
	)

	if elapsed >= duration:
		elapsed = duration
		active = false
		finished = true

	var normalized_time := elapsed / duration

	# Two round trips = four one-way traversals.
	var traversals := float(pattern.round_trips * 2)

	# Starting position is represented as phase along
	# the repeating triangular wave.
	var start_wave_phase := start_phase

	var phase := (
		start_wave_phase
		+ normalized_time * traversals
	)

	cursor_position = _triangle_wave(phase)


func judge() -> StringName:
	if pattern == null:
		return &"miss"

	return pattern.judge(cursor_position)


func cancel() -> void:
	active = false
	finished = true


func _triangle_wave(value: float) -> float:
	var wrapped := fposmod(value, 2.0)

	if wrapped <= 1.0:
		return wrapped

	return 2.0 - wrapped
