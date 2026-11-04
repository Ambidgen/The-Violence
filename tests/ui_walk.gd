extends SceneTree
## The rendered walk (EA_TASKS P0.B1): a new run driven through the real UI buttons, from
## the title to week 2 and the management screens, with checks at every step.
##
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1600x900 -s res://tests/ui_walk.gd -- \
##       [--out=DIR] [--seed=410255] [--steps=title,desk,brief,run,endweek,screens]
##   godot --headless --path . -s res://tests/ui_walk.gd        (every step and check, no screenshots)
##
## On Linux without a display: xvfb-run -s "-screen 0 1600x900x24" godot ...
##
## Writes DIR/NN_<step>.png (when rendering), DIR/NN_<step>.txt (every visible label and
## button on the side panel, disabled ones marked), DIR/walk.log and DIR/walk.json.
## Exits 1 if a check fails: a button the flow needs is missing or disabled, opening a
## briefing spends money, the operation does not end, the week does not advance, a
## management screen does not open or close, or a visible control leaves the viewport
## horizontally (the overflow check). Known problems that belong to a later cycle are
## reported as KNOWN and do not fail the walk (today: the stale tactical map behind
## management screens, EA_TASKS P3.A1).

const ALL_STEPS := ["title", "desk", "brief", "run", "endweek", "screens"]
const SCREENS := ["Roster", "Budget", "Internal affairs", "City Hall", "Armoury and programs", "Campaign file"]
const OP_WALL_LIMIT_MS := 900000      # an operation that has not ended after 15 min of wall time has hung

var main
var out := ""
var n := 0
var log_lines: Array = []
var failures: Array = []
var known: Array = []
var shots: Array = []
var rendering := true
var steps: Array = []
var facts := {}


func say(s: String) -> void:
	print("WALK ", s)
	log_lines.append(s)


func fail(what: String) -> void:
	failures.append(what)
	say("FAIL " + what)


func check(ok: bool, what: String) -> bool:
	if ok:
		say("ok   " + what)
	else:
		fail(what)
	return ok


func note_known(what: String) -> void:
	if not known.has(what):
		known.append(what)
		say("KNOWN " + what)


func frames(k: int) -> void:
	for i in k:
		await process_frame


## A screenshot (when rendering), the text of the side panel, and the overflow check.
func snap(tag: String) -> void:
	await frames(6)
	n += 1
	var base := "%s/%02d_%s" % [out, n, tag]
	if rendering:
		var img := root.get_texture().get_image()
		if img != null and not img.is_empty():
			img.save_png(base + ".png")
			shots.append(base.get_file() + ".png")
	var acc: Array = []
	_labels(main.ops_ui.root, acc)
	var f := FileAccess.open(base + ".txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(acc))
		f.close()
	_overflow(tag)


func _labels(node: Node, acc: Array) -> void:
	if node is Button and (node as Button).is_visible_in_tree():
		acc.append("[" + (node as Button).text + "]" + (" (disabled: %s)" % (node as Button).tooltip_text if (node as Button).disabled else ""))
	elif node is RichTextLabel and (node as RichTextLabel).is_visible_in_tree():
		acc.append((node as RichTextLabel).get_parsed_text())
	elif node is Label and (node as Label).is_visible_in_tree():
		acc.append((node as Label).text)
	for c in node.get_children():
		_labels(c, acc)


## A control that is visible but sits (partly) left or right of the viewport cannot be
## read or clicked. Vertical overflow inside the side panel's scroll is normal.
func _overflow(tag: String) -> void:
	var vw: float = root.get_visible_rect().size.x
	var bad: Array = []
	_overflow_walk(main.ops_ui.root, vw, bad)
	if main.front != null and main.front.visible:
		_overflow_walk(main.front, vw, bad)
	if bad.is_empty():
		return
	fail("overflow on %s: %d control(s) leave the viewport horizontally, first: %s" % [tag, bad.size(), bad[0]])


func _overflow_walk(node: Node, vw: float, bad: Array) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var r: Rect2 = (node as Control).get_global_rect()
		if r.size.x > 0.0 and (r.position.x < -1.0 or r.end.x > vw + 1.0):
			var label := ""
			if node is Button:
				label = " '%s'" % (node as Button).text
			elif node is Label:
				label = " '%s'" % (node as Label).text.substr(0, 40)
			bad.append("%s%s x %.0f..%.0f of %.0f" % [node.get_class(), label, r.position.x, r.end.x, vw])
			return
	for c in node.get_children():
		_overflow_walk(c, vw, bad)


func find_btn(node: Node, sub: String) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and sub.to_lower() in (node as Button).text.to_lower():
		return node
	for c in node.get_children():
		var r := find_btn(c, sub)
		if r != null:
			return r
	return null


## Press the first visible button whose text contains `sub`. `need` makes absence or a
## disabled button a failure; otherwise it is only logged.
func press(sub: String, need := true, ui_root: Node = null) -> bool:
	var b := find_btn(ui_root if ui_root != null else main.ops_ui.root, sub)
	if b == null:
		if need:
			fail("no button '%s' (%s)" % [sub, main.ops_ui.mode])
		else:
			say("no button '%s'" % sub)
		return false
	if b.disabled:
		if need:
			fail("button '%s' is disabled: %s" % [sub, b.tooltip_text])
		else:
			say("disabled '%s': %s" % [sub, b.tooltip_text])
		return false
	b.pressed.emit()
	return true


## Management screens should not sit over a tactical map (EA_TASKS P3.A1).
func backdrop(tag: String) -> void:
	var stale: bool = main.floorplan != null and main.floorplan.is_visible_in_tree() and not main.ops_ui.city_map.visible
	facts["backdrop_" + tag] = "tactical map" if stale else "city map"
	if stale:
		note_known("management screens sit over the last tactical map, not the city (EA_TASKS P3.A1)")


func want(step: String) -> bool:
	return steps.has(step)


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	out = args.get("out", ProjectSettings.globalize_path("user://ui_walk"))
	DirAccess.make_dir_recursive_absolute(out)
	steps = String(args.get("steps", ",".join(ALL_STEPS))).split(",", false)
	for s in steps:
		if not ALL_STEPS.has(s):
			push_error("ui_walk: unknown step '%s' (known: %s)" % [s, ", ".join(ALL_STEPS)])
			quit(2)
			return
	rendering = DisplayServer.get_name() != "headless"
	# the opening films are not part of the walk; the setting lives in this run's user://
	load("res://scripts/ui/settings.gd").set_v("intro", false)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_walk.call_deferred(int(args.get("seed", "410255")))


func _walk(seed_v: int) -> void:
	var t_start := Time.get_ticks_msec()
	await frames(30)
	facts["viewport"] = "%dx%d" % [int(root.get_visible_rect().size.x), int(root.get_visible_rect().size.y)]
	var win: Vector2i = DisplayServer.window_get_size() if rendering else Vector2i(root.size)
	facts["window"] = "%dx%d" % [win.x, win.y]
	# the project stretches canvas items: the UI is laid out at the base size and scaled to
	# the window, so a smaller window shrinks every word rather than pushing it off-screen
	facts["ui_scale"] = snappedf(minf(float(win.x) / root.get_visible_rect().size.x, float(win.y) / root.get_visible_rect().size.y), 0.01)
	facts["rendering"] = rendering
	say("window %s, layout %s (text drawn at x%.2f), rendering %s, steps %s, seed %d" % [facts["window"], facts["viewport"], facts["ui_scale"], str(rendering), ",".join(steps), seed_v])

	# ---- title -> a new run (the real button), then the fixed seed
	main.go_title()
	await frames(10)
	if want("title"):
		await snap("title")
	check(press("New run", true, main.front), "the title has a New run button")
	await frames(10)
	press("Start a new story", false, main.front)   # only when a save already exists
	await frames(10)
	check(main.campaign != null and main.campaign.run != null, "New run starts a roguelike run")
	main.front.hide_front()
	var Campaign = load("res://scripts/campaign/campaign.gd")
	main.campaign = Campaign.new()
	main.campaign.start(seed_v, true)
	main._placeholder = false
	main.dept = main.campaign.dept
	main.ops_ui.guide_dismissed = false
	main.ops_ui.guide_active = true
	main._default_selection()
	main.ops_open()
	await frames(10)
	var c = main.campaign
	facts["week1_drafts"] = c.run.drafts.map(func(d): return "%s:%s" % [d["kind"], ",".join(d["cards"])])
	say("week %d, account $%d, %d fit, desk %s" % [c.week(), c.dept.balance, c.dept.available().size(), str(facts["week1_drafts"])])
	if want("title"):
		await snap("board_week1")
		check(main.ops_ui.city_map.visible, "the board draws the city map")

	# ---- the desk: inheritance first, then procurement
	if want("desk") or want("brief") or want("run"):
		var bp := find_btn(main.ops_ui.root, "Brief and plan")
		check(bp != null and bp.disabled, "Brief and plan waits for the inheritance")
		if bp != null and bp.disabled:
			facts["first_action_reason_visible"] = false   # the reason is a tooltip only (EA_TASKS P3.B1)
			note_known("the first call's Brief and plan is disabled with its reason in a tooltip only (EA_TASKS P3.B1)")
		check(press("Open"), "the desk opens the inheritance")
		await frames(6)
		if want("desk"):
			await snap("desk_inheritance")
			backdrop("desk")
		var a0: int = c.dept.balance
		check(press("Choose"), "an inheritance can be chosen")
		await frames(6)
		check(not c.run.drafts.any(func(d): return d["kind"] == "doctrine"), "the inheritance is settled")
		facts["inheritance_cost"] = a0 - c.dept.balance
		if c.run.drafts.any(func(d): return d["kind"] == "procurement"):
			var stock0: int = c.run.armory.size()
			var a1: int = c.dept.balance
			check(press("Open"), "the desk opens procurement")
			await frames(6)
			if want("desk"):
				await snap("desk_procurement")
			check(press("Choose"), "a contract can be signed")
			await frames(6)
			facts["procurement_cost"] = a1 - c.dept.balance
			facts["armoury_items_added"] = c.run.armory.size() - stock0
			check(facts["procurement_cost"] == 0 or facts["armoury_items_added"] > 0, "a paid contract adds to the armoury")
		if want("desk"):
			await snap("board_after_desk")

	# ---- brief, force, orders
	if want("brief") or want("run"):
		var a2: int = c.dept.balance
		check(press("Brief and plan"), "the first call can be briefed after the desk")
		await frames(10)
		check(c.dept.balance == a2, "opening a briefing spends nothing (account change $%d)" % (c.dept.balance - a2))
		if want("brief"):
			await snap("briefing")
		for tname in ["Force", "Orders"]:
			if check(press(tname), "the %s tab opens" % tname):
				await frames(8)
				if want("brief"):
					await snap("tab_" + tname.to_lower())
		press("Briefing", false)
		await frames(4)

	# ---- run it, at 20x, to the debrief
	if want("run"):
		var t0 := Time.get_ticks_msec()
		if check(press("RUN"), "the plan can be run"):
			await frames(20)
			if want("run"):
				await snap("run_start")
			press("20x", false)
			var shot_mid := false
			while not main._op_done and Time.get_ticks_msec() - t0 < OP_WALL_LIMIT_MS:
				await frames(10)
				if not shot_mid and main.world != null and main.world.t > 20.0:
					shot_mid = true
					await snap("run_mid")
			facts["op_wall_ms"] = Time.get_ticks_msec() - t0
			facts["op_sim_s"] = snappedf(main.world.t, 0.1) if main.world != null else -1.0
			check(main._op_done, "the operation ends (%.0f s sim in %d ms wall)" % [facts["op_sim_s"], facts["op_wall_ms"]])
			await frames(20)
			await snap("debrief")
			check(press("Back to the board"), "the debrief returns to the board")
			await frames(10)

	# ---- end the week, answering whatever the desk holds
	if want("endweek"):
		var wk: int = c.week()
		var guard := 0
		while guard < 8:
			guard += 1
			var ew := find_btn(main.ops_ui.root, "End week")
			if ew != null and not ew.disabled:
				ew.pressed.emit()
				break
			if not press("Open", false):
				break
			await frames(6)
			if not (press("Choose", false) or press("Accept", false) or press("Decline", false)):
				press("Board", false)
			await frames(6)
		await frames(10)
		check(c.week() == wk + 1, "End week advances to week %d (now %d)" % [wk + 1, c.week()])
		facts["week2_desk"] = c.run.drafts.map(func(d): return d["kind"]) + c.run.offers.map(func(o): return "offer") + c.run.events.map(func(e): return "event")
		await snap("board_week2")

	# ---- the management screens open and close
	if want("screens"):
		for scr in SCREENS:
			if not check(press(scr), "the board opens %s" % scr):
				continue
			await frames(8)
			var tag: String = "screen_" + scr.to_lower().replace(" ", "_")
			await snap(tag)
			backdrop(tag)
			if not (press("Back to the board", false) or press("Board", false)):
				fail("%s has no way back to the board" % scr)
				main.ops_ui.show_board()
			await frames(6)
			check(main.ops_ui.mode == "board", "%s returns to the board" % scr)

	facts["wall_ms"] = Time.get_ticks_msec() - t_start
	var summary := {"seed": seed_v, "steps": steps, "failures": failures, "known": known, "facts": facts, "shots": shots,
		"engine": Engine.get_version_info()["string"]}
	var jf := FileAccess.open(out + "/walk.json", FileAccess.WRITE)
	if jf != null:
		jf.store_string(JSON.stringify(summary, "  "))
		jf.close()
	var lf := FileAccess.open(out + "/walk.log", FileAccess.WRITE)
	if lf != null:
		lf.store_string("\n".join(log_lines))
		lf.close()
	print("ui_walk: %d failure(s), %d known, %d screenshot(s) in %s" % [failures.size(), known.size(), shots.size(), out])
	for f in failures:
		print("  FAIL ", f)
	# free the game before quitting, or the engine reports resources still in use
	# (an ERROR line, which the runner counts as a failure)
	if main.world != null:
		main.world.dispose()
		main.world = null
	# EA_TASKS B4, found by the --verbose annotation (CI 40884831856, 4.4.1): the office
	# ambience was still playing when the game was freed, and the audio server let go of
	# its playback (and the .wav) only on its next mix -- after the engine counted what
	# was still in use, or before it, depending on the audio thread. Stop every player
	# and give the server a few frames first.
	for p in main.find_children("*", "AudioStreamPlayer", true, false) + main.find_children("*", "AudioStreamPlayer2D", true, false):
		p.stop()
		p.stream = null
	await frames(5)
	root.remove_child(main)
	main.free()
	# EA_TASKS B4: the game keeps fonts, textures and sounds in static caches, and what a
	# live operation puts in them depends on how many steps fit in a frame (runner
	# speed). Held at shutdown, they are "resources still in use" -- seen once on CI,
	# never in 18 local runs. Release them before quitting.
	_release_static_caches()
	# the renderer releases textures a few frames after their last user is gone
	await frames(10)
	quit(1 if not failures.is_empty() else 0)


func _release_static_caches() -> void:
	ThemeDB.fallback_font = null
	for spec in [["res://scripts/view/decals.gd", "_tex"], ["res://scripts/view/sound.gd", "_cache"],
			["res://scripts/ui/shorts.gd", "_cache"], ["res://scripts/campaign/city.gd", "_cached"]]:
		var d = load(spec[0]).get(spec[1])
		if d is Dictionary:
			(d as Dictionary).clear()
	for spec2 in [["res://scripts/view/floor_plan.gd", "_paper"], ["res://scripts/view/crayon.gd", "font"],
			["res://scripts/ui/ui.gd", "_hand"]]:
		load(spec2[0]).set(spec2[1], null)
