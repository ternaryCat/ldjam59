extends CharacterBody2D

@export var speed: float = 320.0

const SEPARATION_DIST: float = 45.0
const ENEMY_PUSH: float = 6.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "top", "down")
	velocity = direction * speed + _enemy_push()
	move_and_slide()


func _enemy_push() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if not (other is Node2D):
			continue
		var offset := global_position - (other as Node2D).global_position
		var d := offset.length()
		if d >= SEPARATION_DIST or d <= 0.01:
			continue
		push += offset / d * (SEPARATION_DIST - d)
	return push * ENEMY_PUSH
