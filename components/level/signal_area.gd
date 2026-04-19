extends Area2D

const SIGNAL_SFX: AudioStream = preload("res://images/dydka_blyat.wav")

@export var fill_color: Color = Color(1, 1, 1, 0.18)
@export var outline_color: Color = Color(1, 1, 1, 0.5)
@export var outline_width: float = 2.0
@export var volume_db: float = 0.0

@onready var _shape: CollisionShape2D = $shape

var _sfx: AudioStreamPlayer


func _ready() -> void:
	add_to_group("signal_field")
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = SIGNAL_SFX
	_sfx.volume_db = volume_db
	_sfx.finished.connect(_on_sfx_finished)
	add_child(_sfx)
	print("[signal_area] sfx stream=", SIGNAL_SFX, " class=", SIGNAL_SFX.get_class() if SIGNAL_SFX else "null")
	_set_active(false)


func _physics_process(_delta: float) -> void:
	var should_be_active := Input.is_action_pressed("activate")
	if should_be_active != monitoring:
		_set_active(should_be_active)


func _set_active(active: bool) -> void:
	visible = active
	monitoring = active
	if _sfx == null:
		return
	if active:
		if not _sfx.playing:
			_sfx.play()
			print("[signal_area] sfx.play() called, playing=", _sfx.playing)
	else:
		_sfx.stop()


func _on_sfx_finished() -> void:
	if monitoring and _sfx:
		_sfx.play()


func _draw() -> void:
	var s := _shape.shape
	if s is CircleShape2D:
		var r := (s as CircleShape2D).radius
		draw_circle(_shape.position, r, fill_color)
		draw_arc(_shape.position, r, 0.0, TAU, 64, outline_color, outline_width)
