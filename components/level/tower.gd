extends Node2D

const SHOT_SCENE: PackedScene = preload("res://components/level/tower/shot.tscn")

@export var fire_interval: float = 0.6
@export var shot_speed: float = 700.0

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0

@onready var _vision: Area2D = $vision
@onready var _head: Sprite2D = $head
@onready var _shoot_point: Node2D = $head/shoot_point


func _ready() -> void:
	_vision.area_entered.connect(_on_target_entered)
	_vision.area_exited.connect(_on_target_exited)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
	if _targets.is_empty():
		return
	var target := _targets[0]
	_head.look_at(target.global_position)
	_head.rotation += PI
	if _cooldown > 0.0:
		return
	_fire(target)
	_cooldown = fire_interval


func _on_target_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target is Node2D and target.is_in_group("enemies"):
		_targets.append(target)


func _on_target_exited(area: Area2D) -> void:
	var target := area.get_parent()
	if target is Node2D and target.is_in_group("enemies"):
		_targets.erase(target)


func _fire(target: Node2D) -> void:
	var shot := SHOT_SCENE.instantiate()
	get_parent().add_child(shot)
	shot.global_position = _shoot_point.global_position
	var dir := (target.global_position - _shoot_point.global_position).normalized()
	shot.launch(dir, shot_speed)


func get_spec() -> Dictionary:
	var shape: CollisionShape2D = get_node_or_null("vision/shape")
	var r := 0.0
	if shape and shape.shape is CircleShape2D:
		r = (shape.shape as CircleShape2D).radius
	var shot: Node = SHOT_SCENE.instantiate()
	var dmg: int = shot.damage
	shot.free()
	return {
		"range": r,
		"min_range": 0.0,
		"reload": fire_interval,
		"damage": dmg,
		"damage_label": "Damage",
	}
