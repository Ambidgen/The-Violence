extends SceneTree
## Crowd trace (EA_TASKS P1.B4): what was true at each misjudgment at a quiet public
## event -- which officer, his stress against his own floor, whether he was in combat,
## the person's state (filming, fleeing, ...), speed and distance, whether that officer
## had already cleared the person, the light -- and every police round that struck a
## civilian. Used to find the causes Fix A (calm measured from the floor) does not cover.
##
##   godot --headless --path . -s res://tests/crowd_trace.gd -- --seeds=5051,5068,5119 [--trauma=0] [--morale=60]
##
## Prints one line per misjudgment and per civilian struck, then a count of the first
## misjudgment's circumstances across the seeds. A diagnostic: exit 0 unless an event
## did not end.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")


func _trace(seed_v: int, trauma: float, morale: int, n_off: int, firsts: Dictionary) -> bool:
	var c = Campaign.new()
	c.start(1001)
	c.dept.morale = morale
	for r in c.dept.officers:
		r["trauma"] = maxf(float(r["trauma"]), trauma)
	var s: Dictionary = Situations.make("event", seed_v, 12, 0, c.politics.trust, true)
	s["attack"] = false
	s["attack_t"] = -1
	s["attack_p"] = 0.0
	c.board = [s]
	var lv = Maps.get_level(int(s["map"]))
	var nav = Nav.new()
	nav.build(lv)
	var av: Array = c.available_for(s["id"]).slice(0, n_off)
	var plan: Dictionary = Autoplan.suggest(s, av, lv, false, n_off)
	s["plan"] = plan
	var b: Dictionary = Operation.build_planned(s, plan, c.dept, lv, nav)
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	var by_id := {}
	for o in w.ops:
		by_id[o.id] = o
	print("== seed %d  trauma %.0f  morale %d  night %s  officers %s" % [seed_v, trauma, morale, str(w.night),
		", ".join(w.ops.filter(func(o): return o.judges).map(func(o): return "%s stress0 %.3f" % [o.id, float(o.ech.get("stress0", 0.0))]))])
	var seen := 0
	var first := true
	var guard := 0
	while not w.over and guard < 60000:
		w.step()
		w.events.clear()
		guard += 1
		while seen < w.incident.findings.size():
			var f: Dictionary = w.incident.findings[seen]
			seen += 1
			var kind := String(f["kind"])
			if kind != "misjudgment" and kind != "civilian_hit_by_police" and kind != "civilian_killed":
				continue
			var o = by_id.get(String(f["by"]), null)
			var e = by_id.get(String(f["target"]), null)
			if kind == "misjudgment" and o != null and e != null:
				var floor_s := float(o.ech.get("stress0", 0.0))
				var why := {
					"combat": w.in_combat(o), "stress_over_floor": snappedf(o.stress - floor_s, 0.01),
					"state": String(e.cstate), "running": e.vel.length() > 2.0,
					"cleared_before": o.cleared.has(e.id), "dist": snappedf(o.pos.distance_to(e.pos), 0.1),
					"night": w.night}
				print("  t %6.1f  MISJUDGE  %s -> %s  stress %.2f (floor %.2f)  %s" % [float(f["t"]), o.id, e.id, o.stress, floor_s, str(why)])
				if first:
					first = false
					var key := "%s%s%s%s" % ["combat " if why["combat"] else "", "running " if why["running"] else "",
						("state=" + why["state"] + " ") if why["state"] != "" else "", "cleared-before" if why["cleared_before"] else "new-face"]
					firsts[key] = int(firsts.get(key, 0)) + 1
			else:
				print("  t %6.1f  %s  %s" % [float(f["t"]), kind.to_upper(), String(f["text"])])
	if first:
		firsts["no misjudgment"] = int(firsts.get("no misjudgment", 0)) + 1
	var ended: bool = w.over
	w.dispose()
	return ended


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var seeds: Array = String(args.get("seeds", "5051,5068,5119")).split(",", false)
	var firsts := {}
	var hung := 0
	for sd in seeds:
		if not _trace(int(sd), float(args.get("trauma", "0")), int(args.get("morale", "60")), int(args.get("officers", "2")), firsts):
			hung += 1
	print("FIRST MISJUDGMENT, by circumstance: ", firsts)
	quit(1 if hung > 0 else 0)
