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
	"rune_slot_5": KEY_F
}

var resistance_knowledge: Dictionary = {}
