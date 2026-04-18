extends Node2D

const SHELL_SCENE: PackedScene = preload("res://components/level/mortar/shell.tscn")

@export var fire_interval: float = 1.8
@export var min_range: float = 180.0
@export var flight_time_per_px: float = 0.002
@export var flight_time_min: float = 0.6

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0

@onready var _vision: Area2D = $vision
@onready var _shoot_point: Node2D = $head/shoot_point


func _ready() -> void:
	_vision.area_entered.connect(_on_target_entered)
	_vision.area_exited.connect(_on_target_exited)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
	if _cooldown > 0.0:
		return
	var target := _first_valid_target()
	if target == null:
		return
	_fire(target)
	_cooldown = fire_interval


func _first_valid_target() -> Node2D:
	var min_sq := min_range * min_range
	for t in _targets:
		if not is_instance_valid(t):
			continue
		if global_position.distance_squared_to(t.global_position) < min_sq:
			continue
		return t
	return null


func _on_target_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target is Node2D and target.is_in_group("enemies"):
		_targets.append(target)


func _on_target_exited(area: Area2D) -> void:
	var target := area.get_parent()
	if target is Node2D and target.is_in_group("enemies"):
		_targets.erase(target)


func _fire(target: Node2D) -> void:
	var shell := SHELL_SCENE.instantiate()
	get_parent().add_child(shell)
	var from := _shoot_point.global_position
	var to := target.global_position
	var dist := from.distance_to(to)
	var flight_time := maxf(dist * flight_time_per_px, flight_time_min)
	shell.launch(from, to, flight_time)
