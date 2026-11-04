extends SceneTree
## Focused test-range regressions for safe lane recovery, reload/cover search,
## diagnostics, shield observations and resistance-adjusted habit stress.
##   godot --headless --path . -s res://tests/test_range_regression_test.gd
const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

var failures := 0


class NoRouteNav:
	extends RefCounted
	var candidates: Array = []
	func is_free(_p: Vector2) -> bool:
		return false
	func line_ok(_prof: int, _a: Vector2, _b: Vector2) -> bool:
		return false
	func spots_near(_p: Vector2, _r: float) -> Array:
		return candidates
	func find_path(_prof: int, _a: Vector2, _b: Vector2, _avoid := "") -> PackedVector2Array:
		return PackedVector2Array()


func check(ok: bool, text: String) -> void:
	print(("ok    " if ok else "FAIL  ") + text)
	if not ok:
		failures += 1


func world(map_id := 11, count := 2):
	Equipment.armory = {}
	var lv = Maps.get_level(map_id)
	var nav = Nav.new()
	nav.build(lv)
	var cfgs: Array = Teams.team_with_preset_kit(lv, 0, {"n": count, "ech": "regular", "habits": "none"})
	cfgs += Teams.team_with_preset_kit(lv, 1, {"n": count, "ech": "regular", "habits": "none"})
	for cfg in cfgs:
		cfg["bad"] = {}
	var w = World.new()
	w.keep_events = false
	w.diagnostics_enabled = true
	w.setup(lv, nav, cfgs, ["assault", "hold"], 94131)
	w.t = 10.0
	w.by_id["A1"].pos = Vector2(5.0, 5.0)
	w.by_id["B1"].pos = Vector2(9.0, 5.0)
	if count > 1:
		w.by_id["A2"].pos = Vector2(7.0, 5.0)
		w.by_id["B2"].pos = Vector2(16.0, 10.0)
	w._grid_build()
	return w


func ready(w, shooter, target) -> void:
	shooter.action = {}
	shooter.sidestep = {}
	shooter.last_shot_t = -99.0
	shooter.judges = false
	w.engage(shooter, target, "chest", true)
	shooter.aim["on"] = true
	shooter.aim["settle"] = 1.0
	shooter.aim["pause"] = 0.0
	shooter.aim["want_t"] = w.t


func hold_for(w, shooter, seconds: float) -> void:
	for i in int(ceil(seconds / World.DT)):
		w.t += World.DT
		shooter.aim["want_t"] = w.t
		w._aim_update(shooter)


func event_count(w, kind: String) -> int:
	return int(w.diagnostic_counts.get(kind, 0))


func test_weapons_tight() -> void:
	var w = world(11, 1)
	var a = w.by_id["A1"]
	var e = w.by_id["B1"]
	a.judges = true
	a.judged[e.id] = {"v": "threat"}
	e.aim = {}
	e.last_shot_t = -99.0
	a.roe_tight = false
	check(w.cleared_to_fire(a, e), "ordinary police may fire at a judged armed threat before it attacks")
	a.roe_tight = true
	check(not w.cleared_to_fire(a, e), "Weapons tight holds fire on an armed but non-attacking threat")
	e.aim = {"tid": a.id}
	e.armed_t = w.t
	check(w.cleared_to_fire(a, e), "Weapons tight still permits fire at an attacking threat")
	w.dispose()


func test_lane() -> void:
	var w = world()
	var a = w.by_id["A1"]
	var mate = w.by_id["A2"]
	var e = w.by_id["B1"]
	ready(w, a, e)
	var magazine: int = a.ws()["mag"]
	w._aim_update(a)
	check(a.ws()["mag"] == magazine and a.aim.has("held_t"), "ordinary shooters hold fire through a friend")
	hold_for(w, a, 1.2)
	check(a.sidestep.is_empty() and mate.sidestep.is_empty(), "non-WD10 shooters do not take the faster WD10 recovery")
	hold_for(w, a, 0.5)
	check(not a.sidestep.is_empty() or not mate.sidestep.is_empty() or a.ticker.has("lane_goal"),
		"ordinary shooters attempt a bounded safe lane recovery")
	var unsafe := false
	for i in 40:
		w.t += World.DT
		w._grid_build()
		w._move2(a)
		w._move2(mate)
		w._grid_build()
		var blocked: bool = w.friend_in_line(a, e.pos, 0.3)
		var before: int = a.ws()["mag"]
		a.aim["want_t"] = w.t
		w._aim_update(a)
		if blocked and a.ws()["mag"] < before:
			unsafe = true
		if a.ws()["mag"] < before:
			break
	check(not unsafe and a.ws()["mag"] < magazine, "repositioned shooter progresses without firing through the blocked lane")
	check(event_count(w, "lane_hold_start") > 0 and event_count(w, "lane_recovery") > 0,
		"lane holds and recovery attempts are recorded as events")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	mate = w.by_id["A2"]
	e = w.by_id["B1"]
	a.good["WD10"] = true
	ready(w, a, e)
	hold_for(w, a, 0.5)
	check(not a.sidestep.is_empty() or not mate.sidestep.is_empty() or a.ticker.has("lane_goal"),
		"WD10 attempts the wider-lane recovery sooner")
	mate.pos = Vector2(7.0, 5.4)
	w._grid_build()
	check(not w.friend_in_line(a, e.pos, 0.3) and w.friend_in_line(a, e.pos, 0.5),
		"WD10's wider lane remains distinct from the ordinary instinct")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	mate = w.by_id["A2"]
	e = w.by_id["B1"]
	a.good["HD11"] = true
	a.holding = true
	ready(w, a, e)
	magazine = a.ws()["mag"]
	w._aim_update(a)
	mate.pos = Vector2(7.0, 7.0)
	w._grid_build()
	hold_for(w, a, 0.4)
	check(a.ws()["mag"] == magazine, "HD11 keeps its half-second lift delay after the lane clears")
	hold_for(w, a, 0.2)
	check(a.ws()["mag"] < magazine, "HD11 resumes fire after its lift delay")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	mate = w.by_id["A2"]
	e = w.by_id["B1"]
	mate.pos = Vector2(11.0, 5.0)
	w._grid_build()
	ready(w, a, e)
	a.judges = true
	magazine = a.ws()["mag"]
	w._aim_update(a)
	check(a.ws()["mag"] == magazine and w.friend_in_line(a, e.pos, 0.3, 4.0),
		"police lane protection checks beyond the target")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	e = w.by_id["B1"]
	a.active_bad["BH26"] = true
	a.holding = true
	ready(w, a, e)
	magazine = a.ws()["mag"]
	w._aim_update(a)
	check(a.ws()["mag"] < magazine, "intentional BH26 exception still allows firing through the lane")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	mate = w.by_id["A2"]
	e = w.by_id["B1"]
	w.nav = NoRouteNav.new()
	ready(w, a, e)
	magazine = a.ws()["mag"]
	hold_for(w, a, 2.2)
	check(a.ws()["mag"] == magazine and a.sidestep.is_empty() and mate.sidestep.is_empty() and not a.ticker.has("lane_goal"),
		"no-route fallback holds fire instead of moving or shooting unsafely")
	var no_route := false
	for ev in w.diagnostics:
		if ev["kind"] == "lane_recovery" and ev.get("method", "") == "no_safe_route":
			no_route = true
	check(no_route, "no safe lane route is explicitly diagnosed")
	var alt = w.by_id["B2"]
	alt.pos = Vector2(5.0, 9.0)
	a.rec[alt.id] = 1.0
	a.vis[alt.id] = {"los": true}
	a.tracked[alt.id] = {"lost_t": -1.0, "ready_t": INF}
	w._grid_build()
	hold_for(w, a, 1.7)
	check(a.ticker.get("lane_alt", "") == alt.id and w.brain._lane_alternative(a, true) == alt,
		"a visible clear alternative is preferred when local movement has no safe route")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	mate = w.by_id["A2"]
	e = w.by_id["B1"]
	mate.pos = Vector2(6.5, 5.5)
	w._grid_build()
	var safe_route := PackedVector2Array([a.pos, Vector2(5.0, 3.0)])
	var crossing_route := PackedVector2Array([a.pos, Vector2(8.0, 6.0)])
	check(w.brain._reposition_route_safe(a, e, safe_route) and not w.brain._reposition_route_safe(a, e, crossing_route),
		"reposition routes reject crossing a teammate rather than checking only the destination")
	mate.pos = Vector2(5.0, 4.0)
	w._grid_build()
	check(not w.brain._reposition_route_safe(a, e, safe_route),
		"a previously safe reposition is rejected when a teammate moves onto its remaining path")
	w.dispose()


func test_cover() -> void:
	var w = world()
	var a = w.by_id["A1"]
	var dest := Vector2(40.625, 1.125)
	var threat := Vector2(46.625, 7.125)
	a.pos = Vector2(40.801, 0.949)
	w.by_id["A2"].pos = Vector2(5.0, 5.0)
	w._grid_build()
	a.good["PF09"] = true
	a.ticker["cover_cache"] = {"p": dest, "t": w.t}
	check(a.pos.distance_to(dest) < 0.3 and not w.brain._hidden(a.pos, [threat], 0.82)
		and w.brain._hidden(dest, [threat], 0.82), "near-point fixture is exposed although its goal is concealed")
	var result: String = w.brain._seek_cover(a, [threat], "rule2")
	check(result == "moving" and a.moving, "being within 0.3 m of cover does not stop an exposed operator")
	for i in 90:
		w.t += World.DT
		w._grid_build()
		result = w.brain._seek_cover(a, [threat], "rule2")
		if result == "hidden":
			break
		w._move2(a)
	check(result == "hidden" and w.brain._hidden(a.pos, [threat], 0.82),
		"cover search completes only at a genuinely concealed position")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	var e = w.by_id["B1"]
	a.pos = Vector2(40.801, 0.949)
	e.pos = threat
	a.good["PF09"] = true
	a.active = "pistol"
	a.weapons["pistol"]["mag"] = 0
	a.weapons["pistol"]["spare"] = 2
	a.weapons["rifle"]["lost"] = true
	a.lkp[e.id] = {"p": e.pos, "t": w.t}
	a.rec[e.id] = 1.0
	a.vis[e.id] = {"los": true}
	w._grid_build()
	var fake := NoRouteNav.new()
	fake.candidates = [[a.pos.distance_squared_to(dest), {"p": dest, "gap": 1.2}]]
	w.nav = fake
	for i in 50:
		w.brain._rule2(a)
		if a.action.get("type", "") == "reload":
			break
		w.t += 0.1
	check(a.action.get("type", "") == "reload" and a.stance_goal == 2 and w.t < 15.0,
		"after bounded unreachable-cover attempts, a dry operator performs an explicit crouched emergency reload")
	var saw_no_path := false
	var exposed_reload := false
	for ev in w.diagnostics:
		if ev["kind"] == "cover_replan" and ev.get("reason", "") == "no_path":
			saw_no_path = true
		if ev["kind"] == "reload_started" and not ev.get("concealed", true):
			exposed_reload = true
	check(saw_no_path and event_count(w, "cover_fallback") == 1 and event_count(w, "reload_blocked") == 1 and exposed_reload,
		"unreachable cover, reload blocker, fallback, and exposed reload are attributed")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	e = w.by_id["B1"]
	a.pos = Vector2(40.801, 0.949)
	e.pos = threat
	a.good = {"PF09": true, "WD03": true, "WD02": true}
	a.active = "rifle"
	a.weapons["rifle"]["mag"] = 2
	a.weapons["rifle"]["spare"] = 2
	a.last_enemy_seen_t = -99.0
	a.lkp[e.id] = {"p": e.pos, "t": w.t}
	a.rec[e.id] = 1.0
	a.vis[e.id] = {"los": true}
	w._grid_build()
	w.nav = NoRouteNav.new()
	for i in 50:
		var occupied: bool = w.brain._maintain(a)
		if not occupied:
			break
		w.t += 0.1
	check(a.action.is_empty() and a.ws()["mag"] == 2 and float(a.ticker.get("reload_defer_until", -1.0)) > w.t,
		"an optional top-up is deferred rather than reloading exposed with ammunition still available")
	w.dispose()


func test_shield() -> void:
	var w = world()
	var a = w.by_id["A1"]
	var e = w.by_id["B1"]
	var mate = w.by_id["A2"]
	mate.pos = Vector2(2.0, 10.0)
	e.shield = true
	e.body_dir = (a.pos - e.pos).angle()
	e.good["WD09"] = true
	a.rec[e.id] = 1.0
	a.vis[e.id] = {"los": true}
	a.tracked[e.id] = {"lost_t": -1.0, "ready_t": INF}
	w._grid_build()
	ready(w, a, e)
	var u: Vector2 = (e.pos - a.pos).normalized()
	var chest: Array = e.zone_at(e.zone_centre("chest"))
	var before := int(w.stat.get("shield", 0))
	w._hit(e, chest, 0.0, u, a, 1.0, 0, e)
	w._hit(e, chest, 0.0, u, a, 1.0, 0, e)
	check(int(w.stat.get("shield", 0)) - before == 2 and int(a.ticker.get("shield_observed_count", 0)) == 2,
		"two aimed frontal rifle stops are observed by their shooter")
	var attributed := false
	for ev in w.diagnostics:
		if ev["kind"] == "shield_stop" and ev["id"] == a.id and ev.get("defender", "") == e.id \
				and ev.get("zone", "") == "chest" and ev.get("penetration", "") == "rifle" and ev.get("intended", false):
			attributed = true
	check(attributed, "shield-stop telemetry attributes shooter, bearer, zone, weapon class and intent")
	var responded: bool = w.brain._shield_response(a, e)
	var flank_goal: Vector2 = a.ticker.get("shield_goal", Vector2.INF)
	check(responded and flank_goal != Vector2.INF and not a.aim.get("fire", true)
		and absf(angle_difference(e.body_dir, (flank_goal - e.pos).angle())) > deg_to_rad(60.0),
		"repeated visible shield stops can produce a bounded flank without firing while moving")
	var alt = w.by_id["B2"]
	alt.pos = Vector2(5.0, 9.0)
	a.rec[alt.id] = 1.0
	a.vis[alt.id] = {"los": true}
	a.tracked[alt.id] = {"lost_t": -1.0, "ready_t": INF}
	a.ticker.erase("shield_goal")
	a.ticker["shield_next"] = -1.0
	w._grid_build()
	responded = w.brain._shield_response(a, e)
	check(responded and a.ticker.get("lane_alt", "") == alt.id, "a clear visible alternative is preferred to a shield flank")
	a.ticker.erase("shield_observed_target")
	a.ticker.erase("shield_observed_count")
	w._hit(e, chest, 0.0, u, a, 1.0, 1, e)
	check(not a.ticker.has("shield_observed_count"), "a stop through a wall does not create omniscient shield knowledge")
	a.active = "pistol"
	var pistol_before := int(w.stat.get("shield", 0))
	w._hit(e, chest, 0.0, u, a)
	check(int(w.stat.get("shield", 0)) == pistol_before + 1, "a frontal pistol round is still stopped by the shield")
	a.active = "rifle"
	var shield_before := int(w.stat.get("shield", 0))
	e.body_dir = 0.0
	e.plates = 0
	e.vest = false
	w._hit(e, chest, 0.0, u, a)
	check(int(w.stat.get("shield", 0)) == shield_before, "an attack from outside the shield's frontal arc is not stopped by it")
	e.body_dir = (a.pos - e.pos).angle()
	a.kit["primary"] = "battle_rifle"
	var heavy_before := int(w.stat.get("shield", 0))
	for i in 30:
		e.state = "ok"
		e.wounds = 0
		e.stress = 0.0
		e.habit_stress = 0.0
		w._hit(e, chest, 0.0, u, a)
	var heavy_stops: int = int(w.stat.get("shield", 0)) - heavy_before
	check(heavy_stops > 0 and heavy_stops < 30, "heavy rounds retain the existing probabilistic shield penetration")
	e.state = "ok"
	e.stance = 0
	e.shield = false
	e.helmet = false
	e.helmet_ballistic = false
	e.plates = 0
	var head: Array = e.zone_at(e.zone_centre("head"))
	w._hit(e, head, 0.0, u, a)
	check(e.state == "dead", "an ordinary unshielded, unhelmeted head hit retains normal damage behavior")
	w.dispose()


func test_diagnostic_bounds_and_interruptions() -> void:
	var w = world()
	var a = w.by_id["A1"]
	var e = w.by_id["B1"]
	ready(w, a, e)
	w._aim_update(a)
	check(a.ticker.has("lane_since"), "blocked lane episode starts while aiming")
	a.aim.clear()
	w._aim_update(a)
	check(not a.ticker.has("lane_since") and event_count(w, "lane_hold_end") == 1,
		"interrupted aim ends and clears its lane-hold episode")
	a.ticker["lane_goal"] = Vector2(6.0, 6.0)
	a.ticker["lane_goal_target"] = e.id
	a.ticker["lane_goal_until"] = w.t - 1.0
	check(not w.brain._follow_lane_replan(a, e) and not a.ticker.has("lane_goal"),
		"an expired lane replan is discarded when the encounter resumes")
	a.ticker["shield_goal"] = Vector2(6.0, 6.0)
	a.ticker["shield_goal_target"] = e.id
	a.ticker["shield_goal_until"] = w.t - 1.0
	e.shield = true
	check(not w.brain._shield_response(a, e) and not a.ticker.has("shield_goal"),
		"an expired shield flank is discarded when the encounter resumes")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	a.pos = Vector2(40.801, 0.949)
	a.good["PF09"] = true
	var threat := Vector2(46.625, 7.125)
	a.ticker["cover_cache"] = {"p": Vector2(40.625, 1.125), "t": w.t}
	w.brain._seek_cover(a, [threat], "rule2")
	a.ticker["cover_failures"] = 2
	w.t += 2.1
	w.brain._seek_cover(a, [threat], "rule2")
	check(event_count(w, "cover_search_start") == 2 and int(a.ticker.get("cover_failures", 0)) < 2,
		"an interrupted cover search starts a fresh bounded episode")
	w.diagnostics.clear()
	w.diagnostic_counts.clear()
	var rng_before: int = w.rng.state
	for i in World.DIAGNOSTIC_LIMIT + 3:
		w.diagnose("buffer_test", a, {"i": i})
	check(w.diagnostics.size() == World.DIAGNOSTIC_LIMIT and w.diagnostics_dropped == 3
		and event_count(w, "buffer_test") == World.DIAGNOSTIC_LIMIT + 3 and w.rng.state == rng_before,
		"diagnostic buffer is bounded while totals and overflow remain accurate without drawing RNG")
	w.diagnostics_enabled = false
	w.diagnose("disabled_test", a)
	check(event_count(w, "disabled_test") == 0 and w.diagnostics_dropped == 3,
		"disabled diagnostics neither record nor count events")
	var lv = w.level
	var nav = w.nav
	w._base(lv, nav, 94131)
	check(w.diagnostics.is_empty() and w.diagnostic_counts.is_empty() and w.diagnostics_dropped == 0,
		"a new world setup clears the diagnostic buffer, totals and overflow")
	w.dispose()


func test_stress_and_kits() -> void:
	Equipment.armory = {}
	var lv = Maps.get_level(0)
	var legacy := Teams.team(lv, 0, {"n": 1, "ech": "sof"})
	var preset := Teams.team_with_preset_kit(lv, 0, {"n": 1, "ech": "sof"})
	check(not legacy[0].has("kit") and preset[0]["kit"]["primary"] == "sbr"
		and legacy[0]["bad"] == preset[0]["bad"], "preset-kit helper is opt-in and preserves legacy habit defaults")
	var w = world()
	var a = w.by_id["A1"]
	a.good["WD09"] = true
	a.bad = {"BH01": true}
	var counts := []
	for resist in [0.0, 0.25, 0.5, 0.65, 0.8, 0.95]:
		a.ech["resist"] = resist
		a.stress = 0.0
		a.habit_stress = 0.0
		a.active_bad.clear()
		w._update_bad(a, true)
		var n := 0
		while not a.hb("BH01") and n < 30:
			w.add_stress(a, 0.15, "test")
			w._update_bad(a, false)
			n += 1
		counts.append(n)
	check(counts[0] < counts[2] and counts[2] < counts[4] and counts[4] < counts[5] and counts[5] < 30,
		"sustained stress reaches BH01 at all tested resistances, more slowly for stronger resistance")
	check(is_equal_approx(a.stress, 1.0) and a.hb("BH01") and event_count(w, "habit_transition") > 0,
		"activation is recorded as a transition even after raw stress saturates")
	a.ech["resist"] = 0.8
	a.ech["stress0"] = 0.3
	a.stress = 0.9
	a.habit_stress = 0.9
	a.last_stress_t = -99.0
	a.last_enemy_seen_t = -99.0
	for i in 300:
		w.t += World.DT
		w._passive(a)
	check(is_equal_approx(a.stress, 0.3) and is_equal_approx(a.habit_stress, 0.12),
		"quiet rally decay respects separate raw and resistance-adjusted baseline floors")
	a.stress = 0.0
	a.habit_stress = 0.0
	a.ticker["gassed_until"] = w.t + 6.0
	w.clouds = [{"room": "", "p": a.pos, "r": 0.4, "until": w.t + 10.0, "by": "B1"}]
	w._gas_tick()
	check(is_equal_approx(a.stress, 0.03) and is_equal_approx(a.habit_stress, 0.012),
		"direct gas stress updates the separate accumulator without changing raw input")
	a.civ = true
	a.cstate = "unaware"
	a.stress = 0.0
	a.habit_stress = 0.0
	w.civ_brain.alarm(a, Vector2(9.0, 5.0), "gunfire")
	check(is_equal_approx(a.stress, 0.12) and is_equal_approx(a.habit_stress, 0.048),
		"civilian alarm stress is retained for a concealed attacker who later reveals")
	w.dispose()

	w = world()
	a = w.by_id["A1"]
	var c := Vector2(5.0, 5.0)
	var direction := Vector2.RIGHT
	var side := Vector2.DOWN
	a.good["PF04"] = true
	var with_pf: Array = w.brain._entry_target(a, 0, c, direction, c + direction * 0.7, side, 3.0, 3.0, 3.0)
	a.good.erase("PF04")
	var without_pf: Array = w.brain._entry_target(a, 0, c, direction, c + direction * 0.7, side, 3.0, 3.0, 3.0)
	check(with_pf[0] != without_pf[0], "PF04 changes the entry target when an entry opportunity occurs")
	w.dispose()

	# Exercise the actual entry-phase branch, not only its target calculation. An
	# unreachable instrumentation block must never turn a planned entry into a
	# false arrival at the stack.
	w = world(0)
	a = w.by_id["A1"]
	a.good["PF04"] = true
	var door_id: String = w.level.doors.keys()[0]
	var door: Dictionary = w.level.doors[door_id]
	var into: String = door["b"]
	var inward: Vector2 = w.level.inward(door_id, into)
	a.pos = w.nav.snap(door["c"] - inward * 1.5)
	a.room = w.level.room_at(a.pos)
	var entry_target: Vector2 = w.nav.snap(door["c"] + inward * 1.5)
	var record := {"order": 0, "enters": true, "paused": false, "arrived": false,
		"target": entry_target, "diag_pf04_plan_active": true}
	var entry_el := {"task": {"door": door_id, "into": into}, "entry": {a.id: record},
		"ctl": {}, "phase": "entry"}
	w.brain._task_assault(a, w.teams[0], entry_el)
	check(a.moving and a.goal.distance_to(entry_target) < 0.01 and not record["arrived"],
		"entry phase issues movement toward the PF04 target rather than falsely declaring arrival")
	check(event_count(w, "pf04_entry_move") == 1, "PF04 execution is recorded when entry movement starts")
	w.brain._task_assault(a, w.teams[0], entry_el)
	check(event_count(w, "pf04_entry_move") == 1, "an ongoing entry emits only one execution event")
	a.pos = entry_target
	w.brain._task_assault(a, w.teams[0], entry_el)
	check(record["arrived"] and not a.moving, "entry arrival is marked only after reaching the target")
	a.good["GD02"] = true
	w.by_id["A2"].good["GD02"] = true
	var el: Dictionary = w.teams[0]["elements"][a.el]
	w.brain._sectors(el, w.team_ops[0])
	a.ticker["scan_next"] = 0.0
	w.brain._scan(a, w.teams[0])
	check(event_count(w, "gd02_sector_plan") > 0 and event_count(w, "gd02_scan") > 0,
		"GD02 sector assignment and actual scan opportunities are recorded")
	w.dispose()


func _init() -> void:
	test_weapons_tight()
	test_lane()
	test_cover()
	test_shield()
	test_diagnostic_bounds_and_interruptions()
	test_stress_and_kits()
	print("test range regressions: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)
