extends StaticBody2D

signal hp_changed(current: int, max_value: int)
signal damaged

@export var max_hp: int = 100
@export var roof_color: Color = Color(1, 1, 1):
	set(value):
		roof_color = value
		if is_node_ready():
			_roof.modulate = value

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)

var _hp: int

@onready var _sprite: Sprite2D = $base
@onready var _roof: Sprite2D = $base/roof


func _ready() -> void:
	_hp = max_hp
	_roof.modulate = roof_color
	add_to_group("buildings")
	hp_changed.emit(_hp, max_hp)


func take_damage(amount: int) -> void:
	_hp -= amount
	damaged.emit()
	if _hp <= 0:
		hp_changed.emit(0, max_hp)
		queue_free()
		return
	var t := 1.0 - float(_hp) / float(max_hp)
	_sprite.modulate = HEALTHY_COLOR.lerp(DEAD_COLOR, t)
	hp_changed.emit(_hp, max_hp)
