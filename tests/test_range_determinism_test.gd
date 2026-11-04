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
	var snapshot := {"time": snappedf(w.t, 0.001), "winner": w.winner, "stat": w.stat.duplicate(true),
		"rng": w.rng.state, "operators": operators}
	var result := {"digest": JSON.stringify(snapshot, "", true).md5_text().substr(0, 16), "time": snapshot["time"],
		"winner": w.winner, "shots": w.stat["shots"], "hits": w.stat["hits"], "timeout": w.t >= w.time_limit}
	w.dispose()
	return result


func _init() -> void:
	var write := "--write" in OS.get_cmdline_user_args()
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
		out.store_string(JSON.stringify({"model": "test-range-2026-11-02-clearance-progress", "cases": results}, "  ", true) + "\n")
		out.close()
		print("Wrote %d range-only digests to %s" % [results.size(), FIXTURE])
	print("range determinism: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)
