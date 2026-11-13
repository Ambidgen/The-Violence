extends Node2D
## Loader for the two native short illustration sheets.

const OFFICE_VIEW := preload("res://scripts/view/crayon_short_office.gd")
const CIVIC_VIEW := preload("res://scripts/view/crayon_short_civic.gd")
const OFFICE_KEYS := [
	"s01_week",
	"s02_situation",
	"s03_plan",
	"s04_staging",
	"s05_threshold",
	"s06_officer_down",
	"s07_debrief",
	"s15_week_recap"
]
const CIVIC_KEYS := [
	"s08_press",
	"s09_case",
	"s10_ally",
	"s11_election",
	"s12_end_of_watch",
	"s13_allocation",
	"s14_course"
]

var renderer: Node2D


func supports_short(short_key: String) -> bool:
	return short_key in OFFICE_KEYS or short_key in CIVIC_KEYS


func configure(
	short_key: String, short_props: Dictionary, slot_text: Dictionary, length: float
) -> void:
	if not supports_short(short_key):
		return
	if is_instance_valid(renderer):
		renderer.hide()
		renderer.queue_free()
	var renderer_script: Script = OFFICE_VIEW if short_key in OFFICE_KEYS else CIVIC_VIEW
	renderer = renderer_script.new() as Node2D
	renderer.call("configure", short_key, short_props, slot_text, length)
	add_child(renderer)
