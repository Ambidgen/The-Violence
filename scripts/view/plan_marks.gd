extends Node2D
## The plan drawn on the floor plan (v0.7): stage areas and vehicles, each squad's
## formed-up officers, and its orders (rooms to clear, rooms to avoid, the room to
## consolidate, the entry door, contain posts, the post, the patrol route), plus what the
## briefing says about who is where. Greyscale like the rest of the plan; the selected
## squad is drawn dark, the others faint.
##
## Theory (v0.8, red ink): the selected squad's plan is one clean red line from the stage
## through the entry to each objective in turn, with numbered rings and an arrowhead. The
## model has no field for anything else.

const Operation = preload("res://scripts/campaign/operation.gd")
const PX := 40.0
const INK := Color("#141313")
const Ink = preload("res://scripts/view/ink.gd")

var level
var nav
var sit := {}
var plan := {}
var sel := 0
var pick := ""            # the map tool in use, shown as a hint near the cursor
var font: Font
var bold: Font
var _cache := {}          # squad index -> {"posts": [...]} for contain previews


func _ready() -> void:
	font = ThemeDB.fallback_font
	bold = ThemeDB.fallback_font


func setup(lv, nv, s: Dictionary, p: Dictionary) -> void:
	level = lv
	nav = nv
	sit = s
	plan = p
	_cache.clear()
	visible = true
	queue_redraw()


func clear() -> void:
	sit = {}
	plan = {}
	visible = false
	queue_redraw()


func changed() -> void:
	_cache.clear()
	queue_redraw()


func _r(r: Rect2) -> Rect2:
	return Rect2(r.position * PX, r.size * PX)


func _room_outline(rm: String, col: Color, wd: float, dashed: bool) -> void:
	if not level.rooms.has(rm):
		return
	for rv in level.rooms[rm]["rects"]:
		var r := _r((rv as Rect2).grow(-0.15))
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for k in 4:
			if dashed:
				draw_dashed_line(pts[k], pts[k + 1], col, wd, 8.0)
			else:
				draw_line(pts[k], pts[k + 1], col, wd)


func _room_hatch(rm: String, col: Color) -> void:
	if not level.rooms.has(rm):
		return
	for rv in level.rooms[rm]["rects"]:
		var r := _r((rv as Rect2).grow(-0.1))
		var s := -r.size.y
		while s < r.size.x:
			var t0 := maxf(0.0, -s)
			var t1 := minf(r.size.y, r.size.x - s)
			if t1 > t0:
				draw_line(r.position + Vector2(s + t0, t0), r.position + Vector2(s + t1, t1), col, 1.0)
			s += 14.0


func _label(p: Vector2, text: String, col: Color, size := 13) -> void:
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_rect(Rect2(p + Vector2(-w / 2.0 - 3, -size), Vector2(w + 6, size + 4)), Color(0.93, 0.93, 0.91, 0.85))
	draw_string(font, p + Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _draw() -> void:
	if level == null or sit.is_empty():
		return
	var stages: Array = Operation.stages(level)
	# stage areas
	for st in stages:
		var r := _r(st["r"])
		draw_rect(r, Color(0.07, 0.07, 0.07, 0.05))
		draw_rect(r, Color(0.07, 0.07, 0.07, 0.35), false, 1.0)
		_label(r.position + Vector2(r.size.x / 2.0, -4), "STAGE  %s" % String(st["name"]).to_upper(), Color(0.07, 0.07, 0.07, 0.6), 10)
	# what the briefing says about rooms
	for f in sit.get("intel", []):
		if not f.has("room"):
			continue
		var rm: String = f["room"] if f["known"] else f.get("room_est", "")
		if not level.rooms.has(rm):
			continue
		var lp: Vector2 = (level.rooms[rm]["label"] as Vector2) * PX + Vector2(0, 26)
		var tag: String = {"named_room": "SUSPECT", "hostage_room": "HOSTAGES"}.get(f["key"], "?")
		_label(lp, tag + ("  (tip)" if f["known"] else "  ?"), INK if f["known"] else Color(0.07, 0.07, 0.07, 0.55), 10)
	# squads
	var squads: Array = plan.get("squads", [])
	var taken: Array = []
	for si in squads.size():
		var sq: Dictionary = squads[si]
		var dark: bool = si == sel
		var col := INK if dark else Color(0.07, 0.07, 0.07, 0.35)
		var od: Dictionary = sq.get("orders", {})
		# formed up at the stage
		var n: int = sq.get("members", []).size()
		if n > 0 and not stages.is_empty():
			var stg: int = clampi(int(sq.get("stage", 0)), 0, stages.size() - 1)
			var pts: Array = Operation.stage_points(level, nav, stg, n, taken)
			for p in pts:
				draw_circle((p as Vector2) * PX, 9.0, Color(0.93, 0.93, 0.91, 0.9))
				draw_arc((p as Vector2) * PX, 9.0, 0.0, TAU, 16, col, 2.2 if dark else 1.2)
			if not pts.is_empty():
				_label((pts[0] as Vector2) * PX + Vector2(0, -12), "SQ%d" % (si + 1), col, 13)
		# objectives
		for oi in od.get("objs", []).size():
			var ob: Dictionary = od["objs"][oi]
			var tag2 := "SQ%d %s" % [si + 1, ("THEN " if oi > 0 else "")]
			match ob.get("kind", ""):
				"clear", "rescue":
					var rooms: Array = ob.get("rooms", [])
					for rm2 in rooms:
						_room_outline(rm2, col, 2.0 if dark else 1.0, true)
						_label((level.rooms[rm2]["label"] as Vector2) * PX + Vector2(0, -8),
							tag2 + ("CLEAR" if ob["kind"] == "clear" else "RESCUE"), col, 12)
				"contain":
					if not _cache.has(si):
						_cache[si] = {"posts": Operation.contain_posts(level, nav, ob.get("openings", []))}
					for oi2 in ob.get("openings", []):
						if int(oi2) < level.openings.size():
							var oc: Vector2 = level.openings[int(oi2)]["c"] * PX
							draw_rect(Rect2(oc - Vector2(6, 6), Vector2(12, 12)), col, false, 2.0)
					for pp in _cache[si]["posts"]:
						var q: Vector2 = (pp["p"] as Vector2) * PX
						draw_circle(q, 5.0, col)
						draw_line(q, q + Vector2.from_angle(pp["face"]) * 22.0, col, 1.5)
					if not _cache[si]["posts"].is_empty():
						_label((_cache[si]["posts"][0]["p"] as Vector2) * PX + Vector2(0, -10), tag2 + "CONTAIN", col, 12)
				"post":
					var pa = ob.get("p", null)
					if pa != null:
						var q2: Vector2 = Operation._v(pa) * PX
						draw_arc(q2, 12.0, 0.0, TAU, 20, col, 2.0)
						draw_line(q2, q2 + Vector2.from_angle(float(ob.get("face", 0.0))) * 30.0, col, 2.0)
						_label(q2 + Vector2(0, -16), tag2 + "POST", col, 12)
				"patrol":
					var route: Array = ob.get("route", [])
					var prev = null
					for k in route.size():
						var q3: Vector2 = Operation._v(route[k]) * PX
						if prev != null:
							draw_dashed_line(prev, q3, col, 1.6, 10.0)
						draw_circle(q3, 4.0, col)
						draw_string(font, q3 + Vector2(6, -6), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
						prev = q3
					if route.size() > 2:
						draw_dashed_line(prev, Operation._v(route[0]) * PX, col, 1.0, 10.0)
					if not route.is_empty():
						_label(Operation._v(route[0]) * PX + Vector2(0, -12), tag2 + "PATROL", col, 12)
		# constraints
		for rm3 in od.get("avoid", []):
			_room_hatch(rm3, Color(0.07, 0.07, 0.07, 0.35 if dark else 0.15))
			_label((level.rooms[rm3]["label"] as Vector2) * PX + Vector2(0, 8), "SQ%d AVOID" % (si + 1), col, 12)
		var cr: String = od.get("consolidate", "")
		if cr != "" and level.rooms.has(cr):
			_room_outline(cr, col, 3.0 if dark else 1.5, false)
			_label((level.rooms[cr]["label"] as Vector2) * PX + Vector2(0, 20), "SQ%d CONSOLIDATE" % (si + 1), col, 12)
		var en: String = od.get("entry", "")
		if en != "" and level.doors.has(en):
			var D: Dictionary = level.doors[en]
			var c: Vector2 = D["c"] * PX
			var into := ""
			for side in [D["a"], D["b"]]:
				if not level.is_exterior(side):
					into = side
			var nin: Vector2 = level.inward(en, into) if into != "" else D["n"]
			draw_line(c - nin * 40.0, c, col, 3.0)
			draw_line(c, c - nin * 12.0 + nin.orthogonal() * 8.0, col, 3.0)
			draw_line(c, c - nin * 12.0 - nin.orthogonal() * 8.0, col, 3.0)
			_label(c - nin * 48.0, "SQ%d ENTRY" % (si + 1), col, 12)
	if sel >= 0 and sel < squads.size():
		_route(sel, squads[sel], stages)
	if pick != "":
		_label(Vector2(level.W * PX / 2.0, -30), pick, INK, 13)


## The waypoints of a squad's plan: formed up, the entry (outside, inside), then each
## objective's first point.
func _waypoints(si: int, sq: Dictionary, stages: Array) -> Array:
	var wp: Array = []
	var od: Dictionary = sq.get("orders", {})
	var n: int = sq.get("members", []).size()
	if n <= 0 or stages.is_empty():
		return wp
	var stg: int = clampi(int(sq.get("stage", 0)), 0, stages.size() - 1)
	var pts: Array = Operation.stage_points(level, nav, stg, n, [])
	if pts.is_empty():
		return wp
	wp.append(pts[0])
	var en: String = od.get("entry", "")
	if en != "" and level.doors.has(en):
		var D: Dictionary = level.doors[en]
		var into := ""
		for side in [D["a"], D["b"]]:
			if not level.is_exterior(side):
				into = side
		var nin: Vector2 = level.inward(en, into) if into != "" else D["n"]
		wp.append((D["c"] as Vector2) - nin * 0.9)
		wp.append((D["c"] as Vector2) + nin * 0.9)
	for ob in od.get("objs", []):
		match ob.get("kind", ""):
			"clear", "rescue":
				for rm in ob.get("rooms", []):
					if level.rooms.has(rm):
						wp.append(level.rooms[rm]["label"])
			"contain":
				if _cache.has(si) and not _cache[si]["posts"].is_empty():
					wp.append(_cache[si]["posts"][0]["p"])
			"arrest":
				# the room the briefing puts him in (a tip or an estimate)
				for f in sit.get("intel", []):
					if f.get("key", "") == "named_room":
						var rm2: String = f.get("room", "") if f.get("known", false) else f.get("room_est", "")
						if level.rooms.has(rm2):
							wp.append(level.rooms[rm2]["label"])
			"post":
				if ob.get("p", null) != null:
					wp.append(Operation._v(ob["p"]))
			"patrol":
				if not ob.get("route", []).is_empty():
					wp.append(Operation._v(ob["route"][0]))
	return wp


func _route(si: int, sq: Dictionary, stages: Array) -> void:
	var key := "route%d" % si
	if not _cache.has(key):
		var wp := _waypoints(si, sq, stages)
		var line := PackedVector2Array()
		for k in range(1, wp.size()):
			var seg: PackedVector2Array = nav.find_path(0, wp[k - 1], wp[k]) if nav != null else PackedVector2Array()
			if seg.size() < 2:
				seg = PackedVector2Array([wp[k - 1], wp[k]])
			for q in seg:
				if line.is_empty() or line[line.size() - 1].distance_to(q) > 0.05:
					line.append(q)
		_cache[key] = {"wp": wp, "line": line}
	var c: Dictionary = _cache[key]
	var ln: PackedVector2Array = c["line"]
	if ln.size() < 2:
		return
	var px := PackedVector2Array()
	for q in ln:
		px.append(q * PX)
	draw_polyline(px, Ink.accent(0.85), 2.4, true)
	# arrowhead at the end
	var e := px[px.size() - 1]
	var u := (e - px[px.size() - 2]).normalized()
	draw_colored_polygon(PackedVector2Array([e + u * 4.0, e - u * 12.0 + u.orthogonal() * 7.0, e - u * 12.0 - u.orthogonal() * 7.0]), Ink.accent(0.9))
	# numbered rings at the waypoints (the number carries it with red off)
	var wp: Array = c["wp"]
	for k in wp.size():
		var q2: Vector2 = (wp[k] as Vector2) * PX
		draw_circle(q2, 9.0, Ink.PAPER)
		draw_arc(q2, 9.0, 0.0, TAU, 20, Ink.accent(0.9), 2.0)
		var t := str(k + 1)
		var tw: float = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, q2 + Vector2(-tw / 2.0, 4.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Ink.INK)
