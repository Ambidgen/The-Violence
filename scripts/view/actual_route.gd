extends Node2D
## Application (v0.8, red ink): where each police squad actually went. The squad
## leader's position is sampled through the operation and drawn as a wobbling red route
## with a faint offset duplicate stroke, a numbered ring where it started and a beacon
## tick where it is now. Set beside the briefing's one clean line, it is the gap between
## the plan and the room. Presentation only: it reads the world, never writes it.

const Ink = preload("res://scripts/view/ink.gd")
const PX := 40.0
const STEP := 0.5        # seconds between samples
const MIN_MOVE := 0.4    # metres a leader must move before a new point is kept

var world
var team := 0
var trails := {}         # element index -> PackedVector2Array (metres)
var labels := {}         # element index -> the squad number it is drawn with
var _t := 0.0
var _rev := -1


func setup(w, tm := 0) -> void:
	world = w
	team = tm
	trails.clear()
	labels.clear()
	_t = -STEP
	visible = true
	queue_redraw()


func clear() -> void:
	world = null
	trails.clear()
	queue_redraw()


func _process(_dt: float) -> void:
	if _rev != Ink.rev:
		_rev = Ink.rev
		queue_redraw()
	if world == null or world.over or team >= world.teams.size():
		return
	# sampled on simulation time, so the same operation always draws the same route
	if world.t - _t < STEP:
		return
	_t = world.t
	var changed := false
	for el in world.teams[team].get("elements", []):
		if el.get("mode", "") == "split":
			continue
		var ld = world.brain.leader_of(el)
		if ld == null:
			continue
		var si: int = int(el["i"])
		labels[si] = int(el.get("parent", el["i"])) + 1 if el.get("child", false) else int(el["i"]) + 1
		if not trails.has(si):
			trails[si] = PackedVector2Array()
		var tr: PackedVector2Array = trails[si]
		if tr.is_empty() or tr[tr.size() - 1].distance_to(ld.pos) >= MIN_MOVE:
			tr.append(ld.pos)
			trails[si] = tr
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for si in trails:
		var tr: PackedVector2Array = trails[si]
		if tr.size() < 2:
			continue
		# the wobble: each step bent a little off true, deterministically
		var pts := PackedVector2Array()
		for i in tr.size():
			var p: Vector2 = tr[i] * PX
			if i > 0 and i < tr.size() - 1:
				var u: Vector2 = (tr[i + 1] - tr[i - 1]).normalized().orthogonal()
				p += u * sin(float(i) * 1.7 + float(si)) * 2.6
			pts.append(p)
		var dup := PackedVector2Array()
		for q in pts:
			dup.append(q + Vector2(3.0, 2.0))
		draw_polyline(dup, Ink.accent(0.22), 1.2, true)
		draw_polyline(pts, Ink.accent(0.6), 2.2, true)
		# started here (numbered), is here now (beacon tick)
		var a := pts[0]
		draw_circle(a, 8.0, Ink.PAPER)
		draw_arc(a, 8.0, 0.0, TAU, 18, Ink.accent(0.6), 1.6)
		draw_arc(a + Vector2(2, 1.5), 8.0, 0.0, TAU, 18, Ink.accent(0.2), 1.0)
		var t := str(labels.get(si, int(si) + 1))
		draw_string(font, a + Vector2(-3.5 * t.length(), 4.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Ink.INK)
		var e := pts[pts.size() - 1]
		for k in 3:
			var ang := float(k) * TAU / 3.0 + 0.4
			draw_line(e + Vector2.from_angle(ang) * 6.0, e + Vector2.from_angle(ang) * 11.0, Ink.accent(0.7), 1.6)
