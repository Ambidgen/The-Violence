extends SceneTree
## Renders one of the overhaul prototypes to a frame sequence (needs a display).
##   godot --path . --fixed-fps 30 -s res://tests/proto_capture.gd -- --which=topdown --secs=13 --out=/tmp/td [--every=1] [--stills=4,9,12]
## which: topdown | menu | cutscene. Frames are JPEG (frame_0001.jpg ...); stills PNG.

var view
var out := "user://proto"
var secs := 12.0
var every := 1
var stills: Array = []
var n := 0
var _t := 0.0


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	out = String(args.get("out", out))
	secs = float(args.get("secs", "12"))
	every = int(args.get("every", "1"))
	for s in String(args.get("stills", "")).split(",", false):
		stills.append(float(s))
	DirAccess.make_dir_recursive_absolute(out)
	var which := String(args.get("which", "topdown"))
	view = load("res://scripts/view/proto/%s_view.gd" % which).new()
	root.add_child(view)


func _process(delta: float) -> bool:
	_t += delta
	n += 1
	if n > 2:
		var img: Image = root.get_viewport().get_texture().get_image()
		if every > 0 and n % every == 0:
			img.save_jpg("%s/frame_%04d.jpg" % [out, n / every], 0.9)
		if not stills.is_empty() and _t >= float(stills[0]):
			img.save_png("%s/still_%05.2f.png" % [out, float(stills[0])])
			stills.pop_front()
	if _t >= secs:
		quit(0)
	return false
