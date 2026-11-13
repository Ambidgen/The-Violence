extends SceneTree
## The operation camera's arithmetic (2026-11-11): zoom steps stay inside the wheel's
## limits, a follow closes in from the fitted view and never pulls back, the view eases
## to what it follows, and "a squad" means its living, present officers (split pairs too).
##   godot --headless --path . -s res://tests/op_camera_test.gd

const OpCamera = preload("res://scripts/view/op_camera.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var fails := 0


func _check(ok: bool, what: String) -> bool:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1
	return ok


func _init() -> void:
	_zoom()
	_ease()
	_points()
	print("op camera test: %s" % ("ALL OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


func _zoom() -> void:
	print("zoom")
	_check(is_equal_approx(OpCamera.zoom_step(1.0, 1), OpCamera.STEP), "a step in multiplies by the step")
	_check(is_equal_approx(OpCamera.zoom_step(OpCamera.zoom_step(1.0, 1), -1), 1.0), "a step out undoes it")
	var z := 1.0
	for k in 40:
		z = OpCamera.zoom_step(z, 1)
	_check(is_equal_approx(z, OpCamera.ZOOM_MAX), "forty steps in stop at the wheel's limit (%.2f)" % z)
	for k in 80:
		z = OpCamera.zoom_step(z, -1)
	_check(is_equal_approx(z, OpCamera.ZOOM_MIN), "and eighty out stop at the other (%.2f)" % z)
	_check(OpCamera.zoom_step(0.0, 1) == 1.0 and OpCamera.zoom_step(NAN, -1) == 1.0, "a zero or broken zoom comes back as 1, never as 0 or NaN")
	_check(is_equal_approx(OpCamera.follow_zoom(0.5, 0.5), 1.0), "a follow from the fitted view closes in to twice it")
	_check(is_equal_approx(OpCamera.follow_zoom(1.8, 0.5), 1.8), "a follow from closer than that leaves the zoom alone")
	_check(is_equal_approx(OpCamera.follow_zoom(0.5, 3.0), OpCamera.ZOOM_MAX), "and never passes the limit")
	_check(is_equal_approx(OpCamera.follow_zoom(0.7, 0.0), 0.7), "with no fitted zoom known it changes nothing")


func _ease() -> void:
	print("easing")
	var a := Vector2(10, 20)
	var b := Vector2(410, -80)
	_check(OpCamera.approach(a, b, 0.0) == a, "no time, no movement")
	_check(OpCamera.approach(a, Vector2.INF, 0.5) == a, "nothing to follow leaves the view where it is")
	_check(OpCamera.approach(a, b, -1.0) == a, "a negative step is no step")
	var p := a
	var last := p.distance_to(b)
	var closer := true
	for k in 120:      # two seconds at sixty frames
		p = OpCamera.approach(p, b, 1.0 / 60.0)
		closer = closer and p.distance_to(b) <= last
		last = p.distance_to(b)
	_check(closer, "every frame is closer than the last")
	_check(last < 1.0, "two seconds is enough to arrive (%.3f px left)" % last)
	var one := OpCamera.approach(a, b, 1.0)
	var p2 := a
	for k in 60:
		p2 = OpCamera.approach(p2, b, 1.0 / 60.0)
	_check(one.distance_to(p2) < 0.5, "one second is one second at any frame rate (%.3f px apart)" % one.distance_to(p2))
	_check(OpCamera.centre([]) == Vector2.INF, "the middle of nobody is nowhere")
	_check(OpCamera.centre([Vector2(0, 0), Vector2(4, 2)]) == Vector2(2, 1), "the middle of two is between them")


func _points() -> void:
	print("who is followed")
	var dept = Department.new()
	dept.found(77)
	var recs: Array = dept.officers.duplicate()
	recs.sort_custom(func(x, y): return Orders.rank_i(x) > Orders.rank_i(y) or (Orders.rank_i(x) == Orders.rank_i(y) and int(x["xp"]) > int(y["xp"])))
	var lv = Maps.get_level(4)
	var nav = Nav.new()
	nav.build(lv)
	var sit := {"id": "T", "type": "gang", "seed": 501, "named": "", "visibility": 2, "intel": [],
		"occupants": [{"role": "suspect", "ech": "untrained", "room": "BED2", "arms": "pistol", "alert": 0, "flight": 0.0}]}
	var mk := func(ids: Array, stage: int) -> Dictionary:
		var od := Orders.empty_orders()
		od["objs"] = [{"kind": "clear", "rooms": []}]
		return {"members": ids, "orders": od, "stage": stage}
	var ids: Array = recs.slice(0, 7).map(func(r): return r["id"])
	var plan := {"squads": [mk.call(ids.slice(0, 4), 0), mk.call(ids.slice(4, 7), 1)]}
	var b: Dictionary = Operation.build_planned(sit, plan, dept, lv, nav)
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	var s0: Array = OpCamera.squad_points(w, 0)
	var s1: Array = OpCamera.squad_points(w, 1)
	_check(s0.size() == 4 and s1.size() == 3, "each squad is its own officers (%d and %d)" % [s0.size(), s1.size()])
	_check(OpCamera.squad_points(w, 5).is_empty() and OpCamera.squad_points(null, 0).is_empty(), "a squad that does not exist, or no operation, is nobody")
	var c0 := OpCamera.centre(s0)
	_check(c0.is_finite() and c0.x > -10.0 and c0.x < lv.W + 10.0 and c0.y > -10.0 and c0.y < lv.H + 10.0, "the squad's middle is on the map (%.1f, %.1f)" % [c0.x, c0.y])
	_check(OpCamera.centre(s0).distance_to(OpCamera.centre(s1)) > 1.0, "two squads staged apart are followed apart")
	for k in 600:
		w.step()
		w.events.clear()
	var moved := OpCamera.centre(OpCamera.squad_points(w, 0))
	_check(moved.is_finite() and moved.distance_to(c0) > 1.0, "the followed point moves with the squad (%.1f m in ten seconds)" % moved.distance_to(c0))
	var act: Array = OpCamera.action_points(w)
	_check(not act.is_empty(), "with nothing fired, the action is the police (%d)" % act.size())
	# an officer who has left the map is no longer followed
	var gone_one = null
	for el in w.teams[0]["elements"]:
		if int(el.get("i", -1)) == 0 and not el.get("child", false):
			for m in el["members"]:
				if m.alive() and not m.gone:
					gone_one = m
					break
	if _check(gone_one != null, "squad 1 still has someone to lose"):
		var n0: int = OpCamera.squad_points(w, 0).size()
		gone_one.gone = true
		_check(OpCamera.squad_points(w, 0).size() == n0 - 1, "an officer who has gone is not followed")
	w.dispose()
