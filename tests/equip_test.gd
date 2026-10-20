extends SceneTree
## The v0.7.5 gate: every item in the equipment database has a test where carrying it
## changes the outcome, and the special operations helmet stops one head hit and never
## a second. Each test runs N seeds with the item and N without, on the same map with
## the same people, and compares one measure (means over the seeds).
##   godot --headless --path . -s res://tests/equip_test.gd -- --n=12 [--only=ram] [--v]
##
## Two harnesses:
##   range:  one shooter (Regular stats, no hold habits) posted in the open on the plaza,
##           three targets at a set distance facing away. Measures the shooter's hits per
##           round, time on target, first shot, and how many hits put a target down.
##   op:     a police squad of five against a held house (map 04 unless named), with
##           the item on the squad or on its point man.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Op = preload("res://scripts/sim/op.gd")

var args := {}
var _navs := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "12"))
	var tests: Array = GATES.keys()
	if args.has("only"):
		tests = String(args["only"]).split(",")
	var t0 := Time.get_ticks_msec()
	var passed := 0
	var lines: Array = []
	print("item              measure                                              with   without   gate")
	for tn in tests:
		var spec: Dictionary = GATES[tn]
		if tn == "sof_helmet":
			var res: Array = _helmet_unit()
			var ok0: bool = res[0]
			passed += 1 if ok0 else 0
			print("%-17s %-52s %6s  %7s   %s" % [tn, spec["measure"], res[1], res[2], "PASS" if ok0 else "FAIL"])
			continue
		var wv: Array = []
		var wo: Array = []
		# the range is cheap and its effects small: four times the seeds
		for k in (n * 4 if spec.get("range", false) else n):
			var a = call("t_" + tn, true, 700 + k)
			var b = call("t_" + tn, false, 700 + k)
			if a != null:
				wv.append(a)
			if b != null:
				wo.append(b)
		var ma := _pool(wv) if spec.get("pooled", false) else _mean(wv)
		var mb := _pool(wo) if spec.get("pooled", false) else _mean(wo)
		var ok: bool = (ma - mb) * float(spec["dir"]) >= float(spec["margin"])
		passed += 1 if ok else 0
		print("%-17s %-52s %6.2f  %7.2f   %s" % [tn, spec["measure"], ma, mb, "PASS" if ok else "FAIL"])
		if args.has("v"):
			print("    with: %s\n    without: %s" % [str(wv), str(wo)])
	print("%d of %d items change the outcome (%d runs each way, %d s)" % [passed, tests.size(), n, (Time.get_ticks_msec() - t0) / 1000])
	quit()


## measure, direction (+1: higher with the item), smallest difference that counts
const GATES := {
	"compact_pistol": {"measure": "s to the first shot from the holster (less)", "dir": -1, "margin": 0.08, "range": true},
	"heavy_pistol": {"measure": "targets killed outright per hit, 6 m (more)", "dir": 1, "margin": 0.03, "range": true},
	"smg": {"measure": "share of police rounds through a wall (less)", "dir": -1, "margin": 0.03, "pooled": true},
	"sbr": {"measure": "s on target per acquisition, 6 m (less)", "dir": -1, "margin": 0.01, "range": true},
	"assault_rifle": {"measure": "targets killed outright per hit, 15 m (more)", "dir": 1, "margin": 0.02, "range": true},
	"battle_rifle": {"measure": "targets killed outright per hit, 15 m (more)", "dir": 1, "margin": 0.04, "range": true},
	"shotgun": {"measure": "hits per round, 12 m (more)", "dir": 1, "margin": 0.08, "range": true},
	"marksman": {"measure": "hits per round, 38 m (more)", "dir": 1, "margin": 0.08, "range": true},
	"irons": {"measure": "s on target per acquisition, 18 m (more)", "dir": 1, "margin": 0.02, "range": true},
	"magnified": {"measure": "hits per round, 38 m (more)", "dir": 1, "margin": 0.08, "range": true},
	"flashbang": {"measure": "officers hit in the entry of a room held by 3 rifles (fewer)", "dir": -1, "margin": 0.3},
	"ram": {"measure": "s to the first officer inside, outer doors locked (less)", "dir": -1, "margin": 3.0},
	"breach": {"measure": "s to the first officer inside, outer doors locked (less)", "dir": -1, "margin": 3.0},
	"shield": {"measure": "rounds through to an officer facing 3 rifles, 10 m (fewer)", "dir": -1, "margin": 0.3, "range": true},
	"light": {"measure": "s for police to recognize someone, at night (less)", "dir": -1, "margin": 0.05},
	"medkit": {"measure": "share of the downed who die after the operation (less)", "dir": -1, "margin": 0.1},
	"taser": {"measure": "s until an unarmed man who will not give up is cuffed (less)", "dir": -1, "margin": 10.0},
	"launcher": {"measure": "s until an unarmed man who will not give up is cuffed (less)", "dir": -1, "margin": 10.0},
	"sof_helmet": {"measure": "head hits survived: first, second", "dir": 1, "margin": 0},
}


## [numerator, denominator] pairs summed before dividing.
func _pool(a: Array) -> float:
	var n := 0.0
	var d := 0.0
	for v in a:
		n += float(v[0])
		d += float(v[1])
	return n / maxf(1.0, d)


func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(1.0, a.size())


func _nav(mi: int):
	if not _navs.has(mi):
		var lv = Maps.get_level(mi)
		var nv = Nav.new()
		nv.build(lv)
		_navs[mi] = nv
	return _navs[mi]


func _cfg(id: String, team: int, slot: int, ech: String, kit: Dictionary, pos: Vector2, face: float, hold_layer := false) -> Dictionary:
	var good := {}
	for g in Habits.preset_good(ech):
		if hold_layer or not String(g).begins_with("HD"):
			good[g] = true
	var bad := {}
	for b in Habits.stress_bad_ids():
		bad[b] = true
	return {"id": id, "team": team, "slot": slot, "echelon": ech, "good": good, "bad": bad,
		"plates": int(Equipment.normalize(kit)["plates"]), "exp": Habits.PRESET_EXP[ech], "pos": pos, "face": face,
		"enabled": true, "kit": kit}


func _kit(primary: String, secondary := "service_pistol", gear := {}, extra := {}) -> Dictionary:
	var k := {"primary": primary, "secondary": secondary, "optic": "red_dot", "armour": "none", "plates": 0,
		"head": "none", "gear": gear}
	for key in extra:
		k[key] = extra[key]
	return Equipment.normalize(k)


# ------------------------------------------------------------------ range harness
## A lane on the plaza: a shooter at a and three targets around a + dist along x,
## all in the open with clear sight of each other.
func _lane(dist: float) -> Array:
	var lv = Maps.get_level(11)
	var nv = _nav(11)
	var y := 4.0
	while y < lv.H - 4.0:
		var x := 4.0
		while x + dist < lv.W - 4.0:
			var a := Vector2(x, y)
			var ok: bool = nv.reachable(a) and not lv.is_inside(a)
			var tg: Array = []
			if ok:
				for dy in [-1.6, 0.0, 1.6]:
					var b := Vector2(x + dist, y + dy)
					if not nv.reachable(b) or lv.is_inside(b) or not lv.geom.sight_clear(a, 1.6, b, 1.6):
						ok = false
						break
					tg.append(b)
			if ok:
				return [a, tg]
			x += 1.0
		y += 1.0
	return []


## One range run: returns the shooter after the fight (or 20 s).
func _range(kit: Dictionary, dist: float, sd: int, alert := 1, opts := {}, t_max := 20.0) -> Dictionary:
	var lane := _lane(dist)
	var lv = Maps.get_level(11)
	var cfgs: Array = [_cfg("A1", 0, 0, "regular", kit, lane[0], 0.0)]
	cfgs[0]["alert"] = alert
	for k in 3:
		var tk := _kit("", "")
		cfgs.append(_cfg("B%d" % (k + 1), 1, k, "untrained", tk, lane[1][k], 0.0))
	var o2 := {"a_posted": true, "b_stay": true, "b_posted": true}
	for key in opts:
		o2[key] = opts[key]
	var w = World.new()
	w.keep_events = false
	w.setup(lv, _nav(11), cfgs, ["hold", "hold"], sd, [alert, 0], o2)
	while not w.over and w.t < t_max:
		w.step()
		w.events.clear()
	var a = w.by_id["A1"]
	var down := 0
	var dead := 0
	for o in w.ops:
		if o.team == 1 and o.state != "ok":
			down += 1
		if o.team == 1 and o.state == "dead":
			dead += 1
	var out := {"shots": a.shots, "hits": a.hits, "down": down, "dead": dead, "first": float(a.ticker.get("first_shot_t", t_max)),
		"tot": float(w.stat.get("tot_sum_0", 0.0)) / maxf(1.0, float(w.stat.get("tot_n_0", 0))), "tot_n": int(w.stat.get("tot_n_0", 0))}
	w.dispose()
	return out


func _hit_rate(r: Dictionary):
	return float(r["hits"]) / float(r["shots"]) if r["shots"] > 0 else null


func _down_per_hit(r: Dictionary):
	return float(r["down"]) / float(r["hits"]) if r["hits"] > 0 else null


func _kill_per_hit(r: Dictionary):
	return float(r["dead"]) / float(r["hits"]) if r["hits"] > 0 else null


func t_compact_pistol(on: bool, sd: int):
	var r := _range(_kit("", "compact_pistol" if on else "service_pistol"), 6.0, sd, 0)
	return r["first"]


func t_heavy_pistol(on: bool, sd: int):
	return _kill_per_hit(_range(_kit("", "heavy_pistol" if on else "service_pistol"), 6.0, sd))


func t_sbr(on: bool, sd: int):
	var r := _range(_kit("sbr" if on else "carbine"), 6.0, sd)
	return r["tot"] if r["tot_n"] > 0 else null


func t_assault_rifle(on: bool, sd: int):
	return _kill_per_hit(_range(_kit("assault_rifle" if on else "carbine"), 15.0, sd))


func t_battle_rifle(on: bool, sd: int):
	return _kill_per_hit(_range(_kit("battle_rifle" if on else "carbine"), 15.0, sd))


func t_shotgun(on: bool, sd: int):
	return _hit_rate(_range(_kit("shotgun" if on else "carbine"), 12.0, sd))


func t_marksman(on: bool, sd: int):
	return _hit_rate(_range(_kit("marksman" if on else "carbine"), 38.0, sd))


func t_irons(on: bool, sd: int):
	var r := _range(_kit("carbine", "service_pistol", {}, {"optic": "irons" if on else "red_dot"}), 18.0, sd)
	return r["tot"] if r["tot_n"] > 0 else null


func t_magnified(on: bool, sd: int):
	return _hit_rate(_range(_kit("carbine", "service_pistol", {}, {"optic": "magnified" if on else "red_dot"}), 38.0, sd))


# ------------------------------------------------------------------ operation harness
## Five police (Police tactical stats) assault a house held by five Militia. kits: one
## per officer. Returns the world after the fight (caller disposes).
func _op(mi: int, kits: Array, sd: int, opts := {}, b_kit := {}, nb := 5, b_ech := "militia", t_max := 240.0, b_alert := 1, b_extra := {}):
	var lv = Maps.get_level(mi)
	var cfgs: Array = []
	for k in kits.size():
		var id := "A%d" % (k + 1)
		cfgs.append(_cfg(id, 0, k, "police", kits[k], lv.spawns[id]["p"], lv.spawns[id]["face"]))
	for k2 in nb:
		var id2 := "B%d" % (k2 + 1)
		cfgs.append(_cfg(id2, 1, k2, b_ech, b_kit if not b_kit.is_empty() else _kit("carbine"), lv.spawns[id2]["p"], lv.spawns[id2]["face"]))
		cfgs[-1]["alert"] = b_alert
		for key in b_extra:
			cfgs[-1][key] = b_extra[key]
	var w = World.new()
	w.keep_events = false
	w.setup(lv, _nav(mi), cfgs, ["assault", "hold"], sd, [1, 1], opts)
	var first_in := -1.0
	var first_id := ""
	while not w.over and w.t < t_max:
		w.step()
		w.events.clear()
		if first_in < 0.0:
			for o in w.ops:
				if o.team == 0 and o.alive() and lv.is_inside(o.pos):
					first_in = w.t
					first_id = o.id
	w.set_meta("first_in", first_in if first_in >= 0.0 else w.t)
	w.set_meta("first_id", first_id)
	return w


func _police_kits(n: int, gear := {}, point_gear := {}, primary := "carbine", point_primary := "") -> Array:
	var out: Array = []
	for k in n:
		var g: Dictionary = (point_gear if k == 0 and not point_gear.is_empty() else gear).duplicate()
		var p: String = point_primary if k == 0 and point_primary != "" else primary
		out.append(_kit(p, "service_pistol", g, {"armour": "plates", "plates": 2}))
	return out


func _officers_hit(w) -> int:
	var n := 0
	for o in w.ops:
		if o.team == 0 and (o.state != "ok" or o.wounds > 0):
			n += 1
	return n


## A bedroom held by three men with rifles, facing its door; a police squad of four in the
## hall outside it (map 05, the east unit): the entry is the whole fight.
func t_flashbang(on: bool, sd: int):
	var lv = Maps.get_level(5)
	var door: Vector2 = lv.doors["D8"]["c"]
	var cfgs: Array = []
	var a_pos := [Vector2(26.5, 13.5), Vector2(25.5, 13.5), Vector2(26.5, 14.3), Vector2(25.5, 14.3)]
	for k in 4:
		var kit := _kit("carbine", "service_pistol", {"flashbang": 2} if on else {}, {"armour": "plates", "plates": 2})
		cfgs.append(_cfg("A%d" % (k + 1), 0, k, "police", kit, _nav(5).snap(a_pos[k]), -PI / 2.0))
	for k2 in 3:
		var p: Vector2 = lv.spawns["B%d" % (k2 + 1)]["p"]
		cfgs.append(_cfg("B%d" % (k2 + 1), 1, k2, "militia", _kit("carbine"), p, (door - p).angle()))
	var w = World.new()
	w.keep_events = false
	w.setup(lv, _nav(5), cfgs, ["assault", "hold"], sd, [1, 1], {"b_stay": true, "b_posted": true, "doors": {"D8": "closed"}})
	# officers hit from the moment the first of them steps into the bedroom
	var t_in := INF
	while not w.over and w.t < 120.0:
		w.step()
		w.events.clear()
		if t_in == INF:
			for o0 in w.ops:
				if o0.team == 0 and o0.alive() and lv.room_at(o0.pos) == "E BED1":
					t_in = w.t
	var v := 0
	for o in w.ops:
		if o.team == 0 and float(o.ticker.get("first_hit_t", INF)) >= t_in - 0.5 and o.ticker.has("first_hit_t"):
			v += 1
	w.dispose()
	return v


func t_ram(on: bool, sd: int):
	var w = _op(4, _police_kits(5, {}, {"ram": 1} if on else {}), sd, {"door_mode": "outer"})
	var v: float = w.get_meta("first_in")
	w.dispose()
	return v


func t_breach(on: bool, sd: int):
	var w = _op(4, _police_kits(5, {}, {"breach": 1} if on else {}, "carbine", "shotgun"), sd, {"door_mode": "outer"})
	var v: float = w.get_meta("first_in")
	w.dispose()
	return v


## The shield in a gunfight: one officer with a pistol facing three armed men at 10 m.
## Rounds that got through to him (by the shield, his plates, or around them).
func t_shield(on: bool, sd: int):
	var lane := _lane(10.0)
	var lv = Maps.get_level(11)
	var ka := _kit("", "service_pistol", {"shield": 1} if on else {}, {"armour": "plates", "plates": 2})
	var cfgs: Array = [_cfg("A1", 0, 0, "police", ka, lane[0], 0.0)]
	for k in 3:
		cfgs.append(_cfg("B%d" % (k + 1), 1, k, "militia", _kit("carbine"), lane[1][k], PI))
	var w = World.new()
	w.keep_events = false
	w.setup(lv, _nav(11), cfgs, ["hold", "hold"], sd, [1, 1], {"a_posted": true, "b_stay": true, "b_posted": true})
	while not w.over and w.t < 20.0:
		w.step()
		w.events.clear()
	var v := 0
	for o in w.ops:
		if o.team == 1:
			v += o.hits
	w.dispose()
	return v


func t_light(on: bool, sd: int):
	var w = _op(4, _police_kits(5, {"light": 1} if on else {}), sd, {"night": true, "police_rules": true})
	var n: int = int(w.stat.get("rec_n_0", 0))
	var v = float(w.stat.get("rec_sum_0", 0.0)) / n if n > 0 else null
	w.dispose()
	return v


func t_medkit(on: bool, sd: int):
	var w = _op(4, _police_kits(5, {"medkit": 1} if on else {}), sd, {"police_rules": true}, {}, 5, "militia")
	var downed := 0
	var died := 0
	for o in w.ops:
		if o.ticker.has("down_t"):
			downed += 1
			if o.state == "dead" and not o.ticker.get("killed_outright", false):
				pass
	# count from the log: who died of wounds after the operation
	for ln in w.log_lines:
		if String(ln["text"]).contains("dies of wounds"):
			died += 1
	var v = float(died) / downed if downed > 0 else null
	w.dispose()
	return v


## A man alone in the house with no weapon who will not give up when covered and
## challenged. Seconds until he is in cuffs (the operation's 240 s if never).
func _defiant(on: bool, sd: int, tool: String):
	var gear := {tool: 1} if on else {}
	var kits := _police_kits(3, gear)
	var lv = Maps.get_level(4)
	var cfgs_extra := {"defiant": true}
	var w = _op(4, kits, sd, {"police_rules": true}, _kit("", ""), 1, "untrained", 240.0, 0, cfgs_extra)
	var b = w.by_id["B1"]
	var v: float = float(b.ticker.get("cuffed_t", w.t)) if b.arrested else 240.0
	w.dispose()
	return v


func t_taser(on: bool, sd: int):
	return _defiant(on, sd, "taser")


func t_launcher(on: bool, sd: int):
	return _defiant(on, sd, "launcher")


func t_smg(on: bool, sd: int):
	var w = _op(5, _police_kits(5, {}, {}, "smg" if on else "carbine"), sd, {"police_rules": true})
	var shots := 0
	var through := 0
	for rec in w.incident.shots:
		if rec.get("pol", false):
			shots += 1
			if int(rec.get("walls", 0)) > 0:
				through += 1
	w.dispose()
	return [through, shots]


# ------------------------------------------------------------------ the helmet
## Two head hits on a Special operations officer with the helmet: the first is stopped
## (alive, stunned, helmet spent), the second kills. And without the helmet, one kills.
func _helmet_unit() -> Array:
	var lv = Maps.get_level(11)
	var lane := _lane(8.0)
	var kit_h := _kit("sbr", "service_pistol", {}, {"armour": "plates", "plates": 3, "head": "sof_helmet"})
	var cfgs: Array = [_cfg("A1", 0, 0, "sof", kit_h, lane[0], 0.0, true), _cfg("B1", 1, 0, "regular", _kit("carbine"), lane[1][1], PI)]
	var survived := 0
	var second_kills := 0
	var stunned := 0
	var runs := 20
	for sd in runs:
		var w = World.new()
		w.keep_events = false
		w.setup(lv, _nav(11), cfgs, ["hold", "hold"], 900 + sd, [1, 1], {"a_posted": true, "b_stay": true, "b_posted": true})
		var a = w.by_id["A1"]
		var b = w.by_id["B1"]
		var u: Vector2 = (a.pos - b.pos).normalized()
		w._hit(a, a.zone_at(a.zone_centre("head")), 0.0, u, b, 1.0, 0)
		if a.alive() and a.state == "ok" and not a.helmet:
			survived += 1
		if a.stunned(w.t):
			stunned += 1
		w._hit(a, a.zone_at(a.zone_centre("head")), 0.0, u, b, 1.0, 0)
		if a.state == "dead":
			second_kills += 1
		w.dispose()
	var ok: bool = survived == runs and second_kills == runs and stunned == runs
	return [ok, "%d/%d" % [survived, runs], "%d/%d" % [runs - second_kills, runs]]
