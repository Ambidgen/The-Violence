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
			elif resolved + escaped == suspects.size() and escaped * 2 <= suspects.size():
				kind = "partial"
				goal = "%d of %d got away" % [escaped, suspects.size()]
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
	var score: int = maxi(0, int(BASE[kind]) - 15 * deaths - 5 * downs)
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
		"deaths": deaths, "officers_killed": int(s.get("officers_killed", 0)), "civ_killed": int(s.get("civ_killed", 0)),
		"escaped": escaped, "aborted": w.aborted, "t": w.t, "squads": squads, "findings": int(s.get("findings", 0)),
		"orders_broken": w.broken.size()}
