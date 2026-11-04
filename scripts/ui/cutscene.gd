extends CanvasLayer
## Crayon opening cutscenes, played before a new campaign and from the title's Prologue.
## These are native Godot drawings (scripts/view/proto), not the legacy Remotion videos.
## Space, Enter or a click skips the current scene; Esc skips the rest.

signal finished

const SCENES := [
	["c1_port_carrick", "Port Carrick", "res://scripts/view/proto/opening_view.gd"],
	["c2_outgoing_chief", "The Press Conference", "res://scripts/view/proto/presser_view.gd"],
	["c3_the_plan", "Jeremy Berry", "res://scripts/view/proto/jeremy_view.gd"],
	["c4_forty_weeks", "This Machine Kills Tyrants", "res://scripts/view/proto/fettick_view.gd"],
]
const PAPER := Color("#e6dfcd")
const MID := Color("#45413b")
const HAND_FONT := preload("res://fonts/PatrickHand.woff2")

var view: Node2D
var hint: Label
var title: Label
var queue: Array = []
var _hint_t := 0.0
var _scene_t := 0.0
var _scene_duration := 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_click)
	add_child(bg)
	title = Label.new()
	title.add_theme_font_override("font", HAND_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", MID)
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(28, 14)
	title.size = Vector2(500, 34)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	hint = Label.new()
	hint.text = "Space: next   ·   Esc: skip the opening"
	hint.add_theme_font_override("font", HAND_FONT)
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", MID)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-360, -38)
	hint.size = Vector2(340, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	visible = false


## Play the given scenes (all four by default), then emit finished.
func play(which: Array = []) -> void:
	queue = which.duplicate() if not which.is_empty() else SCENES.map(func(s): return s[0])
	visible = true
	_next()


static func available() -> bool:
	return ResourceLoader.exists(String(SCENES[0][2]))


func _scene_for(key: String) -> Array:
	for entry: Array in SCENES:
		if String(entry[0]) == key:
			return entry
	return []


func _next() -> void:
	if is_instance_valid(view):
		view.hide()
		view.queue_free()
	view = null
	while not queue.is_empty():
		var key := String(queue.pop_front())
		var entry := _scene_for(key)
		if entry.is_empty() or not ResourceLoader.exists(String(entry[2])):
			continue
		var script: Script = load(String(entry[2]))
		if script == null:
			continue
		var instance = script.new()
		if not instance is Node2D:
			if instance is Node:
				instance.free()
			continue
		view = instance as Node2D
		add_child(view)
		# Keep the image above the paper but beneath the title and skip controls.
		move_child(view, 1)
		title.text = String(entry[1])
		_scene_t = 0.0
		_scene_duration = float(view.call("duration")) if view.has_method("duration") else 0.0
		_hint_t = 3.5
		hint.modulate.a = 1.0
		return
	stop()


func stop() -> void:
	queue.clear()
	if is_instance_valid(view):
		view.hide()
		view.queue_free()
	view = null
	visible = false
	finished.emit()


func _process(dt: float) -> void:
	if not visible:
		return
	_hint_t -= dt
	hint.modulate.a = clampf(_hint_t, 0.0, 1.0)
	_scene_t += dt
	if _scene_duration > 0.0 and _scene_t >= _scene_duration:
		_next()


func _on_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_skip_one()


func _skip_one() -> void:
	if is_instance_valid(view):
		view.hide()
		view.queue_free()
	view = null
	_next()


func _unhandled_input(ev: InputEvent) -> void:
	if not visible or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	get_viewport().set_input_as_handled()
	match (ev as InputEventKey).keycode:
		KEY_ESCAPE:
			stop()
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_skip_one()
		_:
			_hint_t = 3.0
