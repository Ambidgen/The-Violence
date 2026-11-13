extends SceneTree
## Playtest 02: big fights on every map. Prints CSV rows:
## map,case,A win %,B win %,draw %,mean time,A down,B down,rooms cleared
##   godot --headless --path . -s res://tests/scale_playtest.gd -- --n=3
##   ... -- --n=4 --gate   pooled per-case assertions (Q5): wins pooled over all
##   maps per case (never a mean of per-map percentages), gated only at n>=30
##   pooled games, non-degenerate (neither side wins everything). The asserted
##   5v5 balance bands live in tests/balance_matrix_test.gd.
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

const CASES := [
	["10 SOF assault vs 20 militia", {"n": 10, "ech": "sof"}, {"n": 20, "ech": "militia"}, "assault", "hold"],
	["20 militia assault vs 10 SOF", {"n": 20, "ech": "militia"}, {"n": 10, "ech": "sof"}, "assault", "hold"],
	["20 regular vs 20 regular", {"n": 20, "ech": "regular"}, {"n": 20, "ech": "regular"}, "assault", "hold"],
]


func _init() -> void:
	var n := 3
	var gate := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.trim_prefix("--n="))
		elif a == "--gate":
			gate = true
	var pooled := {}        # case label -> [a wins, b wins, draws, games]
	for i in Maps.count():
		var lv = Maps.get_level(i)
		var nav = Nav.new()
		nav.build(lv)
		for c in CASES:
			var wins := [0, 0, 0]
			var tot := {"t": 0.0, "ad": 0, "bd": 0, "cl": 0}
			for s in n:
				var cfgs: Array = Teams.team(lv, 0, c[1]) + Teams.team(lv, 1, c[2])
				var w = World.new()
				w.keep_events = false
				w.setup(lv, nav, cfgs, [c[3], c[4]], 9000 + 31 * i + s)
				while not w.over:
					w.step()
				wins[w.winner] += 1
				tot["t"] += w.t
				tot["cl"] += w.teams[0]["cleared"].size()
				for o in w.ops:
					if not o.alive():
						tot["ad" if o.team == 0 else "bd"] += 1
				w.dispose()
			print("%02d,%s,%.0f,%.0f,%.0f,%.1f,%.1f,%.1f,%.1f" % [i, c[0], 100.0 * wins[0] / n, 100.0 * wins[1] / n, 100.0 * wins[2] / n,
				tot["t"] / n, float(tot["ad"]) / n, float(tot["bd"]) / n, float(tot["cl"]) / n])
			var p: Array = pooled.get(c[0], [0, 0, 0, 0])
			p[0] += wins[0]
			p[1] += wins[1]
			p[2] += wins[2]
			p[3] += n
			pooled[c[0]] = p
	var fails := 0
	if gate:
		for c2 in CASES:
			var p2: Array = pooled[c2[0]]
			var sh: float = float(p2[0]) / maxf(1.0, float(p2[3]))
			var ok: bool = p2[3] < 30 or (sh > 0.05 and sh < 0.95)
			print("# pooled %s: attackers win %.1f%% over %d games  %s" % [c2[0], 100.0 * sh, p2[3],
				"ungated (n<30)" if p2[3] < 30 else ("PASS" if ok else "FAIL")])
			if not ok:
				fails += 1
		print("# scale gate: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
