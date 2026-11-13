extends "res://scripts/view/crayon_short_base.gd"
## Shorts 01-07: calendar, situation file, route, staging, threshold, casualty and debrief.


func draw_short() -> void:
	match key:
		"s01_week":
			_week()
		"s02_situation":
			_situation()
		"s03_plan":
			_plan()
		"s04_staging":
			_staging()
		"s05_threshold":
			_threshold()
		"s06_officer_down":
			_officer_down()
		"s07_debrief":
			_debrief()
		"s15_week_recap":
			_week_recap()
		_:
			_unknown()


func _week() -> void:
	_heading("PORT CARRICK · OPERATIONS BOARD", "THE BOARD REFILLS", 100)
	var week := int(props.get("week", 1))
	var total := maxi(1, int(props.get("of", 40)))
	var big := "%02d" % week
	_panel(Rect2(84, 222, 520, 432), 110, STOCK, _reveal(0.35, 0.75))
	_txt(big, Vector2(126, 510), 230, DARK, 111, 385, _reveal(0.55, 0.65))
	_txt("/ %d WEEKS" % total, Vector2(128, 588), 24, MID, 112, 370, _reveal(0.9, 0.5))
	_txt(
		_slot("week-title", _ps(props.get("ward", "PORT CARRICK"))),
		Vector2(105, 714),
		30,
		DARK,
		113,
		440,
		_reveal(1.0, 0.6)
	)
	var card_data: Array = props.get("cards", [])
	for i in mini(3, card_data.size()):
		var r := Rect2(692, 236 + i * 143, 806, 118)
		_panel(r, 120 + i, STOCK, _reveal(1.2 + i * 0.65, 0.42))
		var item: Dictionary = card_data[i] if card_data[i] is Dictionary else {}
		_txt("0%d" % (i + 1), r.position + Vector2(25, 66), 27, MID, 128 + i)
		_txt(
			String(item.get("kind", "SITUATION")),
			r.position + Vector2(94, 54),
			29,
			DARK,
			130 + i,
			610,
			_reveal(1.45 + i * 0.65, 0.55)
		)
		_txt(String(item.get("ward", "WARD")), r.position + Vector2(95, 93), 17, MID, 140 + i, 560)
	var cells := mini(40, total)
	for j in cells:
		var x := 90.0 + j * 34.5
		var r2 := Rect2(x, 786, 27, 43)
		var active := j < week
		C.hatch_rect(
			self,
			r2,
			_alpha(DARK if active else STOCK, _reveal(0.8 + j * 0.025, 0.18)),
			4.0,
			0.4,
			160 + j,
			1.0
		)
		_box(r2, 170 + j, _reveal(0.8 + j * 0.025, 0.18), DARK)
		if j == week - 1:
			C.scribble_ring(self, r2.get_center(), 19, 28, RED, 210, _reveal(1.5, 0.4), 3.2)
	_txt(
		_slot("note", _ps(props.get("note", "SITUATIONS ON THE BOARD"))),
		Vector2(715, 713),
		21,
		DARK,
		180,
		760,
		_reveal(3.0, 0.5)
	)
	_stamp("WEEK %d" % week, Vector2(1240, 860), 190, DARK)


func _situation() -> void:
	_heading(
		"SITUATION FILE · WEEK %s" % _ps(props.get("week", 12)),
		_ps(props.get("kind", "THE FILE")),
		220
	)
	var folder := Rect2(92, 222, 965, 594)
	_panel(folder, 221, STOCK, _reveal(0.32, 0.65))
	var title_text := _slot("title", _prop_text("title", "SITUATION TITLE"))
	_txt(title_text, Vector2(128, 326), 39, DARK, 224, 860, _reveal(0.65, 0.7))
	_txt(
		_slot("ward", _ps(props.get("ward", "WARD"))),
		Vector2(128, 408),
		25,
		UMBER,
		225,
		620,
		_reveal(1.05, 0.5)
	)
	_txt("VISIBILITY", Vector2(128, 494), 18, MID, 226, 220)
	var visible_n := clampi(int(props.get("visibility", 3)), 1, 5)
	for i in 5:
		var r := Rect2(362 + i * 60, 466, 42, 38)
		C.hatch_rect(
			self,
			r,
			_alpha(DARK if i < visible_n else STOCK, _reveal(1.25 + i * 0.18, 0.22)),
			4.0,
			0.6,
			227 + i,
			1.0
		)
		_box(r, 240 + i, _reveal(1.25 + i * 0.18, 0.22))
	_txt(
		_ps(props.get("pressure", "PRESSURE UNKNOWN")),
		Vector2(128, 576),
		23,
		RED if _ps(props.get("pressure", "")).contains("HIGH") else DARK,
		250,
		760,
		_reveal(2.0, 0.55)
	)
	C.line(self, Vector2(128, 603), Vector2(1000, 603), DARK, 1.7, 251)
	_txt(
		_ps(props.get("room", "ROOM ESTIMATE")),
		Vector2(132, 666),
		19,
		MID,
		252,
		790,
		_reveal(2.5, 0.6)
	)
	# Miniature plan drawing, with an intentionally uncertain room marked in pencil.
	var plan := Rect2(1115, 252, 390, 432)
	_panel(plan, 260, _alpha(PAPER, 0.45), _reveal(0.8, 0.7))
	for r in [
		Rect2(1160, 296, 142, 144),
		Rect2(1320, 296, 142, 144),
		Rect2(1160, 456, 142, 176),
		Rect2(1320, 456, 142, 176)
	]:
		_box(r, 265 + int(r.position.x), _reveal(1.1, 0.7), MID)
	C.scribble_ring(self, Vector2(1387, 528), 63, 55, RED, 270, _reveal(3.0, 0.55), 3.0)
	_txt("EST.", Vector2(1200, 720), 16, MID, 271, 250)
	_stamp("FILED", Vector2(1270, 846), 272, DARK)


func _plan() -> void:
	_heading("BRIEFING SHEET · ROUTE DRAWN BEFORE THE DOOR OPENS", "THE PLAN", 300)
	var r := Rect2(106, 225, 922, 575)
	_panel(r, 301, STOCK, _reveal(0.3, 0.65))
	var rooms := clampi(int(props.get("rooms", 5)), 2, 12)
	var split := Vector2(567, 505)
	var walls := [
		Vector2(145, 282),
		Vector2(988, 282),
		Vector2(988, 740),
		Vector2(145, 740),
		Vector2(145, 282)
	]
	for i in 4:
		C.line(
			self, walls[i], walls[i + 1], DARK, 9, 310 + i, 1.7, 2, _reveal(0.65 + i * 0.25, 0.55)
		)
	C.line(
		self, Vector2(split.x, 282), Vector2(split.x, 465), DARK, 6, 315, 1.2, 2, _reveal(1.6, 0.45)
	)
	C.line(
		self, Vector2(145, split.y), Vector2(420, split.y), DARK, 6, 316, 1.2, 2, _reveal(1.8, 0.45)
	)
	C.line(
		self, Vector2(704, split.y), Vector2(988, split.y), DARK, 6, 317, 1.2, 2, _reveal(2.0, 0.45)
	)
	C.line(
		self, Vector2(split.x, 563), Vector2(split.x, 740), DARK, 6, 318, 1.2, 2, _reveal(2.2, 0.45)
	)
	# A room count is shown as numbered pencil tags; the route itself is the red exception.
	for i in mini(rooms, 8):
		var pos := Vector2(220 + (i % 3) * 210, 354 + int(i / 3) * 158)
		C.evidence(self, pos, i + 1, 320 + i, 1.7)
	var route := [
		Vector2(104, 616),
		Vector2(212, 616),
		Vector2(345, 581),
		Vector2(552, 519),
		Vector2(728, 408),
		Vector2(861, 354)
	]
	for i in route.size() - 1:
		C.line(
			self, route[i], route[i + 1], RED, 5.0, 340 + i, 1.6, 2, _reveal(2.8 + i * 0.38, 0.28)
		)
	for i in mini(8, int(props.get("officers", 6))):
		_person(Vector2(192 + i * 37, 681 + (i % 2) * 16), 0.74, NAVY, 360 + i)
	_panel(Rect2(1080, 246, 412, 524), 370, STOCK, _reveal(1.0, 0.6))
	_txt("ENTRY", Vector2(1120, 330), 18, MID, 371, 280)
	_txt(
		_slot("entry", _ps(props.get("entry", "FRONT DOOR"))),
		Vector2(1120, 390),
		26,
		DARK,
		372,
		330,
		_reveal(2.0, 0.55)
	)
	_txt(
		"SQUADS   %d" % int(props.get("squads", 2)),
		Vector2(1120, 500),
		21,
		DARK,
		373,
		320,
		_reveal(2.5, 0.55)
	)
	_txt(
		_slot("objective", _ps(props.get("objective", "CLEAR THE HOUSE"))),
		Vector2(1120, 624),
		22,
		RED,
		374,
		330,
		_reveal(3.1, 0.55)
	)
	_stamp("SIGNED", Vector2(1180, 839), 380, DARK)


func _staging() -> void:
	_heading("CALL SIGN · " + _ps(props.get("callsign", "A-2")), "STAGING", 400)
	var road := PackedVector2Array(
		[Vector2(80, 390), Vector2(1510, 334), Vector2(1510, 643), Vector2(80, 700)]
	)
	C.hatch(self, road, _alpha(NIGHT, _reveal(0.35, 0.8)), 5.2, 0.5, 401, 2.0)
	C.outline(self, road, DARK, 3.0, 402, 1.2, _reveal(0.35, 0.8))
	for i in 12:
		var x := 148.0 + i * 112.0
		C.line(self, Vector2(x, 530), Vector2(x + 36, 528), _alpha(STOCK, 0.8), 3, 410 + i, 0.8)
	# House face, warm window, and van pair from above.
	_panel(Rect2(422, 236, 654, 174), 430, _alpha(STOCK, 0.7), _reveal(0.8, 0.5))
	for i in 5:
		var x := 461.0 + i * 117.0
		_box(Rect2(x, 276, 72, 61), 440 + i, _reveal(1.1 + i * 0.1, 0.3), MID)
		C.hatch_rect(
			self,
			Rect2(x + 4, 280, 64, 52),
			_alpha(AMBER, 0.68),
			3.2,
			-0.5,
			450 + i,
			1.4,
			_reveal(1.35, 0.3)
		)
	_draw_van(Vector2(280, 542), 1.3, 460)
	_draw_van(Vector2(1295, 570), 1.15, 470)
	var n := clampi(int(props.get("officers", 6)), 2, 12)
	for i in mini(n, 12):
		_person(Vector2(688 + (i % 6) * 49, 622 + int(i / 6) * 27), 0.76, NAVY, 480 + i, i % 4 == 0)
	_panel(Rect2(1090, 704, 404, 104), 500, STOCK, _reveal(2.2, 0.45))
	_txt(
		_slot("callsign", _ps(props.get("callsign", "A-2"))),
		Vector2(1122, 770),
		29,
		NAVY,
		501,
		330,
		_reveal(2.55, 0.35)
	)
	_txt(
		(
			_slot("street", _ps(props.get("street", "FOUNDRY ST")))
			+ " · "
			+ _ps(props.get("time", "02:14"))
		),
		Vector2(96, 834),
		21,
		DARK,
		502,
		630,
		_reveal(3.0, 0.4)
	)
	C.tape(self, Vector2(427, 438), Vector2(1069, 438), 510, 11.0)


func _threshold() -> void:
	_heading("FIRST ROOM · RECOGNITION TAKES A MOMENT", "THE THRESHOLD", 520)
	var room := Rect2(236, 236, 1110, 492)
	_panel(room, 521, _alpha(PAPER, 0.55), _reveal(0.3, 0.6))
	var walls := [
		Vector2(284, 290),
		Vector2(1299, 290),
		Vector2(1299, 674),
		Vector2(284, 674),
		Vector2(284, 290)
	]
	for i in 4:
		if i == 3:
			C.line(self, walls[i], Vector2(284, 520), DARK, 10, 530 + i, 1.5, 2, _reveal(0.7, 0.4))
			C.line(
				self, Vector2(284, 612), walls[i + 1], DARK, 10, 540 + i, 1.5, 2, _reveal(0.7, 0.4)
			)
		else:
			C.line(
				self, walls[i], walls[i + 1], DARK, 10, 530 + i, 1.5, 2, _reveal(0.7 + i * 0.2, 0.5)
			)
	# Door swings away; the search cone sketches the room into view.
	C.line(self, Vector2(284, 520), Vector2(410, 418), UMBER, 8, 550, 1.6, 2, _reveal(1.1, 0.55))
	C.line(self, Vector2(410, 418), Vector2(410, 545), UMBER, 5, 551, 1.1, 2, _reveal(1.2, 0.55))
	C.cone(self, Vector2(374, 548), -0.55, 650, 0.52, AMBER, 560, 0.62, 5.0)
	C.pool(self, Vector2(892, 511), 270, 148, _alpha(AMBER, 0.7), 561, 0.42)
	var contact := _ps(props.get("variant", "clear")) == "contact"
	if contact:
		_person(Vector2(934, 592), 1.45, UMBER, 570)
		C.scribble_ring(self, Vector2(934, 515), 48, 58, RED, 571, _reveal(3.3, 0.45), 3.0)
	else:
		C.line(self, Vector2(780, 601), Vector2(1010, 601), SAP, 5.0, 572, 1.2)
	# Recognition bar fills then holds; contact and clear resolve to different word marks.
	var bar := Rect2(420, 750, 760, 28)
	_box(bar, 580, _reveal(1.0, 0.35))
	var fill := (
		bar.size.x * clampf((t - 1.4) / maxf(0.3, float(props.get("seconds", 1.4))), 0.0, 1.0)
	)
	C.hatch_rect(
		self,
		Rect2(bar.position, Vector2(fill, bar.size.y)),
		_alpha(RED if contact else SAP, 0.95),
		4.0,
		-0.4,
		581,
		2.0
	)
	_txt(
		_slot("room", _ps(props.get("room", "ROOM UNKNOWN"))),
		Vector2(414, 840),
		26,
		DARK,
		582,
		760,
		_reveal(1.5, 0.5)
	)
	_stamp("CONTACT" if contact else "CLEAR", Vector2(1220, 850), 583, RED if contact else SAP)


func _officer_down() -> void:
	var killed := _ps(props.get("variant", "down")) == "killed"
	_heading("INCIDENT RECORD · WEEK %s" % _ps(props.get("week", 1)), "OFFICER DOWN", 600)
	C.hatch_rect(
		self, Rect2(78, 224, 1440, 572), _alpha(NIGHT, _reveal(0.2, 0.6)), 5.0, -0.5, 601, 2.4
	)
	# Radio rings and one small figure on the wet plan.
	for i in 4:
		var a := clampf((t - 0.7 - i * 0.37) / 0.45, 0.0, 1.0)
		C.outline(
			self,
			C.ellipse_poly(Vector2(800, 489), 65 + i * 58, 38 + i * 39, 22, 610 + i),
			_alpha(BLUE, 0.7),
			2.4,
			620 + i,
			0.8,
			a
		)
	_person(Vector2(800, 548), 1.75, NAVY, 630)
	# Case note and badge are deliberately kept as paper-coloured spaces.
	_panel(Rect2(176, 624, 790, 126), 640, STOCK, _reveal(2.0, 0.55))
	_txt(
		_slot("name", _ps(props.get("name", "OFFICER"))),
		Vector2(212, 694),
		34,
		DARK,
		641,
		690,
		_reveal(2.35, 0.5)
	)
	_txt(
		(
			"BADGE "
			+ _slot("badge", _ps(props.get("badge", "0000")))
			+ " · WEEK "
			+ _ps(props.get("week", 1))
		),
		Vector2(214, 730),
		18,
		MID,
		642,
		680,
		_reveal(2.7, 0.4)
	)
	if killed:
		# End-of-watch: folded flag, badge, one red rule; no graphic injury.
		for i in 7:
			var x := 1065.0 + i * 46.0
			C.line(
				self, Vector2(x, 320), Vector2(x + 42, 516), _alpha(STOCK, 0.58), 5.0, 650 + i, 1.2
			)
		C.evidence(self, Vector2(1288, 581), int(props.get("badge", 4417)) % 100, 670, 2.2)
		C.line(self, Vector2(166, 774), Vector2(1427, 774), RED, 4.0, 671, 1.1)
		_stamp("END OF WATCH", Vector2(1080, 852), 672, RED)
	else:
		_stamp("RADIO SILENCE", Vector2(1080, 852), 673, DARK)
		C.line(self, Vector2(1050, 650), Vector2(1460, 650), _alpha(BLUE, 0.75), 4.0, 674, 1.2)


func _debrief() -> void:
	_heading("OPERATION RECORD · PLAN / RESULT", "THE FOG LIFTS", 700)
	var plan := Rect2(100, 234, 898, 528)
	_panel(plan, 701, _alpha(PAPER, 0.48), _reveal(0.3, 0.7))
	for r in [
		Rect2(154, 286, 344, 190),
		Rect2(532, 286, 410, 190),
		Rect2(154, 500, 344, 208),
		Rect2(532, 500, 410, 208)
	]:
		_box(r, 710 + int(r.position.x), _reveal(0.8, 0.5), MID)
	var planned := [
		Vector2(183, 641),
		Vector2(302, 606),
		Vector2(447, 442),
		Vector2(647, 422),
		Vector2(838, 330)
	]
	for i in planned.size() - 1:
		C.line(
			self,
			planned[i],
			planned[i + 1],
			RED,
			4.3,
			730 + i,
			1.2,
			2,
			_reveal(1.4 + i * 0.24, 0.4)
		)
	var actual := [
		Vector2(183, 641),
		Vector2(365, 656),
		Vector2(598, 578),
		Vector2(776, 520),
		Vector2(853, 429)
	]
	for i in actual.size() - 1:
		C.line(
			self, actual[i], actual[i + 1], BLUE, 3.1, 740 + i, 1.0, 1, _reveal(3.0 + i * 0.24, 0.4)
		)
	for i in 4:
		C.evidence(self, Vector2(280 + i * 135, 376 + (i % 2) * 275), i + 1, 750 + i, 1.7)
	_panel(Rect2(1054, 238, 438, 524), 760, STOCK, _reveal(1.0, 0.55))
	_txt(
		"ROUNDS     %s" % _ps(props.get("rounds", 0)),
		Vector2(1100, 352),
		22,
		DARK,
		761,
		340,
		_reveal(2.0, 0.4)
	)
	_txt(
		"FINDINGS   %s" % _ps(props.get("findings", 0)),
		Vector2(1100, 432),
		22,
		DARK,
		762,
		340,
		_reveal(2.5, 0.4)
	)
	_txt(
		"TIME       %s MIN" % _ps(props.get("minutes", 0)),
		Vector2(1100, 512),
		22,
		DARK,
		763,
		340,
		_reveal(3.0, 0.4)
	)
	_txt(
		"CIVILIANS  %s" % _ps(props.get("civilians", 0)),
		Vector2(1100, 592),
		22,
		DARK,
		764,
		340,
		_reveal(3.5, 0.4)
	)
	_txt(_slot("counts", "ROUNDS / FINDINGS / TIME"), Vector2(1090, 710), 15, MID, 765, 330)
	_stamp("RECORDED", Vector2(1170, 852), 770, DARK)


## S15 Week Closed (2026-11-04): the week's sheet, filled in line by line and stamped.
## Plays every time the player ends a week, so it reads at a glance: what the force
## answered and left, who was taken alive, who died, what it cost, the Ledger's headline.
func _week_recap() -> void:
	var week := int(props.get("week", 1))
	var total := maxi(1, int(props.get("of", 40)))
	_heading("PORT CARRICK · WEEK %d OF %d" % [week, total], "WEEK CLOSED", 1500)
	# the week, drawn large on its own card, then stamped
	_panel(Rect2(84, 222, 430, 470), 1510, STOCK, _reveal(0.25, 0.6))
	_txt("%02d" % week, Vector2(120, 520), 230, DARK, 1511, 360, _reveal(0.4, 0.6))
	_txt("%d WEEKS LEFT" % maxi(0, total - week), Vector2(120, 590), 24, MID, 1512, 360, _reveal(0.8, 0.5))
	# the stamp, drawn in over half a second (the shared _stamp() reveals against the clock
	# and never completes when called late in a short)
	var verdict := String(props.get("verdict", "CLOSED"))
	var sr := _reveal(3.7, 0.5)
	if sr > 0.0:
		var sw := C.letters_width(verdict, 34) + 40.0
		var sp := Vector2(299.0 - sw * 0.5, 662.0)
		C.outline(self, C.rect_poly(Rect2(sp.x - 20, sp.y - 44, sw, 60)), RED, 3.6, 1513, 1.2, sr)
		C.letters(self, verdict, sp, 34, RED, 1514, 2, 0.72, sr)
	# the sheet: one row per line, written in as the short runs
	var money := int(props.get("money", 0))
	var rows := [
		["ANSWERED", str(int(props.get("answered", 0))), false],
		["LEFT UNATTENDED", str(int(props.get("unattended", 0))), int(props.get("unattended", 0)) > 0],
		["TAKEN ALIVE", str(int(props.get("arrests", 0))), false],
		["CIVILIANS KILLED", str(int(props.get("civilians", 0))), int(props.get("civilians", 0)) > 0],
		["OFFICERS KILLED", str(int(props.get("officers", 0))), int(props.get("officers", 0)) > 0],
		["OFFICERS HURT", str(int(props.get("wounded", 0))), int(props.get("wounded", 0)) > 0],
		["THE ACCOUNT", ("+" if money >= 0 else "-") + _dollars(absi(money)), money < 0],
		["BALANCE", ("" if int(props.get("balance", 0)) >= 0 else "-") + _dollars(absi(int(props.get("balance", 0)))), int(props.get("balance", 0)) < 0],
	]
	_panel(Rect2(580, 222, 936, 520), 1520, STOCK, _reveal(0.35, 0.6))
	for i in rows.size():
		var y := 290.0 + i * 58.0
		var at := 0.8 + i * 0.32
		var row: Array = rows[i]
		_txt(String(row[0]), Vector2(624, y), 26, MID, 1530 + i, 0.0, _reveal(at, 0.35))
		var val := String(row[1])
		var vw := C.letters_width(val, 30)
		_txt(val, Vector2(1476 - vw, y), 30, RED if bool(row[2]) else DARK, 1540 + i, 0.0, _reveal(at + 0.15, 0.35))
		C.line(self, Vector2(620, y + 16), Vector2(1480, y + 16), _alpha(MID, 0.45), 1.2, 1550 + i, 0.8, 1, _reveal(at, 0.4))
	# the Ledger's line for the week
	var head := _slot("headline", String(props.get("headline", "")))
	if head != "":
		_panel(Rect2(84, 760, 1432, 70), 1560, STOCK, _reveal(3.4, 0.4))
		_txt("THE LEDGER: " + head, Vector2(110, 806), 24, DARK, 1561, 1380, _reveal(3.6, 0.6))
	_footer()


static func _dollars(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return "$" + s + out
