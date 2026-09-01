class_name CastingPattern
extends Resource

@export var id: StringName = &"pattern_1"

@export var total_duration: float = 2.0

# MISS 20 | NORMAL 27 | PERFECT 6 | NORMAL 27 | MISS 20
@export_range(0.0, 1.0) var miss_edge: float = 0.20
@export_range(0.0, 1.0) var perfect_start: float = 0.47
@export_range(0.0, 1.0) var perfect_end: float = 0.53

@export var round_trips: int = 2


func judge(position: float) -> StringName:
	position = clampf(position, 0.0, 1.0)

	if position < miss_edge:
		return &"miss"

	if position > 1.0 - miss_edge:
		return &"miss"

	if position >= perfect_start and position <= perfect_end:
		return &"perfect"

	return &"normal"
