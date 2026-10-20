extends RefCounted
## A sensible first plan for a situation (v0.7): the starting point the force and
## orders screens open with, and the plan the scripted chief uses in the campaign test.
## It is only a suggestion: two squads, the obvious objectives, a constraint or two the
## leaders can afford.

const Orders = preload("res://scripts/campaign/orders.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Operation = preload("res://scripts/campaign/operation.gd")

const WANT := {"warrant": 7, "gang": 10, "barricade": 7, "hostage": 9, "event": 10}


## Exterior doors of a map as opening indices, nearest to a point first.
static func exterior_doors(lv, near := Vector2.INF) -> Array:
	var out: Array = []
	for i in lv.openings.size():
		var op: Dictionary = lv.openings[i]
		if op["kind"] != "door":
			continue
		var D: Dictionary = lv.doors[op["id"]]
		if lv.is_exterior(D["a"]) or lv.is_exterior(D["b"]):
			out.append(i)
	if near != Vector2.INF:
		out.sort_custom(func(a, b): return (lv.openings[a]["c"] as Vector2).distance_to(near) < (lv.openings[b]["c"] as Vector2).distance_to(near))
	return out


## Officers best suited to lead first, then the rest by experience.
static func ranked(records: Array) -> Array:
	var r := records.duplicate()
	r.sort_custom(func(a, b):
		var ra: int = Orders.rank_i(a)
		var rb: int = Orders.rank_i(b)
		if ra != rb:
			return ra > rb
		return int(a["xp"]) > int(b["xp"]))
	return r


## How many officers a suggestion for one situation should take, so the week's other
## open situations nobody has planned yet keep their fair part of those still free:
## each situation's want, scaled down together when the free officers fall short.
static func share(board: Array, sid: String, free: int) -> int:
	var mine := 0
	var total := 0
	for s in board:
		if s.get("status", "open") != "open":
			continue
		if s["id"] != sid and not s.get("plan", {}).get("squads", []).is_empty():
			continue
		var w: int = WANT.get(s["type"], 8)
		total += w
		if s["id"] == sid:
			mine = w
	if mine == 0 or total <= free:
		return mini(mine if mine > 0 else 8, free)
	return clampi(int(round(float(free) * mine / total)), mini(3, free), mine)


## cap: the most officers to take (-1: as many as the situation wants).
static func suggest(sit: Dictionary, available: Array, lv, bodycams := false, cap := -1) -> Dictionary:
	var pool := ranked(available)
	var want: int = mini(WANT.get(sit["type"], 8), pool.size())
	if cap >= 0:
		want = mini(want, cap)
	var n_sq := 2 if want >= 4 else 1
	if sit["type"] == "event" and want >= 9:
		n_sq = 3
	# leaders first: one per squad, then the rest dealt round
	var squads: Array = []
	for k in n_sq:
		squads.append({"members": [], "stage": k % maxi(1, lv.stage_a.size()), "orders": Orders.empty_orders()})
	var picked := pool.slice(0, want)
	for k2 in picked.size():
		squads[k2 % n_sq]["members"].append(picked[k2]["id"])
	var stages: Array = Operation.stages(lv)
	match sit["type"]:
		"warrant", "barricade":
			var o1: Dictionary = squads[0]["orders"]
			o1["objs"] = [{"kind": "arrest"}]
			var pts := _points(squads[0], available)
			if n_sq > 1:
				var st: Vector2 = (stages[squads[0]["stage"]]["r"] as Rect2).get_center() if not stages.is_empty() else Vector2.ZERO
				var doors := exterior_doors(lv, st)
				squads[1]["orders"]["objs"] = [{"kind": "contain", "openings": doors.slice(1, 3) if doors.size() > 1 else doors}]
				# surround first, then go in
				if pts >= 1:
					o1["phase"] = {"kind": "squad", "squad": 1}
					pts -= 1
			if sit["type"] == "warrant" and pts >= 1:
				o1["knock"] = true
				pts -= 1
			if pts >= 1:
				o1["objs"].append({"kind": "clear", "rooms": []})
				pts -= 1
			if sit["type"] == "barricade" and pts >= 2:
				o1["tight"] = true
		"gang":
			squads[0]["orders"]["objs"] = [{"kind": "clear", "rooms": []}]
			if n_sq > 1:
				squads[1]["orders"]["objs"] = [{"kind": "clear", "rooms": []}]
		"hostage":
			var room := ""
			for f in sit["intel"]:
				if f["key"] == "hostage_room":
					room = f["room"] if f["known"] else f.get("room_est", "")
			squads[0]["orders"]["objs"] = [{"kind": "rescue", "rooms": [room] if room != "" else []}]
			if n_sq > 1:
				var st2: Vector2 = (stages[squads[0]["stage"]]["r"] as Rect2).get_center() if not stages.is_empty() else Vector2.ZERO
				var doors2 := exterior_doors(lv, st2)
				squads[1]["orders"]["objs"] = [{"kind": "contain", "openings": doors2.slice(1, 3) if doors2.size() > 1 else doors2}]
		"event":
			var sc: Vector2 = lv.get("stage_c") if lv.get("stage_c") != null else Vector2(lv.W / 2.0, lv.H / 3.0)
			squads[0]["orders"]["objs"] = [{"kind": "post", "p": [sc.x - 6.0, sc.y + 3.5], "face": PI / 2.0}]
			if n_sq > 1:
				squads[1]["orders"]["objs"] = [{"kind": "patrol", "route": [[17.0, 28.0], [17.0, 16.0], [47.5, 16.0], [47.5, 28.0], [32.0, 36.0]]}]
			if n_sq > 2:
				squads[2]["orders"]["objs"] = [{"kind": "post", "p": [sc.x + 6.0, sc.y + 3.5], "face": PI / 2.0}]
	# kit (v0.7.5): squads going in carry the entry kit (a ram on the point man, flashbangs
	# for those trained for them); the rest keep their own
	if sit["type"] != "event":
		var by_id := {}
		for r in available:
			by_id[r["id"]] = r
		for si in squads.size():
			var kinds: Array = squads[si]["orders"]["objs"].map(func(o): return o.get("kind", ""))
			if not (kinds.has("clear") or kinds.has("arrest") or kinds.has("rescue")):
				continue
			var spec: Dictionary = Equipment.SQUAD_KITS["entry"]
			var mem: Array = squads[si]["members"]
			for k in mem.size():
				var r2: Dictionary = by_id.get(mem[k], {})
				if not r2.is_empty():
					r2["kit"] = Equipment.validate(spec["point"] if k == 0 else spec["rest"], Equipment.who_of_record(r2))
	return {"squads": squads, "night": false, "bodycams": bodycams}


static func _points(sq: Dictionary, available: Array) -> int:
	var recs: Array = []
	for r in available:
		if sq["members"].has(r["id"]):
			recs.append(r)
	return Orders.points_for(recs)
