extends SceneTree
## Test-range-only deterministic fixture. Uses UI preset kits; no campaign cases.
## Run: godot --headless --path . -s res://tests/test_range_determinism_test.gd
## Deliberately regenerate after reviewing intentional behavior changes:
##   godot --headless --path . -s res://tests/test_range_determinism_test.gd -- --write
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

const FIXTURE := "res://tests/fixtures/test_range_determinism.json"
const CASES := [
	{"id": "lane_repro", "map": 0, "na": 5, "nb": 5, "a": "patrol", "b": "regular", "seed": 717920},
	{"id": "cover_repro", "map": 11, "na": 5, "nb": 5, "a": "untrained", "b": "untrained", "seed": 721001},
	{"id": "sof_control", "map": 0, "na": 3, "nb": 3, "a": "sof", "b": "sof", "seed": 2293801, "all_good": true},
	{"id": "militia_patrol", "map": 3, "na": 3, "nb": 3, "a": "militia", "b": "patrol", "seed": 2296801},
	{"id": "unequal", "map": 4, "na": 5, "nb": 2, "a": "regular", "b": "police", "seed": 2297801},
	{"id": "motel", "map": 7, "na": 8, "nb": 8, "a": "sof", "b": "regular", "seed": 2300801},
	{"id": "shield", "map": 11, "na": 3, "nb": 3, "a": "sof", "b": "sof", "seed": 2304801, "all_good": true, "shield": true},
	{"id": "large_team", "map": 3, "na": 10, "nb": 10, "a": "regular", "b": "regular", "seed": 2296801},
]


## Floats in the snapshot are settled to a millionth before they are hashed (2026-11-12).
## The stat block carries running sums of seconds at full double precision, and the last
## bits of those depend on the CPU and C library a run happens on: on 2026-11-13 the same
## commit that passed CI on 5 Nov failed 7 of 8 cases on a newer runner, with every
## winner, time, shot and hit unchanged. A millionth of a second is arithmetic, not
## behaviour; anything larger still changes the digest.
static func _settle(v):
	if v is float:
		return snappedf(v, 0.000001)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _settle(v[k])
		return d
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(_settle(x))
		return a
	return v


static func _md5(v) -> String:
	return JSON.stringify(v, "", true).md5_text().substr(0, 16)


## The last run's snapshots, by case: printed for a failing case so that two machines'
## logs can be compared line for line. Never written to the fixture.
var _snapshots := {}


func _run(c: Dictionary) -> Dictionary:
	Equipment.armory = {}
	var lv = Maps.get_level(c["map"])
	var nav = Nav.new()
	nav.build(lv)
	var cfgs := Teams.team_with_preset_kit(lv, 0, {"n": c["na"], "ech": c["a"]})
	cfgs += Teams.team_with_preset_kit(lv, 1, {"n": c["nb"], "ech": c["b"]})
	if c.get("all_good", false):
		for cfg in cfgs:
			cfg["good"] = {}
			for hid in Habits.good_ids():
				cfg["good"][hid] = true
			cfg["bad"] = {}
	if c.get("shield", false):
		var kit: Dictionary = cfgs[0]["kit"].duplicate(true)
		kit["gear"]["shield"] = 1
		kit = Equipment.validate(kit, Equipment.who_of_echelon(cfgs[0]["echelon"]))
		cfgs[0]["kit"] = kit
		cfgs[0]["plates"] = kit["plates"]
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, cfgs, ["assault", "hold"], c["seed"], [1, 1], {})
	var guard := 0
	while not w.over and guard < int((w.time_limit + 1.0) / World.DT):
		w.step()
		guard += 1
	var operators: Array = []
	for o in w.ops:
		var bad: Array = o.active_bad.keys()
		bad.sort()
		operators.append({"id": o.id, "state": o.state, "x": snappedf(o.pos.x, 0.001), "y": snappedf(o.pos.y, 0.001),
			"stress": snappedf(o.stress, 0.0001), "habit_stress": snappedf(o.habit_stress, 0.0001),
			"shots": o.shots, "hits": o.hits, "kills": o.kills, "plates": o.plates, "bad": bad,
			"rifle": o.weapons["rifle"].duplicate(true), "pistol": o.weapons["pistol"].duplicate(true)})
	var snapshot := {"time": snappedf(w.t, 0.001), "winner": w.winner, "stat": _settle(w.stat.duplicate(true)),
		"rng": w.rng.state, "operators": _settle(operators)}
	_snapshots[c["id"]] = snapshot
	# the digest is the whole snapshot; the parts say which of it moved when it does
	var result := {"digest": _md5(snapshot), "time": snapshot["time"],
		"winner": w.winner, "shots": w.stat["shots"], "hits": w.stat["hits"], "timeout": w.t >= w.time_limit,
		"parts": {"stat": _md5(snapshot["stat"]), "rng": str(snapshot["rng"]), "operators": _md5(snapshot["operators"])}}
	var per_op := {}
	for od in snapshot["operators"]:
		per_op[String(od["id"])] = _md5(od).substr(0, 8)
	result["ops"] = per_op
	w.dispose()
	return result


func _init() -> void:
	var write := "--write" in OS.get_cmdline_user_args()
	# --show=<case>: print that case's stat and operators as this machine computes them
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--show="):
			for c0 in CASES:
				if c0["id"] == String(arg).trim_prefix("--show="):
					_run(c0)
					var sn: Dictionary = _snapshots[c0["id"]]
					print("stat %s" % JSON.stringify(sn["stat"], "", true))
					for od0 in sn["operators"]:
						print("op %s" % JSON.stringify(od0, "", true))
			quit(0)
			return
	var expected := {}
	if not write:
		var f := FileAccess.open(FIXTURE, FileAccess.READ)
		if f == null:
			printerr("Missing range determinism fixture: " + FIXTURE)
			quit(1)
			return
		var parsed = JSON.parse_string(f.get_as_text())
		if not parsed is Dictionary or not parsed.get("cases", null) is Dictionary:
			printerr("Invalid range determinism fixture")
			quit(1)
			return
		expected = parsed["cases"]
	var results := {}
	var failures := 0
	for c in CASES:
		var result := _run(c)
		results[c["id"]] = result
		var old: Dictionary = expected.get(c["id"], {})
		var ok: bool = write or (not old.is_empty() and old["digest"] == result["digest"])
		if not ok:
			failures += 1
		print("%s %-16s %s  winner=%d time=%.2f shots=%d" % ["ok  " if ok else "FAIL", c["id"],
			result["digest"], result["winner"], result["time"], result["shots"]])
		if not ok and not old.is_empty():
			# Which part moved, and what it is now, so the next reader does not have to guess.
			# Every line says FAIL: that is what tools/run_tests.sh copies into the CI log.
			var moved: Array = []
			var op: Dictionary = old.get("parts", {})
			for part in result["parts"]:
				if op.has(part) and String(op[part]) != String(result["parts"][part]):
					moved.append(part)
			for k in ["winner", "time", "shots", "hits", "timeout"]:
				if old.has(k) and str(old[k]) != str(result[k]):
					moved.append("%s %s -> %s" % [k, str(old[k]), str(result[k])])
			print("FAIL   %s moved: %s" % [c["id"], ", ".join(moved) if not moved.is_empty() else "(the fixture has no parts to compare)"])
			var snap: Dictionary = _snapshots[c["id"]]
			if moved.has("stat"):
				print("FAIL   %s stat %s" % [c["id"], JSON.stringify(snap["stat"], "", true)])
			var old_ops: Dictionary = old.get("ops", {})
			var shown := 0
			for od in snap["operators"]:
				var oid := String(od["id"])
				if old_ops.has(oid) and String(old_ops[oid]) != String(result["ops"][oid]) and shown < 6:
					shown += 1
					print("FAIL   %s op %s" % [c["id"], JSON.stringify(od, "", true)])
	if not write:
		for id in expected:
			if not results.has(id):
				print("FAIL missing case ", id)
				failures += 1
	if write:
		var out := FileAccess.open(FIXTURE, FileAccess.WRITE)
		if out == null:
			printerr("Could not write range determinism fixture")
			quit(1)
			return
		out.store_string(JSON.stringify({"model": "test-range-2026-11-02-clearance-progress",
			"digest": "floats settled to 1e-6, parts recorded (2026-11-12); no change of behaviour: every winner, time, shot and hit is as before",
			"cases": results}, "  ", true) + "\n")
		out.close()
		print("Wrote %d range-only digests to %s" % [results.size(), FIXTURE])
	print("range determinism: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)
