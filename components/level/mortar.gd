extends Node2D

const SHELL_SCENE: PackedScene = preload("res://components/level/mortar/shell.tscn")
const ATTACK_SFX: AudioStream = preload("res://images/siege.mp3")

signal clicked(tower: Node2D)

@export var fire_interval: float = 1.8
@export var min_range: float = 180.0
@export var flight_time_per_px: float = 0.002
@export var flight_time_min: float = 0.6
@export var splash_radius: float = 120.0
@export var splash_damage: int = 25
@export var upgrades: Array[MortarUpgrade] = []

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0
var _level: int = 0
var _sfx: AudioStreamPlayer2D

@onready var _vision: Area2D = $vision
@onready var _shoot_point: Node2D = $head/shoot_point
@onready var _base: Sprite2D = $base
@onready var _head: Sprite2D = $head
@onready var _body: StaticBody2D = $body


func _ready() -> void:
	_vision.area_entered.connect(_on_target_entered)
	_vision.area_exited.connect(_on_target_exited)
	if _body:
		_body.input_pickable = true
		_body.input_event.connect(_on_body_input)
	_sfx = AudioStreamPlayer2D.new()
	_sfx.stream = ATTACK_SFX
	add_child(_sfx)
	if upgrades.is_empty():
		_populate_default_upgrades()


func _populate_default_upgrades() -> void:
	var lv1 := MortarUpgrade.new()
	lv1.cost = 150
	lv1.fire_interval = 1.6
	lv1.splash_radius = 150.0
	lv1.splash_damage = 35
	lv1.vision_radius = 450.0
	lv1.min_range = 160.0
	lv1.tint = Color(0.95, 0.85, 0.65, 1.0)
	upgrades.append(lv1)
	var lv2 := MortarUpgrade.new()
	lv2.cost = 300
	lv2.fire_interval = 1.4
	lv2.splash_radius = 190.0
	lv2.splash_damage = 50
	lv2.vision_radius = 500.0
	lv2.min_range = 150.0
	lv2.tint = Color(1.0, 0.7, 0.4, 1.0)
	upgrades.append(lv2)
	var lv3 := MortarUpgrade.new()
	lv3.cost = 600
	lv3.fire_interval = 1.2
	lv3.splash_radius = 240.0
	lv3.splash_damage = 70
	lv3.vision_radius = 550.0
	lv3.min_range = 140.0
	lv3.tint = Color(1.0, 0.5, 0.2, 1.0)
	upgrades.append(lv3)


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
	shell.splash_radius = splash_radius
	shell.splash_damage = splash_damage
	var from := _shoot_point.global_position
	var to := target.global_position
	var dist := from.distance_to(to)
	var flight_time := maxf(dist * flight_time_per_px, flight_time_min)
	shell.launch(from, to, flight_time)
	if _sfx:
		_sfx.play()


func _on_body_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


func current_level() -> int:
	return _level


func max_upgrade_level() -> int:
	return upgrades.size()


func can_upgrade() -> bool:
	return _level < upgrades.size()


func get_upgrade_cost() -> int:
	if _level >= upgrades.size():
		return 0
	return upgrades[_level].cost


func get_upgrade_spec() -> Dictionary:
	if _level >= upgrades.size():
		return {}
	var u: MortarUpgrade = upgrades[_level]
	return {
		"level": _level + 1,
		"cost": u.cost,
		"range": u.vision_radius,
		"min_range": u.min_range,
		"reload": u.fire_interval,
		"damage": u.splash_damage,
		"damage_label": "Splash",
		"splash_radius": u.splash_radius,
	}


func apply_upgrade() -> void:
	if _level >= upgrades.size():
		return
	var u: MortarUpgrade = upgrades[_level]
	fire_interval = u.fire_interval
	min_range = u.min_range
	splash_radius = u.splash_radius
	splash_damage = u.splash_damage
	_set_vision_radius(u.vision_radius)
	_apply_tint(u.tint)
	_level += 1


func get_spec() -> Dictionary:
	return {
		"range": _vision_radius(),
		"min_range": min_range,
		"reload": fire_interval,
		"damage": splash_damage,
		"damage_label": "Splash",
		"splash_radius": splash_radius,
	}


func _vision_radius() -> float:
	var shape: CollisionShape2D = get_node_or_null("vision/shape")
	if shape and shape.shape is CircleShape2D:
		return (shape.shape as CircleShape2D).radius
	return 0.0


func _set_vision_radius(r: float) -> void:
	var shape: CollisionShape2D = get_node_or_null("vision/shape")
	if shape == null or not (shape.shape is CircleShape2D):
		return
	var circle: CircleShape2D = shape.shape.duplicate()
	circle.radius = r
	shape.shape = circle


func _apply_tint(c: Color) -> void:
	if _base:
		_base.modulate = c
	if _head:
		_head.modulate = c
