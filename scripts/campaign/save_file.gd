extends RefCounted
## Safe saves (1.0). A save is written to a temporary file, checked, then swapped in;
## the previous save is kept beside it as .bak. Loading falls back to the .bak when the
## save itself is missing or unreadable, so a crash mid-write never costs a campaign.


static func write_json(path: String, data: Dictionary, preserve_backup := false) -> bool:
	# 4.72: JSON.stringify can fail on deeply nested data (e.g., recursive dept history)
	var txt := JSON.stringify(data, "\t")
	if txt == "":
		push_warning("SaveFile.write_json: stringify produced empty string for %s" % path)
		return false
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("SaveFile.write_json: open(%s) -> %s" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(txt)
	var flush_err := f.get_error()
	f.close()
	if flush_err != OK:
		DirAccess.remove_absolute(tmp)
		return false
	# 4.72: atomic check — file must parse back before we replace the good save
	var check_txt := FileAccess.get_file_as_string(tmp)
	if check_txt == "":
		DirAccess.remove_absolute(tmp)
		return false
	if typeof(_parse(check_txt)) != TYPE_DICTIONARY:
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if preserve_backup:
			# The primary was unreadable but .bak loaded: never rotate the bad
			# primary over the only known-good backup during recovery.
			if not FileAccess.file_exists(path + ".bak") or DirAccess.remove_absolute(path) != OK:
				DirAccess.remove_absolute(tmp)
				return false
		else:
			if FileAccess.file_exists(path + ".bak") and DirAccess.remove_absolute(path + ".bak") != OK:
				DirAccess.remove_absolute(tmp)
				return false
			var bak_err := DirAccess.rename_absolute(path, path + ".bak")
			if bak_err != OK:
				push_warning("SaveFile.write_json: rename to .bak failed: %d" % bak_err)
				DirAccess.remove_absolute(tmp)
				return false
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_warning("SaveFile.write_json: final rename failed: %d" % err)
	return err == OK


## The save's data, or the backup's if the save is missing or damaged; null if neither.
static func read_json(path: String):
	for p in [path, path + ".bak"]:
		var d = read_one_json(p)
		if d != null:
			return d
	return null


## Parse exactly one file. Campaign performs its own semantic validation before
## choosing between the primary and backup, not just a JSON syntax check.
static func read_one_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var d = _parse(FileAccess.get_file_as_string(path))
	return d if typeof(d) == TYPE_DICTIONARY else null


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
