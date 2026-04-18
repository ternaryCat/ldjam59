extends VBoxContainer

const ENTRY_SCRIPT: Script = preload("res://components/level/building_hud_entry.gd")


func set_buildings(buildings: Array) -> void:
	for child in get_children():
		child.queue_free()
	for b in buildings:
		if not is_instance_valid(b):
			continue
		var entry: HBoxContainer = ENTRY_SCRIPT.new()
		add_child(entry)
		entry.bind(b)
