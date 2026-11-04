extends RefCounted
## Crayon (visual overhaul, prototype 2). The page is drawn by hand, right now, in
## charcoal, graphite and wax crayon on toned paper — dense and dark, rough but
## detailed, with a few hot colours doing all the talking: lamplight, police lights,
## warning tape, blood.
##
## Reference plates (2026-10-27): a riot line at a crossroads in the rain under a
## searchlight; an evidence scene from above (markers, a cap, a belt, a blood trail into
## a drain); a police van in red-and-blue smear and steam; a smog-orange grid of housing
## blocks; an interrogation room under one bulb; a looted storefront; an apartment cut
## away from above (dark rooms, orange window light, a red hallway); a graffiti alley; a
## police compound with orange light cones.
##
## What carries the look:
##   - CHARCOAL: fills are dense parallel hatching, two or three layers at crossing
##     angles, plus smudges; dark values dominate, paper shows only in highlights;
##   - LIGHT IS COLOUR: light is never a gradient but a scribbled shape in amber or
##     orange laid over the dark (cones, pools, window spill), and red/blue smears;
##   - BOIL: every stroke shivers a few times a second (frame, advanced by the scene);
##   - DRAW-ON: strokes can be asked for part of their length (reveal 0..1).
## Presentation only. Nothing here touches the simulation.

# ------------------------------------------------------------------ palette
const PAPER_GREY := Color("#8d8a83")     # toned paper (most plates)
const PAPER_CREAM := Color("#e6dfcd")    # the compound and apartment plates
const CHALK := Color("#ecebe4")          # chalk white: markers, rain glints, steam
const CHARCOAL := Color("#141313")
const GRAPHITE := Color("#2f2e2d")
const SLATE := Color("#3b4350")          # wet asphalt, night rooms
const SLATE_LIGHT := Color("#5d6878")
const NAVY := Color("#1f2a44")           # uniforms
const BRICK := Color("#6b2f24")
const BRICK_DARK := Color("#3f1d17")
const UMBER := Color("#4a3426")
const MOSS := Color("#55644a")           # sidewalks, grime
const AMBER := Color("#f0b53b")          # bulbs, searchlights
const ORANGE := Color("#e8722b")         # sodium lamps, window spill
const TAPE := Color("#e7c93b")           # warning tape, barriers
const RED := Color("#c42b33")            # police light, alarm light
const BLOOD := Color("#7e1d1f")
const BLUE := Color("#3b6fd6")           # police light
const RAIN := Color("#7f9fd6")
const SKIN := Color("#c99a7a")

static var frame := 0          # the boil frame (advanced ~8 times a second)
static var boil := 1.0         # wobble scale; 0 = still lines
static var font: Font = null
## Boil frames a second for everything live (the "Line boil" setting; 0 stills the page).
static var fps := 8.0


## Advance the boil clock from real time; returns the frame.
static func tick() -> int:
	frame = 0 if fps <= 0.0 else int(Time.get_ticks_msec() * fps / 1000.0)
	return frame


# ------------------------------------------------------------------ noise
## Stable 0..1 hash (does not boil).
static func rnd(s: int, i: int) -> float:
	var h := int((s * 374761393 + i * 668265263) & 0x7fffffff)
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


## Boiling -1..1 hash (changes with frame).
static func jit(s: int, i: int) -> float:
	return rnd(s + frame * 7919, i) * 2.0 - 1.0


static func n1(s: int, x: float) -> float:
	var i := int(floor(x))
	var f := x - float(i)
	var u := f * f * (3.0 - 2.0 * f)
	return lerpf(jit(s, i), jit(s, i + 1), u)


# ------------------------------------------------------------------ strokes
## One quick stroke (fills use thousands): ends jittered, width and alpha varied.
static func stroke(ci, a: Vector2, b: Vector2, col: Color, w: float, s: int, j := 1.2) -> void:
	var o1 := Vector2(jit(s, 1), jit(s, 2)) * j * boil
	var o2 := Vector2(jit(s, 3), jit(s, 4)) * j * boil
	var c := col
	c.a *= 0.55 + 0.45 * rnd(s, 5)
	ci.draw_line(a + o1, b + o2, c, w * (0.7 + 0.6 * rnd(s, 6)), true)


## An outline line as a hand draws it: wobbling, overshooting, gone over twice.
static func line(ci, a: Vector2, b: Vector2, col: Color, w := 2.0, s := 0, amp := 1.4, passes := 2, reveal := 1.0) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.5 or reveal <= 0.0:
		return
	var t := d / L
	var nrm := Vector2(-t.y, t.x)
	var over := minf(7.0, L * 0.07)
	for p in passes:
		var sd := s * 31 + p * 7
		var pa := a - t * over * rnd(sd, 1)
		var pb := b + t * over * rnd(sd, 2)
		var seg := maxi(2, int(L / 10.0))
		var pts := PackedVector2Array()
		var n_draw := maxi(1, int(ceil(seg * reveal)))
		for k in n_draw + 1:
			var f := minf(float(k) / float(seg), reveal)
			pts.append(pa.lerp(pb, f) + nrm * (n1(sd, f * L / 24.0) * amp * boil + p * 0.9 - 0.45))
		var c := col
		c.a *= 0.9 if p == 0 else 0.5
		ci.draw_polyline(pts, c, w * (1.0 if p == 0 else 0.65), true)


static func outline(ci, poly: PackedVector2Array, col: Color, w := 2.0, s := 0, amp := 1.2, reveal := 1.0) -> void:
	var n := poly.size()
	for k in n:
		var rv := clampf(reveal * n - k, 0.0, 1.0)
		line(ci, poly[k], poly[(k + 1) % n], col, w, s + k * 13, amp, 2, rv)


static func rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func ellipse_poly(c: Vector2, rx: float, ry: float, n := 18, s := 0, wob := 0.08, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		var w := 1.0 + wob * (rnd(s, k) * 2.0 - 1.0)
		pts.append(c + Vector2(cos(a) * rx * w, sin(a) * ry * w).rotated(rot))
	return pts


## Hatching inside any polygon: parallel strokes at an angle, spacing in px. reveal
## draws the first part of the strokes in order (the hand working across).
static func hatch(ci, poly: PackedVector2Array, col: Color, spacing := 5.0, angle := -0.7, s := 0, w := 2.0, reveal := 1.0, skip := 0.0) -> void:
	if poly.size() < 3 or reveal <= 0.0:
		return
	var mn := poly[0]
	var mx := poly[0]
	for p in poly:
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
	var c := (mn + mx) * 0.5
	var half := (mx - mn).length() * 0.5 + 2.0
	var dir := Vector2(cos(angle), sin(angle))
	var nrm := Vector2(-dir.y, dir.x)
	var n := int(half * 2.0 / maxf(1.0, spacing))
	var shown := int(ceil(n * reveal))
	for k in shown:
		if skip > 0.0 and rnd(s + 9, k) < skip:
			continue
		var off := -half + k * spacing + (rnd(s, k) - 0.5) * spacing * 0.8
		var ang_j := (rnd(s + 1, k) - 0.5) * 0.12
		var d2 := dir.rotated(ang_j)
		var p0 := c + nrm * off - d2 * half
		var p1 := c + nrm * off + d2 * half
		var segs: Array = Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([p0, p1]), poly)
		for sg in segs:
			var pl: PackedVector2Array = sg
			if pl.size() >= 2:
				stroke(ci, pl[0], pl[pl.size() - 1], col, w, s * 977 + k * 3, 1.0)


static func hatch_rect(ci, r: Rect2, col: Color, spacing := 5.0, angle := -0.7, s := 0, w := 2.0, reveal := 1.0) -> void:
	hatch(ci, rect_poly(r), col, spacing, angle, s, w, reveal)


## Charcoal: two crossing layers of hatching and a few smudges. The dark default.
static func charcoal(ci, poly: PackedVector2Array, col: Color, spacing := 4.0, s := 0, reveal := 1.0, w := 2.2) -> void:
	hatch(ci, poly, col, spacing, -0.75, s, w, reveal)
	var c2 := col
	c2.a *= 0.7
	hatch(ci, poly, c2, spacing * 1.6, 0.5, s + 50, w * 0.9, reveal, 0.25)


## A soft charcoal smudge (thumb-rubbed).
static func smudge(ci, c: Vector2, r: float, col: Color) -> void:
	for k in 12:
		var cc := col
		cc.a *= 0.05
		ci.draw_circle(c + Vector2(rnd(int(c.x), k) - 0.5, rnd(int(c.y), k) - 0.5) * r * 0.2, r * (1.0 - k * 0.075), cc)


# ------------------------------------------------------------------ light
## A pool of lamplight on the ground: an ellipse scribbled in hard over the dark, with a
## ragged rim of strokes. The plates never fade light out; they draw its edge.
static func pool(ci, c: Vector2, rx: float, ry: float, col: Color, s := 0, alpha := 0.85) -> void:
	var cc := col
	cc.a = alpha
	var poly := ellipse_poly(c, rx, ry, 20, s, 0.12)
	hatch(ci, poly, cc, 3.4, -0.6, s, 3.0)
	var c2 := cc.lightened(0.25)
	c2.a = alpha * 0.8
	hatch(ci, ellipse_poly(c, rx * 0.55, ry * 0.55, 14, s + 3, 0.1), c2, 3.0, 0.7, s + 5, 2.6)
	for k in 16:
		var a := TAU * k / 16.0 + rnd(s, k) * 0.3
		var p := c + Vector2(cos(a) * rx, sin(a) * ry)
		var q := c + Vector2(cos(a) * rx, sin(a) * ry) * (1.08 + 0.12 * rnd(s, k + 30))
		stroke(ci, p, q, cc, 2.2, s * 17 + k)


## A cone of light from apex along angle: searchlights, weapon lights, a bulb's throw.
static func cone(ci, apex: Vector2, ang: float, length: float, spread: float, col: Color, s := 0, alpha := 0.7, spacing := 3.6) -> void:
	var pts := PackedVector2Array([apex])
	for k in 9:
		var a := ang - spread + 2.0 * spread * k / 8.0
		var L := length * (0.92 + 0.08 * cos((k - 4) * 0.4))
		pts.append(apex + Vector2(cos(a), sin(a)) * L)
	var cc := col
	cc.a = alpha
	hatch(ci, pts, cc, spacing, ang + 0.35, s, 2.6)
	var c2 := col.lightened(0.3)
	c2.a = alpha * 0.6
	var inner := PackedVector2Array([apex])
	for k2 in 5:
		var a2 := ang - spread * 0.4 + 0.8 * spread * k2 / 4.0
		inner.append(apex + Vector2(cos(a2), sin(a2)) * length * 0.75)
	hatch(ci, inner, c2, spacing * 1.1, ang - 0.3, s + 11, 2.2)


## Red and blue police light, smeared like pastel on the street; phase flips them.
static func police_smear(ci, c: Vector2, r: float, phase: float, s := 0) -> void:
	var red_on := fmod(phase, 1.0) < 0.5
	for side: float in [-1.0, 1.0]:
		var col := RED if (side < 0.0) == red_on else BLUE
		var strong := (side < 0.0) == red_on
		var cc := col
		cc.a = 0.75 if strong else 0.35
		var cen := c + Vector2(side * r * 0.45, 0)
		hatch(ci, ellipse_poly(cen, r * (0.9 if strong else 0.6), r * 0.55, 14, s + int(side * 3), 0.3), cc, 3.2, side * 0.6, s + 40 + int(side), 3.0)


## A puddle: slate blob, a cold rim, chalk glints, and the colour of whatever lights it.
static func puddle(ci, c: Vector2, rx: float, ry: float, s := 0, tint: Color = Color(0, 0, 0, 0)) -> void:
	var poly := ellipse_poly(c, rx, ry, 16, s, 0.28)
	var sl := SLATE_LIGHT
	sl.a = 0.75
	hatch(ci, poly, sl, 3.0, 0.15, s, 2.4)
	if tint.a > 0.0:
		var tc := tint
		tc.a = 0.6
		hatch(ci, ellipse_poly(c + Vector2(rx * 0.1, 0), rx * 0.5, ry * 0.4, 10, s + 2, 0.3), tc, 3.0, 1.5, s + 7, 2.6)
	var ch := CHALK
	ch.a = 0.55
	for k in 4:
		var y := c.y + (rnd(s, k) - 0.5) * ry
		var x := c.x + (rnd(s, k + 9) - 0.5) * rx
		stroke(ci, Vector2(x - rx * 0.25, y), Vector2(x + rx * 0.2, y), ch, 1.4, s + k * 5)
	var oc := GRAPHITE
	oc.a = 0.6
	outline(ci, poly, oc, 1.3, s + 60, 0.8)


## Rain: pale blue slashes over everything, re-dealt every boil frame.
static func rain(ci, area: Rect2, n := 140, s := 0, slant := -0.22, length := 30.0) -> void:
	for k in n:
		var x := area.position.x + rnd(s + frame * 31, k) * area.size.x
		var y := area.position.y + rnd(s + frame * 31 + 1, k) * area.size.y
		var col := RAIN
		col.a = 0.35 + 0.35 * rnd(s, k)
		ci.draw_line(Vector2(x, y), Vector2(x + slant * length, y + length), col, 1.5, true)


# ------------------------------------------------------------------ lettering
## A child's capitals as strokes (a single-stroke font of our own, so every letter is
## drawn — and can be drawn on — like any other line). Unit box: x 0..1, y 0 (top)..1.
const GLYPHS := {
	"A": [[[0, 1], [0.5, 0], [1, 1]], [[0.2, 0.62], [0.8, 0.62]]],
	"B": [[[0, 1], [0, 0], [0.62, 0], [0.85, 0.12], [0.85, 0.35], [0.62, 0.48], [0, 0.48]], [[0.62, 0.48], [0.92, 0.6], [0.92, 0.86], [0.68, 1], [0, 1]]],
	"C": [[[0.95, 0.15], [0.72, 0], [0.3, 0], [0.04, 0.25], [0.04, 0.75], [0.3, 1], [0.72, 1], [0.95, 0.85]]],
	"D": [[[0, 0], [0, 1], [0.55, 1], [0.92, 0.75], [0.92, 0.25], [0.55, 0], [0, 0]]],
	"E": [[[0.9, 0], [0, 0], [0, 1], [0.9, 1]], [[0, 0.5], [0.7, 0.5]]],
	"F": [[[0.9, 0], [0, 0], [0, 1]], [[0, 0.5], [0.7, 0.5]]],
	"G": [[[0.95, 0.15], [0.72, 0], [0.3, 0], [0.04, 0.25], [0.04, 0.75], [0.3, 1], [0.72, 1], [0.95, 0.8], [0.95, 0.55], [0.55, 0.55]]],
	"H": [[[0, 0], [0, 1]], [[1, 0], [1, 1]], [[0, 0.5], [1, 0.5]]],
	"I": [[[0.5, 0], [0.5, 1]], [[0.15, 0], [0.85, 0]], [[0.15, 1], [0.85, 1]]],
	"J": [[[0.9, 0], [0.9, 0.75], [0.65, 1], [0.3, 1], [0.05, 0.8]]],
	"K": [[[0, 0], [0, 1]], [[0.9, 0], [0, 0.62]], [[0.3, 0.42], [0.95, 1]]],
	"L": [[[0, 0], [0, 1], [0.85, 1]]],
	"M": [[[0, 1], [0, 0], [0.5, 0.62], [1, 0], [1, 1]]],
	"N": [[[0, 1], [0, 0], [1, 1], [1, 0]]],
	"O": [[[0.5, 0], [0.14, 0.12], [0, 0.5], [0.14, 0.88], [0.5, 1], [0.86, 0.88], [1, 0.5], [0.86, 0.12], [0.5, 0]]],
	"P": [[[0, 1], [0, 0], [0.7, 0], [0.92, 0.15], [0.92, 0.38], [0.7, 0.52], [0, 0.52]]],
	"Q": [[[0.5, 0], [0.14, 0.12], [0, 0.5], [0.14, 0.88], [0.5, 1], [0.86, 0.88], [1, 0.5], [0.86, 0.12], [0.5, 0]], [[0.6, 0.7], [1, 1.06]]],
	"R": [[[0, 1], [0, 0], [0.7, 0], [0.92, 0.15], [0.92, 0.38], [0.7, 0.52], [0, 0.52]], [[0.45, 0.52], [0.95, 1]]],
	"S": [[[0.9, 0.12], [0.65, 0], [0.3, 0], [0.05, 0.15], [0.08, 0.4], [0.5, 0.5], [0.9, 0.62], [0.95, 0.85], [0.7, 1], [0.3, 1], [0.04, 0.88]]],
	"T": [[[0, 0], [1, 0]], [[0.5, 0], [0.5, 1]]],
	"U": [[[0, 0], [0, 0.75], [0.25, 1], [0.75, 1], [1, 0.75], [1, 0]]],
	"V": [[[0, 0], [0.5, 1], [1, 0]]],
	"W": [[[0, 0], [0.22, 1], [0.5, 0.4], [0.78, 1], [1, 0]]],
	"X": [[[0, 0], [1, 1]], [[1, 0], [0, 1]]],
	"Y": [[[0, 0], [0.5, 0.5], [1, 0]], [[0.5, 0.5], [0.5, 1]]],
	"Z": [[[0, 0], [1, 0], [0, 1], [1, 1]]],
	"0": [[[0.5, 0], [0.12, 0.15], [0.05, 0.5], [0.12, 0.85], [0.5, 1], [0.88, 0.85], [0.95, 0.5], [0.88, 0.15], [0.5, 0]]],
	"1": [[[0.2, 0.22], [0.55, 0], [0.55, 1]], [[0.2, 1], [0.85, 1]]],
	"2": [[[0.05, 0.2], [0.3, 0], [0.7, 0], [0.95, 0.2], [0.9, 0.45], [0, 1], [1, 1]]],
	"3": [[[0.05, 0.1], [0.4, 0], [0.8, 0.05], [0.9, 0.25], [0.6, 0.48], [0.9, 0.7], [0.85, 0.95], [0.45, 1], [0.05, 0.9]], [[0.6, 0.48], [0.32, 0.48]]],
	"4": [[[0.75, 1], [0.75, 0], [0, 0.7], [1, 0.7]]],
	"5": [[[0.9, 0], [0.15, 0], [0.08, 0.45], [0.55, 0.4], [0.9, 0.6], [0.9, 0.85], [0.6, 1], [0.05, 0.92]]],
	"6": [[[0.85, 0.05], [0.45, 0], [0.1, 0.3], [0.05, 0.7], [0.3, 1], [0.7, 1], [0.95, 0.75], [0.8, 0.5], [0.4, 0.48], [0.08, 0.65]]],
	"7": [[[0, 0], [1, 0], [0.35, 1]]],
	"8": [[[0.5, 0.48], [0.15, 0.3], [0.2, 0.05], [0.5, 0], [0.8, 0.05], [0.85, 0.3], [0.5, 0.48], [0.1, 0.7], [0.2, 0.97], [0.5, 1], [0.8, 0.97], [0.9, 0.7], [0.5, 0.48]]],
	"9": [[[0.92, 0.35], [0.6, 0.52], [0.2, 0.45], [0.08, 0.2], [0.4, 0], [0.8, 0.05], [0.95, 0.35], [0.85, 0.75], [0.5, 1], [0.15, 0.95]]],
	":": [[[0.5, 0.28], [0.5, 0.36]], [[0.5, 0.78], [0.5, 0.86]]],
	".": [[[0.5, 0.9], [0.5, 1]]],
	",": [[[0.55, 0.88], [0.38, 1.12]]],
	"·": [[[0.45, 0.5], [0.55, 0.52]]],
	"!": [[[0.5, 0], [0.5, 0.68]], [[0.5, 0.9], [0.5, 1]]],
	"?": [[[0.08, 0.2], [0.35, 0], [0.75, 0.05], [0.88, 0.3], [0.5, 0.5], [0.5, 0.7]], [[0.5, 0.9], [0.5, 1]]],
	"-": [[[0.15, 0.52], [0.85, 0.52]]],
	"'": [[[0.5, 0], [0.42, 0.26]]],
	"/": [[[0.9, 0], [0.1, 1]]],
	"+": [[[0.5, 0.25], [0.5, 0.78]], [[0.2, 0.52], [0.8, 0.52]]],
	"%": [[[0.9, 0], [0.1, 1]], [[0.15, 0.05], [0.3, 0.05], [0.3, 0.25], [0.15, 0.25], [0.15, 0.05]], [[0.7, 0.75], [0.85, 0.75], [0.85, 0.95], [0.7, 0.95], [0.7, 0.75]]],
	"$": [[[0.85, 0.2], [0.5, 0.08], [0.15, 0.22], [0.2, 0.42], [0.8, 0.58], [0.85, 0.8], [0.5, 0.92], [0.12, 0.8]], [[0.5, -0.05], [0.5, 1.05]]],
	"#": [[[0.35, 0], [0.25, 1]], [[0.75, 0], [0.65, 1]], [[0.05, 0.35], [0.95, 0.35]], [[0.05, 0.68], [0.95, 0.68]]],
	"(": [[[0.8, -0.05], [0.35, 0.2], [0.25, 0.5], [0.35, 0.8], [0.8, 1.05]]],
	")": [[[0.2, -0.05], [0.65, 0.2], [0.75, 0.5], [0.65, 0.8], [0.2, 1.05]]],
	"&": [[[0.95, 1], [0.2, 0.35], [0.25, 0.08], [0.5, 0], [0.7, 0.12], [0.6, 0.35], [0.1, 0.65], [0.15, 0.92], [0.45, 1], [0.75, 0.85], [0.95, 0.55]]],
}
const GLYPH_W := {"I": 0.5, "1": 0.55, "M": 1.15, "W": 1.2, ":": 0.3, ".": 0.3, ",": 0.3, "·": 0.35, "!": 0.3, "'": 0.3, "-": 0.6, "(": 0.45, ")": 0.45}


static func _font() -> Font:
	if font == null:
		font = ThemeDB.fallback_font
	return font


## Letters printed in crayon capitals, as strokes: each glyph a little tilted and bobbing,
## its strokes wobbling and gone over (heavy passes). pos is the left end of the baseline;
## size is the cap height in px. reveal prints the first part of the text. Returns width.
static func letters(ci, text: String, pos: Vector2, size := 32, col: Color = CHARCOAL, s := 0, heavy := 2, spacing := 1.0, reveal := 1.0) -> float:
	var up := text.to_upper()
	var h := float(size)
	var x := 0.0
	var n := up.length()
	var shown := reveal * n
	var w := maxf(1.2, h * 0.085)
	for i in n:
		var ch := up.substr(i, 1)
		var gw: float = float(GLYPH_W.get(ch, 0.78)) * h * 0.62
		if ch == " ":
			x += h * 0.42 * spacing
			continue
		if float(i) >= shown:
			break
		var part := clampf(shown - i, 0.0, 1.0)
		var strokes: Array = GLYPHS.get(ch, [])
		var rot := (rnd(s, i) - 0.5) * 0.16
		var bob := (rnd(s + 3, i) - 0.5) * h * 0.1
		var org := pos + Vector2(x, bob - h)
		var ns := strokes.size()
		for k in ns:
			var sp := clampf(part * ns - k, 0.0, 1.0)
			if sp <= 0.0:
				break
			var pts: Array = strokes[k]
			var seg_n := pts.size() - 1
			for j in seg_n:
				var segp := clampf(sp * seg_n - j, 0.0, 1.0)
				if segp <= 0.0:
					break
				var a := Vector2(float(pts[j][0]) * gw, float(pts[j][1]) * h).rotated(rot) + org
				var b := Vector2(float(pts[j + 1][0]) * gw, float(pts[j + 1][1]) * h).rotated(rot) + org
				for p in heavy:
					var cc := col
					cc.a *= 0.95 if p == 0 else 0.45
					var o := Vector2(rnd(s + p * 5, i * 31 + k * 7 + j), rnd(s + p * 5 + 1, i * 31 + k * 7 + j)) * p * 1.3
					line(ci, a + o, b + o, cc, w * (1.0 if p == 0 else 0.7), s * 97 + i * 13 + k * 5 + j + p * 1009, h * 0.025, 1, segp)
		x += gw + h * 0.2 * spacing
	return x


## The width a text will take (for layout).
static func letters_width(text: String, size := 32, spacing := 1.0) -> float:
	var up := text.to_upper()
	var h := float(size)
	var x := 0.0
	for i in up.length():
		var ch := up.substr(i, 1)
		if ch == " ":
			x += h * 0.42 * spacing
		else:
			x += float(GLYPH_W.get(ch, 0.78)) * h * 0.62 + h * 0.2 * spacing
	return x


## A scribbled underline or circle round something (menus, emphasis).
static func scribble_ring(ci, c: Vector2, rx: float, ry: float, col: Color, s := 0, reveal := 1.0, w := 2.6) -> void:
	var turns := 1.35
	var n := int(40 * turns)
	var shown := int(n * reveal)
	var pts := PackedVector2Array()
	for k in shown:
		var a := -2.4 + TAU * turns * k / n
		var wob := 1.0 + 0.07 * n1(s, k * 0.3) * boil + 0.05 * k / n
		pts.append(c + Vector2(cos(a) * rx * wob, sin(a) * ry * wob))
	if pts.size() >= 2:
		ci.draw_polyline(pts, col, w, true)


# ------------------------------------------------------------------ props and marks
## An evidence tent: a chalk-white folded card with its number.
static func evidence(ci, p: Vector2, n: int, s := 0, scale := 1.0) -> void:
	var r := Rect2(p - Vector2(9, 7) * scale, Vector2(18, 14) * scale)
	ci.draw_rect(r, CHALK.darkened(0.05))
	outline(ci, rect_poly(r), GRAPHITE, 1.2, s, 0.5)
	letters(ci, str(n), p + Vector2(-4, 5) * scale, int(12 * scale), CHARCOAL, s + 1, 1)


## Warning tape: a yellow band with black slashes, sagging.
static func tape(ci, a: Vector2, b: Vector2, s := 0, w := 7.0) -> void:
	var mid := (a + b) * 0.5 + Vector2(0, (b - a).length() * 0.06)
	var pts := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	ci.draw_polyline(pts, TAPE, w, true)
	for k2 in 12:
		var q := pts[k2]
		var d := (pts[k2 + 1] - q).normalized()
		var nn := Vector2(-d.y, d.x)
		ci.draw_line(q - nn * w * 0.45, q + d * w * 0.6 + nn * w * 0.45, CHARCOAL, 2.2, true)


## A streetlamp seen from above: a dark head, its pool of sodium light around it.
static func lamp_top(ci, p: Vector2, r: float, s := 0) -> void:
	pool(ci, p, r, r * 0.8, ORANGE, s, 0.8)
	ci.draw_circle(p, 5.0, CHARCOAL)
	ci.draw_circle(p, 2.4, AMBER)


# ------------------------------------------------------------------ paper
## Toned paper: fibres, grain, foxing, thumbprints at the margins, a darker edge.
static func paper_texture(size: Vector2i, base: Color, s := 7, grime := 1.0) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	for y in size.y:
		for x in size.x:
			var g := rng.randf_range(-0.035, 0.035)
			var ex := minf(minf(x, size.x - 1 - x), minf(y, size.y - 1 - y)) / float(mini(size.x, size.y))
			var edge := clampf(0.12 - ex, 0.0, 0.12) * grime
			img.set_pixel(x, y, Color(base.r + g - edge, base.g + g - edge, base.b + g * 1.1 - edge))
	# fibres
	for k in int(size.x * size.y / 900):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var d := Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(2, 7)
		for t in 6:
			var q := p + d * t / 6.0
			if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y:
				img.set_pixel(int(q.x), int(q.y), img.get_pixel(int(q.x), int(q.y)).darkened(0.06))
	# thumbprints and grime, mostly at the margins
	for k2 in int(14 * grime):
		var edge_side := rng.randi() % 4
		var cx := rng.randi_range(0, size.x - 1)
		var cy := rng.randi_range(0, size.y - 1)
		match edge_side:
			0: cx = rng.randi_range(0, size.x / 10)
			1: cx = rng.randi_range(size.x * 9 / 10, size.x - 1)
			2: cy = rng.randi_range(0, size.y / 8)
			3: cy = rng.randi_range(size.y * 7 / 8, size.y - 1)
		var rr := rng.randi_range(8, 26)
		for dy in range(-rr, rr):
			for dx in range(-rr, rr):
				var px := cx + dx
				var py := cy + dy
				if px < 0 or py < 0 or px >= size.x or py >= size.y:
					continue
				var dd := sqrt(float(dx * dx + dy * dy)) / float(rr)
				# whorls: rings of a print
				var ring := 0.5 + 0.5 * sin(dd * 18.0)
				if dd < 1.0:
					img.set_pixel(px, py, img.get_pixel(px, py).darkened(0.09 * (1.0 - dd) * ring))
	return ImageTexture.create_from_image(img)


# ================================================================== people
## A person seen from straight above, drawn the way a child makes sense of one: a round
## head (cap, helmet or hair), a pebble body in the uniform's colour, two whole arms
## reaching for what the hands hold (mittens, never missing), two big boots that swap as
## they walk. Facing +x; rot turns it.
##   kind: "police" (cap), "tactical" (helmet), "suspect", "civilian"
static func figure(ci, pos: Vector2, rot: float, body: Color, kind := "police", s := 0, step := 0.0, aim := 1.0, gun := true, down := false, scale := 1.0, hands_up := false) -> void:
	var k := scale
	var T := func(v: Vector2) -> Vector2: return pos + v.rotated(rot) * k
	var shade := body.darkened(0.35)
	if down:
		var torso := PackedVector2Array()
		for p in ellipse_poly(Vector2(-6, 0), 22, 12, 14, s, 0.08):
			torso.append(T.call(p))
		ci.draw_colored_polygon(torso, body)
		hatch(ci, torso, shade, 3.0, rot + 0.6, s, 1.6)
		outline(ci, torso, CHARCOAL, 1.8, s + 1)
		for side: float in [-1.0, 1.0]:
			line(ci, T.call(Vector2(2, side * 9)), T.call(Vector2(14, side * 25)), body.darkened(0.15), 7 * k, s + 5 + int(side), 1.0, 1)
			ci.draw_circle(T.call(Vector2(15, side * 26)), 4.2 * k, SKIN)
			var boot := PackedVector2Array()
			for p2 in ellipse_poly(Vector2(-30, side * 8), 8, 5, 10, s + 7, 0.1):
				boot.append(T.call(p2))
			ci.draw_colored_polygon(boot, CHARCOAL)
		ci.draw_circle(T.call(Vector2(20, 2)), 9.5 * k, SKIN.darkened(0.1))
		hatch(ci, ellipse_poly(T.call(Vector2(17, 2)), 9.5 * k, 9.5 * k, 12, s + 9), GRAPHITE, 2.6, 0.4, s + 9, 1.8)
		return
	var sw := sin(step) * 7.0
	# boots
	for side: float in [-1.0, 1.0]:
		var boot2 := PackedVector2Array()
		for p3 in ellipse_poly(Vector2(5 + sw * side, side * 6.5), 8.5, 5.0, 10, s + 11 + int(side), 0.1):
			boot2.append(T.call(p3))
		ci.draw_colored_polygon(boot2, CHARCOAL)
	# body
	var bpoly := PackedVector2Array()
	for p4 in ellipse_poly(Vector2(-2, 0), 10.5, 16.5, 16, s + 13, 0.07):
		bpoly.append(T.call(p4))
	ci.draw_colored_polygon(bpoly, body)
	hatch(ci, bpoly, shade, 2.6, rot - 0.8, s + 14, 1.6)
	outline(ci, bpoly, CHARCOAL, 1.9, s + 15, 0.9)
	# arms, whole: shoulder, elbow, mitten
	var grip := Vector2(17, 3)
	var fore := Vector2(27, -1)
	for side2: float in [-1.0, 1.0]:
		var sh := Vector2(0, side2 * 13)
		var free_hand := Vector2(7 - sw * side2 * 0.6, side2 * 19)
		var hand: Vector2 = free_hand
		if hands_up:
			hand = Vector2(-4, side2 * 24)
		elif gun:
			hand = free_hand.lerp(grip if side2 > 0 else fore, aim)
		var elbow := sh.lerp(hand, 0.5) + Vector2(-4, side2 * 5)
		line(ci, T.call(sh), T.call(elbow), shade, 7.0 * k, s + 20 + int(side2), 0.9, 1)
		line(ci, T.call(elbow), T.call(hand), body.darkened(0.15), 6.0 * k, s + 22 + int(side2), 0.9, 1)
		ci.draw_circle(T.call(hand), 4.3 * k, SKIN)
		line(ci, T.call(hand) + Vector2(-3, 0).rotated(rot), T.call(hand) + Vector2(3, 0).rotated(rot), CHARCOAL, 1.0, s + 24, 0.6, 1)
	if gun and not hands_up:
		line(ci, T.call(Vector2(9, 2)), T.call(Vector2(9, 2).lerp(Vector2(42, 0), aim * 0.65 + 0.35)), CHARCOAL, 4.6 * k, s + 30, 0.5, 2)
	# head
	match kind:
		"police":
			ci.draw_circle(T.call(Vector2(0, 0)), 10.5 * k, NAVY.darkened(0.2))
			ci.draw_circle(T.call(Vector2(0, 0)), 7.0 * k, NAVY.lightened(0.1))
			line(ci, T.call(Vector2(9, -7)), T.call(Vector2(9, 7)), CHARCOAL, 3.0 * k, s + 41, 0.4, 1)   # the brim
			ci.draw_circle(T.call(Vector2(3, 0)), 1.8 * k, AMBER)                                           # the badge
		"tactical":
			ci.draw_circle(T.call(Vector2(0, 0)), 11.0 * k, CHARCOAL)
			ci.draw_circle(T.call(Vector2(-2, -2)), 4.0 * k, GRAPHITE.lightened(0.2))
		_:
			ci.draw_circle(T.call(Vector2(0, 0)), 9.8 * k, SKIN)
			var hair := UMBER if kind == "suspect" else Color("#2a2420")
			for h in 7:
				var a := -1.4 + h * 0.46
				line(ci, T.call(Vector2(-7, 0) + Vector2(cos(a), sin(a)) * 3), T.call(Vector2(2, 0) + Vector2(cos(a), sin(a)) * 8), hair, 2.6 * k, s + 50 + h, 0.7, 1)
	outline(ci, ellipse_poly(pos, 10.5 * k, 10.5 * k, 10, s + 60), CHARCOAL, 1.5, s + 61, 0.6)


## A person seen from the front at a distance (cutscenes, the menu): head, shoulders,
## maybe an arm up with a sign. Used by the hundred in a crowd.
static func person_front(ci, foot: Vector2, h: float, col: Color, s := 0, arm_up := false, sign_text := "", lit := 0.0) -> void:
	var head := foot - Vector2(0, h * 0.86)
	var body := PackedVector2Array([foot + Vector2(-h * 0.17, 0), foot + Vector2(h * 0.17, 0), head + Vector2(h * 0.15, h * 0.16), head + Vector2(-h * 0.15, h * 0.16)])
	var c := col.lerp(ORANGE, lit * 0.5)
	ci.draw_colored_polygon(body, c)
	hatch(ci, body, c.darkened(0.4), 2.4, -0.9, s, 1.4)
	ci.draw_circle(head, h * 0.1, c.lerp(SKIN, 0.35 + lit * 0.3))
	if arm_up:
		var hand := head + Vector2(h * (0.12 + 0.1 * rnd(s, 3)), -h * 0.32)
		line(ci, head + Vector2(h * 0.1, h * 0.2), hand, c, h * 0.06, s + 3, 0.5, 1)
		if sign_text != "":
			var r := Rect2(hand + Vector2(-h * 0.28, -h * 0.34), Vector2(h * 0.56, h * 0.3))
			line(ci, hand, hand + Vector2(0, -h * 0.05), UMBER, 2.0, s + 4, 0.3, 1)
			ci.draw_rect(r, CHALK.darkened(0.1 + 0.1 * rnd(s, 5)))
			outline(ci, rect_poly(r), CHARCOAL, 1.2, s + 6, 0.5)
			letters(ci, sign_text, r.position + Vector2(h * 0.04, r.size.y * 0.78), int(h * 0.2), CHARCOAL, s + 7, 1, 0.85)


## A riot officer from the front: helmet, visor glint, a round shield, boots.
static func riot_officer(ci, foot: Vector2, h: float, s := 0, lit := 0.0) -> void:
	var head := foot - Vector2(0, h * 0.86)
	var body := PackedVector2Array([foot + Vector2(-h * 0.19, 0), foot + Vector2(h * 0.19, 0), head + Vector2(h * 0.17, h * 0.15), head + Vector2(-h * 0.17, h * 0.15)])
	var c := NAVY.lerp(ORANGE, lit * 0.35)
	ci.draw_colored_polygon(body, c)
	hatch(ci, body, CHARCOAL, 2.2, -0.9, s, 1.5)
	ci.draw_circle(head, h * 0.12, CHARCOAL)
	line(ci, head + Vector2(-h * 0.08, h * 0.01), head + Vector2(h * 0.08, h * 0.01), SLATE_LIGHT, 2.0, s + 2, 0.3, 1)
	var sc := foot + Vector2(h * 0.08, -h * 0.42)
	var shield := ellipse_poly(sc, h * 0.2, h * 0.26, 14, s + 3, 0.05)
	ci.draw_colored_polygon(shield, SLATE.lerp(ORANGE, lit * 0.3))
	hatch(ci, shield, SLATE_LIGHT, 2.6, 0.9, s + 4, 1.4)
	outline(ci, shield, CHARCOAL, 1.8, s + 5, 0.6)
	for side: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(foot + Vector2(side * h * 0.1 - h * 0.06, -h * 0.03), Vector2(h * 0.12, h * 0.05)), CHARCOAL)
