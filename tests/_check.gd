extends SceneTree
## Compile every GDScript in scripts/, tests/ and tools/, recursively.
## A broken script may load as a resource but cannot be instantiated; checking
## only for null therefore misses parser and dependency errors.

var fails := 0
var scanned := 0


func _scan(path: String) -> void:
	var da := DirAccess.open(path)
	if da == null:
		print("FAILED  ", path, " does not open")
		fails += 1
		return
	for f in da.get_files():
		if not f.ends_with(".gd"):
			continue
		scanned += 1
		var script = load(path + "/" + f)
		if script == null or not script.can_instantiate():
			print("FAILED ", path, "/", f)
			fails += 1
	for sub in da.get_directories():
		if not sub.begins_with("."):
			_scan(path + "/" + sub)


func _init() -> void:
	for path in ["res://scripts", "res://tools", "res://tests"]:
		_scan(path)
	print("check done: %d scripts, %d failed" % [scanned, fails])
	quit(1 if fails > 0 else 0)
