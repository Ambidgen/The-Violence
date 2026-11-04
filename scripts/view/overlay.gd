extends Node2D
## Per-frame analysis overlays (bible section 9): vision cones, recognition bars,
## aim traverse arcs, planned paths, tracers, muzzle flashes and habit callouts.

const PX := 40.0
const Ink = preload("res://scripts/view/ink.gd")
const INK := Color("#141313")

var world
var show_cones := true
var show_rec := true
var show_aim := true
var show_paths := false
var tracers: Array = []   # {a, b, age}
var flashes: Array = []   # {p, dir, age}
var floats: Array = []    # {p, text, age}
var puffs: Array = []     # {p, age}
var ears: Array = []      # {id, dir, age}: someone just heard an enemy
var bursts: Array = []    # {p, age}: flashbangs going off (v0.7.5)
var lobs: Array = []      # {a, b, age}: flashbangs in the air
var wires: Array = []     # {a, b, hit, age}: taser darts and sponge rounds
var stops: Array = []     # {p, dir, age}: a shield or the helmet stopping a round
var view := Rect2()       # city: only draw what is in view
var zoom := 1.0
var fog = null            # v0.7: with the fog on, only officers' cones, aims and recognition show


func setup(w) -> void:
	world = w
	tracers.clear()
	flashes.clear()
	floats.clear()
	puffs.clear()
	ears.clear()
	bursts.clear()
	lobs.clear()
	wires.clear()
	stops.clear()


func handle(ev: Dictionary) -> void:
	match ev["type"]:
		"shot":
			tracers.append({"a": ev["from"], "b": ev["to"], "age": 0.0})
			flashes.append({"p": ev["from"], "dir": (ev["to"] - ev["from"]).angle(), "age": 0.0})
		"bad_on":
			var o = world.op_by_id(ev["id"])
			if o != null:
				_float(o.pos, "%s %s" % [ev["bad"], ev["name"].to_upper()])
		"impact":
			puffs.append({"p": ev["p"], "age": 0.0})
		"plate":
			_float(ev["p"], "plate")
		"float":
			_float(ev["p"], ev["text"])
		"heard":
			var o2 = world.op_by_id(ev["id"])
			if o2 != null:
				ears.append({"id": ev["id"], "dir": (ev["p"] - o2.pos).angle(), "age": 0.0})
		"flash":
			bursts.append({"p": ev["p"], "age": 0.0, "sting": ev.get("kind", "") == "sting"})
		"throw":
			lobs.append({"a": ev["from"], "b": ev["to"], "age": 0.0})
		"less":
			wires.append({"a": ev["from"], "b": ev["to"], "hit": ev["hit"], "age": 0.0, "tool": ev.get("tool", "taser")})
		"shield", "helmet":
			stops.append({"p": ev["p"], "dir": (ev["dir"] as Vector2).angle() + PI, "age": 0.0, "head": ev["type"] == "helmet"})


## Stack labels that appear near the same spot so they never print over each other.
func _float(p: Vector2, text: String) -> void:
	var near: Array = []
	for f in floats:
		if f["p"].distance_to(p) < 1.5:
			near.append(f)
	if near.size() >= 4:
		floats.erase(near[0])
		near.remove_at(0)
	var used := {}
	for f in near:
		used[f["slot"]] = true
	var slot := 0
	while used.has(slot):
		slot += 1
	floats.append({"p": p, "text": text, "age": 0.0, "slot": slot})


func tick_real(dt: float) -> void:
	for arr in [tracers, flashes, floats, puffs, ears, bursts, lobs, wires, stops]:
		for it in arr:
			it["age"] += dt
	tracers = tracers.filter(func(x): return x["age"] < 0.18)
	flashes = flashes.filter(func(x): return x["age"] < 0.07)
	floats = floats.filter(func(x): return x["age"] < 1.8)
	puffs = puffs.filter(func(x): return x["age"] < 0.4)
	ears = ears.filter(func(x): return x["age"] < 1.2)
	bursts = bursts.filter(func(x): return x["age"] < 0.6)
	lobs = lobs.filter(func(x): return x["age"] < 1.3)
	wires = wires.filter(func(x): return x["age"] < 1.0)
	stops = stops.filter(func(x): return x["age"] < 0.35)
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var font: Font = ThemeDB.fallback_font
	var cull: bool = world.city
	var vr := view.grow(300.0)
	for o in world.ops:
		if not o.alive() or o.mounted != null:
			continue
		var p: Vector2 = o.pos * PX
		if cull and (not vr.has_point(p) or zoom < 0.3 or o.medic):
			continue
		if o.civ or o.complying:
			continue
		if fog != null and fog.enabled and not o.judges:
			continue
		if show_cones:
			var half: float = world.cone_half(o)
			var r := 7.0 * PX
			var pts := PackedVector2Array([p])
			for k in 25:
				var a: float = o.look_dir - half + 2.0 * half * k / 24.0
				pts.append(p + Vector2.from_angle(a) * r)
			draw_colored_polygon(pts, Color(0.07, 0.07, 0.07, 0.028 if o.team == 0 else 0.04))
			for k in [0, 24]:
				draw_line(p, pts[k + 1], Color(0.07, 0.07, 0.07, 0.18), 1.0)
			for a2 in [deg_to_rad(30.0), deg_to_rad(45.0)]:
				if a2 < half:
					for sgn in [-1.0, 1.0]:
						draw_dashed_line(p, p + Vector2.from_angle(o.look_dir + a2 * sgn) * r * 0.6, Color(0.07, 0.07, 0.07, 0.12), 1.0, 4.0)
		if show_paths and o.moving and o.path.size() > 0:
			var last := p
			for k in range(o.path_i, o.path.size()):
				var q: Vector2 = o.path[k] * PX
				draw_dashed_line(last, q, Color(0.07, 0.07, 0.07, 0.35), 1.0, 5.0)
				last = q
		if show_aim and not o.aim.is_empty():
			var e = world.op_by_id(o.aim["tid"])
			if e != null:
				var ep: Vector2 = e.pos * PX
				if not o.aim["on"]:
					var b: float = (e.pos - o.pos).angle()
					var a0: float = o.muzzle_dir
					draw_arc(p, 26.0, a0, a0 + angle_difference(a0, b), 12, INK, 1.4, true)
					draw_string(font, p + Vector2(14, -18), "%d ms" % int(o.aim["acq_left"] * 1000.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
				else:
					draw_dashed_line(p + Vector2.from_angle(o.muzzle_dir) * 20.0, ep, Color(0.07, 0.07, 0.07, 0.28), 1.0, 3.0)
	if show_rec:
		# one bar per target: the enemy closest to recognizing it, plus how many others are on it
		var best_on := {}
		for o in world.ops:
			if not o.alive():
				continue
			if fog != null and fog.enabled and not o.judges:
				continue
			for eid in o.rec:
				if fog != null and fog.enabled and not fog.visible_ids.has(eid):
					continue
				var rv: float = o.rec[eid]
				if rv <= 0.02:
					continue
				var cur: Array = best_on.get(eid, [null, 0.02, 0])
				cur[2] += 1
				if rv > cur[1]:
					cur[0] = o
					cur[1] = rv
				best_on[eid] = cur
		for eid2 in best_on:
			var e = world.op_by_id(eid2)
			var bo: Array = best_on[eid2]
			if e == null or not e.alive() or bo[0] == null:
				continue
			if cull and (zoom < 0.3 or not vr.has_point(e.pos * PX)):
				continue
			var bv: float = bo[1]
			var base: Vector2 = e.pos * PX + Vector2(-14, -40)
			draw_rect(Rect2(base, Vector2(28, 4)), Color(0.93, 0.93, 0.91, 0.9))
			draw_rect(Rect2(base, Vector2(28 * minf(bv, 1.0), 4)), INK if bv >= 1.0 else Color("#6e675c"))
			draw_rect(Rect2(base, Vector2(28, 4)), INK, false, 1.0)
			var tag: String = bo[0].id + ("" if bo[2] <= 1 else " +%d" % (bo[2] - 1))
			draw_string(font, base + Vector2(30, 5), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
	for tr in tracers:
		var al: float = 1.0 - tr["age"] / 0.18
		draw_line(tr["a"] * PX, tr["b"] * PX, Color(0.07, 0.07, 0.07, 0.55 * al), 1.0, true)
	for f in flashes:
		var c: Vector2 = f["p"] * PX
		var pts2 := PackedVector2Array()
		for i in 10:
			var a3: float = f["dir"] + i * TAU / 10.0
			pts2.append(c + Vector2.from_angle(a3) * (9.0 if i % 2 == 0 else 3.5))
		draw_colored_polygon(pts2, Color(0.93, 0.93, 0.91))
		pts2.append(pts2[0])
		draw_polyline(pts2, INK, 1.0)
	for ea in ears:
		var lo = world.op_by_id(ea["id"])
		if lo == null or not lo.alive():
			continue
		var al: float = 1.0 - ea["age"] / 1.2
		for k2 in 3:
			draw_arc(lo.pos * PX, 16.0 + 5.0 * k2, ea["dir"] - 0.45, ea["dir"] + 0.45, 6, Color(0.17, 0.17, 0.17, 0.55 * al), 1.0)
	for pf in puffs:
		draw_arc(pf["p"] * PX, 3.0 + 14.0 * pf["age"], 0, TAU, 14, Color(0.17, 0.17, 0.17, 0.5 * (1.0 - pf["age"] / 0.4)), 1.0)
	_draw_kit_fx()
	for fl in floats:
		var a4: float = clampf(1.6 - fl["age"], 0.0, 1.0)
		var pos: Vector2 = fl["p"] * PX + Vector2(-30, -48 - 14 * fl["slot"])
		draw_string(font, pos + Vector2(1, 1), fl["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.93, 0.93, 0.91, a4))
		draw_string(font, pos, fl["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.07, 0.07, 0.07, a4))


## Entry tools and protection (v0.7.5), drawn above everything else.
func _draw_kit_fx() -> void:
	_draw_gas()
	for l in lobs:
		# the flashbang's arc, a dot travelling along it
		var a: Vector2 = l["a"] * PX
		var b: Vector2 = l["b"] * PX
		var mid: Vector2 = (a + b) * 0.5 + (b - a).orthogonal().normalized() * 18.0
		var pts := PackedVector2Array()
		for k in 9:
			var f: float = k / 8.0
			pts.append(a.lerp(mid, f).lerp(mid.lerp(b, f), f))
		draw_polyline(pts, Color(0.07, 0.07, 0.07, 0.35), 1.0)
		var ft: float = clampf(l["age"] / 0.4, 0.0, 1.0)
		draw_circle(a.lerp(mid, ft).lerp(mid.lerp(b, ft), ft), 3.5, INK)
	for bz in bursts:
		var c: Vector2 = bz["p"] * PX
		var f2: float = 1.0 - bz["age"] / 0.6
		if bz.get("sting", false):
			# a sting-ball: a ring of rubber pellets flying out
			var rs: float = (0.4 + 4.6 * (1.0 - f2)) * PX
			for k3 in 24:
				var an3: float = TAU * k3 / 24.0 + 0.21 * (k3 % 3)
				draw_circle(c + Vector2.from_angle(an3) * rs * (0.8 + 0.2 * ((k3 * 7) % 5) / 4.0), 1.8, Color(0.07, 0.07, 0.07, 0.85 * f2))
			draw_circle(c, 0.35 * PX, Color(0.07, 0.07, 0.07, 0.5 * f2))
			continue
		var r: float = (0.6 + 1.6 * (1.0 - f2)) * PX
		draw_circle(c, r, Color(0.93, 0.93, 0.91, 0.85 * f2))
		draw_arc(c, r, 0.0, TAU, 32, Color(0.07, 0.07, 0.07, 0.7 * f2), 1.5)
		for k2 in 12:
			var an: float = TAU * k2 / 12.0 + 0.13
			draw_line(c + Vector2.from_angle(an) * r * 0.55, c + Vector2.from_angle(an) * r * 1.25, Color(0.07, 0.07, 0.07, 0.6 * f2), 1.2)
	for wv in wires:
		var al: float = 1.0 - wv["age"]
		var tool: String = wv.get("tool", "taser")
		if tool in ["oc_spray", "pepperball"]:
			# a spray: a widening stream of droplets, a cloud where it lands
			var a5: Vector2 = wv["a"] * PX
			var b5: Vector2 = wv["b"] * PX
			var dv: Vector2 = (b5 - a5)
			for k5 in 14:
				var f5: float = (k5 + 1) / 14.0
				var off: Vector2 = dv.orthogonal().normalized() * sin(k5 * 2.3) * 5.0 * f5
				draw_circle(a5 + dv * f5 + off, 1.2 + 0.6 * f5, Ink.accent(0.6 * al))
			if wv["hit"]:
				for k6 in 10:
					draw_circle(b5 + Vector2.from_angle(k6 * 0.63) * (4.0 + 3.0 * (k6 % 3)), 2.0, Ink.accent(0.35 * al))
			continue
		if tool == "baton":
			var b7: Vector2 = wv["b"] * PX
			var an7: float = (wv["b"] - wv["a"]).angle()
			draw_arc(wv["a"] * PX, (wv["b"] - wv["a"]).length() * PX, an7 - 0.6, an7 + 0.6, 8, Color(0.07, 0.07, 0.07, 0.8 * al), 2.0)
			if wv["hit"]:
				draw_circle(b7, 4.0, Color(0.07, 0.07, 0.07, 0.8 * al))
			continue
		draw_dashed_line(wv["a"] * PX, wv["b"] * PX, Color(0.07, 0.07, 0.07, 0.7 * al), 1.0, 3.0)
		if wv["hit"]:
			draw_circle(wv["b"] * PX, 4.0, Color(0.07, 0.07, 0.07, 0.8 * al))
	for st in stops:
		var p: Vector2 = st["p"] * PX
		var al2: float = 1.0 - st["age"] / 0.35
		var rr: float = 9.0 if st["head"] else 14.0
		draw_arc(p, rr, st["dir"] - 0.9, st["dir"] + 0.9, 10, Color(0.07, 0.07, 0.07, 0.9 * al2), 2.5)


## CS gas (v0.8): a halftone haze of dots over every gassed room (or a cloud in the open),
## thinning as it clears.
func _draw_gas() -> void:
	if world == null or world.clouds.is_empty():
		return
	for c in world.clouds:
		var left: float = float(c["until"]) - world.t
		var thick: float = clampf(left / 20.0, 0.0, 1.0) * clampf((world.t - float(c.get("t0", world.t))) / 2.0 + 0.3, 0.0, 1.0)
		var col := Color(0.17, 0.17, 0.17, 0.55 * thick)
		var rects: Array = []
		if c["room"] != "" and world.level.rooms.has(c["room"]):
			rects = world.level.rooms[c["room"]]["rects"]
		else:
			var r: float = float(c["r"])
			rects = [Rect2(c["p"] - Vector2(r, r), Vector2(r, r) * 2.0)]
		for rc in rects:
			var rr: Rect2 = rc
			var step := 0.35
			var y: float = rr.position.y + step * 0.5
			var row := 0
			while y < rr.end.y:
				var x: float = rr.position.x + step * (0.25 if row % 2 == 0 else 0.75)
				while x < rr.end.x:
					var q := Vector2(x, y)
					if c["room"] != "" or q.distance_to(c["p"]) <= float(c["r"]):
						var wob: float = 0.5 + 0.5 * sin(x * 3.1 + y * 2.3 + world.t * 0.8)
						draw_circle(q * PX, 2.2 + 2.4 * wob, col)
					x += step
				y += step
				row += 1
