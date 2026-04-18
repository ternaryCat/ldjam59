extends Sprite2D

const SHOT_SCENE: PackedScene = preload("res://components/level/tower/shot.tscn")

@export var fire_interval: float = 0.6
@export var shot_speed: float = 700.0

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0

@onready var _vision: Area2D = $vision


func _ready() -> void:
	_vision.area_entered.connect(_on_target_entered)
	_vision.area_exited.connect(_on_target_exited)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
	if _cooldown > 0.0 or _targets.is_empty():
		return
	_fire(_targets[0])
	_cooldown = fire_interval


func _on_target_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target is Node2D:
		_targets.append(target)


func _on_target_exited(area: Area2D) -> void:
	_targets.erase(area.get_parent())


func _fire(target: Node2D) -> void:
	var shot := SHOT_SCENE.instantiate()
	get_parent().add_child(shot)
	shot.global_position = global_position
	var dir := (target.global_position - global_position).normalized()
	shot.launch(dir, shot_speed)
