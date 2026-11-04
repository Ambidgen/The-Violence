extends "res://scripts/view/proto/jeremy_view.gd"
## Cutscene 4 — This Machine Kills Tyrants (prototype, 2026-11-01). The diary of Douglas
## Fettick (Subject A), read off the case file: the machine he built on the hill, the one
## man it was for, the board of everything George Carrick is, the election that makes it
## settled, the night he decides he would rather live, the Mayor Elect on every set in the
## city, and inauguration day, when the same line fills page after page. Then Thomas
## Grendel's case report, and George Carrick's status: unknown.
##
## Story rule (design, not shown): this branch only plays when the player is aligned more
## than 50% with George Carrick, and what happens to him is decided by the player's actions.
##
## Same hand as the other three: a child's brightest crayons, a page per beat. The machine
## is a contraption a child would draw: nothing on it says what it does. Nothing of the
## plan is shown (the case report's diary page is redacted). Her things creep in twice:
## her family at the end of the line of people holding hands, and a heart sticker on
## Daddy's case folder. Presentation only.

## [text, who, gap before (s), duration (<= 0: from length), page]
##   who: N = the diary (strip), BEAT = the page alone, HEAD = a date written on the page,
##   STAMP = a stamp on the page, SCRAWL = the inauguration-day pages, REP = typed on the
##   case report, END = on black.
const LINES4 := [
	["", "BEAT", 0.0, 6.0, 0],
	["THIS MACHINE,", "N", 0.3, 2.2, 1],
	["THIS DUSTY, RUSTY, (AT ONE POINT TRUSTY) OLD PILE OF NUTS AND BOLTS.", "N", 0.4, -1.0, 1],
	["THIS CREAKY, SQUEAKY, LEAKY (SOME SAY FREAKY) TWISTED HUNK OF METAL, PLASTIC, RUBBER AND OIL.", "N", 0.4, -1.0, 1],
	["I BUILT THIS MACHINE AS I SAT ON A HILL.", "N", 0.9, -1.0, 2],
	["I BUILT THIS MACHINE WITH A PRACTICED OLD SKILL.", "N", 0.2, -1.0, 2],
	["I BUILT THIS MACHINE WITH A HAMMER AND DRILL.", "N", 0.2, -1.0, 2],
	["I BUILT THIS MACHINE AND I BUILT IT TO *KILL*.", "N", 0.5, 4.2, 2],
	["I BUILT THIS MACHINE TO KILL ONE MAN.", "N", 0.9, -1.0, 3],
	["ONE VERY BAD MAN.", "N", 0.5, 2.6, 3],
	["ONE", "N", 0.5, 1.3, 3],
	["VERY POWERFUL,", "N", 0.1, 2.0, 3],
	["VERY WEALTHY,", "N", 0.1, 2.0, 3],
	["VERY FRIENDLY BAD MAN.", "N", 0.1, 3.0, 3],
	["GEORGE CARRICK.", "N", 0.9, 3.8, 3],
	["SOME OF YOU WILL CALL ME A MONSTER.", "N", 0.9, -1.0, 4],
	["SOME OF YOU WILL CALL ME A HERO.", "N", 0.3, -1.0, 4],
	["...ALL OF YOU WILL CALL ME INSANE.", "N", 0.7, 3.8, 4],
	["GEORGE CARRICK, WHO OWNED FOUR OF THE PAISLEY TOWERS FROM THE 80S TO THE MID 90S.", "N", 0.9, -1.0, 5],
	["GEORGE CARRICK, WHO WAS INDICTED FOR USING UNION MONEY TO HIRE HIS SON KEVIN'S COMPANY.", "N", 0.4, -1.0, 5],
	["GEORGE CARRICK, CEO OF PORT CARRICK ENTERPRISES.", "N", 0.4, -1.0, 5],
	["A COMPANY THAT HAS NO OFFICIAL RELATIONSHIP WITH THE LOCAL GOVERNMENT.", "N", 0.7, -1.0, 6],
	["A COMPANY THAT SUED THE CITY FOR TWO MILLION DOLLARS FOR TRADEMARK INFRINGEMENT AND WON.", "N", 0.3, -1.0, 6],
	["A COMPANY THAT ILLEGALLY CLAIMS TO HAVE BEEN FOUNDED IN 1834 BY OUR FOUNDER, HENRY CARRICK JR HIMSELF.", "N", 0.7, -1.0, 7],
	["GEORGE CARRICK STARTED THE COMPANY IN 1973.", "N", 0.6, -1.0, 7],
	["HE ISN'T EVEN RELATED TO HENRY CARRICK JR. IN THE SLIGHTEST", "N", 0.3, -1.0, 7],
	["(ALTHOUGH CARRICK IS HIS REAL LAST NAME).", "N", 0.1, -1.0, 7],
	["HE JUST LOVES LETTING OTHER PEOPLE SAY IT.", "N", 0.4, 3.6, 7],
	["GEORGE CARRICK WILL BE OUR NEXT MAYOR.", "N", 1.0, -1.0, 8],
	["I SAY AGAIN,", "N", 0.6, 1.8, 8],
	["GEORGE CARRICK WILL BE OUR NEXT MAYOR.", "N", 0.3, -1.0, 8],
	["THIS IS NO LONGER A MATTER OF DELIBERATION.", "N", 0.7, -1.0, 8],
	["THE PEOPLE HAVE BEEN FRIGHTENED ENOUGH.", "N", 0.5, -1.0, 8],
	["THEY KNOW WHAT HE IS, AND THEY CHOOSE HIM ANYWAY.", "N", 0.5, 4.2, 8],
	["...THAT'S WHY I'VE DECIDED NOT TO GO THROUGH WITH IT.", "N", 1.6, -1.0, 9],
	["I'VE REALIZED THAT I'D RATHER LIVE.", "N", 0.7, 4.0, 9],
	["SO I'M WRITING THIS RIGHT NOW SO I CAN REMEMBER HOW I FELT JUST NOW.", "N", 0.9, -1.0, 10],
	["SO I CAN REMEMBER THAT I'LL HAVE MOMENTS THAT MAKE IT ALL WORTH IT.", "N", 0.3, -1.0, 10],
	["I KNOW HE'S AN EVIL MAN.", "N", 0.7, -1.0, 10],
	["BUT I HAVE THINGS TO LIVE FOR.", "N", 0.3, -1.0, 10],
	["I HAVE THINGS TO DO WITH MY LIFE I CAN'T LET HIM TAKE AWAY FROM ME.", "N", 0.2, -1.0, 10],
	["I'LL SURVIVE THIS. WE'LL SURVIVE THIS. TOGETHER.", "N", 0.7, 5.2, 10],
	["END NOTE", "STAMP", 0.3, 2.8, 10],
	["JULY 27TH, 2000:", "HEAD", 1.4, 1.8, 11],
	["FIRST TV APPEARANCE OF MAYOR ELECT", "N", 0.2, -1.0, 11],
	["(MOST WATCHED TV MOMENT IN CITY HISTORY)", "N", 0.4, 4.4, 11],
	["JULY 30TH, 2000 - INAUGURATION DAY.", "HEAD", 1.4, 2.4, 12],
	["I'M GONNA DO IT.", "SCRAWL", 0.2, 16.6, 12],
	["CASE REPORT:", "REP", 0.8, 1.2, 13],
	["THOMAS GRENDEL (ACTING CHIEF)", "REP", 0.1, 1.8, 13],
	["SUBJECT A (FULL NAME: DOUGLAS FETTICK)", "REP", 0.3, 2.4, 13],
	["A'S DIARY ENTRIES BECOME INCREASINGLY DERANGED UNTIL THE POINT OF INCOHERENCE.", "REP", 0.7, -1.0, 13],
	["A'S MOST COGENT MOMENT PAST THE SEVENTH PAGE IS SPENT PLANNING THE LOGISTICS OF THE ASSASSINATION.", "REP", 0.5, 7.4, 13],
	["", "BEAT", 0.6, 4.4, 14],
	["STATUS UNKNOWN", "END", 0.2, 5.6, 14],
]

const PAGES4 := 15
const CORK := Color("#e0a35e")
const CORK_DARK := Color("#a8692c")
const RUST := Color("#c0561c")
const OIL := Color("#2b2b3a")
const SEPIA := Color("#d9b98c")
const MANILA := Color("#f3d99b")
const DESK := Color("#a0662e")
const SHEET := Color("#fffdf7")
const LINE_BLUE := Color("#a9d4ff")
const MARGIN := Color("#ff9a9a")
const SHIRT := Color("#6f8f5a")
const JEANS := Color("#3d5a99")
const SKINS: Array[Color] = [Color("#f6d7c3"), Color("#e8bb94"), Color("#c68c5c"), Color("#94603c"), Color("#5c3b26")]
const PHRASE := "I'M GONNA DO IT."
## Inauguration day: [start, end, exponent] for each sheet, seconds after the scrawl begins.
const SCRAWL := [[0.0, 7.0, 1.7], [7.6, 11.0, 1.2], [11.6, 13.4, 1.0], [14.0, 15.4, 1.0]]
const PILE: Array[Vector2] = [Vector2(1470, 800), Vector2(1525, 690), Vector2(1440, 600)]
const HAMMER_P := 0.45

var page_xf := Transform2D.IDENTITY


func _build() -> void:
	reporters = []
	flashes = []
	flash_pos = []
	intrusions = []
	cards.clear()
	var at := 0.0
	for i in LINES4.size():
		var l: Array = LINES4[i]
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
	for pg in PAGES4:
		for i in cards.size():
			if int(cards[i]["pg"]) == pg:
				pages.append(cs(i))
				break
	var hits: Array = []
	var h0 := wt(6, "HAMMER") + 0.2
	var k := 0
	while h0 + k * HAMMER_P < ce(7) - 0.4:
		hits.append(h0 + k * HAMMER_P)
		k += 1
	var crumples: Array = []
	for q in SCRAWL.size() - 1:
		crumples.append(cs(47) + float(SCRAWL[q][1]))
	var sheets: Array = []
	for q2 in SCRAWL.size():
		sheets.append([cs(47) + float(SCRAWL[q2][0]), cs(47) + float(SCRAWL[q2][1])])
	var typing: Array = []
	for i2 in range(48, 53):
		typing.append([cs(i2), cs(i2) + _plain(String(cards[i2]["text"])).length() / CPS])
	return {"cards": starts, "pages": pages,
		"creak": wt(3, "CREAKY"), "squeak": wt(3, "SQUEAKY"), "leak": wt(3, "LEAKY"), "freaky": wt(3, "FREAKY"),
		"hammer": hits, "drill": wt(6, "DRILL"), "kill": wt(7, "KILL"), "dark": wt(7, "KILL") - 0.1,
		"name": cs(14), "pins": [cs(18) - 0.2, cs(18), cs(19), cs(20), cs(21), cs(22), cs(23), cs(24) + 0.6],
		"money": wt(22, "TWO"), "gavel": wt(22, "WON"), "cross": wt(24, "1973"), "x": wt(25, "SLIGHTEST"),
		"posters": [cs(28) - 0.2, cs(29) + 0.2, cs(30), cs(30) + 0.35, cs(30) + 0.7], "ballots": cs(31) + 0.6,
		"sheet": wt(34, "DECIDED"), "sunrise": cs(35), "together": wt(41, "TOGETHER"), "endnote": cs(42),
		"tv": cs(43) - 0.3, "scrawl": cs(47), "sheets": sheets, "crumples": crumples, "scrawl_end": cs(47) + float(SCRAWL[SCRAWL.size() - 1][1]),
		"report": cs(48), "typing": typing, "redact": wt(52, "LOGISTICS"), "confidential": ce(52) - 2.2,
		"question": cs(53) + 1.4, "end_line": cs(54), "end": T_END}


# ================================================================== draw
func _draw() -> void:
	C.frame = int(t * 8.0)
	C.boil = 1.0
	var rs := vp.x / W
	var cx := jb_cam_x()
	var shake := Vector2.ZERO
	var tau := t - cs(47)
	if tau > 6.0 and tau < float(SCRAWL[SCRAWL.size() - 1][1]):
		shake = Vector2(C.jit(23700, 1), C.jit(23701, 1)) * 7.0 * clampf((tau - 6.0) / 9.0, 0.0, 1.0)
	for pg in PAGES4:
		var x0 := pg * W
		if x0 + W < cx - W * 0.5 - 2.0 or x0 > cx + W * 0.5 + 2.0:
			continue
		page_xf = Transform2D(0.0, Vector2(rs, rs), 0.0, (Vector2(x0 - cx + W * 0.5, 0.0) + (shake if pg == 12 else Vector2.ZERO)) * rs)
		draw_set_transform_matrix(page_xf)
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		C.boil = 1.0
		match pg:
			0: fk_p0()
			1: fk_p1()
			2: fk_p2()
			3: fk_p3()
			4: fk_p4()
			5: fk_p5()
			6: fk_p6()
			7: fk_p7()
			8: fk_p8()
			9: fk_p9()
			10: fk_p10()
			11: fk_p11()
			12: fk_p12()
			13: fk_p13()
			14: fk_p14()
	C.boil = 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	_captions()
	fk_end()


func fk_push(c: Vector2, rot := 0.0, sc := 1.0) -> void:
	draw_set_transform_matrix(page_xf * Transform2D(rot, Vector2(sc, sc), 0.0, c))


func fk_pop() -> void:
	draw_set_transform_matrix(page_xf)


func fk_end() -> void:
	var i := cards.size() - 1
	if t < cs(i) - 0.6:
		return
	draw_rect(Rect2(0, 0, W, H), ca(INK, rv(cs(i) - 0.6, 0.6)))
	if t < cs(i):
		return
	var light := Color("#f4f0e6")
	txt_c("GEORGE CARRICK", 800.0, 380.0, 40, light, 30001, 2, rv(cs(i), 0.9))
	var size := 56
	var tw := C.letters_width("STATUS UNKNOWN", size)
	var x0 := 800.0 - tw * 0.5
	ln(Vector2(x0 - 210, 466), Vector2(x0 - 40, 466), light, 5.0, 30002, rv(cs(i) + 0.9, 0.5), 0.6)
	txt("STATUS UNKNOWN", Vector2(x0, 494), size, light, 30003, 3, rv(cs(i) + 1.3, 1.0))
	for k in 7:
		var rk := rv(cs(i) + 2.5 + k * 0.22, 0.12)
		if rk > 0.0:
			var sx := x0 + tw + 34.0 + k * 26.0
			ln(Vector2(sx, 496), Vector2(sx + 24, 436), RED, 6.0, 30010 + k, rk, 0.6)


# ================================================================== people
func fk_look(who: String) -> Dictionary:
	match who:
		"GC":
			return {"suit": NAVY, "skin": Color("#f4c2a1"), "tie": RED}
		"HC":
			return {"suit": Color("#6b4a2e"), "skin": Color("#ead0a8"), "tie": Color("#3a2a1a")}
		"SIL":
			return {"suit": Color("#2e2a33"), "skin": Color("#3c3742")}
	return {"suit": SHIRT, "skin": Color("#efc4a0")}


## Head and shoulders, for photographs, frames, posters and the television.
func fk_bust(hc: Vector2, r: float, who: String, s: int, rr: float, mood := "") -> void:
	if rr <= 0.0:
		return
	var lk := fk_look(who)
	var suit: Color = lk["suit"]
	var r1 := clampf(rr * 2.0, 0.0, 1.0)
	var r2 := clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	var neck := hc + Vector2(0, r * 0.9)
	var body := PackedVector2Array([neck + Vector2(-r * 0.55, 0), neck + Vector2(r * 0.55, 0), hc + Vector2(r * 2.0, r * 1.85),
		hc + Vector2(r * 2.25, r * 2.8), hc + Vector2(-r * 2.25, r * 2.8), hc + Vector2(-r * 2.0, r * 1.85)])
	solid(body, ca(suit.lightened(0.3), 0.6 * r1))
	fill(body, suit, s, r1, 4.0, -0.6, 3.6)
	edge(body, INK, 2.6, s + 1, r1)
	if r1 >= 1.0:
		if lk.has("tie"):
			var vee := PackedVector2Array([neck + Vector2(-r * 0.45, 0), neck + Vector2(r * 0.45, 0), neck + Vector2(0, r * 1.1)])
			solid(vee, WHITE)
			edge(vee, INK, 1.8, s + 2, 1.0, 0.4)
			var tie := PackedVector2Array([neck + Vector2(-r * 0.12, r * 0.05), neck + Vector2(r * 0.12, r * 0.05), neck + Vector2(r * 0.2, r * 1.3),
				neck + Vector2(0, r * 1.55), neck + Vector2(-r * 0.2, r * 1.3)])
			solid(tie, lk["tie"])
			edge(tie, INK, 1.6, s + 3, 1.0, 0.3)
		else:
			path(PackedVector2Array([neck + Vector2(-r * 0.5, 0), neck + Vector2(0, r * 0.6), neck + Vector2(r * 0.5, 0)]), INK, 2.2, s + 4)
			for sd: float in [-1.0, 1.0]:
				edge(C.rect_poly(Rect2(hc + Vector2(sd * r * 1.1 - r * 0.3, r * 1.9), Vector2(r * 0.6, r * 0.5))), INK, 1.8, s + 5 + int(sd), 1.0, 0.4)
	fk_head(hc, r, who, s + 20, r2, mood)


func fk_head(hc: Vector2, r: float, who: String, s: int, rr: float, mood := "") -> void:
	if rr <= 0.0:
		return
	var lk := fk_look(who)
	var skin: Color = lk["skin"]
	if who == "HC" and rr >= 1.0:
		for sd: float in [-1.0, 1.0]:
			solid(C.ellipse_poly(hc + Vector2(sd * r * 0.85, r * 0.35), r * 0.32, r * 0.55, 10, s + 40 + int(sd), 0.08), Color("#8a6a4a"))
	var head := circ(hc, r, s, 20)
	solid(head, ca(skin.lightened(0.05), rr))
	fill(head, skin.darkened(0.06), s + 1, rr, 4.4, 0.5, 2.6)
	edge(head, INK, 2.6, s + 2, rr)
	if rr < 1.0:
		return
	var ink := Color("#141215") if who == "SIL" else INK
	for sd2: float in [-1.0, 1.0]:
		var e := hc + Vector2(sd2 * r * 0.36, -r * 0.08)
		draw_circle(e, r * 0.085, ink)
		ln(e + Vector2(-sd2 * r * 0.16, -r * 0.24), e + Vector2(sd2 * r * 0.16, -r * 0.28), ink, 2.6, s + 3 + int(sd2), 1.0, 0.4)
	path(PackedVector2Array([hc + Vector2(0, r * 0.02), hc + Vector2(r * 0.1, r * 0.22), hc + Vector2(-r * 0.04, r * 0.24)]), ink, 2.2, s + 6)
	match who:
		"GC":
			fk_pomp(hc, r, s + 10)
			fk_grin(hc, r, s + 20, 1.0)
		"DF":
			for sd3: float in [-1.0, 1.0]:
				path(arc(hc, r * 1.02, r * 1.02, PI * (0.95 if sd3 < 0.0 else 1.78), PI * (1.22 if sd3 < 0.0 else 2.05), 5), GREY, r * 0.2, s + 30 + int(sd3))
				edge(circ(hc + Vector2(sd3 * r * 0.36, -r * 0.08), r * 0.2, s + 32 + int(sd3), 10), INK, 2.0, s + 34 + int(sd3), 1.0, 0.3)
			ln(hc + Vector2(-r * 0.16, -r * 0.08), hc + Vector2(r * 0.16, -r * 0.08), INK, 2.0, s + 36, 1.0, 0.2)
			var bd := arc(hc + Vector2(0, r * 0.12), r * 0.92, r * 0.86, 0.15, PI - 0.15, 12)
			bd.append_array(arc(hc + Vector2(0, r * 0.3), r * 0.5, r * 0.32, PI - 0.3, 0.3, 8))
			solid(bd, Color("#bdb6ab"))
			if mood == "smile":
				path(arc(hc + Vector2(0, r * 0.36), r * 0.26, r * 0.16, 0.3, PI - 0.3, 8), INK, 2.6, s + 37)
			else:
				ln(hc + Vector2(-r * 0.2, r * 0.48), hc + Vector2(r * 0.2, r * 0.46), INK, 2.6, s + 37, 1.0, 0.3)
		"HC":
			var hat := C.rect_poly(Rect2(hc + Vector2(-r * 0.72, -r * 2.15), Vector2(r * 1.44, r * 1.3)))
			solid(hat, Color("#2a2420"))
			edge(hat, INK, 2.2, s + 42, 1.0, 0.4)
			ln(hc + Vector2(-r * 1.15, -r * 0.84), hc + Vector2(r * 1.15, -r * 0.84), Color("#2a2420"), r * 0.2, s + 43, 1.0, 0.4)
			ln(hc + Vector2(-r * 0.25, r * 0.5), hc + Vector2(r * 0.25, r * 0.5), INK, 2.6, s + 44, 1.0, 0.3)


## George Carrick's hair: white, high at the front.
func fk_pomp(hc: Vector2, r: float, s: int) -> void:
	var p := PackedVector2Array()
	for k in 15:
		var a := PI + PI * k / 14.0
		var bump := 1.0 + 0.32 * exp(-pow(a - PI * 1.62, 2.0) / 0.05)
		p.append(hc + Vector2(cos(a) * r * 1.1, sin(a) * r * 1.02 * bump))
	p.append(hc + Vector2(r * 0.92, -r * 0.22))
	p.append(hc + Vector2(r * 0.3, -r * 0.6))
	p.append(hc + Vector2(-r * 0.3, -r * 0.62))
	p.append(hc + Vector2(-r * 0.92, -r * 0.22))
	solid(p, Color("#f3f3f6"))
	edge(p, INK, 2.2, s, 1.0, 0.6)
	path(arc(hc + Vector2(r * 0.15, -r * 0.7), r * 0.5, r * 0.3, PI * 1.1, PI * 1.9, 6), GREY, 2.0, s + 1)


## His grin: wide, white, every tooth.
func fk_grin(hc: Vector2, r: float, s: int, a: float) -> void:
	if a <= 0.01:
		return
	var g := arc(hc + Vector2(0, r * 0.22), r * 0.62, r * 0.5, 0.0, PI, 12)
	solid(g, ca(WHITE, a))
	edge(g, ca(INK, a), 2.4, s, 1.0, 0.5)
	for k in 5:
		var x := -r * 0.4 + k * r * 0.2
		var dep := sqrt(maxf(0.0, 1.0 - pow(x / (r * 0.62), 2.0))) * r * 0.5
		ln(hc + Vector2(x, r * 0.22), hc + Vector2(x, r * 0.22 + dep * 0.9), ca(INK, a * 0.8), 1.6, s + 1 + k, 1.0, 0.2)
	ln(hc + Vector2(-r * 0.55, r * 0.42), hc + Vector2(r * 0.55, r * 0.42), ca(INK, a * 0.6), 1.6, s + 7, 1.0, 0.3)
	for sd: float in [-1.0, 1.0]:
		solid(circ(hc + Vector2(sd * r * 0.68, r * 0.18), r * 0.14, s + 8 + int(sd), 8), ca(PINK, a * 0.45))


## George Carrick, standing. wave raises his left hand.
func fk_carrick(foot: Vector2, h: float, rr: float, wave := 0.0, dark := false) -> void:
	if rr <= 0.0:
		return
	var s := 21500 if not dark else 21700
	var rp := {"id": "GC", "foot": foot, "h": h, "s": s, "suit": NAVY, "skin": Color("#f4c2a1"), "tie": RED, "plain": true}
	if dark:
		rp = {"id": "SIL", "foot": foot, "h": h, "s": s, "suit": Color("#2e2a33"), "skin": Color("#3c3742"), "plain": true}
	var r := h * 0.165
	var hc := foot + Vector2(0, -h + r + sin(t * 1.3 + s) * h * 0.006)
	if wave > 0.0:
		var down := foot + Vector2(-h * 0.21, -h * 0.32)
		var up := hc + Vector2(-r * 2.4 + sin(t * 8.0) * r * 0.35, -r * 0.5)
		rp["hand_l"] = down.lerp(up, _ease(wave))
	_reporter(rp, rr, "frown" if dark else "smile", 0.0)
	if rr >= 0.67 and not dark:
		fk_pomp(hc, r, s + 200)
		fk_grin(hc, r, s + 210, 1.0)


func fk_douglas(foot: Vector2, h: float, rr: float, mouth := "frown") -> void:
	var rp := {"id": "DF", "foot": foot, "h": h, "s": 21800, "suit": SHIRT, "skin": Color("#efc4a0"), "hair": "bald",
		"hair_col": Color("#a7a29a"), "glasses": true, "beard": true, "plain": true}
	_reporter(rp, rr, mouth, 0.0)


## Douglas sitting, knees up, one hand free.
func fk_sit(hip: Vector2, h: float, s: int, rr: float, hand_r := Vector2.ZERO, mood := "") -> void:
	if rr <= 0.0:
		return
	var r := h * 0.11
	var hc := hip + Vector2(-h * 0.02, -h * 0.6)
	var r1 := clampf(rr * 2.0, 0.0, 1.0)
	var knee := hip + Vector2(h * 0.2, -h * 0.12)
	var ankle := knee + Vector2(h * 0.08, h * 0.15)
	ln(hip, knee, JEANS, h * 0.075, s, r1, 0.6)
	ln(knee, ankle, JEANS, h * 0.07, s + 1, r1, 0.6)
	if r1 >= 1.0:
		solid(oval(ankle + Vector2(h * 0.04, h * 0.01), h * 0.06, h * 0.03, s + 2, 10), INK)
	var neck := hc + Vector2(0, r * 0.9)
	var torso := PackedVector2Array([neck + Vector2(-r * 0.9, r * 0.2), neck + Vector2(r * 0.9, r * 0.2), hip + Vector2(r * 1.0, 0), hip + Vector2(-r * 1.1, 0)])
	solid(torso, ca(SHIRT.lightened(0.3), 0.6 * r1))
	fill(torso, SHIRT, s + 3, r1, 4.0, -0.6, 3.4)
	edge(torso, INK, 2.4, s + 4, r1)
	var sh := neck + Vector2(r * 0.6, r * 0.5)
	var hr := hand_r if hand_r != Vector2.ZERO else knee + Vector2(-h * 0.02, -h * 0.04)
	var el := sh.lerp(hr, 0.5) + Vector2(0, h * 0.05)
	ln(sh, el, SHIRT, h * 0.05, s + 5, r1, 0.6)
	ln(el, hr, SHIRT, h * 0.045, s + 6, r1, 0.6)
	if r1 >= 1.0:
		solid(circ(hr, h * 0.03, s + 7, 10), Color("#efc4a0"))
		edge(circ(hr, h * 0.03, s + 8, 10), INK, 1.6, s + 9, 1.0, 0.4)
	fk_head(hc, r, "DF", s + 20, clampf(rr * 2.0 - 1.0, 0.0, 1.0), mood)


## Little people: a body, a round head, a face for the mood.
func fk_folk(foot: Vector2, h: float, col: Color, skin: Color, s: int, rr: float, mood := "smile", hand_l := Vector2.ZERO, hand_r := Vector2.ZERO, a := 1.0) -> void:
	if rr <= 0.0 or a <= 0.01:
		return
	var r := h * 0.16
	var hc := foot + Vector2(0, -h + r)
	var neck := hc + Vector2(0, r)
	var hip := foot + Vector2(0, -h * 0.38)
	var ink := ca(INK, a)
	for sd: float in [-1.0, 1.0]:
		ln(hip + Vector2(sd * h * 0.06, 0), foot + Vector2(sd * h * 0.08, 0), ink, 3.0, s + 1 + int(sd), rr, 0.6)
	var body := PackedVector2Array([neck + Vector2(-h * 0.09, 0), neck + Vector2(h * 0.09, 0), hip + Vector2(h * 0.13, h * 0.03), hip + Vector2(-h * 0.13, h * 0.03)])
	solid(body, ca(col.lightened(0.3), a * 0.6 * rr))
	fill(body, ca(col, a), s + 3, rr, 3.4, -0.6, 3.2)
	edge(body, ink, 2.2, s + 4, rr, 0.8)
	var sh := neck + Vector2(0, h * 0.06)
	var hl := hand_l if hand_l != Vector2.ZERO else sh + Vector2(-h * 0.24, h * 0.2)
	var hr := hand_r if hand_r != Vector2.ZERO else sh + Vector2(h * 0.24, h * 0.2)
	ln(sh, hl, ink, 3.0, s + 5, rr, 0.6)
	ln(sh, hr, ink, 3.0, s + 6, rr, 0.6)
	var head := circ(hc, r, s + 7, 16)
	solid(head, ca(skin, a * rr))
	edge(head, ink, 2.2, s + 8, rr, 0.8)
	if rr < 1.0:
		return
	match mood:
		"scared":
			for sd2: float in [-1.0, 1.0]:
				var e := hc + Vector2(sd2 * r * 0.36, -r * 0.1)
				solid(circ(e, r * 0.22, s + 9 + int(sd2), 10), ca(WHITE, a))
				edge(circ(e, r * 0.22, s + 11 + int(sd2), 10), ink, 1.4, s + 13 + int(sd2), 1.0, 0.3)
				draw_circle(e, r * 0.08, ink)
			solid(oval(hc + Vector2(0, r * 0.45), r * 0.14, r * 0.2, s + 15, 10), ink)
			solid(C.ellipse_poly(hc + Vector2(r * 0.85, -r * 0.4), r * 0.1, r * 0.17, 8, s + 16, 0.05), ca(TEAR, a))
		"flat":
			draw_circle(hc + Vector2(-r * 0.34, -r * 0.08), r * 0.09, ink)
			draw_circle(hc + Vector2(r * 0.34, -r * 0.08), r * 0.09, ink)
			ln(hc + Vector2(-r * 0.25, r * 0.45), hc + Vector2(r * 0.25, r * 0.45), ink, 2.4, s + 17, 1.0, 0.3)
		_:
			draw_circle(hc + Vector2(-r * 0.34, -r * 0.08), r * 0.09, ink)
			draw_circle(hc + Vector2(r * 0.34, -r * 0.08), r * 0.09, ink)
			path(arc(hc + Vector2(0, r * 0.18), r * 0.42, r * 0.32, 0.35, PI - 0.35, 8), ca(RED, a), 2.4, s + 18)


# ================================================================== things
func fk_gear(c: Vector2, r: float, teeth: int, ang: float, col: Color, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var pts := PackedVector2Array()
	var n := teeth * 4
	for k in n:
		var a := ang + TAU * k / n
		var rad := r if (k % 4 == 1 or k % 4 == 2) else r * 0.78
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	solid(pts, ca(col.lightened(0.25), rr * 0.7))
	fill(pts, col, s, rr, 3.6, -0.5, 3.2)
	edge(pts, INK, 2.4, s + 1, rr, 0.6)
	if rr >= 1.0:
		solid(circ(c, r * 0.25, s + 2, 10), GREY.darkened(0.2))
		edge(circ(c, r * 0.25, s + 3, 10), INK, 2.0, s + 4, 1.0, 0.4)


## The machine: a contraption the way a child draws one. Nothing on it says what it does.
## st: dust, rust, star, nuts, creak, squeak, leak, eyes (0..1 each).
func fk_machine(c: Vector2, sc: float, s: int, rr: float, st := {}) -> void:
	if rr <= 0.0:
		return
	var lw := maxf(1.4, 2.8 * sqrt(sc))
	var r1 := clampf(rr * 2.0, 0.0, 1.0)
	var r2 := clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	fk_gear(c + Vector2(-240, -100) * sc, 95.0 * sc, 10, t * 0.6, Color("#e0b23a"), s, r1)
	fk_gear(c + Vector2(-120, -190) * sc, 55.0 * sc, 8, -t * 1.0 + 0.2, ORANGE, s + 10, r1)
	var ch := PackedVector2Array([c + Vector2(120, -100) * sc, c + Vector2(180, -100) * sc, c + Vector2(210, -235) * sc, c + Vector2(90, -235) * sc])
	solid(ch, ca(RED.lightened(0.3), r1 * 0.6))
	fill(ch, RED, s + 20, r1, 3.6, -0.5, 3.0)
	edge(ch, INK, lw, s + 21, r1)
	var sp := PackedVector2Array()
	for k in 9:
		sp.append(c + Vector2(-40.0 + (12.0 if k % 2 == 0 else -12.0), -100.0 - k * 11.0) * sc)
	path(sp, GREY.darkened(0.3), lw, s + 22, r1)
	var knob := circ(c + Vector2(-40, -212) * sc, 18.0 * sc, s + 23, 12)
	solid(knob, ca(PINK, r1))
	edge(knob, INK, lw * 0.8, s + 24, r1)
	for k2 in 2:
		var wc := c + Vector2(-150.0 + k2 * 300.0, 230.0) * sc
		var wob := 1.0 if k2 == 0 else 1.0 + 0.12 * sin(t * 3.0)
		var wh := C.ellipse_poly(wc, 55.0 * sc * wob, 55.0 * sc / wob, 16, s + 30 + k2, 0.08)
		solid(wh, ca(OIL, r1))
		edge(wh, INK, lw, s + 32 + k2, r1)
		if r1 >= 1.0:
			solid(circ(wc, 18.0 * sc, s + 34 + k2, 10), GREY)
			var sa := t * 2.0 + k2
			ln(wc, wc + Vector2(cos(sa), sin(sa)) * 40.0 * sc, GREY, lw, s + 36 + k2, 1.0, 0.3)
	var body := C.rect_poly(Rect2(c + Vector2(-240, -100) * sc, Vector2(480, 300) * sc))
	solid(body, ca(Color("#c9cdd6"), r1))
	fill(body, GREY, s + 25, r1, 4.2, -0.5, 3.6)
	edge(body, INK, lw * 1.1, s + 26, r1)
	if r2 <= 0.0:
		return
	# rust
	var rust := float(st.get("rust", 1.0))
	if rust > 0.0:
		var spots: Array[Vector2] = [Vector2(-180, -40), Vector2(150, 150), Vector2(70, -62), Vector2(-60, 172), Vector2(205, 20)]
		for k3 in spots.size():
			var bl := C.ellipse_poly(c + spots[k3] * sc, 30.0 * sc, 19.0 * sc, 10, s + 40 + k3, 0.25, k3 * 0.7)
			fill(bl, RUST, s + 45 + k3, clampf(rust * 5.0 - k3, 0.0, 1.0), 2.6, 0.6, 2.6)
	# rivets, dial, buttons
	for k4 in 8:
		draw_circle(c + Vector2(-210.0 + k4 * 60.0, -82.0) * sc, 4.0 * sc + 0.6, ca(INK, r2))
		draw_circle(c + Vector2(-210.0 + k4 * 60.0, 182.0) * sc, 4.0 * sc + 0.6, ca(INK, r2))
	var dc := c + Vector2(0, 70) * sc
	var dial := circ(dc, 52.0 * sc, s + 50, 18)
	solid(dial, ca(WHITE, r2))
	edge(dial, INK, lw, s + 51, r2)
	if r2 >= 1.0:
		var na := -PI * 0.5 - 0.8 + 0.5 * sin(t * 2.3) + C.jit(s + 52, 1) * 0.06
		ln(dc, dc + Vector2(cos(na), sin(na)) * 40.0 * sc, RED, lw, s + 53, 1.0, 0.2)
		var bc: Array[Color] = [RED, SUN, SKY]
		for k5 in 3:
			var b := circ(c + Vector2(-200.0 + k5 * 40.0, 140.0) * sc, 14.0 * sc, s + 54 + k5, 10)
			solid(b, bc[k5])
			edge(b, INK, lw * 0.7, s + 57 + k5, 1.0, 0.3)
		# the crank, going round
		var ax := c + Vector2(270, 40) * sc
		ln(c + Vector2(240, 40) * sc, ax, INK, lw * 1.4, s + 60, 1.0, 0.3)
		var ca2 := t * 1.6
		var tip := ax + Vector2(cos(ca2), sin(ca2)) * 62.0 * sc
		ln(ax, tip, GREY.darkened(0.3), lw * 1.6, s + 61, 1.0, 0.3)
		solid(circ(tip, 13.0 * sc, s + 62, 10), PINK)
		edge(circ(tip, 13.0 * sc, s + 63, 10), INK, lw * 0.7, s + 64, 1.0, 0.3)
		# smoke
		for k6 in 4:
			var ph := fmod(t * 0.45 + k6 * 0.25, 1.0)
			var pc := c + Vector2(150.0 + sin(t + k6) * 20.0, -255.0 - ph * 150.0) * sc
			solid(circ(pc, (14.0 + ph * 26.0) * sc, s + 65 + k6, 12), ca(GREY.lightened(0.35), 0.7 * (1.0 - ph)))
	var star_k := float(st.get("star", 0.0))
	star(c + Vector2(178, 112) * sc, 26.0 * sc, GOLD, s + 70, star_k)
	var eyes := float(st.get("eyes", 0.0))
	if eyes > 0.0:
		for k7 in 2:
			var ec := c + Vector2(-90.0 + k7 * 180.0, -30.0) * sc
			var ew := circ(ec, 36.0 * sc * eyes, s + 72 + k7, 14)
			solid(ew, WHITE)
			edge(ew, INK, lw, s + 74 + k7, 1.0, 0.4)
			var po := Vector2(cos(t * 4.7 + k7 * 2.0), sin(t * 3.9 + k7)) * 14.0 * sc
			draw_circle(ec + po * eyes, 14.0 * sc * eyes, INK)
	var dust := float(st.get("dust", 0.0))
	if dust > 0.0:
		for k8 in 9:
			var ph2 := fmod(t * 0.3 + C.rnd(s + 80, k8), 1.0)
			var dp := c + Vector2(-260.0 + C.rnd(s + 81, k8) * 520.0, -110.0 + C.rnd(s + 82, k8) * 300.0 - ph2 * 60.0) * sc
			solid(circ(dp, (10.0 + ph2 * 18.0) * sc, s + 83 + k8, 10), ca(Color("#b8ad98"), 0.55 * dust * (1.0 - ph2)))
	var leak := float(st.get("leak", 0.0))
	if leak > 0.0:
		var pud := C.ellipse_poly(c + Vector2(232, 300) * sc, (22.0 + 52.0 * leak) * sc, (7.0 + 9.0 * leak) * sc, 14, s + 90, 0.12)
		solid(pud, ca(OIL, 0.85))
		var dph := fmod(t * 1.1, 1.0)
		draw_circle(c + Vector2(205, 205.0 + dph * 90.0) * sc, 6.0 * sc, OIL)
	var nuts := float(st.get("nuts", 0.0))
	if nuts > 0.0:
		var xs: Array[float] = [-330.0, -260.0, -40.0, 30.0, 300.0, 360.0, -400.0]
		for k9 in xs.size():
			var a9 := clampf(nuts * 7.0 - k9, 0.0, 1.0)
			if a9 <= 0.0:
				continue
			var np := c + Vector2(xs[k9], 290.0 - (k9 % 2) * 8.0) * sc
			if k9 % 2 == 0:
				var hx := PackedVector2Array()
				for q in 6:
					hx.append(np + Vector2(cos(TAU * q / 6.0 + k9), sin(TAU * q / 6.0 + k9)) * 13.0 * sc)
				solid(hx, ca(GREY, a9))
				edge(hx, ca(INK, a9), 1.8, s + 100 + k9, 1.0, 0.3)
				draw_circle(np, 5.0 * sc, ca(SHEET, a9))
			else:
				ln(np + Vector2(-16, 0) * sc, np + Vector2(18, 0) * sc, ca(GREY.darkened(0.3), a9), 6.0 * sc, s + 110 + k9, 1.0, 0.3)
				solid(C.rect_poly(Rect2(np + Vector2(-24, -9) * sc, Vector2(10, 18) * sc)), ca(GREY.darkened(0.2), a9))
	var creak := float(st.get("creak", 0.0))
	jb_jag(c + Vector2(-420, -230) * sc, "CREAK!", int(28.0 * sc), INK, s + 120, creak)
	var squeak := float(st.get("squeak", 0.0))
	jb_jag(c + Vector2(440, -260) * sc, "SQUEAK!", int(28.0 * sc), PURPLE, s + 125, squeak)


## A label with an arrow, the way she labelled her drawings.
func fk_label(text: String, at: Vector2, to: Vector2, col: Color, size: int, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var tw := C.letters_width(text, size)
	txt(text, at, size, col, s, 2, rr)
	var st := at + Vector2(-12.0, -size * 0.35) if to.x < at.x else at + Vector2(tw + 12.0, -size * 0.35)
	var ra := rv(0.0, 1.0) * clampf(rr * 2.0 - 1.0, 0.0, 1.0)
	if ra <= 0.0:
		return
	ln(st, to, col, 3.0, s + 1, ra, 0.6)
	if ra >= 1.0:
		var d := (to - st).normalized()
		var nrm := Vector2(-d.y, d.x)
		ln(to, to - d * 16.0 + nrm * 9.0, col, 3.0, s + 2, 1.0, 0.3)
		ln(to, to - d * 16.0 - nrm * 9.0, col, 3.0, s + 3, 1.0, 0.3)


func fk_pin(p: Vector2, s: int, col: Color = RED) -> void:
	solid(circ(p, 9.0, s, 10), col)
	edge(circ(p, 9.0, s + 1, 10), INK, 1.6, s + 2, 1.0, 0.3)
	draw_circle(p + Vector2(-3, -3), 2.6, Color(1, 1, 1, 0.8))


func fk_string(a: Vector2, b: Vector2, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var pts := PackedVector2Array()
	var sag := a.distance_to(b) * 0.07
	for k in 13:
		var f := float(k) / 12.0
		pts.append(a.lerp(b, f) + Vector2(0, sin(PI * f) * sag))
	path(pts, RED, 3.0, s, rr, 0.6)


func fk_cork(s: int, rr: float) -> void:
	var board := C.rect_poly(Rect2(30, 26, 1540, 676))
	solid(board, ca(CORK.lightened(0.25), rr))
	fill(board, CORK, s, rr, 4.4, -0.5, 4.0)
	edge(board, BROWN.darkened(0.2), 7.0, s + 1, rr, 1.0)
	if rr >= 1.0:
		for k in 140:
			draw_circle(Vector2(40.0 + C.rnd(s + 2, k) * 1520.0, 36.0 + C.rnd(s + 3, k) * 656.0), 1.6 + C.rnd(s + 4, k) * 1.6, ca(CORK_DARK, 0.6))


func fk_card(r: Rect2, s: int, rr: float, tint: Color = WHITE) -> void:
	if rr <= 0.0:
		return
	var p := PackedVector2Array([r.position + Vector2(C.rnd(s, 1) * 6.0, C.rnd(s, 2) * 6.0), Vector2(r.end.x, r.position.y) + Vector2(-C.rnd(s, 3) * 6.0, C.rnd(s, 4) * 6.0),
		r.end + Vector2(-C.rnd(s, 5) * 6.0, -C.rnd(s, 6) * 6.0), Vector2(r.position.x, r.end.y) + Vector2(C.rnd(s, 7) * 6.0, -C.rnd(s, 8) * 6.0)])
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(5, 6))
	solid(sh, ca(Color(0, 0, 0, 0.18), rr))
	solid(p, ca(tint, rr))
	edge(p, ca(GREY.darkened(0.3), rr), 1.8, s + 9, rr, 0.5)
	if rr >= 1.0:
		ln(Vector2(r.position.x + 10, r.position.y + 40), Vector2(r.end.x - 10, r.position.y + 40), MARGIN, 2.0, s + 10, 1.0, 0.3)
		fk_pin(Vector2(r.get_center().x, r.position.y + 14), s + 11)


## A photograph with a white border, pinned at the top.
func fk_polaroid(c: Vector2, w: float, who: String, s: int, rr: float, caption := "", rot := 0.0, mood := "") -> void:
	if rr <= 0.0:
		return
	var h := w * 1.18
	fk_push(c, rot)
	var fr := C.rect_poly(Rect2(-w * 0.5, -h * 0.5, w, h))
	var sh := PackedVector2Array()
	for q in fr:
		sh.append(q + Vector2(6, 7))
	solid(sh, ca(Color(0, 0, 0, 0.2), rr))
	solid(fr, ca(WHITE, rr))
	edge(fr, ca(GREY.darkened(0.3), rr), 2.0, s, rr, 0.5)
	var pw := w * 0.86
	var top := -h * 0.5 + w * 0.07
	var ph := C.rect_poly(Rect2(-pw * 0.5, top, pw, pw))
	solid(ph, ca(Color("#9cc9ff") if who != "HC" else SEPIA, rr))
	if rr >= 1.0:
		fk_bust(Vector2(0, top + pw * 0.42), pw * 0.17, who, s + 10, 1.0, mood)
		if caption != "":
			txt_c(caption, 0.0, h * 0.5 - w * 0.075, int(w * 0.075), INK, s + 5, 2)
		fk_pin(Vector2(0, -h * 0.5 + 10), s + 9)
	fk_pop()


func fk_stamp(c: Vector2, text: String, size: int, col: Color, rot: float, s: int, t0: float) -> void:
	if t < t0:
		return
	var k := rv(t0, 0.14)
	var sc := lerpf(1.7, 1.0, _ease(k))
	var a := minf(1.0, k * 1.5)
	fk_push(c, rot, sc)
	var tw := C.letters_width(text, size)
	edge(C.rect_poly(Rect2(-tw * 0.5 - 28, -size * 0.85, tw + 56, size * 1.5)), ca(col, a * 0.9), 5.0, s, 1.0, 1.2)
	edge(C.rect_poly(Rect2(-tw * 0.5 - 17, -size * 0.7, tw + 34, size * 1.2)), ca(col, a * 0.75), 2.4, s + 1, 1.0, 0.8)
	txt(text, Vector2(-tw * 0.5, size * 0.42), size, ca(col, a * 0.92), s + 2, 3, 1.0)
	fk_pop()


func fk_hammer(hand: Vector2, ang: float, ln_: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var d := Vector2(cos(ang), sin(ang))
	var tip := hand + d * ln_
	ln(hand - d * ln_ * 0.2, tip, BROWN, ln_ * 0.12, s, rr, 0.4)
	if rr >= 1.0:
		var nrm := Vector2(-d.y, d.x)
		var head := PackedVector2Array([tip + nrm * ln_ * 0.28 - d * ln_ * 0.1, tip + nrm * ln_ * 0.28 + d * ln_ * 0.1, tip - nrm * ln_ * 0.22 + d * ln_ * 0.1, tip - nrm * ln_ * 0.22 - d * ln_ * 0.1])
		solid(head, GREY.darkened(0.25))
		edge(head, INK, 2.0, s + 1, 1.0, 0.3)


func fk_drill(c: Vector2, sz: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var body := C.rect_poly(Rect2(c + Vector2(-sz * 0.5, -sz * 0.5), Vector2(sz, sz * 0.36)))
	solid(body, ca(ORANGE, rr))
	edge(body, INK, 2.2, s, rr, 0.5)
	var grip := PackedVector2Array([c + Vector2(-sz * 0.3, -sz * 0.14), c + Vector2(-sz * 0.05, -sz * 0.14), c + Vector2(-sz * 0.1, sz * 0.3), c + Vector2(-sz * 0.38, sz * 0.3)])
	solid(grip, ca(INK.lightened(0.15), rr))
	if rr >= 1.0:
		ln(c + Vector2(sz * 0.5, -sz * 0.32), c + Vector2(sz * 0.92, -sz * 0.32), GREY.darkened(0.3), 4.0, s + 1, 1.0, 0.3)
		for q in 4:
			var x := sz * (0.56 + q * 0.09)
			ln(c + Vector2(x, -sz * 0.4), c + Vector2(x + sz * 0.05, -sz * 0.24), INK, 1.4, s + 2 + q, 1.0, 0.2)


func fk_cityhall(c: Vector2, w: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var stone := Color("#f2ead7")
	var base := C.rect_poly(Rect2(c + Vector2(-w * 0.5, w * 0.2), Vector2(w, w * 0.12)))
	fill(base, GREY.lightened(0.2), s, rr, 3.6, -0.4, 3.0)
	edge(base, INK, 2.2, s + 1, rr, 0.5)
	var hall := C.rect_poly(Rect2(c + Vector2(-w * 0.42, -w * 0.18), Vector2(w * 0.84, w * 0.38)))
	solid(hall, ca(stone, rr))
	edge(hall, INK, 2.2, s + 2, rr, 0.5)
	var ped := PackedVector2Array([c + Vector2(-w * 0.48, -w * 0.18), c + Vector2(0, -w * 0.38), c + Vector2(w * 0.48, -w * 0.18)])
	fill(ped, GREY.lightened(0.1), s + 3, rr, 3.4, 0.4, 3.0)
	edge(ped, INK, 2.2, s + 4, rr, 0.5)
	if rr < 1.0:
		return
	for q in 4:
		var x := -w * 0.3 + q * w * 0.2
		solid(C.rect_poly(Rect2(c + Vector2(x - w * 0.035, -w * 0.15), Vector2(w * 0.07, w * 0.35))), WHITE)
		edge(C.rect_poly(Rect2(c + Vector2(x - w * 0.035, -w * 0.15), Vector2(w * 0.07, w * 0.35))), INK, 1.6, s + 5 + q, 1.0, 0.3)
	var dome := arc(c + Vector2(0, -w * 0.38), w * 0.16, w * 0.14, PI, TAU, 10)
	solid(dome, GOLD)
	edge(dome, INK, 2.0, s + 10, 1.0, 0.4)
	ln(c + Vector2(0, -w * 0.52), c + Vector2(0, -w * 0.68), INK, 2.4, s + 11, 1.0, 0.3)
	var flag := PackedVector2Array([c + Vector2(0, -w * 0.68), c + Vector2(w * 0.14, -w * 0.64 + sin(t * 4.0) * 3.0), c + Vector2(0, -w * 0.6)])
	solid(flag, RED)


func fk_gavel(c: Vector2, sz: float, ang: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var blk := C.ellipse_poly(c + Vector2(sz * 0.95, sz * 0.42), sz * 0.36, sz * 0.12, 12, s, 0.05)
	solid(blk, ca(BROWN.darkened(0.2), rr))
	edge(blk, INK, 2.0, s + 1, rr, 0.4)
	fk_push(c, ang)
	var hd := C.rect_poly(Rect2(Vector2(0, -sz * 0.06), Vector2(sz, sz * 0.12)))
	solid(hd, ca(BROWN, rr))
	edge(hd, INK, 1.8, s + 2, rr, 0.3)
	var head := C.rect_poly(Rect2(Vector2(sz * 0.82, -sz * 0.3), Vector2(sz * 0.32, sz * 0.6)))
	solid(head, ca(BROWN.darkened(0.15), rr))
	fill(head, BROWN.darkened(0.3), s + 3, rr, 3.0, 1.2, 2.6)
	edge(head, INK, 2.2, s + 4, rr, 0.4)
	fk_pop()


func fk_poster(c: Vector2, w: float, rot: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	fk_push(c, rot)
	var p := C.rect_poly(Rect2(-w * 0.5, -w * 0.55, w, w * 1.1))
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(6, 7))
	solid(sh, ca(Color(0, 0, 0, 0.18), rr))
	solid(p, ca(WHITE, rr))
	edge(p, ca(INK, rr), 2.2, s, rr, 0.5)
	if rr >= 1.0:
		solid(C.rect_poly(Rect2(-w * 0.5, -w * 0.55, w, w * 0.07)), RED)
		solid(C.rect_poly(Rect2(-w * 0.5, w * 0.48, w, w * 0.07)), NAVY)
		txt_c("CARRICK", 0.0, -w * 0.3, int(w * 0.16), RED, s + 1, 3)
		fk_bust(Vector2(0, -w * 0.07), w * 0.11, "GC", s + 10, 1.0)
		txt_c("FOR MAYOR", 0.0, w * 0.43, int(w * 0.1), NAVY, s + 2, 3)
		for sd: float in [-1.0, 1.0]:
			star(Vector2(sd * w * 0.36, -w * 0.07), w * 0.06, GOLD, s + 3 + int(sd))
	fk_pop()


func fk_ball(c: Vector2, r: float, s: int) -> void:
	var pts := PackedVector2Array()
	for q in 14:
		var a := TAU * q / 14.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.78 + 0.4 * C.rnd(s, q)))
	solid(pts, SHEET)
	edge(pts, INK, 2.2, s + 1, 1.0, 0.6)
	for q2 in 4:
		var a2 := C.rnd(s + 2, q2) * TAU
		ln(c + Vector2(cos(a2), sin(a2)) * r * 0.1, c + Vector2(cos(a2 + 0.6), sin(a2 + 0.6)) * r * 0.6, GREY, 1.6, s + 3 + q2, 1.0, 0.4)
		ln(c + Vector2(cos(a2 + 2.0), sin(a2 + 2.0)) * r * 0.3, c + Vector2(cos(a2 + 2.4), sin(a2 + 2.4)) * r * 0.7, LINE_BLUE, 1.6, s + 8 + q2, 1.0, 0.4)


# ================================================================== page 0: the notebook
func fk_p0() -> void:
	var desk := C.rect_poly(Rect2(-10, -10, W + 20, H + 20))
	fill(desk, DESK, 20000, rv(0.0, 0.8), 4.6, 1.2, 4.4)
	var rn := rv(0.2, 1.2)
	fk_push(Vector2(780, 450), -0.035)
	var cover := C.rect_poly(Rect2(-330, -400, 660, 800))
	solid(cover, ca(Color("#1d1c22"), rn))
	if rn >= 1.0:
		for k in 110:
			var p := Vector2((C.rnd(20010, k) - 0.5) * 640.0, (C.rnd(20011, k) - 0.5) * 780.0)
			var bl := C.ellipse_poly(p, 6.0 + C.rnd(20012, k) * 20.0, 4.0 + C.rnd(20013, k) * 10.0, 9, 20014 + k, 0.35, C.rnd(20015, k) * TAU)
			solid(bl, Color(1, 1, 1, 0.8))
		solid(C.rect_poly(Rect2(-330, -400, 70, 800)), Color("#0f0e12"))
	edge(cover, INK, 3.0, 20001, rn)
	var rl := rv(0.9, 0.5)
	var lab := C.rect_poly(Rect2(-230, -250, 460, 330))
	solid(lab, ca(WHITE, rl))
	edge(lab, INK, 2.2, 20002, rl)
	if rl >= 1.0:
		for k2 in 3:
			ln(Vector2(-210, -126 + k2 * 66), Vector2(210, -126 + k2 * 66), LINE_BLUE, 2.0, 20003 + k2, 1.0, 0.3)
	txt_c("THIS MACHINE", 0.0, -134.0, 46, INK, 20010, 3, rv(1.3, 1.2))
	txt_c("KILLS TYRANTS", 0.0, -68.0, 46, RED, 20011, 3, rv(2.4, 1.2))
	txt_c("JULY 20TH, 2000", 0.0, 0.0, 30, INK, 20012, 2, rv(3.6, 0.9))
	fk_pop()
	# the evidence tag on its string
	var rt := rv(4.4, 0.6)
	if rt > 0.0:
		path(PackedVector2Array([Vector2(1090, 800), Vector2(1140, 760), Vector2(1190, 700)]), Color("#f3f0e6"), 3.0, 20020, rt)
		fk_push(Vector2(1330, 660), 0.08)
		var tag := PackedVector2Array([Vector2(-150, -70), Vector2(150, -70), Vector2(150, 70), Vector2(-150, 70), Vector2(-178, 0)])
		solid(tag, ca(MANILA, rt))
		edge(tag, INK, 2.2, 20021, rt, 0.5)
		if rt >= 1.0:
			edge(circ(Vector2(-150, 0), 9.0, 20022, 10), INK, 1.8, 20023, 1.0, 0.3)
			txt("PCPD EVIDENCE", Vector2(-124, -26), 26, RED, 20024, 2)
			txt("EXHIBIT A", Vector2(-124, 14), 28, INK, 20025, 2)
			txt("SUBJ: FETTICK, D.", Vector2(-124, 50), 20, INK, 20026, 1)
		fk_pop()


# ================================================================== page 1: the machine
func fk_p1() -> void:
	var t0 := cs(1)
	var c := Vector2(800, 400)
	var st := {"dust": rv(wt(2, "DUSTY"), 0.5), "rust": rv(wt(2, "RUSTY"), 0.6), "star": rv(wt(2, "TRUSTY"), 0.4),
		"nuts": rv(wt(2, "NUTS"), 1.0), "creak": rv(wt(3, "CREAKY"), 0.3), "squeak": rv(wt(3, "SQUEAKY"), 0.3),
		"leak": rv(wt(3, "LEAKY"), 2.4), "eyes": rv(wt(3, "FREAKY"), 0.4)}
	if t < wt(3, "CREAKY") + 2.6:
		st["creak"] = float(st["creak"]) * (1.0 - rv(wt(3, "CREAKY") + 2.2, 0.4))
	else:
		st["creak"] = 0.0
	if t >= wt(3, "SQUEAKY") + 2.6:
		st["squeak"] = 0.0
	# when it creaks, it shakes
	var jig := Vector2.ZERO
	if t > wt(3, "CREAKY") and t < wt(3, "SQUEAKY") + 1.0:
		jig = Vector2(C.jit(20100, 1), C.jit(20101, 1)) * 3.0
	fk_machine(c + jig, 1.0, 20200, rv(t0 - 0.3, 1.8), st)
	fk_label("METAL", Vector2(1210, 240), Vector2(1045, 318), PURPLE, 30, 20300, rv(wt(3, "METAL"), 0.4))
	fk_label("PLASTIC", Vector2(1210, 400), Vector2(1110, 455), PURPLE, 30, 20310, rv(wt(3, "PLASTIC"), 0.4))
	fk_label("RUBBER", Vector2(180, 600), Vector2(590, 632), PURPLE, 30, 20320, rv(wt(3, "RUBBER"), 0.4))
	fk_label("OIL", Vector2(1230, 680), Vector2(1095, 696), PURPLE, 30, 20330, rv(wt(3, "OIL"), 0.4))


# ================================================================== page 2: the hill
func fk_hill_y(x: float) -> float:
	return 330.0 + pow((x - 800.0) / 600.0, 2.0) * 370.0


func fk_hill(s: int, rr: float) -> void:
	var pts := PackedVector2Array()
	for k in 25:
		var x := lerpf(140.0, 1460.0, k / 24.0)
		pts.append(Vector2(x, fk_hill_y(x)))
	pts.append(Vector2(1460, 820))
	pts.append(Vector2(140, 820))
	solid(pts, ca(HILL.lightened(0.25), rr * 0.6))
	fill(pts, HILL, s, rr, 4.4, -0.9, 4.2)
	var top := PackedVector2Array()
	for k2 in 25:
		top.append(pts[k2])
	path(top, GRASS_DARK, 3.6, s + 1, rr)


func fk_p2() -> void:
	var t0 := cs(4)
	var dark := rv(wt(7, "KILL") - 0.1, 0.9)
	sky_strip(700.0, SKY, 20400, rv(t0 - 0.5, 0.8))
	sun(Vector2(1320, 150), 70.0, 20401, rv(t0 - 0.2, 0.8))
	cloud(Vector2(300, 110), 200.0, 20402, rv(t0, 0.6))
	fk_hill(20410, rv(t0 - 0.4, 1.0))
	grass_strip(690.0, 20420, rv(t0 - 0.3, 0.8))
	# the toolbox, the machine, the man
	var rb := rv(wt(5, "PRACTICED") - 0.2, 0.6)
	var tb := C.rect_poly(Rect2(560, 318, 90, 52))
	solid(tb, ca(RED, rb))
	edge(tb, INK, 2.2, 20430, rb)
	if rb >= 1.0:
		path(arc(Vector2(605, 318), 24.0, 16.0, PI, TAU, 8), INK, 3.0, 20431)
	fk_machine(Vector2(900, 249), 0.32, 20440, rv(wt(4, "MACHINE") - 0.2, 1.4), {"rust": 1.0})
	var hip := Vector2(700, 336)
	var h := 240.0
	var hand := hip + Vector2(h * 0.36, -h * 0.2)
	var ham_on := t >= wt(6, "HAMMER") - 0.1
	var hammering := t >= wt(6, "HAMMER") + 0.2 and t < ce(7) - 0.4
	var ang := -0.35
	if hammering:
		var p := fmod(t - wt(6, "HAMMER") - 0.2, HAMMER_P) / HAMMER_P
		ang = -0.3 - 1.1 * sin(PI * p)
		hand.y -= h * 0.06 * sin(PI * p)
	fk_sit(hip, h, 20460, rv(wt(4, "SAT") - 0.4, 1.0), hand if ham_on else Vector2.ZERO)
	fk_hammer(hand, ang, 64.0, 20490, rv(wt(6, "HAMMER") - 0.1, 0.3))
	# skill: sparkles round his hands
	var rk := rv(wt(5, "SKILL") - 0.2, 0.4)
	if rk > 0.0 and t < ce(6):
		for q in 4:
			var tw := 0.5 + 0.5 * sin(t * 6.0 + q * 1.7)
			star(Vector2(790 + q * 34, 230 + (q % 2) * 40), 10.0 + 6.0 * tw, GOLD, 20500 + q, rk)
	var rd := rv(wt(6, "DRILL") - 0.1, 0.4)
	fk_drill(Vector2(1080, 385), 70.0, 20510, rd)
	if rd >= 1.0 and t < ce(6) + 0.8:
		jb_jag(Vector2(1190, 300), "BZZZ!", 24, ORANGE, 20520, 1.0)
	# to kill: the weather turns
	if dark > 0.0:
		draw_rect(Rect2(-10, -10, W + 20, H + 20), ca(Color("#1e1830"), 0.38 * dark))
		for q2 in 3:
			var cx := lerpf(1800.0 + q2 * 160.0, 1180.0 + q2 * 130.0, _ease(rv(wt(7, "KILL") - 0.1 + q2 * 0.15, 1.2)))
			var bl := C.ellipse_poly(Vector2(cx, 130 + q2 * 36), 170.0, 66.0, 18, 20530 + q2, 0.14)
			solid(bl, Color("#3a3446"))
			fill(bl, Color("#251f30"), 20540 + q2, 1.0, 4.0, -0.3, 3.6)


# ================================================================== page 3: one man
func fk_p3() -> void:
	var t0 := cs(8)
	var grow := _ease(rv(wt(11, "POWERFUL"), 1.0))
	var h := 520.0 * (1.0 + 0.1 * grow)
	var foot := Vector2(640, 700)
	var name_t := cs(14)
	var wave := rv(wt(13, "FRIENDLY"), 0.6)
	if t < name_t + 0.8:
		fk_carrick(foot, h, rv(wt(8, "ONE") - 0.3, 1.6), wave, true)
		var r := h * 0.165
		var hc := foot + Vector2(0, -h + r + sin(t * 1.3 + 21700) * h * 0.006)
		fk_grin(hc, r, 21760, rv(wt(13, "FRIENDLY"), 0.5))
		var fade := rv(name_t, 0.8)
		if fade > 0.0:
			draw_texture_rect_region(paper, Rect2(380, 60, 560, 660), Rect2(190, 30, 280, 330), Color(1, 1, 1, fade))
	fk_carrick(foot, h, rv(name_t + 0.3, 1.4), wave)
	if wave >= 1.0:
		var hl := foot + Vector2(-h * 0.165 * 2.4, -h + h * 0.165 * 0.5)
		jb_jag(hl + Vector2(-20, -70), "HI!", 26, PURPLE, 21780, 1.0)
	txt("1", Vector2(150, 290), 210, RED, 21800, 3, rv(cs(10), 0.5))
	fk_label("FRIENDLY", Vector2(990, 160), Vector2(715, 250), PURPLE, 34, 21810, rv(cs(13), 0.4))
	fk_label("BAD", Vector2(990, 270), Vector2(735, 400), RED, 34, 21820, rv(wt(9, "BAD"), 0.4))
	fk_label("POWERFUL", Vector2(990, 380), Vector2(790, 470), NAVY, 34, 21830, rv(cs(11), 0.4))
	fk_label("WEALTHY", Vector2(990, 490), Vector2(830, 600), CASH_DARK, 34, 21840, rv(cs(12), 0.4))
	var rw := rv(cs(12), 0.6)
	jb_bag(Vector2(800, 655), 42.0, 21850, rw)
	jb_bag(Vector2(870, 668), 32.0, 21851, rv(cs(12) + 0.2, 0.5))
	jb_bag(Vector2(745, 676), 24.0, 21852, rv(cs(12) + 0.4, 0.5))
	if rw >= 1.0:
		for q in 3:
			jb_bill(Vector2(930 + q * 22, 560 + sin(t * 2.0 + q) * 8.0), 48.0, 0.3 * q - 0.2, 21860 + q, 1.0)
	var rn := rv(name_t, 1.4)
	txt("GEORGE", Vector2(110, 470), 62, RED, 21870, 3, rn)
	txt("CARRICK", Vector2(110, 550), 62, RED, 21871, 3, rv(name_t + 0.6, 1.2))


# ================================================================== page 4: monster, hero, insane
func fk_p4() -> void:
	var t0 := cs(15)
	var xs: Array[float] = [330.0, 800.0, 1270.0]
	var labels := ["MONSTER", "HERO", "INSANE"]
	var lab_t: Array[float] = [wt(15, "MONSTER"), wt(16, "HERO"), wt(17, "INSANE")]
	var insane := rv(wt(17, "INSANE"), 0.5)
	for k in 3:
		var x := xs[k]
		var rf := rv(t0 - 0.4 + k * 0.2, 0.7)
		var fr := C.rect_poly(Rect2(x - 180, 40, 360, 430))
		solid(fr, ca(GOLD.darkened(0.15), rf))
		edge(fr, INK, 2.6, 22000 + k, rf)
		var inner := C.rect_poly(Rect2(x - 150, 66, 300, 378))
		solid(inner, ca(Color("#cfe6ff"), rf))
		edge(inner, INK, 1.8, 22010 + k, rf, 0.5)
		var hc := Vector2(x, 220)
		var r := 62.0
		if k == 1:
			var cape := rv(lab_t[1], 0.5)
			if cape > 0.0:
				var cp := PackedVector2Array([hc + Vector2(-r * 1.0, r * 0.95), hc + Vector2(r * 1.0, r * 0.95), hc + Vector2(r * 2.35, r * 3.5), hc + Vector2(-r * 2.35, r * 3.5)])
				fill(cp, RED, 22020, cape, 3.6, -0.5, 3.4)
				edge(cp, RED.darkened(0.3), 2.4, 22021, cape)
		fk_bust(hc, r, "DF", 22030 + k * 60, rf)
		var rl := rv(lab_t[k], 0.5)
		match k:
			0:
				if rl > 0.0:
					for sd: float in [-1.0, 1.0]:
						var horn := PackedVector2Array([hc + Vector2(sd * r * 0.45, -r * 0.8), hc + Vector2(sd * r * 0.95, -r * 1.75), hc + Vector2(sd * r * 0.85, -r * 0.55)])
						fill(horn, RED, 22200 + int(sd), rl, 2.6, 0.4, 3.0)
						edge(horn, RED.darkened(0.35), 2.2, 22202 + int(sd), rl)
						ln(hc + Vector2(sd * r * 0.55, -r * 0.42), hc + Vector2(sd * r * 0.12, -r * 0.24), RED.darkened(0.2), 5.0, 22204 + int(sd), rl, 0.4)
						if rl >= 1.0:
							var fang := PackedVector2Array([hc + Vector2(sd * r * 0.2 - r * 0.07, r * 0.5), hc + Vector2(sd * r * 0.2 + r * 0.07, r * 0.5), hc + Vector2(sd * r * 0.2, r * 0.78)])
							solid(fang, WHITE)
							edge(fang, INK, 1.6, 22206 + int(sd), 1.0, 0.3)
			1:
				if rl > 0.0:
					star(hc + Vector2(0, r * 2.1), r * 0.36, GOLD, 22210, rl)
					edge(C.ellipse_poly(hc + Vector2(0, -r * 1.35), r * 0.7, r * 0.18, 16, 22211, 0.04), GOLD, 5.0, 22212, rl, 0.5)
		# insane: everyone draws the spiral eyes on, all three
		var ri := rv(wt(17, "INSANE") + k * 0.25, 0.5)
		if ri > 0.0:
			for sd2: float in [-1.0, 1.0]:
				var e := hc + Vector2(sd2 * r * 0.36, -r * 0.08)
				var sp := PackedVector2Array()
				for q in 18:
					var a := q * 0.75 + t * 3.0 * sd2
					sp.append(e + Vector2(cos(a), sin(a)) * r * 0.03 * q * 0.6)
				path(sp, PURPLE, 2.6, 22220 + k * 4 + int(sd2), ri, 0.3)
			for q2 in 7:
				var a2 := PI * 1.05 + q2 * 0.14
				var base := hc + Vector2(cos(a2), sin(a2)) * r
				var zz := PackedVector2Array([base, base + Vector2(cos(a2) * r * 0.2 + 6, sin(a2) * r * 0.25), base + Vector2(cos(a2) * r * 0.35 - 6, sin(a2) * r * 0.45)])
				path(zz, ORANGE.darkened(0.2), 3.0, 22240 + k * 10 + q2, ri, 0.6)
		txt_c(String(labels[k]), x, 545.0, 42, RED if k == 0 else (GOLD.darkened(0.3) if k == 1 else PURPLE), 22300 + k, 3, rl if k < 2 else insane)
		# some of you
		var rp := rv(cs(15 + mini(k, 2)) + 0.2, 0.6) if k < 2 else rv(wt(17, "ALL"), 0.6)
		for q3 in 3:
			var fx := x - 100.0 + q3 * 100.0
			var pf := Vector2(fx, 708)
			fk_folk(pf, 96.0, [ORANGE, SKY, GRASS, PINK, PURPLE][(k * 3 + q3) % 5], SKINS[(k + q3 * 2) % 5], 22400 + k * 30 + q3 * 9, rp,
				"flat", Vector2.ZERO, pf + Vector2((x - fx) * 0.3, -122))
	# insane, all of you: more folk along the bottom
	var ra := rv(wt(17, "ALL") + 0.3, 0.6)
	if ra > 0.0:
		for q4 in 4:
			var fx2: float = [90.0, 565.0, 1035.0, 1510.0][q4]
			var pf2 := Vector2(fx2, 708)
			fk_folk(pf2, 90.0, [RED, NAVY, GOLD, CYAN][q4], SKINS[(q4 * 3) % 5], 22500 + q4 * 9, ra, "flat", Vector2.ZERO, pf2 + Vector2(20, -118))


# ================================================================== page 5: the board
func fk_p5() -> void:
	var t0 := cs(18)
	var rb := rv(t0 - 0.6, 0.8)
	fk_cork(22600, rb)
	var pc := Vector2(800, 330)
	var rp := rv(t0 - 0.2, 0.6)
	var ra := rv(cs(18), 0.5)
	var rbb := rv(cs(19), 0.5)
	var rc := rv(cs(20), 0.5)
	fk_string(Vector2(330, 99), pc + Vector2(0, -150), 22610, rv(cs(18) + 0.4, 0.5))
	fk_string(Vector2(1270, 99), pc + Vector2(0, -150), 22611, rv(cs(19) + 0.4, 0.5))
	fk_string(Vector2(800, 539), pc + Vector2(0, 150), 22612, rv(cs(20) + 0.4, 0.5))
	fk_polaroid(pc, 280.0, "GC", 22620, rp, "GEORGE CARRICK")
	# four towers
	fk_card(Rect2(120, 85, 420, 330), 22700, ra)
	if ra >= 1.0:
		txt_c("PAISLEY TOWERS", 330.0, 160.0, 28, NAVY, 22710, 2)
		for q in 4:
			jb_mini_tower(Vector2(195 + q * 90, 350), 66.0, 160.0, 22720 + q * 10, rv(wt(18, "FOUR") + q * 0.18, 0.4))
		txt_c("80S - MID 90S", 330.0, 396.0, 24, RED, 22760, 2, rv(wt(18, "80S"), 0.6))
	# union money to Kevin
	fk_card(Rect2(1060, 85, 420, 330), 22800, rbb)
	if rbb >= 1.0:
		txt_c("UNION", 1150.0, 175.0, 26, NAVY, 22810, 2, rv(wt(19, "UNION"), 0.4))
		jb_bag(Vector2(1150, 250), 48.0, 22811, rv(wt(19, "MONEY"), 0.4))
		var rk := rv(wt(19, "KEVIN"), 0.6)
		house(1330.0, 330.0, 100.0, 80.0, SUN, BROWN, 22812, rk)
		txt_c("KEVIN'S CO.", 1380.0, 372.0, 22, INK, 22813, 2, rk)
		var ar := rv(wt(19, "HIRE"), 0.5)
		if ar > 0.0:
			ln(Vector2(1205, 250), Vector2(1310, 280), CASH_DARK, 4.0, 22814, ar, 0.5)
			if ar >= 1.0:
				ln(Vector2(1310, 280), Vector2(1290, 266), CASH_DARK, 4.0, 22815)
				ln(Vector2(1310, 280), Vector2(1292, 292), CASH_DARK, 4.0, 22816)
		fk_stamp(Vector2(1270, 300), "INDICTED", 34, RED, -0.16, 22820, wt(19, "INDICTED"))
	# CEO
	fk_card(Rect2(540, 525, 520, 150), 22900, rc)
	if rc >= 1.0:
		var plate := C.rect_poly(Rect2(580, 580, 140, 64))
		solid(plate, GOLD)
		edge(plate, INK, 2.0, 22910, 1.0, 0.4)
		txt_c("CEO", 650.0, 626.0, 34, INK, 22911, 3)
		txt("PORT CARRICK", Vector2(750, 606), 28, NAVY, 22912, 2, rv(wt(20, "PORT"), 0.5))
		txt("ENTERPRISES", Vector2(750, 644), 28, NAVY, 22913, 2, rv(wt(20, "ENTERPRISES"), 0.5))


# ================================================================== page 6: the company
func fk_logo(c: Vector2, w: float, s: int, rr: float, year := "1834", crossed := 0.0, new_year := 0.0) -> void:
	var pl := C.rect_poly(Rect2(c - Vector2(w * 0.5, w * 0.27), Vector2(w, w * 0.54)))
	solid(pl, ca(Color("#14213d"), rr))
	edge(pl, GOLD, 4.0, s, rr, 0.6)
	if rr < 1.0:
		return
	solid(circ(c + Vector2(-w * 0.32, -w * 0.02), w * 0.13, s + 1, 16), GOLD)
	txt_c("PCE", c.x - w * 0.32, c.y + w * 0.02, int(w * 0.07), Color("#14213d"), s + 2, 3)
	txt("PORT CARRICK", c + Vector2(-w * 0.15, -w * 0.07), int(w * 0.075), WHITE, s + 3, 2)
	txt("ENTERPRISES", c + Vector2(-w * 0.15, w * 0.04), int(w * 0.075), WHITE, s + 4, 2)
	var ey := c + Vector2(-w * 0.15, w * 0.17)
	var tw := txt("EST. " + year, ey, int(w * 0.07), GOLD, s + 5, 2)
	if crossed > 0.0:
		var yw := C.letters_width(year, int(w * 0.07))
		ln(ey + Vector2(tw - yw - 6, -w * 0.025), ey + Vector2(tw + 6, -w * 0.03), RED, 6.0, s + 6, crossed, 0.6)
	if new_year > 0.0:
		txt("1973", ey + Vector2(tw + 18, -w * 0.0), int(w * 0.09), RED, s + 7, 3, new_year)


func fk_p6() -> void:
	var t0 := cs(21)
	fk_cork(23000, rv(t0 - 0.6, 0.8))
	var lc := Vector2(800, 260)
	fk_logo(lc, 440.0, 23010, rv(t0 - 0.3, 0.7))
	fk_pin(lc + Vector2(0, -112), 23011)
	var rd := rv(cs(21), 0.6)
	var re := rv(cs(22), 0.6)
	fk_card(Rect2(60, 130, 380, 400), 23100, rd)
	if rd >= 1.0:
		fk_cityhall(Vector2(250, 380), 270.0, 23110, rv(wt(21, "LOCAL") - 0.6, 0.8))
		txt_c("CITY HALL", 250.0, 490.0, 30, NAVY, 23120, 2, rv(wt(21, "GOVERNMENT"), 0.5))
	# the string that isn't there
	var rs := rv(wt(21, "RELATIONSHIP") - 0.4, 0.5)
	if rs > 0.0:
		var a := Vector2(440, 300)
		var b := lc + Vector2(-220, 30)
		for q in 5:
			var f0 := q / 5.0
			var f1 := f0 + 0.11
			ln(a.lerp(b, f0) + Vector2(0, sin(PI * f0) * 24.0), a.lerp(b, f1) + Vector2(0, sin(PI * f1) * 24.0), RED, 3.0, 23130 + q, rs, 0.4)
		var m := a.lerp(b, 0.5) + Vector2(0, 24)
		var rx := rv(wt(21, "NO") + 0.2, 0.4)
		ln(m + Vector2(-26, -26), m + Vector2(26, 26), RED, 8.0, 23140, rx, 0.6)
		ln(m + Vector2(26, -26), m + Vector2(-26, 26), RED, 8.0, 23141, rv(wt(21, "NO") + 0.4, 0.3), 0.6)
		txt_c("NOT OFFICIAL", m.x, m.y + 92.0, 22, RED, 23142, 2, rv(wt(21, "OFFICIAL"), 0.5))
	# the lawsuit
	fk_card(Rect2(1160, 130, 380, 400), 23200, re)
	fk_string(Vector2(1160, 300), lc + Vector2(220, 30), 23201, rv(cs(22) + 0.3, 0.5))
	if re >= 1.0:
		var won := wt(22, "WON")
		var ang := -0.75
		if t >= won - 0.2:
			ang = lerpf(-0.75, 0.15, _ease(rv(won - 0.2, 0.18)))
		fk_gavel(Vector2(1210, 300), 140.0, ang, 23210, 1.0)
		txt_c("$2,000,000", 1350.0, 420.0, 40, CASH_DARK, 23220, 3, rv(wt(22, "TWO"), 0.7))
		var rtm := rv(wt(22, "TRADEMARK"), 0.4)
		txt("TM", Vector2(1440, 220), 32, INK, 23221, 2, rtm)
		edge(circ(Vector2(1465, 206), 30.0, 23222, 14), INK, 2.4, 23223, rtm)
		txt_c("WON!", 1350.0, 500.0, 44, RED, 23224, 3, rv(won, 0.4))
	# the money, across the board
	var rm := rv(wt(22, "TWO"), 2.6)
	if rm > 0.0 and rm < 1.0:
		for q2 in 6:
			var f := clampf(rm * 1.6 - q2 * 0.12, 0.0, 1.0)
			if f <= 0.0 or f >= 1.0:
				continue
			var p := Vector2(300, 300).lerp(Vector2(800, 250), f) + Vector2(0, -sin(PI * f) * 200.0)
			jb_bill(p, 56.0, sin(t * 5.0 + q2) * 0.4, 23300 + q2, 1.0, true)


# ================================================================== page 7: the founder
func fk_oval_portrait(c: Vector2, rx: float, ry: float, s: int, rr: float) -> void:
	if rr <= 0.0:
		return
	var outer := C.ellipse_poly(c, rx, ry, 26, s, 0.03)
	solid(outer, ca(GOLD.darkened(0.2), rr))
	edge(outer, INK, 2.6, s + 1, rr, 0.6)
	var inner := C.ellipse_poly(c, rx * 0.86, ry * 0.88, 26, s + 2, 0.03)
	solid(inner, ca(SEPIA, rr))
	edge(inner, BROWN.darkened(0.2), 2.0, s + 3, rr, 0.4)
	if rr >= 1.0:
		fk_bust(c + Vector2(0, -ry * 0.14), rx * 0.33, "HC", s + 10, 1.0)


func fk_p7() -> void:
	var t0 := cs(23)
	fk_cork(23400, rv(t0 - 0.6, 0.8))
	var lc := Vector2(800, 160)
	var cross := rv(wt(24, "1973") - 0.3, 0.5)
	fk_logo(lc, 470.0, 23410, rv(t0 - 0.3, 0.6), "1834", cross, rv(wt(24, "1973"), 0.6))
	fk_pin(lc + Vector2(0, -118), 23411)
	var rh := rv(wt(23, "HENRY") - 0.4, 0.7)
	fk_oval_portrait(Vector2(300, 370), 140.0, 175.0, 23420, rh)
	txt_c("HENRY CARRICK JR", 300.0, 600.0, 26, INK, 23430, 2, rv(wt(23, "HENRY"), 0.6))
	txt_c("1834", 300.0, 640.0, 28, BROWN.darkened(0.2), 23431, 2, rv(wt(23, "1834"), 0.4))
	fk_string(Vector2(300, 196), lc + Vector2(-200, 40), 23432, rv(wt(23, "FOUNDED"), 0.6))
	var rg := rv(cs(24) - 0.2, 0.6)
	fk_polaroid(Vector2(1300, 370), 250.0, "GC", 23440, rg, "GEORGE CARRICK", 0.04)
	txt_c("1973", 1300.0, 560.0, 34, RED, 23450, 3, rv(wt(24, "1973"), 0.5))
	# the family tree that isn't
	var rt := rv(wt(25, "RELATED") - 0.3, 0.8)
	if rt > 0.0:
		for q in 10:
			var f0 := q / 10.0
			var f1 := f0 + 0.06
			var a := Vector2(450, 430)
			var b := Vector2(1160, 430)
			ln(a.lerp(b, f0) + Vector2(0, sin(PI * f0) * 50.0), a.lerp(b, f1) + Vector2(0, sin(PI * f1) * 50.0), BROWN, 4.0, 23460 + q, clampf(rt * 10.0 - q, 0.0, 1.0), 0.4)
		var m := Vector2(805, 480)
		var rx := rv(wt(25, "SLIGHTEST") - 0.2, 0.3)
		ln(m + Vector2(-50, -50), m + Vector2(50, 50), RED, 12.0, 23480, rx, 0.8)
		ln(m + Vector2(50, -50), m + Vector2(-50, 50), RED, 12.0, 23481, rv(wt(25, "SLIGHTEST") + 0.05, 0.3), 0.8)
	# the name is real
	var rn := rv(wt(26, "REAL"), 0.5)
	if rn > 0.0:
		var tag := C.rect_poly(Rect2(1180, 590, 240, 56))
		solid(tag, ca(WHITE, rn))
		edge(tag, INK, 2.0, 23490, rn, 0.5)
		txt("CARRICK", Vector2(1196, 632), 30, NAVY, 23491, 2, rn)
		if rn >= 1.0:
			path(PackedVector2Array([Vector2(1360, 614), Vector2(1376, 634), Vector2(1408, 596)]), GRASS_DARK, 6.0, 23492)
	# and everyone says it for him
	var rs := rv(cs(27), 0.6)
	if rs > 0.0:
		for q2 in 4:
			var fx := 600.0 + q2 * 110.0
			fk_folk(Vector2(fx, 704), 88.0, [ORANGE, SKY, PINK, GRASS][q2], SKINS[(q2 * 2 + 1) % 5], 23500 + q2 * 9, rv(cs(27) + q2 * 0.15, 0.5))
		jb_jag(Vector2(640, 560), "SINCE 1834!", 22, NAVY, 23540, rv(cs(27) + 0.6, 0.3))
		jb_jag(Vector2(960, 590), "THE FOUNDER'S FAMILY!", 20, NAVY, 23545, rv(cs(27) + 1.2, 0.3))


# ================================================================== page 8: the next mayor
func fk_p8() -> void:
	var t0 := cs(28)
	var wall := C.rect_poly(Rect2(-10, -10, W + 20, 490))
	fill(wall, BRICK.lightened(0.35), 23600, rv(t0 - 0.6, 0.8), 4.6, -0.2, 4.2)
	var walk := C.rect_poly(Rect2(-10, 480, W + 20, 240))
	fill(walk, GREY.lightened(0.25), 23601, rv(t0 - 0.5, 0.7), 4.4, -0.1, 4.0)
	if t >= t0:
		for r in 8:
			ln(Vector2(-10, 60 + r * 56), Vector2(W + 10, 60 + r * 56), BRICK.darkened(0.1), 2.0, 23610 + r, 1.0, 0.6)
	fk_poster(Vector2(380, 245), 340.0, -0.05, 23700, rv(t0 - 0.2, 0.4))
	fk_poster(Vector2(820, 255), 340.0, 0.04, 23720, rv(cs(29) + 0.2, 0.3))
	fk_poster(Vector2(1240, 235), 340.0, -0.03, 23740, rv(cs(30), 0.25))
	fk_poster(Vector2(600, 330), 240.0, 0.09, 23760, rv(cs(30) + 0.35, 0.2))
	fk_poster(Vector2(1030, 340), 240.0, -0.08, 23780, rv(cs(30) + 0.7, 0.2))
	# the ballot box
	var rb := rv(cs(31), 0.6)
	var bx := C.rect_poly(Rect2(1340, 560, 190, 140))
	solid(bx, ca(NAVY, rb))
	fill(bx, NAVY.darkened(0.2), 23800, rb, 3.6, -0.5, 3.2)
	edge(bx, INK, 2.6, 23801, rb)
	if rb >= 1.0:
		solid(C.rect_poly(Rect2(1385, 566, 100, 12)), INK)
		txt_c("VOTE", 1435.0, 660.0, 36, WHITE, 23802, 3)
	# the people, frightened, choosing him anyway
	var rf := rv(cs(32), 0.8)
	var choose := wt(33, "CHOOSE")
	for q in 8:
		var fx := 110.0 + q * 150.0
		var pf := Vector2(fx, 706)
		var mood := "scared" if t < choose else "flat"
		var hand := Vector2.ZERO
		var vote := rv(choose + q * 0.18, 0.5)
		if vote > 0.0:
			hand = pf + Vector2(34, -150)
		fk_folk(pf, 120.0, [RED, ORANGE, SKY, PURPLE, GRASS, PINK, GOLD, CYAN][q], SKINS[q % 5], 23900 + q * 11, rv(cs(32) + q * 0.1, 0.5), mood, Vector2.ZERO, hand)
		if vote > 0.0:
			var bp := hand + Vector2(0, -18)
			var fly := rv(choose + 1.2 + q * 0.12, 0.9)
			if fly > 0.0:
				bp = bp.lerp(Vector2(1435, 560), _ease(fly)) + Vector2(0, -sin(PI * fly) * 120.0)
			if fly < 1.0:
				var bl := C.rect_poly(Rect2(bp - Vector2(18, 13), Vector2(36, 26)))
				solid(bl, WHITE)
				edge(bl, INK, 1.6, 23990 + q, 1.0, 0.3)
				ln(bp + Vector2(-7, -6), bp + Vector2(7, 6), RED, 2.6, 23999 + q, 1.0, 0.2)
				ln(bp + Vector2(7, -6), bp + Vector2(-7, 6), RED, 2.6, 24010 + q, 1.0, 0.2)
	# the fright: his shadow over them
	if rf > 0.0 and t < choose + 0.5:
		var sh := rv(cs(32) + 0.4, 1.0) * (1.0 - rv(choose, 0.5))
		var dk := ca(Color("#1e1830"), 0.34 * sh)
		solid(C.ellipse_poly(Vector2(560, 300), 190.0, 210.0, 20, 24020, 0.06), dk)
		solid(C.ellipse_poly(Vector2(560, 640), 470.0, 190.0, 20, 24021, 0.05), dk)
	# ballots dropping in
	if t > cs(31) + 0.6 and t < cs(33):
		for q2 in 3:
			var ph := fmod((t - cs(31)) * 0.9 + q2 * 0.33, 1.0)
			var bp2 := Vector2(1435 + (q2 - 1) * 12, 470 + ph * 100.0)
			solid(C.rect_poly(Rect2(bp2 - Vector2(16, 11), Vector2(32, 22))), ca(WHITE, 1.0 - ph * 0.5))


# ================================================================== page 9: the turn
func fk_p9() -> void:
	var t0 := cs(34)
	var live := cs(35)
	var blue := _ease(rv(live, 2.4))
	sky_strip(700.0, Color("#ff9f6b"), 24100, rv(t0 - 0.6, 0.8))
	if blue > 0.0:
		sky_strip(700.0, ca(SKY, blue), 24101, 1.0)
	var sy := lerpf(660.0, 150.0, _ease(rv(live + 0.2, 2.6)))
	sun(Vector2(1300, sy), 70.0, 24102, rv(t0 - 0.4, 0.6))
	fk_hill(24110, rv(t0 - 0.5, 0.8))
	grass_strip(690.0, 24120, rv(t0 - 0.4, 0.8))
	fk_machine(Vector2(900, 249), 0.32, 24130, rv(t0 - 0.5, 0.6), {"rust": 1.0})
	# the sheet over it
	var sd := wt(34, "DECIDED")
	var drop := _ease(rv(sd, 0.7))
	if t >= sd:
		var off := Vector2(0, -280.0 * (1.0 - drop))
		var sh := PackedVector2Array([Vector2(782, 346), Vector2(786, 262), Vector2(812, 196), Vector2(872, 158), Vector2(944, 168), Vector2(984, 226), Vector2(996, 300), Vector2(1000, 346)])
		for q in sh.size():
			sh[q] = sh[q] + off
		solid(sh, Color("#f4f1ea"))
		fill(sh, Color("#d9d4c8"), 24140, 1.0, 6.0, 1.2, 2.4)
		edge(sh, INK, 2.6, 24141, 1.0, 0.8)
		for q2 in 3:
			ln(Vector2(830 + q2 * 50, 220 + q2 * 10) + off, Vector2(818 + q2 * 56, 340) + off, GREY, 2.0, 24142 + q2, 1.0, 0.6)
	# he gets up and goes
	var go := wt(34, "THROUGH") + 0.3
	if t < go:
		fk_sit(Vector2(700, 336), 240.0, 24150, rv(t0 - 0.5, 0.8))
	else:
		var wk := _ease(rv(go, 3.4))
		var fx := lerpf(700.0, 380.0, wk)
		fk_douglas(Vector2(fx, fk_hill_y(fx) + 18.0), 230.0, 1.0, "smile" if t > live + 0.5 else "frown")
	birds(Vector2(500, 120), 24170, rv(live + 1.0, 0.6))


# ================================================================== page 10: things to live for
func fk_p10() -> void:
	var t0 := cs(36)
	var rr := rv(t0 - 0.6, 0.8)
	var wall := C.rect_poly(Rect2(-10, -10, W + 20, 570))
	fill(wall, Color("#ffe48a"), 24200, rr, 4.6, -0.3, 4.2)
	var floor_p := C.rect_poly(Rect2(-10, 560, W + 20, H - 550))
	fill(floor_p, TAN, 24201, rr, 4.0, 0.0, 4.0)
	# the window
	var win := C.rect_poly(Rect2(1330, 70, 230, 220))
	solid(win, ca(SKY.lightened(0.3), rr))
	edge(win, INK, 3.0, 24210, rr)
	if rr >= 1.0:
		sun(Vector2(1500, 130), 30.0, 24211, 1.0)
		solid(C.ellipse_poly(Vector2(1440, 300), 150.0, 60.0, 16, 24212, 0.05), GRASS)
		ln(Vector2(1445, 70), Vector2(1445, 290), INK, 3.0, 24213, 1.0, 0.4)
		ln(Vector2(1330, 180), Vector2(1560, 180), INK, 3.0, 24214, 1.0, 0.4)
		edge(win, INK, 3.0, 24215)
	# desk, chair, lamp, the diary
	var rd := rv(t0 - 0.4, 0.8)
	var top := C.rect_poly(Rect2(380, 420, 420, 22))
	fill(top, BROWN, 24220, rd, 3.6, 0.1, 3.4)
	edge(top, INK, 2.4, 24221, rd)
	for lx: float in [400.0, 780.0]:
		ln(Vector2(lx, 442), Vector2(lx, 600), BROWN.darkened(0.2), 10.0, 24222 + int(lx), rd, 0.4)
	ln(Vector2(250, 300), Vector2(250, 600), BROWN.darkened(0.2), 9.0, 24230, rd, 0.4)
	ln(Vector2(250, 478), Vector2(360, 478), BROWN.darkened(0.2), 10.0, 24231, rd, 0.4)
	ln(Vector2(355, 478), Vector2(355, 600), BROWN.darkened(0.2), 9.0, 24232, rd, 0.4)
	if rd >= 1.0:
		var shade := PackedVector2Array([Vector2(700, 330), Vector2(760, 330), Vector2(785, 376), Vector2(675, 376)])
		solid(PackedVector2Array([Vector2(675, 376), Vector2(785, 376), Vector2(850, 420), Vector2(610, 420)]), Color(1.0, 0.95, 0.5, 0.45))
		ln(Vector2(730, 376), Vector2(730, 420), INK, 4.0, 24240, 1.0, 0.3)
		solid(shade, PINK)
		edge(shade, INK, 2.2, 24241, 1.0, 0.4)
		var book := PackedVector2Array([Vector2(396, 414), Vector2(520, 408), Vector2(530, 420), Vector2(396, 422)])
		solid(book, WHITE)
		edge(book, INK, 1.8, 24242, 1.0, 0.3)
	var wh := Vector2(440, 408) + Vector2(sin(t * 7.0) * 10.0, cos(t * 9.0) * 2.0)
	fk_sit(Vector2(310, 470), 240.0, 24250, rv(t0 - 0.3, 0.9), wh, "smile" if t > cs(39) else "")
	if rd >= 1.0:
		ln(wh, wh + Vector2(10, -26), SUN.darkened(0.3), 4.0, 24280, 1.0, 0.3)
	# the evil man: a cloud with his grin, pushed off the page
	var re := rv(wt(38, "EVIL") - 0.2, 0.6)
	if re > 0.0:
		var push := _ease(rv(cs(39) + 0.3, 1.0)) * 520.0
		var cc := Vector2(200 - push, 120)
		var cl := C.ellipse_poly(cc, 150.0 * re, 70.0 * re, 18, 24290, 0.15)
		solid(cl, Color("#3a3446"))
		fill(cl, Color("#251f30"), 24291, 1.0, 4.0, -0.3, 3.4)
		if re >= 1.0:
			fk_grin(cc + Vector2(0, -16), 46.0, 24292, 1.0)
			for sd: float in [-1.0, 1.0]:
				draw_circle(cc + Vector2(sd * 22, -30), 5.0, WHITE)
	# things to live for
	var spots: Array[Vector2] = [Vector2(920, 150), Vector2(1170, 140), Vector2(960, 360), Vector2(1200, 360)]
	for k in 4:
		var rk := rv(cs(39) + 0.2 + k * 0.45, 0.5)
		if rk <= 0.0:
			continue
		var bc: Vector2 = spots[k]
		cloud(bc, 230.0, 24300 + k * 40, rk)
		if rk < 1.0:
			continue
		match k:
			0:
				solid(C.ellipse_poly(bc + Vector2(10, 22), 46.0, 26.0, 14, 24320, 0.06), ORANGE)
				solid(circ(bc + Vector2(-34, -4), 24.0, 24321, 12), ORANGE)
				for sd2: float in [-1.0, 1.0]:
					solid(PackedVector2Array([bc + Vector2(-34 + sd2 * 18, -16), bc + Vector2(-34 + sd2 * 8, -14), bc + Vector2(-34 + sd2 * 16, -36)]), ORANGE.darkened(0.15))
					draw_circle(bc + Vector2(-34 + sd2 * 8, -6), 3.0, INK)
				path(PackedVector2Array([bc + Vector2(54, 18), bc + Vector2(76, -6), bc + Vector2(70, -30)]), ORANGE.darkened(0.15), 7.0, 24322)
			1:
				ln(bc + Vector2(-70, 40), bc + Vector2(40, -50), BROWN, 4.0, 24330, 1.0, 0.3)
				ln(bc + Vector2(40, -50), bc + Vector2(50, 20), INK, 1.4, 24331, 1.0, 0.2)
				var fish := C.ellipse_poly(bc + Vector2(50, 36), 26.0, 13.0, 12, 24332, 0.05)
				solid(fish, SKY)
				edge(fish, INK, 1.8, 24333, 1.0, 0.3)
				solid(PackedVector2Array([bc + Vector2(74, 36), bc + Vector2(92, 22), bc + Vector2(92, 50)]), SKY.darkened(0.2))
			2:
				jb_bloom(bc + Vector2(-50, -10), 20.0, 6, 24340, 1.0)
				jb_bloom(bc + Vector2(10, -24), 22.0, 6, 24350, 1.0)
				jb_bloom(bc + Vector2(66, -6), 18.0, 2, 24360, 1.0)
			3:
				var cake := C.rect_poly(Rect2(bc + Vector2(-56, -6), Vector2(112, 50)))
				solid(cake, PINK)
				edge(cake, INK, 2.0, 24370, 1.0, 0.4)
				ln(bc + Vector2(-56, 12), bc + Vector2(56, 12), WHITE, 6.0, 24371, 1.0, 0.4)
				for q in 3:
					var cx := bc.x - 30.0 + q * 30.0
					solid(C.rect_poly(Rect2(Vector2(cx - 4, bc.y - 34), Vector2(8, 28))), SKY)
					solid(C.ellipse_poly(Vector2(cx, bc.y - 42), 5.0, 9.0 + sin(t * 9.0 + q) * 1.5, 8, 24372 + q, 0.05), ORANGE)
	# trailing bubbles from his head
	var rb := rv(cs(39) + 0.1, 0.4)
	if rb > 0.0:
		for q2 in 3:
			solid(circ(Vector2(400 + q2 * 110, 290 - q2 * 40), 10.0 + q2 * 6.0, 24380 + q2, 10), ca(WHITE, rb))
			edge(circ(Vector2(400 + q2 * 110, 290 - q2 * 40), 10.0 + q2 * 6.0, 24383 + q2, 10), SKY.darkened(0.25), 2.0, 24386 + q2, rb, 0.4)
	# together: a line of people holding hands, and her family at the end of it
	var tg := wt(41, "TOGETHER")
	var rt := rv(cs(41), 0.8)
	if rt > 0.0:
		var xs: Array[float] = []
		for q3 in 8:
			xs.append(130.0 + q3 * 128.0)
		var fam := rv(tg, 0.6) * (1.0 - rv(cs(42) + 0.3, 0.9))
		var fx: Array[float] = [1170.0, 1300.0, 1420.0]
		var hy := 700.0 - 120.0 * 0.5
		for q4 in 8:
			var hl := Vector2((xs[q4] + xs[q4 - 1]) * 0.5, hy) if q4 > 0 else Vector2.ZERO
			var hr := Vector2((xs[q4] + xs[q4 + 1]) * 0.5, hy) if q4 < 7 else (Vector2((xs[7] + fx[0]) * 0.5, hy) if fam > 0.5 else Vector2.ZERO)
			fk_folk(Vector2(xs[q4], 704), 120.0, [RED, ORANGE, SUN, GRASS, SKY, NAVY, PURPLE, PINK][q4], SKINS[(q4 * 3) % 5], 24400 + q4 * 11, clampf(rt * 8.0 - q4, 0.0, 1.0), "smile", hl, hr)
		if fam > 0.0:
			var kinds := ["daddy", "mommy", "me"]
			var hs: Array[float] = [150.0, 140.0, 95.0]
			for q5 in 3:
				var hgt := hs[q5]
				var hl2 := Vector2((fx[q5] + (fx[q5 - 1] if q5 > 0 else xs[7])) * 0.5, hy)
				var hr2 := Vector2((fx[q5] + fx[q5 + 1]) * 0.5, hy) if q5 < 2 else Vector2.ZERO
				stick(Vector2(fx[q5], 704), hgt, String(kinds[q5]), 24500 + q5 * 60, 1.0, fam, hl2, hr2, 3.0)
	fk_stamp(Vector2(800, 300), "END NOTE", 76, RED, -0.12, 24600, cs(42))


# ================================================================== page 11: the television
func fk_p11() -> void:
	var t0 := cs(43)
	var rn := rv(t0 - 0.6, 0.8)
	var sky := C.rect_poly(Rect2(-10, -10, W + 20, 600))
	fill(sky, NIGHT, 24700, rn, 4.4, -0.2, 4.4)
	var gr := C.rect_poly(Rect2(-10, 580, W + 20, H - 570))
	fill(gr, Color("#1d1640"), 24701, rn, 4.4, 0.0, 4.4)
	if rn >= 1.0:
		for q in 30:
			var sp := Vector2(C.rnd(24702, q) * W, C.rnd(24703, q) * 300.0)
			draw_circle(sp, 1.6 + C.rnd(24704, q) * 1.6, ca(WHITE, 0.6 + 0.4 * sin(t * 2.0 + q)))
		for q2 in 8:
			var hx := 30.0 + q2 * 200.0
			if hx > 330.0 and hx < 1210.0:
				continue
			var hw := 150.0
			var hp := C.rect_poly(Rect2(hx, 470, hw, 120))
			solid(hp, Color("#2b2560"))
			edge(hp, INK, 2.0, 24710 + q2, 1.0, 0.4)
			solid(PackedVector2Array([Vector2(hx - 14, 470), Vector2(hx + hw * 0.5, 404), Vector2(hx + hw + 14, 470)]), Color("#3b2f7a"))
			var gl := 0.6 + 0.4 * sin(t * 9.0 + q2 * 1.3) * sin(t * 4.1 + q2)
			var wnd := C.rect_poly(Rect2(hx + 40, 500, 70, 52))
			solid(wnd, Color(0.45, 0.85, 1.0, gl))
			edge(wnd, INK, 1.6, 24720 + q2, 1.0, 0.3)
			draw_circle(Vector2(hx + 75, 526), 42.0, Color(0.45, 0.85, 1.0, 0.12 * gl))
	txt("JULY 27TH, 2000:", Vector2(50, 88), 46, SUN, 24730, 3, rv(t0, 1.0))
	var rtv := rv(cs(44) - 0.4, 0.8)
	var scr := jb_tv(Rect2(420, 120, 760, 460), 24740, rtv)
	if rtv >= 1.0:
		draw_circle(scr.get_center(), 520.0, Color(0.45, 0.85, 1.0, 0.06))
		var on := rv(cs(44) - 0.1, 0.3)
		solid(C.rect_poly(scr), Color("#9cc9ff").lerp(Color("#22305a"), 1.0 - on))
		if on >= 1.0:
			var hc := Vector2(scr.get_center().x, scr.position.y + scr.size.y * 0.4)
			var r := scr.size.y * 0.15
			var hand := hc + Vector2(-r * 2.6 + sin(t * 8.0) * r * 0.3, -r * 0.4)
			ln(hc + Vector2(-r * 1.6, r * 1.9), hand, NAVY, r * 0.4, 24750, 1.0, 0.5)
			fk_bust(hc, r, "GC", 24760, 1.0)
			solid(circ(hand, r * 0.28, 24790, 10), Color("#f4c2a1"))
			edge(circ(hand, r * 0.28, 24791, 10), INK, 1.8, 24792, 1.0, 0.3)
			var bn := C.rect_poly(Rect2(scr.position.x, scr.end.y - 64, scr.size.x, 64))
			solid(bn, RED)
			txt_c("MAYOR ELECT", scr.get_center().x, scr.end.y - 18.0, 40, WHITE, 24793, 3)
			var lv := C.rect_poly(Rect2(scr.position + Vector2(18, 16), Vector2(80, 34)))
			solid(lv, RED)
			txt("LIVE", scr.position + Vector2(30, 44), 24, WHITE, 24794, 2)
	# everyone watching
	var ra := rv(cs(44) + 0.4, 0.8)
	for q3 in 15:
		var hx2 := 70.0 + q3 * 104.0
		var me := q3 == 7
		var rq := clampf(ra * 15.0 - absf(q3 - 7.0) * 1.6, 0.0, 1.0)
		if rq <= 0.0:
			continue
		var r2 := 40.0 if me else 30.0 + C.rnd(24800, q3) * 8.0
		var hc2 := Vector2(hx2, 650.0 - r2 * 0.4)
		var shp := C.ellipse_poly(hc2 + Vector2(0, r2 * 1.7), r2 * 1.7, r2 * 0.9, 14, 24810 + q3, 0.05)
		solid(shp, ca(Color("#14102a"), rq))
		solid(circ(hc2, r2, 24830 + q3, 14), ca(Color("#1d1838") if not me else Color("#c9a68a").darkened(0.55), rq))
		path(arc(hc2, r2, r2, PI * 1.15, PI * 1.6, 6), ca(Color(0.45, 0.85, 1.0, 0.8), rq), 3.0, 24850 + q3, rq)
		if me and rq >= 1.0:
			for sd: float in [-1.0, 1.0]:
				path(arc(hc2, r2 * 1.02, r2 * 1.02, PI * (0.95 if sd < 0.0 else 1.78), PI * (1.22 if sd < 0.0 else 2.05), 5), Color("#7d786f"), r2 * 0.2, 24870 + int(sd))
	# ratings: off the chart
	var rc := rv(cs(45), 0.6)
	if rc > 0.0:
		var pr := C.rect_poly(Rect2(1230, 150, 300, 250))
		solid(pr, ca(WHITE, rc))
		edge(pr, INK, 2.2, 24880, rc)
		if rc >= 1.0:
			txt("RATINGS", Vector2(1250, 190), 26, INK, 24881, 2)
			var hts: Array[float] = [50.0, 70.0, 60.0, 330.0]
			for q4 in 4:
				var gh := hts[q4] * _ease(rv(cs(45) + 0.3 + q4 * 0.2, 0.6 if q4 < 3 else 1.4))
				var bar := C.rect_poly(Rect2(1270 + q4 * 64, 380 - gh, 44, gh))
				fill(bar, SUN if q4 < 3 else RED, 24882 + q4, 1.0, 3.0, -0.5, 3.0)
				edge(bar, INK, 1.8, 24886 + q4, 1.0, 0.3)
			if rv(cs(45) + 1.9, 0.3) > 0.0:
				star(Vector2(1484, 40), 30.0, GOLD, 24890, rv(cs(45) + 1.9, 0.3))


# ================================================================== page 12: inauguration day
func fk_layout(sheet: int) -> Array:
	var out: Array = []
	var top := 210.0 if sheet == 0 else 106.0
	var step := C.letters_width(PHRASE, 30) + 34.0
	var per := maxi(1, int((1290.0 - 340.0) / step))
	var rows := int((850.0 - top) / 52.0) + 1
	for r in rows:
		for c in per:
			out.append(Vector2(340.0 + c * step, top + r * 52.0))
	return out


func fk_sheet() -> void:
	var sh := C.rect_poly(Rect2(250, 26, 1100, 852))
	var sd := PackedVector2Array()
	for q in sh:
		sd.append(q + Vector2(8, 10))
	solid(sd, Color(0, 0, 0, 0.25))
	solid(sh, SHEET)
	for k in 15:
		var y := 106.0 + k * 52.0
		draw_line(Vector2(258, y), Vector2(1342, y), LINE_BLUE, 2.0, true)
	draw_line(Vector2(320, 30), Vector2(320, 874), MARGIN, 2.0, true)
	for q2 in 3:
		draw_circle(Vector2(282, 180 + q2 * 280), 11.0, DESK.darkened(0.3))


func fk_p12() -> void:
	var desk := C.rect_poly(Rect2(-10, -10, W + 20, H + 20))
	fill(desk, DESK, 23000 + 12000, 1.0, 4.6, 1.2, 4.4)
	var T0 := cs(47)
	var tau := t - T0
	var n_sheets := SCRAWL.size()
	var done := 0
	for k in n_sheets - 1:
		if tau >= float(SCRAWL[k][1]) + 0.55:
			done += 1
	for b in done:
		fk_ball(PILE[b], 62.0, 35100 + b * 17)
	var cur := 0
	for k2 in n_sheets:
		if tau >= float(SCRAWL[k2][0]):
			cur = k2
	var sc: Array = SCRAWL[cur]
	var crumple := 0.0
	if cur < n_sheets - 1:
		crumple = clampf((tau - float(sc[1])) / 0.55, 0.0, 1.0)
	if crumple > 0.0:
		var e := _ease(crumple)
		var ctr := Vector2(800, 452).lerp(PILE[cur], e * e)
		var rad := lerpf(430.0, 62.0, e)
		var pts := PackedVector2Array()
		for q in 18:
			var a := TAU * q / 18.0
			var d := Vector2(cos(a), sin(a))
			var sc2 := minf(550.0 / maxf(0.001, absf(d.x)), 426.0 / maxf(0.001, absf(d.y)))
			var rp := Vector2(800, 452) + d * sc2
			var ball := ctr + d * rad * (0.75 + 0.5 * C.rnd(35200 + cur, q))
			pts.append(rp.lerp(ball, e))
		solid(pts, SHEET)
		edge(pts, INK, 2.4, 35210 + cur, 1.0, 0.8)
		return
	fk_sheet()
	if cur == 0:
		txt("JULY 30TH, 2000 - INAUGURATION DAY.", Vector2(350, 156), 38, INK, 35300, 2, rv(cs(46) + 0.2, 1.6))
	if tau < 0.0:
		return
	# how many phrases on the sheets before this one, and in all
	var lay := fk_layout(cur)
	var before := 0
	var total := 0
	for k3 in n_sheets:
		var cnt := fk_layout(k3).size()
		if k3 == n_sheets - 1:
			cnt = int(cnt * 0.62)
		if k3 < cur:
			before += cnt
		total += cnt
	var cap := lay.size() if cur < n_sheets - 1 else int(lay.size() * 0.62)
	var u := clampf((tau - float(sc[0])) / (float(sc[1]) - float(sc[0])), 0.0, 1.0)
	var written := cap * pow(u, float(sc[2]))
	for j in cap:
		var rj := clampf(written - j, 0.0, 1.0)
		if rj <= 0.0:
			break
		var g := before + j
		var d2 := float(g) / float(total)
		var p: Vector2 = lay[j]
		var jx := (C.rnd(35400 + cur, j) - 0.5) * 60.0 * d2
		var jy := (C.rnd(35500 + cur, j) - 0.5) * 34.0 * d2
		var sz := int(30.0 + (C.rnd(35600 + cur, j) - 0.3) * 20.0 * d2)
		var col := INK.lerp(RED.darkened(0.25), clampf(d2 * 1.5 - 0.25, 0.0, 1.0))
		var text := PHRASE
		if cur == n_sheets - 1 and j == cap - 1:
			text = "I'M GONNA DO IT-"
		C.boil = 1.0 + 3.0 * d2
		txt(text, p + Vector2(jx, jy), sz, col, 35700 + g * 3, 3 if d2 > 0.5 else 2, rj)
	C.boil = 1.0


# ================================================================== page 13: the case report
func fk_p13() -> void:
	var t0 := cs(48)
	var desk := C.rect_poly(Rect2(-10, -10, W + 20, H + 20))
	fill(desk, DESK.darkened(0.15), 36000, rv(t0 - 0.8, 0.6), 4.6, 1.2, 4.4)
	var rf := rv(t0 - 0.7, 0.6)
	var tab := C.rect_poly(Rect2(110, 20, 260, 50))
	solid(tab, ca(MANILA, rf))
	edge(tab, INK, 2.0, 36001, rf, 0.5)
	var folder := C.rect_poly(Rect2(80, 50, 1440, 820))
	solid(folder, ca(MANILA, rf))
	fill(folder, MANILA.darkened(0.06), 36002, rf, 5.0, -0.4, 3.6)
	edge(folder, INK, 2.6, 36003, rf)
	if rf >= 1.0:
		txt("CASE FILE", Vector2(134, 58), 24, INK, 36004, 2)
		ln(Vector2(800, 54), Vector2(800, 866), MANILA.darkened(0.25), 3.0, 36005, 1.0, 0.4)
		heart(Vector2(640, 150), 22.0, PINK, 36006)
		txt("DADDY", Vector2(672, 160), 20, PURPLE, 36007, 2)
	# his photograph, clipped in
	var rp := rv(t0 - 0.3, 0.6)
	fk_polaroid(Vector2(300, 270), 250.0, "DF", 36010, rp, "SUBJECT A", -0.05)
	if rp >= 1.0:
		path(PackedVector2Array([Vector2(272, 104), Vector2(272, 150), Vector2(290, 160), Vector2(306, 150), Vector2(306, 96), Vector2(290, 88), Vector2(282, 96), Vector2(282, 140)]), GREY.darkened(0.2), 3.0, 36020)
	# a page from the diary, the plan blacked out
	var rd := rv(cs(51) + 0.6, 0.6)
	if rd > 0.0:
		fk_push(Vector2(500, 650), 0.06)
		var pg := C.rect_poly(Rect2(-250, -190, 500, 380))
		solid(pg, ca(SHEET, rd))
		edge(pg, INK, 2.0, 36030, rd, 0.5)
		if rd >= 1.0:
			for k in 8:
				var y := -150.0 + k * 42.0
				draw_line(Vector2(-240, y + 8), Vector2(240, y + 8), LINE_BLUE, 2.0, true)
				var sw := PackedVector2Array()
				for q in 26:
					sw.append(Vector2(-210.0 + q * 16.0, y + sin(q * 2.1 + k) * 5.0 + C.jit(36040 + k, q) * 3.0))
				draw_polyline(sw, Color(0.15, 0.13, 0.15, 0.85), 2.0, true)
			draw_line(Vector2(-200, -186), Vector2(-200, 186), MARGIN, 2.0, true)
			var rx := rv(wt(52, "LOGISTICS"), 1.2)
			for k2 in 6:
				var rk := clampf(rx * 6.0 - k2, 0.0, 1.0)
				if rk > 0.0:
					var by := -150.0 + (k2 + 1) * 42.0
					solid(C.rect_poly(Rect2(Vector2(-220, by - 18), Vector2(440.0 * rk, 26))), Color("#0d0c10"))
			var r7 := rv(wt(52, "SEVENTH"), 0.4)
			if r7 > 0.0:
				edge(circ(Vector2(200, -150), 28.0, 36050, 12), RED, 3.0, 36051, r7)
				txt_c("7", 200.0, -136.0, 32, RED, 36052, 3, r7)
		fk_pop()
	# the report itself
	var rr := rv(t0 - 0.5, 0.6)
	var sheet := C.rect_poly(Rect2(840, 80, 640, 760))
	var shd := PackedVector2Array()
	for q2 in sheet:
		shd.append(q2 + Vector2(6, 8))
	solid(shd, ca(Color(0, 0, 0, 0.2), rr))
	solid(sheet, ca(WHITE, rr))
	edge(sheet, GREY.darkened(0.3), 2.0, 36060, rr, 0.5)
	if rr >= 1.0:
		star(Vector2(1410, 140), 30.0, GOLD, 36061)
		txt_c("PCPD", 1410.0, 196.0, 20, NAVY, 36062, 2)
	_print_card(48, 42, 520.0, 880.0, 170.0, 50.0, false, INK, 3)
	_print_card(49, 26, 560.0, 880.0, 222.0, 38.0, false, INK, 2)
	if t >= cs(49) + 0.8:
		ln(Vector2(880, 246), Vector2(1440, 246), INK, 2.4, 36063, rv(cs(49) + 0.8, 0.4), 0.4)
	_print_card(50, 26, 560.0, 880.0, 300.0, 38.0, false, INK, 2)
	var l50 := _layout(_tokens(String(cards[50]["text"])), 26, 560.0).size()
	var b51 := 300.0 + l50 * 38.0 + 46.0
	_print_card(51, 26, 560.0, 880.0, b51, 40.0, false, INK, 2)
	var l51 := _layout(_tokens(String(cards[51]["text"])), 26, 560.0).size()
	_print_card(52, 26, 560.0, 880.0, b51 + l51 * 40.0 + 30.0, 40.0, false, INK, 2)
	fk_stamp(Vector2(1160, 780), "CONFIDENTIAL", 40, RED, -0.08, 36070, ce(52) - 2.2)


# ================================================================== page 14: status unknown
func fk_p14() -> void:
	var t0 := cs(53)
	var bg := C.rect_poly(Rect2(-10, -10, W + 20, H + 20))
	fill(bg, Color("#2a2730"), 37000, rv(t0 - 0.6, 0.6), 4.6, -0.5, 4.4)
	var rp := rv(t0 - 0.2, 1.0)
	fk_polaroid(Vector2(800, 420), 360.0, "GC", 37010, rp, "GEORGE CARRICK", 0.02)
	var rq := rv(t0 + 1.4, 1.4)
	if rq > 0.0:
		var hc := Vector2(800, 420) + Vector2(0, -360.0 * 1.18 * 0.5 + 360.0 * 0.07 + 360.0 * 0.86 * 0.42)
		var q := PackedVector2Array()
		for k in 15:
			var a := PI * 1.15 + k * 0.17
			q.append(hc + Vector2(cos(a) * 80.0, sin(a) * 90.0 - 40.0))
		q.append(hc + Vector2(10, 80))
		q.append(hc + Vector2(6, 130))
		path(q, RED, 16.0, 37030, rq, 1.2, 2)
		if rq >= 1.0:
			solid(circ(hc + Vector2(6, 190), 14.0, 37031, 10), RED)
