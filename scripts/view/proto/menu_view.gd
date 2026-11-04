extends Node2D
## Prototype 2 — the title and main menu in the overhaul's hand. Port Carrick from the
## air under an orange smog (the housing-block plate): rows of blocks in charcoal, the
## streets between them lit sodium orange, chimneys pouring black smoke that moves, rain.
## The title is printed in crayon capitals and underlined in red; the menu is a stack of
## torn paper scraps; the hovered one gets a red scribble round it, drawn as you watch.
## A Ledger cutting sits in the corner.

const C = preload("res://scripts/view/crayon.gd")

var t := 0.0
var _bt := 0.0
var paper: ImageTexture
var vp := Vector2(1600, 900)
const ITEMS := ["NEW RUN", "CONTINUE  ·  WEEK 12", "TEST RANGE", "HOW TO PLAY", "SETTINGS", "QUIT"]
const HOVER_AT := [4.2, 5.6, 7.0, 8.4]   # the cursor visits items 0, 1, 3, 0
const HOVER_ITEM := [0, 1, 3, 0]
var blocks: Array = []     # [{row, x, w, d, h, kind}]


func _ready() -> void:
	vp = get_viewport_rect().size
	paper = C.paper_texture(Vector2i(int(vp.x / 2), int(vp.y / 2)), C.PAPER_GREY.lightened(0.05), 33, 1.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for row in 6:
		var x := -80.0 + rng.randf() * 60.0
		while x < vp.x + 60.0:
			var kind := "block"
			var r := rng.randf()
			if r < 0.14:
				kind = "factory"
			elif r < 0.45:
				kind = "court"
			var w := rng.randf_range(120, 230)
			blocks.append({"row": row, "x": x, "w": w, "d": rng.randf_range(110, 170), "h": rng.randf_range(60, 120), "kind": kind, "seed": blocks.size() * 13})
			x += w + rng.randf_range(34, 60)


func _process(delta: float) -> void:
	t += delta
	_bt += delta
	if _bt >= 0.125:
		_bt = 0.0
		C.frame += 1
	queue_redraw()


func rev(start: float, dur := 0.6) -> float:
	return clampf((t - start) / dur, 0.0, 1.0)


## Oblique projection of the city: row 0 is far (small, high), row 5 near.
func _row_y(row: int) -> float:
	return 300.0 + pow(row / 5.0, 1.35) * 520.0


func _row_k(row: int) -> float:
	return 0.42 + 0.58 * row / 5.0


func _draw() -> void:
	draw_texture_rect(paper, Rect2(Vector2.ZERO, vp), false)
	var page := Rect2(Vector2(18, 16), vp - Vector2(36, 32))
	# ---------------------------------------------------------------- the smog sky
	var sky := Rect2(page.position, Vector2(page.size.x, 330))
	var oc := C.ORANGE
	oc.a = 0.8
	C.hatch(self, C.rect_poly(sky), oc, 3.2, -0.25, 1, 3.0, rev(0.0, 0.8))
	var gc := C.GRAPHITE
	gc.a = 0.55
	C.hatch(self, C.rect_poly(Rect2(sky.position, Vector2(sky.size.x, 120))), gc, 3.6, 0.2, 2, 3.0, rev(0.2, 0.8))
	for k in 7:
		var cx := 120.0 + k * 230.0 + sin(t * 0.2 + k) * 20.0
		C.smudge(self, Vector2(cx, 70 + 30 * C.rnd(k, 1)), 110, C.GRAPHITE)
	# ---------------------------------------------------------------- the city, far to near
	var ground := PackedVector2Array([Vector2(page.position.x, 290), Vector2(page.end.x, 290), page.end, Vector2(page.position.x, page.end.y)])
	C.charcoal(self, ground, C.GRAPHITE, 2.6, 5, rev(0.3, 1.0), 2.6)
	for row in 6:
		var y := _row_y(row)
		var k := _row_k(row)
		# the street in front of this row, sodium orange
		var st := C.ORANGE
		st.a = 0.55 + 0.15 * row / 5.0
		C.hatch(self, C.rect_poly(Rect2(page.position.x, y + 4, page.size.x, 16 * k)), st, 3.0, -0.1, 30 + row, 2.4, rev(0.6 + row * 0.12, 0.5))
		for b in blocks:
			if int(b["row"]) != row:
				continue
			if rev(0.8 + row * 0.15 + float(b["x"]) / 4000.0, 0.4) <= 0.0:
				continue
			_block(b, y, k)
	# smoke, over the city: rising, drifting scribbles
	for b2 in blocks:
		if b2["kind"] == "factory" and t > 1.6:
			var k2 := _row_k(int(b2["row"]))
			var base := Vector2(float(b2["x"]) + float(b2["w"]) * 0.3, _row_y(int(b2["row"])) - float(b2["h"]) * k2 - 70 * k2)
			_smoke(base, k2, int(b2["seed"]))
	C.rain(self, page, 220, 77, -0.18, 34.0)
	# ---------------------------------------------------------------- the title
	var title_bg := PackedVector2Array([Vector2(60, 70), Vector2(760, 58), Vector2(772, 250), Vector2(54, 262)])
	var tb := C.PAPER_CREAM
	tb.a = 0.93
	if t > 0.4:
		draw_colored_polygon(title_bg, tb)
		C.outline(self, title_bg, C.GRAPHITE, 1.5, 500, 0.8)
	if t > 0.6:
		C.letters(self, "THE VIOLENCE", Vector2(88, 176), 84, C.CHARCOAL, 501, 3, 0.95, rev(0.6, 1.6))
	if t > 2.0:
		C.line(self, Vector2(86, 198), Vector2(86 + 640 * rev(2.0, 0.6), 194), C.RED, 7.0, 502, 2.4, 2)
		C.line(self, Vector2(96, 210), Vector2(96 + 560 * rev(2.2, 0.6), 212), C.RED, 4.0, 503, 2.0, 1)
	if t > 2.6:
		C.letters(self, "PORT CARRICK  ·  FORTY WEEKS TO THE ELECTION", Vector2(90, 242), 20, C.BRICK, 504, 2, 1.0, rev(2.6, 0.8))
	# ---------------------------------------------------------------- the menu: torn scraps
	var hov := -1
	var hov_t := 0.0
	for h in HOVER_AT.size():
		if t >= float(HOVER_AT[h]):
			hov = HOVER_ITEM[h]
			hov_t = t - float(HOVER_AT[h])
	for i in ITEMS.size():
		var appear := 2.8 + i * 0.18
		if t < appear:
			continue
		var y2 := 300.0 + i * 74.0
		var rot := (C.rnd(600, i) - 0.5) * 0.06
		var w: float = C.letters_width(String(ITEMS[i]), 30) + 60.0
		var lift := 8.0 if i == hov else 0.0
		var org := Vector2(80 + lift, y2)
		var scrap := PackedVector2Array()
		for p: Vector2 in [Vector2(0, 4), Vector2(w * 0.5, 0), Vector2(w, 6), Vector2(w - 4, 56), Vector2(w * 0.4, 60), Vector2(2, 54)]:
			scrap.append(org + (p as Vector2).rotated(rot) + Vector2(C.rnd(610 + i, int(p.x)) * 4.0, 0))
		var sc := C.PAPER_CREAM.darkened(0.04 + 0.05 * C.rnd(620, i))
		draw_colored_polygon(scrap, sc)
		C.outline(self, scrap, C.GRAPHITE, 1.3, 630 + i, 0.8)
		var tc := C.CHARCOAL if i != ITEMS.size() - 1 else C.BRICK_DARK
		if i == 1:
			tc = C.GRAPHITE
		C.letters(self, ITEMS[i], org + Vector2(24, 45).rotated(rot), 30, tc, 640 + i, 2, 1.0, rev(appear, 0.5))
		if i == hov:
			C.scribble_ring(self, org + Vector2(w * 0.5, 30), w * 0.56, 40, C.RED, 650 + i, clampf(hov_t / 0.5, 0.0, 1.0), 3.4)
			# a crayon arrow pointing at it
			var ap := org + Vector2(-46, 32)
			C.line(self, ap, ap + Vector2(34, 0), C.RED, 4.0, 660, 1.0, 1)
			C.line(self, ap + Vector2(34, 0), ap + Vector2(22, -10), C.RED, 4.0, 661, 1.0, 1)
			C.line(self, ap + Vector2(34, 0), ap + Vector2(22, 10), C.RED, 4.0, 662, 1.0, 1)
	# ---------------------------------------------------------------- the Ledger cutting
	if t > 3.6:
		var cut := PackedVector2Array([Vector2(1150, 640), Vector2(1540, 628), Vector2(1548, 846), Vector2(1144, 856)])
		draw_colored_polygon(cut, C.PAPER_CREAM.darkened(0.1))
		C.outline(self, cut, C.GRAPHITE, 1.4, 700, 0.8)
		C.letters(self, "THE CARRICK LEDGER", Vector2(1172, 680), 20, C.CHARCOAL, 701, 2)
		C.line(self, Vector2(1170, 690), Vector2(1520, 686), C.CHARCOAL, 2.0, 702, 0.8, 1)
		C.letters(self, "NEW CHIEF INHERITS", Vector2(1172, 732), 26, C.CHARCOAL, 703, 2)
		C.letters(self, "BRIDGE STREET FILE", Vector2(1172, 768), 26, C.CHARCOAL, 704, 2)
		for l in 3:
			var ly := 796.0 + l * 16.0
			C.line(self, Vector2(1172, ly), Vector2(1172 + 330 - l * 60, ly + 2), C.GRAPHITE, 2.0, 710 + l, 1.0, 1)
		# a thumbprint where someone held it
		C.smudge(self, Vector2(1520, 830), 22, C.CHARCOAL)
	# the footer, in pencil
	if t > 3.0:
		C.letters(self, "V1.3  ·  F2 RED INK  ·  F3 GORE  ·  ESC MENU", Vector2(84, 872), 14, C.CHARCOAL, 720, 1)


## One housing block (or a factory) in oblique view: roof, front face, window grid.
func _block(b: Dictionary, y: float, k: float) -> void:
	var x := float(b["x"])
	var w := float(b["w"]) * k
	var d := float(b["d"]) * k * 0.5
	var h := float(b["h"]) * k
	var s := int(b["seed"])
	var x0 := x * (0.75 + 0.25 * k) + (1.0 - k) * 300.0
	var front := Rect2(Vector2(x0, y - h), Vector2(w, h))
	var roof := PackedVector2Array([Vector2(x0, y - h), Vector2(x0 + w, y - h), Vector2(x0 + w + d * 0.4, y - h - d), Vector2(x0 + d * 0.4, y - h - d)])
	var rc := C.GRAPHITE.lightened(0.18)
	draw_colored_polygon(roof, rc)
	C.hatch(self, roof, C.CHARCOAL, 4.0, 0.3, s, 1.6, 1.0, 0.3)
	draw_rect(front, C.GRAPHITE.darkened(0.1))
	var fo := C.ORANGE
	fo.a = 0.22
	C.hatch(self, C.rect_poly(front), fo, 5.0, -1.2, s + 1, 1.6)
	if b["kind"] == "court":
		# the courtyard: a dark hole in the roof
		var cen := (roof[0] + roof[1] + roof[2] + roof[3]) * 0.25
		var court := PackedVector2Array()
		for rp in roof:
			court.append(cen.lerp(rp, 0.55))
		draw_colored_polygon(court, C.CHARCOAL)
		var cc := C.ORANGE
		cc.a = 0.35
		C.hatch(self, court, cc, 3.0, 0.9, s + 7, 1.4)
	# windows: a grid of ticks, a few of them lit
	var cols := maxi(3, int(w / (12.0 * maxf(0.6, k))))
	var rows := maxi(2, int(h / (11.0 * maxf(0.6, k))))
	for cx in cols:
		for ry in rows:
			var wx := front.position.x + (cx + 0.5) * w / cols
			var wy := front.position.y + (ry + 0.5) * h / rows
			var lit := C.rnd(s + cx, ry) < 0.08
			var wc := C.AMBER if lit else C.CHARCOAL
			draw_rect(Rect2(wx - 2.0 * k, wy - 2.5 * k, 4.0 * k, 5.0 * k), wc)
	C.outline(self, C.rect_poly(front), C.CHARCOAL, 1.6, s + 3, 0.7)
	C.outline(self, roof, C.CHARCOAL, 1.4, s + 4, 0.7)
	if b["kind"] == "factory":
		for ch in 3:
			var cx2 := x0 + w * (0.22 + ch * 0.14)
			var ctop := y - h - 70 * k - ch * 8 * k
			draw_rect(Rect2(cx2 - 5 * k, ctop, 10 * k, y - h - ctop), C.CHARCOAL)


## Black smoke pouring from a chimney: loops rising and drifting, moving with time.
func _smoke(base: Vector2, k: float, s: int) -> void:
	for puff in 14:
		var age := fmod(t * 0.3 + puff / 14.0, 1.0)
		var c := base + Vector2(age * 260 * k + sin(age * 6.0 + s) * 14, -age * 210 * k)
		var r := (14 + age * 60) * k
		var col := C.CHARCOAL
		col.a = 0.9 * (1.0 - age * 0.8)
		C.hatch(self, C.ellipse_poly(c, r, r * 0.7, 12, s + puff, 0.25), col, 2.6, 0.5 + puff, s + puff * 3, 2.2)
