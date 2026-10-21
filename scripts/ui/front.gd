extends CanvasLayer
## The front end (1.0): the title screen, settings, the manual, credits and the pause
## menu, drawn in red ink over the plan. Main asks for a screen; the buttons call back.
##
## Screens: "title", "settings", "manual", "credits", "confirm_new", "pause".

const UI = preload("res://scripts/ui/ui.gd")
const Ink = preload("res://scripts/view/ink.gd")
const Settings = preload("res://scripts/ui/settings.gd")
const Campaign = preload("res://scripts/campaign/campaign.gd")

const VERSION := "1.0.0"

var main
var shade: ColorRect
var root: Control
var screen := ""
var back_to := "title"       # where settings, the manual and credits return to
var manual_page := 0
var _wrap_w := 560.0


func build(m) -> void:
	main = m
	layer = 20
	shade = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.make_theme()
	add_child(root)
	visible = false


func hide_front() -> void:
	visible = false
	screen = ""


func is_open() -> bool:
	return visible


func _clear() -> void:
	for c in root.get_children():
		c.queue_free()


# ------------------------------------------------------------------ widgets
func _label(parent: Control, text: String, size: int, col := Ink.INK, wrap := false, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if wrap:
		# a wrapping label needs a width, or it measures one character to a line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width if width > 0.0 else _wrap_w, 0)
	parent.add_child(l)
	return l


func _menu_btn(parent: Control, text: String, cb: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 38)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", UI._sb(Color(Ink.PAPER, 0.0), Color(Ink.PAPER, 0.0), 0, 8.0))
	b.add_theme_stylebox_override("hover", UI._sb(Color(Ink.FLOOR, 0.9), Ink.INK, 1, 8.0))
	b.add_theme_stylebox_override("pressed", UI._sb(Ink.LIGHT, Ink.INK, 1, 8.0))
	b.add_theme_stylebox_override("disabled", UI._sb(Color(Ink.PAPER, 0.0), Color(Ink.PAPER, 0.0), 0, 8.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.disabled = not enabled
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	return b


func _page(title: String, width := 900.0) -> VBoxContainer:
	_clear()
	shade.color = Color(Ink.PAPER, 0.96)
	_wrap_w = width - 60.0
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI._sb(Ink.PAPER, Ink.INK, 1, 28.0))
	panel.custom_minimum_size = Vector2(width, 0)
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	_label(v, _spaced(title), 22)
	var rule := ColorRect.new()
	rule.color = Ink.INK
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	return v


static func _spaced(s: String) -> String:
	var out := ""
	for i in s.length():
		out += s[i] + (" " if i < s.length() - 1 and s[i] != " " else (" " if s[i] == " " else ""))
	return out.to_upper()


# ------------------------------------------------------------------ title
func show_title() -> void:
	visible = true
	screen = "title"
	_clear()
	shade.color = Color(Ink.PAPER, 0.93)
	var art := TitleArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)
	var v := VBoxContainer.new()
	v.position = Vector2(110, 90)
	v.add_theme_constant_override("separation", 4)
	root.add_child(v)
	_label(v, "PORT CARRICK POLICE DEPARTMENT  ·  OFFICE OF THE CHIEF", 13, Ink.MID)
	_label(v, "T H E   V I O L E N C E", 64)
	var rule := ColorRect.new()
	rule.color = Ink.accent(0.9)
	rule.custom_minimum_size = Vector2(560, 5)
	v.add_child(rule)
	var tag := _label(v, "Forty weeks to the election. Every operation is a plan until it meets a room.", 16, Ink.DARK)
	tag.custom_minimum_size = Vector2(620, 0)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	v.add_child(gap)
	var c: Dictionary = _campaign_summary()
	if c.get("exists", false):
		_menu_btn(v, "Continue    ·    %s" % c["text"], func(): _continue())
	_menu_btn(v, "New campaign", func(): _new_campaign_ask())
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 12)
	v.add_child(gap2)
	_menu_btn(v, "Test range", func(): _test_range())
	_menu_btn(v, "Endless battle: Port Carrick", func(): _endless())
	var gap3 := Control.new()
	gap3.custom_minimum_size = Vector2(0, 12)
	v.add_child(gap3)
	_menu_btn(v, "How to play", func(): show_manual("title"))
	_menu_btn(v, "Settings", func(): show_settings("title"))
	_menu_btn(v, "Credits", func(): show_credits("title"))
	_menu_btn(v, "Quit", func(): main.get_tree().quit())
	var foot := _label(root, "v%s   ·   F2 red ink   ·   F3 gore   ·   Esc menu" % VERSION, 11, Ink.MID)
	foot.position = Vector2(110, 860)


func _campaign_summary() -> Dictionary:
	var c = main.campaign
	if c == null or not load("res://scripts/campaign/save_file.gd").exists(Campaign.SAVE_PATH):
		return {}
	if c.over():
		return {"exists": true, "text": "election night (the campaign is over)"}
	return {"exists": true, "text": "week %d of %d, %d officers fit, account $%s" % [c.week(), c.WEEKS, c.dept.available().size(), c.dept.money(c.dept.balance)]}


func _continue() -> void:
	hide_front()
	main.ops_open()


func _new_campaign_ask() -> void:
	var c: Dictionary = _campaign_summary()
	if not c.get("exists", false) or main.campaign.over():
		_new_campaign()
		return
	screen = "confirm_new"
	var v := _page("A new campaign", 620.0)
	_label(v, "Your campaign (%s) has one save. A new campaign replaces it for good." % c["text"], 14, Ink.INK, true)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var yes := Button.new()
	yes.text = "Start a new campaign"
	yes.pressed.connect(func(): _new_campaign())
	h.add_child(yes)
	var no := Button.new()
	no.text = "Keep my campaign"
	no.pressed.connect(func(): show_title())
	h.add_child(no)


func _new_campaign() -> void:
	hide_front()
	main.ops_new_campaign()
	main.ops_open()
	main.ops_ui.show_board(["Week 1. The department is yours."])


func _test_range() -> void:
	hide_front()
	main.ops_close()


func _endless() -> void:
	hide_front()
	main.start_city(randi_range(1, 999999), 60, 108)


# ------------------------------------------------------------------ pause
## Esc during the campaign or a match: resume, the manual, settings, and the way out.
func show_pause() -> void:
	visible = true
	screen = "pause"
	var running: bool = main.mode == "run" and main.world != null and not main.world.over
	var v := _page("Paused", 460.0)
	_menu_btn(v, "Resume", func(): resume())
	_menu_btn(v, "How to play", func(): show_manual("pause"))
	_menu_btn(v, "Settings", func(): show_settings("pause"))
	if running and main.op_mode:
		_menu_btn(v, "Abort the operation", func(): resume(); main.ops_abort())
		_label(v, "The operation must end before you leave it: abort, or let it play out. The campaign is saved after every operation.", 11, Ink.MID, true)
	else:
		_menu_btn(v, "Main menu", func(): to_title())
		_label(v, "The campaign is saved after every operation and every week.", 11, Ink.MID, true)


func resume() -> void:
	hide_front()
	main.front_closed()


func to_title() -> void:
	main.go_title()


# ------------------------------------------------------------------ settings
func show_settings(from: String) -> void:
	back_to = from
	visible = true
	screen = "settings"
	var v := _page("Settings", 620.0)
	_check(v, "Full screen", "fullscreen")
	_slider(v, "Master volume", "master")
	_slider(v, "Effects (shots, doors, radio)", "effects")
	_slider(v, "Ambience (the city)", "ambience")
	_check(v, "Red ink (F2): off is the monochrome proof", "red_ink")
	_check(v, "Gore (F3): off keeps the evidence markers", "gore")
	_check(v, "Tips in the first weeks of a campaign", "tips")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	_label(h, "Operations start at", 14)
	var ob := OptionButton.new()
	for s in Settings.SPEEDS:
		ob.add_item("%sx" % str(s))
		if absf(float(s) - float(Settings.get_v("speed"))) < 0.01:
			ob.select(ob.item_count - 1)
	ob.item_selected.connect(func(i): Settings.set_v("speed", Settings.SPEEDS[i]))
	h.add_child(ob)
	_label(v, "Presentation settings never change the simulation.", 11, Ink.MID)
	var back := Button.new()
	back.text = "<  Back"
	back.pressed.connect(func(): _back())
	v.add_child(back)


func _check(parent: Control, text: String, key: String) -> void:
	var cb := CheckButton.new()
	cb.text = text
	cb.button_pressed = bool(Settings.get_v(key))
	cb.toggled.connect(func(on): Settings.set_v(key, on); main.settings_changed())
	parent.add_child(cb)


func _slider(parent: Control, text: String, key: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	var l := _label(h, text, 14)
	l.custom_minimum_size = Vector2(260, 0)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.get_v(key))
	s.custom_minimum_size = Vector2(260, 24)
	s.value_changed.connect(func(val): Settings.set_v(key, val))
	h.add_child(s)


func _back() -> void:
	if back_to == "pause":
		show_pause()
	else:
		show_title()


# ------------------------------------------------------------------ credits
func show_credits(from: String) -> void:
	back_to = from
	visible = true
	screen = "credits"
	var v := _page("Credits", 620.0)
	for ln in [
		["THE VIOLENCE", 18],
		["Version %s" % VERSION, 12],
		["", 8],
		["Design: Ambidgen", 14],
		["Built with Claude (Anthropic): code, simulation, art generation and sound.", 13],
		["", 8],
		["Engine: Godot Engine 4.7 (MIT licence), godotengine.org.", 13],
		["Art: every sprite is drawn by tools/make_placeholders.py, in red ink.", 13],
		["Sound: every effect is synthesised by tools/make_sounds.py. No samples.", 13],
		["", 8],
		["Port Carrick, its wards, its people and its candidates are invented. Any resemblance to a real city is the point, not the intent.", 12],
		["", 8],
		["FILED. NOT RESOLVED.", 13],
	]:
		_label(v, ln[0], ln[1], Ink.accent(0.9) if ln[0] == "FILED. NOT RESOLVED." else Ink.INK, true)
	var back := Button.new()
	back.text = "<  Back"
	back.pressed.connect(func(): _back())
	v.add_child(back)


# ------------------------------------------------------------------ the manual
const MANUAL := [
	["The job", """You are the new chief of the Port Carrick Police Department. The city is broke, its mills are closing, and there is an election in forty weeks. Whoever wins decides what happens to you.

Each week the operations board fills with situations: warrants, crew houses, barricaded suspects, hostage takings and, more often as the election nears, public rallies. You decide which to answer, who to send and what they are allowed to do. Then the operation plays out on its own. You watch; you do not steer.

Everything the department does is remembered: by its officers, its budget, the press, the city's four power brokers and three candidates. There is no perfect playthrough. Every decision is a trade."""],
	["A week", """The board shows this week's situations. For each: its type, its ward, how much trust that ward has in the police, how many people are watching (visibility), and how much time you have.

Officers sent to one situation, or out canvassing for tips, cannot go to another that week. With twenty officers and three or four situations, you will not answer everything. What you leave is written down, and some of it comes back.

When you are done, End week. Pay goes out, the city's allocation comes in, wounds heal, courses finish, and a new board fills. The front page of the Carrick Ledger tells you what the city made of last week."""],
	["Planning an operation", """Brief and plan opens three tabs.

Briefing: what is known, what is estimated and how sure, and the tips. It is never complete. Canvassing sends an officer for two more tips and costs you that officer for the week.

Force: who goes, in up to five squads of up to six, and what each carries. Kit is bought from the budget. Tactical gear (bangs, gas, the shield) needs tactical training.

Orders: each squad's objectives (clear, arrest, rescue, contain, post, patrol) and constraints (avoid a room, consolidate, an entry door, a phase line). The number of orders a squad can follow depends on the experience of its leader.

On the map the plan is one clean red line. It will not survive the house. Suggest a plan gives you a sensible start; it will not send fewer than four officers through a door."""],
	["The operation", """The operation runs hands-off, as your officers would run it: their habits, their training, their stress and their judgment. Under police rules every person seen is judged before an officer may fire; suspects can give up, and officers cuff them.

You see what your officers see: their view cones, live. Everyone else appears where the radio last called them out.

Space pauses. 1-7 set the speed. The slider rewinds what you have seen; the operation itself never goes back. Abort withdraws every squad: a failure, but a failure with everyone alive always scores better than one with deaths."""],
	["Afterwards", """The debrief scores the result and lists every officer, every round and every finding, with its evidence: body camera, phone video, witnesses, or nobody.

Findings that name an officer open an internal affairs case. Clear it, send the officer to a use-of-force review, suspend them, or dismiss them. The union watches your discipline; the community coalition and the district attorney watch what you clear.

What civilians suffered at police hands becomes a story: next week if there was video or a crowd, months later if nobody was watching, and sometimes never. Lawsuits settle out of your budget weeks after."""],
	["The department", """The roster: open an officer's file to send them on a course (close quarters, firearms, judgment, stress, coaching, tactical certification) or to dismiss them. Hire recruits (two weeks at the academy) or experienced officers who report at once.

The budget: the city's weekly allocation against pay, overtime, kit, training, medical bills and settlements. In the red, hiring, training and new kit freeze, and the council notices.

Morale falls with deaths, wounds, dismissals and deficits. Low morale puts more stress into every operation; very low morale costs you officers."""],
	["The city", """City Hall shows the polls, the four allies and the trust of each ward.

Each ally holds something: the budget chair the allocation, the union president the officers' goodwill, the community coalition the tips, the district attorney the benefit of the doubt. Lose one below 25 and what they hold goes with them; win them back above 40.

Royce Kettering gains from failure and fear. Dana Okonjo-Vale gains from every story of police harm, and wants you gone. Gordon Pell gains from quiet competence and balanced books. At the end of week 40 the city votes."""],
	["Controls", """Mouse wheel zooms; middle or right drag pans; Home refits the view.
Space pauses an operation; 1-7 set its speed.
F2 switches red ink off (the monochrome proof); F3 switches gore off. Neither touches the simulation.
Esc opens the menu.

The test range (from the title) is a sandbox: any two teams, any echelons, habits and kit, on any of the twelve maps. The Endless Battle is the city of Port Carrick at war with itself, its gangs and its police, until you stop it."""],
]


func show_manual(from: String) -> void:
	back_to = from
	visible = true
	screen = "manual"
	Settings.set_v("seen_manual", true)
	var v := _page("How to play", 980.0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	v.add_child(h)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size = Vector2(210, 0)
	h.add_child(nav)
	for i in MANUAL.size():
		var b := _menu_btn(nav, MANUAL[i][0], func(): manual_page = i; show_manual(back_to))
		b.custom_minimum_size = Vector2(210, 32)
		b.add_theme_font_size_override("font_size", 14)
		if i == manual_page:
			b.add_theme_stylebox_override("normal", UI._sb(Ink.FLOOR, Ink.INK, 1, 8.0))
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(680, 420)
	h.add_child(body)
	_label(body, String(MANUAL[manual_page][0]).to_upper(), 16)
	_label(body, String(MANUAL[manual_page][1]), 14, Ink.INK, true, 680.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var back := Button.new()
	back.text = "<  Back"
	back.pressed.connect(func(): _back())
	row.add_child(back)
	if manual_page < MANUAL.size() - 1:
		var nxt := Button.new()
		nxt.text = "Next: %s  >" % MANUAL[manual_page + 1][0]
		nxt.pressed.connect(func(): manual_page += 1; show_manual(back_to))
		row.add_child(nxt)


## Esc on a front screen: one step back.
func escape() -> void:
	match screen:
		"pause":
			resume()
		"title":
			pass
		"settings", "manual", "credits":
			_back()
		"confirm_new":
			show_title()


# ------------------------------------------------------------------ the title's picture
## Right of the menu: the plan as the briefing draws it (a doorway, a room, one clean
## red route with numbered rings), stamped by the model's confidence.
class TitleArt extends Control:
	func _draw() -> void:
		var o := Vector2(size.x * 0.56, size.y * 0.16)
		var s := minf(size.x * 0.36, size.y * 0.62) / 10.0
		var room := Rect2(o + Vector2(1, 1) * s, Vector2(8, 6) * s)
		draw_rect(room, Ink.FLOOR)
		# grain and a halftone corner
		for i in 160:
			var p := room.position + Vector2(float((i * 73) % 997) / 997.0 * room.size.x, float((i * 151) % 991) / 991.0 * room.size.y)
			draw_rect(Rect2(p, Vector2(1.5, 1.5)), Color(Ink.MID, 0.18))
		for gy in 6:
			for gx in 6:
				var rad := 2.4 - 0.36 * float(gx + gy)
				if rad > 0.3:
					draw_circle(room.end - Vector2(14, 14) - Vector2(gx, gy) * 8.0, rad, Color(Ink.DARK, 0.15))
		# walls, the gap, the door on its swing
		var wt := 0.22 * s
		draw_rect(Rect2(room.position - Vector2(wt, wt), Vector2(room.size.x + 2 * wt, wt)), Ink.INK)
		draw_rect(Rect2(Vector2(room.position.x - wt, room.end.y), Vector2(room.size.x + 2 * wt, wt)), Ink.INK)
		draw_rect(Rect2(Vector2(room.end.x, room.position.y), Vector2(wt, room.size.y)), Ink.INK)
		var gap_y := room.position.y + 3.0 * s
		draw_rect(Rect2(Vector2(room.position.x - wt, room.position.y), Vector2(wt, gap_y - room.position.y - 0.5 * s)), Ink.INK)
		draw_rect(Rect2(Vector2(room.position.x - wt, gap_y + 0.5 * s), Vector2(wt, room.end.y - gap_y - 0.5 * s)), Ink.INK)
		var hinge := Vector2(room.position.x, gap_y - 0.5 * s)
		draw_line(hinge, hinge + Vector2(1.0 * s, 0), Ink.INK, 2.0)
		draw_arc(hinge, 1.0 * s, 0.0, PI / 2.0, 16, Ink.MID, 1.0, true)
		# the plan: stage, door, room, corner
		var pts := [o + Vector2(-2.2, 4.0) * s, o + Vector2(0.3, 4.0) * s, o + Vector2(3.0, 4.0) * s, o + Vector2(6.8, 2.2) * s]
		draw_polyline(PackedVector2Array(pts), Ink.accent(0.85), 2.6, true)
		var e: Vector2 = pts[3]
		var u: Vector2 = (pts[3] - pts[2]).normalized()
		draw_colored_polygon(PackedVector2Array([e + u * 5.0, e - u * 14.0 + u.orthogonal() * 8.0, e - u * 14.0 - u.orthogonal() * 8.0]), Ink.accent(0.9))
		var font := ThemeDB.fallback_font
		for k in 3:
			var q: Vector2 = pts[k]
			draw_circle(q, 11.0, Ink.PAPER)
			draw_arc(q, 11.0, 0.0, TAU, 22, Ink.accent(0.9), 2.0)
			draw_string(font, q + Vector2(-4, 5), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Ink.INK)
		# the stamp
		var at := o + Vector2(1.2, 7.9) * s
		draw_set_transform(at, -0.03)
		var sz := Vector2(230, 56)
		draw_rect(Rect2(Vector2.ZERO, sz), Ink.INK, false, 2.0)
		draw_rect(Rect2(Vector2(4, 4), sz - Vector2(8, 8)), Ink.INK, false, 1.0)
		draw_string(font, Vector2(14, 24), "MODEL: COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Ink.INK)
		draw_string(font, Vector2(14, 44), "UNKNOWN: NONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Ink.INK)
		draw_set_transform(Vector2.ZERO, 0.0)
