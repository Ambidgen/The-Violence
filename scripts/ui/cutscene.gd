extends CanvasLayer
## The opening (1.2): four cutscenes made with Remotion (cinematics/), played before a new
## campaign and from the title's Prologue. Space, Enter or a click skips the current one;
## Esc skips the rest. Videos are Ogg Theora in assets/cutscenes.

signal finished

const SCENES := [
	["c1_port_carrick", "Port Carrick"],
	["c2_outgoing_chief", "The Outgoing Chief"],
	["c3_the_plan", "The Plan"],
	["c4_forty_weeks", "Forty Weeks"],
]
const PAPER := Color(0.93, 0.93, 0.91)
const MID := Color(0.45, 0.45, 0.44)

var player: VideoStreamPlayer
var hint: Label
var title: Label
var queue: Array = []
var _hint_t := 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_click)
	add_child(bg)
	player = VideoStreamPlayer.new()
	player.set_anchors_preset(Control.PRESET_FULL_RECT)
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.bus = "Effects"
	player.finished.connect(_next)
	add_child(player)
	hint = Label.new()
	hint.text = "Space: next   ·   Esc: skip the opening"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", MID)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-330, -34)
	hint.size = Vector2(320, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)
	visible = false


## Play the given scenes (all four by default), then emit finished.
func play(which: Array = []) -> void:
	queue = which.duplicate() if not which.is_empty() else SCENES.map(func(s): return s[0])
	visible = true
	_next()


static func available() -> bool:
	return ResourceLoader.exists("res://assets/cutscenes/%s.ogv" % SCENES[0][0])


func _next() -> void:
	while not queue.is_empty():
		var key: String = queue.pop_front()
		var path := "res://assets/cutscenes/%s.ogv" % key
		if ResourceLoader.exists(path):
			player.stream = load(path)
			player.play()
			_hint_t = 3.5
			hint.modulate.a = 1.0
			return
	stop()


func stop() -> void:
	queue.clear()
	if player.is_playing():
		player.stop()
	visible = false
	finished.emit()


func _process(dt: float) -> void:
	if not visible:
		return
	_hint_t -= dt
	hint.modulate.a = clampf(_hint_t, 0.0, 1.0)


func _on_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_skip_one()


func _skip_one() -> void:
	player.stop()
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
