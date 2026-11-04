extends SceneTree
## Doorway regression test. For every door on every map: a body of radius 0.30 can walk
## from the floor on one side to the floor on the other, the path it takes never puts that
## body inside a wall, a door frame or the furniture, and a shut door stops someone going
## through it without stopping someone walking past it.
##   godot --headless --path . -s res://tests/nav_door_test.gd
##   godot --headless --path . -s res://tests/nav_door_test.gd -- --map=4
##
## Two v1.2.1 regressions live here:
##  - the navigator smoothed a leg by testing one grid cell per 0.25 m of it, so a leg
##    could cross the corner of a blocked cell between two samples and put the officer's
##    body through a door jamb or a wall corner. Measured on the shipped maps: up to 11 cm
##    of the 0.30 m body inside geometry, and 59 of the 175 door crossings doing it.
##  - a shut door's leaf was grown by the body's radius on every side, including across the
##    opening, so an officer walking *past* a closed door a hand's width away was caught by
##    it, stopped dead, and made to open a door he was only walking past.
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")

const BODY := 0.30       # body radius + margin, the radius the nav mask is inflated for
const CLEAR := 0.28      # what a path leg must keep: the body, less the slack of a cell
const SIDE_DEPTH := 2.4  # how far into each room the test looks for a point to walk from
const MAX_LEN := 14.0    # a path between two points inside the two rooms a door joins


func _init() -> void:
	var only := -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			only = Maps.index_of(a.trim_prefix("--map="))
	var problems := 0
	for i in Maps.count():
		if only >= 0 and i != only:
			continue
		var lv = Maps.get_level(i)
		var nav = Nav.new()
		nav.build(lv)
		var bad := _crossings(lv, nav) + _leaves(lv)
		print("map %02d %-32s doors %2d  %s" % [i, lv.map_name, lv.doors.size(),
			"ok" if bad == 0 else "PROBLEMS %d" % bad])
		problems += bad
	print("problems: %d" % problems)
	quit(1 if problems > 0 else 0)   # P0.A1


## Every door: a point on the floor of each room it joins, a path between them, and the
## body fits along every leg of that path.
func _crossings(lv, nav) -> int:
	var bad := 0
	for did in lv.doors:
		var D: Dictionary = lv.doors[did]
		var c: Vector2 = D["c"]
		var n: Vector2 = D["n"]
		var t: Vector2 = D["t"]
		# walk in from a corner of the room rather than straight at the door: that is the
		# way officers arrive, and it is the approach that used to clip the jamb
		var a = _floor_in(lv, nav, c, -n, t, D["a"])
		var b = _floor_in(lv, nav, c, n, t, D["b"])
		if a == null or b == null:
			print("  ! door %s at %s: no free floor on the %s side within %.1f m"
				% [did, str(c), "A" if a == null else "B", SIDE_DEPTH + 0.6])
			bad += 1
			continue
		var pth: PackedVector2Array = nav.find_path(0, a, b)
		if pth.is_empty():
			print("  ! door %s at %s: no path across" % [did, str(c)])
			bad += 1
			continue
		var L: float = nav.path_length(pth)
		if L > MAX_LEN:
			print("  ! door %s at %s: %.1f m to cross a %.1f m gap" % [did, str(c), L, SIDE_DEPTH * 2.0])
			bad += 1
		for k in range(1, pth.size()):
			if not lv.geom.path_clear(pth[k - 1], pth[k], CLEAR):
				print("  ! door %s at %s: the path puts the body through geometry at %s"
					% [did, str(c), str(pth[k])])
				bad += 1
				break
	return bad


## The farthest free floor in `room` within SIDE_DEPTH of the door, preferring a point off
## to the side so the path has to turn into the doorway. A cell centre, so the body has the
## clearance the nav mask promises it. null when the room has no floor there.
func _floor_in(lv, nav, c: Vector2, dir: Vector2, t: Vector2, room: String):
	for depth in [SIDE_DEPTH, 1.9, 1.4, 1.0, 0.7]:
		for lat in [1.4, -1.4, 0.9, -0.9, 0.0]:
			var p: Vector2 = c + dir * float(depth) + t * float(lat)
			var cell: Vector2i = nav.cell_of(p)
			if not nav.is_free(p) or nav.reach[cell.y * nav.nx + cell.x] != 1:
				continue
			var rm: String = lv.room_at(p)
			if not ((lv.is_exterior(room) and lv.is_exterior(rm)) or rm == room):
				continue
			return nav.cell_centre(cell)
	return null


## A shut leaf stops a body going through it, and does not stop one walking past it.
func _leaves(lv) -> int:
	var bad := 0
	for did in lv.doors:
		var D: Dictionary = lv.doors[did]
		if D.get("arch", false) or not D.has("leaf"):
			continue
		lv.reset_doors()
		lv.set_door(did, lv.DOOR_CLOSED)
		var c: Vector2 = D["c"]
		var n: Vector2 = D["n"]
		var t: Vector2 = D["t"]
		var leaf: int = int(D["leaf"])
		# through it: from a metre out, straight at the opening
		if lv.geom.leaf_in_way(c - n * 1.0, c + n * 0.4, 0.25) != leaf:
			print("  ! door %s at %s: a body walking through the shut door is not stopped" % [did, str(c)])
			bad += 1
		# past it: along the wall, from a hand's width off the door out to shoulder to
		# shoulder with it — all inside the radius the leaf used to be grown by
		for off in [0.10, 0.20, 0.28]:
			var a: Vector2 = c + n * float(off) + t * (D["half"] + 1.0)
			var b: Vector2 = c + n * float(off) - t * (D["half"] + 1.0)
			if lv.geom.leaf_in_way(a, b, 0.25) != -1:
				print("  ! door %s at %s: walking past the shut door %.2f m off it stops the officer"
					% [did, str(c), off])
				bad += 1
				break
		# and someone pressed against the leaf, going on through, is still stopped
		if lv.geom.leaf_in_way(c - n * 0.10, c + n * 0.50, 0.25) != leaf:
			print("  ! door %s at %s: a body pressed on the shut door walks through it" % [did, str(c)])
			bad += 1
	lv.reset_doors()
	return bad
