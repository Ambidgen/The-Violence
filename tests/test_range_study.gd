extends SceneTree
## Reproducible, non-campaign test-range study. One JSONL record per match.
## Uses the actual UI preset kit, not the legacy fallback in tests/teams.gd.
##   godot --headless --path . -s res://tests/test_range_study.gd -- \
##     --group=matrix --maps=0,3,4 --n=2 --out=/tmp/range-matrix.jsonl
##   ... -- --group=habits --maps=0,3 --n=2 --shard=0/2 --out=/tmp/habits0.jsonl
##   ... -- --group=habits --cases=baseline,good_off:PF01:A --offset=8 --n=8 --out=/tmp/followup.jsonl
## Groups: matrix, size, mixed, habits, equipment. Shards partition cases, not games;
## merge all shard JSONL files before comparing to the baseline.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

const LEVELS := ["untrained", "militia", "patrol", "regular", "police", "sof"]
const GEAR_VARIANTS := ["no_plates", "vest", "no_helmet", "no_flashbang", "no_medkit", "no_gear", "carbine", "smg", "shotgun", "battle_rifle", "irons", "magnified", "shield_point"]
var navs := {}


func _parse_args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = String(arg).trim_prefix("--").split("=", true, 1)
		result[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return result


func _case(group: String, id: String, a: Array, b: Array, change := {}) -> Dictionary:
	return {"group": group, "case": id, "a": a, "b": b, "change": change}


func _side(echelon: String, count: int) -> Array:
	var result: Array = []
	for i in count:
		result.append(echelon)
	return result


func _cases(group: String) -> Array:
	var out: Array = []
	if group == "matrix":
		for a in LEVELS:
			for b in LEVELS:
				out.append(_case(group, "%s_vs_%s" % [a, b], _side(a, 5), _side(b, 5)))
	elif group == "size":
		# Reversed unequal pairings make side and numbers explicit.
		for sz in [[1, 1], [2, 2], [3, 3], [5, 5], [8, 8], [10, 10], [2, 5], [5, 2], [3, 5], [5, 3], [5, 8], [8, 5], [5, 10], [10, 5]]:
			out.append(_case(group, "%dv%d" % [sz[0], sz[1]], _side("regular", sz[0]), _side("regular", sz[1])))
	elif group == "mixed":
		# Ordered slots affect spawns/assignment; AI selects leaders and entry order dynamically.
		for mix in [["sof", "militia", "militia", "militia", "militia"],
			["militia", "sof", "sof", "sof", "sof"],
			["sof", "sof", "militia", "militia", "militia"],
			["police", "police", "patrol", "patrol", "patrol"],
			["regular", "regular", "regular", "regular", "regular"]]:
			var name := "+".join(mix)
			out.append(_case(group, "A_" + name, mix, _side("regular", 5)))
			out.append(_case(group, "B_" + name, _side("regular", 5), mix))
	elif group == "habits":
		var sof := _side("sof", 3)
		out.append(_case(group, "baseline", sof, sof, {"mode": "baseline"}))
		for side in ["A", "B"]:
			out.append(_case(group, "no_good:" + side, sof, sof, {"side": side, "mode": "no_good"}))
			out.append(_case(group, "all_bad:" + side, sof, sof, {"side": side, "mode": "all_bad"}))
			for hid in Habits.good_ids():
				# HD habits are explicitly suspended while not holding; test them on B.
				if side == "A" and Habits.is_hold(hid):
					continue
				out.append(_case(group, "good_off:%s:%s" % [hid, side], sof, sof, {"side": side, "mode": "good_off", "habit": hid}))
			for hid in Habits.bad_ids():
				if side == "A" and Habits.is_hold(hid):
					continue
				out.append(_case(group, "bad_on:%s:%s" % [hid, side], sof, sof, {"side": side, "mode": "bad_on", "habit": hid}))
	elif group == "equipment":
		var sof := _side("sof", 3)
		out.append(_case(group, "baseline", sof, sof, {"mode": "baseline"}))
		for side in ["A", "B"]:
			for variant in GEAR_VARIANTS:
				out.append(_case(group, "kit:%s:%s" % [variant, side], sof, sof,
					{"side": side, "mode": "kit", "variant": variant}))
	return out


func _kit_for(echelon: String, change: Dictionary, side: String, slot: int) -> Dictionary:
	var kit: Dictionary = Equipment.preset(echelon)
	if change.get("mode", "") == "kit" and change.get("side", "") == side:
		match String(change["variant"]):
			"no_plates":
				kit["armour"] = "none"
				kit["plates"] = 0
			"vest":
				kit["armour"] = "vest"
				kit["plates"] = 0
			"no_helmet": kit["head"] = "none"
			"no_flashbang": kit["gear"].erase("flashbang")
			"no_medkit": kit["gear"].erase("medkit")
			"no_gear": kit["gear"] = {}
			"carbine", "smg", "shotgun", "battle_rifle": kit["primary"] = change["variant"]
			"irons", "magnified": kit["optic"] = change["variant"]
			"shield_point":
				if slot == 0:
					kit["gear"]["shield"] = 1
	# Matches the UI's equipment validation (including removing the primary for a shield).
	return Equipment.validate(kit, Equipment.who_of_echelon(echelon))


func _cfgs(lv, c: Dictionary) -> Array:
	var cfgs: Array = []
	var all_good: bool = c["group"] in ["habits", "equipment"]
	var change: Dictionary = c["change"]
	for team in 2:
		var side := "A" if team == 0 else "B"
		var lineup: Array = c["a"] if team == 0 else c["b"]
		for slot in lineup.size():
			var echelon: String = lineup[slot]
			var good := {}
			for g in (Habits.good_ids() if all_good else Habits.preset_good(echelon)):
				good[g] = true
			var bad := {}
			if not all_good:
				for b in Habits.stress_bad_ids():
					bad[b] = true
			if change.get("side", "") == side:
				match String(change.get("mode", "")):
					"good_off": good.erase(change["habit"])
					"no_good": good.clear()
					"bad_on": bad[change["habit"]] = true
					"all_bad":
						for b in Habits.bad_ids():
							bad[b] = true
			var id := "%s%d" % [side, slot + 1]
			var kit := _kit_for(echelon, change, side, slot)
			cfgs.append({"id": id, "team": team, "slot": slot, "echelon": echelon,
				"good": good, "bad": bad, "traits": {}, "kit": kit, "plates": kit["plates"],
				"exp": Habits.PRESET_EXP[echelon], "pos": lv.spawns[id]["p"], "face": lv.spawns[id]["face"],
				"alert": 1, "enabled": true})
	return cfgs


func _nav(mi: int, lv):
	if not navs.has(mi):
		var n = Nav.new()
		n.build(lv)
		navs[mi] = n
	return navs[mi]


func _diagnostic_summary(w, bad_id: String, side_i: int) -> Dictionary:
	var by_team := [{}, {}]
	var habit_ops := [{}, {}]
	var selected_bad := {}
	for ev in w.diagnostics:
		var team: int = int(ev["team"])
		if team < 0 or team > 1:
			continue
		var kind: String = ev["kind"]
		var bucket: Dictionary = by_team[team]
		bucket[kind] = int(bucket.get(kind, 0)) + 1
		if kind == "habit_transition" and ev.get("active", false):
			var hid: String = ev["habit"]
			if not habit_ops[team].has(hid):
				habit_ops[team][hid] = {}
			habit_ops[team][hid][ev["id"]] = true
			if team == side_i and hid == bad_id:
				selected_bad[ev["id"]] = true
		elif kind == "lane_recovery":
			var key: String = "lane_" + String(ev["method"])
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "cover_replan":
			var key: String = "cover_" + String(ev["reason"])
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "pf04_entry_plan":
			var key := "pf04_plan_active" if ev["active"] else "pf04_plan_inactive"
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "pf04_entry_move":
			var key := "pf04_move_planned_active" if ev["planned_active"] else "pf04_move_planned_inactive"
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "gd02_sector_plan":
			var key := "gd02_assigned" if ev["assigned"] else "gd02_unassigned"
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "gd02_scan":
			bucket["gd02_scan_with_sector"] = int(bucket.get("gd02_scan_with_sector", 0)) + int(ev["has_sector"])
			bucket["gd02_scan_excluded_candidates"] = int(bucket.get("gd02_scan_excluded_candidates", 0)) + int(ev["excluded_by_sector"])
		elif kind == "reload_started" and not ev["concealed"]:
			bucket["reload_exposed"] = int(bucket.get("reload_exposed", 0)) + 1
		elif kind == "shield_stop":
			var key: String = "shield_stop_" + String(ev["penetration"])
			bucket[key] = int(bucket.get(key, 0)) + 1
		elif kind == "shield_response":
			var key: String = "shield_response_" + String(ev["method"])
			bucket[key] = int(bucket.get(key, 0)) + 1
	for team in 2:
		for hid in habit_ops[team].keys():
			habit_ops[team][hid] = habit_ops[team][hid].size()
	return {"by_team": by_team, "habit_operators": habit_ops, "selected_bad_operators": selected_bad.size(),
		"total_events": w.diagnostic_counts.duplicate(), "dropped": w.diagnostics_dropped}


func _run(c: Dictionary, mi: int, seed_val: int) -> Dictionary:
	var lv = Maps.get_level(mi)
	var cfgs := _cfgs(lv, c)
	var w = World.new()
	w.keep_events = false
	# Decision events are separate from UI events and do not consume RNG. Enable
	# before setup so initial trait activations are included as transitions.
	w.diagnostics_enabled = true
	w.log_kinds = {"bad": true}
	w.setup(lv, _nav(mi, lv), cfgs, ["assault", "hold"], seed_val, [1, 1], {})
	if w.ops.size() != cfgs.size():
		push_error("operator count does not match the requested lineup")
		return {}
	# Initial kit counts let us distinguish carrying an item from actually using it.
	var initial := {}
	for o in w.ops:
		initial[o.id] = o.gear.duplicate()
	var change: Dictionary = c["change"]
	var bad_id: String = change.get("habit", "") if change.get("mode", "") == "bad_on" else ""
	var side_i := 0 if change.get("side", "A") == "A" else 1
	var max_habit_stress := [0.0, 0.0]
	var max_raw_effective := [0.0, 0.0]
	var max_stress := [0.0, 0.0]
	var ticks := 0
	while not w.over:
		w.step()
		ticks += 1
		# At half-second intervals sample the highest stress on each side. Habit
		# activations are counted from transitions instead of intermittent samples.
		if ticks % 15 == 0:
			for o in w.ops:
				max_stress[o.team] = maxf(max_stress[o.team], o.stress)
				max_habit_stress[o.team] = maxf(max_habit_stress[o.team], o.habit_stress)
				max_raw_effective[o.team] = maxf(max_raw_effective[o.team], o.stress * (1.0 - o.ech["resist"]))
		# Defensive sanity guard; the game's normal per-map time limit remains in force.
		if ticks > int((w.time_limit + 1.0) / World.DT):
			push_error("match exceeded the normal time limit")
			w.dispose()
			return {}
	if w.winner < 0 or w.winner > 2:
		push_error("invalid winner %d" % w.winner)
		w.dispose()
		return {}
	var down := [0, 0]
	var dead := [0, 0]
	var shots := [0, 0]
	var hits := [0, 0]
	var plates_used := [0, 0]
	var helmets_spent := [0, 0]
	var used := [{}, {}]
	for o in w.ops:
		if o.state != "ok":
			down[o.team] += 1
		if o.state == "dead":
			dead[o.team] += 1
		shots[o.team] += o.shots
		hits[o.team] += o.hits
		plates_used[o.team] += maxi(0, o.plates_max - o.plates)
		if o.kit["head"] == "sof_helmet" and not o.helmet:
			helmets_spent[o.team] += 1
		for item in initial[o.id]:
			var spent := maxi(0, int(initial[o.id][item]) - int(o.gear.get(item, 0)))
			if spent > 0:
				used[o.team][item] = int(used[o.team].get(item, 0)) + spent
	var telemetry := _diagnostic_summary(w, bad_id, side_i)
	var result := {"group": c["group"], "case": c["case"], "map": mi, "map_name": lv.map_name,
		"seed": seed_val, "a": c["a"], "b": c["b"], "change": change,
		"winner": w.winner, "timeout": w.t + World.DT >= w.time_limit, "seconds": snappedf(w.t, 0.001),
		"a_down": down[0], "b_down": down[1], "a_dead": dead[0], "b_dead": dead[1],
		"a_shots": shots[0], "b_shots": shots[1], "a_hits": hits[0], "b_hits": hits[1],
		"a_plates_used": plates_used[0], "b_plates_used": plates_used[1],
		"a_helmets_spent": helmets_spent[0], "b_helmets_spent": helmets_spent[1],
		"stress_model": "resistance_adjusted_event_accumulator_v1", "stress_sample_seconds": 0.5,
		"a_max_stress": max_stress[0], "b_max_stress": max_stress[1],
		"a_max_habit_stress": max_habit_stress[0], "b_max_habit_stress": max_habit_stress[1],
		"a_max_raw_effective_stress": max_raw_effective[0], "b_max_raw_effective_stress": max_raw_effective[1],
		"shield_stops": int(w.stat.get("shield", 0)),
		"friendly_hits": w.stat["friendly"], "stray": w.stat["stray"],
		"a_gear_used": used[0], "b_gear_used": used[1],
		"bad_active_operators": telemetry["selected_bad_operators"], "decision_telemetry": telemetry}
	w.dispose()
	return result


func _init() -> void:
	# The test range has the complete equipment database, not a campaign armoury.
	Equipment.armory = {}
	var args := _parse_args()
	var group: String = args.get("group", "matrix")
	var cases := _cases(group)
	var n := int(args.get("n", "2"))
	var offset := int(args.get("offset", "0"))
	var maps: PackedStringArray = String(args.get("maps", "0,3,4")).split(",", false)
	var shard: PackedStringArray = String(args.get("shard", "0/1")).split("/")
	var only: PackedStringArray = String(args.get("cases", "")).split(",", false)
	var out_path: String = args.get("out", "user://test_range_results.jsonl")
	if cases.is_empty() or n < 1 or offset < 0 or maps.is_empty() or shard.size() != 2:
		printerr("Invalid study arguments")
		quit(2)
		return
	var shard_i := int(shard[0])
	var shards := int(shard[1])
	if shards < 1 or shard_i < 0 or shard_i >= shards:
		printerr("Invalid shard")
		quit(2)
		return
	for map_text in maps:
		if not map_text.is_valid_int() or int(map_text) < 0 or int(map_text) >= Maps.count():
			printerr("Invalid map: " + map_text)
			quit(2)
			return
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		printerr("Cannot open output: " + out_path)
		quit(2)
		return
	var games := 0
	var completed := 0
	var t0 := Time.get_ticks_msec()
	for i in cases.size():
		var c: Dictionary = cases[i]
		if i % shards != shard_i or (not only.is_empty() and not only.has(c["case"])):
			continue
		var wins := [0, 0, 0]
		for map_text in maps:
			var mi := int(map_text)
			for rep in range(offset, offset + n):
				# Common seeds for paired comparisons; matches diverge naturally after setup.
				var seed_val := 710001 + 1000 * mi + 7919 * rep
				var row := _run(c, mi, seed_val)
				if row.is_empty():
					f.close()
					quit(1)
					return
				f.store_line(JSON.stringify(row))
				f.flush()
				wins[int(row["winner"])] += 1
				games += 1
		completed += 1
		print("%s %s: A/B/draw %d/%d/%d (%d games); %d cases, %.1f s elapsed" % [
			group, c["case"], wins[0], wins[1], wins[2], maps.size() * n, completed, (Time.get_ticks_msec() - t0) / 1000.0])
	f.close()
	if completed == 0:
		printerr("No study cases selected")
		quit(2)
		return
	print("DONE %s: %d cases, %d matches -> %s" % [group, completed, games, out_path])
	quit(0)
