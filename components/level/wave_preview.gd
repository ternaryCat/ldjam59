extends PanelContainer

const ENEMY_SCENE: PackedScene = preload("res://components/level/enemy.tscn")
const ICON_SIZE: Vector2 = Vector2(56, 56)

@onready var _icon: Control = $row/icon
@onready var _label: Label = $row/label

var _sprite: AnimatedSprite2D


func _ready() -> void:
	var probe: Node = ENEMY_SCENE.instantiate()
	var probe_sprite: AnimatedSprite2D = probe.get_node("sprite")
	var frames: SpriteFrames = probe_sprite.sprite_frames
	probe.free()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = &"walk"
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.position = ICON_SIZE * 0.5
	_icon.add_child(_sprite)
	_sprite.play(&"walk")


func set_count(count: int) -> void:
	_label.text = "× %d" % count
