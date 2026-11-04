extends SceneTree
## Cutscene/prototype frame capture for CI review (companion to proto_capture.gd).
##
## proto_capture.gd renders the overhaul prototypes for local use; this harness is the
## stricter, machine-checkable version the cutscene-capture workflow runs under Xvfb:
## it fails loudly (exit 1) when the view cannot be loaded or no still was written,
## and it drops a capture.json manifest next to the stills so the contact-sheet step
## (tools/make_contact_sheet.py) and reviewers can see what was asked for.
##
## Needs a display (Xvfb in CI counts). --headless will capture nothing useful:
## the headless RenderingServer is a dummy and the viewport texture stays blank,
## which this harness reports as an error rather than succeeding on black frames.
##
##   xvfb-run -a godot --path . --fixed-fps 30 -s res://tests/cutscene_capture.gd -- \
##       --which=cutscene --secs=12 --stills=1,4,8,11.5 --out=build/cutscene-captures/cutscene
##
## Args (all optional):
##   --which=cutscene|menu|topdown   prototype view (scripts/view/proto/<which>_view.gd)
##   --scene=res://path/to/view.gd    explicit view script; overrides --which
##   --short=s01_week                configure and capture one native crayon campaign short
##   --secs=12                        seconds of fixed-fps time to run
##   --stills=1,4,8                   comma-separated times (s) to save as PNG stills
##   --every=0                        also save a JPG every N frames (0 = stills only)
##   --out=build/...                  output folder (absolute, or relative to res://)

var view: Node = null
var out_dir := ""
var secs := 12.0
var every := 0
var stills: Array = []
var frame_count := 0
var elapsed := 0.0
var saved_stills: Array = []
var saved_frames := 0
var failed := false


func _init() -> void:
	var args: Dictionary = {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"

	out_dir = String(args.get("out", "build/cutscene-captures/cutscene"))
	if out_dir.begins_with("res://"):
		out_dir = ProjectSettings.globalize_path(out_dir)
	elif not out_dir.is_absolute_path():
		out_dir = ProjectSettings.globalize_path("res://" + out_dir)
	secs = maxf(0.5, float(args.get("secs", "12")))
	every = int(args.get("every", "0"))
	for s in String(args.get("stills", "1,4,8")).split(",", false):
		stills.append(float(s))
	stills.sort()

	var short_key := String(args.get("short", ""))
	var scene_path := String(args.get("scene", ""))
	if short_key != "":
		scene_path = "res://scripts/view/crayon_short.gd"
	elif scene_path == "":
		var which := String(args.get("which", "cutscene"))
		scene_path = "res://scripts/view/proto/%s_view.gd" % which

	var err := DirAccess.make_dir_recursive_absolute(out_dir)
	if err != OK:
		push_error("cutscene_capture: cannot create output dir %s (err %d)" % [out_dir, err])
		failed = true
		return

	var script: Resource = load(scene_path)
	if script == null:
		push_error("cutscene_capture: cannot load view script %s" % scene_path)
		failed = true
		return
	view = script.new()
	if view == null:
		push_error("cutscene_capture: %s did not construct a view" % scene_path)
		failed = true
		return
	if short_key != "":
		var manifest_file := FileAccess.open(
			"res://assets/cutscenes/shorts/shorts.json", FileAccess.READ
		)
		var manifest: Dictionary = (
			JSON.parse_string(manifest_file.get_as_text()) if manifest_file != null else {}
		)
		var short_entry: Dictionary = {}
		for candidate in manifest.get("shorts", []):
			if String(candidate.get("key", "")) == short_key:
				short_entry = candidate
				break
		if short_entry.is_empty():
			push_error("cutscene_capture: unknown short key %s" % short_key)
			failed = true
			return
		if not args.has("secs"):
			secs = float(short_entry.get("seconds", secs))
		view.call("configure", short_key, short_entry.get("props", {}), {}, secs)
		if not args.has("stills"):
			stills = [1.0, minf(4.0, secs * 0.5), maxf(0.5, secs - 0.5)]
			stills.sort()
	root.add_child(view)


func _process(delta: float) -> bool:
	if failed:
		quit(1)
		return true
	elapsed += delta
	frame_count += 1
	# Let the view draw a couple of frames before trusting the viewport texture.
	if frame_count > 2:
		var img: Image = root.get_viewport().get_texture().get_image()
		if img == null or img.is_empty():
			var message := "cutscene_capture: viewport texture is empty at frame %d " % frame_count
			push_error(message + "(running headless? use Xvfb, not --headless)")
			failed = true
			quit(1)
			return true
		if every > 0 and frame_count % every == 0:
			saved_frames += 1
			img.save_jpg("%s/frame_%04d.jpg" % [out_dir, saved_frames], 0.9)
		while not stills.is_empty() and elapsed >= float(stills[0]):
			var at: float = float(stills.pop_front())
			var path := "%s/still_%06.2fs.png" % [out_dir, at]
			var serr: Error = img.save_png(path)
			if serr != OK:
				push_error("cutscene_capture: save_png(%s) failed (err %d)" % [path, serr])
				failed = true
				quit(1)
				return true
			saved_stills.append({"at": at, "file": path.get_file()})
	if elapsed >= secs:
		_finish()
		return true
	return false


func _finish() -> void:
	if saved_stills.is_empty():
		push_error("cutscene_capture: no stills saved in %.1fs — nothing to review" % secs)
		quit(1)
		return
	var manifest: Dictionary = {
		"harness": "tests/cutscene_capture.gd",
		"viewport":
		(
			"%dx%d"
			% [
				int(root.get_viewport().get_visible_rect().size.x),
				int(root.get_viewport().get_visible_rect().size.y)
			]
		),
		"secs": secs,
		"frames": frame_count,
		"stills": saved_stills,
	}
	var f := FileAccess.open(out_dir + "/capture.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(manifest, "  "))
		f.close()
	print(
		(
			"cutscene_capture: %d still(s), %d frames -> %s"
			% [saved_stills.size(), frame_count, out_dir]
		)
	)
	quit(0)
