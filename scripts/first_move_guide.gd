@tool
class_name FirstMoveGuide
extends Control

signal exit_requested
signal next_requested

const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const INK := Color("1b2d22")
const PANEL_PADDING := 16.0
const TARGET_GAP := 12.0

@export var editor_preview := true

@onready var bubble_root: Control = %GuideBubbleRoot
@onready var mascot: TextureRect = %GuideMascot
@onready var title_label: Label = %GuideTitle
@onready var action_label: Label = %GuideAction
@onready var hint_label: Label = %GuideHint
@onready var next_button_artwork: TextureRect = %NextButtonArtwork
@onready var exit_button_artwork: TextureRect = %ExitButtonArtwork
@onready var next_button: Button = %TutorialNextButton
@onready var exit_button: Button = %TutorialExitButton

var target_cell_index := -1
var _target_cell: Control
var _keyboard_mode := false
var _animation_time := 0.0
var _title_text := ""
var _action_text := ""
var _hint_text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_apply_text_styles()
	_apply_button_styles()
	next_button.pressed.connect(_on_next_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	resized.connect(_on_resized)
	if Engine.is_editor_hint():
		_title_text = "小芽带你到安全起点啦！"
		_action_text = "点这里开始第一次净化"
		_hint_text = "这是安全建议，也可以选择别处"
		visible = editor_preview
		_refresh_copy()
		call_deferred("_update_bubble_position")
		return
	visible = false


func _apply_text_styles() -> void:
	title_label.add_theme_color_override("font_color", GREEN)
	title_label.add_theme_font_size_override("font_size", 17)
	action_label.add_theme_color_override("font_color", INK)
	action_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(INK, 0.68))
	hint_label.add_theme_font_size_override("font_size", 11)


func _apply_button_styles() -> void:
	var empty_style := StyleBoxEmpty.new()
	for button in [next_button, exit_button]:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", empty_style)
		button.add_theme_stylebox_override("hover", empty_style)
		button.add_theme_stylebox_override("pressed", empty_style)
		button.add_theme_stylebox_override("disabled", empty_style)
		button.add_theme_stylebox_override("focus", empty_style)
	next_button.add_theme_color_override("font_color", Color("315f36"))
	next_button.add_theme_color_override("font_hover_color", Color("315f36"))
	next_button.add_theme_color_override("font_pressed_color", Color("315f36"))
	exit_button.add_theme_color_override("font_color", Color("5b4935"))
	exit_button.add_theme_color_override("font_hover_color", Color("5b4935"))
	exit_button.add_theme_color_override("font_pressed_color", Color("5b4935"))


func _process(delta: float) -> void:
	if not visible:
		return
	if Engine.is_editor_hint():
		_update_bubble_position()
		return
	if not is_instance_valid(_target_cell):
		hide_guide()
		return
	_animation_time += delta
	_update_bubble_position()
	queue_redraw()


func show_for_cell(
	cell: Control,
	cell_index: int,
	keyboard_mode: bool,
	title_text: String = "",
	action_text: String = "",
	hint_text: String = "",
	_show_next_button: bool = false
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
	_animation_time = 0.0
	visible = true
	_refresh_copy()
	_update_bubble_position()
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
	_refresh_copy()


func is_keyboard_mode() -> bool:
	return _keyboard_mode


func get_action_text() -> String:
	if not _action_text.is_empty():
		return _action_text
	return "按 Z 从这里开始" if _keyboard_mode else "点这里开始第一次净化"


func get_stable_bubble_rect() -> Rect2:
	if not is_instance_valid(bubble_root) or size.x <= 1.0 or size.y <= 1.0:
		return Rect2()
	var bubble_size := bubble_root.size
	if Engine.is_editor_hint():
		return Rect2((size - bubble_size) * 0.5, bubble_size)
	if not is_instance_valid(_target_cell):
		return Rect2()
	var target_rect := _control_rect_in_guide(_target_cell)
	var bubble_x := clampf(
		target_rect.get_center().x - bubble_size.x * 0.5,
		PANEL_PADDING,
		maxf(PANEL_PADDING, size.x - bubble_size.x - PANEL_PADDING)
	)
	var above_y := target_rect.position.y - bubble_size.y - TARGET_GAP
	var below_y := target_rect.end.y + TARGET_GAP
	var bubble_y := above_y
	if above_y < PANEL_PADDING and below_y + bubble_size.y <= size.y - PANEL_PADDING:
		bubble_y = below_y
	bubble_y = clampf(
		bubble_y,
		PANEL_PADDING,
		maxf(PANEL_PADDING, size.y - bubble_size.y - PANEL_PADDING)
	)
	return Rect2(Vector2(bubble_x, bubble_y), bubble_size)


func get_target_center() -> Vector2:
	if not is_instance_valid(_target_cell):
		return Vector2(-1.0, -1.0)
	return _control_rect_in_guide(_target_cell).get_center()


func _update_bubble_position() -> void:
	var bubble_rect := get_stable_bubble_rect()
	if bubble_rect.size == Vector2.ZERO:
		return
	bubble_root.position = bubble_rect.position


func _refresh_copy() -> void:
	var title := _title_text
	if title.is_empty():
		title = "小芽带你到安全起点啦！" if _keyboard_mode else "小芽找到安全起点啦！"
	title_label.text = title
	action_label.text = get_action_text()
	hint_label.text = _hint_text if not _hint_text.is_empty() else "这是安全建议，也可以选择别处"
	next_button.visible = true
	next_button.disabled = false
	exit_button.visible = true
	next_button_artwork.visible = true
	exit_button_artwork.visible = true


func _draw() -> void:
	if Engine.is_editor_hint() or not visible or not is_instance_valid(_target_cell):
		return
	var bubble_rect := Rect2(bubble_root.position, bubble_root.size)
	var target_rect := _control_rect_in_guide(_target_cell)
	if target_rect.size == Vector2.ZERO:
		return
	_draw_pointer(bubble_rect, target_rect)


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


func _on_resized() -> void:
	_update_bubble_position()
	queue_redraw()


func _on_next_pressed() -> void:
	next_requested.emit()


func _on_exit_pressed() -> void:
	exit_requested.emit()


func _control_rect_in_guide(control: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	return Rect2(global_rect.position - get_global_rect().position, global_rect.size)
