extends SceneTree
## Movement/pathfinding regressions, including whole groups at a narrow door.
##   godot --headless --path . -s res://tests/group_movement_test.gd
const Level = preload("res://scripts/sim/level.gd")
const Geom = preload("res://scripts/sim/geom.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

var failures := 0


class DoorLevel extends Level:
	func _init() -> void:
		id = "test_group_door"
		W = 16.0
		H = 12.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_vwall(0.0, 12.0, 8.0, 0.12, [[5.55, 6.45, "door"]])
		_add_door("D", Vector2(8, 6), Vector2.RIGHT, 0.45)


class PartitionLevel extends Level:
	func _init() -> void:
		id = "test_group_partition"
		W = 14.0
		H = 12.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_wall(Rect2(7.94, 0, 0.12, 12))


class LargeObstacleLevel extends Level:
	func _init() -> void:
		id = "test_group_obstacle"
		W = 20.0
		H = 20.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_wall(Rect2(6, 6, 8, 8))


class DetourLevel extends Level:
	func _init() -> void:
		id = "test_group_detour"
		W = 16.0
		H = 28.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_wall(Rect2(7.94, 0, 0.12, 22))


class SolidLevel extends Level:
	func _init() -> void:
		id = "test_group_no_floor"
		W = 4.0
		H = 4.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_wall(Rect2(0, 0, W, H))


class AvoidLevel extends Level:
	func _init() -> void:
		id = "test_group_avoid"
		W = 16.0
		H = 12.0
		fenced = false
		skip_posts = true

	func _build() -> void:
		_room("AVOID", "Avoid", [Rect2(6, 3, 3, 4)], {"deck": true})


class FailOnceNav:
	extends RefCounted
	var calls := 0

	func find_path(_prof: int, a: Vector2, b: Vector2, _avoid := "") -> PackedVector2Array:
		calls += 1
		return PackedVector2Array() if calls == 1 else PackedVector2Array([a, b])


func check(ok: bool, text: String) -> void:
	print(("ok    " if ok else "FAIL  ") + text)
	if not ok:
		failures += 1


func make_nav(lv):
	lv.build()
	var nav = Nav.new()
	nav.build(lv)
	return nav


func make_world(lv, nav, positions: Array):
	var cfgs: Array = []
	for i in positions.size():
		cfgs.append({"id": "A%d" % (i + 1), "team": 0, "slot": i, "echelon": "regular",
			"good": {}, "bad": {}, "plates": 0, "pos": positions[i], "face": 0.0})
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, cfgs, ["hold", "hold"], 22, [1, 1], {"a_posted": true})
	return w


func clear_path(lv, path: PackedVector2Array) -> bool:
	for i in range(1, path.size()):
		if not lv.geom.path_clear(path[i - 1], path[i], 0.28):
			return false
	return true


func test_navigation_endpoints() -> void:
	check(Nav.new().find_path(0, Vector2(1, 1), Vector2(2, 2)).is_empty(),
		"an unbuilt navigator fails closed instead of returning an unchecked straight line")
	var lv = DoorLevel.new()
	var nav = make_nav(lv)
	var too_close := Vector2(7.74, 3.125)
	var snapped: Vector2 = nav.snap(too_close)
	check(not lv.geom.blocked_disc(snapped, Nav.RADIUS) and nav.reachable(snapped),
		"snap checks the actual body, not just the containing cell centre")
	var outside := Vector2(-2, 3)
	check(not nav.is_free(outside) and not nav.reachable(outside) and nav.snap(outside).x >= Nav.RADIUS,
		"out-of-bounds points are not treated as free cells")
	var recovered: PackedVector2Array = nav.find_path(0, too_close, Vector2(5, 3))
	check(recovered.size() >= 2 and recovered[0] == too_close,
		"a near-wall start retains its true position and can recover toward free floor")

	lv = PartitionLevel.new()
	nav = make_nav(lv)
	var left := Vector2(3.125, 3.125)
	var pocket := Vector2(8.875, 3.125)
	var path: PackedVector2Array = nav.find_path(0, left, pocket)
	check(not path.is_empty() and nav.reachable(path[path.size() - 1])
		and path[path.size() - 1] != pocket and clear_path(lv, path),
		"a disconnected free goal ends on reachable floor without crossing its wall")
	check(nav.find_path(0, pocket, left).is_empty(),
		"an operator in a disconnected pocket is not given a teleporting route across a wall")

	lv = LargeObstacleLevel.new()
	nav = make_nav(lv)
	var deep := Vector2(10, 10)
	var cell: Vector2i = nav.nearest_free(deep)
	check(cell.x >= 0 and nav.reachable(nav.cell_centre(cell)),
		"nearest free searches beyond the old 2.75 m limit for large obstacles")
	check(nav.reachable(nav.snap(deep)), "snapping a point deep inside furniture finds reachable floor")
	check(nav.find_path(0, deep, Vector2(2, 2)).is_empty(),
		"a start inside solid furniture does not produce a route that teleports it out")

	# On Corner Store a body displaced into the gap by the checkout counter is
	# clear, but its geometrically nearest lattice centre clips the adjacent wall.
	# A nearby reachable centre around the counter must be tried instead.
	lv = Maps.get_level(3)
	nav = Nav.new()
	nav.build(lv)
	var by_counter := Vector2(19.00203, 15.60482)
	var route: PackedVector2Array = nav.find_path(0, by_counter, Vector2(12, 7.8))
	check(not lv.geom.blocked_disc(by_counter, Nav.PATH_CLEARANCE) and not route.is_empty()
		and route[0] == by_counter and clear_path(lv, route),
		"a displaced start tries another reachable cell if the nearest one is obstructed")

	lv = SolidLevel.new()
	nav = make_nav(lv)
	check(nav.nearest_free(Vector2(2, 2)) == Vector2i(-1, -1) and not nav.reachable(Vector2(2, 2))
		and nav.find_path(0, Vector2(1, 1), Vector2(3, 3)).is_empty(),
		"a map with no floor has no reachable cells or invented route")


func test_avoid_overlay() -> void:
	var lv = AvoidLevel.new()
	var nav = make_nav(lv)
	var a := Vector2(3, 5)
	var b := Vector2(12, 5)
	var key: String = nav.avoid_key(["AVOID"])
	var mask: PackedByteArray = nav.avoid_mask(key)
	var path: PackedVector2Array = nav.find_path(0, a, b, key)
	var enters := false
	for i in range(1, path.size()):
		var steps := int(ceil(path[i - 1].distance_to(path[i]) / 0.05))
		for j in range(steps + 1):
			var p: Vector2 = path[i - 1].lerp(path[i], float(j) / maxf(1.0, steps))
			var c: Vector2i = nav.cell_of(p)
			if mask[c.y * nav.nx + c.x] == 1:
				enters = true
	check(not path.is_empty() and not enters and clear_path(lv, path),
		"a smoothed group route still goes around an Avoid room")
	var exit: PackedVector2Array = nav.find_path(0, Vector2(7, 5), b, key)
	check(not exit.is_empty() and exit[exit.size() - 1] == b,
		"an operator already in an Avoid room can still leave it")


func test_retry_changed_order() -> void:
	var lv = DoorLevel.new()
	var nav = make_nav(lv)
	var w = make_world(lv, nav, [Vector2(3, 3)])
	var o = w.ops[0]
	var fake = FailOnceNav.new()
	w.nav = fake
	w.move_to(o, Vector2(5, 3), "walk", 0)
	w.move_to(o, Vector2(5, 3), "walk", 0)
	check(fake.calls == 1 and o.path.is_empty(), "an unchanged failed request respects the retry cooldown")
	w.move_to(o, Vector2(5, 3), "walk", 1)
	check(fake.calls == 2 and not o.path.is_empty(),
		"a changed path profile retries immediately after a failed search")
	fake = FailOnceNav.new()
	w.nav = fake
	o.path = PackedVector2Array()
	o.goal = Vector2.INF
	o.ticker.erase("path_fail_until")
	o.avoid_key = "avoid-room"
	w.move_to(o, Vector2(5, 3), "walk", 0)
	w.move_to(o, Vector2(5, 3), "walk", 0, true)
	check(fake.calls == 2 and not o.path.is_empty(),
		"changing the avoid order retries immediately after a failed search")
	w.dispose()


func test_stopped_and_sidestep() -> void:
	var lv = DoorLevel.new()
	var nav = make_nav(lv)
	check(lv.geom.move_clear(Vector2(7.96, 3), Vector2(7.90, 3), 0.28),
		"an actor embedded in a wall can recover toward the nearest face")
	check(not lv.geom.move_clear(Vector2(7.96, 3), Vector2(8.10, 3), 0.28),
		"recovery from inside a thin wall cannot pass through its far face")
	var w = make_world(lv, nav, [Vector2(7.62, 3.125), Vector2(7.35, 3.125)])
	var o = w.ops[0]
	var before: Vector2 = o.pos
	w._grid_build()
	w.stop(o)
	w._move2(o)
	check(o.pos == before and o.vel == Vector2.ZERO,
		"a stopped officer is not shoved into a wall by a nearby teammate")
	o.pos = Vector2(4, 3)
	w.ops[1].pos = Vector2(4.2, 3)
	before = o.pos
	w._grid_build()
	w._move2(o)
	check(o.pos == before, "a stopped officer also holds position in open ground")
	w.dispose()

	w = make_world(lv, nav, [Vector2(7.65, 6)])
	lv.set_door("D", lv.DOOR_CLOSED)
	o = w.ops[0]
	o.sidestep = {"dir": Vector2.RIGHT, "left": 1.0}
	var crossed := false
	for i in 30:
		w.t += World.DT
		w._grid_build()
		w._move2(o)
		if o.pos.x >= 8.0:
			crossed = true
	check(not crossed and lv.door_shut("D"), "a sidestep cannot carry an officer through a shut door")
	w.dispose()


## Integrate everyone in deterministic order, without combat brains changing the goals.
## The group starts clear of the walls. Check every tick, not only terminal positions.
func cross_door(two_way: bool) -> Dictionary:
	var lv = DoorLevel.new()
	var nav = make_nav(lv)
	var positions: Array = [Vector2(6.1, 5.3), Vector2(6.1, 6.7), Vector2(5.3, 5.3),
		Vector2(5.3, 6.7), Vector2(4.5, 5.3), Vector2(4.5, 6.7)]
	var goals: Array = [Vector2(11, 5), Vector2(11, 7), Vector2(12, 5),
		Vector2(12, 7), Vector2(13, 5), Vector2(13, 7)]
	if two_way:
		positions = [Vector2(6.1, 5.3), Vector2(6.1, 6.7), Vector2(5.3, 5.3), Vector2(5.3, 6.7),
			Vector2(9.9, 5.3), Vector2(9.9, 6.7), Vector2(10.7, 5.3), Vector2(10.7, 6.7)]
		goals = [Vector2(11, 5), Vector2(11, 7), Vector2(12, 5), Vector2(12, 7),
			Vector2(5, 5), Vector2(5, 7), Vector2(4, 5), Vector2(4, 7)]
	var w = make_world(lv, nav, positions)
	lv.set_door("D", lv.DOOR_CLOSED)
	var clips := 0
	var crossed_leaf := 0
	var too_fast := 0
	var arrived := 0
	var finish := -1.0
	for tick in 900:
		w.t += World.DT
		w._grid_build()
		for i in positions.size():
			if w.at(w.ops[i], goals[i], 0.3):
				w.stop(w.ops[i])
			else:
				w.move_to(w.ops[i], goals[i], "run", 0)
		for i in positions.size():
			var o = w.ops[i]
			var from: Vector2 = o.pos
			var was_closed: bool = lv.door_shut("D")
			w._integrate2(o)
			if lv.geom.blocked_disc(o.pos, 0.28):
				clips += 1
			if was_closed and lv.door_shut("D") and lv.geom.leaf_in_way(from, o.pos, 0.20) >= 0:
				crossed_leaf += 1
			if o.vel.length() > o.speed + 0.02:
				too_fast += 1
		arrived = 0
		for i in positions.size():
			if w.at(w.ops[i], goals[i], 0.4):
				arrived += 1
		if arrived == positions.size():
			finish = w.t
			break
	var end: Array = []
	for o in w.ops:
		end.append(o.pos.snapped(Vector2(0.001, 0.001)))
	var result := {"finish": finish, "arrived": arrived, "count": positions.size(), "clips": clips,
		"leaf": crossed_leaf, "too_fast": too_fast, "paths": nav.path_calls, "end": str(end)}
	w.dispose()
	return result


func test_groups() -> void:
	for two_way in [false, true]:
		var r := cross_door(two_way)
		var name := "opposing groups" if two_way else "a six-person group"
		print("  ", name, ": ", r)
		check(r["arrived"] == r["count"] and r["finish"] > 0.0 and r["finish"] < 25.0,
			name + " clear a narrow closed door without a lasting jam")
		check(r["clips"] == 0 and r["leaf"] == 0,
			name + " keep their bodies out of walls and shut door leaves")
		check(r["too_fast"] == 0, name + " never gain extra speed from separation")
		check(r["paths"] < 100, name + " do not continually re-search the map")
		var repeat := cross_door(two_way)
		check(r == repeat, name + " movement is deterministic on repetition")


## Exercise the real hunt/formation brain and the whole World.step() pipeline too.
## Separation can displace the lead off a waypoint; the next replan must produce a
## leg the movement integrator can actually follow rather than jamming at the jamb.
func test_hunting_squad() -> void:
	for disciplined in [false, true]:
		var lv = DoorLevel.new()
		var nav = make_nav(lv)
		lv.patrol = [Vector2(12, 6)]
		var positions: Array = [Vector2(6.1, 5.3), Vector2(6.1, 6.7), Vector2(5.3, 5.3),
			Vector2(5.3, 6.7), Vector2(4.5, 5.3)]
		var w = make_world(lv, nav, positions)
		w.endless = true
		if disciplined:
			for o in w.ops:
				o.good["GD07"] = true
				o.good["GD10"] = true
		var tm: Dictionary = w.teams[0]
		tm["patrol"] = lv.patrol
		tm["posted"] = false
		w.brain._set_mode(tm, tm["elements"][0], "hunt")
		lv.set_door("D", lv.DOOR_CLOSED)
		var clips := 0
		var reached := false
		for tick in 900:
			w.step()
			var across := 0
			for o in w.ops:
				if lv.geom.blocked_disc(o.pos, 0.28):
					clips += 1
				if o.pos.x > 8.5:
					across += 1
			if across == positions.size():
				reached = true
				break
		var name := "disciplined hunt squad" if disciplined else "ordinary hunt squad"
		check(reached and clips == 0 and not lv.door_shut("D"),
			name + " opens the door and gets everyone through without clipping")
		check(nav.path_calls < 80, name + " does not endlessly replan at the jamb")
		w.dispose()


func test_detour_watchdog() -> void:
	var lv = DetourLevel.new()
	var nav = make_nav(lv)
	var w = make_world(lv, nav, [Vector2(6, 2)])
	var o = w.ops[0]
	var target := Vector2(10, 2)
	var abandoned := false
	for tick in 1500:
		w.t += World.DT
		w._grid_build()
		if w.brain._stuck_on(o, target):
			abandoned = true
			break
		w.move_to(o, target, "walk", 0)
		w._move2(o)
		if w.at(o, target, 0.4):
			break
	check(not abandoned and w.at(o, target, 0.4),
		"the squad progress watchdog follows a long valid detour instead of abandoning it")
	o.ticker.erase("prog")
	o.pos = Vector2(6, 2)
	o.goal = target
	o.path = PackedVector2Array([o.pos, target])
	o.path_i = 1
	var initially_stuck: bool = w.brain._stuck_on(o, target)
	w.t += 8.1
	check(not initially_stuck and w.brain._stuck_on(o, target),
		"the progress watchdog still abandons a genuinely motionless route")
	w.dispose()


func test_formation_reassignment() -> void:
	var lv = DoorLevel.new()
	var nav = make_nav(lv)
	var w = make_world(lv, nav, [Vector2(3, 3), Vector2(4, 4), Vector2(3, 5)])
	var tm: Dictionary = w.teams[0]
	var el: Dictionary = tm["elements"][0]
	tm["patrol"] = [Vector2(6, 9)]
	el["hunt_i"] = 0
	var follower = w.ops[2]
	w.brain._task_hunt(follower, tm, el)
	var old_key: String = follower.ticker.get("form_key", "")
	var old_slot: Vector2 = follower.ticker["form_p"]
	w.ops[0].state = "down"
	w.brain._task_hunt(follower, tm, el)
	check(follower.ticker.get("form_key", "") != old_key and follower.ticker["form_p"] != old_slot,
		"hunt followers recalculate slots when the leader or their squad position changes")
	# Switching modes at the same destination must not reuse a different
	# formation's cached slot.
	el["sweep_target"] = Vector2(6, 9)
	el["sweep"] = [Vector2(6, 9)]
	old_key = follower.ticker["form_key"]
	w.brain._task_sweep(follower, el)
	check(follower.ticker.get("form_key", "") != old_key,
		"sweep and hunt do not share stale formation slots")
	w.dispose()

	w = make_world(lv, nav, [Vector2(2, 2), Vector2(3, 3), Vector2(2, 6)])
	el = w.teams[0]["elements"][0]
	el["dest"] = Vector2(12, 6)
	follower = w.ops[2]
	w.brain._task_transit(follower, el)
	old_key = follower.ticker.get("form_key", "")
	old_slot = follower.ticker.get("form_p", Vector2.INF)
	w.ops[0].state = "down"
	w.brain._task_transit(follower, el)
	check(follower.ticker.get("form_key", "") != old_key and follower.ticker.get("form_p", Vector2.INF) != old_slot,
		"transit followers recalculate slots after a casualty")
	w.dispose()


## PF10 must allow a real detour to a check room, but not wait forever if no progress
## is possible. These real maps previously skipped the room after 12 s of walking.
func test_check_room_progress() -> void:
	Equipment.armory = {}
	for c in [[4, "LAUNDRY", 100.0], [11, "KIOSK", 220.0]]:
		var lv = Maps.get_level(c[0])
		var nav = Nav.new()
		nav.build(lv)
		var w = World.new()
		w.keep_events = false
		w.setup(lv, nav, Teams.team_with_preset_kit(lv, 0, {"n": 1, "ech": "sof"}), ["assault", "hold"], 101)
		w.endless = true
		var check_started := -1.0
		while w.t < c[2] and not w.teams[0]["cleared"].has(c[1]) and not w.teams[0]["skipped"].has(c[1]):
			w.step()
			var el: Dictionary = w.teams[0]["elements"][0]
			if el["phase"] == "check" and el["task"].get("into", "") == c[1] and check_started < 0.0:
				check_started = w.t
		check(check_started >= 0.0 and w.t - check_started > 12.0 and w.teams[0]["cleared"].has(c[1])
			and not w.teams[0]["skipped"].has(c[1]), "%s is checked after a longer-than-12-second route" % c[1])
		w.dispose()

	var lv = Maps.get_level(0)
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, Teams.team_with_preset_kit(lv, 0, {"n": 1, "ech": "sof"}), ["assault", "hold"], 101)
	var tm: Dictionary = w.teams[0]
	var el: Dictionary = tm["elements"][0]
	w.brain._release(tm, el)
	el["task"] = {"door": "BATH", "into": "BATH", "check": true}
	w.brain._begin_task(tm, el)
	el["ctl"]["checker"] = "A1"
	# Invoke the team watchdog with an intentionally motionless operator: no combat,
	# action or route progress can mask a real jam.
	for tick in 420:
		w.t += World.DT
		w.brain._assault_tick(tm, el, [w.by_id["A1"]])
		if tm["skipped"].has("BATH"):
			break
	check(tm["skipped"].has("BATH") and not tm["cleared"].has("BATH"),
		"a genuinely motionless checker eventually reports the room unchecked")
	w.dispose()


func test_check_room_closed_door_and_reassignment() -> void:
	var lv = Maps.get_level(0)
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, Teams.team_with_preset_kit(lv, 0, {"n": 2, "ech": "sof"}), ["assault", "hold"], 101,
		[1, 1], {"doors": {"BATH": "closed"}})
	w.endless = true
	var replaced := false
	var falsely_checked := false
	while w.t < 120.0 and not w.teams[0]["cleared"].has("BATH") and not w.teams[0]["skipped"].has("BATH"):
		w.step()
		var el: Dictionary = w.teams[0]["elements"][0]
		if el["phase"] == "check" and el["task"].get("into", "") == "BATH":
			if lv.door_shut("BATH") and el["ctl"].has("check_done_t"):
				falsely_checked = true
			var id: String = el["ctl"].get("checker", "")
			if id != "" and not replaced:
				w.by_id[id].state = "dead"
				replaced = true
	check(replaced and w.teams[0]["cleared"].has("BATH") and not w.teams[0]["skipped"].has("BATH"),
		"a surviving teammate takes over when the checker goes down")
	check(not falsely_checked and not lv.door_shut("BATH"), "a closed check-room door is opened before the room is checked")
	w.dispose()


## This actual two-person stack oscillated in place against its own teammate at
## W FRONT. Alternating forward/backward ticks reset the old per-tick jam timer,
## and the room was eventually marked clear by timeouts without either entering.
func test_oscillating_doorway_stack() -> void:
	Equipment.armory = {}
	var lv = Maps.get_level(5)
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, Teams.team_with_preset_kit(lv, 0, {"n": 2, "ech": "sof"}), ["assault", "hold"], 816001)
	w.endless = true
	var entered := {}
	var clipped := false
	while w.t < 30.0 and not w.teams[0]["cleared"].has("W LIVING"):
		var before := {}
		for o in w.teams[0]["members"]:
			before[o.id] = o.pos
		w.step()
		for o in w.teams[0]["members"]:
			if o.room == "W LIVING":
				entered[o.id] = true
			if not lv.geom.move_clear(before[o.id], o.pos, Geom.MOVE_CLEARANCE):
				clipped = true
	check(w.teams[0]["cleared"].has("W LIVING") and entered.size() == 2,
		"an oscillating two-person Duplex stack enters and clears its first room within 30 s")
	check(not clipped, "doorway-jam recovery never passes either operator through a wall")
	w.dispose()


## A casualty treatment delayed this Plaza squad so its 45 s approach and 9 s
## entry deadlines both expired while the only survivor was still far outside.
## A timed-out entry must not be treated as a physically cleared room.
func test_entry_timeout_does_not_clear_from_afar() -> void:
	Equipment.armory = {}
	var lv = Maps.get_level(11)
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	var cfgs: Array = Teams.team_with_preset_kit(lv, 0, {"n": 2, "ech": "sof"}) \
		+ Teams.team_with_preset_kit(lv, 1, {"n": 2, "ech": "regular"})
	w.setup(lv, nav, cfgs, ["assault", "hold"], 822001, [1, 1], {"b_stay": true})
	var entered := false
	var observed_timeout := false
	while w.t < 180.0 and not w.teams[0]["cleared"].has("HALL"):
		w.step()
		if w.over:
			if w.winner != 0:
				break
			w.over = false
			w.endless = true
		var el: Dictionary = w.teams[0]["elements"][0]
		if el["task"].get("into", "") == "HALL":
			if el["phase"] == "entry" and w.t - float(el["phase_t"]) > 9.0:
				observed_timeout = true
			for o in w.teams[0]["members"]:
				if o.fighting() and o.room == "HALL":
					entered = true
	# CL2 (2026-11-03): the approach fallback now waits while the survivor is still gaining
	# route, so the entry no longer starts with him across the map and the 9 s timeout this
	# test used to provoke does not occur (observed_timeout is kept for diagnosis). The
	# invariant is unchanged: the hall is cleared, and only after someone has entered it.
	check(entered and w.teams[0]["cleared"].has("HALL"),
		"a long Plaza entry is not marked clear from across the map")
	w.dispose()


## Rear security can take over if every initially designated entrant is lost.
func test_entry_reassigns_rear_security() -> void:
	Equipment.armory = {}
	var lv = Maps.get_level(0)
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, Teams.team_with_preset_kit(lv, 0, {"n": 5, "ech": "sof"}), ["assault", "hold"], 101)
	var tm: Dictionary = w.teams[0]
	var el: Dictionary = tm["elements"][0]
	w.brain._release(tm, el)
	el["task"] = {"door": "BATH", "into": "BATH", "check": false}
	w.brain._begin_task(tm, el)
	el["phase"] = "entry"
	el["phase_t"] = -20.0
	var removed := 0
	for m in el["members"]:
		if el["entry"][m.id]["enters"]:
			m.state = "dead"
			removed += 1
	var survivors: Array = w.brain._alive(el)
	w.brain._assault_tick(tm, el, survivors)
	var promoted := 0
	for m in survivors:
		if el["entry"][m.id]["enters"]:
			promoted += 1
	check(removed > 0 and not survivors.is_empty() and promoted == 1 and el["phase"] == "entry"
		and not tm["cleared"].has("BATH"), "a surviving rear guard takes over without a remote clear")
	w.dispose()


func _init() -> void:
	test_navigation_endpoints()
	test_avoid_overlay()
	test_retry_changed_order()
	test_stopped_and_sidestep()
	test_groups()
	test_hunting_squad()
	test_detour_watchdog()
	test_formation_reassignment()
	test_check_room_progress()
	test_check_room_closed_door_and_reassignment()
	test_oscillating_doorway_stack()
	test_entry_timeout_does_not_clear_from_afar()
	test_entry_reassigns_rear_security()
	print("group movement: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)
