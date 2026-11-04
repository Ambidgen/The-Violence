extends "res://scripts/view/proto/presser_view.gd"
## Cutscene 3 — Jeremy Berry (prototype, 2026-10-30). Thomas's narration of how the man
## behind the Valentine's Day shooting got there: the silly name, the serious man, the
## Eastside tower, who he would and would not rent to, the internet, the empty rooms,
## the loans, the rebrand, Christmas 1998, the things he stopped doing, and the door.
## It ends on the date and leads straight into the tutorial mission (the top-floor
## clear of Paisley Tower).
##
## Same hand as the other two: a child's brightest crayons. The camera travels along
## one long drawing, a page per beat. The emoji in the script are drawn as she would
## have drawn them (graves and flowers, thumbs, a shrug between two no-signs, the
## falling charts and the money slipping through, a wall of TVs, the placards, the
## footprints). Her own things creep in twice: the bridge backing up, and a present
## under the Christmas tree. Nothing of the shooting is shown. Presentation only.

## [text, who, gap before (s), duration (<= 0: from length), page]
##   who: N = his narration (strip), BEAT = the page alone, END = on black.
const LINES3 := [
	["", "BEAT", 0.0, 3.8, 0],
	["JEREMY BERRY WAS A STUPID FUCKING NAME.", "N", 0.2, -1.0, 0],
	["I ALWAYS THINK THAT EVERY TIME I THINK ABOUT *IT*.", "N", 0.3, -1.0, 0],
	["IT JUST SOUNDED SO SILLY LIKE THE KIND OF GUY YOU COULD NEVER TAKE SERIOUSLY.", "N", 0.3, -1.0, 0],
	["HE WAS PRETTY SERIOUS IN PERSON THOUGH.", "N", 0.6, -1.0, 0],
	["MR. J. BERRY WAS SERIOUS AS A COUGH.", "N", 0.3, -1.0, 0],
	["", "BEAT", 0.3, 4.8, 1],
	["JUST NOT *SO* SERIOUS THAT IT PUT PEOPLE OFF.", "N", 0.3, -1.0, 2],
	["PEOPLE DIDN'T LIKE HIM VERY MUCH, BUT HE NEVER WEIRDED ANYONE OUT LIKE *THAT*.", "N", 0.3, -1.0, 2],
	["HE ALWAYS JUST SEEMED LIKE THE KIND OF GUY THAT DIDN'T CARE ABOUT MAKING FRIENDS.", "N", 0.6, -1.0, 2],
	["HE HAD MONEY THOUGH. EASTSIDE REAL ESTATE.", "N", 0.6, -1.0, 2],
	["PAISLEY AVENUE. HIGH RISK HIGH REWARD.", "N", 0.6, -1.0, 3],
	["BLACK FOLKS TENDED TO CLUSTER IN NORTH WEST. LATINOS SOUTH.", "N", 0.6, -1.0, 3],
	["THE APARTMENTS EAST WERE THE MOST A LOT OF PEOPLE THAT DIDN'T FIT IN WITH THOSE TWO COMMUNITIES COULD AFFORD.", "N", 0.3, -1.0, 3],
	["IF YOU OWNED A BUILDING THERE YOU RENTED EXCLUSIVELY TO THE INDIAN, AFGHAN OR KOREAN FAMILIES IN THE AREA", "N", 0.4, -1.0, 3],
	["OR YOU SETTLED FOR PURE, DOMESTIC AMERICAN TRASH.", "N", 0.2, -1.0, 3],
	["MOST LANDLORDS PREFERRED THE IMMIGRANTS.", "N", 0.6, -1.0, 3],
	["JEREMY WAS... LET'S JUST SAY OPEN TO SETTLING.", "N", 0.4, -1.0, 3],
	["JEREMY DIDN'T HAVE A PROBLEM WITH IMMIGRANTS.", "N", 0.6, -1.0, 4],
	["IT WAS SIMPLER THAN THAT.", "N", 0.3, 4.4, 4],
	["PROBLEM WAS, THIS WASN'T THE 50S.", "N", 0.6, -1.0, 4],
	["I MEAN SURE WE STILL HAD RACISM IN PORT CARRICK,", "N", 0.3, -1.0, 4],
	["SHIT, I STILL HAVE MOMENTS WHEN THE BRIDGE BACKS UP FAR ENOUGH.", "N", 0.2, 5.4, 4],
	["BUT THE INTERNET CHANGED A LOT.", "N", 1.0, -1.0, 5],
	["AND SO WORD GOT AROUND ABOUT THAT KIND OF THING IN WAYS IT NEVER USED TO.", "N", 0.3, -1.0, 5],
	["LET'S JUST SAY JEREMY GOT A LOT OF ATTENTION THAT WASN'T VERY NICE.", "N", 0.8, -1.0, 5],
	["SO MUCH SO THAT TENANTS STARTED LEAVING.", "N", 0.6, -1.0, 6],
	["AND ONE BY ONE, ALL THOSE LOVELY LITTLE ROOMS STARTED GOING EMPTY.", "N", 0.3, 5.4, 6],
	["SO AFTER A YEAR OF BURNING THROUGH HIS SAVINGS TRYING TO HOLD ON, TAKING A", "N", 0.4, -1.0, 6],
	["", "BEAT", 0.2, 8.4, 7],
	["A LITTLE 'REBRANDING'...", "N", 0.6, -1.0, 8],
	["MARKETING THAT RAN FROM JUNE TO DECEMBER.", "N", 0.3, -1.0, 8],
	["A GREAT RE-OPENING FOR A NEW PAISLEY TOWER.", "N", 0.3, -1.0, 8],
	["A *BETTER* PAISLEY TOWER.", "N", 0.2, -1.0, 8],
	["A MORE MODERN PAISLEY TOWER.", "N", 0.2, -1.0, 8],
	["...UNTIL HE REALIZED THAT FATEFUL DAY.", "N", 0.8, -1.0, 9],
	["CHRISTMAS 1998.", "N", 0.3, 3.0, 9],
	["THAT PEOPLE DIDN'T FORGET AS EASILY AS THEY USED TO.", "N", 0.4, -1.0, 9],
	["AND SO JEREMY STOPPED RUNNING THE COMMERCIALS.", "N", 0.8, -1.0, 10],
	["STOPPED PUTTING OUT FLYERS.", "N", 0.2, -1.0, 10],
	["STOPPED PICKING UP THE PHONE WHEN THE BANK CALLED.", "N", 0.2, -1.0, 10],
	["STOPPED PAYING THE PHONE BILL.", "N", 0.2, -1.0, 10],
	["STOPPED TALKING TO OTHERS.", "N", 0.2, -1.0, 10],
	["STOPPED LEAVING THE TOWER ALTOGETHER, PEOPLE IN THAT NEIGHBORHOOD SAY.", "N", 0.2, -1.0, 10],
	["", "BEAT", 0.4, 3.8, 11],
	["...UNTIL ONE DAY HE DID.", "N", 0.2, 3.8, 11],
	["FEBRUARY 14TH, 1999", "END", 0.6, 4.6, 11],
]

const PAGES := 12
const TOWER := Color("#c69cff")
const TOWER_TRIM := Color("#ff4fa7")
const CASH := Color("#7fd36b")
const CASH_DARK := Color("#2f8a3a")
const BEIGE := Color("#eadcc0")
const SNOW := Color("#ffffff")


func _build() -> void:
	reporters = []
	flashes = []
	flash_pos = []
	intrusions = []
	cards.clear()
	var at := 0.0
	for i in LINES3.size():
		var l: Array = LINES3[i]
		var text := String(l[0])
		var n := _plain(text).length()
		var dur := float(l[3])
		if dur <= 0.0:
			dur = maxf(1.6, 0.9 + n / 15.0)
		var st := at + float(l[2])
		cards.append({"text": text, "who": String(l[1]), "t": st, "dur": dur, "pg": int(l[4]), "cps": CPS})
		at = st + dur
	T_END = ce(cards.size() - 1) + 1.0


func cues() -> Dictionary:
	var starts: Array = []
	for c: Dictionary in cards:
		starts.append(float(c["t"]))
	var pages: Array = []
	for pg in PAGES:
		for i in cards.size():
			if int(cards[i]["pg"]) == pg:
				pages.append(cs(i))
				break
	var stops: Array = []
	for i2 in range(38, 44):
		stops.append(wt(i2, "STOPPED") + 0.5)
	return {"cards": starts, "pages": pages, "graves": cs(6), "loans": cs(29), "bills": cs(29) + 4.0,
		"bridge": wt(22, "BRIDGE"), "christmas": cs(36), "phone": cs(40), "stops": stops,
		"footsteps": cs(44), "door": cs(45) + 0.4, "end_line": cs(46), "end": T_END}


func jb_cam_x() -> float:
	var i := -1
	for k in cards.size():
		if t >= cs(k) - 0.35:
			i = k
	if i < 0:
		return W * 0.5
	var pg := int(cards[i]["pg"])
	var prev := int(cards[i - 1]["pg"]) if i > 0 else pg
	var f := _ease((t - (cs(i) - 0.35)) / 0.85)
	if absi(pg - prev) > 1:
		f = 1.0
	return lerpf(prev * W + W * 0.5, pg * W + W * 0.5, f)


# ================================================================== draw
func _draw() -> void:
	C.frame = int(t * 8.0)
	C.boil = 1.0
	var rs := vp.x / W
	var cx := jb_cam_x()
	for pg in PAGES:
		var x0 := pg * W
		if x0 + W < cx - W * 0.5 - 2.0 or x0 > cx + W * 0.5 + 2.0:
			continue
		draw_set_transform(Vector2(x0 - cx + W * 0.5, 0.0) * rs, 0.0, Vector2(rs, rs))
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		match pg:
			0: jb_p0()
			1: jb_p1()
			2: jb_p2()
			3: jb_p3()
			4: jb_p4()
			5: jb_p5()
			6: jb_p6()
			7: jb_p7()
			8: jb_p8()
			9: jb_p9()
			10: jb_p10()
			11: jb_p11()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	_captions()
	jb_end()


func jb_end() -> void:
	var i := cards.size() - 1
	if t < cs(i) - 0.5:
		return
	draw_rect(Rect2(0, 0, W, H), ca(INK, rv(cs(i) - 0.5, 0.5)))
	if t >= cs(i):
		_print_card(i, 52, 1300.0, 0.0, 470.0, 70.0, true, Color("#f4f0e6"), 3)


# ================================================================== people
func jb_jeremy(foot: Vector2, h: float, rr: float, mouth := "frown", extra := {}) -> void:
	var rp := {"id": "JB", "foot": foot, "h": h, "s": 9050, "suit": Color("#a0662e"), "skin": Color("#f3cfb3"),
		"hair": "short", "hair_col": Color("#3b2a1a"), "tie": GRASS_DARK, "plain": true}
	for k: String in extra:
		rp[k] = extra[k]
	_reporter(rp, rr, mouth, 0.0)


# ================================================================== little drawings
func jb_berry(c: Vector2, r: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		var w := r * (1.0 - 0.35 * maxf(0.0, sin(a)))
		pts.append(c + Vector2(cos(a) * w, sin(a) * r * 1.15))
	solid(pts, ca(RED.lightened(0.2), rr * 0.7))
	fill(pts, RED, s, rr, 3.0, -0.5, 3.0)
	edge(pts, RED.darkened(0.35), 2.2, s + 1, rr)
	if rr >= 1.0:
		for k2 in 7:
			var p := c + Vector2((C.rnd(s, k2) - 0.5) * r * 1.2, (C.rnd(s + 1, k2) - 0.3) * r * 1.4)
			draw_circle(p, 2.2, SUN)
		for k3 in 4:
			var a2 := PI * 1.15 + k3 * 0.23
			var lf := C.ellipse_poly(c + Vector2(cos(a2), sin(a2)) * r * 1.05, r * 0.32, r * 0.13, 8, s + 10 + k3, 0.05, a2)
			solid(lf, GRASS_DARK)


func jb_tomb(base: Vector2, w: float, h: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var pts := arc(base + Vector2(0, -h + w * 0.5), w * 0.5, w * 0.5, PI, TAU, 10)
	pts.append(base + Vector2(w * 0.5, 0))
	pts.append(base + Vector2(-w * 0.5, 0))
	solid(pts, ca(Color("#dfe2ea"), rr))
	fill(pts, GREY, s, rr, 4.0, -0.5, 3.0)
	edge(pts, INK, 2.6, s + 1, rr)
	if rr >= 1.0:
		txt_c("RIP", base.x, base.y - h * 0.4, int(w * 0.3), INK, s + 2, 1)
		for k in 4:
			var gx := base.x - w * 0.6 + k * w * 0.4
			ln(Vector2(gx, base.y + 4), Vector2(gx - 5, base.y - 10), GRASS_DARK, 2.4, s + 3 + k, 1.0, 0.4)
			ln(Vector2(gx, base.y + 4), Vector2(gx + 6, base.y - 12), GRASS_DARK, 2.4, s + 9 + k, 1.0, 0.4)


## 0 wilted rose, 1 rose, 2 blossom, 3 bouquet, 4 hibiscus, 5 tulip, 6 sunflower.
func jb_bloom(p: Vector2, r: float, kind: int, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var bot := p + Vector2(0, r * 2.6)
	var head := p
	if kind == 0:
		head = p + Vector2(r * 0.9, r * 0.9)
		path(PackedVector2Array([bot, p + Vector2(0, r * 0.5), p + Vector2(r * 0.5, r * 0.2), head]), GRASS_DARK, 4.0, s, rr)
	elif kind != 3:
		ln(bot, head, GRASS_DARK, 4.0, s, rr, 0.6)
	if kind != 3:
		solid(C.ellipse_poly(p + Vector2(r * 0.25, r * 1.7), r * 0.35, r * 0.14, 8, s + 1, 0.05, -0.5), ca(GRASS, rr))
	if rr < 1.0:
		return
	match kind:
		0:
			var hd := C.ellipse_poly(head, r * 0.45, r * 0.6, 12, s + 2, 0.08, 0.6)
			solid(hd, Color("#7a1f3d"))
			edge(hd, INK, 2.0, s + 3, 1.0, 0.5)
			solid(C.ellipse_poly(head + Vector2(r * 0.4, r * 1.6), r * 0.22, r * 0.12, 8, s + 4, 0.1, 0.4), Color("#7a1f3d"))
		1:
			var rose := circ(p, r * 0.7, s + 2, 14)
			solid(rose, RED)
			edge(rose, RED.darkened(0.4), 2.0, s + 3, 1.0, 0.5)
			path(arc(p, r * 0.35, r * 0.35, 0.0, TAU * 0.85, 10), RED.darkened(0.4), 2.4, s + 4)
		2:
			for k in 5:
				var a := TAU * k / 5.0 - PI * 0.5
				solid(circ(p + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.38, s + 5 + k, 10), Color("#ffb3d9"))
			draw_circle(p, r * 0.18, SUN)
		3:
			var wrap := PackedVector2Array([p + Vector2(-r * 0.8, r * 0.3), p + Vector2(r * 0.8, r * 0.3), p + Vector2(0, r * 2.4)])
			solid(wrap, LILAC)
			edge(wrap, INK, 2.0, s + 6, 1.0, 0.5)
			var cols: Array[Color] = [PINK, SUN, PURPLE, RED]
			for k2 in 4:
				solid(circ(p + Vector2(-r * 0.5 + k2 * r * 0.34, -r * 0.1 - (k2 % 2) * r * 0.3), r * 0.3, s + 7 + k2, 10), cols[k2])
		4:
			for k3 in 5:
				var a3 := TAU * k3 / 5.0 - PI * 0.5
				solid(C.ellipse_poly(p + Vector2(cos(a3), sin(a3)) * r * 0.5, r * 0.5, r * 0.32, 10, s + 12 + k3, 0.08, a3), Color("#ff3d7f"))
			ln(p, p + Vector2(r * 0.3, -r * 0.5), RED.darkened(0.3), 3.0, s + 18, 1.0, 0.3)
			draw_circle(p + Vector2(r * 0.3, -r * 0.5), r * 0.1, SUN)
		5:
			var cup := PackedVector2Array([p + Vector2(-r * 0.55, -r * 0.6), p + Vector2(-r * 0.2, -r * 0.2), p + Vector2(0, -r * 0.7), p + Vector2(r * 0.2, -r * 0.2), p + Vector2(r * 0.55, -r * 0.6), p + Vector2(r * 0.45, r * 0.3), p + Vector2(-r * 0.45, r * 0.3)])
			solid(cup, PINK if s % 2 == 0 else RED)
			edge(cup, INK, 2.0, s + 19, 1.0, 0.5)
		6:
			for k4 in 12:
				var a4 := TAU * k4 / 12.0
				solid(C.ellipse_poly(p + Vector2(cos(a4), sin(a4)) * r * 0.65, r * 0.32, r * 0.13, 8, s + 20 + k4, 0.05, a4), SUN)
			solid(circ(p, r * 0.42, s + 33, 12), BROWN)
			for k5 in 6:
				draw_circle(p + Vector2(C.rnd(s, k5) - 0.5, C.rnd(s + 1, k5) - 0.5) * r * 0.5, 2.0, INK)


func jb_thumb(c: Vector2, sz: float, col: Color, up: bool, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var d := -1.0 if up else 1.0
	var th := oval(c + Vector2(-sz * 0.18, d * sz * 0.5), sz * 0.14, sz * 0.32, s, 12, 0.05)
	solid(th, ca(col, rr))
	fill(th, col.darkened(0.12), s + 1, rr, 3.4, -0.5, 2.6)
	edge(th, INK, 2.6, s + 2, rr, 0.6)
	var fist := oval(c, sz * 0.44, sz * 0.36, s + 3, 16, 0.05)
	solid(fist, ca(col, rr))
	fill(fist, col.darkened(0.12), s + 4, rr, 4.0, -0.5, 3.0)
	edge(fist, INK, 2.8, s + 5, rr, 0.6)
	if rr >= 1.0:
		for k in 3:
			var y := c.y + (k - 1) * sz * 0.18
			ln(Vector2(c.x + sz * 0.05, y), Vector2(c.x + sz * 0.38, y), INK, 2.2, s + 6 + k, 1.0, 0.3)


func jb_no(c: Vector2, r: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	edge(circ(c, r, s, 22), RED, 9.0, s + 1, rr, 0.8)
	ln(c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, r * 0.7), RED, 9.0, s + 2, rr, 0.6)


func jb_face(c: Vector2, r: float, kind: String, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var col := SUN
	match kind:
		"angry": col = Color("#ff4a3d")
		"swear": col = Color("#c81e2b")
	var f := circ(c, r, s, 18)
	solid(f, ca(col, rr))
	fill(f, col.darkened(0.12), s + 1, rr, 4.0, -0.5, 3.0)
	edge(f, INK, 2.6, s + 2, rr)
	if rr < 1.0:
		return
	match kind:
		"grin":
			for sd: float in [-1.0, 1.0]:
				draw_circle(c + Vector2(sd * r * 0.35, -r * 0.2), r * 0.11, INK)
			var g := arc(c + Vector2(0, r * 0.1), r * 0.55, r * 0.45, 0.1, PI - 0.1, 10)
			solid(g, WHITE)
			edge(g, INK, 2.2, s + 3, 1.0, 0.4)
		"money":
			for sd2: float in [-1.0, 1.0]:
				txt_c("$", c.x + sd2 * r * 0.36, c.y - r * 0.02, int(r * 0.5), CASH_DARK, s + 4 + int(sd2), 2)
			var g2 := arc(c + Vector2(0, r * 0.15), r * 0.55, r * 0.42, 0.1, PI - 0.1, 10)
			solid(g2, INK)
			solid(C.rect_poly(Rect2(c + Vector2(-r * 0.22, r * 0.3), Vector2(r * 0.44, r * 0.42))), CASH)
		"angry", "swear":
			for sd3: float in [-1.0, 1.0]:
				draw_circle(c + Vector2(sd3 * r * 0.34, -r * 0.08), r * 0.1, INK)
				ln(c + Vector2(sd3 * r * 0.6, -r * 0.42), c + Vector2(sd3 * r * 0.12, -r * 0.24), INK, 3.6, s + 6 + int(sd3), 1.0, 0.3)
			if kind == "swear":
				solid(C.rect_poly(Rect2(c + Vector2(-r * 0.55, r * 0.25), Vector2(r * 1.1, r * 0.34))), INK)
				txt_c("#$%!", c.x, c.y + r * 0.52, int(r * 0.26), WHITE, s + 9, 1)
			else:
				path(arc(c + Vector2(0, r * 0.62), r * 0.32, r * 0.18, PI + 0.3, TAU - 0.3, 8), INK, 3.2, s + 10)
		"eyeroll":
			for sd4: float in [-1.0, 1.0]:
				var e := c + Vector2(sd4 * r * 0.34, -r * 0.12)
				solid(circ(e, r * 0.2, s + 11 + int(sd4), 10), WHITE)
				edge(circ(e, r * 0.2, s + 13 + int(sd4), 10), INK, 1.6, s + 15 + int(sd4), 1.0, 0.3)
				draw_circle(e + Vector2(r * 0.04, -r * 0.1), r * 0.08, INK)
			ln(c + Vector2(-r * 0.3, r * 0.45), c + Vector2(r * 0.3, r * 0.42), INK, 3.0, s + 17, 1.0, 0.4)


func jb_chart(p: Vector2, w: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var card := C.rect_poly(Rect2(p, Vector2(w, w * 0.86)))
	solid(card, ca(WHITE, rr))
	edge(card, ca(GREY.darkened(0.3), rr), 1.8, s, rr, 0.4)
	if rr < 1.0:
		return
	var pts := PackedVector2Array([p + Vector2(w * 0.12, w * 0.18), p + Vector2(w * 0.35, w * 0.38), p + Vector2(w * 0.52, w * 0.3), p + Vector2(w * 0.86, w * 0.7)])
	path(pts, RED, 3.4, s + 1)
	ln(p + Vector2(w * 0.86, w * 0.7), p + Vector2(w * 0.7, w * 0.68), RED, 3.0, s + 5, 1.0, 0.3)
	ln(p + Vector2(w * 0.86, w * 0.7), p + Vector2(w * 0.84, w * 0.54), RED, 3.0, s + 6, 1.0, 0.3)


func jb_bill(c: Vector2, w: float, rot: float, s: int, a := 1.0, wings := false) -> void:
	if a <= 0.01:
		return
	var T := func(v: Vector2) -> Vector2: return c + v.rotated(rot)
	var b := PackedVector2Array([T.call(Vector2(-w * 0.5, -w * 0.24)), T.call(Vector2(w * 0.5, -w * 0.24)), T.call(Vector2(w * 0.5, w * 0.24)), T.call(Vector2(-w * 0.5, w * 0.24))])
	if wings:
		var flap := sin(t * 10.0 + s) * w * 0.12
		for sd: float in [-1.0, 1.0]:
			var wg := C.ellipse_poly(T.call(Vector2(sd * w * 0.32, -w * 0.32 - flap)), w * 0.26, w * 0.12, 10, s + int(sd), 0.06, rot + sd * 0.5)
			solid(wg, ca(WHITE, a))
			edge(wg, ca(INK, a), 1.4, s + 2 + int(sd), 1.0, 0.3)
	solid(b, ca(CASH, a))
	edge(b, ca(CASH_DARK, a), 2.0, s + 4, 1.0, 0.4)
	solid(circ(c, w * 0.15, s + 5, 10), ca(CASH.lightened(0.3), a))
	txt_c("$", c.x, c.y + w * 0.1, int(w * 0.24), ca(CASH_DARK, a), s + 6, 1)


func jb_bag(c: Vector2, r: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var sack := PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.75), c + Vector2(r * 0.3, -r * 0.75), c + Vector2(r * 0.85, r * 0.2), c + Vector2(r * 0.7, r * 0.8), c + Vector2(-r * 0.7, r * 0.8), c + Vector2(-r * 0.85, r * 0.2)])
	solid(sack, ca(TAN, rr))
	fill(sack, TAN.darkened(0.15), s, rr, 3.4, -0.5, 3.0)
	edge(sack, INK, 2.4, s + 1, rr)
	if rr >= 1.0:
		ln(c + Vector2(-r * 0.4, -r * 0.6), c + Vector2(r * 0.4, -r * 0.6), BROWN, 4.0, s + 2, 1.0, 0.3)
		txt_c("$", c.x, c.y + r * 0.45, int(r * 0.85), CASH_DARK, s + 3, 2)


func jb_tv(r: Rect2, s: int, rr: float) -> Rect2:
	var scr := r.grow_individual(-r.size.x * 0.07, -r.size.y * 0.09, -r.size.x * 0.2, -r.size.y * 0.09)
	if rr <= 0.0:
		return scr
	var ah := minf(r.size.y * 0.3, 30.0)
	ln(r.position + Vector2(r.size.x * 0.45, 0), r.position + Vector2(r.size.x * 0.45 - ah * 0.6, -ah), INK, 2.4, s, rr, 0.4)
	ln(r.position + Vector2(r.size.x * 0.45, 0), r.position + Vector2(r.size.x * 0.45 + ah * 0.6, -ah * 1.05), INK, 2.4, s + 1, rr, 0.4)
	var body := C.rect_poly(r)
	solid(body, ca(Color("#b07a44"), rr))
	fill(body, Color("#8a5a2b"), s + 2, rr, 4.0, 0.6, 3.2)
	edge(body, INK, 2.8, s + 3, rr)
	if rr >= 1.0:
		solid(C.rect_poly(scr), Color("#22305a"))
		edge(C.rect_poly(scr), INK, 2.2, s + 4, 1.0, 0.5)
		for k in 2:
			var kc := Vector2(r.end.x - r.size.x * 0.1, r.position.y + r.size.y * (0.3 + k * 0.3))
			solid(circ(kc, r.size.x * 0.035, s + 5 + k, 10), INK)
	return scr


func jb_mini_tower(base: Vector2, w: float, h: float, s: int, rr := 1.0, dark := 0.0) -> void:
	if rr <= 0.0:
		return
	var body := C.rect_poly(Rect2(base + Vector2(-w * 0.5, -h), Vector2(w, h)))
	solid(body, ca(TOWER.lightened(0.3), rr))
	fill(body, TOWER, s, rr, 3.6, -0.5, 3.0)
	edge(body, INK, 2.2, s + 1, rr, 0.6)
	if rr < 1.0:
		return
	var cols := 3
	var rows := maxi(2, int(h / (w * 0.32)))
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var lit := C.rnd(s + 7, idx) >= dark
			var wc := base + Vector2(-w * 0.32 + c * w * 0.32, -h + w * 0.2 + r * (h - w * 0.4) / rows)
			solid(C.rect_poly(Rect2(wc - Vector2(w * 0.09, w * 0.08), Vector2(w * 0.18, w * 0.16))), SUN if lit else Color("#3b3f52"))


func jb_phone(c: Vector2, sz: float, s: int, rr: float, ring := false) -> void:
	if rr <= 0.0:
		return
	var base := PackedVector2Array([c + Vector2(-sz * 0.55, -sz * 0.1), c + Vector2(sz * 0.55, -sz * 0.1), c + Vector2(sz * 0.7, sz * 0.5), c + Vector2(-sz * 0.7, sz * 0.5)])
	solid(base, ca(RED, rr))
	fill(base, RED.darkened(0.15), s, rr, 3.4, -0.5, 3.0)
	edge(base, INK, 2.4, s + 1, rr)
	var hs := arc(c + Vector2(0, -sz * 0.1), sz * 0.6, sz * 0.32, PI, TAU, 10)
	path(hs, ca(RED.darkened(0.25), rr), sz * 0.16, s + 2, rr)
	if rr >= 1.0:
		for sd: float in [-1.0, 1.0]:
			solid(oval(c + Vector2(sd * sz * 0.6, -sz * 0.12), sz * 0.16, sz * 0.1, s + 3 + int(sd), 10), RED.darkened(0.25))
		solid(circ(c + Vector2(0, sz * 0.22), sz * 0.22, s + 5, 14), WHITE)
		for k in 8:
			var a := TAU * k / 8.0
			draw_circle(c + Vector2(0, sz * 0.22) + Vector2(cos(a), sin(a)) * sz * 0.14, 2.2, INK)
		if ring and fmod(t * 3.0, 1.0) < 0.6:
			for sd2: float in [-1.0, 1.0]:
				for k2 in 2:
					var rad := sz * (0.95 + k2 * 0.22)
					path(arc(c, rad, rad, (-0.5 if sd2 > 0.0 else PI - 0.5), (0.5 if sd2 > 0.0 else PI + 0.5), 6), INK, 3.0, s + 10 + k2 + int(sd2) * 3)


func jb_jag(c: Vector2, text: String, size: int, col: Color, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var tw := C.letters_width(text, size)
	var rx := (tw * 0.5 + 30.0) * (0.6 + 0.4 * rr)
	var ry := (size * 0.9 + 20.0) * (0.6 + 0.4 * rr)
	var pts := PackedVector2Array()
	for k in 22:
		var a := TAU * k / 22.0
		var m := 1.0 if k % 2 == 0 else 0.8
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry) * m)
	solid(pts, WHITE)
	edge(pts, col, 3.0, s, 1.0, 0.6)
	if rr >= 1.0:
		txt_c(text, c.x, c.y + size * 0.5, size, col, s + 1, 2)


func jb_tree(base: Vector2, h: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var trunk := C.rect_poly(Rect2(base + Vector2(-h * 0.06, -h * 0.12), Vector2(h * 0.12, h * 0.12)))
	solid(trunk, BROWN)
	for k in 3:
		var top := base.y - h * (0.42 + k * 0.24)
		var w := h * (0.36 - k * 0.08)
		var tri := PackedVector2Array([Vector2(base.x - w, top + h * 0.32), Vector2(base.x, top), Vector2(base.x + w, top + h * 0.32)])
		fill(tri, GRASS_DARK, s + k, rr, 3.6, 0.5, 3.6)
		edge(tri, INK, 2.2, s + 3 + k, rr, 0.6)
	if rr >= 1.0:
		var orn: Array[Color] = [RED, SKY, SUN, PINK, PURPLE]
		for k2 in 9:
			var oy := base.y - h * (0.2 + C.rnd(s, k2) * 0.62)
			var spread := (base.y - oy) / h
			var ox := base.x + (C.rnd(s + 1, k2) - 0.5) * h * 0.5 * (1.0 - spread * 0.9)
			draw_circle(Vector2(ox, oy), h * 0.025, orn[k2 % orn.size()])
		star(Vector2(base.x, base.y - h * 0.95), h * 0.07, SUN, s + 20)


func jb_present(c: Vector2, sz: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var box := C.rect_poly(Rect2(c - Vector2(sz * 0.5, sz * 0.4), Vector2(sz, sz * 0.8)))
	solid(box, ca(PINK, rr))
	fill(box, PINK.darkened(0.12), s, rr, 3.4, -0.5, 3.0)
	edge(box, INK, 2.2, s + 1, rr)
	if rr < 1.0:
		return
	ln(c + Vector2(0, -sz * 0.4), c + Vector2(0, sz * 0.4), SUN, sz * 0.12, s + 2, 1.0, 0.3)
	ln(c + Vector2(-sz * 0.5, 0), c + Vector2(sz * 0.5, 0), SUN, sz * 0.12, s + 3, 1.0, 0.3)
	for sd: float in [-1.0, 1.0]:
		solid(C.ellipse_poly(c + Vector2(sd * sz * 0.16, -sz * 0.5), sz * 0.16, sz * 0.09, 10, s + 4 + int(sd), 0.05, sd * 0.4), SUN)
	var tag := PackedVector2Array([c + Vector2(sz * 0.55, -sz * 0.28), c + Vector2(sz * 1.75, -sz * 0.34), c + Vector2(sz * 1.78, sz * 0.12), c + Vector2(sz * 0.58, sz * 0.16)])
	ln(c + Vector2(sz * 0.3, -sz * 0.3), c + Vector2(sz * 0.58, -sz * 0.1), INK, 1.6, s + 6, 1.0, 0.3)
	solid(tag, WHITE)
	edge(tag, INK, 1.8, s + 7, 1.0, 0.4)
	txt("TO DADDY", c + Vector2(sz * 0.66, sz * 0.02), int(sz * 0.22), PURPLE, s + 8, 2)


func jb_footprint(c: Vector2, ang: float, sz: float, s: int, a := 1.0) -> void:
	if a <= 0.01:
		return
	solid(C.ellipse_poly(c, sz * 0.3, sz * 0.5, 12, s, 0.06, ang), ca(INK, a))
	for k in 5:
		var off := Vector2(-sz * 0.24 + k * sz * 0.12, -sz * (0.66 + 0.06 * (2 - absi(k - 1)))).rotated(ang)
		draw_circle(c + off, sz * (0.09 if k > 0 else 0.11), ca(INK, a))


# ================================================================== page 0: the name
func jb_p0() -> void:
	txt_c("THE VALENTINE'S DAY MASS SHOOTING", 800.0, 104.0, 54, RED, 9001, 3, rv(0.15, 1.6))
	txt_c("FEBRUARY 14TH, 1999", 800.0, 162.0, 32, INK, 9002, 2, rv(1.7, 0.9))
	var hp: Array = [Vector2(90, 90), Vector2(1510, 90), Vector2(110, 300), Vector2(1490, 300)]
	for k in hp.size():
		heart(hp[k], 24.0, PINK if k % 2 == 0 else PURPLE, 9003 + k * 3, rv(2.4 + k * 0.1, 0.3))
	grass_strip(700.0, 9010, rv(0.4, 0.8))
	var foot := Vector2(800, 712)
	var h := 430.0
	jb_jeremy(foot, h, rv(cs(1) - 0.6, 1.2), "frown")
	var hc := foot + Vector2(0, -h + h * 0.165)
	var r := h * 0.165
	var ra := rv(wt(1, "JEREMY") - 0.3, 0.5)
	if ra > 0.0:
		path(PackedVector2Array([Vector2(1050, 352), Vector2(960, 320), Vector2(890, 300)]), INK, 4.0, 9020, ra)
		if ra >= 1.0:
			ln(Vector2(890, 300), Vector2(914, 288), INK, 4.0, 9021)
			ln(Vector2(890, 300), Vector2(910, 322), INK, 4.0, 9022)
	txt("JEREMY BERRY", Vector2(1062, 370), 50, INK, 9023, 3, rv(wt(1, "JEREMY"), 0.8))
	jb_berry(Vector2(1460, 292), 30.0, 9024, rv(wt(1, "BERRY") + 0.4, 0.5))
	# the silly name: a party hat, scribbled off when he turns out to be serious
	var rh := rv(wt(3, "SILLY") - 0.1, 0.4)
	var gone := rv(wt(4, "SERIOUS"), 0.5)
	if rh > 0.0 and t < cs(5):
		var a := 1.0 - rv(cs(4) + 1.4, 0.6)
		var top := hc + Vector2(r * 0.15, -r * 2.6)
		var hat := PackedVector2Array([hc + Vector2(-r * 0.6, -r * 0.82), top, hc + Vector2(r * 0.7, -r * 0.78)])
		solid(hat, ca(PINK, a * rh))
		for k2 in 3:
			var f := 0.25 + k2 * 0.22
			ln(hat[0].lerp(top, f), hat[2].lerp(top, f), ca(SUN, a), 6.0, 9030 + k2, rh, 0.4)
		edge(hat, ca(INK, a), 2.4, 9033, rh)
		solid(circ(top, r * 0.16, 9034, 10), ca(SKY, a * rh))
		if gone > 0.0:
			var pts := PackedVector2Array()
			for j in int(24 * gone) + 1:
				var ang := j * 2.4
				pts.append(hc + Vector2(r * 0.1, -r * 1.6) + Vector2(cos(ang) * r * 0.7, sin(ang) * r * 0.9) + Vector2(C.jit(9035, j), C.jit(9036, j)) * 4.0)
			if pts.size() >= 2:
				draw_polyline(pts, ca(GREY.darkened(0.45), a), 6.0, true)
	# serious as a cough
	var rc := rv(wt(5, "COUGH") - 0.1, 0.4)
	if rc > 0.0 and t < ce(5) + 0.3:
		for k3 in 3:
			var ph := fmod((t - wt(5, "COUGH")) * 0.8 + k3 * 0.25, 1.0)
			var pc := hc + Vector2(r * 1.2 + ph * r * 1.6 + k3 * r * 0.3, r * 0.4 - ph * r * 0.5)
			var puff := circ(pc, r * (0.22 + ph * 0.18), 9040 + k3, 12)
			solid(puff, ca(GREY.lightened(0.3), 0.8 * (1.0 - ph) * rc))
			edge(puff, ca(GREY.darkened(0.2), 0.8 * (1.0 - ph) * rc), 2.0, 9043 + k3, 1.0, 0.5)


# ================================================================== page 1: graves and flowers
func jb_p1() -> void:
	var t0 := cs(6)
	var kinds := [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0]
	for k in 13:
		var x := 92.0 + k * 118.0
		jb_tomb(Vector2(x, 300), 76.0, 118.0, 9100 + k * 5, rv(t0 + 0.05 + k * 0.08, 0.3))
		jb_bloom(Vector2(x, 420), 30.0, int(kinds[k]), 9200 + k * 41, rv(t0 + 1.4 + k * 0.08, 0.3))
		jb_tomb(Vector2(x, 700), 76.0, 118.0, 9500 + k * 5, rv(t0 + 2.7 + k * 0.08, 0.3))


# ================================================================== page 2: no friends, some money
func jb_p2() -> void:
	var t0 := cs(7)
	grass_strip(690.0, 9600, rv(t0 - 0.3, 0.7))
	var folks: Array = [
		{"id": "F1", "foot": Vector2(230, 700), "h": 290.0, "s": 9610, "suit": PURPLE, "skin": Color("#8d5a3b"), "hair": "curly", "hair_col": INK, "plain": true},
		{"id": "F2", "foot": Vector2(430, 700), "h": 270.0, "s": 9640, "suit": SKY, "skin": SKIN, "hair": "bob", "hair_col": GOLD, "plain": true},
		{"id": "F3", "foot": Vector2(1170, 700), "h": 300.0, "s": 9670, "suit": GRASS_DARK, "skin": Color("#c98a5e"), "hair": "short", "hair_col": INK, "mustache": true, "plain": true},
		{"id": "F4", "foot": Vector2(1370, 700), "h": 280.0, "s": 9700, "suit": ORANGE, "skin": Color("#f1c7a3"), "hair": "ponytail", "hair_col": BROWN, "plain": true},
	]
	for k in folks.size():
		_reporter(folks[k], rv(t0 + 0.2 + k * 0.15, 0.8), "frown", 0.0)
	jb_jeremy(Vector2(800, 700), 360.0, rv(t0 - 0.2, 1.0), "frown")
	# my friends: (nobody)
	var rf := rv(wt(9, "FRIENDS") - 0.2, 0.6)
	if rf > 0.0:
		var note := PackedVector2Array([Vector2(1180, 60), Vector2(1500, 52), Vector2(1506, 250), Vector2(1186, 258)])
		solid(note, ca(WHITE, rf))
		edge(note, INK, 2.2, 9720, rf)
		if rf >= 1.0:
			txt("MY FRIENDS", Vector2(1210, 110), 32, PURPLE, 9721, 2)
			for k2 in 3:
				ln(Vector2(1210, 150 + k2 * 34), Vector2(1470, 148 + k2 * 34), Color("#a9d4ff"), 2.0, 9722 + k2, 1.0, 0.3)
			txt("1.", Vector2(1212, 176), 24, INK, 9726, 1)
	# money: a bag in his hand, and the building behind him
	jb_bag(Vector2(905, 600), 38.0, 9730, rv(wt(10, "MONEY"), 0.4))
	var rb := rv(wt(10, "EASTSIDE") - 0.1, 0.7)
	jb_mini_tower(Vector2(250, 300), 150.0, 240.0, 9740, rb)
	txt_c("EASTSIDE", 250.0, 340.0, 26, NAVY, 9741, 2, rv(wt(10, "EASTSIDE") + 0.4, 0.5))


# ================================================================== page 3: the map
func jb_p3() -> void:
	var t0 := cs(11)
	var rm := rv(t0 - 0.3, 1.4)
	var nw := C.rect_poly(Rect2(60, 50, 820, 330))
	fill(nw, LILAC.lightened(0.2), 9800, rm, 4.6, -0.4, 4.0)
	edge(nw, INK, 2.4, 9801, rm)
	var so := C.rect_poly(Rect2(60, 420, 820, 270))
	fill(so, ORANGE.lightened(0.35), 9802, rm, 4.6, -0.4, 4.0)
	edge(so, INK, 2.4, 9803, rm)
	var ea := C.rect_poly(Rect2(1060, 50, 480, 640))
	fill(ea, SKY.lightened(0.4), 9804, rm, 4.6, -0.4, 4.0)
	edge(ea, INK, 2.4, 9805, rm)
	var river := C.rect_poly(Rect2(920, -10, 110, 710))
	fill(river, RIVER, 9806, rm, 4.0, -1.3, 4.4)
	var rr := rv(t0 + 0.4, 0.8)
	bridge(890.0, 1060.0, 420.0, 34.0, PINK, 9807, rr, 1.0, 0.5)
	if rm >= 1.0:
		var hc: Array[Color] = [RED, SUN, GRASS, PINK, SKY, PURPLE]
		for k in 6:
			house(110.0 + k * 125.0, 330.0, 74.0, 60.0, hc[k], BROWN, 9810 + k * 20, 1.0)
			house(130.0 + k * 120.0, 660.0, 70.0, 58.0, hc[(k + 3) % 6], RED, 9940 + k * 20, 1.0)
		for k2 in 3:
			if k2 == 1:
				continue
			jb_mini_tower(Vector2(1150 + k2 * 150, 420), 110.0, 230.0, 10080 + k2 * 10, 1.0)
		ln(Vector2(1060, 560), Vector2(1540, 560), GREY.darkened(0.2), 14.0, 10120, 1.0, 0.6)
		txt("PAISLEY AVE", Vector2(1080, 610), 26, INK, 10121, 2)
		var rt := rv(t0 + 0.3, 0.6)
		jb_mini_tower(Vector2(1300, 545), 130.0, 330.0, 10122, rt, 0.0)
		star(Vector2(1300, 190), 26.0, GOLD, 10123, rt)
		# the compass
		ln(Vector2(900, 330), Vector2(900, 250), INK, 3.0, 10124, 1.0, 0.4)
		ln(Vector2(900, 250), Vector2(888, 270), INK, 3.0, 10125, 1.0, 0.3)
		ln(Vector2(900, 250), Vector2(912, 270), INK, 3.0, 10126, 1.0, 0.3)
	txt_c("NORTH WEST", 470.0, 100.0, 32, PURPLE.darkened(0.2), 10130, 2, rv(wt(12, "NORTH"), 0.6))
	txt_c("SOUTH", 470.0, 472.0, 32, ORANGE.darkened(0.3), 10131, 2, rv(wt(12, "SOUTH"), 0.5))
	txt_c("EAST", 1300.0, 100.0, 32, NAVY, 10132, 2, rv(wt(13, "EAST"), 0.5))
	var rh := rv(wt(11, "HIGH"), 0.4)
	if rh > 0.0:
		txt("$", Vector2(1395, 300), 54, CASH_DARK, 10133, 3, rh)
		txt("!", Vector2(1440, 300), 54, RED, 10134, 3, rv(wt(11, "RISK"), 0.3))
		txt("$", Vector2(1470, 300), 54, CASH_DARK, 10135, 3, rv(wt(11, "REWARD"), 0.3))
	# the families in the area
	var rf := rv(cs(14) + 0.6, 0.6)
	if rf > 0.0:
		var kinds := ["mommy", "boy", "old", "mommy", "boy"]
		for k3 in 5:
			stick(Vector2(1110 + k3 * 46 + (k3 / 3) * 230, 690), 74.0, String(kinds[k3]), 10140 + k3 * 30, rf, 1.0, Vector2.ZERO, Vector2.ZERO, 2.2)
	# Jeremy, open to settling: a vacancy sign
	var rj := rv(cs(17) + 0.4, 0.6)
	if rj > 0.0:
		var sg := C.rect_poly(Rect2(1370, 470, 150, 44))
		solid(sg, ca(WHITE, rj))
		edge(sg, RED, 2.4, 10300, rj)
		txt_c("VACANCY", 1445.0, 502.0, 22, RED, 10301, 2, rj)


# ================================================================== page 4: simpler than that
func jb_p4() -> void:
	var t0 := cs(18)
	jb_jeremy(Vector2(210, 700), 300.0, rv(t0 - 0.2, 0.9), "frown")
	var cols: Array[Color] = [Color("#f6d7c3"), Color("#e8bb94"), Color("#ffcc33"), Color("#c68c5c"), Color("#94603c"), Color("#5c3b26")]
	var ups := [true, true, false, false, false, false]
	for k in 6:
		jb_thumb(Vector2(470 + k * 200, 300), 130.0, cols[k], bool(ups[k]), 10400 + k * 13, rv(wt(19, "SIMPLER") + k * 0.42, 0.35))
	# the bridge backs up: her bridge, cars bunching on it
	var rb := rv(wt(22, "BRIDGE") - 0.4, 0.9)
	if rb > 0.0:
		var slide := (1.0 - _ease(rb)) * 400.0
		var river := C.rect_poly(Rect2(520 + slide, 600, 1100, 110))
		fill(river, ca(RIVER, 0.9), 10500, rb, 3.6, -0.15, 4.0)
		bridge(560.0 + slide, 1560.0 + slide, 600.0, 110.0, PINK, 10501, rb, 1.0, 1.0)
		var bunch := _ease(rv(wt(22, "BACKS"), 2.2))
		var cc: Array[Color] = [RED, SUN, SKY, GRASS, ORANGE, PURPLE, NAVY]
		for k2 in 7:
			var x := lerpf(640.0 + k2 * 140.0, 900.0 + k2 * 70.0, bunch) + slide
			car(Vector2(x, 584), 66.0, cc[k2], 10510 + k2 * 11, 0.0, rb)


# ================================================================== page 5: the internet
func jb_p5() -> void:
	var t0 := cs(23)
	var rm := rv(t0 - 0.3, 1.0)
	var body := C.rect_poly(Rect2(540, 110, 520, 400))
	solid(body, ca(BEIGE, rm))
	fill(body, BEIGE.darkened(0.12), 10600, rm, 4.0, -0.5, 3.4)
	edge(body, INK, 3.0, 10601, rm)
	var stand := PackedVector2Array([Vector2(740, 510), Vector2(860, 510), Vector2(900, 560), Vector2(700, 560)])
	fill(stand, BEIGE.darkened(0.2), 10602, rm, 3.4, 0.4, 3.0)
	edge(stand, INK, 2.4, 10603, rm)
	var kb := C.rect_poly(Rect2(520, 590, 560, 90))
	fill(kb, BEIGE.darkened(0.08), 10604, rm, 3.6, -0.3, 3.2)
	edge(kb, INK, 2.4, 10605, rm)
	if rm >= 1.0:
		for kx in 12:
			for ky in 3:
				solid(C.rect_poly(Rect2(540 + kx * 44, 602 + ky * 24, 34, 16)), BEIGE.darkened(0.3))
		var scr := C.rect_poly(Rect2(580, 150, 440, 310))
		solid(scr, Color("#2a62d9"))
		edge(scr, INK, 2.4, 10606)
		txt("WWW", Vector2(600, 196), 30, WHITE, 10607, 2)
		var rs := rv(wt(24, "WORD") - 0.2, 0.8)
		jb_no(Vector2(680, 340), 58.0, 10610, rs)
		jb_no(Vector2(920, 340), 58.0, 10611, rv(wt(24, "WORD") + 0.2, 0.6))
		var sf := Vector2(800, 430)
		stick(sf, 150.0, "boy", 10612, rv(wt(24, "WORD") + 0.1, 0.6), 1.0, sf + Vector2(-62, -120), sf + Vector2(62, -120), 2.6)
	var shouts: Array = [["SHAME!", Vector2(290, 170)], ["#$%!", Vector2(1330, 170)], ["BOO!", Vector2(250, 440)], ["RACIST", Vector2(1340, 430)], ["NEVER RENT HERE", Vector2(1300, 640)], ["MOVE OUT!", Vector2(290, 640)]]
	for k in shouts.size():
		var sh: Array = shouts[k]
		jb_jag(sh[1], String(sh[0]), 30, RED, 10620 + k * 5, rv(wt(25, "ATTENTION") + k * 0.35, 0.18))


# ================================================================== page 6: the empty rooms
func jb_p6() -> void:
	var t0 := cs(26)
	sky_strip(150.0, SKY, 10700, rv(t0 - 0.3, 0.6))
	grass_strip(700.0, 10701, rv(t0 - 0.2, 0.6))
	var rt := rv(t0 - 0.1, 1.0)
	var tw := C.rect_poly(Rect2(600, 90, 400, 610))
	solid(tw, ca(TOWER.lightened(0.3), rt))
	fill(tw, TOWER, 10702, rt, 4.0, -0.5, 4.0)
	edge(tw, INK, 3.0, 10703, rt)
	var sg := C.rect_poly(Rect2(620, 40, 360, 56))
	solid(sg, ca(WHITE, rt))
	edge(sg, TOWER_TRIM, 3.0, 10704, rt)
	txt_c("PAISLEY TOWER", 800.0, 82.0, 34, TOWER_TRIM, 10705, 2, rt)
	if rt >= 1.0:
		var gone := int(rv(t0 + 0.6, 3.0) * 4.0) + int(rv(cs(27), ce(27) - cs(27) - 0.3) * 32.0)
		for r in 8:
			for c in 5:
				var idx := r * 5 + c
				var rank := 0
				for j in 40:
					if C.rnd(10710, j) < C.rnd(10710, idx):
						rank += 1
				var lit := rank >= gone
				var wr := C.rect_poly(Rect2(626 + c * 74, 122 + r * 62, 52, 42))
				solid(wr, SUN if lit else Color("#3b3f52"))
				edge(wr, INK, 1.6, 10720 + idx, 1.0, 0.3)
		var door := C.rect_poly(Rect2(762, 620, 76, 80))
		solid(door, BROWN)
		edge(door, INK, 2.0, 10790)
	# tenants leaving with their bags
	var kinds := ["mommy", "boy", "old", "mommy", "boy", "old", "mommy"]
	for k in kinds.size():
		var tk := t0 + 0.4 + k * 1.3
		if t < tk:
			continue
		var x := 840.0 + (t - tk) * 150.0
		if x > 1660.0:
			continue
		var f := Vector2(x, 712 + sin((t - tk) * 9.0) * 2.0)
		var hand := f + Vector2(36, -60)
		stick(f, 120.0, String(kinds[k]), 10800 + k * 30, 1.0, 1.0, Vector2.ZERO, hand, 2.4)
		var case := C.rect_poly(Rect2(hand + Vector2(-14, 2), Vector2(32, 24)))
		solid(case, [RED, SKY, SUN, GRASS][k % 4])
		edge(case, INK, 1.6, 10810 + k, 1.0, 0.3)
	# the savings, burning
	var rp := rv(wt(28, "SAVINGS") - 0.3, 0.6)
	if rp > 0.0:
		_piggy(Vector2(300, 600), 70.0, 10900, rp)
		_flames(Vector2(300, 650), 66.0, 10910, rv(wt(28, "BURNING"), 0.6))


# ================================================================== page 7: a couple little loans
func jb_row_word(parts: Array, pos: Vector2, size: int, s: int, r: float) -> float:
	var x := pos.x
	for i in parts.size():
		var p := String(parts[i])
		if p == "@FACE":
			jb_face(Vector2(x + size * 0.5, pos.y - size * 0.5), size * 0.48, "money", s + i, r)
			x += size * 1.05
		elif p == "@BAG":
			jb_bag(Vector2(x + size * 0.5, pos.y - size * 0.45), size * 0.5, s + i, r)
			x += size * 1.05
		else:
			txt(p, Vector2(x, pos.y), size, INK, s + i * 7, 3, r)
			x += C.letters_width(p, size) + size * 0.1
	return x


func jb_p7() -> void:
	var T := cs(29)
	var rows: Array = [[["C", "@FACE", "UPLE"], 0, 1], [[], 220, 2], [["LITTLE"], 0, 3], [[], 200, 4], [["L", "@BAG", "ANS"], 0, 5], [[], 220, 6], [[], 0, 9]]
	var size := 50
	for k in rows.size():
		var row: Array = rows[k]
		var y := 96.0 + k * 66.0
		var x := 470.0
		var r := rv(T + k * 0.42, 0.4)
		if r <= 0.0:
			continue
		var parts: Array = row[0]
		if not parts.is_empty():
			x = jb_row_word(parts, Vector2(x, y), size, 11000 + k * 31, r) + 20.0
		elif int(row[1]) > 0:
			ln(Vector2(x, y - 22), Vector2(x + float(row[1]), y - 22), INK, 4.0, 11100 + k, r, 0.6)
			x += float(row[1]) + 20.0
		for c in int(row[2]):
			jb_chart(Vector2(x + c * 66.0, y - 46.0), 56.0, 11200 + k * 17 + c, rv(T + k * 0.42 + 0.15 + c * 0.05, 0.2))
	# the bills, then the money slipping away
	var tb := T + rows.size() * 0.42 + 0.2
	var tf := T + 4.2
	for c2 in 9:
		var x0 := 450.0 + c2 * 88.0
		var p0 := Vector2(x0, 560)
		if t < tf:
			jb_bill(p0, 74.0, 0.0, 11300 + c2 * 7, rv(tb + c2 * 0.06, 0.2))
			continue
		var k3 := clampf((t - tf - c2 * 0.12) / 3.4, 0.0, 1.0)
		if c2 == 4:
			var land := Vector2(800, 790)
			var pp := p0.lerp(land, _ease(k3)) + Vector2(sin(k3 * 12.0) * 30.0 * (1.0 - k3), 0)
			jb_bill(pp, 74.0 - 16.0 * k3, sin(k3 * 9.0) * 0.4 * (1.0 - k3), 11300 + c2 * 7, 1.0, k3 < 0.95)
		else:
			var out := (x0 - 800.0) * 1.3
			var pp2 := p0 + Vector2(out * k3 + sin(k3 * 10.0 + c2) * 40.0, k3 * 520.0 - sin(k3 * PI) * 80.0)
			jb_bill(pp2, 74.0 - 20.0 * k3, sin(k3 * 8.0 + c2) * 0.6, 11300 + c2 * 7, 1.0 - k3 * k3, true)
	# the hands
	var rhd := rv(tf + 0.4, 0.6)
	if rhd > 0.0:
		for sd: float in [-1.0, 1.0]:
			var palm := C.ellipse_poly(Vector2(800 + sd * 54, 840), 66.0, 40.0, 14, 11400 + int(sd), 0.05, sd * 0.25)
			solid(palm, ca(Color("#f6d7c3"), rhd))
			fill(palm, Color("#e8bb94"), 11402 + int(sd), rhd, 3.6, -0.5, 2.6)
			edge(palm, INK, 2.4, 11404 + int(sd), rhd)
			if rhd >= 1.0:
				for f in 4:
					var fx := 800.0 + sd * (20.0 + f * 24.0)
					ln(Vector2(fx, 812), Vector2(fx + sd * 4.0, 790), INK, 2.0, 11410 + f + int(sd) * 5, 1.0, 0.3)


# ================================================================== page 8: the rebrand on TV
func jb_p8() -> void:
	var T := cs(30)
	for k in 7:
		var r := Rect2(70 + k * 212, 40, 170, 110)
		var rr := rv(T - 0.3 + k * 0.08, 0.3)
		var scr := jb_tv(r, 11500 + k * 9, rr)
		if rr >= 1.0:
			solid(C.rect_poly(scr), SKY.lightened(0.3))
			jb_mini_tower(Vector2(scr.get_center().x, scr.end.y - 4), 30.0, 62.0, 11570 + k, 1.0)
			for q in 5:
				var qc: Array[Color] = [PINK, SUN, GRASS, RED, PURPLE]
				var qp := scr.position + Vector2(C.rnd(11580 + k, q + C.frame) * scr.size.x, C.rnd(11590 + k, q + C.frame) * scr.size.y)
				draw_circle(qp, 3.0, qc[q])
	ln(Vector2(60, 178), Vector2(1540, 178), INK, 3.0, 11600, rv(T, 0.6), 0.8)
	# the big set
	var rb := rv(T - 0.1, 0.9)
	var scr2 := jb_tv(Rect2(340, 210, 920, 490), 11610, rb)
	if rb < 1.0:
		return
	solid(C.rect_poly(scr2), SKY.lightened(0.35))
	var conf: Array[Color] = [PINK, SUN, GRASS, RED, PURPLE, ORANGE]
	for q2 in 40:
		var ph := fmod(t * 0.25 + C.rnd(11620, q2), 1.0)
		var cp := scr2.position + Vector2(C.rnd(11621, q2) * scr2.size.x, ph * scr2.size.y)
		draw_line(cp, cp + Vector2(6, 8).rotated(t * 3.0 + q2), conf[q2 % conf.size()], 4.0, true)
	jb_mini_tower(Vector2(scr2.get_center().x, scr2.end.y - 10), 150.0, 330.0, 11630, 1.0)
	for sd: float in [-1.0, 1.0]:
		jb_face(Vector2(scr2.get_center().x + sd * 270, scr2.end.y - 120), 62.0, "grin", 11640 + int(sd), 1.0)
	# 'rebranding': the handshake
	var rh := rv(cs(30) + 0.3, 0.5) * (1.0 - rv(cs(32) - 0.3, 0.4))
	if rh > 0.0:
		var hc := Vector2(scr2.get_center().x, scr2.get_center().y + 30)
		ln(hc + Vector2(-230, 30), hc + Vector2(-40, 0), ca(NAVY, rh), 34.0, 11650, 1.0, 0.4)
		ln(hc + Vector2(230, 30), hc + Vector2(40, 0), ca(GREY, rh), 34.0, 11651, 1.0, 0.4)
		solid(C.ellipse_poly(hc + Vector2(-20, -2), 50.0, 30.0, 14, 11652, 0.05, 0.2), ca(Color("#5c3b26"), rh))
		solid(C.ellipse_poly(hc + Vector2(20, 6), 50.0, 28.0, 14, 11653, 0.05, -0.2), ca(Color("#f6d7c3"), rh))
		edge(C.ellipse_poly(hc + Vector2(20, 6), 50.0, 28.0, 14, 11654, 0.05, -0.2), ca(INK, rh), 2.2, 11655, 1.0, 0.4)
		for k2 in 4:
			ln(hc + Vector2(-6 + k2 * 12, -8), hc + Vector2(-2 + k2 * 12, 22), ca(INK, rh), 1.8, 11656 + k2, 1.0, 0.3)
		txt_c("'NEW!'", hc.x, hc.y + 120.0, 48, ca(RED, rh), 11660, 3)
	# June to December, across the top of the set
	var rmo := rv(wt(31, "JUNE") - 0.2, 0.4) * (1.0 - rv(cs(32) - 0.3, 0.4))
	if rmo > 0.0:
		var months := ["JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
		var on := int(clampf((t - wt(31, "JUNE")) / 1.8, 0.0, 1.0) * 7.0)
		for m in 7:
			var mx := scr2.position.x + 40.0 + m * 104.0
			var box := C.rect_poly(Rect2(mx, scr2.position.y + 20, 92, 46))
			solid(box, ca(SUN if m < on else WHITE, rmo))
			edge(box, ca(INK, rmo), 1.8, 11670 + m, 1.0, 0.3)
			txt_c(String(months[m]), mx + 46.0, scr2.position.y + 56.0, 24, ca(INK, rmo), 11680 + m, 2)
	# grand re-opening; better; more modern
	var rg := rv(cs(32) + 0.1, 0.5)
	if rg > 0.0:
		var rib := PackedVector2Array([scr2.position + Vector2(60, 20), scr2.position + Vector2(scr2.size.x - 60, 20), scr2.position + Vector2(scr2.size.x - 90, 50), scr2.position + Vector2(scr2.size.x - 60, 80), scr2.position + Vector2(60, 80), scr2.position + Vector2(90, 50)])
		solid(rib, ca(RED, rg))
		edge(rib, INK, 2.4, 11690, rg)
		txt_c("GRAND RE-OPENING!", scr2.get_center().x, scr2.position.y + 66.0, 36, WHITE, 11691, 2, rg)
	var rbt := rv(wt(33, "BETTER"), 0.3)
	if rbt > 0.0:
		var bc := Vector2(scr2.end.x - 150, scr2.position.y + 200)
		var burst := PackedVector2Array()
		for j in 24:
			var rad := (110.0 if j % 2 == 0 else 76.0) * (0.6 + 0.4 * rbt)
			burst.append(bc + Vector2(cos(TAU * j / 24.0), sin(TAU * j / 24.0)) * rad)
		solid(burst, SUN)
		edge(burst, RED, 3.0, 11692, 1.0, 0.6)
		txt_c("BETTER!", bc.x, bc.y + 14.0, 34, RED, 11693, 3, rbt)
	var rmd := rv(wt(34, "MODERN"), 0.3)
	if rmd > 0.0:
		var mc := Vector2(scr2.position.x + 150, scr2.position.y + 200)
		var burst2 := PackedVector2Array()
		for j2 in 24:
			var rad2 := (110.0 if j2 % 2 == 0 else 76.0) * (0.6 + 0.4 * rmd)
			burst2.append(mc + Vector2(cos(TAU * j2 / 24.0), sin(TAU * j2 / 24.0)) * rad2)
		solid(burst2, CYAN)
		edge(burst2, PURPLE, 3.0, 11694, 1.0, 0.6)
		txt_c("MODERN!", mc.x, mc.y + 14.0, 32, PURPLE, 11695, 3, rmd)


# ================================================================== page 9: Christmas 1998
func jb_p9() -> void:
	var T := cs(35)
	sky_strip(170.0, SKY, 11700, rv(T - 0.3, 0.6))
	var ground := C.rect_poly(Rect2(-10, 640, W + 20, 270))
	fill(ground, Color("#e9f3ff"), 11701, rv(T - 0.2, 0.6), 4.4, -0.2, 4.0)
	jb_mini_tower(Vector2(800, 650), 230.0, 470.0, 11702, rv(T - 0.2, 0.8), 0.7)
	var signs := ["SHAME", "BOYCOTT", "RACIST", "WE REMEMBER", "NOT HERE", "SHAME", "NEVER AGAIN", "NO!"]
	var pos: Array = [Vector2(200, 280), Vector2(420, 190), Vector2(1180, 190), Vector2(1400, 280), Vector2(330, 450), Vector2(530, 380), Vector2(1070, 380), Vector2(1330, 450)]
	for k in 8:
		var rp := rv(T + 0.1 + k * 0.14, 0.4)
		if rp <= 0.0:
			continue
		var p: Vector2 = pos[k]
		ln(p + Vector2(0, 30), p + Vector2(0, 110), BROWN, 5.0, 11710 + k, rp, 0.4)
		var w := C.letters_width(String(signs[k]), 26) + 30.0
		var board := C.rect_poly(Rect2(p + Vector2(-w * 0.5, -36), Vector2(w, 66)))
		solid(board, ca(WHITE, rp))
		edge(board, INK, 2.4, 11720 + k, rp, 0.6)
		txt_c(String(signs[k]), p.x, p.y + 10.0, 26, RED, 11730 + k, 2, rp)
		jb_face(p + Vector2(0, 140), 38.0, "swear" if k % 2 == 1 else "angry", 11740 + k * 19, rp)
	# Christmas: snow, a tree, and her present under it
	var rx := rv(cs(36), 0.6)
	if rx > 0.0:
		jb_tree(Vector2(110, 700), 250.0, 11900, rx)
		for q in 110:
			var ph := fmod(t * 0.12 + C.rnd(11910, q), 1.0)
			var sp := Vector2(C.rnd(11911, q) * W + sin(t + q) * 12.0, ph * H)
			draw_circle(sp, 3.2, ca(SNOW, 0.9 * rx))
		jb_present(Vector2(140, 640), 64.0, 11920, rv(cs(36) + 1.1, 0.5))
	jb_face(Vector2(1490, 96), 56.0, "eyeroll", 11930, rv(wt(37, "PEOPLE") - 0.4, 0.4))


# ================================================================== page 10: the things he stopped
func jb_p10() -> void:
	var cx := [300.0, 800.0, 1300.0]
	var cy := [190.0, 510.0]
	for i in 6:
		var ci := 38 + i
		var c := Vector2(float(cx[i % 3]), float(cy[i / 3]))
		var r := rv(cs(ci) - 0.25, 0.5)
		if r <= 0.0:
			continue
		var card := C.rect_poly(Rect2(c - Vector2(200, 140), Vector2(400, 280)))
		solid(card, ca(WHITE, r))
		edge(card, INK, 2.4, 12000 + i, r, 0.6)
		var s := 12010 + i * 40
		match i:
			0:
				var scr := jb_tv(Rect2(c - Vector2(120, 80), Vector2(240, 160)), s, r)
				if r >= 1.0:
					solid(C.rect_poly(scr), SKY.lightened(0.3))
					jb_mini_tower(Vector2(scr.get_center().x, scr.end.y - 4), 40.0, 90.0, s + 5, 1.0)
			1:
				for k in 3:
					var sh := C.rect_poly(Rect2(c + Vector2(-90 + k * 18, -100 + k * 14), Vector2(150, 190)))
					solid(sh, ca(SUN.lightened(0.5) if k < 2 else WHITE, r))
					edge(sh, INK, 1.8, s + k, r, 0.4)
				if r >= 1.0:
					txt_c("GRAND", c.x + 11.0, c.y - 20.0, 24, RED, s + 4, 2)
					txt_c("RE-OPENING!", c.x + 11.0, c.y + 12.0, 22, RED, s + 5, 2)
					star(c + Vector2(11, 52), 18.0, GOLD, s + 6)
			2:
				jb_phone(c + Vector2(-60, 10), 80.0, s, r, t < cs(ci) + 3.0)
				if r >= 1.0:
					jb_jag(c + Vector2(100, -70), "BANK", 24, NAVY, s + 20, 1.0)
			3:
				var bill := C.rect_poly(Rect2(c + Vector2(-150, -100), Vector2(150, 190)))
				solid(bill, ca(WHITE, r))
				edge(bill, INK, 1.8, s, r, 0.4)
				if r >= 1.0:
					txt("PHONE", c + Vector2(-140, -64), 22, INK, s + 1, 2)
					txt("BILL", c + Vector2(-140, -36), 22, INK, s + 2, 2)
					txt("$$$", c + Vector2(-140, 10), 30, CASH_DARK, s + 3, 2)
					txt("PAST DUE", c + Vector2(-146, 70), 20, RED, s + 4, 2)
					jb_phone(c + Vector2(100, 30), 60.0, s + 10, 1.0)
					path(PackedVector2Array([c + Vector2(70, 70), c + Vector2(60, 110), c + Vector2(30, 120)]), INK, 2.4, s + 20)
					path(PackedVector2Array([c + Vector2(4, 124), c + Vector2(-40, 128)]), INK, 2.4, s + 21)
			4:
				for sd: float in [-1.0, 1.0]:
					var hc := c + Vector2(sd * 90, 40)
					solid(circ(hc, 46.0, s + int(sd), 14), ca(Color("#f6d7c3") if sd < 0.0 else Color("#c68c5c"), r))
					edge(circ(hc, 46.0, s + 2 + int(sd), 14), INK, 2.2, s + 4 + int(sd), r)
					if r >= 1.0:
						draw_circle(hc + Vector2(-14, -6), 4.0, INK)
						draw_circle(hc + Vector2(14, -6), 4.0, INK)
						path(arc(hc + Vector2(0, 12), 14, 8, 0.3, PI - 0.3, 6), INK, 2.4, s + 6 + int(sd))
				if r >= 1.0:
					jb_jag(c + Vector2(0, -80), "HI!", 26, PURPLE, s + 10, 1.0)
			5:
				jb_mini_tower(c + Vector2(0, 130), 170.0, 250.0, s, r, 0.85)
				if r >= 1.0:
					var dr := C.rect_poly(Rect2(c + Vector2(-26, 70), Vector2(52, 60)))
					solid(dr, BROWN)
					edge(dr, INK, 2.0, s + 3, 1.0, 0.4)
		# and the X
		var rxx := rv(wt(ci, "STOPPED") + 0.5, 0.4)
		if rxx > 0.0:
			ln(c + Vector2(-170, -110), c + Vector2(170, 110), RED, 11.0, 12300 + i, rxx, 1.0)
			ln(c + Vector2(170, -110), c + Vector2(-170, 110), RED, 11.0, 12310 + i, rv(wt(ci, "STOPPED") + 0.8, 0.3), 1.0)


# ================================================================== page 11: the door
func jb_p11() -> void:
	var T := cs(44)
	var wall := C.rect_poly(Rect2(-10, -10, W + 20, 720))
	fill(wall, TOWER, 12400, rv(T - 0.3, 0.8), 4.6, -0.4, 4.4)
	var walk := C.rect_poly(Rect2(-10, 700, W + 20, 210))
	fill(walk, GREY.lightened(0.2), 12401, rv(T - 0.2, 0.6), 4.4, -0.1, 4.0)
	if t < T + 0.4:
		return
	for r in 2:
		for c in 6:
			if c == 2 or c == 3:
				continue
			var wr := C.rect_poly(Rect2(80 + c * 250, 60 + r * 180, 130, 110))
			solid(wr, Color("#3b3f52"))
			edge(wr, INK, 2.0, 12410 + r * 6 + c, 1.0, 0.4)
	var sg := C.rect_poly(Rect2(600, 200, 400, 64))
	solid(sg, WHITE)
	edge(sg, TOWER_TRIM, 3.0, 12430)
	txt_c("PAISLEY TOWER", 800.0, 248.0, 38, TOWER_TRIM, 12431, 2)
	var fr := Rect2(680, 300, 240, 400)
	solid(C.rect_poly(fr), INK)
	var o := _ease(rv(cs(45) + 0.4, 1.6))
	var leaf := Rect2(fr.position, Vector2(fr.size.x * (1.0 - 0.85 * o), fr.size.y))
	var lp := C.rect_poly(leaf)
	solid(lp, BROWN)
	fill(lp, BROWN.darkened(0.15), 12432, 1.0, 3.6, 1.2, 3.2)
	edge(lp, INK, 2.6, 12433)
	draw_circle(Vector2(leaf.end.x - 24.0 * (1.0 - o * 0.7), 510), 7.0, GOLD)
	edge(C.rect_poly(fr.grow(8)), INK, 4.0, 12434, 1.0, 0.6)
	# his footprints, going in
	for k in 10:
		var a := rv(T + 0.4 + k * 0.28, 0.15)
		var sd := -1.0 if k % 2 == 0 else 1.0
		jb_footprint(Vector2(800 + sd * 22, 880 - k * 20), 0.0, 26.0, 12440 + k, a * (0.35 + 0.65 * float(k) / 9.0))
