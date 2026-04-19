extends Node2D


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://components/level2.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://components/menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
