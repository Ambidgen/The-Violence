extends RefCounted
## The four balance policies (EA_TASKS P1.A1), as code and as data.
##
## Every policy answers the same questions the interface asks a chief, in the same
## order the interface demands (the inheritance and procurement drafts are settled
## before the first operation, not after it), and every answer is derived from the
## desk's own contents — never from a random number. Two runs of the same seed and
## the same policy therefore decide the same way, which is what makes the balance
## baseline (P1.A4) reproducible.
##
## What a policy sets: the inheritance, the contracts and programs it signs, how it
## answers offers and events, whom it hires, whom it sends on courses, how it decides
## internal-affairs cases, whether it lets a plan buy kit, and which calls it takes.
##
## It never touches a combat roll: kit, habits, money, allies and intel are inputs the
## simulation reads (the same boundary the run layer keeps).

const Rogue = preload("res://scripts/campaign/rogue.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Patrol = preload("res://scripts/campaign/patrol.gd")

## The order the plan and the playtest report use.
const ORDER := ["cautious", "minimal", "military", "accept_all"]

## Priority for the calls a chief answers, most urgent first (the intel-reading chief's
## order in op_test: a hostage, a public event, a crew house, a barricade, a warrant).
const CALL_PRIORITY := {"hostage": 0, "event": 1, "gang": 2, "barricade": 3, "warrant": 4}

## The four policies. Each field is read by exactly one function below, so a policy can
## be changed in one place without disturbing the others.
##
##   doctrine      ids to prefer, in order (the week-1 inheritance; fall back to the
##                 first card dealt if none of them is on the desk)
##   contracts     procurement tags to consider, in order; [] means never sign one
##   max_contract  the most a contract may cost (0 = no limit)
##   programs      training programs to prefer, in order; [] means never start one
##   offers        decline_all | military | by_gain | accept_all
##   events        cheapest | no_cost | rich | first
##   hire          {on, fit_below, min_balance, prefer, max}
##   courses       {on, min_balance, list}  -- coaching, judgment, uof, firearms
##   ia            lapse | protect | discipline | review
##   issue_kit     let Suggest a plan buy kit for the operation (false = current kit)
##   calls         {max, types, skip_warrant_below_fit, skip_event_above_trauma}
const POLICIES := {
	"cautious": {
		"label": "cautious",
		"desc": "Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.",
		"doctrine": ["liaison", "pie", "cams", "reserve", "union", "lines", "tactical", "plates"],
		"contracts": ["restraint", "neutral"],
		"max_contract": 5000,
		"programs": ["crisis", "peer", "ED04", "GD03", "WD09", "ED06", "WD10"],
		"offers": "by_gain",
		"events": "cheapest",
		"hire": {"on": true, "fit_below": 14, "min_balance": 9000, "prefer": "judgment", "max": 8,
			"emergency_below": 12, "keep_on_books": 18},
		"courses": {"on": true, "min_balance": 5000, "list": ["coaching", "judgment"]},
		"ia": "discipline",
		"issue_kit": false,
		"suggested_kit": true,
		"calls": {"max": 2, "types": [], "skip_warrant_below_fit": 12, "skip_event_above_trauma": 12.0},
	},
	"minimal": {
		"label": "minimal",
		"desc": "No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.",
		"doctrine": ["reserve", "cams", "pie", "liaison", "union", "lines", "tactical", "plates"],
		"contracts": [],
		"max_contract": 0,
		"programs": [],
		"offers": "decline_all",
		"events": "no_cost",
		"hire": {"on": false, "fit_below": 0, "min_balance": 0, "prefer": "any", "max": 0,
			"emergency_below": 0, "keep_on_books": 0},
		"courses": {"on": false, "min_balance": 0, "list": []},
		"ia": "lapse",
		"issue_kit": false,
		"calls": {"max": 1, "types": [], "skip_warrant_below_fit": 0, "skip_event_above_trauma": 0.0},
	},
	"military": {
		"label": "military-first",
		"desc": "Military contracts and kit, Carrick's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.",
		"doctrine": ["plates", "tactical", "reserve", "union", "cams", "lines", "pie", "liaison"],
		"contracts": ["military", "neutral"],
		"max_contract": 8000,
		"programs": ["inservice", "GD03", "PF03", "WD09", "ED04"],
		"offers": "military",
		"events": "rich",
		"hire": {"on": true, "fit_below": 16, "min_balance": 6000, "prefer": "lateral", "max": 8,
			"emergency_below": 12, "keep_on_books": 0},
		"courses": {"on": true, "min_balance": 4000, "list": ["coaching", "firearms"]},
		"ia": "protect",
		"issue_kit": true,
		"calls": {"max": 3, "types": [], "skip_warrant_below_fit": 0, "skip_event_above_trauma": 0.0},
	},
	"accept_all": {
		"label": "accept-all",
		"desc": "Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.",
		"doctrine": ["reserve", "plates", "pie", "liaison", "union", "cams", "tactical", "lines"],
		"contracts": ["restraint", "neutral", "military"],
		"max_contract": 0,
		"programs": ["crisis", "inservice", "peer", "GD03", "ED04", "WD09"],
		"offers": "accept_all",
		"events": "first",
		"hire": {"on": true, "fit_below": 18, "min_balance": 4000, "prefer": "lateral", "max": 10,
			"emergency_below": 0, "keep_on_books": 20},
		"courses": {"on": true, "min_balance": 3500, "list": ["coaching"]},
		"ia": "review",
		"issue_kit": true,
		"calls": {"max": 3, "types": [], "skip_warrant_below_fit": 0, "skip_event_above_trauma": 0.0},
	},
}


static func has(policy: String) -> bool:
	return POLICIES.has(policy)


static func label(policy: String) -> String:
	return String(POLICIES.get(policy, {}).get("label", policy))


## Every policy id, in the plan's order.
static func all() -> Array:
	return ORDER.duplicate()


## Parse a --policy value: "all", one id, or a comma-separated list. Unknown ids are
## reported by name rather than silently dropped.
static func parse(spec: String) -> Array:
	var s := spec.strip_edges()
	if s == "" or s == "all":
		return all()
	var out: Array = []
	for raw in s.split(",", false):
		var id := String(raw).strip_edges()
		if has(id) and not out.has(id):
			out.append(id)
	return out


# ================================================================== the desk
## Settle everything the week's desk holds, in the interface's order — the inheritance
## first, then procurement, then a training program, then the week's offers and events.
## Nothing here draws a random number: the choice is a function of the cards dealt.
static func settle_desk(c, policy: String) -> Array:
	var pol: Dictionary = POLICIES[policy]
	var lines: Array = []
	var guard := 0
	while not c.run.drafts.is_empty() and guard < 12:
		guard += 1
		var d: Dictionary = c.run.drafts[0]
		var cards: Array = (d["cards"] as Array).duplicate()
		var kind: String = String(d["kind"])
		var choice := ""
		match kind:
			"doctrine":
				choice = pick_doctrine(cards, pol)
			"procurement":
				choice = pick_contract(c, cards, pol)
			"program":
				choice = pick_program(c, cards, pol)
		var out: Array = c.run.pick(c, 0, choice)
		# A card the policy wanted but could not pay for leaves the draft open: pass.
		if not c.run.drafts.is_empty() and c.run.drafts[0]["cards"] == cards:
			out = c.run.pick(c, 0, "")
			if not c.run.drafts.is_empty() and c.run.drafts[0]["cards"] == cards:
				break   # nothing on the desk can be settled; leave it (the run continues)
		lines.append_array(out)
	guard = 0
	while not c.run.offers.is_empty() and guard < 12:
		guard += 1
		var o: Dictionary = c.run.offers[0]
		var want: bool = want_offer(o, pol)
		var got: Array = c.run.answer_offer(c, 0, want)
		if not c.run.offers.is_empty() and c.run.offers[0] == o:
			# the account could not cover accepting: decline instead of looping
			got = c.run.answer_offer(c, 0, false)
		lines.append_array(got)
	guard = 0
	while not c.run.events.is_empty() and guard < 12:
		guard += 1
		var e: Dictionary = c.run.events[0]
		var k: int = pick_event_choice(c, e, pol)
		var out2: Array = c.run.answer_event(c, 0, k)
		if not c.run.events.is_empty() and c.run.events[0] == e:
			break
		lines.append_array(out2)
	return lines


## The inheritance: the first preferred doctrine that was dealt, else the first card.
static func pick_doctrine(cards: Array, pol: Dictionary) -> String:
	for want in pol["doctrine"]:
		if cards.has(want):
			return String(want)
	return String(cards[0]) if not cards.is_empty() else ""


## A procurement contract: the first allowed tag with a card the account can cover,
## else pass (""). `contracts: []` means never sign one.
static func pick_contract(c, cards: Array, pol: Dictionary) -> String:
	var tags: Array = pol["contracts"]
	if tags.is_empty():
		return ""
	var cap: int = int(pol["max_contract"])
	for tag in tags:
		var best := ""
		var best_cost := 1 << 30
		for cid in cards:
			var ct: Dictionary = Rogue.CONTRACTS.get(String(cid), {})
			if ct.is_empty() or String(ct["tag"]) != String(tag):
				continue
			var cost: int = int(ct["cost"])
			if cap > 0 and cost > cap:
				continue
			if cost < best_cost:   # the cheapest contract of the tag it prefers
				best = String(cid)
				best_cost = cost
		if best != "" and int(c.dept.balance) >= best_cost:
			return best
	return ""


## A training program: the first preferred id on the desk the account can cover, else a
## restorative special program, else pass. `programs: []` means never start one.
static func pick_program(c, cards: Array, pol: Dictionary) -> String:
	var prefs: Array = pol["programs"]
	if prefs.is_empty():
		return ""
	for want in prefs:
		if not cards.has(want):
			continue
		var cost: int = int(c.run.program_info(String(want), c).get("cost", 0))
		if int(c.dept.balance) >= cost:
			return String(want)
	# nothing preferred was dealt: take the cheapest card it can still afford, but only
	# where the policy is not picky about content (cautious and minimal are)
	if String(pol["label"]) in ["cautious"]:
		return ""
	var best := ""
	var best_cost := 1 << 30
	for cid in cards:
		var cost2: int = int(c.run.program_info(String(cid), c).get("cost", 0))
		if cost2 <= int(c.dept.balance) and cost2 < best_cost:
			best = String(cid)
			best_cost = cost2
	return best


## Accept or decline an offer, by what its accept block does (never by its prose).
static func want_offer(o: Dictionary, pol: Dictionary) -> bool:
	var mode: String = String(pol["offers"])
	if mode == "decline_all":
		return false
	if mode == "accept_all":
		return true
	var eff: Dictionary = o.get("accept", {})
	if mode == "military":
		# the Safe Streets chief: hardware, cash, and Carrick's favour
		if eff.has("contract"):
			return true
		if int(eff.get("money", 0)) > 0:
			return true
		var poll: Dictionary = eff.get("poll", {})
		return float(poll.get("kettering", 0.0)) > 0.0
	# by_gain: take what buys goodwill or money and costs no ally
	var ally: Dictionary = eff.get("ally", {})
	for a in ally:
		if int(ally[a]) < 0:
			return false
	if eff.has("reconcile"):
		# EA_TASKS P1.E2: winning a lost ally back is the whole point of the offer
		# (affordability is enforced by answer_offer, to the overdraft limit)
		return true
	if eff.has("contract"):
		# "military" is the tag an offer uses to grant *some* military contract; check
		# both forms, or cautious would take Carrick's truck for the cash.
		var cc := String(eff["contract"])
		if cc == "military" or String(Rogue.CONTRACTS.get(cc, {}).get("tag", "")) == "military":
			return false
	if int(eff.get("money", 0)) > 0:
		return true
	for a2 in ally:
		if int(ally[a2]) > 0:
			return true
	var poll2: Dictionary = eff.get("poll", {})
	return float(poll2.get("okonjo", 0.0)) > 0.0 or float(poll2.get("pell", 0.0)) > 0.0


## The index of the answer a policy gives an event: the best-scoring affordable choice,
## ties going to the first (so the answer is stable).
static func pick_event_choice(c, e: Dictionary, pol: Dictionary) -> int:
	var mode: String = String(pol["events"])
	var best := -1
	var best_score := -1e9
	var chs: Array = e.get("choices", [])
	for i in chs.size():
		var ch: Dictionary = chs[i]
		if c.run.choice_blocked(c, ch) != "":
			continue
		var cost: int = int(ch.get("cost", 0))
		var eff: Dictionary = ch.get("effects", {})
		var score := 0.0
		match mode:
			"no_cost":
				score = -float(cost)
			"cheapest":
				score = -float(cost) / 1000.0 + float(eff.get("money", 0)) / 2000.0
				for a in eff.get("ally", {}):
					score += 0.5 * float(eff["ally"][a])
			"rich":
				score = float(eff.get("money", 0)) / 1000.0 - float(cost) / 1000.0
				if eff.has("contract"):
					score += 3.0
				for p in eff.get("poll", {}):
					score += float(eff["poll"][p])
			_:
				score = float(-i)   # "first": keep the desk's own order
		if score > best_score:
			best_score = score
			best = i
	return best if best >= 0 else maxi(0, chs.size() - 1)


# ================================================================== the department
## Hiring: while the force is short of the policy's target and the account can carry it,
## take the applicant it prefers. Returns the lines the department wrote.
static func hiring(c, policy: String) -> Array:
	var pol: Dictionary = POLICIES[policy]
	var rule: Dictionary = pol["hire"]
	var lines: Array = []
	if not bool(rule["on"]):
		return lines
	var target: int = int(rule["fit_below"])
	var floor_money: int = int(rule["min_balance"])
	# EA_TASKS P1.C4: the standing order is set like the player sets it, on the Roster
	c.dept.keep_on_books = int(rule.get("keep_on_books", 0))
	# EA_TASKS P1.C3: short of officers this week, sign the emergency lateral (on duty now)
	var below: int = int(rule.get("emergency_below", 0))
	if below > 0 and c.dept.available().size() < below and c.dept.emergency_blocked() == "":
		var cand: Dictionary = c.dept.emergency_candidate()
		if int(c.dept.balance) - Department.emergency_cost(cand) >= floor_money:
			var em: Dictionary = c.dept.sign_emergency()
			if not em.is_empty():
				lines.append("Signed %s %s (emergency lateral)." % [String(em.get("rank", "")).to_lower(), String(em.get("name", ""))])
	var made := 0
	while made < int(rule["max"]):
		var booked: int = c.dept.available().size() + c.dept.officers.filter(func(r): return String(r["status"]) == "academy").size()
		if booked >= target or int(c.dept.balance) <= floor_money or c.dept.frozen():
			break
		var pool: Array = c.dept.applicants_now()
		if pool.is_empty():
			break
		var pick: Dictionary = choose_applicant(pool, String(rule["prefer"]), int(c.dept.balance))
		if pick.is_empty():
			break
		var got: Dictionary = c.dept.choose_applicant(pick)
		if got.is_empty():
			break
		made += 1
		lines.append("Hired %s %s (%s)." % [String(got.get("rank", "")).to_lower(), String(got.get("name", "")),
			"lateral" if bool(got.get("lateral", false)) else "academy"])
	return lines


## The applicant a policy takes: the preference is explicit so the choice is stable.
static func choose_applicant(pool: Array, prefer: String, balance: int) -> Dictionary:
	var ok: Array = pool.filter(func(r): return Department.applicant_cost(r) <= balance)
	if ok.is_empty():
		return {}
	match prefer:
		"lateral":
			var lat: Array = ok.filter(func(r): return bool(r.get("lateral", false)))
			if not lat.is_empty():
				lat.sort_custom(func(a, b): return int(a.get("judgment", 0)) > int(b.get("judgment", 0)))
				return lat[0]
		"judgment":
			ok.sort_custom(func(a, b): return int(a.get("judgment", 0)) > int(b.get("judgment", 0)))
			return ok[0]
	return ok[0]


## Courses: one bad habit at a time, while the policy's cushion lasts.
static func training(c, policy: String) -> Array:
	var pol: Dictionary = POLICIES[policy]
	var rule: Dictionary = pol["courses"]
	var lines: Array = []
	if not bool(rule["on"]):
		return lines
	var floor_money: int = int(rule["min_balance"])
	var list: Array = rule["list"]
	for r in c.dept.officers:
		if int(c.dept.balance) <= floor_money or c.dept.frozen():
			break
		if String(r["status"]) in ["dead", "retired", "fired", "resigned", "academy", "suspended"]:
			continue
		if String(r["course"]) != "":
			continue
		var cid := ""
		if list.has("coaching") and not (r["bad_traits"] as Array).is_empty() and not (r["queue"] as Array).has("coaching"):
			cid = "coaching"
		elif list.has("judgment") and int(r.get("judgment", 0)) < 55 and not (r["queue"] as Array).has("judgment"):
			cid = "judgment"
		elif list.has("firearms") and int(r.get("drill", 0)) < 4 and not (r["queue"] as Array).has("firearms"):
			cid = "firearms"
		if cid == "":
			continue
		var res: Dictionary = c.dept.enrol_or_queue(r, cid)
		if bool(res.get("ok", false)):
			lines.append("%s: %s (%s)." % [String(r.get("name", "")), cid, String(res.get("mode", ""))])
	return lines


## Internal affairs: what the policy does with the findings on its desk.
##   lapse       leave the cases to run out (three weeks)
##   protect     clear the officer, whatever the finding
##   discipline  retrain on the grave findings, clear the rest
##   review      suspend the most serious, clear the rest
static func ia(c, policy: String) -> Array:
	var pol: Dictionary = POLICIES[policy]
	var mode: String = String(pol["ia"])
	var lines: Array = []
	if mode == "lapse":
		return lines
	var grave := ["excessive_force", "misjudgment", "civilian_hit_by_police", "friendly_fire", "jumpy_fire"]
	for cs in c.dept.open_cases():
		var kind: String = String(cs.get("kind", ""))
		var decision := "clear"
		match mode:
			"protect":
				decision = "clear"
			"review":
				decision = "suspend" if grave.has(kind) and Department.case_is_urgent(cs, int(c.dept.week)) else "clear"
			_:
				decision = "retrain" if grave.has(kind) else "clear"
		var ln: String = c.decide_case(cs, decision)
		if ln != "" and decision != "clear":
			lines.append(ln)
	return lines


# ================================================================== the week's calls
## The situations a policy answers this week, in the order it answers them. Officers
## already committed are left out (the caller re-checks availability as it goes).
static func call_plan(c, policy: String) -> Array:
	var pol: Dictionary = POLICIES[policy]
	var rule: Dictionary = pol["calls"]
	var open: Array = c.board.filter(func(s): return String(s["status"]) == "open")
	var types: Array = rule["types"]
	if not types.is_empty():
		open = open.filter(func(s): return types.has(String(s["type"])))
	var fit: int = c.dept.available().size()
	var skip_warrant: int = int(rule["skip_warrant_below_fit"])
	var skip_trauma: float = float(rule["skip_event_above_trauma"])
	var out: Array = []
	for s in open:
		if bool(s.get("truce", false)):
			continue
		var kind: String = String(s["type"])
		if kind == "warrant" and skip_warrant > 0 and int(s["visibility"]) <= 1 and fit < skip_warrant:
			continue   # not worth an officer when the department is short
		if kind == "event" and skip_trauma > 0.0 and not _has_calm_officer(c, s, skip_trauma):
			continue   # nobody under the crowd-risk trauma floor: do not take that call
		out.append(s)
	out.sort_custom(func(a, b):
		var pa: int = int(CALL_PRIORITY.get(String(a["type"]), 9))
		var pb: int = int(CALL_PRIORITY.get(String(b["type"]), 9))
		if pa != pb:
			return pa < pb
		return int(a["visibility"]) > int(b["visibility"]))
	var max_calls: int = int(rule["max"])
	return out.slice(0, max_calls)


# ================================================================== patrol encounters (2026-11-05)
## How a policy answers the radio: 0 proceed, 1 proceed with backup en route, 2 wait for
## backup. Read from the dispatch only (Patrol.read: urgency and danger as the chief sees
## them), never from the encounter's hidden dice.
##   cautious     backup for anything that could turn; waits unless it is urgent
##   military     backup en route for anything that could turn
##   accept_all   backup en route only when it reads dangerous
##   minimal      never answers: the pair goes in alone (the default at the week's end)
static func patrol_choice(e: Dictionary, policy: String) -> int:
	var rd: Dictionary = Patrol.read(e)
	var danger: String = String(rd["danger"])
	var urgent: bool = String(rd["urgency"]) == "urgent"
	match policy:
		"cautious":
			if danger == "dangerous":
				return 1 if urgent else 2
			if danger == "could turn":
				return 1
			return 0
		"military":
			return 1 if danger != "routine" else 0
		"accept_all":
			return 1 if danger == "dangerous" else 0
	return 0


## True when at least one officer free for this situation is under the trauma floor.
static func _has_calm_officer(c, s: Dictionary, floor: float) -> bool:
	for r in c.available_for(s["id"]):
		if float(r.get("trauma", 0.0)) < floor:
			return true
	return false


## Whether a policy lets Suggest a plan buy kit for an operation (P1.A1: current kit
## unless the policy buys kit).
## EA_TASKS P1.C5: does the policy accept the kit Suggest a plan proposes for a raid?
static func takes_suggested_kit(policy: String) -> bool:
	return bool(POLICIES.get(policy, {}).get("suggested_kit", false))


static func issues_kit(policy: String) -> bool:
	return bool(POLICIES.get(policy, {}).get("issue_kit", false))


## A one-line description, for the report header.
static func describe(policy: String) -> String:
	return String(POLICIES.get(policy, {}).get("desc", ""))
