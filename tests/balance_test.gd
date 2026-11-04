extends SceneTree
## The attack/defence balance (v0.8.5): five a side, assault against a held house on maps
## 00, 04, 05 and 06, the attackers' share of wins. With the brains switched off one at a
## time it shows which one moves the balance.
##   godot --headless --path . -s res://tests/balance_test.gd -- [--n=10] [--ech=regular] [--off=wolf,lion] [--each] [--gate]
##
## --gate (run it with --n=20: at the default 40 fights the share wobbles past 50%) passes when equal regulars' attackers win 30-50% (the hold layer's 33% before
## the brains, v0.7.9's 60% after).
##
## The full asserted matrix (every map family, regular/police/SOF, pooled n>=30, the
## SOF hold-habit regression) is tests/balance_matrix_test.gd; this stays the quick
## one-matchup check and the brains on/off comparison.

const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

const MAPS := [0, 4, 5, 6]
var _navs := {}
var only_enabled := false


func _nav(mi: int, lv):
	if not _navs.has(mi):
		var nv = Nav.new()
		nv.build(lv)
		_navs[mi] = nv
	return _navs[mi]


func run(n: int, ech: String, off: Array) -> Dictionary:
	var res := {"a": 0, "b": 0, "draw": 0, "a_dead": 0, "b_dead": 0, "t": 0.0}
	for mi in MAPS:
		var lv = Maps.get_level(mi)
		for sd in n:
			var cfgs: Array = Teams.team(lv, 0, {"n": 5, "ech": ech}) + Teams.team(lv, 1, {"n": 5, "ech": ech})
			if only_enabled:
				cfgs = cfgs.filter(func(c): return c["enabled"])
			var w = World.new()
			w.keep_events = false
			w.setup(lv, _nav(mi, lv), cfgs, ["assault", "hold"], 9100 + sd * 13 + mi, [1, 1], {})
			for f in off:
				w.brain.features[f] = false
			while not w.over and w.t < 600.0:
				w.step()
				w.events.clear()
			res[["a", "b", "draw", "draw"][clampi(w.winner, 0, 3)]] += 1
			for o in w.ops:
				if not o.alive():
					res["a_dead" if o.team == 0 else "b_dead"] += 1
			res["t"] += w.t
			w.dispose()
	return res


func _line(label: String, r: Dictionary, n_all: int) -> void:
	print("%-22s attackers win %3d%%  (%d/%d, draws %d)  down per fight A %.1f B %.1f  %.0f s" % [label,
		int(round(100.0 * r["a"] / n_all)), r["a"], n_all, r["draw"], float(r["a_dead"]) / n_all, float(r["b_dead"]) / n_all, r["t"] / n_all])


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "10"))
	var ech: String = args.get("ech", "regular")
	var off: Array = String(args.get("off", "")).split(",", false)
	var n_all := n * MAPS.size()
	only_enabled = args.has("enabled")
	var base := run(n, ech, off)
	_line("%s%s" % [ech, (" -" + ",".join(off)) if not off.is_empty() else ""], base, n_all)
	if args.has("each"):
		for f in ["lizard", "lion", "wolf", "pairs", "disperse"]:
			_line("  without " + f, run(n, ech, off + [f]), n_all)
		_line("  all brains off", run(n, ech, ["lizard", "lion", "wolf", "pairs", "disperse"]), n_all)
	var ok := true
	if args.has("gate"):
		var share := float(base["a"]) / n_all
		ok = share >= 0.30 and share <= 0.50
		print("gate (30-50%%): %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
