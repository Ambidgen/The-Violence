extends SceneTree
## Roster UI smoke test: the weekly applicant pool is visible and hiring through its
## buttons updates the department and rebuilds the roster without stale callbacks.
##   godot --headless --path . -s res://tests/ops_ui_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const OpsUI = preload("res://scripts/ui/ops_ui.gd")
const Front = preload("res://scripts/ui/front.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const FRONT_TEST_PATH := "user://front_ui_test.json"

var fails := 0


class FakeMain:
	var campaign
	var changes := 0
	var _placeholder := true
	var cutscene = null

	func ops_dept_changed() -> void:
		changes += 1


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _buttons(n: Node, out: Array = []) -> Array:
	if n is Button:
		out.append(n)
	for child in n.get_children():
		_buttons(child, out)
	return out


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Campaign.read_city_file = false
	var c = Campaign.new()
	c.start(99)
	var main = FakeMain.new()
	main.campaign = c
	var ui = OpsUI.new()
	root.add_child(ui)
	ui.build(main)
	ui.show_board()
	await process_frame
	_check(ui.city_map.visible and ui.city_map.situations.size() == c.board.size(), "the board displays this week's canonical city pins")
	_check(OpsUI._ward_label({"city_error": true}) == "ward unavailable", "an unlocated call does not display fabricated ward trust")
	ui._roster()
	await process_frame
	# EA_TASKS P3.A1 (2026-11-03): management screens sit over the city, not the last tactical map
	_check(ui.city_map.visible, "the city overview stays behind the other management screens (P3.A1)")

	var pool: Array = c.dept.applicants_now()
	var hire: Array = _buttons(ui.box).filter(func(b): return String(b.text).begins_with("Hire  $"))
	_check(pool.size() >= 2 and hire.size() == pool.size(), "one Hire button for each of the %d visible applicants" % pool.size())
	_check(_buttons(ui.box).all(func(b): return not String(b.text).begins_with("Hire a recruit") and not String(b.text).begins_with("Hire laterally")),
		"the removed blind-hire buttons stay removed")
	if not hire.is_empty():
		var before: int = c.dept.officers.size()
		var chosen: Dictionary = pool[0]
		hire[0].pressed.emit()
		await process_frame
		_check(c.dept.officers.size() == before + 1 and c.dept.officers.has(chosen), "clicking Hire adds the chosen applicant to the roster")
		_check(chosen["status"] in ["academy", "active"] and String(chosen["id"]).begins_with("PC-"), "the hire reports to the academy or duty with a department id")
		_check(c.dept.applicants_now().is_empty(), "the unchosen applicants walk after one hire")
		_check(main.changes == 1, "the UI propagates one department change")

	# EA_TASKS P1.F3: election night's score breakdown is the arithmetic, not a grey line
	var sc := {"total": -158, "kept": true, "clean": false,
		"parts": {"successes": 60, "arrests": 9, "failures": -16, "officers killed": -50,
			"civilians killed": -80, "civilians hit": -36, "suspects killed": -30,
			"excessive force": -20, "unattended": -15, "the election": 20},
		"clean_line": {"officers_killed": 2, "civilians_killed": 2, "findings": 5,
			"needs": {"officers_killed": 2, "civilians_killed": 6, "findings": 6}}}
	var rows: Array = OpsUI.score_breakdown(sc)
	_check(rows.size() == 10, "every scoring part that moved is a row (%d of 10)" % rows.size())
	_check(rows.all(func(r): return String(r.get("label", "")) != "" and String(r.get("why", "")) != ""),
		"every row says what it is and why")
	_check(rows.back()["key"] == "the election" and int(rows.back()["amount"]) == 20,
		"the election row carries its own amount (+%d)" % int(rows.back()["amount"]))
	_check(String(rows.back()["why"]).contains("2 of 2") and String(rows.back()["why"]).contains("5 of 6"),
		"and says which line of the clean-record test was missed: %s" % String(rows.back()["why"]))
	var zeroed := OpsUI.score_breakdown({"total": 0, "parts": {"successes": 0, "arrests": 0}, "kept": false, "clean_line": {}})
	_check(zeroed.size() == 1 and int(zeroed[0]["amount"]) == 0, "a run with nothing in it says so in one row")
	var sum := 0
	for r in rows:
		sum += int(r["amount"])
	_check(sum == int(sc["total"]), "the rows add up to the total (%d)" % sum)

	c.dept.next_week()
	ui._roster()
	await process_frame
	_check(not c.dept.applicants_now().is_empty(), "a fresh applicant pool appears the next week")
	ui.queue_free()
	await process_frame
	# An unreadable or newer save must not masquerade as a playable placeholder.
	SaveFile.erase(FRONT_TEST_PATH)
	var front := Front.new()
	front.build(main)
	front._campaign_save_path = FRONT_TEST_PATH
	root.add_child(front)
	_check(front._campaign_summary().is_empty(), "an empty save slot offers no continue")
	_check(SaveFile.write_json(FRONT_TEST_PATH, {"version": Campaign.VERSION + 1}), "the unreadable-save UI fixture writes")
	var future_save := FileAccess.get_file_as_string(FRONT_TEST_PATH)
	_check(front._campaign_summary().get("unreadable", false), "a placeholder with an existing unreadable save is identified")
	front.show_title()
	await process_frame
	var continue_count := 0
	for b in _buttons(front.root, []):
		if b.text.begins_with("Continue run"):
			continue_count += 1
	_check(continue_count == 0, "an unreadable save never offers a fake Continue")
	front._new_campaign_ask()
	_check(front.screen == "confirm_new" and FileAccess.get_file_as_string(FRONT_TEST_PATH) == future_save,
		"starting over an unreadable save requires confirmation without changing the file")
	_check(c.save(FRONT_TEST_PATH), "the valid-save UI fixture writes")
	main._placeholder = false
	_check(front._campaign_summary().get("exists", false), "a loaded campaign still offers Continue")
	front._new_campaign_ask()
	_check(front.screen == "confirm_new", "an in-progress loaded campaign still asks before replacement")
	front.queue_free()
	SaveFile.erase(FRONT_TEST_PATH)
	print("ops ui test: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
	quit(1 if fails > 0 else 0)
