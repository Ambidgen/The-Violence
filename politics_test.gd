extends SceneTree
## v0.9 gate: the city's politics. Stories land by visibility and evidence, allies are lost
## and what they hold goes with them, the DA charges what the chief clears, the election
## ends the campaign, and it all replays and saves exactly.
##   godot --headless --path . -s res://tests/politics_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Situations = preload("res://scripts/campaign/situations.gd")

var problems := 0


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
	_check(j5 == j, "the campaign, politics included, survives a save")
	# a version 1 save (before v0.9) loads, with the city starting fresh
	var old: Dictionary = c2.to_data()
	old["version"] = 1
	old.erase("politics")
	var c6 = Campaign.new()
	_check(c6.from_data(old) and c6.politics.trust.size() == Situations.WARDS.size(), "a v0.8 save loads; the city starts from the wards' trust")
	print("problems: %d" % problems)
	quit(1 if problems > 0 else 0)
