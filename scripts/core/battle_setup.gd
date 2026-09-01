class_name BattleSetup
extends RefCounted

var enemies: Array[EnemyData] = []

var background: Texture2D = null
var bgm: AudioStream = null

var origin_scene_path: String = ""
var special_metadata: Dictionary = {}


func _init(
	p_enemies: Array[EnemyData] = []
) -> void:
	enemies = p_enemies
