extends CanvasLayer
## The operations screens (v0.7, Loop B): the week's board, then for one situation the
## briefing, the force (squads of up to five) and the orders, then Run (fog of war,
## pause, slow motion, rewind as viewing tools, and Abort), then the debrief with a full
## replay. Built in code, in the drafting-table style of the setup panel.

const UI = preload("res://scripts/ui/ui.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const PANEL_W := 460.0
const INK := Color("#1c1c1c")
const GREY := Color("#666666")
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
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func _text(parent: Control, text: String, col := INK, size := 12) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


## A short fixed label for a row of controls (no wrapping).
func _lab(parent: Control, text: String, col := INK, size := 12) -> Label:
	var l := Label.new()
	l.text = text
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
	r.text = bb
	parent.add_child(r)
	return r


func _h(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	parent.add_child(h)
	return h


func _btn(parent: Control, text: String, cb: Callable, toggle := false) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	if toggle:
		b.toggled.connect(func(on): cb.call(on))
	else:
		b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _card(parent: Control) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color("#ffffff"), Color("#9a9a9a"), 1, 8.0))
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
	_btn(hb, "Test range", func(): main.ops_close())
	var hb2 := _h(box)
	_btn(hb2, "New campaign", func(): main.ops_new_campaign())
	_text(box, "One save slot: the campaign is saved after every operation and every week.", GREY, 10)


func _end_week() -> void:
	var lines: Array = main.ops_end_week()
	show_board(lines)


func _roster() -> void:
	mode = "roster"
	_clear()
	var d = main.campaign.dept
	_title("ROSTER  ·  week %d" % d.week)
	var order: Array = d.officers.duplicate()
	order.sort_custom(func(a, b):
		var ra: int = Orders.rank_i(a)
		var rb: int = Orders.rank_i(b)
		if ra != rb:
			return ra > rb
		return int(a["xp"]) > int(b["xp"]))
	var busy: Dictionary = main.campaign.committed()
	for r in order:
		var st: String = "fit"
		if r["status"] == "injured":
			st = "out until week %d" % int(r["out_until"])
		elif r["status"] == "dead":
			st = "killed"
		elif busy.has(r["id"]):
			st = "committed (%s)" % busy[r["id"]]
		var l := _text(box, "%s %s  ·  %d yr  ·  %s %d xp  ·  J %d  ·  %s" % [r["rank"], r["name"], int(r.get("years", 0)),
			Habits.EXP_NAMES[int(r["exp"])], int(r["xp"]), int(r["judgment"]), st], INK if r["status"] == "active" else GREY, 11)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.tooltip_text = UI.officer_file(r)
	_btn(box, "<  Back to the board", func(): show_board())


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
	cb.tooltip_text = "With body cameras you see what each officer sees, live. Without them, only the officers and the radio's last-known positions."


func _force(s: Dictionary) -> void:
	var plan: Dictionary = main.plan
	var squads: Array = plan.get("squads", [])
	_text(box, "Pick squads of up to five. The highest rank leads; the leader's experience sets the squad's order points.", GREY, 11)
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
		INK if used <= pts else Color("#7d0a0a"), 13)
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
	var cams := 0
	var offs := 0
	for o in w.ops:
		if o.judges and o.alive() and not o.gone:
			offs += 1
			if o.bodycam:
				cams += 1
	if fog != null and fog.enabled:
		_run_refs["know"].text = "Fog of war: %d of %d officers on camera. %d people in view, %d radio last-known positions." % [cams, offs,
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
	_run_refs["squads"].text = bb
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
				lg.append_text("[b][color=#7d0a0a]%s[/color][/b]\n" % txt)
			"bad", "end":
				lg.append_text("[b]%s[/b]\n" % txt)
			"comms":
				lg.append_text("[i][color=#555555]%s[/color][/i]\n" % txt)
			_:
				lg.append_text("[color=#444444]%s[/color]\n" % txt)


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
			st = "[color=#7d0a0a]killed[/color]"
		elif o.state == "down":
			st = "[color=#7d0a0a]down[/color]"
		elif o.wounds > 0 or o.arm_hit or o.leg_hit:
			st = "wounded"
		bb += "%s %s: %s; %d rounds, %d hit%s%s\n" % [o.id, o.name, st, p2["shots"], p2["hits"],
			("; misses: " + ", ".join(misses)) if not misses.is_empty() else "",
			("; [b]broke orders:[/b] " + ", ".join(broken.get(o.id, []))) if broken.has(o.id) else ""]
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
