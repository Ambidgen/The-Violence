extends SceneTree
## Stall hunt: every map, several sizes and matchups; flags matches that run to the time
## limit and prints what the survivors were doing.
##   godot --headless --path . -s res://tests/stall_test.gd -- [--map=4] [--seed=1]
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Memory = preload("res://scripts/sim/memory.gd")
const Teams = preload("res://tests/teams.gd")

const CASES := [
	[5, 5, "regular", "regular", "assault", "hold"],
	[12, 12, "police", "militia", "assault", "hold"],
	[20, 20, "regular", "regular", "assault", "hold"],
	[8, 16, "sof", "militia", "assault", "hold"],
	[10, 10, "regular", "militia", "hunt", "hunt"],
	[16, 8, "militia", "sof", "assault", "hold"],
]


## ---------------------------------------------------------------- watchdogs
## Tier 0 #3. A match can reach the time limit for a legitimate reason (two
## evenly matched teams sitting in cover), and those are already reported above.
## These catch the ones that are bugs: an operator frozen in a state it cannot
## leave. Each is a "this should never last this long" timer.
var _wd := {}          # op id -> {kind: seconds}
var _wd_el := {}       # element key -> {kind: seconds}
var _flagged := {}     # "kind:who" -> text


func _watch(w, ticks: int) -> void:
	if ticks % 15 != 0:
		return
	var dt: float = 15.0 / 30.0
	for o in w.ops:
		if not o.alive():
			continue
		var rec: Dictionary = _wd.get(o.id, {})
		# H4: aimed, wanting to fire, with rounds, and not firing
		var held: bool = (not o.aim.is_empty()) and bool(o.aim.get("on", false)) \
			and bool(o.aim.get("fire", false)) and o.action.is_empty() \
			and o.ws()["mag"] > 0 and not o.ws()["jam"]
		rec["aim_hold"] = (float(rec.get("aim_hold", 0.0)) + dt) if held else 0.0
		# moving but going nowhere
		var stuck: bool = o.moving and o.speed > 0.0 and o.vel.length() < 0.01
		rec["no_progress"] = (float(rec.get("no_progress", 0.0)) + dt) if stuck else 0.0
		# pinned
		rec["pinned"] = (float(rec.get("pinned", 0.0)) + dt) if o.suppress > 0.9 else 0.0
		# memory that never lets go: a record of the DEAD whose salience has run
		# out but is still there. fade() strips the keeper fields at death, so
		# prune() must drop it on the next tick; TTLs run up to ~36 s for living
		# entries, so only "expired and present" is a leak signal.
		var stale := 0
		for eid in o.mem:
			var eo = w.op_by_id(eid)
			if eo != null and not eo.alive() and Memory.salience(o, o.mem[eid], w.t) <= 0.0:
				stale += 1
		rec["memory"] = (float(rec.get("memory", 0.0)) + dt) if stale > 2 else 0.0
		_wd[o.id] = rec
		for k in ["aim_hold", "no_progress", "pinned", "memory"]:
			var lim: float = 10.0 if k == "aim_hold" else (5.0 if k == "no_progress" \
				else (20.0 if k == "pinned" else 5.0))
			if float(rec[k]) > lim:
				_flagged["%s:%s" % [k, o.id]] = "%s held %s for %.1f s (%s, %s)" % [
					o.id, k, float(rec[k]), o.dbg, o.room]
				rec[k] = -1.0e9
	for tm in w.teams:
		if tm["free"]:
			continue
		for el in tm["elements"]:
			if el["task"].is_empty():
				continue
			var ek: String = "%s-%d" % [tm["tag"], el["i"]]
			var er: Dictionary = _wd_el.get(ek, {})
			var ph: String = el["phase"]
			er[ph] = float(er.get(ph, 0.0)) + dt
			_wd_el[ek] = er
			var lim2: float = 40.0 if ph == "approach" else (110.0 if ph == "sweep" \
				else (25.0 if ph == "breach" else 60.0))
			if float(er[ph]) > lim2:
				_flagged["phase_%s:%s" % [ph, ek]] = "%s stuck in phase %s for %.1f s (%s)" % [
					ek, ph, float(er[ph]), str(el["task"])]
				er[ph] = -1.0e9


func _init() -> void:
	var only := -1
	var seed_v := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			only = Maps.index_of(a.trim_prefix("--map="))
		elif a.begins_with("--seed="):
			seed_v = int(a.trim_prefix("--seed="))
	var stalls := 0
	var t_all := Time.get_ticks_msec()
	for i in Maps.count():
		if only >= 0 and i != only:
			continue
		var lv = Maps.get_level(i)
		var nav = Nav.new()
		nav.build(lv)
		for c in CASES:
			var cfgs: Array = Teams.team(lv, 0, {"n": c[0], "ech": c[2]}) + Teams.team(lv, 1, {"n": c[1], "ech": c[3]})
			var w = World.new()
			w.keep_events = false
			w.setup(lv, nav, cfgs, [c[4], c[5]], 100 * i + seed_v)
			var t0 := Time.get_ticks_usec()
			var ticks := 0
			while not w.over:
				w.step()
				ticks += 1
				_watch(w, ticks)
			var alive := [0, 0]
			for o in w.ops:
				if o.alive():
					alive[o.team] += 1
			var flag := ""
			if w.t >= w.time_limit:
				flag = "  <<< TIME LIMIT"
				stalls += 1
			print("map %02d %2dv%-2d %-8s %-8s %-7s/%-5s -> %-6s %5.1f s  alive %2d/%-2d  cleared %2d  %.2f ms/tick%s" % [i, c[0], c[1],
				c[2], c[3], c[4], c[5], ["A", "B", "draw"][w.winner], w.t, alive[0], alive[1], w.teams[0]["cleared"].size(),
				(Time.get_ticks_usec() - t0) / 1000.0 / ticks, flag])
			if flag != "":
				for o in w.ops:
					if o.alive():
						print("      %s el %d %s %s: %s" % [o.id, o.el, str(o.pos.snapped(Vector2(0.1, 0.1))), o.room, o.dbg])
				for el in w.teams[0]["elements"]:
					print("      A-%d mode %s task %s phase %s" % [el["i"] + 1, el["mode"], str(el["task"]), el["phase"]])
			w.dispose()
	print("stalls: %d   (%d s)" % [stalls, (Time.get_ticks_msec() - t_all) / 1000])
	if _flagged.is_empty():
		print("watchdogs: clean")
	else:
		print("")
		print("WATCHDOGS: %d frozen state(s)" % _flagged.size())
		for k in _flagged.keys():
			print("   %s" % _flagged[k])
	quit()
