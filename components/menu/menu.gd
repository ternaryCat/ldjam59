extends Node2D

const SETTINGS_SCRIPT := preload("res://components/settings.gd")

@onready var _settings_overlay: Control = $ui/settings_overlay
@onready var _master_slider: HSlider = $ui/settings_overlay/center/panel/margin/vbox/master_row/slider
@onready var _music_slider: HSlider = $ui/settings_overlay/center/panel/margin/vbox/music_row/slider
@onready var _sfx_slider: HSlider = $ui/settings_overlay/center/panel/margin/vbox/sfx_row/slider
@onready var _master_value: Label = $ui/settings_overlay/center/panel/margin/vbox/master_row/value
@onready var _music_value: Label = $ui/settings_overlay/center/panel/margin/vbox/music_row/value
@onready var _sfx_value: Label = $ui/settings_overlay/center/panel/margin/vbox/sfx_row/value
@onready var _close_button: Button = $ui/settings_overlay/center/panel/margin/vbox/close

var _volumes: Dictionary


func _ready() -> void:
	_volumes = SETTINGS_SCRIPT.load_and_apply()
	_master_slider.value = _volumes[SETTINGS_SCRIPT.BUS_MASTER]
	_music_slider.value = _volumes[SETTINGS_SCRIPT.BUS_MUSIC]
	_sfx_slider.value = _volumes[SETTINGS_SCRIPT.BUS_SFX]
	_update_labels()
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_close_button.pressed.connect(_on_settings_close)
	_settings_overlay.visible = false


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://components/tutorial.tscn")


func _on_settings_pressed() -> void:
	_settings_overlay.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_master_changed(value: float) -> void:
	_volumes[SETTINGS_SCRIPT.BUS_MASTER] = value
	SETTINGS_SCRIPT.set_bus_volume(SETTINGS_SCRIPT.BUS_MASTER, value)
	_update_labels()


func _on_music_changed(value: float) -> void:
	_volumes[SETTINGS_SCRIPT.BUS_MUSIC] = value
	SETTINGS_SCRIPT.set_bus_volume(SETTINGS_SCRIPT.BUS_MUSIC, value)
	_update_labels()


func _on_sfx_changed(value: float) -> void:
	_volumes[SETTINGS_SCRIPT.BUS_SFX] = value
	SETTINGS_SCRIPT.set_bus_volume(SETTINGS_SCRIPT.BUS_SFX, value)
	_update_labels()


func _update_labels() -> void:
	_master_value.text = "%d%%" % int(round(float(_volumes[SETTINGS_SCRIPT.BUS_MASTER]) * 100.0))
	_music_value.text = "%d%%" % int(round(float(_volumes[SETTINGS_SCRIPT.BUS_MUSIC]) * 100.0))
	_sfx_value.text = "%d%%" % int(round(float(_volumes[SETTINGS_SCRIPT.BUS_SFX]) * 100.0))


func _on_settings_close() -> void:
	SETTINGS_SCRIPT.save(_volumes)
	_settings_overlay.visible = false
