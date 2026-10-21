extends SceneTree
## Why officers fall (v0.9.1 diagnostic): planned operations of one type, each from a fresh
## department and the suggested plan, with every officer hit taken apart: who hit them, at
## what range, whether they had recognised the shooter, what they were doing, and whether
## they died outright or bled out.
##   godot --headless --path . -s res://tests/lethality_test.gd -- [--type=gang] [--n=20] [--seed=500] [--v]

const Situations = preload("res://scripts/campaign/situations.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var _navs := {}


func _nav(mi: int, lv):
	if not _navs.has(mi):
		var nv = Nav.new()
		nv.build(lv)
		_navs[mi] = nv
	return _navs[mi]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var typ: String = args.get("type", "gang")
	var n := int(args.get("n", "20"))
	var seed0 := int(args.get("seed", "500"))
	var agg := {"ops": 0, "off": 0, "killed": 0, "down": 0, "bled": 0, "outright": 0, "sus": 0, "sus_down": 0, "sus_killed": 0,
		"success": 0, "partial": 0, "failure": 0, "t": 0.0}
	var why := {}           # officer state when hit -> count
	var who := {}           # shooter echelon -> count
	var rng_d := {"<3 m": 0, "3-6 m": 0, "6-12 m": 0, ">12 m": 0}
	var recog := {"had recognised the shooter": 0, "had not": 0}
	var first := {"police fired first": 0, "suspects fired first": 0}
	var t_down: Array = []
	var ff := {}
	for k in n:
		var sit: Dictionary = Situations.make(typ, seed0 + k * 7919, 1, 0)
		var lv = Maps.get_level(int(sit["map"]))
		var nav = _nav(int(sit["map"]), lv)
		var d = Department.new()
		d.found(seed0 + k, int(args.get("rookies", "0")))
		if args.has("morale"):
			d.morale = int(args["morale"])
		var av: Array = d.available()
		var plan: Dictionary = Autoplan.suggest(sit, av, lv, false, int(args.get("cap", "-1")))
		sit["plan"] = plan
		if args.has("nohelmet"):
			for r in d.officers:
				r["kit"]["head"] = "none"
		var b: Dictionary = Operation.build_planned(sit, plan, d, lv, nav)
		var w = World.new()
		w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
		var hits_seen := {}
		var first_shot := ""
		while not w.over and w.t < 900.0:
			w.step()
			for ev in w.events:
				if ev["type"] == "down":
					var o = w.by_id.get(ev["id"], null)
					if o == null or not o.judges:
						continue
					t_down.append(w.t)
					# the shot that put them down
					var sh: Dictionary = {}
					for i in range(w.incident.shots.size() - 1, -1, -1):
						if w.incident.shots[i]["hit"] == o.id:
							sh = w.incident.shots[i]
							break
					var shooter = w.by_id.get(sh.get("by", ""), null)
					if shooter != null:
						who[shooter.ech.get("name", "?")] = who.get(shooter.ech.get("name", "?"), 0) + 1
						var dist: float = o.pos.distance_to(shooter.pos)
						rng_d["<3 m" if dist < 3.0 else ("3-6 m" if dist < 6.0 else ("6-12 m" if dist < 12.0 else ">12 m"))] += 1
						recog["had recognised the shooter" if float(o.rec.get(shooter.id, 0.0)) >= 1.0 else "had not"] += 1
					var st: String = "%s/%s" % [o.mind, String(o.dbg).substr(0, 28)]
					why[st] = why.get(st, 0) + 1
					if args.has("v"):
						print("  %s down at %.1f s: %s, by %s (%s, %s) at %.1f m; %s" % [o.id, w.t, st, sh.get("by", "?"),
							shooter.ech.get("name", "?") if shooter != null else "?", sh.get("weapon", "?"),
							o.pos.distance_to(shooter.pos) if shooter != null else -1.0, "recognised" if shooter != null and float(o.rec.get(shooter.id, 0.0)) >= 1.0 else "not recognised"])
			if first_shot == "" and not w.incident.shots.is_empty():
				first_shot = "police fired first" if w.incident.shots[0]["pol"] else "suspects fired first"
			w.events.clear()
		if first_shot != "":
			first[first_shot] += 1
		# friendly fire: police rounds that hit police
		for sh2 in w.incident.shots:
			if sh2["pol"] and sh2["hkind"] == "officer":
				var key: String = "aimed at %s, %s, %d wall(s)" % [sh2["tkind"] if sh2["tgt"] != "" else "nobody", sh2["weapon"], int(sh2["walls"])]
				ff[key] = ff.get(key, 0) + 1
				if args.has("ff"):
					var sh_o = w.by_id.get(sh2["by"], null)
					var vic = w.by_id.get(sh2["hit"], null)
					var tg = w.by_id.get(sh2["tgt"], null)
					print("  FF %.1f s: %s -> aimed at %s, hit %s; shooter-victim %.1f m, shooter-target %.1f m, verdict %s" % [sh2["t"], sh2["by"], sh2["tgt"], sh2["hit"],
						sh_o.pos.distance_to(vic.pos) if sh_o != null and vic != null else -1.0, sh_o.pos.distance_to(tg.pos) if sh_o != null and tg != null else -1.0, sh2["verdict"]])
		var s: Dictionary = w.incident.summary()
		var res: Dictionary = Outcome.evaluate(sit, w)
		agg["ops"] += 1
		agg[res["kind"] if agg.has(res["kind"]) else "partial"] += 1
		agg["off"] += int(s["officers"])
		agg["killed"] += int(s["officers_killed"])
		agg["down"] += int(s["officers_down"])
		agg["sus"] += int(s["suspects"])
		agg["sus_down"] += int(s["suspects_down"])
		agg["sus_killed"] += int(s["suspects_killed"])
		agg["t"] += w.t
		for f in w.incident.findings:
			if f["kind"] == "officer_killed":
				agg["bled" if String(f["text"]).ends_with("died of wounds") else "outright"] += 1
		if args.has("v"):
			print("%s map %02d: %s (%s); officers %d of %d down (%d killed); suspects %d of %d down; %.0f s" % [sit["type"], int(sit["map"]), res["label"], res["goal"],
				int(s["officers_down"]), int(s["officers"]), int(s["officers_killed"]), int(s["suspects_down"]), int(s["suspects"]), w.t])
		w.dispose()
	var ops: float = maxf(1.0, agg["ops"])
	print("%s x%d: success %d, partial %d, failure %d; %.0f s each" % [typ, agg["ops"], agg["success"], agg["partial"], agg["failure"], agg["t"] / ops])
	print("officers: %.2f sent, %.2f down, %.2f killed per operation (%d outright, %d bled out)" % [agg["off"] / ops, agg["down"] / ops, agg["killed"] / ops, agg["outright"], agg["bled"]])
	print("suspects: %.2f, %.2f down, %.2f killed per operation" % [agg["sus"] / ops, agg["sus_down"] / ops, agg["sus_killed"] / ops])
	print("officers hit by: ", who)
	print("range: ", rng_d)
	print("recognition: ", recog)
	print("first shot: ", first)
	print("police rounds that hit police: ", ff)
	var ks: Array = why.keys()
	ks.sort_custom(func(a, b): return why[a] > why[b])
	print("what they were doing when hit:")
	for kk in ks.slice(0, 12):
		print("  %3d  %s" % [why[kk], kk])
	quit()
