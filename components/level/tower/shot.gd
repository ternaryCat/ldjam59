extends Sprite2D

@export var damage: int = 10
@export var lifetime: float = 3.0

var _velocity: Vector2 = Vector2.ZERO
var _life_left: float

@onready var _collision: Area2D = $collision


func _ready() -> void:
	_life_left = lifetime
	_collision.area_entered.connect(_on_hit)


func launch(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


func _on_hit(area: Area2D) -> void:
	var target := area.get_parent()
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
