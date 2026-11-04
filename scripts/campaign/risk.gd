extends RefCounted
## Planning readiness from the same public intelligence the chief can read.
##
## This is deliberately not a combat predictor. It is a broad, bounded readiness
## index for comparing plans: the range describes uncertainty in the briefing and
## the assigned force, not a probability of winning. In particular, do not add
## occupants, attack, attack_t, attack_p, or unconfirmed `truth` fields here.

const Autoplan = preload("res://scripts/campaign/autoplan.gd")

const BASE := {"warrant": 56.0, "gang": 46.0, "barricade": 51.0, "hostage": 43.0, "event": 55.0}
const EXPECTED_THREAT := {"warrant": 2.0, "gang": 5.0, "barricade": 1.5, "hostage": 2.0, "event": 1.5}


static func assess(sit: Dictionary, plan: Dictionary, officers: Array) -> Dictionary:
	var typ := String(sit.get("type", "warrant"))
	var want := Autoplan.want_for(sit)
	var n := officers.size()
	var known: Array = []
	var unknown: Array = []
	var threat_lo: float = EXPECTED_THREAT.get(typ, 2.0)
	var threat_hi: float = threat_lo
	var threat_seen := false
	var confidence := 0.35
	var weapon_risk := 0.0
	for f in sit.get("intel", []):
		var key := String(f.get("key", ""))
		var is_known := bool(f.get("known", false))
		# Unknown truth is intentionally never read, even for a tooltip.
		var text := String(f.get("truth", "") if is_known else f.get("est", ""))
		var label := String(f.get("label", key))
		if is_known:
			known.append("%s: %s" % [label, text])
		elif key not in ["deadline", "duration"]:
			unknown.append(label)
		if key in ["armed", "captors"]:
			var nums := _numbers(text)
			if not nums.is_empty():
				threat_lo = float(nums[0])
				threat_hi = float(nums[nums.size() - 1])
				if not is_known and nums.size() == 1:
					threat_hi += 1.0
				threat_seen = true
				confidence = float(f.get("conf", 0.35))
		if key == "arms" and "rifle" in text.to_lower():
			weapon_risk = 3.0 if is_known else 1.5
	if not threat_seen:
		unknown.append("armed threat")
	var threat_mid := (threat_lo + threat_hi) * 0.5
	var avg_exp := 1.0
	var avg_judgment := 55.0
	var armour := 0.0
	if n > 0:
		var exp_sum := 0.0
		var jud_sum := 0.0
		for r in officers:
			exp_sum += float(r.get("exp", 1))
			jud_sum += float(r.get("judgment", 55))
			var kit: Dictionary = r.get("kit", {})
			if String(kit.get("armour", "none")) in ["vest", "plates"]:
				armour += 1.0
		avg_exp = exp_sum / n
		avg_judgment = jud_sum / n
		armour /= n
	var force_delta := (float(n - want) * 4.0) if n > 0 else -28.0
	var quality_delta := (avg_exp - 1.0) * 3.0 + (avg_judgment - 60.0) * 0.08 + armour * 2.0
	var threat_delta := (threat_mid - float(EXPECTED_THREAT.get(typ, 2.0))) * 3.0
	var centre := float(BASE.get(typ, 50.0)) + force_delta + quality_delta - threat_delta - weapon_risk
	# Fewer confirmed facts and a smaller force widen the range. It is an index,
	# so clamp both ends rather than presenting a spurious percentage.
	var spread := 7.0 + float(unknown.size()) * 1.8 + (1.0 - confidence) * 7.0
	spread += maxf(0.0, 5.0 - float(n)) * 1.2
	if threat_hi > threat_lo:
		spread += (threat_hi - threat_lo) * 1.2
	var low := clampi(int(round(centre - spread)), 0, 100)
	var high := clampi(int(round(centre + spread)), 0, 100)
	var band := "under-supported"
	if centre >= 70.0:
		band = "well supported"
	elif centre >= 50.0:
		band = "contested"
	elif centre >= 30.0:
		band = "high risk"
	var assumptions: Array = ["%d officer%s assigned; planning baseline %d" % [n, "" if n == 1 else "s", want]]
	assumptions.append("Threat read: %s" % (_range_text(threat_lo, threat_hi) if threat_seen else "not established"))
	if weapon_risk > 0.0:
		assumptions.append("Long guns are mentioned in the public briefing")
	return {
		"low": low, "high": high, "score_low": low, "score_high": high,
		"band": band, "label": "READINESS %d–%d / 100  ·  %s" % [low, high, band],
		"range_text": "%d–%d / 100" % [low, high],
		"known": known, "unknown": unknown, "assumptions": assumptions,
		"note": "A planning index, not a win probability. Unconfirmed rooms, people and intent remain uncertain.",
		"assigned": n, "baseline": want,
	}


static func _numbers(text: String) -> Array:
	var out: Array = []
	var re := RegEx.new()
	re.compile("\\d+")
	for m in re.search_all(text):
		out.append(int(m.get_string()))
	return out


static func _range_text(lo: float, hi: float) -> String:
	if is_equal_approx(lo, hi):
		return "%d (confirmed or single estimate)" % int(lo)
	return "%d–%d estimated" % [int(lo), int(hi)]
