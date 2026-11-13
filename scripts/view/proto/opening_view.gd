extends Node2D
## The opening — Thomas Grendel's monologue (prototype, 2026-10-29).
##
## Thomas Grendel, 42, married. His daughter was killed in a pileup on Port Carrick's
## central bridge, and the whole game is drawn the way she drew. This is where the player
## first sees it: the page is a child's crayon drawing, louder and brighter than anything
## in the game (sky-blue strip, smiling sun, stick family, rainbow, castle), while the man
## talking over it is grieving, bitter and funny. Her drawings creep in from the edges of
## the frame while he talks; once, they take the page over until he scribbles them out.
##
## The monologue is printed in crayon capitals on a torn strip of ruled school paper. The
## camera travels along one long drawing, page by page. Everything is a pure function of
## t, so any frame can be rendered on its own (set auto_time = false and t). Presentation
## only: nothing here touches the simulation.

const C = preload("res://scripts/view/crayon.gd")

const W := 1600.0
const H := 900.0

# ------------------------------------------------------------------ the bright box
const PAPER := Color("#fbf7ec")
const INK := Color("#1e1b1c")
const SKY := Color("#33a6ff")
const SUN := Color("#ffd60a")
const SUN_EDGE := Color("#ff9500")
const GRASS := Color("#2fcf3f")
const GRASS_DARK := Color("#14a52c")
const HILL := Color("#86e35c")
const RED := Color("#ff2b30")
const ORANGE := Color("#ff7f11")
const PINK := Color("#ff4fa7")
const PURPLE := Color("#9b4dff")
const LILAC := Color("#c69cff")
const BROWN := Color("#a5592a")
const TAN := Color("#f2b866")
const SKIN := Color("#ffc39a")
const COAT := Color("#d9701f")
const NAVY := Color("#2747e6")
const GOLD := Color("#ffc400")
const WHITE := Color("#ffffff")
const GREY := Color("#9aa1ad")
const RIVER := Color("#16b7ff")
const NIGHT := Color("#251a7a")
const CYAN := Color("#12e3e0")
const TEAR := Color("#4fc3ff")
const ROAD := Color("#8a909b")
const BRICK := Color("#e0472b")

const CPS := 30.0          # captions print at this many characters a second
const TAKE_LEN := 6.4      # her drawing taking the page over, until he scribbles it out

## The monologue, as printed: [text, style, gap before (s), optional duration].
## *WORD* prints in red; {PIZZA} is a little slice drawn inline.
const LINES := [
	["HAVE YOU EVER SCREAMED *NO* SO LOUD", "strip", 3.0],
	["YOU THOUGHT MAYBE... JUST MAYBE... AGAINST ALL OF YOUR BELIEFS,", "strip", 0.35],
	["HARDER THAN WISDOM AND KNOWLEDGE OF THE WORLD, THAT SOMEONE MIGHT LISTEN?", "strip", 0.35],
	["THAT OUTSIDE OF EVERYTHING... EVERYTHING YOU KNOW TO BE REAL,", "strip", 0.9],
	["EVERYTHING THAT YOU CAN SEE, SMELL, LISTEN TO, AND AND FEEL MOVING RIGHT IN FRONT OF YOUR FACE,", "strip", 0.35],
	["SCREAMING MIGHT ACTUALLY CHANGE SOMETHING?", "strip", 0.35],
	["IT'S NOT AS CRAZY AS SOME PEOPLE THINK.", "strip", 1.0],
	["AT LEAST ONE PART OF YOU, STILL THERE.", "strip", 0.4],
	["THAT PART OF YOU THAT WAS THERE AT THE BEGINNING, BEFORE YOU KNEW SHIT ABOUT SHIT,", "strip", 0.4],
	["BEFORE YOU GREW THE FUCK UP AND STOPPED WISHING FOR FAIRYTALES.", "strip", 0.4],
	["BEFORE YOU REALIZE THERE WAS NOTHING SPECIAL ABOUT YOU.", "strip", 2.2],
	["AND YOUR BRIGHTEST HOPE FOR THE FUTURE INVOLVED A MORTGAGE WITH A STABLE INTEREST RATE", "strip", 0.5],
	["AND A REASONABLE PENSION WITH SOME SAVINGS TO BACK IT UP.", "strip", 0.4],
	["AND THEN YOU REALIZED THAT WAS JUST ANOTHER FAIRYTALE TOO.", "strip", 0.8],
	["....WHAT THE FUCK WAS I SAYING AGAIN?", "center", 1.2, 3.6],
	["RIGHT.", "strip", 0.9, 1.5],
	["MY NAME'S THOMAS. NICE TO MEET YOU.", "strip", 0.3, 3.4],
	["WELCOME TO PORT CARRICK, PENNSYLVANIA.", "strip", 1.6],
	["HOME OF THE P.C. PELICANS SINGLE A SOFTBALL TEAM.", "strip", 1.6],
	["BIRTHPLACE OF PORT-CARRICK STYLE PIZZA.", "strip", 1.6],
	["THAT'S RIGHT, *THE* PORT CARRICK STYLE. IT'S EXACTLY THE ONE YOU'RE THINKING OF.", "strip", 0.4],
	["(OFTEN CONFUSED WITH BUT COMPLETELY DIFFERENT FROM NEW YORK STYLE PIZZA.)", "strip", 0.4],
	["IT WAS A PRETTY BIG DEAL IN THE 80S.", "strip", 0.4],
	["...SOME PEOPLE BLAME NEW YORK FOR PCP{PIZZA} GOING OUT OF STYLE.", "strip", 0.5],
	["THIS IS THE SINGLE WORST TOWN IN AMERICA.", "strip", 2.2],
	["COME GRAB A SLICE.", "strip", 1.2, 2.8],
]

var t := 0.0
var auto_time := true
var vp := Vector2(W, H)
var paper: ImageTexture
var cards: Array = []      # [{text, style, t, dur}]
var pans: Array = []       # [[start, end, from_x, to_x]] (camera centre, world px)
var page_t0: Array = []    # when each page starts drawing itself
var intrusions: Array = [] # her drawings at the edges: [{kind, t, dur}]
var T_TAKE := 0.0
var T_CUT := 0.0
var T_TITLE := 0.0
var T_END := 0.0


func _init() -> void:
	_build()


func _ready() -> void:
	vp = get_viewport_rect().size
	paper = C.paper_texture(Vector2i(800, 450), PAPER, 29, 0.0)


func _process(delta: float) -> void:
	if auto_time:
		t += delta
	queue_redraw()


func duration() -> float:
	return T_END


## Times worth hanging sound on (the harness writes them out next to the frames).
func cues() -> Dictionary:
	var starts: Array = []
	for c: Dictionary in cards:
		starts.append(float(c["t"]))
	return {
		"takeover": T_TAKE, "scribble": T_TAKE + TAKE_LEN * 0.8, "cut": T_CUT,
		"town": float(page_t0[3]), "night": cs(24) - 1.4, "slice": cs(25),
		"title": T_TITLE, "end": T_END, "cards": starts,
	}


# ================================================================== timeline
func _build() -> void:
	cards.clear()
	var at := 0.0
	for i in LINES.size():
		var l: Array = LINES[i]
		var text := String(l[0])
		if i == 14:
			T_TAKE = at + 0.5
			T_CUT = T_TAKE + TAKE_LEN
			at = T_CUT
		at += float(l[2])
		var n := _plain(text).length()
		var dur := maxf(1.8, 0.9 + n / 15.0)
		if l.size() > 3:
			dur = float(l[3])
		cards.append({"text": text, "style": String(l[1]), "t": at, "dur": dur})
		at += dur
	T_TITLE = at + 0.4
	T_END = T_TITLE + 5.2
	pans = [
		[ce(9) + 0.2, cs(10) - 0.15, 800.0, 2400.0],
		[ce(16) + 0.15, cs(17) - 0.2, 4000.0, 5600.0],
		[ce(17) + 0.15, cs(18) - 0.2, 5600.0, 7200.0],
		[ce(18) + 0.15, cs(19) - 0.2, 7200.0, 8800.0],
		[ce(23) + 0.15, ce(23) + 1.35, 8800.0, 5600.0],
	]
	page_t0 = [0.0, ce(9) + 0.2, cs(15), ce(16) + 0.15, ce(17) + 0.15, ce(18) + 0.15]
	intrusions = [
		{"kind": "heart", "t": wt(2, "SOMEONE") - 0.6, "dur": 3.6},
		{"kind": "balloon", "t": cs(17) + 0.5, "dur": 3.8},
		{"kind": "girl_pizza", "t": cs(19) + 0.6, "dur": 3.4},
		{"kind": "girl_wave", "t": cs(25) + 0.1, "dur": 2.9},
	]


func _plain(text: String) -> String:
	return text.replace("*", "").replace("{PIZZA}", "#")


func cs(i: int) -> float:
	return float(cards[i]["t"])


func ce(i: int) -> float:
	return float(cards[i]["t"]) + float(cards[i]["dur"])


## When a word of card i is printed.
func wt(i: int, word: String) -> float:
	var p := _plain(String(cards[i]["text"])).find(word)
	return cs(i) + maxf(0.0, float(p)) / CPS


func rv(start: float, dur := 0.6) -> float:
	return clampf((t - start) / dur, 0.0, 1.0)


func _ease(x: float) -> float:
	var y := clampf(x, 0.0, 1.0)
	return y * y * (3.0 - 2.0 * y)


func _take_k() -> float:
	if t < T_TAKE or t >= T_CUT:
		return 0.0
	return (t - T_TAKE) / TAKE_LEN


func cam_x() -> float:
	var x := 800.0
	var p0: Array = pans[0]
	if t >= float(p0[0]):
		x = lerpf(float(p0[2]), float(p0[3]), _ease((t - float(p0[0])) / (float(p0[1]) - float(p0[0]))))
	if t >= T_CUT:
		x = 4000.0
	for k in range(1, pans.size()):
		var p: Array = pans[k]
		if t >= float(p[0]):
			x = lerpf(float(p[2]), float(p[3]), _ease((t - float(p[0])) / (float(p[1]) - float(p[0]))))
	return x


func zoom() -> float:
	var p0: Array = pans[0]
	var a := float(p0[0])
	var b := float(p0[1])
	var z := 1.0
	if t < a:
		z = 1.0 + 0.05 * _ease(t / a)
	elif t < b:
		z = lerpf(1.05, 1.0, _ease((t - a) / (b - a)))
	if t > cs(24):
		z = 1.0 + 0.045 * _ease((t - cs(24)) / (T_END - cs(24)))
	return z


# ================================================================== draw
func _draw() -> void:
	var k := _take_k()
	C.frame = int(t * 8.0 + (maxf(0.0, minf(t, T_CUT) - T_TAKE) * 16.0 if t > T_TAKE else 0.0))
	C.boil = 1.0 + 1.6 * k
	var rs := vp.x / W
	var cx := cam_x()
	var z := zoom()
	var half := W * 0.5 / z
	for pg in 6:
		var x0 := pg * W
		if x0 + W < cx - half - 2.0 or x0 > cx + half + 2.0:
			continue
		var off := (Vector2(x0, 0.0) - Vector2(cx, H * 0.5)) * z + Vector2(W, H) * 0.5
		draw_set_transform(off * rs, 0.0, Vector2(z, z) * rs)
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		match pg:
			0: _page_scream()
			1: _page_family()
			2: _page_thomas()
			3: _page_town()
			4: _page_pelicans()
			5: _page_pizza()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	_intrusions()
	_takeover(k)
	_captions()
	_title()
	C.boil = 1.0


# ================================================================== crayon helpers
func ca(col: Color, a: float) -> Color:
	var c := col
	c.a *= a
	return c


func circ(c: Vector2, r: float, s := 0, n := 20) -> PackedVector2Array:
	return C.ellipse_poly(c, r, r, n, s, 0.05)


func oval(c: Vector2, rx: float, ry: float, s := 0, n := 20, wob := 0.05) -> PackedVector2Array:
	return C.ellipse_poly(c, rx, ry, n, s, wob)


func arc(c: Vector2, rx: float, ry: float, a0: float, a1: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n + 1:
		var a := lerpf(a0, a1, float(k) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Wax crayon worked back and forth, a second lighter pass across it, paper showing.
func fill(poly: PackedVector2Array, col: Color, s: int, r := 1.0, sp := 4.4, ang := -0.55, w := 3.8) -> void:
	if r <= 0.0 or poly.size() < 3 or col.a <= 0.01:
		return
	C.hatch(self, poly, col, sp, ang, s, w, r)
	var c2 := col.darkened(0.15)
	c2.a *= 0.45
	C.hatch(self, poly, c2, sp * 2.3, ang + 0.45, s + 7, w * 0.75, r, 0.35)


func edge(poly: PackedVector2Array, col: Color = INK, w := 2.8, s := 0, r := 1.0, amp := 1.3) -> void:
	if r <= 0.0 or col.a <= 0.01:
		return
	C.outline(self, poly, col, w, s, amp, r)


func ln(a: Vector2, b: Vector2, col: Color, w: float, s: int, r := 1.0, amp := 1.4) -> void:
	if col.a <= 0.01:
		return
	C.line(self, a, b, col, w, s, amp, 2, r)


func path(pts: PackedVector2Array, col: Color, w: float, s: int, r := 1.0, amp := 1.2, passes := 1) -> void:
	var n := pts.size() - 1
	if n < 1 or r <= 0.0 or col.a <= 0.01:
		return
	for k in n:
		var rr := clampf(r * n - k, 0.0, 1.0)
		if rr <= 0.0:
			break
		C.line(self, pts[k], pts[k + 1], col, w, s + k * 7, amp, passes, rr)


## Pressed hard: a solid base under things that must read (faces, mittens, boots).
func solid(poly: PackedVector2Array, col: Color) -> void:
	if poly.size() >= 3 and col.a > 0.01:
		draw_colored_polygon(poly, col)


func txt(s_: String, pos: Vector2, size: int, col: Color, s: int, heavy := 2, r := 1.0) -> float:
	if r <= 0.0 or col.a <= 0.01:
		return 0.0
	return C.letters(self, s_, pos, size, col, s, heavy, 1.0, r)


func txt_c(s_: String, cx: float, base: float, size: int, col: Color, s: int, heavy := 2, r := 1.0) -> void:
	txt(s_, Vector2(cx - C.letters_width(s_, size) * 0.5, base), size, col, s, heavy, r)


func star(c: Vector2, r: float, col: Color, s: int, rr := 1.0, rot := -PI * 0.5) -> void:
	if rr <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 10:
		var rad := r if k % 2 == 0 else r * 0.45
		var a := rot + TAU * k / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad * (1.0 + 0.08 * (C.rnd(s, k) - 0.5)))
	solid(pts, ca(col, 0.55 * rr))
	fill(pts, col, s, rr, 3.0, -0.4, 3.0)
	edge(pts, ca(col.darkened(0.35), col.a), 2.0, s + 1, rr, 0.8)


func heart(c: Vector2, r: float, col: Color, s: int, rr := 1.0) -> void:
	if rr <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * r / 16.0)
	fill(pts, col, s, rr, 3.0, -0.5, 3.0)
	edge(pts, ca(col.darkened(0.25), col.a), 2.2, s + 1, rr, 0.8)


func sky_strip(y1: float, col: Color, s: int, r: float) -> void:
	var pts := PackedVector2Array([Vector2(-10, -10), Vector2(W + 10, -10)])
	var n := 16
	for k in n + 1:
		var x := lerpf(W + 10.0, -10.0, float(k) / n)
		pts.append(Vector2(x, y1 + sin(k * 1.7 + s) * 9.0 + (C.rnd(s, k) - 0.5) * 12.0))
	fill(pts, col, s, r, 4.4, -0.22, 4.4)


func grass_strip(y0: float, s: int, r: float) -> void:
	var pts := PackedVector2Array()
	var n := 16
	for k in n + 1:
		var x := lerpf(-10.0, W + 10.0, float(k) / n)
		pts.append(Vector2(x, y0 + sin(k * 1.3 + s) * 7.0 + (C.rnd(s, k) - 0.5) * 10.0))
	pts.append(Vector2(W + 10, H + 10))
	pts.append(Vector2(-10, H + 10))
	fill(pts, GRASS, s, r, 4.4, -0.95, 4.4)
	var nb := int(W / 30.0)
	var shown := int(nb * r)
	for k in shown:
		var x := 12.0 + k * 30.0 + C.rnd(s + 3, k) * 10.0
		var y := y0 + 4.0 + sin(k * 0.4) * 4.0
		ln(Vector2(x, y + 10), Vector2(x - 6, y - 10), GRASS_DARK, 2.4, s + 100 + k, 1.0, 0.6)
		ln(Vector2(x, y + 10), Vector2(x + 6, y - 12), GRASS_DARK, 2.4, s + 300 + k, 1.0, 0.6)


func sun(c: Vector2, r: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var disk := circ(c, r, s, 24)
	solid(disk, ca(SUN.lightened(0.3), a * rr * 0.6))
	fill(disk, ca(SUN, a), s, rr, 3.8, -0.5, 4.0)
	edge(disk, ca(SUN_EDGE, a), 3.4, s + 1, rr)
	for k in 12:
		var ang := TAU * k / 12.0 + 0.13
		var r2 := clampf(rr * 12.0 - k, 0.0, 1.0)
		if r2 <= 0.0:
			break
		var d := Vector2(cos(ang), sin(ang))
		ln(c + d * (r + 12.0), c + d * (r + 40.0 + 12.0 * C.rnd(s, k)), ca(SUN_EDGE, a), 4.4, s + 20 + k, r2)
	if rr >= 1.0:
		var ink := ca(INK, a)
		var j := Vector2(C.jit(s, 1), C.jit(s, 2)) * 1.2
		draw_circle(c + Vector2(-r * 0.32, -r * 0.16) + j, r * 0.085, ink)
		draw_circle(c + Vector2(r * 0.32, -r * 0.16) + j, r * 0.085, ink)
		path(arc(c + Vector2(0, r * 0.02), r * 0.48, r * 0.42, 0.35, PI - 0.35, 10), ink, 3.6, s + 40)
		for side: float in [-1.0, 1.0]:
			solid(circ(c + Vector2(side * r * 0.55, r * 0.18), r * 0.12, s + 41 + int(side), 10), ca(PINK, a * 0.45))


func moon(c: Vector2, r: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var disk := circ(c, r, s, 22)
	solid(disk, ca(Color("#fff6b0"), 0.85 * rr))
	fill(disk, Color("#fff27a"), s, rr, 3.8, 0.5, 3.6)
	edge(disk, SUN, 3.0, s + 1, rr)
	if rr >= 1.0:
		draw_circle(c + Vector2(-r * 0.3, -r * 0.15), r * 0.08, INK)
		draw_circle(c + Vector2(r * 0.3, -r * 0.15), r * 0.08, INK)
		path(arc(c + Vector2(0, r * 0.05), r * 0.42, r * 0.36, 0.4, PI - 0.4, 8), INK, 3.0, s + 3)
		for k in 3:
			solid(circ(c + Vector2(-r * 0.2 + k * r * 0.25, r * 0.5 - k * r * 0.6), r * 0.08, s + 5 + k, 8), ca(Color("#e8d860"), 0.8))


func cloud(c: Vector2, w: float, s: int, rr := 1.0, a := 1.0) -> void:
	if rr <= 0.0:
		return
	var bumps := [[-0.36, 0.04, 0.2], [-0.14, -0.12, 0.25], [0.13, -0.1, 0.23], [0.35, 0.04, 0.19], [0.0, 0.08, 0.27]]
	for b: Array in bumps:
		solid(circ(c + Vector2(float(b[0]), float(b[1])) * w, float(b[2]) * w, s + int(float(b[0]) * 100.0), 16), ca(WHITE, a * rr))
	var bl := ca(SKY.darkened(0.25), a)
	for i in bumps.size():
		var b2: Array = bumps[i]
		var cc := c + Vector2(float(b2[0]), float(b2[1])) * w
		var rad := float(b2[2]) * w
		path(arc(cc, rad, rad, PI * 1.08, PI * 1.92, 10), bl, 3.0, s + 40 + i * 13, rr)
	ln(c + Vector2(-0.52 * w, 0.2 * w), c + Vector2(0.5 * w, 0.2 * w), bl, 3.0, s + 90, rr)


func birds(c: Vector2, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	for k in 3:
		var p := c + Vector2(k * 70.0 + sin(t * 0.7 + k) * 10.0 + t * 6.0, (k % 2) * 30.0 + sin(t * 2.0 + k) * 5.0)
		var flap := 8.0 + sin(t * 6.0 + k * 2.0) * 5.0
		path(PackedVector2Array([p + Vector2(-16, -flap), p, p + Vector2(16, -flap)]), INK, 2.6, s + k * 5, rr)


func hills(y: float, col: Color, s: int, r: float, amp := 60.0) -> void:
	var pts := PackedVector2Array()
	var n := 24
	for k in n + 1:
		var x := lerpf(-10.0, W + 10.0, float(k) / n)
		pts.append(Vector2(x, y - absf(sin(k * 0.55 + s)) * amp - 10.0))
	pts.append(Vector2(W + 10, y + 40))
	pts.append(Vector2(-10, y + 40))
	fill(pts, col, s, r, 4.6, -0.3, 4.0)


func car(c: Vector2, w: float, col: Color, s: int, rot := 0.0, rr := 1.0, a := 1.0, police := false) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var T := func(v: Vector2) -> Vector2: return c + v.rotated(rot)
	var body := PackedVector2Array([T.call(Vector2(-0.5 * w, -0.06 * w)), T.call(Vector2(0.5 * w, -0.06 * w)), T.call(Vector2(0.5 * w, 0.18 * w)), T.call(Vector2(-0.5 * w, 0.18 * w))])
	var cab := PackedVector2Array([T.call(Vector2(-0.3 * w, -0.06 * w)), T.call(Vector2(-0.18 * w, -0.3 * w)), T.call(Vector2(0.2 * w, -0.3 * w)), T.call(Vector2(0.32 * w, -0.06 * w))])
	var win := PackedVector2Array([T.call(Vector2(-0.22 * w, -0.09 * w)), T.call(Vector2(-0.14 * w, -0.25 * w)), T.call(Vector2(0.16 * w, -0.25 * w)), T.call(Vector2(0.24 * w, -0.09 * w))])
	var bc := ca(WHITE if police else col, a)
	solid(body, ca(bc, 0.35))
	fill(body, ca(NAVY, a) if police else bc, s, rr, 3.4, -0.5, 3.4)
	fill(cab, bc if not police else ca(WHITE, a), s + 2, rr, 3.4, -0.5, 3.0)
	solid(win, ca(Color("#bfe8ff"), a * rr))
	edge(body, ca(INK, a), 2.4, s + 4, rr, 0.8)
	edge(cab, ca(INK, a), 2.2, s + 5, rr, 0.8)
	if rr >= 1.0:
		for side: float in [-1.0, 1.0]:
			var wc: Vector2 = T.call(Vector2(side * 0.3 * w, 0.19 * w))
			solid(circ(wc, 0.11 * w, s + 6 + int(side), 12), ca(INK, a))
			draw_circle(wc, 0.04 * w, ca(GREY, a))
		draw_circle(T.call(Vector2(0.47 * w, 0.02 * w)), 0.04 * w, ca(SUN, a))
		if police:
			var red_on := fmod(t * 2.0, 1.0) < 0.5
			draw_circle(T.call(Vector2(-0.06 * w, -0.34 * w)), 0.05 * w, ca(RED if red_on else RED.darkened(0.5), a))
			draw_circle(T.call(Vector2(0.08 * w, -0.34 * w)), 0.05 * w, ca(SKY.darkened(0.5) if red_on else SKY, a))


func house(x: float, base: float, w: float, h: float, wall: Color, roof: Color, s: int, rr := 1.0, boarded := false, lit := 0.0, a := 1.0) -> void:
	if rr <= 0.0:
		return
	var wl := C.rect_poly(Rect2(x, base - h, w, h))
	solid(wl, ca(wall.lightened(0.45), a * 0.6 * rr))
	fill(wl, ca(wall, a), s, rr, 4.0, -0.6, 3.8)
	edge(wl, ca(INK, a), 2.6, s + 1, rr)
	var roof_p := PackedVector2Array([Vector2(x - w * 0.12, base - h), Vector2(x + w * 0.5, base - h - w * 0.5), Vector2(x + w * 1.12, base - h)])
	fill(roof_p, ca(roof, a), s + 2, rr, 3.8, 0.5, 3.6)
	edge(roof_p, ca(INK, a), 2.6, s + 3, rr)
	if rr < 1.0:
		return
	var dw := w * 0.22
	var door := C.rect_poly(Rect2(x + w * 0.5 - dw * 0.5, base - h * 0.42, dw, h * 0.42))
	fill(door, ca(BROWN, a), s + 4, 1.0, 3.4, 1.1, 3.2)
	edge(door, ca(INK, a), 2.0, s + 5)
	draw_circle(Vector2(x + w * 0.5 + dw * 0.25, base - h * 0.2), 2.8, ca(GOLD, a))
	for side: float in [-1.0, 1.0]:
		var wc := Vector2(x + w * 0.5 + side * w * 0.3, base - h * 0.66)
		var ws := w * 0.14
		var wr := C.rect_poly(Rect2(wc - Vector2(ws, ws * 0.85), Vector2(ws * 2.0, ws * 1.7)))
		var glass := SUN if lit > 0.5 else Color("#bfe8ff")
		solid(wr, ca(glass, a))
		edge(wr, ca(INK, a), 2.0, s + 8 + int(side), 1.0, 0.8)
		if boarded:
			ln(wr[0], wr[2], ca(BROWN, a), 5.0, s + 10 + int(side), 1.0, 0.6)
			ln(wr[1], wr[3], ca(BROWN, a), 5.0, s + 12 + int(side), 1.0, 0.6)
		else:
			ln(Vector2(wc.x, wr[0].y), Vector2(wc.x, wr[2].y), ca(INK, a), 1.8, s + 14 + int(side), 1.0, 0.5)
			ln(Vector2(wr[0].x, wc.y), Vector2(wr[1].x, wc.y), ca(INK, a), 1.8, s + 16 + int(side), 1.0, 0.5)


## A bridge the way a child draws one: side-on, a deck, a big arch, the hangers, two piers.
func bridge(x0: float, x1: float, deck: float, ah: float, col: Color, s: int, rr := 1.0, a := 1.0, k := 1.0) -> void:
	if rr <= 0.0:
		return
	var c := ca(col, a)
	var ink := ca(INK, a)
	var ax0 := x0 + (x1 - x0) * 0.08
	var ax1 := x1 - (x1 - x0) * 0.08
	for px: float in [ax0, ax1]:
		var pier := C.rect_poly(Rect2(px - 14.0 * k, deck, 28.0 * k, 70.0 * k))
		fill(pier, ca(GREY, a), s + int(px), rr, 3.4, 1.0, 3.0)
		edge(pier, ink, 2.0, s + int(px) + 1, rr)
	var band := C.rect_poly(Rect2(x0, deck - 10.0 * k, x1 - x0, 18.0 * k))
	fill(band, c, s, rr, 3.4, -0.3, 3.4)
	edge(band, ink, 2.4, s + 2, rr)
	var pts := PackedVector2Array()
	var n := 24
	for j in n + 1:
		var f := float(j) / n
		pts.append(Vector2(lerpf(ax0, ax1, f), deck - 10.0 * k - ah * 4.0 * f * (1.0 - f)))
	path(pts, c, 8.0 * k, s + 3, rr, 1.0, 2)
	var rh := clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	if rh > 0.0:
		for j in range(2, n - 1, 2):
			ln(pts[j], Vector2(pts[j].x, deck - 10.0 * k), c, 2.6 * k, s + 40 + j, rh, 0.6)


# ================================================================== people
## Thomas, front-on, as a child draws a grown-up: a big round head, a tired face, the
## uniform or his own coat, whole arms ending in mittens, big boots.
##   arms: "down", "up", "wave", "wave_l", "offer", "podium"
##   mouth: "scream", "tired", "flat", "open", "grin", "frown"
##   nose: 0 = his own; above that it grows (he is lying). sweat: 0..1.
func thomas(foot: Vector2, h: float, s: int, rr: float, uniform: bool, mouth: String, arms: String, a := 1.0, nose := 0.0, sweat := 0.0) -> Dictionary:
	var out := {}
	if rr <= 0.0:
		return out
	var r := h * 0.165
	var hc := foot + Vector2(0, -h + r)
	var neck := hc + Vector2(0, r * 0.95)
	var hip := foot.y - h * 0.34
	var bw0 := h * 0.15
	var bw1 := h * 0.18
	var coat := ca(NAVY if uniform else COAT, a)
	var ink := ca(INK, a)
	var skin := ca(SKIN, a)
	var r1 := clampf(rr * 3.0, 0.0, 1.0)
	var r2 := clampf(rr * 3.0 - 1.0, 0.0, 1.0)
	var r3 := clampf(rr * 3.0 - 2.0, 0.0, 1.0)
	for side: float in [-1.0, 1.0]:
		var lx := foot.x + side * h * 0.075
		var leg := C.rect_poly(Rect2(lx - h * 0.048, hip, h * 0.096, foot.y - hip - h * 0.03))
		fill(leg, coat.darkened(0.3), s + 3 + int(side), r1, 4.0, 1.2, 3.4)
		edge(leg, ink, 2.4, s + 5 + int(side), r1)
		if r1 >= 1.0:
			solid(oval(Vector2(lx + side * h * 0.025, foot.y - h * 0.02), h * 0.075, h * 0.036, s + 7 + int(side), 12, 0.06), ink)
	var body := PackedVector2Array([neck + Vector2(-bw0, 0), neck + Vector2(bw0, 0), Vector2(foot.x + bw1, hip + h * 0.05), Vector2(foot.x - bw1, hip + h * 0.05)])
	solid(body, ca(coat.lightened(0.35), 0.5 * r1))
	fill(body, coat, s + 10, r1, 4.0, -0.6, 4.0)
	edge(body, ink, 3.0, s + 11, r1)
	if r1 >= 1.0:
		if uniform:
			star(neck + Vector2(bw0 * 0.55, h * 0.08), h * 0.034, ca(GOLD, a), s + 12)
			ln(Vector2(foot.x - bw1 * 0.96, hip - h * 0.005), Vector2(foot.x + bw1 * 0.96, hip - h * 0.005), ink, 6.0, s + 13)
			draw_circle(Vector2(foot.x, hip - h * 0.005), h * 0.016, ca(GOLD, a))
			for k in 3:
				draw_circle(Vector2(foot.x, neck.y + h * 0.06 + k * h * 0.075), h * 0.01, ca(GOLD, a))
		else:
			ln(neck + Vector2(-bw0 * 0.5, 0), neck + Vector2(0, h * 0.09), ink, 2.6, s + 14)
			ln(neck + Vector2(bw0 * 0.5, 0), neck + Vector2(0, h * 0.09), ink, 2.6, s + 15)
			for k in 3:
				draw_circle(Vector2(foot.x, neck.y + h * 0.13 + k * h * 0.06), h * 0.009, ink)
	var shL := neck + Vector2(-bw0 * 0.92, h * 0.03)
	var shR := neck + Vector2(bw0 * 0.92, h * 0.03)
	var hL := Vector2(foot.x - bw1 - h * 0.03, hip + h * 0.02)
	var hR := Vector2(foot.x + bw1 + h * 0.03, hip + h * 0.02)
	var eL := shL.lerp(hL, 0.5) + Vector2(-h * 0.03, 0)
	var eR := shR.lerp(hR, 0.5) + Vector2(h * 0.03, 0)
	match arms:
		"up":
			hL = Vector2(foot.x - h * 0.31, hc.y - r * 1.15) + Vector2(C.jit(s + 20, 1), C.jit(s + 20, 2)) * h * 0.012
			hR = Vector2(foot.x + h * 0.31, hc.y - r * 1.15) + Vector2(C.jit(s + 21, 1), C.jit(s + 21, 2)) * h * 0.012
			eL = shL + Vector2(-h * 0.14, -h * 0.06)
			eR = shR + Vector2(h * 0.14, -h * 0.06)
		"wave":
			hR = Vector2(foot.x + h * 0.3 + sin(t * 9.0) * h * 0.035, hc.y - r * 0.3)
			eR = shR + Vector2(h * 0.15, h * 0.03)
		"wave_l":
			hL = Vector2(foot.x - h * 0.3 + sin(t * 9.0) * h * 0.035, hc.y - r * 0.3)
			eL = shL + Vector2(-h * 0.15, h * 0.03)
		"offer":
			hR = Vector2(foot.x + h * 0.36, neck.y + h * 0.1)
			eR = shR + Vector2(h * 0.13, h * 0.12)
		"podium":
			hL = Vector2(foot.x - h * 0.25, foot.y - h * 0.47)
			hR = Vector2(foot.x + h * 0.25, foot.y - h * 0.47)
			eL = shL + Vector2(-h * 0.13, h * 0.13)
			eR = shR + Vector2(h * 0.13, h * 0.13)
	var arm_list := [[shL, eL, hL, 1], [shR, eR, hR, 2]]
	for arm: Array in arm_list:
		var p0: Vector2 = arm[0]
		var p1: Vector2 = arm[1]
		var p2: Vector2 = arm[2]
		var kk: int = arm[3]
		ln(p0, p1, coat, h * 0.056, s + 30 + kk, r3, 1.0)
		ln(p1, p2, coat, h * 0.05, s + 32 + kk, r3, 1.0)
		if r3 >= 1.0:
			var mit := circ(p2, h * 0.04, s + 34 + kk, 12)
			solid(mit, skin)
			edge(mit, ink, 2.0, s + 36 + kk, 1.0, 0.6)
	out["hand_r"] = hR
	out["head"] = hc
	out["r"] = r
	if r2 <= 0.0:
		return out
	for side: float in [-1.0, 1.0]:
		var ear := circ(hc + Vector2(side * r * 0.98, r * 0.05), r * 0.2, s + 41 + int(side), 10)
		solid(ear, skin)
		edge(ear, ink, 2.0, s + 43 + int(side), r2, 0.5)
	var head := circ(hc, r, s + 40, 24)
	solid(head, ca(SKIN.lightened(0.08), a * r2))
	fill(head, ca(SKIN.darkened(0.05), a), s + 44, r2, 4.6, 0.5, 2.8)
	edge(head, ink, 3.0, s + 45, r2)
	if r2 < 1.0:
		return out
	_face(hc, r, s + 50, mouth, a, nose)
	if sweat > 0.0:
		for k in 3:
			var side := -1.0 if k != 1 else 1.0
			var ph := fmod(t * 0.9 + k * 0.37, 1.0)
			var sp := hc + Vector2(side * r * (0.92 + 0.05 * k), -r * 0.5 + ph * r * 0.7)
			solid(oval(sp, r * 0.06, r * 0.09, s + 70 + k, 8), ca(TEAR, a * sweat * (1.0 - ph * 0.5)))
	if uniform:
		var crown := PackedVector2Array([hc + Vector2(-r * 1.02, -r * 0.42), hc + Vector2(-r * 0.88, -r * 1.06), hc + Vector2(r * 0.88, -r * 1.06), hc + Vector2(r * 1.02, -r * 0.42)])
		solid(crown, ca(NAVY.lightened(0.2), a * 0.6))
		fill(crown, ca(NAVY, a), s + 60, 1.0, 3.6, -0.4, 3.6)
		edge(crown, ink, 2.8, s + 61)
		ln(hc + Vector2(-r * 1.12, -r * 0.4), hc + Vector2(r * 1.12, -r * 0.4), ink, r * 0.14, s + 62, 1.0, 0.8)
		star(hc + Vector2(0, -r * 0.74), r * 0.17, ca(GOLD, a), s + 63)
	else:
		var hair := arc(hc, r * 1.04, r * 1.04, PI * 1.08, PI * 1.92, 12)
		var inner := arc(hc + Vector2(0, r * 0.12), r * 0.86, r * 0.8, PI * 1.92, PI * 1.08, 12)
		hair.append_array(inner)
		fill(hair, ca(BROWN, a), s + 64, 1.0, 3.4, 0.9, 3.4)
		edge(hair, ink, 2.0, s + 65, 1.0, 0.8)
	return out


func _face(hc: Vector2, r: float, s: int, mouth: String, a: float, nose_len := 0.0) -> void:
	var ink := ca(INK, a)
	if mouth == "scream":
		for side: float in [-1.0, 1.0]:
			var e := hc + Vector2(side * r * 0.36, -r * 0.14)
			ln(e + Vector2(-side * r * 0.14, -r * 0.1), e + Vector2(side * r * 0.08, 0), ink, 3.8, s + 3 + int(side), 1.0, 0.5)
			ln(e + Vector2(side * r * 0.08, 0), e + Vector2(-side * r * 0.14, r * 0.1), ink, 3.8, s + 5 + int(side), 1.0, 0.5)
		solid(oval(hc + Vector2(0, r * 0.44), r * 0.3, r * 0.36, s + 8, 16, 0.12), ink)
		solid(oval(hc + Vector2(0, r * 0.64), r * 0.15, r * 0.1, s + 9, 10), ca(RED, a))
		return
	var j := Vector2(C.jit(s, 1), C.jit(s, 2)) * r * 0.012
	for side: float in [-1.0, 1.0]:
		var e := hc + Vector2(side * r * 0.36, -r * 0.08) + j
		draw_circle(e, r * 0.075, ink)
		ln(e + Vector2(-r * 0.15, -r * 0.12), e + Vector2(r * 0.15, -r * 0.12), ink, 2.4, s + 11 + int(side), 1.0, 0.4)
		path(arc(e + Vector2(0, r * 0.07), r * 0.13, r * 0.07, 0.3, PI - 0.3, 6), ca(PURPLE, a * 0.6), 2.2, s + 13 + int(side))
		ln(e + Vector2(-side * r * 0.14, -r * 0.34), e + Vector2(side * r * 0.19, -r * 0.24), ink, 3.2, s + 15 + int(side), 1.0, 0.5)
	var nose := PackedVector2Array([hc + Vector2(r * 0.02, r * 0.0), hc + Vector2(r * 0.12, r * 0.2), hc + Vector2(-r * 0.05, r * 0.23)])
	path(nose, ink, 2.6, s + 20)
	match mouth:
		"flat":
			ln(hc + Vector2(-r * 0.2, r * 0.45), hc + Vector2(r * 0.2, r * 0.45), ink, 3.0, s + 22, 1.0, 0.6)
		"open":
			solid(oval(hc + Vector2(0, r * 0.44), r * 0.13, r * 0.1, s + 22, 10, 0.1), ink)
		"grin":
			var gp := arc(hc + Vector2(0, r * 0.3), r * 0.36, r * 0.24, 0.15, PI - 0.15, 10)
			solid(gp, ca(WHITE, a))
			edge(gp, ink, 2.6, s + 22, 1.0, 0.5)
			ln(hc + Vector2(-r * 0.3, r * 0.42), hc + Vector2(r * 0.3, r * 0.42), ink, 1.6, s + 23, 1.0, 0.3)
		"frown":
			path(arc(hc + Vector2(0, r * 0.56), r * 0.22, r * 0.12, PI + 0.3, TAU - 0.3, 8), ink, 3.0, s + 22)
		_:
			path(arc(hc + Vector2(0, r * 0.36), r * 0.22, r * 0.1, 0.25, PI - 0.25, 8), ink, 3.0, s + 22)
	if nose_len > 0.0:
		var base := hc + Vector2(r * 0.06, r * 0.12)
		var L := r * 2.4 * nose_len
		var np := PackedVector2Array([base + Vector2(0, -r * 0.11), base + Vector2(L, -r * 0.02), base + Vector2(L + r * 0.05, r * 0.03), base + Vector2(0, r * 0.11)])
		solid(np, ca(SKIN, a))
		fill(np, ca(SKIN.darkened(0.08), a), s + 24, 1.0, 3.0, 0.4, 2.4)
		edge(np, ink, 2.4, s + 25, 1.0, 0.6)
	var stub := ca(GREY.darkened(0.2), a * 0.8)
	for k in 12:
		var ang := 0.55 + k * 0.17
		var p := hc + Vector2(cos(ang), sin(ang)) * r * (0.62 + 0.12 * C.rnd(s + 30, k))
		draw_circle(p, 1.6, stub)


## A stick person the way she drew them: circle head, dot eyes, a big smile, a box or a
## triangle for clothes, stick arms out (to hold hands), stick legs, round shoes.
##   kind: "daddy", "mommy", "me", "boy", "old"
func stick(foot: Vector2, h: float, kind: String, s: int, rr := 1.0, a := 1.0, hand_l := Vector2.ZERO, hand_r := Vector2.ZERO, w := 3.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var ink := ca(INK, a)
	var r := h * 0.15
	var hc := foot + Vector2(0, -h + r)
	var neck := hc + Vector2(0, r)
	var waist := foot + Vector2(0, -h * 0.36)
	var r1 := clampf(rr * 3.0, 0.0, 1.0)
	var r2 := clampf(rr * 3.0 - 1.0, 0.0, 1.0)
	var r3 := clampf(rr * 3.0 - 2.0, 0.0, 1.0)
	var body_col := NAVY
	match kind:
		"mommy": body_col = PURPLE
		"me": body_col = PINK
		"boy": body_col = RED
		"old": body_col = Color("#7a8aa8")
	for side: float in [-1.0, 1.0]:
		ln(waist + Vector2(side * h * 0.06, 0), foot + Vector2(side * h * 0.09, -h * 0.03), ink, w, s + 2 + int(side), r1)
		if r1 >= 1.0:
			solid(oval(foot + Vector2(side * h * 0.11, -h * 0.025), h * 0.055, h * 0.03, s + 4 + int(side), 10), ink)
	var body: PackedVector2Array
	if kind == "mommy" or kind == "me":
		body = PackedVector2Array([neck + Vector2(-h * 0.06, 0), neck + Vector2(h * 0.06, 0), waist + Vector2(h * 0.21, h * 0.05), waist + Vector2(-h * 0.21, h * 0.05)])
	else:
		body = PackedVector2Array([neck + Vector2(-h * 0.13, 0), neck + Vector2(h * 0.13, 0), waist + Vector2(h * 0.13, 0), waist + Vector2(-h * 0.13, 0)])
	solid(body, ca(body_col.lightened(0.4), a * 0.5 * r1))
	fill(body, ca(body_col, a), s + 6, r1, 3.6, -0.6, 3.4)
	edge(body, ink, 2.4, s + 7, r1)
	var sh := neck + Vector2(0, h * 0.07)
	var hl := hand_l if hand_l != Vector2.ZERO else sh + Vector2(-h * 0.3, h * 0.1)
	var hr := hand_r if hand_r != Vector2.ZERO else sh + Vector2(h * 0.3, h * 0.1)
	ln(sh, hl, ink, w, s + 20, r3)
	ln(sh, hr, ink, w, s + 21, r3)
	if r3 >= 1.0:
		draw_circle(hl, h * 0.03, ca(SKIN.darkened(0.1), a))
		draw_circle(hr, h * 0.03, ca(SKIN.darkened(0.1), a))
	if kind == "mommy" and r2 > 0.0:
		for side2: float in [-1.0, 1.0]:
			for k in 4:
				var x := side2 * (r * 0.75 + k * r * 0.12)
				ln(hc + Vector2(x * 0.8, -r * 0.7), hc + Vector2(x * 1.05, r * 1.6), ca(BROWN, a), 3.2, s + 80 + k + int(side2) * 10, r2, 0.8)
	var head := circ(hc, r, s + 9, 18)
	solid(head, ca(SKIN.lightened(0.05), a * r2))
	fill(head, ca(SKIN.darkened(0.05), a), s + 9, r2, 4.0, 0.4, 2.6)
	edge(head, ink, 2.4, s + 10, r2)
	if r2 < 1.0:
		return
	draw_circle(hc + Vector2(-r * 0.35, -r * 0.08), r * 0.1, ink)
	draw_circle(hc + Vector2(r * 0.35, -r * 0.08), r * 0.1, ink)
	path(arc(hc + Vector2(0, r * 0.12), r * 0.5, r * 0.42, 0.3, PI - 0.3, 8), ca(RED, a), 2.8, s + 12)
	for side3: float in [-1.0, 1.0]:
		solid(circ(hc + Vector2(side3 * r * 0.62, r * 0.25), r * 0.14, s + 13 + int(side3), 8), ca(PINK, a * 0.4))
	match kind:
		"daddy":
			var crown := PackedVector2Array([hc + Vector2(-r * 1.0, -r * 0.45), hc + Vector2(-r * 0.85, -r * 1.05), hc + Vector2(r * 0.85, -r * 1.05), hc + Vector2(r * 1.0, -r * 0.45)])
			fill(crown, ca(NAVY, a), s + 30, 1.0, 3.2, -0.4, 3.2)
			edge(crown, ink, 2.2, s + 31)
			ln(hc + Vector2(-r * 1.1, -r * 0.42), hc + Vector2(r * 1.1, -r * 0.42), ink, r * 0.16, s + 32, 1.0, 0.6)
			star(hc + Vector2(0, -r * 0.75), r * 0.18, ca(GOLD, a), s + 33)
		"mommy":
			var top := arc(hc, r * 1.05, r * 1.05, PI * 1.05, PI * 1.95, 10)
			path(top, ca(BROWN, a), 7.0, s + 34)
		"me":
			for side4: float in [-1.0, 1.0]:
				var pg := hc + Vector2(side4 * r * 1.3, -r * 0.3)
				solid(circ(pg, r * 0.36, s + 35 + int(side4), 10), ca(GOLD, a))
				edge(circ(pg, r * 0.36, s + 37 + int(side4), 10), ink, 1.8, s + 38 + int(side4), 1.0, 0.6)
				heart(pg + Vector2(-side4 * r * 0.25, -r * 0.35), r * 0.22, ca(PINK, a), s + 40 + int(side4))
			path(arc(hc, r * 1.04, r * 1.04, PI * 1.1, PI * 1.9, 10), ca(GOLD.darkened(0.1), a), 6.0, s + 42)
		"boy":
			path(arc(hc, r * 1.05, r * 1.05, PI * 1.05, PI * 1.95, 10), ca(BROWN, a), 9.0, s + 43)
		"old":
			for k2 in 5:
				var ang := PI * 1.1 + k2 * 0.2
				ln(hc + Vector2(cos(ang), sin(ang)) * r, hc + Vector2(cos(ang), sin(ang)) * r * 1.35, ca(GREY, a), 3.0, s + 44 + k2, 1.0, 0.5)


# ================================================================== her things
func castle(x: float, base: float, w: float, s: int, rr := 1.0, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var h := w * 0.6
	var wall := ca(Color("#ffa6d3"), a)
	var roof := ca(PURPLE, a)
	var ink := ca(INK, a)
	var keep := C.rect_poly(Rect2(x + w * 0.2, base - h, w * 0.6, h))
	fill(keep, wall, s, rr, 4.0, -0.5, 3.6)
	edge(keep, ink, 2.4, s + 1, rr)
	for k in 4:
		var b := C.rect_poly(Rect2(x + w * 0.22 + k * w * 0.16, base - h - w * 0.07, w * 0.09, w * 0.07))
		fill(b, wall, s + 10 + k, rr, 3.2, -0.5, 3.0)
		edge(b, ink, 1.8, s + 20 + k, rr, 0.6)
	for side: float in [0.0, 1.0]:
		var tx := x + side * w * 0.76
		var tw := C.rect_poly(Rect2(tx, base - h * 1.35, w * 0.24, h * 1.35))
		fill(tw, wall, s + 30 + int(side), rr, 4.0, -0.5, 3.6)
		edge(tw, ink, 2.4, s + 32 + int(side), rr)
		var rf := PackedVector2Array([Vector2(tx - w * 0.04, base - h * 1.35), Vector2(tx + w * 0.12, base - h * 1.35 - w * 0.3), Vector2(tx + w * 0.28, base - h * 1.35)])
		fill(rf, roof, s + 34 + int(side), rr, 3.4, 0.6, 3.4)
		edge(rf, ink, 2.2, s + 36 + int(side), rr)
		if rr >= 1.0:
			var tip := Vector2(tx + w * 0.12, base - h * 1.35 - w * 0.3)
			ln(tip, tip + Vector2(0, -w * 0.12), ink, 2.2, s + 38 + int(side))
			var fl := PackedVector2Array([tip + Vector2(0, -w * 0.12), tip + Vector2(w * 0.1, -w * 0.09), tip + Vector2(0, -w * 0.06)])
			solid(fl, ca(SUN, a))
			solid(oval(Vector2(tx + w * 0.12, base - h * 0.9), w * 0.04, w * 0.06, s + 40 + int(side), 10), ca(PURPLE, a))
	if rr >= 1.0:
		var door := arc(Vector2(x + w * 0.5, base - h * 0.32), w * 0.1, w * 0.12, PI, TAU, 8)
		door.append(Vector2(x + w * 0.6, base))
		door.append(Vector2(x + w * 0.4, base))
		solid(door, ca(BROWN, a))
		edge(door, ink, 2.0, s + 44)
		heart(Vector2(x + w * 0.5, base - h * 0.7), w * 0.06, ca(RED, a), s + 46)


func rainbow(c: Vector2, r: float, band: float, s: int, rr := 1.0, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var cols: Array[Color] = [RED, ORANGE, SUN, GRASS, SKY, PURPLE]
	for k in cols.size():
		var rad := r - k * band
		path(arc(c, rad, rad * 0.95, PI, TAU, 26), ca(cols[k], a * 0.9), band * 1.1, s + k * 30, rr, 1.0, 1)


func unicorn(c: Vector2, sz: float, s: int, rr := 1.0, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var ink := ca(INK, a)
	var coat := ca(Color("#f6eeff"), a)
	var r1 := clampf(rr * 2.0, 0.0, 1.0)
	var r2 := clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	for k in 4:
		var lx := c.x - sz * 0.32 + k * sz * 0.21
		ln(Vector2(lx, c.y + sz * 0.16), Vector2(lx + (k % 2) * 6.0 - 3.0, c.y + sz * 0.55), ink, 4.0, s + k, r1)
		if r1 >= 1.0:
			solid(oval(Vector2(lx, c.y + sz * 0.56), sz * 0.04, sz * 0.025, s + 10 + k, 8), ca(PURPLE, a))
	var body := oval(c, sz * 0.48, sz * 0.24, s + 20, 20, 0.06)
	solid(body, coat)
	fill(body, ca(LILAC.lightened(0.5), a), s + 21, r1, 5.0, -0.4, 3.0)
	edge(body, ink, 2.6, s + 22, r1)
	var neck := PackedVector2Array([c + Vector2(-sz * 0.3, -sz * 0.12), c + Vector2(-sz * 0.5, -sz * 0.48), c + Vector2(-sz * 0.34, -sz * 0.54), c + Vector2(-sz * 0.14, -sz * 0.18)])
	solid(neck, coat)
	edge(neck, ink, 2.4, s + 23, r1)
	var hd := oval(c + Vector2(-sz * 0.56, -sz * 0.52), sz * 0.19, sz * 0.12, s + 24, 16, 0.05)
	solid(hd, coat)
	edge(hd, ink, 2.6, s + 25, r2)
	if r2 > 0.0:
		var horn := PackedVector2Array([c + Vector2(-sz * 0.58, -sz * 0.63), c + Vector2(-sz * 0.5, -sz * 0.62), c + Vector2(-sz * 0.6, -sz * 0.92)])
		solid(horn, ca(GOLD, a))
		edge(horn, ink, 2.0, s + 26, r2, 0.6)
		var mane := PackedVector2Array()
		for k2 in 9:
			var f := float(k2) / 8.0
			var p := (c + Vector2(-sz * 0.44, -sz * 0.6)).lerp(c + Vector2(-sz * 0.18, -sz * 0.16), f)
			mane.append(p + Vector2(sz * 0.06 * (1.0 if k2 % 2 == 0 else -0.2), 0))
		path(mane, ca(PINK, a), 9.0, s + 27, r2)
		var tail := arc(c + Vector2(sz * 0.56, -sz * 0.02), sz * 0.14, sz * 0.2, -PI * 0.6, PI * 0.8, 10)
		path(tail, ca(PURPLE, a), 9.0, s + 28, r2)
		path(arc(c + Vector2(sz * 0.6, sz * 0.04), sz * 0.1, sz * 0.16, -PI * 0.4, PI * 0.9, 8), ca(PINK, a), 7.0, s + 29, r2)
		if r2 >= 1.0:
			draw_circle(c + Vector2(-sz * 0.6, -sz * 0.55), sz * 0.025, ink)
			path(arc(c + Vector2(-sz * 0.66, -sz * 0.49), sz * 0.05, sz * 0.03, 0.2, PI - 0.6, 5), ink, 2.0, s + 30)


func balloon(c: Vector2, r: float, col: Color, string_end: Vector2, s: int, rr := 1.0, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var b := oval(c, r * 0.85, r, s, 18, 0.04)
	solid(b, ca(col.lightened(0.2), a * 0.6 * rr))
	fill(b, ca(col, a), s + 1, rr, 3.2, -0.6, 3.4)
	edge(b, ca(col.darkened(0.3), a), 2.4, s + 2, rr)
	if rr >= 1.0:
		path(arc(c + Vector2(-r * 0.3, -r * 0.3), r * 0.3, r * 0.4, PI * 1.05, PI * 1.45, 5), ca(WHITE, a), 4.0, s + 3)
		var knot := c + Vector2(0, r)
		var pts := PackedVector2Array()
		for k in 9:
			var f := float(k) / 8.0
			pts.append(knot.lerp(string_end, f) + Vector2(sin(f * 9.0 + t * 3.0) * 6.0, 0))
		path(pts, ca(INK, a), 1.8, s + 4)


func eye_icon(c: Vector2, sz: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var al := arc(c, sz, sz * 0.55, PI, TAU, 10)
	al.append_array(arc(c, sz, sz * 0.45, 0.0, PI, 10))
	solid(al, ca(WHITE, a))
	edge(al, ca(INK, a), 3.0, s, rr)
	if rr >= 1.0:
		solid(circ(c, sz * 0.36, s + 1, 14), ca(SKY, a))
		draw_circle(c, sz * 0.16, ca(INK, a))
		draw_circle(c + Vector2(-sz * 0.1, -sz * 0.1), sz * 0.06, ca(WHITE, a))
		for k in 5:
			var ang := PI * 1.15 + k * PI * 0.175
			var p := c + Vector2(cos(ang) * sz, sin(ang) * sz * 0.55)
			ln(p, p + Vector2(cos(ang), sin(ang)) * sz * 0.3, ca(INK, a), 2.6, s + 3 + k, 1.0, 0.5)


func nose_icon(c: Vector2, sz: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var n := PackedVector2Array([c + Vector2(-sz * 0.12, -sz * 0.8), c + Vector2(sz * 0.14, -sz * 0.8), c + Vector2(sz * 0.4, sz * 0.15), c + Vector2(sz * 0.5, sz * 0.45), c + Vector2(0, sz * 0.55), c + Vector2(-sz * 0.5, sz * 0.45), c + Vector2(-sz * 0.4, sz * 0.15)])
	solid(n, ca(SKIN, a))
	edge(n, ca(INK, a), 3.0, s, rr)
	if rr >= 1.0:
		solid(oval(c + Vector2(-sz * 0.2, sz * 0.36), sz * 0.1, sz * 0.06, s + 1, 8), ca(INK, a))
		solid(oval(c + Vector2(sz * 0.2, sz * 0.36), sz * 0.1, sz * 0.06, s + 2, 8), ca(INK, a))
		for k in 3:
			var pts := PackedVector2Array()
			for j in 7:
				pts.append(c + Vector2(sz * 0.7 + j * sz * 0.12, -sz * 0.4 + k * sz * 0.35 + sin(j * 1.4 + t * 4.0) * sz * 0.08))
			path(pts, ca(GRASS_DARK, a), 2.6, s + 10 + k)


func ear_icon(c: Vector2, sz: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var e := oval(c, sz * 0.45, sz * 0.7, s, 16, 0.06)
	solid(e, ca(SKIN, a))
	edge(e, ca(INK, a), 3.0, s + 1, rr)
	if rr >= 1.0:
		path(arc(c + Vector2(sz * 0.05, -sz * 0.05), sz * 0.22, sz * 0.38, PI * 0.6, PI * 1.9, 10), ca(INK, a), 2.6, s + 2)
		for k in 3:
			path(arc(c, sz * (0.8 + k * 0.25), sz * (0.8 + k * 0.25), -0.5, 0.5, 6), ca(PURPLE, a), 3.0, s + 3 + k)


func hand_icon(c: Vector2, sz: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var palm := oval(c + Vector2(0, sz * 0.2), sz * 0.42, sz * 0.4, s, 14, 0.05)
	for k in 4:
		var fx := c.x - sz * 0.3 + k * sz * 0.2
		ln(Vector2(fx, c.y + sz * 0.05), Vector2(fx + (k - 1.5) * sz * 0.05, c.y - sz * 0.6 + absf(k - 1.5) * sz * 0.12), ca(SKIN.darkened(0.08), a), sz * 0.17, s + 2 + k, rr, 0.6)
	ln(c + Vector2(-sz * 0.35, sz * 0.25), c + Vector2(-sz * 0.72, -sz * 0.05), ca(SKIN.darkened(0.08), a), sz * 0.17, s + 8, rr, 0.6)
	solid(palm, ca(SKIN, a))
	edge(palm, ca(INK, a), 2.6, s + 9, rr)


# ================================================================== page 0: the scream
func _page_scream() -> void:
	var t_no := wt(0, "NO")
	var fade := 1.0 - 0.65 * rv(wt(9, "FAIRYTALES"), 1.2)
	sky_strip(185.0, SKY, 11, rv(0.0, 0.9))
	sun(Vector2(1390, 128), 76.0, 12, rv(0.3, 0.9))
	cloud(Vector2(420, 96), 230.0, 13, rv(0.6, 0.5))
	cloud(Vector2(930, 70), 180.0, 14, rv(0.7, 0.5))
	birds(Vector2(640, 300), 15, rv(1.4, 0.4))
	# her rainbow comes in over the sky
	rainbow(Vector2(330, 610), 330.0, 20.0, 15, rv(cs(7) - 0.2, 1.2), fade)
	hills(540.0, HILL, 16, rv(0.4, 0.6), 50.0)
	# far off, small: the bridge
	bridge(110.0, 470.0, 528.0, 40.0, Color("#ff6f8a"), 17, rv(0.9, 0.8), 0.9, 0.45)
	var road := C.rect_poly(Rect2(-10, 548, W + 20, 82))
	fill(road, ROAD, 18, rv(0.6, 0.5), 4.0, -0.1, 4.0)
	if t > 1.1:
		for k in 14:
			ln(Vector2(30 + k * 120, 588), Vector2(90 + k * 120, 588), SUN, 5.0, 19 + k, 1.0, 0.6)
	# the traffic, which does not stop
	if t > cs(3) - 0.5:
		var cols: Array[Color] = [RED, SUN, SKY, PURPLE, ORANGE, GRASS_DARK, PINK]
		for k in 7:
			var dir := 1.0 if k % 2 == 0 else -1.0
			var lane := 574.0 if dir > 0.0 else 604.0
			var x := fposmod(k * 330.0 + dir * (t - cs(3)) * 290.0, 2200.0) - 300.0
			car(Vector2(x, lane), 118.0, cols[k], 40 + k * 17, 0.0, 1.0)
			for m in 3:
				var sx := x - dir * (78.0 + m * 18.0)
				ln(Vector2(sx, lane - 14 + m * 12), Vector2(sx - dir * 26.0, lane - 14 + m * 12), GREY, 2.4, 60 + k * 5 + m, 1.0, 0.5)
	grass_strip(632.0, 20, rv(0.2, 0.8))
	# her castle and unicorn creep in from the edges
	var ec := _ease(rv(cs(6) + 0.2, 1.4))
	castle(30.0 - (1.0 - ec) * 260.0, 664.0, 280.0, 21, ec, fade)
	var eu := _ease(rv(cs(7) + 0.6, 1.3))
	unicorn(Vector2(1395.0 + (1.0 - eu) * 300.0, 470.0), 230.0, 22, eu, fade)
	for k in 6:
		var sp: Array = [[90.0, 250.0], [240.0, 210.0], [1250.0, 250.0], [1520.0, 300.0], [700.0, 245.0], [1080.0, 215.0]][k]
		star(Vector2(float(sp[0]), float(sp[1])), 18.0 + 6.0 * C.rnd(23, k), ca(SUN, fade), 24 + k * 3, rv(cs(8) + k * 0.15, 0.3))
	# what you can see, smell, listen to, and feel
	var sense_a := 1.0 - rv(cs(6) + 0.3, 0.8)
	eye_icon(Vector2(500, 300), 62.0, 30, rv(wt(4, "SEE") - 0.1, 0.4), sense_a)
	nose_icon(Vector2(1110, 300), 60.0, 31, rv(wt(4, "SMELL") - 0.1, 0.4), sense_a)
	ear_icon(Vector2(470, 470), 70.0, 32, rv(wt(4, "LISTEN") - 0.1, 0.4), sense_a)
	hand_icon(Vector2(1130, 470), 74.0, 33, rv(wt(4, "FEEL") - 0.1, 0.4), sense_a)
	# Thomas, in his own coat, screaming
	var screaming := t >= t_no - 0.05
	var th := thomas(Vector2(800, 706), 470.0, 40, rv(1.0, 1.6), false, "scream" if screaming else "flat", "up" if screaming else "down")
	if screaming and not th.is_empty() and t < ce(5) + 0.8:
		var hc: Vector2 = th["head"]
		var r: float = th["r"]
		_tears(hc, r, 41)
		for k2 in 6:
			var side := -1.0 if k2 < 3 else 1.0
			var ang := -PI * 0.5 + side * (0.35 + (k2 % 3) * 0.32)
			var d := Vector2(cos(ang), sin(ang))
			ln(hc + d * r * 1.3, hc + d * r * (1.8 + 0.15 * C.jit(42, k2)), RED, 4.0, 43 + k2, 1.0, 0.8)
	# the part of you that was there at the beginning: a boy with a red balloon
	var boy_r := rv(wt(8, "BEGINNING") - 0.3, 0.9)
	if boy_r > 0.0:
		var scr := rv(wt(9, "GREW"), 0.9)
		var boy_a := 1.0 - 0.75 * scr
		var bfoot := Vector2(1030, 706)
		var bh := 210.0
		var hand := bfoot + Vector2(bh * 0.24, -bh * 0.72)
		stick(bfoot, bh, "boy", 50, boy_r, boy_a, Vector2.ZERO, hand)
		var lift := maxf(0.0, t - wt(9, "FUCK") - 0.2)
		var bc := Vector2(1080, 430) + Vector2(lift * 60.0, -lift * 240.0)
		var send := hand if lift <= 0.0 else bc + Vector2(-10, 150)
		balloon(bc, 46.0, RED, send, 51, boy_r)
		if scr > 0.0:
			var pts := PackedVector2Array()
			var n := 40
			var cen := bfoot + Vector2(0, -bh * 0.5)
			for j in int(n * scr) + 1:
				var ang := j * 2.3 + C.rnd(52, j) * 1.2
				var rad := bh * (0.25 + 0.3 * C.rnd(53, j))
				pts.append(cen + Vector2(cos(ang) * rad * 0.7, sin(ang) * rad) + Vector2(C.jit(54, j), C.jit(55, j)) * 5.0)
			if pts.size() >= 2:
				draw_polyline(pts, ca(GREY.darkened(0.45), 0.9), 6.0, true)
	# NO
	var g := rv(t_no, 0.45)
	if g > 0.0:
		var droop := rv(ce(5) - 0.2, 1.2)
		var shake := 4.0 + 12.0 * rv(cs(5), 1.0)
		var sz := int(lerpf(40.0, 170.0, _ease(g)))
		var off := Vector2(C.jit(901, 1), C.jit(901, 2)) * shake * (1.0 - droop)
		var col := ca(RED, 1.0 - droop)
		txt_c("NO", 800.0 + off.x, 205.0 + off.y - droop * 30.0, sz, col, 902, 3, 1.0)
		var echoes: Array = [[cs(1) + 0.3, 430.0, 300.0], [cs(1) + 1.6, 1190.0, 270.0], [cs(2) + 0.6, 560.0, 190.0], [cs(2) + 1.8, 1060.0, 180.0]]
		for k3 in echoes.size():
			var e: Array = echoes[k3]
			var et := t - float(e[0])
			if et > 0.0 and et < 2.6:
				txt_c("NO", float(e[1]), float(e[2]) - et * 40.0, 64, ca(RED, 0.8 * (1.0 - et / 2.6)), 910 + k3, 2, minf(1.0, et * 3.0))


func _tears(hc: Vector2, r: float, s: int) -> void:
	for k in 6:
		var side := -1.0 if k % 2 == 0 else 1.0
		var ph := fmod(t * 1.3 + k * 0.33, 1.0)
		var p0 := hc + Vector2(side * r * 0.55, -r * 0.05)
		var p := p0 + Vector2(side * ph * r * 1.7, -r * 0.7 * ph + r * 2.0 * ph * ph)
		solid(oval(p, r * 0.07, r * 0.1, s + k, 8), ca(TEAR, 1.0 - ph * 0.6))


# ================================================================== page 1: the family
func _page_family() -> void:
	var t1 := float(page_t0[1])
	sky_strip(170.0, SKY, 101, rv(t1, 0.8))
	sun(Vector2(150, 110), 64.0, 102, rv(t1 + 0.3, 0.7))
	birds(Vector2(760, 230), 109, rv(t1 + 0.9, 0.4))
	grass_strip(612.0, 103, rv(t1 + 0.1, 0.8))
	var hr := rv(t1 + 0.4, 1.2)
	house(170.0, 612.0, 380.0, 250.0, RED, BROWN, 104, hr)
	if hr >= 1.0:
		var ch := C.rect_poly(Rect2(450, 236, 46, 90))
		fill(ch, BRICK, 105, 1.0, 3.4, 0.4, 3.2)
		edge(ch, INK, 2.2, 106)
		for k in 4:
			var ph := fmod(t * 0.35 + k * 0.25, 1.0)
			path(arc(Vector2(475 + ph * 60.0, 210 - ph * 120.0), 18 + ph * 16, 14 + ph * 10, 0.0, TAU * 0.85, 10), ca(PURPLE.lightened(0.15), 1.0 - ph * 0.8), 5.0, 107 + k)
		var walk := PackedVector2Array([Vector2(340, 612), Vector2(380, 612), Vector2(420, 700), Vector2(300, 700)])
		fill(walk, TAN, 108, 1.0, 3.6, 0.2, 3.4)
		for k2 in 5:
			var fx := 90.0 + k2 * 70.0 if k2 < 2 else 520.0 + (k2 - 2) * 40.0
			_flower(Vector2(fx, 660), 110 + k2, [PINK, SUN, PURPLE, RED, ORANGE][k2])
	# the family, holding hands
	var me_gone := rv(cs(13) + 0.7, 2.2)
	var j1 := Vector2(772, 470)
	var j2 := Vector2(918, 506)
	var rd := rv(cs(10), 0.9)
	var rm := rv(cs(10) + 0.5, 0.9)
	var rme := rv(cs(10) + 1.0, 0.9)
	stick(Vector2(690, 652), 300.0, "daddy", 120, rd, 1.0, Vector2.ZERO, j1, 3.4)
	stick(Vector2(850, 652), 280.0, "mommy", 130, rm, 1.0, j1, j2, 3.4)
	stick(Vector2(990, 652), 190.0, "me", 140, rme * (1.0 - me_gone), 1.0 - 0.95 * me_gone, j2, Vector2.ZERO, 3.0)
	var lab := PURPLE
	txt_c("DADDY", 690.0, 318.0, 34, lab, 150, 2, rv(cs(10) + 0.6, 0.6))
	txt_c("MOMMY", 850.0, 338.0, 34, lab, 151, 2, rv(cs(10) + 1.1, 0.6))
	var me_label := rv(cs(10) + 1.6, 0.4) * (1.0 - rv(cs(13) + 0.3, 0.8))
	txt_c("ME", 990.0, 430.0, 36, ca(PINK, 1.0 - rv(cs(13) + 0.3, 0.8)), 152, 2, me_label)
	heart(Vector2(1050, 412), 16.0, ca(RED, 1.0 - rv(cs(13) + 0.3, 0.8)), 153, rv(cs(10) + 1.9, 0.3))
	# the bank, with a flag for the interest rate
	var rb := rv(wt(11, "MORTGAGE") - 0.2, 1.0)
	if rb > 0.0:
		var bx := 1150.0
		var bw := 290.0
		var base := 430.0
		var ped := PackedVector2Array([Vector2(bx - 10, base - 160), Vector2(bx + bw * 0.5, base - 225), Vector2(bx + bw + 10, base - 160)])
		fill(ped, Color("#d7dbe3"), 160, rb, 3.6, 0.4, 3.4)
		edge(ped, INK, 2.4, 161, rb)
		var slab := C.rect_poly(Rect2(bx, base - 160, bw, 34))
		fill(slab, Color("#d7dbe3"), 162, rb, 3.6, -0.4, 3.4)
		edge(slab, INK, 2.4, 163, rb)
		for k3 in 4:
			var col_r := C.rect_poly(Rect2(bx + 20 + k3 * 72, base - 126, 30, 126))
			fill(col_r, Color("#e9ecf2"), 164 + k3, rb, 3.4, 1.4, 3.0)
			edge(col_r, INK, 2.0, 170 + k3, rb, 0.8)
		var step := C.rect_poly(Rect2(bx - 14, base, bw + 28, 22))
		fill(step, GREY, 175, rb, 3.4, -0.2, 3.2)
		edge(step, INK, 2.2, 176, rb)
		if rb >= 1.0:
			txt_c("BANK", bx + bw * 0.5, base - 134, 26, INK, 177, 2)
			var rf := rv(wt(11, "INTEREST") - 0.3, 0.6)
			var top := Vector2(bx + bw * 0.5, base - 225)
			ln(top, top + Vector2(0, -90), INK, 3.0, 178, rf)
			if rf >= 1.0:
				var fl := PackedVector2Array([top + Vector2(0, -90), top + Vector2(96, -78 + sin(t * 3.0) * 4.0), top + Vector2(96, -36 + sin(t * 3.0 + 0.5) * 4.0), top + Vector2(0, -44)])
				fill(fl, GRASS, 179, 1.0, 3.4, 0.6, 3.4)
				edge(fl, INK, 2.0, 180)
				txt("%", top + Vector2(18, -50), 34, RED, 181, 2)
				ln(top + Vector2(52, -64), top + Vector2(88, -64), WHITE, 4.0, 182, 1.0, 0.4)
	# the savings: a piggy bank, coins going in
	var rp := rv(wt(12, "SAVINGS") - 0.2, 0.8)
	if rp > 0.0:
		_piggy(Vector2(1190, 650), 56.0, 190, rp)
	# the pension: daddy, old, with a cane
	var ro := rv(wt(12, "PENSION") - 0.2, 0.9)
	if ro > 0.0:
		stick(Vector2(1420, 700), 210.0, "old", 200, ro, 1.0, Vector2.ZERO, Vector2(1490, 600), 3.0)
		if ro >= 1.0:
			ln(Vector2(1490, 596), Vector2(1496, 700), BROWN, 5.0, 201, 1.0, 0.5)
			path(arc(Vector2(1478, 596), 14, 12, PI, TAU, 6), BROWN, 5.0, 202)
		txt_c("OLD DADDY", 1420.0, 474.0, 28, PURPLE, 203, 2, rv(wt(12, "PENSION") + 0.5, 0.6))


func _flower(p: Vector2, s: int, col: Color) -> void:
	ln(p, p + Vector2(0, 40), GRASS_DARK, 3.0, s, 1.0, 0.5)
	for k in 5:
		var ang := TAU * k / 5.0
		solid(circ(p + Vector2(cos(ang), sin(ang)) * 10.0, 8.0, s + k, 8), col)
	draw_circle(p, 6.0, SUN)


func _piggy(c: Vector2, r: float, s: int, rr: float) -> void:
	var pk := Color("#ff9ccf")
	for k in 4:
		var lx := c.x - r * 0.6 + k * r * 0.38
		ln(Vector2(lx, c.y + r * 0.4), Vector2(lx, c.y + r * 0.85), pk.darkened(0.2), 9.0, s + k, rr, 0.5)
	var b := oval(c, r, r * 0.72, s + 5, 18, 0.05)
	solid(b, ca(pk.lightened(0.3), 0.7 * rr))
	fill(b, pk, s + 6, rr, 3.4, -0.5, 3.4)
	edge(b, INK, 2.4, s + 7, rr)
	if rr < 1.0:
		return
	var sn := oval(c + Vector2(r * 0.95, r * 0.05), r * 0.22, r * 0.26, s + 8, 12)
	solid(sn, pk.darkened(0.1))
	edge(sn, INK, 2.0, s + 9, 1.0, 0.5)
	draw_circle(c + Vector2(r * 0.9, 0), r * 0.05, INK)
	draw_circle(c + Vector2(r * 1.02, r * 0.1), r * 0.05, INK)
	draw_circle(c + Vector2(r * 0.5, -r * 0.25), r * 0.07, INK)
	var ear := PackedVector2Array([c + Vector2(r * 0.3, -r * 0.6), c + Vector2(r * 0.42, -r * 0.95), c + Vector2(r * 0.58, -r * 0.55)])
	solid(ear, pk.darkened(0.1))
	path(arc(c + Vector2(-r * 1.12, -r * 0.1), r * 0.14, r * 0.14, 0.0, TAU * 0.9, 8), pk.darkened(0.3), 3.0, s + 10)
	ln(c + Vector2(-r * 0.25, -r * 0.7), c + Vector2(r * 0.15, -r * 0.7), INK, 4.0, s + 11, 1.0, 0.4)
	for k2 in 3:
		var ph := fmod(t * 0.9 + k2 / 3.0, 1.0)
		var cp := c + Vector2(-r * 0.05, -r * 2.0 + ph * r * 1.3)
		solid(circ(cp, r * 0.17, s + 12 + k2, 10), ca(GOLD, 1.0 - ph * 0.4))
		edge(circ(cp, r * 0.17, s + 15 + k2, 10), ca(SUN_EDGE, 1.0 - ph * 0.4), 1.8, s + 18 + k2, 1.0, 0.4)


# ================================================================== page 2: Thomas
func _page_thomas() -> void:
	var t2 := cs(15)
	if t < t2:
		return
	sky_strip(150.0, SKY, 301, rv(t2, 0.6))
	sun(Vector2(1460, 100), 52.0, 302, rv(t2 + 0.2, 0.5))
	grass_strip(690.0, 303, rv(t2 + 0.1, 0.6))
	var waving := t >= wt(16, "NICE") - 0.4
	thomas(Vector2(640, 706), 590.0, 310, rv(t2 + 0.15, 1.3), true, "tired", "wave_l" if waving else "down")
	# the label, with an arrow, like she would have done
	var ra := rv(wt(16, "THOMAS") - 0.4, 0.5)
	if ra > 0.0:
		path(PackedVector2Array([Vector2(1000, 296), Vector2(880, 260), Vector2(762, 238)]), INK, 4.0, 320, ra)
		if ra >= 1.0:
			ln(Vector2(762, 238), Vector2(790, 224), INK, 4.0, 321)
			ln(Vector2(762, 238), Vector2(786, 258), INK, 4.0, 322)
	txt("THOMAS GRENDEL", Vector2(1010, 312), 54, INK, 323, 3, rv(wt(16, "THOMAS"), 1.0))
	txt("AGE 42", Vector2(1014, 370), 30, GREY.darkened(0.35), 324, 2, rv(wt(16, "THOMAS") + 1.0, 0.5))
	# and in pink, smaller: hers. He strikes it out.
	var td := wt(16, "NICE") + 0.1
	var da := 1.0 - rv(td + 1.7, 0.7)
	txt("DADDY", Vector2(1040, 458), 40, ca(PINK, da), 325, 2, rv(td, 0.5))
	heart(Vector2(1250, 440), 18.0, ca(PINK, da), 326, rv(td + 0.4, 0.3))
	ln(Vector2(1024, 440), Vector2(1280, 432), ca(GREY.darkened(0.4), da), 6.0, 327, rv(td + 1.0, 0.3), 0.8)


# ================================================================== page 3: Port Carrick
func _page_town() -> void:
	var t3 := float(page_t0[3])
	var nt := cs(24) - 1.4
	var night := rv(nt, 1.8)
	sky_strip(230.0, SKY, 401, rv(t3, 0.7))
	if night > 0.0:
		var ns := PackedVector2Array([Vector2(-10, -10), Vector2(W + 10, -10), Vector2(W + 10, 470), Vector2(-10, 470)])
		fill(ns, NIGHT, 402, night, 4.0, -0.3, 4.6)
	sun(Vector2(180, 120), 70.0, 403, rv(t3 + 0.2, 0.6), 1.0 - rv(nt, 0.6))
	moon(Vector2(1400, 110), 58.0, 404, rv(nt + 1.0, 0.8))
	if night >= 1.0:
		for k in 18:
			var sp := Vector2(40.0 + C.rnd(405, k) * 1520.0, 30.0 + C.rnd(406, k) * 230.0)
			if sp.distance_to(Vector2(1400, 110)) < 100.0 or (sp.x > 430 and sp.x < 1350 and sp.y < 300 and t > T_TITLE):
				continue
			star(sp, 9.0 + 5.0 * C.rnd(407, k), SUN, 408 + k * 3)
	hills(470.0, HILL, 409, rv(t3 + 0.3, 0.5), 70.0)
	var lit := 1.0 if night > 0.7 else 0.0
	# the houses, the church, the mill
	var hs: Array = [[50.0, 104.0, 120.0, RED, BROWN, false], [180.0, 92.0, 98.0, SUN, PURPLE, true], [292.0, 112.0, 132.0, SKY, RED, false], [420.0, 94.0, 104.0, PINK, NAVY, true], [690.0, 108.0, 118.0, GRASS, BROWN, true], [815.0, 96.0, 100.0, ORANGE, PURPLE, false]]
	for i in hs.size():
		var hd: Array = hs[i]
		house(float(hd[0]), 476.0, float(hd[1]), float(hd[2]), hd[3], hd[4], 410 + i * 20, rv(t3 + 0.4 + i * 0.08, 0.5), hd[5], lit)
	var rc := rv(t3 + 0.6, 0.6)
	var church := C.rect_poly(Rect2(548, 330, 110, 146))
	fill(church, LILAC, 540, rc, 4.0, -0.5, 3.6)
	edge(church, INK, 2.4, 541, rc)
	var steeple := PackedVector2Array([Vector2(560, 330), Vector2(603, 210), Vector2(646, 330)])
	fill(steeple, PURPLE, 542, rc, 3.6, 0.5, 3.4)
	edge(steeple, INK, 2.4, 543, rc)
	if rc >= 1.0:
		ln(Vector2(603, 210), Vector2(603, 168), GOLD, 5.0, 544)
		ln(Vector2(588, 184), Vector2(618, 184), GOLD, 5.0, 545)
		solid(circ(Vector2(603, 372), 18.0, 546, 12), SUN if lit > 0.0 else Color("#bfe8ff"))
		edge(circ(Vector2(603, 372), 18.0, 547, 12), INK, 2.0, 548, 1.0, 0.5)
	var rf := rv(t3 + 0.6, 0.7)
	for k2 in 3:
		var cx := 1000.0 + k2 * 110.0
		var chm := C.rect_poly(Rect2(cx, 150, 40, 200))
		fill(chm, BRICK, 560 + k2, rf, 3.4, 0.3, 3.4)
		edge(chm, INK, 2.2, 563 + k2, rf)
		if rf >= 1.0:
			for b in 2:
				ln(Vector2(cx, 175 + b * 26), Vector2(cx + 40, 175 + b * 26), WHITE, 6.0, 566 + k2 * 2 + b, 1.0, 0.5)
			var smoke: Array[Color] = [GREY, LILAC, Color("#ff9ccf")]
			for m in 5:
				var ph := fmod(t * 0.22 + m / 5.0 + k2 * 0.13, 1.0)
				var sc := Vector2(cx + 20 + ph * 150.0, 140 - ph * 120.0)
				var sr := 16.0 + ph * 34.0
				var puff := circ(sc, sr, 570 + k2 * 10 + m, 12)
				solid(puff, ca(smoke[(m + k2) % 3].lightened(0.2), 0.75 * (1.0 - ph)))
				edge(puff, ca(smoke[(m + k2) % 3].darkened(0.2), 0.8 * (1.0 - ph)), 2.4, 600 + k2 * 10 + m, 1.0, 0.8)
	var mill := C.rect_poly(Rect2(940, 340, 440, 136))
	fill(mill, BRICK, 610, rf, 4.0, -0.5, 3.8)
	edge(mill, INK, 2.6, 611, rf)
	var saw := PackedVector2Array([Vector2(940, 340)])
	for k3 in 5:
		saw.append(Vector2(940 + k3 * 88 + 88, 290))
		saw.append(Vector2(940 + k3 * 88 + 88, 340))
	fill(saw, GREY, 612, rf, 3.4, 0.5, 3.4)
	edge(saw, INK, 2.2, 613, rf)
	if rf >= 1.0:
		for k4 in 5:
			var wr := C.rect_poly(Rect2(960 + k4 * 84, 420, 44, 36))
			solid(wr, SUN if lit > 0.0 and k4 == 3 else Color("#bfe8ff"))
			edge(wr, INK, 1.8, 614 + k4, 1.0, 0.5)
			ln(wr[0], wr[2], BROWN, 5.0, 620 + k4, 1.0, 0.5)
			ln(wr[1], wr[3], BROWN, 5.0, 626 + k4, 1.0, 0.5)
		var sign_r := C.rect_poly(Rect2(1080, 356, 180, 46))
		solid(sign_r, WHITE)
		edge(sign_r, INK, 2.2, 632)
		txt_c("CLOSED", 1170.0, 392.0, 28, RED, 633, 2)
	# the river and the central bridge
	var rr := rv(t3 + 0.5, 0.6)
	var river := C.rect_poly(Rect2(-10, 480, W + 20, 112))
	fill(river, RIVER, 640, rr, 4.0, -0.15, 4.4)
	if rr >= 1.0:
		for k5 in 12:
			var wx := 40.0 + k5 * 130.0 + fposmod(t * 20.0, 130.0)
			var wy := 510.0 + (k5 % 3) * 26.0
			path(PackedVector2Array([Vector2(wx, wy), Vector2(wx + 14, wy - 8), Vector2(wx + 28, wy), Vector2(wx + 42, wy - 8)]), WHITE, 3.0, 641 + k5)
	var rbr := rv(t3 + 0.8, 0.9)
	bridge(360.0, 1240.0, 500.0, 120.0, RED, 660, rbr)
	if rbr >= 1.0:
		var bc: Array[Color] = [SUN, PURPLE, GRASS, ORANGE]
		for k6 in 4:
			var x := 400.0 + fposmod(k6 * 230.0 + t * 55.0, 800.0)
			car(Vector2(x, 480), 56.0, bc[k6], 670 + k6 * 9)
	# the memorial at the foot of the bridge
	if night > 0.0:
		var rm := rv(nt + 1.6, 0.8)
		if rm > 0.0:
			for k7 in 3:
				_flower(Vector2(372 + k7 * 16, 462 - (k7 % 2) * 8), 680 + k7 * 7, [PINK, SUN, PURPLE][k7])
			_teddy(Vector2(422, 474), 16.0, 690, rm)
	grass_strip(596.0, 700, rv(t3 + 0.3, 0.6))
	var road := C.rect_poly(Rect2(-10, 620, W + 20, 66))
	fill(road, ROAD, 701, rv(t3 + 0.6, 0.5), 4.0, -0.1, 4.0)
	if t > t3 + 1.1:
		for k8 in 14:
			ln(Vector2(30 + k8 * 120, 653), Vector2(88 + k8 * 120, 653), SUN, 5.0, 702 + k8, 1.0, 0.5)
	# the welcome sign
	var rs := rv(t3 + 0.9, 0.6)
	if rs > 0.0:
		for px: float in [1090.0, 1450.0]:
			ln(Vector2(px, 690), Vector2(px, 740), BROWN, 10.0, 720 + int(px), rs, 0.5)
		var board := C.rect_poly(Rect2(1030, 548, 480, 142))
		solid(board, ca(WHITE, rs))
		edge(board, INK, 3.0, 722, rs)
		if rs >= 1.0:
			txt_c("WELCOME TO", 1270.0, 584.0, 24, NAVY, 723, 2, rv(cs(17), 0.5))
			txt_c("PORT CARRICK", 1270.0, 644.0, 48, RED, 724, 3, rv(wt(17, "PORT") - 0.1, 0.9))
			txt_c("PENNSYLVANIA", 1270.0, 678.0, 22, NAVY, 725, 2, rv(wt(17, "PENNSYLVANIA") - 0.1, 0.8))
	# night: the worst town in America, in her brightest crayons
	if night > 0.0:
		var rn := rv(nt + 0.6, 0.8)
		C.tape(self, Vector2(470, 624), Vector2(980, 624), 730, 9.0)
		_smear(Vector2(760, 652), 110.0, 731, rn)
		car(Vector2(760, 652), 150.0, WHITE, 732, 0.0, rn, 1.0, true)
		var rfi := rv(nt + 1.0, 0.8)
		car(Vector2(1330, 486), 96.0, GREY, 733, 0.18, rfi)
		_flames(Vector2(1330, 470), 58.0, 734, rfi)
		if night >= 1.0:
			for k9 in 150:
				var x2 := C.rnd(740 + C.frame * 31, k9) * W
				var y2 := C.rnd(741 + C.frame * 31, k9) * H
				var cc := ca(TEAR if k9 % 3 else CYAN, 0.75)
				draw_line(Vector2(x2, y2), Vector2(x2 - 8, y2 + 30), cc, 2.4, true)
	# Thomas, offering a slice
	var tf := rv(cs(25) - 1.0, 1.3)
	if tf > 0.0:
		var th := thomas(Vector2(300, 712), 470.0, 760, tf, true, "tired", "offer")
		if th.has("hand_r") and tf >= 1.0:
			var hnd: Vector2 = th["hand_r"]
			slice(hnd + Vector2(118, -86), hnd + Vector2(6, 0), 46.0, 770, 1.0)
			var mit := circ(hnd, 470.0 * 0.04, 771, 12)
			solid(mit, SKIN)
			edge(mit, INK, 2.0, 772, 1.0, 0.6)


func _smear(c: Vector2, r: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var red_on := fmod(t * 2.0, 1.0) < 0.5
	for side: float in [-1.0, 1.0]:
		var strong := (side < 0.0) == red_on
		var col := RED if side < 0.0 else SKY
		col.a = (0.85 if strong else 0.35) * rr
		C.hatch(self, oval(c + Vector2(side * r * 0.6, 0), r * (1.0 if strong else 0.7), r * 0.5, s + int(side), 14, 0.3), col, 3.2, side * 0.6, s + 40 + int(side), 3.4)


func _flames(c: Vector2, sz: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var cols: Array[Color] = [RED, ORANGE, SUN]
	for k in 3:
		var hgt := sz * (1.4 - k * 0.35) * rr
		var wid := sz * (0.8 - k * 0.2)
		var pts := PackedVector2Array()
		var n := 9
		for j in n + 1:
			var f := float(j) / n
			var x := c.x - wid + f * wid * 2.0
			var y := c.y - (hgt * (0.4 + 0.6 * absf(sin(f * PI * 3.0 + k))) if j % 2 == 1 else hgt * 0.25) + C.jit(s + k, j) * 8.0
			pts.append(Vector2(x, y))
		pts.append(Vector2(c.x + wid, c.y + 10))
		pts.append(Vector2(c.x - wid, c.y + 10))
		fill(pts, cols[k], s + k * 10, 1.0, 3.2, 1.2 - k * 0.4, 3.4)


func _teddy(c: Vector2, r: float, s: int, rr: float) -> void:
	var b := BROWN.lightened(0.15)
	for p: Vector2 in [Vector2(-0.8, -1.9), Vector2(0.8, -1.9)]:
		solid(circ(c + p * r, r * 0.38, s + int(p.x * 10), 8), ca(b, rr))
	solid(circ(c + Vector2(0, r * 0.3), r * 0.95, s + 3, 12), ca(b, rr))
	solid(circ(c + Vector2(0, -r * 1.3), r * 0.75, s + 4, 12), ca(b, rr))
	edge(circ(c + Vector2(0, -r * 1.3), r * 0.75, s + 5, 12), INK, 1.6, s + 6, rr, 0.4)
	if rr >= 1.0:
		draw_circle(c + Vector2(-r * 0.28, -r * 1.4), 1.8, INK)
		draw_circle(c + Vector2(r * 0.28, -r * 1.4), 1.8, INK)
		heart(c + Vector2(0, r * 0.2), r * 0.35, RED, s + 7)


# ================================================================== page 4: the Pelicans
func _page_pelicans() -> void:
	var t4 := float(page_t0[4])
	sky_strip(240.0, SKY, 801, rv(t4, 0.6))
	cloud(Vector2(330, 90), 200.0, 802, rv(t4 + 0.3, 0.5))
	cloud(Vector2(1290, 110), 170.0, 803, rv(t4 + 0.4, 0.5))
	grass_strip(380.0, 804, rv(t4 + 0.1, 0.7))
	var rf := rv(t4 + 0.3, 0.6)
	if rf > 0.0:
		var nl := int(rf * 70)
		for k in nl:
			var x := -40.0 + k * 26.0
			ln(Vector2(x, 260), Vector2(x + 120, 380), ca(GREY.darkened(0.15), 0.8), 2.0, 805 + k, 1.0, 0.4)
			ln(Vector2(x + 120, 260), Vector2(x, 380), ca(GREY.darkened(0.15), 0.8), 2.0, 900 + k, 1.0, 0.4)
		ln(Vector2(-10, 258), Vector2(W + 10, 258), GREY.darkened(0.3), 5.0, 980, rf)
	for px: float in [110.0, 1490.0]:
		var rt := rv(t4 + 0.4, 0.6)
		ln(Vector2(px, 640), Vector2(px, 150), GREY.darkened(0.3), 9.0, 981 + int(px), rt)
		if rt >= 1.0:
			var head := C.rect_poly(Rect2(px - 60, 80, 120, 80))
			solid(head, INK)
			for k2 in 6:
				draw_circle(Vector2(px - 38 + (k2 % 3) * 38, 102 + (k2 / 3) * 36), 13.0, SUN)
	var rd := rv(t4 + 0.5, 0.7)
	var dia := PackedVector2Array([Vector2(760, 430), Vector2(1000, 548), Vector2(760, 666), Vector2(520, 548)])
	fill(dia, Color("#d98a4a"), 990, rd, 4.0, 0.3, 4.2)
	edge(dia, WHITE, 4.0, 991, rd)
	if rd >= 1.0:
		for p: Vector2 in dia:
			solid(C.rect_poly(Rect2(p - Vector2(12, 10), Vector2(24, 20))), WHITE)
		solid(circ(Vector2(760, 548), 26.0, 992, 12), Color("#c2753a"))
	var rb := rv(t4 + 0.6, 0.6)
	for k3 in 4:
		ln(Vector2(150 + k3 * 18, 420 + k3 * 30), Vector2(450 - k3 * 18, 420 + k3 * 30), SKY.darkened(0.2), 12.0, 993 + k3, rb, 0.6)
	if rb >= 1.0:
		stick(Vector2(250, 448), 90.0, "boy", 997, 1.0, 1.0, Vector2.ZERO, Vector2.ZERO, 2.4)
		stick(Vector2(380, 508), 90.0, "old", 998, 1.0, 1.0, Vector2.ZERO, Vector2.ZERO, 2.4)
		txt("Z", Vector2(410, 390), 24, GREY.darkened(0.3), 999, 1)
		txt("Z", Vector2(432, 362), 18, GREY.darkened(0.3), 1000, 1)
	# the scoreboard
	var rsb := rv(t4 + 0.2, 0.6)
	var sb := C.rect_poly(Rect2(530, 26, 540, 190))
	if rsb > 0.0:
		ln(Vector2(640, 216), Vector2(640, 262), INK, 10.0, 1001, rsb)
		ln(Vector2(960, 216), Vector2(960, 262), INK, 10.0, 1002, rsb)
		solid(sb, ca(Color("#163a2a"), rsb))
		fill(sb, Color("#0f2a1e"), 1003, rsb, 4.0, -0.4, 4.0)
		edge(sb, INK, 3.4, 1004, rsb)
		txt_c("P.C. PELICANS", 800.0, 92.0, 40, SUN, 1005, 2, rv(wt(18, "P.C.") - 0.1, 0.8))
		txt_c("HOME  0", 690.0, 170.0, 40, WHITE, 1006, 2, rv(wt(18, "SINGLE") - 0.2, 0.5))
		txt_c("AWAY 11", 920.0, 170.0, 40, RED, 1007, 2, rv(wt(18, "SOFTBALL") - 0.2, 0.5))
	var rpn := rv(wt(18, "SINGLE") - 0.3, 0.6)
	if rpn > 0.0:
		ln(Vector2(1160, 330), Vector2(1160, 40), INK, 4.0, 1008, rpn)
		if rpn >= 1.0:
			var wav := sin(t * 3.0) * 6.0
			var fl := PackedVector2Array([Vector2(1160, 40), Vector2(1440, 82 + wav), Vector2(1160, 136)])
			fill(fl, SUN, 1009, 1.0, 3.4, 0.4, 3.6)
			edge(fl, INK, 2.2, 1010)
			txt("SINGLE A", Vector2(1174, 102 + wav * 0.4), 32, RED, 1011, 3)
	_pelican(Vector2(1240, 704), 380.0, 1020, rv(t4 + 0.7, 1.2))


func _pelican(foot: Vector2, h: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var r1 := clampf(rr * 2.0, 0.0, 1.0)
	var r2 := clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	var feather := Color("#f3f6ff")
	for side: float in [-1.0, 1.0]:
		var lx := foot.x + side * h * 0.08
		ln(Vector2(lx, foot.y - h * 0.18), Vector2(lx, foot.y - h * 0.02), ORANGE, 7.0, s + int(side), r1, 0.5)
		if r1 >= 1.0:
			var ft := PackedVector2Array([Vector2(lx, foot.y - h * 0.03), Vector2(lx + side * h * 0.12, foot.y), Vector2(lx - side * h * 0.04, foot.y + 2)])
			solid(ft, ORANGE)
			edge(ft, INK, 1.8, s + 3 + int(side), 1.0, 0.4)
	var body := oval(foot + Vector2(0, -h * 0.42), h * 0.23, h * 0.27, s + 5, 20, 0.05)
	solid(body, feather)
	fill(body, Color("#dfe6f5"), s + 6, r1, 5.0, -0.5, 3.0)
	edge(body, INK, 3.0, s + 7, r1)
	var wing := oval(foot + Vector2(h * 0.1, -h * 0.42), h * 0.1, h * 0.19, s + 8, 14, 0.06)
	fill(wing, GREY, s + 9, r1, 3.6, 0.8, 3.0)
	edge(wing, INK, 2.2, s + 10, r1)
	var bat_a := foot + Vector2(h * 0.14, -h * 0.36)
	ln(bat_a, bat_a + Vector2(h * 0.22, -h * 0.36), BROWN, h * 0.035, s + 11, r2, 0.5)
	var hc := foot + Vector2(-h * 0.02, -h * 0.8)
	var head := circ(hc, h * 0.11, s + 12, 16)
	solid(head, feather)
	edge(head, INK, 2.6, s + 13, r1)
	if r2 <= 0.0:
		return
	var tip := hc + Vector2(-h * 0.44, h * 0.08)
	var upper := PackedVector2Array([hc + Vector2(-h * 0.06, -h * 0.03), tip, hc + Vector2(-h * 0.08, h * 0.04)])
	solid(upper, ORANGE)
	edge(upper, INK, 2.2, s + 14, r2)
	var pouch := arc(hc + Vector2(-h * 0.24, h * 0.06), h * 0.18, h * 0.12, 0.0, PI, 12)
	solid(pouch, SUN)
	edge(pouch, INK, 2.2, s + 15, r2)
	if r2 >= 1.0:
		draw_circle(hc + Vector2(-h * 0.03, -h * 0.03), h * 0.016, INK)
		ln(hc + Vector2(-h * 0.07, -h * 0.07), hc + Vector2(0, -h * 0.06), INK, 2.4, s + 16, 1.0, 0.4)
		var cap := arc(hc + Vector2(0, -h * 0.02), h * 0.115, h * 0.1, PI, TAU, 10)
		solid(cap, NAVY)
		edge(cap, INK, 2.0, s + 17, 1.0, 0.5)
		ln(hc + Vector2(-h * 0.2, -h * 0.03), hc + Vector2(-h * 0.06, -h * 0.03), INK, 5.0, s + 18, 1.0, 0.4)
		txt("PC", hc + Vector2(-h * 0.035, -h * 0.05), 16, GOLD, s + 19, 1)


# ================================================================== page 5: the pizza
func slice(tip: Vector2, crust_c: Vector2, half_w: float, s: int, rr: float, a := 1.0) -> Vector2:
	var face := crust_c.lerp(tip, 0.38)
	if rr <= 0.0 or a <= 0.01:
		return face
	var d := (tip - crust_c).normalized()
	var pp := Vector2(-d.y, d.x)
	var cl := crust_c - pp * half_w
	var cr := crust_c + pp * half_w
	var cheese := PackedVector2Array([cl, cr, tip])
	solid(cheese, ca(SUN.lightened(0.3), a * 0.7 * rr))
	fill(cheese, ca(SUN, a), s, rr, maxf(2.6, half_w * 0.02 + 2.4), -0.5, maxf(2.4, half_w * 0.014 + 2.4))
	edge(cheese, ca(SUN_EDGE.darkened(0.1), a), maxf(1.6, half_w * 0.012), s + 1, rr, 0.8)
	var crust := PackedVector2Array()
	var n := 8
	for k in n + 1:
		crust.append(cl.lerp(cr, float(k) / n) - d * (half_w * 0.1 + (half_w * 0.05 if k % 2 == 1 else 0.0)))
	for k2 in n + 1:
		crust.append(cr.lerp(cl, float(k2) / n) + d * half_w * 0.06)
	fill(crust, ca(TAN.darkened(0.1), a), s + 2, rr, maxf(2.4, half_w * 0.016 + 2.2), 0.4, maxf(2.2, half_w * 0.012 + 2.2))
	edge(crust, ca(BROWN, a), maxf(1.6, half_w * 0.012), s + 3, rr, 0.8)
	if rr < 1.0:
		return face
	var pep: Array = [[0.16, 0.1], [0.84, 0.1], [0.5, 0.08], [0.38, 0.86], [0.64, 0.84]]
	for k3 in pep.size():
		var pv: Array = pep[k3]
		var u := float(pv[0])
		var v := float(pv[1])
		var p := cl.lerp(cr, u).lerp(tip, v * 0.8)
		var pc := circ(p, half_w * 0.1, s + 10 + k3, 10)
		solid(pc, ca(RED, a))
		edge(pc, ca(RED.darkened(0.35), a), maxf(1.2, half_w * 0.01), s + 20 + k3, 1.0, 0.4)
	for side: float in [-1.0, 1.0]:
		var dp := (cl if side < 0.0 else cr).lerp(tip, 0.6)
		var drip := oval(dp + Vector2(0, half_w * 0.08), half_w * 0.05, half_w * 0.12, s + 30 + int(side), 8)
		solid(drip, ca(SUN, a))
	return face


func _page_pizza() -> void:
	var t5 := float(page_t0[5])
	# the wall and the tablecloth
	if t > t5:
		for k in 8:
			star(Vector2(100 + k * 200 + (k % 2) * 60, 260 + (k % 3) * 80), 10.0, ca(LILAC, 0.8), 1100 + k * 3, rv(t5 + 0.1 + k * 0.05, 0.3))
	var rt := rv(t5 + 0.1, 0.8)
	if rt > 0.0:
		var cloth := C.rect_poly(Rect2(-10, 560, W + 20, 350))
		solid(cloth, ca(WHITE, rt))
		var nsq := int(rt * 40)
		for k2 in nsq:
			var cx := k2 % 20
			var cy := k2 / 20
			for cyy in [cy, cy + 2, cy + 4]:
				if (cx + cyy) % 2 == 0:
					fill(C.rect_poly(Rect2(-10 + cx * 82, 560 + cyy * 60, 82, 60)), RED, 1120 + k2 * 3 + cyy, 1.0, 4.4, -0.6, 3.6)
	# the banner
	var rbn := rv(wt(19, "PORT") - 0.4, 0.9)
	if rbn > 0.0:
		var rib := PackedVector2Array([Vector2(420, 60), Vector2(1180, 60), Vector2(1140, 105), Vector2(1180, 150), Vector2(420, 150), Vector2(460, 105)])
		solid(rib, ca(SUN.lightened(0.2), rbn))
		fill(rib, SUN, 1200, rbn, 3.6, -0.3, 3.6)
		edge(rib, INK, 2.6, 1201, rbn)
		txt_c("PORT CARRICK STYLE", 800.0, 124.0, 44, RED, 1202, 3, rv(wt(19, "PORT"), 1.0))
	# slice A (Port Carrick) and, later, slice B (New York): the same slice
	var mv := _ease(rv(cs(21) + 0.15, 0.9))
	var ax := lerpf(800.0, 520.0, mv)
	var ra := rv(t5 + 0.3, 1.2)
	if ra > 0.0 and t < cs(21):
		for k3 in 3:
			var ph := fmod(t * 0.6 + k3 / 3.0, 1.0)
			var sx := ax - 60.0 + k3 * 60.0
			var pts := PackedVector2Array()
			for j in 6:
				pts.append(Vector2(sx + sin(j * 1.3 + t * 3.0) * 10.0, 200.0 - ph * 40.0 - j * 14.0))
			path(pts, ca(GREY, 1.0 - ph), 3.0, 1210 + k3)
	var fa := slice(Vector2(ax, 640), Vector2(ax, 238), 225.0, 1220, ra)
	var rbs := rv(wt(21, "NEW") - 0.3, 1.0)
	var fb := slice(Vector2(1090, 640), Vector2(1090, 238), 225.0, 1220, rbs)
	# "THE" Port Carrick style: a gold #1 star
	var r1 := rv(wt(20, "THE"), 0.4) * (1.0 - rv(cs(21), 0.4))
	if r1 > 0.0:
		star(Vector2(ax + 210, 300), 52.0, GOLD, 1240, r1)
		txt_c("#1", ax + 210.0, 316.0, 34, RED, 1241, 2, r1)
	# not equal
	var rne := rv(wt(21, "COMPLETELY") - 0.1, 0.5)
	if rne > 0.0:
		ln(Vector2(770, 400), Vector2(840, 400), RED, 9.0, 1250, rne)
		ln(Vector2(770, 430), Vector2(840, 430), RED, 9.0, 1251, rne)
		ln(Vector2(828, 370), Vector2(782, 460), RED, 9.0, 1252, rv(wt(21, "COMPLETELY") + 0.3, 0.3))
	var rl := rv(wt(21, "NEW") + 0.4, 0.5)
	if rl > 0.0:
		for lab: Array in [[ax, "PORT CARRICK"], [1090.0, "NEW YORK"]]:
			var lx := float(lab[0])
			var tag := C.rect_poly(Rect2(lx - 150, 668, 300, 48))
			solid(tag, ca(WHITE, rl))
			edge(tag, INK, 2.2, 1260 + int(lx), rl)
			txt_c(String(lab[1]), lx, 704.0, 30, INK, 1262 + int(lx), 2, rl)
	# the 80s
	var r8 := rv(cs(22), 0.7) * (1.0 - rv(cs(23) + 0.4, 0.6))
	if r8 > 0.0:
		var zig: Array = [[Vector2(60, 220), PINK], [Vector2(1330, 470), CYAN], [Vector2(60, 470), CYAN], [Vector2(1330, 220), PINK]]
		for k4 in zig.size():
			var zz: Array = zig[k4]
			var o: Vector2 = zz[0]
			var pts2 := PackedVector2Array()
			for j2 in 7:
				pts2.append(o + Vector2(j2 * 34.0, (j2 % 2) * 46.0))
			path(pts2, ca(zz[1], r8), 8.0, 1270 + k4 * 10, r8)
		var burst := PackedVector2Array()
		var bc := Vector2(1420, 330)
		for j3 in 24:
			var rad := 95.0 if j3 % 2 == 0 else 62.0
			var ang := TAU * j3 / 24.0
			burst.append(bc + Vector2(cos(ang), sin(ang)) * rad)
		var rbu := rv(wt(22, "80S") - 0.2, 0.4) * (1.0 - rv(cs(23) + 0.4, 0.6))
		if rbu > 0.0:
			solid(burst, ca(CYAN.lightened(0.3), rbu))
			edge(burst, ca(PINK, rbu), 3.0, 1290, rbu)
			txt_c("80S!", 1420.0, 352.0, 50, ca(PINK, rbu), 1291, 3, rbu)
	# faces: sunglasses in the 80s; then one sad, one smug
	var sg := rv(cs(22) + 0.4, 0.3) * (1.0 - rv(wt(23, "BLAME") - 0.3, 0.3))
	if sg > 0.0 and ra >= 1.0:
		for side: float in [-1.0, 1.0]:
			solid(oval(fa + Vector2(side * 40, 0), 36, 22, 1300 + int(side), 12), ca(INK, sg))
		ln(fa + Vector2(-8, -4), fa + Vector2(8, -4), ca(INK, sg), 5.0, 1302)
	var rsad := rv(wt(23, "BLAME") - 0.1, 0.4)
	if rsad > 0.0 and ra >= 1.0:
		for side2: float in [-1.0, 1.0]:
			draw_circle(fa + Vector2(side2 * 38, -6), 9.0, ca(INK, rsad))
			ln(fa + Vector2(side2 * 54, -22), fa + Vector2(side2 * 22, -38), ca(INK, rsad), 4.0, 1303 + int(side2))
		path(arc(fa + Vector2(0, 48), 34, 16, PI + 0.3, TAU - 0.3, 8), ca(INK, rsad), 4.0, 1305, rsad)
		var tr := fmod(t * 0.8, 1.0)
		solid(oval(fa + Vector2(42, 10 + tr * 40), 6, 9, 1306, 8), ca(TEAR, rsad * (1.0 - tr)))
	var rsm := rv(wt(23, "NEW") - 0.1, 0.4)
	if rsm > 0.0 and rbs >= 1.0:
		for side3: float in [-1.0, 1.0]:
			draw_circle(fb + Vector2(side3 * 38, -4), 9.0, ca(INK, rsm))
			ln(fb + Vector2(side3 * 56, -30), fb + Vector2(side3 * 20, -20), ca(INK, rsm), 5.0, 1307 + int(side3))
		path(PackedVector2Array([fb + Vector2(-30, 36), fb + Vector2(0, 44), fb + Vector2(34, 28)]), ca(INK, rsm), 4.0, 1309, rsm)


# ================================================================== her, at the edges
func _intrusions() -> void:
	for it: Dictionary in intrusions:
		var p := (t - float(it["t"])) / float(it["dur"])
		if p <= 0.0 or p >= 1.0:
			continue
		var inn := _ease(p / 0.3)
		var a := 1.0 - _ease((p - 0.72) / 0.28)
		var slide := (1.0 - inn) * 150.0
		match String(it["kind"]):
			"heart":
				heart(Vector2(120 - slide, 600), 40.0, ca(PINK, a), 2000, inn)
				txt("DADDY", Vector2(50 - slide, 700), 44, ca(PINK.darkened(0.15), a), 2001, 3, inn)
			"balloon":
				var c := Vector2(1470, 150 - slide + sin(t * 1.5) * 6.0)
				balloon(c, 52.0, PINK, c + Vector2(-16, 210), 2010, inn, a)
				heart(c + Vector2(0, 6), 16.0, ca(WHITE, a * 0.9), 2011, inn)
			"girl_pizza":
				var f := Vector2(110 - slide, 560)
				stick(f, 200.0, "me", 2020, inn, a, Vector2.ZERO, f + Vector2(66, -110), 3.0)
				if inn >= 1.0:
					slice(f + Vector2(96, -170), f + Vector2(62, -108), 22.0, 2021, 1.0, a)
				txt_c("ME", 110.0 - slide, 330.0, 32, ca(PINK, a), 2022, 2, inn)
			"girl_wave":
				var f2 := Vector2(1500 + slide, 568)
				var hand := f2 + Vector2(-60 + sin(t * 9.0) * 8.0, -220)
				stick(f2, 190.0, "me", 2030, inn, a, hand, Vector2.ZERO, 3.0)


# ================================================================== the takeover
func _takeover(k: float) -> void:
	if k <= 0.0:
		return
	var cols: Array[Color] = [PINK, PURPLE, RED, LILAC, Color("#ff8fd0")]
	var depth := _ease(k * 1.4) * 540.0
	for e in 4:
		for i in 54:
			var s := 7000 + e * 211 + i
			var u := C.rnd(s, 1)
			var st := Vector2(u * W, -8)
			var dir := Vector2(0, 1)
			match e:
				1:
					st = Vector2(W + 8, u * H)
					dir = Vector2(-1, 0)
				2:
					st = Vector2(u * W, H + 8)
					dir = Vector2(0, -1)
				3:
					st = Vector2(-8, u * H)
					dir = Vector2(1, 0)
			dir = dir.rotated((C.rnd(s, 2) - 0.5) * 1.0)
			var L := depth * (0.35 + 0.9 * C.rnd(s, 3)) * clampf(k * 2.2 - C.rnd(s, 4), 0.0, 1.0)
			if L < 6.0:
				continue
			var nrm := Vector2(-dir.y, dir.x)
			var n := int(L / 12.0) + 2
			var pts := PackedVector2Array()
			for j in n:
				var f := float(j) / (n - 1)
				pts.append(st + dir * L * f + nrm * (C.jit(s, j) * 16.0 + sin(f * 9.0 + i) * 10.0))
			draw_polyline(pts, ca(cols[i % cols.size()], 0.85), 3.0 + 3.0 * C.rnd(s, 5), true)
	# her bridge, across the middle of everything
	var rb := clampf((k - 0.12) / 0.2, 0.0, 1.0)
	if rb > 0.0:
		var rv_band := C.rect_poly(Rect2(-10, 520, W + 20, 90))
		fill(rv_band, ca(RIVER, 0.9), 7200, rb, 3.6, -0.15, 4.0)
		bridge(160.0, 1440.0, 500.0, 170.0, PINK, 7300, rb, 1.0, 1.4)
	# the cars, bunching up
	var rc := clampf((k - 0.28) / 0.1, 0.0, 1.0)
	if rc > 0.0:
		var bunch := _ease((k - 0.36) / 0.36)
		var car_cols: Array[Color] = [RED, SUN, SKY, GRASS, ORANGE, PURPLE, NAVY, PINK, CYAN]
		for i2 in 9:
			var spread := 250.0 + i2 * 130.0 + (k - 0.28) * 260.0
			var packed := 620.0 + i2 * 44.0
			var x := lerpf(spread, packed, bunch)
			var cr := clampf((bunch - 0.6) / 0.4, 0.0, 1.0)
			var rot := (C.rnd(7400, i2) - 0.5) * 1.0 * cr
			var lift := -C.rnd(7401, i2) * 30.0 * clampf((bunch - 0.7) / 0.3, 0.0, 1.0)
			car(Vector2(x, 470 + lift), 92.0, car_cols[i2], 7410 + i2 * 13, rot, rc)
	# her word for him, over and over
	var rw := clampf((k - 0.36) / 0.3, 0.0, 1.0)
	for i3 in int(rw * 12):
		var px := 60.0 + C.rnd(7500, i3) * (W - 400.0)
		var ys: Array[float] = [110.0, 230.0, 330.0, 700.0, 800.0]
		var py: float = ys[i3 % ys.size()] + C.rnd(7502, i3) * 30.0
		txt("DADDY", Vector2(px, py), 34 + int(C.rnd(7501, i3) * 26.0), PINK if i3 % 2 == 0 else PURPLE, 7510 + i3, 2)
	# and he scribbles it out
	var rs := clampf((k - 0.8) / 0.15, 0.0, 1.0)
	if rs > 0.0:
		for pi in 3:
			var pts2 := PackedVector2Array()
			var n2 := 46
			var shown := int(n2 * rs)
			for j2 in shown + 1:
				var f2 := float(j2) / n2
				var x2 := lerpf(-60.0, W + 60.0, f2) + C.jit(7600 + pi, j2) * 18.0 + pi * 12.0
				var y2 := (H * 0.04 if j2 % 2 == 0 else H * 0.96) + C.jit(7610 + pi, j2) * 50.0
				pts2.append(Vector2(x2, y2))
			if pts2.size() >= 2:
				draw_polyline(pts2, ca(INK, 0.92), 24.0 + pi * 8.0, true)
		if k > 0.95:
			draw_rect(Rect2(0, 0, W, H), ca(INK, (k - 0.95) / 0.05))


# ================================================================== captions
func _tokens(text: String) -> Array:
	var out: Array = []
	for raw: String in text.split(" ", false):
		var red := raw.contains("*")
		var pizza := raw.contains("{PIZZA}")
		out.append({"w": raw.replace("*", "").replace("{PIZZA}", ""), "red": red, "pizza": pizza})
	return out


func _tok_w(tk: Dictionary, size: int) -> float:
	var w := C.letters_width(String(tk["w"]), size) if String(tk["w"]) != "" else 0.0
	if bool(tk["pizza"]):
		w += size * 1.2
	return w


func _layout(tokens: Array, size: int, maxw: float) -> Array:
	var lines: Array = []
	var cur: Array = []
	var x := 0.0
	var sp := size * 0.42
	for i in tokens.size():
		var tw := _tok_w(tokens[i], size)
		if not cur.is_empty() and x + sp + tw > maxw:
			lines.append(cur)
			cur = []
			x = 0.0
		if not cur.is_empty():
			x += sp
		cur.append(i)
		x += tw
	if not cur.is_empty():
		lines.append(cur)
	return lines


func _print_card(i: int, size: int, maxw: float, left: float, base0: float, line_h: float, centred: bool, col: Color, heavy: int) -> void:
	var tokens := _tokens(String(cards[i]["text"]))
	var lines := _layout(tokens, size, maxw)
	var shown := (t - cs(i)) * CPS
	var starts: Array = []
	var acc := 0
	for tk: Dictionary in tokens:
		starts.append(acc)
		acc += String(tk["w"]).length() + (1 if bool(tk["pizza"]) else 0) + 1
	var sp := size * 0.42
	var y0 := base0
	if centred:
		y0 = base0 - (lines.size() - 1) * line_h * 0.5
	for li in lines.size():
		var row: Array = lines[li]
		var lw := 0.0
		for ti: int in row:
			lw += _tok_w(tokens[ti], size)
		lw += sp * (row.size() - 1)
		var x := (W * 0.5 - lw * 0.5) if centred else left
		var y := y0 + li * line_h
		for ti2: int in row:
			var tk2: Dictionary = tokens[ti2]
			var w := String(tk2["w"])
			var n := w.length() + (1 if bool(tk2["pizza"]) else 0)
			var r := clampf((shown - float(starts[ti2])) / maxf(1.0, float(n)), 0.0, 1.0)
			if r <= 0.0:
				return
			var tw := C.letters_width(w, size) if w != "" else 0.0
			if w != "":
				C.letters(self, w, Vector2(x, y), size, RED if bool(tk2["red"]) else col, 3000 + i * 97 + ti2 * 7, heavy, 1.0, r)
			if bool(tk2["pizza"]):
				if r >= 1.0:
					var pc := Vector2(x + tw + size * 0.55, y - size * 0.5)
					slice(pc + Vector2(0, size * 0.62), pc - Vector2(0, size * 0.5), size * 0.42, 3500 + i, 1.0)
				tw += size * 1.2
			x += tw + sp


func _captions() -> void:
	var strip_on := false
	var cur := -1
	for i in cards.size():
		if String(cards[i]["style"]) == "strip" and t >= cs(i) - 0.25 and t < ce(i) + 0.45:
			strip_on = true
		if t >= cs(i) and t < ce(i):
			cur = i
	if strip_on:
		_strip()
	if cur < 0:
		return
	if String(cards[cur]["style"]) == "center":
		_print_card(cur, 50, 1300.0, 0.0, 470.0, 80.0, true, INK, 3)
	else:
		_print_card(cur, 31, 1330.0, 160.0, 766.0, 54.0, false, INK, 2)


func _strip() -> void:
	var x0 := 70.0
	var x1 := 1530.0
	var y0 := 716.0
	var y1 := 880.0
	var pts := PackedVector2Array()
	for k in 33:
		pts.append(Vector2(lerpf(x0, x1, k / 32.0), y0 + (C.rnd(1100, k) - 0.5) * 10.0))
	for k2 in 33:
		pts.append(Vector2(lerpf(x1, x0, k2 / 32.0), y1 + (C.rnd(1101, k2) - 0.5) * 10.0))
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(6, 7))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.12))
	draw_colored_polygon(pts, Color("#fffdf7"))
	for ly: float in [770.0, 824.0]:
		draw_line(Vector2(x0 + 8, ly), Vector2(x1 - 8, ly), Color("#a9d4ff"), 2.0, true)
	draw_line(Vector2(140, y0 + 6), Vector2(140, y1 - 6), Color("#ff9a9a"), 2.0, true)
	C.outline(self, pts, Color("#c9c3b4"), 1.4, 1102, 0.4)


# ================================================================== the title
func _title() -> void:
	if t < T_TITLE:
		return
	var r := rv(T_TITLE, 1.6)
	var scrap := PackedVector2Array()
	for k in 21:
		scrap.append(Vector2(lerpf(450, 1330, k / 20.0), 112 + (C.rnd(9000, k) - 0.5) * 12.0))
	for k2 in 21:
		scrap.append(Vector2(lerpf(1330, 450, k2 / 20.0), 292 + (C.rnd(9001, k2) - 0.5) * 12.0))
	draw_colored_polygon(scrap, ca(Color("#fffdf7"), minf(1.0, r * 3.0)))
	txt_c("THE VIOLENCE", 890.0, 256.0, 108, RED, 9002, 3, r)
	var ru := rv(T_TITLE + 1.7, 0.5)
	if ru > 0.0:
		var pts := PackedVector2Array()
		for j in 9:
			pts.append(Vector2(lerpf(510, 1270, j / 8.0), 276 + (j % 2) * 8.0))
		path(pts, RED, 7.0, 9003, ru, 1.0, 2)
