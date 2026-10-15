extends RefCounted
## Test Range 01: a shotgun house in a fenced yard.
## Adapted from the 14x32 ft shotgun-house sketch, scaled up to 5 x 13 m so two-person
## teams can move through it, and laid on its side: the street and porch are west,
## the back door is east. Rooms run front to back: living & guest room, kitchen with
## the bathroom off it, bedroom. Every door sits on one line, the "shotgun" line.
## All units are metres; y grows downward (south).

const Geom = preload("res://scripts/sim/geom.gd")

const W := 36.0
const H := 24.0

var geom: Geom
var props: Array = []        # [{key, r: Rect2, rot: deg}] sprites to draw
var windows: Array = []      # [{r: Rect2, axis: "h"|"v"}]
var walls: Array = []        # indices of obstacles drawn as walls (poche)
var doors := {}              # id -> {id, c, n, t, half, a, b, hinge_sign}
var rooms := {}              # name -> {rects: [Rect2], label: Vector2, title}
var openings: Array = []     # [{c, out, kind, vps: [Vector2]}] for exposure and scanning
var corners: Array = []      # [{p, room}] room corners for eye discipline
var decor: Array = []        # [{type, ...}] drawing-only items (paths, driveway, canopies)
var spawns := {}             # "A1" -> {p, face}
var plans := {}              # "front"/"back" -> Array of steps
var patrol: Array = []       # yard and house waypoints for hunting


func build() -> void:
	geom = Geom.new()
	geom.setup(W, H)
	_fence()
	_house()
	_furniture()
	_yard()
	geom.build_index()
	_annotate()


# ------------------------------------------------------------------ helpers
func _wall(r: Rect2, name := "wall") -> void:
	walls.append(geom.add(r, Geom.WALL, 3.0, name))


## Horizontal wall along y from x0 to x1 with gaps [[a, b, "door"|"window"], ...].
func _hwall(x0: float, x1: float, y: float, t: float, gaps: Array) -> void:
	var x := x0
	for g in gaps:
		if g[0] > x:
			_wall(Rect2(x, y - t / 2, g[0] - x, t))
		if g[2] == "window":
			var r := Rect2(g[0], y - t / 2, g[1] - g[0], t)
			geom.add(r, Geom.WINDOW, 0.0, "window", true, 0.9, 2.1)
			windows.append({"r": r, "axis": "h"})
		x = g[1]
	if x1 > x:
		_wall(Rect2(x, y - t / 2, x1 - x, t))


func _vwall(y0: float, y1: float, x: float, t: float, gaps: Array) -> void:
	var y := y0
	for g in gaps:
		if g[0] > y:
			_wall(Rect2(x - t / 2, y, t, g[0] - y))
		if g[2] == "window":
			var r := Rect2(x - t / 2, g[0], t, g[1] - g[0])
			geom.add(r, Geom.WINDOW, 0.0, "window", true, 0.9, 2.1)
			windows.append({"r": r, "axis": "v"})
		y = g[1]
	if y1 > y:
		_wall(Rect2(x - t / 2, y, t, y1 - y))


func _prop(key: String, r: Rect2, kind: int, h: float, rot := 0.0, name := "") -> void:
	if kind >= 0:
		geom.add(r, kind, h, name if name != "" else key)
	if key != "":
		props.append({"key": key, "r": r, "rot": rot})


func _trunk(c: Vector2, canopy := 3.6) -> void:
	geom.add(Rect2(c - Vector2(0.22, 0.22), Vector2(0.44, 0.44)), Geom.WALL, 6.0, "tree trunk")
	props.append({"key": "yard/tree", "r": Rect2(c - Vector2(canopy, canopy) / 2, Vector2(canopy, canopy)), "rot": 0.0, "under": true})


# ------------------------------------------------------------------ build
func _fence() -> void:
	var t := 0.12
	_wall(Rect2(0, 0, W, t), "fence")
	_wall(Rect2(0, H - t, W, t), "fence")
	_wall(Rect2(0, 0, t, H), "fence")
	_wall(Rect2(W - t, 0, t, H), "fence")


func _house() -> void:
	var e := 0.22  # exterior wall thickness
	var p := 0.12  # partitions
	# exterior: north (y 9.5) and south (y 14.5) long walls
	_hwall(11.89, 25.11, 9.5, e, [[13.2, 15.0, "window"], [19.6, 20.6, "window"], [22.0, 23.6, "window"]])
	_hwall(11.89, 25.11, 14.5, e, [[13.4, 15.2, "window"], [18.2, 19.6, "window"], [22.2, 23.8, "window"]])
	# front (west, x 12) and back (east, x 25) walls, doors on the shotgun line y 12.9-13.8
	_vwall(9.61, 14.39, 12.0, e, [[10.1, 11.5, "window"], [12.9, 13.8, "door"]])
	_vwall(9.61, 14.39, 25.0, e, [[10.2, 11.6, "window"], [12.9, 13.8, "door"]])
	# partitions on the same line
	_vwall(9.61, 14.39, 17.0, p, [[12.9, 13.8, "door"]])
	_vwall(9.61, 14.39, 21.0, p, [[12.9, 13.8, "door"]])
	# bathroom off the kitchen
	_vwall(9.61, 11.96, 19.2, p, [])
	_hwall(17.06, 19.26, 11.9, p, [[17.25, 18.05, "door"]])
	# porch: railings (wood spindles: concealment, not cover) and corner posts
	_prop("", Rect2(10.0, 9.45, 1.89, 0.08), Geom.CONCEAL, 0.95, 0.0, "porch rail")
	_prop("", Rect2(10.0, 14.47, 1.89, 0.08), Geom.CONCEAL, 0.95, 0.0, "porch rail")
	_prop("", Rect2(9.98, 9.45, 0.08, 3.1), Geom.CONCEAL, 0.95, 0.0, "porch rail")
	_prop("", Rect2(9.98, 14.15, 0.08, 0.4), Geom.CONCEAL, 0.95, 0.0, "porch rail")
	for c in [Vector2(10.02, 9.49), Vector2(10.02, 14.51), Vector2(10.02, 12.55), Vector2(10.02, 14.15)]:
		_wall(Rect2(c - Vector2(0.09, 0.09), Vector2(0.18, 0.18)), "porch post")

	doors["FRONT"] = _door("FRONT", Vector2(12.0, 13.35), Vector2(1, 0), 0.45, "OUT", "LIVING", 1)
	doors["LK"] = _door("LK", Vector2(17.0, 13.35), Vector2(1, 0), 0.45, "LIVING", "KITCHEN", 1)
	doors["KB"] = _door("KB", Vector2(21.0, 13.35), Vector2(1, 0), 0.45, "KITCHEN", "BEDROOM", 1)
	doors["BACK"] = _door("BACK", Vector2(25.0, 13.35), Vector2(1, 0), 0.45, "BEDROOM", "OUT", -1)
	doors["BATH"] = _door("BATH", Vector2(17.65, 11.9), Vector2(0, -1), 0.40, "KITCHEN", "BATH", 1)

	rooms["LIVING"] = {"rects": [Rect2(12, 9.5, 5, 5)], "label": Vector2(14.5, 12.25), "title": "LIVING & GUEST RM"}
	rooms["KITCHEN"] = {"rects": [Rect2(19.2, 9.5, 1.8, 2.4), Rect2(17, 11.9, 4, 2.6)], "label": Vector2(18.45, 14.05), "title": "KITCHEN"}
	rooms["BATH"] = {"rects": [Rect2(17, 9.5, 2.2, 2.4)], "label": Vector2(18.35, 11.55), "title": "BATH"}
	rooms["BEDROOM"] = {"rects": [Rect2(21, 9.5, 4, 5)], "label": Vector2(23.0, 11.75), "title": "BEDROOM"}
	rooms["PORCH"] = {"rects": [Rect2(10, 9.5, 2, 5)], "label": Vector2(11.0, 10.4), "title": "PORCH", "exterior": true}


func _door(id: String, c: Vector2, n: Vector2, half: float, a: String, b: String, hinge_sign: int) -> Dictionary:
	return {"id": id, "c": c, "n": n, "t": Vector2(-n.y, n.x), "half": half, "a": a, "b": b, "hinge": hinge_sign}


func _furniture() -> void:
	# living & guest room
	_prop("furn/sofa", Rect2(13.0, 9.62, 2.2, 0.85), Geom.CONCEAL, 0.85)
	_prop("furn/armchair", Rect2(15.7, 9.66, 0.85, 0.85), Geom.CONCEAL, 0.85)
	_prop("furn/coffee_table", Rect2(13.5, 10.9, 1.2, 0.6), Geom.LOW, 0.45)
	_prop("furn/bookshelf", Rect2(15.3, 13.98, 1.6, 0.4), Geom.CONCEAL, 1.8, 0.0, "bookshelf")
	# kitchen
	_prop("furn/counter", Rect2(19.32, 9.62, 1.6, 0.6), Geom.COVER, 0.92, 0.0, "counter")
	_prop("furn/fridge", Rect2(20.24, 10.3, 0.68, 0.7), Geom.COVER, 1.8, 0.0, "fridge")
	_prop("furn/dining", Rect2(19.3, 11.95, 1.1, 0.8), Geom.LOW, 0.75)
	# bath
	_prop("furn/tub", Rect2(17.08, 9.62, 1.6, 0.72), Geom.COVER, 0.55, 0.0, "cast-iron tub")
	_prop("furn/toilet", Rect2(18.5, 10.75, 0.65, 0.5), Geom.LOW, 0.4, 90.0)
	_prop("furn/basin", Rect2(18.72, 9.66, 0.42, 0.55), Geom.LOW, 0.85, 90.0)
	# bedroom
	_prop("furn/bed", Rect2(22.7, 9.62, 2.0, 1.6), Geom.CONCEAL, 0.6)
	_prop("furn/dresser", Rect2(21.15, 9.64, 1.2, 0.5), Geom.COVER, 1.0, 0.0, "dresser")
	_prop("furn/wardrobe", Rect2(23.95, 13.93, 0.95, 0.45), Geom.COVER, 2.0, 0.0, "wardrobe")


func _yard() -> void:
	# front yard (west, street side)
	_prop("yard/car", Rect2(3.8, 16.2, 4.4, 1.9), Geom.COVER, 1.45, 0.0, "car")
	_prop("yard/low_wall", Rect2(2.2, 6.6, 3.0, 0.4), Geom.COVER, 1.0, 0.0, "brick wall")
	_prop("yard/hedge", Rect2(0.6, 1.6, 0.8, 3.6), Geom.CONCEAL, 1.7, 0.0, "hedge")
	_prop("yard/drum", Rect2(7.6, 6.8, 0.6, 0.6), Geom.COVER, 0.9, 0.0, "oil drum")
	_trunk(Vector2(4.6, 11.4))
	# north side yard
	_trunk(Vector2(15.4, 4.2), 4.0)
	_prop("yard/low_wall", Rect2(18.6, 6.0, 3.0, 0.4), Geom.COVER, 1.0, 0.0, "brick wall")
	_prop("yard/drum", Rect2(22.4, 4.8, 0.6, 0.6), Geom.COVER, 0.9, 0.0, "oil drum")
	_prop("yard/drum", Rect2(23.1, 5.2, 0.6, 0.6), Geom.COVER, 0.9, 0.0, "oil drum")
	_prop("yard/picnic", Rect2(26.6, 6.6, 1.8, 1.6), Geom.LOW, 0.75)
	# south side yard
	_prop("yard/ac_unit", Rect2(19.3, 14.64, 0.8, 0.6), Geom.COVER, 0.9, 0.0, "AC unit")
	_prop("yard/bins", Rect2(23.0, 14.66, 0.8, 0.6), Geom.CONCEAL, 1.1, 0.0, "plastic bins")
	_prop("yard/low_wall", Rect2(14.0, 19.0, 3.0, 0.4), Geom.COVER, 1.0, 0.0, "brick wall")
	_trunk(Vector2(21.6, 20.2))
	# back yard (east)
	_prop("yard/shed", Rect2(30.0, 2.0, 3.5, 3.0), Geom.WALL, 2.4, 0.0, "shed")
	_prop("yard/woodpile", Rect2(28.0, 16.6, 2.0, 0.8), Geom.COVER, 1.1, 0.0, "woodpile")
	_prop("yard/drum", Rect2(32.0, 17.4, 0.6, 0.6), Geom.COVER, 0.9, 0.0, "oil drum")
	_prop("yard/drum", Rect2(32.7, 17.9, 0.6, 0.6), Geom.COVER, 0.9, 0.0, "oil drum")
	_prop("yard/hedge", Rect2(34.6, 8.4, 0.8, 3.6), Geom.CONCEAL, 1.7, 0.0, "hedge")
	_prop("yard/low_wall", Rect2(29.4, 10.8, 0.4, 3.0), Geom.COVER, 1.0, 90.0, "brick wall")
	_trunk(Vector2(32.8, 14.2))
	# drawing-only: front walk, driveway, back step
	decor.append({"type": "dash_rect", "r": Rect2(2.6, 15.6, 7.2, 3.1)})
	decor.append({"type": "dash_rect", "r": Rect2(0.15, 12.6, 9.8, 1.5)})
	decor.append({"type": "rect", "r": Rect2(25.11, 12.75, 0.6, 1.2)})


# ------------------------------------------------------------------ annotation
func _annotate() -> void:
	# openings: windows look out; exterior doors look out; interior doors both ways
	for w in windows:
		var r: Rect2 = w["r"]
		var c := r.get_center()
		var outward := _outward(c, w["axis"])
		openings.append({"c": c, "out": outward, "kind": "window", "vps": [c - outward * 1.2]})
	for id in doors:
		var d: Dictionary = doors[id]
		var vps := [d["c"] + d["n"] * 1.2, d["c"] - d["n"] * 1.2]
		openings.append({"c": d["c"], "out": d["n"], "kind": "door", "id": id, "vps": vps})
	for name in rooms:
		if rooms[name].get("exterior", false):
			continue
		for rv in rooms[name]["rects"]:
			var r: Rect2 = rv
			for k in 4:
				var p: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][k]
				var inset: Vector2 = (r.get_center() - p).normalized() * 0.35
				if room_at(p + inset) == name:
					corners.append({"p": p + inset, "room": name})
	# Default posts. Team A forms up on the front walk; team B is spread through
	# the house (kitchen, bedroom, living room, bathroom) with one in the back yard.
	spawns = {
		"A1": {"p": Vector2(3.0, 13.0), "face": 0.0},
		"A2": {"p": Vector2(3.0, 14.3), "face": 0.0},
		"A3": {"p": Vector2(1.8, 13.0), "face": 0.0},
		"A4": {"p": Vector2(1.8, 14.3), "face": 0.0},
		"A5": {"p": Vector2(0.75, 13.65), "face": 0.0},
		"B1": {"p": Vector2(20.2, 13.2), "face": PI},
		"B2": {"p": Vector2(24.1, 12.2), "face": PI},
		"B3": {"p": Vector2(15.8, 11.3), "face": PI},
		"B4": {"p": Vector2(17.6, 11.0), "face": PI / 2.0},
		"B5": {"p": Vector2(29.2, 18.0), "face": -2.3},
	}
	plans["front"] = [
		{"door": "FRONT", "into": "LIVING"}, {"door": "LK", "into": "KITCHEN"},
		{"door": "BATH", "into": "BATH", "check": true}, {"door": "KB", "into": "BEDROOM"}]
	plans["back"] = [
		{"door": "BACK", "into": "BEDROOM"}, {"door": "KB", "into": "KITCHEN"},
		{"door": "BATH", "into": "BATH", "check": true}, {"door": "LK", "into": "LIVING"}]
	patrol = [Vector2(8.5, 12.0), Vector2(14.5, 12.4), Vector2(19.6, 13.4), Vector2(23.4, 12.4),
		Vector2(27.5, 12.5), Vector2(27.0, 18.5), Vector2(18.0, 17.0), Vector2(8.0, 20.0),
		Vector2(8.0, 4.0), Vector2(20.0, 3.5), Vector2(31.0, 8.0)]


func _outward(c: Vector2, axis: String) -> Vector2:
	var house := Rect2(12, 9.5, 13, 5)
	if axis == "h":
		return Vector2(0, -1) if c.y < house.get_center().y else Vector2(0, 1)
	return Vector2(-1, 0) if c.x < house.get_center().x else Vector2(1, 0)


func room_at(p: Vector2) -> String:
	for name in rooms:
		for r in rooms[name]["rects"]:
			if r.has_point(p):
				return name
	return "OUT"


## Interior rooms seat 2-4 entering operators (about 4.5 m2 each); the rest of a
## five-person team holds outside as rear security.
func room_capacity(name: String) -> int:
	var area := 0.0
	for r in rooms[name]["rects"]:
		area += (r as Rect2).get_area()
	return clampi(int(area / 4.5), 2, 4)


func is_inside(p: Vector2) -> bool:
	var rm := room_at(p)
	return rm != "OUT" and rm != "PORCH"


## Inward direction of a door when entering room `into`.
func inward(door_id: String, into: String) -> Vector2:
	var d: Dictionary = doors[door_id]
	return d["n"] if d["b"] == into else -d["n"]


## The room on the other side of a door from `into`.
func from_room(door_id: String, into: String) -> String:
	var d: Dictionary = doors[door_id]
	return d["a"] if d["b"] == into else d["b"]


## Distance from point p (inside a room rect) to that rect's edge along dir.
func extent_along(p: Vector2, dir: Vector2) -> float:
	for name in rooms:
		for r in rooms[name]["rects"]:
			if r.grow(0.01).has_point(p):
				var best := 99.0
				if dir.x > 0.01:
					best = minf(best, (r.end.x - p.x) / dir.x)
				if dir.x < -0.01:
					best = minf(best, (r.position.x - p.x) / dir.x)
				if dir.y > 0.01:
					best = minf(best, (r.end.y - p.y) / dir.y)
				if dir.y < -0.01:
					best = minf(best, (r.position.y - p.y) / dir.y)
				return best
	return 2.0
