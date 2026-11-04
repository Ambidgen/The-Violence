extends SceneTree
## Probe (1.3 playtest; EA_TASKS P1.B1): police on post at a public event, with and
## without a habit or a stress floor.
##
##   godot --headless --path . -s res://tests/event_probe.gd -- --n=20 --trauma=14 [--morale=60]
##       [--officers=2] [--habit=HD17] [--first=0] [--attack] [--json]
##
## Quiet events (default): nobody attacks. What matters is how many *distinct* people in
## the crowd police rounds struck (civ_struck), how many of them died (civ_killed_police),
## the misjudgments, and the shots. civ_hit_police is kept as the older round count.
## --attack: every event has one armed attacker who opens fire at t=300 s. What matters
## is that the police still answer: whether the attacker was stopped (stopped), how long
## after the attack began (stop_s), and how many bystanders the attacker hit
## (civ_struck_by_attacker) -- alongside the same police numbers.
## Seeds are 5000 + 17 * k for k in [first, first + n), the family the playtests used.
## --json prints one "EVENT {json}" line per event and a "TOTAL {json}" line.
## Exit 1 only if an event did not end (a probe: it does not judge the numbers).

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

const ATTACK_T := 300.0


func _run(seed_v: int, habits: Array, n_off: int, morale: int, trauma: float, attack: bool) -> Dictionary:
	var c = Campaign.new()
	c.start(1001)
	c.dept.morale = morale
	for r in c.dept.officers:
		r["trauma"] = maxf(float(r["trauma"]), trauma)
		for h in habits:
			if not (r["good"] as Array).has(h):
				r["good"].append(h)
	var s: Dictionary = Situations.make("event", seed_v, 12, 0, c.politics.trust, true)
	if attack:
		s["attack"] = true
		s["attack_t"] = ATTACK_T
		if not (s["occupants"] as Array).any(func(o): return String(o.get("role", "")) == "attacker"):
			s["occupants"].append({"role": "attacker", "name": "Probe Attacker", "ech": "militia", "arms": "pistol",
				"flight": 0.4, "alert": 0})
	else:
		s["attack"] = false
		s["attack_t"] = -1
	s["attack_p"] = 1.0 if attack else 0.0
	c.board = [s]
	var lv = Maps.get_level(int(s["map"]))
	var nav = Nav.new()
	nav.build(lv)
	var av: Array = c.available_for(s["id"]).slice(0, n_off)
	var plan: Dictionary = Autoplan.suggest(s, av, lv, false, n_off)
	s["plan"] = plan
	var b: Dictionary = Operation.build_planned(s, plan, c.dept, lv, nav)
	var w = World.new()
	w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
	var guard := 0
	var stop_t := -1.0
	while not w.over and guard < 60000:
		w.step()
		w.events.clear()
		guard += 1
		if attack and stop_t < 0.0 and w.attack_on:
			var any_up := false
			for o in w.ops:
				if o.attacker and o.alive() and not o.complying:
					any_up = true
			if not any_up:
				stop_t = w.t
	var police := {}
	var attackers := {}
	for o in w.ops:
		if o.judges:
			police[o.id] = true
		if o.attacker:
			attackers[o.id] = true
	var struck := {}
	var struck_att := {}
	var dead := {}
	for f in w.incident.findings:
		var tgt := String(f["target"])
		if attackers.has(tgt):
			continue
		match String(f["kind"]):
			"civilian_hit_by_police":
				struck[tgt] = true
			"civilian_hit_by_suspect":
				struck_att[tgt] = true
			"civilian_killed":
				dead[tgt] = true
	# a death is police-caused if police rounds struck that person: one who bleeds out
	# is recorded with no shooter, so the finding's "by" alone undercounts
	var killed_any := dead.size()
	var killed_police := 0
	for d in dead:
		if struck.has(d):
			killed_police += 1
	var sm: Dictionary = w.incident.summary()
	var out := {"seed": seed_v, "trauma": trauma, "morale": morale, "attack": attack, "attack_on": w.attack_on,
		"civ_struck": struck.size(), "civ_killed_police": killed_police, "civ_killed": killed_any,
		"civ_hit_police": int(sm["civ_hit_police"]), "police_shots": int(sm["police_shots"]),
		"misjudged": int(sm["misjudged"]), "sim_s": snappedf(w.t, 0.1), "ended": w.over}
	if attack:
		out["stopped"] = stop_t >= 0.0
		out["stop_s"] = snappedf(stop_t - ATTACK_T, 0.1) if stop_t >= 0.0 else -1.0
		out["civ_struck_by_attacker"] = struck_att.size()
	w.dispose()
	return out


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var n := int(args.get("n", "4"))
	var first := int(args.get("first", "0"))
	var habits: Array = String(args.get("habit", "")).split(",", false)
	var n_off := int(args.get("officers", "2"))
	var morale := int(args.get("morale", "60"))
	var trauma := float(args.get("trauma", "0"))
	var attack := args.has("attack")
	var as_json := args.has("json")
	var keys := ["civ_struck", "civ_killed_police", "civ_killed", "civ_hit_police", "police_shots", "misjudged"]
	var tot := {"events": 0, "events_with_struck": 0, "max_struck": 0, "hung": 0}
	for key in keys:
		tot[key] = 0
	if attack:
		tot["stopped"] = 0
		tot["civ_struck_by_attacker"] = 0
		tot["stop_s_sum"] = 0.0
	for k in range(first, first + n):
		var seed_v := 5000 + k * 17
		var r: Dictionary = _run(seed_v, habits, n_off, morale, trauma, attack)
		if as_json:
			print("EVENT ", JSON.stringify(r))
		else:
			print("seed %d: %s" % [seed_v, str(r)])
		tot["events"] += 1
		for key in keys:
			tot[key] += int(r[key])
		tot["events_with_struck"] += 1 if int(r["civ_struck"]) > 0 else 0
		tot["max_struck"] = maxi(int(tot["max_struck"]), int(r["civ_struck"]))
		tot["hung"] += 0 if bool(r["ended"]) else 1
		if attack:
			tot["stopped"] += 1 if bool(r["stopped"]) else 0
			tot["civ_struck_by_attacker"] += int(r["civ_struck_by_attacker"])
			if bool(r["stopped"]):
				tot["stop_s_sum"] += float(r["stop_s"])
	var head := {"habits": ",".join(habits), "officers": n_off, "morale": morale, "trauma": trauma, "attack": attack,
		"first": first, "n": n}
	head.merge(tot)
	if as_json:
		print("TOTAL ", JSON.stringify(head))
	else:
		print("TOTAL %s" % str(head))
	quit(1 if int(tot["hung"]) > 0 else 0)
