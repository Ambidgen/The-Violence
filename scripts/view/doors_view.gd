extends Node2D
## Doors as they stand (v0.7.5). The floor plan draws every door open, in plan notation:
## the leaf at 90 degrees and its swing. Over it this layer draws a shut door (the swing
## painted out, the leaf across the opening), a locked one (a lock at the latch) and one
## that was forced (splinters at the latch, the leaf knocked wide). Live it reads the
## level; in a replay it is handed the states recorded at that moment.

const Crayon = preload("res://scripts/view/crayon.gd")
const PX := 40.0
const INK := Color("#141313")
const LEAF := Color("#e8722b")               # 1.4: doors are orange leaves
const SWING := Color(0.93, 0.9, 0.82, 0.3)
var _bi := -1

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


func _process(_d: float) -> void:
	var bi: int = Crayon.tick()
	if bi != _bi:
		_bi = bi
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
	var C = Crayon
	var k := 0
	for did in level.doors:
		var D: Dictionary = level.doors[did]
		k += 1
		if D.get("arch", false):
			continue
		var st: String = states.get(did, "open")
		var forced: bool = broken.get(did, false)
		var c: Vector2 = D["c"]
		var t: Vector2 = D["t"]
		var n: Vector2 = D["n"]
		var half: float = D["half"]
		var into: Vector2 = n if not level.is_exterior(D["b"]) else -n
		var hinge: Vector2 = c + t * half * float(D.get("hinge", 1))
		var latch: Vector2 = c - t * half * float(D.get("hinge", 1))
		var leaf := minf(half * 2.0, 1.0)
		var double: bool = half * 2.0 > 1.25
		var s := 3000 + k * 17
		if st == "open":
			# the leaf standing open at a right angle, and a faint swing
			var ends: Array = []
			if double:
				for sgn in [-1.0, 1.0]:
					var hg: Vector2 = c + t * half * sgn
					ends.append([hg, hg + into * half])
			else:
				var wide := into
				if forced:
					wide = into.rotated(0.35 * float(D.get("hinge", 1)) * signf(t.cross(into)))
				ends.append([hinge, hinge + wide * leaf])
			for e in ends:
				C.line(self, e[0] * PX, e[1] * PX, LEAF, 3.4, s, 0.5, 1)
				var r: float = (e[0] as Vector2).distance_to(e[1]) * PX
				var a0: float = (c - (e[0] as Vector2)).angle()
				var a1: float = ((e[1] as Vector2) - (e[0] as Vector2)).angle()
				draw_arc(e[0] * PX, r, a0, a0 + angle_difference(a0, a1), 10, SWING, 1.2, true)
		else:
			if double:
				for sgn2 in [-1.0, 1.0]:
					var hg2: Vector2 = c + t * half * sgn2
					C.line(self, hg2 * PX + into * 2.0, c * PX + into * 2.0, LEAF, 4.4, s + int(sgn2), 0.5, 2)
			else:
				C.line(self, hinge * PX + into * 2.0, latch * PX + into * 2.0, LEAF, 4.4, s, 0.5, 2)
			if st == "locked":
				var lp: Vector2 = latch * PX + (hinge - latch).normalized() * 7.0 + into * 2.0
				draw_circle(lp, 5.5, INK)
				draw_circle(lp, 2.4, Crayon.AMBER)
		if forced:
			for j in 5:
				var ang: float = into.angle() + (j - 2.0) * 0.42
				C.line(self, latch * PX, latch * PX + Vector2.from_angle(ang) * (6.0 + 4.0 * (j % 2)), Crayon.UMBER.lightened(0.3), 1.6, s + 40 + j, 0.4, 1)
