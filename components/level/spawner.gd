extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://components/level/enemy.tscn")

@export var spawn_interval: float = 0.5
@export var max_spawns: int = 100

var _spawned: int = 0
var _cooldown: float = 0.0


func _process(delta: float) -> void:
	if _spawned >= max_spawns:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = spawn_interval
	_spawn()


func _spawn() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	_spawned += 1
