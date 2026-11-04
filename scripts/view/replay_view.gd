extends Node2D
## Rewind and replay (v0.7): everyone as the recorder kept them, at any moment of the
## operation. During the run, rewinding shows only what the department knew at the time
## (officers, what body cameras saw, radio callouts). The debrief replay lifts the fog.
## Nothing here touches the simulation.

const Decals = preload("res://scripts/view/decals.gd")
const Ink = preload("res://scripts/view/ink.gd")
const Op = preload("res://scripts/sim/op.gd")
const Rig = preload("res://scripts/view/rig.gd")
const PX := 40.0
const INK := Color("#141313")

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
	# Older in-memory records without a look retain the original team fallback.
	return String(e["info"].get("look", "a" if int(e["info"]["team"]) == 0 else "b"))


func _display_id(e: Dictionary) -> String:
	var info: Dictionary = e["info"]
	if (int(e["flags"]) & 4) and info.get("attacker", false):
		return String(info.get("disguise_id", "CIV"))
	return String(e["id"])


func _sprite_for(e: Dictionary) -> Dictionary:
	var id: String = e["id"]
	if sprites.has(id):
		return sprites[id]
	var root := Node2D.new()
	add_child(root)
	var rig = Rig.new()
	root.add_child(rig)
	rig.setup(_look(e), hash(id))
	var info: Dictionary = e["info"]
	var armour = null
	if info.get("armour", "none") != "none":
		armour = rig.wear("kit/plates" if info["armour"] == "plates" else "kit/vest", false)
	var helmet = null
	if info.get("head", "none") in ["sof_helmet", "ballistic_helmet"]:
		helmet = rig.wear("kit/riot_head" if info.get("look", "") == "riot" else "kit/helmet_head", true)
	var mask = null
	if info.get("mask", false):
		mask = rig.wear("kit/gas_mask_head", true)
	var shield = null
	if info.get("shield", false):
		shield = Sprite2D.new()
		shield.texture = Decals.tex("kit/shield")
		shield.scale = Vector2.ONE * 0.5
		root.add_child(shield)
	var ram = null
	if info.get("ram", false):
		ram = Sprite2D.new()
		ram.texture = Decals.tex("kit/ram")
		ram.scale = Vector2.ONE * 0.5
		root.add_child(ram)
	var gun = rig.gun
	var body = rig.torso
	var lab := Label.new()
	lab.text = _display_id(e)
	lab.add_theme_font_size_override("font_size", 11)
	lab.add_theme_color_override("font_color", INK)
	lab.position = Vector2(-26, -30)
	root.add_child(lab)
	var rec_s := {"root": root, "body": body, "gun": gun, "rig": rig, "label": lab, "look": "", "down": false, "t": -1.0,
		"helmet": helmet, "armour": armour, "mask": mask, "shield": shield, "ram": ram}
	sprites[id] = rec_s
	return rec_s


## Show the operation at time tt.
var _last_t := -1.0
var _dt := 0.0


func show_at(tt: float) -> void:
	if rec == null:
		return
	_dt = get_process_delta_time()
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
		s["label"].text = _display_id(e)
		var rig = s["rig"]
		var down: bool = int(e["state"]) > 0
		var lk := _look(e)
		if lk != s["look"]:
			s["look"] = lk
			rig.set_look(lk)
		var stepped: bool = absf(tt - float(s["t"])) < 0.6 and tt >= float(s["t"])
		if down != s["down"]:
			s["down"] = down
			s["label"].modulate.a = 0.55 if down else 1.0
			if down:
				if stepped:
					rig.fall(Vector2.ZERO, int(e["state"]) == 2)
				else:
					rig.lie(float(e["body"]), int(e["state"]) == 2)
			else:
				rig.stand_up()
		s["t"] = tt
		var stance: int = (fl >> 5) & 3
		var armed: bool = not (fl & 4) and not (fl & 1) and not down and not bool(e["info"].get("medic", false))
		var wk: String = e["info"].get("primary" if fl & 512 else "secondary", "")
		rig.set_gun(("w/" + wk) if wk != "" else ("op/rifle" if fl & 512 else "op/pistol"))
		rig.body_dir = e["body"]
		rig.muzzle_dir = e["muzzle"]
		rig.look_dir = e["muzzle"] if fl & 16 else e["body"]
		rig.stance = stance
		rig.pistol = not (fl & 512)
		rig.gun_shown = armed
		rig.ready_low = not (fl & 16)
		var pose := "aim"
		if e["info"].get("medic", false):
			pose = "unarmed"
		elif fl & 4:
			pose = "hands" if fl & 1024 else "unarmed"
		elif fl & 2:
			pose = "cuffed"
		elif fl & 1:
			pose = "hands"
		elif ((fl >> 7) & 3) == 0 and not (fl & 16):
			pose = "low" if fl & 512 else "holstered"
		elif pose == "aim" and rig.ready_low and armed:
			pose = "high"          # 1.4: ready, not aiming: high carry
		rig.holster = not (fl & 4) and pose == "holstered"
		rig.pose = pose
		rig.advance(_dt, s["root"].position)
		# Keep equipment under a disguised attacker's civilian appearance.
		if s["armour"] != null:
			s["armour"].visible = not (fl & 4)
		if s["mask"] != null:
			s["mask"].visible = not (fl & 4)
		if s["helmet"] != null:
			s["helmet"].visible = not (fl & 4)
			s["helmet"].modulate.a = 1.0 if fl & 2048 else 0.45
		if s["shield"] != null:
			s["shield"].visible = not down and not (fl & 4)
			s["shield"].rotation = rig.body_dir
			s["shield"].position = rig.torso.position + Vector2.from_angle(rig.body_dir) * 13.0
		if s["ram"] != null:
			s["ram"].visible = not down and not (fl & 4)
			s["ram"].rotation = rig.body_dir
			s["ram"].position = rig.torso.position + Vector2.from_angle(rig.body_dir + PI / 2.0) * 11.0 - Vector2.from_angle(rig.body_dir) * 6.0
	# the rounds fired since the last frame kick whoever fired them
	if _last_t >= 0.0 and tt > _last_t and tt - _last_t < 0.6:
		for sh in rec.shots_between(_last_t, tt):
			var from: Vector2 = (sh[1] as Vector2) * PX
			for id2 in sprites:
				var s2: Dictionary = sprites[id2]
				if s2["root"].visible and s2["root"].position.distance_to(from) < 30.0:
					s2["rig"].shot()
					break
	_last_t = tt
	queue_redraw()


var _n_marker := 0


func _draw() -> void:
	_n_marker = 0
	if rec == null:
		return
	# blood where people fell, growing as it did
	for d in rec.downs:
		if float(d[0]) > t:
			break
		var id: String = d[1]
		if fog_on and not _know.get("bodies", {}).has(id):
			continue
		var r := sqrt(clampf((t - float(d[0])) / 14.0, 0.06, 1.0)) * (0.6 if d[2] else 0.48)
		var c: Vector2 = (d[3] as Vector2) * PX
		var hs: int = absi(hash(id))
		if Ink.gore_enabled:
			var outer := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 11:
				var a := float(hs % 628) / 100.0 + TAU * float(i) / 11.0
				var j1 := 0.72 + 0.4 * float((hs >> (i % 20)) % 7) / 6.0
				var j2 := 0.72 + 0.4 * float((hs >> ((i + 3) % 20)) % 7) / 6.0
				outer.append(c + Vector2.from_angle(a) * r * PX * j1)
				inner.append(c + Vector2.from_angle(a + 0.2) * r * PX * 0.58 * j2)
			draw_colored_polygon(outer, Ink.accent(0.68))
			draw_colored_polygon(inner, Ink.accent(0.9))
		# the evidence marker stays with gore off
		var mp := c + Vector2.from_angle(float(hs % 360) * PI / 180.0) * 0.95 * PX
		draw_rect(Rect2(mp - Vector2(8, 7), Vector2(16, 14)), Ink.PAPER)
		draw_rect(Rect2(mp - Vector2(8, 7), Vector2(16, 14)), Ink.INK, false, 1.2)
		_n_marker += 1
		var txt := str(_n_marker)
		draw_string(ThemeDB.fallback_font, mp + Vector2(-3.5 * txt.length(), 4.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Ink.INK)
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
		draw_line(a * PX, b * PX, Color(0.07, 0.07, 0.07, 0.6 * al), 1.0, true)
	# shouted words
	for f in rec.floats:
		if float(f[0]) > t:
			break
		if t - float(f[0]) > 1.6:
			continue
		var p: Vector2 = (f[1] as Vector2) * PX + Vector2(-30, -48)
		var al2 := clampf(1.6 - (t - float(f[0])), 0.0, 1.0)
		draw_string(font, p, f[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.07, 0.07, 0.07, al2))
	# radio callouts, as known at the time
	if fog_on:
		for l in _know.get("lkp", []):
			var c: Vector2 = (l[0] as Vector2) * PX
			var age: float = t - float(l[1])
			var col := Color(0.07, 0.07, 0.07, clampf(1.0 - age / 120.0, 0.25, 1.0))
			var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(11, 0), c + Vector2(0, 11), c + Vector2(-11, 0), c + Vector2(0, -11)])
			draw_polyline(pts, col, 1.5)
			draw_string(font, c + Vector2(-4, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


## A flashbang going off: a white disc ringed in ink, spikes, fading over 0.6 s.
func _burst(c: Vector2, age: float) -> void:
	var f: float = 1.0 - age / 0.6
	var r: float = (0.6 + 1.6 * (1.0 - f)) * PX
	draw_circle(c, r, Color(0.93, 0.93, 0.91, 0.85 * f))
	draw_arc(c, r, 0.0, TAU, 32, Color(0.07, 0.07, 0.07, 0.7 * f), 1.5)
	for k in 12:
		var a: float = TAU * k / 12.0 + 0.13
		draw_line(c + Vector2.from_angle(a) * r * 0.55, c + Vector2.from_angle(a) * r * 1.25, Color(0.07, 0.07, 0.07, 0.6 * f), 1.2)
