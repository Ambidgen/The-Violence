extends RefCounted
## Plan-view geometry with analytic height (bible section 1).
## Every obstacle is an axis-aligned rectangle in metres with a kind and a height.
## Sight lines and bullets are 2D segments whose height varies linearly along
## their length; the obstacle kind decides what each one stops.

enum {WALL, COVER, CONCEAL, WINDOW, LOW}

var obs: Array = []        # [{r: Rect2, kind, h, sill, lintel, move: bool, name}]
var width := 0.0
var height := 0.0
var _cells: Array = []     # 1 m buckets of obstacle indices
var _cw := 0
var _ch := 0
var _stamp := PackedInt32Array()
var _stamp_id := 0


func setup(w: float, h: float) -> void:
	width = w
	height = h
	_cw = int(ceil(w))
	_ch = int(ceil(h))


func add(r: Rect2, kind: int, h: float = 3.0, name: String = "", move: bool = true,
		sill: float = 0.9, lintel: float = 2.1) -> int:
	obs.append({"r": r, "kind": kind, "h": h, "sill": sill, "lintel": lintel, "move": move, "name": name})
	return obs.size() - 1


func build_index() -> void:
	_cells.clear()
	_cells.resize(_cw * _ch)
	for i in _cells.size():
		_cells[i] = []
	for i in obs.size():
		var r: Rect2 = obs[i]["r"]
		var x0 := clampi(int(floor(r.position.x)), 0, _cw - 1)
		var y0 := clampi(int(floor(r.position.y)), 0, _ch - 1)
		var x1 := clampi(int(floor(r.end.x - 0.0001)), 0, _cw - 1)
		var y1 := clampi(int(floor(r.end.y - 0.0001)), 0, _ch - 1)
		for cy in range(y0, y1 + 1):
			for cx in range(x0, x1 + 1):
				_cells[cy * _cw + cx].append(i)
	_stamp.resize(obs.size())
	_stamp.fill(0)


func _collect(cx: int, cy: int, out: Array) -> void:
	if cx < 0 or cy < 0 or cx >= _cw or cy >= _ch:
		return
	for idx in _cells[cy * _cw + cx]:
		if _stamp[idx] != _stamp_id:
			_stamp[idx] = _stamp_id
			out.append(idx)


## Obstacle indices whose buckets the segment a->b passes through (2D DDA).
func candidates(a: Vector2, b: Vector2) -> Array:
	_stamp_id += 1
	var out: Array = []
	var x := int(floor(a.x))
	var y := int(floor(a.y))
	var xe := int(floor(b.x))
	var ye := int(floor(b.y))
	var d := b - a
	var step_x := 1 if d.x > 0.0 else -1
	var step_y := 1 if d.y > 0.0 else -1
	var t_max_x := INF
	var t_max_y := INF
	var t_dx := INF
	var t_dy := INF
	if absf(d.x) > 1e-9:
		t_max_x = ((x + (1 if d.x > 0.0 else 0)) - a.x) / d.x
		t_dx = absf(1.0 / d.x)
	if absf(d.y) > 1e-9:
		t_max_y = ((y + (1 if d.y > 0.0 else 0)) - a.y) / d.y
		t_dy = absf(1.0 / d.y)
	var guard := 0
	while true:
		_collect(x, y, out)
		if (x == xe and y == ye) or guard > 512:
			break
		if t_max_x < t_max_y:
			t_max_x += t_dx
			x += step_x
		else:
			t_max_y += t_dy
			y += step_y
		guard += 1
	return out


## Slab test. Returns Vector3(t_in, t_out, face) with face 0 = entered through an
## x face, 1 = through a y face, -1 = starts inside; t_in < 0 means no hit.
static func seg_rect(a: Vector2, d: Vector2, r: Rect2) -> Vector3:
	var t0 := 0.0
	var t1 := 1.0
	var face := -1
	for axis in 2:
		var p: float = a[axis]
		var dd: float = d[axis]
		var lo: float = r.position[axis]
		var hi: float = lo + r.size[axis]
		if absf(dd) < 1e-9:
			if p < lo or p > hi:
				return Vector3(-1, -1, -1)
		else:
			var ta := (lo - p) / dd
			var tb := (hi - p) / dd
			if ta > tb:
				var tmp := ta
				ta = tb
				tb = tmp
			if ta > t0:
				t0 = ta
				face = axis
			t1 = minf(t1, tb)
			if t0 > t1:
				return Vector3(-1, -1, -1)
	return Vector3(t0, t1, face)


func _stops(o: Dictionary, zlo: float, zhi: float, is_bullet: bool) -> bool:
	match o["kind"]:
		WALL:
			return true
		COVER:
			return zlo < o["h"]
		CONCEAL:
			return (not is_bullet) and zlo < o["h"]
		WINDOW:
			return zlo < o["sill"] or zhi > o["lintel"]
	return false


## True when nothing blocks sight from (a, za) to (b, zb).
var sight_calls := 0


func sight_clear(a: Vector2, za: float, b: Vector2, zb: float) -> bool:
	sight_calls += 1
	var d := b - a
	for idx in candidates(a, b):
		var o: Dictionary = obs[idx]
		if o["kind"] == LOW:
			continue
		var r: Rect2 = o["r"]
		if r.has_point(a) or r.has_point(b):
			continue
		var tt := seg_rect(a, d, r)
		if tt.x < 0.0:
			continue
		var z0 := lerpf(za, zb, tt.x)
		var z1 := lerpf(za, zb, tt.y)
		if _stops(o, minf(z0, z1), maxf(z0, z1), false):
			return false
	return true


## First obstacle that stops a bullet on a->b. Returns {hit, t, p, n, idx, kind}.
func trace_shot(a: Vector2, za: float, b: Vector2, zb: float) -> Dictionary:
	var d := b - a
	var best_t := 2.0
	var best := {}
	for idx in candidates(a, b):
		var o: Dictionary = obs[idx]
		if o["kind"] == LOW or o["kind"] == CONCEAL:
			continue
		var r: Rect2 = o["r"]
		if r.has_point(a):
			continue
		var tt := seg_rect(a, d, r)
		if tt.x < 0.0 or tt.x >= best_t:
			continue
		var z0 := lerpf(za, zb, tt.x)
		var z1 := lerpf(za, zb, tt.y)
		if _stops(o, minf(z0, z1), maxf(z0, z1), true):
			best_t = tt.x
			var n := Vector2.ZERO
			if int(tt.z) == 0:
				n = Vector2(-signf(d.x), 0)
			elif int(tt.z) == 1:
				n = Vector2(0, -signf(d.y))
			best = {"hit": true, "t": tt.x, "p": a + d * tt.x, "n": n, "idx": idx,
				"kind": o["kind"], "z": lerpf(za, zb, tt.x)}
	if best.is_empty():
		return {"hit": false, "t": 1.0, "p": b, "n": Vector2.ZERO, "idx": -1, "kind": -1, "z": zb}
	return best


## Does a disc of radius rad at p overlap any movement-blocking obstacle?
func blocked_disc(p: Vector2, rad: float) -> bool:
	if p.x < rad or p.y < rad or p.x > width - rad or p.y > height - rad:
		return true
	var x0 := clampi(int(floor(p.x - rad)), 0, _cw - 1)
	var x1 := clampi(int(floor(p.x + rad)), 0, _cw - 1)
	var y0 := clampi(int(floor(p.y - rad)), 0, _ch - 1)
	var y1 := clampi(int(floor(p.y + rad)), 0, _ch - 1)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			for idx in _cells[cy * _cw + cx]:
				var o: Dictionary = obs[idx]
				if not o["move"]:
					continue
				var r: Rect2 = o["r"]
				var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
				if q.distance_squared_to(p) < rad * rad:
					return true
	return false


## Distance from p to the nearest obstacle of the given kinds (capped at cap).
func dist_to_kinds(p: Vector2, kinds: Array, cap: float = 3.0) -> float:
	var best := cap
	var x0 := clampi(int(floor(p.x - cap)), 0, _cw - 1)
	var x1 := clampi(int(floor(p.x + cap)), 0, _cw - 1)
	var y0 := clampi(int(floor(p.y - cap)), 0, _ch - 1)
	var y1 := clampi(int(floor(p.y + cap)), 0, _ch - 1)
	_stamp_id += 1
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			for idx in _cells[cy * _cw + cx]:
				if _stamp[idx] == _stamp_id:
					continue
				_stamp[idx] = _stamp_id
				var o: Dictionary = obs[idx]
				if not kinds.has(o["kind"]):
					continue
				var r: Rect2 = o["r"]
				var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
				best = minf(best, q.distance_to(p))
	return best
