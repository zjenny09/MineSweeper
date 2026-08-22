class_name MineCell
extends Button

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)
signal chord_requested(cell_index: int)


enum ProceduralVisual {
	NONE,
	BIOSENSOR,
	SLUDGE_CORE,
}

const BIOSENSOR_SPEED := 2.7
const WILT_SPEED := 1.8
const SEED_COLOR := Color("8b6f45")

const DEFAULT_COLOR := Color("1b2d22")
const FLAG_COLOR := Color("469d65")
const GUIDE_COLOR := Color("1b2d22")
const MINE_COLOR := Color("1b2d22")
const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const LIGHT_GREEN := Color("a3e086")
const INK := Color("1b2d22")
const NUMBER_COLORS := {
	0: Color("777264"),
	1: Color("315f8a"),
	2: Color("3d7547"),
	3: Color("a3473f"),
	4: Color("66508a"),
	5: Color("81443c"),
	6: Color("337576"),
	7: Color("34342f"),
	8: Color("676257"),
}

var cell_index := -1
var _is_revealed := false
var _input_locked := false
var _hidden_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _revealed_style: StyleBoxFlat
var _guide_style: StyleBoxFlat
var _guide_hover_style: StyleBoxFlat
var _selected_hidden_style: StyleBoxFlat
var _selected_revealed_style: StyleBoxFlat
var _selected_guide_style: StyleBoxFlat
var _is_keyboard_selected := false
var _is_guided := false
var _level_number := 0
var procedural_visual: int = ProceduralVisual.NONE
var biosensor_progress := 0.0
var _biosensor_target_visible := false
var _idle_time := 0.0
var sprout_wilt_progress := 0.0
var _sprout_wilting := false
var _oil_time := 0.0
var pollution_progress := 0.0


func _ready() -> void:
	_configure_styles()
	pressed.connect(_on_pressed)
	set_process(false)


func setup(index: int, level_number: int = 0) -> void:
	cell_index = index
	_level_number = level_number


func render_state(
	is_revealed: bool,
	is_flagged: bool,
	mine_visible: bool,
	adjacent_count: int,
	input_locked: bool,
	wrong_flag: bool = false,
	solved_mine: bool = false,
	is_guided: bool = false
) -> void:
	text = ""
	_set_text_color(DEFAULT_COLOR)

	if wrong_flag:
		if not _sprout_wilting:
			_clear_procedural_visual()
		text = "X"
		_set_text_color(MINE_COLOR)
	elif mine_visible:
		if _uses_level_one_art():
			if not _sprout_wilting:
				_show_sludge_core()
		else:
			_clear_procedural_visual()
			text = "●"
			_set_text_color(MINE_COLOR)
	elif solved_mine or is_flagged:
		if _uses_level_one_art():
			_set_biosensor_target(true, solved_mine)
		else:
			_clear_procedural_visual()
			text = "!"
			_set_text_color(FLAG_COLOR)
	elif is_revealed and adjacent_count > 0:
		_clear_procedural_visual()
		text = str(adjacent_count)
		_set_text_color(NUMBER_COLORS.get(adjacent_count, DEFAULT_COLOR))
	elif is_revealed:
		_clear_procedural_visual()
	elif is_guided:
		_set_biosensor_target(false)
		_set_text_color(GUIDE_COLOR)
	else:
		_set_biosensor_target(false)

	_is_revealed = is_revealed
	_input_locked = input_locked
	_is_guided = is_guided
	disabled = input_locked
	_apply_visual_style()
	queue_redraw()
	if _uses_level_one_art() and is_flagged:
		tooltip_text = "检测种子已标记疑似污染源"
	elif is_guided:
		tooltip_text = "建议从这里开始（也可以忽略）"
	elif is_revealed and adjacent_count == 0:
		tooltip_text = "空白净化区"
	elif is_revealed:
		tooltip_text = "邻近污染核心：%d；双击可快速展开" % adjacent_count
	else:
		tooltip_text = "左键净化，右键标记污染核心"


func set_keyboard_selected(selected: bool) -> void:
	if _is_keyboard_selected == selected:
		return
	_is_keyboard_selected = selected
	_apply_visual_style()


func uses_level_one_art() -> bool:
	return _uses_level_one_art()


func set_pollution_progress(value: float) -> void:
	var next_progress := clampf(value, 0.0, 1.0)
	if is_equal_approx(pollution_progress, next_progress):
		return
	pollution_progress = next_progress
	_update_polluted_styles()
	_apply_visual_style()
	queue_redraw()


func _update_polluted_styles() -> void:
	if _hidden_style == null:
		return
	var eased := 1.0 - pow(1.0 - pollution_progress, 2.0)
	_hidden_style.bg_color = Color("ffffff").lerp(Color("eee5f3"), eased)
	_hover_style.bg_color = Color("a3e086").lerp(Color("eadcf0"), eased)
	_pressed_style.bg_color = Color("469d65").lerp(Color("c3a6d1"), eased)
	_revealed_style.bg_color = Color("a3e086").lerp(Color("eadbbd"), eased)
	_guide_style.bg_color = Color("fadf3c").lerp(Color("dfc16f"), eased)
	_guide_hover_style.bg_color = Color("ffe96a").lerp(Color("ead38c"), eased)
	_hidden_style.border_color = Color("469d65").lerp(Color("9a79ad"), eased)
	_hover_style.border_color = Color("469d65").lerp(Color("9a79ad"), eased)
	_pressed_style.border_color = Color("469d65").lerp(Color("76558b"), eased)
	_revealed_style.border_color = Color("ffffff").lerp(Color("b59558"), eased)
	_guide_style.border_color = Color("469d65").lerp(Color("b08d42"), eased)
	_guide_hover_style.border_color = Color("469d65").lerp(Color("b08d42"), eased)
	_selected_hidden_style.bg_color = _hidden_style.bg_color
	_selected_revealed_style.bg_color = _revealed_style.bg_color
	_selected_guide_style.bg_color = _guide_style.bg_color
	_selected_hidden_style.border_color = Color("fadf3c").lerp(Color("9b7ab0"), eased)
	_selected_revealed_style.border_color = _selected_hidden_style.border_color
	_selected_guide_style.border_color = DEFAULT_COLOR.lerp(Color("8e70a5"), eased)


func reset_transient_visuals() -> void:
	procedural_visual = ProceduralVisual.NONE
	biosensor_progress = 0.0
	_biosensor_target_visible = false
	_idle_time = 0.0
	sprout_wilt_progress = 0.0
	_sprout_wilting = false
	_oil_time = 0.0
	set_process(false)
	queue_redraw()


func advance_biosensor_animation(delta: float) -> void:
	if procedural_visual != ProceduralVisual.BIOSENSOR:
		set_process(false)
		return
	var step := maxf(0.0, delta)
	_idle_time += step
	if _sprout_wilting:
		sprout_wilt_progress = move_toward(
			sprout_wilt_progress,
			1.0,
			step * WILT_SPEED
		)
		if is_equal_approx(sprout_wilt_progress, 1.0):
			set_process(false)
		queue_redraw()
		return
	var target := 1.0 if _biosensor_target_visible else 0.0
	biosensor_progress = move_toward(
		biosensor_progress,
		target,
		step * BIOSENSOR_SPEED
	)
	if not _biosensor_target_visible and is_zero_approx(biosensor_progress):
		procedural_visual = ProceduralVisual.NONE
		set_process(false)
	queue_redraw()


func begin_loss_wilt_if_visible() -> void:
	if not _uses_level_one_art():
		return
	if procedural_visual != ProceduralVisual.BIOSENSOR or biosensor_progress <= 0.0:
		return
	_biosensor_target_visible = false
	_sprout_wilting = true
	sprout_wilt_progress = 0.0
	set_process(true)
	queue_redraw()


func is_sprout_wilting() -> bool:
	return _sprout_wilting


func _process(delta: float) -> void:
	if procedural_visual == ProceduralVisual.SLUDGE_CORE:
		_oil_time += maxf(0.0, delta)
		queue_redraw()
		return
	advance_biosensor_animation(delta)


func _set_biosensor_target(visible_target: bool, snap_complete: bool = false) -> void:
	if not _uses_level_one_art():
		_clear_procedural_visual()
		return
	if visible_target:
		procedural_visual = ProceduralVisual.BIOSENSOR
		_biosensor_target_visible = true
		_sprout_wilting = false
		sprout_wilt_progress = 0.0
		if snap_complete:
			biosensor_progress = 1.0
		set_process(true)
	else:
		_biosensor_target_visible = false
		if procedural_visual == ProceduralVisual.BIOSENSOR and biosensor_progress > 0.0:
			set_process(true)
		elif procedural_visual != ProceduralVisual.SLUDGE_CORE:
			procedural_visual = ProceduralVisual.NONE
			biosensor_progress = 0.0
			set_process(false)
	queue_redraw()


func _show_sludge_core() -> void:
	var was_sludge_core := procedural_visual == ProceduralVisual.SLUDGE_CORE
	procedural_visual = ProceduralVisual.SLUDGE_CORE
	biosensor_progress = 0.0
	_biosensor_target_visible = false
	_sprout_wilting = false
	sprout_wilt_progress = 0.0
	if not was_sludge_core:
		_oil_time = 0.0
	set_process(true)
	queue_redraw()


func _clear_procedural_visual() -> void:
	if procedural_visual == ProceduralVisual.NONE and is_zero_approx(biosensor_progress):
		return
	procedural_visual = ProceduralVisual.NONE
	biosensor_progress = 0.0
	_biosensor_target_visible = false
	_sprout_wilting = false
	sprout_wilt_progress = 0.0
	_oil_time = 0.0
	set_process(false)
	queue_redraw()


func _uses_level_one_art() -> bool:
	return _level_number == 1


func _on_pressed() -> void:
	if not _input_locked and not _is_revealed:
		reveal_requested.emit(cell_index)


func _gui_input(event: InputEvent) -> void:
	if _input_locked:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click and mouse_event.pressed and _is_revealed:
			chord_requested.emit(cell_index)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and not _is_revealed:
			flag_requested.emit(cell_index)
			accept_event()


func _configure_styles() -> void:
	_hidden_style = _make_style(Color("ffffff"), Color("469d65"), 2)
	_hover_style = _make_style(Color("a3e086"), Color("469d65"), 2)
	_pressed_style = _make_style(Color("469d65"), Color("469d65"), 2)
	_revealed_style = _make_style(Color("a3e086"), Color("ffffff"), 2)
	_guide_style = _make_style(Color("fadf3c"), Color("469d65"), 2)
	_guide_hover_style = _make_style(Color("ffe96a"), Color("469d65"), 2)
	_selected_hidden_style = _make_selected_style(_hidden_style, Color("fadf3c"))
	_selected_revealed_style = _make_selected_style(_revealed_style, Color("fadf3c"))
	_selected_guide_style = _make_selected_style(_guide_style, DEFAULT_COLOR)
	add_theme_stylebox_override("normal", _hidden_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _hidden_style)


func _apply_visual_style() -> void:
	if _hidden_style == null:
		return
	var normal_style := _hidden_style
	var hover_style := _hover_style
	var pressed_style := _pressed_style
	if _is_revealed:
		normal_style = _revealed_style
		hover_style = _revealed_style
		pressed_style = _revealed_style
	elif _is_guided:
		normal_style = _guide_style
		hover_style = _guide_hover_style
		pressed_style = _guide_hover_style
	if _is_keyboard_selected:
		var selected_style := _selected_hidden_style
		if _is_revealed:
			selected_style = _selected_revealed_style
		elif _is_guided:
			selected_style = _selected_guide_style
		normal_style = selected_style
		hover_style = selected_style
		pressed_style = selected_style
	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", normal_style)


func _make_selected_style(base_style: StyleBoxFlat, border: Color) -> StyleBoxFlat:
	var style := base_style.duplicate() as StyleBoxFlat
	style.border_color = border
	style.set_border_width_all(4)
	style.expand_margin_left = 1.0
	style.expand_margin_top = 1.0
	style.expand_margin_right = 1.0
	style.expand_margin_bottom = 1.0
	return style


func _make_style(background: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


func _draw() -> void:
	if not _uses_level_one_art():
		return
	match procedural_visual:
		ProceduralVisual.BIOSENSOR:
			_draw_biosensor()
		ProceduralVisual.SLUDGE_CORE:
			_draw_sludge_core()


func _draw_biosensor() -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var progress := clampf(biosensor_progress, 0.0, 1.0)
	var center_x := size.x * 0.5
	var soil_y := size.y * 0.68
	var drop_progress := clampf(progress / 0.30, 0.0, 1.0)
	var drop_eased := 1.0 - pow(1.0 - drop_progress, 3.0)
	var bounce := sin(drop_progress * TAU) * (1.0 - drop_progress) * unit * 0.045
	var seed_y := lerpf(size.y * 0.24, soil_y, drop_eased) + bounce
	if progress >= 0.30:
		seed_y = soil_y

	var stem_progress := clampf((progress - 0.26) / 0.46, 0.0, 1.0)
	var wilt := clampf(sprout_wilt_progress, 0.0, 1.0)
	var idle_sway := (
		sin(_idle_time * 2.5 + float(cell_index) * 0.7)
		* unit
		* 0.025
		* stem_progress
		* (1.0 - wilt)
	)
	var stem_top := Vector2(
		center_x + idle_sway + unit * 0.18 * wilt,
		lerpf(soil_y - unit * 0.02, size.y * 0.34, stem_progress) + unit * 0.20 * wilt
	)
	var wilt_color := Color("77705d")
	var stem_color := GREEN.lerp(wilt_color, wilt)
	if stem_progress > 0.0:
		draw_line(
			Vector2(center_x, soil_y),
			stem_top,
			stem_color,
			maxf(2.0, unit * 0.045),
			true
		)

	var left_progress := clampf((progress - 0.56) / 0.24, 0.0, 1.0)
	var right_progress := clampf((progress - 0.68) / 0.24, 0.0, 1.0)
	var stem_base := Vector2(center_x, soil_y)
	if left_progress > 0.01:
		var left_attach := stem_base.lerp(stem_top, 0.70)
		var left_center := left_attach + Vector2(
			-unit * (0.075 - 0.020 * wilt),
			unit * (0.010 + 0.045 * wilt)
		)
		draw_line(left_attach, left_center, stem_color, maxf(1.3, unit * 0.022), true)
		_draw_cell_leaf(
			left_center,
			Vector2(unit * 0.23, unit * 0.13) * left_progress * (1.0 - 0.16 * wilt),
			lerpf(-0.52, 0.34, wilt) + idle_sway / maxf(1.0, unit) * 0.8,
			LIGHT_GREEN.lerp(wilt_color, wilt)
		)
	if right_progress > 0.01:
		var right_attach := stem_base.lerp(stem_top, 0.80)
		var right_center := right_attach + Vector2(
			unit * (0.080 - 0.018 * wilt),
			unit * (0.012 + 0.050 * wilt)
		)
		draw_line(right_attach, right_center, stem_color, maxf(1.3, unit * 0.022), true)
		_draw_cell_leaf(
			right_center,
			Vector2(unit * 0.22, unit * 0.12) * right_progress * (1.0 - 0.16 * wilt),
			lerpf(0.48, -0.34, wilt) + idle_sway / maxf(1.0, unit) * 0.8,
			GREEN.lerp(wilt_color, wilt)
		)

	var seed_points := _ellipse_points(
		Vector2(center_x, seed_y),
		Vector2(unit * 0.105, unit * 0.070),
		-0.18
	)
	draw_colored_polygon(seed_points, SEED_COLOR.lerp(wilt_color, wilt * 0.55))
	_draw_closed_outline(seed_points, INK, maxf(1.3, unit * 0.020))
	draw_circle(
		Vector2(center_x - unit * 0.018, seed_y - unit * 0.010),
		unit * 0.014,
		YELLOW
	)


func _draw_sludge_core() -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var appear := clampf(_oil_time / 0.55, 0.18, 1.0)
	var center := size * 0.5 + Vector2(0.0, unit * 0.08)
	var breathe := 1.0 + sin(_oil_time * 3.2 + float(cell_index)) * 0.035
	var body := PackedVector2Array()
	for index in 30:
		var angle := TAU * float(index) / 30.0
		var wobble := 1.0 + 0.055 * sin(angle * 3.0 + 0.8)
		body.append(center + Vector2(
			cos(angle) * unit * 0.27 * wobble * breathe * appear,
			sin(angle) * unit * 0.22 * wobble / breathe * appear
		))
	var body_color := Color("916fbbb8")
	var outline_color := Color("795a96dc")
	draw_colored_polygon(body, body_color)
	_draw_closed_outline(body, outline_color, maxf(1.7, unit * 0.025))

	# Soft highlights make the creature read as translucent jelly.
	draw_arc(
		center - Vector2(unit * 0.075, unit * 0.070),
		unit * 0.105,
		3.65,
		5.15,
		12,
		Color("fff8ff9c"),
		maxf(1.7, unit * 0.025),
		true
	)
	draw_circle(
		center + Vector2(unit * 0.13, unit * 0.095),
		unit * 0.030,
		Color("d8c2e973")
	)

	var blink := 0.18 if fmod(_oil_time, 4.0) > 3.72 else 1.0
	var eye_y := center.y - unit * 0.025
	for eye_x in [center.x - unit * 0.075, center.x + unit * 0.075]:
		_draw_sludge_eye(eye_x, eye_y, unit, blink)
	draw_arc(
		center + Vector2(0.0, unit * 0.055),
		unit * 0.065,
		0.30,
		PI - 0.30,
		12,
		Color("65437e"),
		maxf(1.4, unit * 0.019),
		true
	)

	for bubble_index in 3:
		var phase := _oil_time * (1.4 + 0.22 * float(bubble_index)) + float(bubble_index) * 1.7
		var bubble_center := center + Vector2(
			unit * (-0.24 + 0.24 * float(bubble_index)) + sin(phase) * unit * 0.025,
			-unit * (0.20 + 0.08 * fmod(phase, 1.0))
		)
		var bubble_radius := unit * (0.025 + 0.008 * float(bubble_index % 2))
		draw_circle(bubble_center, bubble_radius, Color("cbb2df70"))
		draw_arc(bubble_center, bubble_radius, 0.0, TAU, 16, Color("8c6aa4b8"), 1.1, true)


func _draw_sludge_eye(eye_x: float, eye_y: float, unit: float, blink: float) -> void:
	var eye_center := Vector2(eye_x, eye_y)
	var eye := _ellipse_points(
		eye_center,
		Vector2(unit * 0.040, unit * 0.050 * blink),
		0.0
	)
	draw_colored_polygon(eye, Color("ee6f72e8"))
	_draw_closed_outline(eye, Color("874a6bc8"), maxf(1.0, unit * 0.012))
	if blink > 0.5:
		draw_circle(eye_center + Vector2(0.0, unit * 0.007), unit * 0.018, Color("a93651"))
		draw_circle(eye_center - Vector2(unit * 0.007, unit * 0.006), unit * 0.006, Color("fff6f0e8"))

	# Slanted brows keep the transparent slime playfully fierce.
	var side := -1.0 if eye_x < size.x * 0.5 else 1.0
	var outer := eye_center + Vector2(side * unit * 0.045, -unit * 0.058)
	var inner := eye_center + Vector2(-side * unit * 0.030, -unit * 0.030)
	draw_line(outer, inner, Color("68427fd8"), maxf(1.2, unit * 0.017), true)


func _draw_cell_leaf(
	center: Vector2,
	leaf_size: Vector2,
	rotation: float,
	color: Color
) -> void:
	var points := _ellipse_points(center, leaf_size * 0.5, rotation)
	draw_colored_polygon(points, color)
	_draw_closed_outline(points, INK, maxf(1.2, minf(size.x, size.y) * 0.018))


func _ellipse_points(
	center: Vector2,
	radius: Vector2,
	rotation: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		var local_point := Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		points.append(center + local_point.rotated(rotation))
	return points


func _rotated_cell_point(local_point: Vector2, center: Vector2, rotation: float) -> Vector2:
	return center + local_point.rotated(rotation)


func _draw_closed_outline(
	points: PackedVector2Array,
	color: Color,
	width: float
) -> void:
	if points.size() < 2:
		return
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, color, width, true)


func _set_text_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_focus_color", color)
	add_theme_color_override("font_disabled_color", color)
