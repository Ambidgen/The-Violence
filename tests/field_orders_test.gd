extends SceneTree
## Orders in the field (2026-11-03): the chief moves a squad to a room mid-operation. It
## gets there by the ordinary paths, consolidates and holds until told to resume or to
## move again; resume picks its own orders back up. Squads only, and replay-safe: the
## same orders at the same moment give the same operation.
##   godot --headless --path . -s res://tests/field_orders_test.gd

const Department = preload("res://scripts/campaign/department.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Orders = preload("res://scripts/campaign/orders.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var dept
var fails := 0


func _check(ok: bool, what: String) -> bool:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1
	return ok


func _init() -> void:
	dept = Department.new()
	dept.found(77)
	var any_moved := false
	for sd in [501, 502, 503]:
		print("seed %d" % sd)
		if _scenario(sd):
			any_moved = true
	_check(any_moved, "at least one seed ran the whole move, hold, move again, resume sequence")
	_determinism()
	print("field orders test: %s" % ("ALL OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


func _officers(n: int) -> Array:
	var recs: Array = dept.officers.duplicate()
	recs.sort_custom(func(a, b): return Orders.rank_i(a) > Orders.rank_i(b) or (Orders.rank_i(a) == Orders.rank_i(b) and int(a["xp"]) > int(b["xp"])))
	return recs.slice(0, n).map(func(r): return r["id"])


func _world(sd: int) -> Object:
	var lv = Maps.get_level(4)
	var nav = Nav.new()
	nav.build(lv)
	var sit := {"id": "T", "type": "gang", "seed": sd, "named": "", "visibility": 2, "intel": [],
		"occupants": [{"role": "suspect", "ech": "untrained", "room": "BED2", "arms": "pistol", "alert": 0, "flight": 0.0}]}
	var od := Orders.empty_orders()
	od["objs"] = [{"kind": "clear", "rooms": []}]
	var plan := {"squads": [{"members": _officers(4), "orders": od, "stage": 0}]}
	var b: Dictionary = Operation.build_planned(sit, plan, dept, lv, nav)
	b["opts"]["time_limit"] = 400.0
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	return w


func _police(w) -> Array:
	return w.ops.filter(func(o): return o.judges and o.alive() and not o.gone)


func _all_in(w, room: String) -> bool:
	var ps := _police(w)
	return not ps.is_empty() and ps.all(func(o): return w.level.room_at(o.pos) == room)


func _step_until(w, limit: float, cond: Callable) -> bool:
	var end: float = w.t + limit
	while not w.over and w.t < end:
		w.step()
		w.events.clear()
		if cond.call():
			return true
	return false


## Returns true when the operation lasted long enough to run every step.
func _scenario(sd: int) -> bool:
	var w = _world(sd)
	var yard := ""
	for r in w.level.rooms:
		if w.level.is_exterior(r):
			yard = r
			break
	_check(yard == "" or w.order_squad_move(0, yard) != "", "an order to the yard is refused: rooms inside only (%s)" % yard)
	_check(w.order_squad_move(0, "NO_SUCH_ROOM") != "", "an order to a room that does not exist is refused")
	_check(w.order_squad_move(3, "KITCHEN") != "", "an order to a squad that does not exist is refused")
	_check(w.order_squad_resume(0) != "", "resume is refused for a squad that is not holding on an order")
	_step_until(w, 4.0, func(): return false)
	var why: String = w.order_squad_move(0, "KITCHEN")
	_check(why == "", "squad 1 takes the order to the kitchen (%s)" % why)
	var el: Dictionary = w.teams[0]["elements"][0]
	_check(el["mode"] == "hold" and el.get("ordered_room", "") == "KITCHEN", "the squad holds on the order")
	var got := _step_until(w, 90.0, func(): return _all_in(w, "KITCHEN"))
	if w.over:
		print("  (the operation ended before the squad reached the kitchen: %.0f s)" % w.t)
		w.dispose()
		return false
	_check(got, "the whole squad reaches the kitchen by the ordinary paths (%.0f s)" % w.t)
	_step_until(w, 6.0, func(): return false)
	_check(w.teams[0]["cleared"].has("KITCHEN"), "a held kitchen counts as cleared")
	# it holds: nobody leaves the kitchen for half a minute and no other room is cleared
	var cleared0: int = w.teams[0]["cleared"].size()
	var left := _step_until(w, 30.0, func(): return not _all_in(w, "KITCHEN") and _police(w).size() > 0)
	if not w.over:
		_check(not left, "the squad stays in the kitchen until told otherwise")
		_check(w.teams[0]["cleared"].size() == cleared0, "and clears nothing else meanwhile")
		_check(el["mode"] == "hold", "still holding after 30 s")
	# move again while holding
	why = w.order_squad_move(0, "LIVING")
	_check(why == "", "a holding squad can be moved again (%s)" % why)
	got = _step_until(w, 90.0, func(): return _all_in(w, "LIVING"))
	if w.over:
		w.dispose()
		return false
	_check(got, "and goes to the living room (%.0f s)" % w.t)
	# resume
	why = w.order_squad_resume(0)
	_check(why == "", "resume is taken (%s)" % why)
	_check(not el.has("ordered_room") and el["mode"] != "hold", "resume returns the squad to its orders (mode %s)" % el["mode"])
	var other := _step_until(w, 90.0, func():
		for o in _police(w):
			var r: String = w.level.room_at(o.pos)
			if not r in ["KITCHEN", "LIVING", "HALL"] and not w.level.is_exterior(r):
				return true
		return false)
	_check(other or w.over, "after resume the squad goes on clearing")
	var marks := 0
	for tl in w.timeline:
		if String(tl.get("text", "")).begins_with("Chief:"):
			marks += 1
	_check(marks == 3, "each order is on the timeline (%d)" % marks)
	w.dispose()
	return true


## Same seed, same orders at the same tick: the same operation.
func _determinism() -> void:
	var sig := []
	for k in 2:
		var w = _world(510)
		var n := 0
		while not w.over and n < 6000:
			if n == 200:
				w.order_squad_move(0, "BED1")
			if n == 1400:
				w.order_squad_resume(0)
			w.step()
			w.events.clear()
			n += 1
		var s := "%.2f|%d" % [w.t, w.winner]
		for o in w.ops:
			s += "|%s:%.2f,%.2f:%s" % [o.id, o.pos.x, o.pos.y, o.alive()]
		sig.append(s)
		w.dispose()
	_check(sig[0] == sig[1], "the same orders at the same moment give the same operation")
