extends Node2D

@onready var _settings_dialog: AcceptDialog = $ui/settings_dialog


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://components/level2.tscn")


func _on_settings_pressed() -> void:
	_settings_dialog.popup_centered()


func _on_quit_pressed() -> void:
	get_tree().quit()
