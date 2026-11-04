extends SceneTree
## Rendered click-through of the roguelike campaign: real buttons, real frames (software GL).
##   godot --path . --rendering-driver opengl3 -s res://ui_walk.gd -- --out=/dir --seed=410255

var main
var out := "/tmp/shots"
var n := 0
var log_lines: Array = []


func say(s: String) -> void:
	print("WALK ", s)
	log_lines.append(s)


func frames(k: int) -> void:
	for i in k:
		await process_frame


func shot(tag: String) -> void:
	await frames(6)
	n += 1
	var img := root.get_texture().get_image()
	var p := "%s/%02d_%s.png" % [out, n, tag]
	img.save_png(p)
	say("shot %s %dx%d" % [tag, img.get_width(), img.get_height()])


func find_btn(node: Node, sub: String) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and sub.to_lower() in (node as Button).text.to_lower():
		return node
	for c in node.get_children():
		var r := find_btn(c, sub)
		if r != null:
			return r
	return null


## Press the first visible button whose text contains `sub`. Returns false if absent/disabled.
func press(sub: String, ui_root: Node = null) -> bool:
	var b := find_btn(ui_root if ui_root != null else main.ops_ui.root, sub)
	if b == null:
		say("NO BUTTON '%s'" % sub)
		return false
	if b.disabled:
		say("DISABLED '%s' tooltip='%s'" % [sub, b.tooltip_text])
		return false
	b.pressed.emit()
	return true


func labels(node: Node, acc: Array) -> void:
	if node is Label and (node as Label).is_visible_in_tree():
		acc.append((node as Label).text)
	elif node is RichTextLabel and (node as RichTextLabel).is_visible_in_tree():
		acc.append((node as RichTextLabel).get_parsed_text())
	elif node is Button and (node as Button).is_visible_in_tree():
		acc.append("[" + (node as Button).text + "]" + (" (disabled)" if (node as Button).disabled else ""))
	for c in node.get_children():
		labels(c, acc)


func dump(tag: String) -> void:
	var acc: Array = []
	labels(main.ops_ui.root, acc)
	var f := FileAccess.open("%s/%02d_%s.txt" % [out, n, tag], FileAccess.WRITE)
	f.store_string("\n".join(acc))
	f.close()


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	out = args.get("out", out)
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	run.call_deferred(int(args.get("seed", "410255")))


func run(seed_v: int) -> void:
	await frames(40)
	main.go_title()
	await frames(30)
	await shot("title")
	# --- the real title button, then swap in a fixed seed
	press("New run", main.front)
	await frames(30)
	await shot("after_new_run_click")
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
	say("week %d drafts=%s account=%d fit=%d" % [c.week(), str(c.run.drafts.map(func(d): return d["kind"] + ":" + ",".join(d["cards"]))), c.dept.balance, c.dept.available().size()])
	await shot("board_week1")
	dump("board_week1")
	# first call: is Brief and plan blocked?
	press("Brief and plan")
	await frames(4)
	# open inheritance
	press("Open")
	await frames(6)
	await shot("inheritance")
	dump("inheritance")
	press("Choose")
	await frames(6)
	say("after inheritance: drafts=%s account=%d" % [str(c.run.drafts.map(func(d): return d["kind"] + ":" + ",".join(d["cards"]))), c.dept.balance])
	await shot("after_inheritance")
	# procurement
	if press("Open"):
		await frames(6)
		await shot("procurement")
		dump("procurement")
		press("Choose")
		await frames(6)
		say("after procurement: contracts=%s armory=%d account=%d" % [str(c.run.contracts), c.run.armory.size(), c.dept.balance])
	await shot("board_after_desk")
	dump("board_after_desk")
	# brief the first open situation
	var acct0: int = c.dept.balance
	press("Brief and plan")
	await frames(10)
	say("briefing opened; account change=%d" % (c.dept.balance - acct0))
	await shot("briefing")
	dump("briefing")
	# tabs: Force, Orders
	for tname in ["Force", "Orders"]:
		if press(tname):
			await frames(8)
			await shot("tab_" + tname.to_lower())
			dump("tab_" + tname.to_lower())
	press("Brief")
	await frames(4)
	# run it
	var t0 := Time.get_ticks_msec()
	if press("RUN"):
		await frames(30)
		await shot("run_start")
		var guard := 0
		while not main._op_done and guard < 900:
			guard += 1
			await frames(10)
			if guard == 2:
				await shot("run_mid")
				press("20x")
			if guard % 20 == 0:
				say("live t=%.1f mode=%s" % [main.world.t if main.world != null else -1.0, main.mode])
			if main._op_done:
				break
		say("operation took %d ms wall, mode=%s" % [Time.get_ticks_msec() - t0, main.mode])
		await frames(20)
		await shot("debrief")
		dump("debrief")
	# back to the board, then the rest of week 1
	press("Back to the board")
	await frames(10)
	await shot("board_after_op")
	dump("board_after_op")
	say("after op1: account=%d fit=%d week=%d" % [c.dept.balance, c.dept.available().size(), c.week()])
	# end the week (events may block)
	var loops := 0
	while loops < 6:
		loops += 1
		if press("End week"):
			break
		if press("Open"):
			await frames(6)
			await shot("desk_item_%d" % loops)
			dump("desk_item_%d" % loops)
			if not (press("Choose") or press("Accept")):
				press("Board")
			await frames(6)
		else:
			break
	await frames(10)
	await shot("week2_board")
	dump("week2_board")
	say("week2: week=%d account=%d fit=%d drafts=%s offers=%d events=%d" % [c.week(), c.dept.balance, c.dept.available().size(), str(c.run.drafts.map(func(d): return d["kind"])), c.run.offers.size(), c.run.events.size()])
	for scr in ["Roster", "Budget", "Internal affairs", "City Hall"]:
		press("Board") if false else null
		if press(scr):
			await frames(8)
			await shot("screen_" + scr.to_lower().replace(" ", "_"))
			dump("screen_" + scr.to_lower().replace(" ", "_"))
			if not press("Board"):
				press("Back")
			await frames(6)
	var f := FileAccess.open(out + "/walk.log", FileAccess.WRITE)
	f.store_string("\n".join(log_lines))
	f.close()
	quit(0)
