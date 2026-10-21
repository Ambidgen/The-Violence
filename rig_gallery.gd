extends SceneTree
## Every pose of the animated figure (1.1), side by side, for review. Not headless:
##   xvfb-run godot --path . --resolution 1600x900 -s res://tests/rig_gallery.gd -- --out=gallery.png [--t=0.6] [--walk]
## --t sets how far into each timed action the frame is taken; --walk moves every figure.

const Rig = preload("res://scripts/view/rig.gd")
const Ink = preload("res://scripts/view/ink.gd")

const POSES := [
	["aim", "rifle", 0], ["aim", "pistol", 0], ["aim", "low ready", 0], ["low", "slung", 0], ["holstered", "", 0],
	["reload", "", 0], ["clear", "stoppage", 0], ["swap", "to pistol", 0], ["throw", "bang", 0], ["door", "", 0],
	["ram", "", 0], ["kick", "", 0], ["cuffing", "", 1], ["treat", "", 1], ["spray", "OC", 0],
	["strike", "baton", 0], ["stunned", "", 2], ["gassed", "", 0], ["flinch", "", 2], ["hands", "", 0],
	["cuffed", "", 0], ["film", "civ", 0], ["frozen", "civ", 0], ["unarmed", "civ walk", 0], ["aim", "crouch", 1],
	["down", "fallen", 0], ["recoil", "rifle", 0], ["hit", "stagger", 0],
]

var rigs: Array = []
var frame := 0
var args := {}
var labels: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color(0.83, 0.83, 0.81))
	var root := Node2D.new()
	get_root().add_child(root)
	var cam := Camera2D.new()
	var z := float(args.get("zoom", "2.6"))
	cam.zoom = Vector2(z, z)
	var f: PackedStringArray = String(args.get("focus", "270,150")).split(",")
	cam.position = Vector2(float(f[0]), float(f[1]))
	root.add_child(cam)
	cam.make_current()
	var font: Font = ThemeDB.fallback_font
	var only: Array = []
	if args.has("only"):
		for k in String(args["only"]).split(","):
			only.append(int(k))
	for i in POSES.size():
		if not only.is_empty() and not i in only:
			continue
		var p: Array = POSES[i]
		var r = Rig.new()
		root.add_child(r)
		var civ: bool = String(p[1]).begins_with("civ")
		r.setup("c" if civ else ("b" if i % 5 == 4 else "a"), i * 31)
		r.position = Vector2((i % 7) * 85 + 20, int(i / 7) * 85 + 20)
		if not only.is_empty():
			var j := only.find(i)
			r.position = Vector2(j * 70, 0)
		r.set_gun("w/service_pistol" if p[1] == "pistol" else "w/carbine")
		r.pistol = p[1] == "pistol"
		r.pose = p[0] if not p[0] in ["down", "recoil", "hit"] else "aim"
		r.ready_low = p[1] == "low ready"
		r.gun_shown = not civ
		r.stance = p[2]
		var d0 := float(args.get("dir", "-0.35"))
		r.body_dir = d0
		r.muzzle_dir = d0
		r.look_dir = d0 + (0.7 if i % 3 == 0 else 0.0)
		if p[0] == "swap":
			r.pose_p = 0.3
		if p[0] == "hands" or p[0] == "cuffed":
			r.gun_shown = false
		if r.stance > 0 and p[0] == "aim":
			pass
		rigs.append([r, p])
		var lb := Label.new()
		lb.text = "%s %s" % [p[0], p[1]]
		lb.add_theme_font_size_override("font_size", 7)
		lb.add_theme_color_override("font_color", Color(0.17, 0.17, 0.17))
		lb.position = r.position + Vector2(-30, 26)
		root.add_child(lb)


func _process(dt: float) -> bool:
	frame += 1
	var t := float(args.get("t", "0.6"))
	if args.has("anim"):
		t = fmod(frame / 60.0, 1.0)
	for e in rigs:
		var r = e[0]
		var p: Array = e[1]
		r.pose_p = t if p[0] != "swap" else (0.3 if t < 0.5 else 0.8)
		if p[0] == "down" and frame == 20:
			r.fall(Vector2(1, 0.3).normalized(), true)
		if p[0] == "recoil" and frame % 6 == 0:
			r.shot()
		if p[0] == "hit" and frame == 34:
			r.hit(Vector2(-1, 0.2).normalized(), 1.0)
		var walk: bool = args.has("walk") or p[1] == "civ walk"
		if walk:
			# back and forth across the cell, so the figure stays in frame
			var ph := fmod(frame / 120.0, 2.0)
			var base: Vector2 = r.get_meta("home", r.position)
			r.set_meta("home", base)
			r.position = base + Vector2.from_angle(r.body_dir) * (ph if ph < 1.0 else 2.0 - ph) * 40.0 * 1.4 - Vector2.from_angle(r.body_dir) * 28.0
		r.advance(1.0 / 60.0, r.position)
		if p[0] == "down" and args.has("anim") and frame % 90 == 0:
			r.stand_up()
			r._last_pos = Vector2.INF
		if p[0] == "down" and args.has("anim") and frame % 90 == 30:
			r.fall(Vector2(1, 0.3).normalized(), frame % 180 < 90)
	if frame == int(args.get("frames", "40")):
		var img := get_root().get_texture().get_image()
		img.save_png(args.get("out", "user://rig_gallery.png"))
		return true
	return false
