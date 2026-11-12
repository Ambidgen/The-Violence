extends "res://scripts/view/crayon_short_base.gd"
## Shorts 08-14: press, internal affairs, ally standing, election, end of watch, funds and training.


func draw_short() -> void:
	match key:
		"s08_press":
			_press()
		"s09_case":
			_case()
		"s10_ally":
			_ally()
		"s11_election":
			_election()
		"s12_end_of_watch":
			_end_watch()
		"s13_allocation":
			_allocation()
		"s14_course":
			_course()
		_:
			_unknown()


func _press() -> void:
	_heading("PORT CARRICK LEDGER · FRONT PAGE", "THE FRONT PAGE", 800)
	_panel(Rect2(92, 218, 1410, 580), 801, STOCK, _reveal(0.25, 0.7))
	_txt("THE PORT CARRICK LEDGER", Vector2(130, 286), 31, DARK, 802, 1280, _reveal(0.55, 0.55))
	C.line(self, Vector2(130, 309), Vector2(1460, 309), DARK, 2.8, 803)
	_txt("WEEK %s" % _ps(props.get("week", 1)), Vector2(130, 347), 17, MID, 804, 250)
	var headline := _slot("headline", _ps(props.get("headline", "A CITY WAITS FOR ANSWERS")))
	_txt(headline, Vector2(132, 448), 42, DARK, 805, 1260, _reveal(0.85, 0.7))
	C.line(self, Vector2(132, 476), Vector2(1458, 476), DARK, 2.0, 806)
	var deck := _slot(
		"deck", _ps(props.get("deck", "The paper puts the week's events into words."))
	)
	_txt(deck, Vector2(140, 540), 23, MID, 807, 830, _reveal(1.5, 0.8))
	# A crude press photograph: a van under a lamp, built from hatching instead of a bitmap.
	C.hatch_rect(
		self,
		Rect2(1040, 525, 382, 196),
		_alpha(NIGHT, 0.48),
		4.0,
		-0.6,
		810,
		2.0,
		_reveal(1.8, 0.5)
	)
	_draw_van(Vector2(1228, 645), 0.78, 811)
	C.hatch(
		self,
		C.ellipse_poly(Vector2(1225, 704), 168, 24, 18, 820),
		_alpha(AMBER, 0.56),
		3.5,
		0.0,
		821,
		2.0
	)
	var tone := _ps(props.get("tone", "neutral"))
	if tone == "bad":
		C.line(self, Vector2(136, 731), Vector2(1438, 731), RED, 7.0, 822, 1.8)
		_stamp("BAD WEEK", Vector2(1270, 844), 823, RED)
	else:
		_stamp(_ps(props.get("price", "50 CENTS")), Vector2(1270, 844), 824, DARK)


func _case() -> void:
	_heading("INTERNAL AFFAIRS · EXHIBIT", "THE CASE", 840)
	_panel(Rect2(114, 238, 928, 548), 841, STOCK, _reveal(0.28, 0.7))
	_txt(_ps(props.get("caseNo", "IA 00-000")), Vector2(158, 304), 20, MID, 842, 520)
	_txt(
		_slot("officer", _ps(props.get("officer", "OFFICER"))),
		Vector2(158, 366),
		25,
		DARK,
		843,
		680,
		_reveal(0.65, 0.55)
	)
	C.line(self, Vector2(158, 389), Vector2(998, 389), DARK, 2.0, 844)
	var summary := _slot("summary", _ps(props.get("summary", "THE FINDING IS RECORDED.")))
	_txt(summary, Vector2(162, 476), 25, DARK, 845, 780, _reveal(1.0, 0.85))
	# Redactions obscure what the file cannot publish.
	for i in 5:
		var x := 164.0 + i * 148
		C.hatch_rect(
			self,
			Rect2(x, 550 + (i % 2) * 46, 112, 18),
			_alpha(DARK, _reveal(2.0 + i * 0.2, 0.25)),
			3.2,
			0.0,
			850 + i,
			1.5
		)
	var exhibit := Rect2(1100, 276, 346, 432)
	_panel(exhibit, 860, _alpha(PAPER, 0.5), _reveal(0.8, 0.55))
	C.evidence(self, Vector2(1274, 442), 3, 861, 3.5)
	C.scribble_ring(self, Vector2(1274, 444), 94, 88, DARK, 862, _reveal(1.5, 0.6), 2.4)
	var verdict := _ps(props.get("finding", "CLEARED")).to_upper()
	_stamp(verdict, Vector2(1124, 832), 863, RED if verdict == "SUSTAINED" else DARK)


func _ally() -> void:
	_heading("A SUPPORTING VOICE · POLITICAL CAPITAL", "THE STANDING", 880)
	_panel(Rect2(116, 232, 1364, 514), 881, STOCK, _reveal(0.25, 0.65))
	var from_value := clampf(float(props.get("from", 60)), 0, 100)
	var to_value := clampf(float(props.get("to", 22)), 0, 100)
	var x0 := 180.0
	var bar_y := 500.0
	var bar_w := 1190.0
	_box(Rect2(x0, bar_y, bar_w, 58), 882, _reveal(0.8, 0.45))
	C.hatch_rect(
		self,
		Rect2(x0, bar_y, bar_w * from_value / 100.0, 58),
		_alpha(NAVY, _reveal(1.2, 0.65)),
		3.6,
		-0.5,
		883,
		2.0
	)
	var threshold_x := x0 + bar_w * 0.25
	C.line(self, Vector2(threshold_x, 444), Vector2(threshold_x, 610), RED, 5, 884, 1.2)
	C.letters(self, "25", Vector2(threshold_x - 18, 428), 20, RED, 885, 2)
	var score := lerpf(from_value, to_value, clampf((t - 2.2) / 2.8, 0.0, 1.0))
	var cur_x := x0 + bar_w * score / 100.0
	C.scribble_ring(
		self,
		Vector2(cur_x, bar_y + 29),
		30,
		43,
		RED if to_value < 25 else AMBER,
		886,
		_reveal(2.0, 0.3),
		3.2
	)
	_txt(
		_slot("name", _ps(props.get("name", "ALLY"))),
		Vector2(170, 330),
		31,
		DARK,
		887,
		890,
		_reveal(0.8, 0.6)
	)
	_txt(
		_slot("title", _ps(props.get("title", "A COALITION PARTNER"))),
		Vector2(170, 384),
		19,
		MID,
		888,
		990,
		_reveal(1.2, 0.55)
	)
	_txt(
		_ps(props.get("holds", "THE DEPARTMENT'S GOODWILL")),
		Vector2(184, 660),
		21,
		MID,
		889,
		800,
		_reveal(2.5, 0.6)
	)
	_txt("%d  TO  %d" % [int(from_value), int(to_value)], Vector2(1150, 677), 22, DARK, 890, 260)
	if bool(props.get("lost", to_value < 25)):
		_stamp("CROSSED THE LINE", Vector2(1010, 833), 891, RED)
	else:
		_stamp("STAYS", Vector2(1180, 833), 892, DARK)


func _election() -> void:
	_heading("WEEK 40 · SIX WARDS REPORTING", "ELECTION NIGHT", 900)
	var shares: Array = props.get("shares", [38, 33, 29])
	var names: Array = props.get("names", ["CANDIDATE ONE", "CANDIDATE TWO", "CANDIDATE THREE"])
	var tickets: Array = props.get("tickets", ["SAFE STREETS", "TOGETHER", "INDEPENDENT"])
	var winner := clampi(int(props.get("winner", 0)), 0, maxi(0, shares.size() - 1))
	for i in mini(3, shares.size()):
		var y := 248.0 + i * 166.0
		var r := Rect2(122, y, 1344, 130)
		_panel(r, 910 + i, STOCK, _reveal(0.3 + i * 0.45, 0.55))
		_txt(
			String(names[i]),
			Vector2(160, y + 52),
			25,
			DARK,
			920 + i,
			590,
			_reveal(0.6 + i * 0.45, 0.5)
		)
		_txt(String(tickets[i]), Vector2(160, y + 91), 16, MID, 930 + i, 540)
		var bw := 500.0 * clampf(float(shares[i]) / 100.0, 0, 1)
		C.hatch_rect(
			self,
			Rect2(770, y + 47, bw, 34),
			_alpha(NAVY if i == winner else NIGHT, _reveal(1.3 + i * 0.4, 0.65)),
			4.0,
			-0.4,
			940 + i,
			2.0
		)
		_txt(
			"%d%%" % int(shares[i]),
			Vector2(1290, y + 88),
			26,
			DARK,
			950 + i,
			120,
			_reveal(1.7 + i * 0.4, 0.5)
		)
		if i == winner:
			C.scribble_ring(self, Vector2(1440, y + 63), 34, 42, RED, 960, _reveal(3.7, 0.4), 3.0)
	for i in 6:
		var x := 260.0 + i * 184.0
		C.hatch(
			self,
			C.ellipse_poly(Vector2(x, 790), 19, 19, 14, 970 + i),
			_alpha(AMBER, 0.75),
			3.0,
			0.2,
			980 + i,
			2.1,
			_reveal(4.0 + i * 0.2, 0.3)
		)
		C.outline(self, C.ellipse_poly(Vector2(x, 790), 19, 19, 14, 970 + i), DARK, 1.5, 981 + i)
	_stamp("PROJECTED", Vector2(1240, 856), 990, DARK)


func _end_watch() -> void:
	_heading("A BADGE · A NAME · A BELL", "END OF WATCH", 1000)
	_panel(Rect2(112, 228, 1374, 578), 1001, _alpha(STOCK, 0.78), _reveal(0.25, 0.7))
	# Drawn badge and folded flag, quiet rather than photographic.
	var badge := C.ellipse_poly(Vector2(492, 492), 174, 208, 24, 1002, 0.09)
	C.hatch(self, badge, _alpha(AMBER, _reveal(0.65, 0.65)), 4.2, -0.55, 1003, 2.2)
	C.outline(self, badge, DARK, 4.0, 1004, 1.2)
	C.scribble_ring(self, Vector2(492, 466), 97, 105, DARK, 1005, _reveal(1.5, 0.6), 2.6)
	C.evidence(self, Vector2(492, 466), int(props.get("badge", 0)) % 100, 1006, 2.6)
	for i in 7:
		var x := 850.0 + i * 51.0
		C.line(self, Vector2(x, 330), Vector2(x - 54, 626), _alpha(NAVY, 0.62), 6, 1010 + i, 1.7)
	C.line(self, Vector2(830, 660), Vector2(1348, 660), RED, 4, 1020)
	_txt(
		_slot("name", _ps(props.get("name", "OFFICER"))),
		Vector2(778, 468),
		36,
		DARK,
		1021,
		600,
		_reveal(1.2, 0.6)
	)
	_txt("BADGE " + _ps(props.get("badge", "0000")), Vector2(790, 525), 21, MID, 1022, 570)
	_txt(
		_slot(
			"dates",
			"WEEK %s · %s YEARS" % [_ps(props.get("week", 1)), _ps(props.get("years", 0))]
		),
		Vector2(790, 582),
		19,
		MID,
		1023,
		610
	)
	_stamp("NEVER FORGOTTEN", Vector2(1000, 842), 1024, DARK)
	# Bell is a hand-drawn outline, rung once by the timeline.
	var bell := C.ellipse_poly(Vector2(1344, 306), 29, 29, 16, 1025)
	C.outline(self, bell, DARK, 2.7, 1026)
	for i in 3:
		C.line(
			self,
			Vector2(1344 + i * 24, 260),
			Vector2(1344 + i * 35, 236),
			_alpha(AMBER, 0.8),
			2,
			1030 + i,
			0.8,
			1,
			_reveal(5.6 + i * 0.1, 0.25)
		)


func _allocation() -> void:
	_heading("CITY COUNCIL · WEEK %s" % _ps(props.get("week", 1)), "THE ALLOCATION", 1040)
	_panel(Rect2(104, 230, 1392, 564), 1041, STOCK, _reveal(0.25, 0.65))
	_txt("DEPARTMENT LEDGER", Vector2(154, 300), 20, MID, 1042, 480)
	C.line(self, Vector2(154, 318), Vector2(1450, 318), DARK, 2.5, 1043)
	var amount := int(props.get("amount", 0))
	_txt(
		_slot("amount", "$%s" % str(amount)),
		Vector2(174, 485),
		104,
		DARK,
		1044,
		870,
		_reveal(0.75, 0.75)
	)
	var delta := int(props.get("delta", 0))
	_txt(
		"%s%d%%" % ["+" if delta >= 0 else "", delta],
		Vector2(1120, 480),
		44,
		RED if delta < 0 else SAP,
		1045,
		280,
		_reveal(1.5, 0.5)
	)
	for i in 12:
		var coin_x := 190.0 + (i % 6) * 91.0
		var coin_y := 592.0 + int(i / 6) * 53.0
		var rr := C.ellipse_poly(Vector2(coin_x, coin_y), 24, 24, 14, 1050 + i)
		C.hatch(self, rr, _alpha(AMBER, _reveal(2.0 + i * 0.11, 0.25)), 3.0, 0.4, 1070 + i, 1.5)
		C.outline(self, rr, DARK, 1.5, 1090 + i)
		C.letters(self, "$", Vector2(coin_x - 5, coin_y + 6), 14, DARK, 1100 + i, 1)
	var verdict := _slot("verdict", _ps(props.get("verdict", "APPROVED")))
	_stamp(verdict, Vector2(1110, 697), 1120, RED if verdict == "CUT" else DARK)
	C.line(self, Vector2(152, 738), Vector2(1450, 738), RED if delta < 0 else DARK, 4.0, 1121, 1.2)


func _course() -> void:
	_heading("TRAINING BUREAU · COMPLETION", "THE COURSE", 1140)
	_panel(Rect2(184, 230, 1232, 550), 1141, STOCK, _reveal(0.25, 0.65))
	# Certificate border is doubled and deliberately not square.
	_box(Rect2(222, 270, 1154, 456), 1142, _reveal(0.55, 0.6), UMBER)
	_box(Rect2(242, 290, 1114, 416), 1143, _reveal(0.75, 0.6), UMBER)
	_txt("CERTIFICATE OF COMPLETION", Vector2(440, 386), 23, MID, 1144, 730, _reveal(0.9, 0.55))
	_txt(
		_slot("course", _ps(props.get("course", "CLOSE-QUARTERS DRILL"))),
		Vector2(320, 492),
		35,
		DARK,
		1145,
		960,
		_reveal(1.5, 0.7)
	)
	var grads := clampi(int(props.get("graduates", 4)), 1, 12)
	for i in mini(grads, 10):
		_person(Vector2(470 + i * 70, 625), 0.86, NAVY, 1150 + i, i % 2 == 0)
	_txt(
		_slot("roster", "%d GRADUATES · WEEK %s" % [grads, _ps(props.get("week", 1))]),
		Vector2(528, 700),
		19,
		MID,
		1165,
		600,
		_reveal(3.4, 0.55)
	)
	_stamp("PASSED", Vector2(1190, 836), 1170, DARK)
	for i in 3:
		var x := 1330.0 + i * 24.0
		C.line(
			self,
			Vector2(x, 260),
			Vector2(x + 62, 198),
			_alpha(AMBER, 0.86),
			3,
			1180 + i,
			1.1,
			2,
			_reveal(4.0 + i * 0.2, 0.35)
		)
