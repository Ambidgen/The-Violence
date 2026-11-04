extends RefCounted
## How an operation went (v0.7): the situation's goal met or not, each squad's
## objectives, and a competence score.
##
## Label: the goal result; a success or partial success that cost a death or an officer
## down reads ", at a cost".
## Score: a success starts at 100, a partial success at 65, a failure (an abort
## included) at 30. Every death costs 15 (officers, civilians, hostages) and every
## officer down 5. So a failure with everyone alive always scores better than one
## with deaths. Force (excessive force, civilians hit by police) is not in this score:
## it is the department's other reputation, which the city remembers (Politics, v0.9).

const Orders = preload("res://scripts/campaign/orders.gd")

const BASE := {"success": 100, "partial": 65, "failure": 30, "quiet": 100}
const LABELS := {"success": "Success", "partial": "Partial success", "failure": "Failure", "quiet": "Passed quietly"}


static func evaluate(sit: Dictionary, w) -> Dictionary:
	var s: Dictionary = w.incident.summary() if w.incident != null else {}
	var kind := "failure"
	var goal := ""
	var named = null
	for o in w.ops:
		if not o.judges and not o.civ and o.name == sit.get("named", "~") and sit.get("named", "") != "":
			named = o
	var suspects: Array = []
	for o2 in w.ops:
		if o2.team == 1:
			suspects.append(o2)
	var escaped := 0
	var resolved := 0
	for o3 in suspects:
		if o3.gone:
			escaped += 1
		elif o3.arrested or not o3.alive():
			resolved += 1
	match sit["type"]:
		"warrant", "barricade":
			if named == null:
				goal = "the named suspect was never found"
			elif named.arrested:
				kind = "success"
				goal = "%s arrested" % named.name
			elif named.complying:
				kind = "success"
				goal = "%s gave up" % named.name
			elif named.state == "dead":
				kind = "partial"
				goal = "%s killed" % named.name
			elif named.state == "down":
				kind = "partial"
				goal = "%s shot and taken to hospital" % named.name
			elif named.gone:
				goal = "%s escaped" % named.name
			else:
				goal = "%s still free" % named.name
		"gang":
			if suspects.is_empty():
				kind = "success"
				goal = "the house was empty"
			elif escaped == 0 and resolved == suspects.size():
				kind = "success"
				goal = "every member arrested or down"
			elif (suspects.size() - resolved) * 2 <= suspects.size():
				# most of the crew is in custody or down; whoever got away or stayed hidden
				# keeps it from a success (v0.9.1: a member never found no longer fails it)
				kind = "partial"
				var hid: int = suspects.size() - resolved - escaped
				goal = "%d of %d %s" % [suspects.size() - resolved, suspects.size(),
					"got away" if hid == 0 else ("never found" if escaped == 0 else "got away or were never found")]
			else:
				goal = "%d arrested or down, %d got away, %d still inside" % [resolved, escaped, suspects.size() - resolved - escaped]
		"hostage":
			var hs := int(s.get("hostages", 0))
			var safe := int(s.get("hostages_safe", 0))
			var dead := int(s.get("hostages_killed", 0))
			if hs > 0 and safe == hs:
				kind = "success"
				goal = "every hostage out alive"
			elif dead == 0 and safe > 0:
				kind = "partial"
				goal = "%d of %d hostages out" % [safe, hs]
			elif safe > 0 and dead < hs:
				kind = "partial" if dead * 2 < hs else "failure"
				goal = "%d hostage%s out, %d killed" % [safe, "" if safe == 1 else "s", dead]
			else:
				goal = "%d hostage%s killed" % [dead, "" if dead == 1 else "s"] if dead > 0 else "no hostage got out"
		"event":
			if not w.attack_on:
				# no attack, but anyone the police killed or an officer lost is not "quiet"
				var ck := int(s.get("civ_killed", 0))
				var chp := int(s.get("civ_hit_police", s.get("civ_hit_by_police", 0)))
				var ok_ := int(s.get("officers_killed", 0))
				if ck > 0 or ok_ > 0:
					kind = "failure"
					goal = "no attack came; %d in the crowd and %d officer%s killed" % [ck, ok_, "" if ok_ == 1 else "s"]
				elif chp > 0:
					kind = "partial"
					goal = "no attack came; police shot %d in the crowd" % chp
				else:
					kind = "quiet"
					goal = "nothing happened"
			else:
				var cd := int(s.get("civ_killed", 0))
				var stopped: bool = true
				for o4 in suspects:
					if o4.fighting():
						stopped = false
				if stopped and cd == 0:
					kind = "success"
					goal = "the attack was stopped with no one in the crowd killed"
				elif stopped:
					kind = "partial" if cd <= 2 else "failure"
					goal = "the attack was stopped; %d in the crowd killed" % cd
				else:
					goal = "the attacker%s got away; %d in the crowd killed" % ["" if suspects.size() == 1 else "s", cd]
	if w.aborted:
		kind = "failure"
		goal = "aborted: " + goal
	var deaths: int = int(s.get("officers_killed", 0)) + int(s.get("civ_killed", 0))
	var downs: int = int(s.get("officers_down", 0)) - int(s.get("officers_killed", 0))
	var base_score := int(BASE[kind])
	var death_penalty := 15 * deaths
	var down_penalty := 5 * downs
	var raw_score := base_score - death_penalty - down_penalty
	var score: int = maxi(0, raw_score)
	var score_parts: Array = [
		{"label": "Goal base (%s)" % LABELS[kind].to_lower(), "amount": base_score},
		{"label": "Deaths (%d × -15)" % deaths, "amount": -death_penalty},
		{"label": "Nonfatal officer downs (%d × -5)" % downs, "amount": -down_penalty},
	]
	if raw_score < 0:
		score_parts.append({"label": "Minimum score floor", "amount": -raw_score})
	score_parts.append({"label": "TOTAL", "amount": score, "total": true})
	var equation := "%d - %d - %d = %d" % [base_score, death_penalty, down_penalty, raw_score]
	if raw_score < 0:
		equation += " → 0 (minimum)"
	var squads: Array = []
	if w.teams.size() > 0:
		for el in w.teams[0]["elements"]:
			if not el.has("orders"):
				continue
			var res: Array = el.get("results", [])
			var alive := 0
			for m in el["members"]:
				if m.alive():
					alive += 1
			squads.append({"i": el["i"], "results": res.duplicate(true), "alive": alive, "n": el["members"].size(),
				"mode": el["mode"]})
	# the label is the goal; the score also counts the cost, so a goal met with people
	# killed or hurt says so (otherwise "Success, 50" reads as a contradiction)
	var label: String = LABELS[kind]
	if kind in ["success", "partial"] and score < int(BASE[kind]):
		label += ", at a cost"
	if w.aborted:
		label += " (aborted)"
	if w.get("stood_down") == true and goal.find("still") >= 0:
		goal += " (never found; the squads stood down)"
	return {"kind": kind, "label": label, "goal": goal, "score": score,
		"score_base": base_score, "score_death_penalty": death_penalty, "score_down_penalty": down_penalty,
		"score_raw": raw_score, "score_parts": score_parts, "score_explanation": equation,
		"deaths": deaths, "officers_killed": int(s.get("officers_killed", 0)), "civ_killed": int(s.get("civ_killed", 0)),
		"escaped": escaped, "aborted": w.aborted, "t": w.t, "squads": squads, "findings": int(s.get("findings", 0)),
		"orders_broken": w.broken.size()}


## What the chief changed, and whether it held (Q4). suggested is the plan Suggest
## produced when the situation was opened (or last pressed); executed is what ran.
## One line per squad that differs (objectives, constraints, entry, officers),
## closed with what that squad's objectives did and whether it broke an order —
## the closest the debrief can honestly come to "your edit was better" without
## running the operation twice. op_test.gd does run it twice, suggestion against
## an intel-reading chief, on matched seeds.
static func plan_diff(suggested: Dictionary, executed: Dictionary, res: Dictionary, w) -> Array:
	if suggested.is_empty():
		return []
	var s_sq: Array = suggested.get("squads", [])
	var e_sq: Array = executed.get("squads", [])
	if s_sq == e_sq and bool(suggested.get("night", false)) == bool(executed.get("night", false)):
		return ["You ran the suggestion unchanged."]
	var broken_sq := {}
	for b in w.broken:
		var o = w.by_id.get(b["id"], null)
		if o != null and o.squad >= 0:
			broken_sq[o.squad] = int(broken_sq.get(o.squad, 0)) + 1
	var by_i := {}
	for sqr in res.get("squads", []):
		by_i[int(sqr["i"])] = sqr
	var lines: Array = []
	for i in maxi(s_sq.size(), e_sq.size()):
		if i >= e_sq.size():
			lines.append("Squad %d: in the suggestion, dropped by you." % (i + 1))
			continue
		if i >= s_sq.size():
			lines.append("Squad %d: yours (no squad here in the suggestion): %s." % [i + 1, _fate(by_i.get(i, {}), broken_sq.get(i, 0))])
			continue
		var a: Dictionary = s_sq[i]
		var b2: Dictionary = e_sq[i]
		if a == b2:
			continue
		var bits: Array = []
		var ma: Array = a.get("members", [])
		var mb: Array = b2.get("members", [])
		if ma != mb:
			bits.append("%d officer%s (suggestion: %d)" % [mb.size(), "" if mb.size() == 1 else "s", ma.size()])
		var oa: Dictionary = a.get("orders", {})
		var ob: Dictionary = b2.get("orders", {})
		var ka: Array = (oa.get("objs", []) as Array).map(func(x): return Orders.OBJECTIVES.get(x.get("kind", ""), {}).get("name", x.get("kind", "")))
		var kb: Array = (ob.get("objs", []) as Array).map(func(x): return Orders.OBJECTIVES.get(x.get("kind", ""), {}).get("name", x.get("kind", "")))
		if ka != kb:
			bits.append("objective %s (suggestion: %s)" % [", then ".join(kb), ", then ".join(ka)])
		var changed: Array = []
		for key in ["entry", "consolidate", "pace"]:
			if String(oa.get(key, "")) != String(ob.get(key, "")):
				changed.append(Orders.CONSTRAINTS[key]["name"].to_lower())
		for key2 in ["tight", "less", "knock", "pistols"]:
			if bool(oa.get(key2, false)) != bool(ob.get(key2, false)):
				changed.append(Orders.CONSTRAINTS[key2]["name"] + (" on" if bool(ob.get(key2, false)) else " off"))
		if (oa.get("avoid", []) as Array).size() != (ob.get("avoid", []) as Array).size():
			changed.append("avoid %d room%s" % [(ob.get("avoid", []) as Array).size(), "" if (ob.get("avoid", []) as Array).size() == 1 else "s"])
		if (oa.get("phase", {}) as Dictionary).is_empty() != (ob.get("phase", {}) as Dictionary).is_empty():
			changed.append("phase line" + (" set" if not (ob.get("phase", {}) as Dictionary).is_empty() else " lifted"))
		if not changed.is_empty():
			bits.append(", ".join(changed))
		if int(a.get("stage", 0)) != int(b2.get("stage", 0)):
			bits.append("a different forming-up stage")
		lines.append("Squad %d — your %s: %s." % [i + 1, "; ".join(bits) if not bits.is_empty() else "edits", _fate(by_i.get(i, {}), broken_sq.get(i, 0))])
	if bool(suggested.get("night", false)) != bool(executed.get("night", false)):
		lines.append("You went in at %s; the suggestion had it by %s." % ["night" if bool(executed.get("night", false)) else "day",
			"night" if bool(suggested.get("night", false)) else "day"])
	return lines if not lines.is_empty() else ["You ran the suggestion unchanged."]


## One squad's account of itself, for the diff's closing clause.
static func _fate(sqr: Dictionary, broken: int) -> String:
	var fate := "objective unresolved when it ended"
	if not sqr.is_empty() and not (sqr.get("results", []) as Array).is_empty():
		var met: int = (sqr["results"] as Array).filter(func(r): return bool(r.get("ok", false))).size()
		fate = "%d of %d objective%s met" % [met, (sqr["results"] as Array).size(), "" if (sqr["results"] as Array).size() == 1 else "s"]
	return fate + (", no orders broken" if broken == 0 else (", %d order%s broken" % [broken, "" if broken == 1 else "s"]))
