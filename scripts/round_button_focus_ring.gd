extends Control

const DASH_COUNT := 16
const DASH_FILL := 0.58
const RING_COLOR := Color("f3e7a1")

var _button: BaseButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button = get_parent() as BaseButton
	resized.connect(queue_redraw)
	set_process(true)
	_update_visibility()


func _process(_delta: float) -> void:
	_update_visibility()


func _draw() -> void:
	if _button == null:
		return
	var unit := minf(size.x, size.y)
	var center := size * 0.5
	var radius := unit * 0.365
	var line_width := maxf(2.0, unit * 0.026)
	var segment_angle := TAU / float(DASH_COUNT)
	for dash_index in range(DASH_COUNT):
		var start_angle := float(dash_index) * segment_angle
		var end_angle := start_angle + segment_angle * DASH_FILL
		draw_arc(
			center,
			radius,
			start_angle,
			end_angle,
			6,
			RING_COLOR,
			line_width,
			true
		)


func _update_visibility() -> void:
	if _button == null:
		visible = false
		return
	var should_show := (
		not _button.disabled
		and (_button.is_hovered() or _button.has_focus() or _button.button_pressed)
	)
	if visible == should_show:
		return
	visible = should_show
	if visible:
		queue_redraw()
