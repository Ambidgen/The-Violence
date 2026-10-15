extends SceneTree
## Debug trace: prints team A every TR_STEP sim seconds, plus the event log.
##   TR_STEP=0.5 godot --headless --path . -s res://tests/trace.gd -- --t=60 --a=sof --na=5 --b=militia --nb=5
const Teams = preload("res://tests/teams.gd")
const Level = preload("res://scripts/sim/level.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")


func _init() -> void:
	var opt := {"a": "sof", "b": "militia", "na": "5", "nb": "5", "t": "60", "seed": "7000", "pa": "assault", "pb": "hold", "log": "1"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2:
			opt[kv[0]] = kv[1]
	var step := float(OS.get_environment("TR_STEP")) if OS.get_environment("TR_STEP") != "" else 1.0
	var lv = Level.new()
	lv.build()
	var nav = Nav.new()
	nav.build(lv)
	var w = World.new()
	w.keep_events = false
	var cfgs: Array = Teams.team(lv, 0, {"n": int(opt["na"]), "ech": opt["a"]}) + Teams.team(lv, 1, {"n": int(opt["nb"]), "ech": opt["b"]})
	w.setup(lv, nav, cfgs, [opt["pa"], opt["pb"]], int(opt["seed"]))
	var next := 0.0
	var nlog := 0
	while not w.over and w.t < float(opt["t"]):
		w.step()
		if w.t >= next and step > 0.0:
			next += step
			var line := "%5.1f %-8s|" % [w.t, w.teams[0]["phase"]]
			for o in w.ops:
				if o.team != 0:
					continue
				line += " %s(%4.1f,%4.1f)%s %-14s|" % [o.id.substr(1), o.pos.x, o.pos.y, "" if o.alive() else "X", o.dbg.substr(0, 14)]
			print(line)
		if opt["log"] == "1":
			while nlog < w.log_lines.size():
				print("      ", w.log_lines[nlog]["text"])
				nlog += 1
	quit()
