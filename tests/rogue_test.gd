extends SceneTree
## The run layer (1.3): the roguelike story mode, headless.
##   godot --headless --path . -s res://tests/rogue_test.gd [-- --seeds=6 --matrix-seeds=12]
## Gates: the same seed deals the same desk; a run saves and loads back unchanged; the
## armoury gates every kit and opens as contracts are signed; no inheritance or free
## contract can leave a procurement card that charges for stocked kit (EA_TASKS P0.C);
## a finished program teaches its habit to the whole force and to every hire after;
## forty weeks of randomly answered desks reach the election with a score and a legacy
## entry; the classic campaign (the harnesses' campaign) is untouched.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Courses = preload("res://scripts/data/courses.gd")

const LEGACY := "user://legacy_rogue_test.json"
var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1


## JSON keeps numbers as floats: compare what a save would hold.
static func _norm(d) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)), "", true)


func _week_through(c) -> void:
	c.run.auto_resolve(c)
	c.end_week()


## The cards of the first open draft of this kind, copied.
func _cards_of(c, kind: String) -> Array:
	for d in c.run.drafts:
		if String(d["kind"]) == kind:
			return (d["cards"] as Array).duplicate()
	return []


func _draft_index(c, kind: String) -> int:
	for i in c.run.drafts.size():
		if String(c.run.drafts[i]["kind"]) == kind:
			return i
	return -1


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	DirAccess.open("user://").remove(LEGACY.get_file())

	# the classic campaign has no run layer and no armoury
	var classic = Campaign.new()
	classic.start(1001)
	check(classic.run == null and Equipment.armory.is_empty(), "the classic campaign has no run layer and an open armoury")

	# same seed, same desk
	var a = Campaign.new()
	a.start(4242, true, LEGACY)
	var b = Campaign.new()
	b.start(4242, true, LEGACY)
	for k in 10:
		_week_through(a)
		_week_through(b)
	check(JSON.stringify(a.run.to_data()) == JSON.stringify(b.run.to_data()), "the same seed deals the same desk for ten weeks")
	check(a.run.doctrine != "", "the inheritance was drafted (%s)" % a.run.doctrine)
	check(a.run.desk_log.size() >= 3, "the desk decided things (%d entries)" % a.run.desk_log.size())

	# save and load
	var saved: Dictionary = JSON.parse_string(JSON.stringify(a.to_data()))
	var a2 = Campaign.new()
	check(a2.from_data(saved), "a run loads from its save")
	check(a2.run != null and _norm(a2.run.to_data()) == _norm(a.run.to_data()), "and its desk comes back unchanged")
	check(a2.dept.curriculum == a.dept.curriculum, "and so does the academy curriculum")

	# the armoury
	var c = Campaign.new()
	c.start(77, true, LEGACY)
	var heavy := {"primary": "sbr", "secondary": "heavy_pistol", "optic": "magnified", "armour": "plates", "plates": 2,
		"head": "ballistic_helmet", "gear": {"flashbang": 2, "medkit": 1, "taser": 1}}
	var k1: Dictionary = Equipment.validate(heavy, "tactical")
	check(k1["primary"] == "carbine" and k1["secondary"] == "service_pistol" and k1["optic"] == "red_dot",
		"locked weapons and sights fall back to patrol stock")
	check(k1["armour"] == ("plates" if c.run.armory.has("plates") else "vest"), "plates only with a contract (%s)" % k1["armour"])
	check(k1["head"] == "none" and not k1["gear"].has("flashbang") and k1["gear"].has("medkit"), "locked gear is left in the armoury")
	c.run.stock(["sbr", "flashbang", "ballistic_helmet"])
	var k2: Dictionary = Equipment.validate(heavy, "tactical")
	check(k2["primary"] == "sbr" and k2["head"] == "ballistic_helmet" and k2["gear"].get("flashbang", 0) == 2, "signed contracts open the armoury")
	var ok_all := true
	for r in c.dept.officers:
		var v: Dictionary = Equipment.validate(r["kit"], Equipment.who_of_record(r))
		if v["primary"] != r["kit"]["primary"] or v["gear"].size() != r["kit"]["gear"].size():
			ok_all = false
	check(ok_all, "every inherited officer's kit is already in patrol stock")
	classic.activate()
	check(Equipment.armory.is_empty(), "activating a classic campaign opens the armoury again")
	c.activate()

	# ------------------------------------------------------------ duplicate procurement (P0.C)
	# The 28 Oct playtest (docs/PLAYTEST_2026-10-28_CAMPAIGN.md §2) reproduced a charge for
	# an item already in the armoury: the procurement draft is dealt before the inheritance
	# is chosen, so picking "plate carriers on day one" left a $6,000 plate contract on the
	# desk. dup_probe.gd is folded in here: seeds 1-12, every inheritance, every contract.
	var mlegacy := "user://legacy_rogue_test_matrix.json"
	DirAccess.open("user://").remove(mlegacy.get_file())
	var matrix_seeds := int(args.get("matrix-seeds", "12"))
	var combos := 0
	var wasted: Array = []
	var redealt := 0
	var stream_checked := false
	for msd in range(1, matrix_seeds + 1):
		var probe = Campaign.new()
		probe.start(msd, true, mlegacy)
		for did in _cards_of(probe, "doctrine"):
			var base = Campaign.new()
			base.start(msd, true, mlegacy)
			var pre: Array = _cards_of(base, "procurement")
			var rng0: int = base.run.rng.state
			var drng0: int = base.run.draft_rng.state
			base.run.pick(base, _draft_index(base, "doctrine"), String(did))
			var post: Array = _cards_of(base, "procurement")
			var replaced: Array = pre.filter(func(x): return not post.has(x))
			redealt += replaced.size()
			if not stream_checked and not replaced.is_empty():
				check(base.run.rng.state == rng0, "a re-dealt card leaves the desk's rng alone (seed %d, %s)" % [msd, did])
				check(base.run.draft_rng.state != drng0, "and draws from its own replacement stream")
				stream_checked = true
			for pc in post:
				if base.run.contract_stocked(String(pc)):
					wasted.append("seed %d %s: the draft still offers stocked %s" % [msd, did, pc])
			for pc in post:
				combos += 1
				var c2 = Campaign.new()
				c2.start(msd, true, mlegacy)
				c2.run.pick(c2, _draft_index(c2, "doctrine"), String(did))
				var stock0: Array = c2.run.armory.duplicate()
				var money0: int = c2.dept.balance
				var cost: int = int(c2.run.CONTRACTS[String(pc)]["cost"])
				c2.run.pick(c2, _draft_index(c2, "procurement"), String(pc))
				var fresh: Array = c2.run.armory.filter(func(it): return not stock0.has(it))
				var spent: int = money0 - c2.dept.balance
				if fresh.is_empty():
					wasted.append("seed %d %s -> %s charged $%d and added nothing" % [msd, did, pc, spent])
				elif spent != cost:
					wasted.append("seed %d %s -> %s charged $%d, the contract is $%d" % [msd, did, pc, spent, cost])
	check(wasted.is_empty(), "no inheritance x contract pair charges for stocked kit (%d pairs, seeds 1-%d)%s" % [
		combos, matrix_seeds, "" if wasted.is_empty() else ": " + "; ".join(wasted.slice(0, 3))])
	check(redealt > 0, "the inheritance re-deals the procurement draft (%d card%s replaced)" % [redealt, "" if redealt == 1 else "s"])

	# the guard (P0.C3): a card the armoury already covers is refused with a line, no
	# charge and no closed draft. A save written before the fix can still hold one.
	var g = Campaign.new()
	g.start(77, true, mlegacy)
	var gi: int = _draft_index(g, "procurement")
	check(gi >= 0, "seed 77 deals a procurement draft to guard")
	if gi >= 0:
		g.run.stock(["plates"])
		g.run.drafts[gi]["cards"][0] = "plates"
		var gm: int = g.dept.balance
		var gstock: Array = g.run.armory.duplicate()
		var gl: Array = g.run.pick(g, gi, "plates")
		check(g.dept.balance == gm and g.run.armory.size() == gstock.size() and _draft_index(g, "procurement") >= 0 and not gl.is_empty(),
			"a contract for stocked items is refused: no charge, no closed draft (%s)" % str(gl))

	# a free military contract arriving by offer mid-week (P0.C4): Carrick's armoured
	# rescue vehicle. It stocks the armoury and re-deals the draft in the same step.
	var o = Campaign.new()
	o.start(2024, true, mlegacy)
	var odraft: int = _draft_index(o, "procurement")
	o.run.apply(o, {"contract": "military"}, {"title": "Carrick's armoured truck"})
	var granted := ""
	if not o.run.contracts.is_empty():
		granted = String(o.run.contracts[0])
	check(o.run.contracts.size() == 1 and granted != "" and o.run.contract_stocked(granted),
		"a free military contract arrives by offer and stocks its kit (%s)" % str(o.run.contracts))
	var still := _cards_of(o, "procurement").filter(func(x): return o.run.contract_stocked(String(x)))
	check(still.is_empty(), "and no card in the open draft is fully stocked afterwards%s" % ("" if still.is_empty() else ": " + str(still)))
	check(_draft_index(o, "procurement") == odraft, "with the procurement draft still open for the week")

	# a program teaches the whole force
	c.run.program = {"id": "GD03", "name": "Respect lines of fire (GD03)", "weeks_left": 1, "started": 1}
	c.run.on_week_end(c)
	var force: Array = c.dept.officers.filter(func(r): return String(r["status"]) not in ["dead", "fired", "resigned"])
	check(force.all(func(r): return (r["good"] as Array).has("GD03")), "a finished program teaches every officer (%d)" % force.size())
	var hire: Dictionary = c.dept.hire("Officer", 0)
	check((hire["good"] as Array).has("GD03"), "and the academy teaches it to the next hire")

	## EA_TASKS P1.D4.e: an effect assertion for each new late-game sink, the P1.E2
	## reconciliation offer, and the P1.F2 conditional election bonus.
	var r1 = Campaign.new()
	r1.start(8000, true, LEGACY)
	check(r1.dept.officers.size() > 0, "run starts")
	# the ARV: a capital contract, flagged in dept.capital (the gang-raid rescue reads it)
	check(not r1.dept.capital.get("arv", false), "no ARV before the contract")
	r1.run._sign(r1, "arv", true)
	check(r1.dept.capital.get("arv", false) and Rogue.item_name("arv") == "Armoured rescue vehicle",
		"the ARV contract lands as a capital item")
	# the training range offer: courses a quarter cheaper
	var cqb0: int = r1.dept.course_cost("cqb")
	r1.run.apply(r1, {"range": true}, {})
	check(r1.dept.has_range and r1.dept.course_cost("cqb") == int(round(cqb0 * Courses.RANGE_DISCOUNT)),
		"the range offer makes courses a quarter cheaper ($%d -> $%d)" % [cqb0, r1.dept.course_cost("cqb")])
	# the union contract: the morale floor rises for good
	var m0: int = int(r1.dept.morale_home)
	r1.run.apply(r1, {"morale_floor": Courses.MORALE_FLOOR_UP}, {})
	check(int(r1.dept.morale_home) == m0 + Courses.MORALE_FLOOR_UP, "the union contract raises the morale floor to %d" % int(r1.dept.morale_home))
	# the surplus-return offer is on the desk, and the tier-3 programs are repriced
	check(Rogue.OFFERS.any(func(o): return String(o.get("id", "")) == "return_surplus"), "the surplus-return offer exists")
	check(Rogue.PROGRAM_TIER3_WEEK == 20 and Rogue.PROGRAM_TIER3.size() > 0 and Rogue.PROGRAM_TIER3_MULT > 1.0,
		"tier-3 programs join the drafts at week %d, repriced x%.1f" % [Rogue.PROGRAM_TIER3_WEEK, Rogue.PROGRAM_TIER3_MULT])
	# P1.E2: a lost ally gets a reconciliation offer, once per ally per run
	r1.politics._ally("union", -100, r1.dept, [], "test")
	check(r1.politics.lost("union"), "union is lost after -100 standing")
	var rl: Array = r1.run._maybe_reconcile(r1)
	check(r1.run.offers.any(func(o): return String(o.get("id", "")) == "reconcile_union") and rl.size() == 1,
		"a lost ally gets a reconciliation offer")
	check(r1.run._maybe_reconcile(r1).is_empty(), "not again inside the cooldown window")
	# P1.F2: keeping the office pays +60 on a clean record, +20 on a violent one
	r1.politics.result = {"ending": {"keep": true}}
	var sc1: Dictionary = Rogue.run_score(r1)
	check(int(sc1["parts"].get("the election", 0)) == 60, "a clean record keeps the office for +60")
	r1.politics.record["officers_killed"] = 5
	var sc2: Dictionary = Rogue.run_score(r1)
	check(int(sc2["parts"].get("the election", 0)) == 20, "five officers killed: kept, but for +20")

## a whole run, randomly answered, for several seeds
	var seeds := int(args.get("seeds", "4"))
	for sd in seeds:
		var r0 = Campaign.new()
		r0.start(9000 + sd, true, LEGACY)
		var weeks := 0
		while not r0.over() and weeks < 45:
			_week_through(r0)
			weeks += 1
		var sc: Dictionary = Rogue.run_score(r0)
		check(r0.over() and weeks == 40, "run %d reaches the election in 40 weeks (score %d, %d contracts, %d programs, %d desk entries)" % [
			9000 + sd, int(sc["total"]), r0.run.contracts.size(), r0.run.programs_done.size(), r0.run.desk_log.size()])
	var lg: Dictionary = Rogue.load_legacy(LEGACY)
	check((lg["runs"] as Array).size() == seeds, "every finished run is in the legacy file (%d)" % (lg["runs"] as Array).size())
	check(Rogue.unlocked_doctrines(lg).size() > Rogue.DOCTRINE_BASE, "finished runs unlock more doctrines (%d)" % Rogue.unlocked_doctrines(lg).size())
	DirAccess.open("user://").remove(LEGACY.get_file())
	Equipment.armory = {}
	print("rogue_test: %d failure%s" % [failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
