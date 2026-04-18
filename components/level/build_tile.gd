extends Node2D

signal clicked(tile: Node)

enum TileColor { GREEN, YELLOW, RED }

const COLORS := {
	TileColor.GREEN: Color(0.3, 0.8, 0.3, 0.45),
	TileColor.YELLOW: Color(0.9, 0.8, 0.2, 0.45),
	TileColor.RED: Color(0.9, 0.3, 0.3, 0.45),
}
const OCCUPIED_ALPHA: float = 0.12

@export var tile_color: TileColor = TileColor.GREEN:
	set(value):
		tile_color = value
		if is_node_ready():
			_apply_color()
@export var tile_size: Vector2 = Vector2(96, 96):
	set(value):
		tile_size = value
		if is_node_ready():
			_apply_size()

var occupied: bool = false
var selected: bool = false

@onready var _rect: ColorRect = $rect


func _ready() -> void:
	_apply_size()
	_apply_color()


func mark_occupied() -> void:
	occupied = true
	selected = false
	_apply_color()


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	_apply_color()


func _apply_color() -> void:
	if _rect == null:
		return
	var c: Color = COLORS[tile_color]
	if occupied:
		c.a = OCCUPIED_ALPHA
	elif selected:
		c = c.lightened(0.5)
		c.a = 0.85
	_rect.color = c


func _apply_size() -> void:
	if _rect == null:
		return
	_rect.position = -tile_size * 0.5
	_rect.size = tile_size


func _unhandled_input(event: InputEvent) -> void:
	if occupied or not is_visible_in_tree():
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var rect := Rect2(global_position - tile_size * 0.5, tile_size)
	if not rect.has_point(get_global_mouse_position()):
		return
	clicked.emit(self)
	get_viewport().set_input_as_handled()
