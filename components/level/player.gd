extends CharacterBody2D

@export var speed: float = 320.0

const SEPARATION_DIST: float = 45.0
const ENEMY_PUSH: float = 6.0

var _query: PhysicsShapeQueryParameters2D


func _ready() -> void:
	add_to_group("player")
	_query = PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = SEPARATION_DIST
	_query.shape = shape
	_query.collision_mask = 64
	_query.collide_with_areas = false
	_query.exclude = [get_rid()]


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "top", "down")
	velocity = direction * speed + _enemy_push()
	move_and_slide()


func _enemy_push() -> Vector2:
	_query.transform = Transform2D(0.0, global_position)
	var space_state := get_world_2d().direct_space_state
	var hits := space_state.intersect_shape(_query, 16)
	var push := Vector2.ZERO
	var sep_sq := SEPARATION_DIST * SEPARATION_DIST
	for hit in hits:
		var other = hit.collider
		if not (other is Node2D):
			continue
		var offset := global_position - (other as Node2D).global_position
		var d_sq := offset.length_squared()
		if d_sq >= sep_sq or d_sq <= 0.0001:
			continue
		var d := sqrt(d_sq)
		push += offset / d * (SEPARATION_DIST - d)
	return push * ENEMY_PUSH
