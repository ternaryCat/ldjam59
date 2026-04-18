extends CharacterBody2D

@export var speed: float = 260.0
@export var max_hp: int = 100
@export var attack_damage: int = 1
@export var attack_interval: float = 0.5

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)
const SEPARATION_DIST: float = 45.0
const NEIGHBOR_PUSH: float = 15.0

var _in_field: bool = false
var _player: CharacterBody2D = null
var _hp: int
var _buildings_in_range: Array[Node2D] = []
var _attack_cooldown: float = 0.0
var _target_building: Node2D = null

@onready var _sprite: AnimatedSprite2D = $sprite
@onready var _collision: Area2D = $collision


func _ready() -> void:
	add_to_group("enemies")
	_hp = max_hp
	_collision.area_entered.connect(_on_area_entered)
	_collision.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	_attack_cooldown -= delta
	_cleanup_buildings()
	var direction := _desired_direction()
	velocity = direction * speed + _crowd_push()
	move_and_slide()
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	if not (_in_field and Input.is_action_pressed("activate")):
		_attack_touching_building()


func _crowd_push() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		push += _repel_from(other)
	for p in get_tree().get_nodes_in_group("player"):
		push += _repel_from(p)
	return push * NEIGHBOR_PUSH


func _repel_from(other: Node) -> Vector2:
	if not (other is Node2D):
		return Vector2.ZERO
	var offset := global_position - (other as Node2D).global_position
	var d := offset.length()
	if d >= SEPARATION_DIST or d <= 0.01:
		return Vector2.ZERO
	return offset / d * (SEPARATION_DIST - d)


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
		return
	var t := 1.0 - float(_hp) / float(max_hp)
	_sprite.modulate = HEALTHY_COLOR.lerp(DEAD_COLOR, t)


func _desired_direction() -> Vector2:
	if _in_field and Input.is_action_pressed("activate"):
		if _player == null:
			return Vector2.ZERO
		var v := _player.get_real_velocity()
		if v.length_squared() < 25.0:
			return Vector2.ZERO
		return v.normalized()
	if not _buildings_in_range.is_empty():
		return Vector2.ZERO
	var target := _pick_target_building()
	if target == null:
		return Vector2.ZERO
	var to_target := target.global_position - global_position
	if to_target == Vector2.ZERO:
		return Vector2.ZERO
	return to_target.normalized()


func _attack_touching_building() -> void:
	if _attack_cooldown > 0.0 or _buildings_in_range.is_empty():
		return
	var target := _buildings_in_range[0]
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	_attack_cooldown = attack_interval


func _pick_target_building() -> Node2D:
	if is_instance_valid(_target_building):
		return _target_building
	var buildings := get_tree().get_nodes_in_group("buildings")
	if buildings.is_empty():
		_target_building = null
		return null
	_target_building = buildings.pick_random() as Node2D
	return _target_building


func _cleanup_buildings() -> void:
	for i in range(_buildings_in_range.size() - 1, -1, -1):
		if not is_instance_valid(_buildings_in_range[i]):
			_buildings_in_range.remove_at(i)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("signal_field"):
		_in_field = true
		var owner_node := area.get_parent()
		if owner_node is CharacterBody2D:
			_player = owner_node
		return
	var parent := area.get_parent()
	if parent is Node2D and parent.is_in_group("buildings"):
		_buildings_in_range.append(parent)


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("signal_field"):
		_in_field = false
		return
	var parent := area.get_parent()
	if parent is Node2D and parent.is_in_group("buildings"):
		_buildings_in_range.erase(parent)
