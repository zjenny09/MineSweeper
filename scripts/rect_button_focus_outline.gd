extends Control

const OUTLINE_COLOR := Color("f2c94c")
const DASH_LENGTH_RATIO := 0.075

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
	var line_width := maxf(2.0, unit * 0.026)
	var inset := maxf(10.0, unit * 0.14)
	var left := inset
	var top := inset
	var right := maxf(left, size.x - inset)
	var bottom := maxf(top, size.y - inset)
	var dash_length := maxf(5.0, unit * DASH_LENGTH_RATIO)
	for segment in [
		[Vector2(left, top), Vector2(right, top)],
		[Vector2(right, top), Vector2(right, bottom)],
		[Vector2(right, bottom), Vector2(left, bottom)],
		[Vector2(left, bottom), Vector2(left, top)],
	]:
		draw_dashed_line(
			segment[0],
			segment[1],
			OUTLINE_COLOR,
			line_width,
			dash_length,
			true,
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
