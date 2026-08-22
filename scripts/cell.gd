class_name MineCell
extends Button

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)
signal chord_requested(cell_index: int)

const DEFAULT_COLOR := Color("1b2d22")
const FLAG_COLOR := Color("469d65")
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


func _ready() -> void:
	_configure_styles()
	pressed.connect(_on_pressed)


func setup(index: int) -> void:
	cell_index = index


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
		text = "X"
		_set_text_color(MINE_COLOR)
	elif mine_visible:
		text = "●"
		_set_text_color(MINE_COLOR)
	elif solved_mine or is_flagged:
		text = "!"
		_set_text_color(FLAG_COLOR)
	elif is_revealed and adjacent_count > 0:
		text = str(adjacent_count)
		_set_text_color(NUMBER_COLORS.get(adjacent_count, DEFAULT_COLOR))
	elif is_guided:
		text = "↓"
		_set_text_color(GUIDE_COLOR)

	_is_revealed = is_revealed
	_input_locked = input_locked
	if is_revealed:
		add_theme_stylebox_override("normal", _revealed_style)
		add_theme_stylebox_override("hover", _revealed_style)
		add_theme_stylebox_override("pressed", _revealed_style)
	elif is_guided:
		add_theme_stylebox_override("normal", _guide_style)
		add_theme_stylebox_override("hover", _guide_hover_style)
		add_theme_stylebox_override("pressed", _guide_hover_style)
	else:
		add_theme_stylebox_override("normal", _hidden_style)
		add_theme_stylebox_override("hover", _hover_style)
		add_theme_stylebox_override("pressed", _pressed_style)
	disabled = input_locked
	add_theme_stylebox_override("disabled", _revealed_style if is_revealed else _hidden_style)
	if is_guided:
		tooltip_text = "建议从这里开始（也可以忽略）"
	elif is_revealed and adjacent_count == 0:
		tooltip_text = "空白净化区"
	elif is_revealed:
		tooltip_text = "邻近污染核心：%d；双击可快速展开" % adjacent_count
	else:
		tooltip_text = "左键净化，右键标记污染核心"


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
	add_theme_stylebox_override("normal", _hidden_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _hidden_style)


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


func _set_text_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_focus_color", color)
	add_theme_color_override("font_disabled_color", color)
