extends SceneTree
## The balance policies (EA_TASKS P1.A1), without the simulation: every gate the
## harness depends on, in a few seconds.
##
##   godot --headless --path . -s res://tests/policies_test.gd
##
## Gates: the four policies exist and parse; the same seed and policy settle the desk the
## same way twice (deterministic, not random); the desk is settled **before** the first
## operation and never left blocking the week; the policies actually differ; the call
## plan respects the policy's cap and priority and only offers open situations; kit is
## bought only by the policies that buy kit; the Gate 1 bands file is well formed and
## asserts (P1.I2) — a full matrix fails the tier on a miss, the two-week smoke never does.

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Policies = preload("res://tests/policies.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")

const LEGACY := "user://legacy_policies_test.json"
var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1


func _init() -> void:
	DirAccess.open("user://").remove(LEGACY.get_file())

	# ---- the four policies, by name
	check(Policies.all() == ["cautious", "minimal", "military", "accept_all"],
		"the four policies exist in the plan's order (%s)" % ", ".join(Policies.all()))
	check(Policies.parse("all").size() == 4, "parse(\"all\") is every policy")
	check(Policies.parse("cautious,military") == ["cautious", "military"], "parse takes a list")
	check(Policies.parse("minimal,minimal").size() == 1, "parse drops duplicates")
	check(Policies.parse("nonsense").is_empty(), "parse reports an unknown policy as nothing")
	check(Policies.label("military") == "military-first" and Policies.label("accept_all") == "accept-all",
		"the labels are the plan's names")

	# ---- deterministic: the same seed settles the desk the same way twice
	for pol in Policies.all():
		var a = Campaign.new()
		a.start(4242, true, LEGACY)
		var b = Campaign.new()
		b.start(4242, true, LEGACY)
		var la: Array = Policies.settle_desk(a, pol)
		var lb: Array = Policies.settle_desk(b, pol)
		check(JSON.stringify(a.run.to_data()) == JSON.stringify(b.run.to_data()),
			"%s: the same seed settles the same desk (no random answers)" % pol)
		check(la == lb, "%s: and writes the same lines" % pol)

	# ---- the desk is settled after the inheritance, before any operation, and leaves
	# nothing blocking the week (the interface refuses End week while a draft is open)
	for pol2 in Policies.all():
		var c = Campaign.new()
		c.start(1001, true, LEGACY)
		var had_doctrine: bool = false
		for d in c.run.drafts:
			if String(d["kind"]) == "doctrine":
				had_doctrine = true
		Policies.settle_desk(c, pol2)
		check(c.run.blocking().is_empty(), "%s: nothing is left blocking the week (%s)" % [pol2, str(c.run.blocking())])
		check(c.run.doctrine != "", "%s: the inheritance was chosen (had one dealt: %s -> %s)" % [pol2, str(had_doctrine), c.run.doctrine])

	# ---- the policies differ, and in the ways they are meant to
	var doc := {}
	var contracts := {}
	for pol3 in Policies.all():
		var d3 = Campaign.new()
		d3.start(1001, true, LEGACY)
		Policies.settle_desk(d3, pol3)
		doc[pol3] = d3.run.doctrine
		contracts[pol3] = d3.run.contracts.duplicate()
	check(doc["cautious"] != doc["military"] or doc["cautious"] != doc["accept_all"],
		"the inheritance differs between policies (%s)" % str(doc))
	check((contracts["minimal"] as Array).is_empty(), "minimal signs no contract (%s)" % str(contracts["minimal"]))
	check(not (contracts["military"] as Array).is_empty() or not (contracts["cautious"] as Array).is_empty(),
		"cautious or military sign one (%s / %s)" % [str(contracts["cautious"]), str(contracts["military"])])
	for pol4 in Policies.all():
		for cid in contracts[pol4]:
			var tag := String(Rogue.CONTRACTS.get(String(cid), {}).get("tag", ""))
			if pol4 == "cautious":
				check(tag != "military", "cautious never signs military hardware (%s)" % cid)
			if pol4 == "military":
				check(tag == "military" or tag == "neutral", "military-first signs hardware or neutral kit (%s: %s)" % [cid, tag])

	# ---- kit: only the policies that buy it let a plan issue new kit
	check(not Policies.issues_kit("cautious") and not Policies.issues_kit("minimal"),
		"cautious and minimal run on current kit")
	check(Policies.issues_kit("military") and Policies.issues_kit("accept_all"),
		"military-first and accept-all let the plan buy kit")

	# ---- the call plan: open situations only, the policy's cap, its priority order
	for pol5 in Policies.all():
		var c5 = Campaign.new()
		c5.start(3003, true, LEGACY)
		Policies.settle_desk(c5, pol5)
		var plan: Array = Policies.call_plan(c5, pol5)
		var cap: int = int(Policies.POLICIES[pol5]["calls"]["max"])
		check(plan.size() <= cap, "%s: takes at most %d call(s) (%d)" % [pol5, cap, plan.size()])
		check(plan.all(func(s): return String(s["status"]) == "open"), "%s: only open situations" % pol5)
		var prio := true
		for i in range(1, plan.size()):
			if int(Policies.CALL_PRIORITY.get(String(plan[i]["type"]), 9)) < int(Policies.CALL_PRIORITY.get(String(plan[i - 1]["type"]), 9)):
				prio = false
		check(prio, "%s: the gravest calls come first (%s)" % [pol5, str(plan.map(func(s): return s["type"]))])
	check(int(Policies.POLICIES["minimal"]["calls"]["max"]) == 1 and int(Policies.POLICIES["cautious"]["calls"]["max"]) == 2
		and int(Policies.POLICIES["military"]["calls"]["max"]) == 3,
		"minimal answers one call a week, cautious two, military-first and accept-all three")

	# ---- a short account is handled: the desk still gets settled, nothing is bought
	var poor = Campaign.new()
	poor.start(1001, true, LEGACY)
	poor.dept.balance = 250
	var from: int = poor.dept.ledger.size()
	Policies.settle_desk(poor, "accept_all")
	check(poor.run.blocking().is_empty(), "accept-all settles the desk with $250 in the account (%s)" % str(poor.run.blocking()))
	# The invariant is not "it buys nothing" -- accept-all signs what the desk offers,
	# and a card can pay into the account before another is paid out of it. It is that
	# no purchase takes the account below zero: the desk is settled, not overdrawn.
	var cash := 250
	var low := cash
	for i in range(from, poor.dept.ledger.size()):
		cash += int(poor.dept.ledger[i]["amount"])
		low = mini(low, cash)
	check(cash == poor.dept.balance, "the ledger accounts for every dollar of the settlement ($%d walked, $%d in the account)" % [cash, int(poor.dept.balance)])
	check(low >= 0, "and it settles the week without an overdraft (lowest $%d; contracts %s)" % [low, str(poor.run.contracts)])

	# ---- the roster levers (EA_TASKS P1.C3, P1.C4): used the way the Roster offers them
	for pol6 in Policies.all():
		var rc = Campaign.new()
		rc.start(1001, true, LEGACY)
		rc.dept.balance = 200000
		var keep_rule: int = int(Policies.POLICIES[pol6]["hire"].get("keep_on_books", 0))
		var below: int = int(Policies.POLICIES[pol6]["hire"].get("emergency_below", 0))
		# a department down to 8 fit: the rest injured
		var k := 0
		for r in rc.dept.officers:
			if String(r["status"]) == "active":
				k += 1
				if k > 8:
					r["status"] = "injured"
					r["out_until"] = rc.dept.week + 3
		var fit0: int = rc.dept.available().size()
		var hl: Array = Policies.hiring(rc, pol6)
		var signed: bool = hl.any(func(l): return String(l).contains("emergency lateral"))
		var hired_on: bool = bool(Policies.POLICIES[pol6]["hire"]["on"])
		check(signed == (hired_on and below > fit0), "%s: %s the emergency lateral at %d fit" % [pol6, "signs" if signed else "does not sign", fit0])
		check(int(rc.dept.keep_on_books) == (keep_rule if hired_on else 0), "%s: standing order %d" % [pol6, int(rc.dept.keep_on_books)])

	# ---- the bands file: well formed, every metric known, asserting (P1.I2)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://tests/balance_bands.json"))
	check(parsed is Dictionary, "balance_bands.json parses")
	var bands: Dictionary = parsed if parsed is Dictionary else {}
	check(int(bands.get("gate", 0)) == 1, "it is the Gate 1 file")
	check(String(bands.get("status", "")) == "asserting" and bool(bands.get("enforce", false)),
		"and it asserts on a full matrix, never on the smoke (status %s, enforce %s)" % [bands.get("status"), str(bands.get("enforce"))])
	var known := ["min_fit", "weeks_fit_below_12", "weeks_below_zero", "weeks_below_zero_1_12", "balance_end",
		"balance_min", "balance_max", "unattended", "officers_killed", "officers_killed_per_op", "civ_killed",
		"findings", "allies_lost_end", "allies_regained", "run_score", "kept_share", "ops", "successes", "failures"]
	var tests := [">=", ">", "<=", "<", "=="]
	var aggs := ["min", "max", "mean"]
	var bad: Array = []
	for band in bands.get("bands", []):
		var m := String(band.get("metric", ""))
		if not known.has(m):
			bad.append("unknown metric %s" % m)
		if not tests.has(String(band.get("test", ""))):
			bad.append("%s: bad test %s" % [m, band.get("test")])
		if not aggs.has(String(band.get("agg", ""))):
			bad.append("%s: bad agg %s" % [m, band.get("agg")])
		if String(band.get("why", "")) == "":
			bad.append("%s: no reason given" % m)
	check(bad.is_empty() and not (bands.get("bands", []) as Array).is_empty(),
		"every band names a known metric, test and aggregation, with a reason (%d bands)%s" % [
			(bands.get("bands", []) as Array).size(), "" if bad.is_empty() else ": " + ", ".join(bad)])

	DirAccess.open("user://").remove(LEGACY.get_file())
	print("policies_test: %d failure%s" % [failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
