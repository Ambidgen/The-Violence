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
		"blurb": "A councilman who has never met a police budget he would not double, or a contract he would not steer to a cousin. Loves the department. Loves it loudly."},
	"okonjo": {"name": "Dana Okonjo-Vale", "ticket": "Carrick Together", "start": 31,
		"blurb": "A democratic socialist who wants to fix the city and means it. She also wants you gone, and means that too: she has not forgiven you for the Bridge Street evictions."},
	"pell": {"name": "Gordon Pell", "ticket": "Independent", "start": 35,
		"blurb": "Competent, tireless and boring enough to stop clocks. His platform is a comprehensive review of the city's existing reviews."},
}
const CAND_ORDER := ["kettering", "okonjo", "pell"]

var trust: Array = []          # per ward, 0-100
var allies := {}               # id -> {standing, lost}
var polls := {}                # candidate id -> score (shares are these normalised)
var pending: Array = []        # [{due, kind, ...}] consequences still to land
var press: Array = []          # [{week, head, body, kind}]
var record := {}               # running totals the press and the endings quote
var ended := false
var result := {}               # the election, once held
var rng := RandomNumberGenerator.new()


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
		"dismissed": 0, "cleared": 0, "crowd_killed": 0}
	_headline(1, "NEW CHIEF TAKES COMMAND OF PORT CARRICK PD", "Forty weeks to the election. The council wants results, the coalition wants answers, and the union wants a raise.", "city")


# ================================================================== reading it
func share(c: String) -> float:
	var tot := 0.0
	for k in CAND_ORDER:
		tot += maxf(1.0, float(polls[k]))
	return 100.0 * maxf(1.0, float(polls[c])) / tot


func leader() -> String:
	var best := CAND_ORDER[0]
	for c in CAND_ORDER:
		if share(c) > share(best):
			best = c
	return best


func standing(a: String) -> int:
	return int(allies[a]["standing"])


func lost(a: String) -> bool:
	return bool(allies[a]["lost"])


func avg_trust() -> float:
	var t := 0.0
	for v in trust:
		t += float(v)
	return t / maxf(1.0, trust.size())


func week_press(week: int) -> Array:
	return press.filter(func(p): return int(p["week"]) == week)


# ================================================================== moving it
func _ally(a: String, d: int, dept, lines: Array) -> void:
	var al: Dictionary = allies[a]
	al["standing"] = clampi(int(al["standing"]) + d, 0, 100)
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


func _poll(c: String, d: float) -> void:
	polls[c] = clampf(float(polls[c]) + d, 3.0, 200.0)


func _headline(week: int, head: String, body: String, kind: String) -> void:
	press.append({"week": week, "head": head, "body": body, "kind": kind})
	if press.size() > 300:
		press = press.slice(press.size() - 300)


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
	var vis: int = int(sit.get("visibility", 1))
	var wi: int = int(sit.get("ward_i", -1))
	var s: Dictionary = w.incident.summary() if w.incident != null else {}
	var police := {}
	for o in w.ops:
		if o.judges:
			police[o.id] = true
	var civ_hit := 0
	var civ_killed := 0
	var excessive := 0
	var best := "none"
	var order := ["video", "witness", "heard", "none"]
	for f in (w.incident.findings if w.incident != null else []):
		var by_police: bool = police.has(String(f.get("by", "")))
		match f["kind"]:
			"civilian_hit_by_police":
				civ_hit += 1
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
			_poll("kettering", 0.6 + 0.5 * vis)
			_poll("pell", -0.3 * vis)
			_trust(wi, -1 - vis / 2)
			if vis >= 3:
				_headline(week, "POLICE OPERATION IN %s ENDS IN FAILURE" % where.to_upper(), "The %s at %s did not go to plan. Kettering: 'Our officers deserve leadership.'" % [what, sit.get("address", "")], "op")
	# officers killed: the union blames management, the law-and-order ticket blames everyone else
	if off_killed > 0:
		_ally("union", -4 * off_killed, dept, lines)
		_ally("council", -2 * off_killed, dept, lines)
		_poll("kettering", 1.5 * off_killed)
		_headline(week, "%s OFFICER%s KILLED IN %s" % [_num(off_killed), "" if off_killed == 1 else "S", where.to_upper()],
			"The department lowers its flags. Rourke (union): 'Somebody sent them in there.'", "op")
	if sus_killed > 0 and vis >= 2:
		_poll("okonjo", 0.4 * sus_killed * vis)
		_trust(wi, -sus_killed)
	# a rally that turned to killing is the city's front page whatever happened next
	if crowd_killed > 0:
		_ally("council", -10, dept, lines)
		_ally("coalition", -6, dept, lines)
		_poll("okonjo", 3.0 * crowd_killed)
		_poll("kettering", 2.0 * crowd_killed)
		_poll("pell", -3.0)
		_trust(2, -8)
		_headline(week, "%s KILLED AT CIVIC PLAZA RALLY" % _num(crowd_killed).to_upper(), "The city asks how the security plan failed. Pell calls for a review; Okonjo-Vale calls for your resignation.", "op")
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
			pending.append({"due": week + rng.randi_range(6, 10), "kind": "lawsuit", "cost": cost, "ward": where, "op_week": week})
			lines.append("A lawsuit is being filed (it will settle in a couple of months).")
	return lines


static func _n(n: int, one: String, many := "") -> String:
	return "%d %s" % [n, one if n == 1 else (many if many != "" else one + "s")]


static func _num(n: int) -> String:
	var words := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
	return words[n].to_upper() if n < words.size() else str(n)


# ================================================================== internal affairs
## A case was decided (Department.decide). The union watches the discipline, the
## coalition watches the cases, and the DA watches what is cleared.
func on_decision(week: int, c: Dictionary, decision: String, dept) -> Array:
	var lines: Array = []
	var strong: bool = String(c.get("strength", "none")) in ["video", "witness"]
	var serious: bool = String(c.get("kind", "")) in ["civilian_hit_by_police", "excessive_force"]
	match decision:
		"clear":
			record["cleared"] += 1
			_ally("union", 2, dept, lines)
			if serious and strong:
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
				elif rng.randf() < (0.55 if c["strength"] == "video" else 0.25):
					pending.append({"due": week + rng.randi_range(1, 4), "kind": "leak", "case": c["id"], "officer": c["officer"],
						"strength": c["strength"], "text": c.get("text", "")})
				_ally("da", -4, dept, lines)
				_ally("coalition", -3, dept, lines)
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
func week_end(week: int, board: Array, dept) -> Array:
	var lines: Array = []
	# what nobody went to
	for s in board:
		if s["status"] != "unattended":
			continue
		record["unattended"] += 1
		var wi: int = int(s["ward_i"])
		_trust(wi, -2)
		_poll("kettering", 0.5 + 0.2 * int(s["visibility"]))
		if s["type"] in ["gang", "hostage"] or int(s["visibility"]) >= 3:
			pending.append({"due": week + rng.randi_range(1, 3), "kind": "neglect", "ward": s["ward"], "ward_i": wi,
				"type": s["type"], "address": s.get("address", ""), "vis": int(s["visibility"])})
	# the budget committee watches the account
	if dept.balance < 0:
		_ally("council", -5, dept, lines)
		_poll("pell", -0.4)
	elif dept.deficit_weeks == 0 and week % 4 == 0:
		_ally("council", 2, dept, lines)
	# a demoralised force talks to its union
	if dept.morale < 40:
		_ally("union", -2, dept, lines)
	# consequences coming due
	var keep: Array = []
	for p in pending:
		if int(p["due"]) > week:
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
	# the polls drift a little on their own; the trailing campaigns try harder
	for c in CAND_ORDER:
		_poll(c, rng.randfn(0.0, 0.7) + (0.25 if c != leader() else -0.15))
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
			var body := "%s%s Okonjo-Vale: 'This is what policing looks like under this chief.'" % [
				"Video of the %s at %s is circulating. " % [p["what"], p["address"]] if p["strength"] == "video" else "Residents of %s describe the %s at %s. " % [p["ward"], p["what"], p["address"]],
				("(The operation was %d weeks ago.) " % late) if late >= 3 else ""]
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
			_trust(int(p["ward_i"]), -3)
			_ally("coalition", -2, dept, lines)
			_poll("kettering", 1.0)
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
			"kettering": ["KETTERING: 'I WILL GIVE THE POLICE WHATEVER THEY ASK FOR'", "%s%% back Kettering's 'Safe Streets' ticket. His brother-in-law's armoured vehicle firm declines to comment." % int(sh)],
			"okonjo": ["OKONJO-VALE LEADS: 'THE CHIEF WILL BE MY FIRST APPOINTMENT TO LEAVE'", "%s%% back Carrick Together. Asked about the Bridge Street evictions, she said only: 'He knows.'" % int(sh)],
			"pell": ["PELL UNVEILS 212-PAGE PLAN TO STREAMLINE CITY PAPERWORK", "%s%% back the independent. The plan includes a form for requesting the plan." % int(sh)],
		}
		_headline(week, lines_c[ld][0], lines_c[ld][1], "politics")
		have += 1
	var filler := [
		["COUNCIL DEBATES POTHOLE ON UNION STREET FOR FOURTH WEEK", "The pothole has been invited to testify."],
		["IRONWORKS PLANT CLOSURE: 300 MORE JOBS GO", "The mill that built the city will be flats, eventually."],
		["HARBOUR BRIDGE INSPECTION 'POSTPONED INDEFINITELY'", "Engineers recommend walking briskly."],
		["CITY HALL ELEVATOR STUCK AGAIN; PELL TAKES STAIRS, NOTES TIME", "He has submitted the figure to the clerk."],
		["CARRICK LEDGER CUTS ANOTHER FOUR REPORTERS", "This newspaper regrets nothing it can still afford to print."],
		["NORTHGATE BAKERY WINS REGIONAL PRIZE FOR RYE", "The one good thing this week."],
		["WATER MAIN BURSTS UNDER STATION ROAD", "Repairs will take 'weeks, possibly a season'."],
		["SCHOOL BOARD VOTES TO MERGE TWO MORE SCHOOLS", "Parents say the buses already run late."],
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
	var win := CAND_ORDER[0]
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
			head = "Kettering keeps you on. Of course he does."
			lines.append("The new mayor doubles the equipment budget in his first week. The contracts go to firms nobody has heard of.")
			if force >= 6:
				lines.append("Your force record is exactly what he campaigned on. He makes you Deputy Mayor for Public Safety. The coalition files a federal complaint the same afternoon.")
			else:
				lines.append("He asks you to be 'more visible'. You are given a podium and a flag and a list of neighbourhoods to be visible in.")
			if lost("da"):
				lines.append("Varga's office keeps charging officers. Kettering keeps pardoning them. Everyone keeps filing.")
		"okonjo":
			keep = t >= 60.0 and not lost("coalition") and force <= 2
			if keep:
				head = "Okonjo-Vale keeps you. In writing. For ninety days."
				lines.append("Your record leaves her nothing to fire you for. She says so at the swearing-in, through her teeth. The coalition calls it 'a test'. Rourke calls it 'probation'. They are both right.")
			else:
				head = "Okonjo-Vale fires you on her first morning."
				lines.append("Your dismissal is the first item of business, before the coffee. She reads the force record aloud: %d civilians hit by police, %d killed. She does not mention Bridge Street. She does not have to." % [int(record["civ_hit"]), int(record["civ_killed"])])
			lines.append("The department is put under a civilian oversight board. Its first request is every file you ever closed.")
		"pell":
			keep = dept.balance >= 0 and dept.deficit_weeks <= 4
			if keep:
				head = "Pell keeps you, subject to review."
				lines.append("The review is scheduled for the third quarter of the year after next. Your budget is balanced, so he likes you, in the way a man likes a spreadsheet that adds up.")
			else:
				head = "Pell reviews your position out of existence."
				lines.append("%d weeks in deficit. The chief's office is merged into the Department of Municipal Services, Sub-Division C. Your desk is reassigned to parking enforcement." % int(dept.deficit_weeks))
	lines.append("Forty weeks: %s succeeded, %d failed, %s nobody went to. %s killed. %s in the papers, %s settled, %s leaked." % [
		_n(int(record["successes"]), "operation"), int(record["failures"]), _n(int(record["unattended"]), "situation"),
		_n(int(record["officers_killed"]), "officer"), _n(int(record["stories"]), "story", "stories"),
		_n(int(record["settled"]), "lawsuit"), _n(int(record["leaks"]), "case")])
	lines.append("FILED. NOT RESOLVED.")
	return {"winner": win, "keep": keep, "head": head, "lines": lines}


# ================================================================== saving
func to_data() -> Dictionary:
	return {"trust": trust.duplicate(), "allies": allies.duplicate(true), "polls": polls.duplicate(), "pending": pending.duplicate(true),
		"press": press.duplicate(true), "record": record.duplicate(), "ended": ended, "result": result.duplicate(true),
		"rng_state": str(rng.state)}


func from_data(d: Dictionary, seed_v: int) -> void:
	start(seed_v)
	if d.is_empty():
		return
	trust = []
	for v in d.get("trust", []):
		trust.append(int(v))
	for a in d.get("allies", {}):
		allies[a] = {"standing": int(d["allies"][a]["standing"]), "lost": bool(d["allies"][a]["lost"])}
	for c in d.get("polls", {}):
		polls[c] = float(d["polls"][c])
	pending = d.get("pending", [])
	for p in pending:
		for k in ["due", "ward_i", "vis", "hit", "killed", "excessive", "cost", "op_week"]:
			if p.has(k):
				p[k] = int(p[k])
	press = d.get("press", [])
	for p2 in press:
		p2["week"] = int(p2["week"])
	for k2 in d.get("record", {}):
		record[k2] = int(d["record"][k2])
	ended = bool(d.get("ended", false))
	result = d.get("result", {})
	rng.state = String(d.get("rng_state", "0")).to_int()
