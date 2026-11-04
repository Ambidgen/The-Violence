extends Node2D
## The fog of war (v0.7; v0.8.1 sees through the officers' eyes): during a planned
## operation the player sees only what the officers see.
##   - officers' own positions, always, and the ground within arm's reach;
##   - what each officer can see right now, taken from the simulation's own perception:
##     their view cone where they are actually looking (narrowed by stress and tunnel
##     vision, gone while a flashbang has them), out to 45 m, stopped by walls;
##   - the people any officer has a line of sight to, exactly as the sim has it;
##   - everyone else only as last-known positions from radio callouts.
## Ground once seen stays lighter than ground never seen. Blood and bodies appear when an
## officer sees them. Body cameras no longer gate the view; they are evidence.
##
## Every snapshot the recorder takes gets a copy of what was known, so rewinding shows
## the operation as it was seen at the time; the debrief replay lifts the fog.

const Crayon = preload("res://scripts/view/crayon.gd")
const PX := 40.0
const CELL := 0.5
const CAM_R := 45.0          # the sim's perception range
const RAY_DEG := 2.0         # one sight line every 2 degrees of the cone
const NEAR_R := 1.5          # the ground an officer is standing in
const UNSEEN := 0.62
const SEEN := 0.40

var world
var level
var enabled := false
var nx := 1
var ny := 1
var seen := PackedByteArray()
var now := PackedByteArray()
var img: Image
var tex: ImageTexture
var sprite: Sprite2D
var visible_ids := {}       # people (not officers) a camera sees right now
var bodies := {}            # people seen down: they stay drawn where they fell
var lkps: Array = []        # [{id, p, t}] radio callouts of people not in view
var _next := 0.0
var _last_snap := -1
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crayon_fog.gdshader")
	sprite.material = mat
	add_child(sprite)


func setup(w, on: bool) -> void:
	world = w
	enabled = on and w != null
	visible = enabled
	visible_ids.clear()
	bodies.clear()
	lkps.clear()
	_last_snap = -1
	if w == null:
		return
	level = w.level
	nx = int(ceil(level.W / CELL))
	ny = int(ceil(level.H / CELL))
	seen.resize(nx * ny)
	seen.fill(0)
	now.resize(nx * ny)
	now.fill(0)
	img = Image.create(nx, ny, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.scale = Vector2(CELL * PX, CELL * PX)
	_next = 0.0
	if enabled:
		refresh()


func _cell(p: Vector2) -> int:
	var x := clampi(int(p.x / CELL), 0, nx - 1)
	var y := clampi(int(p.y / CELL), 0, ny - 1)
	return y * nx + x


## Is the ground at p in view of a camera right now? (Always true with the fog off.)
func visible_at(p: Vector2) -> bool:
	if not enabled:
		return true
	return now[_cell(p)] == 1


func _process(_d: float) -> void:
	if sprite.material != null:
		(sprite.material as ShaderMaterial).set_shader_parameter("boil", float(Crayon.tick() % 3))


func tick(dt: float) -> void:
	if not enabled or world == null:
		return
	_next -= dt
	if _next <= 0.0:
		_next = 0.2
		refresh()


## Work out what the cameras see now, and what the radio has reported.
func refresh() -> void:
	if world == null:
		return
	now.fill(0)
	var eyes: Array = []
	for o in world.ops:
		if o.judges and o.alive() and not o.gone:
			_mark_disc(o.pos, NEAR_R)
			if not o.stunned(world.t):
				eyes.append(o)
				_cast(o)
	visible_ids.clear()
	for e in world.ops:
		if e.judges or e.gone:
			continue
		var seen_by := false
		for o2 in eyes:
			var v: Dictionary = o2.vis.get(e.id, {})
			if not v.get("los", false):
				continue
			if absf(angle_difference(o2.look_dir, (e.pos - o2.pos).angle())) <= world.cone_half(o2) + 0.05:
				seen_by = true
				break
		if not seen_by:
			continue
		if e.alive():
			visible_ids[e.id] = true
		else:
			bodies[e.id] = true
	# radio callouts: last-known positions of anyone not in view
	lkps.clear()
	if world.teams.size() > 0:
		var tl: Dictionary = world.teams[0]["lkps"]
		for eid in tl:
			if visible_ids.has(eid) or bodies.has(eid):
				continue
			var e2 = world.by_id.get(eid, null)
			if e2 == null or e2.gone or (not e2.alive() and not bodies.has(eid)) and world.t - float(tl[eid]["t"]) > 90.0:
				continue
			if world.t - float(tl[eid]["t"]) > 120.0:
				continue
			lkps.append({"id": eid, "p": tl[eid]["p"], "t": tl[eid]["t"]})
	_paint()
	_record()
	queue_redraw()


func _mark(i: int) -> void:
	now[i] = 1
	seen[i] = 1


func _mark_disc(p: Vector2, r: float) -> void:
	var c0 := Vector2i(int((p.x - r) / CELL), int((p.y - r) / CELL))
	var c1 := Vector2i(int((p.x + r) / CELL), int((p.y + r) / CELL))
	for y in range(maxi(0, c0.y), mini(ny - 1, c1.y) + 1):
		for x in range(maxi(0, c0.x), mini(nx - 1, c1.x) + 1):
			if Vector2((x + 0.5) * CELL, (y + 0.5) * CELL).distance_to(p) <= r:
				_mark(y * nx + x)


## A fan of sight lines across the officer's view cone, where they are looking now; every
## cell along each, up to where sight is blocked, is in view. Far out the lines spread,
## so each also fills sideways to meet its neighbour.
func _cast(o) -> void:
	var g = world.geom
	var half: float = world.cone_half(o)
	var rays := maxi(8, int(ceil(rad_to_deg(2.0 * half) / RAY_DEG)) + 1)
	var step_a := 2.0 * half / float(rays - 1)
	var ez: float = o.eye()
	for k in rays:
		var a: float = o.look_dir - half + step_a * k
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		var end: Vector2 = o.pos + dir * CAM_R
		end = Vector2(clampf(end.x, 0.05, level.W - 0.05), clampf(end.y, 0.05, level.H - 0.05))
		var full: float = o.pos.distance_to(end)
		var f: float = g.sight_reach(o.pos, ez, end, 1.1)
		var reach := f * full + 0.25
		var s := 0.0
		while s <= reach:
			var q: Vector2 = o.pos + dir * s
			_mark(_cell(q))
			var w := s * step_a * 0.5
			var off := CELL
			while off <= w + 0.01:
				_mark(_cell(q + side * off))
				_mark(_cell(q - side * off))
				off += CELL
			s += CELL * 0.8


func _paint() -> void:
	var data := PackedByteArray()
	data.resize(nx * ny * 4)
	for i in nx * ny:
		var a := 0.0 if now[i] == 1 else (SEEN if seen[i] == 1 else UNSEEN)
		data[i * 4] = 18
		data[i * 4 + 1] = 18
		data[i * 4 + 2] = 18
		data[i * 4 + 3] = int(a * 255.0)
	img = Image.create_from_data(nx, ny, false, Image.FORMAT_RGBA8, data)
	tex.update(img)


## Keep what was known at this moment with the recorder's latest snapshot.
func _record() -> void:
	var rec = world.recorder
	if rec == null or rec.times.is_empty():
		return
	var i: int = rec.times.size() - 1
	if i == _last_snap:
		return
	_last_snap = i
	var lk: Array = []
	for l in lkps:
		lk.append([l["p"], l["t"]])
	rec.know[i] = {"vis": visible_ids.duplicate(), "bodies": bodies.duplicate(), "lkp": lk}


func _draw() -> void:
	if not enabled or world == null:
		return
	for l in lkps:
		var age: float = world.t - float(l["t"])
		var al := clampf(1.0 - age / 120.0, 0.25, 1.0)
		var c: Vector2 = (l["p"] as Vector2) * PX
		var col := Color(0.07, 0.07, 0.07, al)
		var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(11, 0), c + Vector2(0, 11), c + Vector2(-11, 0), c + Vector2(0, -11)])
		draw_colored_polygon(pts, Color(0.93, 0.93, 0.91, 0.55 * al))
		draw_polyline(pts, col, 1.5)
		draw_string(font, c + Vector2(-4, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_string(font, c + Vector2(13, 4), "%ds" % int(age), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
