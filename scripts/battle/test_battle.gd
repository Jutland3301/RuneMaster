class_name TestBattle
extends Node

static var queued_rng_seed: int = 0
static var has_queued_rng_seed: bool = false

var battle_manager: BattleManager
var scheduler: AttackScheduler
var player: PlayerCombat

var rune_caster: RuneCaster
var player_input: BattlePlayerInput
var spell_executor: SpellExecutor

var battle_status: StatusEffectController
var player_status: StatusEffectController

var spell_database: SpellDatabase

var rng := RandomNumberGenerator.new()

var runes: Dictionary = {}
var enemies: Array[BattleEnemy] = []

var selected_target_index: int = 0

var rng_seed: int = 3301

var battle_ui: BattleUI
var persistent_data: PlayerPersistentData
var resistance_knowledge: ResistanceKnowledge
var keybind_manager: KeybindManager
var loadout_ui: LoadoutKeybindUI
var debug_overlay: DebugOverlay
var battle_result: BattleResult
@export var battle_setup: BattleSetup
@onready var battle_audio: BattleAudio = get_node(
	"BattleAudio"
) as BattleAudio

var total_perfects: int = 0
var parry_count: int = 0
var player_hit_count: int = 0

var spell_use_counts: Dictionary = {}
var defeated_enemy_ids: Array[StringName] = []



func _ready() -> void:
	if has_queued_rng_seed:
		rng_seed = queued_rng_seed

	battle_result = BattleResult.new()
	var queued_setup := BattleSetup.consume_queued()

	if queued_setup != null:
		battle_setup = queued_setup

	if battle_setup == null:
		push_error(
			"TestBattle: BattleSetup is not assigned."
		)
		return

	persistent_data = SaveSystem.load_player()
	persistent_data.validate_loadout()

	resistance_knowledge = ResistanceKnowledge.new()
	resistance_knowledge.setup(
		persistent_data.resistance_knowledge
	)
	keybind_manager = KeybindManager.new()

	keybind_manager.apply_saved_bindings(
		persistent_data.keybinds
	)
	rng.seed = rng_seed

	_create_runtime_nodes()
	_create_spell_database()
	_create_runes()
	_create_test_enemies()
	_connect_runtime()

	_select_initial_target()
	_create_battle_ui()

	print("===================================")
	print("RUNE MASTER TEST BATTLE")
	print("===================================")
	print("Enemies: ", enemies.size())
	print("Selected target: ", _target_name())
	print("Seed: ", rng_seed)
	print("Enter = Judge / Fire; X = Cancel; arrows = Target / Parry")
	print("Tab = Loadout / Keybinds; F3 = Debug")
	print("===================================")


func set_debug_seed(value: int) -> void:
	rng_seed = value
	queued_rng_seed = value
	has_queued_rng_seed = true
	rng.seed = value
	rune_caster.rng.seed = value
	spell_executor.set_rng_seed(value + 7301)


func _create_runtime_nodes() -> void:
	battle_manager = BattleManager.new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)

	scheduler = AttackScheduler.new()
	scheduler.name = "AttackScheduler"
	add_child(scheduler)

	player = PlayerCombat.new()
	player.name = "PlayerCombat"
	add_child(player)

	rune_caster = RuneCaster.new()
	rune_caster.name = "RuneCaster"
	add_child(rune_caster)

	player_input = BattlePlayerInput.new()
	player_input.name = "BattlePlayerInput"
	add_child(player_input)

	spell_executor = SpellExecutor.new()
	spell_executor.name = "SpellExecutor"
	add_child(spell_executor)

	battle_status = StatusEffectController.new()
	battle_status.name = "BattleStatus"
	add_child(battle_status)

	player_status = StatusEffectController.new()
	player_status.name = "PlayerStatus"
	add_child(player_status)

	battle_manager.register_player(player)

	player.reset_for_battle(
		persistent_data.current_hp,
		persistent_data.max_hp,
		persistent_data.magic_power
	)


func _create_spell_database() -> void:
	spell_database = SpellDatabase.new()
	spell_database.register_default_spells()

	rune_caster.setup(
		spell_database,
		persistent_data.max_combo,
		rng_seed
	)

	player_input.setup(
		player,
		rune_caster
	)

	spell_executor.setup(
		player,
		battle_manager,
		battle_status,
		player_status
	)
	spell_executor.set_rng_seed(rng_seed + 7301)


func _create_runes() -> void:
	var files := DirAccess.get_files_at("res://data/runes")
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue

		var resource := load("res://data/runes".path_join(file_name))

		if resource is RuneData:
			var rune := resource as RuneData
			runes[rune.id] = rune

	for i in range(mini(8, persistent_data.loadout.size())):
		var rune_id := persistent_data.loadout[i]

		if rune_id == &"" or not persistent_data.owned_runes.has(rune_id):
			continue

		if not runes.has(rune_id):
			push_warning("Loadout rune resource missing: %s" % rune_id)
			continue

		player_input.register_rune_action(
			KeybindManager.SLOT_ACTIONS[i],
			runes[rune_id]
		)


func _create_test_enemies() -> void:
	for enemy_data in battle_setup.enemies:
		_spawn_enemy(enemy_data)


func _create_default_test_setup() -> BattleSetup:
	var enemy_list: Array[EnemyData] = []

	for path in [
		"res://data/enemies/test_enemy_a.tres",
		"res://data/enemies/test_enemy_b.tres",
		"res://data/enemies/test_enemy_c.tres"
	]:
		var resource := load(path)

		if resource is EnemyData:
			enemy_list.append(resource as EnemyData)
		else:
			push_error("Invalid EnemyData resource: %s" % path)

	return BattleSetup.new(enemy_list)


func _spawn_enemy(data: EnemyData) -> void:
	var enemy := BattleEnemy.new()

	enemy.name = String(data.id)

	add_child(enemy)

	enemy.setup(
		data,
		battle_manager,
		scheduler,
		player,
		rng
	)

	enemies.append(enemy)

	battle_manager.register_enemy(enemy)


func _connect_runtime() -> void:
	player.died.connect(
		_on_player_died
	)

	player.damaged.connect(
		_on_player_damaged
	)

	player.hp_changed.connect(
		_on_player_hp_changed
	)

	rune_caster.casting_started.connect(
		_on_casting_started
	)

	rune_caster.casting_updated.connect(
		_on_casting_updated
	)

	rune_caster.rune_success.connect(
		_on_rune_success
	)

	rune_caster.cast_missed.connect(
		_on_cast_missed
	)
	rune_caster.input_rejected.connect(
		func(_reason: StringName): battle_audio.play_sfx(&"miss")
	)

	rune_caster.combo_changed.connect(
		_on_combo_changed
	)

	player_input.spell_fire_requested.connect(
		_on_spell_fire_requested
	)

	player_input.target_previous_requested.connect(
		_on_target_previous
	)

	player_input.target_next_requested.connect(
		_on_target_next
	)
	player_input.cancel_requested.connect(
		func(): battle_audio.play_sfx(&"cancel")
	)

	spell_executor.activation_started.connect(
		func(_event: PlayerAttackEvent): battle_audio.play_sfx(&"spell_cast")
	)

	player_input.parry_entered.connect(
		_on_parry_entered
	)

	spell_executor.damage_applied.connect(
		_on_spell_damage
	)

	spell_executor.dot_damage_applied.connect(
		_on_dot_damage
	)

	spell_executor.immune.connect(
		_on_immune
	)

	battle_manager.battle_state_changed.connect(
		_on_battle_state_changed
	)

	for enemy in enemies:
		enemy.attack_started.connect(
			_on_enemy_attack_started
		)

		enemy.parried.connect(
			_on_enemy_parried
		)

		enemy.attack_impacted.connect(
			_on_enemy_attack_impacted
		)

		enemy.died.connect(
			_on_enemy_died
		)


func _on_spell_fire_requested() -> void:
	if spell_executor.activation_locked:
		print("SPELL LOCKED")
		return

	var spell := rune_caster.get_current_spell()

	if spell == null:
		return

	var targets: Array = []

	match spell.target_mode:
		SpellData.TargetMode.SINGLE_ENEMY:
			var target = _get_selected_target()

			if target == null:
				return

			targets.append(target)

		SpellData.TargetMode.RANDOM_MULTI:
			var target = _get_selected_target()

			if target == null:
				return

			targets.append(target)

		SpellData.TargetMode.ALL_ENEMIES:
			targets = battle_manager.get_living_enemies()

		SpellData.TargetMode.BATTLE_WIDE:
			targets = battle_manager.get_living_enemies()

		SpellData.TargetMode.SELF:
			pass

		SpellData.TargetMode.NONE:
			pass

	var consumed := rune_caster.consume_combo()

	var event := PlayerAttackEvent.new(
		player,
		targets,
		spell,
		int(consumed["perfect_count"])
	)

	if not spell_executor.activate(event):
		print("Spell activation rejected.")
		return

	var spell_key := String(spell.id)

	spell_use_counts[spell_key] = (
		int(
			spell_use_counts.get(
				spell_key,
				0
			)
		)
		+ 1
	)


func _select_initial_target() -> void:
	# Three-enemy rule: center.
	if enemies.size() == 3:
		selected_target_index = 1

	elif enemies.size() == 2:
		selected_target_index = 0

	else:
		selected_target_index = 0


func _get_selected_target():
	if enemies.is_empty():
		return null

	if (
		selected_target_index >= 0
		and selected_target_index < enemies.size()
	):
		var current := enemies[selected_target_index]

		if current.is_alive():
			return current

	for enemy in enemies:
		if enemy.is_alive():
			return enemy

	return null


func _on_target_previous() -> void:
	_cycle_target(-1)


func _on_target_next() -> void:
	_cycle_target(1)


func _cycle_target(direction: int) -> void:
	if not _current_spell_uses_selected_enemy():
		return

	if enemies.is_empty():
		return

	var index := selected_target_index

	for i in range(enemies.size()):
		index = posmod(
			index + direction,
			enemies.size()
		)

		if enemies[index].is_alive():
			selected_target_index = index
			if battle_ui != null:
				battle_ui.refresh_targets(self)

			print(
				"TARGET -> ",
				_target_name()
			)
			battle_audio.play_sfx(&"target_change")

			return


func _target_name() -> String:
	var target = _get_selected_target()

	if target == null:
		return "NONE"

	return target.data.display_name


func _current_spell_uses_selected_enemy() -> bool:
	var spell := rune_caster.get_current_spell()

	if spell == null:
		return false

	return spell.target_mode in [
		SpellData.TargetMode.SINGLE_ENEMY,
		SpellData.TargetMode.RANDOM_MULTI
	]


func _on_player_died() -> void:
	battle_manager.notify_player_death()


func _on_player_damaged(
	amount: int
) -> void:
	player_hit_count += 1

	rune_caster.clear_combo()

	print("PLAYER HIT: ", amount)
	battle_audio.play_sfx(&"player_hit")

func _on_player_hp_changed(
	current: int,
	maximum: int
) -> void:
	print(
		"PLAYER HP: ",
		current,
		"/",
		maximum
	)


func _on_casting_started(rune: RuneData) -> void:
	battle_audio.play_sfx(&"rune_input")
	print(
		"CAST START: ",
		rune.display_name
	)


func _on_casting_updated(
	_position: float,
	_region: StringName
) -> void:
	# UI will display this later.
	pass


func _on_rune_success(
	rune: RuneData,
	judgement: StringName
) -> void:
	if judgement == &"perfect":
		total_perfects += 1
		battle_audio.play_sfx(&"perfect", 1.0 + float(rune_caster.perfect_count) * 0.05)
	else:
		battle_audio.play_sfx(&"normal")

	print(
		"RUNE ",
		rune.id,
		" -> ",
		judgement
	)


func _on_cast_missed() -> void:
	print("MISS - COMBO CLEARED")
	battle_audio.play_sfx(&"miss")


func _on_combo_changed(
	combo: Array[RuneData],
	perfect_count: int
) -> void:
	var ids: Array[String] = []

	for rune in combo:
		ids.append(String(rune.id))

	print(
		"COMBO: ",
		ids,
		" PERFECT=",
		perfect_count
	)


func _on_parry_entered(
	direction: EnemyAttackEvent.ParryDirection
) -> void:
	print(
		"PARRY STANCE: ",
		_direction_name(direction)
	)


func _on_enemy_attack_started(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	battle_audio.play_sfx(&"telegraph")
	print(
		enemy.data.display_name,
		" ATTACK -> ",
		_direction_name(
			event.resolved_direction
		)
	)


func _on_enemy_parried(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	parry_count += 1
	battle_audio.play_sfx(&"parry")
	print(
		"PARRY SUCCESS: ",
		enemy.data.display_name,
		" ",
		_direction_name(
			event.resolved_direction
		)
	)


func _on_enemy_attack_impacted(
	enemy: BattleEnemy,
	event: EnemyAttackEvent
) -> void:
	print(
		"IMPACT: ",
		enemy.data.display_name,
		" damage=",
		event.damage
	)


func _on_spell_damage(
	target,
	amount: int,
	resistance: float,
	perfect_count: int,
	attribute_id: StringName
) -> void:
	battle_audio.play_sfx(&"spell_hit")
	resistance_knowledge.discover(
		target.data.id,
		attribute_id,
		resistance
	)

	persistent_data.resistance_knowledge = (
		resistance_knowledge.knowledge
	)

	SaveSystem.save_player(
		persistent_data
	)

	print(
		"SPELL HIT: ",
		target.data.display_name,
		" damage=",
		amount,
		" resist=",
		resistance,
		" perfect=",
		perfect_count,
		" attribute=",
		attribute_id,
		" HP=",
		target.hp
	)

func _on_dot_damage(
	target,
	amount: int
) -> void:
	print(
		"DOT: ",
		target.data.display_name,
		" damage=",
		amount,
		" HP=",
		target.hp
	)

func _on_immune(
	target,
	attribute_id: StringName
) -> void:
	resistance_knowledge.discover(
		target.data.id,
		attribute_id,
		0.0
	)

	persistent_data.resistance_knowledge = (
		resistance_knowledge.knowledge
	)

	SaveSystem.save_player(
		persistent_data
	)

	print(
		"IMMUNE: ",
		target.data.display_name,
		" attribute=",
		attribute_id
	)

func _on_enemy_died(enemy: BattleEnemy) -> void:
	defeated_enemy_ids.append(
	enemy.data.id
	)
	print(
		"ENEMY DEAD: ",
		enemy.data.display_name
	)

	_select_next_after_death()


func _select_next_after_death() -> void:
	# Stable left-to-right preference.
	for i in range(enemies.size()):
		if enemies[i].is_alive():
			selected_target_index = i
			if battle_ui != null:
				battle_ui.refresh_targets(self)
			return


func _on_battle_state_changed(
	state: BattleManager.BattleState
) -> void:
	print(
		"BATTLE STATE: ",
		BattleManager.BattleState.keys()[state]
	)

	if state == BattleManager.BattleState.VICTORY:
		battle_audio.stop_bgm()
		battle_audio.play_sfx(&"victory")
		player_input.input_enabled = false
		battle_status.set_battle_running(false)
		player_status.set_battle_running(false)

		_clear_runtime_statuses()

		_build_battle_result(true)

		if battle_ui != null:
			battle_ui.show_result(
				true
			)

	elif state == BattleManager.BattleState.DEFEAT:
		battle_audio.stop_bgm()
		battle_audio.play_sfx(&"defeat")
		player_input.input_enabled = false
		battle_status.set_battle_running(false)
		player_status.set_battle_running(false)

		_clear_runtime_statuses()

		_build_battle_result(false)

		if battle_ui != null:
			battle_ui.show_result(
				false
			)


func _clear_runtime_statuses() -> void:
	spell_executor.clear_runtime_effects()
	battle_status.clear_all()
	player_status.clear_all()

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.status_controller != null:
			enemy.status_controller.clear_all()

func _direction_name(
	direction: EnemyAttackEvent.ParryDirection
) -> String:
	return EnemyAttackEvent.ParryDirection.keys()[
		direction
	]
func _create_battle_ui() -> void:
	battle_ui = BattleUI.new()
	battle_ui.name = "BattleUI"
	add_child(battle_ui)

	battle_ui.setup(self)
	loadout_ui = LoadoutKeybindUI.new()
	loadout_ui.name = "LoadoutKeybindUI"

	battle_ui.add_child(
		loadout_ui
	)

	loadout_ui.setup(
		persistent_data,
		keybind_manager
	)

	loadout_ui.visible = false
	debug_overlay = DebugOverlay.new()
	debug_overlay.name = "DebugOverlay"
	add_child(debug_overlay)
	debug_overlay.setup(self)

func _unhandled_input(
	event: InputEvent
) -> void:
	if not event.is_pressed():
		return

	if event.is_echo():
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if key_event.keycode == KEY_F3:
		if debug_overlay != null:
			debug_overlay.toggle()

		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_TAB:
		if loadout_ui != null:
			loadout_ui.visible = (
				not loadout_ui.visible
			)

		get_viewport().set_input_as_handled()
		return

func _build_battle_result(
	victory: bool
) -> void:
	battle_result.victory = victory
	battle_result.remaining_hp = player.hp

	battle_result.defeated_enemy_ids = (
		defeated_enemy_ids.duplicate()
	)

	battle_result.battle_duration = (
		battle_manager.battle_time
	)

	battle_result.perfect_count = (
		total_perfects
	)

	battle_result.parry_count = (
		parry_count
	)

	battle_result.hit_count = (
		player_hit_count
	)

	battle_result.spell_use_counts = (
		spell_use_counts.duplicate(true)
	)

	persistent_data.current_hp = player.hp
	SaveSystem.save_player(persistent_data)

	print("----- BATTLE RESULT -----")
	print("Victory: ", battle_result.victory)
	print("Remaining HP: ", battle_result.remaining_hp)
	print("Defeated: ", battle_result.defeated_enemy_ids)
	print("Duration: ", battle_result.battle_duration)
	print("Perfects: ", battle_result.perfect_count)
	print("Parries: ", battle_result.parry_count)
	print("Hits taken: ", battle_result.hit_count)
	print("Spells: ", battle_result.spell_use_counts)
