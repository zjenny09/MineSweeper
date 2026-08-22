class_name FirstMoveGuide
extends Control

const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const LIGHT_GREEN := Color("a3e086")
const INK := Color("1b2d22")
const WHITE := Color("ffffff")
const BUBBLE_SIZE := Vector2(310.0, 94.0)
const PANEL_PADDING := 16.0
const TARGET_GAP := 12.0

var target_cell_index := -1
var _target_cell: Control
var _keyboard_mode := false
var _animation_time := 0.0
var _bubble_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false
	_bubble_style = StyleBoxFlat.new()
	_bubble_style.bg_color = Color(WHITE, 0.97)
	_bubble_style.border_color = Color(GREEN, 0.92)
	_bubble_style.set_border_width_all(3)
	_bubble_style.set_corner_radius_all(22)
	_bubble_style.shadow_color = Color(INK, 0.15)
	_bubble_style.shadow_size = 7
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target_cell):
		hide_guide()
		return
	_animation_time += delta
	queue_redraw()


func show_for_cell(cell: Control, cell_index: int, keyboard_mode: bool) -> void:
	if not is_instance_valid(cell):
		hide_guide()
		return
	_target_cell = cell
	target_cell_index = cell_index
	_keyboard_mode = keyboard_mode
	_animation_time = 0.0
	visible = true
	queue_redraw()


func hide_guide() -> void:
	visible = false
	_target_cell = null
	target_cell_index = -1
	queue_redraw()


func set_keyboard_mode(enabled: bool) -> void:
	if _keyboard_mode == enabled:
		return
	_keyboard_mode = enabled
	queue_redraw()


func is_keyboard_mode() -> bool:
	return _keyboard_mode


func get_action_text() -> String:
	return "按 Z 从这里开始" if _keyboard_mode else "点这里开始第一次净化"


func get_stable_bubble_rect() -> Rect2:
	if not is_instance_valid(_target_cell) or size.x <= 1.0 or size.y <= 1.0:
		return Rect2()
	var target_rect := _control_rect_in_guide(_target_cell)
	var bubble_x := clampf(
		target_rect.get_center().x - BUBBLE_SIZE.x * 0.5,
		PANEL_PADDING,
		maxf(PANEL_PADDING, size.x - BUBBLE_SIZE.x - PANEL_PADDING)
	)
	var above_y := target_rect.position.y - BUBBLE_SIZE.y - TARGET_GAP
	var below_y := target_rect.end.y + TARGET_GAP
	var bubble_y := above_y
	if above_y < PANEL_PADDING and below_y + BUBBLE_SIZE.y <= size.y - PANEL_PADDING:
		bubble_y = below_y
	bubble_y = clampf(
		bubble_y,
		PANEL_PADDING,
		maxf(PANEL_PADDING, size.y - BUBBLE_SIZE.y - PANEL_PADDING)
	)
	return Rect2(Vector2(bubble_x, bubble_y), BUBBLE_SIZE)


func get_target_center() -> Vector2:
	if not is_instance_valid(_target_cell):
		return Vector2(-1.0, -1.0)
	return _control_rect_in_guide(_target_cell).get_center()


func _draw() -> void:
	if not visible or not is_instance_valid(_target_cell):
		return
	var bubble_rect := get_stable_bubble_rect()
	var target_rect := _control_rect_in_guide(_target_cell)
	if bubble_rect.size == Vector2.ZERO or target_rect.size == Vector2.ZERO:
		return

	draw_style_box(_bubble_style, bubble_rect)
	_draw_pointer(bubble_rect, target_rect)
	_draw_mascot(bubble_rect)
	_draw_copy(bubble_rect)


func _draw_target_halo(target_rect: Rect2) -> void:
	var pulse := 1.0 + 0.06 * sin(_animation_time * 3.0)
	var radius := maxf(target_rect.size.x, target_rect.size.y) * 0.58 * pulse
	draw_arc(
		target_rect.get_center(),
		radius,
		0.0,
		TAU,
		32,
		Color(YELLOW, 0.72),
		3.0,
		true
	)


func _draw_pointer(bubble_rect: Rect2, target_rect: Rect2) -> void:
	var bubble_above := bubble_rect.get_center().y < target_rect.get_center().y
	var anchor := Vector2(
		clampf(target_rect.get_center().x, bubble_rect.position.x + 28.0, bubble_rect.end.x - 28.0),
		bubble_rect.end.y if bubble_above else bubble_rect.position.y
	)
	var direction := Vector2.DOWN if bubble_above else Vector2.UP
	var bounce := (sin(_animation_time * 4.2) * 0.5 + 0.5) * 3.5
	var base_center := anchor + direction * bounce
	var arrow_tip := base_center + direction * 11.0
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		arrow_tip,
		base_center + perpendicular * 6.0,
		base_center - perpendicular * 6.0,
	])
	draw_colored_polygon(arrow, YELLOW)
	var outline := PackedVector2Array(arrow)
	outline.append(arrow[0])
	draw_polyline(outline, GREEN, 2.0, true)


func _draw_mascot(bubble_rect: Rect2) -> void:
	var bob := sin(_animation_time * 2.4) * 2.5
	var face_center := Vector2(
		bubble_rect.position.x + 47.0,
		bubble_rect.get_center().y + 5.0 + bob
	)
	_draw_leaf(face_center + Vector2(-9.0, -27.0), Vector2(18.0, 10.0), -0.55)
	_draw_leaf(face_center + Vector2(10.0, -29.0), Vector2(19.0, 10.0), 0.48)
	draw_circle(face_center, 25.0, LIGHT_GREEN)
	draw_arc(face_center, 25.0, 0.0, TAU, 28, GREEN, 2.5, true)
	draw_circle(face_center + Vector2(-8.0, -3.0), 2.6, INK)
	draw_circle(face_center + Vector2(8.0, -3.0), 2.6, INK)
	draw_arc(face_center + Vector2(0.0, 2.0), 8.0, 0.28, PI - 0.28, 12, INK, 2.0, true)


func _draw_leaf(center: Vector2, leaf_size: Vector2, rotation: float) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		var point := Vector2(cos(angle) * leaf_size.x * 0.5, sin(angle) * leaf_size.y * 0.5)
		points.append(center + point.rotated(rotation))
	draw_colored_polygon(points, GREEN)
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(INK, 0.65), 1.4, true)


func _draw_copy(bubble_rect: Rect2) -> void:
	var font := get_theme_default_font()
	var text_x := bubble_rect.position.x + 82.0
	var title_y := bubble_rect.position.y + 30.0
	var action_y := bubble_rect.position.y + 55.0
	var hint_y := bubble_rect.position.y + 78.0
	var title := "小芽带你到安全起点啦！" if _keyboard_mode else "小芽找到安全起点啦！"
	var action := get_action_text()
	draw_string(font, Vector2(text_x, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, 214.0, 16, GREEN)
	draw_string(font, Vector2(text_x, action_y), action, HORIZONTAL_ALIGNMENT_LEFT, 214.0, 15, INK)
	draw_string(font, Vector2(text_x, hint_y), "这是安全建议，也可以选择别处", HORIZONTAL_ALIGNMENT_LEFT, 214.0, 11, Color(INK, 0.68))


func _control_rect_in_guide(control: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	return Rect2(global_rect.position - get_global_rect().position, global_rect.size)
