extends Node2D

const BOLT_SCENE: PackedScene = preload("res://components/level/mage/bolt.tscn")
const ATTACK_SFX: AudioStream = preload("res://images/mage.mp3")

signal clicked(tower: Node2D)

@export var fire_interval: float = 0.2
@export var initial_spread: float = 0.6
@export var bolt_damage: int = 1
@export var slow_duration: float = 3.0
@export var slow_factor: float = 0.1
@export var upgrades: Array[MageUpgrade] = []

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0
var _last_target: Node2D = null
var _level: int = 0
var _sfx: AudioStreamPlayer2D

@onready var _vision: Area2D = $vision
@onready var _head: Sprite2D = $head
@onready var _shoot_point: Node2D = $head/shoot_point
@onready var _base: Sprite2D = $base
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
	var lv1 := MageUpgrade.new()
	lv1.cost = 150
	lv1.fire_interval = 0.18
	lv1.bolt_damage = 2
	lv1.slow_duration = 3.5
	lv1.slow_factor = 0.08
	lv1.vision_radius = 600.0
	lv1.tint = Color(0.75, 0.55, 1.3, 1.0)
	upgrades.append(lv1)
	var lv2 := MageUpgrade.new()
	lv2.cost = 300
	lv2.fire_interval = 0.15
	lv2.bolt_damage = 3
	lv2.slow_duration = 4.0
	lv2.slow_factor = 0.06
	lv2.vision_radius = 720.0
	lv2.tint = Color(0.6, 0.4, 1.5, 1.0)
	upgrades.append(lv2)
	var lv3 := MageUpgrade.new()
	lv3.cost = 600
	lv3.fire_interval = 0.12
	lv3.bolt_damage = 5
	lv3.slow_duration = 5.0
	lv3.slow_factor = 0.04
	lv3.vision_radius = 860.0
	lv3.tint = Color(0.45, 0.3, 1.7, 1.0)
	upgrades.append(lv3)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
	if _targets.is_empty():
		return
	if _cooldown > 0.0:
		var aim_target: Node2D = _last_target if is_instance_valid(_last_target) else _targets[0]
		_head.look_at(aim_target.global_position)
		_head.rotation += PI
		return
	var target := _pick_target()
	if target == null:
		return
	_head.look_at(target.global_position)
	_head.rotation += PI
	_fire(target)
	_last_target = target
	_cooldown = fire_interval


func _pick_target() -> Node2D:
	var pool: Array[Node2D] = []
	for t in _targets:
		if is_instance_valid(t) and t != _last_target:
			pool.append(t)
	if not pool.is_empty():
		return pool.pick_random()
	for t in _targets:
		if is_instance_valid(t):
			return t
	return null


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
	bolt.damage = bolt_damage
	bolt.slow_duration = slow_duration
	bolt.slow_factor = slow_factor
	var to_target := (target.global_position - _shoot_point.global_position).normalized()
	var dir := to_target.rotated(randf_range(-initial_spread, initial_spread))
	bolt.launch(dir, target)
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
	var u: MageUpgrade = upgrades[_level]
	return {
		"level": _level + 1,
		"cost": u.cost,
		"range": u.vision_radius,
		"min_range": 0.0,
		"reload": u.fire_interval,
		"damage": u.bolt_damage,
		"damage_label": "Magic",
		"slow_factor": u.slow_factor,
		"slow_duration": u.slow_duration,
	}


func apply_upgrade() -> void:
	if _level >= upgrades.size():
		return
	var u: MageUpgrade = upgrades[_level]
	fire_interval = u.fire_interval
	bolt_damage = u.bolt_damage
	slow_duration = u.slow_duration
	slow_factor = u.slow_factor
	_set_vision_radius(u.vision_radius)
	_apply_tint(u.tint)
	_level += 1


func get_spec() -> Dictionary:
	return {
		"range": _vision_radius(),
		"min_range": 0.0,
		"reload": fire_interval,
		"damage": bolt_damage,
		"damage_label": "Magic",
		"slow_factor": slow_factor,
		"slow_duration": slow_duration,
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
