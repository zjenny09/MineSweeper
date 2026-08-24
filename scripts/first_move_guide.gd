class_name FirstMoveGuide
extends Control

signal exit_requested
signal next_requested

const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const INK := Color("1b2d22")
const WHITE := Color("ffffff")
const BUBBLE_SIZE := Vector2(350.0, 122.0)
const PANEL_PADDING := 16.0
const TARGET_GAP := 12.0
const MASCOT_TEXTURE: Texture2D = preload("res://assets/ui/tutorial/guide_robot_avatar.png")

@onready var next_button: Button = %TutorialNextButton
@onready var exit_button: Button = %TutorialExitButton

var target_cell_index := -1
var _target_cell: Control
var _keyboard_mode := false
var _animation_time := 0.0
var _bubble_style: StyleBoxFlat
var _title_text := ""
var _action_text := ""
var _hint_text := ""
var _show_next_button := false


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
	for button in [next_button, exit_button]:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 12)
	next_button.pressed.connect(_on_next_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	resized.connect(_on_resized)


func _process(delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target_cell):
		hide_guide()
		return
	_animation_time += delta
	_update_button_layout()
	queue_redraw()


func show_for_cell(
	cell: Control,
	cell_index: int,
	keyboard_mode: bool,
	title_text: String = "",
	action_text: String = "",
	hint_text: String = "",
	show_next_button: bool = false
) -> void:
	if not is_instance_valid(cell):
		hide_guide()
		return
	_target_cell = cell
	target_cell_index = cell_index
	_keyboard_mode = keyboard_mode
	_title_text = title_text
	_action_text = action_text
	_hint_text = hint_text
	_show_next_button = show_next_button
	_animation_time = 0.0
	visible = true
	_update_button_layout()
	queue_redraw()


func hide_guide() -> void:
	visible = false
	_target_cell = null
	target_cell_index = -1
	next_button.visible = false
	exit_button.visible = false
	queue_redraw()


func set_keyboard_mode(enabled: bool) -> void:
	if _keyboard_mode == enabled:
		return
	_keyboard_mode = enabled
	queue_redraw()


func is_keyboard_mode() -> bool:
	return _keyboard_mode


func get_action_text() -> String:
	if not _action_text.is_empty():
		return _action_text
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
	var mascot_size := Vector2(68.0, 77.0)
	var mascot_center := Vector2(
		bubble_rect.position.x + 47.0,
		bubble_rect.position.y + 53.0 + bob
	)
	draw_texture_rect(
		MASCOT_TEXTURE,
		Rect2(mascot_center - mascot_size * 0.5, mascot_size),
		false
	)


func _draw_copy(bubble_rect: Rect2) -> void:
	var font := get_theme_default_font()
	var text_x := bubble_rect.position.x + 82.0
	var title_y := bubble_rect.position.y + 26.0
	var action_y := bubble_rect.position.y + 49.0
	var hint_y := bubble_rect.position.y + 70.0
	var title := _title_text
	if title.is_empty():
		title = "清扫者带你到安全起点啦！" if _keyboard_mode else "清扫者找到安全起点啦！"
	var hint := _hint_text if not _hint_text.is_empty() else "这是安全建议，也可以选择别处"
	draw_string(font, Vector2(text_x, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, 250.0, 16, GREEN)
	draw_string(font, Vector2(text_x, action_y), get_action_text(), HORIZONTAL_ALIGNMENT_LEFT, 250.0, 14, INK)
	draw_string(font, Vector2(text_x, hint_y), hint, HORIZONTAL_ALIGNMENT_LEFT, 250.0, 11, Color(INK, 0.68))


func _update_button_layout() -> void:
	if not visible or not is_instance_valid(_target_cell):
		next_button.visible = false
		exit_button.visible = false
		return
	var bubble_rect := get_stable_bubble_rect()
	if bubble_rect.size == Vector2.ZERO:
		return
	var button_y := bubble_rect.end.y - 34.0
	exit_button.position = Vector2(bubble_rect.end.x - 91.0, button_y)
	exit_button.size = Vector2(76.0, 25.0)
	exit_button.visible = true
	next_button.position = Vector2(bubble_rect.end.x - 169.0, button_y)
	next_button.size = Vector2(70.0, 25.0)
	next_button.visible = _show_next_button


func _on_resized() -> void:
	_update_button_layout()
	queue_redraw()


func _on_next_pressed() -> void:
	next_requested.emit()


func _on_exit_pressed() -> void:
	exit_requested.emit()


func _control_rect_in_guide(control: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	return Rect2(global_rect.position - get_global_rect().position, global_rect.size)
