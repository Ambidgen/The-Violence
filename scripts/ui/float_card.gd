extends PanelContainer
## A paper card that floats over the city map or the floor plan (campaign UI, 2026-11-03).
## It replaces the old right-hand side panel: every campaign choice is shown in one of
## these. Drag it by its title bar, fold it to the bar with "–", close it with "×".
## The card sizes itself to its content, up to the height of the window.

signal close_pressed
signal help_toggled(on: bool)

const UI = preload("res://scripts/ui/ui.gd")
const C = preload("res://scripts/view/crayon.gd")
const Icons = preload("res://scripts/ui/icons.gd")
const INK := Color("#1e1b1c")
const RED := Color("#ff2b30")

var width := 460.0
var title_label: Label
var collapse_btn: Button
var close_btn: Button
var help_btn: Button
var scroll: ScrollContainer
var bar: HBoxContainer
var collapsed := false
var min_top := 8.0       # the card never rises above this (the HUD lives above it)
var max_frac := 1.0      # at most this share of the window's height: a popup, not a panel
var bottom_gap := -1.0   # >= 0: the card's bottom edge sits this far above the window's
                         # bottom (over an operation, just above the bar) until dragged
var closable := true
var _drag := false
var _drag_off := Vector2.ZERO
var _last_min := -1.0


func setup(content: Control) -> void:
	add_theme_stylebox_override("panel", UI._sb(Color("#fbf7ec"), INK, 2, 10.0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	bar = HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	bar.custom_minimum_size = Vector2(0, 30)
	bar.gui_input.connect(_bar_input)
	v.add_child(bar)
	title_label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", INK)
	bar.add_child(title_label)
	help_btn = _bar_btn("help", "Explain: show the notes on this card")
	help_btn.toggle_mode = true
	help_btn.toggled.connect(func(on): help_toggled.emit(on))
	collapse_btn = _bar_btn("fold", "Fold the card to its title bar (or unfold it)")
	collapse_btn.pressed.connect(func(): set_collapsed(not collapsed))
	close_btn = _bar_btn("close", "Close")
	close_btn.pressed.connect(func(): close_pressed.emit())
	var rule := ColorRect.new()
	rule.color = Color(RED, 0.85)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(width - 24.0, 80.0)
	v.add_child(scroll)
	scroll.add_child(content)


func _bar_btn(icon_id: String, tip: String) -> Button:
	var b := Button.new()
	b.icon = Icons.tex(icon_id, 18)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(30, 26)
	b.add_theme_font_size_override("font_size", 16)
	bar.add_child(b)
	return b


func set_title(t: String) -> void:
	title_label.text = t
	title_label.tooltip_text = t


func set_closable(on: bool) -> void:
	closable = on
	close_btn.visible = on


func set_width(w: float) -> void:
	width = w
	scroll.custom_minimum_size.x = w - 24.0
	_last_min = -1.0


func set_collapsed(on: bool) -> void:
	collapsed = on
	scroll.visible = not on
	collapse_btn.icon = Icons.tex("unfold" if on else "fold", 18)
	_last_min = -1.0
	_refit()


## Folds open again and scrolls back to the top: a new screen in the same card.
func reset_scroll() -> void:
	scroll.scroll_vertical = 0
	scroll.scroll_horizontal = 0
	_last_min = -1.0


func _max_h() -> float:
	var vp := get_viewport_rect().size
	# title bar, rule and the paper's margins come on top of the scrolled content
	return maxf(120.0, minf(vp.y - min_top - 8.0 - 66.0, vp.y * max_frac - 66.0))


func _process(_delta: float) -> void:
	if not visible or collapsed or scroll.get_child_count() == 0:
		return
	var inner := scroll.get_child(0) as Control
	var want := clampf(inner.get_combined_minimum_size().y + 6.0, 60.0, _max_h())
	if absf(want - _last_min) > 0.5:
		_last_min = want
		scroll.custom_minimum_size.y = want
		_refit()


func _refit() -> void:
	reset_size()
	keep_on_screen()


func keep_on_screen() -> void:
	var vp := get_viewport_rect().size
	var s := get_combined_minimum_size()
	if bottom_gap >= 0.0 and not has_meta("moved"):
		position.y = vp.y - s.y - bottom_gap
	position.x = clampf(position.x, 8.0, maxf(8.0, vp.x - s.x - 8.0))
	position.y = clampf(position.y, min_top, maxf(min_top, vp.y - s.y - 8.0))


func _bar_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := ev as InputEventMouseButton
		if mb.double_click:
			set_collapsed(not collapsed)
			return
		_drag = mb.pressed
		_drag_off = get_global_mouse_position() - global_position
		accept_event()
	elif ev is InputEventMouseMotion and _drag:
		global_position = get_global_mouse_position() - _drag_off
		keep_on_screen()
		set_meta("moved", true)
		accept_event()
