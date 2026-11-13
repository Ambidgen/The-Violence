extends SceneTree
## Roster UI smoke test: the weekly applicant pool is visible and hiring through its
## buttons updates the department and rebuilds the roster without stale callbacks.
##   godot --headless --path . -s res://tests/ops_ui_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const OpsUI = preload("res://scripts/ui/ops_ui.gd")
const Front = preload("res://scripts/ui/front.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const Patrol = preload("res://scripts/campaign/patrol.gd")
const FRONT_TEST_PATH := "user://front_ui_test.json"

var fails := 0


class FakeMain:
	var campaign
	var changes := 0
	var _placeholder := true
	var cutscene = null

	func ops_dept_changed() -> void:
		changes += 1

	# the patrol radio (2026-11-11): what main.ops_patrol does for a call settled on the desk
	var ui = null
	func ops_patrol(pid: String, choice: int) -> void:
		var out: Dictionary = campaign.decide_patrol(pid, choice, false)
		ui.open_radio(out["lines"])


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
	await _radio()
	await _election()
	print("ops ui test: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
	quit(1 if fails > 0 else 0)


func _labels(n: Node, out: Array = []) -> Array:
	if n is Label and (n as Label).is_visible_in_tree():
		out.append(String((n as Label).text))
	for child in n.get_children():
		_labels(child, out)
	return out


## The patrol radio in the map UI (trunk merge, 2026-11-11): a button on the HUD and a row
## on the week's card open the radio's own card; an answer comes back to it with the next
## day's call; and the week's report folds the calls where nothing happened into one line.
func _radio() -> void:
	print("  -- the patrol radio")
	Campaign.read_city_file = false
	var c = Campaign.new()
	c.start(4242)
	var main = FakeMain.new()
	main.campaign = c
	var ui = OpsUI.new()
	root.add_child(ui)
	ui.build(main)
	main.ui = ui
	ui.open_week()
	await process_frame
	var n0: int = Patrol.pending(c.patrols).size()
	_check(n0 == Patrol.PER_WEEK, "a new week has a call a day waiting (%d)" % n0)
	_check(ui.hud_radio.visible and ui.hud_radio.text == str(n0), "the HUD's radio shows how many (%s)" % ui.hud_radio.text)
	_check(_labels(ui.box).any(func(t): return t.begins_with("Patrol radio")), "the week's card has a row for the radio")
	_check(not _buttons(ui.box).any(func(b): return String(b.get_meta("label", "")) == "Wait for backup"), "and no longer carries the radio's answers itself")
	ui.hud_radio.pressed.emit()
	await process_frame
	var answers: Array = _buttons(ui.box).filter(func(b): return String(b.get_meta("label", "")) in ["Proceed", "Proceed, backup en route", "Wait for backup"])
	_check(answers.size() == 3 and String(ui.card.title_label.text).begins_with("PATROL RADIO"), "the radio opens as its own card with the three answers (%d)" % answers.size())
	_check(_labels(ui.box).any(func(t): return t.ends_with("waiting for your answer")), "the week's list marks the day that is waiting")
	if answers.size() == 3:
		answers[0].pressed.emit()
		await process_frame
		_check(Patrol.pending(c.patrols).size() == n0 - 1, "an answer settles that day's call")
		_check(String(ui.card.title_label.text).begins_with("PATROL RADIO") and ui.hud_radio.text == str(n0 - 1), "and comes back to the radio, with one fewer waiting (%s)" % ui.hud_radio.text)
		_check(_buttons(ui.box).any(func(b): return String(b.get_meta("label", "")) == "Proceed"), "where the next day's call is already up")
	# the week ends with the rest unanswered: the report says so once
	var lines: Array = c.end_week()
	var folded: Array = ui._fold_patrol(lines)
	var quiet_n: int = c.last_patrol_quiet_n
	_check(quiet_n > 0 and folded.size() == lines.size() - c.last_patrol_quiet.size() + 1, "the week's report folds %d routine calls into one line (%d lines to %d)" % [quiet_n, lines.size(), folded.size()])
	_check(folded.any(func(l): return String(l).begins_with("Patrol radio: %d call" % quiet_n)), "and that line says how many")
	var kept := true
	var rest: Array = lines.duplicate()
	for q in c.last_patrol_quiet:
		rest.erase(q)
	for l in rest:
		kept = kept and folded.has(l)
	_check(kept, "every other line of the report is still there, a call where someone was hurt included")
	c.last_patrol_quiet = []
	_check(ui._fold_patrol(lines) == lines, "with nothing routine to fold, the report is untouched")
	ui.queue_free()


## Election night in the map UI (trunk merge, 2026-11-11): the last week's card is the
## ending, with the score's arithmetic (P1.F3), drawn over the city like every other card.
func _election() -> void:
	print("  -- election night")
	Campaign.read_city_file = false
	var c = Campaign.new()
	c.start(31, true)
	var guard := 0
	var lines: Array = []
	while not c.over() and guard < 60:
		guard += 1
		if c.run != null:       # the End week button waits for the desk; the campaign itself does not
			c.run.drafts.clear()
			c.run.offers.clear()
			c.run.events.clear()
		lines = c.end_week()
	_check(c.over(), "forty weeks with nobody sent anywhere still reach the election (week %d)" % c.week())
	if not c.over():
		return
	var main = FakeMain.new()
	main.campaign = c
	var ui = OpsUI.new()
	root.add_child(ui)
	ui.build(main)
	main.ui = ui
	ui.show_board(lines)
	await process_frame
	var seen: Array = _labels(ui.box)
	_check(String(ui.card.title_label.text).begins_with("ELECTION NIGHT"), "the last card is election night")
	_check(seen.any(func(t): return t.begins_with("RUN SCORE")) and seen.any(func(t): return t.begins_with("Total")), "with the run score and its arithmetic")
	_check(seen.any(func(t): return t.contains("Carrick") and t.contains("Noussan") and t.contains("Stevens")), "and the count names Carrick, Noussan and Stevens")
	_check(not ui.hud_radio.visible or not ui.hud.visible, "the radio is off the HUD once the campaign is over")
	ui.queue_free()
