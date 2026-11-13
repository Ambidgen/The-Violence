extends "res://scripts/view/proto/fettick_view.gd"
## Cutscene 5 — Hero (prototype, 2026-11-02). Thomas, halfway through a year with fewer
## than twenty murders: to prevent a tyrant you give up on heroes; why people bring tyrants
## back; the papers calling him one; the board; three names and the others; and her.
##
## Story rule (design, not shown): this plays when the player keeps the murder rate low,
## whatever their political alignment.
##
## Same hand as the other four. Her drawing comes in at the end, slowly, when he thinks of
## her. Presentation only.

## [text, who, gap before (s), duration (<= 0: from length), page]
const LINES5 := [
	["", "BEAT", 0.0, 3.2, 0],
	["IN ORDER TO PREVENT A TYRANT,", "N", 0.2, -1.0, 0],
	["YOU NEED TO ACCEPT THAT YOU'LL NEVER SEE ANOTHER HERO.", "N", 0.3, 4.4, 0],
	["THAT'S WHY PEOPLE BRING TYRANTS BACK.", "N", 0.9, -1.0, 1],
	["SOMETIMES BECAUSE THEY NEED THEM,", "N", 0.4, -1.0, 1],
	["SOMETIMES BECAUSE THEY'RE SCARED.", "N", 0.3, -1.0, 1],
	["AND SOMETIMES THINGS ARE JUST A LITTLE TOO BORING.", "N", 0.6, 4.2, 1],
	["THEY'RE CALLING ME A HERO NOW TOO.", "N", 1.0, 3.4, 2],
	["I THOUGHT I WOULDN'T GIVE A SHIT IF SOMEONE DID I JUST...", "N", 0.6, -1.0, 2],
	["I NEVER THOUGHT ANYONE WOULD SAY IT.", "N", 0.6, 3.8, 2],
	["LESS THAN 20 MURDERS ON THE BOARD AND THE YEAR'S HALFWAY DONE.", "N", 1.0, -1.0, 3],
	["GUESS I AM A HERO.", "N", 0.9, 3.4, 3],
	["MARIA LUPELLE, GRAYSON SCOTT, GREGORY IVEY-", "N", 1.0, 4.6, 4],
	["THE OTHERS...", "N", 0.5, 3.0, 4],
	["THEY'D FEEL GOOD IF THEY KNEW WHAT THE YEAR WAS LIKE.", "N", 0.8, -1.0, 4],
	["THEY'D FEEL BETTER ABOUT HOW THINGS TURNED OUT.", "N", 0.3, -1.0, 4],
	["SO WOULD ALICE, I FELT WITHOUT SOUNDING IT.", "N", 1.0, 5.0, 5],
	["...NOW WHERE WAS I?", "END", 1.0, 4.2, 5],
]
const PAGES5 := 6
const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const TALLY := 17


func _build() -> void:
	reporters = []
	flashes = []
	flash_pos = []
	intrusions = []
	cards.clear()
	var at := 0.0
	for i in LINES5.size():
		var l: Array = LINES5[i]
		var text := String(l[0])
		var n := _plain(text).length()
		var dur := float(l[3])
		if dur <= 0.0:
			dur = maxf(1.6, 0.9 + n / 15.0)
		var st := at + float(l[2])
		cards.append({"text": text, "who": String(l[1]), "t": st, "dur": dur, "pg": int(l[4]), "cps": CPS})
		at = st + dur
	T_END = ce(cards.size() - 1) + 1.0


func tally_t(k: int) -> float:
	return wt(10, "MURDERS") + k * 0.17


func cues() -> Dictionary:
	var starts: Array = []
	for c: Dictionary in cards:
		starts.append(float(c["t"]))
	var pages: Array = []
	for pg in PAGES5:
		for i in cards.size():
			if int(cards[i]["pg"]) == pg:
				pages.append(cs(i))
				break
	var tallies: Array = []
	for k in TALLY:
		tallies.append(tally_t(k))
	var months: Array = []
	for m in 6:
		months.append(wt(10, "HALFWAY") + m * 0.22)
	return {"cards": starts, "pages": pages, "crown_x": wt(1, "PREVENT"), "cape": wt(2, "NEVER"),
		"march": cs(3), "throne": ce(6) - 1.2, "zzz": wt(6, "BORING"), "paper": cs(7) - 0.2, "cape2": wt(7, "HERO"),
		"tallies": tallies, "months": months, "star": wt(11, "HERO"),
		"names": [wt(12, "MARIA"), wt(12, "GRAYSON"), wt(12, "GREGORY")], "others": cs(13),
		"alice": wt(16, "ALICE") - 0.3, "end_line": cs(17), "end": T_END}


# ================================================================== draw
func _draw() -> void:
	C.frame = int(t * 8.0)
	C.boil = 1.0
	var rs := vp.x / W
	var cx := jb_cam_x()
	for pg in PAGES5:
		var x0 := pg * W
		if x0 + W < cx - W * 0.5 - 2.0 or x0 > cx + W * 0.5 + 2.0:
			continue
		page_xf = Transform2D(0.0, Vector2(rs, rs), 0.0, Vector2(x0 - cx + W * 0.5, 0.0) * rs)
		draw_set_transform_matrix(page_xf)
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		match pg:
			0: hp0()
			1: hp1()
			2: hp2()
			3: hp3()
			4: hp4()
			5: hp5()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	_captions()
	hp_end()


func hp_end() -> void:
	var i := cards.size() - 1
	if t < cs(i) - 0.6:
		return
	draw_rect(Rect2(0, 0, W, H), ca(INK, rv(cs(i) - 0.6, 0.6)))
	if t >= cs(i):
		_print_card(i, 52, 1300.0, 0.0, 470.0, 70.0, true, Color("#f4f0e6"), 3)


# ================================================================== Thomas in a photograph
func fk_look(who: String) -> Dictionary:
	if who == "TG":
		return {"suit": NAVY, "skin": SKIN, "tie": NAVY.darkened(0.4)}
	return super.fk_look(who)


func fk_head(hc: Vector2, r: float, who: String, s: int, rr: float, mood := "") -> void:
	super.fk_head(hc, r, who, s, rr, mood)
	if who == "TG" and rr >= 1.0:
		var cap := arc(hc + Vector2(0, -r * 0.35), r * 1.05, r * 0.75, PI, TAU, 10)
		solid(cap, NAVY)
		edge(cap, INK, 2.0, s + 50, 1.0, 0.4)
		ln(hc + Vector2(-r * 0.2, -r * 0.38), hc + Vector2(r * 1.25, -r * 0.34), NAVY.darkened(0.4), r * 0.16, s + 51, 1.0, 0.3)
		star(hc + Vector2(0, -r * 0.75), r * 0.18, GOLD, s + 52)
		ln(hc + Vector2(-r * 0.2, r * 0.48), hc + Vector2(r * 0.2, r * 0.48), INK, 2.4, s + 53, 1.0, 0.3)


# ================================================================== little drawings
func hp_crown(c: Vector2, w: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var p := PackedVector2Array([c + Vector2(-w * 0.5, w * 0.3), c + Vector2(-w * 0.5, -w * 0.2), c + Vector2(-w * 0.27, w * 0.02),
		c + Vector2(0, -w * 0.32), c + Vector2(w * 0.27, w * 0.02), c + Vector2(w * 0.5, -w * 0.2), c + Vector2(w * 0.5, w * 0.3)])
	solid(p, ca(GOLD.lightened(0.2), rr * a))
	fill(p, ca(GOLD, a), s, rr, 3.4, -0.5, 3.2)
	edge(p, ca(GOLD.darkened(0.4), a), 2.6, s + 1, rr)
	if rr >= 1.0:
		var jc: Array[Color] = [RED, SKY, RED]
		for k in 3:
			solid(circ(c + Vector2(-w * 0.27 + k * w * 0.27, w * 0.15), w * 0.06, s + 2 + k, 10), ca(jc[k], a))


func hp_cape(c: Vector2, w: float, s: int, rr: float, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var p := PackedVector2Array([c + Vector2(-w * 0.22, -w * 0.4), c + Vector2(w * 0.22, -w * 0.4)])
	for k in 7:
		var f := float(k) / 6.0
		p.append(c + Vector2(lerpf(w * 0.5, -w * 0.5, f), w * 0.42 + sin(f * TAU * 1.5 + t * 3.0) * w * 0.05))
	solid(p, ca(RED.lightened(0.2), rr * a * 0.7))
	fill(p, ca(RED, a), s, rr, 3.4, -0.5, 3.2)
	edge(p, ca(RED.darkened(0.35), a), 2.4, s + 1, rr)
	if rr >= 1.0:
		solid(circ(c + Vector2(0, -w * 0.4), w * 0.05, s + 2, 8), ca(GOLD, a))


func hp_board(r: Rect2, s: int, rr: float) -> void:
	var fr := C.rect_poly(r.grow(14))
	solid(fr, ca(GREY.lightened(0.15), rr))
	edge(fr, INK, 2.6, s, rr)
	var b := C.rect_poly(r)
	solid(b, ca(WHITE, rr))
	edge(b, GREY.darkened(0.3), 1.8, s + 1, rr, 0.5)
	if rr >= 1.0:
		solid(C.rect_poly(Rect2(r.position.x + r.size.x * 0.3, r.end.y + 14, r.size.x * 0.4, 16)), GREY.darkened(0.2))
		for k in 3:
			solid(C.rect_poly(Rect2(r.position.x + r.size.x * 0.34 + k * 50, r.end.y + 6, 36, 10)), [RED, NAVY, GRASS_DARK][k])


# ================================================================== page 0: the scale
func hp0() -> void:
	var rp := rv(0.2, 0.8)
	ln(Vector2(800, 660), Vector2(800, 250), BROWN, 14.0, 40000, rp, 0.6)
	var foot := PackedVector2Array([Vector2(680, 690), Vector2(920, 690), Vector2(800, 640)])
	fill(foot, BROWN, 40001, rp, 3.4, 0.4, 3.2)
	edge(foot, INK, 2.4, 40002, rp)
	var rb := rv(0.6, 0.6)
	ln(Vector2(400, 250), Vector2(1200, 250), BROWN.darkened(0.15), 11.0, 40003, rb, 0.5)
	solid(circ(Vector2(800, 250), 16.0, 40004, 12), ca(GOLD, rb))
	var rpn := rv(1.0, 0.7)
	var ends: Array[float] = [420.0, 1180.0]
	for k in 2:
		var x := ends[k]
		ln(Vector2(x, 252), Vector2(x - 100, 470), INK, 2.4, 40010 + k * 3, rpn, 0.5)
		ln(Vector2(x, 252), Vector2(x + 100, 470), INK, 2.4, 40011 + k * 3, rpn, 0.5)
		var pan := arc(Vector2(x, 470), 115.0, 44.0, 0.0, PI, 12)
		solid(pan, ca(GOLD.darkened(0.15), rpn))
		edge(pan, INK, 2.4, 40012 + k * 3, rpn)
	# the tyrant's crown, crossed out
	hp_crown(Vector2(420, 425), 150.0, 40020, rv(1.5, 0.5))
	txt_c("TYRANT", 420.0, 590.0, 40, RED, 40030, 3, rv(2.3, 0.6))
	var rx := rv(wt(1, "PREVENT"), 0.3)
	ln(Vector2(330, 350), Vector2(510, 500), RED, 11.0, 40031, rx, 0.8)
	ln(Vector2(510, 350), Vector2(330, 500), RED, 11.0, 40032, rv(wt(1, "PREVENT") + 0.25, 0.3), 0.8)
	# the hero's cape, gone
	var go := _ease(rv(wt(2, "NEVER"), 2.2))
	var ca_ := 1.0 - go
	if ca_ > 0.01:
		fk_push(Vector2(1180, 405) + Vector2(520, -460) * go, go * 1.2)
		hp_cape(Vector2.ZERO, 150.0, 40040, rv(1.9, 0.5), ca_)
		fk_pop()
	txt_c("HERO", 1180.0, 590.0, 40, ca(GOLD.darkened(0.3), 1.0 - go * 0.8), 40050, 3, rv(2.5, 0.5))


# ================================================================== page 1: bringing the crown back
func hp1() -> void:
	var t0 := cs(3)
	var rt := rv(t0 - 0.4, 0.8)
	var back := C.rect_poly(Rect2(1225, 330, 150, 250))
	solid(back, ca(RED.lightened(0.2), rt * 0.7))
	fill(back, RED, 40100, rt, 3.6, -0.5, 3.4)
	edge(back, INK, 2.6, 40101, rt)
	var seat := C.rect_poly(Rect2(1195, 560, 210, 40))
	fill(seat, GOLD, 40102, rt, 3.2, 0.2, 3.2)
	edge(seat, INK, 2.4, 40103, rt)
	for lx: float in [1210.0, 1390.0]:
		ln(Vector2(lx, 600), Vector2(lx, 700), BROWN.darkened(0.2), 10.0, 40104 + int(lx), rt, 0.4)
	for k in 3:
		star(Vector2(1300 + (k - 1) * 46, 300 - (k % 2) * 20), 14.0, GOLD, 40110 + k, rt)
	# the people, carrying it
	var march := _ease(clampf((t - t0) / (ce(6) - 1.4 - t0), 0.0, 1.0))
	var cx := lerpf(260.0, 980.0, march)
	var land := _ease(rv(ce(6) - 1.4, 1.0))
	var crown_c := Vector2(cx, 470.0).lerp(Vector2(1300, 530), land)
	var mood := "flat"
	if t >= cs(5):
		mood = "scared"
	if t >= cs(6):
		mood = "flat"
	var offs: Array[float] = [-200.0, -100.0, 0.0, 100.0, 200.0]
	for k2 in offs.size():
		var fx := cx + offs[k2] - 60.0 * land
		var bob := absf(sin(t * 6.0 + k2)) * 8.0 * (1.0 - land)
		var pf := Vector2(fx, 706.0 - bob)
		var hl := Vector2.ZERO
		var hr := Vector2.ZERO
		if absf(offs[k2]) < 150.0 and land < 0.5:
			hl = crown_c + Vector2(offs[k2] * 0.3 - 30.0, 50.0)
			hr = crown_c + Vector2(offs[k2] * 0.3 + 30.0, 50.0)
		fk_folk(pf, 150.0, [ORANGE, SKY, GRASS, PINK, PURPLE][k2], SKINS[(k2 * 2) % 5], 40200 + k2 * 11, rv(t0 - 0.2 + k2 * 0.1, 0.5), mood, hl, hr)
	hp_crown(crown_c, 190.0, 40300, rv(t0 - 0.3, 0.5))
	# need, fear, boredom
	jb_jag(Vector2(300, 250), "WE NEED HIM!", 26, NAVY, 40310, rv(wt(4, "NEED"), 0.3) * (1.0 - rv(ce(4), 0.3)))
	if t >= cs(5) and t < cs(6) + 0.3:
		var dk := rv(cs(5), 0.6) * (1.0 - rv(cs(6), 0.3))
		jb_jag(Vector2(420, 250), "HELP!", 30, RED, 40321, dk)
	var rz := rv(wt(6, "BORING"), 0.5)
	if rz > 0.0:
		for k3 in 3:
			var ph := fmod(t * 0.5 + k3 * 0.33, 1.0)
			txt("Z", Vector2(1060 + k3 * 46 + ph * 30, 470 - ph * 140), 40 + k3 * 10, ca(PURPLE, rz * (1.0 - ph)), 40330 + k3, 2)


# ================================================================== page 2: the papers
func hp2() -> void:
	var t0 := cs(7)
	var rp := rv(t0 - 0.5, 0.8)
	fk_push(Vector2(470, 380), -0.04)
	var pp := C.rect_poly(Rect2(-380, -320, 760, 640))
	var sh := PackedVector2Array()
	for q in pp:
		sh.append(q + Vector2(8, 10))
	solid(sh, ca(Color(0, 0, 0, 0.2), rp))
	solid(pp, ca(Color("#f2efe6"), rp))
	edge(pp, GREY.darkened(0.3), 2.2, 40400, rp, 0.5)
	if rp >= 1.0:
		txt_c("THE CARRICK LEDGER", 0.0, -262.0, 40, INK, 40401, 3)
		ln(Vector2(-350, -244), Vector2(350, -244), INK, 3.0, 40402, 1.0, 0.3)
		ln(Vector2(-350, -236), Vector2(350, -236), INK, 1.4, 40403, 1.0, 0.3)
		txt_c("OUR HERO:", 0.0, -170.0, 56, RED, 40404, 3)
		txt_c("CHIEF GRENDEL", 0.0, -104.0, 56, RED, 40405, 3)
		var ph := C.rect_poly(Rect2(-340, -70, 300, 300))
		solid(ph, Color("#9cc9ff"))
		edge(ph, INK, 2.0, 40406, 1.0, 0.4)
		var cape := rv(wt(7, "HERO"), 0.6)
		if cape > 0.0:
			var cp := PackedVector2Array([Vector2(-245, 90), Vector2(-135, 90), Vector2(-70, 225), Vector2(-310, 225)])
			fill(cp, RED, 40407, cape, 3.0, -0.5, 3.4)
		fk_bust(Vector2(-190, 50), 52.0, "TG", 40410, 1.0)
		if cape >= 1.0:
			star(Vector2(-190, 180), 18.0, GOLD, 40408)
		for k in 9:
			var y := -50.0 + k * 30.0
			var sw := PackedVector2Array()
			for q2 in 12:
				sw.append(Vector2(-10.0 + q2 * 30.0, y + sin(q2 * 1.7 + k) * 3.0))
			draw_polyline(sw, Color(0.3, 0.3, 0.32, 0.7), 2.0, true)
	fk_pop()
	var said := t >= cs(8)
	thomas(Vector2(1210, 706), 540.0, 40500, rv(t0 - 0.2, 1.2), true, "tired" if said else "flat", "down")


# ================================================================== page 3: the board
func hp3() -> void:
	var t0 := cs(10)
	var rb := rv(t0 - 0.5, 0.7)
	hp_board(Rect2(470, 70, 1040, 560), 40600, rb)
	txt("HOMICIDES", Vector2(510, 140), 48, RED, 40601, 3, rv(t0 - 0.2, 0.8))
	for k in TALLY:
		var rk := rv(tally_t(k), 0.12)
		if rk <= 0.0:
			continue
		var grp := k / 5
		var j := k % 5
		var gx := 520.0 + grp * 150.0
		if j < 4:
			var x := gx + j * 26.0
			ln(Vector2(x, 190), Vector2(x + 2, 280), INK, 6.0, 40610 + k, rk, 0.5)
		else:
			ln(Vector2(gx - 12, 270), Vector2(gx + 92, 196), RED.darkened(0.2), 6.0, 40610 + k, rk, 0.5)
	txt("UNDER 20", Vector2(1080, 270), 56, NAVY, 40640, 3, rv(wt(10, "20"), 0.6))
	for m in 12:
		var bx := 510.0 + m * 82.0
		var box := C.rect_poly(Rect2(bx, 400, 72, 90))
		edge(box, GREY.darkened(0.3), 2.0, 40650 + m, rv(t0 + 0.2 + m * 0.04, 0.3), 0.4)
		txt_c(String(MONTHS[m]), bx + 36.0, 470.0, 24, INK, 40670 + m, 2, rv(t0 + 0.4 + m * 0.04, 0.3))
		if m < 6:
			var rx := rv(wt(10, "HALFWAY") + m * 0.22, 0.2)
			ln(Vector2(bx + 6, 406), Vector2(bx + 66, 484), RED, 5.0, 40690 + m, rx, 0.5)
			ln(Vector2(bx + 66, 406), Vector2(bx + 6, 484), RED, 5.0, 40700 + m, rx, 0.5)
	txt_c("HALFWAY", 755.0, 560.0, 30, RED, 40710, 2, rv(wt(10, "HALFWAY") + 1.3, 0.5))
	var th := thomas(Vector2(230, 706), 470.0, 40720, rv(t0 - 0.3, 1.0), true, "flat", "down")
	if th.has("head"):
		var hc: Vector2 = th["head"]
		var r: float = th["r"]
		star(hc + Vector2(r * 0.5, r * 2.6), 24.0, GOLD, 40730, rv(wt(11, "HERO"), 0.4))
		var rh := rv(wt(11, "HERO") + 0.3, 0.4)
		if rh > 0.0:
			txt("HERO", hc + Vector2(r * 1.6, r * 2.3), 22, GOLD.darkened(0.3), 40731, 2, rh)


# ================================================================== page 4: the names
func hp4() -> void:
	var t0 := cs(12)
	hp_board(Rect2(120, 60, 1360, 600), 40800, rv(t0 - 0.5, 0.7))
	var names := ["MARIA LUPELLE", "GRAYSON SCOTT", "GREGORY IVEY"]
	var keys := ["MARIA", "GRAYSON", "GREGORY"]
	var rows: Array = []
	for k in 3:
		var y := 160.0 + k * 90.0
		txt(String(names[k]), Vector2(170, y), 44, INK, 40810 + k, 2, rv(wt(12, String(keys[k])), 0.9))
		rows.append(Vector2(170.0 + C.letters_width(String(names[k]), 44) + 30.0, y - 18.0))
	# the others: names he doesn't say
	var spots: Array[Vector2] = []
	for k2 in 3:
		spots.append(Vector2(170, 430 + k2 * 80))
	for k3 in 6:
		spots.append(Vector2(640, 160 + k3 * 85))
	for k4 in 5:
		spots.append(Vector2(1060, 160 + k4 * 85))
	for q in spots.size():
		var rq := rv(cs(13) + 0.1 + q * 0.12, 0.3)
		if rq <= 0.0:
			continue
		var p0: Vector2 = spots[q]
		var ln_ := 220.0 + C.rnd(40830, q) * 110.0
		var sw := PackedVector2Array()
		var n := int(ln_ / 12.0)
		for k5 in int(n * rq) + 1:
			sw.append(p0 + Vector2(k5 * 12.0, sin(k5 * 1.9 + q) * 7.0 - 10.0))
		if sw.size() >= 2:
			draw_polyline(sw, Color(0.15, 0.13, 0.15, 0.75), 3.0, true)
		rows.append(p0 + Vector2(ln_ + 26.0, -12.0))
	# a flower beside every one of them
	for f in rows.size():
		var at := cs(14) + 0.2 + f * 0.25
		jb_bloom(rows[f] + Vector2(0, -12), 13.0, [6, 2, 1, 5, 4][f % 5], 40900 + f * 41, rv(at, 0.4))


# ================================================================== page 5: her
func hp5() -> void:
	var t0 := cs(16)
	thomas(Vector2(470, 706), 540.0, 41000, rv(t0 - 0.4, 1.0), true, "tired", "down")
	var a := rv(wt(16, "ALICE") - 0.3, 2.6) * 0.92
	if a > 0.01:
		rainbow(Vector2(1180, 640), 300.0, 26.0, 41010, 1.0, a)
		sun(Vector2(1450, 140), 60.0, 41020, 1.0, a)
		stick(Vector2(1180, 700), 250.0, "me", 41030, 1.0, a, Vector2(1140, 560), Vector2(1220, 560))
		heart(Vector2(1180, 556), 40.0, ca(PINK, a), 41040)
		for k in 3:
			heart(Vector2(1000 + k * 170, 200 + (k % 2) * 60), 20.0, ca([PINK, PURPLE, RED][k], a), 41050 + k * 3)
