extends SceneTree
## EA_TASKS P1.C5: the Entry kit Suggest a plan proposes for a gang raid.
##
##   godot --headless --path . -s res://tests/kit_proposal_test.gd
##
## Gates: suggesting changes nobody's kit and spends nothing; a gang raid's door squads
## are proposed the Entry kit and other situations nothing; the price shown is what the
## Run charges; "keep their current kit" issues nothing; an officer whose kit was changed
## by hand after the proposal keeps the chief's choice; nobody outside the plan is issued
## anything; a frozen account issues nothing and says why; and the proposal is spent.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Maps = preload("res://scripts/maps/registry.gd")

var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1


func _gang(c, seed_v: int) -> Dictionary:
	var s: Dictionary = Situations.make("gang", seed_v, 3, 0, c.politics.trust, true)
	c.board = [s]
	return s


func _suggest(c, s: Dictionary) -> Dictionary:
	var lv = Maps.get_level(int(s["map"]))
	var av: Array = c.available_for(s["id"])
	var plan: Dictionary = Autoplan.suggest(s, av, lv, false, 6, false)
	plan["kit"] = Autoplan.propose_kit(s, plan, av)
	s["plan"] = plan
	return plan


func _init() -> void:
	var c = Campaign.new()
	c.start(1001)
	c.dept.balance = 200000
	var kits0 := JSON.stringify(c.dept.officers.map(func(r): return r["kit"]))
	var bal0: int = c.dept.balance
	var s := _gang(c, 7000)
	var plan := _suggest(c, s)
	check(JSON.stringify(c.dept.officers.map(func(r): return r["kit"])) == kits0 and c.dept.balance == bal0,
		"suggesting changes nobody's kit and spends nothing")
	var members: Array = c.plan_members(s)
	check(not plan["kit"].is_empty() and plan["kit"].keys().all(func(k): return members.has(k)),
		"a gang raid's door squads are proposed the Entry kit (%d of %d going)" % [plan["kit"].size(), members.size()])
	var ev: Dictionary = Situations.make("event", 5000, 3, 0, c.politics.trust, true)
	var lv_e = Maps.get_level(int(ev["map"]))
	var av_e: Array = c.available_for(ev["id"])
	var plan_e: Dictionary = Autoplan.suggest(ev, av_e, lv_e, false, 6, false)
	check(Autoplan.propose_kit(ev, plan_e, av_e).is_empty(), "a public event is proposed nothing")
	var proposed: int = plan["kit"].size()
	var price: int = c.plan_kit_cost(s)
	var lines: Array = c.issue_plan_kit(s)
	check(price > 0 and c.dept.balance == bal0 - price, "the Run charges the price the Force tab showed ($%d): %s" % [price, str(lines)])
	var issued := 0
	for oid in members:
		var r: Dictionary = c.dept.get_officer(oid)
		if String(r["kit"].get("head", "")) == "ballistic_helmet" and int(r["kit"].get("plates", 0)) == 2:
			issued += 1
	check(issued == proposed, "and the officers going in carry it (%d of %d)" % [issued, proposed])
	check(plan["kit"].is_empty() and c.issue_plan_kit(s).is_empty(), "the proposal is spent: a second Run buys nothing")

	# keep their current kit
	var c2 = Campaign.new()
	c2.start(1001)
	c2.dept.balance = 200000
	var s2 := _gang(c2, 7013)
	var p2 := _suggest(c2, s2)
	p2["kit_mode"] = "own"
	var b2: int = c2.dept.balance
	var k2 := JSON.stringify(c2.dept.officers.map(func(r): return r["kit"]))
	c2.issue_plan_kit(s2)
	check(c2.dept.balance == b2 and JSON.stringify(c2.dept.officers.map(func(r): return r["kit"])) == k2,
		"\"keep their current kit\": nothing issued, nothing spent")

	# a kit changed by hand after the proposal, and an officer taken off the plan
	var c3 = Campaign.new()
	c3.start(1001)
	c3.dept.balance = 200000
	var s3 := _gang(c3, 7026)
	var p3 := _suggest(c3, s3)
	var ids: Array = p3["kit"].keys()
	var mine: Dictionary = c3.dept.get_officer(ids[0])
	var chosen: Dictionary = Equipment.validate(Equipment.SQUAD_KITS["less"]["rest"], Equipment.who_of_record(mine))
	c3.dept.reissue(mine, chosen)
	var dropped: String = String(ids[1])
	for sq in p3["squads"]:
		sq["members"].erase(dropped)
	var dropped_kit := JSON.stringify(c3.dept.get_officer(dropped)["kit"])
	c3.issue_plan_kit(s3)
	check(JSON.stringify(mine["kit"]) == JSON.stringify(chosen), "a kit the chief changed by hand after the proposal stays the chief's")
	check(JSON.stringify(c3.dept.get_officer(dropped)["kit"]) == dropped_kit, "an officer taken off the plan is issued nothing")

	# a frozen account
	var c4 = Campaign.new()
	c4.start(1001)
	var s4 := _gang(c4, 7039)
	_suggest(c4, s4)
	# P1.D2: the freeze is the overdraft limit, not zero — at -$100 the kit may be issued
	# into the overdraft, so the frozen case is one dollar past the limit
	c4.dept.balance = Department.OVERDRAFT_LIMIT - 1
	var k4 := JSON.stringify(c4.dept.officers.map(func(r): return r["kit"]))
	var l4: Array = c4.issue_plan_kit(s4)
	check(JSON.stringify(c4.dept.officers.map(func(r): return r["kit"])) == k4 and c4.dept.balance == Department.OVERDRAFT_LIMIT - 1
		and l4.any(func(l): return String(l).contains("not issued")), "a frozen account issues nothing and says so: %s" % str(l4))

	print("kit_proposal_test: %d failure%s" % [failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
