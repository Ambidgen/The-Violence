extends Node2D
## Rewind and replay (v0.7): everyone as the recorder kept them, at any moment of the
## operation. During the run, rewinding shows only what the department knew at the time
## (officers, what body cameras saw, radio callouts). The debrief replay lifts the fog.
## Nothing here touches the simulation.

const Decals = preload("res://scripts/view/decals.gd")
const Op = preload("res://scripts/sim/op.gd")
const PX := 40.0
const INK := Color("#1c1c1c")
const BLOOD := Color("#7d0a0a")

var doors_view = null       # the door layer, shown as the doors stood (v0.7.5)
var rec
var fog_on := false
var t := 0.0
var sprites := {}          # id -> {body, gun, label, look, down}
var font: Font
var _state: Array = []
var _know: Dictionary = {}


func _ready() -> void:
	font = ThemeDB.fallback_font


func setup(recorder, with_fog: bool) -> void:
	rec = recorder
	fog_on = with_fog
	for c in get_children():
		c.queue_free()
	sprites.clear()
	visible = rec != null


func clear() -> void:
	rec = null
	for c in get_children():
		c.queue_free()
	sprites.clear()
	visible = false


func _look(e: Dictionary) -> String:
	if int(e["flags"]) & 4:
		return "c"
	return "a" if int(e["info"]["team"]) == 0 else "b"


func _sprite_for(e: Dictionary) -> Dictionary:
	var id: String = e["id"]
	if sprites.has(id):
		return sprites[id]
	var root := Node2D.new()
	add_child(root)
	var gun := Sprite2D.new()
	gun.centered = false
	gun.texture = Decals.tex("op/rifle")
	gun.scale = Vector2.ONE * 0.5
	gun.offset = Vector2(0, -gun.texture.get_height() / 2.0)
	root.add_child(gun)
	var body := Sprite2D.new()
	body.scale = Vector2.ONE * 0.5
	root.add_child(body)
	var lab := Label.new()
	lab.text = id
	lab.add_theme_font_size_override("font_size", 11)
	lab.add_theme_color_override("font_color", INK)
	lab.position = Vector2(-26, -30)
	root.add_child(lab)
	var rec_s := {"root": root, "body": body, "gun": gun, "label": lab, "look": "", "down": false}
	sprites[id] = rec_s
	return rec_s


## Show the operation at time tt.
func show_at(tt: float) -> void:
	if rec == null:
		return
	t = tt
	if doors_view != null and rec.has_method("doors_at"):
		var dd: Array = rec.doors_at(tt)
		doors_view.show_states(dd[0], dd[1])
	_state = rec.state_at(tt)
	_know = rec.knowledge_at(tt) if fog_on else {}
	var vis: Dictionary = _know.get("vis", {})
	var bodies: Dictionary = _know.get("bodies", {})
	for e in _state:
		var s := _sprite_for(e)
		var fl: int = e["flags"]
		var police: bool = e["info"]["judges"]
		var shown := true
		if fl & 8:
			shown = false
		elif fog_on and not police and not vis.has(e["id"]) and not bodies.has(e["id"]):
			shown = false
		s["root"].visible = shown
		if not shown:
			continue
		s["root"].position = (e["p"] as Vector2) * PX
		var down: bool = int(e["state"]) > 0
		var lk := _look(e)
		if lk != s["look"] or down != s["down"]:
			s["look"] = lk
			s["down"] = down
			s["body"].texture = Decals.tex("op/%s_%s" % [lk, "down" if down else "stand"])
			s["label"].modulate.a = 0.55 if down else 1.0
		s["body"].rotation = e["body"]
		var stance: int = (fl >> 5) & 3
		s["body"].scale = Vector2.ONE * (0.5 if stance == Op.STAND else (0.45 if stance == Op.CROUCH else 0.40))
		var armed: bool = not (fl & 4) and not (fl & 1) and not down
		s["gun"].visible = armed and (fl & 16 or fl & 512)
		var wk: String = e["info"].get("primary" if fl & 512 else "secondary", "")
		s["gun"].texture = Decals.tex(("w/" + wk) if wk != "" else ("op/rifle" if fl & 512 else "op/pistol"))
		s["gun"].rotation = e["muzzle"]
		s["gun"].position = Vector2.from_angle(e["muzzle"]) * 4.0
		s["gun"].modulate.a = 1.0 if fl & 16 else 0.55
	queue_redraw()


func _draw() -> void:
	if rec == null:
		return
	# blood where people fell, growing as it did
	for d in rec.downs:
		if float(d[0]) > t:
			break
		var id: String = d[1]
		if fog_on and not _know.get("bodies", {}).has(id):
			continue
		var r := clampf((t - float(d[0])) / 10.0, 0.15, 1.0) * (0.55 if d[2] else 0.42)
		draw_circle((d[3] as Vector2) * PX, r * PX, Color(BLOOD, 0.85))
	# flashbangs going off (v0.7.5)
	for bg in rec.bangs:
		if float(bg[0]) > t:
			break
		var age0: float = t - float(bg[0])
		if age0 > 0.6:
			continue
		_burst((bg[1] as Vector2) * PX, age0)
	# rounds in the last quarter second
	for s in rec.shots_between(t - 0.25, t):
		var a: Vector2 = s[1]
		var b: Vector2 = s[2]
		if fog_on and not s[3]:
			continue
		var al := 1.0 - (t - float(s[0])) / 0.25
		draw_line(a * PX, b * PX, Color(0.1, 0.1, 0.1, 0.6 * al), 1.0, true)
	# shouted words
	for f in rec.floats:
		if float(f[0]) > t:
			break
		if t - float(f[0]) > 1.6:
			continue
		var p: Vector2 = (f[1] as Vector2) * PX + Vector2(-30, -48)
		var al2 := clampf(1.6 - (t - float(f[0])), 0.0, 1.0)
		draw_string(font, p, f[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.08, 0.08, 0.08, al2))
	# radio callouts, as known at the time
	if fog_on:
		for l in _know.get("lkp", []):
			var c: Vector2 = (l[0] as Vector2) * PX
			var age: float = t - float(l[1])
			var col := Color(0.08, 0.08, 0.08, clampf(1.0 - age / 120.0, 0.25, 1.0))
			var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(11, 0), c + Vector2(0, 11), c + Vector2(-11, 0), c + Vector2(0, -11)])
			draw_polyline(pts, col, 1.5)
			draw_string(font, c + Vector2(-4, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


## A flashbang going off: a white disc ringed in ink, spikes, fading over 0.6 s.
func _burst(c: Vector2, age: float) -> void:
	var f: float = 1.0 - age / 0.6
	var r: float = (0.6 + 1.6 * (1.0 - f)) * PX
	draw_circle(c, r, Color(1, 1, 1, 0.85 * f))
	draw_arc(c, r, 0.0, TAU, 32, Color(0.1, 0.1, 0.1, 0.7 * f), 1.5)
	for k in 12:
		var a: float = TAU * k / 12.0 + 0.13
		draw_line(c + Vector2.from_angle(a) * r * 0.55, c + Vector2.from_angle(a) * r * 1.25, Color(0.1, 0.1, 0.1, 0.6 * f), 1.2)
