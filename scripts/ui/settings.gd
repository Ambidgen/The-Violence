extends RefCounted
## Player settings (1.0), kept in user://settings.cfg and applied at launch: the window,
## the three volume buses, the presentation toggles (red ink, gore), the operation speed
## the run starts at, and whether the first-weeks tips are shown.
##
## Static, so the title screen, the pause menu and main all read the same values.

const PATH := "user://settings.cfg"
const SPEEDS := [0.5, 1.0, 2.0, 5.0, 10.0]
const DEFAULTS := {"fullscreen": false, "master": 0.8, "effects": 0.9, "ambience": 0.5,
	"red_ink": true, "gore": true, "speed": 2.0, "tips": true, "seen_manual": false}

static var data := DEFAULTS.duplicate()
static var _loaded := false


## 1.0 renamed the project from "The Violence - Vertical Slice", which moves Godot's
## user folder; the first launch copies the old saves and settings across.
const OLD_DIR := "The Violence - Vertical Slice"
const CARRY := ["campaign.json", "campaign.json.bak", "department.json", "department.json.bak", "settings.cfg"]


static func migrate() -> void:
	var here := ProjectSettings.globalize_path("user://")
	var old := here.trim_suffix("/").get_base_dir().path_join(OLD_DIR)
	if not DirAccess.dir_exists_absolute(old) or old == here.trim_suffix("/"):
		return
	for f in CARRY:
		if FileAccess.file_exists(old.path_join(f)) and not FileAccess.file_exists("user://" + f):
			DirAccess.copy_absolute(old.path_join(f), here.path_join(f))


static func load_all() -> void:
	migrate()
	data = DEFAULTS.duplicate()
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		for k in DEFAULTS:
			data[k] = cf.get_value("settings", k, DEFAULTS[k])
	_loaded = true


static func save_all() -> void:
	var cf := ConfigFile.new()
	for k in data:
		cf.set_value("settings", k, data[k])
	cf.save(PATH)


static func get_v(k: String):
	if not _loaded:
		load_all()
	return data.get(k, DEFAULTS.get(k))


static func set_v(k: String, v) -> void:
	if not _loaded:
		load_all()
	data[k] = v
	save_all()
	apply()


## The audio buses the game plays through: Effects (shots, doors, bangs, radio) and
## Ambience (the city under everything), both into Master.
static func ensure_buses() -> void:
	for b in ["Effects", "Ambience"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")


static func _db(v: float) -> float:
	return linear_to_db(maxf(0.0001, v))


static func apply() -> void:
	if not _loaded:
		load_all()
	ensure_buses()
	AudioServer.set_bus_volume_db(0, _db(float(data["master"])))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), _db(float(data["effects"])))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), _db(float(data["ambience"])))
	var Ink = load("res://scripts/view/ink.gd")
	if Ink.red_ink_enabled != bool(data["red_ink"]):
		Ink.set_red_ink(bool(data["red_ink"]))
	if Ink.gore_enabled != bool(data["gore"]):
		Ink.set_gore(bool(data["gore"]))
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(data["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
