extends Node2D

signal finished

const ENEMY_SCENE: PackedScene = preload("res://components/level/enemy.tscn")

@export var spawn_interval: float = 0.8
@export var max_spawns: int = 30
@export var batch_size: int = 2
@export var auto_start: bool = false

var _spawned: int = 0
var _cooldown: float = 0.0
var _enabled: bool = false
var _finished: bool = true
var _batch_bonus: int = 0


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
	var remaining := max_spawns - _spawned
	var burst := mini(maxi(batch_size + _batch_bonus, 1), remaining)
	for i in burst:
		_spawn()


func start_wave(count: int = -1, batch_bonus: int = 0) -> void:
	if count >= 0:
		max_spawns = count
	_batch_bonus = batch_bonus
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
