extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_resources_and_spell_lookup()
	_test_combat_math()
	_test_combo_and_judgement()
	_test_status_stack_expiration()
	_test_iframe_rules()
	_test_parry_directions()
	_test_scheduler_override()

	if failures.is_empty():
		print("RuneMaster battle smoke tests: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_resources_and_spell_lookup() -> void:
	var database := SpellDatabase.new()
	database.register_default_spells()
	_expect(database.get_all_spells().size() == 10, "Exactly 10 spells must load.")
	_expect(
		database.get_spell([&"fire", &"water"]) == database.get_spell([&"water", &"fire"]),
		"Spell lookup must be unordered."
	)

	for path in [
		"res://data/runes/algiz.tres",
		"res://data/runes/fire.tres",
		"res://data/runes/water.tres",
		"res://data/runes/lightning.tres",
		"res://data/runes/grass.tres"
	]:
		_expect(load(path) is RuneData, "%s must be RuneData." % path)

	for path in [
		"res://data/enemies/test_enemy_a.tres",
		"res://data/enemies/test_enemy_b.tres",
		"res://data/enemies/test_enemy_c.tres"
	]:
		var resource := load(path)
		_expect(resource is EnemyData, "%s must be EnemyData." % path)
		if resource is EnemyData:
			_expect((resource as EnemyData).attacks.size() >= 2, "%s needs attacks." % path)


func _test_combat_math() -> void:
	_expect(CombatMath.calculate_magic_damage(100.0, 10.0, 0, 1.0) == 110, "MP damage formula failed.")
	_expect(CombatMath.calculate_magic_damage(100.0, 10.0, 1, 0.5) == 82, "Perfect/resistance flooring failed.")
	_expect(CombatMath.calculate_magic_damage(100.0, 10.0, 0, 0.0) == 0, "Immunity failed.")


func _test_combo_and_judgement() -> void:
	var database := SpellDatabase.new()
	database.register_default_spells()
	var caster := RuneCaster.new()
	root.add_child(caster)
	caster.set_process(false)
	caster.setup(database, 3, 3301)
	var fire := load("res://data/runes/fire.tres") as RuneData
	var water := load("res://data/runes/water.tres") as RuneData
	var grass := load("res://data/runes/grass.tres") as RuneData

	_expect(caster.begin_rune(fire), "Single rune casting must begin.")
	caster.gauge.cursor_position = 0.5
	_expect(caster.judge_current_cast() == &"perfect", "Perfect judgement failed.")
	_expect(caster.perfect_count == 1, "Perfect count must increment.")
	_expect(not caster.can_begin_rune(fire), "Duplicate rune must be rejected.")
	_expect(caster.begin_rune(water), "Valid two-rune combo must begin.")
	caster.gauge.cursor_position = 0.3
	caster.judge_current_cast()
	_expect(caster.get_current_spell().id == &"mist", "Two-rune spell resolution failed.")
	_expect(not caster.can_begin_rune(grass), "Invalid third rune must be rejected before casting.")
	caster.clear_combo()
	_expect(not caster.has_combo(), "X-equivalent clear must empty combo.")
	_expect(caster.begin_rune(fire), "Rune casting must restart after clear.")
	caster.gauge.cursor_position = 0.0
	caster.judge_current_cast()
	_expect(not caster.has_combo(), "MISS must clear the full combo.")
	root.remove_child(caster)
	caster.free()


func _test_status_stack_expiration() -> void:
	var controller := StatusEffectController.new()
	root.add_child(controller)
	controller.add_effect(&"test", 0.1, StatusEffectController.StackRule.STACK)
	controller.add_effect(&"test", 1.0, StatusEffectController.StackRule.STACK)
	controller.set_process(false)
	controller._process(0.2)
	_expect(controller.has_effect(&"test"), "Expiring one stack must preserve other stacks.")
	root.remove_child(controller)
	controller.free()


func _test_iframe_rules() -> void:
	var player := PlayerCombat.new()
	root.add_child(player)
	player.reset_for_battle()
	_expect(player.receive_enemy_hit(10) == 10, "First hit must deal damage.")
	var iframe := player.invulnerability_remaining
	_expect(player.receive_enemy_hit(10) == 0, "I-frame hit must deal zero damage.")
	_expect(is_equal_approx(player.invulnerability_remaining, iframe), "I-frame hit must not extend invulnerability.")
	root.remove_child(player)
	player.free()


func _test_parry_directions() -> void:
	var player := PlayerCombat.new()
	root.add_child(player)
	player.set_process(false)
	player.reset_for_battle()

	for direction in EnemyAttackEvent.ParryDirection.values():
		player.enter_parry(direction)
		_expect(player.matches_parry(direction), "Parry direction %s failed." % direction)
		player.clear_parry()

	root.remove_child(player)
	player.free()


func _test_scheduler_override() -> void:
	var scheduler := AttackScheduler.new()
	var attack := AttackData.new()
	scheduler.notify_attack_started(attack, 1.0)
	_expect(not scheduler.can_start_attack(attack, 1.1), "Normal spacing must delay attacks.")
	attack.bypass_spacing = true
	_expect(scheduler.can_start_attack(attack, 1.1), "Spacing bypass must permit special attacks.")
	scheduler.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
