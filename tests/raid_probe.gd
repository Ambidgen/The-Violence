extends SceneTree
## Raid probe (EA_TASKS P1.C5): the same situation played with different force sizes, so
## that what the balance matrix cannot separate (policies send whoever is free) can be.
##
##   godot --headless --path . -s res://tests/raid_probe.gd -- --type=gang --n=20 [--first=0]
##       [--force=6,8,10] [--kit=0] [--trauma=T] [--morale=M]   (--kit=0: officers keep their own kit, as cautious and minimal do)
##
## Seeds are 7000 + 13 * k. Each situation is dealt once (its map comes from the city
## site, as in the game) and played once per force size by a freshly founded department
## (campaign seed 1001, default kit, Suggest a plan's orders for that many officers).
## Prints one "RAID {json}" line per play: seed, map, armed suspects, force, officers
## down and killed (and how), suspects killed, the outcome and the simulated seconds;
## then a table by map and force. Exit 1 only if an operation did not end.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

const GUARD_STEPS := 60000


func _play(type: String, seed_v: int, force: int, kit := true, trauma := 0.0, morale := 60) -> Dictionary:
	var c = Campaign.new()
	c.start(1001)
	c.dept.morale = morale
	for r in c.dept.officers:
		r["trauma"] = maxf(float(r["trauma"]), trauma)
	var s: Dictionary = Situations.make(type, seed_v, 12, 0, c.politics.trust, true)
	c.board = [s]
	var lv = Maps.get_level(int(s["map"]))
	var nav = Nav.new()
	nav.build(lv)
	var av: Array = c.available_for(s["id"])
	var plan: Dictionary = Autoplan.suggest(s, av, lv, false, force, kit)
	c.dept.settle_kits()
	s["plan"] = plan
	var b: Dictionary = Operation.build_planned(s, plan, c.dept, lv, nav)
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	var guard := 0
	while not w.over and guard < GUARD_STEPS:
		w.step()
		w.events.clear()
		guard += 1
	var res: Dictionary = Outcome.evaluate(s, w)
	var sm: Dictionary = w.incident.summary()
	var police := {}
	for o in w.ops:
		if o.judges:
			police[o.id] = true
	var by := {"suspect": 0, "friendly": 0, "bled_out": 0}
	for f in w.incident.findings:
		if String(f["kind"]) == "officer_killed":
			var who := String(f["by"])
			by["bled_out" if who == "" else ("friendly" if police.has(who) else "suspect")] += 1
	var bled := {}
	for f2 in w.incident.findings:
		if String(f2["kind"]) == "officer_killed" and String(f2["by"]) == "":
			bled[String(f2["target"])] = true
	var how := {}      # officers dead, by the wound that did it (and whether it came while already down)
	for o in w.ops:
		if o.judges and o.state == "dead":
			var k := String(o.ticker.get("down_where", "?"))
			if o.ticker.has("down_t") and o.ticker.has("first_hit_t") and float(o.ticker["down_t"]) - float(o.ticker["first_hit_t"]) > 0.05:
				var gap: float = float(o.ticker["down_t"]) - float(o.ticker["first_hit_t"])
				k += " (after an earlier hit, %s)" % ("<0.5 s" if gap < 0.5 else ("0.5-2 s" if gap < 2.0 else ">2 s"))
			if bled.has(o.id):
				k += " / died of wounds"
			how[k] = int(how.get(k, 0)) + 1
	var armed := 0
	for oc in s["occupants"]:
		if String(oc.get("role", "")) == "suspect":
			armed += 1
	var out := {"seed": seed_v, "type": type, "map": int(s["map"]), "map_name": String(lv.map_name), "armed": armed,
		"force": int(sm["officers"]), "asked": force, "down": int(sm["officers_down"]), "killed": int(sm["officers_killed"]),
		"killed_by": by, "suspects_killed": int(sm["suspects_killed"]), "civ_killed": int(sm["civ_killed"]),
		"kind": String(res.get("kind", "")), "kit": kit, "how": how, "sim_s": snappedf(w.t, 0.1), "ended": w.over}
	w.dispose()
	return out


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var type := String(args.get("type", "gang"))
	var n := int(args.get("n", "10"))
	var first := int(args.get("first", "0"))
	var forces: Array = []
	for x in String(args.get("force", "6,8,10")).split(",", false):
		forces.append(int(x))
	var kit: bool = String(args.get("kit", "1")) != "0"
	var trauma := float(args.get("trauma", "0"))
	var morale := int(args.get("morale", "60"))
	var rows: Array = []
	var hung := 0
	for k in range(first, first + n):
		var seed_v := 7000 + 13 * k
		for f in forces:
			var r := _play(type, seed_v, f, kit, trauma, morale)
			rows.append(r)
			hung += 0 if r["ended"] else 1
			print("RAID ", JSON.stringify(r))
	# by map and force: plays, officers killed and down per raid, outcomes
	var g := {}
	for r in rows:
		var key := "%s|%d" % [r["map_name"], int(r["asked"])]
		if not g.has(key):
			g[key] = {"plays": 0, "killed": 0, "down": 0, "success": 0, "armed": 0}
		g[key]["plays"] += 1
		g[key]["killed"] += int(r["killed"])
		g[key]["down"] += int(r["down"])
		g[key]["armed"] += int(r["armed"])
		g[key]["success"] += 1 if r["kind"] == "success" else 0
	var keys := g.keys()
	keys.sort()
	print("| map | force | raids | armed per raid | killed per raid | down per raid | success |")
	print("|---|---|---|---|---|---|---|")
	for key in keys:
		var d: Dictionary = g[key]
		var p: float = float(d["plays"])
		print("| %s | %s | %d | %.1f | %.2f | %.2f | %d%% |" % [key.split("|")[0], key.split("|")[1], int(d["plays"]),
			d["armed"] / p, d["killed"] / p, d["down"] / p, int(round(100.0 * d["success"] / p))])
	quit(1 if hung > 0 else 0)
