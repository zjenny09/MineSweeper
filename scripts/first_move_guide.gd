@tool
class_name FirstMoveGuide
extends Control

signal exit_requested
signal next_requested
signal dialogue_completed(dialogue_id: StringName)

const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const INK := Color("1b2d22")
const PANEL_PADDING := 16.0
const TARGET_GAP := 12.0

@export var editor_preview := true

@onready var bubble_root: Control = %GuideBubbleRoot
@onready var character_rig: Control = %GuideCharacterRig
@onready var mascot: TextureRect = %GuideMascot
@onready var claw: TextureRect = %GuideClaw
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
var _show_next_button := false
var _action_blank := false
var _hint_blank := false
var _hint_layout_y := 89.0
var _action_layout_y := 62.0
var _dialogue_mode := false
var _dialogue_id := &""
var _dialogue_pages: Array[Dictionary] = []
var _dialogue_page_index := 0
var _dialogue_button_key := ""
var _dialogue_target_global_position := Vector2(INF, INF)
var _has_dialogue_target := false
var _pointer_vertices := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _pointer_outline := PackedVector2Array([
	Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO
])


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_apply_text_styles()
	_apply_button_styles()
	_apply_locale_layout()
	next_button.pressed.connect(_on_next_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	resized.connect(_on_resized)
	if Engine.is_editor_hint():
		_title_text = "TXT_0241"
		_action_text = "TXT_0244"
		_hint_text = "TXT_0246"
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


func _apply_locale_layout() -> void:
	var english := TranslationServer.get_locale().begins_with("en")
	if english:
		bubble_root.size = Vector2(560.0, 212.0)
		character_rig.position = Vector2(22.0, 60.0)
		character_rig.size = Vector2(100.0, 72.0)
		mascot.size = Vector2(64.0, 64.0)
		claw.size = Vector2(32.0, 32.0)
		title_label.position = Vector2(116.0, 22.0)
		title_label.size = Vector2(418.0, 30.0)
		action_label.position = Vector2(116.0, 56.0)
		action_label.size = Vector2(418.0, 66.0)
		action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.position = Vector2(116.0, 126.0)
		_hint_layout_y = 126.0
		_action_layout_y = 56.0
		hint_label.size = Vector2(418.0, 34.0)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		next_button_artwork.position = Vector2(258.0, 168.0)
		next_button_artwork.size = Vector2(132.0, 34.0)
		next_button.position = next_button_artwork.position
		next_button.size = next_button_artwork.size
		exit_button_artwork.position = Vector2(400.0, 168.0)
		exit_button_artwork.size = Vector2(132.0, 34.0)
		exit_button.position = exit_button_artwork.position
		exit_button.size = exit_button_artwork.size
		return
	bubble_root.size = Vector2(484.0, 175.853)
	character_rig.position = Vector2(24.0, 43.0)
	character_rig.size = Vector2(100.0, 72.0)
	mascot.size = Vector2(64.0, 64.0)
	claw.size = Vector2(32.0, 32.0)
	title_label.position = Vector2(116.0, 31.0)
	title_label.size = Vector2(340.0, 26.0)
	action_label.position = Vector2(116.0, 62.0)
	action_label.size = Vector2(340.0, 22.0)
	action_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint_label.position = Vector2(116.0, 89.0)
	_hint_layout_y = 89.0
	_action_layout_y = 62.0
	hint_label.size = Vector2(340.0, 34.0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	next_button_artwork.position = Vector2(220.0, 119.5)
	next_button_artwork.size = Vector2(108.0, 32.0)
	next_button.position = next_button_artwork.position
	next_button.size = next_button_artwork.size
	exit_button_artwork.position = Vector2(332.0, 122.92651)
	exit_button_artwork.size = Vector2(108.0, 27.0)
	exit_button.position = Vector2(332.0, 115.5)
	exit_button.size = Vector2(108.0, 40.0)


func _process(delta: float) -> void:
	if not visible:
		return
	if Engine.is_editor_hint():
		_update_bubble_position()
		return
	if _dialogue_mode:
		_animation_time += delta
		_update_bubble_position()
		queue_redraw()
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
	show_next_button: bool = false
) -> void:
	if not is_instance_valid(cell):
		hide_guide()
		return
	_target_cell = cell
	target_cell_index = cell_index
	_dialogue_mode = false
	_dialogue_id = &""
	_dialogue_pages.clear()
	_dialogue_page_index = 0
	_clear_dialogue_target()
	_keyboard_mode = keyboard_mode
	_title_text = title_text
	_action_text = action_text
	_hint_text = hint_text
	_action_blank = action_text.strip_edges().is_empty()
	_hint_blank = hint_text.strip_edges().is_empty()
	_show_next_button = show_next_button
	_animation_time = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
	_refresh_copy()
	_update_bubble_position()
	queue_redraw()


func show_dialogue(
	dialogue_id: StringName,
	pages: Array,
	keyboard_mode: bool = false,
	target: Variant = null
) -> void:
	if dialogue_id.is_empty() or pages.is_empty():
		return
	_dialogue_pages.clear()
	for page in pages:
		if page is Dictionary:
			_dialogue_pages.append((page as Dictionary).duplicate(true))
	if _dialogue_pages.is_empty():
		return
	_target_cell = null
	target_cell_index = -1
	_dialogue_mode = true
	_dialogue_id = dialogue_id
	_dialogue_page_index = 0
	_assign_dialogue_target(target)
	_keyboard_mode = keyboard_mode
	_animation_time = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
	_update_dialogue_page()
	_update_bubble_position()
	queue_redraw()


func is_dialogue_mode() -> bool:
	return _dialogue_mode


func set_dialogue_target(target: Variant) -> void:
	if not _dialogue_mode:
		return
	_assign_dialogue_target(target)
	_update_bubble_position()
	queue_redraw()


func _clear_dialogue_target() -> void:
	_dialogue_target_global_position = Vector2(INF, INF)
	_has_dialogue_target = false


func _assign_dialogue_target(target: Variant) -> void:
	_target_cell = null
	_clear_dialogue_target()
	if target is Control and is_instance_valid(target):
		_target_cell = target
	elif target is Vector2 and is_finite(target.x) and is_finite(target.y):
		_dialogue_target_global_position = target
		_has_dialogue_target = true


func _has_target() -> bool:
	return is_instance_valid(_target_cell) or (_dialogue_mode and _has_dialogue_target)


func _target_rect_in_guide() -> Rect2:
	if is_instance_valid(_target_cell):
		return _control_rect_in_guide(_target_cell)
	return Rect2(
		get_global_transform().affine_inverse() * _dialogue_target_global_position,
		Vector2.ZERO
	)


func complete_dialogue() -> void:
	if _dialogue_mode:
		_complete_dialogue()


func hide_guide() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_cell = null
	target_cell_index = -1
	_dialogue_mode = false
	_dialogue_id = &""
	_dialogue_pages.clear()
	_dialogue_page_index = 0
	_clear_dialogue_target()
	queue_redraw()


func set_keyboard_mode(enabled: bool) -> void:
	if _keyboard_mode == enabled:
		return
	_keyboard_mode = enabled
	if _dialogue_mode:
		_update_dialogue_page()
	else:
		_refresh_copy()


func is_keyboard_mode() -> bool:
	return _keyboard_mode


func get_action_text() -> String:
	if not _action_text.is_empty():
		return tr(_action_text)
	if _action_blank:
		return ""
	return tr("TXT_0245") if _keyboard_mode else tr("TXT_0244")


func refresh_localized_text() -> void:
	_apply_locale_layout()
	_refresh_copy()
	_update_bubble_position()
	queue_redraw()


func get_stable_bubble_rect() -> Rect2:
	if not is_instance_valid(bubble_root) or size.x <= 1.0 or size.y <= 1.0:
		return Rect2()
	var bubble_size := bubble_root.size
	if Engine.is_editor_hint():
		return Rect2((size - bubble_size) * 0.5, bubble_size)
	if not _has_target():
		if not _dialogue_mode:
			return Rect2()
		return Rect2(
			Vector2(maxf(PANEL_PADDING, (size.x - bubble_size.x) * 0.5), PANEL_PADDING),
			bubble_size
		)
	return _bubble_rect_near_target(_target_rect_in_guide(), bubble_size)


func _bubble_rect_near_target(target_rect: Rect2, bubble_size: Vector2) -> Rect2:
	var center := target_rect.get_center()
	var minimum := Vector2(PANEL_PADDING, PANEL_PADDING)
	var maximum := (size - bubble_size - minimum).max(minimum)
	var best_rect := Rect2()
	var best_overlap := INF
	var best_shift := INF
	# Prefer above, then below, with side placements when vertical space is tight.
	for side in range(4):
		var candidate := center - bubble_size * 0.5
		match side:
			0:
				candidate.y = target_rect.position.y - bubble_size.y - TARGET_GAP
			1:
				candidate.y = target_rect.end.y + TARGET_GAP
			2:
				candidate.x = target_rect.end.x + TARGET_GAP
			3:
				candidate.x = target_rect.position.x - bubble_size.x - TARGET_GAP
		var clamped := candidate.clamp(minimum, maximum)
		var candidate_rect := Rect2(clamped, bubble_size)
		var overlap := candidate_rect.intersection(target_rect.grow(TARGET_GAP)).get_area()
		var shift := candidate.distance_squared_to(clamped)
		if overlap < best_overlap or (is_equal_approx(overlap, best_overlap) and shift < best_shift):
			best_rect = candidate_rect
			best_overlap = overlap
			best_shift = shift
	return best_rect


func get_target_center() -> Vector2:
	if not _has_target():
		return Vector2(-1.0, -1.0)
	return _target_rect_in_guide().get_center()


func _update_bubble_position() -> void:
	var bubble_rect := get_stable_bubble_rect()
	if bubble_rect.size == Vector2.ZERO:
		return
	bubble_root.position = bubble_rect.position


func _refresh_copy() -> void:
	var title := _title_text
	if title.is_empty():
		title = "TXT_0241" if _keyboard_mode else "TXT_0242"
	title_label.text = tr(title)
	action_label.text = get_action_text()
	action_label.visible = not _action_blank
	hint_label.position.y = (_action_layout_y if _action_blank else _hint_layout_y) - 2.0
	if _hint_blank:
		hint_label.text = ""
	else:
		hint_label.text = (
			tr(_hint_text)
			if not _hint_text.is_empty()
			else tr("TXT_0246")
		)
	if _dialogue_mode:
		next_button.visible = true
		next_button.disabled = false
		if not _dialogue_button_key.is_empty():
			next_button.text = tr(_dialogue_button_key)
		else:
			next_button.text = (
				tr("TXT_0247")
				if _dialogue_page_index >= _dialogue_pages.size() - 1
				else tr("TXT_0248")
			)
		exit_button.text = tr("TXT_0249")
		next_button_artwork.visible = true
		exit_button_artwork.visible = true
		exit_button.visible = true
		return
	next_button.text = tr("TXT_0250")
	exit_button.text = tr("TXT_0251")
	next_button.visible = _show_next_button
	next_button.disabled = not _show_next_button
	exit_button.visible = true
	next_button_artwork.visible = _show_next_button
	exit_button_artwork.visible = true


func _draw() -> void:
	if Engine.is_editor_hint() or not visible:
		return
	var bubble_rect := Rect2(bubble_root.position, bubble_root.size)
	if _has_target():
		_draw_pointer(bubble_rect, _target_rect_in_guide())


func _rect_edge_toward(rect: Rect2, point: Vector2) -> Vector2:
	var center := rect.get_center()
	var offset := point - center
	if rect.size == Vector2.ZERO or offset.is_zero_approx():
		return center
	var half_size := rect.size * 0.5
	var ratio_x := absf(offset.x) / half_size.x if half_size.x > 0.0 else INF
	var ratio_y := absf(offset.y) / half_size.y if half_size.y > 0.0 else INF
	return center + offset / maxf(ratio_x, ratio_y)


func _draw_pointer(bubble_rect: Rect2, target_rect: Rect2) -> void:
	var target_center := target_rect.get_center()
	var anchor: Vector2
	if bubble_rect.end.y <= target_rect.position.y \
			or bubble_rect.position.y >= target_rect.end.y:
		anchor = Vector2(
			clampf(target_center.x, bubble_rect.position.x + 28.0, bubble_rect.end.x - 28.0),
			bubble_rect.end.y if bubble_rect.end.y <= target_rect.position.y else bubble_rect.position.y
		)
	else:
		anchor = Vector2(
			bubble_rect.end.x if bubble_rect.end.x <= target_rect.position.x else bubble_rect.position.x,
			clampf(target_center.y, bubble_rect.position.y + 28.0, bubble_rect.end.y - 28.0)
		)
	var target_edge := _rect_edge_toward(target_rect, anchor)
	var to_target := target_edge - anchor
	var distance := to_target.length()
	# Keep the tip close to the actual target, not to a possibly clamped bubble.
	var gap := 3.0 + (sin(_animation_time * 4.2) * 0.5 + 0.5) * 1.5
	var length := minf(24.0 if _dialogue_mode else 11.0, distance - gap)
	if length <= 0.0 or bubble_rect.has_point(target_rect.get_center()):
		return
	var direction := to_target / distance
	var tip := target_edge - direction * gap
	var base := tip - direction * length
	var perpendicular := Vector2(-direction.y, direction.x)
	var half_width := minf(13.0 if _dialogue_mode else 6.0, length * 0.7)
	_pointer_vertices[0] = tip
	_pointer_vertices[1] = base + perpendicular * half_width
	_pointer_vertices[2] = base - perpendicular * half_width
	draw_colored_polygon(_pointer_vertices, YELLOW)
	_pointer_outline[0] = _pointer_vertices[0]
	_pointer_outline[1] = _pointer_vertices[1]
	_pointer_outline[2] = _pointer_vertices[2]
	_pointer_outline[3] = _pointer_vertices[0]
	draw_polyline(_pointer_outline, GREEN, 3.0 if _dialogue_mode else 2.0, true)


func _on_resized() -> void:
	_update_bubble_position()
	queue_redraw()


func _on_next_pressed() -> void:
	if _dialogue_mode:
		if _dialogue_page_index < _dialogue_pages.size() - 1:
			_dialogue_page_index += 1
			_update_dialogue_page()
		else:
			_complete_dialogue()
		return
	next_requested.emit()


func _on_exit_pressed() -> void:
	if _dialogue_mode:
		_complete_dialogue()
		return
	exit_requested.emit()


func _update_dialogue_page() -> void:
	if not _dialogue_mode or _dialogue_page_index < 0 \
			or _dialogue_page_index >= _dialogue_pages.size():
		return
	var page := _dialogue_pages[_dialogue_page_index]
	_title_text = str(page.get("title", "TXT_0243"))
	var action_key := "keyboard_text" if _keyboard_mode and page.has("keyboard_text") else "text"
	_action_text = str(page.get(action_key, "TXT_0244"))
	_hint_text = str(page.get("hint", "TXT_0246"))
	_action_blank = page.has(action_key) and _action_text.is_empty()
	_hint_blank = page.has("hint") and _hint_text.is_empty()
	_dialogue_button_key = str(page.get("button", ""))
	_refresh_copy()


func _complete_dialogue() -> void:
	var completed_id := _dialogue_id
	hide_guide()
	dialogue_completed.emit(completed_id)


func _control_rect_in_guide(control: Control) -> Rect2:
	var into_guide := get_global_transform().affine_inverse() * control.get_global_transform()
	return into_guide * Rect2(Vector2.ZERO, control.size)
