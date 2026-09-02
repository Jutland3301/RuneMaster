class_name PlayerPersistentData
extends RefCounted

var max_hp: int = 100
var current_hp: int = 100
var magic_power: float = 10.0

var max_combo: int = 2

var owned_runes: Array[StringName] = [
	&"algiz",
	&"fire",
	&"water",
	&"lightning",
	&"grass"
]

var loadout: Array[StringName] = [
	&"algiz",
	&"fire",
	&"water",
	&"lightning",
	&"grass",
	&"",
	&"",
	&""
]

var keybinds: Dictionary = {
	"rune_slot_1": KEY_Q,
	"rune_slot_2": KEY_A,
	"rune_slot_3": KEY_S,
	"rune_slot_4": KEY_D,
	"rune_slot_5": KEY_F,
	"rune_slot_6": KEY_Z,
	"rune_slot_7": KEY_C,
	"rune_slot_8": KEY_V
}

var resistance_knowledge: Dictionary = {}

# Isolated persistence extension point. It is deliberately not read by combat.
var equipment: Dictionary = {}


func validate_loadout() -> void:
	while loadout.size() < 8:
		loadout.append(&"")

	if loadout.size() > 8:
		loadout.resize(8)

	loadout[0] = &"algiz"

	for i in range(1, loadout.size()):
		if loadout[i] != &"" and not owned_runes.has(loadout[i]):
			loadout[i] = &""
