class_name GameSettings
extends RefCounted

const CONFIG_PATH: String = "user://settings.cfg"
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const DEFAULTS := {
	BUS_MASTER: 0.8,
	BUS_MUSIC: 0.8,
	BUS_SFX: 0.8,
}


static func load_and_apply() -> Dictionary:
	var volumes: Dictionary = {}
	for key in DEFAULTS:
		volumes[key] = DEFAULTS[key]
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		for key in volumes:
			volumes[key] = float(cfg.get_value("audio", key.to_lower(), volumes[key]))
	apply(volumes)
	return volumes


static func apply(volumes: Dictionary) -> void:
	for bus_name in volumes:
		set_bus_volume(bus_name, float(volumes[bus_name]))


static func save(volumes: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for bus_name in volumes:
		cfg.set_value("audio", bus_name.to_lower(), float(volumes[bus_name]))
	cfg.save(CONFIG_PATH)


static func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, linear <= 0.0001)
	if linear > 0.0001:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
