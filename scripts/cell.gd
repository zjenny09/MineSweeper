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
const SPROUT_TEXTURE: Texture2D = preload("res://assets/gameplay/markers/sprout_marker.png")
const SLIME_TEXTURE: Texture2D = preload("res://assets/gameplay/markers/pollution_slime.png")

const DEFAULT_COLOR := Color("1b2d22")
const GUIDE_COLOR := Color("1b2d22")
const MINE_COLOR := Color("1b2d22")
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
		if not _sprout_wilting:
			_show_sludge_core()
	elif solved_mine or is_flagged:
		_set_biosensor_target(true, solved_mine)
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
	if is_flagged:
		tooltip_text = "小芽已标记疑似污染源"
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
	match procedural_visual:
		ProceduralVisual.BIOSENSOR:
			_draw_biosensor()
		ProceduralVisual.SLUDGE_CORE:
			_draw_sludge_core()


func _draw_biosensor() -> void:
	var unit := minf(size.x, size.y)
	var progress := clampf(biosensor_progress, 0.0, 1.0)
	if unit <= 1.0 or progress <= 0.0:
		return
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var wilt := clampf(sprout_wilt_progress, 0.0, 1.0)
	var texture_ratio := float(SPROUT_TEXTURE.get_width()) / float(SPROUT_TEXTURE.get_height())
	var marker_size := Vector2(unit * 0.72 * texture_ratio, unit * 0.72)
	var sway := sin(_idle_time * 2.5 + float(cell_index) * 0.7) * 0.055 * (1.0 - wilt)
	var rotation := sway + wilt * 0.30
	var center := Vector2(size.x * 0.5, size.y * 0.54)
	center += Vector2(unit * 0.10 * wilt, marker_size.y * (1.0 - eased) * 0.5)
	var tint := Color.WHITE.lerp(Color("8b826d"), wilt * 0.72)
	draw_set_transform(
		center,
		rotation,
		Vector2(lerpf(0.78, 1.0, eased), maxf(0.04, eased))
	)
	draw_texture_rect(SPROUT_TEXTURE, Rect2(-marker_size * 0.5, marker_size), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sludge_core() -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var appear := clampf(_oil_time / 0.42, 0.08, 1.0)
	var eased := 1.0 - pow(1.0 - appear, 3.0)
	var breathe := 1.0 + sin(_oil_time * 3.2 + float(cell_index)) * 0.030
	var texture_ratio := float(SLIME_TEXTURE.get_width()) / float(SLIME_TEXTURE.get_height())
	var marker_size := Vector2(unit * 0.76, unit * 0.76 / texture_ratio)
	var center := size * 0.5 + Vector2(0.0, unit * 0.035)
	draw_set_transform(center, 0.0, Vector2.ONE * eased * breathe)
	draw_texture_rect(
		SLIME_TEXTURE,
		Rect2(-marker_size * 0.5, marker_size),
		false,
		Color(1.0, 1.0, 1.0, eased)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _set_text_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_focus_color", color)
	add_theme_color_override("font_disabled_color", color)
