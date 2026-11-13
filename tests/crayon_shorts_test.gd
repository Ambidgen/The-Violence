extends SceneTree
## Headless smoke test for the native shorts: every manifest key must resolve, instantiate
## its correct crayon view, accept manifest props/slots, and expose a positive duration.

const Shorts = preload("res://scripts/ui/shorts.gd")
const ViewScript = preload("res://scripts/view/crayon_short.gd")


func _init() -> void:
	var entries := Shorts.entries()
	if entries.size() != 15:
		_fail("expected 15 shorts, got %d" % entries.size())
		return
	for entry: Dictionary in entries:
		var key := String(entry.get("key", ""))
		if not Shorts.available(key):
			_fail("short unavailable: %s" % key)
			return
		var duration := Shorts.length(key)
		if duration < 5.0 or duration > 10.0:
			_fail("short has invalid duration %s: %.2f" % [key, duration])
			return
		var view: Node2D = ViewScript.new()
		if not bool(view.call("supports_short", key)):
			_fail("short has no native drawing: %s" % key)
			view.free()
			return
		view.call(
			"configure", key, entry.get("props", {}), {"title": "LIVE CAMPAIGN TEXT"}, duration
		)
		if view.get_child_count() != 1:
			_fail("short renderer did not select a scene: %s" % key)
			view.free()
			return
		view.free()
	print("CRAYON_SHORTS_OK count=%d" % entries.size())
	# The shorts cache one paper texture and one font on their scripts; quitting with them
	# held makes the engine report "N resources still in use at exit", which fails the
	# suite. ui_walk releases the same caches for the same reason.
	load("res://scripts/view/crayon_short_base.gd").set("_paper_cache", null)
	load("res://scripts/view/crayon.gd").set("font", null)
	quit(0)


func _fail(message: String) -> void:
	push_error("crayon_shorts_test: " + message)
	quit(1)
