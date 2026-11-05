extends RefCounted
## The campaign (v0.7): forty weeks to the election. Each week the operations board
## fills with situations; the player sends officers to some of them, plans and runs
## each one, and ends the week. Officers sent to one situation, or out canvassing for
## tips, are not available for any other that week. Situations nobody was sent to are
## written down as unattended, and the city remembers them (v0.9).
##
## One ironman save slot: the campaign is saved after every operation and every week.

const Department = preload("res://scripts/campaign/department.gd")
const Courses = preload("res://scripts/data/courses.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Patrol = preload("res://scripts/campaign/patrol.gd")

const VERSION := 4        # 2: v0.9, the city's politics; 3: the endless-battle link (removed); 4: the run layer (roguelike)
const SAVE_PATH := "user://campaign.json"
static var read_city_file := false   # kept for old harnesses; the endless battle is gone
const WEEKS := 40

var seed_val := 1001
var dept
var board: Array = []          # this week's situations
var past: Array = []           # every situation of earlier weeks, with its outcome
var patrols: Array = []        # this week's patrol encounters, one a day (Patrol, 2026-11-05)
var patrol_past: Array = []    # earlier weeks' encounters, briefly
var rng := RandomNumberGenerator.new()
var politics                   # v0.9: wards, allies, candidates, the press, the election
var run                        # 1.3: the run layer (Rogue) for a roguelike story; null for the classic campaign
var opening: Array = []        # 1.3: what the desk said when the run began
var legacy_path := "user://legacy.json"   # 1.3: where finished runs are recorded (harnesses point elsewhere)
# Presentation history is additive save data: it never enters simulation decisions.
var short_history := {}         # key -> week last played; each shipped short once per campaign
var short_last_week := -99
var last_recap := {}           # S15 Week Closed: the week end_week() just closed (not saved)
var _recovered_path := ""      # preserve the known-good .bak on the first save after recovery
const SHORT_COOLDOWN_WEEKS := 3


## rogue: a roguelike run (every story begun from the title screen). The classic
## campaign (rogue = false) is what the deterministic harnesses replay.
func start(seed_v: int, rogue := false, legacy_path_v: String = Rogue.LEGACY_PATH) -> void:
	seed_val = seed_v
	past = []
	short_history = {}
	short_last_week = -99
	_recovered_path = ""
	rng.seed = seed_v * 31 + 7
	dept = Department.new()
	dept.found(seed_v)
	politics = Politics.new()
	politics.start(seed_v)
	board = _new_board()
	patrol_past = []
	patrols = _new_patrols()
	run = null
	opening = []
	legacy_path = legacy_path_v
	if rogue:
		run = Rogue.new()
		run.start(seed_v, Rogue.load_legacy(legacy_path_v))
		run.on_board(self)
		opening = run.on_week_start(self)
	activate()
	dept.note("Week 1: %d situations on the board." % board.size())


## Make this campaign's armoury the one every kit is checked against.
func activate() -> void:
	Equipment.armory = run.armory_set() if run != null else {}


func week() -> int:
	return dept.week


func _new_board() -> Array:
	if politics != null and politics.ended:
		return []
	return Situations.board(seed_val, dept.week, politics.trust if politics != null else [],
		politics == null or not politics.lost("coalition"))


func _new_patrols() -> Array:
	if politics != null and politics.ended:
		return []
	return Patrol.week_encounters(seed_val, dept.week, dept)


func get_patrol(pid: String) -> Dictionary:
	for e in patrols:
		if String(e["id"]) == pid:
			return e
	return {}


## The chief answers a patrol encounter (Patrol, 2026-11-05): 0 proceed, 1 proceed with
## backup en route, 2 wait for backup. Returns {"lines": [...], "run": sid}: "run" names
## the situation the interface (or the harness) must now play when the encounter turned
## out to be armed; it is on the board with its plan made.
func decide_patrol(pid: String, choice: int, allow_sim := true) -> Dictionary:
	var e := get_patrol(pid)
	if e.is_empty() or String(e["status"]) != "pending":
		return {"lines": [], "run": ""}
	choice = clampi(choice, 0, 2)
	e["choice"] = choice
	Patrol.refresh_pair(e, dept)
	e["backup"] = Patrol.pick_officers(e, dept, 2, e["pair"]) if choice >= 1 else []
	if e["pair"].is_empty():
		# nobody fit to send: the call goes unanswered, and the ward notices
		e["status"] = "done"
		e["result"] = {"kind": "failure", "late": true, "text": "No car was free.", "trust": -1}
		politics._trust(int(e["ward_i"]), -1)
		return {"lines": ["%s: no car was free." % Patrol.spec(e)["name"]], "run": ""}
	var armed: bool = bool(e.get("armed", false))
	# the wait itself can cost an armed call too: gone (or worse) before the cars arrive
	if armed and allow_sim and not Patrol.is_late(e, choice):
		var used: Array = []
		for s0 in board:
			if s0.get("site_id", "") != "":
				used.append(s0["site_id"])
		var s: Dictionary = Patrol.to_situation(e, choice, dept, politics.trust, not politics.lost("coalition"), used)
		if not s.is_empty():
			e["status"] = "running"
			e["sim"] = true
			board.append(s)
			if Patrol.OVERTIME[choice] > 0:
				dept.spend("Overtime, patrol backup (%s, %s)" % [String(Patrol.spec(e)["name"]).to_lower(), Patrol.DAYS[int(e["day"])]], Patrol.OVERTIME[choice])
			return {"lines": ["%s: the suspect is armed. It is now an operation." % Patrol.spec(e)["name"]], "run": String(s["id"])}
	var res: Dictionary = Patrol.resolve_desk(e, choice, dept)
	var lines: Array = Patrol.apply(e, choice, res, dept)
	lines.append_array(politics.on_patrol(dept.week, e, res, dept))
	e["result"] = res
	e["status"] = "done"
	lines.push_front(Patrol.summary_line(e))
	return {"lines": lines, "run": ""}


func over() -> bool:
	return politics != null and politics.ended


## Rare interstitials: one play per key per campaign, and no ordinary shorts in
## adjacent weeks. Election night may override the gap, but not the per-key limit.
func claim_short(key: String, force := false) -> bool:
	if short_history.has(key):
		return false
	if not force and week() - int(short_last_week) < SHORT_COOLDOWN_WEEKS:
		return false
	short_history[key] = week()
	short_last_week = week()
	return true


## An operation's consequences for the city (v0.9). Returns readable lines.
func after_operation(sid: String, result: Dictionary, w) -> Array:
	var s := get_sit(sid)
	if s.is_empty():
		return []
	return politics.on_operation(dept.week, s, result, w, dept)


## The account four weeks out (Q8): the department's books against the city's
## pending ledger (the lawsuits already filed).
func forecast(weeks_n := 4) -> Array:
	return dept.forecast(weeks_n, politics.pending if politics != null else [])


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
## EA_TASKS P1.C5: the kit Suggest a plan proposed (plan["kit"], see Autoplan.propose_kit),
## priced: what issuing it would cost now (new kit at cost, kit handed back at half).
func plan_kit_cost(s: Dictionary) -> int:
	var plan: Dictionary = s.get("plan", {})
	var t := 0
	var members: Array = plan_members(s)
	for oid in plan.get("kit", {}):
		var r: Dictionary = dept.get_officer(String(oid))
		var p: Dictionary = plan["kit"][oid]
		if r.is_empty() or not members.has(oid) or JSON.stringify(r["kit"]) != JSON.stringify(p["from"]):
			continue
		var d: int = Equipment.cost(p["to"]) - int(r.get("issued", Equipment.cost(r["kit"])))
		t += d if d > 0 else -int(round(-d * Courses.SURPLUS))
	return t


## Issue the proposed kit as the operation starts, unless the chief kept their own
## (plan["kit_mode"] == "own"): only to officers who are going, whose kit has not been
## changed by hand since it was proposed, and through the department's reissue (it is
## bought, and refused while the account is in the red). Returns lines for the log.
func issue_plan_kit(s: Dictionary) -> Array:
	var plan: Dictionary = s.get("plan", {})
	var lines: Array = []
	if String(plan.get("kit_mode", "suggested")) == "own" or plan.get("kit", {}).is_empty():
		return lines
	var members: Array = plan_members(s)
	var n := 0
	var spent := 0
	for oid in plan["kit"]:
		var r: Dictionary = dept.get_officer(String(oid))
		var p: Dictionary = plan["kit"][oid]
		if r.is_empty() or not members.has(oid) or JSON.stringify(r["kit"]) != JSON.stringify(p["from"]):
			continue
		var got = dept.reissue(r, p["to"])
		if got is String:
			lines.append("The suggested kit was not issued: %s." % got)
			break
		n += 1
		spent += int(got)
	if n > 0:
		lines.append("Entry kit issued to %d officer%s ($%s)." % [n, "" if n == 1 else "s", Department.money(spent)])
	plan["kit"] = {}
	return lines


## The board's next-week strip (EA_TASKS P1.C2): who will be fit when next week starts,
## and what this week's open calls want between them (Suggest a plan's force for each).
## Below ROSTER_FLOOR the strip is red: the 28 Oct playtest and the 1.A baseline both
## lose calls to an empty roster long before they lose them to anything else.
const ROSTER_FLOOR := 12


func roster_outlook() -> Dictionary:
	var out: Dictionary = dept.fit_next_week()
	var want := 0
	var n_open := 0
	for s in board:
		if String(s.get("status", "")) == "open" and not s.get("truce", false):
			want += Autoplan.want_for(s)
			n_open += 1
	out["want"] = want
	out["open"] = n_open
	out["short"] = int(out["fit"]) < ROSTER_FLOOR
	return out


func committed(except_sid := "") -> Dictionary:
	var out := {}
	for s in board:
		# Canvassing commits an officer for the week, including to this call.
		for oid in s.get("canvass", []):
			out[oid] = s["id"]
		# A plan may be edited without treating its existing members as busy.
		if s["id"] == except_sid and s["status"] == "open":
			continue
		# a patrol encounter takes nobody off the week's operations (owner, 2026-11-05)
		if String(s.get("patrol_id", "")) != "":
			continue
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
	return dept.available().filter(func(r): return not busy.has(r["id"]))


## Send one officer to canvass the neighbourhood of a situation: two more tips, and the
## officer is gone for the week.
func canvass(sid: String, oid: String) -> Array:
	var s := get_sit(sid)
	if s.is_empty() or s["status"] != "open":
		return []
	var busy := committed(sid)
	if busy.has(oid):
		return []
	var r: Dictionary = dept.get_officer(oid)
	if r.is_empty() or r.get("status", "") != "active":
		return []
	# Only after all checks pass, transfer this officer out of this call's plan.
	for sq in s.get("plan", {}).get("squads", []):
		sq.get("members", []).erase(oid)
	s["canvass"].append(oid)
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
	if String(s.get("patrol_id", "")) != "":
		var e := get_patrol(String(s["patrol_id"]))
		if not e.is_empty():
			e["result"] = Patrol.from_operation(e, result)
			e["status"] = "done"
			politics.record["patrols"] = int(politics.record.get("patrols", 0)) + 1


## The week ends: situations nobody went to are written down, wounds heal, and a new
## board fills. Returns readable lines.
func end_week() -> Array:
	if over():
		return []
	var lines: Array = []
	# patrol encounters nobody answered: the pair went in on their own
	# (an armed one is settled on the desk: there is no one to watch it play out), and an
	# armed one answered but never run is settled the same way, with the chief's choice
	for e0 in patrols:
		if String(e0["status"]) != "running":
			continue
		var s_run := get_sit(String(e0["id"]))
		if not s_run.is_empty() and String(s_run["status"]) == "done":
			continue
		board.erase(s_run)
		e0["status"] = "pending"
		e0["sim"] = false
		e0["overtime_paid"] = true
		lines.append_array(decide_patrol(String(e0["id"]), int(e0["choice"]), false)["lines"])
	for e in Patrol.pending(patrols):
		lines.append_array(decide_patrol(String(e["id"]), 0, false)["lines"])
	# S15 Week Closed: the week as it stood when the chief ended it
	var recap := _recap_start()
	if run != null:
		lines.append_array(run.on_week_end(self))
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
	if run != null and politics.ended:
		var newly: Array = run.record_run(self, legacy_path)
		var sc: Dictionary = Rogue.run_score(self)
		lines.append("Run score: %d." % int(sc["total"]))
		for nd in newly:
			lines.append("Unlocked for the next run: %s." % Rogue.DOCTRINES[nd]["name"])
	lines.append_array(dept.next_week())
	recap["money"] = dept.balance - int(recap["money"])
	recap["balance"] = dept.balance
	var press: Array = politics.week_press(int(recap["week"]))
	if not press.is_empty():
		recap["headline"] = String(press[0].get("head", "")).to_upper()
	last_recap = recap
	var triage := Department.triage_line(dept.cases, dept.week)
	if triage != "":
		lines.append(triage)
	for e2 in patrols:
		patrol_past.append({"id": e2["id"], "week": e2["week"], "kind": e2["kind"], "ward": e2["ward"], "choice": e2["choice"],
			"status": e2["status"], "result": (e2.get("result", {}) as Dictionary).duplicate(true)})
	if patrol_past.size() > 300:
		patrol_past = patrol_past.slice(patrol_past.size() - 300)
	board = _new_board()
	patrols = _new_patrols()
	if not over():
		dept.note("Week %d: %d situations on the board." % [dept.week, board.size()])
		if run != null:
			run.on_board(self)
			lines.append_array(run.on_week_start(self))
	return lines


## S15 Week Closed: this week's counts, taken before end_week() moves anything. "money"
## holds the opening balance until end_week() turns it into the week's movement.
func _recap_start() -> Dictionary:
	var r := {"week": dept.week, "of": Politics.ELECTION_WEEK,
		"answered": 0, "unattended": 0, "arrests": 0, "civilians": 0, "officers": 0, "wounded": 0,
		"money": dept.balance, "balance": dept.balance, "headline": "", "verdict": "CLOSED"}
	for s in board:
		if s["status"] == "done":
			r["answered"] += 1
			var res: Dictionary = s.get("result", {})
			r["arrests"] += int(res.get("arrests", 0))
			r["civilians"] += int(res.get("civ_killed", 0))
			r["officers"] += int(res.get("officers_killed", 0))
			r["wounded"] += int(res.get("officers_hurt", 0))
		elif s["status"] == "open":
			r["unattended"] += 1
	# patrol encounters settled on the desk (the armed ones are on the board above)
	r["patrols"] = 0
	for e in patrols:
		if String(e["status"]) != "done":
			continue
		r["patrols"] += 1
		if bool(e.get("sim", false)):
			continue
		var pr: Dictionary = e.get("result", {})
		r["arrests"] += int(pr.get("arrests", 0))
		r["civilians"] += int(pr.get("civ_killed", 0))
		r["officers"] += int(pr.get("officers_killed", 0))
		r["wounded"] += int(pr.get("officers_hurt", 0))
	if r["officers"] > 0 or r["civilians"] > 0:
		r["verdict"] = "ON THE RECORD"
	return r


## What is kept of a past situation (the full intel and plan are dropped).
static func _brief_record(s: Dictionary) -> Dictionary:
	var record := {"id": s["id"], "week": s["week"], "type": s["type"], "title": s["title"], "ward": s["ward"],
		"visibility": s["visibility"], "status": s["status"], "result": s.get("result", {}).duplicate(true)}
	# Preserve the actual place at the time of the call even if the city is edited later.
	for key in ["address", "site_id", "site_name", "site_archetype", "ward_id", "city_version", "city_x", "city_y"]:
		if s.has(key):
			record[key] = s[key]
	return record


# ================================================================== saving
func to_data() -> Dictionary:
	return {"version": VERSION, "seed": seed_val, "rng_state": str(rng.state), "department": dept.to_data(),
		"board": board.duplicate(true), "past": past.duplicate(true), "politics": politics.to_data(),
		"patrols": patrols.duplicate(true), "patrol_past": patrol_past.duplicate(true),
		"short_history": short_history.duplicate(true), "short_last_week": short_last_week,
		"run": run.to_data() if run != null else null}


func from_data(d: Dictionary) -> bool:
	var ver := _save_version(d)
	if ver < 1 or ver > VERSION:
		return false
	# Guard optional fields during boot. load_from also tries the backup when a
	# parsed primary fails the required department or version checks below.
	seed_val = int(d.get("seed", 1001))
	rng.seed = seed_val * 31 + 7
	rng.state = String(d.get("rng_state", "0")).to_int()
	dept = Department.new()
	if not dept.from_data(d.get("department", {}) if d.get("department", {}) is Dictionary else {}):
		return false
	board = []
	var raw_board: Array = d.get("board", []) if d.get("board", []) is Array else []
	for b0 in raw_board:
		if b0 is Dictionary:
			board.append(b0)
			_ints(b0)
	past = []
	var raw_past: Array = d.get("past", []) if d.get("past", []) is Array else []
	for p0 in raw_past:
		if p0 is Dictionary:
			past.append(p0)
			_ints(p0)
	patrols = []
	for e0 in (d.get("patrols", []) if d.get("patrols", []) is Array else []):
		if e0 is Dictionary:
			for k in ["week", "day", "seed", "ward_i", "choice"]:
				if e0.has(k):
					e0[k] = int(e0[k])
			patrols.append(e0)
	patrol_past = []
	for p1 in (d.get("patrol_past", []) if d.get("patrol_past", []) is Array else []):
		if p1 is Dictionary:
			patrol_past.append(p1)
	short_history = {}
	if d.get("short_history", {}) is Dictionary:
		short_history = d["short_history"].duplicate(true)
	short_last_week = int(d.get("short_last_week", -99))
	# version 1 (before v0.9) had no politics: the city starts from the wards' trust now
	politics = Politics.new()
	politics.from_data(d.get("politics", {}) if d.get("politics", {}) is Dictionary else {}, seed_val)
	# 1.3: version 3 and earlier, and classic campaigns, have no run layer
	run = null
	if d.get("run", null) is Dictionary:
		run = Rogue.new()
		run.from_data(d["run"], seed_val)
	activate()
	return true


## JSON keeps every number as a float: put back the ones that are integers.
## 4.72: guarded — board/past entries come from a file, and `int(null)` silently
## becomes 0 while `int("abc")` also becomes 0, so a junk value degrades instead
## of throwing mid-boot.
static func _ints(s: Dictionary) -> void:
	if not (s is Dictionary):
		return
	for k in ["week", "seed", "map", "ward_i", "trust", "visibility", "crowd", "duration", "attack_t", "deadline", "tip_count"]:
		if s.has(k):
			s[k] = int(s[k])


## A malformed version is not a supported save. Never replace a future-version
## primary with an older backup: a newer game may still be able to read it.
static func _save_version(d: Dictionary) -> int:
	var v = d.get("version", 0)
	if v is int or v is float:
		return int(v)
	if v is String and String(v).is_valid_int():
		return int(v)
	return 0


func save(path := SAVE_PATH) -> bool:
	var ok: bool = load("res://scripts/campaign/save_file.gd").write_json(path, to_data(), path == _recovered_path)
	if ok and path == _recovered_path:
		_recovered_path = ""
	return ok


static func load_from(path := SAVE_PATH):
	var saves = load("res://scripts/campaign/save_file.gd")
	for candidate in [path, path + ".bak"]:
		var d = saves.read_one_json(candidate)
		if d == null:
			continue
		if candidate == path and _save_version(d) > VERSION:
			return null
		var c = load("res://scripts/campaign/campaign.gd").new()
		if c.from_data(d):
			if candidate != path:
				c._recovered_path = path
			return c
	return null
