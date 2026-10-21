extends RefCounted
## The campaign (v0.7): forty weeks to the election. Each week the operations board
## fills with situations; the player sends officers to some of them, plans and runs
## each one, and ends the week. Officers sent to one situation, or out canvassing for
## tips, are not available for any other that week. Situations nobody was sent to are
## written down as unattended, and the city remembers them (v0.9).
##
## One ironman save slot: the campaign is saved after every operation and every week.

const Department = preload("res://scripts/campaign/department.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Politics = preload("res://scripts/campaign/politics.gd")

const VERSION := 2        # 2: v0.9, the city's politics
const SAVE_PATH := "user://campaign.json"
const WEEKS := 40

var seed_val := 1001
var dept
var board: Array = []          # this week's situations
var past: Array = []           # every situation of earlier weeks, with its outcome
var rng := RandomNumberGenerator.new()
var politics                   # v0.9: wards, allies, candidates, the press, the election


func start(seed_v: int) -> void:
	seed_val = seed_v
	rng.seed = seed_v * 31 + 7
	dept = Department.new()
	dept.found(seed_v)
	politics = Politics.new()
	politics.start(seed_v)
	board = _new_board()
	dept.note("Week 1: %d situations on the board." % board.size())


func week() -> int:
	return dept.week


func _new_board() -> Array:
	if politics != null and politics.ended:
		return []
	return Situations.board(seed_val, dept.week, politics.trust if politics != null else [], politics == null or not politics.lost("coalition"))


func over() -> bool:
	return politics != null and politics.ended


## An operation's consequences for the city (v0.9). Returns readable lines.
func after_operation(sid: String, result: Dictionary, w) -> Array:
	var s := get_sit(sid)
	if s.is_empty():
		return []
	return politics.on_operation(dept.week, s, result, w, dept)


## Decide an internal affairs case: the department carries it out, the city watches.
func decide_case(c: Dictionary, decision: String) -> String:
	var ln: String = dept.decide(c, decision)
	if ln != "":
		for l2 in politics.on_decision(dept.week, c, decision, dept):
			ln += " " + l2
	return ln


func get_sit(sid: String) -> Dictionary:
	for s in board:
		if s["id"] == sid:
			return s
	return {}


## Officer ids already committed this week: planned into a situation, run in one, or
## out canvassing.
func committed(except_sid := "") -> Dictionary:
	var out := {}
	for s in board:
		if s["id"] == except_sid and s["status"] == "open":
			continue
		for oid in s.get("canvass", []):
			out[oid] = s["id"]
		for oid2 in plan_members(s):
			out[oid2] = s["id"]
	return out


static func plan_members(s: Dictionary) -> Array:
	var out: Array = []
	for sq in s.get("plan", {}).get("squads", []):
		for oid in sq.get("members", []):
			out.append(oid)
	return out


## Fit officers not committed to another situation this week.
func available_for(sid: String) -> Array:
	var busy := committed(sid)
	return dept.available().filter(func(r): return not busy.has(r["id"]) or busy[r["id"]] == sid)


## Send one officer to canvass the neighbourhood of a situation: two more tips, and the
## officer is gone for the week.
func canvass(sid: String, oid: String) -> Array:
	var s := get_sit(sid)
	if s.is_empty() or s["status"] != "open":
		return []
	var busy := committed()
	if busy.has(oid):
		return []
	s["canvass"].append(oid)
	var r: Dictionary = dept.get_officer(oid)
	var lines: Array = []
	for k in 2:
		lines.append(Situations.tip(s, rng, "canvass"))
	if not r.is_empty():
		r["file"].append({"week": dept.week, "text": "Canvassed for %s." % s["title"]})
	return lines


## An operation has been run: keep its plan and outcome on the situation.
func record(sid: String, result: Dictionary) -> void:
	var s := get_sit(sid)
	if s.is_empty():
		return
	s["status"] = "done"
	s["result"] = result


## The week ends: situations nobody went to are written down, wounds heal, and a new
## board fills. Returns readable lines.
func end_week() -> Array:
	var lines: Array = []
	for s in board:
		if s["status"] == "open":
			s["status"] = "unattended"
			lines.append("Unattended: %s." % s["title"])
			dept.note("Week %d: nobody went to %s." % [dept.week, s["title"]])
		past.append(_brief_record(s))
	if past.size() > 400:
		past = past.slice(past.size() - 400)
	# the city's week: what was left undone, what lands, the polls; at week 40 the election
	lines.append_array(politics.week_end(dept.week, board, dept))
	lines.append_array(dept.next_week())
	board = _new_board()
	if not over():
		dept.note("Week %d: %d situations on the board." % [dept.week, board.size()])
	return lines


## What is kept of a past situation (the full intel and plan are dropped).
static func _brief_record(s: Dictionary) -> Dictionary:
	return {"id": s["id"], "week": s["week"], "type": s["type"], "title": s["title"], "ward": s["ward"],
		"visibility": s["visibility"], "status": s["status"], "result": s.get("result", {}).duplicate(true)}


# ================================================================== saving
func to_data() -> Dictionary:
	return {"version": VERSION, "seed": seed_val, "rng_state": str(rng.state), "department": dept.to_data(),
		"board": board.duplicate(true), "past": past.duplicate(true), "politics": politics.to_data()}


func from_data(d: Dictionary) -> bool:
	var ver := int(d.get("version", 0))
	if ver < 1 or ver > VERSION:
		return false
	seed_val = int(d["seed"])
	rng.seed = seed_val * 31 + 7
	rng.state = String(d.get("rng_state", "0")).to_int()
	dept = Department.new()
	if not dept.from_data(d["department"]):
		return false
	board = d.get("board", [])
	past = d.get("past", [])
	# version 1 (before v0.9) had no politics: the city starts from the wards' trust now
	politics = Politics.new()
	politics.from_data(d.get("politics", {}), seed_val)
	for s in board:
		_ints(s)
	for s2 in past:
		_ints(s2)
	return true


## JSON keeps every number as a float: put back the ones that are integers.
static func _ints(s: Dictionary) -> void:
	for k in ["week", "seed", "map", "ward_i", "trust", "visibility", "crowd", "duration", "attack_t", "deadline", "tip_count"]:
		if s.has(k):
			s[k] = int(s[k])


func save(path := SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_data(), "\t"))
	f.close()
	return true


static func load_from(path := SAVE_PATH):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var c = load("res://scripts/campaign/campaign.gd").new()
	if not c.from_data(d):
		return null
	return c
