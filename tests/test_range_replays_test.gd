extends SceneTree
## Full test-range replays of the two reported stalls, plus an exact diagnostic
## on/off determinism comparison. No campaign state or campaign scenarios.
##   godot --headless --path . -s res://tests/test_range_replays_test.gd
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

var fails := 0


func check(ok: bool, text: String) -> void:
	print(("ok    " if ok else "FAIL  ") + text)
	if not ok:
		fails += 1


func replay(map_id: int, a_ech: String, b_ech: String, count: int, seed_v: int, diagnose: bool) -> Dictionary:
	Equipment.armory = {}
	var lv = Maps.get_level(map_id)
	var nav = Nav.new()
	nav.build(lv)
	var cfgs := Teams.team_with_preset_kit(lv, 0, {"n": count, "ech": a_ech})
	cfgs += Teams.team_with_preset_kit(lv, 1, {"n": count, "ech": b_ech})
	var w = World.new()
	w.keep_events = false
	w.diagnostics_enabled = diagnose
	w.log_kinds = {"bad": true}
	w.setup(lv, nav, cfgs, ["assault", "hold"], seed_v, [1, 1], {})
	var guard := 0
	while not w.over and guard < int((w.time_limit + 1.0) / World.DT):
		w.step()
		guard += 1
	var operators := []
	for o in w.ops:
		var bad: Array = o.active_bad.keys()
		bad.sort()
		operators.append({"id": o.id, "state": o.state, "x": o.pos.x, "y": o.pos.y, "stress": o.stress,
			"habit_stress": o.habit_stress, "shots": o.shots, "hits": o.hits, "kills": o.kills,
			"plates": o.plates, "bad": bad, "weapons": o.weapons.duplicate(true)})
	var snapshot := {"time": w.t, "winner": w.winner, "stat": w.stat.duplicate(true),
		"rng_state": w.rng.state, "operators": operators}
	var result := {"snapshot": snapshot, "limit": w.time_limit, "over": w.over,
		"diagnostics": w.diagnostic_counts.duplicate(), "dropped": w.diagnostics_dropped}
	w.dispose()
	return result


func _init() -> void:
	var lane := replay(0, "patrol", "regular", 5, 717920, true)
	var ls: Dictionary = lane["snapshot"]
	print("lane replay: t=%.2f winner=%d shots=%d limit=%.0f events=%s" % [ls["time"], ls["winner"], ls["stat"]["shots"], lane["limit"], str(lane["diagnostics"])])
	check(lane["over"] and ls["time"] < lane["limit"] and ls["stat"]["shots"] > 28,
		"map 00 seed 717920 advances beyond the old 28-shot, 300-second stalemate")
	var cover := replay(11, "untrained", "untrained", 5, 721001, true)
	var cs: Dictionary = cover["snapshot"]
	print("cover replay: t=%.2f winner=%d shots=%d limit=%.0f events=%s" % [cs["time"], cs["winner"], cs["stat"]["shots"], cover["limit"], str(cover["diagnostics"])])
	# The jam-recovery fix changes this fight's trajectory and it now ends after
	# 135 shots, before the old stalled replay had reached its 141st shot. The
	# relevant invariant is a genuine combat outcome before the timeout, not a
	# requirement to fire more rounds than a fight that lasted 900 seconds.
	check(cover["over"] and cs["time"] < cover["limit"] and cs["winner"] != 2 and cs["stat"]["shots"] > 0,
		"map 11 seed 721001 resolves combat before the old 900-second stalemate")
	check(lane["dropped"] == 0 and cover["dropped"] == 0, "replay diagnostics did not overflow")
	var plain := replay(3, "sof", "regular", 3, 740123, false)
	var observed := replay(3, "sof", "regular", 3, 740123, true)
	check(JSON.stringify(plain["snapshot"], "", true) == JSON.stringify(observed["snapshot"], "", true),
		"enabling decision telemetry leaves terminal state and RNG state identical")
	check(int(observed["diagnostics"].get("gd02_sector_plan", 0)) > 0, "instrumented replay records GD02 opportunities")
	check(int(observed["diagnostics"].get("pf04_entry_move", 0)) > 0,
		"a full instrumented replay records actual room-entry movement, not just plans")
	print("test range replays: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails else 0)
