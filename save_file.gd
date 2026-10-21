extends RefCounted
## Safe saves (1.0). A save is written to a temporary file, checked, then swapped in;
## the previous save is kept beside it as .bak. Loading falls back to the .bak when the
## save itself is missing or unreadable, so a crash mid-write never costs a campaign.


static func write_json(path: String, data: Dictionary) -> bool:
	var txt := JSON.stringify(data, "\t")
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(txt)
	f.close()
	# check it reads back whole before it replaces anything
	if typeof(_parse(FileAccess.get_file_as_string(tmp))) != TYPE_DICTIONARY:
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


## The save's data, or the backup's if the save is missing or damaged; null if neither.
static func read_json(path: String):
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var d = _parse(FileAccess.get_file_as_string(p))
		if typeof(d) == TYPE_DICTIONARY:
			return d
	return null


static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


static func erase(path: String) -> void:
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Parses quietly: a damaged file is an expected case here, not an engine error.
static func _parse(txt: String):
	var j := JSON.new()
	if j.parse(txt) != OK:
		return null
	return j.data
