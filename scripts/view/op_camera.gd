extends RefCounted
## The operation camera's arithmetic (trunk merge, 2026-11-11).
##
## The wheel, middle- or right-drag and Home have moved the plan since 1.3, but nothing on
## screen said so and nothing followed the people. This adds the parts that were missing:
## zoom in steps (for buttons), the point a followed squad or the action is at, and the
## easing towards it. No scene and no input here: main.gd owns the Camera2D and calls
## these, and tests/op_camera_test.gd checks them headless.

const ZOOM_MIN := 0.3
const ZOOM_MAX := 4.0
const STEP := 1.25            # one press of + or -
const FOLLOW_ZOOM := 2.0      # a follow that starts from the fitted view closes in this much
const EASE := 6.0             # per second: how fast the view catches up with what it follows
const KEY_PAN := 620.0        # screen pixels a second on W A S D


## One step in (dir > 0) or out, inside the limits the wheel uses.
static func zoom_step(zoom: float, dir: int) -> float:
	if not is_finite(zoom) or zoom <= 0.0:
		return 1.0
	return clampf(zoom * (STEP if dir > 0 else 1.0 / STEP), ZOOM_MIN, ZOOM_MAX)


## The zoom a follow starts at: never further out than FOLLOW_ZOOM times the fitted view,
## and never changed if the chief is already closer than that.
static func follow_zoom(zoom: float, fit: float) -> float:
	if not is_finite(fit) or fit <= 0.0:
		return clampf(zoom, ZOOM_MIN, ZOOM_MAX)
	return clampf(maxf(zoom, fit * FOLLOW_ZOOM), ZOOM_MIN, ZOOM_MAX)


## The middle of some points; Vector2.INF when there are none (nothing to follow).
static func centre(points: Array) -> Vector2:
	if points.is_empty():
		return Vector2.INF
	var c := Vector2.ZERO
	for p in points:
		c += p
	return c / float(points.size())


## Where the view is this frame on its way to goal. An unknown goal leaves it where it is.
static func approach(pos: Vector2, goal: Vector2, delta: float) -> Vector2:
	if not goal.is_finite():
		return pos
	return pos.lerp(goal, 1.0 - exp(-EASE * maxf(delta, 0.0)))


## Where squad i's living, present officers are (metres). A squad that has split into
## pairs is still one squad: its children count.
static func squad_points(w, i: int) -> Array:
	var out: Array = []
	if w == null or w.teams.is_empty():
		return out
	var seen := {}
	for el in w.teams[0]["elements"]:
		var mine: bool = int(el.get("i", -1)) == i and not el.get("child", false)
		var kid: bool = el.get("child", false) and int(el.get("parent", -1)) == i
		if not (mine or kid):
			continue
		for m in el.get("members", []):
			if m.alive() and not m.gone and not seen.has(m):
				seen[m] = true
				out.append(m.pos)
	return out


## Where the action is (metres): anyone who has fired in the last 2.5 s, with the police
## who are moving; if nothing is happening, the police.
static func action_points(w) -> Array:
	var out: Array = []
	if w == null:
		return out
	for o in w.ops:
		if o.alive() and not o.gone and (w.t - o.last_shot_t < 2.5 or (o.team == 0 and o.moving)):
			out.append(o.pos)
	if out.is_empty():
		for o in w.ops:
			if o.alive() and not o.gone and o.team == 0:
				out.append(o.pos)
	return out
