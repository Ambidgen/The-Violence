extends Node2D
## Prototype 3 — a cutscene in the overhaul's hand: election night, week 40. A crossroads
## from a high corner in the rain (the riot-line plates): brick blocks with VOTE posters,
## a crowd behind yellow-and-black barriers with signs and raised arms, a line of riot
## officers with round shields, a searchlight on a pole sweeping the crowd, sodium lamps,
## a police van smearing red and blue across the wet street. The page draws itself, the
## camera creeps in, the captions are printed in crayon, and it ends on the stamp.
##
## The scene is real 3D projected by hand (a pinhole camera), so the camera move gives
## true parallax while everything is still drawn in strokes.

const C = preload("res://scripts/view/crayon.gd")

var t := 0.0
var _bt := 0.0
var vp := Vector2(1600, 900)
var paper: ImageTexture
var cam := Vector3(6.0, 15.0, 6.0)
var target := Vector3(-0.5, 0.0, 38.0)
var _f := Vector3.FORWARD
var _r := Vector3.RIGHT
var _u := Vector3.UP
var focal := 1100.0
var crowd: Array = []    # [{x, z, col, arm, sign, s}]
var police: Array = []   # [{x, z, s}]

const SIGNS := ["VOTE", "NO", "VOTE", "WHY?", "NO", "ENOUGH", "", "", "", "VOTE"]
const BLOCKS := [
	# x0, x1, z0, z1, height, seed
	[-34.0, -9.0, 44.0, 90.0, 15.0, 11],
	[9.0, 34.0, 44.0, 90.0, 13.0, 12],
	[-34.0, -10.0, -10.0, 20.0, 6.5, 13],
	[10.0, 34.0, -10.0, 20.0, 5.5, 14],
]


func _ready() -> void:
	vp = get_viewport_rect().size
	paper = C.paper_texture(Vector2i(int(vp.x / 2), int(vp.y / 2)), C.PAPER_GREY, 61, 1.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 40
	for i in 170:
		var z := rng.randf_range(36.5, 47.0)
		var x := rng.randf_range(-6.5, 6.5)
		var arm := rng.randf() < 0.42
		var sg := ""
		if arm and rng.randf() < 0.55:
			sg = SIGNS[rng.randi() % SIGNS.size()]
		var cols := [C.GRAPHITE, C.SLATE, C.UMBER, C.NAVY.lightened(0.15), C.MOSS.darkened(0.3), C.BRICK_DARK]
		crowd.append({"x": x, "z": z, "col": cols[rng.randi() % cols.size()], "arm": arm, "sign": sg, "s": i * 17, "ph": rng.randf() * TAU})
	crowd.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
	for j in 16:
		police.append({"x": -6.6 + j * 0.88 + rng.randf_range(-0.15, 0.15), "z": 33.2 + sin(j * 0.6) * 0.5 + rng.randf_range(-0.2, 0.2), "s": 900 + j * 11})
	police.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))


func _process(delta: float) -> void:
	t += delta
	_bt += delta
	if _bt >= 0.125:
		_bt = 0.0
		C.frame += 1
	# the camera creeps in and down
	var f := clampf(t / 12.0, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	cam = Vector3(6.0 - 2.5 * f, 15.0 - 3.0 * f, 6.0 + 7.0 * f)
	target = Vector3(-0.5 + 0.5 * f, 0.0, 38.0)
	_f = (target - cam).normalized()
	_r = Vector3.UP.cross(_f).normalized()
	_u = _f.cross(_r).normalized()
	queue_redraw()


func P(p: Vector3) -> Vector2:
	var d := p - cam
	var z := maxf(0.5, d.dot(_f))
	return vp * 0.5 + Vector2(d.dot(_r), -d.dot(_u)) * focal / z


func depth_scale(p: Vector3) -> float:
	return focal / maxf(0.5, (p - cam).dot(_f))


func rev(start: float, dur := 0.6) -> float:
	return clampf((t - start) / dur, 0.0, 1.0)


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> PackedVector2Array:
	return PackedVector2Array([P(a), P(b), P(c), P(d)])


func ground_ellipse(c: Vector3, rx: float, rz: float, s := 0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		var w := 1.0 + 0.15 * (C.rnd(s, k) - 0.5)
		pts.append(P(c + Vector3(cos(a) * rx * w, 0.0, sin(a) * rz * w)))
	return pts


func _draw() -> void:
	draw_texture_rect(paper, Rect2(Vector2.ZERO, vp), false)
	var page := Rect2(Vector2(22, 18), vp - Vector2(44, 36))
	# ---------------------------------------------------------------- ground
	var dark := C.GRAPHITE
	C.charcoal(self, C.rect_poly(page), dark, 3.0, 1, rev(0.0, 0.8), 2.6)
	var road := quad(Vector3(-6, 0, -10), Vector3(6, 0, -10), Vector3(6, 0, 120), Vector3(-6, 0, 120))
	var cross := quad(Vector3(-60, 0, 28), Vector3(60, 0, 28), Vector3(60, 0, 40), Vector3(-60, 0, 40))
	var sl := C.SLATE
	sl.a = 0.9
	C.hatch(self, road, sl, 3.0, 1.35, 2, 2.6, rev(0.2, 0.8))
	C.hatch(self, cross, sl, 3.0, 0.1, 3, 2.6, rev(0.3, 0.8))
	# kerbs and sidewalks
	for side: float in [-1.0, 1.0]:
		for zz: Array in [[-10.0, 28.0], [40.0, 120.0]]:
			var walk := quad(Vector3(side * 6, 0, zz[0]), Vector3(side * 9, 0, zz[0]), Vector3(side * 9, 0, zz[1]), Vector3(side * 6, 0, zz[1]))
			var mc := C.MOSS.darkened(0.2)
			mc.a = 0.75
			C.hatch(self, walk, mc, 3.4, 1.0, 4 + int(side * 3), 2.4, rev(0.4, 0.6))
			C.line(self, P(Vector3(side * 6, 0, zz[0])), P(Vector3(side * 6, 0, zz[1])), C.CHARCOAL, 2.4, 20 + int(side * 5), 1.0, 2, rev(0.5, 0.6))
	# the centre line, dashed chalk
	if t > 0.8:
		for k in 16:
			var z0 := -6.0 + k * 7.0
			if z0 > 26.0 and z0 < 41.0:
				continue
			C.line(self, P(Vector3(0, 0, z0)), P(Vector3(0, 0, z0 + 3.0)), C.CHALK.darkened(0.2), 3.0, 40 + k, 0.6, 1)
	# puddles and lamplight pools on the ground
	var lamps := [Vector3(-7.5, 0, 26.0), Vector3(7.5, 0, 48.0), Vector3(-7.5, 0, 60.0), Vector3(7.5, 0, 14.0)]
	if t > 1.0:
		for li in lamps.size():
			var lp: Vector3 = lamps[li]
			var pc := C.ORANGE
			pc.a = 0.62
			pc.a = 0.5
			C.hatch(self, ground_ellipse(lp + Vector3(signf(lp.x) * -1.2, 0.0, 0.5), 2.6, 2.0, 60 + li), pc, 3.0, 0.3, 61 + li, 2.6)
		var puddles := [[Vector3(-2.5, 0, 22.0), 2.2, 1.0, C.ORANGE], [Vector3(3.0, 0, 18.0), 1.6, 0.8, C.RED], [Vector3(-1.0, 0, 52.0), 2.0, 1.0, C.BLUE], [Vector3(4.0, 0, 30.0), 1.4, 0.6, C.AMBER]]
		for pi in puddles.size():
			var pd: Array = puddles[pi]
			var pp := P(pd[0])
			var k2 := depth_scale(pd[0])
			C.puddle(self, pp, float(pd[1]) * k2, float(pd[2]) * k2 * 0.45, 70 + pi, pd[3])
	# ---------------------------------------------------------------- far blocks
	for bi in [0, 1]:
		_block(BLOCKS[bi], rev(0.4 + bi * 0.2, 0.9))
	# the police van at the far kerb, smearing red and blue
	if t > 1.2:
		_van(Vector3(-3.6, 0, 58.0))
	# lamp posts (far ones before the crowd)
	for li2 in lamps.size():
		var lp2: Vector3 = lamps[li2]
		if lp2.z > 40.0 and t > 1.1:
			_lamp(lp2, 700 + li2)
	# ---------------------------------------------------------------- the crowd, the barriers, the line
	var beam_x := -4.0 + 8.0 * (0.5 + 0.5 * sin((t - 3.5) * 0.6)) if t > 3.5 else -99.0
	var surge := clampf((t - 8.5) / 1.2, 0.0, 1.0) * 0.8
	var n_shown := int(clampf((t - 1.4) / 1.8, 0.0, 1.0) * crowd.size())
	for i in n_shown:
		var cp: Dictionary = crowd[i]
		var foot := Vector3(float(cp["x"]) + sin(t * 1.3 + float(cp["ph"])) * 0.06, 0.0, float(cp["z"]) - surge)
		var h := 1.75 * depth_scale(foot)
		var lit := clampf(1.0 - absf(foot.x - beam_x) / 2.4, 0.0, 1.0) * clampf(1.0 - absf(foot.z - 41.0) / 6.0, 0.0, 1.0)
		var arm: bool = cp["arm"] and (sin(t * 2.0 + float(cp["ph"])) > -0.6)
		C.person_front(self, P(foot), h, cp["col"], int(cp["s"]), arm, String(cp["sign"]), lit)
	# barriers: yellow and black A-frames across the street
	if t > 2.3:
		for bk in 7:
			var bx := -6.0 + bk * 2.0
			_barrier(Vector3(bx, 0, 35.2 - surge * 0.3), Vector3(bx + 1.7, 0, 35.2 - surge * 0.3), 800 + bk, rev(2.3 + bk * 0.06, 0.3))
	# the searchlight's throw over the crowd (drawn over the people it lights)
	if t > 3.5:
		var flick := 0.5 if (t < 3.8 and fmod(t * 14.0, 1.0) < 0.5) else 1.0
		var head := P(Vector3(9.5, 9.0, 47.0))
		var spot := Vector3(beam_x, 0.0, 41.0)
		var ell := ground_ellipse(spot, 2.6, 2.2, 900)
		var poly := PackedVector2Array([head])
		var best_l := 0
		var best_r := 0
		for k3 in ell.size():
			if ell[k3].x < ell[best_l].x:
				best_l = k3
			if ell[k3].x > ell[best_r].x:
				best_r = k3
		poly.append(ell[best_l])
		var k4 := best_l
		while k4 != best_r:
			k4 = (k4 + 1) % ell.size()
			poly.append(ell[k4])
		var am := C.AMBER
		am.a = 0.42 * flick
		C.hatch(self, poly, am, 3.6, 0.9, 901, 2.6)
		var am2 := C.ORANGE
		am2.a = 0.5 * flick
		C.hatch(self, ell, am2, 3.0, -0.4, 902, 2.6)
		draw_circle(head, 9.0, C.CHARCOAL)
		draw_circle(head, 5.0, C.AMBER.lightened(0.3))
		C.line(self, head, P(Vector3(9.5, 0.0, 47.0)), C.CHARCOAL, 4.0, 903, 0.6, 2)
	# the riot line, stepping forward when the crowd surges
	if t > 2.6:
		var step := clampf((t - 9.0) / 0.8, 0.0, 1.0) * 1.0
		var shown_p := int(clampf((t - 2.6) / 1.0, 0.0, 1.0) * police.size())
		for j in shown_p:
			var pc2: Dictionary = police[j]
			var foot2 := Vector3(float(pc2["x"]), 0.0, float(pc2["z"]) + step * 0.6)
			var lit2 := clampf(1.0 - absf(foot2.x - beam_x) / 3.0, 0.0, 1.0) * 0.4
			C.riot_officer(self, P(foot2), 1.85 * depth_scale(foot2), int(pc2["s"]), lit2)
	# ---------------------------------------------------------------- near blocks (rooftops)
	for bi2 in [2, 3]:
		_block(BLOCKS[bi2], rev(0.8 + (bi2 - 2) * 0.2, 0.9))
	for li3 in lamps.size():
		var lp3: Vector3 = lamps[li3]
		if lp3.z <= 40.0 and t > 1.1:
			_lamp(lp3, 720 + li3)
	# ---------------------------------------------------------------- weather and words
	C.rain(self, page, 260, 99, -0.2, 40.0)
	_captions()


## A brick block: the faces the camera sees (the side on the street, the end facing the
## camera), the roof; windows as dark ticks, a few lit; VOTE posters at street level.
func _block(b: Array, reveal: float) -> void:
	if reveal <= 0.0:
		return
	var x0: float = b[0]
	var x1: float = b[1]
	var z0: float = b[2]
	var z1: float = b[3]
	var h: float = b[4]
	var s: int = b[5]
	var inner_x := x1 if x1 < 0.0 else x0
	# the side on the street
	var side := quad(Vector3(inner_x, 0, z0), Vector3(inner_x, 0, z1), Vector3(inner_x, h, z1), Vector3(inner_x, h, z0))
	draw_colored_polygon(side, C.BRICK_DARK)
	C.hatch(self, side, C.BRICK, 3.0, -0.2, s, 2.6, reveal)
	# mortar courses
	for course in int(h / 1.2):
		var y := (course + 0.5) * 1.2
		var mc := C.CHARCOAL
		mc.a = 0.35
		C.line(self, P(Vector3(inner_x, y, z0)), P(Vector3(inner_x, y, z1)), mc, 1.0, s * 7 + course, 0.6, 1, reveal)
	# windows along the street side
	if reveal >= 1.0:
		var nz := int((z1 - z0) / 3.2)
		var ny := int((h - 3.0) / 3.0)
		for iz in nz:
			for iy in ny:
				var zc := z0 + 1.6 + iz * 3.2
				var yc := 3.6 + iy * 3.0
				var lit := C.rnd(s + iz, iy) < 0.12
				var wq := quad(Vector3(inner_x, yc, zc - 0.6), Vector3(inner_x, yc, zc + 0.6), Vector3(inner_x, yc + 1.5, zc + 0.6), Vector3(inner_x, yc + 1.5, zc - 0.6))
				draw_colored_polygon(wq, C.AMBER if lit else C.CHARCOAL)
				if lit:
					C.hatch(self, wq, C.ORANGE, 2.4, 0.5, s + iz * 11 + iy, 1.4)
		# posters at street level: VOTE, crossed in red
		for pz in 4:
			var zc2 := z0 + 3.0 + pz * 2.4 + C.rnd(s, pz) * 1.2
			if zc2 > z1 - 1.0:
				break
			var pq := quad(Vector3(inner_x, 1.0, zc2 - 0.6), Vector3(inner_x, 1.0, zc2 + 0.6), Vector3(inner_x, 2.6, zc2 + 0.6), Vector3(inner_x, 2.6, zc2 - 0.6))
			draw_colored_polygon(pq, C.CHALK.darkened(0.12))
			var pc := (pq[0] + pq[2]) * 0.5
			var ph := absf(pq[2].y - pq[1].y)
			if ph > 14.0:
				C.letters(self, "VOTE", pq[3] + Vector2(2, ph * 0.45), int(ph * 0.24), C.CHARCOAL, s + pz, 1)
				C.line(self, pc + Vector2(-ph * 0.18, -ph * 0.05), pc + Vector2(ph * 0.18, ph * 0.3), C.RED, 2.4, s + pz + 5, 0.8, 1)
				C.line(self, pc + Vector2(ph * 0.18, -ph * 0.05), pc + Vector2(-ph * 0.18, ph * 0.3), C.RED, 2.4, s + pz + 6, 0.8, 1)
	C.outline(self, side, C.CHARCOAL, 2.0, s + 1, 1.0, reveal)
	# the end facing the camera (only the far blocks show theirs)
	if z0 > cam.z + 5.0:
		var front := quad(Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, h, z0), Vector3(x0, h, z0))
		draw_colored_polygon(front, C.BRICK_DARK.darkened(0.2))
		C.hatch(self, front, C.BRICK.darkened(0.15), 3.2, 0.25, s + 2, 2.4, reveal)
		if reveal >= 1.0:
			var nx := int((x1 - x0) / 3.2)
			for ix in nx:
				for iy2 in int((h - 3.0) / 3.0):
					var xc := x0 + 1.6 + ix * 3.2
					var yc2 := 3.6 + iy2 * 3.0
					var lit2 := C.rnd(s + 50 + ix, iy2) < 0.1
					var wq2 := quad(Vector3(xc - 0.6, yc2, z0), Vector3(xc + 0.6, yc2, z0), Vector3(xc + 0.6, yc2 + 1.5, z0), Vector3(xc - 0.6, yc2 + 1.5, z0))
					draw_colored_polygon(wq2, C.AMBER if lit2 else C.CHARCOAL)
		C.outline(self, front, C.CHARCOAL, 2.0, s + 3, 1.0, reveal)
	# the roof
	var roof := quad(Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, h, z1), Vector3(x0, h, z1))
	draw_colored_polygon(roof, C.GRAPHITE.darkened(0.2))
	C.hatch(self, roof, C.CHARCOAL, 3.4, 0.6, s + 4, 2.4, reveal)
	C.outline(self, roof, C.CHARCOAL, 2.2, s + 5, 1.0, reveal)
	if reveal >= 1.0:
		# roof clutter: a vent, a hatch
		var rc := Vector3((x0 + x1) * 0.5, h, (z0 + z1) * 0.5)
		var vq := quad(rc + Vector3(-1.5, 0, -1.0), rc + Vector3(1.5, 0, -1.0), rc + Vector3(1.5, 0, 1.0), rc + Vector3(-1.5, 0, 1.0))
		draw_colored_polygon(vq, C.GRAPHITE.lightened(0.15))
		C.outline(self, vq, C.CHARCOAL, 1.6, s + 6, 0.6)


func _lamp(base: Vector3, s: int) -> void:
	var top := base + Vector3(0, 7.5, 0)
	var arm := top + Vector3(-signf(base.x) * 1.4, 0, 0)
	C.line(self, P(base), P(top), C.CHARCOAL, 3.0, s, 0.5, 2)
	C.line(self, P(top), P(arm), C.CHARCOAL, 3.0, s + 1, 0.5, 2)
	var hp := P(arm)
	C.pool(self, hp, 22, 16, C.AMBER, s + 2, 0.75)
	draw_circle(hp, 4.0, C.AMBER.lightened(0.4))


func _barrier(a: Vector3, b: Vector3, s: int, reveal: float) -> void:
	if reveal <= 0.0:
		return
	var top_a := a + Vector3(0, 1.0, 0)
	var top_b := b + Vector3(0, 1.0, 0)
	var band := quad(a + Vector3(0, 0.55, 0), b + Vector3(0, 0.55, 0), top_b, top_a)
	draw_colored_polygon(band, C.TAPE)
	for k in 5:
		var f0 := k / 5.0
		var p0 := band[3].lerp(band[2], f0)
		var p1 := band[0].lerp(band[1], f0 + 0.12)
		C.line(self, p0, p1, C.CHARCOAL, 3.0, s + k, 0.5, 1)
	C.outline(self, band, C.CHARCOAL, 1.6, s + 9, 0.5)
	for leg: Vector3 in [a, b]:
		C.line(self, P(leg + Vector3(0, 1.0, 0)), P(leg + Vector3(0, 0, -0.35)), C.CHARCOAL, 2.4, s + 20, 0.4, 1)
		C.line(self, P(leg + Vector3(0, 1.0, 0)), P(leg + Vector3(0, 0, 0.35)), C.CHARCOAL, 2.4, s + 21, 0.4, 1)


func _van(c: Vector3) -> void:
	var ph := t * 1.8
	var k := depth_scale(c)
	C.police_smear(self, P(c), k * 4.2, ph, 650)
	var L := 6.4
	var Wd := 2.2
	var H := 2.2
	var x0 := c.x - Wd * 0.5
	var x1 := c.x + Wd * 0.5
	var z0 := c.z - L * 0.5
	var z1 := c.z + L * 0.5
	var back := quad(Vector3(x0, 0.3, z0), Vector3(x1, 0.3, z0), Vector3(x1, H, z0), Vector3(x0, H, z0))
	var side := quad(Vector3(x1, 0.3, z0), Vector3(x1, 0.3, z1), Vector3(x1, H, z1), Vector3(x1, H, z0))
	var top := quad(Vector3(x0, H, z0), Vector3(x1, H, z0), Vector3(x1, H, z1), Vector3(x0, H, z1))
	for q: PackedVector2Array in [side, back, top]:
		draw_colored_polygon(q, C.NAVY)
		C.hatch(self, q, C.CHARCOAL, 3.0, 0.7, 660, 1.8)
		C.outline(self, q, C.CHARCOAL, 2.0, 661, 0.6)
	# the windscreen and a chalk stripe down the side
	var ws := quad(Vector3(x0 + 0.15, 1.2, z0 - 0.01), Vector3(x1 - 0.15, 1.2, z0 - 0.01), Vector3(x1 - 0.2, H - 0.2, z0 - 0.01), Vector3(x0 + 0.2, H - 0.2, z0 - 0.01))
	draw_colored_polygon(ws, C.SLATE_LIGHT)
	C.line(self, P(Vector3(x1 + 0.01, 1.0, z0 + 0.3)), P(Vector3(x1 + 0.01, 1.0, z1 - 0.3)), C.CHALK, 3.0, 662, 0.4, 1)
	for wz: float in [z0 + 1.0, z1 - 1.0]:
		draw_circle(P(Vector3(x1, 0.3, wz)), 0.38 * k, C.CHARCOAL)
	var red_on := fmod(ph, 1.0) < 0.5
	draw_circle(P(Vector3(x0 + 0.5, H + 0.15, z0 + 0.6)), 4.0, C.RED if red_on else C.RED.darkened(0.6))
	draw_circle(P(Vector3(x1 - 0.5, H + 0.15, z0 + 0.6)), 4.0, C.BLUE.darkened(0.6) if red_on else C.BLUE)


## The captions: crayon capitals printed on as you watch, on a torn strip.
func _captions() -> void:
	var lines := [[5.0, "WEEK 40."], [6.6, "THE CITY VOTES TONIGHT."], [9.6, "SOMEBODY HAS TO HOLD THE LINE."]]
	var shown := []
	for l: Array in lines:
		if t > float(l[0]):
			shown.append(l)
	if shown.is_empty():
		return
	var strip := PackedVector2Array([Vector2(60, 742), Vector2(980, 736), Vector2(986, 862), Vector2(56, 870)])
	var sc := C.PAPER_CREAM
	sc.a = 0.94
	draw_colored_polygon(strip, sc)
	C.outline(self, strip, C.GRAPHITE, 1.4, 1200, 0.8)
	var last: Array = shown[shown.size() - 1]
	var prev: Array = shown[shown.size() - 2] if shown.size() >= 2 else []
	if not prev.is_empty():
		C.letters(self, String(prev[1]), Vector2(84, 784), 26, C.GRAPHITE, 1210, 1, 1.0)
	C.letters(self, String(last[1]), Vector2(84, 840), 40, C.CHARCOAL, 1220 + shown.size(), 3, 1.0, clampf((t - float(last[0])) / 1.2, 0.0, 1.0))
	# the stamp
	if t > 11.0:
		var org := Vector2(1080, 770)
		var a := clampf((t - 11.0) / 0.25, 0.0, 1.0)
		var box := PackedVector2Array([org, org + Vector2(440, -18), org + Vector2(450, 72), org + Vector2(8, 90)])
		var rc := C.RED
		rc.a = 0.9 * a
		C.outline(self, box, rc, 4.0, 1300, 1.0)
		C.letters(self, "FILED. NOT RESOLVED.", org + Vector2(26, 60), 34, rc, 1301, 2)
