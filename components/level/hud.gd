extends CanvasLayer

signal wave_requested
signal tower_requested(tower_id: String)
signal confirm_requested
signal cancel_requested

@onready var _money_label: Label = $root/money
@onready var _phase_label: Label = $root/phase
@onready var _start_button: Button = $root/start_wave
@onready var _picker: PanelContainer = $root/picker
@onready var _picker_row: HBoxContainer = $root/picker/row
@onready var _confirm_panel: PanelContainer = $root/confirm
@onready var _confirm_button: Button = $root/confirm/row/confirm_btn
@onready var _cancel_button: Button = $root/confirm/row/cancel_btn

var _in_build: bool = false


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_confirm_button.pressed.connect(func() -> void: confirm_requested.emit())
	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	_picker.visible = false
	_confirm_panel.visible = false


func set_money(value: int) -> void:
	_money_label.text = "$%d" % value


func show_build(next_wave: int, total: int) -> void:
	_in_build = true
	_phase_label.text = "Build — next: wave %d / %d" % [next_wave, total]
	if not _picker.visible and not _confirm_panel.visible:
		_start_button.visible = true
	_start_button.disabled = false


func show_wave(wave: int, total: int) -> void:
	_in_build = false
	_phase_label.text = "Wave %d / %d" % [wave, total]
	_start_button.visible = false
	_picker.visible = false
	_confirm_panel.visible = false


func show_victory() -> void:
	_in_build = false
	_phase_label.text = "Victory!"
	_start_button.visible = false
	_picker.visible = false
	_confirm_panel.visible = false


func show_defeat() -> void:
	_in_build = false
	_phase_label.text = "Defeat"
	_start_button.visible = false
	_picker.visible = false
	_confirm_panel.visible = false


func show_picker(items: Array) -> void:
	for child in _picker_row.get_children():
		child.queue_free()
	for item in items:
		_picker_row.add_child(_build_card(item))
	_picker.visible = true
	_confirm_panel.visible = false
	_start_button.visible = false


func hide_picker() -> void:
	_picker.visible = false
	if _in_build and not _confirm_panel.visible:
		_start_button.visible = true


func show_confirm(cost: int, affordable: bool) -> void:
	_confirm_button.text = "Confirm ($%d)" % cost
	_confirm_button.disabled = not affordable
	_confirm_panel.visible = true
	_picker.visible = false
	_start_button.visible = false


func hide_confirm() -> void:
	_confirm_panel.visible = false
	if _in_build and not _picker.visible:
		_start_button.visible = true


func _build_card(item: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(140, 0)
	var name_lbl := Label.new()
	name_lbl.text = item.get("label", "")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)
	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: $%d" % item.get("cost", 0)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(cost_lbl)
	for stat in item.get("stats", []):
		var s := Label.new()
		s.text = "%s: %s" % [stat.get("key", ""), stat.get("value", "")]
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(s)
	var btn := Button.new()
	btn.text = "Build"
	btn.disabled = not item.get("affordable", false)
	var id: String = item.get("id", "")
	btn.pressed.connect(func() -> void: tower_requested.emit(id))
	card.add_child(btn)
	return card


func _on_start_pressed() -> void:
	wave_requested.emit()
