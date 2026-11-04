extends Node2D
## Prototype 1 — the operation, top-down, in the overhaul's hand. A night warrant at
## the Center-Hall Bungalow (map 4): the page draws itself (ground, street, the house,
## its rooms in the dark, the furniture), rain starts, the stack crosses from the
## cruiser to the front door with weapon lights on, and each room is drawn up out of
## the dark as an officer sees into it. In the kitchen a man raises a pistol; the point
## man fires; red goes onto the page slowly; the evidence markers follow.
##
## Scripted, not simulated: this is a look prototype. It reads the real map (rooms,
## walls, doors, windows, props) from the registry.

const C = preload("res://scripts/view/crayon.gd")
const Maps = preload("res://scripts/maps/registry.gd")

const MAP := 4
const VIEW := Rect2(0.0, 5.5, 40.0, 22.5)   # metres on screen, wide
const VIEW_IN := Rect2(9.5, 9.0, 21.0, 11.8)  # the camera closes in on the house as the stack goes in

var level
var t := 0.0
var _bt := 0.0
var px := 40.0
var origin := Vector2.ZERO
var paper: ImageTexture
var seen := {}          # room -> 0..1 drawn up out of the dark

# officer paths: [time, x, y]
const PATHS := [
	[[3.5, 18.5, 25.5], [5.0, 20.0, 22.2], [5.6, 20.0, 20.6], [6.4, 20.0, 18.0], [6.9, 20.0, 16.6], [7.6, 22.2, 16.5], [8.4, 24.0, 16.9]],
	[[3.5, 19.5, 25.9], [5.2, 20.3, 22.6], [5.9, 20.2, 20.8], [6.7, 20.1, 18.4], [7.2, 20.3, 16.9], [8.0, 22.0, 15.6], [8.6, 23.0, 14.9]],
	[[3.5, 20.5, 26.1], [5.4, 19.8, 22.9], [6.1, 19.9, 21.0], [6.9, 19.9, 18.6], [7.4, 19.6, 16.6], [8.2, 17.6, 16.4], [9.0, 15.8, 16.6]],
	[[3.5, 21.5, 26.3], [5.6, 20.6, 23.2], [6.4, 20.0, 21.4], [7.2, 20.0, 19.2], [7.8, 20.0, 18.6]],
]
const SUSPECT := Vector2(26.0, 18.2)
const CIVILIAN := Vector2(14.3, 13.9)
const SHOT_T := 8.62


func _ready() -> void:
	level = Maps.get_level(MAP)
	var vp := get_viewport_rect().size
	_camera()
	paper = C.paper_texture(Vector2i(int(vp.x / 2), int(vp.y / 2)), C.PAPER_GREY, 21, 1.6)
	for rn in level.rooms:
		seen[rn] = 0.0


## Wide while the page draws, then a slow push in on the house (the player's zoom).
func _camera() -> void:
	var vp := get_viewport_rect().size
	var f := clampf((t - 4.2) / 3.2, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	var v := Rect2(VIEW.position.lerp(VIEW_IN.position, f), VIEW.size.lerp(VIEW_IN.size, f))
	px = minf(vp.x / v.size.x, vp.y / v.size.y)
	origin = (vp - v.size * px) * 0.5 - v.position * px


func _process(delta: float) -> void:
	t += delta
	_camera()
	_bt += delta
	if _bt >= 0.125:
		_bt = 0.0
		C.frame += 1
	# rooms come up out of the dark as officers see into them
	for rn in level.rooms:
		var occupied := false
		for i in PATHS.size():
			var p := _pos(i)
			for rr in level.rooms[rn]["rects"]:
				if (rr as Rect2).grow(0.4).has_point(p):
					occupied = true
		if occupied:
			seen[rn] = minf(1.0, float(seen[rn]) + delta * 1.6)
	queue_redraw()


func W(p: Vector2) -> Vector2:
	return origin + p * px


func WR(r: Rect2) -> Rect2:
	return Rect2(W(r.position), r.size * px)


func rev(start: float, dur := 0.6) -> float:
	return clampf((t - start) / dur, 0.0, 1.0)


func _pos(i: int) -> Vector2:
	var path: Array = PATHS[i]
	if t <= float(path[0][0]):
		return Vector2(path[0][1], path[0][2])
	for k in path.size() - 1:
		var a: Array = path[k]
		var b: Array = path[k + 1]
		if t <= float(b[0]):
			var f := (t - float(a[0])) / (float(b[0]) - float(a[0]))
			f = f * f * (3.0 - 2.0 * f)
			return Vector2(a[1], a[2]).lerp(Vector2(b[1], b[2]), f)
	var e: Array = path[path.size() - 1]
	return Vector2(e[1], e[2])


func _facing(i: int) -> float:
	var p := _pos(i)
	var t0 := t
	t = t0 + 0.15
	var q := _pos(i)
	t = t0
	if q.distance_to(p) > 0.01:
		return (q - p).angle()
	match i:
		0, 1:
			return (SUSPECT - p).angle()
		2:
			return (CIVILIAN - p).angle()
	return -PI / 2.0


func _draw() -> void:
	var vp := get_viewport_rect()
	draw_texture_rect(paper, vp, false)
	var page := WR(Rect2(0, 0, level.W, level.H)).intersection(vp.grow(-14))
	# ---------------------------------------------------------------- 1. the ground
	C.charcoal(self, C.rect_poly(page), C.GRAPHITE, 3.2, 3, rev(0.0, 1.0), 2.6)
	var yard := WR(Rect2(0, 0, level.W, 22.6))
	var moss := C.MOSS.darkened(0.35)
	moss.a = 0.85
	C.hatch(self, C.rect_poly(yard.intersection(page)), moss, 6.0, 0.9, 5, 3.0, rev(0.3, 1.0), 0.3)
	# the sidewalk and the street
	var walk := WR(Rect2(0, 22.6, level.W, 1.1)).intersection(page)
	var mc := C.MOSS
	mc.a = 0.8
	C.hatch(self, C.rect_poly(walk), mc, 3.2, -0.2, 7, 2.6, rev(0.6, 0.6))
	var street := WR(Rect2(0, 23.7, level.W, 4.3)).intersection(page)
	var sl := C.SLATE
	sl.a = 0.9
	C.hatch(self, C.rect_poly(street), sl, 3.6, -0.15, 9, 2.8, rev(0.7, 0.8))
	if t > 1.2:
		for k in 8:
			var x := 1.5 + k * 5.0
			C.line(self, W(Vector2(x, 26.0)), W(Vector2(x + 2.2, 26.0)), C.CHALK.darkened(0.25), 3.0, 70 + k, 0.8, 1)
	# trees: dark loops
	var tk := 0
	for pr in level.props:
		if pr["key"] == "yard/tree":
			var tr: Rect2 = WR(pr["r"])
			var tp := C.ellipse_poly(tr.get_center(), tr.size.x * 0.5, tr.size.y * 0.5, 16, 80 + tk, 0.18)
			var tc := C.MOSS.darkened(0.55)
			tc.a = 0.9
			C.charcoal(self, tp, tc, 3.0, 80 + tk, rev(1.0 + tk * 0.1, 0.5))
			if t > 1.4 + tk * 0.1:
				for l in 5:
					C.outline(self, C.ellipse_poly(tr.get_center() + Vector2(C.rnd(tk, l) - 0.5, C.rnd(tk + 3, l) - 0.5) * tr.size * 0.4, tr.size.x * 0.18, tr.size.y * 0.16, 9, tk * 10 + l, 0.3), C.CHARCOAL, 1.4, tk * 10 + l, 0.6)
			tk += 1
	# ---------------------------------------------------------------- 2. the house, in the dark
	var rk := 0
	for rn in level.rooms:
		var rm: Dictionary = level.rooms[rn]
		for rr in rm["rects"]:
			var r: Rect2 = WR(rr)
			var lit: float = float(seen.get(rn, 0.0))
			var base := C.SLATE.lerp(C.SLATE_LIGHT, lit * 0.6)
			C.charcoal(self, C.rect_poly(r), base, 3.2, 100 + rk, rev(1.2 + rk * 0.08, 0.5), 2.4)
			# unseen rooms keep a second charcoal layer: the dark is drawn, not tinted
			if lit < 1.0:
				var dk := C.CHARCOAL
				dk.a = 0.85 * (1.0 - lit)
				C.hatch(self, C.rect_poly(r), dk, 3.0, 1.1, 130 + rk, 2.6, rev(1.4 + rk * 0.08, 0.5))
			rk += 1
	# the hall's red light (the plates' alarm-lit corridor)
	if t > 2.0:
		var hall: Rect2 = WR(level.rooms["HALL"]["rects"][0])
		var hc := C.RED
		hc.a = 0.42 + 0.08 * sin(t * 2.0)
		C.hatch(self, C.rect_poly(hall.grow(-2)), hc, 3.6, 1.35, 150, 2.4)
		var hc2 := C.RED.lightened(0.2)
		hc2.a = 0.35
		C.hatch(self, C.rect_poly(Rect2(hall.position + Vector2(hall.size.x * 0.2, 4), Vector2(hall.size.x * 0.6, hall.size.y * 0.45))), hc2, 3.0, 1.6, 151, 2.0)
		C.pool(self, hall.position + Vector2(hall.size.x * 0.5, 10), hall.size.x * 0.22, hall.size.x * 0.18, C.RED.lightened(0.3), 152, 0.9)
	# window spill: orange light lying on the floor inside each window
	var wk := 0
	for win in level.windows:
		var wr: Rect2 = win["r"]
		var c: Vector2 = wr.get_center()
		var inside := _room_at(c + Vector2(0, 0.6)) if win["axis"] == "h" else _room_at(c + Vector2(0.6, 0))
		var dir := Vector2(0, 1)
		if inside == "":
			inside = _room_at(c - Vector2(0, 0.6)) if win["axis"] == "h" else _room_at(c - Vector2(0.6, 0))
			dir = Vector2(0, -1) if win["axis"] == "h" else Vector2(-1, 0)
		elif win["axis"] == "v":
			dir = Vector2(1, 0)
		if inside != "" and t > 2.2 + wk * 0.04 and wk % 3 != 1:
			# the window's shape thrown across the floor, slanted, as the plates draw it
			var along := Vector2(1, 0) if win["axis"] == "h" else Vector2(0, 1)
			var span := wr.size.x if win["axis"] == "h" else wr.size.y
			var a0 := c - along * span * 0.5 + dir * 0.15
			var a1 := c + along * span * 0.5 + dir * 0.15
			var slant := along * 0.45
			var patch := PackedVector2Array([W(a0), W(a1), W(a1 + dir * 1.3 + slant), W(a0 + dir * 1.3 + slant)])
			var oc := C.ORANGE
			oc.a = 0.62
			C.hatch(self, patch, oc, 3.0, 0.9, 160 + wk, 2.6)
			# window bars across the patch
			var mid0 := (patch[0] + patch[3]) * 0.5
			var mid1 := (patch[1] + patch[2]) * 0.5
			C.line(self, mid0, mid1, C.CHARCOAL, 1.6, 170 + wk, 0.6, 1)
		wk += 1
	# walls pressed hard; the fence as chain link
	var wn := 0
	for wi in level.walls:
		var ob: Dictionary = level.geom.obs[wi]
		var r2: Rect2 = WR(ob["r"])
		var rv := rev(2.4 + wn * 0.015, 0.3)
		if rv <= 0.0:
			wn += 1
			continue
		if String(ob.get("name", "")) == "fence":
			var fc := C.GRAPHITE.lightened(0.25)
			C.line(self, r2.position, r2.end, fc, 2.0, 200 + wn, 1.0, 1, rv)
			wn += 1
			continue
		draw_rect(r2.grow(1.5), C.CHARCOAL)
		C.outline(self, C.rect_poly(r2.grow(2.0)), C.CHARCOAL, 2.6, 300 + wn, 1.2, rv)
		wn += 1
	# windows: cold glass lines across the wall
	var gk := 0
	for win2 in level.windows:
		var g: Rect2 = WR(win2["r"])
		var gc := C.SLATE_LIGHT.lightened(0.2)
		if win2["axis"] == "h":
			C.line(self, Vector2(g.position.x, g.get_center().y), Vector2(g.end.x, g.get_center().y), gc, 3.0, 400 + gk, 0.6, 2, rev(2.8, 0.3))
		else:
			C.line(self, Vector2(g.get_center().x, g.position.y), Vector2(g.get_center().x, g.end.y), gc, 3.0, 400 + gk, 0.6, 2, rev(2.8, 0.3))
		gk += 1
	# doors: an open leaf and its swing
	var dk2 := 0
	for did in level.doors:
		var d: Dictionary = level.doors[did]
		if d.get("arch", false):
			continue
		var dc := W(d["c"])
		var half := float(d["half"]) * px
		var tt: Vector2 = d["t"]
		var nn: Vector2 = d["n"]
		var hinge := dc - tt * half
		var leaf_end := hinge + nn * half * 2.0
		C.line(self, hinge, leaf_end, C.CHALK.darkened(0.35), 2.4, 500 + dk2, 0.8, 1, rev(3.0, 0.3))
		if t > 3.1:
			var arc := PackedVector2Array()
			for a in 7:
				var f := a / 6.0
				arc.append(hinge + (nn * cos(f * PI / 2.0) + tt * sin(f * PI / 2.0)) * half * 2.0)
			var ac := C.CHALK
			ac.a = 0.25
			draw_polyline(arc, ac, 1.2, true)
		dk2 += 1
	# ---------------------------------------------------------------- 3. what is in the rooms
	var pk := 0
	for pr2 in level.props:
		if pr2["key"] == "yard/tree":
			continue
		var room := _room_at(Rect2(pr2["r"]).get_center())
		var lit2: float = 1.0 if room == "" else float(seen.get(room, 0.0))
		var rv2 := rev(3.0 + pk * 0.03, 0.35)
		if rv2 > 0.0:
			_prop(pr2, pk, rv2, lit2)
		pk += 1
	# ---------------------------------------------------------------- 4. the street at night
	var lamps := [Vector2(7.0, 23.4), Vector2(33.0, 23.4), Vector2(20.0, 23.4)]
	for li in lamps.size():
		if t > 1.6 + li * 0.2:
			C.lamp_top(self, W(lamps[li]), px * 2.0, 600 + li)
	_puddles()
	_cruiser(W(Vector2(14.0, 25.6)))
	# ---------------------------------------------------------------- 5. people
	var s := px / 40.0 * 0.95
	if t > 3.2:
		# weapon lights first, under the figures
		for i in PATHS.size():
			var p := _pos(i)
			if p.y < 21.5:
				C.cone(self, W(p), _facing(i), px * 3.6, 0.3, C.AMBER, 700 + i, 0.45, 3.4)
		# the man in the kitchen
		var sp2 := W(SUSPECT)
		var down := t > SHOT_T + 0.12
		# the fog of war: nobody is drawn until an officer has seen into their room
		var see_k: float = float(seen.get("KITCHEN", 0.0))
		var see_l: float = float(seen.get("LIVING", 0.0))
		if see_k < 0.3:
			pass
		elif down:
			var rvb := rev(SHOT_T + 0.2, 2.6)
			var bp := C.ellipse_poly(sp2 + Vector2(-8, 6) * s, 30 * s * rvb + 2, 18 * s * rvb + 2, 16, 777, 0.3)
			C.hatch(self, bp, C.BLOOD.lightened(0.15), 2.4, 0.8, 778, 3.0)
			C.hatch(self, bp, C.RED.darkened(0.2), 4.0, -0.5, 779, 2.0, 1.0, 0.4)
			# the trail towards the drain, as in the evidence plate
			if t > SHOT_T + 1.4:
				C.line(self, sp2 + Vector2(-10, 14) * s, sp2 + Vector2(-30, 40) * s, C.BLOOD, 5.0, 780, 2.5, 2, rev(SHOT_T + 1.4, 2.0))
			C.figure(self, sp2, 2.6, C.UMBER.lightened(0.15), "suspect", 950, 0.0, 0.0, false, true, s)
		else:
			var aim := clampf((t - 8.2) / 0.35, 0.0, 1.0)
			C.figure(self, sp2, (W(_pos(0)) - sp2).angle() if t > 7.6 else PI, C.UMBER.lightened(0.15), "suspect", 950, 0.0, aim, true, false, s)
		# the woman on the sofa: hands up when the light finds her
		var up := t > 9.0
		if see_l >= 0.3:
			C.figure(self, W(CIVILIAN), PI / 2.0, C.ORANGE.darkened(0.15), "civilian", 970, 0.0, 0.0, false, false, s, up)
		for i2 in PATHS.size():
			var p2 := _pos(i2)
			var moving := p2.distance_to(_pos_at(i2, t - 0.1)) > 0.01
			C.figure(self, W(p2), _facing(i2), C.NAVY, "police" if i2 % 2 == 0 else "tactical", 900 + i2 * 7, t * 9.0 + i2 if moving else 0.0, 1.0 if i2 < 2 else 0.6, true, false, s)
		# the shot: an amber star at the point man's muzzle
		if t > SHOT_T and t < SHOT_T + 0.16:
			var mz := W(_pos(0)) + Vector2.RIGHT.rotated(_facing(0)) * 44 * s
			for k in 9:
				var a := TAU * k / 9.0
				C.stroke(self, mz, mz + Vector2(cos(a), sin(a)) * (18 + 10 * C.rnd(k, 3)), C.AMBER, 4.0, 990 + k, 0.5)
		# evidence: the markers go down one by one
		if t > SHOT_T + 2.4:
			var marks := [W(_pos(0)) + Vector2(18, 26), sp2 + Vector2(30, -20), sp2 + Vector2(-34, 10) * s, W(Vector2(23.2, 17.8))]
			for m in marks.size():
				if t > SHOT_T + 2.4 + m * 0.5:
					C.evidence(self, marks[m], m + 1, 1000 + m, 1.1)
	# ---------------------------------------------------------------- 6. weather and paperwork
	if t > 1.8:
		C.rain(self, vp, 180, 55, -0.2, 34.0)
	_hud(vp)


func _pos_at(i: int, at: float) -> Vector2:
	var keep := t
	t = at
	var p := _pos(i)
	t = keep
	return p


func _room_at(p: Vector2) -> String:
	for rn in level.rooms:
		if level.rooms[rn].get("exterior", false):
			continue
		for rr in level.rooms[rn]["rects"]:
			if (rr as Rect2).has_point(p):
				return rn
	return ""


func _puddles() -> void:
	var ps := [[Vector2(10.5, 24.6), 1.6, 0.6, C.ORANGE], [Vector2(25.5, 26.8), 2.0, 0.7, C.RED], [Vector2(31.0, 24.4), 1.2, 0.5, C.ORANGE],
		[Vector2(4.0, 26.5), 1.4, 0.55, Color(0, 0, 0, 0)], [Vector2(17.0, 22.0), 0.9, 0.35, Color(0, 0, 0, 0)]]
	for k in ps.size():
		if t > 1.9 + k * 0.1:
			var e: Array = ps[k]
			C.puddle(self, W(e[0]), float(e[1]) * px, float(e[2]) * px, 650 + k, e[3])


## The cruiser at the kerb: a dark box, a white roof with POLICE, the light bar, and
## red and blue smeared across the wet street around it.
func _cruiser(c: Vector2) -> void:
	if t < 2.0:
		return
	C.police_smear(self, c, px * 3.4, t * 1.6, 680)
	var L := px * 4.6
	var Wd := px * 2.0
	var body := C.rect_poly(Rect2(c - Vector2(L, Wd) * 0.5, Vector2(L, Wd)))
	draw_colored_polygon(body, C.CHARCOAL)
	var roof := Rect2(c - Vector2(L * 0.24, Wd * 0.36), Vector2(L * 0.42, Wd * 0.72))
	draw_rect(roof, C.CHALK.darkened(0.12))
	C.hatch(self, C.rect_poly(roof), C.GRAPHITE, 4.0, 0.4, 681, 1.2, 1.0, 0.5)
	var red_on := fmod(t * 1.6, 1.0) < 0.5
	var bar_x := roof.position.x - px * 0.34
	draw_rect(Rect2(Vector2(bar_x, c.y - Wd * 0.42), Vector2(px * 0.26, Wd * 0.4)), C.RED if red_on else C.RED.darkened(0.5))
	draw_rect(Rect2(Vector2(bar_x, c.y + Wd * 0.02), Vector2(px * 0.26, Wd * 0.4)), C.BLUE.darkened(0.5) if red_on else C.BLUE)
	C.letters(self, "POLICE", roof.position + Vector2(5, roof.size.y * 0.64), int(px * 0.36), C.CHARCOAL, 682, 1, 0.82)
	C.outline(self, body, C.CHARCOAL, 2.4, 683, 1.0)
	for sx: float in [-0.32, 0.3]:
		for sy: float in [-0.55, 0.55]:
			draw_rect(Rect2(c + Vector2(L * sx - px * 0.35, Wd * sy - px * 0.12), Vector2(px * 0.7, px * 0.24)), C.CHARCOAL)
	# the windscreen, front and back, dark with a glint
	for side: float in [1.0, -1.0]:
		var ws := PackedVector2Array([c + Vector2(side * L * 0.22, -Wd * 0.38), c + Vector2(side * L * 0.34, -Wd * 0.32), c + Vector2(side * L * 0.34, Wd * 0.32), c + Vector2(side * L * 0.22, Wd * 0.38)])
		draw_colored_polygon(ws, C.SLATE)
		C.stroke(self, ws[0] + Vector2(side * 3, 6), ws[1] + Vector2(-side * 2, 10), C.CHALK, 1.5, 690 + int(side))


## One piece of furniture or yard clutter, with the one detail a child would draw.
func _prop(pr: Dictionary, k: int, reveal: float, lit: float) -> void:
	var r: Rect2 = WR(pr["r"])
	var key: String = String(pr["key"]).get_file()
	var s := 1100 + k * 17
	var dark := 1.0 - lit
	var tone := func(col: Color) -> Color: return col.lerp(C.CHARCOAL, dark * 0.65)
	var line_c: Color = C.CHARCOAL
	var fill := func(col: Color, sp := 3.4, ang := 0.6) -> void:
		var cc: Color = tone.call(col)
		cc.a = 0.9
		C.hatch(self, C.rect_poly(r), cc, sp, ang, s, 2.4, reveal)
	match key:
		"bed":
			fill.call(C.SLATE_LIGHT, 3.2)
			var long_x := r.size.x >= r.size.y
			var pil := Rect2(r.position + Vector2(3, 3), Vector2(r.size.x * 0.22, r.size.y * 0.42)) if long_x else Rect2(r.position + Vector2(3, 3), Vector2(r.size.x * 0.42, r.size.y * 0.22))
			draw_rect(pil, tone.call(C.CHALK.darkened(0.2)))
			if long_x:
				draw_rect(pil.grow(0) if false else Rect2(pil.position + Vector2(0, r.size.y * 0.48), pil.size), tone.call(C.CHALK.darkened(0.2)))
			# the sheets: a tangle
			if reveal >= 1.0:
				var cen := r.get_center() + Vector2(r.size.x * 0.12, 0)
				var tangle := PackedVector2Array()
				for a in 26:
					tangle.append(cen + Vector2(cos(a * 1.9), sin(a * 2.7)) * Vector2(r.size.x * 0.28, r.size.y * 0.33) * (0.4 + 0.6 * C.rnd(s, a)))
				var tc: Color = tone.call(C.CHARCOAL)
				tc.a = 0.7
				draw_polyline(tangle, tc, 1.5, true)
		"sofa", "armchair":
			fill.call(C.GRAPHITE.lightened(0.15), 2.6, 1.0)
			var back := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.32))
			draw_rect(back, tone.call(C.CHARCOAL))
			for sx: float in [0.0, 1.0]:
				draw_rect(Rect2(r.position + Vector2(sx * (r.size.x - r.size.x * 0.14), 0), Vector2(r.size.x * 0.14, r.size.y)), tone.call(C.CHARCOAL))
		"coffee_table", "dining", "table", "desk":
			fill.call(C.UMBER.lightened(0.25), 4.0, -0.5)
			if reveal >= 1.0:
				for pp in 4:
					var q := r.position + Vector2(C.rnd(s, pp), C.rnd(s + 1, pp)) * r.size * 0.8 + r.size * 0.05
					var paper_c: Color = tone.call(C.CHALK.darkened(0.15))
					draw_rect(Rect2(q, Vector2(7, 9)).abs(), paper_c)
			if key == "dining":
				for ch in 4:
					var side := -1.0 if ch < 2 else 1.0
					var cx := r.position.x + r.size.x * (0.3 + 0.4 * (ch % 2))
					var cy := r.get_center().y + side * (r.size.y * 0.5 + 7)
					draw_rect(Rect2(cx - 6, cy - 5, 12, 10), tone.call(C.UMBER))
		"counter", "checkout":
			fill.call(C.SLATE_LIGHT.lightened(0.1), 3.0, 0.2)
			C.outline(self, C.ellipse_poly(r.get_center(), r.size.x * 0.12, r.size.y * 0.28, 10, s), tone.call(C.CHALK.darkened(0.3)), 1.6, s, 0.4)
		"stove":
			fill.call(C.GRAPHITE.lightened(0.3), 3.0)
			for ring in 4:
				var rc := r.position + Vector2(0.28 + 0.44 * (ring % 2), 0.3 + 0.4 * (ring / 2)) * r.size
				draw_arc(rc, minf(r.size.x, r.size.y) * 0.14, 0, TAU, 12, tone.call(C.CHARCOAL), 2.0, true)
		"fridge", "cooler", "cabinet", "lockers":
			fill.call(C.CHALK.darkened(0.35), 3.4, -0.3)
			C.line(self, r.position + Vector2(r.size.x * 0.12, r.size.y * 0.5), r.end - Vector2(r.size.x * 0.12, r.size.y * 0.5), line_c, 1.4, s + 5, 0.5, 1)
		"tub":
			fill.call(C.CHALK.darkened(0.3), 3.0, 0.9)
			C.outline(self, C.ellipse_poly(r.get_center(), r.size.x * 0.38, r.size.y * 0.32, 14, s), tone.call(C.SLATE), 1.8, s, 0.5)
		"toilet", "basin":
			var tp := C.ellipse_poly(r.get_center() + Vector2(0, r.size.y * 0.1), r.size.x * 0.45, r.size.y * 0.38, 12, s, 0.05)
			draw_colored_polygon(tp, tone.call(C.CHALK.darkened(0.25)))
			C.outline(self, tp, line_c, 1.4, s, 0.4)
			draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.25)), tone.call(C.CHALK.darkened(0.3)))
		"washer":
			fill.call(C.CHALK.darkened(0.3), 3.2)
			draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.32, 0, TAU, 14, tone.call(C.SLATE), 2.0, true)
		"dresser", "wardrobe", "bookshelf", "shelving", "rack":
			fill.call(C.UMBER, 3.4, 1.0)
			var n := 4
			for b in n:
				var bc: Color = [C.BRICK, C.MOSS, C.SLATE_LIGHT, C.AMBER.darkened(0.3)][b % 4]
				var along_x := r.size.x >= r.size.y
				var cell := Rect2(r.position + (Vector2(r.size.x * b / n, 0) if along_x else Vector2(0, r.size.y * b / n)), Vector2(r.size.x / n, r.size.y) if along_x else Vector2(r.size.x, r.size.y / n))
				if key == "bookshelf":
					draw_rect(cell.grow(-2), tone.call(bc))
				else:
					C.line(self, cell.position, cell.position + (Vector2(0, cell.size.y) if along_x else Vector2(cell.size.x, 0)), line_c, 1.2, s + b, 0.4, 1)
		"car", "van", "truck":
			_car(r, s, tone.call(C.BRICK.darkened(0.2)))
			return
		"shed", "container":
			fill.call(C.GRAPHITE.lightened(0.1), 3.0, 0.8)
			C.line(self, Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), line_c, 2.0, s + 3, 0.6, 2)
		"woodpile":
			for lg in 6:
				var lc := r.position + Vector2((lg + 0.5) / 6.0 * r.size.x, r.size.y * 0.5)
				draw_circle(lc, r.size.y * 0.32, C.UMBER.lightened(0.1))
				draw_arc(lc, r.size.y * 0.32, 0, TAU, 10, C.CHARCOAL, 1.4, true)
			return
		"drum", "bins":
			draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.5, C.GRAPHITE.lightened(0.2))
			draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.5, 0, TAU, 14, C.CHARCOAL, 2.0, true)
			draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.32, 0, TAU, 12, C.CHARCOAL, 1.2, true)
			return
		"hedge":
			C.charcoal(self, C.ellipse_poly(r.get_center(), r.size.x * 0.55, r.size.y * 0.55, 14, s, 0.2), C.MOSS.darkened(0.4), 2.6, s)
			return
		"low_wall":
			draw_rect(r, C.BRICK_DARK)
			C.hatch(self, C.rect_poly(r), C.BRICK, 6.0, PI / 2.0, s, 2.0)
		"picnic", "bench":
			fill.call(C.UMBER.lightened(0.1), 5.0, 0.0)
		"ac_unit", "generator", "tank":
			fill.call(C.SLATE_LIGHT, 3.0)
			draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.34, 0, TAU, 12, C.CHARCOAL, 1.6, true)
		_:
			fill.call(C.UMBER)
	C.outline(self, C.rect_poly(r), line_c, 1.8, s + 9, 0.9, reveal)


func _car(r: Rect2, s: int, col: Color) -> void:
	var c := r.get_center()
	var vertical := r.size.y > r.size.x
	var L := maxf(r.size.x, r.size.y)
	var Wd := minf(r.size.x, r.size.y)
	draw_set_transform(c, PI / 2.0 if vertical else 0.0, Vector2.ONE)
	var body := C.rect_poly(Rect2(Vector2(-L, -Wd) * 0.5, Vector2(L, Wd)))
	draw_colored_polygon(body, col)
	C.hatch(self, body, C.CHARCOAL, 3.4, 0.6, s, 1.8)
	draw_rect(Rect2(Vector2(-L * 0.22, -Wd * 0.38), Vector2(L * 0.42, Wd * 0.76)), col.lightened(0.15))
	for side: float in [1.0, -1.0]:
		var ws := PackedVector2Array([Vector2(side * L * 0.2, -Wd * 0.38), Vector2(side * L * 0.32, -Wd * 0.3), Vector2(side * L * 0.32, Wd * 0.3), Vector2(side * L * 0.2, Wd * 0.38)])
		draw_colored_polygon(ws, C.SLATE)
	for sx: float in [-0.3, 0.3]:
		for sy: float in [-0.55, 0.55]:
			draw_rect(Rect2(Vector2(L * sx - 8, Wd * sy - 3), Vector2(16, 6)), C.CHARCOAL)
	C.outline(self, body, C.CHARCOAL, 2.0, s + 1, 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The paperwork: the file name in crayon capitals, the clock, the radio on a scrap.
func _hud(vp: Rect2) -> void:
	if t < 0.6:
		return
	var scrap := PackedVector2Array([Vector2(26, 22), Vector2(560, 18), Vector2(566, 92), Vector2(22, 98)])
	draw_colored_polygon(scrap, C.PAPER_CREAM.darkened(0.08))
	C.outline(self, scrap, C.GRAPHITE, 1.4, 1500, 0.6)
	C.letters(self, "WARRANT  ·  41 FOUNDRY ST", Vector2(42, 56), 26, C.CHARCOAL, 1501, 2)
	var secs := maxi(0, int((t - 3.5) * 6.0))
	C.letters(self, "WEEK 12   NIGHT   00:%02d" % mini(59, secs), Vector2(44, 86), 18, C.BRICK, 1502, 2)
	var radio := []
	if t > 5.0:
		radio.append("A1: AT THE DOOR")
	if t > 6.6:
		radio.append("A1: HALL CLEAR")
	if t > 8.3:
		radio.append("A1: GUN! KITCHEN!")
	if t > SHOT_T + 0.6:
		radio.append("A1: ONE DOWN. MEDIC.")
	if t > 9.4:
		radio.append("A3: ONE CIVILIAN, HANDS UP")
	if radio.is_empty():
		return
	var h := 30.0 + radio.size() * 26.0
	var r := Rect2(Vector2(28, vp.size.y - h - 26), Vector2(360, h))
	var rp := C.rect_poly(r)
	draw_colored_polygon(rp, C.CHARCOAL)
	C.outline(self, rp, C.GRAPHITE.lightened(0.3), 1.4, 1510, 0.8)
	for i in radio.size():
		C.letters(self, radio[i], r.position + Vector2(14, 34 + i * 26), 18, C.CHALK if i < radio.size() - 1 else C.AMBER, 1520 + i, 2)
