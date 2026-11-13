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
## 1.4: the physical blood. Every hit throws droplets out along the round's path (and a
## little back-spatter towards the shooter); each flies as a ballistic body from the wound
## (gravity, no drag), and where it meets the floor it leaves a stain stretched along its
## flight (width / length = sin of the impact angle, as on a real floor), with satellites
## when it lands fast; where it meets a wall it leaves a streak on the face. The residue
## stays: stains dry from red to brown, and anyone who walks through a pool tracks it in
## footprints for a few steps.
## drops: [{p, len, wid, rot, t, seen, wall, sat: [[p, r]]}]   flights: [{a, b, z0, vz, t0, t1}]
var drops: Array = []
var flights: Array = []
var prints: Array = []        # [{p, rot, a, t, seen}]
var _tracking := {}           # id -> {"left": steps, "last": Vector2, "side": 1.0}
const MAX_DROPS := 900
const MAX_PRINTS := 260
const G := 9.81
var _stain_layer: Node2D
var _marker_layer: Node2D
var _rev := -1


## The sprite for a key (1.4): the crayon bake's three boil variants as one
## AnimatedTexture, so every sprite shivers with the page; the vector original if the
## bake is missing.
static var boil_fps := 8.0

static func tex(key: String) -> Texture2D:
	if not _tex.has(key):
		var p0 := "res://assets/crayon/%s_0.png" % key
		if ResourceLoader.exists(p0):
			var at := AnimatedTexture.new()
			at.frames = 3
			for v in 3:
				at.set_frame_texture(v, load("res://assets/crayon/%s_%d.png" % [key, v]))
			at.speed_scale = boil_fps
			at.pause = boil_fps <= 0.0
			_tex[key] = at
		else:
			_tex[key] = load("res://assets/svg/%s.svg" % key)
	return _tex[key]


## Line boil for the sprites: 0 stills them (the accessibility setting).
static func set_boil(fps: float) -> void:
	boil_fps = fps
	for t in _tex.values():
		if t is AnimatedTexture:
			t.speed_scale = maxf(fps, 0.01)
			t.pause = fps <= 0.0


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
	drops.clear()
	flights.clear()
	prints.clear()
	_tracking.clear()
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
	for dr in drops:
		if not dr["seen"] and (all or _seen(dr["p"])):
			dr["seen"] = true
			changed = true
	for fp in prints:
		if not fp["seen"] and (all or _seen(fp["p"])):
			fp["seen"] = true
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
	_spray(ev)
	_redraw()


## Throw the droplets of one hit and fly each to where it lands (worked out now, so a
## replay or a paused game gets the same marks; the flight is drawn live until it lands).
func _spray(ev: Dictionary) -> void:
	if world == null:
		return
	var p: Vector2 = ev["p"]
	var u: Vector2 = ev["dir"]
	if u.length() < 0.01:
		u = Vector2.from_angle(rng.randf() * TAU)
	var power: float = clampf(float(ev.get("power", 0.8)), 0.3, 1.6)
	var zone: String = String(ev.get("zone", "body"))
	var h0 := 1.55 if zone == "head" else (0.6 if zone in ["leg", "legs"] else 1.15)
	var o = null
	for oo in world.ops:
		if oo.id == ev.get("id", ""):
			o = oo
	if o != null and int(o.stance) > 0:
		h0 *= 0.65
	var n_fwd := int(6 + 9 * power) + (5 if zone == "head" else 0)
	var n_back := 2 + int(2 * power)
	var t0: float = world.t
	for k in n_fwd + n_back:
		var back := k >= n_fwd
		var dir := (-u if back else u).rotated(rng.randf_range(-0.55, 0.55) * (1.4 if back else 1.0))
		var speed := rng.randf_range(1.5, 4.0) * power * (0.45 if back else 1.0) + (1.5 if zone == "head" and not back else 0.0)
		var vz := rng.randf_range(-0.6, 1.8)
		_fly(p + dir * 0.18, h0 + rng.randf_range(-0.12, 0.12), dir * speed, vz, rng.randf_range(0.012, 0.04) * (0.6 if back else 1.0), t0, ev.get("id", "?"))


func _fly(p: Vector2, z: float, v: Vector2, vz: float, rad: float, t0: float, _id: String) -> void:
	if drops.size() >= MAX_DROPS:
		drops.pop_front()
	var g: Geom = world.geom
	var dt := 0.02
	var t := 0.0
	var pos := p
	var zz := z
	var vzz := vz
	for step in 120:
		var nz := zz + vzz * dt - 0.5 * G * dt * dt
		var npos := pos + v * dt
		var tr: Dictionary = g.trace_shot(pos, maxf(zz, 0.01), npos, maxf(nz, 0.01))
		if tr["hit"] and (tr["kind"] == Geom.WALL or tr["kind"] == Geom.COVER or tr["kind"] == Geom.WINDOW):
			# a streak on the wall face, along it
			var n: Vector2 = tr["n"]
			var c: Vector2 = tr["p"] + n * 0.03
			var tang := n.orthogonal()
			var sl := absf(v.normalized().dot(tang))
			drops.append({"p": c, "len": rad * (2.0 + 6.0 * sl) + 0.02, "wid": rad * 1.1, "rot": tang.angle(), "t": t0 + t, "seen": _seen(c), "wall": true, "sat": []})
			flights.append({"a": p, "b": c, "z0": z, "vz": vz, "t0": t0, "t1": t0 + t, "r": rad})
			return
		if nz <= 0.0:
			var f := zz / maxf(zz - nz, 0.0001)
			var land := pos.lerp(npos, f)
			var vzi := vzz - G * dt * f
			var hs := v.length()
			var ang := atan2(absf(vzi), maxf(hs, 0.01))      # impact angle above the floor
			var wid := rad * (1.6 + hs * 0.12)
			var length := wid / maxf(sin(ang), 0.18)
			var sat: Array = []
			var spd := sqrt(hs * hs + vzi * vzi)
			if spd > 4.0:
				for j in int((spd - 4.0) * 1.5) + 1:
					sat.append([land + v.normalized().rotated(rng.randf_range(-0.6, 0.6)) * (length * 0.6 + rng.randf_range(0.03, 0.12)), rad * rng.randf_range(0.25, 0.5)])
			drops.append({"p": land, "len": length, "wid": wid, "rot": v.angle(), "t": t0 + t + dt * f, "seen": _seen(land), "wall": false, "sat": sat})
			flights.append({"a": p, "b": land, "z0": z, "vz": vz, "t0": t0, "t1": t0 + t + dt * f, "r": rad})
			return
		pos = npos
		zz = nz
		vzz -= G * dt
		t += dt


## Footprints: anyone standing who walks through blood carries it a few steps.
func _residue() -> void:
	if world == null or not Ink.gore_enabled:
		return
	for o in world.ops:
		if not o.alive():
			continue
		var tk: Dictionary = _tracking.get(o.id, {})
		var wet := false
		for id in stains:
			var pl: Dictionary = stains[id]["pool"]
			if not pl.is_empty() and id != o.id and (pl["p"] as Vector2).distance_to(o.pos) < float(pl["full"]) * _pool_k(pl) * 0.9:
				wet = true
				break
		if wet:
			tk = {"left": 9, "last": o.pos, "side": float(tk.get("side", 1.0))}
			_tracking[o.id] = tk
			continue
		if tk.is_empty() or int(tk["left"]) <= 0:
			continue
		if (tk["last"] as Vector2).distance_to(o.pos) >= 0.42:
			var hd: Vector2 = (o.pos - (tk["last"] as Vector2)).normalized()
			var side: float = -float(tk["side"])
			var fp: Vector2 = o.pos + hd.orthogonal() * 0.09 * side
			prints.append({"p": fp, "rot": hd.angle(), "a": float(tk["left"]) / 9.0, "t": world.t, "seen": _seen(fp)})
			if prints.size() > MAX_PRINTS:
				prints.pop_front()
			tk["left"] = int(tk["left"]) - 1
			tk["last"] = o.pos
			tk["side"] = side
			_stain_layer.queue_redraw()


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
var _dry_t := 0.0


## Blood dries: fresh red to brown over a couple of minutes.
func blood_col(t_made: float, a: float) -> Color:
	var age := 0.0 if world == null else maxf(0.0, world.t - t_made)
	var fresh := Ink.accent(1.0)
	var dry := fresh.lerp(Color("#4a2a1e"), 0.65) if Ink.red_ink_enabled else fresh.darkened(0.3)
	var c := fresh.lerp(dry, clampf(age / 150.0, 0.0, 1.0))
	c.a = a
	return c


func _process(dt: float) -> void:
	if _rev != Ink.rev:
		_rev = Ink.rev
		_redraw()
	if world == null:
		return
	# droplets in the air: redraw every frame until the last one lands
	if not flights.is_empty():
		var keep: Array = []
		for f in flights:
			if float(f["t1"]) > world.t:
				keep.append(f)
		flights = keep
		_stain_layer.queue_redraw()
	# pools spread for 14 s after someone goes down: redraw a few times a second
	_grow_t += dt
	if _grow_t < 0.25:
		return
	_grow_t = 0.0
	_residue()
	_dry_t += 0.25
	if _dry_t >= 2.0:
		_dry_t = 0.0
		_stain_layer.queue_redraw()
	for id in stains:
		var pl: Dictionary = stains[id]["pool"]
		if not pl.is_empty() and world.t - float(pl["t0"]) < 15.0:
			_stain_layer.queue_redraw()
			return


func _pool_k(pl: Dictionary) -> float:
	if world == null or world.over:
		return 1.0
	return sqrt(clampf((world.t - float(pl["t0"])) / 14.0, 0.06, 1.0))


## Shared ordered samples for both rings of a pool. Keeping this pure makes the
## triangulation regression independent of a renderer or a running World.
func pool_points(c: Vector2, r: float, rot: float, sh: PackedFloat32Array, scale_f := 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	if sh.size() < 3:
		return out
	for i in sh.size():
		var a := rot + TAU * float(i) / float(sh.size())
		out.append(c + Vector2.from_angle(a) * r * maxf(0.01, sh[i]) * scale_f)
	return out


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
			if false and not sm.is_empty() and sm[2]:
				draw_line(sm[0] * PX, sm[1] * PX, Ink.accent(0.55), 4.0)
				draw_line((sm[0] as Vector2).lerp(sm[1], 0.15) * PX, (sm[0] as Vector2).lerp(sm[1], 0.7) * PX, Ink.accent(0.75), 2.0)

		_drops()

	func _drops() -> void:
		var now: float = d.world.t if d.world != null else 1e9
		for fp in d.prints:
			if not fp["seen"]:
				continue
			var c: Vector2 = fp["p"] * PX
			var col: Color = d.blood_col(fp["t"], 0.55 * float(fp["a"]))
			var pts := PackedVector2Array()
			for k in 8:
				var a := TAU * k / 8.0
				pts.append(c + Vector2(cos(a) * 5.0, sin(a) * 2.6).rotated(fp["rot"]))
			draw_colored_polygon(pts, col)
			draw_circle(c + Vector2.from_angle(fp["rot"] + PI) * 5.5, 1.8, col)
		for dr in d.drops:
			if not dr["seen"] or float(dr["t"]) > now:
				continue
			var c2: Vector2 = dr["p"] * PX
			var L: float = float(dr["len"]) * PX * 0.5
			var W: float = float(dr["wid"]) * PX * 0.5
			var pts2 := PackedVector2Array()
			for k2 in 10:
				var a2 := TAU * k2 / 10.0
				# a teardrop: the tail points the way it was going
				var stretch := 1.0 + 0.5 * maxf(0.0, cos(a2))
				pts2.append(c2 + Vector2(cos(a2) * maxf(L, 1.0) * stretch, sin(a2) * maxf(W, 0.9)).rotated(dr["rot"]))
			draw_colored_polygon(pts2, d.blood_col(dr["t"], 0.85 if not dr["wall"] else 0.95))
			for s in dr["sat"]:
				draw_circle(s[0] * PX, maxf(0.7, float(s[1]) * PX), d.blood_col(dr["t"], 0.75))
		# droplets still in the air: a dot and its shadow on the floor
		for f in d.flights:
			var tt: float = now - float(f["t0"])
			if tt < 0.0:
				continue
			var k3: float = clampf(tt / maxf(0.001, float(f["t1"]) - float(f["t0"])), 0.0, 1.0)
			var g: Vector2 = (f["a"] as Vector2).lerp(f["b"], k3) * PX
			var z: float = maxf(0.0, float(f["z0"]) + float(f["vz"]) * tt - 0.5 * 9.81 * tt * tt)
			draw_circle(g, 1.2, Color(0, 0, 0, 0.18))
			draw_circle(g + Vector2(0, -z * 6.0), maxf(1.0, float(f["r"]) * PX * 0.6), Ink.accent(0.9))

	## One hard-edged irregular pool: outer at 0.68, inner at 0.90 and 0.58 scale, a few
	## dry rim flecks. Both rings use the same ordered angular samples. Independently
	## rotating/permuting the inner ring produced self-intersecting triangulations.
	func _pool(pl: Dictionary, k: float) -> void:
		var c: Vector2 = pl["p"] * PX
		var r: float = float(pl["full"]) * k * PX
		var sh: PackedFloat32Array = pl["shape"]
		var rot: float = pl["rot"]
		var outer: PackedVector2Array = d.pool_points(c, r, rot, sh, 1.0)
		var inner: PackedVector2Array = d.pool_points(c, r, rot, sh, 0.58)
		# 1.4: blood in wax crayon: a thin wash, then strokes back and forth, darker inside
		var cr = load("res://scripts/view/crayon.gd")
		var sd := int(absf(c.x * 13.0 + c.y * 7.0)) % 9000
		draw_colored_polygon(outer, Ink.accent(0.35))
		cr.hatch(self, outer, Ink.accent(0.85), 2.6, rot + 0.8, sd, 2.6)
		cr.hatch(self, inner, Color(Ink.accent(1.0).darkened(0.45), 0.85), 2.4, rot - 0.6, sd + 1, 2.4)
		cr.outline(self, outer, Color(Ink.accent(1.0).darkened(0.35), 0.8), 1.4, sd + 2, 0.6)
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
			var a: Vector2 = tr[i - 1][0] * PX
			var b: Vector2 = tr[i][0] * PX
			draw_line(a, b, Ink.accent(lerpf(0.55, 0.25, f)), lerpf(5.5, 2.5, f))
			draw_line(a + Vector2(1.2, -0.8), b + Vector2(-0.6, 1.0), Color(Ink.accent(1.0).darkened(0.4), lerpf(0.5, 0.2, f)), lerpf(2.6, 1.2, f))


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
