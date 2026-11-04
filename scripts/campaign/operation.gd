extends RefCounted
## Operation spec (v0.5/v0.6): what goes into one run of the simulation.
##   {map, seed, civilians: n, night, police_rules, roe_strict,
##    officers: [department records] (team A) or none (team A from the setup),
##    team_b: [configurations] }
## build() turns team A's department officers and the civilians into world
## configurations; civilians are placed from the seed, mostly indoors.

const CivBrain = preload("res://scripts/sim/civ_brain.gd")


## n civilians on the map: about two in three inside buildings, the rest in the yard,
## at least 1.2 m apart and 5 m from team A's posts. Deterministic for a seed.
static func civilians(level, nav, n: int, seed_val: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 31 + 17
	var out: Array = []
	var taken: Array = []
	var a_posts: Array = []
	for k in 30:
		a_posts.append(level.spawns["A%d" % (k + 1)]["p"])
	var tries := 0
	while out.size() < n and tries < n * 400:
		tries += 1
		var p := Vector2(rng.randf_range(1.0, level.W - 1.0), rng.randf_range(1.0, level.H - 1.0))
		if not nav.reachable(p):
			continue
		var inside: bool = not level.is_exterior(level.room_at(p))
		var want_inside: bool = out.size() % 3 != 2
		if inside != want_inside and tries < n * 200:
			continue
		var ok := true
		for q in taken:
			if p.distance_to(q) < 1.2:
				ok = false
				break
		for q2 in a_posts:
			if p.distance_to(q2) < 5.0:
				ok = false
				break
		if not ok:
			continue
		taken.append(p)
		var i := out.size()
		out.append({"id": "C%d" % (i + 1), "team": 2, "faction": 2, "slot": i, "echelon": "untrained", "good": {}, "bad": {},
			"plates": 0, "exp": 1, "traits": {}, "pos": p, "face": rng.randf() * TAU, "enabled": true, "civ": true,
			"alert": 0, "persona": CivBrain.roll_persona(rng)})
	return out


## The configurations for a run: team A from the department when officers are given
## (in their order, up to twenty), the rest of the setup's configurations as they are,
## and the civilians.
static func build(base_cfgs: Array, level, nav, spec: Dictionary, dept = null) -> Array:
	var out: Array = []
	var officers: Array = spec.get("officers", [])
	var alert_a: int = int(spec.get("alert_a", 1))
	if dept != null and not officers.is_empty():
		for k in mini(officers.size(), 30):
			out.append(dept.to_cfg(officers[k], k, level, alert_a))
		for c in base_cfgs:
			if c["team"] != 0:
				out.append(c)
	else:
		out = base_cfgs.duplicate()
	var n_civ: int = int(spec.get("civilians", 0))
	if n_civ > 0:
		out.append_array(civilians(level, nav, n_civ, int(spec.get("seed", 1))))
	return out


# ================================================================== planned operations (v0.7)
const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Geom = preload("res://scripts/sim/geom.gd")
const TIME_LIMIT := {"warrant": 600.0, "gang": 720.0, "barricade": 900.0, "hostage": 900.0, "event": 900.0}


## The stage areas of a map, named by the side they face from: where squads form up and
## where their vehicles are.
static func stages(level) -> Array:
	var out: Array = []
	for i in level.stage_a.size():
		var st: Dictionary = level.stage_a[i]
		var f: float = st["face"]
		var side := "south"
		if absf(angle_difference(f, PI / 2.0)) < 0.8:
			side = "north"
		elif absf(angle_difference(f, 0.0)) < 0.8:
			side = "west"
		elif absf(angle_difference(f, PI)) < 0.8:
			side = "east"
		var dup := 0
		for o in out:
			if String(o["name"]).begins_with(side):
				dup += 1
		out.append({"i": i, "name": side + ("" if dup == 0 else " %d" % (dup + 1)), "r": st["r"], "face": f})
	return out


## n points in a stage rectangle, front row first, 0.9 m apart, clear of `taken`.
static func stage_points(level, nav, si: int, n: int, taken: Array) -> Array:
	var st: Dictionary = level.stage_a[clampi(si, 0, level.stage_a.size() - 1)]
	var r: Rect2 = st["r"]
	var f := Vector2.from_angle(st["face"])
	var c := r.get_center()
	var cands: Array = []
	var x := r.position.x + 0.45
	while x <= r.end.x - 0.3:
		var y := r.position.y + 0.45
		while y <= r.end.y - 0.3:
			var p := Vector2(x, y)
			if nav.reachable(p):
				cands.append([-(p - c).dot(f), absf((p - c).dot(f.orthogonal())), p])
			y += 0.9
		x += 0.9
	cands.sort_custom(func(a, b): return a[0] < b[0] - 0.3 or (absf(a[0] - b[0]) <= 0.3 and a[1] < b[1]))
	var out: Array = []
	for cd in cands:
		if out.size() >= n:
			break
		var ok := true
		for q in taken:
			if (q as Vector2).distance_to(cd[2]) < 0.8:
				ok = false
				break
		if ok:
			out.append(cd[2])
			taken.append(cd[2])
	while out.size() < n:
		out.append(nav.snap(c))
	return out


## A free point in a room, away from its doors and from everyone already placed.
static func room_point(level, nav, room: String, rng: RandomNumberGenerator, taken: Array) -> Vector2:
	if not level.rooms.has(room):
		return nav.snap(Vector2(level.W / 2.0, level.H / 2.0))
	var doors: Array = []
	for did in level.adj.get(room, []):
		doors.append(level.doors[did]["c"])
	var best := Vector2.INF
	for k in 60:
		var rr: Rect2 = level.rooms[room]["rects"][rng.randi() % level.rooms[room]["rects"].size()]
		var p := Vector2(rng.randf_range(rr.position.x + 0.5, rr.end.x - 0.5), rng.randf_range(rr.position.y + 0.5, rr.end.y - 0.5))
		if not nav.reachable(p) or level.room_at(p) != room:
			continue
		var ok := true
		for d in doors:
			if (d as Vector2).distance_to(p) < 1.1:
				ok = false
		for q in taken:
			if (q as Vector2).distance_to(p) < 1.0:
				ok = false
		if ok:
			best = p
			break
		if best == Vector2.INF:
			best = p
	if best == Vector2.INF:
		best = nav.snap(level.rooms[room]["label"])
	taken.append(best)
	return best


## Contain posts: for each opening, a point 4-7 m outside it, off its axis, with a view
## of it and near cover where there is any.
static func contain_posts(level, nav, openings: Array) -> Array:
	var out: Array = []
	for oi in openings:
		if int(oi) < 0 or int(oi) >= level.openings.size():
			continue
		var op: Dictionary = level.openings[int(oi)]
		var c: Vector2 = op["c"]
		var n: Vector2 = op["out"]
		if not level.is_exterior(level.room_at(c + n * 0.6)):
			n = -n
		var best = null
		var best_s := -INF
		for dist in [4.0, 5.0, 6.0, 7.0]:
			for ang in [-0.6, 0.6, -0.35, 0.35, -0.9, 0.9, 0.0]:
				var p: Vector2 = c + n.rotated(ang) * dist
				if not nav.reachable(p) or not level.is_exterior(level.room_at(p)):
					continue
				if not level.geom.sight_clear(p, 1.5, c + n * 0.3, 1.2):
					continue
				var s := -absf(dist - 5.0) * 0.3 + (1.0 if absf(ang) > 0.3 else 0.0)
				if level.geom.dist_to_kinds(p, [Geom.COVER, Geom.WALL], 1.2) < 1.0:
					s += 1.5
				for q in out:
					if (q["p"] as Vector2).distance_to(p) < 1.5:
						s -= 3.0
				if s > best_s:
					best_s = s
					best = p
		if best == null:
			best = nav.snap(c + n * 5.0)
		out.append({"p": best, "face": (c - best).angle()})
	return out


## Post: a tight group around a point, all facing the same way.
static func post_points(nav, p: Vector2, face: float, n: int) -> Array:
	var out: Array = []
	var side := Vector2.from_angle(face).orthogonal()
	for k in n:
		var off: Vector2 = side * (k - (n - 1) / 2.0) * 1.2
		out.append({"p": nav.snap(p + off), "face": face})
	return out


static func _v(a) -> Vector2:
	if a is Vector2:
		return a
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


## A configuration for one occupant of a situation (team 1: suspects, captors,
## attackers; team 2: civilians and hostages).
static func _occupant_cfg(oc: Dictionary, id: String, team: int, slot: int, p: Vector2, face: float, rng: RandomNumberGenerator) -> Dictionary:
	var role: String = oc["role"]
	if role in ["civilian", "hostage"]:
		return {"id": id, "team": 2, "faction": 2, "slot": slot, "echelon": "untrained", "good": {}, "bad": {},
			"plates": 0, "exp": 1, "traits": {}, "pos": p, "face": face, "enabled": true, "civ": true, "alert": 0,
			"persona": CivBrain.roll_persona(rng), "hostage": role == "hostage"}
	var ech: String = oc.get("ech", "untrained")
	var good := {}
	for g in Habits.preset_good(ech):
		good[g] = true
	var bad := {}
	for b in Habits.stress_bad_ids():
		bad[b] = true
	if rng.randf() < 0.3:
		var pers: Array = [["BH11", "BH12", "BH25"], ["BH13", "BH14"], ["BH15", "BH16", "BH23"], ["BH17", "BH18", "BH27"]][rng.randi() % 4]
		bad[pers[rng.randi() % pers.size()]] = true
	var c := {"id": id, "team": team, "slot": slot, "echelon": ech, "good": good, "bad": bad, "plates": 0,
		"exp": Habits.PRESET_EXP[ech], "traits": {}, "pos": p, "face": face, "enabled": true, "alert": int(oc.get("alert", 0)),
		"name": oc.get("name", ""), "flight": float(oc.get("flight", 0.0)), "captor": role == "captor",
		"sidearm_only": oc.get("arms", "pistol") == "pistol", "kit": occupant_kit(oc)}
	if role == "attacker":
		c["attacker"] = true
		c["arms"] = oc.get("arms", "pistol")
	return c


## What an occupant carries (v0.7.5): "pistol" a handgun, "rifle" a long gun (the
## situation may name which), "shotgun" a pump shotgun; a vest if the situation says so.
static func occupant_kit(oc: Dictionary) -> Dictionary:
	var arms: String = oc.get("arms", "pistol")
	var prim := ""
	if arms == "rifle":
		prim = oc.get("long_gun", "carbine")
	elif arms == "shotgun":
		prim = "shotgun"
	elif Equipment.WEAPONS.has(arms) and Equipment.WEAPONS[arms]["slot"] == "primary":
		prim = arms
	var sec: String = oc.get("handgun", "service_pistol")
	return Equipment.normalize({"primary": prim, "secondary": sec, "optic": "irons" if prim != "" and oc.get("irons", false) else "red_dot",
		"armour": "vest" if oc.get("vest", false) else "none", "plates": 0, "head": "none", "gear": {}})


## Everything a planned operation needs: the configurations of everyone in it, and the
## world's options (squad orders, vehicles, casualty point, deadline, event, night).
## Deterministic for the situation's seed and the plan.
static func build_planned(sit: Dictionary, plan: Dictionary, dept, level, nav) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sit["seed"]) * 13 + 5
	var cfgs: Array = []
	var taken: Array = []
	# occupants
	var ids := {}          # occupant index -> operator id
	var nb := 0
	var nc := 0
	var crowd_pts: Array = []
	for i in sit["occupants"].size():
		var oc: Dictionary = sit["occupants"][i]
		var role: String = oc["role"]
		var p: Vector2
		if role == "attacker":
			p = _crowd_point(level, nav, rng, taken)
		else:
			p = room_point(level, nav, oc.get("room", "OUT"), rng, taken)
		var face := rng.randf() * TAU
		var team := 2 if role in ["civilian", "hostage"] else 1
		var id := ""
		if team == 1:
			nb += 1
			id = "B%d" % nb
		else:
			nc += 1
			id = "C%d" % nc
		ids[i] = id
		cfgs.append(_occupant_cfg(oc, id, team, (nb if team == 1 else nc) - 1, p, face, rng))
	# a crowd at a public event
	if sit["type"] == "event":
		for k in int(sit.get("crowd", 40)):
			nc += 1
			var cp := _crowd_point(level, nav, rng, taken)
			crowd_pts.append(cp)
			var sc = level.get("stage_c")
			var cface: float = (sc - cp).angle() if sc != null else rng.randf() * TAU
			var cc := _occupant_cfg({"role": "civilian"}, "C%d" % nc, 2, nc - 1, cp, cface, rng)
			cfgs.append(cc)
	# police squads, formed up at their stage areas
	var squads: Array = plan.get("squads", [])
	var orders_rt: Array = []
	var vehicles: Array = []
	var slot := 0
	var stage_taken: Array = []
	var st_list := stages(level)
	for si in squads.size():
		var sq: Dictionary = squads[si]
		var members: Array = []
		for oid in sq.get("members", []):
			var r: Dictionary = dept.get_officer(oid)
			if not r.is_empty() and r["status"] == "active":
				members.append(r)
		var stage_i: int = clampi(int(sq.get("stage", si % maxi(1, st_list.size()))), 0, maxi(0, st_list.size() - 1))
		var pts: Array = stage_points(level, nav, stage_i, maxi(1, members.size()), stage_taken)
		var st: Dictionary = st_list[stage_i] if not st_list.is_empty() else {"r": Rect2(1, 1, 2, 2), "face": 0.0}
		var back: Vector2 = (st["r"] as Rect2).get_center() - Vector2.from_angle(st["face"]) * 1.0
		vehicles.append(nav.snap(back))
		var od: Dictionary = _orders_runtime(sq.get("orders", {}), level, nav, sit, ids, members.size())
		# cohesion (v0.8): the pairs' shared operations and the leader's experience
		od["cohesion"] = dept.squad_cohesion(members)
		orders_rt.append(od)
		var ak: String = nav.avoid_key(od.get("avoid", []))
		for k in members.size():
			var c: Dictionary = dept.to_cfg(members[k], slot, level, police_alert(sit))
			c["id"] = "A%d" % (slot + 1)
			c["slot"] = slot
			c["pos"] = pts[k]
			c["face"] = st["face"]
			c["squad"] = si
			c["pace"] = od.get("pace", "")
			c["tight"] = od.get("tight", false)
			c["less"] = od.get("less", false)
			c["pistols"] = od.get("pistols", false)
			c["avoid_key"] = ak
			c["bodycam"] = bool(plan.get("bodycams", dept.bodycams))
			cfgs.append(c)
			slot += 1
	var casualty: Vector2 = vehicles[0] + Vector2(1.5, 0) if not vehicles.is_empty() else nav.snap(Vector2(2, 2))
	var opts := {"police_rules": true, "night": bool(plan.get("night", sit.get("night", false))), "squads": orders_rt,
		"vehicles": vehicles, "casualty": nav.snap(casualty), "b_stay": true, "b_posted": sit["type"] != "event",
		"time_limit": TIME_LIMIT.get(sit["type"], 600.0), "escape": true, "doors": sit.get("doors", {}).duplicate()}
	# where the briefing believes the named suspect is (its best guess, right or wrong)
	for f in sit.get("intel", []):
		if f.get("key", "") == "named_room":
			var rr: String = f["room"] if f.get("known", false) else f.get("room_est", "")
			if rr != "":
				opts["intel_rooms"] = [rr]
	if sit["type"] == "hostage":
		opts["deadline"] = float(sit.get("deadline", 420))
	if sit["type"] == "event":
		opts["event"] = {"attack_t": float(sit.get("attack_t", -1)) if sit.get("attack", false) else -1.0,
			"crowd": crowd_pts.slice(0, 12), "duration": float(sit.get("duration", 900))}
		opts["time_limit"] = float(sit.get("duration", 900))
	return {"cfgs": cfgs, "opts": opts, "postures": ["assault", "hold"], "alerts": [police_alert(sit), 0], "seed": int(sit["seed"]),
		"ids": ids}


## A point in the crowd area of a public event (or anywhere outdoors).
static func _crowd_point(level, nav, rng: RandomNumberGenerator, taken: Array) -> Vector2:
	var rects: Array = level.get("crowd_rects") if level.get("crowd_rects") != null else []
	for k in 80:
		var p: Vector2
		if not rects.is_empty():
			var r: Rect2 = rects[rng.randi() % rects.size()]
			p = Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		else:
			p = Vector2(rng.randf_range(2.0, level.W - 2.0), rng.randf_range(2.0, level.H - 2.0))
		if not nav.reachable(p):
			continue
		var ok := true
		for q in taken:
			if (q as Vector2).distance_to(p) < 0.9:
				ok = false
				break
		if ok:
			taken.append(p)
			return p
	return nav.snap(Vector2(level.W / 2.0, level.H / 2.0))


## The plan's orders (as saved: rooms, door ids, opening indices, points as arrays) made
## ready for the world: posts worked out, the arrest target named, points as vectors.
static func _orders_runtime(od0: Dictionary, level, nav, sit: Dictionary, ids: Dictionary, n_members: int) -> Dictionary:
	var od: Dictionary = od0.duplicate(true)
	if od.is_empty():
		od = {"objs": [{"kind": "clear", "rooms": []}]}
	var objs: Array = []
	for ob0 in od.get("objs", []):
		var ob: Dictionary = ob0.duplicate(true)
		match ob.get("kind", "clear"):
			"arrest":
				# the named suspect (or the first suspect) of the situation
				var tid := ""
				var tname := ""
				for i in sit["occupants"].size():
					var oc: Dictionary = sit["occupants"][i]
					if oc.get("named", false) or (tid == "" and oc["role"] in ["suspect", "captor"]):
						tid = ids.get(i, "")
						tname = oc.get("name", "")
						if oc.get("named", false):
							break
				ob["target"] = tid
				ob["target_name"] = tname
			"contain":
				ob["posts"] = contain_posts(level, nav, ob.get("openings", []))
			"post":
				ob["posts"] = post_points(nav, _v(ob.get("p", [level.W / 2.0, level.H / 2.0])), float(ob.get("face", 0.0)), maxi(1, n_members))
			"patrol":
				var route: Array = []
				for q in ob.get("route", []):
					route.append(nav.snap(_v(q)))
				ob["route"] = route
		objs.append(ob)
	od["objs"] = objs
	return od


## The alert officers start an operation at (each officer's floor, and the team's base).
## Officers on post at a public event start relaxed (GREEN: holstered or low carry), not
## at the ready (EA_TASKS P1.B). At YELLOW a weapon "shows", and a crowd member who sees
## a weapon showing is alarmed and runs: the 1.B trace found quiet rallies with no
## attacker in which the crowd was fleeing from the police's own guns within seven
## seconds, and a running face is judged afresh. Drawing from GREEN costs 0.45-0.9 s.
static func police_alert(sit: Dictionary) -> int:
	return 0 if String(sit.get("type", "")) == "event" else 1
