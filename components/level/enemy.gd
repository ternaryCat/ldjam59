extends AnimatedSprite2D

@export var speed: float = 260.0

var _in_field: bool = false

@onready var _collision: Area2D = $collision


func _ready() -> void:
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


func _on_area_entered(_other: Area2D) -> void:
	_in_field = true


func _on_area_exited(_other: Area2D) -> void:
	_in_field = false
