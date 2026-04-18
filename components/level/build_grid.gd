extends Node2D

signal tile_clicked(tile: Node)


func _ready() -> void:
	for child in get_children():
		if child.has_signal("clicked"):
			child.clicked.connect(_on_tile_clicked)


func _on_tile_clicked(tile: Node) -> void:
	tile_clicked.emit(tile)
