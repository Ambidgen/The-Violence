extends CanvasLayer
## Right-hand panel: setup (placement, echelon presets, habits, seed) and run
## (speed up to 20x, overlays, operator cards, event log). Built in code so the
## whole UI lives in one readable file. Greyscale, drafting-table style.

const Habits = preload("res://scripts/data/habits.gd")
const PANEL_W := 460.0
const INK := Color("#1c1c1c")
const SPEEDS := [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0]
const SHORT := {"untrained": "Untrained", "militia": "Militia", "regular": "Regular", "police": "Police tac", "sof": "Spec ops"}

var main
var root: PanelContainer
var setup_box: VBoxContainer
var run_box: VBoxContainer
var banner: PanelContainer
var banner_label: Label
var sel_buttons := {}
var size_spins: Array = []
var posture_opts: Array = []
var cfg_title: Label
var ech_opt: OptionButton
var plate_spin: SpinBox
var habit_buttons := {}
var tabs: TabContainer
var summary: Label
var seed_spin: SpinBox
var clock: Label
var speed_buttons: Array = []
var pause_btn: Button
var roster: RichTextLabel
var log_box: RichTextLabel
var log_shown := 0
var speed_note: Label
var _updating := false


func build(m) -> void:
	main = m
	var th := _theme()
	root = PanelContainer.new()
	root.theme = th
	root.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	root.offset_left = -PANEL_W
	add_child(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	root.add_child(v)
	var title := Label.new()
	title.text = "T H E   V I O L E N C E"
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	var sub := Label.new()
	sub.text = "Test Range 01  ·  shotgun house  ·  vertical slice"
	sub.add_theme_color_override("font_color", Color("#666666"))
	v.add_child(sub)
	v.add_child(HSeparator.new())
	setup_box = VBoxContainer.new()
	setup_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(setup_box)
	run_box = VBoxContainer.new()
	run_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	run_box.visible = false
	v.add_child(run_box)
	_build_setup()
	_build_run()
	banner = PanelContainer.new()
	banner.theme = th
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(40, 18)
	banner.visible = false
	add_child(banner)
	banner_label = Label.new()
	banner_label.add_theme_font_size_override("font_size", 22)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_label)


# ================================================================== theme
func _sb(bg: Color, border: Color, bw := 1, margin := 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_content_margin_all(margin)
	return s


func _theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 13
	th.set_stylebox("panel", "PanelContainer", _sb(Color("#f3f3f1"), INK, 1, 12.0))
	var normal := _sb(Color("#ffffff"), Color("#9a9a9a"), 1, 5.0)
	var hover := _sb(Color("#f4f4f4"), INK, 1, 5.0)
	var pressed := _sb(Color("#d4d4d1"), INK, 1, 5.0)
	var disabled := _sb(Color("#eeeeee"), Color("#cccccc"), 1, 5.0)
	var focus := StyleBoxEmpty.new()
	for t in ["Button", "OptionButton"]:
		th.set_stylebox("normal", t, normal)
		th.set_stylebox("hover", t, hover)
		th.set_stylebox("pressed", t, pressed)
		th.set_stylebox("hover_pressed", t, pressed)
		th.set_stylebox("disabled", t, disabled)
		th.set_stylebox("focus", t, focus)
		th.set_color("font_color", t, INK)
		th.set_color("font_hover_color", t, Color.BLACK)
		th.set_color("font_pressed_color", t, Color.BLACK)
		th.set_color("font_hover_pressed_color", t, Color.BLACK)
		th.set_color("font_focus_color", t, INK)
		th.set_color("font_disabled_color", t, Color("#9a9a9a"))
	th.set_color("font_color", "Label", INK)
	th.set_stylebox("normal", "LineEdit", _sb(Color("#ffffff"), Color("#9a9a9a"), 1, 4.0))
	th.set_stylebox("focus", "LineEdit", _sb(Color("#ffffff"), INK, 1, 4.0))
	th.set_color("font_color", "LineEdit", INK)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_stylebox("normal", "RichTextLabel", _sb(Color("#ffffff"), Color("#9a9a9a"), 1, 6.0))
	th.set_stylebox("background", "ProgressBar", _sb(Color("#e4e4e2"), Color("#9a9a9a"), 1, 0.0))
	th.set_stylebox("fill", "ProgressBar", _sb(Color("#3a3a3a"), Color("#3a3a3a"), 0, 0.0))
	th.set_stylebox("panel", "PopupMenu", _sb(Color("#ffffff"), INK, 1, 4.0))
	th.set_stylebox("hover", "PopupMenu", _sb(Color("#e8e8e8"), Color("#e8e8e8"), 0, 2.0))
	th.set_color("font_color", "PopupMenu", INK)
	th.set_color("font_hover_color", "PopupMenu", Color.BLACK)
	th.set_stylebox("panel", "TooltipPanel", _sb(Color("#ffffff"), INK, 1, 6.0))
	th.set_color("font_color", "TooltipLabel", INK)
	th.set_stylebox("panel", "TabContainer", _sb(Color("#ffffff"), Color("#9a9a9a"), 1, 6.0))
	th.set_stylebox("tab_selected", "TabContainer", _sb(INK, INK, 1, 6.0))
	th.set_stylebox("tab_unselected", "TabContainer", _sb(Color("#ffffff"), Color("#9a9a9a"), 1, 6.0))
	th.set_stylebox("tab_hovered", "TabContainer", _sb(Color("#eeeeee"), INK, 1, 6.0))
	th.set_color("font_selected_color", "TabContainer", Color.WHITE)
	th.set_color("font_unselected_color", "TabContainer", INK)
	th.set_color("font_hovered_color", "TabContainer", Color.BLACK)
	return th


# ================================================================== setup panel
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


func _heading(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("#555555"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func _build_setup() -> void:
	var s := setup_box
	s.add_theme_constant_override("separation", 6)
	_heading(s, "1  PLACE  ·  click the plan to place the selected operator; right-click sets facing; wheel zooms, middle-drag pans")
	var group := ButtonGroup.new()
	for k in 2:
		var h := _h(s)
		var l := Label.new()
		l.text = "Team %s" % "AB"[k]
		l.custom_minimum_size = Vector2(56, 0)
		h.add_child(l)
		var sp := SpinBox.new()
		sp.min_value = 1
		sp.max_value = 5
		sp.suffix = "operators"
		sp.custom_minimum_size = Vector2(132, 0)
		sp.value_changed.connect(func(v): _size(k, v))
		h.add_child(sp)
		size_spins.append(sp)
		var o := OptionButton.new()
		o.custom_minimum_size = Vector2(110, 0)
		for p in ["Assault", "Hold", "Hunt"]:
			o.add_item(p)
		o.item_selected.connect(func(i): main.set_posture(k, ["assault", "hold", "hunt"][i]))
		o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(o)
		posture_opts.append(o)
		var hb := _h(s)
		for slot in 5:
			var id := "%s%d" % ["AB"[k], slot + 1]
			var b := _btn(hb, id, func(on): _sel(id, on), true)
			b.button_group = group
			b.custom_minimum_size = Vector2(60, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sel_buttons[id] = b
	s.add_child(HSeparator.new())
	cfg_title = _heading(s, "2  CONFIGURE")
	var he := _h(s)
	ech_opt = OptionButton.new()
	for e in Habits.ECHELON_ORDER:
		ech_opt.add_item(Habits.ECHELONS[e]["name"])
	ech_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ech_opt.item_selected.connect(func(i): main.set_echelon(Habits.ECHELON_ORDER[i], false))
	he.add_child(ech_opt)
	_btn(he, "Apply preset", func(): main.set_echelon(Habits.ECHELON_ORDER[ech_opt.selected], true))
	var pl := Label.new()
	pl.text = "Plates"
	he.add_child(pl)
	plate_spin = SpinBox.new()
	plate_spin.min_value = 0
	plate_spin.max_value = 4
	plate_spin.custom_minimum_size = Vector2(72, 0)
	plate_spin.value_changed.connect(func(v): _plates(v))
	he.add_child(plate_spin)
	var hq := _h(s)
	_btn(hq, "All good", func(): main.bulk("good", true))
	_btn(hq, "No good", func(): main.bulk("good", false))
	_btn(hq, "Stress on", func(): main.bulk("stress", true))
	_btn(hq, "No bad", func(): main.bulk("bad", false))
	_btn(hq, "Copy to team", func(): main.copy_to_team())
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.add_child(tabs)
	var names := {"Pathfinding": "Path", "Group discipline": "Group", "Eye discipline": "Eyes", "Weapon discipline": "Weapon"}
	for grp in Habits.GROUPS:
		var sc := ScrollContainer.new()
		sc.name = names[grp]
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(sc)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(col)
		for g in Habits.GOOD:
			if g["group"] != grp:
				continue
			var gid: String = g["id"]
			var b := _btn(col, "", func(on): _habit(gid, on), true)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.tooltip_text = "%s %s\nWith it: %s\nWithout it: %s\nOverridden by: %s" % [gid, g["name"], g["with"], g["without"], _overriders(gid)]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			habit_buttons[gid] = b
	var scb := ScrollContainer.new()
	scb.name = "Bad"
	scb.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scb)
	var colb := VBoxContainer.new()
	colb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scb.add_child(colb)
	_heading(colb, "Stress-triggered: present habits switch on under fire")
	for kind in ["stress", "trait"]:
		if kind == "trait":
			_heading(colb, "Personality: present habits are always on")
		for b0 in Habits.BAD:
			if b0["kind"] != kind:
				continue
			var bid: String = b0["id"]
			var bb := _btn(colb, "", func(on): _habit(bid, on), true)
			bb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var trig: String = ("stress %.2f" % b0["t"]) if kind == "stress" else b0["trait"]
			bb.tooltip_text = "%s %s (%s)\n%s\nOverrides: %s" % [bid, b0["name"], trig, b0["desc"], ", ".join(b0["over"])]
			bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			habit_buttons[bid] = bb
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.add_child(summary)
	s.add_child(HSeparator.new())
	var hs := _h(s)
	var sl := Label.new()
	sl.text = "Seed"
	hs.add_child(sl)
	seed_spin = SpinBox.new()
	seed_spin.min_value = 1
	seed_spin.max_value = 999999
	seed_spin.value = 1001
	seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs.add_child(seed_spin)
	_btn(hs, "Random", func(): seed_spin.value = randi_range(1, 999999))
	seed_spin.custom_minimum_size = Vector2(120, 0)
	var run := _btn(s, "RUN   >   auto-resolve", func(): main.start_run(int(seed_spin.value)))
	run.custom_minimum_size = Vector2(0, 40)
	run.add_theme_font_size_override("font_size", 16)


func _size(k: int, v: float) -> void:
	if not _updating:
		main.set_team_size(k, int(v))


func _sel(id: String, on: bool) -> void:
	if on and not _updating:
		main.select_op(id)


func _plates(v: float) -> void:
	if not _updating:
		main.set_plates(int(v))


func _habit(hid: String, on: bool) -> void:
	if not _updating:
		main.set_habit(hid, on)


func _speed(sp: float, on: bool) -> void:
	if on:
		main.set_speed(sp)


func _overriders(gid: String) -> String:
	var out: Array = []
	for b in Habits.BAD:
		if gid in b["over"]:
			out.append("%s %s" % [b["id"], b["name"]])
	return ", ".join(out) if not out.is_empty() else "none"


## Refresh the setup controls from main's configuration of the selected operator.
func refresh_setup(sel: String, cfgs: Dictionary, postures: Array, sizes: Array) -> void:
	_updating = true
	for id in sel_buttons:
		sel_buttons[id].set_pressed_no_signal(id == sel)
		sel_buttons[id].disabled = not cfgs[id]["enabled"]
		var ec: String = cfgs[id]["echelon"]
		sel_buttons[id].tooltip_text = "%s  %s" % [id, Habits.ECHELONS[ec]["name"]]
	for k in 2:
		size_spins[k].set_value_no_signal(sizes[k])
	for k in 2:
		posture_opts[k].select(["assault", "hold", "hunt"].find(postures[k]))
	var c: Dictionary = cfgs[sel]
	cfg_title.text = "2  CONFIGURE %s   ·   team %s" % [sel, "AB"[c["team"]]]
	ech_opt.select(Habits.ECHELON_ORDER.find(c["echelon"]))
	plate_spin.set_value_no_signal(c["plates"])
	var n_good := 0
	var n_bad := 0
	for g in Habits.GOOD:
		var on: bool = c["good"].get(g["id"], false)
		n_good += 1 if on else 0
		var b: Button = habit_buttons[g["id"]]
		b.set_pressed_no_signal(on)
		b.text = "%s  %s   %s" % ["[x]" if on else "[  ]", g["id"], g["name"]]
	for b0 in Habits.BAD:
		var on2: bool = c["bad"].get(b0["id"], false)
		n_bad += 1 if on2 else 0
		var bb: Button = habit_buttons[b0["id"]]
		bb.set_pressed_no_signal(on2)
		var trig: String = ("stress %.2f" % b0["t"]) if b0["kind"] == "stress" else b0["trait"]
		bb.text = "%s  %s   %s   (%s)" % ["[x]" if on2 else "[  ]", b0["id"], b0["name"], trig]
	var e: Dictionary = Habits.ECHELONS[c["echelon"]]
	summary.text = "%s: %d good habits (reaction time x%.3f), %d bad habits present. Recognition base %.2f s, stress resistance %.2f, %d plate%s." % [
		sel, n_good, 1.0 - 0.005 * n_good, n_bad, e["t_rec0"], e["resist"], c["plates"], "" if c["plates"] == 1 else "s"]
	_updating = false


# ================================================================== run panel
func _build_run() -> void:
	var r := run_box
	r.add_theme_constant_override("separation", 6)
	var h := _h(r)
	pause_btn = _btn(h, "Pause", func(on): main.set_paused(on), true)
	clock = Label.new()
	clock.text = "00:00.0"
	clock.add_theme_font_size_override("font_size", 18)
	clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(clock)
	var hs := _h(r)
	var group := ButtonGroup.new()
	for sp in SPEEDS:
		var label := ("%sx" % str(sp)).replace(".0x", "x")
		var b := _btn(hs, label, func(on): _speed(sp, on), true)
		b.button_group = group
		b.custom_minimum_size = Vector2(44, 0)
		speed_buttons.append(b)
	speed_note = Label.new()
	speed_note.add_theme_color_override("font_color", Color("#666666"))
	speed_note.add_theme_font_size_override("font_size", 11)
	r.add_child(speed_note)
	var ho := _h(r)
	for nm in ["Cones", "Recognition", "Aim", "Paths"]:
		var b2 := _btn(ho, nm, func(on): main.set_overlay(nm, on), true)
		b2.set_pressed_no_signal(nm != "Paths")
	roster = RichTextLabel.new()
	roster.bbcode_enabled = true
	roster.custom_minimum_size = Vector2(0, 360)
	roster.add_theme_font_size_override("normal_font_size", 11)
	roster.add_theme_font_size_override("bold_font_size", 11)
	r.add_child(roster)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_theme_font_size_override("normal_font_size", 11)
	log_box.add_theme_font_size_override("bold_font_size", 11)
	r.add_child(log_box)
	var hb := _h(r)
	_btn(hb, "Back to setup", func(): main.back_to_setup())
	_btn(hb, "Rerun same seed", func(): main.rerun(false))
	_btn(hb, "Rerun new seed", func(): main.rerun(true))


func show_setup() -> void:
	setup_box.visible = true
	run_box.visible = false
	banner.visible = false


func show_run(speed: float) -> void:
	setup_box.visible = false
	run_box.visible = true
	banner.visible = false
	log_box.clear()
	log_shown = 0
	pause_btn.set_pressed_no_signal(false)
	for i in SPEEDS.size():
		speed_buttons[i].set_pressed_no_signal(is_equal_approx(SPEEDS[i], speed))
	roster.clear()


func refresh_run(w, actual_speed: float, target_speed: float) -> void:
	var mm := int(w.t / 60.0)
	clock.text = "%02d:%04.1f" % [mm, fmod(w.t, 60.0)]
	speed_note.text = "Simulation runs at %.1fx real time (target %sx). 30 ticks per simulated second." % [actual_speed, str(target_speed)]
	var txt_all := ""
	for o in w.ops:
		var st := "OK"
		if o.state == "dead":
			st = "KIA"
		elif o.state == "down":
			st = "DOWN"
		elif o.wounds > 0 or o.arm_hit or o.leg_hit:
			st = "WOUNDED"
		var s: Dictionary = o.ws()
		var bad: Array = []
		for b in o.active_bad:
			bad.append(b)
		var n_good := 0
		for gid in o.good:
			if o.has(gid):
				n_good += 1
		var bar := ""
		for i in 10:
			bar += "|" if i < int(o.stress * 10.0) else "."
		var head := "[b]%s[/b]  %s  ·  %s" % [o.id, SHORT.get(o.echelon, o.echelon), st]
		if st == "KIA" or st == "DOWN":
			head = "[color=#7d0a0a]%s[/color]" % head
		txt_all += "%s  ·  %s %d/%d +%d  ·  plates %d/%d  ·  %d habits\n" % [head,
			"Rifle" if o.active == "rifle" else "Pistol", s["mag"], o.wpn()["mag"], s["spare"], o.plates, o.plates_max, n_good]
		if o.alive():
			var line2 := "     stress %s %.2f" % [bar, o.stress]
			if not bad.is_empty():
				line2 += "  [b]%s[/b]" % " ".join(bad)
			txt_all += "[color=#555555]%s  ·  %s[/color]\n" % [line2, o.dbg.replace("[", "(")]
	roster.text = txt_all
	while log_shown < w.log_lines.size():
		var ln: Dictionary = w.log_lines[log_shown]
		var txt: String = ln["text"].replace("[", "(").replace("]", ")")
		match ln["kind"]:
			"kill":
				log_box.append_text("[b][color=#7d0a0a]%s[/color][/b]\n" % txt)
			"hit":
				log_box.append_text("[color=#5a1a1a]%s[/color]\n" % txt)
			"bad":
				log_box.append_text("[b]%s[/b]\n" % txt)
			"end":
				log_box.append_text("[b]%s[/b]\n" % txt)
			"comms":
				log_box.append_text("[i][color=#555555]%s[/color][/i]\n" % txt)
			"rule":
				log_box.append_text("[color=#333333]%s[/color]\n" % txt)
			_:
				log_box.append_text("[color=#444444]%s[/color]\n" % txt)
		log_shown += 1


func show_banner(text: String) -> void:
	banner_label.text = text
	banner.visible = true
