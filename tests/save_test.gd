extends SceneTree
## Safe saves (1.0): the backup is kept, a damaged save falls back to it, and a missing
## save with a backup still loads.
##   godot --headless --path . -s res://tests/save_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const PATH := "user://save_test.json"

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	SaveFile.erase(PATH)
	var c = Campaign.new()
	c.start(4242)
	check(c.save(PATH), "first save writes")
	check(not FileAccess.file_exists(PATH + ".bak"), "no backup after the first save")
	var w1: int = c.week()
	c.dept.balance += 1234
	check(c.save(PATH), "second save writes")
	check(FileAccess.file_exists(PATH + ".bak"), "the previous save is kept as .bak")
	check(not FileAccess.file_exists(PATH + ".tmp"), "no temporary file left behind")
	var c2 = Campaign.load_from(PATH)
	check(c2 != null and c2.dept.balance == c.dept.balance, "the save loads with the latest balance")
	# damage the save: half a file
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{\"version\": 2, \"week\"")
	f.close()
	var c3 = Campaign.load_from(PATH)
	check(c3 != null and c3.dept.balance == c.dept.balance - 1234 and c3.week() == w1, "a damaged save falls back to the backup")
	DirAccess.remove_absolute(PATH)
	check(Campaign.load_from(PATH) != null and SaveFile.exists(PATH), "a missing save with a backup still loads")
	SaveFile.erase(PATH)
	check(Campaign.load_from(PATH) == null and not SaveFile.exists(PATH), "erase removes everything")
	print("save_test: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
