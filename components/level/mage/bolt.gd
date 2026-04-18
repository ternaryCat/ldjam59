extends Sprite2D

@export var speed: float = 900.0
@export var turn_rate: float = 6.0
@export var damage: int = 1
@export var slow_duration: float = 3.0
@export var slow_factor: float = 0.1
@export var lifetime: float = 2.5

var _velocity: Vector2 = Vector2.ZERO
var _target: Node2D = null
var _life_left: float

@onready var _collision: Area2D = $collision


func _ready() -> void:
	_life_left = lifetime
	_collision.area_entered.connect(_on_hit)


func launch(direction: Vector2, target: Node2D) -> void:
	_velocity = direction.normalized() * speed
	_target = target
	rotation = _velocity.angle()


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	if is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		var current := _velocity.normalized()
		var angle_delta := clampf(current.angle_to(desired), -turn_rate * delta, turn_rate * delta)
		_velocity = current.rotated(angle_delta) * speed
	position += _velocity * delta
	rotation = _velocity.angle()


func _on_hit(area: Area2D) -> void:
	var hit_target := area.get_parent()
	if hit_target == null or not hit_target.is_in_group("enemies"):
		return
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(damage)
	if hit_target.has_method("apply_slow"):
		hit_target.apply_slow(slow_duration, slow_factor)
	queue_free()
