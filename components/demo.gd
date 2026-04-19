extends Node2D


func _ready() -> void:
	_set_vision($towers/ballista, 320.0)
	_set_vision($towers/mortar, 320.0)
	_set_vision($towers/mage, 400.0)


func _set_vision(tower: Node, r: float) -> void:
	var shape := tower.get_node_or_null("vision/shape") as CollisionShape2D
	if shape == null or not (shape.shape is CircleShape2D):
		return
	var c: CircleShape2D = shape.shape.duplicate()
	c.radius = r
	shape.shape = c
