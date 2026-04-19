extends CanvasLayer

signal wave_requested
signal tower_requested(tower_id: String)
signal confirm_requested
signal cancel_requested

const COIN_ICON: Texture2D = preload("res://images/coin.png")
const STAT_ICONS: Dictionary = {
	"Range": preload("res://images/range.png"),
	"Min": preload("res://images/min_range.png"),
	"Rate": preload("res://images/rate.png"),
	"Damage": preload("res://images/atack.png"),
	"Splash": preload("res://images/splash.png"),
	"Pierce": preload("res://images/missles.png"),
	"Splash r.": preload("res://images/splash.png"),
	"Bolts": preload("res://images/missles.png"),
	"Slow": preload("res://images/slow.png"),
}

@onready var _money_label: Label = $root/money
@onready var _phase_label: Label = $root/phase
@onready var _start_button: Button = $root/start_wave
@onready var _picker: PanelContainer = $root/picker
@onready var _picker_row: HBoxContainer = $root/picker/row
@onready var _confirm_panel: PanelContainer = $root/confirm
@onready var _confirm_button: Button = $root/confirm/row/confirm_btn
@onready var _cancel_button: Button = $root/confirm/row/cancel_btn
@onready var _buildings_panel: VBoxContainer = $root/buildings_panel
@onready var _wave_preview: PanelContainer = $root/wave_preview

var _in_build: bool = false
var _has_next_wave: bool = false


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_confirm_button.pressed.connect(func() -> void: confirm_requested.emit())
	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	_picker.visible = false
	_confirm_panel.visible = false
	_wave_preview.visible = false


func set_money(value: int) -> void:
	_money_label.text = "$%d" % value


func show_build(next_wave: int, total: int) -> void:
	_in_build = true
	_phase_label.text = "Build — next: wave %d / %d" % [next_wave, total]
	_start_button.disabled = false
	_refresh_bottom()


func show_wave(wave: int, total: int) -> void:
	_in_build = false
	_phase_label.text = "Wave %d / %d" % [wave, total]
	_picker.visible = false
	_confirm_panel.visible = false
	_refresh_bottom()


func show_victory() -> void:
	_in_build = false
	_phase_label.text = "Victory!"
	_picker.visible = false
	_confirm_panel.visible = false
	_refresh_bottom()


func show_defeat() -> void:
	_in_build = false
	_phase_label.text = "Defeat"
	_picker.visible = false
	_confirm_panel.visible = false
	_refresh_bottom()


func show_picker(items: Array) -> void:
	_picker.offset_top = -200.0
	_picker.offset_bottom = -20.0
	for child in _picker_row.get_children():
		child.queue_free()
	for item in items:
		_picker_row.add_child(_build_card(item))
	_picker.visible = true
	_confirm_panel.visible = false
	_refresh_bottom()


func hide_picker() -> void:
	_picker.visible = false
	_refresh_bottom()


func show_confirm(cost: int, affordable: bool) -> void:
	_confirm_button.text = "Confirm ($%d)" % cost
	_confirm_button.disabled = not affordable
	_confirm_panel.visible = true
	_picker.visible = false
	_refresh_bottom()


func show_upgrade(title: String, stats: Array, cost: int, affordable: bool) -> void:
	_picker.offset_top = -300.0
	_picker.offset_bottom = -90.0
	for child in _picker_row.get_children():
		child.queue_free()
	_picker_row.add_child(_build_upgrade_card({
		"id": "upgrade",
		"label": title,
		"cost": cost,
		"affordable": affordable,
		"stats": stats,
	}))
	_picker.visible = true
	_confirm_button.text = "Confirm ($%d)" % cost
	_confirm_button.disabled = not affordable
	_confirm_panel.visible = true
	_refresh_bottom()


func _build_upgrade_card(item: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(220, 0)
	var name_lbl := Label.new()
	name_lbl.text = item.get("label", "")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)
	card.add_child(_stat_row(COIN_ICON, "Cost", "$%d" % int(item.get("cost", 0))))
	for stat in item.get("stats", []):
		var key: String = stat.get("key", "")
		var value: String = str(stat.get("value", ""))
		card.add_child(_stat_row(STAT_ICONS.get(key, null), key, value))
	return card


func hide_confirm() -> void:
	_confirm_panel.visible = false
	_refresh_bottom()


func set_buildings(buildings: Array) -> void:
	_buildings_panel.set_buildings(buildings)


func set_next_wave(count: int, reward: int = 0) -> void:
	_has_next_wave = count > 0
	if _has_next_wave:
		_wave_preview.set_count(count)
		_wave_preview.set_reward(reward)
	_refresh_bottom()


func _refresh_bottom() -> void:
	var bottom_free := _in_build and not _picker.visible and not _confirm_panel.visible
	_start_button.visible = bottom_free
	_wave_preview.visible = bottom_free and _has_next_wave


func _build_card(item: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(160, 0)
	var name_lbl := Label.new()
	name_lbl.text = item.get("label", "")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)
	card.add_child(_stat_row(COIN_ICON, "Cost", "$%d" % int(item.get("cost", 0))))
	for stat in item.get("stats", []):
		var key: String = stat.get("key", "")
		var value: String = str(stat.get("value", ""))
		card.add_child(_stat_row(STAT_ICONS.get(key, null), key, value))
	var btn := Button.new()
	btn.text = "Build"
	btn.disabled = not item.get("affordable", false)
	var id: String = item.get("id", "")
	btn.pressed.connect(func() -> void: tower_requested.emit(id))
	card.add_child(btn)
	return card


func _stat_row(icon: Texture2D, label: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(20, 20)
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon:
		tex.texture = icon
	row.add_child(tex)
	var lbl := Label.new()
	lbl.text = "%s: %s" % [label, value]
	row.add_child(lbl)
	return row


func _on_start_pressed() -> void:
	wave_requested.emit()
