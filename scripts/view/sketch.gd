extends RefCounted
## Sketch (1.4, the crayon overhaul): a recording of Crayon strokes that replays cheaply.
##
## Crayon draws a page out of thousands of short strokes; computing them (hatching clipped
## to polygons, wobbling outlines, stroke-font letters) every frame would cost far too
## much. A Sketch stands in for a CanvasItem while Crayon draws into it — it has the same
## draw_* methods — and keeps the result as batches: runs of line segments of one width
## (replayed with one draw_multiline_colors call) and filled polygons, in drawing order.
##
## Boil: a static layer records a few variants of itself (Sketch.variants), each with
## Crayon.frame set differently so every stroke wobbles a little differently, and the
## view replays variant Crayon.frame % n. The page shivers at the boil rate for the cost
## of replaying pre-cut geometry.
##
## Presentation only.

const C = preload("res://scripts/view/crayon.gd")

var xf := Transform2D.IDENTITY
var batches: Array = []    # [{k: "l", w, pts: PackedVector2Array, cols: PackedColorArray}] or [{k: "p", polys: [[pts, col]]}]


static func variants(n: int, fn: Callable) -> Array:
	var keep: int = C.frame
	var out: Array = []
	for k in n:
		C.frame = 1000 + k * 37
		var s = load("res://scripts/view/sketch.gd").new()
		fn.call(s)
		out.append(s)
	C.frame = keep
	return out


func replay(ci: CanvasItem) -> void:
	for b in batches:
		if b["k"] == "l":
			ci.draw_multiline_colors(b["pts"], b["cols"], b["w"], false)
		else:
			for p in b["polys"]:
				ci.draw_colored_polygon(p[0], p[1])


func _seg(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	if col.a <= 0.003:
		return
	var wq := snappedf(maxf(1.0, w), 0.5)
	var last: Dictionary = batches[batches.size() - 1] if not batches.is_empty() else {}
	if last.is_empty() or last["k"] != "l" or float(last["w"]) != wq:
		last = {"k": "l", "w": wq, "pts": PackedVector2Array(), "cols": PackedColorArray()}
		batches.append(last)
	last["pts"].append(xf * a)
	last["pts"].append(xf * b)
	last["cols"].append(col)


func _poly(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3 or col.a <= 0.003:
		return
	var last: Dictionary = batches[batches.size() - 1] if not batches.is_empty() else {}
	if last.is_empty() or last["k"] != "p":
		last = {"k": "p", "polys": []}
		batches.append(last)
	last["polys"].append([xf * pts, col])


# ------------------------------------------------------------------ the CanvasItem subset Crayon uses
func draw_set_transform(pos: Vector2, rot := 0.0, sc := Vector2.ONE) -> void:
	xf = Transform2D(rot, sc, 0.0, pos)


func draw_line(a: Vector2, b: Vector2, col: Color, w := -1.0, _aa := false) -> void:
	_seg(a, b, col, w)


func draw_polyline(pts: PackedVector2Array, col: Color, w := -1.0, _aa := false) -> void:
	for i in pts.size() - 1:
		_seg(pts[i], pts[i + 1], col, w)


func draw_dashed_line(a: Vector2, b: Vector2, col: Color, w := -1.0, dash := 2.0, _aligned := true, _aa := false) -> void:
	var L := a.distance_to(b)
	if L < 0.1:
		return
	var d := (b - a) / L
	var t := 0.0
	while t < L:
		_seg(a + d * t, a + d * minf(L, t + dash), col, w)
		t += dash * 2.0


func draw_colored_polygon(pts: PackedVector2Array, col: Color, _uvs := PackedVector2Array(), _tex = null) -> void:
	_poly(pts, col)


func draw_circle(c: Vector2, r: float, col: Color, filled := true, w := -1.0, _aa := false) -> void:
	var n := clampi(int(r * 0.8), 8, 24)
	var pts := PackedVector2Array()
	for k in n:
		pts.append(c + Vector2.from_angle(TAU * k / n) * r)
	if filled:
		_poly(pts, col)
	else:
		pts.append(pts[0])
		draw_polyline(pts, col, w)


func draw_arc(c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, w := -1.0, _aa := false) -> void:
	var prev := c + Vector2.from_angle(a0) * r
	for k in range(1, n + 1):
		var p := c + Vector2.from_angle(lerpf(a0, a1, float(k) / n)) * r
		_seg(prev, p, col, w)
		prev = p


func draw_rect(r: Rect2, col: Color, filled := true, w := -1.0, _aa := false) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	if filled:
		_poly(pts, col)
	else:
		pts.append(pts[0])
		draw_polyline(pts, col, w)


func draw_char(_f, _p, _c, _s := 16, _col := Color.WHITE) -> void:
	pass
