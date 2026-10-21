extends Node2D
## The Violence - vertical slice. Setup: pick a map, place up to thirty operators per
## team and edit their habits and traits. Run: the simulation auto-resolves at up to
## 20x while the plan collects the evidence.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const Level = preload("res://scripts/sim/level.gd")
const World = preload("res://scripts/sim/world.gd")
const Op = preload("res://scripts/sim/op.gd")
const FloorPlan = preload("res://scripts/view/floor_plan.gd")
const PlanWalls = preload("res://scripts/view/plan_walls.gd")
const ActualRoute = preload("res://scripts/view/actual_route.gd")
const Ink = preload("res://scripts/view/ink.gd")
const Decals = preload("res://scripts/view/decals.gd")
const ActorView = preload("res://scripts/view/actor_view.gd")
const Overlay = preload("res://scripts/view/overlay.gd")
const DoorsView = preload("res://scripts/view/doors_view.gd")
const Marks = preload("res://scripts/view/marks.gd")
const SetupMarks = preload("res://scripts/view/setup_marks.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Ledger = preload("res://scripts/view/ledger.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Campaign = preload("res://scripts/campaign/campaign.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Recorder = preload("res://scripts/sim/recorder.gd")
const Fog = preload("res://scripts/view/fog.gd")
const ReplayView = preload("res://scripts/view/replay_view.gd")
const PlanMarks = preload("res://scripts/view/plan_marks.gd")
const OpsUI = preload("res://scripts/ui/ops_ui.gd")
const PX := 40.0
const DT := 1.0 / 30.0

var level
var nav
var map_i := 0
var cfgs := {}
var postures := ["assault", "hold"]
var alerts := [1, 1]                # starting alert per team: 0 green, 1 yellow
var sizes := [3, 5]
var IDS: Array = []
var sel := "A1"
var world = null
var mode := "setup"
var speed := 2.0
var paused := false
var acc := 0.0
var actual_speed := 0.0
var _meas_real := 0.0
var _meas_sim := 0.0
var _ui_t := 0.0
var _banner_done := false

var cam: Camera2D
var floorplan
var props_layer: Node2D
var marks
var decals
var actors_layer: Node2D
var canopy_layer: Node2D
var overlay
var setup_marks
var ui
var ledger_layer: CanvasLayer
var ledger
var views := {}
var preview_ops := {}
var _panning := false

# v0.6 operations: civilians, police rules, night, and team A from the department
var n_civ := 0
var police_rules := false
var night := false
var door_mode := "open"              # test range doors (v0.7.5): open, closed, outer, locked
var use_dept := false
var dept = null                     # the department (persistent, saved in user://)
var dept_sel: Array = []            # officer ids picked for the next operation
var _a_backup := {}                 # team A's setup configurations while the department stands in
var _applied := false
var dept_lines: Array = []

# v0.7 planned operations: the campaign, the board, plans, fog of war, rewind and replay
var campaign = null
var ops_ui
var fog
var replay_view
var plan_marks
var actual_route                  # application: where the squads actually went (v0.8)
var veh_layer: Node2D
var doors_view                    # door states over the plan (v0.7.5)
var cur_sit := {}
var plan := {}
var op_mode := false
var view_t := -1.0               # rewinding: the moment shown (-1 = live)
var _paused_before := false
var replay_t := 0.0
var replay_speed := 2.0
var replay_play := false
var replay_on := false
var _op_done := false

# command-line test hooks: --autorun --seed=N --speed=X --shot=path --shot-at=T --setup-shot=path
var _args := {}


func _ready() -> void:
	get_window().title = "The Violence"
	RenderingServer.set_default_clear_color(Color("#d4d4cf"))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	for t in ["A", "B"]:
		for k in range(1, Level.MAX_TEAM + 1):
			IDS.append("%s%d" % [t, k])
	map_i = Maps.index_of(_args.get("map", "0"))
	level = Maps.get_level(map_i)
	nav = Nav.new()
	nav.build(level)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	floorplan = FloorPlan.new()
	add_child(floorplan)
	# red ink draw order (v0.8): floor, blood, walls, furniture, lettering, actors, markers
	decals = Decals.new()
	add_child(decals)
	floorplan.walls = PlanWalls.new()
	floorplan.walls.plan = floorplan
	add_child(floorplan.walls)
	floorplan.setup(level)
	props_layer = Node2D.new()
	add_child(props_layer)
	doors_view = DoorsView.new()
	add_child(doors_view)
	doors_view.setup(level)
	marks = Marks.new()
	add_child(marks)
	marks.setup(level)
	plan_marks = PlanMarks.new()
	add_child(plan_marks)
	plan_marks.visible = false
	actual_route = ActualRoute.new()
	add_child(actual_route)
	veh_layer = Node2D.new()
	add_child(veh_layer)
	fog = Fog.new()
	add_child(fog)
	actors_layer = Node2D.new()
	add_child(actors_layer)
	replay_view = ReplayView.new()
	add_child(replay_view)
	replay_view.doors_view = doors_view
	replay_view.visible = false
	canopy_layer = Node2D.new()
	canopy_layer.modulate.a = 0.8
	add_child(canopy_layer)
	_build_props()
	overlay = Overlay.new()
	add_child(overlay)
	setup_marks = SetupMarks.new()
	setup_marks.main = self
	add_child(setup_marks)
	_default_cfgs()
	_load_department()
	n_civ = clampi(int(_args.get("civ", "0")), 0, 40)
	police_rules = _args.has("police")
	if _args.has("mono"):
		Ink.set_red_ink(false)
	if _args.has("nogore"):
		Ink.set_gore(false)
	night = _args.has("night")
	ui = UI.new()
	add_child(ui)
	ui.build(self)
	ops_ui = OpsUI.new()
	add_child(ops_ui)
	ops_ui.build(self)
	ledger_layer = CanvasLayer.new()
	ledger_layer.layer = 2
	add_child(ledger_layer)
	ledger = Ledger.new()
	ledger.position = Vector2(10, 10)
	ledger_layer.add_child(ledger)
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	if _args.has("tab"):
		ui.tabs.current_tab = int(_args["tab"])
	if _args.has("select"):
		select_op(_args["select"])
	if _args.has("zoom"):
		var zf := float(_args["zoom"])
		cam.zoom *= zf
		var f: PackedStringArray = _args.get("focus", "18,12").split(",")
		cam.position = Vector2(float(f[0]), float(f[1])) * PX + Vector2(UI.PANEL_W / 2.0 / cam.zoom.x, 0)
	if _args.has("dept"):
		set_use_dept(true)
	if _args.has("doors"):
		door_mode = _args["doors"]
	_enter_setup()
	if _args.has("speed"):
		speed = float(_args["speed"])
	if _args.has("autorun"):
		start_run(int(_args.get("seed", "1001")))
	if _args.has("city"):
		start_city.call_deferred(int(_args.get("seed", "1001")), 60, 108)
	if _args.has("ops"):
		_ops_hooks.call_deferred()


# ------------------------------------------------------------------ configuration
func _cfg_for(id: String, team: int, slot: int, echelon: String) -> Dictionary:
	var c := {"id": id, "team": team, "slot": slot, "echelon": echelon, "good": {}, "bad": {},
		"plates": 0, "exp": 1, "traits": {}, "pos": level.spawns[id]["p"], "face": level.spawns[id]["face"], "enabled": true,
		"alert": alerts[team]}
	_apply_preset(c, echelon)
	return c


func _apply_preset(c: Dictionary, echelon: String) -> void:
	c["echelon"] = echelon
	c["kit"] = Equipment.preset(echelon)
	c["good"] = {}
	for g in Habits.preset_good(echelon):
		c["good"][g] = true
	var keep := {}
	for b in c["bad"]:
		if Habits.bad_info(b)["kind"] == "trait" and c["bad"][b]:
			keep[b] = true
	c["bad"] = keep
	for b in Habits.stress_bad_ids():
		c["bad"][b] = true
	c["plates"] = Habits.PRESET_PLATES[echelon]
	c["exp"] = Habits.PRESET_EXP[echelon]


## Default: an outnumbered special-operations team assaults a house held by militia.
func _default_cfgs() -> void:
	var ea: String = _args.get("a", "sof")
	var eb: String = _args.get("b", "militia")
	sizes = [clampi(int(_args.get("na", str(level.default_sizes[0]))), 1, Level.MAX_TEAM), clampi(int(_args.get("nb", str(level.default_sizes[1]))), 1, Level.MAX_TEAM)]
	cfgs = {}
	for id in IDS:
		var team := 0 if id.begins_with("A") else 1
		var slot := int(id.substr(1)) - 1
		cfgs[id] = _cfg_for(id, team, slot, ea if team == 0 else eb)
	# --gear=gas:2,gas_mask:1 (v0.8): team A carries this gear too (what its training allows)
	if _args.has("gear"):
		for id2 in IDS:
			if not id2.begins_with("A"):
				continue
			var k: Dictionary = (cfgs[id2]["kit"] as Dictionary).duplicate(true)
			for part in String(_args["gear"]).split(","):
				var kv := part.split(":")
				k["gear"][kv[0]] = int(kv[1]) if kv.size() > 1 else 1
			cfgs[id2]["kit"] = Equipment.validate(k, Equipment.who_of_echelon(ea))
	_apply_sizes()


func _apply_sizes() -> void:
	for id in IDS:
		var c: Dictionary = cfgs[id]
		c["enabled"] = c["slot"] < sizes[c["team"]]


func cfg_list() -> Array:
	var out: Array = []
	for id in IDS:
		out.append(cfgs[id])
	return out


func select_op(id: String) -> void:
	sel = id
	_refresh()


func set_team_size(k: int, n: int) -> void:
	sizes[k] = clampi(n, 1, Level.MAX_TEAM)
	_apply_sizes()
	if not cfgs[sel]["enabled"]:
		sel = "AB"[k] + "1"
	_rebuild_previews()
	_refresh()


func set_posture(k: int, p: String) -> void:
	postures[k] = p


func set_alert(k: int, lvl: int) -> void:
	alerts[k] = lvl
	for id in IDS:
		if cfgs[id]["team"] == k:
			cfgs[id]["alert"] = lvl
	_rebuild_previews()


## Leave for the endless battle (its own scene); options travel in a static.
func start_city(seed_val: int, gang_cap: int, police_cap: int) -> void:
	var CityMain = load("res://scripts/city_main.gd")
	CityMain.opts = {"seed": seed_val, "gang_cap": gang_cap, "police_cap": police_cap, "speed": speed}
	get_tree().change_scene_to_file("res://scenes/city.tscn")


func set_echelon(e: String, apply: bool) -> void:
	if apply:
		_apply_preset(cfgs[sel], e)
	else:
		cfgs[sel]["echelon"] = e
	_refresh()


func set_plates(n: int) -> void:
	cfgs[sel]["plates"] = n
	var k: Dictionary = Equipment.normalize(cfgs[sel].get("kit", {}))
	k["plates"] = n
	if n > 0:
		k["armour"] = "plates"
	elif k["armour"] == "plates":
		k["armour"] = "none"
	cfgs[sel]["kit"] = Equipment.normalize(k)
	_refresh()


## The Kit tab (v0.7.5): one field of the selected operator's kit; anything their training
## does not allow is taken out again.
func set_kit(field: String, value) -> void:
	var c: Dictionary = cfgs[sel]
	var k: Dictionary = Equipment.normalize(c.get("kit", Equipment.preset(c["echelon"])))
	k[field] = value
	if field == "armour":
		k["plates"] = 2 if value == "plates" else 0
	k = Equipment.validate(k, Equipment.who_of_echelon(c["echelon"]))
	c["kit"] = k
	c["plates"] = int(k["plates"])
	c["vest"] = k["armour"] == "vest"
	_refresh()


func set_gear(gid: String, n: int) -> void:
	var c: Dictionary = cfgs[sel]
	var k: Dictionary = Equipment.normalize(c.get("kit", Equipment.preset(c["echelon"])))
	k["gear"][gid] = n
	c["kit"] = Equipment.validate(k, Equipment.who_of_echelon(c["echelon"]))
	_refresh()


func set_door_mode(m: String) -> void:
	door_mode = m
	_refresh()


func set_exp(n: int) -> void:
	cfgs[sel]["exp"] = clampi(n, 1, Habits.EXP_MAX)
	_refresh()


func set_trait(tid: String, on: bool) -> void:
	cfgs[sel]["traits"][tid] = on
	_refresh()


## Switch maps: rebuild the plan, keep everyone's habits, move them to the new posts.
func set_map(i: int) -> void:
	if i == map_i:
		return
	_load_map(i)
	for id in IDS:
		cfgs[id]["pos"] = level.spawns[id]["p"]
		cfgs[id]["face"] = level.spawns[id]["face"]
	sizes = [level.default_sizes[0], level.default_sizes[1]]
	_apply_sizes()
	if use_dept:
		_sync_dept_cfgs()
	if not cfgs[sel]["enabled"]:
		sel = "A1"
	ui.set_map_title(level)
	_fit_camera()
	_enter_setup()


## Build a map's level, navigation, plan drawing and props (the setup and the
## operations screens share it).
func _load_map(i: int) -> void:
	map_i = i
	level = Maps.get_level(i)
	nav = Nav.new()
	nav.build(level)
	floorplan.setup(level)
	doors_view.setup(level)
	marks.setup(level)
	for ch in props_layer.get_children():
		ch.queue_free()
	for ch2 in canopy_layer.get_children():
		ch2.queue_free()
	_build_props()
	_fit_camera()


func set_habit(hid: String, on: bool) -> void:
	var key := "good" if hid.substr(0, 2) != "BH" else "bad"
	cfgs[sel][key][hid] = on
	_refresh()


func bulk(kind: String, on: bool) -> void:
	var c: Dictionary = cfgs[sel]
	match kind:
		"good":
			for g in Habits.good_ids():
				c["good"][g] = on
		"stress":
			for b in Habits.stress_bad_ids():
				c["bad"][b] = on
		"bad":
			for b in Habits.bad_ids():
				c["bad"][b] = on
	_refresh()


## Copy the selected operator's echelon, habits and plates to every teammate.
func copy_to_team() -> void:
	var c: Dictionary = cfgs[sel]
	for id in IDS:
		var m: Dictionary = cfgs[id]
		if id == sel or m["team"] != c["team"]:
			continue
		m["echelon"] = c["echelon"]
		m["good"] = c["good"].duplicate()
		m["bad"] = c["bad"].duplicate()
		m["plates"] = c["plates"]
		m["exp"] = c["exp"]
		m["traits"] = c["traits"].duplicate()
		m["kit"] = Equipment.normalize(c.get("kit", {}))
		m["vest"] = c.get("vest", false)
	_refresh()


func _refresh() -> void:
	ui.refresh_setup(sel, cfgs, postures, sizes)
	setup_marks.queue_redraw()
	if mode == "setup":
		doors_view.show_states(_preview_doors(), {})


## The test range's door setting as the doors will start (v0.7.5).
func _preview_doors() -> Dictionary:
	var out := {}
	for did in level.doors:
		var D: Dictionary = level.doors[did]
		if not D.has("leaf"):
			continue
		var ext: bool = D.get("exterior", false)
		match door_mode:
			"closed":
				if not ext:
					out[did] = "closed"
			"outer":
				if ext:
					out[did] = "locked"
			"locked":
				out[did] = "locked" if ext else "closed"
	return out


# ------------------------------------------------------------------ the department (v0.5)
## Load the saved campaign (and with it the department), or start one. v0.7 keeps the
## department inside the campaign save; a v0.6 department.json is left as it was.
func _load_department() -> void:
	if not _args.has("new-campaign"):
		campaign = Campaign.load_from()
	if campaign == null:
		campaign = Campaign.new()
		campaign.start(int(_args.get("dept-seed", "1001")))
		campaign.save()
	dept = campaign.dept
	_default_selection()


func _save() -> void:
	if campaign != null:
		campaign.save()


func _default_selection() -> void:
	var av: Array = dept.available()
	av.sort_custom(func(a, b):
		var ra: int = Department.RANKS.find(a["rank"])
		var rb: int = Department.RANKS.find(b["rank"])
		if ra != rb:
			return ra > rb
		return int(a["xp"]) > int(b["xp"]))
	dept_sel = []
	for r in av.slice(0, 6):
		dept_sel.append(r["id"])


## Team A is the department's officers (police rules on), or the setup's operators.
func set_use_dept(on: bool) -> void:
	if on == use_dept:
		return
	use_dept = on
	if on:
		_a_backup = {}
		for id in IDS:
			_a_backup[id] = cfgs[id].duplicate(true)
		_a_backup["_sizes"] = sizes.duplicate()
		_a_backup["_alerts"] = alerts.duplicate()
		_a_backup["_postures"] = postures.duplicate()
		_sync_dept_cfgs()
		# team B becomes a gang house: four suspects, relaxed, holding (change it freely)
		if not _args.has("nb"):
			var mix := ["militia", "untrained", "untrained", "militia"]
			for k in 4:
				_apply_preset(cfgs["B%d" % (k + 1)], mix[k])
			sizes[1] = 4
			postures[1] = "hold"
			set_alert(1, 0)
			_apply_sizes()
			_sync_dept_cfgs()
	else:
		for id in IDS:
			if _a_backup.has(id):
				cfgs[id] = _a_backup[id]
		sizes = _a_backup.get("_sizes", sizes)
		alerts = _a_backup.get("_alerts", alerts)
		postures = _a_backup.get("_postures", postures)
		_apply_sizes()
	if not cfgs[sel]["enabled"]:
		sel = "A1"
	_rebuild_previews()
	_refresh()


## Write the picked officers into team A's slots (keeping where they were placed).
func _sync_dept_cfgs() -> void:
	dept_sel = dept_sel.filter(func(oid): return dept.get_officer(oid).get("status", "") == "active")
	var picked: Array = []
	for oid in dept_sel:
		picked.append(dept.get_officer(oid))
	for k in Level.MAX_TEAM:
		var id := "A%d" % (k + 1)
		if k < picked.size():
			var c: Dictionary = dept.to_cfg(picked[k], k, level, alerts[0])
			c["pos"] = cfgs[id]["pos"]
			c["face"] = cfgs[id]["face"]
			cfgs[id] = c
		else:
			cfgs[id]["enabled"] = false
	sizes[0] = maxi(1, picked.size())
	for k2 in Level.MAX_TEAM:
		var id2 := "A%d" % (k2 + 1)
		cfgs[id2]["enabled"] = k2 < picked.size()


func toggle_officer(oid: String, on: bool) -> void:
	if on and not dept_sel.has(oid) and dept_sel.size() < Level.MAX_TEAM:
		dept_sel.append(oid)
	elif not on:
		dept_sel.erase(oid)
	if use_dept:
		_sync_dept_cfgs()
		if not cfgs[sel]["enabled"]:
			sel = "A1" if cfgs["A1"]["enabled"] else "B1"
		_rebuild_previews()
		_refresh()
	ui.refresh_dept(dept, dept_sel)


func hire_recruit() -> void:
	var r: Dictionary = dept.recruit(false)
	if r.is_empty():
		return
	_save()
	ui.refresh_dept(dept, dept_sel)


func next_week() -> void:
	for ln in dept.next_week():
		dept.note(ln)
	_save()
	ui.refresh_dept(dept, dept_sel)


func new_department(seed_val: int) -> void:
	campaign = Campaign.new()
	campaign.start(seed_val)
	dept = campaign.dept
	_save()
	_default_selection()
	if use_dept:
		_sync_dept_cfgs()
		_rebuild_previews()
		_refresh()
	ui.refresh_dept(dept, dept_sel)


func set_bodycams(on: bool) -> void:
	dept.bodycams = on
	_save()
	if use_dept:
		_sync_dept_cfgs()


func set_civilians(n: int) -> void:
	n_civ = clampi(n, 0, 40)
	_rebuild_previews()


func set_police_rules(on: bool) -> void:
	police_rules = on


func set_night(on: bool) -> void:
	night = on


# ------------------------------------------------------------------ planned operations (v0.7)
## Command-line hooks for screenshots and soak runs: --ops [--ops-select=W1-2]
## [--ops-tab=0..2] [--ops-run] [--ops-abort-at=T] [--ops-replay-at=T]
func _ops_hooks() -> void:
	ops_open()
	if _args.has("ops-select"):
		var sid: String = _args["ops-select"]
		if sid.is_valid_int():
			sid = campaign.board[clampi(int(sid), 0, campaign.board.size() - 1)]["id"]
		ops_select(sid)
		if _args.has("ops-tab"):
			ops_ui.tab = int(_args["ops-tab"])
			ops_ui.show_plan()
		if _args.has("ops-run"):
			ops_run()
	# v0.8.5 screens: --ops-screen=roster|budget|cases [--ops-demo-cases] [--ops-open=N]
	if _args.has("ops-demo-cases"):
		var d = campaign.dept
		var av: Array = d.available()
		d.open_case(av[3], "misjudgment", "fired at a man holding a phone", "witness", "the kitchen, 39 Canal Street")
		d.open_case(av[7], "broke_order", "broke the avoid order (chased a contact)", "radio log", "the yard")
		d.enrol(av[9], "firearms")
		d.recruit(false)
	if _args.has("ops-screen"):
		if _args.has("ops-open"):
			ops_ui.roster_open = campaign.dept.available()[int(_args["ops-open"])]["id"]
		match String(_args["ops-screen"]):
			"roster":
				ops_ui._roster()
			"budget":
				ops_ui._budget()
			"cases":
				ops_ui._cases()


## The operations board: the week's situations.
func ops_open() -> void:
	if world != null:
		world.dispose()
		world = null
	mode = "board"
	op_mode = false
	_clear_views()
	_clear_op_views()
	ui.root.visible = false
	ui.banner.visible = false
	setup_marks.visible = false
	ops_ui.show_board()


func ops_close() -> void:
	_clear_op_views()
	ops_ui.hide_all()
	ui.root.visible = true
	setup_marks.visible = true
	op_mode = false
	_enter_setup()


func ops_board() -> void:
	if world != null:
		world.dispose()
		world = null
	mode = "board"
	op_mode = false
	_clear_views()
	_clear_op_views()
	ui.banner.visible = false
	_save()
	ops_ui.show_board()


func _clear_op_views() -> void:
	plan_marks.clear()
	fog.setup(null, false)
	replay_view.clear()
	replay_on = false
	replay_play = false
	view_t = -1.0
	actors_layer.visible = true
	decals.visible = true
	overlay.visible = true
	decals.setup_empty()
	overlay.setup(null)
	overlay.fog = null
	ledger.setup(null)
	for c in veh_layer.get_children():
		c.queue_free()


## The department changed from a panel (training, hiring, a case decided): save it.
func ops_dept_changed() -> void:
	_save()


func ops_end_week() -> Array:
	var lines: Array = campaign.end_week()
	_save()
	_default_selection()
	return lines


func ops_new_campaign() -> void:
	campaign = Campaign.new()
	campaign.start(randi_range(1, 999999))
	dept = campaign.dept
	_save()
	_default_selection()
	ops_ui.show_board(["A new campaign: week 1."])


## Brief and plan one situation: its map, its plan (or a suggested one).
func ops_select(sid: String) -> void:
	cur_sit = campaign.get_sit(sid)
	if cur_sit.is_empty():
		return
	_load_map(int(cur_sit["map"]))
	ui.set_map_title(level)
	if cur_sit.get("plan", {}).is_empty():
		var av: Array = campaign.available_for(sid)
		cur_sit["plan"] = Autoplan.suggest(cur_sit, av, level, dept.bodycams, Autoplan.share(campaign.board, sid, av.size()))
	plan = cur_sit["plan"]
	mode = "plan"
	_clear_views()
	plan_marks.setup(level, nav, cur_sit, plan)
	floorplan.set_state("theory")
	actual_route.clear()
	ops_ui.tab = 0
	ops_ui.sel_sq = 0
	ops_ui.set_pick({})
	ops_ui.show_plan()


func plan_changed() -> void:
	cur_sit["plan"] = plan
	plan_marks.changed()


func ops_suggest() -> void:
	var av: Array = campaign.available_for(cur_sit["id"])
	plan = Autoplan.suggest(cur_sit, av, level, dept.bodycams, Autoplan.share(campaign.board, cur_sit["id"], av.size()))
	cur_sit["plan"] = plan
	plan_marks.setup(level, nav, cur_sit, plan)
	ops_ui.show_plan()


func ops_canvass(oid: String) -> void:
	for sq in plan.get("squads", []):
		sq["members"].erase(oid)
	campaign.canvass(cur_sit["id"], oid)
	_save()
	plan_changed()
	ops_ui.show_plan()


func ops_set_night(on: bool) -> void:
	plan["night"] = on


func ops_set_bodycams(on: bool) -> void:
	dept.bodycams = on
	plan["bodycams"] = on
	_save()
	ops_ui.show_plan()


## Run the plan: build the operation from the situation and the plan, with the fog on.
func ops_run() -> void:
	if campaign.plan_members(cur_sit).is_empty():
		return
	plan["bodycams"] = dept.bodycams
	var b: Dictionary = Operation.build_planned(cur_sit, plan, dept, level, nav)
	if world != null:
		world.dispose()
	world = World.new()
	world.setup(level, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	world.recorder = Recorder.new(world)
	plan_marks.clear()
	decals.setup(world)
	decals.fog = fog
	actual_route.setup(world, 0)
	_stamp_t = -9.0
	overlay.setup(world)
	overlay.fog = fog
	fog.setup(world, true)
	ledger.setup(world, 8)
	replay_view.clear()
	_clear_views()
	for o in world.ops:
		var v = ActorView.new()
		actors_layer.add_child(v)
		v.setup(o, world)
		views[o.id] = v
	for c in veh_layer.get_children():
		c.queue_free()
	for vp in world.vehicles:
		var car := Sprite2D.new()
		car.texture = Decals.tex("veh/police_car")
		car.position = (vp as Vector2) * PX
		car.scale = Vector2.ONE * 0.5
		car.modulate.a = 0.85
		veh_layer.add_child(car)
	mode = "run"
	op_mode = true
	_op_done = false
	view_t = -1.0
	acc = 0.0
	paused = false
	_banner_done = true
	ui.banner.visible = false
	ops_ui.show_run()


func ops_abort() -> void:
	if world != null and not world.over:
		world.abort()


## Rewind: show the record at tt, as it was known then. The simulation waits.
func ops_rewind(tt: float) -> void:
	if world == null or world.recorder == null:
		return
	if view_t < 0.0:
		_paused_before = paused
	paused = true
	view_t = tt
	if replay_view.rec != world.recorder:
		replay_view.setup(world.recorder, true)
	replay_view.visible = true
	replay_view.show_at(tt)
	actors_layer.visible = false
	decals.visible = false
	overlay.visible = false
	fog.visible = false


func ops_live() -> void:
	if view_t < 0.0:
		return
	view_t = -1.0
	paused = _paused_before
	replay_view.visible = false
	actors_layer.visible = true
	decals.visible = true
	overlay.visible = true
	fog.visible = fog.enabled


## The operation is over: score it, write it into the department and the campaign,
## lift the fog, and show the debrief.
func _op_finished() -> void:
	_op_done = true
	if view_t >= 0.0:
		ops_live()
	var res: Dictionary = Outcome.evaluate(cur_sit, world)
	var lines: Array = dept.apply_result(world, level.map_name)
	for b in world.broken:
		var o = world.by_id.get(b["id"], null)
		if o != null and o.officer_id != "":
			var r: Dictionary = dept.get_officer(o.officer_id)
			if not r.is_empty():
				r["orders_broken"] = int(r.get("orders_broken", 0)) + 1
				r["file"].append({"week": dept.week, "text": "Broke the %s order (%s, %s)." % [b["order"], b["why"], b["where"]]})
				if r["status"] != "dead":
					var c: Dictionary = dept.open_case(r, "broke_order", "broke the %s order (%s)" % [b["order"], b["why"]], "radio log", String(b["where"]))
					lines.append("Internal affairs: %s opened on %s %s (broke an order)." % [c["id"], r["rank"], r["name"]])
	res["plan"] = plan.duplicate(true)
	campaign.record(cur_sit["id"], res)
	_save()
	fog.enabled = false
	fog.visible = false
	decals.reveal(true)
	_update_stamp(true)
	_views_by_fog()
	ui.show_banner("%s   ·   %d" % [String(res["label"]).to_upper(), int(res["score"])])
	ops_ui.show_debrief(res, world, lines)


func ops_replay_play(on: bool) -> void:
	if world == null or world.recorder == null:
		return
	if not replay_on:
		replay_on = true
		replay_view.setup(world.recorder, false)
		replay_t = 0.0
	replay_play = on
	replay_view.visible = true
	actors_layer.visible = false
	decals.visible = false
	overlay.visible = false
	replay_view.show_at(replay_t)


func ops_replay_seek(v: float) -> void:
	if world == null or world.recorder == null:
		return
	if not replay_on:
		ops_replay_play(false)
	replay_t = v
	replay_view.show_at(replay_t)
	ops_ui.refresh_replay(replay_t, world.t, replay_play)


func _views_by_fog() -> void:
	for o in world.ops:
		var v = views.get(o.id, null)
		if v == null:
			continue
		if o.gone:
			v.visible = false
		elif fog.enabled:
			v.visible = o.judges or fog.visible_ids.has(o.id) or fog.bodies.has(o.id)
		else:
			v.visible = true


## With the fog on, a shot, a shout or a flash is drawn only if an officer made it or a
## camera can see it.
func _ev_visible(ev: Dictionary) -> bool:
	if not op_mode or not fog.enabled:
		return true
	match ev["type"]:
		"shot":
			var sh = world.by_id.get(ev.get("id", ""), null)
			return (sh != null and sh.judges) or fog.visible_at(ev["from"]) or fog.visible_at(ev["to"])
		"float", "impact", "plate":
			return fog.visible_at(ev["p"])
		"bad_on", "heard":
			var o = world.by_id.get(ev.get("id", ""), null)
			return o != null and o.judges
	return true


# ------------------------------------------------------------------ views
func _build_props() -> void:
	for pr in level.props:
		var s := Sprite2D.new()
		s.texture = Decals.tex(pr["key"])
		var r: Rect2 = pr["r"]
		s.position = r.get_center() * PX
		var rot: float = pr["rot"]
		s.rotation = deg_to_rad(rot)
		var ts: Vector2 = s.texture.get_size()
		var want := r.size * PX
		if int(rot) % 180 != 0:
			want = Vector2(want.y, want.x)
		s.scale = Vector2(want.x / ts.x, want.y / ts.y)
		if pr.get("under", false):
			canopy_layer.add_child(s)
		else:
			props_layer.add_child(s)


func _clear_views() -> void:
	for v in views.values():
		v.queue_free()
	views.clear()


func _rebuild_previews() -> void:
	_clear_views()
	preview_ops.clear()
	for id in cfgs:
		var c: Dictionary = cfgs[id]
		if not c["enabled"]:
			continue
		var o = Op.new()
		o.configure(c)
		o.reset()
		preview_ops[id] = o
		var v = ActorView.new()
		actors_layer.add_child(v)
		v.setup(o, null)
		views[id] = v
	if n_civ > 0 and ui != null:
		for c2 in Operation.civilians(level, nav, n_civ, int(ui.seed_spin.value)):
			var oc = Op.new()
			oc.configure(c2)
			oc.reset()
			var vc = ActorView.new()
			actors_layer.add_child(vc)
			vc.setup(oc, null)
			views[c2["id"]] = vc


func _enter_setup() -> void:
	mode = "setup"
	if world != null:
		world.dispose()
		world = null
	decals.setup_empty()
	actual_route.clear()
	floorplan.set_state("theory")
	overlay.setup(null)
	ledger.setup(null)
	overlay.queue_redraw()
	_rebuild_previews()
	ui.show_setup()
	_refresh()
	if _args.has("dept-panel"):
		ui.show_dept()


func start_run(seed_val: int) -> void:
	if world != null:
		world.dispose()
	var all: Array = Operation.build(cfg_list(), level, nav, {"civilians": n_civ, "seed": seed_val})
	world = World.new()
	world.setup(level, nav, all, postures, seed_val, alerts, {"police_rules": police_rules or use_dept, "night": night,
		"door_mode": door_mode})
	_applied = false
	dept_lines = []
	decals.setup(world)
	actual_route.setup(world, 0)
	_stamp_t = -9.0
	overlay.setup(world)
	ledger.setup(world, 8)
	_clear_views()
	for o in world.ops:
		var v = ActorView.new()
		actors_layer.add_child(v)
		v.setup(o, world)
		views[o.id] = v
	mode = "run"
	acc = 0.0
	paused = false
	_banner_done = false
	ui.show_run(speed)
	setup_marks.queue_redraw()


func back_to_setup() -> void:
	_enter_setup()


func rerun(new_seed: bool) -> void:
	var s: int = world.seed_used if world != null else 1001
	if new_seed:
		s = randi_range(1, 999999)
	start_run(s)


func set_speed(sp: float) -> void:
	speed = sp


func set_paused(on: bool) -> void:
	paused = on


func set_overlay(nm: String, on: bool) -> void:
	match nm:
		"Cones":
			overlay.show_cones = on
		"Recognition":
			overlay.show_rec = on
		"Aim":
			overlay.show_aim = on
		"Paths":
			overlay.show_paths = on


# ------------------------------------------------------------------ loop
func _process(delta: float) -> void:
	if replay_on and world != null:
		if replay_play:
			replay_t = minf(replay_t + delta * replay_speed, world.t)
			if replay_t >= world.t:
				replay_play = false
			replay_view.show_at(replay_t)
		ops_ui.refresh_replay(replay_t, world.t, replay_play)
	if mode == "run" and world != null and view_t < 0.0 and not replay_on:
		doors_view.refresh()
	if mode == "run" and world != null:
		var steps := 0
		if not paused and not world.over:
			acc += delta * speed
			var t0 := Time.get_ticks_usec()
			while acc >= DT and not world.over:
				world.step()
				acc -= DT
				steps += 1
				if Time.get_ticks_usec() - t0 > 33000:
					break
			acc = minf(acc, DT * 3.0)
		if world.t - _stamp_t >= 1.0 or (world.over and _stamp_t < world.t):
			_stamp_t = world.t
			_update_stamp()
		_meas_real += delta
		_meas_sim += steps * DT
		if _meas_real >= 0.5:
			actual_speed = _meas_sim / _meas_real
			_meas_real = 0.0
			_meas_sim = 0.0
		for ev in world.events:
			decals.handle(ev)
			if _ev_visible(ev):
				overlay.handle(ev)
			if ev["type"] == "blood" and views.has(ev["id"]):
				views[ev["id"]].stain(ev["zone"], ev["side"])
		world.events.clear()
		for v in views.values():
			v.sync()
		if op_mode:
			fog.tick(delta)
			decals.reveal()
			_views_by_fog()
		overlay.tick_real(delta)
		ledger.tick(delta)
		_ui_t -= delta
		if _ui_t <= 0.0:
			_ui_t = 0.1
			if op_mode:
				ops_ui.refresh_run(world, fog)
			else:
				ui.refresh_run(world, actual_speed, speed)
		if op_mode and world.over and not _op_done:
			_op_finished()
		if world.over and not _banner_done:
			_banner_done = true
			ui.refresh_run(world, actual_speed, speed)
			var names := ["TEAM A WINS", "TEAM B WINS", "DRAW", "ABORTED"]
			if world.police_rules():
				names = ["SUSPECTS STOPPED", "POLICE DEFEATED", "DRAW", "ABORTED"]
			ui.show_banner("%s   ·   %02d:%04.1f" % [names[world.winner], int(world.t / 60.0), fmod(world.t, 60.0)])
			if use_dept and not _applied and dept != null:
				_applied = true
				dept_lines = dept.apply_result(world, level.map_name)
				_save()
			ui.show_debrief(world, dept_lines, use_dept)
	_test_hooks()


## Application stamps on the title block (v0.8): the actual time, and the paperwork the
## operation has generated so far. Filed once it is over.
var _stamp_t := -9.0


func _update_stamp(filed := false) -> void:
	if world == null:
		return
	var forms := 1
	var mop := false
	for o in world.ops:
		if not o.alive():
			forms += 2
			mop = true
		elif o.wounds > 0:
			forms += 1
			mop = true
	floorplan.set_state("application", {"actual": world.t, "forms": forms, "mop": mop, "filed": filed or world.over})


## Presentation toggles (v0.8): the monochrome proof and gore. Neither touches the world.
func set_red_ink(on: bool) -> void:
	Ink.set_red_ink(on)
	_ink_changed()


func set_gore(on: bool) -> void:
	Ink.set_gore(on)
	_ink_changed()


func _ink_changed() -> void:
	ui.sync_ink()
	_redraw_all(self)
	if mode == "plan":
		ops_ui.show_plan()


static func _redraw_all(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for c in n.get_children():
		_redraw_all(c)


func _test_hooks() -> void:
	if op_mode and world != null and _args.has("ops-abort-at") and world.t >= float(_args["ops-abort-at"]) and not world.aborted:
		ops_abort()
	if _args.has("ops-replay-at") and _op_done and not replay_on:
		ops_replay_seek(float(_args["ops-replay-at"]))
	if _args.has("ops-rewind-at") and op_mode and world != null and not _op_done and world.t >= float(_args.get("shot-at", "9999")) - 0.05 and view_t < 0.0:
		ops_rewind(float(_args["ops-rewind-at"]))
	if _args.has("setup-tab") and Engine.get_process_frames() == 4:
		ui.tabs.current_tab = int(_args["setup-tab"])
		if _args.has("doors"):
			set_door_mode(_args["doors"])
		if _args.has("sel"):
			select_op(_args["sel"])
	if _args.has("setup-shot") and Engine.get_process_frames() == 8:
		_shot(_args["setup-shot"])
		if not _args.has("autorun"):
			get_tree().quit()
	if _args.has("shot") and world != null:
		var at := float(_args.get("shot-at", "9999"))
		if world.t >= at or world.over:
			if not _args.has("_shot_wait"):
				_args["_shot_wait"] = Engine.get_process_frames()
			elif Engine.get_process_frames() - int(_args["_shot_wait"]) > 3:
				_shot(_args["shot"])
				get_tree().quit()


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)


# ------------------------------------------------------------------ camera and input
func _fit_camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	var avail := Vector2(vs.x - UI.PANEL_W, vs.y)
	var map_px := Vector2(level.W * PX + 140, level.H * PX + 316)
	var z := minf(avail.x / map_px.x, avail.y / map_px.y)
	cam.zoom = Vector2(z, z)
	var centre := Vector2(level.W * PX / 2.0, (level.H * PX + 156.0) / 2.0)
	cam.position = centre + Vector2(UI.PANEL_W / 2.0 / z, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				var f := 1.12 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12
				var before := get_global_mouse_position()
				cam.zoom = (cam.zoom * f).clamp(Vector2(0.3, 0.3), Vector2(4, 4))
				cam.position += (before - cam.position) * (1.0 - 1.0 / f)
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE or (mb.button_index == MOUSE_BUTTON_RIGHT and mode == "run"):
			_panning = mb.pressed
			return
		if mode == "plan" and mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
			ops_ui.map_click(get_global_mouse_position() / PX, mb.button_index == MOUSE_BUTTON_RIGHT)
			return
		if mode == "setup" and mb.pressed:
			var p := get_global_mouse_position() / PX
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if p.x > 0.3 and p.y > 0.3 and p.x < level.W - 0.3 and p.y < level.H - 0.3 and nav.is_free(p):
					cfgs[sel]["pos"] = p
					_rebuild_previews()
					_refresh()
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				var c: Dictionary = cfgs[sel]
				c["face"] = (p - c["pos"]).angle()
				_rebuild_previews()
				_refresh()
	elif event is InputEventMouseMotion and _panning:
		cam.position -= (event as InputEventMouseMotion).relative / cam.zoom.x
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if mode == "run":
			if k == KEY_SPACE:
				paused = not paused
				ui.pause_btn.set_pressed_no_signal(paused)
			elif k >= KEY_1 and k <= KEY_7:
				var i := k - KEY_1
				speed = UI.SPEEDS[i]
				ui.speed_buttons[i].set_pressed_no_signal(true)
			elif k == KEY_ESCAPE and not op_mode:
				back_to_setup()
		if k == KEY_HOME:
			_fit_camera()
		elif k == KEY_F2:
			set_red_ink(not Ink.red_ink_enabled)
		elif k == KEY_F3:
			set_gore(not Ink.gore_enabled)
