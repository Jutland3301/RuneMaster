extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var data := SaveSystem.load_player()
	var manager := KeybindManager.new()
	manager.apply_saved_bindings(data.keybinds)
	var ui := LoadoutKeybindUI.new()
	add_child(ui)
	ui.setup(data, manager)
