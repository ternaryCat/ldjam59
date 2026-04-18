extends HBoxContainer

const HOUSE_BASE_TEX: Texture2D = preload("res://images/home_base.png")
const HOUSE_ROOF_TEX: Texture2D = preload("res://images/home_roof.png")
const ICON_SCALE: float = 0.4
const ICON_SIZE: Vector2 = Vector2(70, 70)
const ROOF_OFFSET_LOCAL: Vector2 = Vector2(-3.0, -22.0)
const SHAKE_DURATION: float = 0.25
const SHAKE_AMPLITUDE: float = 5.0

var _shake_time: float = 0.0
var _icon_root: Control
var _base_sprite: Sprite2D
var _roof_sprite: Sprite2D
var _base_pos: Vector2
var _roof_pos: Vector2
var _bar: ProgressBar


func _init() -> void:
	add_theme_constant_override("separation", 8)
	_icon_root = Control.new()
	_icon_root.custom_minimum_size = ICON_SIZE
	_icon_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon_root)
	_base_sprite = Sprite2D.new()
	_base_sprite.texture = HOUSE_BASE_TEX
	_base_sprite.scale = Vector2(ICON_SCALE, ICON_SCALE)
	_base_pos = ICON_SIZE * 0.5
	_base_sprite.position = _base_pos
	_icon_root.add_child(_base_sprite)
	_roof_sprite = Sprite2D.new()
	_roof_sprite.texture = HOUSE_ROOF_TEX
	_roof_sprite.scale = Vector2(ICON_SCALE, ICON_SCALE)
	_roof_pos = ICON_SIZE * 0.5 + ROOF_OFFSET_LOCAL * ICON_SCALE
	_roof_sprite.position = _roof_pos
	_icon_root.add_child(_roof_sprite)
	_bar = ProgressBar.new()
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(120, 18)
	add_child(_bar)


func bind(building: Node) -> void:
	_roof_sprite.modulate = building.roof_color
	_bar.max_value = building.max_hp
	_bar.value = building.max_hp
	if building.has_signal("hp_changed"):
		building.hp_changed.connect(_on_hp_changed)
	if building.has_signal("damaged"):
		building.damaged.connect(_on_damaged)
	building.tree_exited.connect(queue_free)


func _on_hp_changed(curr: int, max_value: int) -> void:
	_bar.max_value = max_value
	_bar.value = curr


func _on_damaged() -> void:
	_shake_time = SHAKE_DURATION


func _process(delta: float) -> void:
	if _shake_time <= 0.0:
		if _base_sprite.position != _base_pos:
			_base_sprite.position = _base_pos
			_roof_sprite.position = _roof_pos
		return
	_shake_time -= delta
	var amp := SHAKE_AMPLITUDE * maxf(_shake_time / SHAKE_DURATION, 0.0)
	var off := Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	_base_sprite.position = _base_pos + off
	_roof_sprite.position = _roof_pos + off
