extends SceneTree
## Planned operations, headless (v0.7): a campaign's first weeks, each situation run
## with the suggested plan. Prints each outcome.
##   godot --headless --path . -s res://tests/op_test.gd -- --weeks=2 --seed=1001 [--type=hostage] [--v]
##     [--decide=clear|suspend|fire|retrain|lapse] [--hire] [--no-events] [--press]
## v0.9: the city's politics run too; --weeks=40 holds the election and prints the ending.
## P0.B3: --json=path also writes every week's snapshot, every operation and the run's
## totals as JSON (tools/campaign_report.py turns it into the playtest table).

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Recorder = preload("res://scripts/sim/recorder.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var weeks := int(args.get("weeks", "2"))
	var only: String = args.get("type", "")
	var c = Campaign.new()
	c.start(int(args.get("seed", "1001")), args.has("rogue"), "user://legacy_optest.json")   # 1.3: --rogue plays a roguelike run, the desk answered at random
	var t_all := Time.get_ticks_msec()
	var tot_off_k := 0
	var tot_off_d := 0
	var tot_ops := 0
	var tot_causes := {}
	var tot_score := 0
	var tot_findings := 0
	var tot_deficit := 0
	var hung := 0   # P0.A1: operations that hit the step guard without ending
	var j_weeks: Array = []   # P0.B3: --json
	var problems_json := ""
	var j_ops: Array = []
	var j_ally_lines: Array = []   # LOST / Won back from operations, before the week's snapshot
	# EA_TASKS P1.G3: wall time per operation, by situation type, so a full run's cost at
	# default settings can be read off a CI log instead of a stopwatch on someone's desk.
	var t_wall := Time.get_ticks_msec()
	var op_ms_by_type := {}
	for wk in weeks:
		if c.over():
			break
		# --chief=sensible (v0.9.1): the gravest first, at most two operations a week, and
		# quiet warrants left alone while the department is short
		var order: Array = c.board.duplicate()
		var sensible: bool = args.get("chief", "") in ["sensible", "manual"]
		var manual: bool = args.get("chief", "") == "manual"   # Q4: the intel-reading chief, same schedule
		var runs_left := 99
		if sensible:
			runs_left = 2
			var pri := {"hostage": 0, "event": 1, "gang": 2, "barricade": 3, "warrant": 4}
			order.sort_custom(func(a, b): return pri[a["type"]] * 10 - int(a["visibility"]) < pri[b["type"]] * 10 - int(b["visibility"]))
		for s in order:
			if only != "" and s["type"] != only:
				continue
			if sensible and (runs_left <= 0 or (s["type"] == "warrant" and int(s["visibility"]) <= 1 and c.dept.available().size() < 12)):
				continue
			if args.has("no-events") and s["type"] == "event":
				continue
			var lv = Maps.get_level(int(s["map"]))
			var nav = Nav.new()
			nav.build(lv)
			var av: Array = c.available_for(s["id"])
			var plan: Dictionary = Autoplan.suggest(s, av, lv, false, Autoplan.share(c.board, s["id"], av.size()))
			c.dept.settle_kits()
			if manual:
				plan = _manual_edits(s, plan, c.dept.officers, lv)
			s["plan"] = plan
			if c.plan_members(s).is_empty():
				# the game will not run a plan with nobody in it: the situation goes unattended
				s["plan"] = {}
				print("%s %-9s map %02d vis %d  nobody free to send" % [s["id"], s["type"], int(s["map"]), int(s["visibility"])])
				j_ops.append({"id": s["id"], "type": s["type"], "map": int(s["map"]), "vis": int(s["visibility"]), "ran": false})
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
			if not w.over:
				hung += 1
				print("HUNG: %s %s map %02d did not end in %d steps (%.0f s sim)" % [s["id"], s["type"], int(s["map"]), guard, w.t])
			runs_left -= 1
			var op_ms := Time.get_ticks_msec() - t0
			var ty := String(s["type"])
			var acc2: Dictionary = op_ms_by_type.get(ty, {"n": 0, "ms": 0, "max": 0, "sim": 0.0})
			acc2["n"] = int(acc2["n"]) + 1
			acc2["ms"] = int(acc2["ms"]) + op_ms
			acc2["max"] = maxi(int(acc2["max"]), op_ms)
			acc2["sim"] = float(acc2["sim"]) + w.t
			op_ms_by_type[ty] = acc2
			var res: Dictionary = Outcome.evaluate(s, w)
			tot_score += int(res.get("score", 0))
			tot_findings += int(res.get("findings", 0))
			var lines: Array = c.dept.apply_result(w, lv.map_name)
			lines.append_array(c.after_operation(s["id"], res, w))
			# P0.B3: an ally lost to an operation's aftermath used to be invisible in this log
			for ln in lines:
				if _ally_line(ln):
					print("  week: ", ln)
					j_ally_lines.append(String(ln))
			c.record(s["id"], res)
			var smy: Dictionary = w.incident.summary()
			tot_off_k += int(smy["officers_killed"])
			tot_off_d += int(smy["officers_down"])
			tot_ops += 1
			j_ops.append({"id": s["id"], "type": s["type"], "map": int(s["map"]), "vis": int(s["visibility"]), "ran": true,
				"label": String(res.get("label", "")), "score": int(res.get("score", 0)), "sim_s": snappedf(w.t, 0.1),
				"officers": int(smy["officers"]), "officers_killed": int(smy["officers_killed"]), "officers_down": int(smy["officers_down"]),
				"suspects_killed": int(smy["suspects_killed"]), "civ_hit": int(smy.get("civ_hit", 0)), "civ_killed": int(smy.get("civ_killed", 0)),
				"civ_hit_police": int(smy.get("civ_hit_police", 0)), "misjudged": int(smy.get("misjudged", 0)), "findings": int(res.get("findings", 0)),
				"hung": not w.over})
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
			while c.dept.available().size() + c.dept.officers.filter(func(r): return r["status"] == "academy").size() < 16 and c.dept.balance > (3000 if sensible else 8000):
				var pool: Array = c.dept.applicants_now()
				if pool.is_empty() or c.dept.choose_applicant(pool[0]).is_empty():
					break
		var p = c.politics
		print("  week %d: account $%d, morale %d, %d open cases, %d fit  |  trust %.0f  allies %s  polls K %.0f O %.0f P %.0f  pending %d" % [c.dept.week, c.dept.balance, c.dept.morale,
			c.dept.open_cases().size(), c.dept.available().size(), p.avg_trust(),
			" ".join(p.ALLY_ORDER.map(func(a): return "%s%d%s" % [{"council": "CL", "union": "UN", "coalition": "CC", "da": "DA"}[a], p.standing(a), "x" if p.lost(a) else ""])),
			p.share("kettering"), p.share("okonjo"), p.share("pell"), p.pending.size()])
		var j_allies := {}
		for a in p.ALLY_ORDER:
			j_allies[a] = {"standing": p.standing(a), "lost": p.lost(a)}
		var j_week := {"week": c.dept.week, "balance": c.dept.balance, "morale": c.dept.morale,
			"open_cases": c.dept.open_cases().size(), "fit": c.dept.available().size(),
			"academy": c.dept.officers.filter(func(r): return r["status"] == "academy").size(),
			"injured": c.dept.officers.filter(func(r): return r["status"] == "injured").size(),
			"dead_total": c.dept.officers.filter(func(r): return r["status"] == "dead").size(),
			"trust": snappedf(p.avg_trust(), 0.1), "allies": j_allies,
			"polls": {"kettering": snappedf(p.share("kettering"), 0.1), "okonjo": snappedf(p.share("okonjo"), 0.1), "pell": snappedf(p.share("pell"), 0.1)},
			"pending": p.pending.size(), "ops": j_ops, "lines": j_ally_lines}
		j_ops = []
		j_ally_lines = []
		if args.has("ledger"):
			var cats := {}
			for le in c.dept.ledger:
				if int(le["week"]) != c.dept.week:
					continue
				var cat: String = String(le["item"]).split(":")[0].split(",")[0]
				cats[cat] = cats.get(cat, 0) + int(le["amount"])
			print("    ledger week %d: %s" % [c.dept.week, str(cats)])
		if args.has("train"):
			_training_chief(c)
		var wk_now: int = c.dept.week
		if c.run != null:
			for dl in c.run.auto_resolve(c):
				if args.has("v"):
					print("    desk: " + String(dl))
				if _ally_line(dl):   # P0.B3: and so was one lost (or won back) on the desk
					print("  week: ", dl)
					j_week["lines"].append(String(dl))
		for ln in c.end_week():
			if args.has("v") or String(ln).begins_with("LOST") or String(ln).begins_with("Election"):
				print("  week: ", ln)
			if _ally_line(ln) or String(ln).begins_with("Election"):
				j_week["lines"].append(String(ln))
			if String(ln).begins_with("Won back") and not args.has("v"):
				print("  week: ", ln)
		j_weeks.append(j_week)
		if c.dept.balance < 0:
			tot_deficit += 1
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
	# the comparable totals (Q4 matched seeds, Q9 training, Q8 deficit weeks)
	var actives := 0
	var with_bad := 0
	var courses := 0
	for r in c.dept.officers:
		if r["status"] in ["active", "training", "injured", "suspended"]:
			actives += 1
			if not (r["bad_traits"] as Array).is_empty():
				with_bad += 1
		for entry in r["file"]:
			if String(entry["text"]).begins_with("Completed"):
				courses += 1
	print("TOTALS chief=%s train=%s: mean score %d, %d findings, deficit weeks %d; courses/officer %.2f, officers still carrying a bad habit %d/%d." % [
		args.get("chief", "all"), args.has("train"), tot_score / maxi(1, tot_ops), tot_findings, tot_deficit,
		courses / float(maxi(1, actives)), with_bad, actives])
	print("officer deaths: ", tot_causes)
	print("officers per operation: %.2f killed, %.2f down (%d operations)" % [float(tot_off_k) / maxf(1, tot_ops), float(tot_off_d) / maxf(1, tot_ops), tot_ops])
	print("done in %d ms" % (Time.get_ticks_msec() - t_all))
	# P1.G3: the operation clock, as data. `wall` is the whole engine process, not a
	# renderer: the same numbers a headless CI run reports on a modest runner.
	var op_wall_ms := 0
	var op_wall_max := 0
	for ty in op_ms_by_type:
		var a3: Dictionary = op_ms_by_type[ty]
		op_wall_ms += int(a3["ms"])
		op_wall_max = maxi(op_wall_max, int(a3["max"]))
	print("TIMING run wall %d ms, %d operation(s), mean %.0f ms, worst %d ms%s" % [
		Time.get_ticks_msec() - t_wall, tot_ops, float(op_wall_ms) / maxf(1.0, float(tot_ops)), op_wall_max,
		"".join(op_ms_by_type.keys().map(func(k): return ", %s %.0f ms/op" % [k, float(op_ms_by_type[k]["ms"]) / maxf(1.0, float(op_ms_by_type[k]["n"]))]))])
	if args.has("save"):        # 1.1: keep the played campaign (the trailer's election night)
		c.save()
		print("saved the campaign to ", Campaign.SAVE_PATH)
	if args.has("json"):
		var out := {"version": 1, "seed": int(args.get("seed", "1001")), "rogue": args.has("rogue"),
			"chief": args.get("chief", "all"), "hire": args.has("hire"), "train": args.has("train"),
			"decide": args.get("decide", "lapse"), "weeks_asked": weeks, "weeks_played": j_weeks.size(),
			"engine": Engine.get_version_info()["string"], "wall_ms": Time.get_ticks_msec() - t_wall,
			"timing": {"ops": tot_ops, "op_wall_ms": op_wall_ms, "op_wall_max_ms": op_wall_max,
				"mean_op_ms": snappedf(float(op_wall_ms) / maxf(1.0, float(tot_ops)), 0.1), "by_type": op_ms_by_type},
			"ops": tot_ops, "hung": hung, "officers_killed_per_op": snappedf(float(tot_off_k) / maxf(1, tot_ops), 0.01),
			"officers_down_per_op": snappedf(float(tot_off_d) / maxf(1, tot_ops), 0.01), "mean_op_score": tot_score / maxi(1, tot_ops),
			"findings": tot_findings, "deficit_weeks": tot_deficit, "death_causes": tot_causes,
			"record": c.politics.record.duplicate(), "election": {}, "run_score": {}, "weeks": j_weeks}
		if c.over():
			var e2: Dictionary = c.politics.result["ending"]
			out["election"] = {"winner": e2["winner"], "kept": bool(e2["keep"]), "votes": c.politics.result["votes"], "head": e2["head"]}
		# P1.H1: the score of the record, whether or not this is a roguelike run, so the
		# two chiefs can be compared on one number.
		out["run_score"] = Rogue.run_score(c)
		var jf := FileAccess.open(String(args["json"]), FileAccess.WRITE)
		if jf == null:
			problems_json = "could not write --json to %s" % args["json"]
		else:
			jf.store_string(JSON.stringify(out, "  "))
			jf.close()
			print("wrote ", args["json"])
	# P0.A1: op_test is a diagnostic, but three things are failures, not numbers:
	# an operation that never ended, a campaign asked for 40 weeks that never held its
	# election, and a run that played no operation at all.
	var problems: Array = []
	if hung > 0:
		problems.append("%d operation(s) hung" % hung)
	if weeks >= c.WEEKS and not c.over():
		problems.append("asked for %d weeks, but the campaign never reached the election" % weeks)
	if weeks > 0 and tot_ops == 0 and only == "":
		problems.append("no operation ran")
	if problems_json != "":
		problems.append(problems_json)
	print("op_test: %s" % ("ok" if problems.is_empty() else "FAILED: " + "; ".join(problems)))
	quit(1 if not problems.is_empty() else 0)


## The intel-reading chief (playtest pass Q4): the suggestion, edited from what
## the briefing actually says — estimates included, since a human bets on them —
## which is exactly the subset Autoplan now reserves. Compare matched seeds:
## --chief=sensible against --chief=manual; the gap in the closing Totals is the
## measured value of reading the briefing, and the CHANGELOG records the pair.
func _manual_edits(s: Dictionary, plan: Dictionary, roster: Array, lv) -> Dictionary:
	var p: Dictionary = plan.duplicate(true)
	var sqs: Array = p.get("squads", [])
	if sqs.is_empty():
		return p
	var by_id := {}
	for r in roster:
		by_id[r["id"]] = r
	var f_all := {}
	for f in s["intel"]:
		f_all[f["key"]] = f
	var od: Dictionary = (sqs[0] as Dictionary).get("orders", {})
	if od.is_empty():
		return p
	var recs: Array = []
	for j in (sqs[0] as Dictionary).get("members", []):
		if by_id.has(j):
			recs.append(by_id[j])
	var pts: int = Orders.points_for(recs) - Orders.cost(od)
	# the hostage room, estimated or confirmed: clear (and Rescue) that room first
	if s["type"] in ["hostage", "gang", "barricade"] and f_all.has("hostage_room"):
		var f: Dictionary = f_all["hostage_room"]
		var rm: String = f["room"] if f["known"] else f.get("room_est", "")
		if rm != "" and lv.rooms.has(rm) and not (od["objs"] as Array).is_empty():
			(od["objs"] as Array)[0]["rooms"] = [rm]
	# a lookout's building is entered by the far door; paid for out of Knock
	var alert: String = String((f_all.get("alert", {}) as Dictionary).get("est", ""))
	if alert.find("lookout") >= 0 and s["type"] in ["warrant", "gang", "raid"]:
		var stage_pos: Vector2 = ((Operation.stages(lv)[int((sqs[0] as Dictionary).get("stage", 0))] as Dictionary)["r"] as Rect2).get_center()
		var doors: Array = Autoplan.exterior_doors(lv, stage_pos)
		if doors.size() > 1:
			if pts < 1 and bool(od.get("knock", false)):
				od["knock"] = false
				pts += 1
			if pts >= 1:
				od["entry"] = String(lv.openings[doors[doors.size() - 1]]["id"])
				pts -= 1
	# civilians inside: less-lethal first on the entry squad, if leadership allows
	var civs: String = String((f_all.get("civs", {}) as Dictionary).get("est", ""))
	if civs != "" and civs.find("nobody") < 0 and civs.find("none") < 0 and pts >= 1:
		od["less"] = true
		pts -= 1
	# a man who runs, watched: do not knock — go straight in
	var flight: String = String((f_all.get("flight", {}) as Dictionary).get("est", ""))
	if flight.find("has run") >= 0 and alert.find("lookout") >= 0:
		od["knock"] = false
	return p


## The training chief (playtest pass Q9): every officer with a bad habit is sent
## on, or queued for, the course that removes it, while a $4,000 cushion lasts.
## --train against a plain run measures the queue-and-classroom change in
## courses/officer and residual bad habits (closing Totals).
func _training_chief(c) -> void:
	var d = c.dept
	for r in d.officers:
		if d.balance < 4000 or d.frozen():
			return
		if r["status"] in ["dead", "retired", "fired", "resigned", "academy", "suspended"]:
			continue
		if r["course"] != "":
			continue
		if not (r["bad_traits"] as Array).is_empty() and not (r["queue"] as Array).has("coaching"):
			d.enrol_or_queue(r, "coaching")


## P0.B3: a line saying an ally was lost or won back.
static func _ally_line(ln) -> bool:
	var t := String(ln)
	return t.begins_with("LOST:") or t.begins_with("Won back:")
