extends Node2D
## The fog of war (v0.7): during a planned operation the player sees only what the
## department knows.
##   - officers' own positions, always;
##   - what an officer wearing a body camera can see, live (a 140 degree view, 30 m);
##   - everyone else only as last-known positions from radio callouts.
## Ground once seen stays lighter than ground never seen. Blood and bodies appear when a
## camera sees them. Without body cameras, only the officers and the callouts show.
##
## Every snapshot the recorder takes gets a copy of what was known, so rewinding shows
## the operation as it was seen at the time; the debrief replay lifts the fog.

const PX := 40.0
const CELL := 0.5
const CAM_R := 30.0
const CAM_HALF := 1.2
const RAYS := 56
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
	var cams: Array = []
	for o in world.ops:
		if o.judges and o.alive() and not o.gone:
			_mark_disc(o.pos, 1.2)
			if o.bodycam:
				cams.append(o)
				_cast(o)
	visible_ids.clear()
	for e in world.ops:
		if e.judges or e.gone:
			continue
		if now[_cell(e.pos)] != 1:
			continue
		var seen_by := false
		for o2 in cams:
			if o2.pos.distance_to(e.pos) > CAM_R:
				continue
			if absf(angle_difference(o2.body_dir, (e.pos - o2.pos).angle())) > CAM_HALF and o2.pos.distance_to(e.pos) > 1.5:
				continue
			if world.geom.sight_clear(o2.pos, o2.eye(), e.pos, maxf(0.3, e.eye() - 0.4)):
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


## A fan of sight lines across the camera's view; every cell along each, up to where
## sight is blocked, is in view.
func _cast(o) -> void:
	var g = world.geom
	for k in RAYS:
		var a: float = o.body_dir - CAM_HALF + 2.0 * CAM_HALF * k / float(RAYS - 1)
		var dir := Vector2.from_angle(a)
		var end: Vector2 = o.pos + dir * CAM_R
		end = Vector2(clampf(end.x, 0.05, level.W - 0.05), clampf(end.y, 0.05, level.H - 0.05))
		var full: float = o.pos.distance_to(end)
		var f: float = g.sight_reach(o.pos, 1.6, end, 1.1)
		var reach := f * full + 0.25
		var s := 0.0
		while s <= reach:
			var q: Vector2 = o.pos + dir * s
			_mark(_cell(q))
			if s > 9.0:
				_mark(_cell(q + dir.orthogonal() * CELL))
				_mark(_cell(q - dir.orthogonal() * CELL))
			s += CELL * 0.7


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
		var col := Color(0.08, 0.08, 0.08, al)
		var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(11, 0), c + Vector2(0, 11), c + Vector2(-11, 0), c + Vector2(0, -11)])
		draw_colored_polygon(pts, Color(1, 1, 1, 0.55 * al))
		draw_polyline(pts, col, 1.5)
		draw_string(font, c + Vector2(-4, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_string(font, c + Vector2(13, 4), "%ds" % int(age), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
