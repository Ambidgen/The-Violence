extends SceneTree
## Bakes the crayon sprite set (1.4): every key in assets/svg/ gets three boil variants in
## assets/crayon/<key>_<v>.png, which Decals.tex() plays as an AnimatedTexture so the
## sprites shiver like the rest of the page.
##
##   props, vehicles   drawn by view/crayon_props.gd at their canonical size
##   figure parts      drawn by view/crayon_figures.gd (torso, head, lying down)
##   everything else   the vector art rasterised and crayon-processed: the grey ramp
##                     mapped to graphite and wax, a slanted grain, edges pressed harder
##
## Needs a display (it renders through a SubViewport):
##   godot --path . -s res://tools/bake_crayon.gd [-- --only=furn/bed]
## then `godot --headless --path . --import` to import the PNGs.

const C = preload("res://scripts/view/crayon.gd")
const Props = preload("res://scripts/view/crayon_props.gd")
const Figs = preload("res://scripts/view/crayon_figures.gd")
const OUT := "res://assets/crayon/"
const VARIANTS := 3

const FIG_LOOKS := ["a", "b", "c", "med", "pmed", "pd", "qrf"]
# These are authored and baked together by make_character_assets.py. Do not
# replace their coloured linework with the older generic SVG rasterizer.
const CHARACTER_LOOKS := ["patrol", "swat", "riot", "hood", "leather", "workcoat", "track", "vestlook"]


class Painter extends Node2D:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	_run.call_deferred(only)


func _run(only: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var keys := _svg_keys("res://assets/svg", "")
	# 1.4: the eight deaths of every look, which have no vector original
	for lk in FIG_LOOKS:
		for d in 8:
			keys.append("op/%s_dead%d" % [lk, d])
	var n := 0
	for key in keys:
		if (key.get_base_dir() == "op" and key.get_file().get_slice("_", 0) in CHARACTER_LOOKS) or key == "kit/riot_head":
			continue
		if only != "" and not key.begins_with(only):
			continue
		var job := _job(key)
		for v in VARIANTS:
			C.frame = 1000 + v * 37
			var img: Image
			if job.is_empty():
				img = _crayonize(key, v)
			else:
				img = await _render(job["size"], job["fn"], job.get("scale", 1.0))
			if img == null:
				continue
			var path := ProjectSettings.globalize_path(OUT + "%s_%d.png" % [key, v])
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			img.save_png(path)
		n += 1
	print("baked %d keys x %d variants" % [n, VARIANTS])
	quit()


func _svg_keys(dir: String, pre: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	for sub in d.get_directories():
		out += _svg_keys(dir + "/" + sub, pre + sub + "/")
	for f in d.get_files():
		if f.ends_with(".svg"):
			out.append(pre + f.get_basename())
	out.sort()
	return out


func _svg_size(key: String) -> Vector2i:
	var txt := FileAccess.get_file_as_string("res://assets/svg/%s.svg" % key)
	var m := RegEx.create_from_string('width="([0-9.]+)" height="([0-9.]+)"').search(txt)
	return Vector2i(int(float(m.get_string(1))), int(float(m.get_string(2))))


## What draws this key, at what size; empty for the raster route.
func _job(key: String) -> Dictionary:
	var grp := key.get_base_dir()
	var name := key.get_file()
	var seed_v := absi(hash(key)) % 9000
	if grp == "op" and name.contains("_dead"):
		var pr := name.split("_dead")
		var dk := int(pr[1])
		return {"size": Vector2i(176, 176), "fn": func(ci): Figs.dead(ci, pr[0], dk, seed_v)}
	var sz := _svg_size(key)
	if grp in ["furn", "yard"] or (grp == "veh"):
		var r := Rect2(Vector2(1.5, 1.5), Vector2(sz) * 0.5 - Vector2(3, 3))
		return {"size": sz, "scale": 2.0, "fn": func(ci): Props.paint(ci, name, r, seed_v)}
	if grp == "op":
		var parts := name.split("_")
		if parts.size() == 2 and parts[0] in FIG_LOOKS:
			match parts[1]:
				"torso":
					return {"size": Vector2i(64, 64), "fn": func(ci): Figs.torso(ci, parts[0], seed_v)}
				"head":
					return {"size": Vector2i(32, 32), "fn": func(ci): Figs.head(ci, parts[0], seed_v)}
				"down":
					return {"size": Vector2i(152, 96), "fn": func(ci): Figs.down(ci, parts[0], seed_v)}
	if key == "kit/helmet_head":
		return {"size": Vector2i(32, 32), "fn": func(ci): Figs.helmet_head(ci, seed_v)}
	return {}


func _render(size: Vector2i, fn: Callable, scale: float) -> Image:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var p := Painter.new()
	p.fn = fn
	if scale != 1.0:
		p.scale = Vector2.ONE * scale
	else:
		p.position = Vector2(size) * 0.5
	vp.add_child(p)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	_unpremultiply(img)
	return img


func _unpremultiply(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.a < 0.999:
				img.set_pixel(x, y, Color(minf(1.0, c.r / c.a), minf(1.0, c.g / c.a), minf(1.0, c.b / c.a), c.a))


## The grey ramp of the old art, as graphite and wax.
const RAMP := [[0.0, Color("#141313")], [0.2, Color("#2f2e2d")], [0.45, Color("#5f5a52")], [0.75, Color("#b3aa96")], [1.0, Color("#ece4d0")]]


func _ramp(l: float) -> Color:
	for i in RAMP.size() - 1:
		var a: Array = RAMP[i]
		var b: Array = RAMP[i + 1]
		if l <= float(b[0]):
			return (a[1] as Color).lerp(b[1], (l - float(a[0])) / (float(b[0]) - float(a[0])))
	return RAMP[RAMP.size() - 1][1]


func _crayonize(key: String, v: int) -> Image:
	var txt := FileAccess.get_file_as_string("res://assets/svg/%s.svg" % key)
	var src := Image.new()
	if src.load_svg_from_string(txt, 1.0) != OK:
		return null
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var s := absi(hash(key)) % 9000 + v * 101
	var ang := -0.7 + C.rnd(s, 1) * 0.3
	var dir := Vector2(cos(ang), sin(ang))
	for y in h:
		for x in w:
			# the hand wobbles: sample a little off where it should
			var ox := int(round(C.rnd(s + y, 3) * 1.2 - 0.6)) if (y + v) % 3 == 0 else 0
			var c := src.get_pixel(clampi(x + ox, 0, w - 1), y)
			if c.a <= 0.01:
				continue
			var sat := maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			var col: Color
			if sat > 0.15:
				col = C.RED if c.r > c.g else c
			else:
				col = _ramp((c.r + c.g + c.b) / 3.0)
			# the grain: slanted strokes, paper showing between them
			var d := Vector2(x, y).dot(dir)
			var stripe := 0.5 + 0.5 * sin(d * 1.7 + C.rnd(s, int(d * 0.25)) * 4.0)
			var l := (col.r + col.g + col.b) / 3.0
			if l < 0.5:
				col = col.lerp(col.lightened(0.35), stripe * 0.35)
			else:
				col = col.lerp(col.darkened(0.25), stripe * 0.4)
			# edges pressed harder
			var edge := false
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + o
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or src.get_pixel(q.x, q.y).a < 0.4:
					edge = true
					break
			if edge:
				col = col.darkened(0.35)
			var a := c.a * (0.82 + 0.18 * C.rnd(s + x * 7, y))
			out.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return out
