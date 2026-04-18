extends Node2D

signal finished

const ENEMY_SCENE: PackedScene = preload("res://components/level/enemy.tscn")

@export var spawn_interval: float = 0.5
@export var max_spawns: int = 100
@export var auto_start: bool = false

var _spawned: int = 0
var _cooldown: float = 0.0
var _enabled: bool = false
var _finished: bool = true


func _ready() -> void:
	if auto_start:
		start_wave()


func _process(delta: float) -> void:
	if not _enabled or _finished:
		return
	if _spawned >= max_spawns:
		_finished = true
		_enabled = false
		finished.emit()
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = spawn_interval
	_spawn()


func start_wave() -> void:
	_spawned = 0
	_cooldown = 0.0
	_finished = false
	_enabled = true


func set_enabled(value: bool) -> void:
	_enabled = value


func _spawn() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	_spawned += 1
