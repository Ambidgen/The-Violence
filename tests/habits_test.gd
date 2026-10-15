extends SceneTree
## Tier 0 #2 -- the habit coverage report.
##
## Cross-checks the effect registry in scripts/data/habits.gd against the call
## sites in the simulation. It answers three questions that are otherwise only
## answerable by reading two thousand lines of brain:
##
##   * which habits are declared but never referenced?   (not implemented)
##   * which habits have exactly one call site?          (inert outside one branch
##     of the priority ladder -- the PF07 class of bug, where the habit only fired
##     inside Rule 1 and so did nothing at all beyond 10 m)
##   * which hook points does nothing claim?             (dead code paths)
##
##   godot --headless --path . -s res://tests/habits_test.gd [--strict] [--csv]
##
## --strict exits non-zero when a habit with declared hooks has no call site.

const Habits = preload("res://scripts/data/habits.gd")

const SCAN_DIRS := ["res://scripts/sim", "res://scripts/city"]

var _src := {}          # file -> text
var _sites := {}        # habit id -> ["file:line", ...]
var _files := {}        # habit id -> {"file": true}
var _re: RegEx


func _load(path: String) -> String:
	if not _src.has(path):
		var f := FileAccess.open(path, FileAccess.READ)
		_src[path] = "" if f == null else f.get_as_text()
		if f != null:
			f.close()
	return _src[path]


func _scan_dir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			pass
		elif n.ends_with(".gd"):
			_scan_file(path.path_join(n))
		elif DirAccess.dir_exists_absolute(path.path_join(n)):
			_scan_dir(path.path_join(n))
		n = d.get_next()
	d.list_dir_end()


func _scan_file(path: String) -> void:
	var text := _load(path)
	if text == "":
		return
	var short: String = path.get_file()
	var lines := text.split("\n")
	for i in lines.size():
		var line: String = lines[i]
		var found := false
		for m in _re.search_all(line):
			var a: String = m.get_string(1)
			var b: String = m.get_string(2)
			var hid: String = a if a != "" else b
			if hid == "":
				continue
			if not _sites.has(hid):
				_sites[hid] = []
				_files[hid] = {}
			(_sites[hid] as Array).append("%s:%d" % [short, i + 1])
			(_files[hid] as Dictionary)[short] = true
			found = true
		if found:
			pass


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var strict := "--strict" in args
	var csv := "--csv" in args

	_re = RegEx.new()
	# has("PF07") / hb("BH01") / bad.get("TR01", false) / traits.get("TR01", false)
	_re.compile('(?:has|hb)\\(\\s*"([A-Z]{2}\\d{2})"\\s*\\)|(?:bad|traits)\\.get\\(\\s*"([A-Z]{2}\\d{2})"')
	for d in SCAN_DIRS:
		_scan_dir(d)

	var rows: Array = []
	for g in Habits.GOOD:
		rows.append(_row(g["id"], g["name"], g["group"], "good"))
	for b in Habits.BAD:
		rows.append(_row(b["id"], b["name"], str(b.get("kind", "trait")), "bad"))
	for tr in Habits.TRAITS:
		rows.append(_row(tr["id"], tr["name"], str(tr["kind"]), "trait"))

	if csv:
		print("id,name,group,kind,hooks,sites,files")
		for r in rows:
			print("%s,\"%s\",%s,%s,%d,%d,%d" % [r["id"], r["name"], r["group"], r["kind"],
				r["hooks"], r["sites"], r["files"]])
		quit()
		return

	print("")
	print("HABIT COVERAGE  (registry in scripts/data/habits.gd vs call sites in scripts/sim, scripts/city)")
	print("================================================================================")
	print("%-5s %-26s %-12s %-20s %5s  %s" % ["ID", "NAME", "GROUP", "HOOKS", "SITES", "WHERE"])
	print("--------------------------------------------------------------------------------")
	for r in rows:
		print("%-5s %-26s %-12s %-20s %5d  %s" % [r["id"], r["name"].substr(0, 26),
			r["group"].substr(0, 12), r["hooks_s"].substr(0, 20), r["sites"],
			", ".join(r["where"]).substr(0, 34)])
	print("--------------------------------------------------------------------------------")

	var none: Array = []
	var single: Array = []
	for r in rows:
		if int(r["sites"]) == 0:
			none.append(r)
		elif int(r["sites"]) == 1:
			single.append(r)

	var problems: Array = []
	print("")
	print("declared habits  : %d" % rows.size())
	print("with a call site : %d" % (rows.size() - none.size()))
	if none.size() > 0:
		var pure: Array = []
		var missing: Array = []
		for r in none:
			if int(r["hooks"]) == 0:
				pure.append(r["id"])
			else:
				missing.append(r["id"])
		print("")
		if pure.size() > 0:
			print("  no call site and no hooks declared (pure suspension habits):")
			print("     %s" % ", ".join(pure))
		if missing.size() > 0:
			print("  !! hooks declared but NOT implemented: %s" % ", ".join(missing))
			problems.append_array(missing)
	if single.size() > 0:
		print("")
		print("  exactly one call site -- check it is not inert outside one branch:")
		for r in single:
			print("     %-5s %-26s  %s" % [r["id"], r["name"].substr(0, 26), ", ".join(r["where"])])

	var unused: Array = Habits.hooks_unused()
	if unused.size() > 0:
		print("")
		print("  hook points nothing claims: %s" % ", ".join(unused))

	print("")
	if problems.is_empty():
		print("OK: every habit with declared hooks has at least one call site.")
		quit()
		return
	print("FAIL: %d habit(s) declared but not implemented." % problems.size())
	quit(1 if strict else 0)


func _row(hid: String, nm: String, grp: String, kind: String) -> Dictionary:
	var hooks: Array = Habits.hooks_of(hid)
	var where: Array = []
	if _sites.has(hid):
		where = (_sites[hid] as Array).duplicate()
	var nf := 0
	if _files.has(hid):
		nf = (_files[hid] as Dictionary).size()
	return {"id": hid, "name": nm, "group": grp, "kind": kind, "hooks": hooks.size(),
		"hooks_s": ",".join(hooks), "sites": where.size(), "where": where, "files": nf}
