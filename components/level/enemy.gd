extends CharacterBody2D

@export var speed: float = 260.0
@export var max_hp: int = 50
@export var attack_damage: int = 1
@export var attack_interval: float = 2

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)
const SLOW_TINT: Color = Color(0.55, 0.7, 1.2)
const SEPARATION_DIST: float = 45.0
const NEIGHBOR_PUSH: float = 15.0
const DRIFT_IMPULSE_MIN: float = 2.0
const DRIFT_IMPULSE_MAX: float = 5.0
const DRIFT_CAP_MIN: float = 0.35
const DRIFT_CAP_MAX: float = 0.65
const DRIFT_DECAY: float = 1.5
const SPEED_MULT_MIN: float = 0.85
const SPEED_MULT_MAX: float = 1.15
const TARGET_JITTER: float = 25.0
const PLAYER_CTRL_SPEED_FACTOR: float = 0.75
const PLAYER_CTRL_ESCAPE_FACTOR: float = 0.08
const PLAYER_CTRL_ATTACK_MULT: float = 3.0

var _in_field: bool = false
var _player: CharacterBody2D = null
var _hp: int
var _buildings_in_range: Array[Node2D] = []
var _attack_cooldown: float = 0.0
var _target_building: Node2D = null
var _query: PhysicsShapeQueryParameters2D
var _drift_impulse: float = 0.0
var _drift_cap: float = 0.0
var _drift_angle: float = 0.0
var _speed_mult: float = 1.0
var _target_offset: Vector2 = Vector2.ZERO
var _slow_factor: float = 1.0
var _slow_time_left: float = 0.0

@onready var _sprite: AnimatedSprite2D = $sprite
@onready var _collision: Area2D = $collision


func _ready() -> void:
	add_to_group("enemies")
	_hp = max_hp
	_collision.area_entered.connect(_on_area_entered)
	_collision.area_exited.connect(_on_area_exited)
	_query = PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = SEPARATION_DIST
	_query.shape = shape
	_query.collision_mask = 64
	_query.collide_with_areas = false
	_query.exclude = [get_rid()]
	_drift_impulse = randf_range(DRIFT_IMPULSE_MIN, DRIFT_IMPULSE_MAX)
	_drift_cap = randf_range(DRIFT_CAP_MIN, DRIFT_CAP_MAX)
	_speed_mult = randf_range(SPEED_MULT_MIN, SPEED_MULT_MAX)
	_target_offset = Vector2.from_angle(randf() * TAU) * randf_range(0.0, TARGET_JITTER)


func _physics_process(delta: float) -> void:
	_attack_cooldown -= delta
	_cleanup_buildings()
	if _slow_time_left > 0.0:
		_slow_time_left -= delta
		if _slow_time_left <= 0.0:
			_slow_factor = 1.0
			_refresh_tint()
	var player_controlled: bool = _in_field and Input.is_action_pressed("activate")
	var slowed: bool = _slow_time_left > 0.0
	var fully_locked: bool = player_controlled and slowed
	var direction: Vector2
	if fully_locked:
		direction = _player_direction()
	elif player_controlled:
		direction = _player_direction() + _own_direction() * PLAYER_CTRL_ESCAPE_FACTOR
	else:
		direction = _own_direction()
	if direction != Vector2.ZERO and not player_controlled:
		_drift_angle += randf_range(-_drift_impulse, _drift_impulse) * delta
		_drift_angle -= _drift_angle * DRIFT_DECAY * delta
		_drift_angle = clampf(_drift_angle, -_drift_cap, _drift_cap)
		direction = direction.rotated(_drift_angle)
	var move_mult := _speed_mult
	if fully_locked:
		move_mult *= PLAYER_CTRL_SPEED_FACTOR
	elif player_controlled:
		move_mult *= PLAYER_CTRL_SPEED_FACTOR * _slow_factor
	else:
		move_mult *= _slow_factor
	velocity = direction * speed * move_mult + _crowd_push()
	move_and_slide()
	var anim: StringName = &"walk" if direction != Vector2.ZERO else &"idle"
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0
	if not fully_locked:
		_attack_touching_building(player_controlled)


func _crowd_push() -> Vector2:
	_query.transform = Transform2D(0.0, global_position)
	var space_state := get_world_2d().direct_space_state
	var hits := space_state.intersect_shape(_query, 8)
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
	return push * NEIGHBOR_PUSH


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
		return
	_refresh_tint()


func apply_slow(duration: float, factor: float = 0.35) -> void:
	_slow_factor = minf(_slow_factor, factor)
	_slow_time_left = maxf(_slow_time_left, duration)
	_refresh_tint()


func _refresh_tint() -> void:
	var t := 1.0 - float(_hp) / float(max_hp)
	var base := HEALTHY_COLOR.lerp(DEAD_COLOR, t)
	if _slow_time_left > 0.0:
		base = base * SLOW_TINT
	_sprite.modulate = base


func _player_direction() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	var v := _player.get_real_velocity()
	if v.length_squared() < 25.0:
		return Vector2.ZERO
	return v.normalized()


func _own_direction() -> Vector2:
	if not _buildings_in_range.is_empty():
		return Vector2.ZERO
	var target := _pick_target_building()
	if target == null:
		return Vector2.ZERO
	var to_target := target.global_position + _target_offset - global_position
	if to_target == Vector2.ZERO:
		return Vector2.ZERO
	return to_target.normalized()


func _attack_touching_building(player_controlled: bool) -> void:
	if _attack_cooldown > 0.0 or _buildings_in_range.is_empty():
		return
	var target := _buildings_in_range[0]
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	var interval := attack_interval
	if player_controlled:
		interval *= PLAYER_CTRL_ATTACK_MULT
	_attack_cooldown = interval


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
