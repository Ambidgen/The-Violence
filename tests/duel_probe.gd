extends SceneTree
## Diagnostic (v0.9.1): equal teams, assault against hold, how each side's fallen fell:
## what they were doing, at what range, whether they had recognised the shooter, and who
## got the first shot of each exchange.
##   godot --headless --path . -s res://tests/duel_probe.gd -- [--n=10] [--ech=regular] [--off=wolf]
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "10"))
	var ech: String = args.get("ech", "regular")
	var off: Array = String(args.get("off", "")).split(",", false)
	var st := [{}, {}]
	var rg := [{}, {}]
	var rc := [{"yes": 0, "no": 0}, {"yes": 0, "no": 0}]
	var shooter_state := [{}, {}]
	var wins := 0
	var fs := {}
	var games := 0
	for mi in [0, 4, 5, 6]:
		var lv = Maps.get_level(mi)
		var nv = Nav.new()
		nv.build(lv)
		for sd in n:
			var cfgs: Array = Teams.team(lv, 0, {"n": 5, "ech": ech}) + Teams.team(lv, 1, {"n": 5, "ech": ech})
			var w = World.new()
			w.setup(lv, nv, cfgs, ["assault", "hold"], 9100 + sd * 13 + mi, [1, 1], {})
			for f in off:
				w.brain.features[f] = false
			while not w.over and w.t < 600.0:
				w.step()
				for ev in w.events:
					if ev["type"] != "down":
						continue
					var o = w.by_id.get(ev["id"], null)
					if o == null or o.civ:
						continue
					var sh: Dictionary = {}
					for i in range(w.incident.shots.size() - 1, -1, -1):
						if w.incident.shots[i]["hit"] == o.id:
							sh = w.incident.shots[i]
							break
					var k: String = "%s: %s" % [o.mind, String(o.dbg).split(" >")[0].substr(0, 30)]
					st[o.team][k] = st[o.team].get(k, 0) + 1
					var x = w.by_id.get(sh.get("by", ""), null)
					if x != null:
						var d: float = o.pos.distance_to(x.pos)
						var b: String = "<3" if d < 3.0 else ("3-6" if d < 6.0 else ("6-12" if d < 12.0 else "12+"))
						rg[o.team][b] = rg[o.team].get(b, 0) + 1
						rc[o.team]["yes" if float(o.rec.get(x.id, 0.0)) >= 1.0 else "no"] += 1
						var k2: String = "%s: %s" % [x.mind, String(x.dbg).split(" >")[0].substr(0, 30)]
						shooter_state[o.team][k2] = shooter_state[o.team].get(k2, 0) + 1
				w.events.clear()
			# each pair's first shot: who fired first at whom, and who ended up down
			var firsts := {}
			for sh2 in w.incident.shots:
				var a = w.by_id.get(sh2["by"], null)
				var tg = w.by_id.get(sh2["tgt"], null)
				if a == null or tg == null or tg.civ:
					continue
				var key: String = (a.id + "|" + tg.id) if a.id < tg.id else (tg.id + "|" + a.id)
				if not firsts.has(key):
					firsts[key] = [a, tg]
			for key2 in firsts:
				var a2 = firsts[key2][0]
				var t2 = firsts[key2][1]
				var side: String = ["att", "def"][a2.team]
				fs[side + " fired first"] = fs.get(side + " fired first", 0) + 1
				if not t2.alive() or t2.state != "ok":
					fs[side + " first, and the target fell"] = fs.get(side + " first, and the target fell", 0) + 1
				if a2.state != "ok":
					fs[side + " first, and the shooter fell"] = fs.get(side + " first, and the shooter fell", 0) + 1
			games += 1
			if w.winner == 0:
				wins += 1
			w.dispose()
	print("%s: attackers win %d of %d" % [ech, wins, games])
	print("first shots: ", fs)
	for tm in 2:
		print("== %s fallen: range %s, had recognised their killer %s" % [["ATTACKERS", "DEFENDERS"][tm], rg[tm], rc[tm]])
		var ks: Array = st[tm].keys()
		ks.sort_custom(func(a, b): return st[tm][a] > st[tm][b])
		for kk in ks.slice(0, 10):
			print("   %3d  %s" % [st[tm][kk], kk])
		print("   their killers were:")
		var ks2: Array = shooter_state[tm].keys()
		ks2.sort_custom(func(a, b): return shooter_state[tm][a] > shooter_state[tm][b])
		for kk2 in ks2.slice(0, 8):
			print("     %3d  %s" % [shooter_state[tm][kk2], kk2])
	quit(0 if games > 0 else 1)   # P0.A1: a probe; fails only if no game ran
