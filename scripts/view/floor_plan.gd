extends Node2D
## Draws the level as an architectural floor plan: paper, grid, poche walls, window
## triple-lines, door swings, room lettering, dimension strings and a title block.
## Everything here is greyscale; colour is reserved for blood.

const Geom = preload("res://scripts/sim/geom.gd")
const PX := 40.0

const PAPER := Color("#f6f6f4")
const GRID := Color("#e6e6e3")
const GRID_MAJOR := Color("#d8d8d4")
const INK := Color("#1c1c1c")
const LINE := Color("#3a3a3a")
const FAINT := Color("#8f8f8f")
const HOUSE_FLOOR := Color("#fbfbfa")

var level


func setup(lv) -> void:
	level = lv
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	var font: Font = ThemeDB.fallback_font
	var W: float = level.W * PX
	var H: float = level.H * PX
	# paper sheet with a margin for the title block
	draw_rect(Rect2(-60, -60, W + 120, H + 170), Color("#ffffff"))
	draw_rect(Rect2(-60, -60, W + 120, H + 170), INK, false, 2.0)
	draw_rect(Rect2(-48, -48, W + 96, H + 146), LINE, false, 1.0)
	draw_rect(Rect2(0, 0, W, H), PAPER)
	# grid: 1 m faint, 5 m darker
	for x in range(0, int(level.W) + 1):
		draw_line(Vector2(x * PX, 0), Vector2(x * PX, H), GRID_MAJOR if x % 5 == 0 else GRID, 1.0)
	for y in range(0, int(level.H) + 1):
		draw_line(Vector2(0, y * PX), Vector2(W, y * PX), GRID_MAJOR if y % 5 == 0 else GRID, 1.0)
	# house floor and porch boards
	draw_rect(_r(Rect2(12, 9.5, 13, 5)), HOUSE_FLOOR)
	draw_rect(_r(Rect2(10, 9.5, 2, 5)), Color("#f0f0ee"))
	var bx := 10.0
	while bx < 12.0:
		draw_line(Vector2(bx * PX, 9.5 * PX), Vector2(bx * PX, 14.5 * PX), Color("#dcdcd8"), 1.0)
		bx += 0.15
	for k in 3:
		var sx := 9.65 - k * 0.3
		draw_line(Vector2(sx * PX, 12.55 * PX), Vector2(sx * PX, 14.15 * PX), FAINT, 1.0)
	# drawing-only decor (driveway, front walk, back step)
	for d in level.decor:
		var r: Rect2 = _r(d["r"])
		if d["type"] == "dash_rect":
			_dash_rect(r, FAINT)
		else:
			draw_rect(r, Color("#eeeeec"))
			draw_rect(r, LINE, false, 1.0)
	# walls: fence thin, house walls solid poche
	for idx in level.walls:
		var o: Dictionary = level.geom.obs[idx]
		var r2: Rect2 = _r(o["r"])
		if o["name"] == "fence":
			draw_rect(r2, Color("#9a9a9a"))
		elif o["name"] == "porch post":
			draw_rect(r2, INK)
		else:
			draw_rect(r2, INK)
	# fence posts every 2 m
	for x in range(0, int(level.W) + 1, 2):
		draw_rect(Rect2(x * PX - 2, -2, 4, 6), LINE)
		draw_rect(Rect2(x * PX - 2, H - 4, 4, 6), LINE)
	for y in range(0, int(level.H) + 1, 2):
		draw_rect(Rect2(-2, y * PX - 2, 6, 4), LINE)
		draw_rect(Rect2(W - 4, y * PX - 2, 6, 4), LINE)
	# porch railings (concealment) as thin double lines
	for o in level.geom.obs:
		if o["name"] == "porch rail":
			var rr: Rect2 = _r(o["r"])
			draw_rect(rr, Color("#ffffff"))
			draw_rect(rr, LINE, false, 1.0)
	# windows: white gap, three thin lines, sill ticks
	for win in level.windows:
		var wr: Rect2 = _r(win["r"])
		draw_rect(wr, Color("#ffffff"))
		if win["axis"] == "h":
			for f in [0.0, 0.5, 1.0]:
				var y: float = wr.position.y + wr.size.y * f
				draw_line(Vector2(wr.position.x, y), Vector2(wr.end.x, y), LINE, 1.0)
			draw_line(wr.position, Vector2(wr.position.x, wr.end.y), INK, 2.0)
			draw_line(Vector2(wr.end.x, wr.position.y), wr.end, INK, 2.0)
		else:
			for f in [0.0, 0.5, 1.0]:
				var x: float = wr.position.x + wr.size.x * f
				draw_line(Vector2(x, wr.position.y), Vector2(x, wr.end.y), LINE, 1.0)
			draw_line(wr.position, Vector2(wr.end.x, wr.position.y), INK, 2.0)
			draw_line(Vector2(wr.position.x, wr.end.y), wr.end, INK, 2.0)
	# door swings: leaf + quarter arc, opening into the room on the inside
	for id in level.doors:
		var dd: Dictionary = level.doors[id]
		var c: Vector2 = dd["c"]
		var t: Vector2 = dd["t"]
		var half: float = dd["half"]
		var into: Vector2 = dd["n"] if id != "BACK" else -dd["n"]
		var hinge: Vector2 = c + t * half * float(dd["hinge"])
		var closed: Vector2 = c - t * half * float(dd["hinge"])
		var open_end: Vector2 = hinge + into * half * 2.0
		draw_line(hinge * PX, open_end * PX, INK, 2.0)
		var a0: float = (closed - hinge).angle()
		var a1: float = (open_end - hinge).angle()
		var diff := angle_difference(a0, a1)
		draw_arc(hinge * PX, half * 2.0 * PX, a0, a0 + diff, 18, FAINT, 1.0, true)
	# room lettering
	for name in level.rooms:
		var rm: Dictionary = level.rooms[name]
		_label(font, rm["label"] * PX, _spaced(rm["title"]), 11, LINE)
	# dimension strings along the house
	_dimension(Vector2(12, 8.6), Vector2(25, 8.6), "13.00 m", font)
	_dimension(Vector2(25.9, 9.5), Vector2(25.9, 14.5), "5.00", font)
	for xx in [17.0, 21.0]:
		draw_line(Vector2(xx * PX, 8.45 * PX), Vector2(xx * PX, 8.75 * PX), LINE, 1.0)
	# title block, scale bar, notes
	var tb := Rect2(W - 560, H + 14, 560, 92)
	draw_rect(tb, Color("#ffffff"))
	draw_rect(tb, INK, false, 1.5)
	draw_line(Vector2(tb.position.x, tb.position.y + 30), Vector2(tb.end.x, tb.position.y + 30), LINE, 1.0)
	draw_line(Vector2(tb.position.x + 360, tb.position.y + 30), Vector2(tb.position.x + 360, tb.end.y), LINE, 1.0)
	draw_string(font, tb.position + Vector2(12, 21), _spaced("THE VIOLENCE  -  TEST RANGE 01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	draw_string(font, tb.position + Vector2(12, 50), "14 x 32 SHOTGUN HOUSE, DRAWN AT 5 x 13 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LINE)
	draw_string(font, tb.position + Vector2(12, 66), "YARD WITH SCATTERED COVER  ·  1 SQUARE = 1 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LINE)
	draw_string(font, tb.position + Vector2(12, 82), "VERTICAL SLICE  ·  SHEET 1 OF 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, FAINT)
	draw_string(font, tb.position + Vector2(372, 50), "COVER: solid fill / hatched", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LINE)
	draw_string(font, tb.position + Vector2(372, 66), "CONCEALMENT: outline only", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LINE)
	draw_string(font, tb.position + Vector2(372, 82), "WINDOWS: sill 0.9 m, head 2.1 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LINE)
	# scale bar 0-5 m
	var sb := Vector2(0, H + 40)
	for k in 5:
		var seg := Rect2(sb.x + k * PX, sb.y, PX, 8)
		draw_rect(seg, INK if k % 2 == 0 else Color("#ffffff"))
		draw_rect(seg, INK, false, 1.0)
	for k in [0, 1, 5]:
		draw_string(font, sb + Vector2(k * PX - 3, 24), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LINE)
	draw_string(font, sb + Vector2(5 * PX + 12, 9), "m", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LINE)
	draw_string(font, Vector2(0, H + 82), "STREET", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FAINT)


func _r(r: Rect2) -> Rect2:
	return Rect2(r.position * PX, r.size * PX)


func _dash_rect(r: Rect2, col: Color) -> void:
	var p := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(p[k], p[(k + 1) % 4], col, 1.0, 6.0)


func _spaced(s: String) -> String:
	var out := ""
	for i in s.length():
		out += s[i]
		if i < s.length() - 1:
			out += " " if s[i] != " " else "  "
	return out


func _label(font: Font, centre: Vector2, text: String, size: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, centre + Vector2(-w / 2.0, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _dimension(a: Vector2, b: Vector2, text: String, font: Font) -> void:
	var pa := a * PX
	var pb := b * PX
	draw_line(pa, pb, LINE, 1.0)
	var n := (pb - pa).normalized().orthogonal() * 5.0
	var t := (pb - pa).normalized() * 4.0
	for p in [pa, pb]:
		draw_line(p - n, p + n, LINE, 1.0)
		draw_line(p - t - n * 0.8, p + t + n * 0.8, INK, 1.4)
	var mid := (pa + pb) / 2.0
	if absf(pb.x - pa.x) > absf(pb.y - pa.y):
		_label(font, mid + Vector2(0, -9), text, 10, LINE)
	else:
		draw_set_transform(mid + Vector2(10, 0), PI / 2.0)
		_label(font, Vector2.ZERO, text, 10, LINE)
		draw_set_transform(Vector2.ZERO, 0.0)
