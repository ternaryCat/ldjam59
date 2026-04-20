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
		"base_cost": 200,
		"label": "Mortar",
	},
	"mage": {
		"scene": preload("res://components/level/mage.tscn"),
		"base_cost": 120,
		"label": "Mage",
	},
}

const TILE_MULT := {
	0: 1.0,
	1: 1.25,
	2: 1.5,
}

const WAVE_COUNTS: Array[int] = [10, 30, 60, 100, 300]
const WAVE_REWARDS: Array[int] = [160, 200, 280, 360]

@export var starting_money: int = 120

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
var _upgrade_target: Node2D = null

@onready var _build_grid: Node2D = $build_grid
@onready var _hud: CanvasLayer = $hud
@onready var _spawners: Node2D = $enemies
@onready var _towers: Node2D = $towers


func _ready() -> void:
	GameSettings.load_and_apply()
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
	if _upgrade_target != null:
		_confirm_upgrade()
		return
	if _preview_tower == null:
		return
	var cost := _tower_cost(_preview_tower_id, _preview_tile)
	if _money < cost:
		return
	_money -= cost
	_preview_tile.mark_occupied()
	_preview_tower.process_mode = Node.PROCESS_MODE_INHERIT
	_connect_tower_click(_preview_tower)
	_clear_preview_indicator()
	_preview_tower = null
	_preview_tower_id = ""
	_preview_tile = null
	_deselect()
	_hud.set_money(_money)


func _on_cancel_requested() -> void:
	if _upgrade_target != null:
		_cancel_upgrade()
		return
	_clear_preview(true)
	_refresh_picker()


func _on_tower_clicked(tower: Node2D) -> void:
	if _phase != Phase.BUILD:
		return
	if _preview_tower != null or _upgrade_target != null:
		return
	if _selected_tile != null:
		_deselect()
	if not tower.has_method("can_upgrade") or not tower.can_upgrade():
		return
	_start_upgrade_preview(tower)


func _start_upgrade_preview(tower: Node2D) -> void:
	var spec: Dictionary = tower.get_upgrade_spec()
	if spec.is_empty():
		return
	var cost: int = spec.get("cost", 0)
	_upgrade_target = tower
	var ind: Node2D = RANGE_INDICATOR_SCENE.instantiate()
	ind.max_radius = spec.get("range", 0.0)
	ind.min_radius = spec.get("min_range", 0.0)
	var attach: Node = tower.get_node_or_null("vision")
	if attach == null:
		attach = tower
	attach.add_child(ind)
	ind.position = Vector2.ZERO
	_preview_indicator = ind
	var current_spec: Dictionary = tower.get_spec()
	var title := "Upgrade Lv. %d" % int(spec.get("level", tower.current_level() + 1))
	_hud.show_upgrade(title, _upgrade_stats(current_spec, spec), cost, _money >= cost)


func _confirm_upgrade() -> void:
	var tower := _upgrade_target
	if tower == null or not is_instance_valid(tower):
		_cancel_upgrade()
		return
	if not tower.can_upgrade():
		_cancel_upgrade()
		return
	var cost: int = tower.get_upgrade_cost()
	if _money < cost:
		return
	_money -= cost
	tower.apply_upgrade()
	_clear_preview_indicator()
	_upgrade_target = null
	_hud.set_money(_money)
	_hud.hide_picker()
	_hud.hide_confirm()


func _cancel_upgrade() -> void:
	_clear_preview_indicator()
	_upgrade_target = null
	_hud.hide_picker()
	_hud.hide_confirm()


func _connect_tower_click(tower: Node2D) -> void:
	if tower.has_signal("clicked") and not tower.is_connected("clicked", _on_tower_clicked):
		tower.connect("clicked", _on_tower_clicked)


func _upgrade_stats(current: Dictionary, next: Dictionary) -> Array:
	var stats: Array = []
	stats.append({"key": "Range", "value": _delta_text(current.get("range", 0.0), next.get("range", 0.0))})
	if next.get("min_range", 0.0) > 0.0 or current.get("min_range", 0.0) > 0.0:
		stats.append({"key": "Min", "value": _delta_text(current.get("min_range", 0.0), next.get("min_range", 0.0))})
	var cur_reload: float = current.get("reload", 0.0)
	var next_reload: float = next.get("reload", 0.0)
	var cur_rate: float = 1.0 / cur_reload if cur_reload > 0.0 else 0.0
	var next_rate: float = 1.0 / next_reload if next_reload > 0.0 else 0.0
	stats.append({"key": "Rate", "value": "%.1f → %.1f/s" % [cur_rate, next_rate]})
	var dmg_label: String = next.get("damage_label", "Damage")
	stats.append({"key": dmg_label, "value": "%d → %d" % [int(current.get("damage", 0)), int(next.get("damage", 0))]})
	if next.has("pierce"):
		stats.append({"key": "Pierce", "value": "%d → %d" % [int(current.get("pierce", 1)), int(next.get("pierce", 1))]})
	if next.has("splash_radius"):
		stats.append({"key": "Splash", "value": _delta_text(current.get("splash_radius", 0.0), next.get("splash_radius", 0.0))})
	if next.has("slow_factor"):
		var cur_slow: float = 1.0 - float(current.get("slow_factor", 1.0))
		var next_slow: float = 1.0 - float(next.get("slow_factor", 1.0))
		stats.append({"key": "Slow", "value": "%d%% → %d%%" % [int(round(cur_slow * 100.0)), int(round(next_slow * 100.0))]})
	if next.has("bolt_count"):
		stats.append({"key": "Bolts", "value": "%d → %d" % [int(current.get("bolt_count", 1)), int(next.get("bolt_count", 1))]})
	return stats


func _delta_text(a: float, b: float) -> String:
	return "%d → %d" % [int(round(a)), int(round(b))]


func _on_building_lost() -> void:
	if not is_inside_tree():
		return
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
	var next_reward: int = WAVE_REWARDS[_wave_index] if _wave_index < WAVE_REWARDS.size() else 0
	_hud.set_next_wave(next_count, next_reward)


func _enter_wave() -> void:
	_phase = Phase.WAVE
	_wave_index += 1
	_active_spawners = 0
	_clear_preview(true)
	if _upgrade_target != null:
		_cancel_upgrade()
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
		spawner_list[i].start_wave(c, _wave_index - 1)
		_active_spawners += 1
	_hud.show_wave(_wave_index, total_waves)


func _finish_wave() -> void:
	var idx: int = _wave_index - 1
	if idx >= 0 and idx < WAVE_REWARDS.size():
		_money += WAVE_REWARDS[idx]
	if _wave_index >= total_waves:
		_phase = Phase.VICTORY
		_build_grid.visible = false
		_hud.set_money(_money)
		_hud.show_victory()
		_go_to_scene_after_delay("res://components/victory.tscn", 1.5)
		return
	_enter_build()


func _enter_defeat() -> void:
	_phase = Phase.DEFEAT
	_clear_preview(true)
	if _upgrade_target != null:
		_cancel_upgrade()
	_deselect()
	_build_grid.visible = false
	for spawner in _spawners.get_children():
		if spawner.has_method("set_enabled"):
			spawner.set_enabled(false)
	_hud.show_defeat()
	_go_to_scene_after_delay("res://components/defeat.tscn", 1.5)


func _go_to_scene_after_delay(path: String, delay: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(delay).timeout
	tree = get_tree()
	if tree != null:
		tree.change_scene_to_file(path)
