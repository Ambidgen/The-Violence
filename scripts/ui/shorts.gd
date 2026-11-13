extends CanvasLayer
## Native crayon campaign shorts. The manifest remains the source of truth for each
## short's duration, defaults, slots and trigger; the artwork is drawn by Godot at runtime.
##
## Shorts never block and never require a waiting state: `done` fires on completion,
## skip, stop, or a missing/unknown key so a caller can always continue on the callback.

signal done(key: String)

const MANIFEST_PATH := "res://assets/cutscenes/shorts/shorts.json"
const VIEW_SCRIPT := "res://scripts/view/crayon_short.gd"
const HAND_FONT := preload("res://fonts/PatrickHand.woff2")
const MID := Color("#3a3632")
const CUE_MAP := {
	"s01_week": [["click", 1.2], ["click", 2.2], ["stamp", 4.6], ["toll", 5.35]],
	"s02_situation": [["door", 0.8], ["stamp", 3.5], ["click", 5.3]],
	"s03_plan": [["click", 1.0], ["stamp", 6.0], ["toll", 7.2]],
	"s04_staging": [["door", 0.8], ["radio", 2.2], ["radio", 3.4], ["kick", 5.1]],
	"s05_threshold": [["door", 1.0], ["radio", 3.1], ["shot_pistol_1", 4.9]],
	"s06_officer_down":
	[["shot_rifle_1", 0.8], ["shot_rifle_2", 1.0], ["radio", 2.6], ["toll", 6.7]],
	"s07_debrief": [["click", 1.4], ["stamp", 5.3], ["radio", 6.1]],
	"s08_press": [["click", 1.1], ["stamp", 6.5]],
	"s09_case": [["click", 1.4], ["stamp", 6.2]],
	"s10_ally": [["click", 1.2], ["toll", 5.8]],
	"s11_election": [["click", 1.0], ["click", 2.2], ["click", 3.4], ["toll", 9.0]],
	"s12_end_of_watch": [["toll", 6.6]],
	"s13_allocation": [["click", 1.1], ["stamp", 4.4], ["toll", 5.4]],
	"s14_course": [["click", 1.0], ["stamp", 5.0]],
	"s15_week_recap": [["click", 0.9], ["click", 1.9], ["click", 2.9], ["stamp", 3.85]],
}

static var _cache: Dictionary = {}
static var _audio_cache: Dictionary = {}

var view: Node2D
var hint: Label
var skip_button: Button
var busy := false
var _key := ""
var _on_done := Callable()
var _t := 0.0
var _duration := 0.0
var _cue_index := 0
var _cues: Array = []
var _effect_players: Array[AudioStreamPlayer] = []
var _effect_index := 0
var _bed_player: AudioStreamPlayer


func _ready() -> void:
	layer = 38
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var bg := ColorRect.new()
	bg.color = Color("#8d8a83")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_click)
	add_child(bg)
	var view_script: Script = load(VIEW_SCRIPT)
	if view_script != null:
		view = view_script.new() as Node2D
		view.name = "CrayonShortView"
		add_child(view)
		view.hide()
	hint = Label.new()
	hint.text = "Space: skip"
	hint.add_theme_font_override("font", HAND_FONT)
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", MID)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-170, -36)
	hint.size = Vector2(150, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.modulate.a = 0.0
	add_child(hint)
	skip_button = Button.new()
	skip_button.text = "Skip  [Space]"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	skip_button.position = Vector2(24, -52)
	skip_button.size = Vector2(150, 34)
	skip_button.pressed.connect(stop)
	add_child(skip_button)
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		_effect_players.append(player)
	_bed_player = AudioStreamPlayer.new()
	_bed_player.bus = "Ambience"
	add_child(_bed_player)


# ------------------------------------------------------------------ the catalogue
## The manifest, parsed once (an empty Dictionary when the shorts were not shipped).
static func manifest() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_cache = parsed
	return _cache


## Every short, in the manifest's order.
static func entries() -> Array:
	return manifest().get("shorts", [])


## One short's entry, or {} when the key is unknown.
static func entry(key: String) -> Dictionary:
	for short_entry in entries():
		if String(short_entry.get("key", "")) == key:
			return short_entry
	return {}


## Legacy video path retained for tooling; gameplay no longer loads these files.
static func video_path(key: String) -> String:
	var short_entry := entry(key)
	if short_entry.is_empty():
		return ""
	var dir := String(manifest().get("video", {}).get("dir", "res://assets/cutscenes/shorts"))
	return "%s/%s.%s" % [dir, key, String(manifest().get("video", {}).get("ext", "ogv"))]


## True when the key is known and the native crayon view can be loaded.
static func available(key: String) -> bool:
	return not entry(key).is_empty() and ResourceLoader.exists(VIEW_SCRIPT)


## Seconds a short runs, or 0.0.
static func length(key: String) -> float:
	return float(entry(key).get("seconds", 0.0))


## The keys whose `tags` contain tag (e.g. "weekly", "consequence", "in-run").
static func with_tag(tag: String) -> Array:
	var out: Array = []
	for short_entry in entries():
		if tag in short_entry.get("tags", []):
			out.append(String(short_entry.get("key", "")))
	return out


# ------------------------------------------------------------------ playing
## Play one short. `text` fills published slots (slot id -> String); defaults stay in
## the manifest. Returns false (and calls on_done at once) for an unknown key.
func play(key: String, text: Dictionary = {}, on_done: Callable = Callable(), props: Dictionary = {}) -> bool:
	if busy:
		return false
	if not available(key) or not is_instance_valid(view):
		if on_done.is_valid():
			on_done.call()
		return false
	_key = key
	_on_done = on_done
	_t = 0.0
	_duration = length(key)
	_cues = CUE_MAP.get(key, []).duplicate(true)
	_cue_index = 0
	var defaults: Dictionary = entry(key).get("props", {}).duplicate(true)
	# the engine's own figures over the manifest defaults (S15 Week Closed fills every prop)
	defaults.merge(props, true)
	if key == "s05_threshold" and String(defaults.get("variant", "clear")) != "contact":
		_cues.pop_back()
	view.call("configure", key, defaults, text, _duration)
	view.show()
	visible = true
	busy = true
	hint.modulate.a = 0.0
	_play_bed(key)
	return true


## Play a list of shorts in order (a campaign can chain a week card into a briefing).
func play_all(keys: Array, texts: Array = [], on_done: Callable = Callable()) -> void:
	var queue := keys.duplicate()
	if queue.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	var first: String = String(queue.pop_front())
	var slot_text: Dictionary = texts[0] if texts.size() > 0 else {}
	var rest := texts.slice(1)
	play(first, slot_text, func(): play_all(queue, rest, on_done))


## Stop early and run the caller's callback exactly once.
func stop() -> void:
	if busy:
		_complete(false)


func _complete(emit_done: bool) -> void:
	if not busy:
		return
	busy = false
	if is_instance_valid(view):
		view.hide()
	_bed_player.stop()
	for player in _effect_players:
		player.stop()
	visible = false
	hint.modulate.a = 0.0
	var completed_key := _key
	var cb := _on_done
	_on_done = Callable()
	if emit_done:
		done.emit(completed_key)
	if cb.is_valid():
		cb.call()


func _process(dt: float) -> void:
	if not busy:
		return
	var before := _t
	_t += dt
	if before < 3.0 and _t >= 3.0:
		hint.modulate.a = 0.0
	if _t > 3.0:
		hint.modulate.a = minf(1.0, hint.modulate.a + dt * 2.0)
	while _cue_index < _cues.size() and float(_cues[_cue_index][1]) <= _t:
		_play_effect(String(_cues[_cue_index][0]))
		_cue_index += 1
	if _t >= _duration:
		_complete(true)


func _unhandled_input(event: InputEvent) -> void:
	if not busy:
		return
	var skip := false
	if (
		event is InputEventKey
		and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo
	):
		var code := (event as InputEventKey).keycode
		skip = code == KEY_SPACE or code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_ESCAPE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		skip = true
	if skip:
		get_viewport().set_input_as_handled()
		stop()


func _on_click(event: InputEvent) -> void:
	if busy and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		stop()


func _play_bed(short_key: String) -> void:
	var name := "amb_city" if short_key == "s04_staging" else "amb_office"
	var stream := _audio_stream(name)
	if stream == null:
		return
	_bed_player.stream = stream
	_bed_player.volume_db = -14.0
	_bed_player.play()


func _play_effect(name: String) -> void:
	var stream := _audio_stream(name)
	if stream == null or _effect_players.is_empty():
		return
	var player := _effect_players[_effect_index]
	_effect_index = (_effect_index + 1) % _effect_players.size()
	player.stream = stream
	player.volume_db = -5.0 if name.begins_with("shot_") else -8.0
	player.play()


static func _audio_stream(name: String) -> AudioStream:
	if not _audio_cache.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_audio_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _audio_cache[name]
