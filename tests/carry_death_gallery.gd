extends SceneTree
## 1.4 review sheet: for police (a), suspects (b) and civilians (c), the three carries
## (low, high, weaponless with everything holstered or slung), the aim for reference, and
## the eight deaths by the direction of the killing blow. Not headless:
##   godot --path . -s res://tests/carry_death_gallery.gd -- --out=sheet.png

const Rig = preload("res://scripts/view/rig.gd")
const FROM := ["behind", "behind-left", "left", "front-left", "front", "front-right", "right", "behind-right"]

var rigs: Array = []
var frame := 0
var out := "carry_death.png"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	ThemeDB.fallback_font = load("res://scripts/ui/ui.gd").hand_font()
	RenderingServer.set_default_clear_color(Color("#5d6878"))
	var root := Node2D.new()
	get_root().add_child(root)
	var cam := Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	cam.position = Vector2(380, 200)
	root.add_child(cam)
	cam.make_current()
	var looks := ["a", "b", "c"]
	for li in looks.size():
		var lk: String = looks[li]
		var y := 30.0 + li * 130.0
		var carries := [["low", "low carry"], ["high", "high carry"], ["holstered", "weaponless"], ["aim", "aim"]]
		for ci in carries.size():
			if lk == "c" and ci != 2:
				continue
			var r = Rig.new()
			root.add_child(r)
			r.setup(lk, 7 + li * 3)
			r.set_gun("w/carbine")
			r.pose = carries[ci][0] if lk != "c" else "unarmed"
			r.gun_shown = lk != "c" and ci != 2
			r.slung_key = "w/carbine" if (ci == 2 and lk != "c") else ""
			r.holster = lk != "c" and ci != 3
			r.body_dir = -0.5
			r.muzzle_dir = -0.5
			r.look_dir = -0.5
			r.position = Vector2(20 + ci * 52, y)
			rigs.append([r, false])
			_label(root, carries[ci][1], r.position + Vector2(-22, 26))
		for k in 8:
			var r2 = Rig.new()
			root.add_child(r2)
			r2.setup(lk, 11 + k)
			r2.set_gun("w/carbine")
			r2.body_dir = -PI / 2.0
			r2.muzzle_dir = -PI / 2.0
			r2.look_dir = -PI / 2.0
			r2.position = Vector2(240 + k * 64, y + 20)
			rigs.append([r2, k])
			_label(root, "from " + FROM[k], r2.position + Vector2(-28, 38))


func _label(root: Node, text: String, p: Vector2) -> void:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 9)
	lb.add_theme_color_override("font_color", Color("#ece4d0"))
	lb.position = p
	root.add_child(lb)


func _process(dt: float) -> bool:
	frame += 1
	for e in rigs:
		var r = e[0]
		if frame == 3 and e[1] is int:
			# travel direction of the round, in the body frame (facing up the page)
			var k: int = e[1]
			r.fall(Vector2.from_angle(r.body_dir + k * TAU / 8.0), true)
		r.advance(1.0 / 30.0, r.position)
	if frame == 60:
		var img := get_root().get_texture().get_image()
		img.save_png(out)
		quit()
	return false
