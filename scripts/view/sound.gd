extends Node2D
## Sound (1.0): the synthesised effects (tools/make_sounds.py) played from the
## simulation's events, the interface, and an ambience bed per screen.
##
## Shots play where they were fired, by weapon class; a shot the player cannot see (out
## of every officer's view in the fog, or far from the camera) plays its muffled far
## version instead. At high speed the shots are thinned to a few a frame, so a firefight
## at 20x is a rattle, not a wall. Nothing here touches the simulation.

const Equipment = preload("res://scripts/data/equipment.gd")
const PX := 40.0
const POOL := 14
const SHOTS_PER_FRAME := 3
const FAR_M := 28.0

static var _cache := {}

var players: Array = []
var ui_player: AudioStreamPlayer
var radio_player: AudioStreamPlayer
var amb: AudioStreamPlayer
var amb_name := ""
var _next := 0
var _shots_this_frame := 0
var _radio_t := -9.0
var cam: Camera2D
var fog = null


## Recording (1.1): with --soundlog=path, every sound the game plays is also written as a
## line (frame, name, volume, pan), so a recorded video can be given its soundtrack
## afterwards (the recorder's own audio capture is not reliable on a headless box).
var _log: FileAccess = null


func _log_line(name: String, db: float, pan: float, loop := false) -> void:
	if _log == null:
		return
	_log.store_line(JSON.stringify({"f": Engine.get_process_frames(), "s": name, "db": snappedf(db, 0.1), "pan": snappedf(pan, 0.01), "loop": loop}))
	_log.flush()


func _pan_db(p_px: Vector2) -> Array:
	if cam == null:
		return [0.0, 0.0]
	var c := cam.get_screen_center_position()
	var half := get_viewport().get_visible_rect().size.x / cam.zoom.x / 2.0
	var d := p_px.distance_to(c) * cam.zoom.x
	return [clampf((p_px.x - c.x) / maxf(half, 1.0), -1.0, 1.0), -clampf(d / 900.0, 0.0, 1.0) * 14.0]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--soundlog="):
			_log = FileAccess.open(a.substr(11), FileAccess.WRITE)
	for i in POOL:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Effects"
		p.max_distance = 2600.0
		p.attenuation = 1.4
		add_child(p)
		players.append(p)
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Effects"
	add_child(ui_player)
	radio_player = AudioStreamPlayer.new()
	radio_player.bus = "Effects"
	add_child(radio_player)
	amb = AudioStreamPlayer.new()
	amb.bus = "Ambience"
	add_child(amb)


static func stream(name: String) -> AudioStream:
	if not _cache.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


func _process(_dt: float) -> void:
	_shots_this_frame = 0


func play_at(name: String, p_m: Vector2, db := 0.0, pitch := 1.0) -> void:
	var s := stream(name)
	if s == null:
		return
	var p: AudioStreamPlayer2D = players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.global_position = p_m * PX
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()
	if _log != null:
		var pd := _pan_db(p.global_position)
		_log_line(name, db + pd[1], pd[0])


func play_ui(name: String, db := 0.0) -> void:
	var s := stream(name)
	if s == null:
		return
	ui_player.stream = s
	ui_player.volume_db = db
	ui_player.play()
	_log_line(name, db, 0.0)


## The radio's squelch when a callout comes in: at most one every 1.5 s.
func radio() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _radio_t < 1.5:
		return
	_radio_t = now
	var s := stream("radio")
	if s != null:
		radio_player.stream = s
		radio_player.volume_db = -6.0
		radio_player.pitch_scale = randf_range(0.97, 1.03)
		radio_player.play()
		_log_line("radio", -6.0, 0.0)


func ambience(name: String) -> void:
	if name == amb_name:
		return
	amb_name = name
	amb.stop()
	if name == "":
		_log_line("", 0.0, 0.0, true)
		return
	var s = stream(name)     # the beds loop by their import settings (loop_mode forward)
	amb.stream = s
	amb.volume_db = -8.0
	amb.play()
	_log_line(name, -8.0, 0.0, true)


func _far(p_m: Vector2) -> bool:
	if fog != null and fog.enabled and not fog.visible_at(p_m):
		return true
	if cam != null:
		var c: Vector2 = cam.get_screen_center_position() / PX
		return c.distance_to(p_m) > FAR_M / maxf(0.4, cam.zoom.x)
	return false


## A simulation event, live (not in the replay).
func handle(ev: Dictionary) -> void:
	match ev["type"]:
		"shot":
			if _shots_this_frame >= SHOTS_PER_FRAME:
				return
			_shots_this_frame += 1
			var cls: String = String(Equipment.WEAPONS.get(String(ev.get("w", "")), {}).get("sound", "rifle"))
			var p: Vector2 = ev["from"]
			if _far(p):
				play_at("far_" + cls, p, -4.0, randf_range(0.95, 1.05))
			else:
				play_at("shot_%s_%d" % [cls, 1 + randi() % 2], p, 0.0, randf_range(0.96, 1.04))
		"flash":
			play_at("sting" if ev.get("kind", "") == "sting" else "flashbang", ev["p"], 0.0)
		"door":
			match String(ev.get("how", "")):
				"ram":
					play_at("ram", ev["p"])
				"kick":
					play_at("kick", ev["p"])
				"breach_shot", "open", "unlock":
					pass
				_:
					play_at("door", ev["p"], -8.0)
		"gas":
			play_at("gas", ev["p"], -2.0)
		"less":
			match String(ev.get("tool", "")):
				"taser":
					play_at("taser", ev["from"], -3.0)
				"beanbag", "launcher", "pepperball":
					play_at("far_shotgun", ev["from"], -2.0)
				"baton":
					play_at("kick", ev["to"], -8.0)
				"oc_spray":
					play_at("gas", ev["from"], -12.0, 1.6)


## Every button in the scene ticks when pressed.
func hook_buttons(n: Node) -> void:
	if n is BaseButton and not n.has_meta("tick"):
		n.set_meta("tick", true)
		(n as BaseButton).pressed.connect(func(): play_ui("click", -6.0))
