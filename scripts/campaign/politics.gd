extends RefCounted
## The city's politics (v0.9): what Port Carrick makes of its police, and the election
## that ends the campaign.
##
##   - Trust in police, ward by ward (0-100). It sets how many tips a ward's community
##     group gives, and it moves with what the department does there.
##   - Four allies, each holding something the department needs. Below 25 an ally is
##     lost and what they held goes with them; above 40 they can be won back.
##       council    the budget chair: the weekly allocation
##       union      the police union: the morale the department settles back to
##       coalition  the community coalition: community tips in every ward
##       da         the district attorney: whether a cleared case stays cleared
##   - Three candidates and their polling. The election is held at the end of week 40.
##   - Consequences that land later: a story about a civilian hit by police lands in a
##     week or two where people were watching, in months (or never) where they were not;
##     a lawsuit settles six to ten weeks on; a cleared case with video can leak.
##   - The press: three headlines a week on the board.
##
## Deterministic for the campaign seed: every roll comes from this object's rng, which is
## saved with the campaign.

const Situations = preload("res://scripts/campaign/situations.gd")

const LOST := 25
const REGAINED := 40
const ELECTION_WEEK := 40
## The one positive money decision (Q8): a city grant, for a chief the budget chair
## still answers the phone for. It costs some of her standing (a favour called in)
## and the committee will not be asked twice in a quarter.
const GRANT_AMOUNT := 10000
const GRANT_STANDING := 60
const GRANT_COOLDOWN := 8       # weeks between grants
const GRANT_FAVOUR := 5         # council standing spent asking
# EA_TASKS P1.D2/D4, declared 2026-11-02: these were referenced by the overdraft, sweep
# and surplus code but never written down, so the whole politics script failed to parse
# ("Identifier SURPLUS_COOLDOWN not declared") and every campaign run in CI came back with
# no record. The numbers are the ones the changelog and politics_test already describe.
const OVERDRAFT_STANDING_COST := 2   # budget-chair standing a week while the account is below $0
const FROZEN_STANDING_COST := 5      # and a week while it is below the overdraft limit
const SWEEP_EVERY := 4               # the committee's quarterly sweep, in weeks
const SWEEP_FLOOR := 25000           # nothing below this is swept
const SWEEP_SHARE := 0.5             # half of everything above the floor
const SWEEP_CAP := 30000             # but never more than this at once
const SURPLUS_AMOUNT := 5000         # surplus returned to the city by hand (P1.D4)
const SURPLUS_STANDING := 6          # what the budget chair thinks of it
const SURPLUS_COOLDOWN := 4          # weeks before it can be done again

const ALLIES := {
	"council": {"name": "Marguerite Duff", "title": "Councillor, chair of the budget committee", "start": 55,
		"holds": "the weekly allocation", "lost": "The budget committee cuts the department's allocation by 8%."},
	"union": {"name": "Tommy Rourke", "title": "President, Port Carrick Police Benevolent Association", "start": 60,
		"holds": "the officers' goodwill", "lost": "The union turns on you: department morale settles at 45 instead of 60."},
	"coalition": {"name": "Rev. Alma Mbeki-Shaw", "title": "Carrick Community Coalition", "start": 45,
		"holds": "the community groups' tips", "lost": "The coalition tells its groups to stop talking to you: no community tips in any ward."},
	"da": {"name": "Paul Varga", "title": "District Attorney", "start": 55,
		"holds": "the benefit of the doubt", "lost": "The DA's office reviews every case you clear: with evidence behind it, the officer is charged."},
}
const ALLY_ORDER := ["council", "union", "coalition", "da"]

const CANDIDATES := {
	"kettering": {"name": "Royce Kettering", "ticket": "Safe Streets", "start": 34,
		"blurb": "A councilman with an answer for every problem: more police, more money, fewer questions. His brother-in-law builds armoured vehicles; the contracts remain a family matter."},
	"okonjo": {"name": "Dana Okonjo-Vale", "ticket": "Carrick Together", "start": 31,
		"blurb": "A democratic socialist who intends to repair the city. She wants your signature on the Bridge Street order read aloud—and your name off the door."},
	"pell": {"name": "Gordon Pell", "ticket": "Independent", "start": 35,
		"blurb": "Competent, tireless and difficult to hurry. His answer to a failed review is another review, with a clearer filing system."},
}
const CAND_ORDER := ["kettering", "okonjo", "pell"]

var trust: Array = []          # per ward, 0-100
var allies := {}               # id -> {standing, lost}
var polls := {}                # candidate id -> score (shares are these normalised)
var pending: Array = []        # [{due, kind, ...}] consequences still to land
var press: Array = []          # [{week, head, body, kind}]
var record := {}               # running totals the press and the endings quote
var ended := false
var last_grant := -99          # week of the last city grant (Q8)
var last_surplus := -99        # week of the last surplus returned by hand (P1.D4)
var result := {}               # the election, once held
var rng := RandomNumberGenerator.new()
var cur_week := 1              # the week being processed, for the logs below
var ally_log: Array = []       # P1.E1: every ally standing change, with its cause
var poll_log: Array = []       # P1.F1: the poll moves that had a named cause


func start(seed_v: int) -> void:
	rng.seed = seed_v * 977 + 11
	trust = []
	for w in Situations.WARDS:
		trust.append(int(w["trust"]))
	allies = {}
	for a in ALLY_ORDER:
		allies[a] = {"standing": int(ALLIES[a]["start"]), "lost": false}
	polls = {}
	for c in CAND_ORDER:
		polls[c] = float(CANDIDATES[c]["start"])
	pending = []
	press = []
	ended = false
	result = {}
	record = {"civ_hit": 0, "civ_killed": 0, "excessive": 0, "officers_killed": 0, "suspects_killed": 0, "arrests": 0,
		"successes": 0, "failures": 0, "unattended": 0, "stories": 0, "settled": 0, "leaks": 0, "charged": 0,
		"dismissed": 0, "cleared": 0, "crowd_killed": 0, "grants": 0, "patrols": 0, "patrols_late": 0}
	_headline(1, "NEW CHIEF INHERITS BRIDGE STREET FILE", "The deputy chief signed the eviction order that cleared Bridge Street. The outgoing chief gave the briefing. The election is forty weeks away.", "city")


# ================================================================== reading it
func share(c: String) -> float:
	# An unknown id must read as 0, not a phantom candidate's share.
	if not CAND_ORDER.has(c):
		return 0.0
	var tot := 0.0
	for k in CAND_ORDER:
		tot += maxf(1.0, float(polls.get(k, 0.0)))
	return 100.0 * maxf(1.0, float(polls.get(c, 0.0))) / maxf(1.0, tot)


func leader() -> String:
	var best: String = CAND_ORDER[0]
	for c in CAND_ORDER:
		if share(c) > share(best):
			best = c
	return best


## An unknown ally id reads as the default rather than raising: callers include screens
## that walk the roster, and a save can be missing an ally (see from_data).
func _ally_rec(a: String) -> Dictionary:
	if not (allies.get(a) is Dictionary):
		var start_standing := int(ALLIES[a]["start"]) if ALLIES.has(a) else 50
		allies[a] = {"standing": start_standing, "lost": false}
	var al: Dictionary = allies[a]
	return al


## The name the player knows an ally by ("Tommy Rourke"), for the Ledger and the tests.
func ally_name(a: String) -> String:
	return String(ALLIES.get(a, {}).get("name", a))


func standing(a: String) -> int:
	return _int_of(_ally_rec(a).get("standing", 0))


func lost(a: String) -> bool:
	return bool(_ally_rec(a).get("lost", false))


func avg_trust() -> float:
	var t := 0.0
	for v in trust:
		t += float(v)
	return t / maxf(1.0, trust.size())


func week_press(week: int) -> Array:
	return press.filter(func(p): return p is Dictionary and _int_of(p.get("week", -1)) == week)


## EA_TASKS P1.F1: the poll moves of one week that had a named cause, as readable lines.
func week_causes(week: int) -> Array:
	var out: Array = []
	for e in ally_log:
		if e is Dictionary and _int_of(e.get("week", -1)) == week:
			out.append("%s %+d — %s" % [ally_name(String(e.get("ally", ""))),
				_int_of(e.get("delta", 0)), String(e.get("cause", ""))])
	for e in poll_log:
		if e is Dictionary and _int_of(e.get("week", -1)) == week:
			out.append("%s %+.1f — %s" % [String(CANDIDATES.get(String(e.get("cand", "")), {}).get("name", String(e.get("cand", "")))),
				_float_of(e.get("delta", 0.0)), String(e.get("cause", ""))])
	return out


# ================================================================== moving it
## EA_TASKS P1.E1: every ally standing change is logged with week, delta and cause
## (ally_log, saved with the campaign and dumped by the balance harness), and applied.
func _ally(a: String, d: int, dept, lines: Array, cause := "") -> void:
	var al: Dictionary = _ally_rec(a)
	al["standing"] = clampi(_int_of(al.get("standing", 0)) + d, 0, 100)
	ally_log.append({"week": cur_week, "ally": a, "delta": d, "standing": int(al["standing"]),
		"lost": bool(al.get("lost", false)), "cause": String(cause)})
	if ally_log.size() > 400:
		ally_log = ally_log.slice(ally_log.size() - 400)
	if not al["lost"] and int(al["standing"]) < LOST:
		al["lost"] = true
		lines.append("LOST: %s (%s). %s" % [ALLIES[a]["name"], ALLIES[a]["title"], ALLIES[a]["lost"]])
		_on_lost(a, dept, true)
		_headline(-1, _lost_head(a), ALLIES[a]["lost"], "politics")
	elif al["lost"] and int(al["standing"]) > REGAINED:
		al["lost"] = false
		lines.append("Won back: %s (%s)." % [ALLIES[a]["name"], ALLIES[a]["title"]])
		_on_lost(a, dept, false)


func _lost_head(a: String) -> String:
	match a:
		"council":
			return "BUDGET CHAIR: 'WE ARE DONE WRITING BLANK CHEQUES'"
		"union":
			return "UNION BREAKS WITH CHIEF: 'HE HAS LOST THE ROOM'"
		"coalition":
			return "COALITION TELLS MEMBERS: STOP TALKING TO POLICE"
	return "DA'S OFFICE TO REVIEW EVERY POLICE CASE CLOSED WITHOUT CHARGES"


## What an ally's loss (or return) does to the department.
func _on_lost(a: String, dept, is_lost: bool) -> void:
	if dept == null:
		return
	match a:
		"council":
			if is_lost:
				dept.allocation = int(round(dept.allocation * 0.92 / 100.0)) * 100
			else:
				dept.allocation = int(round(dept.allocation / 0.92 / 100.0)) * 100
			dept.note("Allocation now $%s a week." % dept.money(dept.allocation))
		"union":
			dept.morale_home = 45 if is_lost else 60


func _trust(ward_i: int, d: int) -> void:
	if ward_i >= 0 and ward_i < trust.size():
		trust[ward_i] = clampi(int(trust[ward_i]) + d, 0, 100)


## EA_TASKS P1.F1: a poll move with a named cause is logged (week, candidate, delta,
## cause) and shown on the Ledger's week page; a move without one is the background drift
## and stays out of the log. Declared 2026-11-02: ten call sites passed the cause but the
## function took two arguments, which is a parse error and took the whole script with it.
func _poll(c: String, d: float, cause := "") -> void:
	polls[c] = clampf(_float_of(polls.get(c, 0.0)) + d, 3.0, 200.0)
	if cause != "":
		poll_log.append({"week": cur_week, "cand": c, "delta": d, "poll": polls[c], "cause": cause})
		if poll_log.size() > 400:
			poll_log = poll_log.slice(poll_log.size() - 400)


func _headline(week: int, head: String, body: String, kind: String) -> void:
	press.append({"week": week, "head": head, "body": body, "kind": kind})
	if press.size() > 300:
		press = press.slice(press.size() - 300)


## Whether the budget committee can be asked for a grant this week (Q8): "" if it
## can, else why not, in words the budget screen can show.
func can_grant(week: int) -> String:
	if lost("council"):
		return "Marguerite Duff is lost: the committee will not take the application"
	if standing("council") < GRANT_STANDING:
		return "needs the budget chair at %d standing or better (now %d)" % [GRANT_STANDING, standing("council")]
	if week - last_grant < GRANT_COOLDOWN:
		return "the committee approved one in week %d; week %d at the earliest" % [last_grant, last_grant + GRANT_COOLDOWN]
	return ""


## Ask, and be given: $GRANT_AMOUNT into the account, the favour spent. Returns
## {ok, line} — the line reads the same in the budget screen and the department log.
func apply_grant(week: int, dept) -> Dictionary:
	cur_week = week
	var why := can_grant(week)
	if why != "" or dept == null:
		return {"ok": false, "line": "No grant: " + (why if why != "" else "no department") + "."}
	dept.income("City grant (budget committee)", GRANT_AMOUNT)
	last_grant = week
	record["grants"] = int(record.get("grants", 0)) + 1
	var lines: Array = []
	_ally("council", -GRANT_FAVOUR, dept, lines, "asking for a city grant")
	_headline(week, "CITY GRANT KEEPS PORT CARRICK PD SOLVENT", "Duff (budget chair): 'One-time money. Do not make a habit of needing it.'", "money")
	var line := "The budget committee awards the department a $%s grant. Duff's goodwill is spent asking (%d)." % [dept.money(GRANT_AMOUNT), standing("council")]
	dept.note(line)
	return {"ok": true, "line": line}


## EA_TASKS P1.D4: return surplus to the council by hand — a player lever that buys the
## budget chair's standing, alongside the committee's automatic quarterly sweep.
func can_surplus(week: int) -> String:
	if lost("council"):
		return "Marguerite Duff is lost: the committee will not take it back"
	if week - last_surplus < SURPLUS_COOLDOWN:
		return "the committee took a return in week %d; week %d at the earliest" % [last_surplus, last_surplus + SURPLUS_COOLDOWN]
	return ""


func apply_surplus(week: int, dept) -> Dictionary:
	cur_week = week
	var why := can_surplus(week)
	if why != "" or dept == null or dept.balance < SURPLUS_AMOUNT:
		return {"ok": false, "line": "No surplus returned: " + (why if why != "" else "the account cannot spare $%s" % dept.money(SURPLUS_AMOUNT)) + "."}
	dept.spend("Surplus returned to the city", SURPLUS_AMOUNT)
	last_surplus = week
	record["surplus"] = int(record.get("surplus", 0)) + 1
	var lines: Array = []
	_ally("council", SURPLUS_STANDING, dept, lines, "surplus returned to the city")
	var line := "$%s of surplus goes back to the city; the budget chair notes it (%d standing)." % [dept.money(SURPLUS_AMOUNT), standing("council")]
	dept.note(line)
	return {"ok": true, "line": line}


## A story lands: weeks after for low visibility (sometimes never), soon for high, and
## on the next front page when there is video.
func _story_delay(vis: int, strength: String) -> int:
	if strength == "video" or vis >= 4:
		return 0
	if vis >= 3 or strength == "witness":
		return rng.randi_range(1, 2)
	return rng.randi_range(3, 9)


# ================================================================== after an operation
## Everything an operation set in motion. sit is the situation, res the outcome, w the
## world (its incident record). Returns readable lines for the debrief.
func on_operation(week: int, sit: Dictionary, res: Dictionary, w, dept) -> Array:
	var lines: Array = []
	cur_week = week
	var vis: int = int(sit.get("visibility", 1))
	var wi: int = int(sit.get("ward_i", -1))
	var s: Dictionary = w.incident.summary() if w.incident != null else {}
	var police := {}
	for o in w.ops:
		if o.judges:
			police[o.id] = true
	var civ_hit := 0
	var civ_hit_ids := {}          # 1.3: a civilian struck by three police rounds is one civilian hit
	var civ_killed := 0
	var excessive := 0
	var best := "none"
	var order := ["video", "witness", "heard", "none"]
	for f in (w.incident.findings if w.incident != null else []):
		var by_police: bool = police.has(String(f.get("by", "")))
		match f["kind"]:
			"civilian_hit_by_police":
				var tid := String(f.get("target", ""))
				if tid == "" or not civ_hit_ids.has(tid):
					civ_hit += 1
				civ_hit_ids[tid] = true
			"civilian_killed":
				if by_police:
					civ_killed += 1
			"excessive_force":
				excessive += 1
			_:
				continue
		if order.find(String(f["strength"])) < order.find(best):
			best = String(f["strength"])
	var off_killed: int = int(s.get("officers_killed", 0))
	var sus_killed: int = int(s.get("suspects_killed", 0))
	var crowd_killed := 0
	if sit.get("type", "") == "event":
		crowd_killed = int(res.get("civ_killed", 0))
	record["civ_hit"] += civ_hit
	record["civ_killed"] += civ_killed
	record["excessive"] += excessive
	record["officers_killed"] += off_killed
	record["suspects_killed"] += sus_killed
	record["arrests"] += int(s.get("arrested", 0))
	record["crowd_killed"] += crowd_killed
	var kind: String = res.get("kind", "failure")
	var where: String = sit.get("ward", "the city")
	var what: String = Situations.TYPES.get(sit.get("type", ""), {}).get("name", "operation").to_lower()
	# the result: a clean success reassures, a failure is the law-and-order ticket's gift
	var clean: bool = civ_hit == 0 and civ_killed == 0 and excessive == 0 and off_killed == 0
	match kind:
		"success", "quiet":
			record["successes"] += 1
			if clean:
				_trust(wi, 1 + vis / 2)
				_poll("pell", 0.4 + 0.3 * vis)
				_ally("council", 1, dept, lines)
		"failure":
			record["failures"] += 1
			_poll("kettering", 0.4 + 0.3 * vis)
			_poll("pell", -0.2 * vis)
			_trust(wi, -1 - vis / 2)
			if vis >= 3:
				_headline(week, "POLICE OPERATION IN %s ENDS IN FAILURE" % where.to_upper(), "The %s at %s did not go to plan. Kettering: 'The officers did their job. The chief made them wait.'" % [what, sit.get("address", "")], "op")
	# officers killed: the union blames management, the law-and-order ticket blames everyone else
	if off_killed > 0:
		_ally("union", -4 * off_killed, dept, lines)
		_ally("council", -2 * off_killed, dept, lines)
		# EA_TASKS P1.F1: the record moves the race — dead officers are the law-and-order gift
		_poll("kettering", 2.0 * off_killed, "%d officer%s killed in %s" % [off_killed, "" if off_killed == 1 else "s", where])
		_headline(week, "%s OFFICER%s KILLED IN %s" % [_num(off_killed), "" if off_killed == 1 else "S", where.to_upper()],
			"The department lowers its flags. Rourke (union): 'Somebody sent them in there.'", "op")
	if sus_killed > 0 and vis >= 2:
		_poll("okonjo", 0.4 * sus_killed * vis, "%d suspect%s killed in %s" % [sus_killed, "" if sus_killed == 1 else "s", where])
		_trust(wi, -sus_killed)
	# a rally that turned to killing is the city's front page whatever happened next
	if crowd_killed > 0:
		_ally("council", -8, dept, lines, "%d killed at %s" % [crowd_killed, sit.get("site_name", "a public event")])
		_ally("coalition", -6, dept, lines, "%d killed at %s" % [crowd_killed, sit.get("site_name", "a public event")])
		_poll("okonjo", 3.0 * crowd_killed, "%d killed at %s" % [crowd_killed, sit.get("site_name", "a public event")])
		_poll("kettering", 2.0 * crowd_killed, "%d killed at %s" % [crowd_killed, sit.get("site_name", "a public event")])
		_poll("pell", -3.0, "%d killed at %s" % [crowd_killed, sit.get("site_name", "a public event")])
		_trust(wi, -8)
		var place := String(sit.get("site_name", "public event")).to_upper()
		_headline(week, "%s KILLED AT %s" % [_num(crowd_killed).to_upper(), place], "The rally was over before the ambulances left. Pell calls for a review; Okonjo-Vale asks who signed the plan.", "op")
	# what was done to civilians by police: the story is coming, sooner or later
	if civ_hit + civ_killed + excessive > 0:
		var p_never := 0.0
		if vis <= 1 and best in ["none", "heard"]:
			p_never = 0.5
		elif vis <= 2 and best == "none":
			p_never = 0.3
		if rng.randf() >= p_never:
			var due: int = week + _story_delay(vis, best)
			pending.append({"due": due, "kind": "story", "ward": where, "ward_i": wi, "vis": vis, "strength": best,
				"hit": civ_hit, "killed": civ_killed, "excessive": excessive, "what": what, "address": sit.get("address", ""), "op_week": week})
			lines.append("The press will hear of this.%s" % (" There is video." if best == "video" else ""))
		else:
			lines.append("Nobody was watching. For now, it stays quiet.")
		# a lawsuit follows anyone hit, whether or not the papers do
		if civ_hit + civ_killed > 0:
			var cost: int = 10000 * maxi(0, civ_hit - civ_killed) + 40000 * civ_killed
			# EA_TASKS P1.D3: it settles in four weekly instalments, not one hit
			var d0: int = week + rng.randi_range(6, 10)
			var share: int = int(ceil(cost / 4.0))
			var inst: Array = []
			for k in 4:
				var amt: int = share if k < 3 else cost - 3 * share
				inst.append({"week": d0 + k, "amount": amt, "paid": false})
			pending.append({"due": d0, "kind": "lawsuit", "cost": cost, "ward": where, "op_week": week, "instalments": inst})
			lines.append("A lawsuit is being filed; it will settle in four weekly instalments from week %d." % d0)
	return lines


static func _n(n: int, one: String, many := "") -> String:
	return "%d %s" % [n, one if n == 1 else (many if many != "" else one + "s")]


static func _num(n: int) -> String:
	var words := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
	return words[n].to_upper() if n < words.size() else str(n)


# ================================================================== internal affairs
## Q3: how likely a cleared serious case is to leak. The evidence sets the base (as
## before: 55% with video, 25% with witnesses); the named officer's integrity scales
## it (a reputation for straight paperwork keeps a closed file closed, and the
## reverse is also true), and a statement contradicted by the evidence is exactly
## the kind of detail somebody takes to a reporter.
static func leak_p(strength: String, integrity: int, statement := "untested") -> float:
	var p: float = 0.55 if strength == "video" else 0.25
	p *= clampf(1.6 - float(integrity) / 100.0, 0.5, 1.5)
	match statement:
		"disagrees":
			p *= 1.3
		"matches":
			p *= 0.8
	return clampf(p, 0.02, 0.9)


## A case was decided (Department.decide). The union watches the discipline, the
## coalition watches the cases, and the DA watches what is cleared.
func on_decision(week: int, c: Dictionary, decision: String, dept) -> Array:
	var lines: Array = []
	cur_week = week
	var strong: bool = String(c.get("strength", "none")) in ["video", "witness"]
	var serious: bool = String(c.get("kind", "")) in ["civilian_hit_by_police", "excessive_force"]
	var cause := "an internal-affairs decision (%s on %s)" % [decision, String(c.get("id", ""))]
	match decision:
		"clear":
			record["cleared"] += 1
			_ally("union", 2, dept, lines, cause)
			if serious and strong:
				# what the file says about the officer's own account (Q3)
				var integ: int = int(c.get("integrity", 60))
				if dept != null:
					var rec: Dictionary = dept.get_officer(c["officer"])
					if not rec.is_empty():
						integ = int(rec.get("integrity", integ))
				var stmt: String = String(c.get("statement", "untested"))
				if lost("da"):
					# the DA's office reviews it and charges the officer
					var r: Dictionary = dept.get_officer(c["officer"])
					if not r.is_empty() and r["status"] not in ["dead", "fired", "resigned"]:
						r["status"] = "suspended"
						r["out_until"] = maxi(int(r["out_until"]), dept.week + 6)
						r["file"].append({"week": dept.week, "text": "Charged by the DA's office over %s; suspended until week %d." % [c["id"], r["out_until"]]})
						dept.shift_morale(-4)
						record["charged"] += 1
						lines.append("The DA's office has charged %s %s over %s." % [r["rank"], r["name"], c["id"]])
						_headline(week, "DA CHARGES OFFICER THE CHIEF CLEARED", "%s %s is suspended pending trial. Varga: 'Somebody has to read the files.'" % [r["rank"], r["name"]], "case")
				elif rng.randf() < leak_p(String(c["strength"]), integ, stmt):
					pending.append({"due": week + rng.randi_range(1, 4), "kind": "leak", "case": c["id"], "officer": c["officer"],
						"strength": c["strength"], "text": c.get("text", "")})
				# clearing a man whose statement matched the record reads as honest
				# process; clearing one it contradicted reads as a cover-up
				_ally("da", {"disagrees": -6, "matches": -2}.get(stmt, -4), dept, lines)
				_ally("coalition", {"disagrees": -5, "matches": -1}.get(stmt, -3), dept, lines)
		"retrain":
			_ally("union", -1, dept, lines)
			_ally("coalition", 1, dept, lines)
		"suspend":
			_ally("union", -3, dept, lines)
			_ally("coalition", 2, dept, lines)
			_ally("da", 1, dept, lines)
		"fire":
			record["dismissed"] += 1
			_ally("union", -8, dept, lines)
			_ally("coalition", 3 if serious else 1, dept, lines)
			_ally("da", 2, dept, lines)
			_poll("okonjo", -0.5)
			_poll("pell", 0.3)
			if serious:
				_headline(week, "CHIEF DISMISSES OFFICER AFTER INTERNAL INQUIRY", "Rourke: 'A witch hunt.' Mbeki-Shaw: 'A start.'", "case")
	return lines


# ================================================================== the week ends
## Unattended situations, the budget, consequences coming due, the polls drifting, the
## council's quarterly review, and this week's front page. Returns readable lines.
## A patrol encounter resolved on the desk (Patrol, 2026-11-05): the ward's trust, and
## what a killed officer or a civilian hurt while police waited does to the race. An armed
## one that went to the sim is scored by on_operation instead.
func on_patrol(week: int, e: Dictionary, res: Dictionary, dept) -> Array:
	var lines: Array = []
	cur_week = week
	var wi: int = int(e.get("ward_i", -1))
	var where: String = String(e.get("ward", "the city"))
	record["patrols"] = int(record.get("patrols", 0)) + 1
	record["arrests"] += int(res.get("arrests", 0))
	_trust(wi, int(res.get("trust", 0)))
	if bool(res.get("late", false)):
		record["patrols_late"] = int(record.get("patrols_late", 0)) + 1
	var off_killed: int = int(res.get("officers_killed", 0))
	if off_killed > 0:
		record["officers_killed"] += off_killed
		_ally("union", -4 * off_killed, dept, lines, "an officer killed on patrol in %s" % where)
		_ally("council", -2 * off_killed, dept, lines, "an officer killed on patrol in %s" % where)
		_poll("kettering", 2.0 * off_killed, "an officer killed on patrol in %s" % where)
		_headline(week, "OFFICER KILLED ON PATROL IN %s" % where.to_upper(),
			"A routine call, the radio says. Rourke (union): 'There is no such thing.'", "op")
	var hurt_c: int = int(res.get("civ_hurt", 0)) + int(res.get("civ_killed", 0))
	if hurt_c > 0 and bool(res.get("late", false)):
		var why := "police waited at a %s in %s" % [String(e.get("kind", "call")).replace("_", " "), where]
		_ally("coalition", -1, dept, lines, why)
		_poll("kettering", 0.4, why)
		if int(res.get("civ_killed", 0)) > 0:
			_headline(week, "POLICE WAITED; A RESIDENT OF %s DIED" % where.to_upper(),
				"The car was on the corner, the family says. The department says it was waiting for backup.", "op")
	return lines


func week_end(week: int, board: Array, dept) -> Array:
	var lines: Array = []
	cur_week = week
	# EA_TASKS P1.E3: where every ally stood when the week began, so "a quiet week" can
	# mean the week moved nobody (this snapshot was referenced as `before` but never taken,
	# which is a parse error: found in CI 2026-11-02, see tools/gd_arity_check.py).
	var before: Dictionary = {}
	for a in ALLY_ORDER:
		before[a] = standing(a)
	# what nobody went to
	for s in board:
		if s["status"] != "unattended" or s.get("truce", false):   # 1.3: a truce is not neglect
			continue
		record["unattended"] += 1
		var wi: int = int(s["ward_i"])
		# v0.9.1: a quiet warrant left for next week barely registers; a crew house or a
		# hostage taking left alone, or anything people were watching, does
		_trust(wi, -2 if int(s["visibility"]) >= 3 else -1)
			# EA_TASKS P1.F1: neglect moves the race, and the Ledger says why
		var why := "nobody answered the %s at %s" % [String(s["type"]), String(s.get("address", s["ward"]))]
		_poll("kettering", 0.3 * int(s["visibility"]) + (0.5 if s["type"] in ["gang", "hostage"] else 0.0), why)
		if int(s["visibility"]) >= 3:
			_poll("pell", -0.2, why)
		if (s["type"] in ["gang", "hostage"] and int(s["visibility"]) >= 2) or int(s["visibility"]) >= 4:
			pending.append({"due": week + rng.randi_range(1, 3), "kind": "neglect", "ward": s["ward"], "ward_i": wi,
				"type": s["type"], "address": s.get("address", ""), "vis": int(s["visibility"])})
	# the budget committee watches the account. EA_TASKS P1.D2: below zero is the council's
	# overdraft (it costs standing, not a freeze); below the limit it freezes.
	var limit: int = int(dept.OVERDRAFT_LIMIT) if dept != null else -25000
	if dept != null and dept.balance < limit:
		_ally("council", -FROZEN_STANDING_COST, dept, lines, "the account below the overdraft limit ($%s)" % dept.money(dept.balance))
		_poll("pell", -0.4, "the account frozen at $%s" % dept.money(dept.balance))
	elif dept != null and dept.balance < 0:
		_ally("council", -OVERDRAFT_STANDING_COST, dept, lines, "the account in overdraft ($%s of $%s)" % [dept.money(dept.balance), dept.money(-limit)])
		_poll("pell", -0.2, "the account in overdraft ($%s)" % dept.money(dept.balance))
	elif dept != null and dept.deficit_weeks == 0 and week % 4 == 0:
		_ally("council", 2, dept, lines, "a balanced book at the quarterly check")
	# a demoralised force talks to its union
	if dept.morale < 40:
		_ally("union", -2, dept, lines, "morale at %d" % int(dept.morale))
	# consequences coming due. EA_TASKS P1.D3: a lawsuit with instalments pays one per
	# week and stays on the books until the last one; only then does it "settle".
	var keep: Array = []
	for p in pending:
		if int(p["due"]) > week:
			keep.append(p)
			continue
		if p.get("kind", "") == "lawsuit" and p.get("instalments", null) is Array:
			var insts: Array = p["instalments"]
			for inst in insts:
				if inst is Dictionary and not bool(inst.get("paid", false)) and int(inst.get("week", -1)) <= week:
					dept.spend("Settlement of $%s (instalment %d of %d, lawsuit from week %d)" % [dept.money(int(inst["amount"])),
						insts.find(inst) + 1, insts.size(), int(p.get("op_week", week))], int(inst["amount"]))
					_ally("council", -3, dept, lines, "a lawsuit instalment ($%s)" % dept.money(int(inst["amount"])))
					inst["paid"] = true
					lines.append("Instalment of the lawsuit from week %d: $%s paid." % [int(p.get("op_week", week)), dept.money(int(inst["amount"]))])
					break   # one instalment a week, as filed
			var all_paid := true
			for inst2 in insts:
				if inst2 is Dictionary and not bool(inst2.get("paid", false)):
					all_paid = false
			if all_paid:
				record["settled"] = int(record.get("settled", 0)) + 1
				lines.append("The lawsuit from week %d is fully settled: $%s over four weeks." % [int(p.get("op_week", week)), dept.money(int(p.get("cost", 0)))])
				if int(p.get("cost", 0)) >= 40000:
					_headline(week, "CITY PAYS $%s OVER POLICE SHOOTING" % dept.money(int(p.get("cost", 0))), "Duff (budget chair): 'That is a school roof.'", "money")
			else:
				keep.append(p)
			continue
		lines.append_array(_land(week, p, dept))
	pending = keep
	# the council's quarterly review of the allocation
	if week % 8 == 0 and not lost("council"):
		if standing("council") >= 70:
			dept.allocation = int(round(dept.allocation * 1.04 / 100.0)) * 100
			lines.append("Quarterly review: the budget committee raises the allocation to $%s a week." % dept.money(dept.allocation))
		elif standing("council") < 45:
			dept.allocation = int(round(dept.allocation * 0.97 / 100.0)) * 100
			lines.append("Quarterly review: the budget committee trims the allocation to $%s a week." % dept.money(dept.allocation))
	# EA_TASKS P1.D4: the committee sweeps unspent surplus, so a run that signs nothing does
	# not end with a six-figure account. Late-game sinks are the honest way to spend it.
	if dept != null and week % SWEEP_EVERY == 0 and not lost("council") and dept.balance > SWEEP_FLOOR:
		var sweep: int = mini(SWEEP_CAP, int(round((dept.balance - SWEEP_FLOOR) * SWEEP_SHARE / 100.0)) * 100)
		if sweep > 0:
			dept.spend("Council sweeps $%s of unspent surplus into the city reserve" % dept.money(sweep), sweep)
			_ally("council", 2, dept, lines, "a balanced book ($%s swept)" % dept.money(sweep))
			lines.append("The budget committee sweeps $%s of unspent surplus into the city reserve." % dept.money(sweep))
	# a balanced book is Pell's whole platform
	if dept.balance >= 0:
		_poll("pell", 0.3, "a balanced book")
	# EA_TASKS P1.E3: an ally nobody has had word against this week holds its standing —
	# being out of sight never drifts an ally down by itself.
	for a in ALLY_ORDER:
		if not lost(a) and standing(a) == int(before[a]) and standing(a) < 100:
			_ally(a, 1, dept, lines, "a quiet week")
	# the polls drift a little on their own, and a little back towards where the city
	# started (v0.9.1: no lead runs away on momentum alone); the trailing campaigns try harder
	for c in CAND_ORDER:
		_poll(c, rng.randfn(0.0, 0.7) + (0.25 if c != leader() else -0.15) + 0.04 * (float(CANDIDATES[c]["start"]) - float(polls[c])))
	_front_page(week)
	if week >= ELECTION_WEEK and not ended:
		lines.append_array(hold_election(dept))
	return lines


## A consequence lands.
func _land(week: int, p: Dictionary, dept) -> Array:
	var lines: Array = []
	match p["kind"]:
		"story":
			record["stories"] += 1
			var n_hurt: int = int(p["hit"]) - int(p["killed"])
			var weight: float = (float(p["vis"]) / 3.0) * (1.5 if p["strength"] == "video" else 1.0)
			var harm: int = int(p["hit"]) + 3 * int(p["killed"]) + int(p["excessive"])
			_trust(int(p["ward_i"]), -int(round(4.0 * harm * weight)))
			_ally("coalition", -int(round(4.0 * harm * weight)), dept, lines)
			_ally("council", -int(round(1.5 * harm * weight)), dept, lines)
			_ally("da", -int(round(1.0 * harm * weight)), dept, lines)
			_poll("okonjo", 1.0 * harm * weight)
			_poll("pell", 0.2 * harm * weight)
			var head := ""
			if int(p["killed"]) > 0:
				head = "%s KILLED BY POLICE FIRE IN %s" % [_num(int(p["killed"])), String(p["ward"]).to_upper()]
			elif n_hurt > 0:
				head = "BYSTANDER%s SHOT DURING POLICE %s" % ["S" if n_hurt > 1 else "", String(p["what"]).to_upper()]
			else:
				head = "WITNESSES DESCRIBE EXCESSIVE FORCE AT %s" % String(p["address"]).to_upper()
			var late: int = week - int(p["op_week"])
			var source := ""
			match String(p["strength"]):
				"video":
					source = "Video of the operation at %s is circulating. " % String(p["address"])
				"witness":
					source = "Witnesses from %s describe the operation at %s. " % [String(p["ward"]), String(p["address"])]
				"heard":
					source = "Residents near %s describe what they heard. " % String(p["address"])
				_:
					source = "The department's log records the finding at %s. " % String(p["address"])
			var age := ("The operation was %d weeks ago. " % late) if late >= 3 else ""
			var body := "%s%sOkonjo-Vale: 'A report is not the same thing as an answer.'" % [source, age]
			_headline(week, head, body, "story")
			lines.append("In the papers: %s." % head.capitalize())
		"lawsuit":
			record["settled"] += 1
			var cost: int = int(p["cost"])
			dept.spend("Settlement (%s, week %d)" % [p["ward"], int(p["op_week"])], cost)
			_ally("council", -3, dept, lines)
			lines.append("The city settles a lawsuit from week %d: $%s, out of the department's account." % [int(p["op_week"]), dept.money(cost)])
			if cost >= 40000:
				_headline(week, "CITY PAYS $%s OVER POLICE SHOOTING" % dept.money(cost), "Duff (budget chair): 'That is a school roof.'", "money")
		"leak":
			record["leaks"] += 1
			_ally("coalition", -6, dept, lines)
			_ally("da", -5, dept, lines)
			_poll("okonjo", 1.5)
			var r: Dictionary = dept.get_officer(p["officer"])
			var who: String = ("%s %s" % [r.get("rank", ""), r.get("name", "")]).strip_edges()
			_headline(week, "LEAKED: THE CASE THE CHIEF CLEARED", "%s documents show %s %s. The department called it closed." % [
				"Body camera footage and internal" if p["strength"] == "video" else "Internal", who, String(p["text"])], "case")
			lines.append("Leaked: internal affairs case %s, which you cleared." % p["case"])
		"neglect":
			cur_week = week
			_trust(int(p["ward_i"]), -3)
			_ally("coalition", -2, dept, lines, "a no-show at %s" % String(p.get("address", "")))
			_poll("kettering", 0.6, "a no-show at %s" % String(p.get("address", "")))
			var head2: String = {"gang": "SHOTS FIRED NEAR %s; RESIDENTS SAY POLICE NEVER CAME", "hostage": "FAMILY HELD FOR HOURS AT %s; 'WHERE WERE THE POLICE?'"}.get(
				p["type"], "%s: POLICE A NO-SHOW") % String(p["address"]).to_upper()
			_headline(week, head2, "Kettering: 'Under my administration, the police will come when you call.' He did not say how.", "story")
	return lines


## Three headlines for the week: what landed, then the campaign, then the city.
func _front_page(week: int) -> void:
	var have: int = week_press(week).size()
	# fix up stories filed with week -1 (an ally lost mid-week)
	for p in press:
		if int(p["week"]) == -1:
			p["week"] = week
			have += 1
	if have < 3:
		var ld := leader()
		var sh := share(ld)
		var lines_c := {
			"kettering": ["KETTERING: 'I WILL GIVE THE POLICE WHATEVER THEY ASK FOR'", "%s%% back Kettering's Safe Streets ticket. His brother-in-law's armoured vehicle firm did not return the Ledger's call." % int(sh)],
			"okonjo": ["OKONJO-VALE LEADS: 'THE CHIEF WILL BE MY FIRST APPOINTMENT TO LEAVE'", "%s%% back Carrick Together. Asked about Bridge Street, she held up the signed order. 'He knows.'" % int(sh)],
			"pell": ["PELL UNVEILS 212-PAGE PLAN TO STREAMLINE CITY PAPERWORK", "%s%% back the independent. The plan includes a form for requesting a review of the plan." % int(sh)],
		}
		_headline(week, lines_c[ld][0], lines_c[ld][1], "politics")
		have += 1
	var filler := [
		["UNIONTOWN AVENUE REPAIR CREW RETURNS TO THE SAME POTHOLE", "One lane is closed. The city says a steel plate will arrive Thursday."],
		["IRONWORKS PLANT CLOSURE: 300 SHIFTS CUT", "Workers left through the east gate with their lockers in boxes."],
		["FERRY STREET LIFT BRIDGE INSPECTION DELAYED AGAIN", "The weight limit remains in force. The detour adds twenty minutes."],
		["CITY HALL ELEVATOR STUCK; PELL TAKES THE STAIRS", "His office logged the climb as a facilities issue."],
		["CARRICK LEDGER CUTS FOUR REPORTERS", "The city desk will cover council and courts with one fewer person."],
		["NORTHGATE BAKERY WINS REGIONAL PRIZE FOR RYE", "The owner says the ovens are older than the lease."],
		["WATER MAIN BURSTS UNDER FOUNDRY ROAD", "Crews have closed the block. Repairs may run into next week."],
		["SCHOOL BOARD VOTES TO MERGE TWO MORE SCHOOLS", "Families ask which bus will take their children to the new site."],
	]
	while have < 3:
		var f: Array = filler[(week * 3 + have) % filler.size()]
		_headline(week, f[0], f[1], "city")
		have += 1


# ================================================================== the election
func hold_election(dept) -> Array:
	ended = true
	# election-day turnout: a little noise on the final poll
	var final := {}
	for c in CAND_ORDER:
		final[c] = share(c) + rng.randfn(0.0, 2.0)
	var tot := 0.0
	for c in CAND_ORDER:
		final[c] = maxf(1.0, final[c])
		tot += final[c]
	var win: String = CAND_ORDER[0]
	for c in CAND_ORDER:
		final[c] = 100.0 * final[c] / tot
		if final[c] > final[win]:
			win = c
	result = {"winner": win, "votes": final}
	var e := ending(dept)
	result["ending"] = e
	_headline(ELECTION_WEEK, "%s WINS" % String(CANDIDATES[win]["name"]).to_upper(), e["head"], "politics")
	return ["Election day. %s wins with %d%%." % [CANDIDATES[win]["name"], int(round(final[win]))], e["head"]]


## How it ends for you: who won, and what your record lets them do.
func ending(dept) -> Dictionary:
	var win: String = result.get("winner", leader())
	var force: int = int(record["civ_hit"]) + 3 * int(record["civ_killed"]) + int(record["excessive"])
	var t := avg_trust()
	var keep := false
	var head := ""
	var lines: Array = []
	match win:
		"kettering":
			keep = true
			head = "Kettering keeps you. The equipment budget doubles."
			lines.append("On his first morning, the new mayor signs the equipment increase. The first contract goes to a firm owned by his brother-in-law.")
			if force >= 6:
				lines.append("He points to your force record as proof the city needs fewer limits. The coalition's lawyer files a federal complaint before the budget meeting ends.")
			else:
				lines.append("He asks you to be more visible. The podium is set beside the flag; the list of neighbourhoods is on your chair.")
			if lost("da"):
				lines.append("Varga's office keeps charging officers. Kettering keeps pardoning them. Both offices keep the files.")
		"okonjo":
			keep = t >= 60.0 and not lost("coalition") and force <= 2
			if keep:
				head = "Okonjo-Vale keeps you—for ninety days, in writing."
				lines.append("At the swearing-in, she places the Bridge Street order beside your appointment letter. 'Your signature is here,' she says. 'The next one has to mean something.'")
				lines.append("The coalition calls the appointment a test. Rourke calls it probation. The oversight board receives its first file before the office opens.")
			else:
				head = "Okonjo-Vale fires you on her first morning."
				lines.append("She reads the Bridge Street order into the record, then your force record: %d civilians hit by police, %d killed. The old signature and the new numbers share a page." % [int(record["civ_hit"]), int(record["civ_killed"])])
				lines.append("The department goes under civilian oversight. Its first request is every file you ever closed.")
		"pell":
			keep = dept.balance >= 0 and dept.deficit_weeks <= 4
			if keep:
				head = "Pell keeps you, subject to review."
				lines.append("His first order is a review of the Bridge Street file. Yours is scheduled for the third quarter of the year after next. The account balances; for now, so does your desk.")
			else:
				head = "Pell reviews your position out of existence."
				lines.append("After %d weeks in deficit, the chief's office is folded into Municipal Services, Sub-Division C. Your desk is reassigned to parking enforcement; the line item is already approved." % int(dept.deficit_weeks))
	# `_n()` already carries the noun ("7 stories"), so the sentence must not add it
	# again — the first engine run of a 40-week campaign printed "7 stories stories".
	lines.append("Forty weeks: %s succeeded, %d failed, %s went unattended. %s killed. %s reached the papers; %s settled; %s leaked." % [
		_n(int(record["successes"]), "operation"), int(record["failures"]), _n(int(record["unattended"]), "situation"),
		_n(int(record["officers_killed"]), "officer"), _n(int(record["stories"]), "story", "stories"),
		_n(int(record["settled"]), "lawsuit"), _n(int(record["leaks"]), "case")])
	## EA_TASKS P1.F3: election night shows the score breakdown.
	lines.append("FILED. NOT RESOLVED.")
	# P1.F3's breakdown is a set of rows in the election screen (ops_ui `_election_night`);
	# what the ending says in words is the count itself. This used to be a string + int
	# concatenation ("SCORE BREAKDOWN: Kettering=" + int(...)), which does not parse: it was
	# the last of the faults that kept the campaign from compiling (CI 2026-11-02).
	lines.append("The count: Kettering %d%%, Okonjo-Vale %d%%, Pell %d%%." % [
		int(result["votes"]["kettering"]), int(result["votes"]["okonjo"]), int(result["votes"]["pell"])])
	return {"winner": win, "keep": keep, "head": head, "lines": lines}


# ================================================================== saving
func to_data() -> Dictionary:
	return {"trust": trust.duplicate(), "allies": allies.duplicate(true), "polls": polls.duplicate(), "pending": pending.duplicate(true),
		"press": press.duplicate(true), "record": record.duplicate(), "ended": ended, "result": result.duplicate(true),
		"last_grant": last_grant, "last_surplus": last_surplus, "cur_week": cur_week,
		"ally_log": ally_log.duplicate(true), "poll_log": poll_log.duplicate(true), "rng_state": str(rng.state)}


## A save that parses as JSON but lost a key must not throw here. This runs before the
## title screen, on the same path Department.from_data was hardened for: SaveFile only
## falls back to the .bak when the file fails to *parse*. `start()` has already written
## the fresh defaults, so anything missing below keeps its default instead of raising.
func from_data(d: Dictionary, seed_v: int) -> void:
	start(seed_v)
	if d.is_empty():
		return
	var raw_trust: Array = d.get("trust", []) if d.get("trust", []) is Array else []
	trust = []
	for v in raw_trust.slice(0, Situations.WARDS.size()):
		trust.append(clampi(_int_of(v), 0, 100))
	# a short ward list would leave `_trust()` and the City Hall screen indexing nothing
	while trust.size() < Situations.WARDS.size():
		trust.append(_int_of(Situations.WARDS[trust.size()].get("trust", 50)))
	var raw_allies: Dictionary = d.get("allies", {}) if d.get("allies", {}) is Dictionary else {}
	for a in ALLY_ORDER:
		var saved = raw_allies.get(a, {})
		if not (saved is Dictionary):
			continue
		allies[a] = {"standing": clampi(_int_of(saved.get("standing", ALLIES[a]["start"])), 0, 100),
			"lost": bool(saved.get("lost", false))}
	var raw_polls: Dictionary = d.get("polls", {}) if d.get("polls", {}) is Dictionary else {}
	for c in CAND_ORDER:
		if raw_polls.has(c):
			polls[c] = _float_of(raw_polls[c])
	pending = []
	var raw_pending: Array = d.get("pending", []) if d.get("pending", []) is Array else []
	for p0 in raw_pending:
		if not (p0 is Dictionary):
			continue
		var p: Dictionary = p0
		for k in ["due", "ward_i", "vis", "hit", "killed", "excessive", "cost", "op_week"]:
			if p.has(k):
				p[k] = _int_of(p[k])
		pending.append(p)
	press = []
	var raw_press: Array = d.get("press", []) if d.get("press", []) is Array else []
	for p2 in raw_press:
		if not (p2 is Dictionary):
			continue
		p2["week"] = _int_of(p2.get("week", 0))
		press.append(p2)
	var raw_record: Dictionary = d.get("record", {}) if d.get("record", {}) is Dictionary else {}
	for k2 in raw_record:
		record[k2] = _int_of(raw_record[k2])
	ended = bool(d.get("ended", false))
	last_grant = _int_of(d.get("last_grant", -99))
	last_surplus = _int_of(d.get("last_surplus", -99))
	cur_week = _int_of(d.get("cur_week", 1))
	result = d.get("result", {}) if d.get("result", {}) is Dictionary else {}
	ally_log = []
	var raw_ally_log: Array = d.get("ally_log", []) if d.get("ally_log", []) is Array else []
	for e in raw_ally_log:
		if e is Dictionary:
			ally_log.append(e)
	poll_log = []
	var raw_poll_log: Array = d.get("poll_log", []) if d.get("poll_log", []) is Array else []
	for e2 in raw_poll_log:
		if e2 is Dictionary:
			poll_log.append(e2)
	rng.state = String(d.get("rng_state", "0")).to_int()


## JSON gives back numbers as floats and a damaged save can give back anything at all;
## these read a scalar without raising on the wrong type (int(Dictionary) is an error).
static func _int_of(v) -> int:
	if v is int or v is float or v is bool:
		return int(v)
	if v is String:
		return String(v).to_int()
	return 0


static func _float_of(v) -> float:
	if v is int or v is float or v is bool:
		return float(v)
	if v is String:
		return String(v).to_float()
	return 0.0

