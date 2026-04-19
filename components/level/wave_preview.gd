extends PanelContainer

const ENEMY_SCENE: PackedScene = preload("res://components/level/enemy.tscn")
const ICON_SIZE: Vector2 = Vector2(56, 56)

@onready var _icon: Control = $row/icon
@onready var _label: Label = $row/label

var _sprite: AnimatedSprite2D
var _enemy_hp: int = 0
var _count: int = 0
var _reward: int = 0


func _ready() -> void:
	var probe: Node = ENEMY_SCENE.instantiate()
	var probe_sprite: AnimatedSprite2D = probe.get_node("sprite")
	var frames: SpriteFrames = probe_sprite.sprite_frames
	_enemy_hp = probe.max_hp
	probe.free()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = &"walk"
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.position = ICON_SIZE * 0.5
	_icon.add_child(_sprite)
	_sprite.play(&"walk")
	_refresh()


func set_count(count: int) -> void:
	_count = count
	_refresh()


func set_reward(value: int) -> void:
	_reward = value
	_refresh()


func _refresh() -> void:
	if _reward > 0:
		_label.text = "× %d   (HP %d)   +$%d" % [_count, _enemy_hp, _reward]
	else:
		_label.text = "× %d   (HP %d)" % [_count, _enemy_hp]
