extends SceneTree
## Tier 0 #4 -- the determinism regression.
##
## Runs a fixed set of seeds on a fixed set of matchups and hashes the terminal
## world state. The digests are stored in tests/fixtures/determinism.json, so any
## change that quietly alters the simulation -- a refactor of op.gd, a new habit
## hook, a different RNG call order -- shows up here rather than as a mystery
## balance swing three weeks later.
##
##   godot --headless --path . -s res://tests/determinism_test.gd
##   godot --headless --path . -s res://tests/determinism_test.gd -- --write
##   godot --headless --path . -s res://tests/determinism_test.gd -- --verbose
##
## --write regenerates the fixture. Do it deliberately, and read the diff.

const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

const FIXTURE := "res://tests/fixtures/determinism.json"

## [map, n_a, n_b, ech_a, ech_b, posture_a, posture_b]
const CASES := [
	[0, 2, 2, "sof", "untrained", "assault", "hold"],
	[0, 5, 5, "regular", "regular", "assault", "hold"],
	[0, 3, 5, "police", "militia", "assault", "hold"],
	[1, 2, 2, "sof", "militia", "assault", "hold"],
	[1, 4, 4, "regular", "untrained", "assault", "hold"],
	[4, 5, 5, "police", "regular", "assault", "hold"],
	[4, 8, 8, "regular", "militia", "hunt", "hunt"],
	[7, 12, 12, "sof", "regular", "assault", "hold"],
	[10, 6, 6, "police", "militia", "assault", "hold"],
]
const SEEDS := [1001, 2002, 3003]


## A digest of everything the simulation is supposed to decide. Positions to 3
## decimal places: enough to catch divergence, not so much that float noise in an
## unrelated path trips it.
static func digest(w) -> String:
	var parts: Array = []
	parts.append("t=%.4f" % w.t)
	parts.append("sh=%d,h=%d,ff=%d,st=%d" % [w.stat["shots"], w.stat["hits"],
		w.stat["friendly"], w.stat["stray"]])
	var ops: Array = []
	for o in w.ops:
		ops.append("%s|%s|%.3f,%.3f|w%d|p%d|a%d|s%.4f|x%.4f|b%.4f|k%d" % [o.id, o.state,
			o.pos.x, o.pos.y, o.wounds, o.plates, o.alert, o.stress, o.suppress,
			o.blood, o.kills])
	ops.sort()
	parts.append("ops=" + ";".join(ops))
	parts.append("dead=%d" % w.deaths.size())
	return str(hash("|".join(parts)))


func _run(case: Array, seed_v: int) -> Dictionary:
	var lv = Maps.get_level(case[0])
	var nav = Nav.new()
	nav.build(lv)
	var cfgs: Array = Teams.team(lv, 0, {"n": case[1], "ech": case[3]}) \
		+ Teams.team(lv, 1, {"n": case[2], "ech": case[4]})
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, cfgs, [case[5], case[6]], seed_v)
	var guard := 0
	while not w.over and guard < 200000:
		w.step()
		guard += 1
	var d := digest(w)
	var out := {"t": w.t, "winner": w.winner, "shots": w.stat["shots"],
		"hits": w.stat["hits"], "digest": d}
	w.dispose()
	return out


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var write := "--write" in args
	var verbose := "--verbose" in args

	var have: Dictionary = {}
	if not write:
		var f := FileAccess.open(FIXTURE, FileAccess.READ)
		if f != null:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				have = parsed
		if have.is_empty():
			print("no fixture at %s -- run with --write to create one" % FIXTURE)

	var out: Dictionary = {"cases": {}}
	var bad := 0
	var n_run := 0
	var t0 := Time.get_ticks_msec()

	for ci in CASES.size():
		var case: Array = CASES[ci]
		for seed_v in SEEDS:
			var key: String = "m%02d_%dv%d_%s_%s_%d" % [case[0], case[1], case[2],
				case[3], case[4], seed_v]
			var r := _run(case, seed_v)
			n_run += 1
			out["cases"][key] = r
			if have.is_empty():
				continue
			var old: Dictionary = have.get("cases", {}).get(key, {})
			if old.is_empty():
				print("  NEW   %-28s %s" % [key, r["digest"]])
				continue
			if str(old.get("digest", "")) != str(r["digest"]):
				bad += 1
				print("  DIFF  %-28s %s -> %s   (t %.1f -> %.1f, shots %s -> %s)" % [key,
					old.get("digest", "?"), r["digest"], float(old.get("t", 0.0)),
					float(r["t"]), old.get("shots", "?"), r["shots"]])
			elif verbose:
				print("  ok    %-28s %s   t=%.1f shots=%d" % [key, r["digest"], r["t"], r["shots"]])

	if write:
		var j := JSON.stringify(out, "  ")
		DirAccess.make_dir_recursive_absolute(FIXTURE.get_base_dir())
		var g := FileAccess.open(FIXTURE, FileAccess.WRITE)
		if g == null:
			print("could not write %s" % FIXTURE)
			quit(1)
			return
		g.store_string(j)
		g.close()
		print("wrote %d digests to %s" % [out["cases"].size(), FIXTURE])
		quit()
		return

	print("")
	print("%d match(es), %d digest(s) changed, %d ms" % [n_run, bad, Time.get_ticks_msec() - t0])
	if have.is_empty():
		print("no fixture to compare against")
		quit()
		return
	if bad == 0:
		print("OK: the simulation is reproducible for every seeded case.")
		quit()
		return
	print("FAIL: %d case(s) changed. If that is intended, re-run with --write." % bad)
	quit(1)
