extends Node2D
## Persistent marks left on the plan (v0.8, red ink). Blood is red ink and nothing more:
## flat, hard-edged, small. Per person at most one pool (when they go down), one broken
## drag trail (where they bled while moving), a handful of flecks and one contact smear
## where a hit met a wall. No sprays, no wounds. Each fallen person gets a numbered
## evidence marker beside the pool; with gore off (F3) the stains go and the markers stay.
## Bullet chips, spent casings and plate scuffs are neutral ink.
##
## This node sits under the walls (blood slides under a wall and stops at its face); the
## evidence markers draw on their own layer above the actors.

const Geom = preload("res://scripts/sim/geom.gd")
const Ink = preload("res://scripts/view/ink.gd")
const PX := 40.0
const SVG_SCALE := 0.5          # SVGs are authored at 80 px/m; the world is 40 px/m
const MAX_MARKS := 2200
const MAX_FLECKS := 7           # per person
const TRAIL_STEP := 0.3         # m between trail points
const TRAIL_MAX := 36           # points per person

static var _tex := {}

var world
var rng := RandomNumberGenerator.new()
var fog = null                  # v0.7: marks made out of every camera's view stay hidden until one sees them
var fog_hidden: Array = []
## id -> {pool: {p, t0, full, shape}, flecks: [[p, r, seen]], smear: [a, b, seen] or [],
##        trail: [[p, seen]], marker: int, seen_pool}
var stains := {}
var _markers := 0
var _stain_layer: Node2D
var _marker_layer: Node2D
var _rev := -1


static func tex(key: String) -> Texture2D:
	if not _tex.has(key):
		_tex[key] = load("res://assets/svg/%s.svg" % key)
	return _tex[key]


func _ready() -> void:
	_stain_layer = Stains.new()
	_stain_layer.d = self
	add_child(_stain_layer)
	_marker_layer = Markers.new()
	_marker_layer.d = self
	_marker_layer.z_index = 4
	add_child(_marker_layer)


func _clear() -> void:
	fog_hidden.clear()
	for c in get_children():
		if c != _stain_layer and c != _marker_layer:
			c.queue_free()
	stains.clear()
	_markers = 0
	_redraw()


func setup_empty() -> void:
	world = null
	fog = null
	_clear()


func setup(w) -> void:
	world = w
	fog = null
	rng.seed = w.seed_used + 77
	_clear()


func _redraw() -> void:
	if _stain_layer != null:
		_stain_layer.queue_redraw()
		_marker_layer.queue_redraw()


func _seen(p_m: Vector2) -> bool:
	return fog == null or not fog.enabled or fog.visible_at(p_m)


func _fogged(s: Node2D, p_m: Vector2) -> void:
	if not _seen(p_m):
		s.visible = false
		fog_hidden.append(s)


## Show the hidden marks a camera now sees (or all of them, when the fog lifts).
func reveal(all := false) -> void:
	var keep: Array = []
	for s in fog_hidden:
		if not is_instance_valid(s):
			continue
		if all or _seen(s.position / PX):
			s.visible = true
		else:
			keep.append(s)
	fog_hidden = keep
	var changed := false
	for id in stains:
		var st: Dictionary = stains[id]
		if not st["pool"].is_empty() and not st["pool"]["seen"] and (all or _seen(st["pool"]["p"])):
			st["pool"]["seen"] = true
			changed = true
		for f in st["flecks"]:
			if not f[2] and (all or _seen(f[0])):
				f[2] = true
				changed = true
		if not st["smear"].is_empty() and not st["smear"][2] and (all or _seen(st["smear"][0])):
			st["smear"][2] = true
			changed = true
		for tp in st["trail"]:
			if not tp[1] and (all or _seen(tp[0])):
				tp[1] = true
				changed = true
	if changed:
		_redraw()


func _sprite(key: String, p_m: Vector2, rot: float, scale_f: float, alpha := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(key)
	s.position = p_m * PX
	s.rotation = rot
	s.scale = Vector2.ONE * SVG_SCALE * scale_f
	s.modulate.a = alpha
	add_child(s)
	_fogged(s, p_m)
	if get_child_count() > MAX_MARKS:
		for c in get_children():
			if c != _stain_layer and c != _marker_layer:
				c.queue_free()
				break
	return s


func _stain(id: String) -> Dictionary:
	if not stains.has(id):
		stains[id] = {"pool": {}, "flecks": [], "smear": [], "trail": [], "marker": 0}
	return stains[id]


func handle(ev: Dictionary) -> void:
	match ev["type"]:
		"blood":
			_blood(ev)
		"drip":
			_drip(ev["p"])
		"impact":
			if ev["kind"] == Geom.WALL or ev["kind"] == Geom.COVER or ev["kind"] == Geom.WINDOW:
				_sprite("fx/chip", ev["p"] + ev["n"] * 0.02, rng.randf() * TAU, rng.randf_range(0.6, 1.0), 0.85)
		"casing":
			var side := Vector2.from_angle(ev["dir"] + PI / 2.0)
			var p: Vector2 = ev["p"] + side * rng.randf_range(0.5, 1.2) + Vector2.from_angle(ev["dir"]) * rng.randf_range(-0.3, 0.3)
			_sprite("fx/casing", p, rng.randf() * TAU, 1.0, 0.9)
		"plate":
			_sprite("fx/scuff", ev["p"] - ev["dir"] * 0.18, 0.0, 0.8, 0.6)
		"down":
			var st := _stain(ev["id"])
			if st["pool"].is_empty():
				var p2: Vector2 = ev["p"] + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
				var shape := PackedFloat32Array()
				for k in 11:
					shape.append(rng.randf_range(0.72, 1.12))
				st["pool"] = {"p": p2, "t0": world.t, "full": rng.randf_range(0.42, 0.56) * (1.25 if ev["killed"] else 1.0),
					"shape": shape, "rot": rng.randf() * TAU, "seen": _seen(p2)}
				_markers += 1
				st["marker"] = _markers
				st["marker_p"] = p2 + Vector2.from_angle(rng.randf() * TAU) * 0.95
				_redraw()


func _blood(ev: Dictionary) -> void:
	var p: Vector2 = ev["p"]
	var u: Vector2 = ev["dir"]
	var power: float = ev["power"]
	var st := _stain(ev.get("id", "?"))
	# a few flecks just past the body, away from the shooter
	for k in 2:
		if st["flecks"].size() >= MAX_FLECKS:
			break
		var fp: Vector2 = p + u.rotated(rng.randf_range(-0.5, 0.5)) * rng.randf_range(0.25, 0.7) * clampf(power, 0.5, 1.4)
		st["flecks"].append([fp, rng.randf_range(0.03, 0.07), _seen(fp)])
	# one contact smear, where a hit's line meets a wall close behind them
	if st["smear"].is_empty():
		var g: Geom = world.geom
		var tr: Dictionary = g.trace_shot(p, 1.2, p + u * 1.6, 1.0)
		if tr["hit"] and (tr["kind"] == Geom.WALL or tr["kind"] == Geom.COVER):
			var n: Vector2 = tr["n"]
			var along := n.orthogonal() * rng.randf_range(0.18, 0.3)
			var c: Vector2 = tr["p"] + n * 0.04
			st["smear"] = [c - along, c + along, _seen(c)]
	_redraw()


## A drip belongs to whoever is bleeding where it fell: it extends their one trail.
func _drip(p: Vector2) -> void:
	if world == null:
		return
	var best = null
	var bd := 0.35
	for o in world.ops:
		var dd: float = o.pos.distance_to(p)
		if dd < bd:
			bd = dd
			best = o
	if best == null:
		return
	var st := _stain(best.id)
	var tr: Array = st["trail"]
	if tr.size() >= TRAIL_MAX:
		return
	if not tr.is_empty() and (tr[-1][0] as Vector2).distance_to(p) < TRAIL_STEP:
		return
	tr.append([p, _seen(p)])
	_redraw()


var _grow_t := 0.0


func _process(dt: float) -> void:
	if _rev != Ink.rev:
		_rev = Ink.rev
		_redraw()
	if world == null:
		return
	# pools spread for 14 s after someone goes down: redraw a few times a second
	_grow_t += dt
	if _grow_t < 0.25:
		return
	_grow_t = 0.0
	for id in stains:
		var pl: Dictionary = stains[id]["pool"]
		if not pl.is_empty() and world.t - float(pl["t0"]) < 15.0:
			_stain_layer.queue_redraw()
			return


func _pool_k(pl: Dictionary) -> float:
	if world == null or world.over:
		return 1.0
	return sqrt(clampf((world.t - float(pl["t0"])) / 14.0, 0.06, 1.0))


## The stains: under the walls, gone with gore off.
class Stains extends Node2D:
	var d

	func _draw() -> void:
		if not Ink.gore_enabled:
			return
		for id in d.stains:
			var st: Dictionary = d.stains[id]
			_trail(st["trail"])
			var pl: Dictionary = st["pool"]
			if not pl.is_empty() and pl["seen"]:
				_pool(pl, d._pool_k(pl))
			for f in st["flecks"]:
				if f[2]:
					draw_circle(f[0] * PX, f[1] * PX, Ink.accent(0.62))
			var sm: Array = st["smear"]
			if not sm.is_empty() and sm[2]:
				draw_line(sm[0] * PX, sm[1] * PX, Ink.accent(0.55), 4.0)
				draw_line((sm[0] as Vector2).lerp(sm[1], 0.15) * PX, (sm[0] as Vector2).lerp(sm[1], 0.7) * PX, Ink.accent(0.75), 2.0)

	## One hard-edged irregular pool: outer at 0.68, inner at 0.90 and 0.58 scale, a few
	## dry rim flecks. A spilled printing plate first, blood second.
	func _pool(pl: Dictionary, k: float) -> void:
		var c: Vector2 = pl["p"] * PX
		var r: float = float(pl["full"]) * k * PX
		var sh: PackedFloat32Array = pl["shape"]
		var rot: float = pl["rot"]
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in sh.size():
			var a := rot + TAU * float(i) / float(sh.size())
			outer.append(c + Vector2.from_angle(a) * r * sh[i])
			inner.append(c + Vector2.from_angle(a + 0.2) * r * 0.58 * sh[(i + 3) % sh.size()])
		draw_colored_polygon(outer, Ink.accent(0.68))
		draw_colored_polygon(inner, Ink.accent(0.90))
		for j in 3:
			var a2 := rot + 1.9 * float(j) + 0.4
			draw_circle(c + Vector2.from_angle(a2) * r * (1.25 + 0.12 * float(j)), 1.4 + 0.5 * float(j % 2), Ink.accent(0.68))

	## One broken drag trail: width 5.5 to 2.5, alpha 0.46 to 0.20, every fourth step left out.
	func _trail(tr: Array) -> void:
		var n := tr.size()
		for i in range(1, n):
			if i % 4 == 0 or not tr[i][1] or not tr[i - 1][1]:
				continue
			var f := float(i) / float(maxi(1, n - 1))
			draw_line(tr[i - 1][0] * PX, tr[i][0] * PX, Ink.accent(lerpf(0.46, 0.20, f)), lerpf(5.5, 2.5, f))


## Numbered evidence markers: above the actors, and they stay with gore off.
class Markers extends Node2D:
	var d

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		for id in d.stains:
			var st: Dictionary = d.stains[id]
			if int(st["marker"]) <= 0 or st["pool"].is_empty() or not st["pool"]["seen"]:
				continue
			var p: Vector2 = st["marker_p"] * PX
			# a folded tent card, seen from above: paper, ink edge, fold line, number
			var r := Rect2(p - Vector2(8, 7), Vector2(16, 14))
			draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Ink.shadow(0.22))
			draw_rect(r, Ink.PAPER)
			draw_rect(r, Ink.INK, false, 1.2)
			draw_line(Vector2(r.position.x, p.y), Vector2(r.end.x, p.y), Ink.LIGHT, 1.0)
			var txt := "%d" % int(st["marker"])
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(p.x - w / 2.0, p.y + 4.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Ink.INK)
