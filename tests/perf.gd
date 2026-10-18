extends SceneTree
## Profile: where the time goes in a big fight.
##   godot --headless --path . -s res://tests/perf.gd -- --map=10 --na=20 --nb=20 --t=60 --pa=hunt --pb=hunt
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")


func _init() -> void:
	var opt := {"map": "10", "na": "20", "nb": "20", "t": "60", "pa": "assault", "pb": "hold", "a": "sof", "b": "militia", "seed": "77"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2:
			opt[kv[0]] = kv[1]
	var lv = Maps.get_level(Maps.index_of(opt["map"]))
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	w.profiling = true
	var cfgs: Array = Teams.team(lv, 0, {"n": int(opt["na"]), "ech": opt["a"]}) + Teams.team(lv, 1, {"n": int(opt["nb"]), "ech": opt["b"]})
	w.setup(lv, nav, cfgs, [opt["pa"], opt["pb"]], int(opt["seed"]))
	var t0 := Time.get_ticks_usec()
	var ticks := 0
	var sc0: int = w.geom.sight_calls
	var pc0: int = nav.path_calls
	# H3 (analysis 5.3): time moving vs distance to the nearest living enemy.
	# The P1/P4 boundary at 10 m should show as a step in the move fraction.
	var t_move := []
	var t_all := []
	for i in 25:
		t_move.append(0.0)
		t_all.append(0.0)
	while not w.over and w.t < float(opt["t"]):
		w.step()
		ticks += 1
		for o in w.ops:
			if not o.alive():
				continue
			var dmin := 1e9
			for e in w.ops:
				if e.alive() and e.team != o.team:
					dmin = minf(dmin, o.pos.distance_to(e.pos))
			if dmin >= 25.0:
				continue
			var b := int(dmin)
			t_all[b] += 1.0 / 30.0
			if o.moving and o.speed > 0.0:
				t_move[b] += 1.0 / 30.0
	var us := Time.get_ticks_usec() - t0
	print("%d ticks, %.2f ms/tick, sim %.1f s, realtime factor %.1fx" % [ticks, us / 1000.0 / ticks, w.t, w.t / (us / 1e6)])
	for k in w.prof:
		print("  %-10s %6.2f ms/tick" % [k, w.prof[k] / 1000.0 / ticks])
	print("  sight checks/tick %.0f, path calls/tick %.2f (%.2f ms/tick)" % [float(w.geom.sight_calls - sc0) / ticks, float(nav.path_calls - pc0) / ticks, nav.path_us / 1000.0 / ticks])
	var alive := [0, 0]
	for o in w.ops:
		if o.alive():
			alive[o.team] += 1
	print("  alive %d/%d at %.1f s" % [alive[0], alive[1], w.t])
	print("movement vs distance to nearest living enemy (H3):")
	print("  dist_m  time_s  moving_s  moving%")
	for b in 25:
		if t_all[b] <= 0.0:
			continue
		print("  %2d-%2d   %6.1f   %6.1f    %3.0f%%" % [b, b + 1, t_all[b], t_move[b], 100.0 * t_move[b] / t_all[b]])
	quit()
