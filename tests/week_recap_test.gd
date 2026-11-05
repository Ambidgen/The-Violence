extends SceneTree
## S15 Week Closed (2026-11-04): the recap end_week() leaves for the short. One situation
## answered with a known result, the rest left open: the recap must count exactly those,
## carry the account's movement over the week, and be filled for every prop the short
## draws. Also: the short exists, is native, and the setting defaults on.
##
## Run: godot --headless --path . -s res://tests/week_recap_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Shorts = preload("res://scripts/ui/shorts.gd")
const Settings = preload("res://scripts/ui/settings.gd")
const ViewScript = preload("res://scripts/view/crayon_short.gd")

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	print("== week recap (S15)")
	var c = Campaign.new()
	c.legacy_path = "user://week_recap_test_legacy.json"
	c.start(4242, true, c.legacy_path)
	var week0: int = c.dept.week
	_check(c.board.size() >= 2, "the board has at least two situations (%d)" % c.board.size())
	var first: Dictionary = c.board[0]
	c.record(first["id"], {"arrests": 2, "civ_killed": 1, "officers_killed": 0, "officers_hurt": 3})
	var open_n := 0
	for s in c.board:
		if s["status"] == "open":
			open_n += 1
	# patrol encounters settle at the week's end and add to the recap (tests/patrol_test.gd);
	# this test counts the board alone
	c.patrols = []
	var bal0: int = c.dept.balance
	c.end_week()
	var r: Dictionary = c.last_recap
	_check(not r.is_empty(), "end_week() leaves a recap")
	_check(int(r.get("week", -1)) == week0, "it is the week that closed (%s, want %d)" % [str(r.get("week")), week0])
	_check(int(r.get("answered", -1)) == 1, "one answered (%s)" % str(r.get("answered")))
	_check(int(r.get("unattended", -1)) == open_n, "%d unattended (%s)" % [open_n, str(r.get("unattended"))])
	_check(int(r.get("arrests", -1)) == 2 and int(r.get("civilians", -1)) == 1 and int(r.get("wounded", -1)) == 3,
		"the operation's arrests, civilians and hurt officers are carried (%s)" % str(r))
	_check(int(r.get("money", 0)) == c.dept.balance - bal0 and int(r.get("balance", 0)) == c.dept.balance,
		"the account's movement over the week (%d) and the balance after it" % int(r.get("money", 0)))
	_check(String(r.get("verdict", "")) == "ON THE RECORD", "a civilian killed stamps the week ON THE RECORD")
	var props: Dictionary = Shorts.entry("s15_week_recap").get("props", {})
	var missing: Array = []
	for k in props:
		if k != "showSlots" and not r.has(k):
			missing.append(k)
	_check(missing.is_empty(), "the recap fills every prop the short draws (missing: %s)" % str(missing))
	_check(Shorts.available("s15_week_recap") and Shorts.length("s15_week_recap") >= 5.0, "the short is in the manifest, 5 s or more")
	var view: Node2D = ViewScript.new()
	_check(bool(view.call("supports_short", "s15_week_recap")), "it has a native drawing")
	view.call("configure", "s15_week_recap", r, {}, 5.5)
	_check(view.get_child_count() == 1, "the drawing accepts the recap")
	view.free()
	_check(bool(Settings.DEFAULTS.get("week_recap", false)), "the setting defaults on")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(c.legacy_path))
	load("res://scripts/view/crayon_short_base.gd").set("_paper_cache", null)
	load("res://scripts/view/crayon.gd").set("font", null)
	print("week recap: %s" % ("PASS" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)
