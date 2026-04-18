extends StaticBody2D

@export var max_hp: int = 100

const HEALTHY_COLOR: Color = Color(1, 1, 1)
const DEAD_COLOR: Color = Color(1, 0.2, 0.2)

var _hp: int

@onready var _sprite: Sprite2D = $sprite


func _ready() -> void:
	_hp = max_hp
	add_to_group("buildings")


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
		return
	var t := 1.0 - float(_hp) / float(max_hp)
	_sprite.modulate = HEALTHY_COLOR.lerp(DEAD_COLOR, t)
