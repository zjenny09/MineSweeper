class_name MineCell
extends Button

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)
signal chord_requested(cell_index: int)


enum ProceduralVisual {
	NONE,
	BIOSENSOR,
	SLUDGE_CORE,
	WILTED_SPROUT,
	UPROOTED_SPROUT,
}

const ART := preload("res://scripts/art_catalog.gd")
const BIOSENSOR_SPEED := 2.7
const WILT_SPEED := 1.8
const SPROUT_PATH := ART.MARKER_FLAG_SPROUT_HEALTHY
const WILTED_SPROUT_PATH := ART.MARKER_FLAG_SPROUT_WILTED
const UPROOTED_SPROUT_PATH := ART.MARKER_FLAG_SPROUT_UPROOTED
const SLIME_PATH := ART.MARKER_POLLUTION_CORE_SLIME
const LEVEL_ONE_TILE_PAPER_PATH := ART.LEVEL_01_CELL_HIDDEN
const LEVEL_ONE_TILE_HOVER_PATH := ART.LEVEL_01_CELL_HOVER
const LEVEL_ONE_TILE_KEYBOARD_PATH := ART.LEVEL_01_CELL_KEYBOARD_FOCUS
const LEVEL_ONE_TILE_REVEALED_PATH := ART.LEVEL_01_CELL_REVEALED
const LEVEL_ONE_TILE_POLLUTED_PATH := ART.LEVEL_01_CELL_POLLUTED
const LEVEL_ONE_FONT_PATH := ART.UI_FONT
const LEVEL_ONE_FONT_SIZE := 30

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
const LEVEL_ONE_NUMBER_COLORS := {
	1: Color("e8f2ff"),
	2: Color("d7f3c5"),
	3: Color("ffd49a"),
	4: Color("e0d2ff"),
	5: Color("ffc6ba"),
	6: Color("bfeee6"),
	7: Color("fff0bd"),
	8: Color("f4eee0"),
}

var cell_index := -1
var _is_revealed := false
var _input_locked := false
var _hidden_style: StyleBox
var _hover_style: StyleBox
var _pressed_style: StyleBox
var _revealed_style: StyleBox
var _guide_style: StyleBox
var _guide_hover_style: StyleBox
var _selected_hidden_style: StyleBox
var _selected_revealed_style: StyleBox
var _selected_guide_style: StyleBox
var _polluted_style: StyleBox
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
var _sprout_texture: Texture2D
var _wilted_sprout_texture: Texture2D
var _uprooted_sprout_texture: Texture2D
var _slime_texture: Texture2D

static var _level_one_texture_cache: Dictionary = {}
static var _level_one_font: FontFile


func _ready() -> void:
	_sprout_texture = _load_runtime_texture(SPROUT_PATH)
	_wilted_sprout_texture = _load_runtime_texture(WILTED_SPROUT_PATH)
	_uprooted_sprout_texture = _load_runtime_texture(UPROOTED_SPROUT_PATH)
	_slime_texture = _load_runtime_texture(SLIME_PATH)
	_configure_styles()
	pressed.connect(_on_pressed)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
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
		_show_static_sprout(ProceduralVisual.UPROOTED_SPROUT)
	elif mine_visible:
		if is_flagged:
			_show_static_sprout(ProceduralVisual.WILTED_SPROUT)
		else:
			_show_sludge_core()
	elif solved_mine or is_flagged:
		_set_biosensor_target(true, solved_mine)
	elif is_revealed and adjacent_count > 0:
		_clear_procedural_visual()
		text = str(adjacent_count)
		var number_colors := LEVEL_ONE_NUMBER_COLORS if _uses_level_one_art() else NUMBER_COLORS
		_set_text_color(number_colors.get(adjacent_count, DEFAULT_COLOR))
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
	queue_redraw()


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
	if _uses_level_one_art():
		_apply_visual_style()
		return
	var eased := 1.0 - pow(1.0 - pollution_progress, 2.0)
	var hidden_style := _hidden_style as StyleBoxFlat
	var hover_style := _hover_style as StyleBoxFlat
	var pressed_style := _pressed_style as StyleBoxFlat
	var revealed_style := _revealed_style as StyleBoxFlat
	var guide_style := _guide_style as StyleBoxFlat
	var guide_hover_style := _guide_hover_style as StyleBoxFlat
	var selected_hidden := _selected_hidden_style as StyleBoxFlat
	var selected_revealed := _selected_revealed_style as StyleBoxFlat
	var selected_guide := _selected_guide_style as StyleBoxFlat
	hidden_style.bg_color = Color("fff8df").lerp(Color("eee5f3"), eased)
	hover_style.bg_color = Color("edf2cf").lerp(Color("eadcf0"), eased)
	pressed_style.bg_color = Color("cddca6").lerp(Color("c3a6d1"), eased)
	revealed_style.bg_color = Color("e8dec0").lerp(Color("eadbbd"), eased)
	guide_style.bg_color = Color("f4d86a").lerp(Color("dfc16f"), eased)
	guide_hover_style.bg_color = Color("ffe68a").lerp(Color("ead38c"), eased)
	hidden_style.border_color = Color("7ea069").lerp(Color("9a79ad"), eased)
	hover_style.border_color = Color("5f8d5e").lerp(Color("9a79ad"), eased)
	pressed_style.border_color = Color("3f7448").lerp(Color("76558b"), eased)
	revealed_style.border_color = Color("c0ad7c").lerp(Color("b59558"), eased)
	guide_style.border_color = Color("658e56").lerp(Color("b08d42"), eased)
	guide_hover_style.border_color = Color("658e56").lerp(Color("b08d42"), eased)
	selected_hidden.bg_color = hidden_style.bg_color
	selected_revealed.bg_color = revealed_style.bg_color
	selected_guide.bg_color = guide_style.bg_color
	selected_hidden.border_color = Color("fadf3c").lerp(Color("9b7ab0"), eased)
	selected_revealed.border_color = selected_hidden.border_color
	selected_guide.border_color = DEFAULT_COLOR.lerp(Color("8e70a5"), eased)


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


func _show_static_sprout(visual: int) -> void:
	procedural_visual = visual
	biosensor_progress = 1.0
	_biosensor_target_visible = false
	_sprout_wilting = false
	sprout_wilt_progress = 0.0
	_oil_time = 0.0
	set_process(false)
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
	return _level_number >= 1 and _level_number <= 5


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
	if _uses_level_one_art():
		_configure_level_one_styles()
		return
	_hidden_style = _make_style(Color("fff8df"), Color("7ea069"), 2)
	_hover_style = _make_style(Color("edf2cf"), Color("5f8d5e"), 2)
	_pressed_style = _make_style(Color("cddca6"), Color("3f7448"), 2, false)
	_revealed_style = _make_style(Color("e8dec0"), Color("c0ad7c"), 1, false)
	_guide_style = _make_style(Color("f4d86a"), Color("658e56"), 2)
	_guide_hover_style = _make_style(Color("ffe68a"), Color("658e56"), 2)
	_selected_hidden_style = _make_selected_style(_hidden_style as StyleBoxFlat, Color("fadf3c"))
	_selected_revealed_style = _make_selected_style(_revealed_style as StyleBoxFlat, Color("fadf3c"))
	_selected_guide_style = _make_selected_style(_guide_style as StyleBoxFlat, DEFAULT_COLOR)
	add_theme_stylebox_override("normal", _hidden_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _hidden_style)


func _configure_level_one_styles() -> void:
	_hidden_style = _make_texture_style(LEVEL_ONE_TILE_PAPER_PATH)
	_hover_style = _make_texture_style(LEVEL_ONE_TILE_HOVER_PATH)
	_pressed_style = _hover_style
	_revealed_style = _make_texture_style(LEVEL_ONE_TILE_REVEALED_PATH)
	_guide_style = _make_texture_style(LEVEL_ONE_TILE_KEYBOARD_PATH)
	_guide_hover_style = _guide_style
	_selected_hidden_style = _hidden_style
	_selected_revealed_style = _revealed_style
	_selected_guide_style = _hidden_style
	_polluted_style = _make_texture_style(LEVEL_ONE_TILE_POLLUTED_PATH)
	add_theme_stylebox_override("normal", _hidden_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _hidden_style)
	_configure_level_one_typography()


func _configure_level_one_typography() -> void:
	if _level_one_font == null:
		_level_one_font = load(LEVEL_ONE_FONT_PATH) as FontFile
		if _level_one_font == null:
			push_error("Level one cell font could not be loaded: %s" % LEVEL_ONE_FONT_PATH)
			return
	add_theme_font_override("font", _level_one_font)
	add_theme_font_size_override("font_size", LEVEL_ONE_FONT_SIZE)
	add_theme_color_override("font_outline_color", Color("173522"))
	add_theme_constant_override("outline_size", 3)


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
	if (
		_uses_level_one_art()
		and pollution_progress > 0.12
		and procedural_visual != ProceduralVisual.WILTED_SPROUT
	):
		normal_style = _polluted_style
		hover_style = _polluted_style
		pressed_style = _polluted_style
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


func _load_runtime_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Cell artwork could not be loaded: %s" % path)
	return texture


func _make_texture_style(path: String) -> StyleBoxTexture:
	if not _level_one_texture_cache.has(path):
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("Level one tile artwork could not be loaded: %s" % path)
			return StyleBoxTexture.new()
		_level_one_texture_cache[path] = texture
	var style := StyleBoxTexture.new()
	style.texture = _level_one_texture_cache[path]
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	return style


func _make_selected_style(base_style: StyleBoxFlat, border: Color) -> StyleBoxFlat:
	var style := base_style.duplicate() as StyleBoxFlat
	style.border_color = border
	style.set_border_width_all(4)
	style.expand_margin_left = 1.0
	style.expand_margin_top = 1.0
	style.expand_margin_right = 1.0
	style.expand_margin_bottom = 1.0
	return style


func _make_style(
	background: Color,
	border: Color,
	border_width: int = 1,
	raised: bool = true
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0.20, 0.15, 0.08, 0.22 if raised else 0.08)
	style.shadow_size = 2 if raised else 0
	style.shadow_offset = Vector2(0.0, 2.0 if raised else 0.0)
	style.anti_aliasing = true
	return style


func _draw() -> void:
	_draw_focus_outline()
	match procedural_visual:
		ProceduralVisual.BIOSENSOR:
			_draw_biosensor()
		ProceduralVisual.SLUDGE_CORE:
			_draw_sludge_core()
		ProceduralVisual.WILTED_SPROUT:
			_draw_static_sprout(_wilted_sprout_texture, 0.78)
		ProceduralVisual.UPROOTED_SPROUT:
			_draw_static_sprout(_uprooted_sprout_texture, 0.86)


func _draw_focus_outline() -> void:
	if not _uses_level_one_art() or _input_locked:
		return
	var outline_color := Color.TRANSPARENT
	var keyboard_outline := false
	if _is_keyboard_selected:
		outline_color = Color("d9ad32")
		keyboard_outline = true
	elif is_hovered():
		outline_color = Color("f3e7a1") if _is_revealed else Color("315e3c")
	else:
		return

	var unit := minf(size.x, size.y)
	var inset := unit * (0.18 if keyboard_outline else 0.21)
	var left := inset
	var top := inset
	var right := size.x - inset
	var bottom := size.y - inset
	var line_width := (
		maxf(3.2, unit * 0.052)
		if keyboard_outline
		else maxf(2.0, unit * 0.035)
	)
	var dash_length := (
		maxf(5.0, unit * 0.090)
		if keyboard_outline
		else maxf(4.0, unit * 0.075)
	)
	var antialiased := not keyboard_outline
	draw_dashed_line(
		Vector2(left, top), Vector2(right, top),
		outline_color, line_width, dash_length, true, antialiased
	)
	draw_dashed_line(
		Vector2(right, top), Vector2(right, bottom),
		outline_color, line_width, dash_length, true, antialiased
	)
	draw_dashed_line(
		Vector2(right, bottom), Vector2(left, bottom),
		outline_color, line_width, dash_length, true, antialiased
	)
	draw_dashed_line(
		Vector2(left, bottom), Vector2(left, top),
		outline_color, line_width, dash_length, true, antialiased
	)


func _draw_biosensor() -> void:
	var unit := minf(size.x, size.y)
	var progress := clampf(biosensor_progress, 0.0, 1.0)
	if unit <= 1.0 or progress <= 0.0:
		return
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var wilt := clampf(sprout_wilt_progress, 0.0, 1.0)
	var texture_ratio := float(_sprout_texture.get_width()) / float(_sprout_texture.get_height())
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
	draw_texture_rect(_sprout_texture, Rect2(-marker_size * 0.5, marker_size), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_static_sprout(texture: Texture2D, scale_factor: float) -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var marker_size := Vector2.ONE * unit * scale_factor
	var center := size * 0.5
	draw_texture_rect(texture, Rect2(center - marker_size * 0.5, marker_size), false)


func _draw_sludge_core() -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var appear := clampf(_oil_time / 0.42, 0.08, 1.0)
	var eased := 1.0 - pow(1.0 - appear, 3.0)
	var breathe := 1.0 + sin(_oil_time * 3.2 + float(cell_index)) * 0.030
	var texture_ratio := float(_slime_texture.get_width()) / float(_slime_texture.get_height())
	var marker_size := Vector2(unit * 0.76, unit * 0.76 / texture_ratio)
	var center := size * 0.5 + Vector2(0.0, unit * 0.035)
	draw_set_transform(center, 0.0, Vector2.ONE * eased * breathe)
	draw_texture_rect(
		_slime_texture,
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
