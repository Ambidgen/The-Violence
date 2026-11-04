extends CanvasLayer
## The front end (1.0): the title screen, settings, the manual, credits and the pause
## menu, drawn in red ink over the plan. Main asks for a screen; the buttons call back.
##
## Screens: "title", "settings", "manual", "credits", "confirm_new", "pause".

const UI = preload("res://scripts/ui/ui.gd")
const Ink = preload("res://scripts/view/ink.gd")
const Settings = preload("res://scripts/ui/settings.gd")
const Campaign = preload("res://scripts/campaign/campaign.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const Version = preload("res://scripts/version.gd")

const VERSION := Version.VALUE
const CHANNEL := Version.CHANNEL   # "Early Access" while the 1.3 line runs (P0.D1)

var main
# Kept separate for UI tests; in the game this is the campaign's single save slot.
var _campaign_save_path := Campaign.SAVE_PATH
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
	b.custom_minimum_size = Vector2(340, 44)
	b.add_theme_font_size_override("font_size", 22)
	# 1.4: torn scraps of paper; the hovered one lifts (the art rings it in red)
	b.add_theme_stylebox_override("normal", _scrap(Color("#e6dfcd"), Color("#6e675c")))
	b.add_theme_stylebox_override("hover", _scrap(Color("#f2ecdc"), Color("#2f2e2d")))
	b.add_theme_stylebox_override("pressed", _scrap(Color("#ecd49a"), Color("#2f2e2d")))
	b.add_theme_stylebox_override("disabled", _scrap(Color("#e6dfcd", 0.5), Color("#6e675c", 0.5)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.disabled = not enabled
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	return b


func _scrap(bg: Color, edge: Color) -> StyleBox:
	var b = UI._sb(bg, edge, 1, 10.0)
	b.torn = true
	b.content_margin_left = 22.0
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
	shade.color = Color("#8d8a83")
	var art := CityArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.version = VERSION
	root.add_child(art)
	var v := VBoxContainer.new()
	v.position = Vector2(84, 300)
	v.add_theme_constant_override("separation", 8)
	root.add_child(v)
	art.menu = v
	var c: Dictionary = _campaign_summary()
	if c.get("exists", false):
		_menu_btn(v, "Continue run    ·    %s" % c["text"], func(): _continue())
	elif c.get("unreadable", false):
		_label(v, "Saved campaign could not be loaded. It may be damaged or from a newer version.", 13, Ink.INK, true, 360.0)
	_menu_btn(v, "New run", func(): _new_campaign_ask())
	_menu_btn(v, "Test range", func(): _test_range())
	if main.cutscene != null and main.cutscene.available():
		_menu_btn(v, "Prologue", func(): _prologue())
	_menu_btn(v, "How to play", func(): show_manual("title"))
	_menu_btn(v, "Settings", func(): show_settings("title"))
	_menu_btn(v, "Credits", func(): show_credits("title"))
	_menu_btn(v, "Quit", func(): main.get_tree().quit())


func _campaign_summary() -> Dictionary:
	var c = main.campaign
	if c == null or not SaveFile.exists(_campaign_save_path):
		return {}
	if main._placeholder:
		return {"unreadable": true}
	if c.over():
		return {"exists": true, "text": "election night · the file is closed"}
	return {"exists": true, "text": "week %d of %d, %d officers fit, account $%s" % [c.week(), c.WEEKS, c.dept.available().size(), c.dept.money(c.dept.balance)]}


func _continue() -> void:
	hide_front()
	main.ops_open()


func _new_campaign_ask() -> void:
	var c: Dictionary = _campaign_summary()
	if c.is_empty() or (c.get("exists", false) and main.campaign.over()):
		_new_campaign()
		return
	screen = "confirm_new"
	var v := _page("A new story", 620.0)
	if c.get("unreadable", false):
		_label(v, "The existing save could not be loaded. Starting over may replace it; keep a copy first if you want to recover it.", 14, Ink.INK, true)
	else:
		_label(v, "The current file (%s) has one save. Starting over replaces it." % c["text"], 14, Ink.INK, true)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var yes := Button.new()
	yes.text = "Start a new story"
	yes.pressed.connect(func(): _new_campaign())
	h.add_child(yes)
	var no := Button.new()
	no.text = "Keep my campaign"
	no.pressed.connect(func(): show_title())
	h.add_child(no)


func _new_campaign() -> void:
	hide_front()
	main.ops_new_campaign()
	var begin := func():
		main.ops_open()
		main.ops_ui.show_board()
	# 1.2: the opening cutscenes first, unless turned off in Settings
	if bool(Settings.get_v("intro")) and main.cutscene != null and main.cutscene.available():
		main.play_opening(begin)
	else:
		begin.call()


func _prologue() -> void:
	hide_front()
	main.play_opening(func(): show_title())


func _test_range() -> void:
	hide_front()
	main.ops_close()


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
	_check(v, "Line boil: the drawing shivers as if drawn right now (off: still lines)", "boil")
	_check(v, "Tips in the first weeks of a campaign", "tips")
	_check(v, "The opening cutscenes and rare campaign shorts", "intro")
	_check(v, "A short recap when you end the week (a click skips it)", "week_recap")
	_check(v, "Contact-aware fast-forward: slow for contact, injuries and radio", "adaptive_speed")
	_check(v, "Veteran chief: no Suggest a plan (every plan is yours alone)", "veteran")
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
		["%s  ·  version %s" % [CHANNEL, VERSION], 12],
		["In development: the balance, the content and the store build are not finished.", 11],
		["", 8],
		["Design: Ambidgen", 14],
		["Built with Claude (Anthropic): code, simulation, art generation and sound.", 13],
		["", 8],
		["Engine: Godot Engine 4.7 (MIT licence), godotengine.org.", 13],
		["Art: drawn in code, in crayon: scripts/view/crayon*.gd, baked by tools/bake_crayon.gd.", 13],
		["Type: Patrick Hand by Patrick Wagesreiter (SIL Open Font Licence 1.1).", 13],
		["Sound: every effect is synthesised by tools/make_sounds.py. No samples.", 13],
		["Cutscenes: native crayon drawings. Archived Remotion sources use:", 12],
		["Courier Prime, Oswald and Open Sans (SIL Open Font Licence 1.1).", 12],
		["", 8],
		["The Violence is (c) 2026 Ambidgen, all rights reserved. Every third-party component and its licence is listed in THIRD_PARTY_NOTICES, which ships with the game.", 12],
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
	["The job", """You are Port Carrick's new police chief. Before the appointment, you were deputy chief. You signed the Bridge Street eviction order; the outgoing chief gave the briefing. Dana Okonjo-Vale remembers who signed and who briefed it.

For forty weeks, the board gives you more calls than you can answer. Choose which to take, who to send and what orders they carry. Once an operation starts, your officers act on their own. You watch the plan meet the room.

The city keeps its own record: the roster, the budget, the press, four allies, three candidates and six wards. There is no clean run. There are choices—and people who live with them."""],
	["A week", """The board brings two or three calls and, more often as the election nears, a public event. Each file names a type, a ward, the ward's trust in police, how many people may be watching and any time pressure.

An officer sent to a call—or out canvassing—cannot answer another that week. With twenty officers and more calls than teams, some work will wait. The city records what you leave unattended.

End the week when you are ready—once the drafts and events on the desk are settled. Pay goes out, the city's allocation comes in, wounds heal and courses finish. The Carrick Ledger prints its account of the week."""],
	["The desk", """Every story is a run: one seed, forty weeks, one file, and a different city each time. The Desk card on the board holds what the run asks of you.

[Inheritance] In week 1, choose what the outgoing chief left you. Finished runs add more doctrines to choose from.
[Procurement] The armoury starts with patrol stock: carbines, pistols, soft vests, tasers. Every four weeks three contracts are offered; sign one or pass for surplus cash. Military hardware pleases Safe Streets and costs you the coalition.
[Training programs] Every six weeks, three programs. The one you choose teaches one habit to every officer when it ends, and the academy teaches it to every hire after.
[Offers] Candidates, allies, reporters and community leaders want something. Accept, decline, or let it lapse at the end of the week.
[Events] Something happens. Answer before the week can end. Some answers are gambles; some land weeks later.

Election night scores the run and writes it into the legacy file."""],
	["Planning an operation", """Brief and Plan has three tabs.

[Briefing] separates confirmed facts from estimates and shows the source and confidence of each tip. It is never complete. The readiness range compares the assigned force with that public intelligence; it is not a win probability. Canvassing sends an officer for two more tips and costs you that officer for the week.

[Force] assigns up to thirty officers to five squads. Kit comes from the budget. Some equipment requires tactical training.

[Orders] sets each squad's objectives—clear, arrest, rescue, contain, post or patrol—and its limits: avoid, consolidate, a phase line, an entry door, a walking pace, weapons tight, knock and announce, pistols only, less-lethal first. A leader's experience determines how many orders the squad can afford.

The map shows a clean red line. The building will not stay clean. Suggest a Plan gives you a starting point, not a decision: you choose the entry, rooms, people and risks. The debrief shows what changed and what held. Veteran Chief mode removes the suggestion.

At a rally, the briefing prices the threat estimate. Ten officers is the standing plan; lowered chatter may justify six. Static posts cost half overtime, but the clock still runs. The estimate can be wrong."""],
	["The operation", """Your officers act on training, habits, stress and judgment. Under police rules, an officer must identify a threat before firing. A suspect may give up; officers can make an arrest.

Fog of war shows what your officers can see. Everyone else remains at the radio's last reported position.

Space pauses the operation. Keys 1–7 set speed. The slider replays what you have seen; the operation never rewinds. Abort orders every squad to withdraw. The call still counts as a failure, but a withdrawal with everyone alive scores better than a loss of life."""],
	["Afterwards", """The debrief shows the score arithmetic and lists every officer, every round and every finding, with its evidence: body camera, phone video, witnesses, or nobody. Click a timeline event to seek the replay to that moment. Contact-aware fast-forward can briefly return a high playback speed to 1x for contact, casualties and important radio; it changes presentation only.

Findings that name an officer open an internal affairs case. Cases are sorted by severity and evidence, with weekly triage and filters; each case still gets its own decision. The officer gives a statement — and what they say may or may not match the bodycam. Integrity is the stat that decides, and being caught disagreeing with the tape costs more of it. The highest-integrity squadmate still standing gives testimony, which can firm up thin evidence or shake it, though video never slips. All of it is written on the case. The same stat prices the leak: clearing a case over video leaks about half the time, more when the named officer's integrity is low or their statement was already caught out, and the district attorney reads those worst of all. Clear it, send the officer to a use-of-force review, suspend them, or dismiss them. The union watches your discipline; the community coalition and the district attorney watch what you clear.

A report can reach the papers next week, months later or not at all. A lawsuit is different: it can settle against the department's account weeks after the operation."""],
	["The department", """Open an officer's file to see their record, assign training or dismiss them. Each week brings two to four applicants. You can inspect their judgment, temper, integrity, habits and pay before you hire one. The others leave. Recruits spend two weeks at the academy; lateral hires report at once.

Courses can be queued. A queued course starts when the officer is available; classroom courses can be taken while recovering. Three or more officers on the close-quarters refresher train together at a reduced cost and build squad bonds.

The budget covers pay, overtime, kit, training, medical bills and settlements. Overtime includes the callout and time on target; rally posts cost half rate. The forecast shows four weeks on today's numbers, including filed lawsuits. A grant is available while the budget chair will answer. In the red, hiring, training and new kit stop.

Deaths, wounds, dismissals and deficits lower morale. Low morale adds stress to every operation. Very low morale costs you officers."""],
	["The city", """City Hall shows the polls, four allies and trust in each ward. Each ally holds something the department needs: the budget chair controls the allocation; the union affects morale; the coalition shares community tips; the district attorney decides whether a cleared case stays closed. Lose an ally below 25 and that support goes with them. Win them back above 40.

Royce Kettering promises the police more money and fewer limits. Dana Okonjo-Vale wants the Bridge Street order read in public. Gordon Pell wants the books balanced before the next promise is made. At the end of week 40, the city votes. The winner decides whether you keep the office."""],
	["Controls", """Mouse wheel zooms. Middle- or right-drag pans. Home fits the view.
Space pauses an operation; keys 1–7 set its speed.
F2 switches off red ink. F3 switches off gore. Neither changes the simulation.
Esc opens the menu.

The test range is a sandbox: choose teams, habits and kit on any of twelve maps."""],
]


func show_manual(from: String) -> void:
	back_to = from
	visible = true
	screen = "manual"
	Settings.set_v("seen_manual", true)
	# MANUAL[manual_page] is indexed below: the --front=manual --page=N screenshot hook
	# can be handed a page that does not exist, and a clamp costs one line.
	manual_page = clampi(manual_page, 0, MANUAL.size() - 1)
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
## The title page (1.4): Port Carrick from the air under an orange smog, drawn in
## charcoal and wax — rows of housing blocks, sodium streets, chimneys pouring black smoke,
## rain — with the title printed on in crayon capitals and underlined in red, and a red
## scribble round whichever scrap of the menu the pointer is on. The city is recorded
## once (three boil variants); the smoke, the rain and the ring are drawn live.
class CityArt extends Control:
	const C = preload("res://scripts/view/crayon.gd")
	const Sketch = preload("res://scripts/view/sketch.gd")
	var menu: Control
	var version := ""
	var t := 0.0
	var _city: Array = []
	var _size := Vector2.ZERO
	var _blocks: Array = []
	var _paper: Texture2D
	var _hov: Control = null
	var _hov_t := 0.0

	func _process(delta: float) -> void:
		t += delta
		C.tick()
		var h: Control = null
		if menu != null:
			for b in menu.get_children():
				if b is Button and b.is_hovered():
					h = b
		if h != _hov:
			_hov = h
			_hov_t = 0.0
		_hov_t += delta
		queue_redraw()

	func rev(start: float, dur := 0.6) -> float:
		return clampf((t - start) / dur, 0.0, 1.0)

	func _row_y(row: int) -> float:
		return size.y * (0.33 + pow(row / 5.0, 1.35) * 0.58)

	func _row_k(row: int) -> float:
		return 0.42 + 0.58 * row / 5.0

	func _build() -> void:
		_size = size
		_paper = C.paper_texture(Vector2i(int(size.x / 2), int(size.y / 2)), C.PAPER_GREY.lightened(0.05), 33, 1.8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 404
		_blocks.clear()
		for row in 6:
			var x := -80.0 + rng.randf() * 60.0
			while x < size.x + 60.0:
				var kind := "block"
				var r := rng.randf()
				if r < 0.14:
					kind = "factory"
				elif r < 0.45:
					kind = "court"
				var w := rng.randf_range(120, 230)
				_blocks.append({"row": row, "x": x, "w": w, "d": rng.randf_range(110, 170), "h": rng.randf_range(60, 120), "kind": kind, "seed": _blocks.size() * 13})
				x += w + rng.randf_range(34, 60)
		_city = Sketch.variants(3, func(s): _paint_city(s))

	func _paint_city(ci) -> void:
		var page := Rect2(Vector2(18, 16), size - Vector2(36, 32))
		var sky := Rect2(page.position, Vector2(page.size.x, size.y * 0.37))
		C.hatch(ci, C.rect_poly(sky), Color(C.ORANGE, 0.8), 3.2, -0.25, 1, 3.0)
		C.hatch(ci, C.rect_poly(Rect2(sky.position, Vector2(sky.size.x, sky.size.y * 0.36))), Color(C.GRAPHITE, 0.55), 3.6, 0.2, 2, 3.0)
		for k in 7:
			C.smudge(ci, Vector2(120.0 + k * size.x / 7.0, 70 + 30 * C.rnd(k, 1)), 110, C.GRAPHITE)
		var top := size.y * 0.32
		C.charcoal(ci, PackedVector2Array([Vector2(page.position.x, top), Vector2(page.end.x, top), page.end, Vector2(page.position.x, page.end.y)]), C.GRAPHITE, 2.6, 5, 1.0, 2.6)
		for row in 6:
			var y := _row_y(row)
			var k := _row_k(row)
			C.hatch(ci, C.rect_poly(Rect2(page.position.x, y + 4, page.size.x, 16 * k)), Color(C.ORANGE, 0.55 + 0.15 * row / 5.0), 3.0, -0.1, 30 + row, 2.4)
			for b in _blocks:
				if int(b["row"]) == row:
					_block(ci, b, y, k)

	func _block(ci, b: Dictionary, y: float, k: float) -> void:
		var x := float(b["x"])
		var w := float(b["w"]) * k
		var d := float(b["d"]) * k * 0.5
		var h := float(b["h"]) * k
		var s := int(b["seed"])
		var x0 := x * (0.75 + 0.25 * k) + (1.0 - k) * 300.0
		var front := Rect2(Vector2(x0, y - h), Vector2(w, h))
		var roof := PackedVector2Array([Vector2(x0, y - h), Vector2(x0 + w, y - h), Vector2(x0 + w + d * 0.4, y - h - d), Vector2(x0 + d * 0.4, y - h - d)])
		ci.draw_colored_polygon(roof, C.GRAPHITE.lightened(0.18))
		C.hatch(ci, roof, C.CHARCOAL, 4.0, 0.3, s, 1.6, 1.0, 0.3)
		ci.draw_colored_polygon(C.rect_poly(front), C.GRAPHITE.darkened(0.1))
		C.hatch(ci, C.rect_poly(front), Color(C.ORANGE, 0.22), 5.0, -1.2, s + 1, 1.6)
		if b["kind"] == "court":
			var cen := (roof[0] + roof[1] + roof[2] + roof[3]) * 0.25
			var court := PackedVector2Array()
			for rp in roof:
				court.append(cen.lerp(rp, 0.55))
			ci.draw_colored_polygon(court, C.CHARCOAL)
			C.hatch(ci, court, Color(C.ORANGE, 0.35), 3.0, 0.9, s + 7, 1.4)
		var cols := maxi(3, int(w / (12.0 * maxf(0.6, k))))
		var rows := maxi(2, int(h / (11.0 * maxf(0.6, k))))
		for cx in cols:
			for ry in rows:
				var wx := front.position.x + (cx + 0.5) * w / cols
				var wy := front.position.y + (ry + 0.5) * h / rows
				var wc := C.AMBER if C.rnd(s + cx, ry) < 0.08 else C.CHARCOAL
				ci.draw_rect(Rect2(wx - 2.0 * k, wy - 2.5 * k, 4.0 * k, 5.0 * k), wc)
		C.outline(ci, C.rect_poly(front), C.CHARCOAL, 1.6, s + 3, 0.7)
		C.outline(ci, roof, C.CHARCOAL, 1.4, s + 4, 0.7)
		if b["kind"] == "factory":
			for ch in 3:
				var cx2 := x0 + w * (0.22 + ch * 0.14)
				var ctop := y - h - 70 * k - ch * 8 * k
				ci.draw_rect(Rect2(cx2 - 5 * k, ctop, 10 * k, y - h - ctop), C.CHARCOAL)

	func _smoke(base: Vector2, k: float, s: int) -> void:
		for puff in 10:
			var age := fmod(t * 0.3 + puff / 10.0, 1.0)
			var c := base + Vector2(age * 260 * k + sin(age * 6.0 + s) * 14, -age * 210 * k)
			var r := (14 + age * 60) * k
			C.hatch(self, C.ellipse_poly(c, r, r * 0.7, 12, s + puff, 0.25), Color(C.CHARCOAL, 0.9 * (1.0 - age * 0.8)), 2.8, 0.5 + puff, s + puff * 3, 2.2)

	func _draw() -> void:
		if size.x < 10.0:
			return
		if _size != size or _city.is_empty():
			_build()
		draw_texture_rect(_paper, Rect2(Vector2.ZERO, size), false)
		_city[C.frame % _city.size()].replay(self)
		for b2 in _blocks:
			if b2["kind"] == "factory":
				var k2 := _row_k(int(b2["row"]))
				_smoke(Vector2(float(b2["x"]) * (0.75 + 0.25 * k2) + (1.0 - k2) * 300.0 + float(b2["w"]) * k2 * 0.3, _row_y(int(b2["row"])) - float(b2["h"]) * k2 - 70 * k2), k2, int(b2["seed"]))
		C.rain(self, Rect2(Vector2(18, 16), size - Vector2(36, 32)), 160, 77, -0.18, 34.0)
		# the title, printed on
		var title_bg := PackedVector2Array([Vector2(60, 50), Vector2(780, 40), Vector2(792, 262), Vector2(54, 272)])
		draw_colored_polygon(title_bg, Color(C.PAPER_CREAM, 0.94))
		C.outline(self, title_bg, C.GRAPHITE, 1.5, 500, 0.8)
		C.letters(self, "PORT CARRICK POLICE DEPARTMENT  ·  OFFICE OF THE CHIEF", Vector2(90, 88), 14, C.GRAPHITE, 499, 1, 1.0, rev(0.0, 0.8))
		C.letters(self, "THE VIOLENCE", Vector2(88, 182), 84, C.CHARCOAL, 501, 3, 0.95, rev(0.2, 1.4))
		var red := Color(0.70, 0.12, 0.15)
		C.line(self, Vector2(86, 204), Vector2(86 + 640 * rev(1.5, 0.5), 200), red, 7.0, 502, 2.4, 2)
		C.line(self, Vector2(96, 216), Vector2(96 + 560 * rev(1.7, 0.5), 218), red, 4.0, 503, 2.0, 1)
		# the version line, said plainly in the corner of the title plate (P0.D1)
		C.letters(self, CHANNEL.to_upper(), Vector2(622, 84), 17, red, 505, 2, 1.0, rev(0.4, 0.7))
		C.letters(self, "V%s" % VERSION, Vector2(700, 104), 13, C.GRAPHITE, 506, 1, 1.0, rev(0.5, 0.7))
		C.letters(self, "FORTY WEEKS TO THE ELECTION  ·  EVERY RUN A DIFFERENT CITY", Vector2(90, 250), 18, C.BRICK, 504, 2, 1.0, rev(1.9, 0.8))
		# the hovered scrap, ringed in red with an arrow at it
		if _hov != null and is_instance_valid(_hov):
			var r := _hov.get_global_rect()
			r.position -= get_global_rect().position
			var w := minf(r.size.x, 22.0 + _hov.get_theme_font("font").get_string_size(_hov.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 26.0)
			var rc := Vector2(r.position.x + w * 0.5, r.get_center().y)
			C.scribble_ring(self, rc, w * 0.56, r.size.y * 0.72, red, 650, clampf(_hov_t / 0.4, 0.0, 1.0), 3.2)
			var ap := Vector2(r.position.x - 50, rc.y)
			C.line(self, ap, ap + Vector2(34, 0), red, 4.0, 660, 1.0, 1)
			C.line(self, ap + Vector2(34, 0), ap + Vector2(22, -10), red, 4.0, 661, 1.0, 1)
			C.line(self, ap + Vector2(34, 0), ap + Vector2(22, 10), red, 4.0, 662, 1.0, 1)
		# the Ledger cutting, and the footer in pencil
		var o := Vector2(size.x - 456, size.y - 270)
		var cut := PackedVector2Array([o, o + Vector2(390, -12), o + Vector2(398, 206), o + Vector2(-6, 216)])
		draw_colored_polygon(cut, C.PAPER_CREAM.darkened(0.1))
		C.outline(self, cut, C.GRAPHITE, 1.4, 700, 0.8)
		C.letters(self, "THE CARRICK LEDGER", o + Vector2(22, 40), 20, C.CHARCOAL, 701, 2)
		C.line(self, o + Vector2(20, 50), o + Vector2(370, 46), C.CHARCOAL, 2.0, 702, 0.8, 1)
		C.letters(self, "NEW CHIEF INHERITS", o + Vector2(22, 92), 26, C.CHARCOAL, 703, 2)
		C.letters(self, "BRIDGE STREET FILE", o + Vector2(22, 128), 26, C.CHARCOAL, 704, 2)
		for l in 3:
			var ly := o.y + 156.0 + l * 16.0
			C.line(self, Vector2(o.x + 22, ly), Vector2(o.x + 352 - l * 60, ly + 2), C.GRAPHITE, 2.0, 710 + l, 1.0, 1)
		C.smudge(self, o + Vector2(370, 190), 22, C.CHARCOAL)
		C.letters(self, "V%s  ·  F2 RED INK  ·  F3 GORE  ·  ESC MENU" % version, Vector2(84, size.y - 26), 14, C.CHALK, 720, 1)
