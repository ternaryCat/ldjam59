extends Node2D

const BUILDING_SCENE: PackedScene = preload("res://components/level/building.tscn")
const SPAWNER_SCENE: PackedScene = preload("res://components/level/spawner.tscn")
const TOWER_SCENE: PackedScene = preload("res://components/level/tower.tscn")
const PLAYER_SCENE: PackedScene = preload("res://components/level/player.tscn")
const BUILD_TILE_SCENE: PackedScene = preload("res://components/level/build_tile.tscn")

const SLIDES := [
	{
		"title": "Defend the town",
		"text": "Monsters rush at your buildings. Let them wreck everything and you lose.",
	},
	{
		"title": "Build towers",
		"text": "Towers shoot enemies on their own. Ballista, mortar and mage each have their own attack.",
	},
	{
		"title": "Pull the horde",
		"text": "Hold SPACE to switch on your signal field. Enemies chase you — drag them right under your towers.",
	},
	{
		"title": "Pick your ground",
		"text": "Different cells cost different money. Green is cheap, red is expensive.",
	},
	{
		"title": "Upgrade",
		"text": "Between waves spend gold to level up towers: more damage, longer range, faster fire.",
	},
]

const GROUND_Y: float = 210.0

@onready var _title: Label = $ui/center/vbox/title
@onready var _desc: Label = $ui/center/vbox/description
@onready var _stage: Node2D = $ui/center/vbox/viewport_container/viewport/stage
@onready var _prev: Button = $ui/prev
@onready var _next: Button = $ui/next
@onready var _skip: Button = $ui/skip
@onready var _dots: HBoxContainer = $ui/dots

var _index: int = 0
var _slide_builders: Array[Callable] = []


func _ready() -> void:
	_slide_builders = [
		_build_attack,
		_build_towers,
		_build_pull,
		_build_tiles,
		_build_upgrade,
	]
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_skip.pressed.connect(_start_game)
	_build_dots()
	_show(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"):
		_on_prev()
	elif event.is_action_pressed("right"):
		_on_next()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_start_game()


func _exit_tree() -> void:
	Input.action_release("activate")


func _build_dots() -> void:
	for i in SLIDES.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		_dots.add_child(dot)


func _show(i: int) -> void:
	_index = clampi(i, 0, SLIDES.size() - 1)
	var slide: Dictionary = SLIDES[_index]
	_title.text = slide["title"]
	_desc.text = slide["text"]
	_prev.disabled = _index == 0
	_next.text = "Play" if _index == SLIDES.size() - 1 else "→"
	for j in _dots.get_child_count():
		var dot := _dots.get_child(j) as ColorRect
		dot.color = Color(0.9, 0.9, 0.95) if j == _index else Color(0.3, 0.3, 0.35)
	Input.action_release("activate")
	_clear_stage()
	_slide_builders[_index].call()


func _clear_stage() -> void:
	for child in _stage.get_children():
		child.queue_free()


func _on_prev() -> void:
	if _index > 0:
		_show(_index - 1)


func _on_next() -> void:
	if _index < SLIDES.size() - 1:
		_show(_index + 1)
	else:
		_start_game()


func _start_game() -> void:
	Input.action_release("activate")
	get_tree().change_scene_to_file("res://components/level2.tscn")


# --- Diorama helpers ---

func _make_building(pos: Vector2, roof: Color, hp: int = 999999) -> Node2D:
	var b := BUILDING_SCENE.instantiate()
	b.max_hp = hp
	b.roof_color = roof
	b.position = pos
	_stage.add_child(b)
	return b


func _make_spawner(pos: Vector2, interval: float, batch: int, count: int = 12) -> Node2D:
	var s := SPAWNER_SCENE.instantiate()
	s.spawn_interval = interval
	s.batch_size = batch
	s.max_spawns = count
	s.auto_start = true
	s.position = pos
	_stage.add_child(s)
	s.connect("finished", Callable(self, "_on_wave_finished").bind(s, count))
	return s


func _on_wave_finished(s: Node, count: int) -> void:
	if not is_instance_valid(s) or not is_inside_tree():
		return
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(s) or not is_inside_tree():
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	s.call("start_wave", count)


func _make_tower(pos: Vector2, vision_radius: float) -> Node2D:
	var t := TOWER_SCENE.instantiate()
	t.position = pos
	_stage.add_child(t)
	var shape_node := t.get_node_or_null("vision/shape") as CollisionShape2D
	if shape_node != null:
		var circle := CircleShape2D.new()
		circle.radius = vision_radius
		shape_node.shape = circle
	return t


func _make_pet_player(pos: Vector2) -> CharacterBody2D:
	var p := PLAYER_SCENE.instantiate() as CharacterBody2D
	p.set_physics_process(false)
	var cam := p.get_node_or_null("camera")
	if cam:
		p.remove_child(cam)
		cam.free()
	var sig := p.get_node_or_null("signal_area") as Area2D
	if sig:
		var sig_shape := sig.get_node_or_null("shape") as CollisionShape2D
		if sig_shape:
			var circle := CircleShape2D.new()
			circle.radius = 120.0
			sig_shape.shape = circle
	p.position = pos
	_stage.add_child(p)
	if sig:
		sig.set_physics_process(false)
		sig.monitoring = true
		sig.visible = true
		sig.queue_redraw()
	var sprite := p.get_node_or_null("sprite") as AnimatedSprite2D
	if sprite:
		sprite.play("walk")
	return p


# --- Slide 1: enemies attack ---

func _build_attack() -> void:
	_make_building(Vector2(560, GROUND_Y), Color(0.9, 0.4, 0.3))
	_make_building(Vector2(660, GROUND_Y - 30), Color(0.4, 0.7, 0.9))
	_make_spawner(Vector2(60, GROUND_Y), 0.9, 1)


# --- Slide 2: towers shoot enemies ---

func _build_towers() -> void:
	_make_building(Vector2(660, GROUND_Y), Color(0.9, 0.4, 0.3))
	_make_tower(Vector2(420, GROUND_Y + 10), 220.0)
	_make_spawner(Vector2(60, GROUND_Y), 1.2, 1)


# --- Slide 3: lure with signal field ---

func _build_pull() -> void:
	_make_building(Vector2(680, GROUND_Y), Color(0.9, 0.4, 0.3))
	_make_tower(Vector2(520, GROUND_Y + 10), 180.0)
	var player := _make_pet_player(Vector2(360, GROUND_Y))
	_make_spawner(Vector2(60, GROUND_Y), 1.0, 1)
	_animate_pet_player(player)
	Input.action_press("activate")


func _animate_pet_player(player: CharacterBody2D) -> void:
	var sprite := player.get_node_or_null("sprite") as AnimatedSprite2D
	var points := [
		Vector2(440, GROUND_Y - 30),
		Vector2(440, GROUND_Y + 30),
		Vector2(280, GROUND_Y + 30),
		Vector2(280, GROUND_Y - 30),
	]
	var tween := player.create_tween().set_loops()
	var prev: Vector2 = player.position
	for pt in points:
		var target: Vector2 = pt
		var delta_vec: Vector2 = target - prev
		var duration: float = maxf(delta_vec.length() / 110.0, 0.4)
		if sprite != null and delta_vec.x != 0.0:
			tween.tween_callback(Callable(self, "_flip_sprite").bind(sprite, delta_vec.x < 0.0))
		tween.tween_property(player, "position", target, duration)
		prev = target


func _flip_sprite(sprite: AnimatedSprite2D, flip: bool) -> void:
	if is_instance_valid(sprite):
		sprite.flip_h = flip


# --- Slide 4: build tiles & cost ---

func _build_tiles() -> void:
	var configs := [
		{"color": 0, "label": "$50",  "x": 220.0},
		{"color": 1, "label": "$100", "x": 380.0},
		{"color": 2, "label": "$200", "x": 540.0},
	]
	var tiles: Array = []
	for cfg in configs:
		var tile := BUILD_TILE_SCENE.instantiate()
		tile.tile_color = int(cfg["color"])
		tile.position = Vector2(float(cfg["x"]), GROUND_Y + 10.0)
		_stage.add_child(tile)
		tiles.append(tile)
		var label := Label.new()
		label.text = String(cfg["label"])
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.position = Vector2(float(cfg["x"]) - 40.0, GROUND_Y - 80.0)
		label.custom_minimum_size = Vector2(80, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(80, 0)
		_stage.add_child(label)
	var idx_ref: Array[int] = [0]
	var cycle_timer := Timer.new()
	cycle_timer.wait_time = 1.0
	cycle_timer.autostart = true
	_stage.add_child(cycle_timer)
	var cycle_tiles := func() -> void:
		for k in tiles.size():
			var tile: Node = tiles[k] as Node
			if is_instance_valid(tile):
				tile.call("set_selected", k == idx_ref[0])
		idx_ref[0] = (idx_ref[0] + 1) % tiles.size()
	cycle_timer.timeout.connect(cycle_tiles)
	cycle_tiles.call()


# --- Slide 5: tower upgrade ---

func _build_upgrade() -> void:
	_make_building(Vector2(660, GROUND_Y), Color(0.9, 0.4, 0.3))
	_make_spawner(Vector2(60, GROUND_Y), 1.0, 1)
	_spawn_upgradeable_tower()


func _spawn_upgradeable_tower() -> void:
	var tower := _make_tower(Vector2(420, GROUND_Y + 10), 240.0)
	var label := Label.new()
	label.text = "Level 1"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	label.position = Vector2(360, GROUND_Y - 130)
	label.custom_minimum_size = Vector2(120, 0)
	label.size = Vector2(120, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(label)
	var cycle := Timer.new()
	cycle.wait_time = 2.5
	cycle.autostart = true
	_stage.add_child(cycle)
	var on_tick := func() -> void:
		if not is_instance_valid(tower) or not is_instance_valid(label) or not is_instance_valid(cycle):
			return
		if tower.call("can_upgrade"):
			tower.call("apply_upgrade")
			label.text = "Level %d" % (int(tower.call("current_level")) + 1)
		else:
			tower.queue_free()
			label.queue_free()
			cycle.queue_free()
			call_deferred("_spawn_upgradeable_tower")
	cycle.timeout.connect(on_tick)
