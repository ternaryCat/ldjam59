extends Node2D

const BANG_SFX: AudioStream = preload("res://images/bang.mp3")
const RING_DURATION: float = 0.35
const RING_WIDTH: float = 6.0
const RING_COLOR: Color = Color(1.0, 0.7, 0.25, 0.9)

@export var max_radius: float = 160.0

var _ring_time: float = 0.0
var _sfx_done: bool = false


func _ready() -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.stream = BANG_SFX
	sfx.finished.connect(func() -> void: _sfx_done = true)
	add_child(sfx)
	sfx.play()


func _process(delta: float) -> void:
	_ring_time += delta
	if _ring_time < RING_DURATION:
		queue_redraw()
	if _ring_time >= RING_DURATION and _sfx_done:
		queue_free()


func _draw() -> void:
	var t := clampf(_ring_time / RING_DURATION, 0.0, 1.0)
	var radius := lerpf(0.0, max_radius, t)
	var c := RING_COLOR
	c.a = RING_COLOR.a * (1.0 - t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, c, RING_WIDTH, true)
