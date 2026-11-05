extends SceneTree
## Patrol encounters (2026-11-05, owner request) and the two kit rules that came with them.
##
##   - seven encounters a week, one a day, the same for the same seed
##   - routine encounters are about three in four of the draw, and for them proceeding
##     alone is the best of the three choices; for the rest backup en route or waiting is
##   - answering resolves a desk encounter at once (officers, money, the city), and every
##     encounter left unanswered is handled at the week's end
##   - an armed encounter becomes a small operation with the pair (and the backup) that
##     builds, plays out in the sim, and writes its result back to the encounter
##   - the patrol state survives a save
##   - every officer serving a warrant wears a helmet; the .45 is medium calibre and the
##     .22 light pistol is low
##
## Run: godot --headless --path . -s res://tests/patrol_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Patrol = preload("res://scripts/campaign/patrol.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	print("== patrol encounters")
	_draw()
	_best_choice()
	_campaign_flow()
	_armed()
	_kit_rules()
	print("patrol: %s" % ("all passed" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


## Seven a week, deterministic, and the routine share near three in four.
func _draw() -> void:
	var a := Patrol.week_encounters(1001, 3, null)
	var b := Patrol.week_encounters(1001, 3, null)
	_check(a.size() == 7, "seven encounters a week (%d)" % a.size())
	var same := true
	for i in a.size():
		if a[i]["kind"] != b[i]["kind"] or a[i]["dispatch"] != b[i]["dispatch"] or a[i]["esc_roll"] != b[i]["esc_roll"]:
			same = false
	_check(same, "the same seed and week give the same encounters")
	var days := []
	for e in a:
		days.append(int(e["day"]))
	_check(days == [0, 1, 2, 3, 4, 5, 6], "one a day, Monday to Sunday")
	var routine := 0
	var n := 0
	var armed := 0
	for wk in range(1, 41):
		for e in Patrol.week_encounters(77, wk, null):
			n += 1
			if float(Patrol.spec(e)["danger"]) < 0.3:
				routine += 1
			if bool(e["armed"]):
				armed += 1
	var share := float(routine) / n
	_check(share > 0.68 and share < 0.82, "routine encounters %.0f%% of 40 weeks (about 75%%)" % (share * 100.0))
	print("        armed (to the sim): %d of %d, %.1f a week" % [armed, n, float(armed) / 40.0])


## For each kind, the expected cost of each choice over many rolls: officers hurt or
## killed, victims, and lateness, in the same units the policies feel (a death 25, a
## serious wound 6, a wound 2, a victim hurt 4 or killed 20, a late call 1, $1,000 of overtime 1).
func _best_choice() -> void:
	var c = Campaign.new()
	c.start(5, false)
	var dept = c.dept
	var best_w := {0: 0.0, 1: 0.0, 2: 0.0}
	var table: Array = []
	for kind in Patrol.KINDS:
		var cost := [0.0, 0.0, 0.0]
		var N := 4000
		for k in N:
			var e := Patrol.make(kind, 9000 + k, 1, 0, dept)
			for ch in 3:
				var r: Dictionary = Patrol.resolve_desk(e, ch, dept)
				var v := 0.0
				match String(r["harm"]):
					"dead":
						v += 25.0
					"down":
						v += 6.0
					"hurt":
						v += 2.0
				v += 4.0 * int(r["civ_hurt"]) + 20.0 * int(r["civ_killed"])
				v += 1.0 if bool(r["late"]) else 0.0
				v += 0.5 if bool(r["complaint"]) else 0.0
				v += Patrol.OVERTIME[ch] / 1000.0
				cost[ch] += v / N
		var best := 0
		for ch2 in 3:
			if cost[ch2] < cost[best] - 0.0001:
				best = ch2
		best_w[best] += float(Patrol.KINDS[kind]["w"])
		table.append("        %-12s %5.2f %5.2f %5.2f  best: %s" % [kind, cost[0], cost[1], cost[2], Patrol.CHOICES[best]["id"]])
	for ln in table:
		print(ln)
	var tot: float = best_w[0] + best_w[1] + best_w[2]
	_check(abs(best_w[0] / tot - 0.75) < 0.06, "proceeding alone is best for %.0f%% of the draw (about 75%%)" % (100.0 * best_w[0] / tot))
	_check(best_w[1] > 0.0 and best_w[2] > 0.0, "backup en route and waiting are each the best for some encounters")


## Answer one, leave the rest: the week's end settles them, and a save keeps them.
func _campaign_flow() -> void:
	var c = Campaign.new()
	c.legacy_path = "user://patrol_test_legacy.json"
	c.start(4242, false)
	_check(c.patrols.size() == 7, "a new campaign has its first week's seven")
	_check(c.patrols.all(func(e): return (e["pair"] as Array).size() == 2), "every dispatch names a pair")
	var e0: Dictionary = {}
	for e in c.patrols:
		if not bool(e["armed"]):
			e0 = e
			break
	var bal0: int = c.dept.balance
	var out: Dictionary = c.decide_patrol(String(e0["id"]), 1)
	_check(String(e0["status"]) == "done" and String(out["run"]) == "", "an unarmed encounter is settled on the desk at once")
	_check((e0["backup"] as Array).size() == 2, "backup en route sends two more")
	_check(c.dept.balance == bal0 - Patrol.OVERTIME[1] - _medical_since(c, bal0), "backup costs its overtime")
	_check(not (out["lines"] as Array).is_empty(), "and the radio reports back (%s)" % String(out["lines"][0]) if not (out["lines"] as Array).is_empty() else "and the radio reports back")
	var again: Dictionary = c.decide_patrol(String(e0["id"]), 0)
	_check(String(again["run"]) == "" and (again["lines"] as Array).is_empty(), "an answered encounter cannot be answered twice")
	# the save
	var d: Dictionary = c.to_data()
	var c2 = Campaign.new()
	c2.from_data(JSON.parse_string(JSON.stringify(d)))
	_check(c2.patrols.size() == 7 and String(c2.get_patrol(String(e0["id"]))["status"]) == "done", "the patrol radio survives a save")
	var wk: int = c.dept.week
	c.end_week()
	var settled := 0
	for p in c.patrol_past:
		if int(p["week"]) == wk and String(p["status"]) == "done":
			settled += 1
	_check(settled == 7, "the week's end settles every encounter left (%d of 7)" % settled)
	_check(c.patrols.size() == 7 and int(c.patrols[0]["week"]) == wk + 1, "and the next week's seven are on the radio")
	_check(int(c.last_recap.get("patrols", -1)) == 7, "the week's recap counts them (%s)" % str(c.last_recap.get("patrols")))


func _medical_since(c, bal0: int) -> int:
	var t := 0
	for row in c.dept.ledger:
		if String(row["item"]).begins_with("Medical") or String(row["item"]).begins_with("Line-of-duty"):
			t += -int(row["amount"])
	return t


## An armed encounter: the situation, its plan by choice, a run in the sim, and the
## result written back.
func _armed() -> void:
	var c = Campaign.new()
	c.legacy_path = "user://patrol_test_legacy.json"
	c.start(31, false)
	# find an armed robbery that is not late for each choice
	for ch in 3:
		var e := Patrol.make("robbery", 500 + ch * 7, 1, ch, c.dept)
		var k := 0
		while Patrol.is_late(e, ch) and k < 50:
			k += 1
			e = Patrol.make("robbery", 500 + ch * 7 + k * 13, 1, ch, c.dept)
		e["id"] = "PT-%d" % ch
		c.patrols.append(e)
		var out: Dictionary = c.decide_patrol(String(e["id"]), ch)
		_check(String(out["run"]) != "", "%s: an armed robbery becomes an operation" % Patrol.CHOICES[ch]["id"])
		var s: Dictionary = c.get_sit(String(out["run"]))
		var sq: Array = s["plan"]["squads"]
		_check(sq.size() == (1 if ch == 0 else 2), "  the plan has %d squad%s" % [sq.size(), "" if sq.size() == 1 else "s"])
		if ch == 1:
			_check(String(sq[1]["orders"].get("phase", {}).get("kind", "")) == "time", "  the backup arrives on a phase line")
		var sus: Array = s["occupants"].filter(func(o): return o["role"] == "suspect")
		_check(sus.size() == 1 and String(sus[0]["handgun"]) in ["light_pistol", "service_pistol", "compact_pistol", "heavy_pistol"],
			"  one suspect with a street handgun (%s)" % (String(sus[0]["handgun"]) if not sus.is_empty() else "none"))
		_check(not c.committed().has(String(sq[0]["members"][0])), "  the pair is not taken off the week's operations")
		var lv = Maps.get_level(int(s["map"]))
		var nav = Nav.new()
		nav.build(lv)
		var b: Dictionary = Operation.build_planned(s, s["plan"], c.dept, lv, nav)
		var police: int = b["cfgs"].filter(func(cf): return int(cf["team"]) == 0).size()
		_check(police == (2 if ch == 0 else 4), "  %d officers in the sim" % police)
		var w = World.new()
		w.keep_events = false
		w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
		var guard := 0
		while not w.over and guard < 40000:
			w.step()
			w.events.clear()
			guard += 1
		_check(w.over, "  it plays to the end (%.0f s)" % w.t)
		var res: Dictionary = Outcome.evaluate(s, w)
		c.dept.apply_result(w, lv.map_name)
		c.after_operation(s["id"], res, w)
		c.record(s["id"], res)
		_check(String(e["status"]) == "done" and bool(e["result"].get("sim", false)), "  the result is written back: %s" % String(e["result"].get("text", "")))
		w.dispose()


func _kit_rules() -> void:
	_check(String(Equipment.WEAPONS["heavy_pistol"]["cal"]) == "medium", "the .45 is medium calibre")
	_check(Equipment.WEAPONS.has("light_pistol") and String(Equipment.WEAPONS["light_pistol"]["cal"]) == "low", "the .22 light pistol exists and is low calibre")
	var c = Campaign.new()
	c.start(8, false)
	var s := Situations.make("warrant", 1234, 1, 0)
	var lv = Maps.get_level(int(s["map"]))
	var nav = Nav.new()
	nav.build(lv)
	var av: Array = c.dept.available()
	s["plan"] = Autoplan.suggest(s, av, lv, false, av.size(), false)
	var b: Dictionary = Operation.build_planned(s, s["plan"], c.dept, lv, nav)
	var cops: Array = b["cfgs"].filter(func(cf): return int(cf["team"]) == 0)
	_check(not cops.is_empty() and cops.all(func(cf): return String(cf["kit"]["head"]) != "none"),
		"every officer serving a warrant wears a helmet (%d officers)" % cops.size())
	var s2 := Situations.make("gang", 1234, 1, 0)
	var lv2 = Maps.get_level(int(s2["map"]))
	var nav2 = Nav.new()
	nav2.build(lv2)
	s2["plan"] = Autoplan.suggest(s2, av, lv2, false, av.size(), false)
	var b2: Dictionary = Operation.build_planned(s2, s2["plan"], c.dept, lv2, nav2)
	var bare: Array = b2["cfgs"].filter(func(cf): return int(cf["team"]) == 0 and String(cf["kit"]["head"]) == "none")
	_check(not bare.is_empty(), "other calls keep the officers' own kit (%d bare-headed in a crew house)" % bare.size())
