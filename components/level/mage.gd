extends Node2D

const BOLT_SCENE: PackedScene = preload("res://components/level/mage/bolt.tscn")

@export var fire_interval: float = 1.2
@export var initial_spread: float = 0.6

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
	if target is CharacterBody2D:
		_targets.append(target)


func _on_target_exited(area: Area2D) -> void:
	var target := area.get_parent()
	if target is CharacterBody2D:
		_targets.erase(target)


func _fire(target: Node2D) -> void:
	var bolt := BOLT_SCENE.instantiate()
	get_parent().add_child(bolt)
	bolt.global_position = _shoot_point.global_position
	var to_target := (target.global_position - _shoot_point.global_position).normalized()
	var dir := to_target.rotated(randf_range(-initial_spread, initial_spread))
	bolt.launch(dir, target)
