extends SceneTree
## The v0.7 gate: every order has a test where obeying it measurably changes the
## outcome. Each order runs N seeds with the order and N seeds without it, on the same
## map with the same officers and occupants, and compares one measure.
##   godot --headless --path . -s res://tests/orders_test.gd -- --n=8 [--only=avoid] [--v]

const Department = preload("res://scripts/campaign/department.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var dept
var args := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "8"))
	dept = Department.new()
	dept.found(77)
	var tests := ["clear", "arrest", "rescue", "contain", "post", "patrol", "avoid", "consolidate", "phase", "entry",
		"pace", "tight", "knock", "pistols"]
	if args.has("only"):
		tests = [args["only"]]
	var passed := 0
	var t0 := Time.get_ticks_msec()
	print("order         measure                                     with    without   gate")
	for tn in tests:
		var with_v: Array = []
		var without_v: Array = []
		# a yes/no measure needs more seeds than 8 to show a 0.2 difference (v0.7.5)
		var nn := maxi(n, int(GATES[tn].get("n_min", 0)))
		for k in nn:
			with_v.append(call("t_" + tn, true, 500 + k))
			without_v.append(call("t_" + tn, false, 500 + k))
		var a := _mean(with_v)
		var b := _mean(without_v)
		var spec: Dictionary = GATES[tn]
		var ok: bool = (a - b) * float(spec["dir"]) >= float(spec["margin"])
		passed += 1 if ok else 0
		print("%-13s %-42s %7.2f  %7.2f   %s" % [tn, spec["measure"], a, b, "PASS" if ok else "FAIL"])
		if args.has("v"):
			print("    with: %s\n    without: %s" % [str(with_v), str(without_v)])
	print("%d of %d orders change the outcome (%d runs each way, 32 for arrest, %d s)" % [passed, tests.size(), n, (Time.get_ticks_msec() - t0) / 1000])
	quit()


## measure, direction (+1: higher with the order), smallest difference that counts
const GATES := {
	"clear": {"measure": "rooms entered (fewer)", "dir": -1, "margin": 1.5},
	"arrest": {"measure": "named suspect arrested (share)", "dir": 1, "margin": 0.2, "n_min": 32},
	"rescue": {"measure": "hostages walked out safe", "dir": 1, "margin": 0.75},
	"contain": {"measure": "suspects escaped (fewer)", "dir": -1, "margin": 0.25},
	"post": {"measure": "distance from the post at the end, m (less)", "dir": -1, "margin": 3.0},
	"patrol": {"measure": "route waypoints visited (share)", "dir": 1, "margin": 0.4},
	"avoid": {"measure": "officer-seconds in the avoided room (fewer)", "dir": -1, "margin": 5.0},
	"consolidate": {"measure": "s from the hall to the next room or the end", "dir": 1, "margin": 10.0},
	"phase": {"measure": "s to the first officer inside (later)", "dir": 1, "margin": 20.0},
	"entry": {"measure": "first room entered is the kitchen (share)", "dir": 1, "margin": 0.5},
	"pace": {"measure": "top speed out of a fight, m/s (lower)", "dir": -1, "margin": 0.3},
	"tight": {"measure": "police rounds at an armed man not attacking", "dir": -1, "margin": 0.5},
	"knock": {"measure": "civilians with hands up at first entry", "dir": 1, "margin": 0.5},
	"pistols": {"measure": "rifle rounds fired by police (fewer)", "dir": -1, "margin": 1.5},
}


func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(1.0, a.size())


# ------------------------------------------------------------------ harness
## Officers: the most senior n of the test department, in a fixed order.
func _officers(n: int, skip := 0) -> Array:
	var recs: Array = dept.officers.duplicate()
	recs.sort_custom(func(a, b): return Orders.rank_i(a) > Orders.rank_i(b) or (Orders.rank_i(a) == Orders.rank_i(b) and int(a["xp"]) > int(b["xp"])))
	var out: Array = []
	for r in recs.slice(skip, skip + n):
		out.append(r["id"])
	return out


func _sit(type: String, seed_v: int, occ: Array, extra := {}) -> Dictionary:
	var s := {"id": "T", "type": type, "seed": seed_v, "occupants": occ, "intel": [], "named": "", "visibility": 2}
	for k in extra:
		s[k] = extra[k]
	for oc in occ:
		if oc.get("named", false):
			s["named"] = oc.get("name", "")
	return s


## Run one operation. sample(w) is called every 10 ticks; returns the world.
func _run(map_i: int, sit: Dictionary, plan: Dictionary, limit: float, sample := Callable()) -> Object:
	var lv = Maps.get_level(map_i)
	var nav = Nav.new()
	nav.build(lv)
	var b: Dictionary = Operation.build_planned(sit, plan, dept, lv, nav)
	b["opts"]["time_limit"] = limit
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	var k := 0
	while not w.over and k < 40000:
		w.step()
		w.events.clear()
		k += 1
		if k % 10 == 0 and sample.is_valid():
			sample.call(w)
	return w


func _sq(members: Array, od: Dictionary, stage := 0) -> Dictionary:
	return {"members": members, "orders": od, "stage": stage}


func _od(objs: Array, extra := {}) -> Dictionary:
	var od := Orders.empty_orders()
	od["objs"] = objs
	for k in extra:
		od[k] = extra[k]
	return od


func _inside_rooms(w) -> Dictionary:
	var out := {}
	for o in w.ops:
		if o.judges and o.alive() and not w.level.is_exterior(o.room):
			out[o.room] = true
	return out


## Someone in the far bedroom who keeps the operation going and keeps out of the way.
func _far() -> Dictionary:
	return {"role": "suspect", "ech": "untrained", "room": "BED2", "arms": "pistol", "alert": 0, "flight": 0.0}


# ------------------------------------------------------------------ the tests
func t_clear(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [{"role": "suspect", "ech": "untrained", "room": "BED1", "arms": "pistol", "alert": 0}])
	var rooms := [] if not on else ["BED1"]
	var seen := {}
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": rooms}]))]}, 240.0,
		func(ww): for r in _inside_rooms(ww): seen[r] = true)
	w.dispose()
	return seen.size()


func t_arrest(on: bool, sd: int) -> float:
	var sit := _sit("warrant", sd, [{"role": "suspect", "name": "Target", "named": true, "ech": "militia", "room": "LIVING", "arms": "pistol", "alert": 1}])
	var ob := {"kind": "arrest"} if on else {"kind": "clear", "rooms": []}
	var w = _run(4, sit, {"squads": [_sq(_officers(4, 2), _od([ob]))]}, 300.0)
	var got := 0.0
	for o in w.ops:
		if o.name == "Target" and (o.arrested or o.complying):
			got = 1.0
	w.dispose()
	return got


func t_rescue(on: bool, sd: int) -> float:
	var sit := _sit("hostage", sd, [{"role": "captor", "name": "Captor", "named": true, "ech": "untrained", "room": "KITCHEN", "arms": "pistol", "alert": 1},
		{"role": "hostage", "room": "KITCHEN"}, {"role": "hostage", "room": "KITCHEN"}])
	var ob := {"kind": "rescue", "rooms": ["KITCHEN"]} if on else {"kind": "clear", "rooms": ["KITCHEN"]}
	var w = _run(4, sit, {"squads": [_sq(_officers(5), _od([ob]))]}, 300.0)
	var safe := 0
	for o in w.ops:
		if o.hostage and o.cstate == "safe" and o.alive():
			safe += 1
	w.dispose()
	return safe


func t_contain(on: bool, sd: int) -> float:
	var sit := _sit("warrant", sd, [{"role": "suspect", "name": "Runner", "named": true, "ech": "untrained", "room": "BED2", "arms": "pistol", "flight": 1.0, "alert": 0}])
	var sq2 := _od([{"kind": "contain", "openings": [12, 13, 14]}]) if on else _od([{"kind": "post", "p": [36.0, 26.0], "face": -PI / 2.0}])
	var sq1 := _od([{"kind": "arrest"}], {"knock": true, "phase": {"kind": "squad", "squad": 1}})
	if not on:
		sq1["phase"] = {"kind": "time", "t": 30}
	var w = _run(4, sit, {"squads": [_sq(_officers(4), sq1, 0), _sq(_officers(4, 4), sq2, 1)]}, 240.0)
	var esc := float(w.incident.escapes.size())
	w.dispose()
	return esc


func t_post(on: bool, sd: int) -> float:
	var sit := _sit("event", sd, [], {"crowd": 12, "duration": 150})
	var ob := {"kind": "post", "p": [32.0, 20.0], "face": PI / 2.0} if on else {"kind": "patrol", "route": [[18.0, 30.0], [46.0, 30.0], [46.0, 16.0], [18.0, 16.0]]}
	var w = _run(11, sit, {"squads": [_sq(_officers(4), _od([ob]))]}, 150.0)
	var d := 0.0
	var n := 0
	for o in w.ops:
		if o.judges:
			d += o.pos.distance_to(Vector2(32.0, 20.0))
			n += 1
	w.dispose()
	return d / maxf(1.0, n)


func t_patrol(on: bool, sd: int) -> float:
	var route := [Vector2(18.0, 30.0), Vector2(46.0, 30.0), Vector2(46.0, 16.0), Vector2(18.0, 16.0)]
	var sit := _sit("event", sd, [], {"crowd": 12, "duration": 150})
	var ob := {"kind": "patrol", "route": route.map(func(v): return [v.x, v.y])} if on else {"kind": "post", "p": [32.0, 36.0], "face": PI / 2.0}
	var hit := {}
	var w = _run(11, sit, {"squads": [_sq(_officers(4), _od([ob]))]}, 150.0, func(ww):
		for o in ww.ops:
			if o.judges:
				for i in route.size():
					if o.pos.distance_to(route[i]) < 3.0:
						hit[i] = true)
	w.dispose()
	return hit.size() / float(route.size())


func t_avoid(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [{"role": "suspect", "ech": "untrained", "room": "BED2", "arms": "pistol", "alert": 0}])
	var extra := {"avoid": ["LIVING"]} if on else {}
	var secs := [0.0]
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 240.0, func(ww):
		for o in ww.ops:
			if o.judges and o.alive() and o.room == "LIVING":
				secs[0] += 10.0 / 30.0)
	w.dispose()
	return secs[0]


func t_consolidate(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [_far()])
	var extra := {"consolidate": "HALL"} if on else {}
	var st := {"hall": -1.0, "next": -1.0}
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 240.0, func(ww):
		var tm: Dictionary = ww.teams[0]
		if st["hall"] < 0.0 and tm["cleared"].has("HALL"):
			st["hall"] = ww.t
		if st["hall"] >= 0.0 and st["next"] < 0.0:
			for r in _inside_rooms(ww):
				if r != "HALL":
					st["next"] = ww.t)
	# the time until an officer is in another room, or until the operation ends if the
	# suspect forces the issue first (a fight at the hall door can end it before anyone
	# goes on)
	var res := 0.0
	if st["hall"] >= 0.0:
		res = (st["next"] if st["next"] >= 0.0 else w.t) - st["hall"]
	if args.has("vv"):
		print("  seed %d %s: hall %.1f next %.1f end %.1f winner %d" % [sd, "on" if on else "off", st["hall"], st["next"], w.t, w.winner])
		for ln in w.log_lines:
			if ln["kind"] in ["info", "order", "comms"] and not String(ln["text"]).contains("Show me"):
				print("     ", ln["text"])
	w.dispose()
	return res


func t_phase(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [_far()])
	var extra := {"phase": {"kind": "time", "t": 60}} if on else {}
	var first := [-1.0]
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 150.0, func(ww):
		if first[0] < 0.0 and not _inside_rooms(ww).is_empty():
			first[0] = ww.t)
	w.dispose()
	return first[0]


func t_entry(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [_far()])
	var extra := {"entry": "KBACK"} if on else {}
	var first := [""]
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 120.0, func(ww):
		if first[0] == "":
			for r in _inside_rooms(ww):
				first[0] = r)
	w.dispose()
	return 1.0 if first[0] == "KITCHEN" else 0.0


func t_pace(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [_far()])
	var extra := {"pace": "walk"} if on else {}
	var top := [0.0]
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 120.0, func(ww):
		for o in ww.ops:
			if o.judges and o.alive() and not ww.in_combat(o):
				top[0] = maxf(top[0], o.vel.length()))
	w.dispose()
	return top[0]


func t_tight(on: bool, sd: int) -> float:
	# a man with a rifle slung, not expecting anyone: armed, but not attacking
	var sit := _sit("gang", sd, [{"role": "suspect", "ech": "untrained", "room": "LIVING", "arms": "rifle", "alert": 0}])
	var extra := {"tight": true} if on else {}
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 180.0)
	var pre := 0
	for sh in w.incident.shots:
		if sh["pol"] and sh["tgt"] != "" and not sh.get("att", true) and sh["verdict"] == "threat":
			pre += 1
			if args.has("vv"):
				print("      ", on, " ", sh)
	w.dispose()
	return pre


func t_knock(on: bool, sd: int) -> float:
	var sit := _sit("warrant", sd, [{"role": "suspect", "name": "Quiet", "named": true, "ech": "untrained", "room": "BED1", "arms": "pistol", "flight": 0.0, "alert": 0},
		{"role": "civilian", "room": "LIVING"}, {"role": "civilian", "room": "KITCHEN"}, {"role": "civilian", "room": "BED2"}])
	var extra := {"knock": true} if on else {}
	var at_entry := [-1.0]
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "arrest"}], extra))]}, 150.0, func(ww):
		if at_entry[0] < 0.0 and not _inside_rooms(ww).is_empty():
			var n := 0
			for o in ww.ops:
				if o.civ and o.cstate == "comply":
					n += 1
			at_entry[0] = n)
	w.dispose()
	return maxf(0.0, at_entry[0])


func t_pistols(on: bool, sd: int) -> float:
	var sit := _sit("gang", sd, [{"role": "suspect", "ech": "militia", "room": "LIVING", "arms": "rifle", "alert": 1},
		{"role": "suspect", "ech": "untrained", "room": "KITCHEN", "arms": "pistol", "alert": 1}])
	var extra := {"pistols": true} if on else {}
	var w = _run(4, sit, {"squads": [_sq(_officers(4), _od([{"kind": "clear", "rooms": []}], extra))]}, 180.0)
	var rifle := 0
	for sh in w.incident.shots:
		if sh["pol"] and sh.get("weapon", "") == "rifle":
			rifle += 1
	w.dispose()
	return rifle
