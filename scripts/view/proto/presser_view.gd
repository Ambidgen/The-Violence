extends "res://scripts/view/proto/opening_view.gd"
## Cutscene 2 — the February press conference, and the Valentine's Day shooting
## (prototype, 2026-10-30). Same hand as the opening: a child's brightest crayons over
## an adult's worst day.
##
## Part one is one drawing of the PCPD press room, and the camera cuts round it: Thomas
## at the podium, John Dodger, Kelly (the new one), the pack. Whoever speaks gets a
## crayon speech bubble with a tail to their mouth; Thomas's own voice, the things he
## does not say out loud, stays on the torn notebook strip as in the opening. Every lie
## makes his nose grow, the way a child would draw it. His daughter creeps in at the
## edge of the frame when he tells the girls to travel in pairs, and when Valentine's
## Day comes up.
##
## Part two is his narration over her kind of drawings: a valentine, then the Muhammad
## brothers drawn as a memorial. Nothing of the shooting is shown and the shooter is
## never drawn; the page goes black for his name. Presentation only.

## [text, who, gap before (s), duration (<= 0: from length), camera]
##   who: N = his narration (strip); T = Thomas; J = John Dodger; K = Kelly;
##        C1..C4 = the pack; X = a shout from nowhere in particular;
##        DOTS = the silence; END = the last line, on black.
##   camera: WIDE, TH, JO, KE, CH (the pack, all at once), VAL, BRO, BRO2.
const SAY := [
	["YOU KNOW THAT FEELING WHEN YOU'RE IN A ROOM WITH A BUNCH OF PEOPLE AND NO ONE LIKES YOU?", "N", 2.6, -1.0, "WIDE"],
	["REST ASSURED, WE'RE DOING EVERYTHING WE CAN TO FIND THE MEN RESPONSIBLE.", "T", 0.5, -1.0, "TH"],
	["JOHN DODGER RAISED HIS MICROPHONE.", "N", 0.5, -1.0, "JO"],
	["CHIEF GRENDEL, IS THE DEPARTMENT CERTAIN THESE WERE *MEN* THAT DID THIS?", "J", 0.3, -1.0, "JO"],
	["UHH, YEAH WE GOT AN EYEWITNESS ACCOUNT SAYING THE SUSPECTS WERE MALE.", "T", 0.4, -1.0, "TH"],
	["I LIED THROUGH MY TEETH.", "N", 0.3, 2.2, "TH"],
	["DID THE WITNESS SAY HOW MANY THERE WERE?", "J", 0.4, -1.0, "JO"],
	["MORE THAN ONE DEFINITELY.", "T", 0.3, -1.0, "TH"],
	["SO MAYBE TWO OR THREE THEN?", "J", 0.3, -1.0, "JO"],
	["ALMOST CERTAINLY. IT WAS DARK THEY SAID BUT THEY WERE FAIRLY CONFIDENT.", "T", 0.3, -1.0, "TH"],
	["ANYTHING ELSE YOU *CAN'T* TELL US ABOUT THE SUSPECTS?", "J", 0.3, -1.0, "JO"],
	["UNFORTUNATELY THOSE ARE THE DETAILS FOR NOW.", "T", 0.3, -1.0, "TH"],
	["THE NEW ONE RAISED HER MIC.", "N", 0.6, -1.0, "KE"],
	["CHIEF, DO YOU MIND GIVING US YOUR PREDICTION?", "K", 0.3, -1.0, "KE"],
	["FOR?", "T", 0.3, 1.3, "TH"],
	["THE YEAR. IT'S ONLY FEBRUARY AND WE'VE ALREADY HAD SEVEN.", "K", 0.3, -1.0, "KE"],
	["I THINK WE'LL STAY UNDER 100 THIS YEAR.", "T", 0.4, -1.0, "TH"],
	["I LIED AGAIN.", "N", 0.2, 1.8, "TH"],
	["THAT'S MY HONEST OPINION.", "T", 0.2, -1.0, "TH"],
	["DO YOU HAVE ANY WORDS FOR RESIDENTS THAT MIGHT BE SCARED FOR THE SUMMER?", "K", 0.4, -1.0, "KE"],
	["KEEPING YOUR LIGHTS ON IS A GREAT WAY TO PREVENT BREAK INS.", "T", 0.3, -1.0, "TH"],
	["ALSO GIRLS, TRAVEL IN PAIRS, JUST BE SMART ABOUT IT. TAKE THE LONGER WAY ACROSS PAISLEY.", "T", 0.2, -1.0, "TH"],
	["WHAT ABOUT THE PEOPLE THAT LIVE ON PAISLEY CHIEF?", "K", 0.3, -1.0, "KE"],
	["STAY INDOORS AS OFTEN AS YOU CAN. KEEP YOUR WINDOWS AND DOORS LOCKED AT ALL TIMES.", "T", 0.3, -1.0, "TH"],
	["IN FACT BOARDING UP YOUR WINDOWS IS RECOMMENDED.", "T", 0.2, -1.0, "TH"],
	["WHAT ARE YOU DOING TO MAKE PAISLEY SAFE AGAIN CHIEF?", "K", 0.4, -1.0, "KE"],
	["...", "T", 0.3, 3.6, "TH"],
	["CHIEF?", "K", 0.2, 1.4, "KE"],
	["...WE'RE COMMITTED TO MAKING PAISLEY AVENUE SAFER KELLY. MYSELF AND THE MAJOR BOTH.", "T", 0.5, -1.0, "TH"],
	["JUST LIKE WE'RE COMMITTED TO EVERY STREET IN PORT CARRICK. NO EXCEPTIONS.", "T", 0.2, -1.0, "TH"],
	["NO EXCEPTIONS?", "K", 0.3, 1.6, "KE"],
	["ALL OF OUR RESIDENTS CAN COUNT ON THE SAME SWIFT RESPONSE FROM THE PCPD WHEN AND WHERE THEY NEED IT.", "T", 0.3, -1.0, "TH"],
	["ALL HUNDRED THOUSAND OF THEM. THANK YOU KELLY-", "T", 0.2, -1.0, "TH"],
	["NINETY-NINE.", "K", -0.5, 1.5, "TH"],
	["...WHAT?", "T", 0.3, 1.4, "TH"],
	["99,870 RESIDENTS CHIEF. AS OF NEW YEARS ANYWAY.", "K", 0.3, -1.0, "KE"],
	["...HAHA THAT'S FUNNY KELLY, GOOD ONE.", "T", 0.4, -1.0, "TH"],
	["CUNT.", "N", 0.2, 1.7, "TH"],
	["ANY PLANS FOR VALENTINE'S DAY CHIEF?", "K", 0.6, -1.0, "KE"],
	["YOU KNOW ME KELLY, DINNER WITH MARY, MAYBE A SUPERHERO MOVIE.", "T", 0.3, -1.0, "TH"],
	["ANYWAY, I'M AFRAID THAT'S ALL THE TIME I HAVE.", "T", 0.2, -1.0, "TH"],
	["ONE MORE QUESTION CHIEF.", "J", 0.2, -1.0, "CH"],
	["CHIEF! ONE MORE.", "C2", 0.0, -1.0, "CH"],
	["CAN I JUST ASK ONE QUICK ONE CHIEF?", "K", 0.0, -1.0, "CH"],
	["CHIEF!", "C4", 0.0, -1.0, "CH"],
	["ONE LAST QUESTION CHIEF.", "C3", 0.0, -1.0, "CH"],
	["DOYOUKNOWWHO'SRESPONSIBLEFORTHELATESTSCENEATBRAIDER.", "X", 0.0, -1.0, "CH"],
	[". . . . .", "DOTS", 0.0, 3.8, "CH"],
	["THE VALENTINE'S DAY MASS SHOOTING", "N", 1.0, -1.0, "VAL"],
	["(NOT TO BE CONFUSED WITH THE VALENTINE'S DAY MASSACRE, THAT TOOK PLACE IN CHICAGO WITHIN THE CHICAGO MAFIA)", "N", 0.3, -1.0, "VAL"],
	["WAS THE SINGLE WORST DAY IN PORT CARRICK HISTORY.", "N", 0.3, 3.6, "VAL"],
	["HARJIT AND KHARIM MUHAMMAD, TWO THIRTY AND THIRTY TWO YEAR OLD BROTHERS", "N", 1.8, -1.0, "BRO"],
	["WHOSE PARENTS HAD IMMIGRATED FROM AFGHANISTAN TWENTY YEARS EARLIER", "N", 0.2, -1.0, "BRO"],
	["WERE THE FIRST VICTIMS.", "N", 0.2, 3.0, "BRO"],
	["I THINK THAT WAS ON PURPOSE.", "N", 0.8, 2.4, "BRO2"],
	["WHO KNOWS?", "N", 0.4, 1.9, "BRO2"],
	["ALL I KNOW IS IT WOULDN'T HAVE MATTERED EITHER WAY.", "N", 0.6, 3.6, "BRO2"],
	["JEREMY WASN'T STOPPING FOR ANYONE THAT DAY.", "END", 1.0, 4.6, "BRO2"],
]

const FRAMES := {
	"WIDE": [800.0, 450.0, 1.0],
	"TH": [800.0, 360.0, 1.75],
	"JO": [500.0, 600.0, 1.6],
	"KE": [1100.0, 600.0, 1.6],
	"CH": [800.0, 440.0, 1.0],
	"VAL": [2400.0, 450.0, 1.0],
	"BRO": [4000.0, 450.0, 1.0],
	"BRO2": [4000.0, 470.0, 1.1],
}

## Bubble placement on screen: [centre x, top y, max width].
const BUBBLE := {
	"T": [800.0, 22.0, 1420.0],
	"J": [990.0, 36.0, 1080.0],
	"K": [620.0, 36.0, 1080.0],
}
## The pack's bubbles pile up where they land.
const CROWD_AT := [[330.0, 96.0, 540.0], [1250.0, 70.0, 560.0], [700.0, 214.0, 640.0], [1330.0, 300.0, 380.0], [300.0, 330.0, 520.0], [800.0, 470.0, 1460.0]]

const WALL := Color("#8cbcff")
const FLOOR := Color("#e0a463")
const WOOD := Color("#c07a3c")

var reporters: Array = []   # [{id, foot, h, s, suit, skin, hair, hair_col, ...}]
var flashes: Array = []     # [[time, position index]]
var flash_pos: Array = []   # world positions of the cameras' flashes
var T_DARK := 0.0
var T_VAL := 0.0
var T_BRO := 0.0


func _build() -> void:
	reporters = [
		{"id": "C1", "foot": Vector2(150, 860), "h": 300.0, "s": 2300, "suit": PURPLE, "skin": Color("#8d5a3b"), "hair": "curly", "hair_col": INK, "prop": "camera"},
		{"id": "C3", "foot": Vector2(570, 885), "h": 320.0, "s": 2340, "suit": GRASS_DARK, "skin": SKIN, "hair": "bald", "hair_col": BROWN, "mustache": true, "prop": "pad"},
		{"id": "C4", "foot": Vector2(1040, 885), "h": 320.0, "s": 2380, "suit": ORANGE, "skin": Color("#c98a5e"), "hair": "bob", "hair_col": BROWN.darkened(0.3), "prop": "pad", "side": -1.0},
		{"id": "C2", "foot": Vector2(1460, 860), "h": 300.0, "s": 2420, "suit": RED, "skin": Color("#f1c7a3"), "hair": "cap", "hair_col": NAVY, "prop": "camera"},
		{"id": "J", "foot": Vector2(330, 905), "h": 420.0, "s": 2460, "suit": Color("#8b93a3"), "skin": SKIN, "hair": "short", "hair_col": Color("#6d6d6d"), "glasses": true, "mustache": true, "tie": RED, "prop": "mic", "mic_label": "PC7", "mic_col": SKY},
		{"id": "K", "foot": Vector2(1270, 905), "h": 400.0, "s": 2500, "suit": Color("#18b5b0"), "skin": Color("#e0ac7e"), "hair": "ponytail", "hair_col": Color("#e2a72e"), "prop": "mic", "mic_label": "4", "mic_col": RED, "side": -1.0},
	]
	flash_pos = [_lens("C1"), _lens("C2"), Vector2(150, 420), Vector2(1450, 420)]
	cards.clear()
	var at := 0.0
	for i in SAY.size():
		var l: Array = SAY[i]
		var text := String(l[0])
		var n := _plain(text).length()
		var dur := float(l[3])
		if dur <= 0.0:
			dur = maxf(1.6, 0.9 + n / 15.0)
		var st := at + float(l[2])
		if String(l[4]) == "CH" and i > 0 and String((SAY[i - 1] as Array)[4]) == "CH" and String(l[1]) != "DOTS":
			st = float(cards[i - 1]["t"]) + 0.62
		var cps := CPS
		if text == "...":
			cps = 1.3
		cards.append({"text": text, "who": String(l[1]), "t": st, "dur": dur, "frame": String(l[4]), "cps": cps})
		at = st + dur
	# the pack all shout until the last one lands; then silence
	var last := -1
	for i2 in cards.size():
		if String(cards[i2]["frame"]) == "CH" and String(cards[i2]["who"]) != "DOTS":
			last = i2
	var ch_end := ce(last)
	for i3 in cards.size():
		if String(cards[i3]["frame"]) == "CH" and String(cards[i3]["who"]) != "DOTS":
			cards[i3]["dur"] = ch_end - cs(i3)
	var dots := last + 1
	cards[dots]["t"] = ch_end
	var at2 := ch_end + float(cards[dots]["dur"])
	for i4 in range(dots + 1, cards.size()):
		var l2: Array = SAY[i4]
		cards[i4]["t"] = at2 + float(l2[2])
		at2 = cs(i4) + float(cards[i4]["dur"])
	T_VAL = ce(dots)
	T_BRO = ce(50) + 0.15
	T_DARK = cs(56)
	T_END = ce(57) + 1.4
	# the cameras: every couple of seconds; a storm in the silence and in the pack
	flashes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 214
	var ft := 2.2
	while ft < cs(47) - 0.1:
		flashes.append([ft, rng.randi() % flash_pos.size()])
		var gap := rng.randf_range(1.3, 2.8)
		if ft > cs(26) and ft < ce(26):
			gap = rng.randf_range(0.2, 0.42)
		elif ft > cs(41):
			gap = rng.randf_range(0.1, 0.26)
		ft += gap
	intrusions = [
		{"kind": "girl_alone", "t": wt(21, "GIRLS") - 0.2, "dur": 3.8},
		{"kind": "valentine", "t": wt(39, "MARY") - 0.2, "dur": 3.4},
	]


func cues() -> Dictionary:
	var ft: Array = []
	for f: Array in flashes:
		ft.append(float(f[0]))
	var starts: Array = []
	for c: Dictionary in cards:
		starts.append(float(c["t"]))
	return {"cards": starts, "flashes": ft, "pack": cs(41), "shout": cs(46), "dots": cs(47), "val": T_VAL,
		"bro": T_BRO, "worst": wt(50, "WORST"), "dark": T_DARK, "end_line": cs(57), "end": T_END}


func _rep(id: String) -> Dictionary:
	for rp: Dictionary in reporters:
		if String(rp["id"]) == id:
			return rp
	return {}


func _head_of(rp: Dictionary) -> Vector2:
	var h: float = rp["h"]
	var foot: Vector2 = rp["foot"]
	return foot + Vector2(0, -h + h * 0.165)


func _lens(id: String) -> Vector2:
	var rp := _rep(id)
	return _head_of(rp) + Vector2(0, float(rp["h"]) * 0.02)


func _mouth(who: String) -> Vector2:
	match who:
		"T":
			return Vector2(800, 330)
		"X":
			return Vector2(-1, -1)
	var rp := _rep(who)
	if rp.is_empty():
		return Vector2(-1, -1)
	return _head_of(rp) + Vector2(0, float(rp["h"]) * 0.165 * 0.45)


## Is `who` mid-sentence (their bubble still printing)?
func _talking(who: String) -> bool:
	for i in cards.size():
		if String(cards[i]["who"]) != who:
			continue
		var plen := _plain(String(cards[i]["text"])).length() / float(cards[i]["cps"])
		if t >= cs(i) and t < cs(i) + plen and t < ce(i):
			return true
	return false


# ================================================================== camera
func _cam() -> Array:
	var i := -1
	for k in cards.size():
		if t >= cs(k) - 0.25:
			i = k
	var tgt: Array = FRAMES["WIDE"] if i < 0 else FRAMES[String(cards[i]["frame"])]
	var prv: Array = FRAMES["WIDE"] if i <= 0 else FRAMES[String(cards[i - 1]["frame"])]
	var start := 0.0 if i < 0 else cs(i) - 0.25
	var dur := 0.5
	if i >= 0:
		var f0 := String(cards[i]["frame"])
		var f1 := String(cards[i - 1]["frame"]) if i > 0 else "WIDE"
		if f0 == "VAL" and f1 == "CH":
			dur = 0.01
		elif f0 == "BRO" and f1 == "VAL":
			start = T_BRO
			dur = maxf(0.3, cs(i) - T_BRO - 0.1)
		elif f0 == "BRO2" and f1 == "BRO":
			dur = 5.0
	var f := _ease((t - start) / dur)
	var cx := lerpf(float(prv[0]), float(tgt[0]), f)
	var cy := lerpf(float(prv[1]), float(tgt[1]), f)
	var z := lerpf(float(prv[2]), float(tgt[2]), f)
	if t > cs(41) - 0.25 and t < cs(47):
		var pk := clampf((t - cs(41)) / (cs(47) - cs(41)), 0.0, 1.0)
		z += 0.35 * pk * pk
		cy -= 90.0 * pk * pk
	return [Vector2(cx, cy), z]


func to_screen(p: Vector2, cc: Vector2, z: float) -> Vector2:
	return (p - cc) * z + Vector2(W, H) * 0.5


# ================================================================== draw
func _draw() -> void:
	C.frame = int(t * 8.0)
	C.boil = 1.0
	var rs := vp.x / W
	var cam := _cam()
	var cc: Vector2 = cam[0]
	var z: float = cam[1]
	var half := Vector2(W, H) * 0.5 / z
	for pg in 3:
		var x0 := pg * W
		if x0 + W < cc.x - half.x - 2.0 or x0 > cc.x + half.x + 2.0:
			continue
		var off := (Vector2(x0, 0.0) - cc) * z + Vector2(W, H) * 0.5
		draw_set_transform(off * rs, 0.0, Vector2(z, z) * rs)
		draw_texture_rect(paper, Rect2(0, 0, W, H), false)
		match pg:
			0: _room()
			1: _valentine()
			2: _brothers()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(rs, rs))
	if t < cs(47):
		_flash_wash()
		_insets()
		_intrusions()
		_bubbles(cc, z)
	_darkness()
	_captions()
	_dots()
	_end_line()


# ================================================================== the press room
func _room() -> void:
	var wall := C.rect_poly(Rect2(-10, -10, W + 20, 580))
	fill(wall, WALL, 2002, rv(0.0, 0.7), 5.0, -0.25, 4.4)
	var flr := C.rect_poly(Rect2(-10, 560, W + 20, 350))
	fill(flr, FLOOR, 2003, rv(0.1, 0.6), 4.6, 0.12, 4.2)
	if t > 0.7:
		for k in 5:
			var y := 600.0 + k * k * 18.0 + k * 30.0
			ln(Vector2(-10, y), Vector2(W + 10, y), WOOD, 2.6, 2004 + k, 1.0, 1.0)
		ln(Vector2(-10, 562), Vector2(W + 10, 562), INK, 4.0, 2010, 1.0, 0.8)
	# the badge on the wall, a clock, two flags
	var rb := rv(0.4, 0.5)
	star(Vector2(800, 112), 96.0, GOLD, 2011, rb)
	if rb >= 1.0:
		txt_c("PCPD", 800.0, 128.0, 30, NAVY, 2012, 3)
	var rcl := rv(0.6, 0.4)
	if rcl > 0.0:
		var face := circ(Vector2(1210, 110), 46.0, 2013, 18)
		solid(face, ca(WHITE, rcl))
		edge(face, INK, 3.0, 2014, rcl)
		if rcl >= 1.0:
			ln(Vector2(1210, 110), Vector2(1210, 80), INK, 4.0, 2015, 1.0, 0.4)
			ln(Vector2(1210, 110), Vector2(1232, 118), INK, 4.0, 2016, 1.0, 0.4)
			for q in 4:
				var a := TAU * q / 4.0
				draw_circle(Vector2(1210, 110) + Vector2(cos(a), sin(a)) * 36.0, 3.0, INK)
	var rf := rv(0.5, 0.6)
	for pole: float in [470.0, 1130.0]:
		ln(Vector2(pole, 560), Vector2(pole, 140), Color("#d8b25a"), 6.0, 2020 + int(pole), rf, 0.5)
		if rf >= 1.0:
			draw_circle(Vector2(pole, 136), 9.0, GOLD)
	if rf >= 1.0:
		var wv := sin(t * 2.0) * 5.0
		var us := PackedVector2Array([Vector2(478, 150), Vector2(650, 150 + wv), Vector2(650, 262 + wv), Vector2(478, 262)])
		solid(us, WHITE)
		for k2 in 7:
			var y2 := 158.0 + k2 * 16.0
			ln(Vector2(480, y2), Vector2(648, y2 + wv * (y2 - 150.0) / 112.0 * 0.0 + wv), RED, 6.0, 2030 + k2, 1.0, 0.6)
		var canton := C.rect_poly(Rect2(478, 150, 76, 62))
		fill(canton, NAVY, 2040, 1.0, 3.4, 0.6, 3.6)
		for k3 in 9:
			draw_circle(Vector2(488 + (k3 % 3) * 26, 162 + (k3 / 3) * 18), 3.2, WHITE)
		edge(us, INK, 2.4, 2041)
		var pa := PackedVector2Array([Vector2(1138, 150), Vector2(1310, 150 + wv), Vector2(1310, 262 + wv), Vector2(1138, 262)])
		fill(pa, Color("#2246c9"), 2042, 1.0, 3.6, -0.5, 3.8)
		edge(pa, INK, 2.4, 2043)
		solid(circ(Vector2(1224, 206 + wv * 0.5), 26.0, 2044, 14), GOLD)
		txt_c("PA", 1224.0, 216.0 + wv * 0.5, 20, NAVY, 2045, 2)
	# the TV cameras on their tripods
	var rtv := rv(1.2, 0.6)
	for side: float in [-1.0, 1.0]:
		var cpos := Vector2(800 + side * 650, 420)
		for leg in 3:
			ln(cpos + Vector2(0, 30), cpos + Vector2((leg - 1) * 46.0, 200), INK, 4.0, 2050 + leg + int(side) * 5, rtv, 0.5)
		var box := C.rect_poly(Rect2(cpos + Vector2(-66, -36), Vector2(132, 70)))
		fill(box, Color("#3a3f4a"), 2060 + int(side), rtv, 3.4, 0.6, 3.6)
		edge(box, INK, 2.6, 2062 + int(side), rtv)
		if rtv >= 1.0:
			var lens := cpos + Vector2(-side * 76, 0)
			solid(circ(lens, 24.0, 2064 + int(side), 12), INK)
			draw_circle(lens, 11.0, SKY.darkened(0.4))
			draw_circle(cpos + Vector2(side * 40, -24), 7.0, RED if fmod(t, 1.4) < 0.9 else RED.darkened(0.5))
	# Thomas, behind the podium
	var st := _th_state()
	thomas(Vector2(800, 690), 470.0, 2100, rv(0.6, 1.2), true, String(st[0]), "podium", 1.0, float(st[1]), float(st[2]))
	var rp := rv(1.0, 0.6)
	var pod := PackedVector2Array([Vector2(660, 470), Vector2(940, 470), Vector2(915, 702), Vector2(685, 702)])
	solid(pod, ca(WOOD.lightened(0.3), 0.8 * rp))
	fill(pod, WOOD, 2120, rp, 4.0, 1.2, 3.8)
	edge(pod, INK, 3.0, 2121, rp)
	var lip := C.rect_poly(Rect2(648, 456, 304, 22))
	fill(lip, WOOD.darkened(0.25), 2122, rp, 3.4, 0.1, 3.4)
	edge(lip, INK, 2.6, 2123, rp)
	if rp >= 1.0:
		star(Vector2(800, 566), 48.0, GOLD, 2124)
		txt_c("PCPD", 800.0, 642.0, 24, GOLD.lightened(0.3), 2125, 2)
	# the microphones on the podium
	var rm := rv(1.4, 0.4)
	if rm > 0.0:
		var mics: Array = [[730.0, RED, "4"], [770.0, SKY, "PC7"], [810.0, SUN, "11"], [850.0, GRASS, "NEWS"], [880.0, PURPLE, "9"]]
		for mi in mics.size():
			var m: Array = mics[mi]
			var bx := float(m[0])
			var head := Vector2(lerpf(bx, 800.0, 0.55), 404.0 + (mi % 2) * 14.0)
			ln(Vector2(bx, 466), head, INK, 4.0, 2130 + mi, rm, 0.4)
			if rm >= 1.0:
				solid(oval(head, 10.0, 13.0, 2140 + mi, 10), INK)
				var cube := head.lerp(Vector2(bx, 466), 0.45)
				var cr := C.rect_poly(Rect2(cube - Vector2(16, 11), Vector2(32, 22)))
				solid(cr, m[1])
				edge(cr, INK, 1.6, 2150 + mi, 1.0, 0.4)
	# the press
	var order := ["C1", "C3", "C4", "C2", "J", "K"]
	for oi in order.size():
		var rp2 := _rep(order[oi])
		var who := String(rp2["id"])
		var mouth := "frown"
		if _talking(who) or (t > cs(41) and t < cs(47) and C.frame % 2 == oi % 2):
			mouth = "open" if C.frame % 2 == 0 else "frown"
		_reporter(rp2, rv(1.3 + oi * 0.12, 0.7), mouth, _mic_up(who))
	# flashes
	for fl: Array in flashes:
		var dt := t - float(fl[0])
		if dt >= 0.0 and dt < 0.16:
			var p: Vector2 = flash_pos[int(fl[1])]
			var a := 1.0 - dt / 0.16
			var burst := PackedVector2Array()
			for j in 16:
				var rad := (58.0 if j % 2 == 0 else 22.0) * (0.8 + 0.4 * a)
				var ang := TAU * j / 16.0 + float(fl[0])
				burst.append(p + Vector2(cos(ang), sin(ang)) * rad)
			solid(burst, Color(1.0, 1.0, 0.85, 0.95 * a))
			edge(burst, ca(SUN, a), 2.0, 2200 + j_seed(fl), 1.0, 0.4)


func j_seed(fl: Array) -> int:
	return int(float(fl[0]) * 100.0) % 997


func _th_state() -> Array:
	var mouth := "tired"
	if _talking("T"):
		mouth = "open" if C.frame % 2 == 0 else "tired"
	if t >= cs(26) and t < ce(26):
		mouth = "flat"
	if t >= cs(36) and t < ce(37) + 0.3:
		mouth = "grin"
	var nose := 0.45 * _ease(rv(wt(5, "LIED"), 0.6)) + 0.55 * _ease(rv(wt(17, "LIED"), 0.6))
	var sweat := rv(cs(25), 0.5) * (1.0 - rv(ce(30), 0.8)) + rv(cs(41), 0.5)
	return [mouth, nose, clampf(sweat, 0.0, 1.0)]


func _mic_up(who: String) -> float:
	var pack := _ease(rv(cs(41) - 0.3, 0.4))
	match who:
		"J":
			return maxf(0.15 + 0.85 * _ease(rv(cs(2), 0.5)) * (1.0 - 0.75 * _ease(rv(cs(12), 0.6))), pack)
		"K":
			return maxf(0.15 + 0.85 * _ease(rv(cs(12), 0.5)), pack)
	return pack


## A reporter, front-on, the way she'd draw a grown-up in a suit.
func _reporter(rp: Dictionary, rr: float, mouth: String, up: float) -> void:
	if rr <= 0.0:
		return
	var foot: Vector2 = rp["foot"]
	var h: float = rp["h"]
	var s: int = rp["s"]
	var suit: Color = rp["suit"]
	var skin: Color = rp["skin"]
	var side := float(rp.get("side", 1.0))
	var prop := String(rp.get("prop", ""))
	var r := h * 0.165
	var bob := sin(t * 1.3 + s) * h * 0.006
	var hc := foot + Vector2(0, -h + r + bob)
	var neck := hc + Vector2(0, r * 0.95)
	var hip := foot.y - h * 0.34
	var bw0 := h * 0.15
	var bw1 := h * 0.18
	var r1 := clampf(rr * 3.0, 0.0, 1.0)
	var r2 := clampf(rr * 3.0 - 1.0, 0.0, 1.0)
	var r3 := clampf(rr * 3.0 - 2.0, 0.0, 1.0)
	for sd: float in [-1.0, 1.0]:
		var lx := foot.x + sd * h * 0.075
		var leg := C.rect_poly(Rect2(lx - h * 0.046, hip, h * 0.092, foot.y - hip - h * 0.03))
		fill(leg, suit.darkened(0.35), s + 3 + int(sd), r1, 4.0, 1.2, 3.2)
		edge(leg, INK, 2.2, s + 5 + int(sd), r1)
	var body := PackedVector2Array([neck + Vector2(-bw0, 0), neck + Vector2(bw0, 0), Vector2(foot.x + bw1, hip + h * 0.05), Vector2(foot.x - bw1, hip + h * 0.05)])
	solid(body, ca(suit.lightened(0.35), 0.5 * r1))
	fill(body, suit, s + 10, r1, 4.0, -0.6, 3.8)
	edge(body, INK, 2.8, s + 11, r1)
	if r1 >= 1.0:
		var vee := PackedVector2Array([neck + Vector2(-bw0 * 0.42, 0), neck + Vector2(bw0 * 0.42, 0), neck + Vector2(0, h * 0.12)])
		solid(vee, WHITE)
		edge(vee, INK, 1.8, s + 12, 1.0, 0.4)
		if rp.has("tie"):
			var tie := PackedVector2Array([neck + Vector2(-h * 0.015, h * 0.01), neck + Vector2(h * 0.015, h * 0.01), neck + Vector2(h * 0.03, h * 0.15), neck + Vector2(0, h * 0.18), neck + Vector2(-h * 0.03, h * 0.15)])
			solid(tie, rp["tie"])
		var badge := PackedVector2Array() if rp.has("plain") else C.rect_poly(Rect2(neck + Vector2(-bw0 * 0.75, h * 0.1), Vector2(h * 0.07, h * 0.05)))
		if badge.size() > 2:
			solid(badge, WHITE)
			edge(badge, INK, 1.4, s + 13, 1.0, 0.3)
	# arms and what they hold
	var shL := neck + Vector2(-bw0 * 0.92, h * 0.03)
	var shR := neck + Vector2(bw0 * 0.92, h * 0.03)
	var downL := Vector2(foot.x - bw1 - h * 0.03, hip + h * 0.02)
	var downR := Vector2(foot.x + bw1 + h * 0.03, hip + h * 0.02)
	var hands: Array = [downL, downR]
	match prop:
		"mic":
			var upH := Vector2(foot.x + side * h * 0.2, hc.y + r * 0.2)
			if side > 0.0:
				hands[1] = downR.lerp(upH, up)
			else:
				hands[0] = downL.lerp(upH, up)
		"pad":
			hands[0] = neck + Vector2(-h * 0.07, h * 0.16 - up * h * 0.04)
			hands[1] = neck + Vector2(h * 0.08, h * 0.14 - up * h * 0.04)
		"camera":
			hands[0] = hc + Vector2(-r * 1.0, r * 0.35)
			hands[1] = hc + Vector2(r * 1.0, r * 0.35)
	if rp.has("hand_l"):
		hands[0] = rp["hand_l"]
	if rp.has("hand_r"):
		hands[1] = rp["hand_r"]
	var shoulders: Array = [shL, shR]
	for k in 2:
		var sh: Vector2 = shoulders[k]
		var hd: Vector2 = hands[k]
		var el := sh.lerp(hd, 0.5) + Vector2((-1.0 if k == 0 else 1.0) * h * 0.05, h * 0.03)
		ln(sh, el, suit, h * 0.05, s + 20 + k, r3, 0.8)
		ln(el, hd, suit, h * 0.045, s + 22 + k, r3, 0.8)
	# head
	var head := circ(hc, r, s + 30, 20)
	solid(head, ca(skin.lightened(0.05), r2))
	fill(head, skin.darkened(0.06), s + 31, r2, 4.6, 0.5, 2.6)
	edge(head, INK, 2.6, s + 32, r2)
	if r2 >= 1.0:
		var hcol: Color = rp.get("hair_col", INK)
		match String(rp.get("hair", "")):
			"short":
				path(arc(hc, r * 1.02, r * 1.0, PI * 1.08, PI * 1.92, 10), hcol, r * 0.3, s + 33)
			"curly":
				for q in 9:
					var a := PI * 1.0 + q * PI / 8.0
					solid(circ(hc + Vector2(cos(a), sin(a)) * r * 0.95, r * 0.26, s + 34 + q, 8), hcol)
			"bald":
				for sd2: float in [-1.0, 1.0]:
					path(arc(hc, r * 1.02, r * 1.02, PI * (1.0 if sd2 < 0.0 else 1.75), PI * (1.25 if sd2 < 0.0 else 2.0), 5), hcol, r * 0.18, s + 44 + int(sd2))
			"bob":
				var bobh := arc(hc, r * 1.12, r * 1.08, PI * 0.85, PI * 2.15, 14)
				path(bobh, hcol, r * 0.34, s + 46)
			"cap":
				var cap := arc(hc + Vector2(0, -r * 0.1), r * 1.04, r * 0.95, PI, TAU, 10)
				solid(cap, hcol)
				ln(hc + Vector2(-r * 0.2, -r * 0.2), hc + Vector2(r * 1.3, -r * 0.18), hcol.darkened(0.3), r * 0.16, s + 47, 1.0, 0.4)
			"ponytail":
				path(arc(hc, r * 1.04, r * 1.02, PI * 1.02, PI * 1.98, 10), hcol, r * 0.32, s + 48)
				var tail := PackedVector2Array([hc + Vector2(r * 0.9, -r * 0.5), hc + Vector2(r * 1.5, -r * 0.1 + sin(t * 3.0) * r * 0.08), hc + Vector2(r * 1.45, r * 0.6), hc + Vector2(r * 1.1, r * 0.4)])
				fill(tail, hcol, s + 49, 1.0, 3.0, 0.9, 3.0)
				edge(tail, INK, 1.8, s + 50, 1.0, 0.5)
		if prop == "camera":
			var box := C.rect_poly(Rect2(hc + Vector2(-r * 1.05, -r * 0.45), Vector2(r * 2.1, r * 1.15)))
			solid(box, Color("#2c2f36"))
			edge(box, INK, 2.0, s + 51, 1.0, 0.5)
			solid(circ(hc + Vector2(0, r * 0.12), r * 0.42, s + 52, 12), INK)
			draw_circle(hc + Vector2(0, r * 0.12), r * 0.2, SKY.darkened(0.3))
			solid(C.rect_poly(Rect2(hc + Vector2(-r * 0.3, -r * 0.8), Vector2(r * 0.6, r * 0.36))), GREY)
			path(arc(hc + Vector2(0, r * 0.95), r * 0.22, r * 0.1, PI + 0.3, TAU - 0.3, 6), INK, 2.4, s + 53)
		else:
			var j := Vector2(C.jit(s, 1), C.jit(s, 2)) * r * 0.012
			for sd3: float in [-1.0, 1.0]:
				var e := hc + Vector2(sd3 * r * 0.36, -r * 0.08) + j
				draw_circle(e, r * 0.08, INK)
				ln(e + Vector2(-sd3 * r * 0.16, -r * 0.24), e + Vector2(sd3 * r * 0.16, -r * 0.3), INK, 2.6, s + 54 + int(sd3), 1.0, 0.4)
				if rp.has("glasses"):
					edge(circ(e, r * 0.2, s + 56 + int(sd3), 10), INK, 2.0, s + 58 + int(sd3), 1.0, 0.3)
			if rp.has("glasses"):
				ln(hc + Vector2(-r * 0.16, -r * 0.08), hc + Vector2(r * 0.16, -r * 0.08), INK, 2.0, s + 60, 1.0, 0.2)
			path(PackedVector2Array([hc + Vector2(0, r * 0.02), hc + Vector2(r * 0.1, r * 0.2), hc + Vector2(-r * 0.04, r * 0.22)]), INK, 2.2, s + 61)
			if rp.has("mustache"):
				var mu := PackedVector2Array([hc + Vector2(-r * 0.3, r * 0.36), hc + Vector2(0, r * 0.27), hc + Vector2(r * 0.3, r * 0.36), hc + Vector2(0, r * 0.33)])
				solid(mu, rp.get("hair_col", BROWN))
			if rp.has("beard"):
				var bd := arc(hc + Vector2(0, r * 0.12), r * 0.92, r * 0.86, 0.15, PI - 0.15, 12)
				bd.append_array(arc(hc + Vector2(0, r * 0.3), r * 0.5, r * 0.32, PI - 0.3, 0.3, 8))
				solid(bd, rp.get("hair_col", INK))
			match mouth:
				"open":
					solid(oval(hc + Vector2(0, r * 0.5), r * 0.14, r * 0.12, s + 62, 10, 0.1), INK)
				"smile":
					path(arc(hc + Vector2(0, r * 0.36), r * 0.3, r * 0.2, 0.25, PI - 0.25, 8), INK, 2.6, s + 63)
				_:
					path(arc(hc + Vector2(0, r * 0.62), r * 0.24, r * 0.12, PI + 0.3, TAU - 0.3, 8), INK, 2.6, s + 63)
	if r3 >= 1.0:
		for k2 in 2:
			var hd2: Vector2 = hands[k2]
			if prop == "camera":
				continue
			solid(circ(hd2, h * 0.034, s + 70 + k2, 10), skin)
			edge(circ(hd2, h * 0.034, s + 72 + k2, 10), INK, 1.6, s + 74 + k2, 1.0, 0.4)
		if prop == "mic":
			var mh: Vector2 = hands[1] if side > 0.0 else hands[0]
			var dir := (Vector2(800, 330) - mh).normalized()
			var head2 := mh + dir * h * 0.17
			ln(mh, head2, INK, 4.0, s + 76, 1.0, 0.3)
			solid(oval(head2, h * 0.026, h * 0.034, s + 77, 10), INK)
			var cube := mh + dir * h * 0.09
			var cr := C.rect_poly(Rect2(cube - Vector2(h * 0.05, h * 0.035), Vector2(h * 0.1, h * 0.07)))
			solid(cr, rp.get("mic_col", RED))
			edge(cr, INK, 1.6, s + 78, 1.0, 0.3)
			txt_c(String(rp.get("mic_label", "")), cube.x, cube.y + h * 0.02, int(h * 0.04), WHITE, s + 79, 1)
		elif prop == "pad":
			var pc := (hands[0] as Vector2).lerp(hands[1], 0.5) + Vector2(0, -h * 0.02)
			var pad := C.rect_poly(Rect2(pc - Vector2(h * 0.07, h * 0.08), Vector2(h * 0.14, h * 0.16)))
			solid(pad, WHITE)
			edge(pad, INK, 1.8, s + 80, 1.0, 0.4)
			for q2 in 4:
				ln(pc + Vector2(-h * 0.05, -h * 0.05 + q2 * h * 0.03), pc + Vector2(h * 0.05, -h * 0.05 + q2 * h * 0.03), SKY, 1.4, s + 81 + q2, 1.0, 0.3)


# ================================================================== bubbles
func _bubbles(cc: Vector2, z: float) -> void:
	var crowd_k := 0
	for i in cards.size():
		var who := String(cards[i]["who"])
		if who == "N" or who == "DOTS" or who == "END":
			continue
		var crowd := String(cards[i]["frame"]) == "CH"
		if t >= cs(i) and t < ce(i):
			var spec: Array = CROWD_AT[mini(crowd_k, CROWD_AT.size() - 1)] if crowd else BUBBLE[who if BUBBLE.has(who) else "T"]
			_bubble(i, spec, cc, z, who == "X")
		if crowd:
			crowd_k += 1


func _bubble(i: int, spec: Array, cc: Vector2, z: float, shout: bool) -> void:
	var size := 30
	var line_h := 46.0
	var pad := 22.0
	var tokens := _tokens(String(cards[i]["text"]))
	var lines := _layout(tokens, size, float(spec[2]) - pad * 2.0)
	var bw := 0.0
	for row: Array in lines:
		var lw := 0.0
		for ti: int in row:
			lw += _tok_w(tokens[ti], size)
		lw += size * 0.42 * (row.size() - 1)
		bw = maxf(bw, lw)
	bw += pad * 2.0
	var bh := lines.size() * line_h + pad * 2.0 - (line_h - size) + 6.0
	var who0 := String(cards[i]["who"])
	var m0 := _mouth(who0)
	var cx0 := float(spec[0])
	if (who0 == "J" or who0 == "K") and String(cards[i]["frame"]) != "CH" and m0.x >= 0.0:
		cx0 = clampf(to_screen(m0, cc, z).x, 240.0, W - 240.0)
	var x := clampf(cx0 - bw * 0.5, 24.0, W - 24.0 - bw)
	var y := float(spec[1])
	var pop := rv(cs(i), 0.12)
	var cen := Vector2(x + bw * 0.5, y + bh * 0.5)
	var s := 4000 + i * 23
	var poly := PackedVector2Array()
	if shout:
		var n := 30
		for k in n:
			var a := TAU * k / n
			var rr := 1.0 if k % 2 == 0 else 0.84
			poly.append(cen + Vector2(cos(a) * (bw * 0.5 + 34.0), sin(a) * (bh * 0.5 + 30.0)) * rr * (0.6 + 0.4 * pop))
	else:
		var rad := 26.0
		var corners: Array = [[Vector2(x + bw - rad, y + rad), -PI * 0.5], [Vector2(x + bw - rad, y + bh - rad), 0.0], [Vector2(x + rad, y + bh - rad), PI * 0.5], [Vector2(x + rad, y + rad), PI]]
		for cr: Array in corners:
			var cp: Vector2 = cr[0]
			var a0: float = cr[1]
			for q in 5:
				var a := a0 + PI * 0.5 * q / 4.0
				var p := cp + Vector2(cos(a), sin(a)) * rad
				poly.append(cen + (p - cen) * (0.6 + 0.4 * pop) + Vector2(C.rnd(s, q * 7 + int(a0 * 10.0)) - 0.5, C.rnd(s + 1, q * 7 + int(a0 * 10.0)) - 0.5) * 3.0)
	var shadow := PackedVector2Array()
	for p2 in poly:
		shadow.append(p2 + Vector2(5, 6))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.14))
	draw_colored_polygon(poly, Color("#fffefa") if not shout else Color("#fff7a8"))
	C.outline(self, poly, INK, 3.0, s + 2, 1.0)
	# the tail, to the speaker's mouth
	var who := String(cards[i]["who"])
	var m := _mouth(who)
	if not shout and m.x >= 0.0 and pop >= 1.0:
		var tgt := to_screen(m, cc, z)
		var bx := clampf(tgt.x, x + 50.0, x + bw - 50.0)
		var b1 := Vector2(bx - 20.0, y + bh - 2.0)
		var b2 := Vector2(bx + 20.0, y + bh - 2.0)
		var mid := (b1 + b2) * 0.5
		var d := tgt - mid
		var head_r := 78.0 if who == "T" else float(_rep(who).get("h", 300.0)) * 0.165
		var L := clampf(d.length() - (head_r * 1.35 + 14.0) * z, 30.0, 320.0)
		var tip := mid + d.normalized() * L
		tip.x = clampf(tip.x, 10.0, W - 10.0)
		tip.y = clampf(tip.y, 10.0, H - 10.0)
		draw_colored_polygon(PackedVector2Array([b1 + Vector2(0, -6), b2 + Vector2(0, -6), tip]), Color("#fffefa"))
		C.line(self, b1, tip, INK, 3.0, s + 3, 0.8, 1)
		C.line(self, b2, tip, INK, 3.0, s + 4, 0.8, 1)
	if pop >= 1.0:
		_print_at(i, tokens, lines, size, x + pad, y + pad + size, line_h, INK, float(cards[i]["cps"]))


func _print_at(i: int, tokens: Array, lines: Array, size: int, left: float, base0: float, line_h: float, col: Color, cps: float) -> void:
	var shown := (t - cs(i) - 0.12) * cps
	var starts: Array = []
	var acc := 0
	for tk: Dictionary in tokens:
		starts.append(acc)
		acc += String(tk["w"]).length() + 1
	var sp := size * 0.42
	for li in lines.size():
		var row: Array = lines[li]
		var x := left
		var y := base0 + li * line_h
		for ti: int in row:
			var tk2: Dictionary = tokens[ti]
			var w := String(tk2["w"])
			var r := clampf((shown - float(starts[ti])) / maxf(1.0, float(w.length())), 0.0, 1.0)
			if r <= 0.0:
				return
			C.letters(self, w, Vector2(x, y), size, RED if bool(tk2["red"]) else col, 5000 + i * 97 + ti * 7, 2, 1.0, r)
			x += C.letters_width(w, size) + sp


# ================================================================== screen-space bits
func _flash_wash() -> void:
	for fl: Array in flashes:
		var dt := t - float(fl[0])
		if dt >= 0.0 and dt < 0.12:
			draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, 0.16 * (1.0 - dt / 0.12)))


## Paisley, as a scrap pinned up beside him: the sign, then a boarded-up house.
func _insets() -> void:
	var a := rv(wt(21, "PAISLEY") - 0.3, 0.4) * (1.0 - rv(cs(28), 0.5))
	if a <= 0.0:
		return
	var scrap := PackedVector2Array()
	for k in 8:
		scrap.append(Vector2(lerpf(40, 400, k / 8.0), 214 + (C.rnd(6000, k) - 0.5) * 10.0))
	for k2 in 8:
		scrap.append(Vector2(400 + (C.rnd(6001, k2) - 0.5) * 8.0, lerpf(214, 540, k2 / 8.0)))
	for k3 in 8:
		scrap.append(Vector2(lerpf(400, 40, k3 / 8.0), 540 + (C.rnd(6002, k3) - 0.5) * 10.0))
	for k4 in 8:
		scrap.append(Vector2(40 + (C.rnd(6003, k4) - 0.5) * 8.0, lerpf(540, 214, k4 / 8.0)))
	var sh := PackedVector2Array()
	for p in scrap:
		sh.append(p + Vector2(5, 6))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.12 * a))
	draw_colored_polygon(scrap, ca(Color("#fffdf7"), a))
	ln(Vector2(130, 520), Vector2(130, 270), ca(GREY.darkened(0.3), a), 6.0, 6010, 1.0, 0.4)
	var sign_r := C.rect_poly(Rect2(58, 238, 290, 56))
	solid(sign_r, ca(GRASS_DARK, a))
	edge(sign_r, ca(WHITE, a), 3.0, 6011, 1.0, 0.6)
	txt_c("PAISLEY AVE", 203.0, 280.0, 30, ca(WHITE, a), 6012, 2)
	var rh := rv(wt(24, "BOARDING") - 0.1, 0.6)
	house(186.0, 520.0, 150.0, 110.0, PINK, BROWN, 6020, rh, true, 0.0, a)


func _intrusions() -> void:
	for it: Dictionary in intrusions:
		var p := (t - float(it["t"])) / float(it["dur"])
		if p <= 0.0 or p >= 1.0:
			continue
		var inn := _ease(p / 0.3)
		var a := 1.0 - _ease((p - 0.72) / 0.28)
		var slide := (1.0 - inn) * 160.0
		match String(it["kind"]):
			"girl_alone":
				stick(Vector2(1490 + slide, 600), 220.0, "me", 6100, inn, a, Vector2.ZERO, Vector2.ZERO, 3.0)
			"valentine":
				var c := Vector2(1440 + slide, 470)
				var card := PackedVector2Array([c + Vector2(-110, -90), c + Vector2(110, -96), c + Vector2(116, 90), c + Vector2(-104, 96)])
				solid(card, ca(Color("#ffd1e6"), a * inn))
				edge(card, ca(PINK.darkened(0.2), a), 2.6, 6110, inn)
				heart(c + Vector2(0, -16), 42.0, ca(RED, a), 6111, inn)
				txt_c("DADDY", c.x, c.y + 72.0, 30, ca(PURPLE, a), 6112, 2, inn)


func _captions() -> void:
	var strip_on := false
	var cur := -1
	for i in cards.size():
		if String(cards[i]["who"]) != "N":
			continue
		if t >= cs(i) - 0.25 and t < ce(i) + 0.4:
			strip_on = true
		if t >= cs(i) and t < ce(i):
			cur = i
	if strip_on:
		_strip()
	if cur >= 0:
		_print_card(cur, 31, 1330.0, 160.0, 766.0, 54.0, false, INK, 2)


func _dots() -> void:
	var i := 47
	if t < cs(i) or t >= ce(i):
		return
	draw_rect(Rect2(0, 0, W, H), INK)
	for k in 5:
		var at := cs(i) + 0.3 + k * 0.62
		if t >= at:
			draw_circle(Vector2(680 + k * 60, 450), 7.0, Color("#f4f0e6"))


## As he says it wouldn't have mattered, the page is scribbled black from the edges.
func _darkness() -> void:
	if t < T_DARK:
		return
	var k := clampf((t - T_DARK) / (cs(57) - T_DARK), 0.0, 1.0)
	var limits: Array[float] = [190.0, 440.0, 170.0, 450.0]
	for e in 4:
		var depth := _ease(k) * limits[e]
		for i in 60:
			var s := 8000 + e * 131 + i
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
			var L := depth * (0.55 + 0.45 * C.rnd(s, 3))
			if L < 6.0:
				continue
			var nrm := Vector2(-dir.y, dir.x)
			var n := int(L / 14.0) + 2
			var pts := PackedVector2Array()
			for j in n:
				var f := float(j) / (n - 1)
				pts.append(st + dir * L * f + nrm * (C.jit(s, j) * 22.0))
			draw_polyline(pts, ca(INK, 0.92), 9.0 + 6.0 * C.rnd(s, 5), true)
	if t >= cs(57) - 0.4:
		draw_rect(Rect2(0, 0, W, H), ca(INK, rv(cs(57) - 0.4, 0.4)))


func _end_line() -> void:
	if t < cs(57):
		return
	_print_card(57, 46, 1300.0, 0.0, 462.0, 70.0, true, Color("#f4f0e6"), 3)


# ================================================================== part two: the valentine
func _valentine() -> void:
	if t < T_VAL:
		return
	var tv := T_VAL
	var rbd := rv(tv, 0.7)
	var outer := C.rect_poly(Rect2(-10, -10, W + 20, H + 20))
	var band := PackedVector2Array()
	band.append_array(outer)
	for side_r: Rect2 in [Rect2(-10, -10, W + 20, 46), Rect2(-10, H - 36, W + 20, 46), Rect2(-10, -10, 46, H + 20), Rect2(W - 36, -10, 46, H + 20)]:
		fill(C.rect_poly(side_r), PINK, 7000 + int(side_r.position.x + side_r.position.y), rbd, 3.8, 0.7, 3.8)
	var rdo := rv(tv + 0.3, 0.6)
	if rdo > 0.0:
		var cdo := Vector2(800, 420)
		for k in 30:
			var a := TAU * k / 30.0
			solid(circ(cdo + Vector2(cos(a), sin(a)) * 278.0, 26.0, 7100 + k, 10), ca(WHITE, rdo))
		solid(circ(cdo, 280.0, 7140, 36), ca(WHITE, rdo))
		for k2 in 30:
			var a2 := TAU * k2 / 30.0
			path(arc(cdo + Vector2(cos(a2), sin(a2)) * 278.0, 26.0, 26.0, a2 - 1.3, a2 + 1.3, 6), ca(Color("#f3b3cf"), rdo), 2.0, 7150 + k2)
			draw_circle(cdo + Vector2(cos(a2), sin(a2)) * 246.0, 6.0, ca(Color("#fde3ef"), rdo))
	var rh := rv(tv + 0.6, 0.8)
	heart(Vector2(800, 430), 210.0, RED, 7200, rh)
	if rh >= 1.0:
		txt_c("FEB 14", 800.0, 470.0, 66, WHITE, 7201, 3)
	txt_c("HAPPY VALENTINE'S DAY", 800.0, 112.0, 52, RED, 7202, 3, rv(tv + 0.4, 1.2))
	var small: Array = [[160.0, 220.0], [1440.0, 230.0], [210.0, 600.0], [1380.0, 640.0], [470.0, 140.0], [1130.0, 150.0], [120.0, 420.0], [1480.0, 440.0]]
	for k3 in small.size():
		var sp: Array = small[k3]
		heart(Vector2(float(sp[0]), float(sp[1])), 24.0 + 8.0 * C.rnd(7210, k3), PINK if k3 % 2 == 0 else PURPLE, 7220 + k3 * 3, rv(tv + 0.8 + k3 * 0.08, 0.3))
	# not that one: Chicago, 1929, crossed out
	var rc := rv(cs(49) + 0.3, 0.6)
	if rc > 0.0:
		var scrap := C.rect_poly(Rect2(1150, 440, 380, 250))
		solid(scrap, ca(Color("#fffdf7"), rc))
		edge(scrap, GREY, 2.0, 7300, rc)
		var bld: Array = [[1180.0, 70.0, 100.0], [1250.0, 54.0, 150.0], [1310.0, 60.0, 90.0], [1370.0, 50.0, 130.0], [1425.0, 70.0, 80.0]]
		for b in bld.size():
			var bd: Array = bld[b]
			var br := C.rect_poly(Rect2(float(bd[0]), 670.0 - float(bd[2]), float(bd[1]), float(bd[2])))
			fill(br, [GREY, LILAC, SKY.darkened(0.2), GREY.darkened(0.2), PURPLE.lightened(0.3)][b], 7310 + b * 3, rc, 3.4, 0.4, 3.2)
			edge(br, INK, 1.8, 7311 + b * 3, rc, 0.5)
		txt("CHICAGO 1929", Vector2(1172, 484), 26, INK, 7330, 2, rc)
		var rx := rv(wt(49, "CHICAGO") + 0.4, 0.5)
		ln(Vector2(1160, 452), Vector2(1520, 680), RED, 10.0, 7331, rx, 1.0)
		ln(Vector2(1520, 452), Vector2(1160, 680), RED, 10.0, 7332, rv(wt(49, "CHICAGO") + 0.7, 0.4), 1.0)
	# the worst day: the heart cracks
	var rcr := rv(wt(50, "WORST") - 0.1, 0.9)
	if rcr > 0.0:
		var pts := PackedVector2Array()
		for j in 9:
			var f := float(j) / 8.0
			pts.append(Vector2(800 + (22.0 if j % 2 == 1 else -14.0) * (1.0 - absf(f - 0.5)), lerpf(366, 650, f)))
		path(pts, INK, 8.0, 7340, rcr, 0.8, 2)


# ================================================================== part two: the brothers
func _brothers() -> void:
	if t < T_BRO:
		return
	var tb := T_BRO
	sky_strip(150.0, SKY, 7401, rv(tb, 0.6))
	sun(Vector2(1450, 96), 52.0, 7402, rv(tb + 0.3, 0.5))
	grass_strip(692.0, 7403, rv(tb + 0.1, 0.6))
	# where their parents came from, and where they came to
	var rj := rv(wt(52, "IMMIGRATED") - 0.4, 0.6)
	if rj > 0.0:
		for k in 3:
			var mx := 70.0 + k * 70.0
			var mtn := PackedVector2Array([Vector2(mx, 300), Vector2(mx + 60, 210 + (k % 2) * 24.0), Vector2(mx + 120, 300)])
			fill(mtn, BROWN.lightened(0.15), 7410 + k, rj, 3.4, 0.5, 3.4)
			edge(mtn, INK, 2.0, 7413 + k, rj)
			if rj >= 1.0:
				solid(PackedVector2Array([Vector2(mx + 42, 236 + (k % 2) * 24.0), Vector2(mx + 60, 210 + (k % 2) * 24.0), Vector2(mx + 78, 236 + (k % 2) * 24.0)]), WHITE)
		txt_c("AFGHANISTAN", 170.0, 336.0, 22, INK, 7420, 2, rj)
		house(1290.0, 300.0, 110.0, 76.0, SUN, RED, 7421, rj)
		txt_c("PORT CARRICK", 1345.0, 336.0, 22, INK, 7422, 2, rj)
		var pf := _ease(rv(wt(52, "IMMIGRATED"), 2.6))
		var a0 := Vector2(300, 250)
		var a1 := Vector2(1280, 250)
		var nd := 34
		for d in int(nd * pf):
			var f := float(d) / nd
			var p := a0.lerp(a1, f) + Vector2(0, -150.0 * 4.0 * f * (1.0 - f))
			if d % 2 == 0:
				draw_circle(p, 3.0, INK)
		if pf > 0.0:
			var p2 := a0.lerp(a1, pf) + Vector2(0, -150.0 * 4.0 * pf * (1.0 - pf))
			var tan := Vector2(1.0, -150.0 * 4.0 * (1.0 - 2.0 * pf) / (a1.x - a0.x)).normalized()
			_plane(p2, tan.angle(), 7430)
	# the brothers, arm in arm
	var joined := Vector2(802, 548)
	var harjit := {"id": "H", "foot": Vector2(690, 700), "h": 360.0, "s": 7500, "suit": Color("#14b8a6"), "skin": Color("#c98a5e"), "hair": "short", "hair_col": INK, "hand_r": joined, "plain": true}
	var kharim := {"id": "KH", "foot": Vector2(915, 700), "h": 380.0, "s": 7600, "suit": ORANGE, "skin": Color("#b97d52"), "hair": "short", "hair_col": INK, "beard": true, "hand_l": joined, "plain": true}
	_reporter(harjit, rv(cs(51) + 0.1, 1.0), "smile", 0.0)
	_reporter(kharim, rv(cs(51) + 0.8, 1.0), "smile", 0.0)
	txt_c("HARJIT", 690.0, 318.0, 34, INK, 7660, 2, rv(wt(51, "HARJIT"), 0.6))
	txt_c("KHARIM", 915.0, 298.0, 34, INK, 7661, 2, rv(wt(51, "KHARIM"), 0.6))
	# the first victims: a frame, a black ribbon, candles and flowers
	var rf := rv(wt(53, "FIRST") - 0.2, 1.0)
	if rf > 0.0:
		var outer := C.rect_poly(Rect2(500, 250, 610, 462))
		var inner := C.rect_poly(Rect2(526, 276, 558, 410))
		edge(outer, Color("#c9962e"), 12.0, 7700, rf, 0.6)
		edge(inner, Color("#8a5a1c"), 6.0, 7701, rf, 0.6)
		if rf >= 1.0:
			var rib := PackedVector2Array([Vector2(1050, 250), Vector2(1110, 250), Vector2(1110, 310)])
			solid(rib, INK)
			ln(Vector2(1080, 280), Vector2(1060, 330), INK, 8.0, 7702, 1.0, 0.4)
			ln(Vector2(1080, 280), Vector2(1104, 334), INK, 8.0, 7703, 1.0, 0.4)
	var rcd := rv(wt(53, "VICTIMS"), 0.8)
	if rcd > 0.0:
		for k2 in 3:
			var cx := 660.0 + k2 * 140.0
			var cnd := C.rect_poly(Rect2(cx - 14, 640 + (k2 % 2) * 12.0, 28, 72 - (k2 % 2) * 12.0))
			solid(cnd, ca(WHITE, rcd))
			edge(cnd, INK, 2.0, 7710 + k2, rcd, 0.5)
			if rcd >= 1.0:
				var fl := Vector2(cx + C.jit(7720 + k2, 1) * 1.5, 628 + (k2 % 2) * 12.0)
				solid(oval(fl, 9.0, 16.0, 7730 + k2, 10), SUN)
				solid(oval(fl + Vector2(0, 4), 4.5, 8.0, 7740 + k2, 8), ORANGE)
		for k3 in 4:
			_flower(Vector2(540 + k3 * 18 + (k3 / 2) * 500.0, 664 - (k3 % 2) * 10), 7750 + k3 * 9, [PINK, SUN, PURPLE, RED][k3])


func _plane(p: Vector2, ang: float, s: int) -> void:
	var T := func(v: Vector2) -> Vector2: return p + v.rotated(ang)
	var body := PackedVector2Array()
	for v: Vector2 in [Vector2(-44, -9), Vector2(34, -9), Vector2(50, 0), Vector2(34, 9), Vector2(-44, 9)]:
		body.append(T.call(v))
	solid(body, WHITE)
	edge(body, INK, 2.2, s, 1.0, 0.4)
	var wing := PackedVector2Array([T.call(Vector2(-4, 0)), T.call(Vector2(14, 0)), T.call(Vector2(-14, 30)), T.call(Vector2(-26, 30))])
	solid(wing, SKY)
	edge(wing, INK, 1.8, s + 1, 1.0, 0.4)
	var tail := PackedVector2Array([T.call(Vector2(-44, -6)), T.call(Vector2(-30, -6)), T.call(Vector2(-46, -24))])
	solid(tail, RED)
	for q in 4:
		draw_circle(T.call(Vector2(-22 + q * 13, -2)), 3.0, SKY.darkened(0.3))
