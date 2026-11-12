extends "res://scripts/view/proto/fettick_view.gd"
## Cutscene 6 — The Mayor (prototype, 2026-11-05). Thomas on being one more fall guy, then
## Mayor Bob Stevens (not Robert): the most forgettable man in Port Carrick, and the hardest.
## The meeting in his office (a few arrests for the cameras, 1972, the election, "every chief
## does"), and the gears starting to turn.
##
## Same crayon hand as the other cutscenes. The office talk is in speech bubbles; Thomas's
## narration is on the notebook strip. Presentation only.

## [text, who, gap before (s), duration (<= 0: from length), page]
##   who: N = Thomas narrating (strip), B = Bob says, T = Thomas says, BEAT, END = on black.
const LINES6 := [
	["", "BEAT", 0.0, 1.8, 0],
	["I'M JUST LIKE EVERYBODY ELSE.", "N", 0.2, -1.0, 0],
	["I'M JUST LIKE EVERY SINGLE OTHER FUCKING PERSON.", "N", 0.3, -1.0, 0],
	["I'M A PIECE OF SHIT WITH A SLIVER OF POWER AND A BOSS THAT MAKES IT FEEL LIKE NOTHING.", "N", 0.5, 5.6, 0],
	["I'M THE FALL GUY FOR AT LEAST FOUR DECADES WORTH OF DECAY.", "N", 0.9, -1.0, 1],
	["WE'RE ALL FALL GUYS. THAT'S WHAT BOB SAYS ANYWAYS.", "N", 0.5, 4.2, 1],
	["MAYOR BOB STEVENS (NOT ROBERT).", "N", 0.9, 3.0, 2],
	["IF YOU PASSED HIM ON THE STREET HE'D BE THE MOST BORING, BALDING SIXTY YEAR OLD MAN IN A FADED SUIT YOU NEVER REMEMBERED.", "N", 0.4, -1.0, 2],
	["THAT IMAGE YOU'VE GOT IN YOUR HEAD? THAT'S PERFECT.", "N", 0.5, -1.0, 2],
	["THAT'S EXACTLY HOW HE LOOKS.", "N", 0.3, 3.0, 2],
	["MAYOR BOB STEVENS IS THE HARDEST MAN IN PORT CARRICK.", "N", 0.9, -1.0, 3],
	["I DON'T MEAN THAT AS A COMPLIMENT.", "N", 0.3, -1.0, 3],
	["IT'S JUST SOMETHING YOU REALIZE WHEN YOU'VE GOT ENOUGH BLOOD ON YOUR HANDS.", "N", 0.5, -1.0, 3],
	["IT TAKES ONE TO KNOW ONE I GUESS.", "N", 0.3, -1.0, 3],
	["SOMEHOW, HE'S GOT IT WORSE.", "N", 0.7, -1.0, 3],
	["SOMETIMES IT FEELS LIKE HE DOESN'T EVEN TRY TO WASH THEM.", "N", 0.4, 4.4, 3],
	["CRACK A FEW EGGS IN PAISLEY FOR ME, WOULD YOU KINDLY THOMAS?", "B", 1.4, -1.0, 4],
	["...ANYONE SPECIFIC MR. MAYOR?", "T", 0.6, -1.0, 4],
	["HE SHAKES HIS HEAD. ONCE.", "N", 0.6, 2.6, 4],
	["BLACKS AND LATINOS COMPLAINING ABOUT OVER-POLICING. JUST NEED A COUPLE WHITE TRASH ARRESTS FOR THE CAMERAS.", "B", 0.4, -1.0, 4],
	["DONE.", "T", 0.5, 1.6, 4],
	["WE DON'T WANT THIS ELECTION TURNING INTO A RACIAL THING. YOU REMEMBER 72?", "B", 0.6, -1.0, 4],
	["VAGUELY. I WAS JUST A KID.", "T", 0.5, -1.0, 4],
	["72 WAS BAD THOMAS, ABOUT AS BAD AS IT GETS.", "B", 0.5, -1.0, 4],
	["...ROGER THAT SIR. I'LL KEEP THE TEMPERATURE DOWN.", "T", 0.7, -1.0, 4],
	["YOU KNOW I'M FINE IF YOU SUPPORT ANOTHER CANDIDATE RIGHT?", "B", 0.8, -1.0, 4],
	["SIR?", "T", 0.4, 1.4, 4],
	["IT'S YOUR DEMOCRATIC RIGHT.", "B", 0.3, -1.0, 4],
	["I DON'T THINK ABOUT THE POLITICS SIR.", "T", 0.4, -1.0, 4],
	["I JUST MEAN IF YOU THINK THAT GEORGE OR THAT NEW GIRL SHOULD HAVE A SHOT, GO AHEAD.", "B", 0.5, -1.0, 4],
	["I'VE GOT ANOTHER GOOD TERM IN ME, BUT I CAN ALWAYS GO FISHING INSTEAD.", "B", 0.3, -1.0, 4],
	["SIR I DON'T DECIDE THE RACE.", "T", 0.5, -1.0, 4],
	["...OF COURSE YOU DO THOMAS.", "B", 1.8, -1.0, 4],
	["EVERY CHIEF DOES, MORE OR LESS. WHY DO YOU THINK GEORGE KEEPS BUGGING YOU?", "B", 0.4, -1.0, 4],
	["WHAT?", "T", 2.2, 2.4, 4],
	["", "BEAT", 1.2, 3.0, 5],
	["AND JUST LIKE THAT, THE GEARS STARTED CLICKING.", "END", 0.4, 5.6, 5],
]
const PAGES6 := 6
const FADED := Color("#a8a193")
const BOB_SKIN := Color("#e9c6a6")


func _build() -> void:
	reporters = []
	flashes = []
	flash_pos = []
	intrusions = []
	cards.clear()
	var at := 0.0
	for i in LINES6.size():
		var l: Array = LINES6[i]
		var text := String(l[0])
		var n := _plain(text).length()
		var dur := float(l[3])
		if dur <= 0.0:
			dur = maxf(1.6, 0.9 + n / 15.0)
		var st := at + float(l[2])
		cards.append({"text": text, "who": String(l[1]), "t": st, "dur": dur, "pg": int(l[4]), "cps": CPS})
		at = st + dur
	T_END = ce(cards.size() - 1) + 1.0


func gear_t(k: int) -> float:
	# the gears catch slowly, then faster
	var t0 := cs(35) + 0.6
	return t0 + 3.0 * sqrt(k / 24.0) * 1.8


func cues() -> Dictionary:
	var starts: Array = []
	var bubbles: Array = []
	for i in cards.size():
		starts.append(cs(i))
		if String(cards[i]["who"]) in ["B", "T"]:
			bubbles.append(cs(i))
	var pages: Array = []
	for pg in PAGES6:
		for i2 in cards.size():
			if int(cards[i2]["pg"]) == pg:
				pages.append(cs(i2))
				break
	var ticks: Array = []
	var k := 0
	var at := cs(35) + 0.6
	var step := 0.7
	while at < T_END - 0.6:
		ticks.append(at)
		step = maxf(0.16, step * 0.9)
		at += step
		k += 1
	return {"cards": starts, "pages": pages, "bubbles": bubbles,
		"hand": wt(3, "BOSS"), "fall": cs(4), "tumble": cs(5), "cross": wt(6, "ROBERT"), "check": cs(9) + 0.2,
		"blood": wt(12, "BLOOD"), "worse": cs(14), "eggs": cs(16) + 0.2, "shake": cs(18) + 0.3,
		"cameras": wt(19, "CAMERAS"), "72": wt(21, "72"), "temp": wt(24, "TEMPERATURE"), "fishing": wt(30, "FISHING"),
		"phone": wt(33, "GEORGE"), "what": cs(34), "hush": [ce(33), cs(34)], "ticks": ticks,
		"end_line": cs(36), "end": T_END}


# ================================================================== draw
func _draw() -> void:
	C.frame = int(t * 8.0)
	C.boil = 1.0
	var rs := vp.x / W
	var cx := jb_cam_x()
	for pg in PAGES6:
		var x0 := pg * W
		if x0 + W < cx - W * 0.5 - 2.0 or x0 > cx + W * 0.5 + 2.0:
			continue
		page_xf = Transform2D(0.0, Vector2(rs, rs), 0.0, Vector2(x0 - cx + W * 0.5, 0.0) * rs)
		draw_set_transform_matrix(page_xf)
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		match pg:
			0: mp0()
			1: mp1()
			2: mp2()
			3: mp3()
			4: mp4()
			5: mp5()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	_captions()
	mp_end()


func mp_end() -> void:
	var i := cards.size() - 1
	if t < cs(i) - 0.6:
		return
	draw_rect(Rect2(0, 0, W, H), ca(INK, rv(cs(i) - 0.6, 0.6)))
	if t < cs(i):
		return
	_print_card(i, 46, 1300.0, 0.0, 600.0, 64.0, true, Color("#f4f0e6"), 3)
	var ra := rv(cs(i) - 0.4, 0.6)
	fk_gear(Vector2(720, 380), 70.0, 10, t * 1.4, RED, 50000, ra)
	fk_gear(Vector2(842, 330), 48.0, 8, -t * 2.0 + 0.3, RED.darkened(0.25), 50010, ra)
	fk_gear(Vector2(872, 432), 34.0, 7, t * 2.8, RED.lightened(0.15), 50020, ra)


# ================================================================== people
func fk_look(who: String) -> Dictionary:
	if who == "TG":
		return {"suit": NAVY, "skin": SKIN, "tie": NAVY.darkened(0.4)}
	return super.fk_look(who)


## Mayor Bob Stevens: the most forgettable man in the city.
func mp_bob(foot: Vector2, h: float, rr: float, mouth := "frown", hand_r := Vector2.ZERO) -> Dictionary:
	var rp := {"id": "BOB", "foot": foot, "h": h, "s": 51000, "suit": FADED, "skin": BOB_SKIN, "hair": "bald",
		"hair_col": Color("#b9b4ab"), "tie": Color("#8f8a7c"), "plain": true}
	if hand_r != Vector2.ZERO:
		rp["hand_r"] = hand_r
	_reporter(rp, rr, mouth, 0.0)
	var r := h * 0.165
	return {"head": foot + Vector2(0, -h + r + sin(t * 1.3 + 51000) * h * 0.006), "r": r}


## A little speech bubble with its tail pointing at the speaker, printed as it is said.
func mp_say(i: int, box: Rect2, to: Vector2, size := 30) -> void:
	if t < cs(i) - 0.15 or t > ce(i) + 0.25:
		return
	var a := rv(cs(i) - 0.15, 0.15) * (1.0 - rv(ce(i), 0.25))
	var text := String(cards[i]["text"])
	var lines := _layout(_tokens(text), size, box.size.x - 60.0).size()
	var h := 46.0 + lines * size * 1.32
	var r := Rect2(box.position, Vector2(box.size.x, h))
	var c := r.get_center()
	var body := C.ellipse_poly(c, r.size.x * 0.56, r.size.y * 0.64, 26, 52000 + i * 7, 0.03)
	var base := c + (to - c).normalized() * minf(r.size.y * 0.5, 60.0)
	var nrm := (to - c).normalized().orthogonal()
	var tail := PackedVector2Array([base + nrm * 24.0, base - nrm * 24.0, to])
	solid(tail, ca(WHITE, a))
	edge(tail, ca(INK, a), 2.2, 52001 + i * 7, 1.0, 0.4)
	solid(body, ca(WHITE, a))
	edge(body, ca(INK, a), 2.6, 52002 + i * 7, 1.0, 0.5)
	solid(C.ellipse_poly(base, 26.0, 12.0, 10, 52003 + i * 7, 0.0), ca(WHITE, a))
	if a > 0.6:
		_print_card(i, size, r.size.x - 60.0, r.position.x + 30.0, r.position.y + 22.0 + size, size * 1.32, false,
			RED.darkened(0.15) if String(cards[i]["who"]) == "T" else INK, 2)


func mp_cap(hc: Vector2, r: float, s: int) -> void:
	var cap := arc(hc + Vector2(0, -r * 0.35), r * 1.05, r * 0.75, PI, TAU, 10)
	solid(cap, NAVY)
	edge(cap, INK, 2.0, s, 1.0, 0.4)
	ln(hc + Vector2(-r * 0.2, -r * 0.38), hc + Vector2(r * 1.25, -r * 0.34), NAVY.darkened(0.4), r * 0.16, s + 1, 1.0, 0.3)


func mp_hand(c: Vector2, sz: float, flip: bool, stain: float, s: int, rr: float, drip := 0.0) -> void:
	if rr <= 0.0:
		return
	var sx := -1.0 if flip else 1.0
	var palm := C.ellipse_poly(c, sz * 0.5, sz * 0.6, 16, s, 0.06)
	solid(palm, ca(SKIN, rr))
	edge(palm, INK, 2.4, s + 1, rr)
	for f in 4:
		var fc := c + Vector2(sx * (-sz * 0.32 + f * sz * 0.2), -sz * 0.78)
		var fp := C.ellipse_poly(fc, sz * 0.1, sz * 0.26, 10, s + 2 + f, 0.05)
		solid(fp, ca(SKIN, rr))
		edge(fp, INK, 2.0, s + 6 + f, rr, 0.4)
	var th := C.ellipse_poly(c + Vector2(sx * sz * 0.56, -sz * 0.1), sz * 0.24, sz * 0.12, 10, s + 10, 0.05, sx * -0.6)
	solid(th, ca(SKIN, rr))
	edge(th, INK, 2.0, s + 11, rr, 0.4)
	if stain > 0.0 and rr >= 1.0:
		for k in 7:
			var p := c + Vector2((C.rnd(s + 12, k) - 0.5) * sz * 0.8, (C.rnd(s + 13, k) - 0.6) * sz * 1.1)
			var bl := C.ellipse_poly(p, sz * (0.12 + 0.14 * stain), sz * (0.08 + 0.1 * stain), 10, s + 14 + k, 0.3)
			fill(bl, RED.darkened(0.1), s + 30 + k, clampf(stain * 7.0 - k, 0.0, 1.0), 2.2, 0.6, 2.4)
		if stain >= 1.0:
			fill(palm, ca(RED, 0.8), s + 40, 1.0, 3.0, 0.8, 3.0)
	if drip > 0.0:
		for k2 in 3:
			var ph := fmod(t * 0.8 + k2 * 0.33, 1.0)
			var dp := c + Vector2((k2 - 1) * sz * 0.28, sz * 0.6 + ph * sz * 1.2)
			solid(C.ellipse_poly(dp, 6.0, 10.0, 8, s + 50 + k2, 0.0), ca(RED, drip * (1.0 - ph * 0.6)))


# ================================================================== page 0: everybody else
func mp0() -> void:
	var rows: Array[float] = [470.0, 600.0, 706.0]
	var me := Vector2(800, 600)
	var n := 0
	for r in 3:
		for k in 11:
			var x := 110.0 + k * 138.0 + (69.0 if r == 1 else 0.0)
			if x > 1520.0:
				continue
			var pf := Vector2(x, rows[r])
			var rk := rv(0.2 + n * 0.03, 0.4)
			n += 1
			var mine := absf(x - me.x) < 2.0 and r == 1
			var h := 110.0 + r * 18.0
			fk_folk(pf, h, GREY if not mine else NAVY, SKINS[(k + r) % 5], 53000 + n * 9, rk, "flat")
			if mine and rk >= 1.0:
				var hc := pf + Vector2(0, -h + h * 0.16)
				mp_cap(hc, h * 0.16, 53900)
				var sl := rv(wt(3, "SLIVER"), 0.4)
				if sl > 0.0:
					var gl := 0.6 + 0.4 * sin(t * 6.0)
					draw_circle(pf + Vector2(10, -h * 0.55), 18.0, ca(GOLD, 0.35 * gl * sl))
					star(pf + Vector2(10, -h * 0.55), 7.0, GOLD, 53901, sl)
	# the boss: a hand coming down on him
	var hd := _ease(rv(wt(3, "BOSS"), 1.4))
	if hd > 0.0:
		var c := Vector2(800, lerpf(-260.0, 300.0, hd))
		var palm := C.ellipse_poly(c, 230.0, 190.0, 22, 53950, 0.06)
		solid(palm, Color("#2a2533", 0.9))
		for f in 4:
			solid(C.ellipse_poly(c + Vector2(-160 + f * 106, -210), 46.0, 120.0, 12, 53960 + f, 0.05), Color("#2a2533", 0.9))
		draw_circle(Vector2(800, 520), 130.0 * hd, Color(0.1, 0.08, 0.15, 0.18 * hd))


# ================================================================== page 1: the fall guy
func mp1() -> void:
	var t0 := cs(4)
	var rg := rv(t0 - 0.4, 0.8)
	var gr := C.rect_poly(Rect2(-10, 640, W + 20, 120))
	fill(gr, GREY.lightened(0.15), 54000, rg, 4.2, 0.0, 4.0)
	# four decades coming down on him
	var years := ["1959", "1969", "1979", "1989"]
	for k in 4:
		var fall := _ease(rv(t0 + 0.4 + k * 0.6, 1.1))
		if fall <= 0.0:
			continue
		var x: float = [330.0, 520.0, 1080.0, 1270.0][k]
		var y := lerpf(-120.0, 560.0 - (k % 2) * 40.0, fall)
		var pg := C.rect_poly(Rect2(Vector2(x - 80, y - 50), Vector2(160, 100)))
		solid(pg, WHITE)
		edge(pg, INK, 2.2, 54010 + k, 1.0, 0.4)
		solid(C.rect_poly(Rect2(Vector2(x - 80, y - 50), Vector2(160, 26))), RED)
		txt_c(String(years[k]), x, y + 34.0, 40, INK, 54020 + k, 3)
	for k2 in 6:
		var f2 := _ease(rv(wt(4, "DECAY") + k2 * 0.15, 0.8))
		if f2 <= 0.0:
			continue
		var bp := Vector2(330.0 + k2 * 190.0, lerpf(-60.0, 610.0 + (k2 % 2) * 12.0, f2))
		var br := C.rect_poly(Rect2(bp - Vector2(36, 18), Vector2(72, 36)))
		fill(br, BRICK, 54040 + k2, 1.0, 3.0, 0.3, 3.0)
		edge(br, INK, 2.0, 54050 + k2, 1.0, 0.4)
	var th := thomas(Vector2(800, 690), 300.0, 54100, rv(t0 - 0.3, 0.8), true, "tired", "up")
	# we're all fall guys: everyone tumbling
	var rt := rv(cs(5), 0.4)
	if rt > 0.0:
		for k3 in 7:
			var ph := fmod((t - cs(5)) * 0.35 + k3 * 0.143, 1.0)
			var p := Vector2(150.0 + k3 * 215.0, lerpf(-120.0, 760.0, ph))
			fk_push(p, (t - cs(5)) * (1.5 + k3 * 0.3) * (1.0 if k3 % 2 == 0 else -1.0))
			fk_folk(Vector2(0, 60), 120.0, [ORANGE, SKY, GRASS, PINK, PURPLE, SUN, CYAN][k3], SKINS[k3 % 5], 54200 + k3 * 11, rt, "scared")
			fk_pop()


# ================================================================== page 2: Bob
func mp2() -> void:
	var t0 := cs(6)
	var rs := rv(t0 - 0.4, 0.8)
	var street := C.rect_poly(Rect2(-10, 600, W + 20, 160))
	fill(street, GREY.lightened(0.2), 55000, rs, 4.2, 0.0, 4.0)
	# the people who walk past him
	for k in 4:
		var px: float = [180.0, 330.0, 1300.0, 1460.0][k]
		fk_folk(Vector2(px, 700), 150.0, [ORANGE, SKY, PINK, GRASS][k], SKINS[(k * 2) % 5], 55010 + k * 11, rv(wt(7, "STREET") + k * 0.15, 0.5), "smile")
	mp_bob(Vector2(800, 700), 500.0, rv(t0 - 0.2, 1.4))
	# the nameplate
	var rn := rv(t0 + 0.2, 0.6)
	var plate := C.rect_poly(Rect2(70, 60, 440, 130))
	solid(plate, ca(GOLD.darkened(0.1), rn))
	edge(plate, INK, 2.4, 55100, rn)
	txt_c("MAYOR", 290.0, 108.0, 32, INK, 55101, 2, rn)
	txt_c("BOB STEVENS", 290.0, 166.0, 46, INK, 55102, 3, rn)
	var rr := rv(wt(6, "ROBERT") - 0.2, 0.5)
	txt("ROBERT", Vector2(150, 250), 40, GREY.darkened(0.2), 55103, 2, rr)
	ln(Vector2(140, 236), Vector2(320, 230), RED, 6.0, 55104, rv(wt(6, "ROBERT") + 0.4, 0.3), 0.5)
	# the labels
	fk_label("BORING", Vector2(1040, 240), Vector2(885, 275), PURPLE, 32, 55110, rv(wt(7, "BORING"), 0.4))
	fk_label("BALDING", Vector2(1040, 160), Vector2(860, 215), PURPLE, 32, 55120, rv(wt(7, "BALDING"), 0.4))
	fk_label("60", Vector2(1040, 320), Vector2(880, 315), PURPLE, 32, 55130, rv(wt(7, "SIXTY"), 0.4))
	fk_label("FADED SUIT", Vector2(1040, 420), Vector2(880, 430), PURPLE, 32, 55140, rv(wt(7, "FADED"), 0.4))
	# the picture in your head
	var rb := rv(cs(8), 0.6)
	if rb > 0.0:
		cloud(Vector2(300, 400), 300.0, 55150, rb)
		if rb >= 1.0:
			mp_bob(Vector2(300, 470), 150.0, 1.0)
	var rc := rv(cs(9) + 0.2, 0.4)
	path(PackedVector2Array([Vector2(420, 330), Vector2(450, 370), Vector2(510, 290)]), GRASS_DARK, 8.0, 55160, rc)


# ================================================================== page 3: hands
func mp3() -> void:
	var t0 := cs(10)
	var hard := rv(t0, 0.6)
	txt_c("THE HARDEST MAN IN PORT CARRICK", 800.0, 110.0, 44, INK, 56000, 3, hard)
	var rnc := rv(cs(11), 0.4)
	if rnc > 0.0:
		txt_c("(NOT A COMPLIMENT)", 800.0, 160.0, 26, GREY.darkened(0.3), 56001, 2, rnc)
	var mine := rv(cs(12) - 0.2, 0.8)
	var stain_m := rv(wt(12, "BLOOD"), 1.2) * 0.55
	mp_hand(Vector2(300, 420), 150.0, false, stain_m, 56100, mine)
	mp_hand(Vector2(520, 430), 150.0, true, stain_m, 56160, mine)
	txt_c("MINE", 410.0, 640.0, 34, NAVY, 56200, 2, rv(cs(13), 0.4))
	var his := rv(cs(14) - 0.2, 0.8)
	var stain_h := rv(cs(14), 1.0)
	mp_hand(Vector2(1080, 420), 150.0, false, stain_h, 56300, his, rv(cs(14) + 0.8, 0.6))
	mp_hand(Vector2(1300, 430), 150.0, true, stain_h, 56360, his, rv(cs(14) + 0.8, 0.6))
	txt_c("HIS", 1190.0, 640.0, 34, RED, 56400, 2, rv(cs(14) + 0.4, 0.4))
	# the soap, never used
	var rso := rv(cs(15), 0.6)
	if rso > 0.0:
		var soap := C.ellipse_poly(Vector2(1470, 610), 60.0, 30.0, 14, 56500, 0.05)
		solid(soap, ca(PINK.lightened(0.4), rso))
		edge(soap, INK, 2.0, 56501, rso)
		txt_c("SOAP", 1470.0, 620.0, 22, INK, 56502, 2, rso)
		if rso >= 1.0:
			for k in 3:
				star(Vector2(1430 + k * 40, 560 - (k % 2) * 16), 8.0 + 2.0 * sin(t * 5.0 + k), WHITE.darkened(0.05), 56503 + k)


# ================================================================== page 4: the office
func mp4() -> void:
	var t0 := cs(16)
	var rw := rv(t0 - 0.8, 0.8)
	var wall := C.rect_poly(Rect2(-10, -10, W + 20, 560))
	fill(wall, Color("#d8cfb8"), 57000, rw, 4.6, -0.3, 4.2)
	var floor_p := C.rect_poly(Rect2(-10, 550, W + 20, H - 540))
	fill(floor_p, Color("#8a6a4a"), 57001, rw, 4.0, 0.0, 4.0)
	# the window and the city in it
	var win := C.rect_poly(Rect2(860, 50, 480, 260))
	solid(win, ca(SKY.lightened(0.2), rw))
	edge(win, INK, 3.0, 57010, rw)
	if rw >= 1.0:
		for k in 7:
			var bx := 880.0 + k * 66.0
			var bh := 60.0 + C.rnd(57011, k) * 130.0
			solid(C.rect_poly(Rect2(bx, 310 - bh, 56, bh)), GREY.darkened(0.1 + 0.1 * (k % 2)))
		ln(Vector2(1100, 50), Vector2(1100, 310), INK, 3.0, 57012, 1.0, 0.4)
	# 1972, framed on the wall
	var r72 := rv(wt(21, "72"), 0.6)
	if r72 > 0.0:
		var fr := C.rect_poly(Rect2(1400, 80, 150, 180))
		solid(fr, ca(Color("#3a3446"), r72))
		edge(fr, GOLD.darkened(0.2), 5.0, 57020, r72)
		if r72 >= 1.0:
			for k2 in 5:
				var fp := Vector2(1440 + k2 * 18, 220)
				solid(PackedVector2Array([fp + Vector2(-10, 0), fp + Vector2(10, 0), fp + Vector2(0, -40 - sin(t * 9.0 + k2) * 8.0)]), ORANGE)
			txt_c("'72", 1475.0, 150.0, 38, WHITE, 57021, 3)
	# the thermometer: keep the temperature down
	var rtp := rv(wt(24, "TEMPERATURE") - 0.2, 0.5)
	if rtp > 0.0:
		var lv := lerpf(1.0, 0.3, _ease(rv(wt(24, "DOWN"), 1.2)))
		ln(Vector2(110, 120), Vector2(110, 330), INK, 22.0, 57030, rtp, 0.4)
		ln(Vector2(110, 120), Vector2(110, 330), WHITE, 14.0, 57031, rtp, 0.2)
		if rtp >= 1.0:
			ln(Vector2(110, 330), Vector2(110, 330 - 200 * lv), RED, 10.0, 57032, 1.0, 0.2)
			solid(circ(Vector2(110, 346), 22.0, 57033, 12), RED)
	# fishing rod in the corner
	var rfi := rv(wt(30, "FISHING"), 0.6)
	if rfi > 0.0:
		ln(Vector2(1520, 640), Vector2(1440, 300), BROWN, 6.0, 57040, rfi, 0.4)
		path(PackedVector2Array([Vector2(1440, 300), Vector2(1470, 380), Vector2(1480, 440)]), INK, 1.4, 57041, rfi)
	# the election through the window: Carrick and the new girl
	var rel := rv(wt(29, "GEORGE") - 0.3, 0.5)
	if rel > 0.0:
		fk_poster(Vector2(940, 210), 110.0, -0.04, 57050, rel)
		var bp := C.rect_poly(Rect2(1230, 150, 96, 120))
		solid(bp, ca(WHITE, rv(wt(29, "GIRL"), 0.5)))
		edge(bp, ca(INK, rv(wt(29, "GIRL"), 0.5)), 1.8, 57060, rv(wt(29, "GIRL"), 0.5))
		if rv(wt(29, "GIRL"), 0.5) >= 1.0:
			solid(C.rect_poly(Rect2(1230, 150, 96, 14)), SKY)
			txt_c("NOUSSAN", 1278.0, 260.0, 14, NAVY, 57061, 2)
			fk_folk(Vector2(1278, 240), 70.0, SKY, SKINS[1], 57062, 1.0, "smile")
	# Bob behind his desk
	var shake := 0.0
	var sh0 := cs(18) + 0.3
	if t > sh0 and t < sh0 + 0.7:
		shake = sin((t - sh0) / 0.7 * TAU) * 14.0
	var smile := t > cs(32) and t < ce(33)
	mp_bob(Vector2(1060 + shake, 830), 540.0, rv(t0 - 0.6, 1.2), "smile" if smile else "frown")
	var desk := C.rect_poly(Rect2(760, 500, 700, 60))
	fill(desk, BROWN, 57100, rw, 3.6, 0.1, 3.4)
	edge(desk, INK, 2.6, 57101, rw)
	var front := C.rect_poly(Rect2(790, 560, 640, 160))
	fill(front, BROWN.darkened(0.2), 57102, rw, 4.0, 1.4, 3.6)
	edge(front, INK, 2.4, 57103, rw)
	if rw >= 1.0:
		var plate := C.rect_poly(Rect2(990, 455, 200, 46))
		solid(plate, GOLD)
		edge(plate, INK, 1.8, 57104, 1.0, 0.3)
		txt_c("MAYOR STEVENS", 1090.0, 488.0, 20, INK, 57105, 2)
	# eggs, cracked
	var re := rv(cs(16) + 0.2, 0.5)
	if re > 0.0:
		for k3 in 3:
			var ec := Vector2(820 + k3 * 46, 482)
			var egg := C.ellipse_poly(ec, 18.0, 23.0, 12, 57110 + k3, 0.04)
			solid(egg, ca(WHITE, re))
			edge(egg, INK, 1.8, 57113 + k3, re, 0.3)
			if k3 < 2 and rv(wt(16, "CRACK"), 0.3) >= 1.0:
				path(PackedVector2Array([ec + Vector2(-16, -2), ec + Vector2(-6, 6), ec + Vector2(2, -4), ec + Vector2(10, 6), ec + Vector2(17, -1)]), INK, 2.0, 57116 + k3)
				solid(C.ellipse_poly(ec + Vector2(0, 26), 22.0, 6.0, 10, 57119 + k3, 0.1), SUN)
	# the phone, with George on a sticky note
	var rph := rv(wt(33, "GEORGE") - 0.3, 0.4)
	if rph > 0.0:
		var ring := 0.0
		if t > wt(33, "GEORGE") and t < cs(34):
			ring = sin(t * 60.0) * 3.0
		var ph := C.rect_poly(Rect2(Vector2(1300 + ring, 456), Vector2(110, 44)))
		solid(ph, ca(RED.darkened(0.2), rph))
		edge(ph, INK, 2.0, 57130, rph)
		var note := C.rect_poly(Rect2(1330, 400, 90, 50))
		solid(note, ca(SUN.lightened(0.3), rph))
		txt_c("GEORGE", 1375.0, 432.0, 16, INK, 57131, 2, rph)
	# the cameras he wants it for
	var rcm := rv(wt(19, "CAMERAS"), 0.5) * (1.0 - rv(ce(19) + 0.6, 0.4))
	if rcm > 0.0:
		for k4 in 2:
			var cc := Vector2(260 + k4 * 360, 230)
			var body := C.rect_poly(Rect2(cc - Vector2(60, 34), Vector2(120, 68)))
			solid(body, ca(INK, rcm))
			solid(circ(cc + Vector2(70, 0), 20.0, 57140 + k4, 10), ca(GREY, rcm))
			txt_c("REC", cc.x - 20.0, cc.y + 10.0, 20, ca(RED, rcm), 57142 + k4, 2)
	# Thomas, cap in hand
	var mouth := "flat"
	if t >= cs(34) and t < ce(34) + 1.0:
		mouth = "open"
	elif t >= cs(24):
		mouth = "tired"
	var th := thomas(Vector2(400, 800), 540.0, 57200, rv(t0 - 0.4, 1.2), true, mouth, "down")
	# the talk
	var tg: Vector2 = th.get("head", Vector2(400, 300)) + Vector2(60, -100)
	var bg := Vector2(1060, 300)
	for i in range(16, 35):
		var who := String(cards[i]["who"])
		if who == "B":
			mp_say(i, Rect2(640, 24, 660, 0), bg + Vector2(-20, 20), 28)
		elif who == "T":
			mp_say(i, Rect2(40, 24, 600, 0), tg, 28)


# ================================================================== page 5: the gears
func mp5() -> void:
	var t0 := cs(35)
	var rb := rv(t0 - 0.4, 0.8)
	var hc := Vector2(800, 380)
	fk_bust(hc, 150.0, "TG", 58000, rb)
	if rb >= 1.0:
		mp_cap(hc, 150.0, 58100)
	var gs: Array = [[Vector2(640, 150), 70.0, 10, ORANGE], [Vector2(780, 90), 54.0, 8, GOLD], [Vector2(910, 140), 64.0, 9, RED],
		[Vector2(1020, 230), 44.0, 7, SKY], [Vector2(560, 250), 40.0, 7, GRASS]]
	for k in gs.size():
		var g: Array = gs[k]
		var spin := clampf((t - t0 - 0.8 - k * 0.3) / 2.0, 0.0, 1.0)
		var ang := (t - t0) * (0.4 + 1.6 * spin) * (1.0 if k % 2 == 0 else -1.2)
		fk_gear(g[0], float(g[1]), int(g[2]), ang, g[3], 58200 + k * 10, rv(t0 + 0.5 + k * 0.3, 0.4))
