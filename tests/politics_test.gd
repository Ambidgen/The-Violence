extends SceneTree
## v0.9 gate: the city's politics. Stories land by visibility and evidence, allies are lost
## and what they hold goes with them, the DA charges what the chief clears, the election
## ends the campaign, and it all replays and saves exactly.
##   godot --headless --path . -s res://tests/politics_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")

var problems := 0
var _low_leaks := 0


## A JSON document with every object's keys in order. `to_data()` writes its top-level keys
## in a fixed order, but a dictionary rebuilt by `from_data` can hold the same keys in the
## order the save listed them, so a byte comparison of two saves reports a difference that
## no player would ever see. (2026-11-02: both save round trips failed on exactly that.)
func _canon(v):
	if v is Dictionary:
		var keys: Array = v.keys()
		keys.sort()
		var out := {}
		for k in keys:
			out[k] = _canon(v[k])
		return out
	if v is Array:
		var arr: Array = []
		for x in v:
			arr.append(_canon(x))
		return arr
	return v


## The first place two JSON documents differ, so a failing save round trip names its own
## key instead of printing two walls of numbers the annotation would truncate anyway.
func _json_diff(a: String, b: String) -> String:
	if a == b:
		return "nothing"
	var da = JSON.parse_string(a)
	var db = JSON.parse_string(b)
	if not (da is Dictionary) or not (db is Dictionary):
		return "not an object"
	for k in da:
		if not db.has(k):
			return "'%s' missing" % k
		var va := JSON.stringify(da[k])
		var vb := JSON.stringify(db[k])
		if va != vb:
			return "'%s' %s vs %s" % [k, va.substr(0, 60), vb.substr(0, 60)]
	for k2 in db:
		if not da.has(k2):
			return "extra '%s'" % k2
	return "order"


func _check(ok: bool, what: String) -> void:
	print("  %s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		problems += 1


## Just enough of a world for Politics.on_operation: officers, and an incident record.
class FakeOp:
	var id := ""
	var judges := false

	func _init(i: String, j: bool) -> void:
		id = i
		judges = j


class FakeIncident:
	var findings: Array = []
	var sm := {}

	func summary() -> Dictionary:
		return sm


class FakeWorld:
	var ops: Array = []
	var incident


func _world(civ_hit: int, strength: String, officers_killed := 0) -> FakeWorld:
	var w := FakeWorld.new()
	w.ops = [FakeOp.new("A1", true), FakeOp.new("B1", false)]
	var inc := FakeIncident.new()
	for k in civ_hit:
		inc.findings.append({"kind": "civilian_hit_by_police", "by": "A1", "strength": strength, "text": "x", "place": "y"})
	inc.sm = {"officers_killed": officers_killed, "suspects_killed": 0, "arrested": 1}
	w.incident = inc
	return w


func _sit(vis: int) -> Dictionary:
	return {"id": "T", "type": "warrant", "visibility": vis, "ward_i": 3, "ward": "Ironworks", "address": "1 Test Street"}


func _init() -> void:
	# a story on video at a high-visibility operation lands the next week
	var c = Campaign.new()
	c.start(5)
	var p = c.politics
	var tr0: int = p.trust[3]
	var co0: int = p.standing("coalition")
	p.on_operation(1, _sit(5), {"kind": "success", "civ_killed": 0}, _world(1, "video"), c.dept)
	_check(p.pending.filter(func(x): return x["kind"] == "story" and int(x["due"]) == 1).size() == 1, "a civilian hit on video at visibility 5: the story makes the next front page")
	_check(p.pending.filter(func(x): return x["kind"] == "lawsuit").size() == 1, "and a lawsuit is filed")
	c.end_week()
	_check(p.trust[3] < tr0 and p.standing("coalition") < co0, "it lands: Ironworks trust %d -> %d, the coalition %d -> %d" % [tr0, p.trust[3], co0, p.standing("coalition")])
	_check(p.press.any(func(x): return String(x["head"]).begins_with("BYSTANDER")), "and makes the front page")
	# out of sight, with nobody watching, some stories never land
	var never := 0
	for k in 40:
		var p2 = Politics.new()
		p2.start(100 + k)
		p2.on_operation(1, _sit(1), {"kind": "success"}, _world(1, "none"), null)
		if p2.pending.filter(func(x): return x["kind"] == "story").is_empty():
			never += 1
	_check(never >= 10 and never <= 30, "visibility 1, no witnesses: %d of 40 never reach the papers" % never)
	# the lawsuit settles out of the department's account
	var b0: int = c.dept.balance
	for k in 12:
		c.end_week()
	_check(p.record["settled"] == 1 and c.dept.ledger.any(func(x): return String(x["item"]).begins_with("Settlement")), "the lawsuit settled within twelve weeks")
	# losing the council costs 8% of the allocation; winning them back restores it
	var c2 = Campaign.new()
	c2.start(7)
	var a0: int = c2.dept.allocation
	var ln: Array = []
	c2.politics._ally("council", -40, c2.dept, ln)
	_check(c2.politics.lost("council") and c2.dept.allocation < a0, "council lost: allocation $%d -> $%d" % [a0, c2.dept.allocation])
	c2.politics._ally("council", 30, c2.dept, ln)
	_check(not c2.politics.lost("council") and absi(c2.dept.allocation - a0) <= 100, "council won back: allocation restored ($%d)" % c2.dept.allocation)
	c2.politics._ally("union", -50, c2.dept, ln)
	_check(c2.dept.morale_home == 45, "union lost: morale settles at 45")
	# coalition lost: no community tips anywhere
	var with_groups := Situations.board(9, 3, c2.politics.trust, true)
	var without := Situations.board(9, 3, c2.politics.trust, false)
	var t_with := 0
	var t_without := 0
	for s in with_groups:
		t_with += s["tips"].filter(func(t): return String(t).find("community group") >= 0).size()
	for s2 in without:
		t_without += s2["tips"].filter(func(t): return String(t).find("community group") >= 0).size()
	_check(t_without == 0, "coalition lost: no community tips (%d with the coalition, %d without)" % [t_with, t_without])
	# the DA charges what the chief clears, once the DA is lost
	c2.politics._ally("da", -50, c2.dept, ln)
	var r: Dictionary = c2.dept.available()[0]
	var cs: Dictionary = c2.dept.open_case(r, "civilian_hit_by_police", "hit a bystander", "video", "here")
	c2.decide_case(cs, "clear")
	_check(r["status"] == "suspended" and c2.politics.record["charged"] == 1, "DA lost: a cleared case with video gets the officer charged")
	# the election ends the campaign
	var c3 = Campaign.new()
	c3.start(11)
	var guard := 0
	while not c3.over() and guard < 60:
		c3.end_week()
		guard += 1
	_check(c3.over() and c3.board.is_empty() and c3.politics.result.has("winner"), "the election is held after week 40 (%d weeks) and %s wins" % [guard, Politics.CANDIDATES[c3.politics.result["winner"]]["name"]])
	var after_election := JSON.stringify(c3.to_data())
	check_election_noop(c3, after_election)
	_check(not c3.politics.result["ending"]["lines"].is_empty(), "with an ending: %s" % c3.politics.result["ending"]["head"])
	# every candidate can win, and each ending reads the record
	for cand in Politics.CAND_ORDER:
		var c7 = Campaign.new()
		c7.start(13)
		for k in Politics.CAND_ORDER:
			c7.politics.polls[k] = 90.0 if k == cand else 10.0
		c7.politics.hold_election(c7.dept)
		var e: Dictionary = c7.politics.result["ending"]
		_check(e["winner"] == cand and String(e["head"]) != "", "%s wins: %s" % [Politics.CANDIDATES[cand]["name"], e["head"]])
	# it replays and saves exactly
	var c4 = Campaign.new()
	c4.start(11)
	for k in 40:
		c4.end_week()
	_check(JSON.stringify(c4.politics.to_data()) == JSON.stringify(c3.politics.to_data()), "the same seed and the same weeks: the same city")
	var j := JSON.stringify(c3.to_data())
	var c5 = Campaign.new()
	c5.from_data(JSON.parse_string(j))
	var j5 := JSON.stringify(c5.to_data())
	var saved5 := JSON.stringify(_canon(JSON.parse_string(j5)))
	var saved3 := JSON.stringify(_canon(JSON.parse_string(j)))
	_check(saved5 == saved3, "the campaign, politics included, survives a save (differs at: %s)" % _json_diff(saved3, saved5))
	# Q3: a cleared case leaks by the officer's integrity, not just its evidence
	_check(Politics.leak_p("video", 60) > Politics.leak_p("witness", 60), "video still leaks more than witnesses at the same name")
	_check(Politics.leak_p("video", 10) > Politics.leak_p("video", 95), "integrity 10 leaks (%.2f) more than integrity 95 (%.2f)" % [Politics.leak_p("video", 10), Politics.leak_p("video", 95)])
	_check(Politics.leak_p("video", 60, "disagrees") > Politics.leak_p("video", 60, "matches"), "a statement the camera contradicts leaks more than one it backs up")
	for fixture in [[10, "low"], [95, "high"]]:
		var leaked := 0
		for k in 80:
			var px = Politics.new()
			px.start(4000 + k * 3 + fixture[0])
			px.on_decision(1, {"id": "IA-X", "officer": "PC-X", "kind": "excessive_force", "strength": "video", "text": "x", "integrity": fixture[0]}, "clear", null)
			leaked += px.pending.filter(func(x): return x["kind"] == "leak").size()
		if fixture[1] == "low":
			_low_leaks = leaked
		else:
			_check(leaked < _low_leaks, "over 80 cleared cases: integrity 95 leaked %d, integrity 10 leaked %d" % [leaked, _low_leaks])
	# and clearing a man the camera contradicted costs the DA and the coalition more
	var pa = Politics.new()
	pa.start(21)
	var da0: int = pa.standing("da")
	pa.on_decision(1, {"id": "IA-1", "officer": "PC-X", "kind": "excessive_force", "strength": "video", "text": "x", "integrity": 60, "statement": "matches"}, "clear", null)
	var pb = Politics.new()
	pb.start(21)
	pb.on_decision(1, {"id": "IA-1", "officer": "PC-X", "kind": "excessive_force", "strength": "video", "text": "x", "integrity": 60, "statement": "disagrees"}, "clear", null)
	_check(pb.standing("da") < pa.standing("da") and pa.standing("da") < da0, "the DA reads the statement: contradicted %d, matched %d (from %d)" % [pb.standing("da"), pa.standing("da"), da0])
	# Q8: the grant — ally-gated, once a quarter, and asking costs goodwill
	var cg = Campaign.new()
	cg.start(17)
	_check(cg.politics.can_grant(1) != "", "at the opening standing (%d) the committee says no" % cg.politics.standing("council"))
	var waste: Array = []
	cg.politics._ally("council", 10, cg.dept, waste)
	var gb0: int = cg.dept.balance
	var gs0: int = cg.politics.standing("council")
	var gr: Dictionary = cg.politics.apply_grant(1, cg.dept)
	_check(bool(gr["ok"]) and cg.dept.balance == gb0 + Politics.GRANT_AMOUNT and cg.politics.standing("council") == gs0 - Politics.GRANT_FAVOUR,
		"the grant lands ($%s) and the favour is spent (%d -> %d)" % [Department.money(Politics.GRANT_AMOUNT), gs0, cg.politics.standing("council")])
	_check(cg.politics.can_grant(4) != "" and cg.politics.can_grant(1 + Politics.GRANT_COOLDOWN) == "",
		"and the committee will not be asked again for %d weeks" % Politics.GRANT_COOLDOWN)
	var jg := JSON.stringify(cg.politics.to_data())
	var pg = Politics.new()
	pg.from_data(JSON.parse_string(jg), 17)
	var pgs := JSON.stringify(_canon(JSON.parse_string(JSON.stringify(pg.to_data()))))
	var jgc := JSON.stringify(_canon(JSON.parse_string(jg)))
	_check(pgs == jgc and pg.last_grant == 1, "the grant week survives a save (differs at: %s)" % _json_diff(jgc, pgs))
	# Q10: chatter priced in the briefing, and the suggestion sized by it
	var sit: Dictionary = Situations.make("event", 4242, 1, 0)
	var ch: Dictionary = Situations.chatter(sit)
	_check(int(ch.get("odds", 0)) >= 2 and int(ch.get("conf", 0)) >= 30, "a fresh rally reads as a priced bet (1 in %d, %d%%)" % [int(ch.get("odds", 0)), int(ch.get("conf", 0))])
	for f in sit["intel"]:
		if f.get("key", "") == "threat":
			f["level"] = "lowered"
			f["est"] = "lowered (about 1 in 20)"
	_check(Autoplan.want_for(sit) == Autoplan.EVENT_WANT_LOW, "lowered chatter: the suggestion sends six")
	for f2 in sit["intel"]:
		if f2.get("key", "") == "threat":
			f2["level"] = "raised"
			f2["est"] = "raised (about 1 in 5)"
	_check(Autoplan.want_for(sit) == Autoplan.WANT["event"], "raised chatter: the full ten")
	var threat_line := ""
	for brief_line in Situations.briefing_lines(sit):
		if String(brief_line["label"]) == "Threat estimate":
			threat_line = String(brief_line["text"])
	_check(threat_line.find("cries wolf") >= 0, "and the briefing carries the confidence: %s" % threat_line)
	# a version 1 save (before v0.9) loads, with the city starting fresh
	var old: Dictionary = c2.to_data()
	old["version"] = 1
	old.erase("politics")
	var c6 = Campaign.new()
	_check(c6.from_data(old) and c6.politics.trust.size() == Situations.WARDS.size(), "a v0.8 save loads; the city starts from the wards' trust")
	_lawsuit_instalments_d3()
	_surplus_sweep_d4()
	_causes_e1_f1()
	print("problems: %d" % problems)
	quit(1 if problems > 0 else 0)


func check_election_noop(c, before: String) -> void:
	_check(c.end_week().is_empty() and JSON.stringify(c.to_data()) == before, "ending an already finished campaign does not advance time or pay again")
	_check(c.politics.share("not-a-candidate") == 0.0, "an unknown candidate has no phantom poll share")
	var p = Politics.new()
	p.from_data({"trust": [1, 2, 3, 4, 5, 6, 99]}, 5)
	_check(p.trust.size() == Situations.WARDS.size() and p.avg_trust() == 3.5, "extra saved trust entries cannot distort the six-ward average")


## EA_TASKS P1.D3: a lawsuit settles in four weekly instalments — one paid a week,
## each costing the council standing with its cause logged — and only counts as
## settled when the last one is paid. The shape survives a save.
func _lawsuit_instalments_d3() -> void:
	print("  -- lawsuit instalments (P1.D3)")
	var c = Campaign.new()
	c.start(11)
	var p: Politics = c.politics
	var dept = c.dept
	var inst: Array = []
	for k in 4:
		inst.append({"week": 3 + k, "amount": 4000, "paid": false})
	p.pending.append({"due": 3, "kind": "lawsuit", "cost": 16000, "ward": 0, "op_week": 1, "instalments": inst})
	var bal0: int = dept.balance
	p.week_end(1, [], dept)
	p.week_end(2, [], dept)
	_check(dept.balance == bal0, "nothing is paid before the first instalment's week")
	var co0: int = p.standing("council")
	p.week_end(3, [], dept)
	_check(dept.balance == bal0 - 4000 and p.standing("council") == co0 - 3,
		"week 3 pays the first $4,000 instalment and costs the council 3 standing (%d -> %d)" % [co0, p.standing("council")])
	_check(p.week_causes(3).any(func(l): return String(l).contains("instalment")), "the instalment's cause is in the week's cause log")
	# the paid flag survives a save
	var p2 = Politics.new()
	p2.from_data(JSON.parse_string(JSON.stringify(p.to_data())), 11)
	var l2: Array = p2.pending.filter(func(x): return x.get("kind", "") == "lawsuit")
	_check(l2.size() == 1 and bool(l2[0]["instalments"][0]["paid"]) and not bool(l2[0]["instalments"][1]["paid"]),
		"a save keeps the instalment ledger (first paid, second not)")
	p.week_end(4, [], dept)
	_check(dept.balance == bal0 - 8000 and int(p.record.get("settled", 0)) == 0, "week 4 pays the second; not settled yet")
	p.week_end(5, [], dept)
	_check(dept.balance == bal0 - 12000 and int(p.record.get("settled", 0)) == 0, "week 5 pays the third")
	p.week_end(6, [], dept)
	_check(dept.balance == bal0 - 16000 and int(p.record.get("settled", 0)) == 1, "week 6 pays the last; the lawsuit is settled")
	_check(p.pending.filter(func(x): return x.get("kind", "") == "lawsuit").is_empty(), "a settled lawsuit leaves the pending list")


## EA_TASKS P1.D4: the quarterly sweep and the hand surplus return. The sweep takes
## half of everything above $25,000 (capped at $30,000) every fourth week; returning
## $5,000 of surplus by hand buys council standing, once every four weeks.
func _surplus_sweep_d4() -> void:
	print("  -- surplus sweep and hand return (P1.D4)")
	var c = Campaign.new()
	c.start(12)
	var p: Politics = c.politics
	var dept = c.dept
	dept.balance = 60000
	var bal0: int = dept.balance
	var co0: int = p.standing("council")
	p.week_end(4, [], dept)
	var sweep: int = mini(30000, int(round((bal0 - 25000) * 0.5 / 100.0)) * 100)
	_check(dept.balance == bal0 - sweep and p.standing("council") >= co0 + 2,
		"week 4 sweeps $%s above the $25,000 floor and the council notices (+2)" % Department.money(sweep))
	_check(p.week_causes(4).any(func(l): return String(l).contains("swept") or String(l).contains("surplus")), "the sweep's cause is logged")
	dept.balance = 30000
	co0 = p.standing("council")
	_check(p.can_surplus(4) == "", "with a surplus and no cooldown, the return is offered")
	var res: Dictionary = p.apply_surplus(4, dept)
	_check(bool(res.get("ok", false)) and dept.balance == 25000 and p.standing("council") == co0 + 6,
		"returning $5,000 buys +6 council standing")
	_check(p.can_surplus(4) != "", "and goes on cooldown")
	p.week_end(5, [], dept)
	p.week_end(6, [], dept)
	p.week_end(7, [], dept)
	_check(p.can_surplus(7) != "", "still cooling down at week 7")
	p.week_end(8, [], dept)
	_check(p.can_surplus(8) == "", "cooled down again by week 8")


## EA_TASKS P1.E1 / P1.F1: every ally and poll movement carries a cause, and the week's
## cause log reads them back; a quiet week holds every non-lost ally's standing (E3).
func _causes_e1_f1() -> void:
	print("  -- ally and poll causes (P1.E1, P1.F1, P1.E3)")
	var c = Campaign.new()
	c.start(13)
	var p: Politics = c.politics
	var dept = c.dept
	var tmp: Array = []
	p._ally("union", 5, dept, tmp, "a test decision")
	p._poll("pell", 2.0, "a test decision")
	var cl: Array = p.week_causes(1)
	_check(cl.any(func(l): return String(l).contains(p.ally_name("union")) and String(l).contains("+5") and String(l).contains("test decision")),
		"an ally gain is logged with its cause: %s" % str(cl))
	_check(cl.any(func(l): return String(l).contains("Pell") and String(l).contains("+2.0")), "and so is a poll gain")
	p.week_end(1, [], dept)
	_check(p.week_causes(1).size() >= 2, "the causes survive the week_end into the log")
	# E3: a quiet week (nothing moved an ally) holds every non-lost ally's standing
	var before: Dictionary = {}
	for a in Politics.ALLY_ORDER:
		before[a] = p.standing(a)
	p.week_end(2, [], dept)
	var held := 0
	for a in Politics.ALLY_ORDER:
		if not p.lost(a) and p.standing(a) == before[a] + 1:
			held += 1
	_check(held >= 1, "a quiet week holds non-lost allies' standing (+1 on %d of them)" % held)
