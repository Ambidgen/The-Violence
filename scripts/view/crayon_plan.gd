extends RefCounted
## The plan in crayon (1.4). Replaces the red-ink architectural print: the same topology,
## drawn by a child's hand.
##
## Two looks, one map, as before:
##   theory (the briefing)      daylight pencil on cream: rooms coloured in lightly, each
##                              its own crayon, the yard scribbled green, labels in capitals;
##   application (the operation) night: charcoal over everything, rooms in dark wax, the
##                              yard nearly black, walls pressed through the paper.
##
## Painters are static and draw into anything with the CanvasItem draw_* calls; the plan
## records them into Sketch variants (view/sketch.gd) and replays them as the page boils.
## Door leaves are drawn live by view/doors_view.gd. Presentation only.

const C = preload("res://scripts/view/crayon.gd")
const Ink = preload("res://scripts/view/ink.gd")
const PX := 40.0

## Room crayons: [day, night], picked per room so neighbours differ.
const ROOM_TINTS := [
	[Color("#dccfb4"), Color("#59606c")],
	[Color("#cfd6c6"), Color("#56635a")],
	[Color("#e0c9b3"), Color("#695a55")],
	[Color("#c9d0dc"), Color("#4f5b6d")],
	[Color("#e3d6a8"), Color("#66604a")],
	[Color("#d8c3c9"), Color("#62555e")],
]
const WET_ROOMS := ["BATH", "KITCHEN", "LAUNDRY", "WC", "WASHROOM", "ENSUITE", "SHOWER", "PANTRY", "MESS"]


static func _r(r: Rect2) -> Rect2:
	return Rect2(r.position * PX, r.size * PX)


static func _seed(name: String) -> int:
	return absi(hash(name)) % 7919


static func _a(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)


## The site and the floors: ground, roads and lots, decks, rooms coloured in.
static func paint_ground(ci, lv, night: bool) -> void:
	var W: float = lv.W * PX
	var H: float = lv.H * PX
	var site := C.rect_poly(Rect2(0, 0, W, H))
	# the ground: green scribble by day, near-black charcoal by night
	if night:
		ci.draw_colored_polygon(site, Color("#2c312c"))
		C.hatch(ci, site, _a(C.GRAPHITE, 0.9), 3.4, -0.7, 11, 2.6)
		C.hatch(ci, site, _a(C.MOSS.darkened(0.45), 0.8), 5.0, 0.9, 12, 2.4)
	else:
		C.hatch(ci, site, _a(C.MOSS.lightened(0.15), 0.55), 4.2, -0.7, 11, 2.4)
		C.hatch(ci, site, _a(C.GRAPHITE, 0.16), 7.0, 0.8, 12, 1.6)
	for d in lv.decor:
		_decor(ci, d, night)
	var k := 0
	for name in lv.rooms:
		var rm: Dictionary = lv.rooms[name]
		var sd := _seed(name)
		for rv in rm["rects"]:
			var r: Rect2 = _r(rv)
			var poly := C.rect_poly(r)
			if rm["deck"]:
				var wood := Color("#8a5a36") if not night else Color("#4a3426")
				ci.draw_colored_polygon(poly, _a(wood.lightened(0.25), 0.9))
				C.hatch(ci, poly, _a(wood, 0.9), 6.0, 0.0 if r.size.x >= r.size.y else PI / 2.0, sd, 2.6)
				C.hatch(ci, poly, _a(wood.darkened(0.3), 0.4), 3.0, 0.4, sd + 1, 1.4)
				continue
			if rm["exterior"]:
				continue
			var tint: Color = ROOM_TINTS[sd % ROOM_TINTS.size()][1 if night else 0]
			if rm.get("hall", false):
				tint = Color("#d5cdbd") if not night else Color("#4e4f55")
			ci.draw_colored_polygon(poly, tint)
			C.hatch(ci, poly, _a(tint.darkened(0.28), 0.85), 3.6 if night else 4.6, -0.75 + C.rnd(sd, 1) * 0.4, sd + k, 2.4)
			if night:
				C.hatch(ci, poly, _a(C.CHARCOAL, 0.35), 4.6, 0.85, sd + k + 1, 2.0)
			else:
				C.hatch(ci, poly, _a(tint.lightened(0.2), 0.6), 6.0, 0.9, sd + k + 1, 1.6)
			# a child gives the wet rooms their tiles
			var title := String(rm.get("title", name)).to_upper()
			for wet in WET_ROOMS:
				if title.contains(wet):
					_tiles(ci, r, night, sd)
					break
			k += 1


static func _tiles(ci, r: Rect2, night: bool, sd: int) -> void:
	var col := _a(C.CHALK if not night else C.SLATE_LIGHT.lightened(0.15), 0.55)
	var step := 0.6 * PX
	var x := r.position.x + step
	while x < r.end.x - 2.0:
		C.line(ci, Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), col, 1.2, sd + int(x), 0.5, 1)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 2.0:
		C.line(ci, Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), col, 1.2, sd + int(y) * 3, 0.5, 1)
		y += step


static func _decor(ci, d: Dictionary, night: bool) -> void:
	var s := absi(hash(str(d.get("r", d.get("p", ""))))) % 5000
	match d["type"]:
		"road":
			var rr: Rect2 = _r(d["r"])
			var poly := C.rect_poly(rr)
			ci.draw_colored_polygon(poly, C.SLATE if night else Color("#9a9a96"))
			C.hatch(ci, poly, _a(C.SLATE.darkened(0.3) if night else C.GRAPHITE, 0.6 if night else 0.35), 3.6, -0.15, s, 2.6)
			var mark := _a(C.TAPE if not night else C.CHALK.darkened(0.3), 0.85)
			if d.get("axis", "h") == "h":
				var cy := rr.get_center().y
				var x := rr.position.x + 10.0
				while x < rr.end.x - 30.0:
					C.line(ci, Vector2(x, cy), Vector2(x + 50.0, cy), mark, 3.0, s + int(x), 0.8, 1)
					x += 110.0
			else:
				var cx := rr.get_center().x
				var y := rr.position.y + 10.0
				while y < rr.end.y - 30.0:
					C.line(ci, Vector2(cx, y), Vector2(cx, y + 50.0), mark, 3.0, s + int(y), 0.8, 1)
					y += 110.0
		"parking":
			var pr: Rect2 = d["r"]
			var stall: float = d.get("stall", 2.7)
			var lc := _a(C.CHALK, 0.7)
			if d.get("axis", "v") == "v":
				var x2 := pr.position.x
				while x2 <= pr.end.x + 0.01:
					C.line(ci, Vector2(x2, pr.position.y) * PX, Vector2(x2, pr.end.y) * PX, lc, 2.2, s + int(x2 * 10), 1.0, 1)
					x2 += stall
			else:
				var y2 := pr.position.y
				while y2 <= pr.end.y + 0.01:
					C.line(ci, Vector2(pr.position.x, y2) * PX, Vector2(pr.end.x, y2) * PX, lc, 2.2, s + int(y2 * 10), 1.0, 1)
					y2 += stall
		"pool":
			var pl: Rect2 = _r(d["r"])
			var deck := C.rect_poly(pl.grow(10.0))
			ci.draw_colored_polygon(deck, Color("#cfc8b6") if not night else Color("#5c5a54"))
			C.outline(ci, deck, C.GRAPHITE, 1.6, s, 0.6)
			var water := C.rect_poly(pl)
			ci.draw_colored_polygon(water, Color("#5f93d6") if not night else Color("#24406e"))
			C.hatch(ci, water, _a(C.BLUE, 0.8), 3.6, 0.2, s + 1, 2.4)
			var yy := pl.position.y + 10.0
			while yy < pl.end.y - 6.0:
				var xx := pl.position.x + 8.0
				while xx < pl.end.x - 16.0:
					C.line(ci, Vector2(xx, yy), Vector2(xx + 8, yy - 3), _a(C.CHALK, 0.7), 1.4, s + int(xx + yy), 0.4, 1)
					C.line(ci, Vector2(xx + 8, yy - 3), Vector2(xx + 16, yy), _a(C.CHALK, 0.7), 1.4, s + int(xx + yy) + 1, 0.4, 1)
					xx += 26.0
				yy += 16.0
			C.outline(ci, water, C.CHARCOAL, 2.2, s + 2, 0.8)
		"steps":
			var rs: Rect2 = d["r"]
			var n: int = d.get("n", 3)
			ci.draw_colored_polygon(C.rect_poly(_r(rs)), Color("#a8a39a") if not night else Color("#55534e"))
			for k in n:
				var f := float(k) / maxf(1.0, n - 1)
				if d.get("axis", "v") == "v":
					var x := rs.end.x - f * rs.size.x
					C.line(ci, Vector2(x, rs.position.y) * PX, Vector2(x, rs.end.y) * PX, C.CHARCOAL, 1.6, s + k, 0.5, 1)
				else:
					var y := rs.position.y + f * rs.size.y
					C.line(ci, Vector2(rs.position.x, y) * PX, Vector2(rs.end.x, y) * PX, C.CHARCOAL, 1.6, s + k, 0.5, 1)
		"text":
			C.letters(ci, String(d["text"]), d["p"] * PX + Vector2(0, 4), int(d.get("size", 10) * 1.5), _a(C.CHALK if night else C.GRAPHITE, 0.85), s, 1)
		"rect":
			var r: Rect2 = _r(d["r"])
			ci.draw_colored_polygon(C.rect_poly(r), Color("#cfc8b6") if not night else Color("#5c5a54"))
			C.outline(ci, C.rect_poly(r), C.GRAPHITE, 1.6, s, 0.6)
		"dash_rect":
			var dr: Rect2 = _r(d["r"])
			var p := C.rect_poly(dr)
			for k2 in 4:
				var a: Vector2 = p[k2]
				var b: Vector2 = p[(k2 + 1) % 4]
				var L := a.distance_to(b)
				var t := 0.0
				while t < L:
					C.line(ci, a.lerp(b, t / L), a.lerp(b, minf(L, t + 10.0) / L), _a(C.CHALK if night else C.GRAPHITE, 0.6), 1.6, s + k2 * 100 + int(t), 0.4, 1)
					t += 20.0
		"hatch":
			var hr: Rect2 = _r(d["r"])
			C.hatch(ci, C.rect_poly(hr), _a(C.CHARCOAL, 0.35), 6.0, 0.8, s, 1.8)
			C.outline(ci, C.rect_poly(hr), _a(C.GRAPHITE, 0.6), 1.4, s + 1, 0.6)


## Walls pressed hard, fences, rails, windows, doorway jambs, and the room names.
static func paint_walls(ci, lv, night: bool) -> void:
	var wk := 0
	for idx in lv.walls:
		var o: Dictionary = lv.geom.obs[idx]
		var r2: Rect2 = _r(o["r"])
		wk += 1
		match o["name"]:
			"fence":
				var a := r2.position + Vector2(0, r2.size.y * 0.5) if r2.size.x >= r2.size.y else r2.position + Vector2(r2.size.x * 0.5, 0)
				var b := a + (Vector2(r2.size.x, 0) if r2.size.x >= r2.size.y else Vector2(0, r2.size.y))
				var fc := C.GRAPHITE.lightened(0.3) if night else C.GRAPHITE
				C.line(ci, a, b, fc, 2.2, 200 + wk, 1.0, 2)
				var L := a.distance_to(b)
				var dv := (b - a) / maxf(L, 1.0)
				var t := 0.0
				while t <= L:
					ci.draw_circle(a + dv * t, 3.2, C.CHARCOAL)
					t += 2.0 * PX
				# chain link: little crosses either side
				var t2 := 6.0
				while t2 < L:
					var q := a + dv * t2
					var nrm := dv.orthogonal() * 3.0
					C.stroke(ci, q - nrm - dv * 3.0, q + nrm + dv * 3.0, _a(fc, 0.6), 1.0, 300 + wk * 50 + int(t2), 0.5)
					t2 += 9.0
			"perimeter":
				var pp := C.rect_poly(r2)
				ci.draw_colored_polygon(pp, C.BRICK_DARK)
				C.hatch(ci, pp, C.BRICK, 5.0, 0.0 if r2.size.x < r2.size.y else PI / 2.0, 400 + wk, 2.6)
				C.outline(ci, pp, C.CHARCOAL, 1.6, 500 + wk, 0.6)
			_:
				ci.draw_colored_polygon(C.rect_poly(r2.grow(1.0)), C.CHARCOAL)
				C.outline(ci, C.rect_poly(r2.grow(1.5)), C.CHARCOAL, 2.4, 600 + wk, 1.1)
	# railings and chain-link (concealment lines): two thin graphite lines
	var rk := 0
	for o3 in lv.geom.obs:
		var nm: String = o3["name"]
		if nm.ends_with("rail") or nm == "chain-link":
			var rr: Rect2 = _r(o3["r"])
			rk += 1
			var col := C.CHALK.darkened(0.2) if night else C.GRAPHITE
			if rr.size.x >= rr.size.y:
				C.line(ci, rr.position, Vector2(rr.end.x, rr.position.y), col, 1.4, 700 + rk, 0.6, 1)
				C.line(ci, Vector2(rr.position.x, rr.end.y), rr.end, col, 1.4, 750 + rk, 0.6, 1)
			else:
				C.line(ci, rr.position, Vector2(rr.position.x, rr.end.y), col, 1.4, 700 + rk, 0.6, 1)
				C.line(ci, Vector2(rr.end.x, rr.position.y), rr.end, col, 1.4, 750 + rk, 0.6, 1)
	# windows: glass in cobalt, across the wall
	var gk := 0
	for win in lv.windows:
		var wr: Rect2 = _r(win["r"])
		gk += 1
		ci.draw_colored_polygon(C.rect_poly(wr), Color("#9ec3e6") if not night else Color("#3d63b2"))
		var gc := C.BLUE if not night else Color("#9ec3e6")
		if win["axis"] == "h":
			C.line(ci, Vector2(wr.position.x, wr.get_center().y), Vector2(wr.end.x, wr.get_center().y), gc, 2.0, 800 + gk, 0.5, 1)
		else:
			C.line(ci, Vector2(wr.get_center().x, wr.position.y), Vector2(wr.get_center().x, wr.end.y), gc, 2.0, 800 + gk, 0.5, 1)
		C.outline(ci, C.rect_poly(wr), C.CHARCOAL, 1.2, 850 + gk, 0.4)
	# arches: jamb ticks only (leaves are live, in doors_view)
	for did in lv.doors:
		var dd: Dictionary = lv.doors[did]
		if dd.get("arch", false):
			var c: Vector2 = dd["c"]
			var t3: Vector2 = dd["t"]
			var n: Vector2 = dd["n"]
			var half: float = dd["half"]
			for sgn: float in [-1.0, 1.0]:
				var j: Vector2 = c + t3 * half * sgn
				C.line(ci, (j - n * 0.2) * PX, (j + n * 0.2) * PX, C.CHARCOAL, 3.0, 900 + int(sgn), 0.4, 1)
	paint_labels(ci, lv, night)


## Room names in wobbly capitals, sized by floor area.
static func paint_labels(ci, lv, night: bool) -> void:
	for name in lv.rooms:
		var rm: Dictionary = lv.rooms[name]
		if rm["exterior"] and not rm["deck"]:
			continue
		var title: String = rm["title"]
		if title == "":
			continue
		var area: float = rm["area"]
		var fs := 12 if area < 8.0 else (15 if area < 20.0 else (18 if area < 50.0 else (22 if area < 150.0 else 26)))
		var w := C.letters_width(title, fs, 0.9)
		var pos: Vector2 = rm["label"] * PX + Vector2(-w * 0.5, fs * 0.45)
		var col := _a(C.CHALK, 0.8) if night else _a(C.GRAPHITE, 0.85)
		C.letters(ci, title, pos, fs, col, _seed(name), 2, 0.9)


## The title scrap under the plan, and the stamps: the model's confidence in the
## briefing, what it cost after the operation.
static func paint_title(ci, lv, state: String, stamp: Dictionary) -> void:
	var W: float = lv.W * PX
	var H: float = lv.H * PX
	var tb := Rect2(W - 560, H + 14, 560, 92)
	var scrap := PackedVector2Array([tb.position + Vector2(-4, 3), Vector2(tb.end.x + 3, tb.position.y - 2), tb.end + Vector2(-2, 4), Vector2(tb.position.x + 2, tb.end.y)])
	ci.draw_colored_polygon(scrap, C.PAPER_CREAM)
	C.hatch(ci, scrap, _a(C.PAPER_CREAM.darkened(0.12), 0.5), 6.0, 0.3, 31, 1.4)
	C.outline(ci, scrap, C.GRAPHITE, 1.6, 32, 0.8)
	C.letters(ci, lv.title, tb.position + Vector2(14, 30), 20, C.CHARCOAL, 33, 2, 0.95)
	for i in mini(3, lv.notes.size()):
		C.letters(ci, String(lv.notes[i]), tb.position + Vector2(14, 54 + 16 * i), 11, _a(C.GRAPHITE, 0.9 if i < 2 else 0.6), 34 + i, 1, 0.85)
	var x := 0.0
	var y := H + 112.0
	if state == "theory":
		x += stamp_box(ci, Vector2(x, y), ["MODEL: COMPLETE", "UNKNOWN: NONE"], C.GRAPHITE, -0.015, 41) + 26.0
		stamp_box(ci, Vector2(x, y + 2), ["RISK: APPROVED", "OWNER: NOT LISTED"], _a(C.GRAPHITE, 0.6), 0.012, 42)
		return
	var secs := float(stamp.get("actual", 0.0))
	var col := Ink.accent(0.85)
	x += stamp_box(ci, Vector2(x, y + 2), ["ACTUAL: %02d:%02d" % [int(secs / 60.0), int(secs) % 60], "FRICTION: ALL"], col, -0.03, 43) + 26.0
	if int(stamp.get("forms", 0)) > 0:
		x += stamp_box(ci, Vector2(x, y), ["PAPERWORK: %02d FORMS" % int(stamp["forms"]),
			"MOP: REQUESTED" if stamp.get("mop", false) else "MOP: NOT REQUIRED"], C.CHALK, 0.015, 44) + 26.0
	if stamp.get("filed", false):
		stamp_box(ci, Vector2(x, y + 4), ["FILED", "NOT RESOLVED"], col, -0.045, 45)


## A rubber stamp drawn in crayon: a double box gone over twice, capitals inside.
static func stamp_box(ci, at: Vector2, lines: Array, col: Color, rot: float, s := 0) -> float:
	var w := 0.0
	for ln in lines:
		w = maxf(w, C.letters_width(String(ln), 14, 0.9))
	var sz := Vector2(w + 24.0, 20.0 * lines.size() + 12.0)
	ci.draw_set_transform(at, rot, Vector2.ONE)
	C.outline(ci, C.rect_poly(Rect2(Vector2.ZERO, sz)), col, 2.4, s, 1.0)
	C.outline(ci, C.rect_poly(Rect2(Vector2(4, 4), sz - Vector2(8, 8))), _a(col, col.a * 0.6), 1.2, s + 1, 0.6)
	for i in lines.size():
		C.letters(ci, String(lines[i]), Vector2(12, 24 + 20 * i), 14, col, s + 2 + i, 1, 0.9)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return sz.x
