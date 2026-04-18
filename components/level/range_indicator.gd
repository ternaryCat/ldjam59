extends Node2D

const FILL_COLOR: Color = Color(1, 1, 1, 0.07)
const RING_COLOR: Color = Color(1, 1, 1, 0.55)
const DEAD_FILL: Color = Color(0, 0, 0, 0.25)
const DEAD_RING: Color = Color(1, 0.4, 0.4, 0.55)

@export var max_radius: float = 100.0:
	set(value):
		max_radius = value
		if is_node_ready():
			queue_redraw()
@export var min_radius: float = 0.0:
	set(value):
		min_radius = value
		if is_node_ready():
			queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if max_radius > 0.0:
		draw_circle(Vector2.ZERO, max_radius, FILL_COLOR)
		draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 64, RING_COLOR, 2.0, true)
	if min_radius > 0.0:
		draw_circle(Vector2.ZERO, min_radius, DEAD_FILL)
		draw_arc(Vector2.ZERO, min_radius, 0.0, TAU, 48, DEAD_RING, 2.0, true)
