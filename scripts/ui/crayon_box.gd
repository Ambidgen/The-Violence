extends StyleBox
## A hand-drawn box (1.4, the crayon overhaul): the panels and buttons of the UI as
## scraps of paper coloured in, edged in pencil gone over twice. Corners are never quite
## square and the strokes overshoot; each box wobbles to its own seed (its size), so two
## buttons side by side are drawn differently. Static (UI boxes do not boil).

const C = preload("res://scripts/view/crayon.gd")

var bg := Color("#e6dfcd")
var border := Color("#2f2e2d")
var border_w := 1.6
var grain := 0.22          # how much the fill shows its strokes (0: flat)
var torn := false          # a torn scrap: the bottom edge ragged
var underline := Color(0, 0, 0, 0)   # a crayon underline (selected tabs, pressed buttons)


static func make(bg_c: Color, border_c: Color, margin := 6.0, bw := 1.6, grain_v := 0.22) -> StyleBox:
	var b = load("res://scripts/ui/crayon_box.gd").new()
	b.bg = bg_c
	b.border = border_c
	b.border_w = bw
	b.grain = grain_v
	b.set_content_margin_all(margin)
	return b


func _rnd(s: int, i: int) -> float:
	return C.rnd(s, i) * 2.0 - 1.0


func _draw(ci: RID, r: Rect2) -> void:
	if r.size.x < 2.0 or r.size.y < 2.0:
		return
	var s := int(r.size.x * 7.0 + r.size.y * 13.0) % 9973
	var j := minf(2.2, minf(r.size.x, r.size.y) * 0.06)
	var p := PackedVector2Array([
		r.position + Vector2(_rnd(s, 1), _rnd(s, 2)) * j,
		Vector2(r.end.x, r.position.y) + Vector2(_rnd(s, 3), _rnd(s, 4)) * j,
		r.end + Vector2(_rnd(s, 5), _rnd(s, 6)) * j,
		Vector2(r.position.x, r.end.y) + Vector2(_rnd(s, 7), _rnd(s, 8)) * j,
	])
	if torn:
		var rag := PackedVector2Array([p[0], p[1], p[2]])
		var n := int(r.size.x / 9.0)
		for k in range(n, 0, -1):
			var x := r.position.x + r.size.x * k / float(n + 1)
			rag.append(Vector2(x, r.end.y + _rnd(s, 40 + k) * 2.5 - 1.0))
		rag.append(p[3])
		p = rag
	if bg.a > 0.0:
		RenderingServer.canvas_item_add_polygon(ci, p, PackedColorArray([bg]))
		if grain > 0.0:
			# the fill's strokes: long slanted passes, lighter and darker
			var dk := bg.darkened(0.12)
			dk.a = grain * bg.a
			var lt := bg.lightened(0.08)
			lt.a = grain * 0.8 * bg.a
			var step := 7.0
			var t := -r.size.y
			var k2 := 0
			while t < r.size.x:
				var a := r.position + Vector2(t, r.size.y)
				var b := r.position + Vector2(t + r.size.y * 0.7, 0)
				var seg := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]), p)
				for sg in seg:
					if sg.size() >= 2:
						RenderingServer.canvas_item_add_line(ci, sg[0], sg[sg.size() - 1], dk if k2 % 2 == 0 else lt, 2.0 + C.rnd(s, k2) * 1.5, true)
				t += step * (0.7 + 0.6 * C.rnd(s + 9, k2))
				k2 += 1
	if border.a > 0.0 and border_w > 0.0:
		var n2 := p.size()
		for e in n2:
			var a2: Vector2 = p[e]
			var b2: Vector2 = p[(e + 1) % n2]
			if torn and e >= 2 and e < n2 - 1:
				continue
			var d := b2 - a2
			var L := d.length()
			if L < 1.0:
				continue
			var tdir := d / L
			var nrm := tdir.orthogonal()
			for pass_i in 2:
				var over := minf(5.0, L * 0.05) * (0.4 + 0.6 * C.rnd(s + pass_i, e))
				var pts := PackedVector2Array()
				var segs := maxi(2, int(L / 14.0))
				for q in segs + 1:
					var f := float(q) / segs
					var wob := sin(f * PI * (1.0 + C.rnd(s, e * 5 + pass_i)) + C.rnd(s, e) * 6.0) * 0.8
					pts.append(a2 - tdir * over + (d + tdir * over * 2.0) * f + nrm * (wob + pass_i * 0.7))
				var col := border
				col.a *= 0.95 if pass_i == 0 else 0.45
				RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([col]), border_w * (1.0 if pass_i == 0 else 0.7), true)
	if underline.a > 0.0:
		var y := r.end.y - 3.0
		var u := PackedVector2Array()
		for q2 in 9:
			var f2 := q2 / 8.0
			u.append(Vector2(lerpf(r.position.x + 5.0, r.end.x - 5.0, f2), y + sin(f2 * 5.0 + s) * 1.1))
		RenderingServer.canvas_item_add_polyline(ci, u, PackedColorArray([underline]), 2.6, true)
