extends Node2D
## Doors as they stand (v0.7.5). The floor plan draws every door open, in plan notation:
## the leaf at 90 degrees and its swing. Over it this layer draws a shut door (the swing
## painted out, the leaf across the opening), a locked one (a lock at the latch) and one
## that was forced (splinters at the latch, the leaf knocked wide). Live it reads the
## level; in a replay it is handed the states recorded at that moment.

const PX := 40.0
const INK := Color("#1c1c1c")
const FLOOR := Color("#fbfbfa")
const FAINT := Color("#8f8f8f")

var level
var states := {}          # door id -> "closed" | "locked" (open doors are absent)
var broken := {}          # door id -> true: forced open
var _sig := ""


func setup(lv) -> void:
	level = lv
	states = {}
	broken = {}
	_sig = ""
	queue_redraw()


## Live: take the states from the level when they change.
func refresh() -> void:
	if level == null:
		return
	var st: Dictionary = level.door_states()
	var br := {}
	for did in level.doors:
		if level.doors[did].get("broken", false):
			br[did] = true
	var sig := str(st) + str(br)
	if sig != _sig:
		_sig = sig
		states = st
		broken = br
		queue_redraw()


## Replay: the states recorded at a moment.
func show_states(st: Dictionary, br: Dictionary) -> void:
	states = st
	broken = br
	_sig = ""
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	for did in level.doors:
		var D: Dictionary = level.doors[did]
		if not D.has("leaf"):
			continue
		var st: String = states.get(did, "open")
		var forced: bool = broken.get(did, false)
		if st == "open" and not forced:
			continue
		var c: Vector2 = D["c"]
		var t: Vector2 = D["t"]
		var n: Vector2 = D["n"]
		var half: float = D["half"]
		var into: Vector2 = n if not level.is_exterior(D["b"]) else -n
		var hinge: Vector2 = c + t * half * float(D.get("hinge", 1))
		var latch: Vector2 = c - t * half * float(D.get("hinge", 1))
		var leaf := minf(half * 2.0, 1.0)
		var double: bool = half * 2.0 > 1.25
		if st != "open":
			# the leaf swung shut: paint out the open leaf (the swing arc stays, faint), and
			# draw the leaf across the opening, bold; a locked door gets a bolt at the latch
			if double:
				for sgn in [-1.0, 1.0]:
					var hg: Vector2 = c + t * half * sgn
					_cover_leaf(hg, hg + into * half)
					draw_line(hg * PX + into * 2.0, c * PX + into * 2.0, INK, 3.5)
			else:
				_cover_leaf(hinge, hinge + into * leaf)
				draw_line(hinge * PX + into * 2.0, latch * PX + into * 2.0, INK, 3.5)
			if st == "locked":
				var lp: Vector2 = latch * PX + (hinge - latch).normalized() * 7.0 + into * 2.0
				draw_rect(Rect2(lp - Vector2(4.5, 4.5), Vector2(9, 9)), INK)
				draw_rect(Rect2(lp - Vector2(2.0, 2.0), Vector2(4, 4)), Color.WHITE)
				draw_line(lp + (latch - hinge).normalized() * 4.5, latch * PX + (latch - hinge).normalized() * 5.0 + into * 2.0, INK, 2.5)
		elif forced:
			# splinters at the latch jamb, the leaf knocked past square
			for k in 4:
				var ang: float = (into.angle() + (k - 1.5) * 0.45)
				var s0: Vector2 = latch * PX
				draw_line(s0, s0 + Vector2.from_angle(ang) * (5.0 + 3.0 * (k % 2)), INK, 1.2)
			if not double:
				var wide: Vector2 = hinge + (into.rotated(0.35 * float(D.get("hinge", 1)) * signf(t.cross(into)))) * leaf
				draw_line(hinge * PX, wide * PX, FAINT, 1.0)


## Paint out the drawn open leaf (a thin strip along it).
func _cover_leaf(a: Vector2, b: Vector2) -> void:
	var d: Vector2 = (b - a).normalized().orthogonal() * 0.07
	var pts := PackedVector2Array([(a + d) * PX, (b + d) * PX, (b - d) * PX, (a - d) * PX])
	draw_colored_polygon(pts, FLOOR)


## The quarter disc a leaf swings through, painted floor-colour.
func _cover(hinge: Vector2, latch: Vector2, leaf: float, into: Vector2) -> void:
	var a0: float = (latch - hinge).angle()
	var a1: float = into.angle()
	var d: float = angle_difference(a0, a1)
	d += signf(d) * 0.12
	var pts := PackedVector2Array([hinge * PX])
	for k in 13:
		pts.append((hinge + Vector2.from_angle(a0 + d * k / 12.0) * (leaf + 0.03)) * PX)
	draw_colored_polygon(pts, FLOOR)
