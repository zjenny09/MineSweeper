class_name MineCell
extends Button

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)
signal chord_requested(cell_index: int)
signal scan_requested(cell_index: int)
signal scan_cancel_requested


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
const OCEAN_CORAL_NORMAL_PATH := ART.OCEAN_MARKER_CORAL_NORMAL
const OCEAN_CORAL_FAILED_PATH := ART.OCEAN_MARKER_CORAL_FAILED
const OCEAN_CORAL_WRONG_PATH := ART.OCEAN_MARKER_CORAL_WRONG
const LEVEL_ONE_TILE_PAPER_PATH := ART.LEVEL_01_CELL_HIDDEN
const LEVEL_ONE_TILE_HOVER_PATH := ART.LEVEL_01_CELL_HOVER
const LEVEL_ONE_TILE_KEYBOARD_PATH := ART.LEVEL_01_CELL_KEYBOARD_FOCUS
const LEVEL_ONE_TILE_REVEALED_PATH := ART.LEVEL_01_CELL_REVEALED
const LEVEL_ONE_TILE_POLLUTED_PATH := ART.LEVEL_01_CELL_POLLUTED
const OCEAN_TILE_HIDDEN_PATH := ART.OCEAN_CELL_HIDDEN
const OCEAN_TILE_REVEALED_PATH := ART.OCEAN_CELL_REVEALED
const OCEAN_TILE_POLLUTED_PATH := ART.OCEAN_CELL_POLLUTED
const LEVEL_ONE_FONT_PATH := ART.UI_FONT
const LEVEL_ONE_FONT_SIZE := 30
const HEX_TOPOLOGY := &"hex_pointy_odd_r"
const HEX_HORIZONTAL_FACTOR := 1.7320508
const HEX_HIDDEN_COLOR := Color("79c9d8")
const HEX_HOVER_COLOR := Color("a4e3e7")
const HEX_REVEALED_COLOR := Color("d9f1ea")
const HEX_GUIDE_COLOR := Color("f3d56a")
const HEX_BORDER_COLOR := Color("286f7b")
const OCEAN_HOVER_DASH_COLOR := Color("267f91")
const OCEAN_KEYBOARD_DASH_COLOR := Color("54d7e8")
const OCEAN_GUIDE_TINT := Color(0.96, 0.79, 0.31, 0.32)
const SCAN_TARGET_COLOR := Color("39c8d4")
const SCAN_SAFE_COLOR := Color("58d69a")
const SCAN_MINE_COLOR := Color("efa94a")
const SCAN_PULSE_DURATION := 0.62
const SCAN_RESULT_SAFE := 0
const SCAN_RESULT_MINE := 1

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
const OCEAN_NUMBER_COLORS := {
	1: Color("174f73"),
	2: Color("24735f"),
	3: Color("b5523f"),
	4: Color("584b8f"),
	5: Color("8e4654"),
	6: Color("146f78"),
	7: Color("263f58"),
	8: Color("5d5965"),
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
var _is_flagged := false
var _is_confirmed := false
var _adjacent_count := 0
var _scan_target_mode := false
var _scan_candidate := false
var _scan_pulse_result := -1
var _scan_pulse_progress := 1.0
var _level_number := 0
var _is_hex := false
var _hex_fill_ratio := 0.94
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
static var _ocean_hidden_texture: Texture2D
static var _ocean_revealed_texture: Texture2D
static var _ocean_polluted_texture: Texture2D
static var _ocean_coral_normal_texture: Texture2D
static var _ocean_coral_failed_texture: Texture2D
static var _ocean_coral_wrong_texture: Texture2D


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


func setup(index: int, level_number: int = 0, topology: StringName = &"square") -> void:
	cell_index = index
	_level_number = level_number
	_is_hex = topology == HEX_TOPOLOGY


func set_hex_fill_ratio(value: float) -> void:
	_hex_fill_ratio = clampf(value, 0.75, 1.0)
	queue_redraw()


func render_state(
	is_revealed: bool,
	is_flagged: bool,
	mine_visible: bool,
	adjacent_count: int,
	input_locked: bool,
	wrong_flag: bool = false,
	solved_mine: bool = false,
	is_guided: bool = false,
	is_confirmed: bool = false
) -> void:
	text = ""
	_set_text_color(DEFAULT_COLOR)

	if is_confirmed:
		if _is_hex and mine_visible:
			_show_static_sprout(ProceduralVisual.WILTED_SPROUT)
		else:
			_set_biosensor_target(true, true)
	elif wrong_flag:
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
		var number_colors := NUMBER_COLORS
		if _uses_level_one_art():
			number_colors = LEVEL_ONE_NUMBER_COLORS
		elif _is_hex:
			number_colors = OCEAN_NUMBER_COLORS
		_set_text_color(number_colors.get(adjacent_count, DEFAULT_COLOR))
	elif is_revealed:
		_clear_procedural_visual()
	elif is_guided:
		_set_biosensor_target(false)
		_set_text_color(GUIDE_COLOR)
	else:
		_set_biosensor_target(false)

	_is_revealed = is_revealed
	_is_flagged = is_flagged
	_is_confirmed = is_confirmed
	_adjacent_count = adjacent_count
	_input_locked = input_locked
	_is_guided = is_guided
	disabled = input_locked
	_apply_visual_style()
	_update_tooltip()
	queue_redraw()


func set_keyboard_selected(selected: bool) -> void:
	if _is_keyboard_selected == selected:
		return
	_is_keyboard_selected = selected
	_apply_visual_style()
	queue_redraw()


func set_scan_target_mode(enabled: bool, candidate: bool) -> void:
	_scan_target_mode = enabled
	_scan_candidate = enabled and candidate
	_update_tooltip()
	queue_redraw()


func play_scan_result(result: int) -> void:
	_scan_pulse_result = SCAN_RESULT_MINE if result == SCAN_RESULT_MINE else SCAN_RESULT_SAFE
	_scan_pulse_progress = 0.0
	set_process(true)
	queue_redraw()


func _update_tooltip() -> void:
	if _scan_target_mode:
		tooltip_text = (
			"点击扫描此格；右键取消"
			if _scan_candidate
			else "此格不可扫描；右键取消"
		)
	elif _is_confirmed:
		tooltip_text = "机器人已确认这里存在污染核心"
	elif _is_flagged:
		tooltip_text = (
			"珊瑚已标记疑似污染源"
			if _is_hex
			else "小芽已标记疑似污染源"
		)
	elif _is_guided:
		tooltip_text = "建议从这里开始（也可以忽略）"
	elif _is_revealed and _adjacent_count == 0:
		tooltip_text = "空白净化区"
	elif _is_revealed:
		tooltip_text = "邻近污染核心：%d；双击可快速展开" % _adjacent_count
	else:
		tooltip_text = "左键净化，右键标记污染核心"


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
	if _is_hex:
		queue_redraw()
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
	_scan_target_mode = false
	_scan_candidate = false
	_scan_pulse_result = -1
	_scan_pulse_progress = 1.0
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
	var step := maxf(0.0, delta)
	if procedural_visual == ProceduralVisual.SLUDGE_CORE:
		_oil_time += step
		queue_redraw()
	else:
		advance_biosensor_animation(step)
	if _scan_pulse_result >= 0:
		_scan_pulse_progress = minf(
			_scan_pulse_progress + step / SCAN_PULSE_DURATION,
			1.0
		)
		queue_redraw()
		if is_equal_approx(_scan_pulse_progress, 1.0):
			_scan_pulse_result = -1
	_refresh_processing()


func _refresh_processing() -> void:
	var procedural_active := procedural_visual == ProceduralVisual.SLUDGE_CORE
	if procedural_visual == ProceduralVisual.BIOSENSOR:
		procedural_active = (
			(_sprout_wilting and sprout_wilt_progress < 1.0)
			or (not _sprout_wilting and (_biosensor_target_visible or biosensor_progress > 0.0))
		)
	set_process(procedural_active or _scan_pulse_result >= 0)


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
	if _input_locked:
		return
	if _scan_target_mode:
		if _scan_candidate:
			scan_requested.emit(cell_index)
		return
	if not _is_revealed:
		reveal_requested.emit(cell_index)


func _gui_input(event: InputEvent) -> void:
	if _input_locked:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if _scan_target_mode:
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
				scan_cancel_requested.emit()
				accept_event()
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click and mouse_event.pressed and _is_revealed:
			chord_requested.emit(cell_index)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and not _is_revealed:
			flag_requested.emit(cell_index)
			accept_event()


func _configure_styles() -> void:
	if _is_hex:
		_configure_hex_styles()
		return
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


func _configure_hex_styles() -> void:
	var empty_style := StyleBoxEmpty.new()
	_hidden_style = empty_style
	_hover_style = empty_style
	_pressed_style = empty_style
	_revealed_style = empty_style
	_guide_style = empty_style
	_guide_hover_style = empty_style
	_selected_hidden_style = empty_style
	_selected_revealed_style = empty_style
	_selected_guide_style = empty_style
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty_style)
	if _ocean_hidden_texture == null:
		_ocean_hidden_texture = _load_runtime_texture(OCEAN_TILE_HIDDEN_PATH)
	if _ocean_revealed_texture == null:
		_ocean_revealed_texture = _load_runtime_texture(OCEAN_TILE_REVEALED_PATH)
	if _ocean_polluted_texture == null:
		_ocean_polluted_texture = _load_runtime_texture(OCEAN_TILE_POLLUTED_PATH)
	if _ocean_coral_normal_texture == null:
		_ocean_coral_normal_texture = _load_runtime_texture(OCEAN_CORAL_NORMAL_PATH)
	if _ocean_coral_failed_texture == null:
		_ocean_coral_failed_texture = _load_runtime_texture(OCEAN_CORAL_FAILED_PATH)
	if _ocean_coral_wrong_texture == null:
		_ocean_coral_wrong_texture = _load_runtime_texture(OCEAN_CORAL_WRONG_PATH)
	_configure_ocean_typography()


func _configure_ocean_typography() -> void:
	if _level_one_font == null:
		_level_one_font = load(LEVEL_ONE_FONT_PATH) as FontFile
		if _level_one_font == null:
			push_error("Ocean cell font could not be loaded: %s" % LEVEL_ONE_FONT_PATH)
			return
	add_theme_font_override("font", _level_one_font)
	add_theme_color_override("font_outline_color", Color(0.93, 0.98, 0.96, 0.82))
	add_theme_constant_override("outline_size", 2)


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


func _has_point(point: Vector2) -> bool:
	if not _is_hex:
		return Rect2(Vector2.ZERO, size).has_point(point)
	return Geometry2D.is_point_in_polygon(point, _hex_points())


func _hex_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var center := size * 0.5
	var radius := minf(size.y * 0.5, size.x / HEX_HORIZONTAL_FACTOR) * _hex_fill_ratio
	for point_index in 6:
		var angle := deg_to_rad(-90.0 + float(point_index) * 60.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ocean_texture_for_state(state: StringName) -> Texture2D:
	match state:
		&"revealed":
			return _ocean_revealed_texture
		&"polluted":
			return _ocean_polluted_texture
		_:
			return _ocean_hidden_texture


func _ocean_base_texture() -> Texture2D:
	return _ocean_texture_for_state(&"revealed" if _is_revealed else &"hidden")


func _ocean_pollution_amount() -> float:
	if _is_flagged:
		return 0.0
	if procedural_visual == ProceduralVisual.SLUDGE_CORE:
		return 1.0
	return clampf(pollution_progress, 0.0, 1.0)


func _draw_hex_cell() -> void:
	if not _is_hex:
		return
	var radius := minf(size.y * 0.5, size.x / HEX_HORIZONTAL_FACTOR) * _hex_fill_ratio
	var texture_size := Vector2(HEX_HORIZONTAL_FACTOR * radius, radius * 2.0)
	var texture_rect := Rect2((size - texture_size) * 0.5, texture_size)
	var base_texture := _ocean_base_texture()
	if base_texture != null:
		draw_texture_rect(base_texture, texture_rect, false)
	else:
		draw_colored_polygon(_hex_points(), HEX_REVEALED_COLOR if _is_revealed else HEX_HIDDEN_COLOR)

	var pollution_amount := _ocean_pollution_amount()
	var polluted_texture := _ocean_texture_for_state(&"polluted")
	if pollution_amount > 0.0 and polluted_texture != null:
		var pollution_color := Color.WHITE
		pollution_color.a = pollution_amount
		draw_texture_rect(polluted_texture, texture_rect, false, pollution_color)
	if _is_guided:
		draw_colored_polygon(_hex_points(), OCEAN_GUIDE_TINT)


func _draw() -> void:
	_draw_hex_cell()
	_draw_focus_outline()
	_draw_scan_target()
	match procedural_visual:
		ProceduralVisual.BIOSENSOR:
			if _is_hex:
				_draw_ocean_coral(_ocean_marker_texture(&"normal"), biosensor_progress, true)
			else:
				_draw_biosensor()
		ProceduralVisual.SLUDGE_CORE:
			_draw_sludge_core()
		ProceduralVisual.WILTED_SPROUT:
			if _is_hex:
				_draw_ocean_coral(_ocean_marker_texture(&"failed"))
			else:
				_draw_static_sprout(_wilted_sprout_texture, 0.78)
		ProceduralVisual.UPROOTED_SPROUT:
			if _is_hex:
				_draw_ocean_coral(_ocean_marker_texture(&"wrong"))
			else:
				_draw_static_sprout(_uprooted_sprout_texture, 0.86)
	if _is_confirmed:
		_draw_confirmed_badge()
	_draw_scan_result_pulse()
	_draw_hex_number()


func _draw_hex_number() -> void:
	if not _is_hex or text.is_empty():
		return
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_size := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	)
	var baseline := Vector2(
		(size.x - text_size.x) * 0.5,
		(size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	)
	draw_string(
		font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		get_theme_color("font_color")
	)


func _draw_ocean_focus_outline() -> void:
	var outline_color := Color.TRANSPARENT
	var keyboard_outline := false
	if _is_keyboard_selected:
		outline_color = OCEAN_KEYBOARD_DASH_COLOR
		keyboard_outline = true
	elif is_hovered():
		outline_color = OCEAN_HOVER_DASH_COLOR
	else:
		return
	var points := _hex_points()
	var center := size * 0.5
	var inset_scale := 0.70 if keyboard_outline else 0.76
	for point_index in points.size():
		points[point_index] = center + (points[point_index] - center) * inset_scale
	var unit := minf(size.x, size.y)
	var line_width := maxf(2.4, unit * (0.052 if keyboard_outline else 0.038))
	var dash_length := maxf(4.0, unit * (0.085 if keyboard_outline else 0.070))
	for point_index in 6:
		draw_dashed_line(
			points[point_index],
			points[(point_index + 1) % 6],
			outline_color,
			line_width,
			dash_length,
			true,
			true
		)


func _draw_focus_outline() -> void:
	if _input_locked:
		return
	if _is_hex:
		_draw_ocean_focus_outline()
		return
	if not _uses_level_one_art():
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


func _draw_scan_target() -> void:
	if not _scan_target_mode or not _scan_candidate or _input_locked:
		return
	var unit := minf(size.x, size.y)
	var emphasized := is_hovered() or _is_keyboard_selected
	var color := SCAN_TARGET_COLOR
	color.a = 0.96 if emphasized else 0.48
	var line_width := maxf(2.2, unit * (0.050 if emphasized else 0.034))
	if _is_hex:
		var points := _hex_points()
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, color, line_width, true)
		return
	var inset := unit * 0.14
	var arm := unit * 0.16
	var left := inset
	var top := inset
	var right := size.x - inset
	var bottom := size.y - inset
	for segment in [
		[Vector2(left, top + arm), Vector2(left, top), Vector2(left + arm, top)],
		[Vector2(right - arm, top), Vector2(right, top), Vector2(right, top + arm)],
		[Vector2(right, bottom - arm), Vector2(right, bottom), Vector2(right - arm, bottom)],
		[Vector2(left + arm, bottom), Vector2(left, bottom), Vector2(left, bottom - arm)],
	]:
		draw_polyline(PackedVector2Array(segment), color, line_width, true)


func _draw_confirmed_badge() -> void:
	var unit := minf(size.x, size.y)
	if unit <= 1.0:
		return
	var center := Vector2(size.x * 0.77, size.y * 0.24)
	var radius := maxf(4.0, unit * 0.105)
	draw_circle(center, radius + 1.5, Color(0.05, 0.25, 0.28, 0.82))
	draw_circle(center, radius, SCAN_TARGET_COLOR)
	var check_color := Color(0.96, 1.0, 0.91, 1.0)
	draw_line(
		center + Vector2(-radius * 0.45, 0.0),
		center + Vector2(-radius * 0.10, radius * 0.32),
		check_color,
		maxf(1.5, unit * 0.035),
		true
	)
	draw_line(
		center + Vector2(-radius * 0.10, radius * 0.32),
		center + Vector2(radius * 0.50, -radius * 0.38),
		check_color,
		maxf(1.5, unit * 0.035),
		true
	)


func _draw_scan_result_pulse() -> void:
	if _scan_pulse_result < 0:
		return
	var unit := minf(size.x, size.y)
	var progress := clampf(_scan_pulse_progress, 0.0, 1.0)
	var color := SCAN_MINE_COLOR if _scan_pulse_result == SCAN_RESULT_MINE else SCAN_SAFE_COLOR
	color.a = (1.0 - progress) * 0.92
	var center := size * 0.5
	var radius := lerpf(unit * 0.24, unit * 0.50, progress)
	draw_arc(
		center,
		radius,
		0.0,
		TAU,
		40,
		color,
		maxf(2.0, unit * 0.045),
		true
	)


func _ocean_marker_texture(state: StringName) -> Texture2D:
	match state:
		&"failed":
			return _ocean_coral_failed_texture
		&"wrong":
			return _ocean_coral_wrong_texture
		_:
			return _ocean_coral_normal_texture


func _draw_ocean_coral(
	texture: Texture2D,
	progress: float = 1.0,
	animated: bool = false
) -> void:
	var unit := minf(size.x, size.y)
	var reveal := clampf(progress, 0.0, 1.0)
	if texture == null or unit <= 1.0 or reveal <= 0.0:
		return
	var eased := 1.0 - pow(1.0 - reveal, 3.0)
	var marker_size := Vector2.ONE * unit * 0.82
	var center := size * 0.5 + Vector2(0.0, unit * 0.025)
	var rotation := 0.0
	if animated:
		rotation = sin(_idle_time * 2.5 + float(cell_index) * 0.7) * 0.045
	draw_set_transform(
		center,
		rotation,
		Vector2(lerpf(0.82, 1.0, eased), maxf(0.06, eased))
	)
	draw_texture_rect(texture, Rect2(-marker_size * 0.5, marker_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
