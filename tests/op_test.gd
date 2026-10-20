extends SceneTree
## Planned operations, headless (v0.7): a campaign's first weeks, each situation run
## with the suggested plan. Prints each outcome.
##   godot --headless --path . -s res://tests/op_test.gd -- --weeks=2 --seed=1001 [--type=hostage] [--v]

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
	for wk in weeks:
		for s in c.board:
			if only != "" and s["type"] != only:
				continue
			var lv = Maps.get_level(int(s["map"]))
			var nav = Nav.new()
			nav.build(lv)
			var av: Array = c.available_for(s["id"])
			var plan: Dictionary = Autoplan.suggest(s, av, lv, false, Autoplan.share(c.board, s["id"], av.size()))
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
			c.record(s["id"], res)
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
		for ln in c.end_week():
			if args.has("v"):
				print("  week: ", ln)
	print("done in %d ms" % (Time.get_ticks_msec() - t_all))
	quit()
