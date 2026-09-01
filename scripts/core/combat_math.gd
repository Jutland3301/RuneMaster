class_name CombatMath
extends RefCounted

static func calculate_magic_damage(
	base_damage: float,
	magic_power: float,
	perfect_count: int,
	resistance_multiplier: float = 1.0
) -> int:
	var damage := base_damage

	damage *= 1.0 + magic_power / 100.0
	damage *= pow(1.5, perfect_count)
	damage *= resistance_multiplier

	return int(floor(damage))


static func calculate_direct_incoming_damage(
	base_damage: float,
	guard_multiplier: float = 1.0
) -> int:
	return int(floor(base_damage * guard_multiplier))
