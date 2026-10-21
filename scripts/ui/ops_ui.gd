extends CanvasLayer
## The operations screens (v0.7, Loop B): the week's board, then for one situation the
## briefing, the force (up to five squads of up to six) and the orders, then Run (fog of war,
## pause, slow motion, rewind as viewing tools, and Abort), then the debrief with a full
## replay. Built in code, in the drafting-table style of the setup panel.

const UI = preload("res://scripts/ui/ui.gd")
const Ink = preload("res://scripts/view/ink.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Courses = preload("res://scripts/data/courses.gd")
const Department = preload("res://scripts/campaign/department.gd")
const PANEL_W := 460.0
const INK := Color("#121212")
const GREY := Color("#737370")
const OBJ_KINDS := ["clear", "arrest", "rescue", "contain", "post", "patrol"]

var main
var root: PanelContainer
var box: VBoxContainer
var mode := ""
var tab := 0                 # plan screen: 0 briefing, 1 force, 2 orders
var sel_sq := 0
var pick := {}               # map tool: {kind, squad, obj}
var abort_armed := false
var _run_refs := {}          # widgets updated every refresh during the run
var _log_shown := 0
var _rewinding := false
var _sliding := false        # the panel itself is moving a slider: not the player
var kit_open := ""           # Force screen: the officer whose kit is being edited (v0.7.5)
var roster_open := ""        # Roster: the officer whose file is open (v0.8.5)
var flash := ""              # a one-line answer to the last thing tried (v0.8.5)


func build(m) -> void:
	main = m
	root = PanelContainer.new()
	root.theme = UI.make_theme()
	root.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	root.offset_left = -PANEL_W
	root.visible = false
	add_child(root)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	sc.add_child(box)


func hide_all() -> void:
	root.visible = false
	mode = ""


func _clear() -> void:
	for c in box.get_children():
		c.queue_free()
	_run_refs.clear()


# ------------------------------------------------------------------ widgets
func _title(text: String, size := 18) -> Label:
	var l := Label.new()
	l.text = Ink.bb(text)
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func _text(parent: Control, text: String, col := INK, size := 12) -> Label:
	var l := Label.new()
	l.text = Ink.bb(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


## A short fixed label for a row of controls (no wrapping).
func _lab(parent: Control, text: String, col := INK, size := 12) -> Label:
	var l := Label.new()
	l.text = Ink.bb(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _rich(parent: Control, bb: String, min_h := 0.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = min_h <= 0.0
	r.scroll_active = min_h > 0.0
	if min_h > 0.0:
		r.custom_minimum_size = Vector2(0, min_h)
	r.add_theme_font_size_override("normal_font_size", 11)
	r.add_theme_font_size_override("bold_font_size", 11)
	r.text = Ink.bb(bb)
	parent.add_child(r)
	return r


func _h(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	parent.add_child(h)
	return h


func _btn(parent: Control, text: String, cb: Callable, toggle := false) -> Button:
	var b := Button.new()
	b.text = Ink.bb(text)
	b.toggle_mode = toggle
	if toggle:
		b.toggled.connect(func(on): cb.call(on))
	else:
		b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _card(parent: Control) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color("#edede8"), Color("#bfbfba"), 1, 8.0))
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	return v


func _sep() -> void:
	box.add_child(HSeparator.new())


static func dots(n: int) -> String:
	var s := ""
	for k in 5:
		s += "●" if k < n else "○"
	return s


# ================================================================== the board
func show_board(lines := []) -> void:
	mode = "board"
	root.visible = true
	_clear()
	var c = main.campaign
	var d = c.dept
	_title("OPERATIONS  ·  week %d of %d" % [c.week(), c.WEEKS])
	var fit: int = d.available().size()
	var out: int = d.officers.filter(func(r): return r["status"] == "injured").size()
	var busy: int = c.committed().size()
	_text(box, "Port Carrick PD: %d officers fit, %d out injured. %d committed this week. Officers sent to one situation, or out canvassing, cannot go to another." % [fit, out, busy], GREY, 11)
	_dept_strip(box)
	for ln in lines:
		_text(box, String(ln), INK, 11)
	for s in c.board:
		var v := _card(box)
		var t := Label.new()
		t.text = s["title"]
		t.add_theme_font_size_override("font_size", 14)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		_text(v, "%s  ·  %s ward (trust %d)  ·  visibility %s  ·  pressure: %s" % [Situations.TYPES[s["type"]]["name"], s["ward"],
			int(s["trust"]), dots(int(s["visibility"])), String(s["pressure"])], GREY, 11)
		var st := ""
		match s["status"]:
			"open":
				var n: int = c.plan_members(s).size()
				st = "Open: %s" % (("planned, %d officer%s" % [n, "" if n == 1 else "s"]) if n > 0 else "nobody assigned yet")
				if not s.get("canvass", []).is_empty():
					st += ", %d canvassing" % s["canvass"].size()
			"done":
				var r: Dictionary = s.get("result", {})
				var g0: String = r.get("goal", "")
				st = "Done: %s, %d. %s." % [r.get("label", "?"), int(r.get("score", 0)), g0.substr(0, 1).to_upper() + g0.substr(1)]
			_:
				st = "Unattended"
		_text(v, st, INK, 12)
		if s["status"] == "open":
			var h := _h(v)
			var sid: String = s["id"]
			_btn(h, "Brief and plan  >", func(): main.ops_select(sid))
	_sep()
	var hb := _h(box)
	_btn(hb, "End week %d" % c.week(), func(): _end_week())
	_btn(hb, "Roster", func(): _roster())
	_btn(hb, "Budget", func(): _budget())
	var nc: int = d.open_cases().size()
	_btn(hb, "Internal affairs%s" % ((" (%d)" % nc) if nc > 0 else ""), func(): _cases())
	_btn(hb, "Test range", func(): main.ops_close())
	var hb2 := _h(box)
	_btn(hb2, "New campaign", func(): main.ops_new_campaign())
	_text(box, "One save slot: the campaign is saved after every operation and every week.", GREY, 10)


func _end_week() -> void:
	var lines: Array = main.ops_end_week()
	show_board(lines)


## The money, morale and open cases at a glance (v0.8.5).
func _dept_strip(parent: Control) -> void:
	var d = main.campaign.dept
	var v := _card(parent)
	var red: bool = d.balance < 0
	_text(v, "ACCOUNT  $%s%s   ·   allocation $%s a week   ·   payroll $%s" % [Department.money(d.balance),
		"  (FROZEN)" if red else "", Department.money(d.allocation), Department.money(d.payroll())],
		Ink.accent(0.9) if red else INK, 12)
	var nc: int = d.open_cases().size()
	_text(v, "Morale %d%s   ·   %d internal affairs case%s open" % [d.morale,
		" (low: more stress in every operation)" if d.morale < Courses.MORALE0 else "",
		nc, "" if nc == 1 else "s"], GREY, 11)


const STATUS_WORDS := {"injured": "out injured until week %d", "training": "on a course until week %d",
	"academy": "at the academy until week %d", "suspended": "suspended until week %d"}


func _status_of(r: Dictionary, busy: Dictionary) -> String:
	if STATUS_WORDS.has(r["status"]):
		return STATUS_WORDS[r["status"]] % int(r["out_until"])
	match r["status"]:
		"dead":
			return "killed"
		"fired":
			return "dismissed"
		"resigned":
			return "resigned"
	if busy.has(r["id"]):
		return "committed (%s)" % busy[r["id"]]
	return "fit"


func _roster() -> void:
	mode = "roster"
	_clear()
	var d = main.campaign.dept
	_title("ROSTER  ·  week %d" % d.week)
	_dept_strip(box)
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	var hh := _h(box)
	_btn(hh, "Hire a recruit ($%s)" % Department.money(Courses.RECRUIT + Equipment.cost(Equipment.default_kit())), func(): _hire(false))
	_btn(hh, "Hire laterally ($%s)" % Department.money(Courses.LATERAL + Equipment.cost(Equipment.default_kit())), func(): _hire(true))
	_text(box, "A recruit spends two weeks at the academy; a lateral hire has three to six years elsewhere and reports at once. Click an officer to open their file: training, and dismissal.", GREY, 10)
	var order: Array = d.officers.filter(func(r): return r["status"] not in ["dead", "fired", "resigned"])
	order.sort_custom(func(a, b):
		var ra: int = Orders.rank_i(a)
		var rb: int = Orders.rank_i(b)
		if ra != rb:
			return ra > rb
		return int(a["xp"]) > int(b["xp"]))
	var busy: Dictionary = main.campaign.committed()
	for r in order:
		var st: String = _status_of(r, busy)
		var oid: String = r["id"]
		var b := _btn(box, "%s %s  ·  %d yr  ·  %s %d xp  ·  J %d  ·  $%s/wk  ·  %s" % [r["rank"], r["name"], int(r.get("years", 0)),
			Habits.EXP_NAMES[int(r["exp"])], int(r["xp"]), int(r["judgment"]), Department.money(Courses.pay(r)), st],
			func(): roster_open = "" if roster_open == oid else oid; _roster())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(10, 0)
		b.add_theme_font_size_override("font_size", 11)
		b.tooltip_text = UI.officer_file(r)
		if r["status"] != "active":
			b.add_theme_color_override("font_color", GREY)
		if roster_open == oid:
			_officer_card(r, busy)
	var gone: Array = d.officers.filter(func(r): return r["status"] in ["dead", "fired", "resigned"])
	if not gone.is_empty():
		_text(box, "No longer serving: " + ", ".join(gone.map(func(r): return "%s %s (%s)" % [r["rank"], r["name"], _status_of(r, {})])), GREY, 10)
	_btn(box, "<  Back to the board", func(): show_board())


func _officer_card(r: Dictionary, busy: Dictionary) -> void:
	var d = main.campaign.dept
	var v := _card(box)
	var good: Array = r["good"]
	_text(v, "%d good habits%s. Personality: %s. Trauma %.1f. Courses: %s." % [good.size(),
		", tactical certified" if r.get("tactical", false) else "", String(r["personality"]) if r["personality"] != "" else "none",
		float(r["trauma"]), ", ".join(r.get("courses", []).map(func(c): return Courses.COURSES[c]["name"])) if not r.get("courses", []).is_empty() else "none"], INK, 11)
	if r["status"] == "active" and not busy.has(r["id"]):
		_text(v, "TRAINING (the officer is off the board for the course)", GREY, 10)
		for cid in Courses.COURSE_ORDER:
			if cid == "uof":
				continue
			var c: Dictionary = Courses.COURSES[cid]
			var why: String = Courses.blocked(r, cid)
			if why == "" and d.frozen():
				why = "account in the red"
			var h := _h(v)
			var cb := _btn(h, "%s  $%s  %dw" % [c["name"], Department.money(int(c["cost"])), int(c["weeks"])], func(): _train(r, cid))
			cb.disabled = why != ""
			cb.add_theme_font_size_override("font_size", 11)
			cb.tooltip_text = String(c["desc"]) + (("\nNot now: " + why) if why != "" else "")
			if why != "":
				_lab(h, why, GREY, 10)
	elif r["status"] == "active":
		_text(v, "Committed this week: no courses until the week ends.", GREY, 10)
	var h2 := _h(v)
	var fb := _btn(h2, "Dismiss ($%s severance)" % Department.money(Courses.pay(r) * Courses.SEVERANCE_WEEKS), func(): _dismiss(r))
	fb.add_theme_font_size_override("font_size", 11)
	_lab(h2, "the union remembers: morale -6", GREY, 10)


func _train(r: Dictionary, cid: String) -> void:
	var why: String = main.campaign.dept.enrol(r, cid)
	flash = ("%s %s is on the %s course." % [r["rank"], r["name"], Courses.COURSES[cid]["name"].to_lower()]) if why == "" else ("Not possible: " + why + ".")
	main.ops_dept_changed()
	_roster()


func _hire(lateral: bool) -> void:
	var r: Dictionary = main.campaign.dept.recruit(lateral)
	flash = ("Hired %s %s." % [r["rank"], r["name"]]) if not r.is_empty() else "Hiring is frozen while the account is in the red."
	main.ops_dept_changed()
	_roster()


func _dismiss(r: Dictionary) -> void:
	main.campaign.dept.fire(r)
	roster_open = ""
	flash = "%s %s has been dismissed." % [r["rank"], r["name"]]
	main.ops_dept_changed()
	_roster()


## The account: this week and the last few, line by line (v0.8.5).
func _budget() -> void:
	mode = "budget"
	_clear()
	var d = main.campaign.dept
	_title("BUDGET  ·  week %d" % d.week)
	_dept_strip(box)
	_text(box, "The city's allocation comes in and the payroll goes out at the end of each week. Overtime, restocking, kit, hiring, training, medical bills and death benefits come out as they happen. In the red, hiring, training and new kit are frozen.", GREY, 10)
	var bb := ""
	var shown := 0
	for wk in range(d.week, maxi(0, d.week - 6), -1):
		var rows: Array = d.ledger.filter(func(le): return int(le["week"]) == wk)
		if rows.is_empty():
			continue
		var net := 0
		for le in rows:
			net += int(le["amount"])
		bb += "[b]WEEK %d[/b]   net %s$%s\n" % [wk, "+" if net >= 0 else "-", Department.money(absi(net))]
		for le in rows:
			var a: int = int(le["amount"])
			bb += ("   %s$%s   %s\n" % ["+" if a >= 0 else "-", Department.money(absi(a)), le["item"]]) if a >= 0 else ("   [color=#b31f26]-$%s[/color]   %s\n" % [Department.money(absi(a)), le["item"]])
		shown += 1
	if shown == 0:
		bb = "Nothing spent yet this campaign."
	_rich(box, bb)
	_btn(box, "<  Back to the board", func(): show_board())


## Internal affairs: every open case and its four answers (v0.8.5).
func _cases() -> void:
	mode = "cases"
	_clear()
	var d = main.campaign.dept
	_title("INTERNAL AFFAIRS  ·  week %d" % d.week)
	_dept_strip(box)
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	_text(box, "Every finding the incident record ties to an officer, and every broken order, opens a case. Clear it, send the officer to a use-of-force review, suspend them for two weeks without pay, or dismiss them. A case nobody decides lapses after three weeks. (What the public makes of your decisions arrives in v0.9.)", GREY, 10)
	var open: Array = d.open_cases()
	if open.is_empty():
		_text(box, "No open cases.", INK, 12)
	for c in open:
		var r: Dictionary = d.get_officer(c["officer"])
		var v := _card(box)
		_text(v, "%s  ·  %s %s  ·  week %d" % [c["id"], r.get("rank", ""), r.get("name", "?"), int(c["week"])], INK, 13)
		_text(v, "%s: %s (%s). Evidence: %s." % [Department.CASE_KINDS.get(c["kind"], c["kind"]), c["text"], c["place"], c["strength"]], INK, 11)
		_text(v, "Judgment %d  ·  integrity %d  ·  %d earlier case%s" % [int(r.get("judgment", 0)), int(r.get("integrity", 0)),
			d.cases.filter(func(x): return x["officer"] == c["officer"] and x["status"] == "closed").size(),
			"" if d.cases.filter(func(x): return x["officer"] == c["officer"] and x["status"] == "closed").size() == 1 else "s"], GREY, 10)
		var h := _h(v)
		var cid: String = c["id"]
		_btn(h, "Clear", func(): _decide(cid, "clear"))
		var rb := _btn(h, "Review ($%s)" % Department.money(int(Courses.COURSES["uof"]["cost"])), func(): _decide(cid, "retrain"))
		rb.disabled = r.get("status", "") != "active" or d.frozen() or main.campaign.committed().has(c["officer"])
		_btn(h, "Suspend", func(): _decide(cid, "suspend"))
		_btn(h, "Dismiss", func(): _decide(cid, "fire"))
	var closed: Array = d.cases.filter(func(c): return c["status"] == "closed")
	if not closed.is_empty():
		var bb := ""
		for k in range(closed.size() - 1, maxi(-1, closed.size() - 13), -1):
			var c2: Dictionary = closed[k]
			var r2: Dictionary = d.get_officer(c2["officer"])
			bb += "%s  %s  ·  %s  ·  %s\n" % [c2["id"], r2.get("name", "?"), Department.CASE_KINDS.get(c2["kind"], c2["kind"]).to_lower(), c2["decision"]]
		_text(box, "CLOSED", GREY, 10)
		_rich(box, bb)
	_btn(box, "<  Back to the board", func(): show_board())


func _decide(cid: String, decision: String) -> void:
	var d = main.campaign.dept
	for c in d.cases:
		if c["id"] == cid:
			var ln: String = d.decide(c, decision)
			flash = ln if ln != "" else "That could not be done this week."
	main.ops_dept_changed()
	_cases()


# ================================================================== briefing, force, orders
func show_plan() -> void:
	mode = "plan"
	root.visible = true
	_clear()
	var s: Dictionary = main.cur_sit
	_title(s["title"], 15)
	var tabs := _h(box)
	for i in 3:
		var b := _btn(tabs, ["1 Briefing", "2 Force", "3 Orders"][i], func(on): if on: _tab(i), true)
		b.set_pressed_no_signal(i == tab)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sep()
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	if tab == 1:
		var d = main.campaign.dept
		_text(box, "Account $%s%s. New kit is bought at cost; kit handed back sells for half." % [Department.money(d.balance),
			" (frozen: no new kit)" if d.frozen() else ""], Ink.accent(0.9) if d.frozen() else GREY, 10)
	match tab:
		0:
			_briefing(s)
		1:
			_force(s)
		2:
			_orders(s)
	_sep()
	var n: int = main.campaign.plan_members(s).size()
	var hb := _h(box)
	_btn(hb, "<  Board", func(): main.ops_board())
	_btn(hb, "Suggest a plan", func(): main.ops_suggest())
	var run := _btn(box, "RUN   >   %d officer%s" % [n, "" if n == 1 else "s"], func(): main.ops_run())
	run.custom_minimum_size = Vector2(0, 40)
	run.add_theme_font_size_override("font_size", 16)
	run.disabled = n == 0


func _tab(i: int) -> void:
	tab = i
	set_pick({})
	show_plan()


func _briefing(s: Dictionary) -> void:
	var spec: Dictionary = Situations.TYPES[s["type"]]
	_text(box, spec["blurb"], INK, 12)
	_text(box, "%s, %s ward. The ward's trust in police: %d of 100%s." % [s["address"], s["ward"], int(s["trust"]),
		" (its community group has broken with the department: no tips from it)" if int(s["trust"]) < 25 else ""], GREY, 11)
	_text(box, "Visibility %s: %s" % [dots(int(s["visibility"])), ["", "almost nobody is watching; mistakes can stay quiet for months",
		"a few neighbours", "a street's worth of phones", "reporters likely; anything that happens is seen", "live cameras and a crowd: it will all be seen, at once"][clampi(int(s["visibility"]), 1, 5)]], GREY, 11)
	_text(box, "Time pressure: %s" % Situations.PRESSURE_NAMES.get(s["pressure"], s["pressure"]), GREY, 11)
	var bb := "[b]WHAT IS KNOWN[/b]\n"
	for ln in Situations.briefing_lines(s):
		bb += ("[b]%s:[/b] %s  [i](confirmed)[/i]\n" if ln["known"] else "%s: %s\n") % [ln["label"], String(ln["text"]).replace("[", "(")]
	if not s["tips"].is_empty():
		bb += "\n[b]TIPS[/b]\n"
		for tp in s["tips"]:
			bb += "· %s\n" % String(tp).replace("[", "(")
	else:
		bb += "\nNo tips have come in."
	_rich(box, bb)
	# canvass
	var av: Array = main.campaign.available_for(s["id"]).filter(func(r): return not main.campaign.plan_members(s).has(r["id"]))
	if not av.is_empty():
		var h := _h(box)
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for r in Autoplan.ranked(av):
			opt.add_item("%s %s (%s)" % [String(r["rank"]).substr(0, 3) + ".", r["name"], Habits.EXP_NAMES[int(r["exp"])]])
			opt.set_item_metadata(opt.item_count - 1, r["id"])
		h.add_child(opt)
		_btn(h, "Canvass", func():
			if opt.selected >= 0:
				main.ops_canvass(String(opt.get_item_metadata(opt.selected))))
		_text(box, "Canvassing brings two more tips; the officer is gone for the week.", GREY, 10)
	if s["type"] in ["warrant", "gang"]:
		var h2 := _h(box)
		_lab(h2, "Hour")
		var hour := OptionButton.new()
		hour.add_item("Day")
		hour.add_item("Night")
		hour.tooltip_text = "Night: darker, so recognition and judgment are slower and civilians are misjudged more often; everyone is at home."
		hour.select(1 if main.plan.get("night", false) else 0)
		hour.item_selected.connect(func(i): main.ops_set_night(i == 1))
		h2.add_child(hour)
	var cams: bool = main.campaign.dept.bodycams
	var cb := _btn(box, "Body cameras: %s" % ("worn" if cams else "not issued"), func(on): main.ops_set_bodycams(on), true)
	cb.set_pressed_no_signal(cams)
	cb.tooltip_text = "Body cameras record what each officer sees as evidence for the incident record. You always see what your officers see."


func _force(s: Dictionary) -> void:
	var plan: Dictionary = main.plan
	var squads: Array = plan.get("squads", [])
	_text(box, "Up to five squads of up to six (30 officers). Suggest a plan forms them: as many threes as it can, then evens them out. The highest rank leads; the leader's experience sets the squad's order points.", GREY, 11)
	var stages: Array = Operation.stages(main.level)
	for si in squads.size():
		var sq: Dictionary = squads[si]
		var recs := _recs(sq["members"])
		var ld = Orders.leader(recs)
		var v := _card(box)
		var h := _h(v)
		var t := Label.new()
		t.text = "SQUAD %d  ·  %d  ·  %s" % [si + 1, recs.size(), ("led by %s %s (%s): %d point%s" % [ld["rank"], ld["name"],
			Habits.EXP_NAMES[int(ld["exp"])], Orders.points_for(recs), "" if Orders.points_for(recs) == 1 else "s"]) if ld != null else "empty"]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		if not stages.is_empty():
			var h2 := _h(v)
			_lab(h2, "Forms up at", GREY, 11)
			var so := OptionButton.new()
			for st in stages:
				so.add_item("stage " + String(st["name"]))
			so.select(clampi(int(sq.get("stage", 0)), 0, stages.size() - 1))
			var k := si
			so.item_selected.connect(func(i): main.plan["squads"][k]["stage"] = i; main.plan_changed())
			h2.add_child(so)
			_btn(h2, "Remove squad", func(): _remove_squad(k))
		# kit (v0.7.5): a ready-made squad kit, then each officer's own
		if not recs.is_empty():
			var hk := _h(v)
			_lab(hk, "Squad kit", GREY, 11)
			var kk := si
			for key in Equipment.SQUAD_KITS:
				var kname: String = Equipment.SQUAD_KITS[key]["name"]
				var kb := _btn(hk, kname, func(): _squad_kit(kk, key))
				kb.tooltip_text = "%s kit. Point man: %s.\nThe rest: %s." % [kname, Equipment.describe(Equipment.SQUAD_KITS[key]["point"]),
					Equipment.describe(Equipment.SQUAD_KITS[key]["rest"])]
			for r0 in recs:
				var hr := _h(v)
				var oid0: String = r0["id"]
				var kl := _text(hr, "%s  ·  %s" % [r0["name"], Equipment.describe(r0.get("kit", Equipment.default_kit()))], INK, 11)
				kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_btn(hr, "Kit" if kit_open != oid0 else "Done", func(): kit_open = "" if kit_open == oid0 else oid0; show_plan())
				if kit_open == oid0:
					_kit_editor(v, r0)
	if squads.size() < Orders.MAX_SQUADS:
		_btn(box, "+ Add a squad", func(): _add_squad())
	_sep()
	var av: Array = Autoplan.ranked(main.campaign.available_for(s["id"]))
	_text(box, "OFFICERS AVAILABLE THIS WEEK (%d)" % av.size(), INK, 12)
	for r in av:
		var h3 := _h(box)
		var opt := OptionButton.new()
		opt.add_item("—")
		for si2 in squads.size():
			opt.add_item("Squad %d" % (si2 + 1))
		var cur := 0
		for si3 in squads.size():
			if squads[si3]["members"].has(r["id"]):
				cur = si3 + 1
		opt.select(cur)
		opt.custom_minimum_size = Vector2(92, 0)
		var oid: String = r["id"]
		opt.item_selected.connect(func(i): _assign(oid, i - 1))
		h3.add_child(opt)
		var l := _text(h3, "%s %s  ·  %d yr  ·  %s  ·  J %d%s" % [String(r["rank"]).substr(0, 3) + ".", r["name"], int(r.get("years", 0)),
			Habits.EXP_NAMES[int(r["exp"])], int(r["judgment"]), ("  ·  " + String(r["personality"]).to_lower()) if r["personality"] != "" else ""], INK, 11)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.tooltip_text = UI.officer_file(r)


## One officer's kit: weapons, sight, armour and gear, within their training.
func _kit_editor(parent: Control, r: Dictionary) -> void:
	var who: String = Equipment.who_of_record(r)
	var kit: Dictionary = Equipment.validate(r.get("kit", Equipment.default_kit()), who)
	var v := VBoxContainer.new()
	parent.add_child(v)
	var rows := [["Primary", "primary", [""] + Equipment.PRIMARY_ORDER], ["Sidearm", "secondary", [""] + Equipment.SECONDARY_ORDER],
		["Sight", "optic", ["red_dot", "irons", "magnified"]], ["Armour", "armour", ["none", "vest", "plates"]]]
	for row in rows:
		var h := _h(v)
		_lab(h, row[0], GREY, 11)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var field: String = row[1]
		for item in row[2]:
			var nm: String = "(none)"
			var ok := true
			match field:
				"primary", "secondary":
					if item != "":
						nm = Equipment.WEAPONS[item]["name"]
						ok = Equipment.allowed(Equipment.WEAPONS[item]["who"], who)
				"optic":
					nm = Equipment.OPTICS[item]["name"]
				"armour":
					nm = Equipment.ARMOUR[item]["name"] + (" (2 plates)" if item == "plates" else "")
			ob.add_item(nm + ("" if ok else "  (tactical training)"))
			ob.set_item_metadata(ob.item_count - 1, item)
			ob.set_item_disabled(ob.item_count - 1, not ok)
			if item == String(kit[field]):
				ob.select(ob.item_count - 1)
		ob.item_selected.connect(func(i): _set_kit(r, field, ob.get_item_metadata(i)))
		h.add_child(ob)
	var grid := GridContainer.new()
	grid.columns = 4
	v.add_child(grid)
	for gid in Equipment.GEAR_ORDER:
		var spec: Dictionary = Equipment.GEAR[gid]
		var ok2: bool = Equipment.allowed(spec["who"], who) and (not spec.has("needs") or kit["primary"] == spec["needs"])
		var gl := _lab(grid, spec["name"], INK if ok2 else GREY, 11)
		gl.tooltip_text = "%s (%s)\n%s" % [spec["name"], Equipment.WHO_NAMES[spec["who"]], spec["desc"]]
		gl.mouse_filter = Control.MOUSE_FILTER_STOP
		var sp := SpinBox.new()
		sp.min_value = 0
		sp.max_value = int(spec["max"])
		sp.value = int(kit["gear"].get(gid, 0))
		sp.editable = ok2
		var g2: String = gid
		sp.value_changed.connect(func(val): _set_gear(r, g2, int(val)))
		grid.add_child(sp)
	_text(v, "%.1f kg (pace x%.2f), cost %d.%s" % [Equipment.weight(kit), Equipment.speed_factor(kit), Equipment.cost(kit),
		"" if who == "tactical" else " Flashbangs, sting-balls, gas, the pepperball and 40 mm launchers, breaching rounds, the short rifle, the battle and marksman rifles and the shield need five years on the job or Experience 3."], GREY, 10)


func _set_kit(r: Dictionary, field: String, value) -> void:
	var k: Dictionary = Equipment.normalize(r.get("kit", Equipment.default_kit()))
	k[field] = value
	if field == "armour":
		k["plates"] = 2 if value == "plates" else 0
	_issue(r, Equipment.validate(k, Equipment.who_of_record(r)))
	main.plan_changed()
	main._save()
	show_plan()


func _set_gear(r: Dictionary, gid: String, n: int) -> void:
	var k: Dictionary = Equipment.normalize(r.get("kit", Equipment.default_kit()))
	k["gear"][gid] = n
	_issue(r, Equipment.validate(k, Equipment.who_of_record(r)))
	main.plan_changed()
	main._save()
	show_plan()


## A ready-made kit for a whole squad: the first officer listed takes the point man's.
func _squad_kit(si: int, key: String) -> void:
	var spec: Dictionary = Equipment.SQUAD_KITS[key]
	var recs := _recs(main.plan["squads"][si]["members"])
	for k in recs.size():
		var r: Dictionary = recs[k]
		_issue(r, Equipment.validate(spec["point"] if k == 0 else spec["rest"], Equipment.who_of_record(r)))
	main.plan_changed()
	main._save()
	show_plan()


## Kit goes through the budget (v0.8.5): new kit is bought, kit handed back sold for half.
func _issue(r: Dictionary, kit: Dictionary) -> void:
	var res = main.campaign.dept.reissue(r, kit)
	if res is String:
		flash = "No new kit: " + res + "."
	elif int(res) > 0:
		flash = "Kit for %s: $%s." % [r["name"], Department.money(int(res))]
	elif int(res) < 0:
		flash = "Kit returned by %s: $%s back." % [r["name"], Department.money(-int(res))]


func _recs(ids: Array) -> Array:
	var out: Array = []
	for oid in ids:
		var r: Dictionary = main.campaign.dept.get_officer(oid)
		if not r.is_empty():
			out.append(r)
	return out


func _add_squad() -> void:
	var stages: Array = Operation.stages(main.level)
	main.plan["squads"].append({"members": [], "stage": main.plan["squads"].size() % maxi(1, stages.size()), "orders": Orders.empty_orders()})
	main.plan_changed()
	show_plan()


func _remove_squad(k: int) -> void:
	main.plan["squads"].remove_at(k)
	sel_sq = 0
	main.plan_changed()
	show_plan()


func _assign(oid: String, si: int) -> void:
	var squads: Array = main.plan["squads"]
	for sq in squads:
		sq["members"].erase(oid)
	if si >= 0 and si < squads.size():
		if squads[si]["members"].size() >= Orders.MAX_SQUAD:
			show_plan()
			return
		squads[si]["members"].append(oid)
	main.plan_changed()
	show_plan()


func _orders(s: Dictionary) -> void:
	var squads: Array = main.plan.get("squads", [])
	if squads.is_empty():
		_text(box, "No squads yet: form them on the Force tab.", GREY, 12)
		return
	sel_sq = clampi(sel_sq, 0, squads.size() - 1)
	var hs := _h(box)
	for si in squads.size():
		var k := si
		var b := _btn(hs, "Squad %d" % (si + 1), func(on): if on: sel_sq = k; set_pick({}); show_plan(), true)
		b.set_pressed_no_signal(si == sel_sq)
	main.plan_marks.sel = sel_sq
	main.plan_marks.queue_redraw()
	var sq: Dictionary = squads[sel_sq]
	var od: Dictionary = sq["orders"]
	var recs := _recs(sq["members"])
	var pts := Orders.points_for(recs)
	var used := Orders.cost(od)
	_text(box, "Order points: %d of %d used%s" % [used, pts, ("  ·  leader " + Orders.leader(recs)["name"]) if not recs.is_empty() else ""],
		INK if used <= pts else Ink.accent(0.9), 13)
	# objectives
	for oi in 2:
		var v := _card(box)
		var objs: Array = od["objs"]
		var h := _h(v)
		_lab(h, "Objective %d%s" % [oi + 1, "  (free)" if oi == 0 else "  (1 point)"])
		var opt := OptionButton.new()
		if oi == 1:
			opt.add_item("none")
		for kk in OBJ_KINDS:
			opt.add_item(Orders.OBJECTIVES[kk]["name"])
		var cur: String = objs[oi]["kind"] if oi < objs.size() else ""
		opt.select((OBJ_KINDS.find(cur) + (1 if oi == 1 else 0)) if cur != "" else 0)
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := oi
		opt.item_selected.connect(func(i): _set_obj(idx, i - (1 if idx == 1 else 0)))
		h.add_child(opt)
		if oi < objs.size():
			var ob: Dictionary = objs[oi]
			_text(v, Orders.OBJECTIVES[ob["kind"]]["desc"], GREY, 10)
			_obj_tool(v, ob, oi)
	# constraints
	var cv := _card(box)
	_text(cv, "CONSTRAINTS", INK, 12)
	_constraint_row(cv, od, "avoid", pts, used)
	_constraint_row(cv, od, "consolidate", pts, used)
	_constraint_row(cv, od, "phase", pts, used)
	_constraint_row(cv, od, "entry", pts, used)
	_constraint_row(cv, od, "pace", pts, used)
	_constraint_row(cv, od, "tight", pts, used)
	_constraint_row(cv, od, "knock", pts, used)
	_constraint_row(cv, od, "pistols", pts, used)
	var bb := "[b]SQUAD %d[/b]\n" % (sel_sq + 1)
	for ln in Orders.describe(od, main.level):
		bb += "· %s\n" % String(ln).replace("[", "(")
	_rich(box, bb)


func _set_obj(oi: int, k: int) -> void:
	var od: Dictionary = main.plan["squads"][sel_sq]["orders"]
	var objs: Array = od["objs"]
	if oi == 1 and k < 0:
		if objs.size() > 1:
			objs.resize(1)
	else:
		var kind: String = OBJ_KINDS[k]
		var ob := {"kind": kind}
		match kind:
			"clear", "rescue":
				ob["rooms"] = []
			"contain":
				ob["openings"] = Autoplan.exterior_doors(main.level).slice(0, 2)
			"post":
				ob["p"] = [main.level.W / 2.0, main.level.H / 2.0]
				ob["face"] = 0.0
			"patrol":
				ob["route"] = []
		if oi < objs.size():
			objs[oi] = ob
		else:
			objs.append(ob)
	set_pick({})
	main.plan_changed()
	show_plan()


func _obj_tool(v: Control, ob: Dictionary, oi: int) -> void:
	var h := _h(v)
	match ob["kind"]:
		"clear", "rescue":
			var n: int = ob.get("rooms", []).size()
			_text(h, ("%d room%s picked" % [n, "" if n == 1 else "s"]) if n > 0 else ("the whole building" if ob["kind"] == "clear" else "wherever the hostages are"), GREY, 11)
			_tool_btn(h, "Pick rooms", {"kind": "rooms", "obj": oi})
			_btn(h, "All", func(): ob["rooms"] = []; main.plan_changed(); show_plan())
		"arrest":
			var nm: String = main.cur_sit.get("named", "")
			_text(h, "Target: %s" % (nm if nm != "" else "the first suspect found"), GREY, 11)
		"contain":
			_text(h, "%d opening%s" % [ob.get("openings", []).size(), "" if ob.get("openings", []).size() == 1 else "s"], GREY, 11)
			_tool_btn(h, "Pick doors and windows", {"kind": "openings", "obj": oi})
		"post":
			_text(h, "Click the plan to place; right-click to set facing.", GREY, 11)
			_tool_btn(h, "Place", {"kind": "post", "obj": oi})
		"patrol":
			_text(h, "%d waypoint%s" % [ob.get("route", []).size(), "" if ob.get("route", []).size() == 1 else "s"], GREY, 11)
			_tool_btn(h, "Draw route", {"kind": "route", "obj": oi})
			_btn(h, "Clear", func(): ob["route"] = []; main.plan_changed(); show_plan())


func _tool_btn(parent: Control, text: String, p: Dictionary) -> void:
	var on: bool = not pick.is_empty() and pick.get("kind", "") == p["kind"] and int(pick.get("obj", -1)) == int(p.get("obj", -1))
	var b := _btn(parent, text, func(state): set_pick(p if state else {}); show_plan(), true)
	b.set_pressed_no_signal(on)


func _constraint_row(v: Control, od: Dictionary, key: String, pts: int, used: int) -> void:
	var spec: Dictionary = Orders.CONSTRAINTS[key]
	var h := _h(v)
	var on := false
	match key:
		"avoid":
			on = not od["avoid"].is_empty()
		"consolidate", "entry", "pace":
			on = String(od.get(key, "")) != ""
		"phase":
			on = not od["phase"].is_empty()
		_:
			on = od.get(key, false)
	var cost: int = int(spec["cost"])
	var cb := CheckBox.new()
	cb.text = "%s (%d)" % [spec["name"], cost]
	cb.button_pressed = on
	cb.disabled = not on and used + cost > pts
	cb.tooltip_text = spec["desc"]
	cb.toggled.connect(func(state): _toggle_constraint(key, state))
	h.add_child(cb)
	if not on:
		return
	match key:
		"avoid":
			_text(h, ", ".join(od["avoid"].map(func(r): return Situations.room_title(main.level, r))) if not od["avoid"].is_empty() else "pick rooms", GREY, 10)
			_tool_btn(h, "Pick", {"kind": "avoid"})
		"consolidate":
			_text(h, Situations.room_title(main.level, od["consolidate"]) if od["consolidate"] != "*" else "pick a room", GREY, 10)
			_tool_btn(h, "Pick", {"kind": "consolidate"})
		"entry":
			_text(h, String(od["entry"]).to_lower() if od["entry"] != "*" else "pick a door", GREY, 10)
			_tool_btn(h, "Pick", {"kind": "entry"})
		"pace":
			var po := OptionButton.new()
			po.add_item("walk")
			po.add_item("creep")
			po.select(1 if od["pace"] == "creep" else 0)
			po.item_selected.connect(func(i): od["pace"] = ["walk", "creep"][i]; main.plan_changed())
			h.add_child(po)
		"phase":
			var ph := OptionButton.new()
			var items: Array = [["time", 30], ["time", 60], ["time", 90], ["time", 120], ["time", 180]]
			for si in main.plan["squads"].size():
				if si != sel_sq:
					items.append(["squad", si])
			var cur := 0
			for i in items.size():
				var it: Array = items[i]
				ph.add_item(("wait %d s" % it[1]) if it[0] == "time" else ("until squad %d is done / in position" % (int(it[1]) + 1)))
				if od["phase"].get("kind", "") == it[0] and int(od["phase"].get("t" if it[0] == "time" else "squad", -1)) == int(it[1]):
					cur = i
			ph.select(cur)
			ph.item_selected.connect(func(i):
				var it2: Array = items[i]
				od["phase"] = {"kind": it2[0], "t": it2[1]} if it2[0] == "time" else {"kind": "squad", "squad": it2[1]}
				main.plan_changed())
			h.add_child(ph)


func _toggle_constraint(key: String, on: bool) -> void:
	var od: Dictionary = main.plan["squads"][sel_sq]["orders"]
	match key:
		"avoid":
			od["avoid"] = [] if not on else od["avoid"]
			if on and od["avoid"].is_empty():
				set_pick({"kind": "avoid"})
				# keep the box ticked: a room is needed to cost anything
				od["avoid"] = []
				show_plan()
				return
		"consolidate":
			od["consolidate"] = "*" if on else ""
			if on:
				set_pick({"kind": "consolidate"})
		"entry":
			od["entry"] = "*" if on else ""
			if on:
				set_pick({"kind": "entry"})
		"pace":
			od["pace"] = "walk" if on else ""
		"phase":
			od["phase"] = {"kind": "time", "t": 60} if on else {}
		_:
			od[key] = on
	if not on:
		set_pick({})
	main.plan_changed()
	show_plan()


func set_pick(p: Dictionary) -> void:
	pick = p
	var hint := ""
	match p.get("kind", ""):
		"rooms":
			hint = "CLICK ROOMS TO CLEAR (click again to drop)"
		"openings":
			hint = "CLICK DOORS AND WINDOWS TO CONTAIN"
		"post":
			hint = "CLICK THE POST; RIGHT-CLICK THE FACING"
		"route":
			hint = "CLICK WAYPOINTS; RIGHT-CLICK REMOVES THE LAST"
		"avoid":
			hint = "CLICK ROOMS TO AVOID (a point each)"
		"consolidate":
			hint = "CLICK THE ROOM TO CONSOLIDATE"
		"entry":
			hint = "CLICK THE ENTRY DOOR"
	if main.plan_marks != null:
		main.plan_marks.pick = hint
		main.plan_marks.queue_redraw()


## A click on the plan while a map tool is on.
func map_click(p: Vector2, right: bool) -> void:
	if pick.is_empty() or main.plan.get("squads", []).is_empty():
		return
	var lv = main.level
	var od: Dictionary = main.plan["squads"][sel_sq]["orders"]
	var rm: String = lv.room_at(p)
	var interior: bool = lv.rooms.has(rm) and not lv.is_exterior(rm)
	match pick["kind"]:
		"rooms":
			var ob: Dictionary = od["objs"][int(pick["obj"])]
			if interior:
				if ob["rooms"].has(rm):
					ob["rooms"].erase(rm)
				else:
					ob["rooms"].append(rm)
		"avoid":
			if interior:
				if od["avoid"].has(rm):
					od["avoid"].erase(rm)
				else:
					od["avoid"].append(rm)
		"consolidate":
			if interior:
				od["consolidate"] = rm
				set_pick({})
		"entry":
			var best := ""
			var bd := 2.5
			for did in lv.doors:
				var D: Dictionary = lv.doors[did]
				if not (lv.is_exterior(D["a"]) or lv.is_exterior(D["b"])):
					continue
				var d: float = (D["c"] as Vector2).distance_to(p)
				if d < bd:
					bd = d
					best = did
			if best != "":
				od["entry"] = best
				set_pick({})
		"openings":
			var ob2: Dictionary = od["objs"][int(pick["obj"])]
			var bi := -1
			var bd2 := 2.0
			for i in lv.openings.size():
				var op: Dictionary = lv.openings[i]
				if op["kind"] == "door":
					var D2: Dictionary = lv.doors[op["id"]]
					if not (lv.is_exterior(D2["a"]) or lv.is_exterior(D2["b"])):
						continue
				var d2: float = (op["c"] as Vector2).distance_to(p)
				if d2 < bd2:
					bd2 = d2
					bi = i
			if bi >= 0:
				var lst: Array = ob2.get("openings", [])
				if lst.has(bi):
					lst.erase(bi)
				else:
					lst.append(bi)
				ob2["openings"] = lst
		"post":
			var ob3: Dictionary = od["objs"][int(pick["obj"])]
			if right:
				var q := Operation._v(ob3.get("p", [p.x, p.y]))
				ob3["face"] = (p - q).angle()
			elif main.nav.reachable(p):
				ob3["p"] = [p.x, p.y]
		"route":
			var ob4: Dictionary = od["objs"][int(pick["obj"])]
			var route: Array = ob4.get("route", [])
			if right:
				if not route.is_empty():
					route.pop_back()
			elif main.nav.reachable(p):
				route.append([p.x, p.y])
			ob4["route"] = route
	main.plan_changed()
	show_plan()


# ================================================================== run
func show_run() -> void:
	mode = "run"
	root.visible = true
	abort_armed = false
	_rewinding = false
	_log_shown = 0
	_clear()
	var s: Dictionary = main.cur_sit
	_title(s["title"], 14)
	var h := _h(box)
	var pb := _btn(h, "Pause", func(on): main.set_paused(on), true)
	_run_refs["pause"] = pb
	var clock := Label.new()
	clock.add_theme_font_size_override("font_size", 18)
	clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(clock)
	_run_refs["clock"] = clock
	var hs := _h(box)
	var group := ButtonGroup.new()
	for sp in UI.SPEEDS:
		var b := _btn(hs, ("%sx" % str(sp)).replace(".0x", "x"), func(on): if on: main.set_speed(sp), true)
		b.button_group = group
		b.custom_minimum_size = Vector2(44, 0)
		b.set_pressed_no_signal(is_equal_approx(sp, main.speed))
	_text(box, "REWIND (a way of looking: the operation itself never goes back)", GREY, 10)
	var hr := _h(box)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.0
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(func(v): _on_rewind(v))
	hr.add_child(sl)
	_run_refs["slider"] = sl
	_btn(hr, "Live", func(): _go_live())
	var know := Label.new()
	know.add_theme_font_size_override("font_size", 11)
	know.add_theme_color_override("font_color", GREY)
	know.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(know)
	_run_refs["know"] = know
	var sq := _rich(box, "", 120.0)
	_run_refs["squads"] = sq
	_text(box, "RADIO", INK, 12)
	var lg := RichTextLabel.new()
	lg.bbcode_enabled = true
	lg.scroll_following = true
	lg.custom_minimum_size = Vector2(0, 300)
	lg.add_theme_font_size_override("normal_font_size", 11)
	box.add_child(lg)
	_run_refs["log"] = lg
	var ab := _btn(box, "ABORT  ·  cut losses", func(): _abort())
	ab.custom_minimum_size = Vector2(0, 36)
	_run_refs["abort"] = ab
	_text(box, "Abort: every squad breaks contact and withdraws to its vehicles, still under fire until it gets there. A failure, but a failure with everyone alive always scores better than one with deaths.", GREY, 10)


func _abort() -> void:
	if main.world == null or main.world.over:
		return
	if not abort_armed:
		abort_armed = true
		_run_refs["abort"].text = "CONFIRM ABORT"
		return
	main.ops_abort()
	_run_refs["abort"].text = "ABORTED: withdrawing"
	_run_refs["abort"].disabled = true


func _on_rewind(v: float) -> void:
	if main.world == null or _sliding:
		return
	if v >= main.world.t - 0.3:
		_go_live()
		return
	_rewinding = true
	main.ops_rewind(v)


func _go_live() -> void:
	_rewinding = false
	main.ops_live()
	if _run_refs.has("slider") and main.world != null:
		_run_refs["slider"].set_value_no_signal(main.world.t)


func refresh_run(w, fog) -> void:
	if mode != "run" or w == null:
		return
	var shown_t: float = main.view_t if main.view_t >= 0.0 else w.t
	_run_refs["clock"].text = ("REWIND  " if main.view_t >= 0.0 else "") + "%02d:%04.1f" % [int(shown_t / 60.0), fmod(shown_t, 60.0)]
	_run_refs["pause"].set_pressed_no_signal(main.paused)
	var sl: HSlider = _run_refs["slider"]
	_sliding = true
	sl.max_value = maxf(1.0, w.t)
	if not _rewinding:
		sl.set_value_no_signal(w.t)
	_sliding = false
	var eyes := 0
	var offs := 0
	for o in w.ops:
		if o.judges and o.alive() and not o.gone:
			offs += 1
			if not o.stunned(w.t):
				eyes += 1
	if fog != null and fog.enabled:
		_run_refs["know"].text = "Fog of war: what %d of %d officers can see. %d people in view, %d radio last-known positions." % [eyes, offs,
			fog.visible_ids.size(), fog.lkps.size()]
	else:
		_run_refs["know"].text = "Fog lifted."
	var bb := ""
	if w.teams.size() > 0:
		for el in w.teams[0]["elements"]:
			if not el.has("orders"):
				continue
			var alive := 0
			for m in el["members"]:
				if m.alive() and not m.gone:
					alive += 1
			var ob: Dictionary = el.get("obj", {})
			var what: String = Orders.OBJECTIVES.get(ob.get("kind", ""), {}).get("name", "")
			var st: String = {"assault": "clearing", "hold": "holding", "hunt": "patrolling", "wait": "on the phase line",
				"withdraw": "withdrawing", "support": "waiting on the next room", "lost": "lost"}.get(el["mode"], el["mode"])
			if el.get("consolidating", false):
				st = "consolidating"
			bb += "[b]SQUAD %d[/b]  %d/%d  ·  %s%s\n" % [el["i"] + 1, alive, el["members"].size(), st, ("  ·  " + what) if what != "" else ""]
	_run_refs["squads"].text = Ink.bb(bb)
	# the radio: what the officers say and what happens to them
	var lg: RichTextLabel = _run_refs["log"]
	_log_shown = maxi(_log_shown, w.log_base)
	while _log_shown < w.log_base + w.log_lines.size():
		var ln: Dictionary = w.log_lines[_log_shown - w.log_base]
		_log_shown += 1
		if not _radio(ln, w):
			continue
		var txt: String = String(ln["text"]).replace("[", "(")
		match ln["kind"]:
			"kill":
				lg.append_text(Ink.bb("[b][color=#b31f26]%s[/color][/b]\n" % txt))
			"bad", "end":
				lg.append_text(Ink.bb("[b]%s[/b]\n" % txt))
			"comms":
				lg.append_text(Ink.bb("[i][color=#737370]%s[/color][/i]\n" % txt))
			_:
				lg.append_text(Ink.bb("[color=#2b2b2b]%s[/color]\n" % txt))


## Is a log line something the department would hear on the radio?
func _radio(ln: Dictionary, w) -> bool:
	var txt: String = ln["text"]
	var body: String = txt.substr(txt.find("  ") + 2) if txt.find("  ") >= 0 else txt
	if float(ln["t"]) < 0.5 and ln["kind"] == "bad":
		return false
	if ln["kind"] == "end" or body.begins_with("Squad") or body.begins_with("ABORT") or body.begins_with("Police"):
		return true
	if body.begins_with("A") and body.length() > 1 and body[1].is_valid_int():
		return ln["kind"] in ["comms", "kill", "info", "bad", "hit", "rule"]
	if ln["kind"] == "kill" and (body.contains("by A") or body.contains("Shots fired")):
		return true
	return false


# ================================================================== debrief
func show_debrief(res: Dictionary, w, dept_lines: Array) -> void:
	mode = "debrief"
	root.visible = true
	_clear()
	var s: Dictionary = main.cur_sit
	_title("DEBRIEF  ·  %s" % s["title"], 14)
	_title("%s  ·  %d" % [res["label"], int(res["score"])], 20)
	var goal: String = res["goal"]
	_text(box, goal.substr(0, 1).to_upper() + goal.substr(1) + ".", INK, 13)
	_text(box, "Score: success 100, partial 65, failure (an abort included) 30; every death costs 15 and every officer down 5. Force is a separate reputation (from v0.9).", GREY, 10)
	var bb := ""
	for sq in res.get("squads", []):
		bb += "[b]SQUAD %d[/b]  %d of %d standing\n" % [int(sq["i"]) + 1, int(sq["alive"]), int(sq["n"])]
		for r in sq["results"]:
			bb += "    %s: %s (%s)\n" % [Orders.OBJECTIVES.get(r["kind"], {}).get("name", r["kind"]), "met" if r["ok"] else "failed", r["why"]]
		if sq["results"].is_empty():
			bb += "    objective not resolved when the operation ended\n"
	bb += "\n[b]TIMELINE[/b]\n"
	for tl in w.timeline:
		bb += "%s  %s\n" % [w.clock(tl["t"]), String(tl["text"]).replace("[", "(")]
	# officers
	bb += "\n[b]OFFICERS[/b]\n"
	var per: Dictionary = {}
	for sh in w.incident.shots:
		if not sh["pol"]:
			continue
		var p: Dictionary = per.get(sh["by"], {"shots": 0, "hits": 0, "miss": {}})
		p["shots"] += 1
		if sh["hit"] != "":
			p["hits"] += 1
		else:
			var e: String = sh.get("end", "")
			p["miss"][e] = p["miss"].get(e, 0) + 1
		per[sh["by"]] = p
	var broken := {}
	for b in w.broken:
		broken[b["id"]] = broken.get(b["id"], []) + ["%s (%s)" % [b["order"], b["why"]]]
	for o in w.ops:
		if not o.judges:
			continue
		var p2: Dictionary = per.get(o.id, {"shots": 0, "hits": 0, "miss": {}})
		var misses: Array = []
		for k in p2["miss"]:
			misses.append("%d %s" % [p2["miss"][k], k if k != "" else "somewhere"])
		var st: String = "standing"
		if o.state == "dead":
			st = "[color=#b31f26]killed[/color]"
		elif o.state == "down":
			st = "[color=#b31f26]down[/color]"
		elif o.wounds > 0 or o.arm_hit or o.leg_hit:
			st = "wounded"
		var used: Array = []
		for gid in ["flashbang", "taser", "launcher"]:
			var had: int = Equipment.gear_counts(o.kit).get(gid, 0)
			var spent: int = had - int(o.gear.get(gid, 0))
			if spent > 0:
				used.append("%s x%d" % [String(Equipment.GEAR[gid]["short"]).to_lower(), spent])
		if o.kit.get("head", "") == "sof_helmet" and not o.helmet:
			used.append("helmet took a round")
		bb += "%s %s: %s; %d rounds, %d hit%s%s\n    [color=#737370]%s%s[/color]\n" % [o.id, o.name, st, p2["shots"], p2["hits"],
			("; misses: " + ", ".join(misses)) if not misses.is_empty() else "",
			("; [b]broke orders:[/b] " + ", ".join(broken.get(o.id, []))) if broken.has(o.id) else "",
			Equipment.describe(o.kit), ("; used " + ", ".join(used)) if not used.is_empty() else ""]
	var sm: Dictionary = w.incident.summary()
	bb += "\n[b]CIVILIANS[/b]  %d present, %d hurt, %d killed; %d round%s from police struck a civilian.\n" % [sm["civ_total"], sm["civ_hit"],
		sm["civ_killed"], sm["civ_hit_police"], "" if sm["civ_hit_police"] == 1 else "s"]
	if sm.get("hostages", 0) > 0:
		bb += "Hostages: %d, %d out safe, %d killed.\n" % [sm["hostages"], sm["hostages_safe"], sm["hostages_killed"]]
	bb += "Suspects: %d, %d down, %d gave up, %d cuffed, %d got away.\n" % [sm["suspects"], sm["suspects_down"], sm["surrendered"], sm["arrested"], sm["escaped"]]
	if not dept_lines.is_empty():
		bb += "\n[b]THE DEPARTMENT[/b]\n"
		for d in dept_lines:
			bb += String(d).replace("[", "(") + "\n"
	bb += "\n[b]FILES OPENED[/b]  %d. What comes of them lands later (consequences arrive in v0.9).\n" % int(sm["findings"])
	_rich(box, bb)
	_sep()
	_text(box, "REPLAY  ·  the whole operation with the fog lifted", INK, 12)
	var hr := _h(box)
	var pl := _btn(hr, "Play", func(on): main.ops_replay_play(on), true)
	_run_refs["play"] = pl
	for sp in [1.0, 2.0, 5.0, 10.0]:
		_btn(hr, "%dx" % int(sp), func(): main.replay_speed = sp)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = maxf(1.0, w.t)
	sl.step = 0.0
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(func(v): if not _sliding: main.ops_replay_seek(v))
	box.add_child(sl)
	_run_refs["rslider"] = sl
	var rc := Label.new()
	rc.add_theme_font_size_override("font_size", 11)
	box.add_child(rc)
	_run_refs["rclock"] = rc
	var back := _btn(box, "<  Back to the board", func(): main.ops_board())
	back.custom_minimum_size = Vector2(0, 34)


func refresh_replay(t: float, total: float, playing: bool) -> void:
	if mode != "debrief" or not _run_refs.has("rslider"):
		return
	_sliding = true
	_run_refs["rslider"].set_value_no_signal(t)
	_sliding = false
	_run_refs["rclock"].text = "%02d:%04.1f of %02d:%04.1f" % [int(t / 60.0), fmod(t, 60.0), int(total / 60.0), fmod(total, 60.0)]
	_run_refs["play"].set_pressed_no_signal(playing)
