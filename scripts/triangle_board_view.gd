class_name TriangleBoardView
extends Control

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)
signal chord_requested(cell_index: int)

const TOP_INSET := 20.0
const GRID_MARGIN := 4.0
const HIDDEN_UP_COLOR := Color("ffffff")
const HIDDEN_DOWN_COLOR := Color("f4fbf5")
const REVEALED_COLOR := Color("a3e086")
const GRID_LINE_COLOR := Color("469d65")
const KEYBOARD_CURSOR_COLOR := Color("fadf3c")
const WRONG_COLOR := Color("9b423d")
const SPROUT_TEXTURE: Texture2D = preload("res://assets/gameplay/markers/sprout_marker.png")
const SLIME_TEXTURE: Texture2D = preload("res://assets/gameplay/markers/pollution_slime.png")
const NUMBER_COLORS := {
	1: Color("315f8a"),
	2: Color("3d7547"),
	3: Color("a3473f"),
}

var row_count := 0
var column_count := 0
var cell_count := 0

var revealed_states: Array[bool] = []
var flagged_states: Array[bool] = []
var core_visible_states: Array[bool] = []
var adjacent_count_states: Array[int] = []
var wrong_flag_states: Array[bool] = []
var solved_core_states: Array[bool] = []
var locked_states: Array[bool] = []

var _triangle_points: Array[PackedVector2Array] = []
var _hovered_index := -1
var _side_length := 0.0
var _triangle_height := 0.0
var _board_origin := Vector2.ZERO
var _keyboard_cursor_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(_rebuild_geometry)
	_rebuild_geometry()


func setup(rows: int, columns: int) -> void:
	row_count = rows
	column_count = columns
	cell_count = row_count * column_count
	_resize_states()
	_rebuild_geometry()


func render_state(
	cell_index: int,
	is_revealed: bool,
	is_flagged: bool,
	core_visible: bool,
	adjacent_count: int,
	input_locked: bool,
	wrong_flag: bool = false,
	solved_core: bool = false
) -> void:
	if cell_index < 0 or cell_index >= cell_count:
		return
	revealed_states[cell_index] = is_revealed
	flagged_states[cell_index] = is_flagged
	core_visible_states[cell_index] = core_visible
	adjacent_count_states[cell_index] = adjacent_count
	locked_states[cell_index] = input_locked
	wrong_flag_states[cell_index] = wrong_flag
	solved_core_states[cell_index] = solved_core
	queue_redraw()


func set_keyboard_cursor(cell_index: int) -> void:
	var next_index := cell_index if cell_index >= 0 and cell_index < cell_count else -1
	if _keyboard_cursor_index == next_index:
		return
	_keyboard_cursor_index = next_index
	queue_redraw()


func get_keyboard_cursor() -> int:
	return _keyboard_cursor_index


func is_upward(cell_index: int) -> bool:
	if cell_index < 0 or cell_index >= cell_count:
		return false
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	return (row + column) % 2 == 0


func get_triangle_points(cell_index: int) -> PackedVector2Array:
	if cell_index < 0 or cell_index >= _triangle_points.size():
		return PackedVector2Array()
	return _triangle_points[cell_index]


func get_triangle_center(cell_index: int) -> Vector2:
	var points := get_triangle_points(cell_index)
	if points.size() != 3:
		return Vector2(-1.0, -1.0)
	return (points[0] + points[1] + points[2]) / 3.0


func get_cell_at_point(point: Vector2) -> int:
	for cell_index in _triangle_points.size():
		if Geometry2D.is_point_in_polygon(point, _triangle_points[cell_index]):
			return cell_index
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := get_cell_at_point((event as InputEventMouseMotion).position)
		if hovered != _hovered_index:
			_hovered_index = hovered
			queue_redraw()
		return

	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	var cell_index := get_cell_at_point(mouse_event.position)
	if cell_index < 0 or locked_states[cell_index]:
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and not revealed_states[cell_index]:
		flag_requested.emit(cell_index)
		accept_event()
	elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_event.double_click and revealed_states[cell_index] and adjacent_count_states[cell_index] > 0:
			chord_requested.emit(cell_index)
		elif not revealed_states[cell_index]:
			reveal_requested.emit(cell_index)
		accept_event()


func _draw() -> void:
	_draw_mountain_background()
	if _triangle_points.size() != cell_count:
		return

	for cell_index in cell_count:
		var points := _triangle_points[cell_index]
		var fill := HIDDEN_UP_COLOR if is_upward(cell_index) else HIDDEN_DOWN_COLOR
		if revealed_states[cell_index]:
			fill = REVEALED_COLOR
		if cell_index == _hovered_index and not locked_states[cell_index]:
			fill = fill.lightened(0.12)
		draw_colored_polygon(points, fill)
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, GRID_LINE_COLOR, 1.4, true)

		var center := get_triangle_center(cell_index)
		if wrong_flag_states[cell_index]:
			_draw_wrong_mark(center)
		elif core_visible_states[cell_index]:
			_draw_core(center)
		elif flagged_states[cell_index] or solved_core_states[cell_index]:
			_draw_flag(center)
		elif revealed_states[cell_index] and adjacent_count_states[cell_index] > 0:
			_draw_number(center, adjacent_count_states[cell_index])

		if cell_index == _keyboard_cursor_index:
			var cursor_outline := PackedVector2Array(points)
			cursor_outline.append(points[0])
			draw_polyline(cursor_outline, KEYBOARD_CURSOR_COLOR, 4.0, true)


func _draw_mountain_background() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("ffffff"))
	draw_circle(
		Vector2(size.x * 0.14, size.y * 0.92),
		minf(size.x, size.y) * 0.26,
		Color("a3e0862e")
	)
	draw_circle(
		Vector2(size.x * 0.88, size.y * 0.12),
		minf(size.x, size.y) * 0.18,
		Color("fadf3c24")
	)


func _draw_number(center: Vector2, number: int) -> void:
	var font := get_theme_default_font()
	var font_size := maxi(13, int(_side_length * 0.43))
	var text := str(number)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, NUMBER_COLORS.get(number, Color("334155")))


func _draw_flag(center: Vector2) -> void:
	_draw_marker_texture(center, SPROUT_TEXTURE, 0.64)


func _draw_core(center: Vector2) -> void:
	_draw_marker_texture(center, SLIME_TEXTURE, 0.70)


func _draw_marker_texture(center: Vector2, texture: Texture2D, size_factor: float) -> void:
	var available_size := Vector2(
		_side_length * size_factor,
		_triangle_height * size_factor
	)
	var texture_size := texture.get_size()
	var scale := minf(
		available_size.x / texture_size.x,
		available_size.y / texture_size.y
	)
	var marker_size := texture_size * scale
	draw_texture_rect(texture, Rect2(center - marker_size * 0.5, marker_size), false)


func _draw_wrong_mark(center: Vector2) -> void:
	var radius := maxf(4.0, _side_length * 0.14)
	draw_line(center - Vector2(radius, radius), center + Vector2(radius, radius), WRONG_COLOR, 2.5)
	draw_line(center + Vector2(radius, -radius), center + Vector2(-radius, radius), WRONG_COLOR, 2.5)


func _rebuild_geometry() -> void:
	_triangle_points.clear()
	if row_count <= 0 or column_count <= 0 or size.x <= 0.0 or size.y <= 0.0:
		queue_redraw()
		return

	var available_width := maxf(1.0, size.x - GRID_MARGIN * 2.0)
	var available_height := maxf(1.0, size.y - TOP_INSET - GRID_MARGIN)
	var width_limited_side := available_width * 2.0 / float(column_count + 1)
	var height_limited_side := available_height / (float(row_count) * sqrt(3.0) * 0.5)
	_side_length = minf(width_limited_side, height_limited_side)
	_triangle_height = _side_length * sqrt(3.0) * 0.5
	var board_size := Vector2(
		float(column_count + 1) * _side_length * 0.5,
		float(row_count) * _triangle_height
	)
	_board_origin = Vector2(
		(size.x - board_size.x) * 0.5,
		TOP_INSET + (available_height - board_size.y) * 0.5
	)

	for row in row_count:
		for column in column_count:
			var x := _board_origin.x + float(column) * _side_length * 0.5
			var y := _board_origin.y + float(row) * _triangle_height
			var points := PackedVector2Array()
			if (row + column) % 2 == 0:
				points.append(Vector2(x + _side_length * 0.5, y))
				points.append(Vector2(x, y + _triangle_height))
				points.append(Vector2(x + _side_length, y + _triangle_height))
			else:
				points.append(Vector2(x, y))
				points.append(Vector2(x + _side_length, y))
				points.append(Vector2(x + _side_length * 0.5, y + _triangle_height))
			_triangle_points.append(points)
	queue_redraw()


func _resize_states() -> void:
	revealed_states.resize(cell_count)
	revealed_states.fill(false)
	flagged_states.resize(cell_count)
	flagged_states.fill(false)
	core_visible_states.resize(cell_count)
	core_visible_states.fill(false)
	adjacent_count_states.resize(cell_count)
	adjacent_count_states.fill(0)
	wrong_flag_states.resize(cell_count)
	wrong_flag_states.fill(false)
	solved_core_states.resize(cell_count)
	solved_core_states.fill(false)
	locked_states.resize(cell_count)
	locked_states.fill(false)
