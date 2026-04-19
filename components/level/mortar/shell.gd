extends Node2D

const IMPACT_SCENE: PackedScene = preload("res://components/level/mortar/impact.tscn")

@export var peak_height: float = 160.0
@export var splash_radius: float = 120.0
@export var splash_damage: int = 25

var _from: Vector2
var _to: Vector2
var _t: float = 0.0
var _flight_time: float = 1.0

@onready var _body: Node2D = $body


func launch(from: Vector2, to: Vector2, flight_time: float) -> void:
	_from = from
	_to = to
	_flight_time = maxf(flight_time, 0.05)
	global_position = from


func _process(delta: float) -> void:
	_t += delta
	var progress := _t / _flight_time
	if progress >= 1.0:
		global_position = _to
		if _body:
			_body.position = Vector2.ZERO
		_impact()
		return
	global_position = _from.lerp(_to, progress)
	if _body:
		_body.position = Vector2(0.0, -sin(PI * progress) * peak_height)


func _impact() -> void:
	var vfx := IMPACT_SCENE.instantiate()
	get_parent().add_child(vfx)
	vfx.global_position = _to
	vfx.max_radius = splash_radius
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = splash_radius
	params.shape = shape
	params.collision_mask = 64
	params.transform = Transform2D(0.0, _to)
	var hits := space_state.intersect_shape(params, 32)
	for hit in hits:
		var other = hit.collider
		if other and other.is_in_group("enemies") and other.has_method("take_damage"):
			other.take_damage(splash_damage)
	queue_free()
