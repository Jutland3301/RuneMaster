class_name DebugOverlay
extends CanvasLayer

var battle
var panel: Panel
var info: Label

var god_button: Button
var heal_button: Button
var reveal_button: Button
var kill_button: Button
var restart_button: Button

var visible_debug: bool = false

var front_button: Button
var up_button: Button
var down_button: Button
var left_button: Button
var right_button: Button

var mist_button: Button
var guard_button: Button
var paralysis_button: Button
var burn_button: Button

var damage_button: Button
var ai_frozen: bool = false
var freeze_ai_button: Button
var mp_spin: SpinBox
var seed_edit: LineEdit


func setup(p_battle) -> void:
	battle = p_battle
	_build()
	visible = false


func _process(_delta: float) -> void:
	if not visible_debug:
		return

	if battle == null:
		return

	_refresh()


func toggle() -> void:
	visible_debug = not visible_debug
	visible = visible_debug

	if visible_debug:
		_refresh()


func _build() -> void:
	panel = Panel.new()
	panel.position = Vector2(15, 15)
	panel.size = Vector2(720, 800)
	add_child(panel)

	info = Label.new()
	info.position = Vector2(15, 15)
	info.size = Vector2(690, 480)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(info)

	god_button = Button.new()
	god_button.position = Vector2(15, 505)
	god_button.size = Vector2(105, 40)
	god_button.text = "God Mode"
	god_button.pressed.connect(_toggle_god)
	panel.add_child(god_button)

	heal_button = Button.new()
	heal_button.position = Vector2(130, 505)
	heal_button.size = Vector2(105, 40)
	heal_button.text = "Heal"
	heal_button.pressed.connect(_heal)
	panel.add_child(heal_button)

	reveal_button = Button.new()
	reveal_button.position = Vector2(245, 505)
	reveal_button.size = Vector2(105, 40)
	reveal_button.text = "Reveal"
	reveal_button.pressed.connect(_toggle_reveal)
	panel.add_child(reveal_button)

	kill_button = Button.new()
	kill_button.position = Vector2(360, 505)
	kill_button.size = Vector2(105, 40)
	kill_button.text = "Kill Target"
	kill_button.pressed.connect(_kill_target)
	panel.add_child(kill_button)

	restart_button = Button.new()
	restart_button.position = Vector2(475, 505)
	restart_button.size = Vector2(105, 40)
	restart_button.text = "Restart"
	restart_button.pressed.connect(_restart)
	panel.add_child(restart_button)
	var attack_label := Label.new()
	attack_label.position = Vector2(15, 555)
	attack_label.size = Vector2(570, 25)
	attack_label.text = "FORCE ATTACK"
	panel.add_child(attack_label)

	front_button = _make_debug_button(
		"FRONT",
		Vector2(15, 585),
		Vector2(100, 36),
		_force_attack.bind(
			EnemyAttackEvent.ParryDirection.FRONT
		)
	)

	up_button = _make_debug_button(
		"UP",
		Vector2(120, 585),
		Vector2(100, 36),
		_force_attack.bind(
			EnemyAttackEvent.ParryDirection.UP
		)
	)

	down_button = _make_debug_button(
		"DOWN",
		Vector2(225, 585),
		Vector2(100, 36),
		_force_attack.bind(
			EnemyAttackEvent.ParryDirection.DOWN
		)
	)

	left_button = _make_debug_button(
		"LEFT",
		Vector2(330, 585),
		Vector2(100, 36),
		_force_attack.bind(
			EnemyAttackEvent.ParryDirection.LEFT
		)
	)

	right_button = _make_debug_button(
		"RIGHT",
		Vector2(435, 585),
		Vector2(100, 36),
		_force_attack.bind(
			EnemyAttackEvent.ParryDirection.RIGHT
		)
	)

	mist_button = _make_debug_button(
		"Mist",
		Vector2(15, 630),
		Vector2(100, 36),
		_force_mist
	)

	guard_button = _make_debug_button(
		"Guard",
		Vector2(120, 630),
		Vector2(100, 36),
		_force_guard
	)

	paralysis_button = _make_debug_button(
		"Paralysis",
		Vector2(225, 630),
		Vector2(100, 36),
		_force_paralysis
	)

	burn_button = _make_debug_button(
		"Burn",
		Vector2(330, 630),
		Vector2(100, 36),
		_force_burn
	)

	damage_button = _make_debug_button(
		"Hit Player",
		Vector2(435, 630),
		Vector2(100, 36),
		_force_player_hit
	)
	
	freeze_ai_button = _make_debug_button(
	"Freeze AI",
	Vector2(15, 675),
	Vector2(120, 36),
	_toggle_ai_freeze
	)

	var mp_label := Label.new()
	mp_label.position = Vector2(150, 681)
	mp_label.text = "MP"
	panel.add_child(mp_label)

	mp_spin = SpinBox.new()
	mp_spin.position = Vector2(185, 675)
	mp_spin.size = Vector2(100, 36)
	mp_spin.min_value = 0.0
	mp_spin.max_value = 999.0
	mp_spin.step = 1.0
	mp_spin.value_changed.connect(_set_magic_power)
	panel.add_child(mp_spin)

	var seed_label := Label.new()
	seed_label.position = Vector2(300, 681)
	seed_label.text = "Seed"
	panel.add_child(seed_label)

	seed_edit = LineEdit.new()
	seed_edit.position = Vector2(345, 675)
	seed_edit.size = Vector2(145, 36)
	seed_edit.placeholder_text = "RNG seed"
	panel.add_child(seed_edit)

	_make_debug_button("Apply Seed", Vector2(500, 675), Vector2(120, 36), _apply_seed)

func _refresh() -> void:
	var player: PlayerCombat = battle.player
	var caster: RuneCaster = battle.rune_caster

	var combo_ids: Array[String] = []

	for rune in caster.combo:
		combo_ids.append(String(rune.id))

	var selected = battle._get_selected_target()

	var selected_name := "NONE"

	if selected != null:
		selected_name = selected.data.display_name

	var cast_position := "-"
	var cast_region := "-"

	if caster.is_casting():
		cast_position = "%.3f" % caster.gauge.cursor_position
		cast_region = String(caster.gauge.judge())

	var lines: Array[String] = []

	lines.append("DEBUG [F3]")
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("RNG seed: %d" % battle.rng_seed)

	lines.append("")
	lines.append(
		"Battle: %s  time=%.2f" % [
			BattleManager.BattleState.keys()[
				battle.battle_manager.state
			],
			battle.battle_manager.battle_time
		]
	)

	lines.append("")
	lines.append(
		"Player HP: %d/%d  MP: %.1f" % [
			player.hp,
			player.max_hp,
			player.magic_power
		]
	)

	lines.append(
		"State: %s" % PlayerCombat.PlayerState.keys()[
			player.state
		]
	)

	lines.append(
		"i-frame: %.3f  hitstun: %.3f" % [
			player.invulnerability_remaining,
			player.hitstun_remaining
		]
	)

	lines.append(
		"Parry: %s" % (
			EnemyAttackEvent.ParryDirection.keys()[
				player.parry_direction
			]
			if player.parry_active
			else "NONE"
		)
	)

	lines.append(
		"Cast: pos=%s region=%s" % [
			cast_position,
			cast_region
		]
	)

	lines.append(
		"Combo: %s  Perfect=%d/%d slots" % [
			str(combo_ids),
			caster.perfect_count,
			caster.max_combo
		]
	)

	lines.append(
		"Target: %s" % selected_name
	)

	lines.append(
		"Activation lock: %s" %
		str(battle.spell_executor.activation_locked)
	)

	lines.append(
		"Mist: %.2f  Guard: %.2f" % [
			battle.battle_status.get_remaining(&"mist"),
			battle.player_status.get_remaining(&"algae_guard")
		]
	)
	lines.append("Player effects: %s" % _effect_text(battle.player_status))
	lines.append("Battle effects: %s" % _effect_text(battle.battle_status))

	lines.append("")
	lines.append("ENEMIES")

	for enemy in battle.enemies:
		var attack_name := "-"
		var direction_name := "-"
		var progress := 0.0
		var parry_window := false

		if enemy.active_attack != null:
			attack_name = String(
				enemy.active_attack.attack_data.id
			)

			direction_name = String(
				EnemyAttackEvent.ParryDirection.keys()[
					enemy.active_attack.resolved_direction
				]
			)

			progress = enemy.active_attack.telegraph_progress
			parry_window = enemy.active_attack.parry_window_active

		lines.append(
			"%s HP=%d timer=%.2f atk=%s dir=%s prog=%.2f P=%s stun=%.2f para=%.2f fx=%s" % [
				enemy.data.display_name,
				enemy.hp,
				enemy.next_attack_remaining,
				attack_name,
				direction_name,
				progress,
				str(parry_window),
				enemy.stun_remaining,
				enemy.paralysis_remaining,
				_effect_text(enemy.status_controller)
			]
		)

	lines.append("")
	lines.append(
		"Scheduler last attack: %.2f" %
		battle.scheduler.last_attack_start_time
	)
	lines.append("Scheduler categories: %s" % str(battle.scheduler.category_last_start))

	lines.append(
		"Reveal all: %s  God: %s" % [
			str(battle.resistance_knowledge.reveal_all),
			str(player.god_mode)
		]
	)

	info.text = "\n".join(lines)

	if not mp_spin.has_focus():
		mp_spin.value = player.magic_power

	if not seed_edit.has_focus():
		seed_edit.text = str(battle.rng_seed)


func _toggle_god() -> void:
	battle.player.god_mode = not battle.player.god_mode


func _heal() -> void:
	battle.player.heal_full()


func _toggle_reveal() -> void:
	battle.resistance_knowledge.reveal_all = (
		not battle.resistance_knowledge.reveal_all
	)


func _kill_target() -> void:
	var target = battle._get_selected_target()

	if target == null:
		return

	target.apply_damage(target.hp)


func _restart() -> void:
	get_tree().reload_current_scene()

func _make_debug_button(
	text: String,
	p_position: Vector2,
	p_size: Vector2,
	callback: Callable
) -> Button:
	var button := Button.new()

	button.text = text
	button.position = p_position
	button.size = p_size

	button.pressed.connect(
		callback
	)

	panel.add_child(button)

	return button


func _get_debug_target():
	if battle == null:
		return null

	return battle._get_selected_target()


func _force_attack(
	direction: EnemyAttackEvent.ParryDirection
) -> void:
	var target = _get_debug_target()

	if target == null:
		return

	target.debug_force_direction_attack(
		direction
	)


func _force_mist() -> void:
	if battle.battle_status.has_effect(
		&"mist"
	):
		return

	battle.battle_status.add_effect(
		&"mist",
		15.0,
		StatusEffectController.StackRule.IGNORE,
		{
			"parry_window_bonus": 0.3
		}
	)


func _force_guard() -> void:
	var applied : bool= (
		battle.player_status.add_effect(
			&"algae_guard",
			15.0,
			StatusEffectController.StackRule.IGNORE,
			{
				"direct_damage_multiplier": 0.8
			}
		)
	)

	if applied:
		battle.player.guard_damage_multiplier = 0.8


func _force_paralysis() -> void:
	var target = _get_debug_target()

	if target == null:
		return

	target.apply_paralysis(1.0)


func _force_burn() -> void:
	var target = _get_debug_target()

	if target == null:
		return

	battle.spell_executor.start_burn(
		target,
		0,
		20.0,
		5,
		1.0
	)


func _force_player_hit() -> void:
	battle.player.receive_enemy_hit(
		20
	)
func _toggle_ai_freeze() -> void:
	ai_frozen = not ai_frozen

	for enemy in battle.enemies:
		enemy.debug_ai_frozen = ai_frozen

	freeze_ai_button.text = (
		"Unfreeze AI"
		if ai_frozen
		else "Freeze AI"
	)


func _set_magic_power(value: float) -> void:
	if battle != null:
		battle.player.magic_power = value
		battle.persistent_data.magic_power = value


func _apply_seed() -> void:
	if not seed_edit.text.is_valid_int():
		return

	var new_seed := seed_edit.text.to_int()
	battle.set_debug_seed(new_seed)


func _effect_text(controller: StatusEffectController) -> String:
	var parts: Array[String] = []

	for entry in controller.get_debug_entries():
		parts.append("%s %.1f" % [entry["id"], entry["remaining"]])

	return "-" if parts.is_empty() else ", ".join(parts)
