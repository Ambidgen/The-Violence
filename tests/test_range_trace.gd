extends SceneTree
## Trace a test-range preset match, including surviving operators and squad tasks.
## Uses the actual UI preset kit, unlike the legacy default in tests/teams.gd.
##   godot --headless --path . -s res://tests/test_range_trace.gd -- \
##     --map=0 --a=patrol --b=regular --na=5 --nb=5 --seed=717920 --interval=60
const Teams = preload("res://tests/teams.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = String(arg).trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var mi := int(args.get("map", "0"))
	var lv = Maps.get_level(mi)
	var nav = Nav.new()
	nav.build(lv)
	var a: String = args.get("a", "patrol")
	var b: String = args.get("b", "regular")
	Equipment.armory = {}
	var cfgs: Array = Teams.team_with_preset_kit(lv, 0, {"n": int(args.get("na", "5")), "ech": a})
	cfgs += Teams.team_with_preset_kit(lv, 1, {"n": int(args.get("nb", "5")), "ech": b})
	var w = World.new()
	w.keep_events = false
	w.log_kinds = {"bad": true}
	w.setup(lv, nav, cfgs, ["assault", "hold"], int(args.get("seed", "717920")), [1, 1], {})
	var interval := maxf(1.0, float(args.get("interval", "60")))
	var next := interval
	while not w.over:
		w.step()
		if w.t >= next or w.over:
			print("=== %.1f s; shots %d, hits %d; over %s winner %d ===" % [w.t, w.stat["shots"], w.stat["hits"], str(w.over), w.winner])
			for o in w.ops:
				if not o.alive():
					continue
				print("  %s %s at %s room=%s shots=%d pos_goal=%s dbg=%s mind=%s last_seen=%.1f path=%d/%d" % [
					o.id, o.echelon, str(o.pos.snapped(Vector2(0.1, 0.1))), o.room, o.shots, str(o.goal), o.dbg,
					o.mind, o.last_enemy_seen_t, o.path_i, o.path.size()])
				if String(o.dbg).begins_with("RULE 2"):
					var threats: Array = w.brain._threats(o)
					var goal_hidden: bool = o.goal != Vector2.INF and w.brain._hidden(o.goal, threats, 0.82)
					print("      gun=%s action=%s threats=%d hidden=%s goal_hidden=%s goal_distance=%.3f" % [str(o.ws()), str(o.action),
						threats.size(), str(w.brain._hidden(o.pos, threats, 0.82)), str(goal_hidden), o.pos.distance_to(o.goal)])
				if not o.aim.is_empty():
					var target = w.by_id.get(o.aim.get("tid", ""), null)
					var friendly_block: bool = target != null and w.friend_in_line(o, target.pos, 0.5 if o.has("WD10") else 0.3, 4.0 if o.judges else 0.0)
					print("      aim=%s action=%s gun=%s friend_in_lane=%s sidestep=%s" % [str(o.aim), str(o.action), str(o.ws()), str(friendly_block), str(o.sidestep)])
			for tm in w.teams.slice(0, 2):
				for el in tm["elements"]:
					print("  squad %s mode=%s task=%s phase=%s" % [tm["tag"], el["mode"], str(el["task"]), el["phase"]])
			next += interval
		if args.has("stop") and w.t >= float(args["stop"]):
			break
	w.dispose()
	quit()
