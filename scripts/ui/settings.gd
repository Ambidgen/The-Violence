extends RefCounted
## Player settings (1.0), kept in user://settings.cfg and applied at launch: the window,
## the three volume buses, the presentation toggles (red ink, gore), the operation speed
## the run starts at, and whether the first-weeks tips are shown.
##
## Static, so the title screen, the pause menu and main all read the same values.

const PATH := "user://settings.cfg"
const SPEEDS := [0.5, 1.0, 2.0, 5.0, 10.0]
const DEFAULTS := {"fullscreen": false, "master": 0.8, "effects": 0.9, "ambience": 0.5,
	"red_ink": true, "gore": true, "boil": true, "speed": 2.0, "tips": true, "seen_manual": false, "intro": true,
	"adaptive_speed": true, "veteran": false, "week_recap": true}   # Q4: veteran chief — no Suggest a plan; every squad is the player's own

static var data := DEFAULTS.duplicate()
static var _loaded := false


## 1.0 renamed the project from "The Violence - Vertical Slice", which moves Godot's
## user folder; the first launch copies the old saves and settings across.
const OLD_DIR := "The Violence - Vertical Slice"
## P0.D4 (2026-10-28): the game now writes to a fixed directory, so renaming it can
## never move a save again (and the Steam Cloud path, when it exists, is the same one).
## app_userdata/ holds the folders Godot derived from the project name: "The Violence"
## for the 1.3 candidate and the old slice name before it. Must match
## application/config/custom_user_dir_name in project.godot.
const USER_DIR := "TheViolence"
const CARRY := ["campaign.json", "campaign.json.bak", "department.json", "department.json.bak",
	"settings.cfg", "legacy.json"]


## Every folder the saves may still be in, oldest name first. The fixed directory is
## here so an install that already ran is recognised as "here" and skipped.
static func legacy_dirs() -> Array:
	var here := ProjectSettings.globalize_path("user://").trim_suffix("/")
	var appdata := here.get_base_dir()
	return [appdata.path_join(OLD_DIR), appdata.path_join("The Violence"), here]


## Copy the saves and settings into the current user directory (never over an existing
## file). Safe to call on every launch: with nothing to carry it does nothing.
static func migrate() -> void:
	var here := ProjectSettings.globalize_path("user://").trim_suffix("/")
	for old in legacy_dirs():
		if old == here or not DirAccess.dir_exists_absolute(old):
			continue
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
	var err := cf.save(PATH)
	if err != OK:
		push_warning("Settings.save_all: ConfigFile.save(%s) -> %d" % [PATH, err])


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
	# 4.72: AudioServer.get_bus_index may return -1 if bus was removed externally
	var eff_idx := AudioServer.get_bus_index("Effects")
	var amb_idx := AudioServer.get_bus_index("Ambience")
	AudioServer.set_bus_volume_db(0, _db(float(data["master"])))
	if eff_idx != -1:
		AudioServer.set_bus_volume_db(eff_idx, _db(float(data["effects"])))
	if amb_idx != -1:
		AudioServer.set_bus_volume_db(amb_idx, _db(float(data["ambience"])))
	var Ink = load("res://scripts/view/ink.gd")
	if Ink.red_ink_enabled != bool(data["red_ink"]):
		Ink.set_red_ink(bool(data["red_ink"]))
	if Ink.gore_enabled != bool(data["gore"]):
		Ink.set_gore(bool(data["gore"]))
	# 1.4: line boil (off stills every crayon line, for players who need still lines)
	var fps := 8.0 if bool(data.get("boil", true)) else 0.0
	load("res://scripts/view/crayon.gd").fps = fps
	load("res://scripts/view/decals.gd").set_boil(fps)
	# 4.72: DisplayServer.window_* may throw in headless/embedded; guard it
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(data["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
