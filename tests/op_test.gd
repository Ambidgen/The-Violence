extends SceneTree
## Planned operations, headless (v0.7): a campaign's first weeks, each situation run
## with the suggested plan. Prints each outcome.
##   godot --headless --path . -s res://tests/op_test.gd -- --weeks=2 --seed=1001 [--type=hostage] [--v]
##     [--decide=clear|suspend|fire|retrain|lapse] [--hire] [--no-events] [--press]
## v0.9: the city's politics run too; --weeks=40 holds the election and prints the ending.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Recorder = preload("res://scripts/sim/recorder.gd")


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var weeks := int(args.get("weeks", "2"))
	var only: String = args.get("type", "")
	var c = Campaign.new()
	c.start(int(args.get("seed", "1001")))
	var t_all := Time.get_ticks_msec()
	var tot_off_k := 0
	var tot_off_d := 0
	var tot_ops := 0
	var tot_causes := {}
	for wk in weeks:
		if c.over():
			break
		for s in c.board:
			if only != "" and s["type"] != only:
				continue
			if args.has("no-events") and s["type"] == "event":
				continue
			var lv = Maps.get_level(int(s["map"]))
			var nav = Nav.new()
			nav.build(lv)
			var av: Array = c.available_for(s["id"])
			var plan: Dictionary = Autoplan.suggest(s, av, lv, false, Autoplan.share(c.board, s["id"], av.size()))
			c.dept.settle_kits()
			s["plan"] = plan
			if c.plan_members(s).is_empty():
				# the game will not run a plan with nobody in it: the situation goes unattended
				s["plan"] = {}
				print("%s %-9s map %02d vis %d  nobody free to send" % [s["id"], s["type"], int(s["map"]), int(s["visibility"])])
				continue
			var b: Dictionary = Operation.build_planned(s, plan, c.dept, lv, nav)
			var w = World.new()
			w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
			w.recorder = Recorder.new(w)
			var t0 := Time.get_ticks_msec()
			var guard := 0
			while not w.over and guard < 40000:
				w.step()
				w.events.clear()
				guard += 1
			var res: Dictionary = Outcome.evaluate(s, w)
			var lines: Array = c.dept.apply_result(w, lv.map_name)
			lines.append_array(c.after_operation(s["id"], res, w))
			c.record(s["id"], res)
			var smy: Dictionary = w.incident.summary()
			tot_off_k += int(smy["officers_killed"])
			tot_off_d += int(smy["officers_down"])
			tot_ops += 1
			for f in w.incident.findings:
				if f["kind"] == "officer_killed":
					tot_causes[("bled out" if String(f["text"]).ends_with("died of wounds") else "killed outright")] = tot_causes.get(("bled out" if String(f["text"]).ends_with("died of wounds") else "killed outright"), 0) + 1
			print("[officers %d killed, %d down of %d; suspects %d down, %d killed] " % [int(smy["officers_killed"]), int(smy["officers_down"]), int(smy["officers"]), int(smy["suspects_down"]), int(smy["suspects_killed"])], "")
			print("%s %-9s map %02d vis %d  %-15s %3d  %s  (%.0f s sim, %d ms, %d officers, %d snaps, broken %d, less %d, gas %d, sting %d)" % [s["id"], s["type"], int(s["map"]),
				int(s["visibility"]), res["label"], res["score"], res["goal"], w.t, Time.get_ticks_msec() - t0,
				c.plan_members(s).size(), w.recorder.times.size(), res["orders_broken"], int(w.stat.get("less", 0)),
				int(w.stat.get("gas", 0)), int(w.stat.get("stings", 0))])
			if args.has("v"):
				for sq in res["squads"]:
					print("    squad %d: %d/%d alive, %s, %s" % [sq["i"] + 1, sq["alive"], sq["n"], sq["mode"], str(sq["results"])])
				for tl in w.timeline:
					print("    %s  %s" % [w.clock(tl["t"]), tl["text"]])
				for ln in lines:
					print("    dept: ", ln)
			w.dispose()
		# the chief's standing orders for the sweep: how to decide cases, whether to hire
		var pol: String = args.get("decide", "lapse")
		if pol != "lapse":
			for cs in c.dept.open_cases():
				c.decide_case(cs, pol)
		if args.has("hire"):
			while c.dept.available().size() + c.dept.officers.filter(func(r): return r["status"] == "academy").size() < 14 and c.dept.balance > 12000:
				if c.dept.recruit(false).is_empty():
					break
		var p = c.politics
		print("  week %d: account $%d, morale %d, %d open cases, %d fit  |  trust %.0f  allies %s  polls K %.0f O %.0f P %.0f  pending %d" % [c.dept.week, c.dept.balance, c.dept.morale,
			c.dept.open_cases().size(), c.dept.available().size(), p.avg_trust(),
			" ".join(p.ALLY_ORDER.map(func(a): return "%s%d%s" % [{"council": "CL", "union": "UN", "coalition": "CC", "da": "DA"}[a], p.standing(a), "x" if p.lost(a) else ""])),
			p.share("kettering"), p.share("okonjo"), p.share("pell"), p.pending.size()])
		var wk_now: int = c.dept.week
		for ln in c.end_week():
			if args.has("v") or String(ln).begins_with("LOST") or String(ln).begins_with("Election"):
				print("  week: ", ln)
		if args.has("press"):
			for pr in p.week_press(wk_now):
				print("    LEDGER  %s" % pr["head"])
	if c.over():
		var e: Dictionary = c.politics.result["ending"]
		print("ELECTION: %s  (K %.0f%%, O %.0f%%, P %.0f%%)  kept: %s" % [c.politics.CANDIDATES[e["winner"]]["name"], c.politics.result["votes"]["kettering"],
			c.politics.result["votes"]["okonjo"], c.politics.result["votes"]["pell"], str(e["keep"])])
		print("  " + e["head"])
		for el in e["lines"]:
			print("  " + el)
	print("officer deaths: ", tot_causes)
	print("officers per operation: %.2f killed, %.2f down (%d operations)" % [float(tot_off_k) / maxf(1, tot_ops), float(tot_off_d) / maxf(1, tot_ops), tot_ops])
	print("done in %d ms" % (Time.get_ticks_msec() - t_all))
	quit()
