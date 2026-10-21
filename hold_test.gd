extends SceneTree
## The hold-mode habit layer (HD01-HD20, BH21-BH27): assault against hold at equal and
## unequal quality, with the defenders' hold habits on and stripped, on several maps.
## Reports the attackers' win rate, the exchange (attackers lost per defender lost) and
## how the defence ended (fell back, counterattacked, sold dearly).
##   godot --headless --path . -s res://tests/hold_test.gd -- --n=10 [--size=5] [--maps=0,4,5,6]
##     [--pairs="police,police;sof,sof"] [--layers=on] [--without=HD07] [--set=HD01,HD02]
##     [--tune=hd10_lo:0.5,hd10_hi:0.95] [--nobh]
##   ... -- --ablate=drop|only [--pair=police,police] [--ids=HD01,HD02] [--base]

const Habits = preload("res://scripts/data/habits.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Brain = preload("res://scripts/sim/brain.gd")


var only := ""        # ablation: the one hold habit kept ("" = all of them)
var drop := ""        # ablation: the one hold habit removed
var keep := {}        # --set: the hold habits kept for the defenders (empty = all)
var without := {}     # --without: hold habits taken away from the defenders
var no_bh := false    # --nobh: the defenders get the hold habits but none of the hold bad habits


func cfg(id: String, team: int, slot: int, ech: String, lv, hold_layer: bool) -> Dictionary:
	var good := {}
	for g in Habits.preset_good(ech):
		var hd: bool = String(g).begins_with("HD")
		if hd and team == 1 and hold_layer and ((only != "" and g != only) or g == drop):
			continue
		if hd and team == 1 and not keep.is_empty() and not keep.has(g):
			continue
		if hd and team == 1 and without.has(g):
			continue
		if hold_layer or not hd:
			good[g] = true
	var bad := {}
	for b in Habits.stress_bad_ids():
		if (hold_layer and not (no_bh and team == 1)) or not Habits.is_hold(b):
			bad[b] = true
	return {"id": id, "team": team, "slot": slot, "echelon": ech, "good": good, "bad": bad,
		"plates": Habits.PRESET_PLATES[ech], "exp": Habits.PRESET_EXP[ech], "pos": lv.spawns[id]["p"],
		"face": lv.spawns[id]["face"], "enabled": true}


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "10"))
	var size := int(args.get("size", "5"))
	var maps: Array = String(args.get("maps", "0,4,5,6")).split(",")
	var pairs := [["regular", "regular"], ["police", "police"], ["militia", "police"], ["sof", "militia"], ["militia", "militia"]]
	if args.has("set"):
		for g in String(args["set"]).split(","):
			keep[g] = true
	# --tune=hd07_lane:0.8,hd10_lo:0.6 sweeps the hold-post geometry
	if args.has("tune"):
		for kv2 in String(args["tune"]).split(","):
			var pr2: PackedStringArray = kv2.split(":")
			match pr2[0]:
				"hd07_lane": Brain.hd07_lane = float(pr2[1])
				"hd07_door_too": Brain.hd07_door_too = pr2[1] == "1"
				"hd10_lo": Brain.hd10_lo = float(pr2[1])
				"hd10_hi": Brain.hd10_hi = float(pr2[1])
				"hd10_bonus": Brain.hd10_bonus = float(pr2[1])
				"hd07_hidden": Brain.hd07_hidden = float(pr2[1])
				"hd07_face_door": Brain.hd07_face_door = pr2[1] == "1"
		print("tune: lane %.2f door_too %s hidden %.1f face_door %s hd10 %.2f-%.2f bonus %.2f" % [Brain.hd07_lane, Brain.hd07_door_too, Brain.hd07_hidden, Brain.hd07_face_door, Brain.hd10_lo, Brain.hd10_hi, Brain.hd10_bonus])
	no_bh = args.has("nobh")
	if args.has("without"):
		for g in String(args["without"]).split(","):
			without[g] = true
	if args.has("pairs"):
		pairs = []
		for pp in String(args["pairs"]).split(";"):
			pairs.append(pp.split(","))
	if args.has("ablate"):
		_ablate(args, n, size, maps)
		quit()
		return
	print("attack     hold       layer   A wins   exchange (A lost / B lost)   fallbacks  counters  mean s")
	for pr in pairs:
		for layer in ([true] if args.get("layers", "") == "on" else [false, true]):
			var a_w := 0
			var games := 0
			var a_lost := 0
			var b_lost := 0
			var falls := 0
			var counters := 0
			var dur := 0.0
			for mi in maps:
				var lv = Maps.get_level(int(mi))
				var nav = Nav.new()
				nav.build(lv)
				for s in n:
					var cfgs: Array = []
					for k in size:
						cfgs.append(cfg("A%d" % (k + 1), 0, k, pr[0], lv, true))
						cfgs.append(cfg("B%d" % (k + 1), 1, k, pr[1], lv, layer))
					var w = World.new()
					w.keep_events = false
					w.setup(lv, nav, cfgs, ["assault", "hold"], 3000 + s)
					while not w.over:
						w.step()
					games += 1
					if w.winner == 0:
						a_w += 1
					for o in w.ops:
						if o.team == 0 and o.state != "ok":
							a_lost += 1
						elif o.team == 1 and o.state != "ok":
							b_lost += 1
					for ln in w.log_lines:
						var tx: String = ln["text"]
						if tx.contains("falls back to the"):
							falls += 1
						elif tx.contains("counterattacks"):
							counters += 1
					dur += w.t
					w.dispose()
			print("%-10s %-10s %-6s %5.0f%%     %6.2f  (%d / %d)            %5d     %5d   %6.1f" % [pr[0], pr[1], "on" if layer else "off",
				100.0 * a_w / games, float(a_lost) / maxf(1.0, b_lost), a_lost, b_lost, falls, counters, dur / games])
	quit()



## One pair, the hold layer one habit at a time ("only") or all but one ("drop").
func _ablate(args: Dictionary, n: int, size: int, maps: Array) -> void:
	var pr: Array = String(args.get("pair", "police,police")).split(",")
	var mode: String = args.get("ablate", "only")
	var ids: Array = Habits.preset_good(pr[1]).filter(func(g): return String(g).begins_with("HD"))
	if args.has("ids"):
		ids = Array(String(args["ids"]).split(","))
	if not args.has("ids") or args.has("base"):
		ids.push_front("")
	print("%s vs %s, hold habits: %s one at a time" % [pr[0], pr[1], "only" if mode == "only" else "all but"])
	for hid in ids:
		only = hid if mode == "only" else ""
		drop = hid if mode != "only" else ""
		var a_w := 0
		var games := 0
		var a_lost := 0
		var b_lost := 0
		for mi in maps:
			var lv = Maps.get_level(int(mi))
			var nav = Nav.new()
			nav.build(lv)
			for s in n:
				var cfgs: Array = []
				for k in size:
					cfgs.append(cfg("A%d" % (k + 1), 0, k, pr[0], lv, true))
					cfgs.append(cfg("B%d" % (k + 1), 1, k, pr[1], lv, hid != "" or mode != "only"))
				var w = World.new()
				w.keep_events = false
				w.setup(lv, nav, cfgs, ["assault", "hold"], 3000 + s)
				while not w.over:
					w.step()
				games += 1
				if w.winner == 0:
					a_w += 1
				for o in w.ops:
					if o.team == 0 and o.state != "ok":
						a_lost += 1
					elif o.team == 1 and o.state != "ok":
						b_lost += 1
				w.dispose()
		print("  %-6s A wins %3.0f%%  exchange %.2f" % [hid if hid != "" else ("none" if mode == "only" else "all"), 100.0 * a_w / games,
			float(a_lost) / maxf(1.0, b_lost)])
