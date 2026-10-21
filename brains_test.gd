extends SceneTree
## The v0.8 gate for the four brains, the squads and the room rules: each part, switched
## on and off in otherwise identical runs (Brain.features), must change what it is for.
##   godot --headless --path . -s res://tests/brains_test.gd -- [--n=8] [--only=lion] [--v]
##
##   formation  Squads.sizes follows the rules (threes, at most five squads, even, at most six)
##   lizard     shot at by someone unseen: share of the time still in that line of fire (less)
##   lion       the leader's order reaches the squad faster in a cohesive squad (lag, s)
##   wolf       a lone fighter in a fight with nobody in sight: share of it hidden (more)
##   pairs      four officers searching small-room buildings: rooms cleared a minute (more)
##   disperse   a squad of four holding small rooms: rooms it holds (more); in a big room: 1
##   bonds      the department's pair bonds raise a squad's cohesion

const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")
const Squads = preload("res://scripts/data/squads.gd")
const Department = preload("res://scripts/campaign/department.gd")

var args := {}
var _navs := {}
var fails := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "8"))
	var only: Array = String(args.get("only", "")).split(",", false)
	var t0 := Time.get_ticks_msec()
	print("part        measure                                                    on       off    gate")
	for part in ["formation", "lizard", "lion", "wolf", "pairs", "disperse", "bonds"]:
		if not only.is_empty() and not only.has(part):
			continue
		call("g_" + part, n)
	print("%d failure(s), %d s" % [fails, (Time.get_ticks_msec() - t0) / 1000])
	quit(1 if fails > 0 else 0)


func _row(part: String, measure: String, on_v, off_v, ok: bool) -> void:
	if not ok:
		fails += 1
	var a: String = ("%.2f" % on_v) if (on_v is float or on_v is int) else str(on_v)
	var b: String = ("%.2f" % off_v) if (off_v is float or off_v is int) else str(off_v)
	print("%-11s %-58s %7s  %7s   %s" % [part, measure, a, b, "PASS" if ok else "FAIL"])


func _nav(mi: int, lv):
	if not _navs.has(mi):
		var nv = Nav.new()
		nv.build(lv)
		_navs[mi] = nv
	return _navs[mi]


func _world(mi: int, na: int, ea: String, nb: int, eb: String, postures: Array, sd: int, off: Array, opts := {}):
	var lv = Maps.get_level(mi)
	var cfgs: Array = Teams.team(lv, 0, {"n": na, "ech": ea}) + Teams.team(lv, 1, {"n": nb, "ech": eb})
	var w = World.new()
	w.keep_events = false
	w.setup(lv, _nav(mi, lv), cfgs, postures, sd, [1, 1], opts)
	for f in off:
		w.brain.features[f] = false
	return w


func _run(w, t_max: float, each := Callable()) -> void:
	while not w.over and w.t < t_max:
		w.step()
		w.events.clear()
		if each.is_valid():
			each.call(w)


# ------------------------------------------------------------------ the parts
func g_formation(_n: int) -> void:
	var want := {1: [1], 2: [2], 3: [3], 4: [4], 5: [5], 6: [3, 3], 7: [4, 3], 8: [4, 4], 9: [3, 3, 3],
		10: [4, 3, 3], 11: [4, 4, 3], 14: [4, 4, 3, 3], 15: [3, 3, 3, 3, 3], 16: [4, 3, 3, 3, 3],
		20: [4, 4, 4, 4, 4], 24: [5, 5, 5, 5, 4], 29: [6, 6, 6, 6, 5], 30: [6, 6, 6, 6, 6]}
	var bad: Array = []
	for k in want:
		if Squads.sizes(k) != want[k]:
			bad.append("%d -> %s" % [k, str(Squads.sizes(k))])
	_row("formation", "squad sizes for 1-30 follow the rules (wrong cases)", bad.size(), 0, bad.is_empty())
	if args.has("v") and not bad.is_empty():
		print("    ", bad)


## Shot at by someone it cannot see: the share of the 2.5 s after that an operator is
## still in that shooter's line of fire. 5v5 regulars, assault against hold, map 04.
## Time fighting a visible enemy (Rule 1) or frozen by BH07 is left out: both override
## the reflex by design.
var why_h := {}


func g_lizard(n: int) -> void:
	# a 15% effect in a noisy measure: at least twenty seeds (v0.9.1)
	n = maxi(n, 20)
	var res := {}
	for on in [true, false]:
		var acc := {"exp": 0.0, "all": 0.0}
		for sd in n:
			var w = _world(4, 5, "regular", 5, "regular", ["assault", "hold"], 800 + sd, [] if on else ["lizard"])
			_run(w, 180.0, func(ww):
				for o in ww.ops:
					if not o.alive() or o.team > 1:
						continue
					var ft: float = float(o.ticker.get("fire_t", -99.0))
					if ww.t - ft > 2.5 or not o.ticker.has("fire_from") or not ww.visible_enemies(o).is_empty():
						continue
					# a bad habit holding them frozen (BH07 flinch and turtle) overrides the
					# reflex by design, as Rule 1 does (v0.9.1): not the Lizard's time
					if o.hb("BH07") and float(o.ticker.get("flinch_until", -1.0)) > ww.t:
						continue
					acc["all"] += 1.0 / 30.0
					var ff: Vector2 = o.ticker["fire_from"]
					if ww.geom.sight_clear(ff, 1.65, o.pos, 1.2 if o.stance == 0 else 0.82):
						acc["exp"] += 1.0 / 30.0
						if on and args.has("why"):
							var key: String = "%s/%s" % [o.mind, String(o.dbg).split(" >")[0].substr(0, 26)]
							why_h[key] = why_h.get(key, 0) + 1)
			w.dispose()
		res[on] = acc["exp"] / maxf(0.01, acc["all"])
	_row("lizard", "share of time under unseen fire still in its line (less)", res[true], res[false], res[true] < res[false] * 0.85)
	if args.has("why"):
		var ks: Array = why_h.keys()
		ks.sort_custom(func(a, b): return why_h[a] > why_h[b])
		for k in ks.slice(0, 14):
			print("    %5d  %s" % [why_h[k], k])


## The leader's order (cover, fall back) and when each subordinate acts on it: the mean
## lag, cohesion forced to 0.9 against 0.15, 6 police against 6 regulars on map 06.
func g_lion(n: int) -> void:
	var res := {}
	for coh in [0.9, 0.15]:
		var lags: Array = []
		for sd in n:
			var w = _world(6, 6, "police", 6, "regular", ["assault", "hold"], 820 + sd, [])
			for el in w.teams[0]["elements"]:
				el["cohesion"] = coh
			_run(w, 120.0, func(ww):
				for el in ww.teams[0]["elements"]:
					var ln: Dictionary = el.get("lion", {})
					if ln.is_empty() or ln["order"] in ["push", "hold"] or el.get("lion_logged", -1) == ln["id"]:
						continue
					var adopt: Dictionary = el.get("lion_adopt", {})
					if adopt.size() >= ww.brain._alive(el).size() and adopt.size() > 1:
						el["lion_logged"] = ln["id"]
						for oid in adopt:
							if oid != ln["by"]:
								lags.append(float(adopt[oid]) - float(ln["t"])))
			w.dispose()
		var s := 0.0
		for v in lags:
			s += v
		res[coh] = [s / maxf(1.0, lags.size()), lags.size()]
	_row("lion", "s from the leader's order to a subordinate acting (cohesion 0.9 / 0.15)", res[0.9][0], res[0.15][0],
		res[0.9][1] > 0 and res[0.15][1] > 0 and res[0.9][0] < res[0.15][0] * 0.6)
	if args.has("v"):
		print("    orders followed: %d / %d" % [res[0.9][1], res[0.15][1]])


## A lone regular hunted by two (the Civic Plaza and the Compound, both hunting): in a
## live fight with no enemy in sight, the share of the time it is hidden from the threat.
func g_wolf(n: int) -> void:
	var res := {}
	for on in [true, false]:
		var acc := {"hid": 0.0, "all": 0.0}
		for mi in [11, 9]:
			for sd in n:
				var w = _world(mi, 1, "regular", 2, "regular", ["hunt", "hunt"], 840 + sd, [] if on else ["wolf"])
				_run(w, 150.0, func(ww):
					var o = ww.by_id.get("A1", null)
					if o == null or not o.alive() or not ww.visible_enemies(o).is_empty():
						return
					var el: Dictionary = ww.teams[0]["elements"][o.el]
					var lk = ww.brain._team_lkp(ww.teams[0], 40.0, o.pos)
					if lk == null or ww.t - float(el.get("contact_t", -99.0)) > 12.0:
						return
					acc["all"] += 1.0 / 30.0
					if not ww.geom.sight_clear(lk, 1.65, o.pos, 1.2):
						acc["hid"] += 1.0 / 30.0)
				w.dispose()
		res[on] = acc["hid"] / maxf(0.01, acc["all"])
	_row("wolf", "share of a lone fighter's unseen fight spent hidden (more)", res[true], res[false], res[true] > res[false] * 1.3)


## Four police searching for one man on the motel, the compound and the warehouse: rooms
## cleared per minute until he is found.
func g_pairs(n: int) -> void:
	var res := {}
	for on in [true, false]:
		var rooms := 0
		var secs := 0.0
		var splits := 0
		for mi in [7, 9]:
			for sd in maxi(2, n / 2):
				var w = _world(mi, 4, "police", 1, "untrained", ["assault", "hold"], 500 + sd, [] if on else ["pairs"])
				_run(w, 240.0)
				rooms += w.teams[0]["cleared"].size()
				secs += w.t
				for ln in w.log_lines:
					if ln["text"].find("breaks into") >= 0:
						splits += 1
				w.dispose()
		res[on] = [rooms / maxf(1.0, secs) * 60.0, splits]
	_row("pairs", "rooms cleared a minute, four officers searching small rooms (more)", res[true][0], res[false][0],
		res[true][1] > 0 and res[true][0] > res[false][0] * 1.15)
	if args.has("v"):
		print("    splits: %d / %d" % [res[true][1], res[false][1]])


## One squad of four holding the Shotgun House (a 20 m2 bedroom, the kitchen behind it)
## and the Bunkhouse (a 42 m2 mess hall): rooms the squad holds once posted.
func g_disperse(_n: int) -> void:
	var res := {}
	for on in [true, false]:
		var small := 0
		var big := 0
		for pair in [[0, 0], [2, 1]]:
			var w = _world(pair[0], 1, "regular", 4, "regular", ["hold", "hold"], 860, [] if on else ["disperse"])
			# the squads posted during setup, before the switch: post them again
			for el in w.teams[1]["elements"]:
				w.brain._release_hold(w.teams[1], el)
				w.brain._consolidate(w.teams[1], el)
			var rooms := {}
			for o in w.ops:
				if o.team == 1:
					rooms[w.level.room_at(o.spawn)] = true
			if pair[1] == 0:
				small = rooms.size()
			else:
				big = rooms.size()
			w.dispose()
		res[on] = [small, big]
	_row("disperse", "rooms a squad of four holds: small-room house (more)", res[true][0], res[false][0], res[true][0] > res[false][0])
	_row("disperse", "rooms a squad of four holds: big room (1 either way)", res[true][1], res[false][1], res[true][1] == 1 and res[false][1] == 1)


## Two squads of the same four officers: strangers, and after six operations together.
func g_bonds(_n: int) -> void:
	var d = Department.new()
	d.found(1001)
	var ms: Array = d.available().slice(0, 4)
	var before: float = d.squad_cohesion(ms)
	for i in ms.size():
		for j in range(i + 1, ms.size()):
			d.bonds[Department.bond_key(ms[i]["id"], ms[j]["id"])] = 6
	var after: float = d.squad_cohesion(ms)
	_row("bonds", "cohesion of four officers: six operations together / strangers", after, before, after > before + 0.3)
	_row("bonds", "their lag in a fight, s (experience 2)", Squads.lag(after, 2), Squads.lag(before, 2), Squads.lag(after, 2) < Squads.lag(before, 2))
