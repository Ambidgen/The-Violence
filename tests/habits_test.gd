extends SceneTree
## The habit coverage check (ported in spirit from the parallel line, v0.7.8).
##
## Cross-checks every habit in scripts/data/habits.gd against the code that reads it, so
## a habit can no longer be silently unimplemented:
##
##   * a good habit nothing reads                          -> FAIL (not implemented)
##   * a bad habit nothing reads, not declared a pure suspension below -> FAIL
##   * a habit read at exactly one place                   -> listed (check it is not inert
##     outside one branch: the parallel line's PF07 only fired inside 10 m)
##   * an id in an "over" list or an echelon preset that does not exist -> FAIL
##
##   godot --headless --path . -s res://tests/habits_test.gd [--strict] [--sites]
##
## --strict exits non-zero on any FAIL; --sites prints every call site.

const Habits = preload("res://scripts/data/habits.gd")

## Behaviour only: the campaign and the UI name habits as data (personalities, rosters).
const SCAN_DIRS := ["res://scripts/sim"]

## Bad habits whose whole effect is suspending good habits (their "over" list): no call
## site of their own is expected. Each needs its reason. Anything a bad habit's
## description says it DOES beyond suspending must have a call site instead.
const PURE_SUSPENSION := {
	"BH08": "comms blackout: no callouts (GD04), status (GD08) or re-sectoring (GD09) is the whole habit",
	"BH17": "skip the checks: the suspension of WD01/WD02/WD04 is the whole habit",
	"BH21": "first sight, first shot: without HD08-HD10 the ambush opens on the first silhouette",
}

var _sites := {}     # id -> ["file:line"]


func _scan_dir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not n.begins_with("."):
			var p := path.path_join(n)
			if n.ends_with(".gd"):
				_scan_file(p)
			elif DirAccess.dir_exists_absolute(p):
				_scan_dir(p)
		n = d.get_next()
	d.list_dir_end()


func _scan_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var lines := f.get_as_text().split("\n")
	f.close()
	var re := RegEx.new()
	re.compile("\"((?:PF|GD|ED|WD|HD|BH)\\d\\d)\"")
	for i in lines.size():
		var line: String = lines[i]
		var code := line.split("#")[0] if not line.strip_edges().begins_with("##") else ""
		for m in re.search_all(code):
			var hid := m.get_string(1)
			if not _sites.has(hid):
				_sites[hid] = []
			(_sites[hid] as Array).append("%s:%d" % [path.get_file(), i + 1])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var strict := "--strict" in args
	var show_sites := "--sites" in args
	for dpath in SCAN_DIRS:
		_scan_dir(dpath)
	var good: Array = Habits.good_ids()
	var bad: Array = Habits.bad_ids()
	var known := {}
	for g in good + bad:
		known[g] = true
	var fails: Array = []
	var single: Array = []
	var suspension: Array = []
	for g in good:
		var n: int = _sites.get(g, []).size()
		if n == 0:
			fails.append("%s %s: a good habit nothing reads" % [g, Habits.good_info(g).get("name", "")])
		elif n == 1:
			single.append("%s %s (%s)" % [g, Habits.good_info(g).get("name", ""), _sites[g][0]])
	for b in bad:
		var info: Dictionary = Habits.bad_info(b)
		var n2: int = _sites.get(b, []).size()
		for o in info.get("over", []):
			if not known.has(o):
				fails.append("%s suspends %s, which does not exist" % [b, o])
		if n2 == 0:
			if PURE_SUSPENSION.has(b):
				suspension.append("%s %s: %s" % [b, info.get("name", ""), PURE_SUSPENSION[b]])
			elif info.get("over", []).is_empty():
				fails.append("%s %s: a bad habit that neither suspends nor does anything" % [b, info.get("name", "")])
			else:
				fails.append("%s %s: no call site, and not declared a pure suspension (\"%s\")" % [b, info.get("name", ""), info.get("desc", "")])
		elif PURE_SUSPENSION.has(b):
			fails.append("%s is declared a pure suspension but has call sites: %s" % [b, ", ".join(_sites[b])])
		elif n2 == 1:
			single.append("%s %s (%s)" % [b, info.get("name", ""), _sites[b][0]])
	for ech in Habits.PRESET_GOOD:
		for g2 in Habits.preset_good(ech):
			if not known.has(g2):
				fails.append("preset %s names %s, which does not exist" % [ech, g2])
	for hid in _sites:
		if not known.has(hid):
			fails.append("%s is read at %s but is not a habit" % [hid, _sites[hid][0]])
	print("habits: %d good, %d bad; %d ids read in %s" % [good.size(), bad.size(), _sites.size(), ", ".join(SCAN_DIRS)])
	if show_sites:
		var ids: Array = _sites.keys()
		ids.sort()
		for hid2 in ids:
			print("  %s  %d  %s" % [hid2, _sites[hid2].size(), ", ".join(_sites[hid2])])
	print("\npure suspensions (%d):" % suspension.size())
	for s in suspension:
		print("  " + s)
	print("\nread at one place only (%d): check each is not inert outside that branch" % single.size())
	for s2 in single:
		print("  " + s2)
	print("\nFAIL (%d):" % fails.size())
	for f in fails:
		print("  " + f)
	if fails.is_empty():
		print("  none")
	quit(1 if strict and not fails.is_empty() else 0)
