extends SceneTree
## Tests the route-and-speed reference model, separate from combat or balance gates.
const Model = preload("res://tests/clearance_model.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var failures := 0


class NoRooms:
	extends RefCounted
	var rooms := {}


class StraightNav:
	extends RefCounted
	var truncate := false
	func find_path(_prof: int, a: Vector2, b: Vector2) -> PackedVector2Array:
		return PackedVector2Array([a, a if truncate else b])
	func path_length(path: PackedVector2Array) -> float:
		var total := 0.0
		for i in range(1, path.size()):
			total += path[i - 1].distance_to(path[i])
		return total


func check(ok: bool, message: String) -> void:
	print(("ok    " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1


func test_reference_arithmetic() -> void:
	var fake = StraightNav.new()
	var model = Model.new(NoRooms.new(), fake)
	var one := [{"id": "A1", "p": Vector2.ZERO, "speed": 2.0}]
	var target := [{"id": "R:one", "name": "one", "p": Vector2(6, 8)}]
	var r: Dictionary = model.estimate(one, target)
	check(r["ok"] and is_equal_approx(r["metres"], 10.0) and is_equal_approx(r["seconds"], 5.0),
		"route metres are divided by equipped movement speed")
	var two := [{"id": "A1", "p": Vector2(0, 0), "speed": 2.0}, {"id": "A2", "p": Vector2(10, 0), "speed": 2.0}]
	var goals := [{"id": "R:left", "name": "left", "p": Vector2(2, 0)}, {"id": "R:right", "name": "right", "p": Vector2(8, 0)}]
	r = model.estimate(two, goals)
	check(r["ok"] and is_equal_approx(r["metres"], 4.0) and is_equal_approx(r["seconds"], 1.0),
		"parallel agents use the maximum of their assigned route times, not their sum")
	check(r["paths"][0]["targets"] == ["left"] and r["paths"][1]["targets"] == ["right"],
		"greedy assignment chooses the earliest reachable agent/target pair")
	check(not model.estimate([], goals)["ok"] and not model.estimate([{"id": "A1", "p": Vector2.ZERO, "speed": 0.0}], goals)["ok"],
		"missing attackers and nonpositive speeds fail closed")
	fake = StraightNav.new()
	fake.truncate = true
	model = Model.new(NoRooms.new(), fake)
	check(not model.estimate(one, target)["ok"], "a path snapped short of the target is not counted as a route")


func test_equipment_and_rooms() -> void:
	var kit: Dictionary = Equipment.preset("sof")
	var v: float = Model.equipped_walk_speed({"kit": kit})
	check(is_equal_approx(v, World.SPEEDS["walk"] * (1.0 - 0.04 * int(kit["plates"])) * Equipment.speed_factor(kit)),
		"the reference includes both armour and carried-kit speed penalties")
	for mi in [0, 11]:
		var lv = Maps.get_level(mi)
		var nav = Nav.new()
		nav.build(lv)
		var model = Model.new(lv, nav)
		var all_safe: bool = model.missing_rooms.is_empty()
		for room in model.rooms:
			var p: Vector2 = room["p"]
			all_safe = all_safe and lv.room_at(p) == room["name"] and nav.reachable(p)
		check(all_safe and not model.rooms.is_empty(), "map %02d room samples are reachable and inside their named rooms" % mi)


func _init() -> void:
	test_reference_arithmetic()
	test_equipment_and_rooms()
	print("clearance model: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)
