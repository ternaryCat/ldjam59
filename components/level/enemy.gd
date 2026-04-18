extends AnimatedSprite2D

@export var speed: float = 260.0
@export var max_hp: int = 100

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)

var _in_field: bool = false
var _hp: int

@onready var _collision: Area2D = $collision


func _ready() -> void:
	_hp = max_hp
	_collision.area_entered.connect(_on_area_entered)
	_collision.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	if not _in_field:
		return
	if not Input.is_action_pressed("activate"):
		return
	var direction := Input.get_vector("left", "right", "top", "down")
	if direction == Vector2.ZERO:
		return
	position += direction * speed * delta
	rotation = direction.angle()


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
		return
	var t := 1.0 - float(_hp) / float(max_hp)
	modulate = HEALTHY_COLOR.lerp(DEAD_COLOR, t)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("signal_field"):
		_in_field = true


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("signal_field"):
		_in_field = false
