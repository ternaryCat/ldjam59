extends Node2D

enum Phase { BUILD, WAVE, VICTORY, DEFEAT }

const RANGE_INDICATOR_SCENE: PackedScene = preload("res://components/level/range_indicator.tscn")

const TOWERS := {
	"ballista": {
		"scene": preload("res://components/level/tower.tscn"),
		"base_cost": 80,
		"label": "Ballista",
	},
	"mortar": {
		"scene": preload("res://components/level/mortar.tscn"),
		"base_cost": 180,
		"label": "Mortar",
	},
	"mage": {
		"scene": preload("res://components/level/mage.tscn"),
		"base_cost": 150,
		"label": "Mage",
	},
}

const TILE_MULT := {
	0: 1.0,
	1: 1.25,
	2: 1.5,
}

const WAVE_COUNTS: Array[int] = [10, 30, 60, 100, 300]

@export var starting_money: int = 300
@export var wave_reward: int = 150

var total_waves: int = WAVE_COUNTS.size()

var _money: int
var _phase: Phase = Phase.BUILD
var _wave_index: int = 0
var _active_spawners: int = 0
var _selected_tile: Node = null
var _buildings_remaining: int = 0
var _preview_tower: Node2D = null
var _preview_indicator: Node2D = null
var _preview_tower_id: String = ""
var _preview_tile: Node = null
var _tower_specs: Dictionary = {}

@onready var _build_grid: Node2D = $build_grid
@onready var _hud: CanvasLayer = $hud
@onready var _spawners: Node2D = $enemies
@onready var _towers: Node2D = $towers


func _ready() -> void:
	_money = starting_money
	for id in TOWERS:
		var probe: Node = TOWERS[id].scene.instantiate()
		_tower_specs[id] = probe.get_spec()
		probe.free()
	_build_grid.tile_clicked.connect(_on_tile_clicked)
	_hud.wave_requested.connect(_on_wave_requested)
	_hud.tower_requested.connect(_on_tower_requested)
	_hud.confirm_requested.connect(_on_confirm_requested)
	_hud.cancel_requested.connect(_on_cancel_requested)
	for spawner in _spawners.get_children():
		if spawner.has_signal("finished"):
			spawner.finished.connect(_on_spawner_finished)
	var buildings := get_tree().get_nodes_in_group("buildings")
	_buildings_remaining = buildings.size()
	for b in buildings:
		b.tree_exited.connect(_on_building_lost)
	_hud.set_buildings(buildings)
	_enter_build()


func _process(_delta: float) -> void:
	if _phase != Phase.WAVE:
		return
	if _active_spawners > 0:
		return
	if not get_tree().get_nodes_in_group("enemies").is_empty():
		return
	_finish_wave()


func _on_tile_clicked(tile: Node) -> void:
	if _phase != Phase.BUILD or tile.occupied:
		return
	if _preview_tower != null:
		return
	if _selected_tile == tile:
		_deselect()
		return
	_select(tile)


func _on_wave_requested() -> void:
	if _phase == Phase.BUILD:
		_enter_wave()


func _on_spawner_finished() -> void:
	_active_spawners -= 1


func _on_tower_requested(tower_id: String) -> void:
	if _phase != Phase.BUILD or _selected_tile == null:
		return
	if _preview_tower != null:
		return
	if not TOWERS.has(tower_id):
		return
	_start_preview(tower_id, _selected_tile)


func _on_confirm_requested() -> void:
	if _preview_tower == null:
		return
	var cost := _tower_cost(_preview_tower_id, _preview_tile)
	if _money < cost:
		return
	_money -= cost
	_preview_tile.mark_occupied()
	_preview_tower.process_mode = Node.PROCESS_MODE_INHERIT
	_clear_preview_indicator()
	_preview_tower = null
	_preview_tower_id = ""
	_preview_tile = null
	_deselect()
	_hud.set_money(_money)


func _on_cancel_requested() -> void:
	_clear_preview(true)
	_refresh_picker()


func _on_building_lost() -> void:
	_buildings_remaining -= 1
	if _buildings_remaining <= 0 and _phase != Phase.DEFEAT and _phase != Phase.VICTORY:
		_enter_defeat()


func _start_preview(tower_id: String, tile: Node) -> void:
	var scene: PackedScene = TOWERS[tower_id].scene
	var tower: Node2D = scene.instantiate()
	_towers.add_child(tower)
	tower.global_position = tile.global_position
	tower.process_mode = Node.PROCESS_MODE_DISABLED
	_preview_tower = tower
	_preview_tower_id = tower_id
	_preview_tile = tile
	var spec: Dictionary = _tower_specs[tower_id]
	var ind: Node2D = RANGE_INDICATOR_SCENE.instantiate()
	ind.max_radius = spec.range
	ind.min_radius = spec.min_range
	var attach: Node = tower.get_node_or_null("vision")
	if attach == null:
		attach = tower
	attach.add_child(ind)
	ind.position = Vector2.ZERO
	_preview_indicator = ind
	var cost := _tower_cost(tower_id, tile)
	_hud.show_confirm(cost, _money >= cost)


func _clear_preview(free_tower: bool) -> void:
	if free_tower and _preview_tower and is_instance_valid(_preview_tower):
		_preview_tower.queue_free()
	_clear_preview_indicator()
	_preview_tower = null
	_preview_tower_id = ""
	_preview_tile = null


func _clear_preview_indicator() -> void:
	if _preview_indicator and is_instance_valid(_preview_indicator):
		_preview_indicator.queue_free()
	_preview_indicator = null


func _tower_cost(tower_id: String, tile: Node) -> int:
	var base: int = TOWERS[tower_id].base_cost
	var mult: float = TILE_MULT.get(tile.tile_color, 1.0)
	return int(round(base * mult))


func _tower_stats(tower_id: String) -> Array:
	var stats: Array = []
	var spec: Dictionary = _tower_specs[tower_id]
	stats.append({"key": "Range", "value": str(int(spec.range))})
	if spec.min_range > 0.0:
		stats.append({"key": "Min", "value": str(int(spec.min_range))})
	var reload: float = spec.reload
	var rate: float = 0.0
	if reload > 0.0:
		rate = 1.0 / reload
	stats.append({"key": "Rate", "value": "%.1f/s" % rate})
	stats.append({"key": spec.damage_label, "value": str(spec.damage)})
	return stats


func _select(tile: Node) -> void:
	if _selected_tile and is_instance_valid(_selected_tile):
		_selected_tile.set_selected(false)
	_selected_tile = tile
	tile.set_selected(true)
	_refresh_picker()


func _deselect() -> void:
	if _selected_tile and is_instance_valid(_selected_tile):
		_selected_tile.set_selected(false)
	_selected_tile = null
	_hud.hide_picker()
	_hud.hide_confirm()


func _refresh_picker() -> void:
	if _selected_tile == null:
		_hud.hide_picker()
		return
	var items: Array = []
	for id in TOWERS:
		var cost := _tower_cost(id, _selected_tile)
		items.append({
			"id": id,
			"label": TOWERS[id].label,
			"cost": cost,
			"affordable": _money >= cost,
			"stats": _tower_stats(id),
		})
	_hud.show_picker(items)


func _enter_build() -> void:
	_phase = Phase.BUILD
	for spawner in _spawners.get_children():
		if spawner.has_method("set_enabled"):
			spawner.set_enabled(false)
	_build_grid.visible = true
	_hud.set_money(_money)
	_hud.show_build(_wave_index + 1, total_waves)
	var next_count: int = WAVE_COUNTS[_wave_index] if _wave_index < total_waves else 0
	_hud.set_next_wave(next_count)


func _enter_wave() -> void:
	_phase = Phase.WAVE
	_wave_index += 1
	_active_spawners = 0
	_clear_preview(true)
	_deselect()
	_build_grid.visible = false
	var spawner_list: Array = []
	for s in _spawners.get_children():
		if s.has_method("start_wave"):
			spawner_list.append(s)
	var total_count: int = WAVE_COUNTS[_wave_index - 1]
	var per_spawner: int = 0
	var remainder: int = 0
	if not spawner_list.is_empty():
		per_spawner = total_count / spawner_list.size()
		remainder = total_count - per_spawner * spawner_list.size()
	for i in spawner_list.size():
		var c: int = per_spawner + (1 if i < remainder else 0)
		spawner_list[i].start_wave(c)
		_active_spawners += 1
	_hud.show_wave(_wave_index, total_waves)


func _finish_wave() -> void:
	_money += wave_reward
	if _wave_index >= total_waves:
		_phase = Phase.VICTORY
		_build_grid.visible = false
		_hud.set_money(_money)
		_hud.show_victory()
		return
	_enter_build()


func _enter_defeat() -> void:
	_phase = Phase.DEFEAT
	_clear_preview(true)
	_deselect()
	_build_grid.visible = false
	for spawner in _spawners.get_children():
		if spawner.has_method("set_enabled"):
			spawner.set_enabled(false)
	_hud.show_defeat()
