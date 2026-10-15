extends SceneTree
## Fuzz: random team sizes (1-5 each), echelons, good/bad habit subsets, placements and
## postures. Any script error shows up in the output; the summary checks that every
## habit was exercised and every match ended.
##   godot --headless --path . -s res://tests/fuzz_test.gd -- --n=150
const Habits = preload("res://scripts/data/habits.gd")
const Level = preload("res://scripts/sim/level.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

func _init() -> void:
	var n := 120
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.trim_prefix("--n="))
	var lv = Level.new()
	lv.build()
	var nav = Nav.new()
	nav.build(lv)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var bad_seen := {}
	var ends := [0, 0, 0]
	var t0 := Time.get_ticks_msec()
	var sim_t := 0.0
	for k in n:
		var cfgs: Array = []
		var sizes := [rng.randi_range(1, 5), rng.randi_range(1, 5)]
		for id in ["A1", "A2", "A3", "A4", "A5", "B1", "B2", "B3", "B4", "B5"]:
			var team := 0 if id.begins_with("A") else 1
			var ech: String = Habits.ECHELON_ORDER[rng.randi_range(0, 4)]
			var good := {}
			for g in Habits.good_ids():
				good[g] = rng.randf() < 0.55
			var bad := {}
			for b in Habits.bad_ids():
				bad[b] = rng.randf() < 0.45
			var p: Vector2 = lv.spawns[id]["p"]
			if rng.randf() < 0.5:
				for tries in 50:
					var q := Vector2(rng.randf_range(1, 35), rng.randf_range(1, 23))
					if nav.is_free(q):
						p = q
						break
			cfgs.append({"id": id, "team": team, "slot": int(id[1]) - 1, "echelon": ech, "good": good, "bad": bad,
				"plates": rng.randi_range(0, 4), "pos": p, "face": rng.randf() * TAU, "enabled": int(id[1]) <= sizes[team]})
		var post: Array = [["assault", "hold", "hunt"][rng.randi_range(0, 2)], ["assault", "hold", "hunt"][rng.randi_range(0, 2)]]
		var w = World.new()
		w.keep_events = rng.randf() < 0.3
		w.setup(lv, nav, cfgs, post, 5000 + k)
		while not w.over:
			w.step()
			for o in w.ops:
				for b in o.active_bad:
					bad_seen[b] = true
			if w.keep_events:
				w.events.clear()
		ends[w.winner] += 1
		sim_t += w.t
		w.dispose()
	print("fuzz matches %d: A %d  B %d  draw %d   sim %.0f s in %d ms" % [n, ends[0], ends[1], ends[2], sim_t, Time.get_ticks_msec() - t0])
	var missing: Array = []
	for b in Habits.bad_ids():
		if not bad_seen.has(b):
			missing.append(b)
	print("bad habits activated: %d/20  missing: %s" % [bad_seen.size(), str(missing)])
	quit()
