extends AnimatedSprite2D

@export var speed: float = 260.0
@export var max_hp: int = 100
@export var attack_damage: int = 1
@export var attack_interval: float = 0.5

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)

var _in_field: bool = false
var _hp: int
var _buildings_in_range: Array[Node2D] = []
var _attack_cooldown: float = 0.0

@onready var _collision: Area2D = $collision


func _ready() -> void:
	_hp = max_hp
	_collision.area_entered.connect(_on_area_entered)
	_collision.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	_attack_cooldown -= delta
	_cleanup_buildings()
	if _in_field and Input.is_action_pressed("activate"):
		_follow_player_input(delta)
		return
	_attack_touching_building()
	_advance_to_nearest_building(delta)


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
		return
	var t := 1.0 - float(_hp) / float(max_hp)
	modulate = HEALTHY_COLOR.lerp(DEAD_COLOR, t)


func _follow_player_input(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "top", "down")
	if direction == Vector2.ZERO:
		return
	position += direction * speed * delta
	rotation = direction.angle()


func _advance_to_nearest_building(delta: float) -> void:
	if not _buildings_in_range.is_empty():
		return
	var target := _find_nearest_building()
	if target == null:
		return
	var to_target := target.global_position - global_position
	if to_target == Vector2.ZERO:
		return
	var direction := to_target.normalized()
	position += direction * speed * delta
	rotation = direction.angle()


func _attack_touching_building() -> void:
	if _attack_cooldown > 0.0 or _buildings_in_range.is_empty():
		return
	var target := _buildings_in_range[0]
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	_attack_cooldown = attack_interval


func _find_nearest_building() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for b in get_tree().get_nodes_in_group("buildings"):
		if not (b is Node2D):
			continue
		var d := global_position.distance_squared_to((b as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = b
	return best


func _cleanup_buildings() -> void:
	for i in range(_buildings_in_range.size() - 1, -1, -1):
		if not is_instance_valid(_buildings_in_range[i]):
			_buildings_in_range.remove_at(i)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("signal_field"):
		_in_field = true
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
