extends SceneTree
## The presentation pacing policy (EA_TASKS P1.G1 and P1.G2), without an operation: a few
## lines of arithmetic that decide how fast a run is watched and when it may be skipped.
##
##   godot --headless --path . -s res://tests/pacing_test.gd
##
## Gates:
##   G1  contact-aware fast-forward is the default and runs BOTH ways: quiet is
##       QUIET_MULT times the speed asked for (capped), contact returns to 1x, a player
##       who asks for 1x keeps 1x, and the setting off changes nothing.
##   G1  the policy is presentation only: it cannot return a speed the simulation sees,
##       and hold_seconds gives a casualty longer than radio.
##   G2  "skip to the report" is offered after QUIET_SKIP_AFTER simulated seconds of
##       quiet, not one frame early.
##   G1  the setting exists, defaults on, and the front-end toggle writes it.
##
## Exit: 1 if a gate fails.

const Pacing = preload("res://scripts/sim/pacing.gd")
const Settings = preload("res://scripts/ui/settings.gd")

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _nn(v: float) -> String:
	return String.num(v, 2)


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	# ---- G1: the policy, both ways
	var quiet2: float = Pacing.speed_for(2.0, 100.0, 0.0, true)
	_check(is_equal_approx(quiet2, minf(2.0 * Pacing.QUIET_MULT, Pacing.QUIET_CAP)),
		"quiet at 2x requested plays at %sx (mult %s, cap %s)" % [_nn(quiet2), _nn(Pacing.QUIET_MULT), _nn(Pacing.QUIET_CAP)])
	var contact: float = Pacing.speed_for(2.0, 100.0, 106.0, true)
	_check(is_equal_approx(contact, 1.0), "inside a contact hold it returns to 1x (got %sx)" % _nn(contact))
	var slow_capped: float = Pacing.speed_for(8.0, 100.0, 106.0, true)
	_check(is_equal_approx(slow_capped, 1.0), "even at 8x asked for, contact is 1x (got %sx)" % _nn(slow_capped))
	var fast_capped: float = Pacing.speed_for(8.0, 100.0, 0.0, true)
	_check(fast_capped <= maxf(8.0, Pacing.QUIET_CAP), "quiet at 8x stays inside the cap (got %sx)" % _nn(fast_capped))
	var one_x: float = Pacing.speed_for(1.0, 100.0, 0.0, true)
	_check(is_equal_approx(one_x, 1.0), "1x asked for is 1x: a deliberate choice is never sped up (got %sx)" % _nn(one_x))
	var off: float = Pacing.speed_for(2.0, 100.0, 106.0, false)
	_check(is_equal_approx(off, 2.0), "with the setting off nothing changes (got %sx)" % _nn(off))
	_check(Pacing.speed_for(2.0, 100.0, 106.0, true) < Pacing.speed_for(2.0, 100.0, 0.0, true),
		"contact is slower than quiet at the same requested speed")
	_check(Pacing.hold_seconds("casualty") > Pacing.hold_seconds("shots fired"),
		"a casualty holds 1x for longer than radio (%s vs %s s)" % [_nn(Pacing.hold_seconds("casualty")), _nn(Pacing.hold_seconds("shots fired"))])

	# ---- G2: the skip offer's arithmetic
	_check(not Pacing.quiet_enough(Pacing.QUIET_SKIP_AFTER - 0.5), "59.5 s of quiet is not enough to skip")
	_check(Pacing.quiet_enough(Pacing.QUIET_SKIP_AFTER), "60 s of quiet is")
	_check(Pacing.quiet_enough(Pacing.QUIET_SKIP_AFTER + 30.0), "and 90 s is")

	# ---- G1: the setting is on by default and reachable from the front-end
	_check(Settings.DEFAULTS.get("adaptive_speed", false) == true,
		"contact-aware fast-forward is on by default")
	var front := FileAccess.get_file_as_string("res://scripts/ui/front.gd")
	_check(front.contains("adaptive_speed"), "the settings screen still offers the toggle")

	print("pacing test: %s (%d ms)" % ["ALL OK" if fails == 0 else "%d FAILURES" % fails, Time.get_ticks_msec() - t0])
	quit(1 if fails > 0 else 0)
