extends Node2D

const RING_DURATION: float = 0.35
const RING_MAX_RADIUS: float = 160.0
const RING_WIDTH: float = 6.0
const RING_COLOR: Color = Color(1.0, 0.7, 0.25, 0.9)

var _ring_time: float = 0.0


func _process(delta: float) -> void:
	_ring_time += delta
	if _ring_time >= RING_DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_ring_time / RING_DURATION, 0.0, 1.0)
	var radius := lerpf(0.0, RING_MAX_RADIUS, t)
	var c := RING_COLOR
	c.a = RING_COLOR.a * (1.0 - t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, c, RING_WIDTH, true)
