extends SceneTree
## The balance matrix (playtest pass Q5): attacker win shares asserted against bands,
## per echelon pair and map family, pooled over seeds.
##
## Why this exists beside balance_test.gd: that gate covers one matchup (equal
## regulars, 5v5) on four houses, while the game ships twelve maps and six echelons,
## and scale_playtest.gd printed a CSV nothing asserted on. This harness is the
## asserted successor: equal regular / police tactical / special-operations pairs on
## every map family, three cross-echelon ordering checks pooled over all twelve
## maps, and a regression cell for the SOF hold-habit interaction the v0.8 notes
## leave open (the hold habits individually help — HD16 was measured at 11 points —
## "but together they cancel out").
##
## Estimator: pooled, never a mean of per-map means. A cell's share is attacker wins
## over all its games (draws in the denominator, as in balance_test.gd), and a cell
## is only gated once it has at least --min games (30 by default); below that it is
## reported and marked "ungated", because a share over a handful of fights wobbles
## past any honest band (see balance_test.gd's own header).
##
## Bands come from the measurements already on record: equal regulars on houses keep
## the long-standing 30-50% design target (43% in v0.8.5, 48% after the v0.9.1
## friendly-fire fix); equal police tactical attackers won 59-67% (v0.8.5) and 60%
## (v0.9.1), an edge their kit gives them, so their house band sits at 40-70%.
## Families and pairs with no measurement on record get wide provisional bands: they
## catch degeneracy (a side that always or never wins) now, and the first engine run
## of --gate is what narrows them. The expected table is in CHANGELOG.md.
##
##   godot --headless --path . -s res://tests/balance_matrix_test.gd -- --n=2
##   godot --headless --path . -s res://tests/balance_matrix_test.gd -- --gate
##     [--n=S seeds per map] [--min=30] [--families=houses,plaza] [--pairs=regular,sof]
##     [--no-cross] [--no-hold]

const Habits = preload("res://scripts/data/habits.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

const FAMILIES := {"houses": [0, 1, 2, 4, 5, 6], "commercial": [3, 7, 8], "multi-room": [9, 10], "plaza": [11]}
const FAMILY_ORDER := ["houses", "commercial", "multi-room", "plaza"]
## Attacker-win bands [lo, hi] for equal pairs, assault against hold, 5v5.
const BANDS := {
	"regular": {"houses": [0.30, 0.50], "commercial": [0.25, 0.60], "multi-room": [0.20, 0.60], "plaza": [0.20, 0.70]},
	"police": {"houses": [0.40, 0.70], "commercial": [0.30, 0.75], "multi-room": [0.30, 0.75], "plaza": [0.30, 0.75]},
	"sof": {"houses": [0.30, 0.70], "commercial": [0.30, 0.70], "multi-room": [0.30, 0.70], "plaza": [0.30, 0.70]},
}
## Cross-echelon ordering, pooled over every map: [attacker, holder, lo, hi].
const CROSS := [["sof", "regular", 0.55, 1.0], ["regular", "sof", 0.0, 0.45], ["police", "regular", 0.50, 1.0]]
const HOLD_MAPS := [0, 4, 5, 6]     # the balance_test houses, for the hold-habit regression

var _navs := {}
var failures := 0
var gated := 0


func _nav(mi: int, lv):
	if not _navs.has(mi):
		var nv = Nav.new()
		nv.build(lv)
		_navs[mi] = nv
	return _navs[mi]


## One pooled cell: every map x every seed, wins pooled (never averaged per map).
func _cell(ech_a: String, ech_b: String, maps: Array, seeds: int, remove_b: Array = []) -> Dictionary:
	var res := {"a": 0, "b": 0, "draw": 0, "games": 0, "a_down": 0, "b_down": 0, "t": 0.0}
	for mi in maps:
		var lv = Maps.get_level(mi)
		for s in seeds:
			var cfgs: Array = Teams.team(lv, 0, {"n": 5, "ech": ech_a}) + Teams.team(lv, 1, {"n": 5, "ech": ech_b, "remove": remove_b})
			var w = World.new()
			w.keep_events = false
			w.setup(lv, _nav(mi, lv), cfgs, ["assault", "hold"], 12000 + mi * 131 + s * 17, [1, 1], {})
			while not w.over and w.t < 600.0:
				w.step()
				w.events.clear()
			res[["a", "b", "draw", "draw"][clampi(w.winner, 0, 3)]] += 1
			res["games"] += 1
			res["t"] += w.t
			for o in w.ops:
				if not o.alive():
					res["a_down" if o.team == 0 else "b_down"] += 1
			w.dispose()
	return res


func _share(r: Dictionary) -> float:
	return float(r["a"]) / maxf(1.0, float(r["games"]))


## Report one cell (CSV + a readable line) and gate it if it has the games for it.
func _report(label: String, fam: String, ech_a: String, ech_b: String, r: Dictionary, band: Array, min_n: int) -> void:
	var sh := _share(r)
	var verdict := "ungated (n=%d < %d)" % [r["games"], min_n]
	if int(r["games"]) >= min_n:
		gated += 1
		var ok: bool = sh >= float(band[0]) and sh <= float(band[1])
		verdict = "PASS" if ok else "FAIL"
		if not ok:
			failures += 1
	print("%s,%s,%s,%s,%d,%.1f,%.0f,%.0f,%s" % [fam, label, ech_a, ech_b, r["games"], 100.0 * sh, 100.0 * float(band[0]), 100.0 * float(band[1]), verdict])
	print("# %-28s attackers win %5.1f%%  (%d/%d, draws %d)  down/fight A %.1f B %.1f  %.0f s  band %.0f-%.0f%%  %s" % [
		label, 100.0 * sh, r["a"], r["games"], r["draw"], float(r["a_down"]) / maxf(1.0, r["games"]),
		float(r["b_down"]) / maxf(1.0, r["games"]), float(r["t"]) / maxf(1.0, r["games"]), 100.0 * float(band[0]), 100.0 * float(band[1]), verdict])


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var gate: bool = args.has("gate")
	var min_n := int(args.get("min", "30"))
	var n_arg := int(args.get("n", "0"))
	var fams: Array = FAMILY_ORDER.duplicate()
	if args.has("families"):
		fams = Array(String(args["families"]).split(","))
	var pairs: Array = ["regular", "police", "sof"]
	if args.has("pairs"):
		pairs = Array(String(args["pairs"]).split(","))
	print("family,label,attack,hold,games,a_win_pct,band_lo,band_hi,verdict")
	# equal pairs, by family. In gate mode each family gets the seeds per map that
	# pool to at least --min games; otherwise --n seeds per map (default 2).
	for fam in fams:
		var maps: Array = FAMILIES[fam]
		var seeds := 2
		if gate:
			seeds = int(ceil(float(min_n) / float(maps.size())))
		if n_arg > 0:
			seeds = n_arg
		for ech in pairs:
			_report("%s equal (%s)" % [ech, fam], fam, ech, ech, _cell(ech, ech, maps, seeds), BANDS[ech][fam], min_n)
	# cross-echelon ordering, pooled over all twelve maps
	if not args.has("no-cross") and (gate or n_arg > 0):
		var all_maps: Array = []
		for mi in Maps.count():
			all_maps.append(mi)
		var seeds2: int = n_arg if n_arg > 0 else int(ceil(float(min_n) / float(all_maps.size())))
		for cx in CROSS:
			_report("%s attack %s (all maps)" % [cx[0], cx[1]], "all", cx[0], cx[1],
				_cell(cx[0], cx[1], all_maps, seeds2), [cx[2], cx[3]], min_n)
	# the SOF hold-habit interaction: none, HD16 alone, the whole layer. Together the
	# habits have been measured to cancel; the regression is that together they must
	# not make the defence *worse* than none by more than the noise band allows.
	if not args.has("no-hold") and gate:
		var hd: Array = Habits.preset_good("sof").filter(func(g): return String(g).begins_with("HD"))
		var hd16_only: Array = hd.filter(func(g): return g != "HD16")
		var seeds3: int = n_arg if n_arg > 0 else int(ceil(float(min_n) / float(HOLD_MAPS.size())))
		var none := _cell("sof", "sof", HOLD_MAPS, seeds3, hd)
		var only16 := _cell("sof", "sof", HOLD_MAPS, seeds3, hd16_only)
		var all := _cell("sof", "sof", HOLD_MAPS, seeds3, [])
		for arm in [["no hold habits", none], ["HD16 only", only16], ["all hold habits", all]]:
			print("# sof vs sof, defenders %-16s attackers win %5.1f%%  (%d games)" % [arm[0], 100.0 * _share(arm[1]), arm[1]["games"]])
		print("# hold layer is worth %.1f points together, %.1f for HD16 alone (the v0.8 cancellation, kept visible)" % [
			100.0 * (_share(none) - _share(all)), 100.0 * (_share(none) - _share(only16))])
		if int(none["games"]) >= min_n:
			gated += 1
			var ok_hold: bool = _share(all) <= _share(none) + 0.10 and _share(only16) <= _share(none) + 0.10
			print("# hold-habit regression: %s" % ("PASS" if ok_hold else "FAIL"))
			if not ok_hold:
				failures += 1
	print("# balance matrix: %d gated cell(s), %d failure(s)%s" % [gated, failures,
		"" if gate or gated > 0 else "  (run with --gate for asserted bands at n>=30 pooled)"])
	quit(1 if failures > 0 else 0)
