extends Node2D
## Draws any level as an architectural floor plan in red ink (v0.8): paper, floors, grain,
## grid, then (on the Walls layer above the blood) poche walls, window triple-lines, door
## swings, room lettering, dimension strings and a title block with its stamps.
## Everything here is ink and stepped greys; red only reaches the plan through
## Ink.accent() on the stamps of a plan that has met a room.
##
## Two states, one map: "theory" (the briefing: clean, sparse, certain) and "application"
## (the live operation, the replay, the debrief: grit, scuffs, loose paper, the times and
## the forms). The topology never changes; only the rendering does.
## The site painters are static so a city lot can draw its template with them.

const Geom = preload("res://scripts/sim/geom.gd")
const Ink = preload("res://scripts/view/ink.gd")
const PX := 40.0

const PAPER := Ink.PAPER
const GRID := Color(0.45, 0.45, 0.44, 0.10)
const GRID_MAJOR := Color(0.45, 0.45, 0.44, 0.20)
const INK := Ink.INK
const LINE := Ink.DARK
const FAINT := Ink.MID
const HOUSE_FLOOR := Ink.FLOOR
const DECK := Ink.FLOOR
const ROAD := Ink.FLOOR

var level
## "theory" or "application"
var state := "theory"
## Application only: {"actual": seconds, "forms": n, "mop": bool, "filed": bool}
var stamp := {}
var walls: Node2D
var _rev := -1


func setup(lv) -> void:
	level = lv
	queue_redraw()
	if walls != null:
		walls.queue_redraw()


func set_state(st: String, info := {}) -> void:
	state = st
	stamp = info
	queue_redraw()
	if walls != null:
		walls.queue_redraw()


func _process(_d: float) -> void:
	if _rev != Ink.rev:
		_rev = Ink.rev
		queue_redraw()
		if walls != null:
			walls.queue_redraw()


func _draw() -> void:
	if level == null:
		return
	var font: Font = ThemeDB.fallback_font
	var W: float = level.W * PX
	var H: float = level.H * PX
	# paper sheet with a margin for the title block
	draw_rect(Rect2(-60, -60, W + 120, H + 236), PAPER)
	draw_rect(Rect2(-60, -60, W + 120, H + 236), INK, false, 2.0)
	draw_rect(Rect2(-48, -48, W + 96, H + 212), LINE, false, 1.0)
	draw_rect(Rect2(0, 0, W, H), PAPER)
	paint_floor(self, level, font)
	# grid over the floors: 1 m faint, 5 m darker
	for x in range(0, int(level.W) + 1):
		draw_line(Vector2(x * PX, 0), Vector2(x * PX, H), GRID_MAJOR if x % 5 == 0 else GRID, 1.0)
	for y in range(0, int(level.H) + 1):
		draw_line(Vector2(0, y * PX), Vector2(W, y * PX), GRID_MAJOR if y % 5 == 0 else GRID, 1.0)
	if not level.fenced:
		_dash_rect(self, Rect2(2, 2, W - 4, H - 4), FAINT)
	paint_print(self, level, state == "application")


## The print: sparse paper grain everywhere, a few halftone patches and corner hatching
## in the rooms. Application adds grit, scuffs and loose paper. Deterministic (modulo
## placement), so the same map always prints the same.
static func paint_print(ci: CanvasItem, lv, applied: bool) -> void:
	var W: float = lv.W * PX
	var H: float = lv.H * PX
	var n := int(lv.W * lv.H * (0.9 if not applied else 2.2))
	for i in n:
		var x := float((i * 73) % 1030) / 1030.0 * W
		var y := float((i * 151 + (i / 1030) * 37) % 997) / 997.0 * H
		ci.draw_rect(Rect2(x, y, 1.5, 1.5), Color(Ink.MID.r, Ink.MID.g, Ink.MID.b, 0.10 + 0.08 * float(i % 3)))
	var k := 0
	for name in lv.rooms:
		var rm: Dictionary = lv.rooms[name]
		if rm["exterior"]:
			continue
		for rv in rm["rects"]:
			var r: Rect2 = _r(rv)
			if r.size.x < 60.0 or r.size.y < 60.0:
				continue
			k += 1
			# corner hatching: a short run of diagonals in one corner, ink at low alpha
			var cs := minf(0.9 * PX, minf(r.size.x, r.size.y) * 0.3)
			var corner := k % 4
			var o := r.position + Vector2(r.size.x - cs if corner % 2 == 1 else 0.0, r.size.y - cs if corner >= 2 else 0.0)
			var step := 5.0
			var t := step
			while t < cs * 2.0:
				var a := Vector2(minf(t, cs), maxf(0.0, t - cs))
				var b := Vector2(maxf(0.0, t - cs), minf(t, cs))
				ci.draw_line(o + a, o + b, Color(Ink.DARK.r, Ink.DARK.g, Ink.DARK.b, 0.16), 1.0)
				t += step
			# a halftone patch in every third room, dots shrinking away from its corner
			if k % 3 == 0:
				var hp := r.position + Vector2(r.size.x * 0.62, r.size.y * 0.58)
				for gy in 6:
					for gx in 6:
						var rad := 2.2 - 0.32 * float(gx + gy)
						if rad <= 0.3:
							continue
						ci.draw_circle(hp + Vector2(gx, gy) * 7.0, rad, Color(Ink.DARK.r, Ink.DARK.g, Ink.DARK.b, 0.13))
			if not applied:
				continue
			# grit: scuffs where people moved, and a sheet of loose paper here and there
			for j in 5:
				var q := r.position + Vector2(float((k * 97 + j * 61) % 89) / 89.0 * r.size.x, float((k * 53 + j * 41) % 83) / 83.0 * r.size.y)
				var ang := float((k * 7 + j * 13) % 31) / 31.0 * PI
				ci.draw_line(q, q + Vector2.from_angle(ang) * (6.0 + float(j % 3) * 4.0), Color(Ink.DARK.r, Ink.DARK.g, Ink.DARK.b, 0.30), 1.0)
			if k % 2 == 1:
				var sp := r.position + Vector2(float((k * 131) % 71) / 71.0 * r.size.x * 0.7 + 8.0, float((k * 89) % 67) / 67.0 * r.size.y * 0.7 + 8.0)
				var rot := (float(k % 9) - 4.0) * 0.12
				var pts := PackedVector2Array()
				for c in [Vector2(-9, -12), Vector2(9, -12), Vector2(9, 12), Vector2(-9, 12)]:
					pts.append(sp + (c as Vector2).rotated(rot))
				ci.draw_colored_polygon(pts, Ink.PAPER)
				pts.append(pts[0])
				ci.draw_polyline(pts, Ink.LIGHT, 1.0)
				for ln in 4:
					var la := sp + Vector2(-6, -7 + ln * 4).rotated(rot)
					ci.draw_line(la, la + Vector2(10 - (ln % 2) * 4, 0).rotated(rot), Color(Ink.MID.r, Ink.MID.g, Ink.MID.b, 0.6), 1.0)


## Site notation, floors, walls (poche), fence posts, rails, windows and doors, in one
## pass (the city lots). The plan itself draws the floor and the walls on two layers.
static func paint_site(ci: CanvasItem, lv, font: Font) -> void:
	paint_floor(ci, lv, font)
	paint_walls(ci, lv, font)


## Site notation and floors: interior rooms flat Floor, decks (porches, walkways, patios)
## boarded.
static func paint_floor(ci: CanvasItem, lv, font: Font) -> void:
	for d in lv.decor:
		_decor(ci, d, font)
	for name in lv.rooms:
		var rm: Dictionary = lv.rooms[name]
		for rv in rm["rects"]:
			var r: Rect2 = rv
			if rm["deck"]:
				ci.draw_rect(_r(r), DECK)
				_boards(ci, r)
			elif not rm["exterior"]:
				ci.draw_rect(_r(r), HOUSE_FLOOR)


## Walls (poche), fence posts, rails, windows and doors.
static func paint_walls(ci: CanvasItem, lv, _font: Font) -> void:
	for idx in lv.walls:
		var o: Dictionary = lv.geom.obs[idx]
		var r2: Rect2 = _r(o["r"])
		match o["name"]:
			"fence":
				ci.draw_rect(r2, Ink.LIGHT)
			"perimeter":
				ci.draw_rect(r2, Ink.MID)
				_hatch(ci, r2, Ink.DARK, 7.0)
				ci.draw_rect(r2, INK, false, 1.0)
			_:
				ci.draw_rect(r2, INK)
	# fence posts every 2 m
	for idx2 in lv.walls:
		var o2: Dictionary = lv.geom.obs[idx2]
		if o2["name"] != "fence":
			continue
		var fr: Rect2 = o2["r"]
		if fr.size.x >= fr.size.y:
			var x := ceilf(fr.position.x / 2.0) * 2.0
			while x <= fr.end.x:
				ci.draw_rect(Rect2(x * PX - 2, fr.get_center().y * PX - 3, 4, 6), LINE)
				x += 2.0
		else:
			var y := ceilf(fr.position.y / 2.0) * 2.0
			while y <= fr.end.y:
				ci.draw_rect(Rect2(fr.get_center().x * PX - 3, y * PX - 2, 6, 4), LINE)
				y += 2.0
	# railings and chain-link (concealment lines) as thin double lines
	for o3 in lv.geom.obs:
		var nm: String = o3["name"]
		if nm.ends_with("rail") or nm == "chain-link":
			var rr: Rect2 = _r(o3["r"])
			ci.draw_rect(rr, Color("#edede8"))
			ci.draw_rect(rr, LINE, false, 1.0)
	# windows: white gap, three thin lines, jamb ticks
	for win in lv.windows:
		var wr: Rect2 = _r(win["r"])
		ci.draw_rect(wr, Color("#edede8"))
		if win["axis"] == "h":
			for f in [0.0, 0.5, 1.0]:
				var y2: float = wr.position.y + wr.size.y * f
				ci.draw_line(Vector2(wr.position.x, y2), Vector2(wr.end.x, y2), LINE, 1.0)
			ci.draw_line(wr.position, Vector2(wr.position.x, wr.end.y), INK, 2.0)
			ci.draw_line(Vector2(wr.end.x, wr.position.y), wr.end, INK, 2.0)
		else:
			for f in [0.0, 0.5, 1.0]:
				var x2: float = wr.position.x + wr.size.x * f
				ci.draw_line(Vector2(x2, wr.position.y), Vector2(x2, wr.end.y), LINE, 1.0)
			ci.draw_line(wr.position, Vector2(wr.end.x, wr.position.y), INK, 2.0)
			ci.draw_line(Vector2(wr.position.x, wr.end.y), wr.end, INK, 2.0)
	# doors: leaf and quarter arc swinging into the interior room; arches get jamb ticks
	for did in lv.doors:
		var dd: Dictionary = lv.doors[did]
		var c: Vector2 = dd["c"]
		var t: Vector2 = dd["t"]
		var n: Vector2 = dd["n"]
		var half: float = dd["half"]
		if dd.get("arch", false):
			for sgn in [-1.0, 1.0]:
				var j: Vector2 = c + t * half * sgn
				ci.draw_line((j - n * 0.18) * PX, (j + n * 0.18) * PX, INK, 2.0)
			ci.draw_dashed_line((c - t * half) * PX, (c + t * half) * PX, FAINT, 1.0, 5.0)
			continue
		var into: Vector2 = n if not lv.is_exterior(dd["b"]) else -n
		var hinge: Vector2 = c + t * half * float(dd["hinge"])
		var closed: Vector2 = c - t * half * float(dd["hinge"])
		var leaf := minf(half * 2.0, 1.0)
		if half * 2.0 > 1.25:
			# double door: two leaves from both jambs
			for sgn2 in [-1.0, 1.0]:
				var hg: Vector2 = c + t * half * sgn2
				var oe: Vector2 = hg + into * half
				ci.draw_line(hg * PX, oe * PX, INK, 2.0)
				var a0: float = (c - hg).angle()
				ci.draw_arc(hg * PX, half * PX, a0, a0 + angle_difference(a0, (oe - hg).angle()), 14, FAINT, 1.0, true)
			continue
		var open_end: Vector2 = hinge + into * leaf
		ci.draw_line(hinge * PX, open_end * PX, INK, 2.0)
		var a1: float = (closed - hinge).angle()
		var a2: float = (open_end - hinge).angle()
		ci.draw_arc(hinge * PX, leaf * PX, a1, a1 + angle_difference(a1, a2), 18, FAINT, 1.0, true)


## Room lettering, sized by floor area.
static func paint_labels(ci: CanvasItem, lv, font: Font) -> void:
	for name2 in lv.rooms:
		var rm2: Dictionary = lv.rooms[name2]
		if rm2["exterior"] and not rm2["deck"]:
			continue
		if rm2["title"] == "":
			continue
		var area: float = rm2["area"]
		var fs := 8 if area < 8.0 else (9 if area < 20.0 else (10 if area < 50.0 else (11 if area < 150.0 else 13)))
		_label(ci, font, rm2["label"] * PX, _spaced(rm2["title"]), fs, LINE)


static func _decor(ci: CanvasItem, d: Dictionary, font: Font) -> void:
	match d["type"]:
		"dash_rect":
			_dash_rect(ci, _r(d["r"]), FAINT)
		"rect":
			var r: Rect2 = _r(d["r"])
			ci.draw_rect(r, Color("#edede8"))
			ci.draw_rect(r, LINE, false, 1.0)
		"steps":
			var rs: Rect2 = d["r"]
			var n: int = d.get("n", 3)
			for k in n:
				var f := float(k) / maxf(1.0, n - 1)
				if d.get("axis", "v") == "v":
					var x := rs.end.x - f * rs.size.x
					ci.draw_line(Vector2(x, rs.position.y) * PX, Vector2(x, rs.end.y) * PX, FAINT, 1.0)
				else:
					var y := rs.position.y + f * rs.size.y
					ci.draw_line(Vector2(rs.position.x, y) * PX, Vector2(rs.end.x, y) * PX, FAINT, 1.0)
		"text":
			ci.draw_string(font, d["p"] * PX, d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, d.get("size", 10), FAINT)
		"road":
			var rr: Rect2 = _r(d["r"])
			ci.draw_rect(rr, ROAD)
			if d.get("axis", "h") == "h":
				ci.draw_line(rr.position, Vector2(rr.end.x, rr.position.y), FAINT, 1.0)
				ci.draw_line(Vector2(rr.position.x, rr.end.y), rr.end, FAINT, 1.0)
				var cy := rr.get_center().y
				ci.draw_dashed_line(Vector2(rr.position.x, cy), Vector2(rr.end.x, cy), Color("#bfbfba"), 2.0, 18.0)
			else:
				ci.draw_line(rr.position, Vector2(rr.position.x, rr.end.y), FAINT, 1.0)
				ci.draw_line(Vector2(rr.end.x, rr.position.y), rr.end, FAINT, 1.0)
				var cx := rr.get_center().x
				ci.draw_dashed_line(Vector2(cx, rr.position.y), Vector2(cx, rr.end.y), Color("#bfbfba"), 2.0, 18.0)
		"parking":
			var pr: Rect2 = d["r"]
			var stall: float = d.get("stall", 2.7)
			if d.get("axis", "v") == "v":
				var x2 := pr.position.x
				while x2 <= pr.end.x + 0.01:
					ci.draw_line(Vector2(x2, pr.position.y) * PX, Vector2(x2, pr.end.y) * PX, Color("#bfbfba"), 1.5)
					x2 += stall
				ci.draw_line(Vector2(pr.position.x, pr.end.y) * PX, pr.end * PX, Color("#bfbfba"), 1.0)
			else:
				var y2 := pr.position.y
				while y2 <= pr.end.y + 0.01:
					ci.draw_line(Vector2(pr.position.x, y2) * PX, Vector2(pr.end.x, y2) * PX, Color("#bfbfba"), 1.5)
					y2 += stall
		"pool":
			var pl: Rect2 = _r(d["r"])
			ci.draw_rect(pl.grow(10.0), Color("#edede8"))
			ci.draw_rect(pl.grow(10.0), LINE, false, 1.0)
			ci.draw_rect(pl, Color("#d4d4cf"))
			var y3 := pl.position.y + 8.0
			while y3 < pl.end.y - 4.0:
				var x3 := pl.position.x + 6.0
				while x3 < pl.end.x - 14.0:
					ci.draw_arc(Vector2(x3 + 6.0, y3), 6.0, PI * 1.1, PI * 1.9, 6, Color("#bfbfba"), 1.0)
					x3 += 22.0
				y3 += 14.0
			ci.draw_rect(pl, INK, false, 1.5)
		"hatch":
			var hr: Rect2 = _r(d["r"])
			_hatch(ci, hr, Color(0.07, 0.07, 0.07, 0.12), 9.0)
			ci.draw_rect(hr, FAINT, false, 1.0)


static func _boards(ci: CanvasItem, r: Rect2) -> void:
	var col := Color("#d4d4cf")
	if r.size.y >= r.size.x:
		var x := r.position.x
		while x < r.end.x:
			ci.draw_line(Vector2(x, r.position.y) * PX, Vector2(x, r.end.y) * PX, col, 1.0)
			x += 0.15
	else:
		var y := r.position.y
		while y < r.end.y:
			ci.draw_line(Vector2(r.position.x, y) * PX, Vector2(r.end.x, y) * PX, col, 1.0)
			y += 0.15


static func _hatch(ci: CanvasItem, r: Rect2, col: Color, step: float) -> void:
	var x := -r.size.y
	while x < r.size.x:
		var a := Vector2(x, r.size.y)
		var b := Vector2(x + r.size.y, 0)
		if a.x < 0:
			a = Vector2(0, r.size.y + a.x)
		if b.x > r.size.x:
			b = Vector2(r.size.x, b.x - r.size.x)
		ci.draw_line(r.position + a, r.position + b, col, 1.0)
		x += step


static func _r(r: Rect2) -> Rect2:
	return Rect2(r.position * PX, r.size * PX)


static func _dash_rect(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var p := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		ci.draw_dashed_line(p[k], p[(k + 1) % 4], col, 1.0, 6.0)


static func _spaced(s: String) -> String:
	var out := ""
	for i in s.length():
		out += s[i]
		if i < s.length() - 1:
			out += " " if s[i] != " " else "  "
	return out


static func _label(ci: CanvasItem, font: Font, centre: Vector2, text: String, size: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, centre + Vector2(-w / 2.0, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func _dimension(ci: CanvasItem, a: Vector2, b: Vector2, text: String, font: Font) -> void:
	var pa := a * PX
	var pb := b * PX
	ci.draw_line(pa, pb, LINE, 1.0)
	var n := (pb - pa).normalized().orthogonal() * 5.0
	var t := (pb - pa).normalized() * 4.0
	for p in [pa, pb]:
		ci.draw_line(p - n, p + n, LINE, 1.0)
		ci.draw_line(p - t - n * 0.8, p + t + n * 0.8, INK, 1.4)
	var mid := (pa + pb) / 2.0
	if absf(pb.x - pa.x) > absf(pb.y - pa.y):
		_label(ci, font, mid + Vector2(0, -9), text, 10, FAINT)
	else:
		ci.draw_set_transform(mid + Vector2(10, 0), PI / 2.0)
		_label(ci, font, Vector2.ZERO, text, 10, FAINT)
		ci.draw_set_transform(Vector2.ZERO, 0.0)


## A rubber stamp: heavy condensed caps in a double box, a little off square. Red only
## once the plan has met the room; the box and the words carry it with red off.
static func _stamp(ci: CanvasItem, font: Font, at: Vector2, lines: Array, col: Color, rot: float) -> float:
	var bold: Font = font
	var w := 0.0
	for ln in lines:
		w = maxf(w, font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	var sz := Vector2(w + 22.0, 18.0 * lines.size() + 12.0)
	ci.draw_set_transform(at, rot)
	ci.draw_rect(Rect2(Vector2.ZERO, sz), col, false, 2.0)
	ci.draw_rect(Rect2(Vector2(3, 3), sz - Vector2(6, 6)), col, false, 1.0)
	for i in lines.size():
		ci.draw_string(bold, Vector2(11, 20 + 18 * i), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0)
	return sz.x
