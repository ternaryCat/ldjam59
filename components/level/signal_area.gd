extends Area2D

@export var fill_color: Color = Color(1, 1, 1, 0.18)
@export var outline_color: Color = Color(1, 1, 1, 0.5)
@export var outline_width: float = 2.0

@onready var _shape: CollisionShape2D = $shape


func _ready() -> void:
	add_to_group("signal_field")
	_set_active(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate"):
		_set_active(true)
	elif event.is_action_released("activate"):
		_set_active(false)


func _set_active(active: bool) -> void:
	visible = active
	monitoring = active


func _draw() -> void:
	var s := _shape.shape
	if s is CircleShape2D:
		var r := (s as CircleShape2D).radius
		draw_circle(_shape.position, r, fill_color)
		draw_arc(_shape.position, r, 0.0, TAU, 64, outline_color, outline_width)
