extends RefCounted
## Crayon props (1.4, the crayon overhaul): every piece of furniture, yard clutter and
## vehicle drawn the way a child draws it from above — a coloured box pressed hard at the
## edges, filled back and forth, and the one detail they would never leave out (pillows on
## the bed, rings on the stove, a seat on the toilet, wheels sticking out of the car).
##
## paint(ci, key, r, s) draws into any CanvasItem (or a Sketch) in plan pixels at 40 px
## per metre; tools/bake_crayon.gd bakes each into assets/crayon/ at the canonical size
## the sprites use. Presentation only.

const C = preload("res://scripts/view/crayon.gd")

const WOOD := Color("#8a5a36")
const WOOD_DARK := Color("#5d3a22")
const STEEL := Color("#8d96a0")
const STEEL_DARK := Color("#56606b")
const WHITE_GOODS := Color("#d9d6cc")
const FABRIC := Color("#6d5a8a")       # a sofa a child would choose
const BLANKET := Color("#3f6db3")
const GREEN := Color("#4f7a3a")
const GREEN_DARK := Color("#2f4a26")
const CONCRETE := Color("#9a968c")
const CAR_COLS := [Color("#a33a2c"), Color("#2f5a8a"), Color("#c99a2e"), Color("#4f6a3a"), Color("#6b6b70")]


static func _solid(ci, poly: PackedVector2Array, col: Color, s := 0) -> void:
	ci.draw_colored_polygon(poly, col)
	if poly.size() >= 3 and col.a > 0.5:
		var dk := col.darkened(0.22) if (col.r + col.g + col.b) > 1.2 else col.lightened(0.18)
		C.hatch(ci, poly, Color(dk, 0.6), 3.0, 0.75 + C.rnd(s + poly.size(), 3), s + 77, 1.4)


static func _fill(ci, r: Rect2, col: Color, s: int, sp := 3.4, ang := 0.6, w := 2.4) -> void:
	ci.draw_colored_polygon(C.rect_poly(r), Color(col, 0.55))
	C.hatch(ci, C.rect_poly(r), Color(col, 0.95), sp, ang, s, w)
	C.hatch(ci, C.rect_poly(r), Color(col.darkened(0.35), 0.45), sp * 1.8, ang + 1.3, s + 1, w * 0.8)


static func _poly_fill(ci, poly: PackedVector2Array, col: Color, s: int, sp := 3.2, ang := 0.6, w := 2.2) -> void:
	ci.draw_colored_polygon(poly, Color(col, 0.55))
	C.hatch(ci, poly, Color(col, 0.95), sp, ang, s, w)


static func _edge(ci, r: Rect2, s: int, w := 1.8) -> void:
	C.outline(ci, C.rect_poly(r), C.CHARCOAL, w, s, 0.9)


static func _ring(ci, c: Vector2, rad: float, col: Color, w := 1.8, s := 0) -> void:
	C.outline(ci, C.ellipse_poly(c, rad, rad, 12, s, 0.06), col, w, s, 0.5)


## Draw one prop. key is "furn/bed" or just "bed"; r is its rectangle in plan pixels.
static func paint(ci, key: String, r: Rect2, s := 0) -> void:
	var k := key.get_file()
	var along_x := r.size.x >= r.size.y
	var c := r.get_center()
	var mn := minf(r.size.x, r.size.y)
	match k:
		"bed", "bunk":
			_fill(ci, r, BLANKET, s, 3.2)
			var pil := Rect2(r.position + Vector2(2, 2), Vector2(r.size.x * 0.2, r.size.y - 4)) if along_x else Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.2))
			if k == "bed" and along_x and r.size.y > 40:
				for side in 2:
					var pr := Rect2(pil.position + Vector2(0, side * pil.size.y * 0.52), Vector2(pil.size.x, pil.size.y * 0.46))
					_solid(ci, C.rect_poly(pr), C.CHALK)
					_edge(ci, pr, s + 3 + side, 1.2)
			else:
				_solid(ci, C.rect_poly(pil), C.CHALK)
				_edge(ci, pil, s + 3, 1.2)
			# the fold of the sheet
			var f0 := r.position + (Vector2(r.size.x * 0.32, 2) if along_x else Vector2(2, r.size.y * 0.32))
			var f1 := f0 + (Vector2(0, r.size.y - 4) if along_x else Vector2(r.size.x - 4, 0))
			C.line(ci, f0, f1, C.CHALK.darkened(0.1), 3.0, s + 5, 0.8, 1)
			if k == "bunk":
				C.line(ci, r.position, r.end, C.CHARCOAL, 1.2, s + 6, 0.6, 1)
		"sofa", "armchair":
			_fill(ci, r, FABRIC, s, 2.8, 1.0)
			var back := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.3))
			_solid(ci, C.rect_poly(back), FABRIC.darkened(0.4))
			for sx: float in [0.0, 1.0]:
				var arm := Rect2(r.position + Vector2(sx * (r.size.x - r.size.x * 0.13), 0), Vector2(r.size.x * 0.13, r.size.y))
				_solid(ci, C.rect_poly(arm), FABRIC.darkened(0.4))
			if k == "sofa":
				for q in 2:
					var cu := Rect2(r.position + Vector2(r.size.x * (0.15 + 0.36 * q), r.size.y * 0.36), Vector2(r.size.x * 0.33, r.size.y * 0.56))
					_edge(ci, cu, s + 8 + q, 1.1)
		"coffee_table", "dining", "table", "desk", "picnic", "bench":
			_fill(ci, r, WOOD, s, 4.0, -0.5)
			if k in ["coffee_table", "desk", "table"]:
				for pp in 3:
					var q := r.position + Vector2(C.rnd(s, pp), C.rnd(s + 1, pp)) * (r.size - Vector2(9, 11)) + Vector2(1, 1)
					var pr := Rect2(q, Vector2(7, 9))
					_solid(ci, C.rect_poly(pr), C.CHALK)
					C.line(ci, q + Vector2(1.5, 3), q + Vector2(5.5, 3), C.GRAPHITE, 0.8, s + pp, 0.2, 1)
			if k == "desk":
				var lamp := r.position + Vector2(r.size.x * 0.85, r.size.y * 0.25)
				C.pool(ci, lamp, 9, 7, C.AMBER, s + 4, 0.7)
				ci.draw_circle(lamp, 3.0, C.CHARCOAL)
			if k == "picnic" or k == "bench":
				var n := 4 if k == "picnic" else 2
				for b in n:
					var y := r.position.y + r.size.y * (b + 0.5) / n
					C.line(ci, Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), WOOD_DARK, 1.4, s + 10 + b, 0.5, 1)
			if k == "dining":
				ci.draw_circle(c, mn * 0.12, C.CHALK)
				_ring(ci, c, mn * 0.12, C.GRAPHITE, 1.0, s + 6)
		"chair":
			_fill(ci, r.grow(-2), WOOD, s, 3.0)
			_solid(ci, C.rect_poly(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.22))), WOOD_DARK)
		"counter", "checkout", "cooler", "cabinet":
			_fill(ci, r, WHITE_GOODS.darkened(0.08) if k != "cooler" else Color("#7fa6c4"), s, 3.0, 0.2)
			if k == "counter":
				var sink := Rect2(c - Vector2(r.size.x * 0.12, r.size.y * 0.28), Vector2(r.size.x * 0.24, r.size.y * 0.56))
				_solid(ci, C.rect_poly(sink), STEEL)
				ci.draw_circle(sink.get_center(), 1.8, C.CHARCOAL)
			elif k == "checkout":
				var till := Rect2(r.position + Vector2(r.size.x * 0.7, 3), Vector2(r.size.x * 0.22, r.size.y * 0.5))
				_solid(ci, C.rect_poly(till), C.CHARCOAL)
				_solid(ci, C.rect_poly(till.grow(-3)), Color("#7cc48a"))
			elif k == "cooler":
				var nd := 4
				for d in nd:
					var x := r.position.x + r.size.x * (d + 1) / float(nd + 1)
					C.line(ci, Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), C.CHALK, 1.2, s + d, 0.4, 1)
				for b2 in 6:
					ci.draw_circle(r.position + Vector2(C.rnd(s + 3, b2) * r.size.x, (0.3 + 0.4 * C.rnd(s + 4, b2)) * r.size.y), 2.0, [C.RED, C.AMBER, GREEN][b2 % 3])
			else:
				C.line(ci, Vector2(c.x, r.position.y + 2), Vector2(c.x, r.end.y - 2), C.CHARCOAL, 1.2, s + 2, 0.4, 1)
		"stove":
			_fill(ci, r, WHITE_GOODS, s, 3.0)
			for ring in 4:
				var rc := r.position + Vector2(0.28 + 0.44 * (ring % 2), 0.3 + 0.4 * (ring / 2)) * r.size
				_ring(ci, rc, mn * 0.14, C.CHARCOAL, 1.8, s + ring)
				if ring == 1:
					_ring(ci, rc, mn * 0.07, C.ORANGE, 1.6, s + 9)
		"fridge", "washer":
			_fill(ci, r, WHITE_GOODS, s, 3.4, -0.3)
			if k == "washer":
				ci.draw_circle(c, mn * 0.3, STEEL_DARK)
				_ring(ci, c, mn * 0.3, C.CHARCOAL, 2.0, s + 2)
				ci.draw_circle(c + Vector2(-2, -2), mn * 0.1, Color("#9ec3e6"))
			else:
				C.line(ci, r.position + Vector2(r.size.x * 0.12, r.size.y * 0.5), r.end - Vector2(r.size.x * 0.12, r.size.y * 0.5), C.CHARCOAL, 1.4, s + 5, 0.5, 1)
				ci.draw_circle(r.position + Vector2(r.size.x * 0.8, r.size.y * 0.25), 2.0, C.RED)    # a magnet
		"tub", "basin", "toilet":
			if k == "tub":
				_fill(ci, r, WHITE_GOODS, s, 3.0, 0.9)
			var bowl := C.ellipse_poly(c + Vector2(0, r.size.y * (0.08 if k == "toilet" else 0.0)), r.size.x * (0.4 if k != "tub" else 0.38), r.size.y * (0.36 if k != "tub" else 0.3), 14, s, 0.05)
			_solid(ci, bowl, C.CHALK if k != "tub" else Color("#9ec3e6"))
			C.outline(ci, bowl, C.SLATE, 1.6, s, 0.4)
			if k == "toilet":
				var tank := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.26))
				_solid(ci, C.rect_poly(tank), C.CHALK.darkened(0.1))
				_edge(ci, tank, s + 4, 1.2)
				return
			ci.draw_circle(c + (Vector2(r.size.x * 0.32, 0) if k == "tub" else Vector2(0, -r.size.y * 0.2)), 1.8, C.CHARCOAL)
		"dresser", "wardrobe", "bookshelf", "shelving", "rack", "lockers":
			var base := WOOD if k in ["dresser", "wardrobe", "bookshelf"] else STEEL
			_fill(ci, r, base, s, 3.4, 1.0)
			var n := maxi(3, int((r.size.x if along_x else r.size.y) / 16.0))
			for b in n:
				var cell := Rect2(r.position + (Vector2(r.size.x * b / n, 0) if along_x else Vector2(0, r.size.y * b / n)), Vector2(r.size.x / n, r.size.y) if along_x else Vector2(r.size.x, r.size.y / n))
				if k in ["bookshelf", "shelving", "rack"]:
					var bc: Color = [C.BRICK, GREEN, C.SLATE_LIGHT, C.AMBER.darkened(0.25), BLANKET][int(C.rnd(s, b) * 5.0) % 5]
					_solid(ci, C.rect_poly(cell.grow(-2)), bc)
				C.line(ci, cell.position, cell.position + (Vector2(0, cell.size.y) if along_x else Vector2(cell.size.x, 0)), C.CHARCOAL, 1.2, s + b, 0.4, 1)
				if k in ["dresser", "lockers", "wardrobe"]:
					ci.draw_circle(cell.get_center(), 1.6, C.CHARCOAL)
		"stairs":
			_fill(ci, r, CONCRETE, s, 4.0, 0.3)
			var n2 := int((r.size.y if not along_x else r.size.x) / 9.0)
			for st in n2:
				var f := (st + 0.5) / n2
				if not along_x:
					C.line(ci, Vector2(r.position.x + 1, r.position.y + f * r.size.y), Vector2(r.end.x - 1, r.position.y + f * r.size.y), C.CHARCOAL, 1.3, s + st, 0.4, 1)
				else:
					C.line(ci, Vector2(r.position.x + f * r.size.x, r.position.y + 1), Vector2(r.position.x + f * r.size.x, r.end.y - 1), C.CHARCOAL, 1.3, s + st, 0.4, 1)
			var a0 := r.position + (Vector2(r.size.x * 0.5, r.size.y * 0.85) if not along_x else Vector2(r.size.x * 0.15, r.size.y * 0.5))
			var a1 := r.position + (Vector2(r.size.x * 0.5, r.size.y * 0.15) if not along_x else Vector2(r.size.x * 0.85, r.size.y * 0.5))
			C.line(ci, a0, a1, C.RED, 1.6, s + 40, 0.5, 1)
			var dv := (a1 - a0).normalized()
			C.line(ci, a1, a1 - dv.rotated(0.5) * 6.0, C.RED, 1.6, s + 41, 0.3, 1)
			C.line(ci, a1, a1 - dv.rotated(-0.5) * 6.0, C.RED, 1.6, s + 42, 0.3, 1)
		"crate", "pallet":
			_fill(ci, r, WOOD.lightened(0.1), s, 4.0, 0.0 if k == "pallet" else 0.6)
			if k == "crate":
				C.line(ci, r.position, r.end, WOOD_DARK, 1.6, s + 3, 0.5, 1)
				C.line(ci, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), WOOD_DARK, 1.6, s + 4, 0.5, 1)
			else:
				for b in 4:
					var y := r.position.y + r.size.y * (b + 0.5) / 4.0
					C.line(ci, Vector2(r.position.x, y), Vector2(r.end.x, y), WOOD_DARK, 1.4, s + b, 0.4, 1)
		"car", "van", "truck", "police_car", "police_van", "ambulance", "police_ambulance", "forklift":
			_vehicle(ci, k, r, s)
			return
		"tree":
			var rad := mn * 0.5
			var crown := C.ellipse_poly(c, rad * 0.95, rad * 0.95, 20, s, 0.16)
			_solid(ci, crown, Color(GREEN_DARK, 0.85))
			C.hatch(ci, crown, GREEN, 3.4, 0.9, s, 2.6)
			C.hatch(ci, crown, Color(GREEN_DARK.darkened(0.3), 0.7), 5.0, -0.5, s + 1, 2.2)
			for l in 7:
				var lc := c + Vector2(C.rnd(s, l) - 0.5, C.rnd(s + 3, l) - 0.5) * rad * 1.2
				C.outline(ci, C.ellipse_poly(lc, rad * 0.22, rad * 0.2, 9, s * 10 + l, 0.3), C.CHARCOAL, 1.4, s * 10 + l, 0.6)
			ci.draw_circle(c, rad * 0.09, WOOD_DARK)
			return
		"hedge", "planter":
			if k == "planter":
				_fill(ci, r, CONCRETE, s, 4.0)
				_edge(ci, r, s + 2)
			var hp := C.ellipse_poly(c, r.size.x * (0.52 if k == "hedge" else 0.36), r.size.y * (0.52 if k == "hedge" else 0.36), 16, s, 0.2)
			_solid(ci, hp, Color(GREEN_DARK, 0.85))
			C.hatch(ci, hp, GREEN, 2.8, 1.2, s, 2.4)
			for l2 in int(maxf(r.size.x, r.size.y) / 14.0) + 2:
				var q := c + Vector2(C.rnd(s + 5, l2) - 0.5, C.rnd(s + 6, l2) - 0.5) * r.size * 0.8
				C.scribble_ring(ci, q, 4.0, 3.5, C.CHARCOAL, s + l2, 1.0, 1.2)
			return
		"drum", "bins", "tank":
			if k == "bins":
				for b in 2:
					var bc := r.position + Vector2(r.size.x * (0.27 + 0.46 * b), r.size.y * 0.5)
					var br := minf(r.size.x * 0.22, r.size.y * 0.45)
					ci.draw_circle(bc, br, [GREEN, STEEL_DARK][b])
					C.hatch(ci, C.ellipse_poly(bc, br, br, 12, s + b), C.CHARCOAL, 3.2, 0.8, s + b, 1.4)
					_ring(ci, bc, br, C.CHARCOAL, 1.8, s + 4 + b)
					C.line(ci, bc - Vector2(br * 0.6, 0), bc + Vector2(br * 0.6, 0), C.CHARCOAL, 1.4, s + 6 + b, 0.3, 1)
				return
			var col := Color("#3f6db3") if k == "drum" else CONCRETE
			var dr := mn * 0.48
			_solid(ci, C.ellipse_poly(c, dr, dr, 16, s, 0.03), Color(col, 0.6))
			C.hatch(ci, C.ellipse_poly(c, dr, dr, 16, s, 0.03), col, 3.0, 0.7, s, 2.2)
			_ring(ci, c, dr, C.CHARCOAL, 2.2, s + 1)
			_ring(ci, c, dr * 0.62, C.CHARCOAL, 1.2, s + 2)
			if k == "tank":
				C.letters(ci, "GAS", c + Vector2(-dr * 0.4, dr * 0.12), int(dr * 0.4), C.RED, s + 3, 1)
			return
		"low_wall", "sandbags", "barrier":
			if k == "barrier":
				_fill(ci, r, C.TAPE, s, 3.0, 0.0)
				var x := r.position.x
				while x < r.end.x:
					C.line(ci, Vector2(x, r.end.y), Vector2(x + r.size.y, r.position.y), C.CHARCOAL, 3.0, s + int(x), 0.4, 1)
					x += r.size.y * 1.4
			elif k == "sandbags":
				var nb := maxi(2, int(r.size.x / 14.0))
				for b in nb:
					for row in 2:
						var bc2 := r.position + Vector2((b + 0.5 + row * 0.5) * r.size.x / nb, r.size.y * (0.28 + row * 0.44))
						if bc2.x > r.end.x - 4:
							continue
						var bag := C.ellipse_poly(bc2, r.size.x / nb * 0.55, r.size.y * 0.26, 10, s + b * 3 + row, 0.08)
						_solid(ci, bag, Color("#b59d6a"))
						C.outline(ci, bag, C.UMBER, 1.2, s + b * 3 + row, 0.4)
				return
			else:
				_solid(ci, C.rect_poly(r), C.BRICK_DARK)
				C.hatch(ci, C.rect_poly(r), C.BRICK, 6.0, PI / 2.0 if along_x else 0.0, s, 2.6)
				C.hatch(ci, C.rect_poly(r), Color(C.BRICK.lightened(0.2), 0.6), 3.0, 0.0 if along_x else PI / 2.0, s + 1, 1.0)
		"woodpile":
			for lg in 6:
				var lc2 := r.position + Vector2((lg + 0.5) / 6.0 * r.size.x, r.size.y * (0.35 + 0.3 * (lg % 2)))
				ci.draw_circle(lc2, r.size.y * 0.3, WOOD.lightened(0.15))
				_ring(ci, lc2, r.size.y * 0.3, C.CHARCOAL, 1.4, s + lg)
				_ring(ci, lc2, r.size.y * 0.12, WOOD_DARK, 1.0, s + lg + 9)
			return
		"ac_unit", "generator":
			_fill(ci, r, STEEL, s, 3.0)
			var fr := mn * 0.34
			var fc := r.position + Vector2(r.size.x - fr - 4, r.size.y * 0.5) if k == "generator" else c
			_ring(ci, fc, fr, C.CHARCOAL, 1.6, s + 3)
			for bl in 3:
				var a := TAU * bl / 3.0
				C.line(ci, fc, fc + Vector2.from_angle(a) * fr * 0.9, C.CHARCOAL, 1.4, s + 4 + bl, 0.3, 1)
			if k == "generator":
				C.letters(ci, "!", r.position + Vector2(6, r.size.y * 0.7), int(r.size.y * 0.5), C.RED, s + 8, 1)
		"shed", "container", "dumpster":
			var base2 := C.GRAPHITE.lightened(0.15) if k == "shed" else (Color("#a3452f") if k == "container" else GREEN_DARK)
			_fill(ci, r, base2, s, 3.0, 0.8)
			if k == "shed":
				C.line(ci, Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), C.CHARCOAL, 2.4, s + 3, 0.6, 2)
				var y2 := r.position.y + 6.0
				while y2 < r.end.y:
					C.line(ci, Vector2(r.position.x + 2, y2), Vector2(r.end.x - 2, y2), Color(C.CHARCOAL, 0.4), 1.0, s + int(y2), 0.3, 1)
					y2 += 9.0
			elif k == "container":
				var x2 := r.position.x + 5.0
				while x2 < r.end.x - 2:
					C.line(ci, Vector2(x2, r.position.y + 2), Vector2(x2, r.end.y - 2), Color(C.CHARCOAL, 0.6), 1.2, s + int(x2), 0.3, 1)
					x2 += 7.0
			else:
				C.line(ci, Vector2(c.x, r.position.y + 2), Vector2(c.x, r.end.y - 2), C.CHARCOAL, 1.6, s + 3, 0.4, 1)
		_:
			_fill(ci, r, WOOD, s)
	_edge(ci, r, s + 99)


## Cars, vans, trucks and the police's own: a box with its windscreens, wheels sticking
## out, and (for the police) the light bar and the word on the roof.
static func _vehicle(ci, k: String, r: Rect2, s: int) -> void:
	var c := r.get_center()
	var vertical := r.size.y > r.size.x
	var L := maxf(r.size.x, r.size.y)
	var Wd := minf(r.size.x, r.size.y)
	ci.draw_set_transform(c, PI / 2.0 if vertical else 0.0, Vector2.ONE)
	var col: Color = CAR_COLS[s % CAR_COLS.size()]
	match k:
		"police_car", "police_van":
			col = Color("#26324f")
		"ambulance":
			col = WHITE_GOODS
		"police_ambulance":
			col = Color("#d9d6cc")
		"truck":
			col = Color("#a3452f")
		"forklift":
			col = C.TAPE
	# wheels first, sticking out of the body as a child draws them
	for sx: float in ([-0.32, 0.3] if k != "truck" else [-0.38, -0.2, 0.32]):
		for sy: float in [-0.5, 0.5]:
			var wr := Rect2(Vector2(L * sx - L * 0.07, Wd * sy * 0.8 - Wd * 0.1), Vector2(L * 0.14, Wd * 0.2))
			_solid(ci, C.rect_poly(wr), C.CHARCOAL)
	var body := C.rect_poly(Rect2(Vector2(-L * 0.5, -Wd * 0.37), Vector2(L, Wd * 0.74)))
	_solid(ci, body, Color(col, 0.75))
	C.hatch(ci, body, col, 3.0, 0.6, s, 2.4)
	C.hatch(ci, body, Color(col.darkened(0.4), 0.5), 5.0, -0.9, s + 1, 1.8)
	if k == "truck":
		# the cab and the box behind
		C.line(ci, Vector2(L * 0.22, -Wd * 0.46), Vector2(L * 0.22, Wd * 0.46), C.CHARCOAL, 2.4, s + 2, 0.6, 2)
		_solid(ci, C.rect_poly(Rect2(Vector2(L * 0.32, -Wd * 0.36), Vector2(L * 0.08, Wd * 0.72))), C.SLATE)
	elif k == "forklift":
		for side: float in [-0.25, 0.25]:
			C.line(ci, Vector2(L * 0.5, Wd * side), Vector2(L * 0.78, Wd * side), C.CHARCOAL, 3.0, s + 3, 0.4, 1)
		_solid(ci, C.rect_poly(Rect2(Vector2(-L * 0.1, -Wd * 0.3), Vector2(L * 0.3, Wd * 0.6))), C.CHARCOAL)
	else:
		var roof_l := 0.42 if k in ["car", "police_car"] else 0.62
		var roof := Rect2(Vector2(-L * (roof_l * 0.5 + 0.04), -Wd * 0.29), Vector2(L * roof_l, Wd * 0.58))
		var roof_col: Color = col.lightened(0.15)
		if k == "police_car":
			roof_col = C.CHALK.darkened(0.08)
		_solid(ci, C.rect_poly(roof), roof_col)
		for side2: float in [1.0, -1.0]:
			var front := side2 > 0.0
			var x0 := roof.end.x if front else roof.position.x
			var x1 := x0 + side2 * L * 0.1
			var ws := PackedVector2Array([Vector2(x0, -Wd * 0.29), Vector2(x1, -Wd * 0.24), Vector2(x1, Wd * 0.24), Vector2(x0, Wd * 0.29)])
			_solid(ci, ws, C.SLATE)
			C.stroke(ci, ws[0].lerp(ws[3], 0.2), ws[1].lerp(ws[2], 0.3), C.CHALK, 1.4, s + 5 + int(side2))
		if k in ["police_car", "police_van", "police_ambulance"]:
			var bar := Rect2(Vector2(roof.position.x + roof.size.x * 0.3, -Wd * 0.33), Vector2(L * 0.05, Wd * 0.66))
			_solid(ci, C.rect_poly(Rect2(bar.position, Vector2(bar.size.x, bar.size.y * 0.5))), C.RED)
			_solid(ci, C.rect_poly(Rect2(bar.position + Vector2(0, bar.size.y * 0.5), Vector2(bar.size.x, bar.size.y * 0.5))), C.BLUE)
			C.letters(ci, "POLICE", Vector2(roof.position.x + roof.size.x * 0.42, Wd * 0.13), int(Wd * 0.26), C.CHARCOAL if k == "police_car" else C.CHALK, s + 7, 1, 0.8)
		if k in ["ambulance", "police_ambulance"]:
			var cx := roof.position.x + roof.size.x * 0.3
			_solid(ci, C.rect_poly(Rect2(Vector2(cx - Wd * 0.2, -Wd * 0.06), Vector2(Wd * 0.4, Wd * 0.12))), C.RED)
			_solid(ci, C.rect_poly(Rect2(Vector2(cx - Wd * 0.06, -Wd * 0.2), Vector2(Wd * 0.12, Wd * 0.4))), C.RED)
	C.outline(ci, body, C.CHARCOAL, 2.2, s + 9, 0.8)
	# headlights
	for sy2: float in [-0.32, 0.32]:
		ci.draw_circle(Vector2(L * 0.48, Wd * sy2), Wd * 0.06, C.AMBER)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
