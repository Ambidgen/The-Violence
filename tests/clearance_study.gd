extends SceneTree
## One SOF assault squad versus one equal regular-infantry hold squad, plus an
## unopposed control. Writes one JSONL record per case and condition.
##
##   godot --headless --path . -s res://tests/clearance_study.gd -- \
##     --maps=0,1,2,3,4,5,6,7,8,9,10,11 --sizes=1,2,3,4,5 --n=3 \
##     --seed=811001 --max-room-seconds=1200 --out=res://build/clearance.jsonl
## Default doors are open, normal fight limits apply. After a fight won with no
## remaining defending fighters, survivors continue searching with only the world's
## end check disabled. A loss, draw, or win by ammunition exhaustion is not a room
## clear. The movement-only control disables the end check from the start. Neither
## continuation is presented as a normal in-game match outcome.

const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Model = preload("res://tests/clearance_model.gd")


func _args() -> Dictionary:
	var out := {"maps": "0,1,2,3,4,5,6,7,8,9,10,11", "sizes": "1,2,3,4,5", "n": "3",
		"seed": "811001", "max-room-seconds": "1200", "out": "res://build/clearance.jsonl"}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = String(arg).trim_prefix("--").split("=", true, 1)
		if kv.size() != 2 or not out.has(kv[0]):
			return {}
		out[kv[0]] = kv[1]
	return out


func _numbers(text: String, lo: int, hi: int) -> Array:
	var out: Array = []
	for token in text.split(",", false):
		if not token.is_valid_int():
			return []
		var v := int(token)
		if v < lo or v > hi or v in out:
			return []
		out.append(v)
	return out


func _fighting(w, side: int) -> int:
	var result := 0
	for o in w.teams[side]["members"]:
		if o.fighting():
			result += 1
	return result


func _rooms_complete(tm: Dictionary, required: Array) -> bool:
	for name in required:
		if not tm["cleared"].has(name):
			return false
	return true


func _missing(tm: Dictionary, required: Array) -> Array:
	var result: Array = []
	for name in required:
		if not tm["cleared"].has(name):
			result.append(name)
	return result


## A normal entry/clear needs evidence that a member actually reached the room;
## PF10 checks intentionally inspect smaller rooms from the near side of the door.
func _note_room_occupancy(w, entered: Dictionary) -> void:
	for el in w.teams[0]["elements"]:
		var room: String = el.get("task", {}).get("into", "")
		if room == "" or el["phase"] == "check":
			continue
		for o in w.teams[0]["members"]:
			if o.el == el["i"] and o.fighting() and o.room == room:
				entered[room] = true


func _movement_snapshot(stats: Dictionary) -> Dictionary:
	var metres := 0.0
	var moving := 0.0
	var stationary := 0.0
	var blocked := 0.0
	var recoveries := 0
	var per_op: Array = []
	var ids: Array = stats.keys()
	ids.sort()
	for id in ids:
		var s: Dictionary = stats[id]
		metres += s["metres"]
		moving += s["moving_s"]
		stationary += s["stationary_s"]
		blocked += s["requested_no_motion_s"]
		recoveries += s["ghost_recoveries"]
		per_op.append({"id": id, "metres": snappedf(s["metres"], 0.001),
			"moving_s": snappedf(s["moving_s"], 0.001), "stationary_s": snappedf(s["stationary_s"], 0.001),
			"requested_no_motion_s": snappedf(s["requested_no_motion_s"], 0.001),
			"ghost_recoveries": s["ghost_recoveries"], "phases_s": s["phases_s"].duplicate()})
	return {"total_metres": snappedf(metres, 0.001), "moving_operator_s": snappedf(moving, 0.001),
		"stationary_operator_s": snappedf(stationary, 0.001), "ghost_recoveries": recoveries,
		"requested_no_motion_operator_s": snappedf(blocked, 0.001), "operators": per_op}


func _run(lv, nav, cfgs: Array, size: int, seed_v: int, required: Array, limit: float, contested: bool) -> Dictionary:
	var w = World.new()
	w.keep_events = false
	var use_cfgs: Array = cfgs if contested else cfgs.filter(func(c): return int(c["team"]) == 0)
	# Defenders hold rather than automatically changing to hunt after 60 quiet seconds.
	w.setup(lv, nav, use_cfgs, ["assault", "hold"], seed_v, [1, 1], {"b_stay": true})
	if w.teams[0]["elements"].size() != 1 or w.teams[0]["members"].size() != size \
		or (contested and (w.teams[1]["elements"].size() != 1 or w.teams[1]["members"].size() != size)):
		w.dispose()
		return {"error": "scenario did not form one equal squad per side"}
	if not contested:
		w.endless = true
	var stats := {}
	for o in w.teams[0]["members"]:
		stats[o.id] = {"metres": 0.0, "moving_s": 0.0, "stationary_s": 0.0,
			"requested_no_motion_s": 0.0, "ghost_recoveries": 0, "phases_s": {}}
	var events: Array = []
	var seen := {}
	var entered := {}
	var room_s = null
	var room_movement = null
	var fight = null
	var continued := false
	var stop_reason := "room_limit"
	# A tick guard is independent of floating point accumulation.
	for step in int(ceil(limit / World.DT)):
		var before := {}
		var phases := {}
		_note_room_occupancy(w, entered)
		for el in w.teams[0]["elements"]:
			var room: String = el.get("task", {}).get("into", "")
			if room != "":
				phases[room] = el["phase"]
		for o in w.teams[0]["members"]:
			before[o.id] = {"p": o.pos, "fighting": o.fighting(), "ghost_until": o.ticker.get("ghost_until", -1.0)}
		w.step()
		_note_room_occupancy(w, entered)
		for o in w.teams[0]["members"]:
			var prior: Dictionary = before[o.id]
			var s: Dictionary = stats[o.id]
			if not prior["fighting"]:
				continue
			var d: float = o.pos.distance_to(prior["p"])
			s["metres"] += d
			if float(o.ticker.get("ghost_until", -1.0)) > float(prior["ghost_until"]) + 0.01:
				s["ghost_recoveries"] += 1
			if d > 0.001:
				s["moving_s"] += World.DT
			else:
				s["stationary_s"] += World.DT
				if o.moving and not w.blocks_move(o):
					s["requested_no_motion_s"] += World.DT
			var el: Dictionary = w.teams[0]["elements"][o.el]
			var phase: String = String(el["mode"]) + "/" + String(el.get("phase", ""))
			s["phases_s"][phase] = float(s["phases_s"].get(phase, 0.0)) + World.DT
		for room in w.teams[0]["cleared"]:
			if not seen.has(room):
				seen[room] = true
				var phase: String = phases.get(room, "unknown")
				events.append({"room": room, "seconds": snappedf(w.t, 0.001),
					"method": "checked" if phase == "check" else ("clear" if phase in ["clear", "sweep"] else "unknown"),
					"entered_by_assigned_element": entered.has(room)})
		if room_s == null and _rooms_complete(w.teams[0], required):
			room_s = snappedf(w.t, 0.001)
			room_movement = _movement_snapshot(stats)
		if contested and fight == null and w.over:
			var a := _fighting(w, 0)
			var b := _fighting(w, 1)
			fight = {"seconds": snappedf(w.t, 0.001), "winner": w.winner, "timeout": w.t >= w.time_limit,
				"a_fighting": a, "b_fighting": b, "shots": w.stat["shots"], "hits": w.stat["hits"],
				"cleared_rooms": w.teams[0]["cleared"].keys(), "skipped_rooms": w.teams[0]["skipped"].keys(),
				"movement": _movement_snapshot(stats)}
			if w.winner == 0 and b == 0 and a > 0 and room_s == null and w.teams[0]["skipped"].is_empty():
				# Continue the same survivors and state; only the automatic match end is disabled.
				w.over = false
				w.endless = true
				continued = true
			else:
				stop_reason = "fight_end"
				break
		if (not contested or continued) and room_s != null:
			stop_reason = "rooms_complete"
			break
		if (not contested or continued) and not w.teams[0]["skipped"].is_empty():
			stop_reason = "room_skipped"
			break
		if (not contested or continued) and _fighting(w, 0) == 0:
			stop_reason = "no_attackers"
			break
	var skipped: Array = w.teams[0]["skipped"].keys()
	skipped.sort()
	var result := {"condition": "fight" if contested else "unopposed", "seed": seed_v, "room_seconds": room_s,
		"room_movement": room_movement, "fight": fight, "continued_after_win": continued,
		"observation_seconds": snappedf(w.t, 0.001), "stop_reason": stop_reason,
		"missing_rooms": _missing(w.teams[0], required), "skipped_rooms": skipped,
		"room_events": events, "movement_at_stop": _movement_snapshot(stats)}
	w.dispose()
	return result


func _init() -> void:
	var args := _args()
	if args.is_empty():
		printerr("Use --maps=0,...,11 --sizes=1,...,5 --n=N --seed=N --max-room-seconds=N --out=PATH")
		quit(2)
		return
	var maps := _numbers(String(args["maps"]), 0, Maps.count() - 1)
	var sizes := _numbers(String(args["sizes"]), 1, 5)
	var repetitions := int(args["n"])
	var first_seed := int(args["seed"])
	var limit := float(args["max-room-seconds"])
	if maps.is_empty() or sizes.is_empty() or not String(args["n"]).is_valid_int() or repetitions < 1 \
		or not String(args["seed"]).is_valid_int() or first_seed < 0 or limit < 900.0:
		printerr("Invalid maps, sizes, n, seed, or room limit (room limit must be >= 900 s)")
		quit(2)
		return
	var outfile := String(args["out"])
	var parent := ProjectSettings.globalize_path(outfile).get_base_dir()
	if DirAccess.make_dir_recursive_absolute(parent) != OK:
		printerr("Cannot create output directory: " + parent)
		quit(2)
		return
	var f := FileAccess.open(outfile, FileAccess.WRITE)
	if f == null:
		printerr("Cannot write " + outfile)
		quit(2)
		return
	Equipment.armory = {}
	var errors := 0
	var count := 0
	for mi in maps:
		var lv = Maps.get_level(mi)
		var nav = Nav.new()
		nav.build(lv)
		var model = Model.new(lv, nav)
		if not model.missing_rooms.is_empty():
			printerr("Map %d has no sampled reachable floor in %s" % [mi, model.missing_rooms])
			errors += 1
			continue
		var required: Array = model.rooms.map(func(r): return r["name"])
		for size in sizes:
			var cfgs: Array = Teams.team_with_preset_kit(lv, 0, {"n": size, "ech": "sof"}) \
				+ Teams.team_with_preset_kit(lv, 1, {"n": size, "ech": "regular"})
			var starts: Array = Model.attackers(cfgs)
			var room_expected: Dictionary = model.estimate(starts, model.rooms)
			var posts_expected: Dictionary = model.estimate(starts, Model.defender_posts(cfgs))
			if not room_expected.get("ok", false) or not posts_expected.get("ok", false):
				printerr("Map %d %dv%d route estimate failed: %s / %s" % [mi, size, size, room_expected, posts_expected])
				errors += 1
				continue
			for rep in repetitions:
				var seed_v := first_seed + 1000 * int(mi) + 7919 * rep
				for contested in [true, false]:
					var r := _run(lv, nav, cfgs, size, seed_v, required, limit, contested)
					if r.has("error"):
						printerr("Map %d %dv%d seed %d: %s" % [mi, size, size, seed_v, r["error"]])
						errors += 1
						continue
					r["schema"] = 2
					r["map"] = int(mi)
					r["map_id"] = lv.id
					r["map_name"] = lv.map_name
					r["size"] = int(size)
					r["room_count"] = required.size()
					r["rooms"] = required
					r["fight_limit_s"] = lv.time_limit
					r["room_limit_s"] = limit
					r["expected_rooms"] = room_expected
					r["expected_defender_posts"] = posts_expected
					f.store_line(JSON.stringify(r))
					f.flush()
					count += 1
					print("map %02d %dv%d seed %d %-9s rooms=%s fight=%s stop=%s" % [mi, size, size, seed_v,
						r["condition"], str(r["room_seconds"]), str(r["fight"]["winner"]) if r["fight"] != null else "--", r["stop_reason"]])
	f.close()
	print("clearance study: %d records, %d errors; %s" % [count, errors, outfile])
	quit(1 if errors > 0 or count == 0 else 0)
