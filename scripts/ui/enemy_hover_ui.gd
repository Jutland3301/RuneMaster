class_name EnemyHoverUI
extends Panel

var title_label: Label
var hp_label: Label
var status_label: Label
var resistance_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(
		260,
		180
	)

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	title_label = Label.new()
	title_label.position = Vector2(12, 10)
	title_label.size = Vector2(236, 25)
	add_child(title_label)

	hp_label = Label.new()
	hp_label.position = Vector2(12, 38)
	hp_label.size = Vector2(236, 25)
	add_child(hp_label)

	status_label = Label.new()
	status_label.position = Vector2(12, 68)
	status_label.size = Vector2(236, 25)
	add_child(status_label)

	resistance_label = Label.new()
	resistance_label.position = Vector2(12, 98)
	resistance_label.size = Vector2(
		236,
		75
	)
	resistance_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	add_child(resistance_label)


func show_enemy(
	enemy: BattleEnemy,
	knowledge: ResistanceKnowledge
) -> void:
	if enemy == null:
		visible = false
		return

	title_label.text = enemy.data.display_name

	hp_label.text = "HP: %d / %d" % [
		enemy.hp,
		enemy.data.max_hp
	]

	var statuses: Array[String] = []

	if enemy.stun_remaining > 0.0:
		statuses.append("STUN")

	if enemy.paralysis_remaining > 0.0:
		statuses.append("PARALYSIS")

	if statuses.is_empty():
		status_label.text = "Status: -"
	else:
		status_label.text = (
			"Status: "
			+ ", ".join(statuses)
		)

	var attributes: Array[StringName] = [
		&"fire",
		&"water",
		&"lightning",
		&"grass",
		&"mist",
		&"plasma",
		&"burning_spores",
		&"electric_whip",
		&"algae_guard",
		&"paralysis"
	]

	var lines: Array[String] = []

	for attribute_id in attributes:
		lines.append(
			"%s %s" % [
				String(attribute_id),
				knowledge.get_display(
					enemy.data,
					attribute_id
				)
			]
		)

	resistance_label.text = "\n".join(
		lines
	)
