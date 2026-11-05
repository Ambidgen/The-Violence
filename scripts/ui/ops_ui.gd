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
const Politics = preload("res://scripts/campaign/politics.gd")
const Story = preload("res://scripts/campaign/story.gd")
const StoryArchive = preload("res://scripts/campaign/story_archive.gd")
const Settings = preload("res://scripts/ui/settings.gd")
const Risk = preload("res://scripts/campaign/risk.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")
const Patrol = preload("res://scripts/campaign/patrol.gd")
const CityMap = preload("res://scripts/ui/city_map.gd")
const PANEL_W := 460.0
const INK := Color("#141313")
const GREY := Color("#6e675c")
const OBJ_KINDS := ["clear", "arrest", "rescue", "contain", "post", "patrol"]

var main
var root: PanelContainer
var city_map
var _scroll: ScrollContainer
var box: VBoxContainer
var mode := ""
var tab := 0  # plan screen: 0 briefing, 1 force, 2 orders
var sel_sq := 0
var pick := {}  # map tool: {kind, squad, obj}
var abort_armed := false
var _run_refs := {}  # widgets updated every refresh during the run
var _log_shown := 0
var _rewinding := false
var _sliding := false  # the panel itself is moving a slider: not the player
var kit_open := ""  # Force screen: the officer whose kit is being edited (v0.7.5)
var roster_open := ""  # Roster: the officer whose file is open (v0.8.5)
var flash := ""  # a one-line answer to the last thing tried (v0.8.5)
var case_filter := "all"      # IA triage: all, grave, video, due
var guide_active := false     # first-operation guide, until the debrief returns to the board
var guide_dismissed := false


func build(m) -> void:
	main = m
	city_map = CityMap.new()
	city_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	city_map.offset_right = -PANEL_W
	city_map.mouse_filter = Control.MOUSE_FILTER_STOP
	city_map.visible = false
	add_child(city_map)
	root = PanelContainer.new()
	root.theme = UI.make_theme()
	root.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	root.offset_left = -PANEL_W
	root.visible = false
	add_child(root)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	_scroll.add_child(box)


func hide_all() -> void:
	root.visible = false
	city_map.visible = false
	mode = ""


func _clear() -> void:
	city_map.visible = false
	for c in box.get_children():
		c.queue_free()
	_scroll.scroll_horizontal = 0
	_scroll.scroll_vertical = 0
	_run_refs.clear()


## EA_TASKS P1.D1: a confirm dialog for any hire, course or contract that pushes the
## four-week forecast into the red. back() rebuilds the screen the choice was on.
func _confirm(title: String, body: String, on_yes: Callable, back: Callable) -> void:
	mode = "confirm"
	_clear()
	_title(title, 16)
	_text(box, body, INK, 12)
	_btn(box, "Yes — commit", func(): on_yes.call())
	_btn(box, "Not now", func(): back.call())


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
	p.add_theme_stylebox_override("panel", UI._sb(Color("#e6dfcd"), Color("#b3aa96"), 1, 8.0))
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
static func _ward_label(s: Dictionary) -> String:
	if s.get("city_error", false):
		return "ward unavailable"
	return "%s ward (trust %d)" % [s.get("ward", "Unknown"), int(s.get("trust", 0))]


func show_board(lines := []) -> void:
	if mode == "debrief":
		guide_active = false
	mode = "board"
	root.visible = true
	_clear()
	var c = main.campaign
	var d = c.dept
	if c.week() == 1 and int(d.ops_run) == 0 and bool(Settings.get_v("tips")) and not guide_dismissed:
		guide_active = true
	if c.over():
		_election_night(lines)
		return
	city_map.show_city(c.board, c.politics.trust, c.week())
	_title("THE CAMPAIGN FILE  ·  week %d of %d" % [c.week(), c.WEEKS])
	var fit: int = d.available().size()
	var out: int = d.officers.filter(func(r): return r["status"] == "injured").size()
	var busy: int = c.committed().size()
	_text(
		box,
		(
			"PORT CARRICK PD  ·  %d fit, %d injured, %d committed this week. An officer sent to one call cannot answer another."
			% [fit, out, busy]
		),
		GREY,
		11
	)
	_roster_strip(box, c)
	_dept_strip(box)
	if c.run != null:
		_desk_card(box)
	_patrol_card(box)
	_story_card(box, Story.current(c))
	if bool(Settings.get_v("tips")) and c.week() <= 2:
		_first_weeks(box)
	_front_page(box, c.politics, c.week() - 1 if c.week() > 1 else 1)
	for ln in lines:
		_text(box, String(ln), INK, 11)
	for i in c.board.size():
		var s: Dictionary = c.board[i]
		var v := _card(box)
		var t := Label.new()
		t.text = "%d  ·  %s" % [i + 1, s["title"]]
		t.add_theme_font_size_override("font_size", 14)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		if s.has("site_name"):
			_text(v, "%s  ·  %s" % [s["site_name"], s["address"]], GREY, 11)
		elif s.get("city_error", false):
			_text(v, "City data unavailable: this call has no mapped location.", GREY, 11)
		_text(
			v,
			(
				"%s  ·  %s  ·  visibility %s  ·  pressure: %s"
				% [
					Situations.TYPES[s["type"]]["name"],
					_ward_label(s),
					dots(int(s["visibility"])),
					String(s["pressure"])
				]
			),
			GREY,
			11
		)
		var st := ""
		var status_key: String = "truce" if s.get("truce", false) else String(s["status"])
		match status_key:
			"truce":
				st = "Truce: the crews are keeping it, and so are you."
			"open":
				var n: int = c.plan_members(s).size()
				st = (
					"Open: %s"
					% (
						("planned, %d officer%s" % [n, "" if n == 1 else "s"])
						if n > 0
						else "nobody assigned yet"
					)
				)
				if not s.get("canvass", []).is_empty():
					st += ", %d canvassing" % s["canvass"].size()
			"done":
				var r: Dictionary = s.get("result", {})
				var g0: String = r.get("goal", "")
				st = (
					"Done: %s, %d. %s."
					% [
						r.get("label", "?"),
						int(r.get("score", 0)),
						g0.substr(0, 1).to_upper() + g0.substr(1)
					]
				)
			_:
				st = "Unattended"
		_text(v, st, INK, 12)
		if s["status"] == "open":
			var h := _h(v)
			var sid: String = s["id"]
			var bp := _btn(h, "Brief and plan  >", func(): main.ops_select(sid))
			if c.run != null and c.run.drafts.any(func(dr): return dr["kind"] == "doctrine"):
				bp.disabled = true
				bp.tooltip_text = "Choose your inheritance on the desk first."
	_sep()
	var hb := _h(box)
	var block: Array = c.run.blocking() if c.run != null else []
	var ew := _btn(hb, "End week %d" % c.week(), func(): _end_week())
	if not block.is_empty():
		ew.disabled = true
		ew.tooltip_text = "Settle the desk first: %s." % ", ".join(block)
	_btn(hb, "City Hall", func(): _city_hall())
	_btn(hb, "Roster", func(): _roster())
	_btn(hb, "Budget", func(): _budget())
	var nc: int = d.open_cases().size()
	_btn(hb, "Internal affairs%s" % ((" (%d)" % nc) if nc > 0 else ""), func(): _cases())
	var hb2 := _h(box)
	if c.run != null:
		_btn(hb2, "Armoury and programs", func(): _armory())
	_btn(hb2, "Campaign file", func(): _story_file())
	_btn(hb2, "<  Main menu", func(): main.go_title())
	_text(
		box, "One campaign is kept. The file is saved after each operation and each week.", GREY, 10
	)


# ================================================================== the desk (1.3, the run layer)
const TAG_WORDS := {"military": "MILITARY  ·  Safe Streets approves; the coalition takes note",
	"restraint": "RESTRAINT  ·  the coalition approves", "neutral": ""}


## What is waiting on the chief's desk this week: drafts, offers, events.
func _desk_card(parent: Control) -> void:
	var run = main.campaign.run
	var v := _card(parent)
	_text(v, "THE DESK", Ink.accent(1.0) if not run.blocking().is_empty() else INK, 13)
	if run.drafts.is_empty() and run.offers.is_empty() and run.events.is_empty():
		_text(v, "Nothing waiting. %s" % _program_line(), GREY, 11)
		return
	for di in run.drafts.size():
		var d: Dictionary = run.drafts[di]
		var h := _h(v)
		# A card the armoury already covers is re-dealt when the inheritance is chosen
		# (EA_TASKS P0.C2), so the count is read from the draft, not assumed to be three.
		var ncards: int = (d.get("cards", []) as Array).size()
		var label: String = {"doctrine": "INHERITANCE  ·  choose what the last chief left you",
			"procurement": "PROCUREMENT  ·  %d contract%s, sign one" % [ncards, "" if ncards == 1 else "s"],
			"program": "TRAINING PROGRAM  ·  one habit for the whole force"}.get(d["kind"], "A draft")
		_text(h, label, INK, 12)
		var k: int = di
		_btn(h, "Open  >", func(): _desk_draft(k))
	for oi in run.offers.size():
		var o: Dictionary = run.offers[oi]
		var h2 := _h(v)
		_text(h2, "OFFER  ·  %s (lapses at the end of the week)" % o["who_name"], INK, 12)
		var k2: int = oi
		_btn(h2, "Open  >", func(): _desk_offer(k2))
	for ei in run.events.size():
		var e: Dictionary = run.events[ei]
		var h3 := _h(v)
		_text(h3, "EVENT  ·  %s (answer before the week ends)" % e["title"], INK, 12)
		var k3: int = ei
		_btn(h3, "Open  >", func(): _desk_event(k3))
	_text(v, _program_line(), GREY, 10)


## The patrol radio (2026-11-05): one encounter a day. The next day's call is answered
## here; the rest of the week waits its turn. Anything left at the end of the week, the
## pair handles alone.
func _patrol_card(parent: Control) -> void:
	var c = main.campaign
	if c.patrols.is_empty():
		return
	var v := _card(parent)
	var nxt: Dictionary = Patrol.next_pending(c.patrols)
	_text(v, "PATROL RADIO  ·  one call a day", Ink.accent(1.0) if not nxt.is_empty() else INK, 13)
	for e in c.patrols:
		var day: String = Patrol.DAYS[int(e["day"])]
		var st: String = String(e["status"])
		if st == "done":
			_text(v, "%s  ·  %s" % [day, Patrol.summary_line(e)], GREY, 11)
			continue
		if st == "running":
			_text(v, "%s  ·  %s: armed, on the board as an operation." % [day, Patrol.spec(e)["name"]], INK, 11)
			continue
		if String(e["id"]) != String(nxt.get("id", "")):
			_text(v, "%s  ·  —" % day, GREY, 10)
			continue
		var rd: Dictionary = Patrol.read(e)
		_text(v, "%s  ·  %s" % [day.to_upper(), String(Patrol.spec(e)["name"]).to_upper()], INK, 12)
		_text(v, Patrol.radio_line(e, c.dept), INK, 12)
		_text(v, "Dispatch reads it as %s; %s." % [rd["danger"], rd["urgency"]], GREY, 10)
		var h := _h(v)
		var pid: String = String(e["id"])
		for k in Patrol.CHOICES.size():
			var ch: Dictionary = Patrol.CHOICES[k]
			var kk: int = k
			var b := _btn(h, String(ch["name"]), func(): main.ops_patrol(pid, kk))
			b.tooltip_text = String(ch["desc"]) + ((" Overtime $%d." % Patrol.OVERTIME[k]) if Patrol.OVERTIME[k] > 0 else "")
	_text(v, "Calls you leave unanswered, the pair goes in alone.", GREY, 10)


func _program_line() -> String:
	var run = main.campaign.run
	if run.program.is_empty():
		return "No training program running."
	return "In training: %s, %d week%s to go." % [run.program["name"], int(run.program["weeks_left"]), "" if int(run.program["weeks_left"]) == 1 else "s"]


func _desk_back(lines: Array) -> void:
	main._save()
	show_board(lines)


func _desk_draft(di: int) -> void:
	var c = main.campaign
	var run = c.run
	if di >= run.drafts.size():
		show_board()
		return
	mode = "desk"
	_clear()
	var d: Dictionary = run.drafts[di]
	var kind: String = d["kind"]
	_title({"doctrine": "THE INHERITANCE", "procurement": "PROCUREMENT", "program": "A TRAINING PROGRAM"}.get(kind, "A DRAFT"))
	_text(box, {
		"doctrine": "The outgoing chief left more than a file. Choose one. Finished runs add more to choose from.",
		"procurement": "The armoury issues only what the department has a contract for. Sign one; the rest go to other cities. Account: $%s." % Department.money(c.dept.balance),
		"program": "In-service training for every officer on the books. When it ends, everyone has the habit, and the academy teaches it to every hire after. One program at a time. Account: $%s." % Department.money(c.dept.balance),
	}.get(kind, ""), GREY, 11)
	for cid in d["cards"]:
		var info: Dictionary = run.card_info(kind, cid, c)
		var v := _card(box)
		_text(v, String(info["name"]), INK, 14)
		_text(v, String(info["desc"]), INK, 11)
		var meta: Array = []
		if int(info.get("cost", 0)) > 0:
			meta.append("$%s" % Department.money(int(info["cost"])))
		if int(info.get("weeks", 0)) > 0:
			meta.append("%d weeks" % int(info["weeks"]))
		if String(info.get("group", "")) != "":
			meta.append(String(info["group"]))
		if TAG_WORDS.get(String(info.get("tag", "")), "") != "":
			meta.append(TAG_WORDS[String(info["tag"])])
		if not meta.is_empty():
			_text(v, "  ·  ".join(meta), GREY, 10)
		var cc: String = cid
		var b := _btn(v, "Choose", func(): _desk_choose(c, run, di, cc))
		# P1.D2/D1: the overdraft carries a purchase, but not past the limit; and the
		# button says which forecast week the price turns red.
		var cost: int = int(info.get("cost", 0))
		if cost > 0 and c.dept.balance - cost < c.dept.OVERDRAFT_LIMIT:
			b.disabled = true
			b.tooltip_text = "Past the overdraft limit (-$%s): the account cannot cover it." % Department.money(-c.dept.OVERDRAFT_LIMIT)
		elif cost > 0:
			var worst: Dictionary = Department.forecast_worst(c.dept.forecast_after("kit" if kind == "procurement" else "course", cost))
			if not worst.is_empty():
				b.tooltip_text = "Week %d goes to -$%s on the four-week forecast." % [int(worst["week"]), Department.money(-int(worst["balance"]))]
	if kind != "doctrine":
		_btn(box, "Pass%s" % (" (surplus sold: +$%s)" % Department.money(Rogue.PASS_REFUND) if kind == "procurement" else ""), func(): _desk_back(run.pick(c, di, "")))
	_btn(box, "<  Board", func(): show_board())


## EA_TASKS P1.D1: choosing a draft card with a price asks first when the four-week
## forecast goes into the red.
func _desk_choose(c, run, di: int, cid: String) -> void:
	if di >= run.drafts.size():
		show_board()
		return
	var kind: String = String(run.drafts[di].get("kind", ""))
	var cost := 0
	if kind != "doctrine":
		cost = int(run.card_info(kind, cid, c).get("cost", 0))
	if cost > 0:
		var worst: Dictionary = Department.forecast_worst(c.dept.forecast_after("kit" if kind == "procurement" else "course", cost))
		if not worst.is_empty():
			_confirm(
				"SPEND INTO THE RED?",
				(
					"$%s now. On the four-week forecast, week %d goes to -$%s (the council's overdraft limit is -$%s). Commit anyway?"
					% [Department.money(cost), int(worst["week"]), Department.money(-int(worst["balance"])), Department.money(-c.dept.OVERDRAFT_LIMIT)]
				),
				func(): _desk_back(run.pick(c, di, cid)),
				func(): show_board()
			)
			return
	_desk_back(run.pick(c, di, cid))


func _desk_offer(oi: int) -> void:
	var c = main.campaign
	var run = c.run
	if oi >= run.offers.size():
		show_board()
		return
	mode = "desk"
	_clear()
	var o: Dictionary = run.offers[oi]
	_title("AN OFFER")
	_text(box, String(o["who_name"]), GREY, 12)
	_text(box, String(o["text"]), INK, 13)
	var v := _card(box)
	_text(v, "ACCEPT  ·  " + run.describe(o["accept"]), INK, 11)
	_btn(v, "Accept", func(): _desk_back(run.answer_offer(c, oi, true)))
	var v2 := _card(box)
	_text(v2, "DECLINE  ·  " + run.describe(o.get("decline", {})), INK, 11)
	_btn(v2, "Decline", func(): _desk_back(run.answer_offer(c, oi, false)))
	_text(box, "Left on the desk, the offer lapses at the end of the week.", GREY, 10)
	_btn(box, "<  Board", func(): show_board())


func _desk_event(ei: int) -> void:
	var c = main.campaign
	var run = c.run
	if ei >= run.events.size():
		show_board()
		return
	mode = "desk"
	_clear()
	var e: Dictionary = run.events[ei]
	_title(String(e["title"]).to_upper())
	_text(box, Rogue.fill(String(e["text"]), e), INK, 13)
	for k in (e["choices"] as Array).size():
		var ch: Dictionary = e["choices"][k]
		var v := _card(box)
		_text(v, Rogue.fill(String(ch["label"]), e), INK, 13)
		_text(v, run.describe(ch["effects"]), GREY, 10)
		var kk := k
		var b := _btn(v, "Choose", func(): _desk_back(run.answer_event(c, ei, kk)))
		var why: String = run.choice_blocked(c, ch)
		if why != "":
			b.disabled = true
			b.tooltip_text = why
	_btn(box, "<  Board", func(): show_board())


## The armoury, the running program, and what the desk has decided this run.
func _armory() -> void:
	var c = main.campaign
	var run = c.run
	mode = "desk"
	_clear()
	_title("ARMOURY AND PROGRAMS  ·  week %d" % c.week())
	_text(box, "Seed %d%s." % [c.seed_val, ("  ·  inheritance: " + String(Rogue.DOCTRINES[run.doctrine]["name"])) if run.doctrine != "" else ""], GREY, 11)
	var v := _card(box)
	_text(v, "IN THE ARMOURY", INK, 12)
	var names: Array = []
	for it in run.armory:
		names.append(Rogue.item_name(it))
	_text(v, ", ".join(names) + ".", INK, 11)
	_text(v, "Contracts signed: %s." % (", ".join(run.contracts.map(func(x): return Rogue.CONTRACTS[x]["name"])) if not run.contracts.is_empty() else "none yet"), GREY, 10)
	var v2 := _card(box)
	_text(v2, "TRAINING", INK, 12)
	_text(v2, _program_line(), INK, 11)
	if not run.program.is_empty():
		_btn(v2, "Abandon the program (no refund)", func(): _desk_back(run.abandon_program(c)))
	var taught: Array = c.dept.curriculum.map(func(h): return "%s (%s)" % [Rogue._habit(h).get("name", h), h])
	_text(v2, "The academy now also teaches: %s." % (", ".join(taught) if not taught.is_empty() else "nothing beyond the standard twelve"), GREY, 10)
	if run.intel_weeks > 0:
		_text(v2, "Extra tips on every file: %d more week%s." % [run.intel_weeks, "" if run.intel_weeks == 1 else "s"], GREY, 10)
	var v3 := _card(box)
	_text(v3, "WHAT THE DESK DECIDED", INK, 12)
	var shown := 0
	for i in range(run.desk_log.size() - 1, -1, -1):
		var lg: Dictionary = run.desk_log[i]
		_text(v3, "Week %d  ·  %s" % [int(lg.get("week", 0)), String(lg.get("text", ""))], INK, 10)
		shown += 1
		if shown >= 30:
			break
	if shown == 0:
		_text(v3, "Nothing yet.", GREY, 10)
	_btn(box, "<  Board", func(): show_board())


func _end_week() -> void:
	var lines: Array = main.ops_end_week()
	if main.campaign.over():
		main.play_consequence_short("s11_election", {}, func(): show_board(lines), true)
	else:
		main.play_week_recap(func(): show_board(lines))


## A note from the outgoing chief (1.0): the first two weeks, unless tips are off.
func _first_weeks(parent: Control) -> void:
	var v := _card(parent)
	_text(v, "FROM THE OUTGOING CHIEF", INK, 12)
	for ln in [
		"The board is a week, not a queue. You will not have enough officers for every call.",
		"Open the file before you plan. Estimates are marked with confidence; canvassing costs an officer for the week.",
		"Suggest a plan is a starting point. Change the people, the entry, the orders—or start with a blank plan in Settings.",
		"After an operation, read the debrief and the internal affairs file. A clean score does not erase what the city saw.",
		"End the week when you are ready. The budget, the roster and the wards carry every decision forward.",
	]:
		_text(v, "·  " + ln, INK, 11)
	_text(v, "These notes stop after week 2. Tips can be turned off in Settings.", GREY, 10)


## The Carrick Ledger: last week's front page (v0.9).
func _front_page(parent: Control, p, week: int) -> void:
	var items: Array = p.week_press(week)
	# P1.F1: the ledger also shows what moved the ally and poll numbers this week.
	var causes: Array = p.week_causes(week)
	if items.is_empty() and causes.is_empty():
		return
	var v := _card(parent)
	var mast := _text(v, "T H E   C A R R I C K   L E D G E R   ·   week %d" % week, INK, 11)
	mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for it in items.slice(0, 3):
		var hot: bool = (
			it["kind"] in ["story", "case"]
			or (it["kind"] == "op" and String(it["head"]).find("KILLED") >= 0)
		)
		_text(v, String(it["head"]), Ink.accent(0.9) if hot else INK, 13)
		_text(v, String(it["body"]), GREY, 10)
	if not causes.is_empty():
		_text(v, "What moved the numbers this week:", GREY, 10)
		for cl in causes.slice(0, 8):
			_text(v, "·  " + cl, GREY, 10)


## The recurring chapter card: the act gives the campaign its question; the open call,
## current record and named voice keep this week's page tied to play.
func _story_card(parent: Control, page: Dictionary) -> void:
	if page.is_empty():
		return
	var v := _card(parent)
	_text(
		v,
		(
			"ACT %d  ·  %s  ·  WEEK %d"
			% [int(page["act"]), String(page["act_title"]).to_upper(), int(page["week"])]
		),
		GREY,
		10
	)
	_text(v, String(page["title"]).to_upper(), INK, 13)
	_text(v, String(page["text"]), INK, 11)
	if String(page.get("focus", "")) != "":
		_text(v, "THIS WEEK  ·  " + String(page["focus"]), GREY, 10)
	if String(page.get("quote", "")) != "":
		_text(v, "“%s”" % String(page["quote"]), INK, 11)
		_text(v, "— %s" % String(page["speaker"]), GREY, 10)
	if String(page.get("record", "")) != "":
		_text(v, "THE RECORD  ·  " + String(page["record"]), GREY, 10)


## A rereadable account of the campaign: the inherited premise, act structure and the
## Ledger's latest version. All entries come from the saved campaign record.
func _story_file() -> void:
	mode = "story"
	_clear()
	var c = main.campaign
	var p = c.politics
	var page: Dictionary = Story.current(c)
	_title("CAMPAIGN FILE  ·  week %d of %d" % [mini(c.week(), c.WEEKS), c.WEEKS])
	_story_card(box, page)
	var tools := _h(box)
	_btn(tools, "People & conversations", func(): _people())
	_btn(tools, "Documents", func(): _documents())
	var inherited := _card(box)
	_text(inherited, "THE INHERITED FILE", INK, 12)
	_text(inherited, Story.PROLOGUE, GREY, 11)
	var figures := _card(box)
	_text(figures, "THE FORCE RECORD", INK, 12)
	_text(
		figures,
		(
			"%d operations succeeded; %d failed; %d situations left unattended. %d civilians hit by police; %d killed. %d officers killed. Average ward trust: %.0f."
			% [
				int(p.record.get("successes", 0)),
				int(p.record.get("failures", 0)),
				int(p.record.get("unattended", 0)),
				int(p.record.get("civ_hit", 0)),
				int(p.record.get("civ_killed", 0)),
				int(p.record.get("officers_killed", 0)),
				p.avg_trust()
			]
		),
		GREY,
		10
	)
	_text(box, "FIVE ACTS", INK, 12)
	for act in Story.acts():
		var av := _card(box)
		var state := "AHEAD"
		if c.week() > int(act["last"]) or c.over():
			state = "FILED"
		elif c.week() >= int(act["first"]):
			state = "CURRENT"
		_text(
			av,
			(
				"ACT %d  ·  %s  ·  WEEKS %d–%d  ·  %s"
				% [
					int(act["number"]),
					String(act["title"]).to_upper(),
					int(act["first"]),
					int(act["last"]),
					state
				]
			),
			Ink.accent(0.9) if state == "CURRENT" else INK,
			11
		)
		_text(av, String(act["summary"]), GREY, 10)
	var latest: Array = p.press
	_text(box, "THE PUBLIC RECORD  ·  THE CARRICK LEDGER", INK, 12)
	var shown := 0
	for i in range(latest.size() - 1, maxi(-1, latest.size() - 9), -1):
		var item: Dictionary = latest[i]
		var h := _card(box)
		_text(
			h, "WEEK %d  ·  %s" % [int(item.get("week", 0)), String(item.get("head", ""))], INK, 11
		)
		_text(h, String(item.get("body", "")), GREY, 10)
		shown += 1
	if shown == 0:
		_text(box, "No front page has been filed yet.", GREY, 10)
	var actions := _h(box)
	_btn(actions, "<  Back to the board", func(): show_board())
	if c.over():
		_btn(actions, "Election night", func(): _election_night([]))


## A directory of people whose choices and institutions shape the campaign.
func _people() -> void:
	mode = "people"
	_clear()
	var c = main.campaign
	_title("PEOPLE  ·  WEEK %d" % mini(c.week(), c.WEEKS))
	_text(
		box,
		"Ask a question. Their answers read the current campaign file; they do not advance the week.",
		GREY,
		10
	)
	for person in StoryArchive.contacts(c):
		var card := _card(box)
		var contact_id := String(person["id"])
		_text(card, String(person["name"]).to_upper(), INK, 12)
		_text(card, String(person["role"]), GREY, 10)
		_text(card, String(person["intro"]), INK, 10)
		_text(
			card,
			String(person["status"]),
			Ink.accent(0.85) if String(person["status"]).contains("lost") else GREY,
			10
		)
		_btn(card, "Open conversation", _conversation.bind(contact_id))
	var actions := _h(box)
	_btn(actions, "Documents", func(): _documents())
	_btn(actions, "Campaign file", func(): _story_file())
	_btn(actions, "<  Back to board", func(): show_board())


## One question at a time; returning to an answer never changes campaign state.
func _conversation(contact_id: String, topic_id := "") -> void:
	mode = "conversation"
	_clear()
	var c = main.campaign
	var person: Dictionary = StoryArchive.contact(c, contact_id)
	if person.is_empty():
		_people()
		return
	_title("CONVERSATION  ·  %s" % String(person["name"]).to_upper())
	var profile := _card(box)
	_text(profile, String(person["role"]), GREY, 10)
	_text(profile, String(person["intro"]), INK, 11)
	_text(profile, String(person["status"]), GREY, 10)
	if topic_id != "":
		var exchange: Dictionary = StoryArchive.dialogue(c, contact_id, topic_id)
		if not exchange.is_empty():
			var scene := _card(box)
			_text(scene, "YOU ASK", GREY, 10)
			_text(scene, "“%s”" % String(exchange["question"]), INK, 11)
			_text(scene, String(exchange["speaker"]).to_upper(), GREY, 10)
			_text(scene, String(exchange["reply"]), INK, 12)
			var reference := String(exchange.get("reference", ""))
			if reference != "":
				_btn(
					scene,
					"Open the referenced document",
					_open_document.bind(reference, "all", contact_id, topic_id)
				)
	_text(box, "ASK ABOUT", INK, 12)
	for topic in StoryArchive.topics(contact_id):
		_btn(box, String(topic["label"]), _conversation.bind(contact_id, String(topic["id"])))
	var actions := _h(box)
	_btn(actions, "All people", func(): _people())
	_btn(actions, "Documents", func(): _documents())
	_btn(actions, "Campaign file", func(): _story_file())


## Documents are extracts from campaign state: memos, accounts, findings and clippings.
func _documents(
	filter := "all", selected_id := "", return_person := "", return_topic := ""
) -> void:
	mode = "documents"
	_clear()
	var c = main.campaign
	_title("DOCUMENTS  ·  WEEK %d" % mini(c.week(), c.WEEKS))
	if selected_id != "":
		var found: Dictionary = {}
		for document in StoryArchive.documents(c, filter):
			if String(document["id"]) == selected_id:
				found = document
				break
		if found.is_empty():
			_text(box, "That document is no longer in the current file.", GREY, 11)
		else:
			var page := _card(box)
			_text(page, String(found["date"]), GREY, 10)
			_text(page, String(found["title"]).to_upper(), INK, 14)
			_text(
				page,
				"FROM  %s   ·   TO  %s" % [String(found["from"]), String(found["to"])],
				GREY,
				10
			)
			_text(page, String(found["body"]), INK, 11)
		var actions := _h(box)
		_btn(actions, "Back to list", _documents.bind(filter))
		if return_person != "":
			_btn(actions, "Back to conversation", _conversation.bind(return_person, return_topic))
		else:
			_btn(actions, "People", func(): _people())
		_btn(actions, "Campaign file", func(): _story_file())
		return
	var tabs := _h(box)
	for tab in [
		{"id": "all", "label": "All"},
		{"id": "office", "label": "Office"},
		{"id": "cases", "label": "Internal Affairs"},
		{"id": "press", "label": "Press"},
		{"id": "street", "label": "Street"},
	]:
		_btn(tabs, String(tab["label"]), _documents.bind(String(tab["id"])))
	_text(
		box,
		"These pages are assembled from the saved campaign record. Nothing here changes the week or adds a finding.",
		GREY,
		10
	)
	var documents: Array = StoryArchive.documents(c, filter)
	if documents.is_empty():
		_text(box, "No documents in this section yet.", GREY, 11)
	for document in documents:
		var card := _card(box)
		_text(card, String(document["date"]), GREY, 9)
		_text(card, String(document["title"]), INK, 12)
		_text(
			card,
			"FROM  %s   ·   TO  %s" % [String(document["from"]), String(document["to"])],
			GREY,
			9
		)
		var body := String(document["body"])
		var excerpt := body.substr(0, mini(body.length(), 150))
		if body.length() > 150:
			excerpt += "…"
		_text(card, excerpt, GREY, 10)
		_btn(card, "Read document", _open_document.bind(String(document["id"]), filter))
	var actions := _h(box)
	_btn(actions, "People & conversations", func(): _people())
	_btn(actions, "Campaign file", func(): _story_file())
	_btn(actions, "<  Back to board", func(): show_board())


func _open_document(
	document_id: String, filter := "all", return_person := "", return_topic := ""
) -> void:
	_documents(filter, document_id, return_person, return_topic)


## Poll bars, told apart by pattern: Kettering solid ink, Okonjo-Vale hatched, Pell outline.
class PollBars:
	extends Control
	var p

	func _init(pol) -> void:
		p = pol
		custom_minimum_size = Vector2(0, 66)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var w := size.x - 190.0
		var y := 4.0
		for c in Politics.CAND_ORDER:
			var sh: float = p.share(c)
			var r := Rect2(150, y, w * sh / 60.0, 14)
			match c:
				"kettering":
					draw_rect(r, Ink.INK)
				"okonjo":
					draw_rect(r, Ink.INK, false, 1.2)
					var x := r.position.x
					while x < r.end.x:
						draw_line(
							Vector2(x, r.end.y),
							Vector2(
								minf(x + 10, r.end.x),
								r.position.y + (14.0 * maxf(0.0, x + 10 - r.end.x) / 10.0)
							),
							Ink.INK,
							1.0
						)
						x += 5.0
				_:
					draw_rect(r, Ink.INK, false, 1.4)
			draw_string(
				font,
				Vector2(0, y + 12),
				Politics.CANDIDATES[c]["name"],
				HORIZONTAL_ALIGNMENT_LEFT,
				146,
				12,
				Ink.INK
			)
			draw_string(
				font,
				Vector2(r.end.x + 6, y + 12),
				"%d%%" % int(round(sh)),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12,
				Ink.INK
			)
			y += 21.0


## A standing bar for an ally: ink to their standing, the lost line marked.
class StandBar:
	extends Control
	var v := 50
	var lost := false

	func _init(val: int, is_lost: bool) -> void:
		v = val
		lost = is_lost
		custom_minimum_size = Vector2(0, 12)

	func _draw() -> void:
		var w := size.x
		draw_rect(Rect2(0, 2, w, 8), Ink.FLOOR)
		draw_rect(Rect2(0, 2, w * v / 100.0, 8), Ink.accent(0.85) if lost else Ink.DARK)
		var lx := w * Politics.LOST / 100.0
		draw_line(Vector2(lx, 0), Vector2(lx, 12), Ink.INK, 1.0)


## City Hall (v0.9): the polls, the allies and what each holds, the wards' trust.
func _city_hall() -> void:
	mode = "city_hall"
	_clear()
	var c = main.campaign
	var p = c.politics
	_title("CITY HALL  ·  week %d of %d" % [c.week(), c.WEEKS])
	_text(
		box,
		(
			"The election is at the end of week %d. The result determines who holds the office next."
			% Politics.ELECTION_WEEK
		),
		GREY,
		10
	)
	_text(box, "THE POLLS", INK, 12)
	box.add_child(PollBars.new(p))
	for cid in Politics.CAND_ORDER:
		var cd: Dictionary = Politics.CANDIDATES[cid]
		_text(box, "%s (%s): %s" % [cd["name"], cd["ticket"], cd["blurb"]], GREY, 10)
	_sep()
	_text(
		box, "ALLIES  ·  below the line an ally is lost, and what they hold goes with them", INK, 12
	)
	for a in Politics.ALLY_ORDER:
		var al: Dictionary = Politics.ALLIES[a]
		var v := _card(box)
		var is_lost: bool = p.lost(a)
		_text(
			v,
			"%s  ·  %s%s" % [al["name"], al["title"], "   ·   LOST" if is_lost else ""],
			Ink.accent(0.9) if is_lost else INK,
			12
		)
		v.add_child(StandBar.new(p.standing(a), is_lost))
		_text(
			v,
			(
				("Standing %d. Holds %s." % [p.standing(a), al["holds"]])
				+ ((" " + String(al["lost"])) if is_lost else "")
			),
			GREY,
			10
		)
	_sep()
	_text(
		box,
		"TRUST IN POLICE, BY WARD  ·  below 25, a ward's community group stops sharing tips",
		INK,
		12
	)
	var bb := ""
	for i in Situations.WARDS.size():
		var t: int = int(p.trust[i])
		var start: int = int(Situations.WARDS[i]["trust"])
		var d := t - start
		bb += (
			"%-10s %3d   %s\n"
			% [
				Situations.WARDS[i]["name"],
				t,
				("(%s%d since you took command)" % ["+" if d > 0 else "", d]) if d != 0 else ""
			]
		)
	_rich(box, "[code]" + bb + "[/code]")
	var stories: int = (
		p.pending.filter(func(x): return x["kind"] in ["story", "leak", "neglect"]).size()
	)
	var suits: Array = p.pending.filter(func(x): return x["kind"] == "lawsuit")
	var owed := 0
	for su in suits:
		owed += int(su["cost"])
	_text(
		box,
		(
			"%d public record item%s pending. %d lawsuit%s not yet settled%s."
			% [
				stories,
				"" if stories == 1 else "s",
				suits.size(),
				"" if suits.size() == 1 else "s",
				(" (about $%s)" % Department.money(owed)) if owed > 0 else ""
			]
		),
		INK,
		11
	)
	_btn(box, "<  Back to the board", func(): show_board())


## The election is over (v0.9).
func _election_night(lines: Array) -> void:
	var c = main.campaign
	var p = c.politics
	var e: Dictionary = p.result.get("ending", {})
	_title("ELECTION NIGHT  ·  THE CAMPAIGN IS FILED")
	_story_card(box, Story.current(c))
	var votes: Dictionary = p.result.get("votes", {})
	var bb := ""
	for cid in Politics.CAND_ORDER:
		bb += (
			"%s%s   %.1f%%%s\n"
			% [
				"[b]" if cid == e.get("winner", "") else "",
				Politics.CANDIDATES[cid]["name"],
				float(votes.get(cid, 0.0)),
				"[/b]" if cid == e.get("winner", "") else ""
			]
		)
	_rich(box, bb)
	var hv := _card(box)
	_text(hv, String(e.get("head", "")), Ink.accent(0.9) if not e.get("keep", false) else INK, 16)
	for ln in e.get("lines", []):
		_text(hv, String(ln), INK if ln != "FILED. NOT RESOLVED." else Ink.accent(0.9), 12)
	if c.run != null:
		var sc: Dictionary = Rogue.run_score(c)
		var sv := _card(box)
		_text(sv, "RUN SCORE  ·  %d" % int(sc["total"]), INK, 16)
		# EA_TASKS P1.F3: every line says what it is worth and why, so the player can see
		# which decisions made the number — the arithmetic, not a single grey line.
		for row in score_breakdown(sc):
			_text(sv, "%s   %+d   ·  %s" % [String(row["label"]), int(row["amount"]), String(row["why"])],
				Ink.accent(0.9) if int(row["amount"]) < 0 else INK, 11)
		_text(sv, "Total  %+d  ·  %s" % [int(sc["total"]), "the office is yours" if bool(sc["kept"]) else "out of office"],
			INK if bool(sc["kept"]) else Ink.accent(0.9), 12)
		_text(sv, "Seed %d. Inheritance: %s. Contracts: %d. Programs: %d." % [c.seed_val,
			String(Rogue.DOCTRINES.get(c.run.doctrine, {}).get("name", "none")), c.run.contracts.size(), c.run.programs_done.size()], GREY, 10)
	_front_page(box, p, Politics.ELECTION_WEEK)
	for ln2 in lines:
		_text(box, String(ln2), GREY, 10)
	_sep()
	var hb := _h(box)
	_btn(hb, "City Hall", func(): _city_hall())
	_btn(hb, "Roster", func(): _roster())
	_btn(hb, "Budget", func(): _budget())
	var hb3 := _h(box)
	_btn(hb3, "Campaign file", func(): _story_file())
	_btn(hb3, "<  Main menu", func(): main.go_title())
	_btn(hb3, "New run", func(): main.ops_new_campaign())


## EA_TASKS P1.F3: the run score as the lines a player can argue with. Each row carries
## what it is worth and why, so election night shows the arithmetic beside the ending
## instead of one grey line of plus and minus.
const SCORE_ROWS := {
	"successes": ["Operations that went right", "ten each"],
	"arrests": ["Arrests made", "three each"],
	"failures": ["Operations that went wrong", "eight off each"],
	"officers killed": ["Officers killed", "twenty-five off each"],
	"civilians killed": ["Civilians killed", "forty off each, thirty for a death in a crowd"],
	"civilians hit": ["Civilians struck by police", "twelve off each"],
	"suspects killed": ["Suspects killed", "six off each"],
	"excessive force": ["Force findings against the department", "ten off each"],
	"unattended": ["Calls left unattended", "three off each"],
	"the election": ["Kept the office", ""],
}
const SCORE_ORDER := ["successes", "arrests", "failures", "officers killed", "civilians killed",
	"civilians hit", "suspects killed", "excessive force", "unattended", "the election"]


static func score_breakdown(sc: Dictionary) -> Array:
	var parts: Dictionary = sc.get("parts", {})
	var rows: Array = []
	for k in SCORE_ORDER:
		var amount: int = int(parts.get(k, 0))
		if amount == 0:
			continue
		var spec: Array = SCORE_ROWS[k]
		rows.append({"key": k, "label": String(spec[0]), "amount": amount,
			"why": election_reason(sc) if k == "the election" else String(spec[1])})
	if rows.is_empty():
		rows.append({"key": "", "label": "Nothing worth counting", "amount": 0, "why": "no operation, no case, no call"})
	return rows


## Why the election paid what it paid (P1.F2): the clean-record test, in words.
static func election_reason(sc: Dictionary) -> String:
	var l: Dictionary = sc.get("clean_line", {})
	var needs: Dictionary = l.get("needs", {})
	return "clean record: %d of %d officers killed, %d of %d civilians, %d of %d findings" % [
		int(l.get("officers_killed", 0)), int(needs.get("officers_killed", 2)),
		int(l.get("civilians_killed", 0)), int(needs.get("civilians_killed", 6)),
		int(l.get("findings", 0)), int(needs.get("findings", 6))]


## The money, morale and open cases at a glance (v0.8.5).
## Next week's roster against this week's calls (EA_TASKS P1.C2), so a shrinking
## department is seen a week before it costs a call.
func _roster_strip(parent: Control, c) -> void:
	var o: Dictionary = c.roster_outlook()
	var parts: Array = []
	if int(o["back"]) > 0:
		parts.append("%d back from injury" % int(o["back"]))
	if int(o["graduates"]) > 0:
		parts.append("%d from the academy" % int(o["graduates"]))
	if int(o["returning"]) > 0:
		parts.append("%d back from courses or suspension" % int(o["returning"]))
	if int(o["to_course"]) > 0:
		parts.append("%d leaving for a queued course" % int(o["to_course"]))
	var txt := "NEXT WEEK  ·  %d fit%s." % [int(o["fit"]), (" (" + ", ".join(parts) + ")") if not parts.is_empty() else ""]
	if int(o["open"]) > 0:
		txt += "  This week's %d open call%s want %d between them." % [int(o["open"]), "" if int(o["open"]) == 1 else "s", int(o["want"])]
	if bool(o["short"]):
		txt += "  Below %d fit, calls go unattended: hire, or bring people back." % c.ROSTER_FLOOR
	_text(parent, txt, Ink.accent(0.9) if bool(o["short"]) else INK, 12)


func _dept_strip(parent: Control) -> void:
	var d = main.campaign.dept
	var v := _card(parent)
	var red: bool = d.frozen()   # P1.D2: the freeze is the overdraft limit, not zero
	_text(
		v,
		(
			"ACCOUNT  $%s%s   ·   allocation $%s a week   ·   payroll $%s"
			% [
				Department.money(d.balance),
				"  (FROZEN)" if red else "",
				Department.money(d.allocation),
				Department.money(d.payroll())
			]
		),
		Ink.accent(0.9) if red else INK,
		12
	)
	var nc: int = d.open_cases().size()
	_text(
		v,
		(
			"Morale %d%s   ·   %d internal affairs case%s open"
			% [
				d.morale,
				" (low: more stress in every operation)" if d.morale < Courses.MORALE0 else "",
				nc,
				"" if nc == 1 else "s"
			]
		),
		GREY,
		11
	)

	if nc > 0:
		_text(v, Department.triage_line(d.cases, d.week), Ink.accent(0.85) if int(Department.case_triage(d.cases, d.week)["urgent"]) > 0 else GREY, 10)
const STATUS_WORDS := {
	"injured": "out injured until week %d",
	"training": "on a course until week %d",
	"academy": "at the academy until week %d",
	"suspended": "suspended until week %d"
}


func _status_of(r: Dictionary, busy: Dictionary) -> String:
	if STATUS_WORDS.has(r["status"]):
		var s: String = STATUS_WORDS[r["status"]] % int(r["out_until"])
		if r["status"] == "injured" and String(r.get("course", "")) != "":
			s += ", on a classroom course"
		return s
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


## EA_TASKS P1.C4: the standing order. The chief sets how many officers to keep on the
## books; at the turn of each week the academy takes recruits towards it while the
## four-week forecast can carry them. Visible here, changed or cancelled here.
func _standing_order_card(d) -> void:
	var v := _card(box)
	var k: int = int(d.keep_on_books)
	var head := (
		"STANDING ORDER  ·  keep %d on the books (%d now)" % [k, d.on_books()]
		if k > 0
		else "STANDING ORDER  ·  none (%d on the books)" % d.on_books()
	)
	_text(v, head, INK, 12)
	_text(
		v,
		"At the turn of each week the academy enrols recruits (two at most) until the books reach the number, while the four-week forecast stays in the black after their academy place and pay. A recruit reports two weeks later.",
		GREY,
		10
	)
	if k > 0 and d.on_books() < k:
		var why: String = d.standing_blocked()
		_text(v, ("Next turn: %s." % why) if why != "" else "Next turn: the academy will take recruits.", Ink.accent(0.9) if why != "" else GREY, 10)
	var h := _h(v)
	_btn(h, "-", func(): _set_standing(maxi(0, k - 1) if k > 0 else 0))
	_btn(h, "+", func(): _set_standing(maxi(k + 1, d.on_books() + 1) if k == 0 else k + 1))
	if k > 0:
		_btn(h, "Cancel the order", func(): _set_standing(0))


func _set_standing(n: int) -> void:
	main.campaign.dept.keep_on_books = n
	flash = ("Standing order: keep %d on the books." % n) if n > 0 else "Standing order cancelled."
	main.ops_dept_changed()
	_roster()


func _roster() -> void:
	mode = "roster"
	_clear()
	var d = main.campaign.dept
	_title("ROSTER  ·  week %d" % d.week)
	_dept_strip(box)
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	_standing_order_card(d)
	_applicants()
	_sep()
	_text(box, "Click an officer to open their file: training, and dismissal.", GREY, 10)
	var order: Array = d.officers.filter(
		func(r): return r["status"] not in ["dead", "fired", "resigned"]
	)
	order.sort_custom(
		func(a, b):
			var ra: int = Orders.rank_i(a)
			var rb: int = Orders.rank_i(b)
			if ra != rb:
				return ra > rb
			return int(a["xp"]) > int(b["xp"])
	)
	var busy: Dictionary = main.campaign.committed()
	for r in order:
		var st: String = _status_of(r, busy)
		var oid: String = r["id"]
		var b := _btn(
			box,
			(
				"%s %s  ·  %d yr  ·  %s %d xp  ·  J %d  ·  $%s/wk  ·  %s"
				% [
					r["rank"],
					r["name"],
					int(r.get("years", 0)),
					Habits.EXP_NAMES[int(r["exp"])],
					int(r["xp"]),
					int(r["judgment"]),
					Department.money(Courses.pay(r)),
					st
				]
			),
			func():
				roster_open = "" if roster_open == oid else oid
				_roster()
		)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(10, 0)
		b.add_theme_font_size_override("font_size", 11)
		b.tooltip_text = UI.officer_file(r)
		if r["status"] != "active":
			b.add_theme_color_override("font_color", GREY)
		if roster_open == oid:
			_officer_card(r, busy)
	var gone: Array = d.officers.filter(
		func(r): return r["status"] in ["dead", "fired", "resigned"]
	)
	if not gone.is_empty():
		_text(
			box,
			(
				"No longer serving: "
				+ ", ".join(
					gone.map(
						func(r): return "%s %s (%s)" % [r["rank"], r["name"], _status_of(r, {})]
					)
				)
			),
			GREY,
			10
		)
	_btn(box, "<  Back to the board", func(): show_board())


func _officer_card(r: Dictionary, busy: Dictionary) -> void:
	var d = main.campaign.dept
	var v := _card(box)
	var good: Array = r["good"]
	_text(
		v,
		(
			"%d good habits%s. Personality: %s. Trauma %.1f. Courses: %s."
			% [
				good.size(),
				", tactical certified" if r.get("tactical", false) else "",
				String(r["personality"]) if r["personality"] != "" else "none",
				float(r["trauma"]),
				(
					", ".join(r.get("courses", []).map(func(c): return Courses.COURSES[c]["name"]))
					if not r.get("courses", []).is_empty()
					else "none"
				)
			]
		),
		INK,
		11
	)
	if r["status"] in ["active", "injured", "training", "academy"]:
		var cur: String = String(r.get("course", ""))
		var q: Array = r.get("queue", [])
		_text(
			v,
			(
				"TRAINING%s%s"
				% [
					(
						(
							"  ·  on the %s course until week %d"
							% [
								Courses.COURSES[cur]["name"].to_lower(),
								int(r.get("course_until", 0))
							]
						)
						if cur != ""
						else ""
					),
					(
						(
							"  ·  queued: "
							+ ", ".join(
								q.map(func(c): return Courses.COURSES[c]["name"].to_lower())
							)
						)
						if not q.is_empty()
						else ""
					)
				]
			),
			GREY,
			10
		)
		for qc in q:
			var hq := _h(v)
			_lab(hq, "queued: %s" % Courses.COURSES[qc]["name"], GREY, 10)
			var qid: String = qc
			_btn(
				hq,
				"drop",
				func():
					main.campaign.dept.unqueue(r, qid)
					main.ops_dept_changed()
					_roster()
			)
		for cid in Courses.COURSE_ORDER:
			if cid == "uof":
				continue
			var c: Dictionary = Courses.COURSES[cid]
			var classroom: bool = bool(c.get("classroom", false))
			var can_now: bool = (
				cur == ""
				and not busy.has(r["id"])
				and (r["status"] == "active" or (r["status"] == "injured" and classroom))
			)
			var why: String = Courses.blocked(r, cid)
			if why == "" and can_now and d.frozen():
				why = "below the overdraft limit (it can still be queued)"
				can_now = false
			var h := _h(v)
			# P1.D1: price this course into the four-week forecast for the button label.
			var cost_now: int = d.course_cost(cid) if can_now else 0
			var worst: Dictionary = Department.forecast_worst(d.forecast_after("course", cost_now)) if can_now else {}
			var effect := ""
			if not worst.is_empty():
				effect = "  → week %d: -$%s" % [int(worst["week"]), Department.money(-int(worst["balance"]))]
			var rr: Dictionary = r
			var ccid: String = cid
			var cb := _btn(
				h,
				(
					"%s: %s  $%s  %dw%s%s"
					% [
						"Send" if can_now else "Queue",
						c["name"],
						Department.money(d.course_cost(cid)),
						d.course_weeks(cid),
						("  (classroom)" if classroom else ""),
						effect
					]
				),
				func():
					if not worst.is_empty():
						_confirm(
							"COURSE INTO THE RED?",
							(
								"%s costs $%s. On the four-week forecast, week %d goes to -$%s. Commit anyway?"
								% [c["name"], Department.money(cost_now), int(worst["week"]), Department.money(-int(worst["balance"]))]
							),
							func(): _train(rr, ccid),
							func(): _roster()
						)
					else:
						_train(rr, ccid)
			)
			cb.disabled = (
				why != ""
				and not (why.begins_with("below the overdraft limit") and q.size() < Courses.QUEUE_MAX)
			)
			if q.size() >= Courses.QUEUE_MAX and not can_now:
				cb.disabled = true
				why = "queue full"
			cb.add_theme_font_size_override("font_size", 11)
			var tip: String = String(c["desc"])
			if cid == "judgment":
				tip += (
					"\nAt judgment %d the base chance of misjudging a civilian is %.2f%% per judgment (before stress, night, phones and range); at %d it is %.2f%%."
					% [
						int(r["judgment"]),
						Courses.misjudge_term(int(r["judgment"])) * 100.0,
						mini(90, int(r["judgment"]) + 6),
						Courses.misjudge_term(mini(90, int(r["judgment"]) + 6)) * 100.0
					]
				)
			if not can_now and why == "":
				tip += "\nQueued courses start themselves when the officer can take them, and are paid for then."
			cb.tooltip_text = tip + (("\nNot now: " + why) if why != "" else "")
			if why != "" and cb.disabled:
				_lab(h, why, GREY, 10)
		if r["status"] == "active" and cur == "" and not busy.has(r["id"]):
			var hc := _h(v)
			var coh := _btn(
				hc, "Refresher with a bonded cohort (3+ at 3/4 cost)", func(): _cohort(r)
			)
			coh.add_theme_font_size_override("font_size", 11)
			coh.tooltip_text = "Send this officer and up to three available colleagues he has served with on the close-quarters refresher together: three or more pay three quarters each, and every pair gains a bond (squad cohesion)."
	var h2 := _h(v)
	var fb := _btn(
		h2,
		"Dismiss ($%s severance)" % Department.money(Courses.pay(r) * Courses.SEVERANCE_WEEKS),
		func(): _dismiss(r)
	)
	fb.add_theme_font_size_override("font_size", 11)
	_lab(h2, "the union remembers: morale -6", GREY, 10)


func _train(r: Dictionary, cid: String) -> void:
	var res: Dictionary = main.campaign.dept.enrol_or_queue(r, cid)
	if bool(res.get("ok", false)):
		flash = (
			(
				"%s %s is on the %s course."
				% [r["rank"], r["name"], Courses.COURSES[cid]["name"].to_lower()]
			)
			if res.get("mode", "") == "now"
			else (
				"%s queued for %s %s: it starts when he can take it."
				% [Courses.COURSES[cid]["name"], r["rank"], r["name"]]
			)
		)
	else:
		flash = "Not possible: " + String(res.get("why", "")) + "."
	main.ops_dept_changed()
	_roster()


## The cohort refresher (Q9): this officer and the available colleagues he is most
## bonded with, refresher-trained together at the cohort rate.
func _cohort(r: Dictionary) -> void:
	var d = main.campaign.dept
	var busy: Dictionary = main.campaign.committed()
	var mates: Array = d.officers.filter(
		func(x):
			return (
				x["id"] != r["id"]
				and x["status"] == "active"
				and String(x.get("course", "")) == ""
				and not busy.has(x["id"])
				and Courses.blocked(x, "cqb") == ""
			)
	)
	mates.sort_custom(
		func(a, b):
			return (
				d.bond(r["id"], a["id"]) > d.bond(r["id"], b["id"])
				if d.bond(r["id"], a["id"]) != d.bond(r["id"], b["id"])
				else int(a["xp"]) > int(b["xp"])
			)
	)
	var group: Array = [r] + mates.slice(0, 3)
	var res: Dictionary = d.enrol_cohort(group)
	if bool(res.get("ok", false)):
		flash = (
			"Cohort refresher: %s ($%s%s)."
			% [
				", ".join(res["started"]),
				Department.money(int(res["cost"])),
				", at the cohort rate" if res["discounted"] else ""
			]
		)
	else:
		flash = "No cohort: " + String(res.get("why", "")) + "."
	main.ops_dept_changed()
	_roster()


## This week's applicants (Q2): everyone who applied, warts and all — judgment,
## temper and integrity where the chief can weigh them before anyone is hired.
func _applicants() -> void:
	var d = main.campaign.dept
	var pool: Array = d.applicants_now()
	_text(
		box,
		(
			"APPLICANTS  ·  week %d%s"
			% [
				d.week,
				("  (frozen: below the -$%s overdraft limit)" % Department.money(-d.OVERDRAFT_LIMIT)) if d.frozen()
				else (("  (overdraft: -$%s, interest accrues weekly)" % Department.money(-d.balance)) if d.balance < 0 else "")
			]
		),
		INK,
		12
	)
	_emergency_card(d)
	if pool.is_empty():
		_text(
			box,
			"Nobody left to hire this week: the pool was taken from, or walked. A fresh pool applies next week.",
			GREY,
			10
		)
		return
	_text(
		box,
		"Hire one and the rest walk. A recruit spends two weeks at the academy; a lateral hire has years elsewhere and reports at once. Whoever nobody hires walks at the end of the week.",
		GREY,
		10
	)
	for r in pool:
		var v := _card(box)
		var who: String = (
			"%s %s  ·  Patrol  ·  %s"
			% [
				r["rank"],
				r["name"],
				(
					(
						"lateral, %d years elsewhere, %s"
						% [int(r.get("years", 0)), Habits.EXP_NAMES[int(r["exp"])]]
					)
					if r.get("lateral", false)
					else "recruit (academy, two weeks)"
				)
			]
		)
		_text(v, who, INK, 12).tooltip_text = UI.officer_file(r)
		var traits: Array = []
		for tr in r.get("traits", []):
			traits.append(String(Habits.trait_info(tr).get("name", tr)))
		var bad: Array = []
		for b in r.get("bad_traits", []):
			bad.append(String(Habits.bad_info(b).get("name", b)))
		var plus: Array = []
		for q in r["ech"].get("plus", []):
			plus.append("+" + String(q))
		for q2 in r["ech"].get("minus", []):
			plus.append("-" + String(q2))
		_text(
			v,
			(
				"Judgment %d  ·  temper %d  ·  integrity %d%s%s%s"
				% [
					int(r["judgment"]),
					int(r["temper"]),
					int(r["integrity"]),
					("  ·  " + ", ".join(traits)) if not traits.is_empty() else "",
					("  ·  " + "  ".join(plus)) if not plus.is_empty() else "",
					(
						(
							"  ·  personality: %s (%s)"
							% [String(r["personality"]).to_lower(), ", ".join(bad)]
						)
						if r["personality"] != ""
						else ""
					)
				]
			),
			GREY,
			10
		)
		var h := _h(v)
		var rec: Dictionary = r
		# P1.D1: the four-week forecast with this hire priced in, so the button says
		# which week goes into the red before the chief commits — and asks first.
		var fc: Array = d.forecast_after("hire", Department.applicant_cost(r), Courses.pay(r))
		var worst := Department.forecast_worst(fc)
		var deficit_text := ""
		if not worst.is_empty():
			deficit_text = " — week %d goes to -$%s" % [int(worst["week"]), Department.money(-int(worst["balance"]))]
		# B6: this was a multi-line lambda passed straight into _btn(), with _confirm()'s
		# own call nested in its else branch. Godot 4.7 rejects that shape ("Unindent doesn't
		# match the previous indentation level"), which stopped ops_ui.gd, and with it main.gd,
		# from loading at all. Built as locals first, it parses.
		var hire_red_text := ""
		if not worst.is_empty():
			hire_red_text = (
				"Hiring %s %s costs $%s now and +$%s a week in payroll. On these numbers week %d goes to -$%s. Inside the council's overdraft that is allowed (with weekly interest); past the -$%s limit hiring freezes. Sign anyway?"
				% [
					rec["rank"], rec["name"], Department.money(Department.applicant_cost(rec)),
					Department.money(Courses.pay(rec)), int(worst["week"]),
					Department.money(-int(worst["balance"])), Department.money(-d.OVERDRAFT_LIMIT)
				]
			)
		var on_hire := func():
			if worst.is_empty():
				_hire_applicant(rec)
			else:
				_confirm("HIRE INTO THE RED?", hire_red_text, func(): _hire_applicant(rec), func(): _roster())
		var hb := _btn(
			h,
			(
				"Hire  ($%s now, payroll +$%s a week)%s"
				% [Department.money(Department.applicant_cost(r)), Department.money(Courses.pay(r)), deficit_text]
			),
			on_hire
		)
		hb.disabled = d.frozen()
		hb.tooltip_text = String(UI.officer_file(r)) + (("\n" + deficit_text.trim_prefix(" — ")) if deficit_text != "" else "")


## EA_TASKS P1.C3: an experienced officer from a neighbouring force, on duty this week,
## at twice a lateral's signing cost -- the lever for a roster that is short now, not in
## two weeks. One a week; frozen with the rest of hiring when the account is in the red.
func _emergency_card(d) -> void:
	var r: Dictionary = d.emergency_candidate()
	var v := _card(box)
	_text(v, "EMERGENCY LATERAL  ·  on duty this week", Ink.accent(0.9), 12)
	_text(
		v,
		(
			"%s %s  ·  %d years with a neighbouring force, %s  ·  judgment %d, temper %d, integrity %d%s"
			% [
				r["rank"],
				r["name"],
				int(r.get("years", 0)),
				Habits.EXP_NAMES[int(r["exp"])],
				int(r["judgment"]),
				int(r["temper"]),
				int(r["integrity"]),
				("  ·  personality: " + String(r["personality"]).to_lower()) if r["personality"] != "" else ""
			]
		),
		GREY,
		10
	).tooltip_text = UI.officer_file(r)
	var h := _h(v)
	var why: String = d.emergency_blocked()
	var b := _btn(
		h,
		(
			"Sign  ($%s now, payroll +$%s a week)"
			% [Department.money(Department.emergency_cost(r)), Department.money(Courses.pay(r))]
		),
		func(): _sign_emergency()
	)
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "Twice a lateral's signing cost; no academy, no wait."
	if why != "":
		_text(v, "Not now: %s." % why, GREY, 10)


func _sign_emergency() -> void:
	var got: Dictionary = main.campaign.dept.sign_emergency()
	flash = (
		("Signed %s %s as an emergency lateral: on duty this week." % [got["rank"], got["name"]])
		if not got.is_empty()
		else "Not now: %s." % main.campaign.dept.emergency_blocked()
	)
	main.ops_dept_changed()
	_roster()


func _hire_applicant(r: Dictionary) -> void:
	var got: Dictionary = main.campaign.dept.choose_applicant(r)
	flash = (
		("Hired %s %s." % [got["rank"], got["name"]])
		if not got.is_empty()
		else "Hiring is frozen while the account is in the red."
	)
	main.ops_dept_changed()
	_roster()


func _dismiss(r: Dictionary) -> void:
	main.campaign.dept.fire(r)
	roster_open = ""
	flash = "%s %s has been dismissed." % [r["rank"], r["name"]]
	main.ops_dept_changed()
	_roster()


## The account: the next four weeks as far as they are knowable, the grant, and
## this week and the last few, line by line (v0.8.5, Q8).
func _budget() -> void:
	mode = "budget"
	_clear()
	var d = main.campaign.dept
	_title("BUDGET  ·  week %d" % d.week)
	_dept_strip(box)
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	_text(
		box,
		"The city's allocation comes in and the payroll goes out at the end of each week. Overtime (a callout plus time on target; static duty at a rally at half rate), restocking, kit, hiring, training, medical bills and death benefits come out as they happen. In the red, hiring, training and new kit are frozen.",
		GREY,
		10
	)
	_forecast()
	_grant_row()
	var bb := ""
	var shown := 0
	for wk in range(d.week, maxi(0, d.week - 6), -1):
		var rows: Array = d.ledger.filter(func(le): return int(le["week"]) == wk)
		if rows.is_empty():
			continue
		var net := 0
		for le in rows:
			net += int(le["amount"])
		bb += (
			"[b]WEEK %d[/b]   net %s$%s\n"
			% [wk, "+" if net >= 0 else "-", Department.money(absi(net))]
		)
		for le in rows:
			var a: int = int(le["amount"])
			bb += (
				(
					"   %s$%s   %s\n"
					% ["+" if a >= 0 else "-", Department.money(absi(a)), le["item"]]
				)
				if a >= 0
				else (
					"   [color=#b31f26]-$%s[/color]   %s\n"
					% [Department.money(absi(a)), le["item"]]
				)
			)
		shown += 1
	if shown == 0:
		bb = "Nothing spent yet this campaign."
	_rich(box, bb)
	_btn(box, "<  Back to the board", func(): show_board())


## Four weeks of the account on today's numbers (Q8): the allocation against
## today's payroll and the lawsuits already filed, so a freeze that is already
## on the books arrives announced. Overtime, wounds and settlements nobody has
## filed yet are not in it, and it says so.
func _forecast() -> void:
	var d = main.campaign.dept
	var v := _card(box)
	_text(v, "THE NEXT FOUR WEEKS (on today's payroll)", INK, 12)
	var worst := 0
	for row in main.campaign.forecast(4):
		var suits: int = int(row["lawsuits"])
		var bal: int = int(row["balance"])
		if bal < 0 and worst == 0:
			worst = int(row["week"])
		_text(
			v,
			(
				"Week %d:  +$%s allocation  -$%s payroll%s    ->    $%s"
				% [
					int(row["week"]),
					Department.money(int(row["allocation"])),
					Department.money(int(row["payroll"])),
					("  -$%s a lawsuit settles" % Department.money(suits)) if suits > 0 else "",
					Department.money(bal)
				]
			),
			Ink.accent(0.9) if bal < 0 else INK,
			11
		)
	if worst > 0:
		_text(
			v,
			(
				"On these numbers the account is in the red at week %d. Interest accrues weekly while it is below zero, and past the -$%s overdraft limit hiring, training and new kit freeze. Spend less, settle nothing new, or ask the committee (below) before it lands."
				% [worst, Department.money(-d.OVERDRAFT_LIMIT)]
			),
			Ink.accent(0.9),
			10
		)
	var qc: int = d.queued_cost()
	if qc > 0:
		_text(
			v,
			(
				"Not in the table: $%s of queued courses, paid when each starts."
				% Department.money(qc)
			),
			GREY,
			10
		)
	_text(
		v,
		"Not knowable, so not in the table: next week's overtime, wounds, and any lawsuit not yet filed.",
		GREY,
		10
	)


## The grant (Q8): the one way to bring money in, while the budget chair is still
## answering — and asking spends some of that goodwill.
func _grant_row() -> void:
	var p = main.campaign.politics
	var v := _card(box)
	_text(v, "A CITY GRANT", INK, 12)
	var why: String = p.can_grant(main.campaign.dept.week)
	var h := _h(v)
	var gb := _btn(
		h, "Apply for a grant ($%s)" % Department.money(Politics.GRANT_AMOUNT), func(): _grant()
	)
	gb.disabled = why != ""
	gb.tooltip_text = (
		"One-time money from the budget committee. Needs Marguerite Duff at %d standing or better; asking costs %d of it, and the committee will not be asked again for %d weeks."
		% [Politics.GRANT_STANDING, Politics.GRANT_FAVOUR, Politics.GRANT_COOLDOWN]
	)
	if why != "":
		_lab(h, why, GREY, 10)
	else:
		_lab(h, "Duff is at %d: she would sign it." % p.standing("council"), GREY, 10)


func _grant() -> void:
	var res: Dictionary = main.campaign.politics.apply_grant(
		main.campaign.dept.week, main.campaign.dept
	)
	flash = String(res.get("line", ""))
	main.ops_dept_changed()
	_budget()


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
	_text(
		box,
		"A finding tied to an officer—or an order left broken—opens a case. Clear it, order a use-of-force review, suspend the officer without pay for two weeks, or dismiss them. A case without a decision lapses after three weeks. The union watches discipline; the coalition and district attorney watch the cases you clear.",
		GREY,
		10
	)
	var triage := Department.case_triage(d.cases, d.week)
	_text(box, "WEEKLY TRIAGE  ·  %d open  ·  %d grave  ·  %d video  ·  %d due before lapse  ·  %d untested" % [triage["open"], triage["grave"], triage["video"], triage["urgent"], triage["untested"]], INK, 11)
	var filters := _h(box)
	for f in [["all", "All"], ["grave", "Grave"], ["video", "Video"], ["due", "Due soon"]]:
		var key: String = f[0]
		var label: String = f[1]
		var fb := _btn(filters, ("[%s]" if case_filter == key else "%s") % label, func(): case_filter = key; _cases())
		fb.tooltip_text = "Sort by severity, then evidence. Filters never decide a case."
		fb.custom_minimum_size = Vector2(70, 0)
	var open: Array = Department.sorted_open_cases(d.cases, d.week)
	var total_open := open.size()
	match case_filter:
		"grave": open = open.filter(func(c): return Department.CASE_ORDER.find(c.get("kind", "")) >= 0 and Department.CASE_ORDER.find(c.get("kind", "")) <= 1)
		"video": open = open.filter(func(c): return c.get("strength", "") == "video")
		"due": open = open.filter(func(c): return Department.case_is_urgent(c, d.week))
	if open.is_empty():
		_text(box, "No open cases." if total_open == 0 else "No cases match this filter.", INK, 12)
	elif case_filter != "all":
		_text(box, "Showing %d of %d open cases; each still requires its own decision." % [open.size(), total_open], GREY, 10)
	for c in open:
		var r: Dictionary = d.get_officer(c["officer"])
		var v := _card(box)
		_text(
			v,
			(
				"%s  ·  %s %s  ·  week %d"
				% [c["id"], r.get("rank", ""), r.get("name", "?"), int(c["week"])]
			),
			INK,
			13
		)
		_text(
			v,
			(
				"%s: %s (%s). Evidence: %s."
				% [
					Department.CASE_KINDS.get(c["kind"], c["kind"]),
					c["text"],
					c["place"],
					c["strength"]
				]
			),
			INK,
			11
		)
		var severity: int = Department.CASE_ORDER.find(c.get("kind", ""))
		var badges: Array = []
		if severity >= 0 and severity <= 1:
			badges.append("GRAVE")
		if Department.case_is_urgent(c, d.week):
			badges.append("DUE BEFORE LAPSE")
		if c.get("strength", "") == "video":
			badges.append("VIDEO")
		if not badges.is_empty():
			_text(v, "TRIAGE  ·  " + "  ·  ".join(badges), Ink.accent(0.9), 10)
		_text(v, "Judgment %d  ·  integrity %d  ·  %d earlier case%s" % [int(r.get("judgment", 0)), int(r.get("integrity", 0)),
			d.cases.filter(func(x): return x["officer"] == c["officer"] and x["status"] == "closed").size(),
			"" if d.cases.filter(func(x): return x["officer"] == c["officer"] and x["status"] == "closed").size() == 1 else "s"], GREY, 10)
		var stmt: String = String(c.get("statement", ""))
		if stmt == "disagrees":
			_text(
				v,
				(
					"The officer's statement does not match the %s. Clearing this reads as a cover-up, and it is the kind of detail that leaks."
					% ("body camera" if c["strength"] == "video" else "witnesses")
				),
				Ink.accent(0.9),
				10
			)
		elif stmt == "matches":
			_text(v, "The officer's statement matches the record.", GREY, 10)
		var wit: Dictionary = d.get_officer(String(c.get("witness", "")))
		var tst: String = String(c.get("testimony", ""))
		if not wit.is_empty() and tst in ["corroborates", "contradicts"]:
			_text(
				v,
				(
					"%s %s, who was there, %s the record in a statement."
					% [
						wit.get("rank", ""),
						wit.get("name", ""),
						"corroborates" if tst == "corroborates" else "contradicts"
					]
				),
				GREY,
				10
			)
		var h := _h(v)
		var cid: String = c["id"]
		_btn(h, "Clear", func(): _decide(cid, "clear"))
		var rb := _btn(
			h,
			"Review ($%s)" % Department.money(int(Courses.COURSES["uof"]["cost"])),
			func(): _decide(cid, "retrain")
		)
		rb.disabled = (
			r.get("status", "") not in ["active", "injured"]
			or d.frozen()
			or main.campaign.committed().has(c["officer"])
		)
		rb.tooltip_text = "A classroom course: a wounded officer can take the review while recovering."
		if main.campaign.committed().has(c["officer"]):
			rb.tooltip_text = "Committed to an operation this week: the review can be ordered from next week (the case stays open three weeks)."
		elif d.frozen():
			rb.tooltip_text = "The account is in the red: no courses until it is back above zero."
		elif r.get("status", "") not in ["active", "injured"]:
			rb.tooltip_text = "Not available: %s." % String(r.get("status", "away"))
		_btn(h, "Suspend", func(): _decide(cid, "suspend"))
		_btn(h, "Dismiss", func(): _decide(cid, "fire"))
	var closed: Array = d.cases.filter(func(c): return c["status"] == "closed")
	if not closed.is_empty():
		var bb := ""
		for k in range(closed.size() - 1, maxi(-1, closed.size() - 13), -1):
			var c2: Dictionary = closed[k]
			var r2: Dictionary = d.get_officer(c2["officer"])
			bb += (
				"%s  %s  ·  %s  ·  %s\n"
				% [
					c2["id"],
					r2.get("name", "?"),
					Department.CASE_KINDS.get(c2["kind"], c2["kind"]).to_lower(),
					c2["decision"]
				]
			)
		_text(box, "CLOSED", GREY, 10)
		_rich(box, bb)
	_btn(box, "<  Back to the board", func(): show_board())


func _decide(cid: String, decision: String) -> void:
	var d = main.campaign.dept
	for c in d.cases:
		if c["id"] == cid:
			var ln: String = main.campaign.decide_case(c, decision)
			flash = ln if ln != "" else "That could not be done this week."
	main.ops_dept_changed()
	_cases()


# ================================================================== briefing, force, orders
func _guide() -> void:
	if not guide_active or guide_dismissed or not bool(Settings.get_v("tips")):
		return
	var v := _card(box)
	var step := tab + 1
	var headings := ["BRIEFING", "FORCE", "ORDERS"]
	_text(v, "FIRST OPERATION  ·  %d/4  ·  %s" % [step, headings[clampi(tab, 0, 2)]], Ink.accent(0.9), 12)
	var copy := [
		"Read what is known and what is only estimated. The readiness range is a planning index, not a win chance. When you have the briefing, continue to Force.",
		"Assign officers to squads and check their kit. Suggest a plan is a starting point, not an order. Continue to Orders when the force is ready.",
		"Give each squad an objective and any constraints its leader can afford. Check the readiness range again, then choose RUN below. The operation itself cannot be rewound.",
	]
	_text(v, copy[clampi(tab, 0, 2)], INK, 11)
	var h := _h(v)
	if tab < 2:
		_btn(h, "Next: %s  >" % headings[tab + 1].capitalize(), func(): _tab(tab + 1))
	_btn(h, "Skip guide", func(): guide_dismissed = true; guide_active = false; show_plan())


func _guide_debrief() -> void:
	if not guide_active or guide_dismissed or not bool(Settings.get_v("tips")):
		return
	var v := _card(box)
	_text(v, "FIRST OPERATION  ·  4/4  ·  DEBRIEF", Ink.accent(0.9), 12)
	_text(v, "Read the score arithmetic, then click a timeline event to seek the replay. The department consequences and any IA cases are below. Back to the board finishes the guide.", INK, 11)


func _risk_for(s: Dictionary) -> Dictionary:
	return Risk.assess(s, main.plan, _recs(main.campaign.plan_members(s)))


func _risk_card(s: Dictionary, full := true) -> void:
	var risk := _risk_for(s)
	var v := _card(box)
	_text(v, risk["label"], INK, 12)
	_text(v, risk["note"], GREY, 10)
	_text(v, "ASSUMPTIONS  ·  " + "  ·  ".join(risk["assumptions"]), GREY, 10)
	if full:
		if not risk["known"].is_empty():
			_text(v, "KNOWN  ·  " + "  ·  ".join(risk["known"]), INK, 10)
		if not risk["unknown"].is_empty():
			_text(v, "STILL UNCERTAIN  ·  " + ", ".join(risk["unknown"]), Ink.accent(0.85), 10)


func show_plan() -> void:
	mode = "plan"
	root.visible = true
	_clear()
	var s: Dictionary = main.cur_sit
	_title(s["title"], 15)
	if main.campaign.week() == 1 and int(main.campaign.dept.ops_run) == 0 and bool(Settings.get_v("tips")) and not guide_dismissed:
		guide_active = true
	_guide()
	var tabs := _h(box)
	var select_tab := func(on: bool, tab_i: int) -> void:
		if on:
			_tab(tab_i)
	for i in 3:
		var b := _btn(tabs, ["1 Briefing", "2 Force", "3 Orders"][i], select_tab.bind(i), true)
		b.set_pressed_no_signal(i == tab)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sep()
	if flash != "":
		_text(box, flash, INK, 11)
		flash = ""
	if bool(Settings.get_v("tips")) and main.campaign.week() <= 2:
		_text(
			box,
			[
				"Tip: confirmed facts and estimates are marked separately. Canvassing adds two tips, but takes an officer for the week.",
				"Tip: each officer's assignment sets their squad. The highest rank leads; experience limits how many orders the squad can carry out. Kit comes from the department account.",
				"Tip: set objectives and constraints for each squad, then place them on the map. The plan is a proposal. The rooms are still unknown."
			][tab],
			GREY,
			10
		)
	if tab == 1:
		var d = main.campaign.dept
		_text(
			box,
			(
				"Account $%s%s. New kit is bought at cost; kit handed back sells for half."
				% [Department.money(d.balance), " (frozen: no new kit)" if d.frozen() else ""]
			),
			Ink.accent(0.9) if d.frozen() else GREY,
			10
		)
	if tab > 0:
		_risk_card(s, false)
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
	if bool(Settings.get_v("veteran")):
		_lab(hb, "Veteran chief — the plan is yours.", GREY, 10)  # Q4: no Suggest at this difficulty
	else:
		_btn(hb, "Suggest a plan", func(): main.ops_suggest())
	var run := _btn(
		box, "RUN   >   %d officer%s" % [n, "" if n == 1 else "s"], func(): main.ops_run()
	)
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
	_text(
		box,
		(
			"On a gang raid the suggested plan proposes the Entry kit for the officers going in (see the Force tab); otherwise suggested plans use the officers' current equipment. Issue or change kit on the Force tab."
			if s["type"] in Autoplan.KIT_PROPOSAL_TYPES
			else "Suggested plans use the officers' current equipment. Issue or change kit on the Force tab."
		),
		GREY,
		11
	)
	if s.has("site_name"):
		_text(box, "%s  ·  %s. The tactical layout is a schematic proxy, not a surveyed floor plan." % [s["site_name"], s.get("site_archetype", "site")], GREY, 11)
	elif s.get("city_error", false):
		_text(box, "City data unavailable: no verified site or ward for this call.", GREY, 11)
	if s.get("city_error", false):
		_text(box, "Location and ward trust are unavailable; no local community group can be identified.", GREY, 11)
	else:
		_text(
			box,
			(
				"%s, %s ward. Trust in police: %d of 100%s."
				% [
					s["address"],
					s["ward"],
					int(s["trust"]),
					(
						" (the coalition has cut off community tips)"
						if not bool(s.get("community", true))
						else ""
					)
				]
			),
			GREY,
			11
		)
	_text(
		box,
		(
			"Visibility %s: %s"
			% [
				dots(int(s["visibility"])),
				[
					"",
					"Few people are watching; a report may take months.",
					"A small number of neighbours may see it.",
					"Phones are out along the street.",
					"Reporters may be there; more people will have an account.",
					"A crowd and live cameras put the event in public view."
				][clampi(int(s["visibility"]), 1, 5)]
			]
		),
		GREY,
		11
	)
	_text(
		box,
		"Time pressure: %s" % Situations.PRESSURE_NAMES.get(s["pressure"], s["pressure"]),
		GREY,
		11
	)
	if s["type"] == "event":
		var ch: Dictionary = Situations.chatter(s)
		_text(
			box,
			(
				"The standing detail is ten officers; six may be enough on a lowered estimate. Suggest a plan assigns %d from the current reading (%s, %d%% confidence). Posts and patrols cost half overtime. The event lasts fifteen minutes; the estimate is not a guarantee. Suggest a plan puts officers with trauma under %d on crowd duty first: a shaken officer carries more stress into every shift and misreads a running crowd sooner once something happens."
				% [
					Autoplan.want_for(s),
					String(ch.get("level", "no word")),
					int(ch.get("conf", 30)),
					int(Autoplan.CROWD_TRAUMA)
				]
			),
			GREY,
			11
		)
	var bb := "[b]FACTS, ESTIMATES, AND SOURCES[/b]\n"
	for ln in Situations.briefing_lines(s):
		bb += (
			("[b]%s:[/b] %s  [i](confirmed)[/i]\n" if ln["known"] else "%s: %s\n")
			% [ln["label"], String(ln["text"]).replace("[", "(")]
		)
	if not s["tips"].is_empty():
		bb += "\n[b]TIPS[/b]\n"
		for tp in s["tips"]:
			bb += "· %s\n" % String(tp).replace("[", "(")
	else:
		bb += "\nNo tips have come in."
	_rich(box, bb)
	_risk_card(s, true)
	# canvass
	var av: Array = main.campaign.available_for(s["id"]).filter(
		func(r): return not main.campaign.plan_members(s).has(r["id"])
	)
	if not av.is_empty():
		var h := _h(box)
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for r in Autoplan.ranked(av):
			opt.add_item(
				(
					"%s %s (%s)"
					% [
						String(r["rank"]).substr(0, 3) + ".",
						r["name"],
						Habits.EXP_NAMES[int(r["exp"])]
					]
				)
			)
			opt.set_item_metadata(opt.item_count - 1, r["id"])
		h.add_child(opt)
		_btn(
			h,
			"Canvass",
			func():
				if opt.selected >= 0:
					main.ops_canvass(String(opt.get_item_metadata(opt.selected)))
		)
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
	var cb := _btn(
		box,
		"Body cameras: %s" % ("worn" if cams else "not issued"),
		func(on): main.ops_set_bodycams(on),
		true
	)
	cb.set_pressed_no_signal(cams)
	cb.tooltip_text = "Body cameras record what each officer sees as evidence for the incident record. You always see what your officers see."


## EA_TASKS P1.C5: the Entry kit Suggest a plan proposed for a gang raid, its price, and
## the chief's choice. It is bought when the operation starts, not before.
func _kit_proposal_card(s: Dictionary, plan: Dictionary) -> void:
	var prop: Dictionary = plan.get("kit", {})
	if prop.is_empty():
		return
	var c = main.campaign
	var members: Array = c.plan_members(s)
	var n := 0
	for oid in prop:
		if members.has(oid):
			n += 1
	if n == 0:
		return
	var own: bool = String(plan.get("kit_mode", "suggested")) == "own"
	var cost: int = c.plan_kit_cost(s)
	var v := _card(box)
	_text(
		v,
		(
			"SUGGESTED KIT  ·  Entry kit for %d officer%s going in (plates, handgun-rated helmet, flashbangs, the ram on the point man): $%s, bought when the operation starts."
			% [n, "" if n == 1 else "s", Department.money(maxi(0, cost))]
		),
		INK if not own else GREY,
		11
	)
	_text(
		v,
		"In tested gang raids it lost about four officers in ten fewer than patrol kit; no single piece of it does that alone.",
		GREY,
		10
	)
	var h := _h(v)
	if own:
		_text(h, "They keep their current kit.", GREY, 11)
		_btn(h, "Use the suggested kit", func(): _set_kit_mode("suggested"))
	else:
		_btn(h, "Keep their current kit", func(): _set_kit_mode("own"))
	if c.dept.frozen() and not own:
		_text(v, "The account is in the red: the kit cannot be bought, and they will go in what they have.", Ink.accent(0.9), 10)


func _set_kit_mode(m: String) -> void:
	main.plan["kit_mode"] = m
	main.plan_changed()
	show_plan()


func _force(s: Dictionary) -> void:
	var plan: Dictionary = main.plan
	var squads: Array = plan.get("squads", [])
	_text(
		box,
		"Build up to five squads of six. The highest rank leads; experience sets how many orders that squad can carry. You can change the suggested grouping and kit before the operation starts.",
		GREY,
		11
	)
	_kit_proposal_card(s, plan)
	var stages: Array = Operation.stages(main.level)
	for si in squads.size():
		var sq: Dictionary = squads[si]
		var recs := _recs(sq["members"])
		var ld = Orders.leader(recs)
		var v := _card(box)
		var h := _h(v)
		var t := Label.new()
		t.text = (
			"SQUAD %d  ·  %d  ·  %s"
			% [
				si + 1,
				recs.size(),
				(
					(
						"led by %s %s (%s): %d point%s"
						% [
							ld["rank"],
							ld["name"],
							Habits.EXP_NAMES[int(ld["exp"])],
							Orders.points_for(recs),
							"" if Orders.points_for(recs) == 1 else "s"
						]
					)
					if ld != null
					else "empty"
				)
			]
		)
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
			so.item_selected.connect(
				func(i):
					main.plan["squads"][k]["stage"] = i
					main.plan_changed()
			)
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
				kb.tooltip_text = (
					"%s kit. Point man: %s.\nThe rest: %s."
					% [
						kname,
						Equipment.describe(Equipment.SQUAD_KITS[key]["point"]),
						Equipment.describe(Equipment.SQUAD_KITS[key]["rest"])
					]
				)
			for r0 in recs:
				var hr := _h(v)
				var oid0: String = r0["id"]
				var kl := _text(
					hr,
					(
						"%s  ·  %s"
						% [r0["name"], Equipment.describe(r0.get("kit", Equipment.default_kit()))]
					),
					INK,
					11
				)
				kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_btn(
					hr,
					"Kit" if kit_open != oid0 else "Done",
					func():
						kit_open = "" if kit_open == oid0 else oid0
						show_plan()
				)
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
		var l := _text(
			h3,
			(
				"%s %s  ·  %d yr  ·  %s  ·  J %d%s"
				% [
					String(r["rank"]).substr(0, 3) + ".",
					r["name"],
					int(r.get("years", 0)),
					Habits.EXP_NAMES[int(r["exp"])],
					int(r["judgment"]),
					(
						("  ·  " + String(r["personality"]).to_lower())
						if r["personality"] != ""
						else ""
					)
				]
			),
			INK,
			11
		)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.tooltip_text = UI.officer_file(r)
		if s["type"] == "event" and float(r.get("trauma", 0.0)) >= Autoplan.CROWD_TRAUMA:
			_text(box, "      trauma %.0f: Suggest a plan keeps this officer off crowd duty while others are free (carries stress into the shift)" % float(r["trauma"]), Ink.accent(0.9), 10)


## One officer's kit: weapons, sight, armour and gear, within their training.
func _kit_editor(parent: Control, r: Dictionary) -> void:
	var who: String = Equipment.who_of_record(r)
	var kit: Dictionary = Equipment.validate(r.get("kit", Equipment.default_kit()), who)
	var v := VBoxContainer.new()
	parent.add_child(v)
	var rows := [
		["Primary", "primary", [""] + Equipment.PRIMARY_ORDER],
		["Sidearm", "secondary", [""] + Equipment.SECONDARY_ORDER],
		["Sight", "optic", ["red_dot", "irons", "magnified"]],
		["Armour", "armour", ["none", "vest", "plates"]],
		["Helmet", "head", ["none", "ballistic_helmet", "sof_helmet"]]
	]
	for row in rows:
		var h := _h(v)
		_lab(h, row[0], GREY, 11)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 1.3 playtest: sized to its longest item, the list pushed the whole panel wider
		# than the screen; it clips instead
		ob.fit_to_longest_item = false
		ob.clip_text = true
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
					nm = (
						Equipment.ARMOUR[item]["name"] + (" (2 plates)" if item == "plates" else "")
					)
				"head":
					nm = Equipment.HEAD[item]["name"]
					ok = Equipment.allowed(Equipment.HEAD[item]["who"], who)
			var instock: bool = Equipment.stocked(String(item))
			ob.add_item(nm + ("" if ok else "  (tactical training)") + ("" if instock else "  (locked)"))
			ob.set_item_metadata(ob.item_count - 1, item)
			ob.set_item_disabled(ob.item_count - 1, not ok or not instock)
			if item == String(kit[field]):
				ob.select(ob.item_count - 1)
		ob.item_selected.connect(func(i): _set_kit(r, field, ob.get_item_metadata(i)))
		h.add_child(ob)
	var grid := GridContainer.new()
	grid.columns = 4
	v.add_child(grid)
	for gid in Equipment.GEAR_ORDER:
		var spec: Dictionary = Equipment.GEAR[gid]
		var ok2: bool = (
			Equipment.allowed(spec["who"], who)
			and (not spec.has("needs") or kit["primary"] == spec["needs"])
			and Equipment.stocked(gid)
		)
		var gl := _lab(grid, spec["name"], INK if ok2 else GREY, 11)
		gl.tooltip_text = (
			"%s (%s)\n%s" % [spec["name"], Equipment.WHO_NAMES[spec["who"]], spec["desc"]]
		)
		gl.mouse_filter = Control.MOUSE_FILTER_STOP
		var sp := SpinBox.new()
		sp.min_value = 0
		sp.max_value = int(spec["max"])
		sp.value = int(kit["gear"].get(gid, 0))
		sp.editable = ok2
		var g2: String = gid
		sp.value_changed.connect(func(val): _set_gear(r, g2, int(val)))
		grid.add_child(sp)
	_text(
		v,
		(
			"%.1f kg (pace x%.2f), cost %d.%s"
			% [
				Equipment.weight(kit),
				Equipment.speed_factor(kit),
				Equipment.cost(kit),
				(
					""
					if who == "tactical"
					else " Flashbangs, sting-balls, gas, the pepperball and 40 mm launchers, breaching rounds, the short rifle, the battle and marksman rifles and the shield need five years on the job or Experience 3."
				)
			]
		),
		GREY,
		10
	)


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
		_issue(
			r,
			Equipment.validate(
				spec["point"] if k == 0 else spec["rest"], Equipment.who_of_record(r)
			)
		)
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
	main.plan["squads"].append(
		{
			"members": [],
			"stage": main.plan["squads"].size() % maxi(1, stages.size()),
			"orders": Orders.empty_orders()
		}
	)
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
	var select_squad := func(on: bool, squad_i: int) -> void:
		if on:
			sel_sq = squad_i
			set_pick({})
			show_plan()
	for si in squads.size():
		var b := _btn(hs, "Squad %d" % (si + 1), select_squad.bind(si), true)
		b.set_pressed_no_signal(si == sel_sq)
	main.plan_marks.sel = sel_sq
	main.plan_marks.queue_redraw()
	var sq: Dictionary = squads[sel_sq]
	var od: Dictionary = sq["orders"]
	var recs := _recs(sq["members"])
	var pts := Orders.points_for(recs)
	var used := Orders.cost(od)
	_text(
		box,
		(
			"Order points: %d of %d used%s"
			% [
				used,
				pts,
				("  ·  leader " + Orders.leader(recs)["name"]) if not recs.is_empty() else ""
			]
		),
		INK if used <= pts else Ink.accent(0.9),
		13
	)
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
	_constraint_row(cv, od, "less", pts, used)
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
			_text(
				h,
				(
					("%d room%s picked" % [n, "" if n == 1 else "s"])
					if n > 0
					else (
						"the whole building"
						if ob["kind"] == "clear"
						else "wherever the hostages are"
					)
				),
				GREY,
				11
			)
			_tool_btn(h, "Pick rooms", {"kind": "rooms", "obj": oi})
			_btn(
				h,
				"All",
				func():
					ob["rooms"] = []
					main.plan_changed()
					show_plan()
			)
		"arrest":
			var nm: String = main.cur_sit.get("named", "")
			_text(h, "Target: %s" % (nm if nm != "" else "the first suspect found"), GREY, 11)
		"contain":
			_text(
				h,
				(
					"%d opening%s"
					% [
						ob.get("openings", []).size(),
						"" if ob.get("openings", []).size() == 1 else "s"
					]
				),
				GREY,
				11
			)
			_tool_btn(h, "Pick doors and windows", {"kind": "openings", "obj": oi})
		"post":
			_text(h, "Click the plan to place; right-click to set facing.", GREY, 11)
			_tool_btn(h, "Place", {"kind": "post", "obj": oi})
		"patrol":
			_text(
				h,
				(
					"%d waypoint%s"
					% [ob.get("route", []).size(), "" if ob.get("route", []).size() == 1 else "s"]
				),
				GREY,
				11
			)
			_tool_btn(h, "Draw route", {"kind": "route", "obj": oi})
			_btn(
				h,
				"Clear",
				func():
					ob["route"] = []
					main.plan_changed()
					show_plan()
			)


func _tool_btn(parent: Control, text: String, p: Dictionary) -> void:
	var on: bool = (
		not pick.is_empty()
		and pick.get("kind", "") == p["kind"]
		and int(pick.get("obj", -1)) == int(p.get("obj", -1))
	)
	var b := _btn(
		parent,
		text,
		func(state):
			set_pick(p if state else {})
			show_plan(),
		true
	)
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
			_text(
				h,
				(
					", ".join(od["avoid"].map(func(r): return Situations.room_title(main.level, r)))
					if not od["avoid"].is_empty()
					else "pick rooms"
				),
				GREY,
				10
			)
			_tool_btn(h, "Pick", {"kind": "avoid"})
		"consolidate":
			_text(
				h,
				(
					Situations.room_title(main.level, od["consolidate"])
					if od["consolidate"] != "*"
					else "pick a room"
				),
				GREY,
				10
			)
			_tool_btn(h, "Pick", {"kind": "consolidate"})
		"entry":
			_text(
				h, String(od["entry"]).to_lower() if od["entry"] != "*" else "pick a door", GREY, 10
			)
			_tool_btn(h, "Pick", {"kind": "entry"})
		"pace":
			var po := OptionButton.new()
			po.add_item("walk")
			po.add_item("creep")
			po.select(1 if od["pace"] == "creep" else 0)
			po.item_selected.connect(
				func(i):
					od["pace"] = ["walk", "creep"][i]
					main.plan_changed()
			)
			h.add_child(po)
		"phase":
			var ph := OptionButton.new()
			var items: Array = [
				["time", 30], ["time", 60], ["time", 90], ["time", 120], ["time", 180]
			]
			for si in main.plan["squads"].size():
				if si != sel_sq:
					items.append(["squad", si])
			var cur := 0
			for i in items.size():
				var it: Array = items[i]
				ph.add_item(
					(
						("wait %d s" % it[1])
						if it[0] == "time"
						else ("until squad %d is done / in position" % (int(it[1]) + 1))
					)
				)
				if (
					od["phase"].get("kind", "") == it[0]
					and int(od["phase"].get("t" if it[0] == "time" else "squad", -1)) == int(it[1])
				):
					cur = i
			ph.select(cur)
			ph.item_selected.connect(
				func(i):
					var it2: Array = items[i]
					od["phase"] = (
						{"kind": it2[0], "t": it2[1]}
						if it2[0] == "time"
						else {"kind": "squad", "squad": it2[1]}
					)
					main.plan_changed()
			)
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
	var select_speed := func(on: bool, speed: float) -> void:
		if on:
			main.set_speed(speed)
	for sp in UI.SPEEDS:
		var speed: float = sp
		var b := _btn(hs, ("%sx" % str(sp)).replace(".0x", "x"), select_speed.bind(speed), true)
		b.button_group = group
		b.custom_minimum_size = Vector2(44, 0)
		b.set_pressed_no_signal(is_equal_approx(sp, main.speed))
	var pacing := _text(box, "", GREY, 10)
	_run_refs["pacing"] = pacing
	# EA_TASKS P1.G2: offered once the operation has been quiet for a minute of its own
	# clock. The simulation still runs to the end; only the watching is skipped.
	if main.has_method("can_skip_report"):
		var sk := _btn(box, "Skip to the report", func(): main.skip_to_report())
		sk.custom_minimum_size = Vector2(0, 30)
		sk.disabled = true
		_run_refs["skip"] = sk
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
	_text(
		box,
		"Abort: every squad breaks contact and withdraws to its vehicles, still under fire until it gets there. A failure, but a failure with everyone alive always scores better than one with deaths.",
		GREY,
		10
	)


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
	_run_refs["clock"].text = (
		("REWIND  " if main.view_t >= 0.0 else "")
		+ "%02d:%04.1f" % [int(shown_t / 60.0), fmod(shown_t, 60.0)]
	)
	_run_refs["pacing"].text = main.adaptive_status()
	_run_refs["pause"].set_pressed_no_signal(main.paused)
	if _run_refs.has("skip") and main.has_method("can_skip_report"):
		var skip_btn: Button = _run_refs["skip"]
		var quiet: float = main.quiet_seconds() if main.has_method("quiet_seconds") else 0.0
		var ready: bool = main.can_skip_report()
		skip_btn.disabled = not ready
		skip_btn.text = Ink.bb("Skip to the report") if ready else "Skip to the report  ·  %d s of quiet of %d" % [int(quiet), int(main.quiet_skip_after())]
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
		_run_refs["know"].text = (
			"Fog of war: what %d of %d officers can see. %d people in view, %d radio last-known positions."
			% [eyes, offs, fog.visible_ids.size(), fog.lkps.size()]
		)
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
			var modes := {
				"assault": "clearing",
				"hold": "holding",
				"hunt": "patrolling",
				"wait": "on the phase line",
				"withdraw": "withdrawing",
				"support": "waiting on the next room",
				"lost": "lost"
			}
			var st: String = String(modes.get(el["mode"], el["mode"]))
			if el.get("consolidating", false):
				st = "consolidating"
			bb += (
				"[b]SQUAD %d[/b]  %d/%d  ·  %s%s\n"
				% [
					el["i"] + 1,
					alive,
					el["members"].size(),
					st,
					("  ·  " + what) if what != "" else ""
				]
			)
	_run_refs["squads"].text = Ink.bb(bb)
	# the radio: what the officers say and what happens to them
	var lg: RichTextLabel = _run_refs["log"]
	_log_shown = maxi(_log_shown, w.log_base)
	while _log_shown < w.log_base + w.log_lines.size():
		var ln: Dictionary = w.log_lines[_log_shown - w.log_base]
		_log_shown += 1
		if not _radio(ln, w):
			continue
		if ln["kind"] in ["comms", "kill", "bad", "end"] and main.sound != null:
			main.sound.radio()
		var txt: String = String(ln["text"]).replace("[", "(")
		match ln["kind"]:
			"kill":
				lg.append_text(Ink.bb("[b][color=#b31f26]%s[/color][/b]\n" % txt))
			"bad", "end":
				lg.append_text(Ink.bb("[b]%s[/b]\n" % txt))
			"comms":
				lg.append_text(Ink.bb("[i][color=#6e675c]%s[/color][/i]\n" % txt))
			_:
				lg.append_text(Ink.bb("[color=#2f2e2d]%s[/color]\n" % txt))


## Is a log line something the department would hear on the radio?
func _radio(ln: Dictionary, w) -> bool:
	var txt: String = ln["text"]
	var body: String = txt.substr(txt.find("  ") + 2) if txt.find("  ") >= 0 else txt
	if float(ln["t"]) < 0.5 and ln["kind"] == "bad":
		return false
	if (
		ln["kind"] == "end"
		or body.begins_with("Squad")
		or body.begins_with("ABORT")
		or body.begins_with("Police")
	):
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
	_guide_debrief()
	_title("%s  ·  %d" % [res["label"], int(res["score"])], 20)
	var goal: String = res["goal"]
	_text(box, goal.substr(0, 1).to_upper() + goal.substr(1) + ".", INK, 13)
	_text(box, "SCORE ARITHMETIC  ·  " + String(res.get("score_explanation", "")), INK, 11)
	for part in res.get("score_parts", []):
		var amount := int(part.get("amount", 0))
		var line := "%s  ·  %s%d" % [part.get("label", ""), "+" if amount >= 0 else "", amount]
		_text(box, line, INK if bool(part.get("total", false)) else GREY, 12 if bool(part.get("total", false)) else 10)
	_text(box, "Deaths include officers and civilians; only nonfatal officer downs use the -5 term. Force is not in this score: it is what the city remembers (City Hall).", GREY, 10)
	var bb := ""
	for sq in res.get("squads", []):
		bb += (
			"[b]SQUAD %d[/b]  %d of %d standing\n"
			% [int(sq["i"]) + 1, int(sq["alive"]), int(sq["n"])]
		)
		for r in sq["results"]:
			bb += (
				"    %s: %s (%s)\n"
				% [
					Orders.OBJECTIVES.get(r["kind"], {}).get("name", r["kind"]),
					"met" if r["ok"] else "failed",
					r["why"]
				]
			)
		if sq["results"].is_empty():
			bb += "    objective not resolved when the operation ended\n"
	# Q4: what you changed from the suggestion, closed with what became of it
	var diff: Array = res.get("diff", [])
	if not diff.is_empty():
		bb += "\n[b]YOUR EDITS[/b]\n"
		for ln in diff:
			bb += "    %s\n" % String(ln)
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
		bb += (
			"%s %s: %s; %d rounds, %d hit%s%s\n    [color=#6e675c]%s%s[/color]\n"
			% [
				o.id,
				o.name,
				st,
				p2["shots"],
				p2["hits"],
				("; misses: " + ", ".join(misses)) if not misses.is_empty() else "",
				(
					("; [b]broke orders:[/b] " + ", ".join(broken.get(o.id, [])))
					if broken.has(o.id)
					else ""
				),
				Equipment.describe(o.kit),
				("; used " + ", ".join(used)) if not used.is_empty() else ""
			]
		)
	var sm: Dictionary = w.incident.summary()
	bb += (
		"\n[b]CIVILIANS[/b]  %d present, %d hurt, %d killed; %d round%s from police struck a civilian.\n"
		% [
			sm["civ_total"],
			sm["civ_hit"],
			sm["civ_killed"],
			sm["civ_hit_police"],
			"" if sm["civ_hit_police"] == 1 else "s"
		]
	)
	if sm.get("hostages", 0) > 0:
		bb += (
			"Hostages: %d, %d out safe, %d killed.\n"
			% [sm["hostages"], sm["hostages_safe"], sm["hostages_killed"]]
		)
	bb += (
		"Suspects: %d, %d down, %d gave up, %d cuffed, %d got away.\n"
		% [sm["suspects"], sm["suspects_down"], sm["surrendered"], sm["arrested"], sm["escaped"]]
	)
	if not dept_lines.is_empty():
		bb += "\n[b]THE DEPARTMENT[/b]\n"
		for d in dept_lines:
			bb += String(d).replace("[", "(") + "\n"
	bb += (
		"\n[b]FILES OPENED[/b]  %d. What comes of them lands later: in the papers, in court, at City Hall.\n"
		% int(sm["findings"])
	)
	_rich(box, bb)
	_timeline(w)
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
	var seek_replay := func(value: float) -> void:
		if not _sliding:
			main.ops_replay_seek(value)
	sl.value_changed.connect(seek_replay)
	box.add_child(sl)
	_run_refs["rslider"] = sl
	var rc := Label.new()
	rc.add_theme_font_size_override("font_size", 11)
	box.add_child(rc)
	_run_refs["rclock"] = rc
	var back := _btn(box, "<  Back to the board", func(): main.ops_board())
	back.custom_minimum_size = Vector2(0, 34)


func _timeline(w) -> void:
	_text(box, "TIMELINE  ·  click an event to seek the replay", INK, 12)
	if w.timeline.is_empty():
		_text(box, "No milestone events were recorded.", GREY, 10)
		return
	for tl in w.timeline:
		var tt := float(tl.get("t", 0.0))
		var kind := String(tl.get("kind", "info")).to_upper()
		var text := "%s  [%s]  %s" % [w.clock(tt), kind, String(tl.get("text", "")).replace("[", "(")]
		var b := _btn(box, text, func(): main.ops_replay_seek(tt))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 28)
		b.add_theme_font_size_override("font_size", 10)
		b.tooltip_text = "Seek replay to %.1f seconds" % tt


func refresh_replay(t: float, total: float, playing: bool) -> void:
	if mode != "debrief" or not _run_refs.has("rslider"):
		return
	_sliding = true
	_run_refs["rslider"].set_value_no_signal(t)
	_sliding = false
	_run_refs["rclock"].text = (
		"%02d:%04.1f of %02d:%04.1f"
		% [int(t / 60.0), fmod(t, 60.0), int(total / 60.0), fmod(total, 60.0)]
	)
	_run_refs["play"].set_pressed_no_signal(playing)
