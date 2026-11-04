extends RefCounted
## A descriptive travel-only reference, not a prediction of combat or a mathematical
## lower bound. One reachable sample per interior room (nearest its label), or each
## defender's starting post, is assigned to independently moving attackers. The next
## stop is the agent/target pair with the earliest predicted arrival. Profile 0 gives
## each unobstructed/open-door route; assigned route length / equipped walking speed
## gives its arrival time. This deliberately ignores formation, exposure preferences,
## checks, entry, combat, wounds, door work, and the fact that a check may not require
## entering a room. It must not be presented as an optimal tactical clearance time.

const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

var lv
var nav
var rooms: Array = []
var missing_rooms: Array = []
var distances := {}


func _init(level, navigator) -> void:
	lv = level
	nav = navigator
	var names: Array = lv.rooms.keys()
	names.sort()
	for name in names:
		if lv.is_exterior(name):
			continue
		var point = _room_sample(name)
		if point == null:
			missing_rooms.append(name)
		else:
			rooms.append({"id": "R:" + String(name), "name": name, "p": point})


## Sample the 0.25 m lattice, not the drawing label itself (which may be in furniture).
func _room_sample(name: String):
	var rm: Dictionary = lv.rooms[name]
	var label: Vector2 = rm["label"]
	var best = null
	var score := INF
	for rect in rm["rects"]:
		var r: Rect2 = rect
		var x0 := maxi(0, int(floor(r.position.x / Nav.CS)))
		var y0 := maxi(0, int(floor(r.position.y / Nav.CS)))
		var x1 := mini(nav.nx - 1, int(ceil(r.end.x / Nav.CS)))
		var y1 := mini(nav.ny - 1, int(ceil(r.end.y / Nav.CS)))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var p: Vector2 = nav.cell_centre(Vector2i(x, y))
				if not r.has_point(p) or lv.room_at(p) != name or not nav.reachable(p):
					continue
				var ds := p.distance_squared_to(label)
				if ds < score:
					score = ds
					best = p
	return best


func _distance(a: Dictionary, b: Dictionary) -> float:
	var key := String(a["id"]) + ">" + String(b["id"])
	if distances.has(key):
		return distances[key]
	var path: PackedVector2Array = nav.find_path(0, a["p"], b["p"])
	var distance := -1.0
	# find_path may deliberately return a safe substitute for an unreachable goal;
	# that is not a measurement to the requested target.
	if not path.is_empty() and path[path.size() - 1].distance_to(b["p"]) < 0.01:
		distance = nav.path_length(path)
	distances[key] = distance
	return distance


static func equipped_walk_speed(cfg: Dictionary) -> float:
	var kit: Dictionary = Equipment.normalize(cfg["kit"])
	return World.SPEEDS["walk"] * (1.0 - 0.04 * int(kit["plates"])) * Equipment.speed_factor(kit)


static func attackers(cfgs: Array) -> Array:
	var result: Array = []
	for cfg in cfgs:
		if cfg.get("enabled", true) and int(cfg["team"]) == 0:
			result.append({"id": String(cfg["id"]), "p": cfg["pos"], "speed": equipped_walk_speed(cfg)})
	return result


static func defender_posts(cfgs: Array) -> Array:
	var result: Array = []
	for cfg in cfgs:
		if cfg.get("enabled", true) and int(cfg["team"]) == 1:
			result.append({"id": "D:" + String(cfg["id"]), "name": String(cfg["id"]), "p": cfg["pos"]})
	return result


func estimate(starts: Array, targets: Array) -> Dictionary:
	if starts.is_empty():
		return {"ok": false, "reason": "no attackers"}
	var agents: Array = []
	for start in starts:
		if float(start["speed"]) <= 0.0:
			return {"ok": false, "reason": "nonpositive speed"}
		agents.append({"id": start["id"], "p": start["p"], "speed": start["speed"],
			"time": 0.0, "metres": 0.0, "visits": []})
	var left := targets.duplicate()
	while not left.is_empty():
		var best_time := INF
		var best_d := 0.0
		var best_a := -1
		var best_t := -1
		for ai in agents.size():
			var agent: Dictionary = agents[ai]
			for ti in left.size():
				var d := _distance(agent, left[ti])
				if d < 0.0:
					continue
				var arrival: float = agent["time"] + d / float(agent["speed"])
				if arrival < best_time:
					best_time = arrival
					best_d = d
					best_a = ai
					best_t = ti
		if best_a < 0:
			return {"ok": false, "reason": "no route to remaining targets",
				"unreachable": left.map(func(target): return target["name"])}
		var chosen: Dictionary = left[best_t]
		var actor: Dictionary = agents[best_a]
		actor["id"] = chosen["id"]
		actor["p"] = chosen["p"]
		actor["time"] = best_time
		actor["metres"] += best_d
		actor["visits"].append(chosen["name"])
		left.remove_at(best_t)
	var last := 0.0
	var total_m := 0.0
	var paths: Array = []
	for ai in agents.size():
		var actor: Dictionary = agents[ai]
		last = maxf(last, actor["time"])
		total_m += actor["metres"]
		paths.append({"id": starts[ai]["id"], "metres": snappedf(actor["metres"], 0.001),
			"seconds": snappedf(actor["time"], 0.001), "targets": actor["visits"]})
	return {"ok": true, "seconds": snappedf(last, 0.001), "metres": snappedf(total_m, 0.001),
		"speed_mps": snappedf(float(starts[0]["speed"]), 0.0001), "paths": paths}
