extends Node2D

const SHOT_SCENE: PackedScene = preload("res://components/level/tower/shot.tscn")
const ATTACK_SFX: AudioStream = preload("res://images/tower.mp3")

signal clicked(tower: Node2D)

@export var fire_interval: float = 0.6
@export var shot_speed: float = 700.0
@export var shot_damage: int = 10
@export var shot_pierce: int = 1
@export var shot_scale: Vector2 = Vector2(1.0, 1.0)
@export var upgrades: Array[BallistaUpgrade] = []

var _targets: Array[Node2D] = []
var _cooldown: float = 0.0
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
	var base_vision := _vision_radius()
	var lv1 := BallistaUpgrade.new()
	lv1.cost = 60
	lv1.fire_interval = fire_interval
	lv1.shot_speed = shot_speed
	lv1.shot_damage = shot_damage + 5
	lv1.shot_pierce = shot_pierce + 1
	lv1.shot_scale = Vector2(1.15, 1.15)
	lv1.vision_radius = base_vision + 50.0
	lv1.tint = Color(1.0, 0.95, 0.8, 1.0)
	upgrades.append(lv1)
	var lv2 := BallistaUpgrade.new()
	lv2.cost = 140
	lv2.fire_interval = fire_interval
	lv2.shot_speed = shot_speed
	lv2.shot_damage = shot_damage + 10
	lv2.shot_pierce = shot_pierce + 2
	lv2.shot_scale = Vector2(1.3, 1.3)
	lv2.vision_radius = base_vision + 100.0
	lv2.tint = Color(1.1, 1.0, 0.7, 1.0)
	upgrades.append(lv2)


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
	shot.damage = shot_damage
	shot.pierce = shot_pierce
	shot.scale = shot_scale
	var dir := (target.global_position - _shoot_point.global_position).normalized()
	shot.launch(dir, shot_speed)
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
	var u: BallistaUpgrade = upgrades[_level]
	return {
		"level": _level + 1,
		"cost": u.cost,
		"range": u.vision_radius,
		"min_range": 0.0,
		"reload": u.fire_interval,
		"damage": u.shot_damage,
		"damage_label": "Damage",
		"pierce": u.shot_pierce,
	}


func apply_upgrade() -> void:
	if _level >= upgrades.size():
		return
	var u: BallistaUpgrade = upgrades[_level]
	fire_interval = u.fire_interval
	shot_speed = u.shot_speed
	shot_damage = u.shot_damage
	shot_pierce = u.shot_pierce
	shot_scale = u.shot_scale
	_set_vision_radius(u.vision_radius)
	_apply_tint(u.tint)
	_level += 1


func get_spec() -> Dictionary:
	return {
		"range": _vision_radius(),
		"min_range": 0.0,
		"reload": fire_interval,
		"damage": shot_damage,
		"damage_label": "Damage",
		"pierce": shot_pierce,
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
