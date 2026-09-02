class_name BattleSetup
extends Resource

static var pending_setup: BattleSetup = null

@export_category("Battle")
@export var enemies: Array[EnemyData] = []
@export var background: Texture2D

@export_category("Navigation")
@export_file("*.tscn") var origin_scene_path: String = ""

var special_metadata: Dictionary = {}


func _init(
	p_enemies: Array[EnemyData] = []
) -> void:
	enemies = p_enemies


static func queue_for_next_battle(
	setup: BattleSetup
) -> void:
	pending_setup = setup


static func consume_queued() -> BattleSetup:
	var setup := pending_setup
	pending_setup = null
	return setup
