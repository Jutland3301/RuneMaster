class_name SpellData
extends Resource

enum TargetMode {
	SINGLE_ENEMY,
	ALL_ENEMIES,
	RANDOM_MULTI,
	SELF,
	BATTLE_WIDE,
	NONE
}

@export var id: StringName
@export var display_name: String = ""
@export var required_runes: Array[StringName] = []

@export var base_damage: float = 0.0
@export var attribute_id: StringName

@export var activation_time: float = 0.3
@export var target_mode: TargetMode = TargetMode.SINGLE_ENEMY

@export var effect_script: Script
@export var effect_color: Color = Color.WHITE
