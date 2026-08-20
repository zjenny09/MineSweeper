class_name MineCell
extends Button

signal reveal_requested(cell_index: int)
signal flag_requested(cell_index: int)

const DEFAULT_COLOR := Color("334155")
const FLAG_COLOR := Color("facc15")
const MINE_COLOR := Color("dc2626")
const NUMBER_COLORS := {
	0: Color("64748b"),
	1: Color("1d4ed8"),
	2: Color("15803d"),
	3: Color("dc2626"),
	4: Color("6d28d9"),
	5: Color("991b1b"),
	6: Color("0f766e"),
	7: Color("111827"),
	8: Color("475569"),
}

var cell_index := -1
var _hidden_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _revealed_style: StyleBoxFlat


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
	solved_mine: bool = false
) -> void:
	text = ""
	_set_text_color(DEFAULT_COLOR)

	if wrong_flag:
		text = "X"
		_set_text_color(MINE_COLOR)
	elif mine_visible:
		text = "*"
		_set_text_color(MINE_COLOR)
	elif solved_mine or is_flagged:
		text = "F"
		_set_text_color(FLAG_COLOR)
	elif is_revealed and adjacent_count > 0:
		text = str(adjacent_count)
		_set_text_color(NUMBER_COLORS.get(adjacent_count, DEFAULT_COLOR))

	disabled = input_locked or is_revealed
	add_theme_stylebox_override("disabled", _revealed_style if is_revealed else _hidden_style)
	tooltip_text = "空白区域" if is_revealed and adjacent_count == 0 else ("相邻地雷：%d" % adjacent_count if is_revealed else "左键翻开，右键插旗")


func _on_pressed() -> void:
	if not disabled:
		reveal_requested.emit(cell_index)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			flag_requested.emit(cell_index)
			accept_event()


func _configure_styles() -> void:
	_hidden_style = _make_style(Color("1f334d"), Color("48698f"))
	_hover_style = _make_style(Color("31557e"), Color("7aa2d3"))
	_pressed_style = _make_style(Color("17273b"), Color("9bbce3"))
	_revealed_style = _make_style(Color("e2e8f0"), Color("94a3b8"))
	add_theme_stylebox_override("normal", _hidden_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _hidden_style)


func _make_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _set_text_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_focus_color", color)
	add_theme_color_override("font_disabled_color", color)
