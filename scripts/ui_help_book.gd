extends Control

signal back_requested

const Catalog := preload("res://scripts/ui_help_catalog.gd")
const Preview := preload("res://scripts/ui_help_preview.gd")
const LocalizationStyle := preload("res://scripts/localization_style.gd")
const ART := preload("res://scripts/art_catalog.gd")
const CHINESE_FONT: Font = preload(ART.UI_FONT)
const ENGLISH_FONT: Font = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const INDEX_FONT_SIZE := 20
const POPUP_FONT_SIZE := 22

@onready var title_label: Label = %HelpTitle
@onready var section_option: OptionButton = %SectionOption
@onready var index_label: Label = %IndexLabel
@onready var element_index: ItemList = %ElementIndex
@onready var element_title: Label = %ElementTitle
@onready var preview_host: Control = %PreviewHost
@onready var purpose_label: Label = %PurposeLabel
@onready var controls_label: Label = %ControlsLabel
@onready var previous_button: Button = %PreviousButton
@onready var page_label: Label = %PageLabel
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton

var _section: StringName = &"land"
var _page_index := 0
var _keyboard_mode := false
var _preview: Control


func _ready() -> void:
	# Keep the shared crayon theme unchanged for the rest of the shell.
	var book_theme: Theme = theme.duplicate() as Theme
	book_theme.default_font = CHINESE_FONT
	theme = book_theme
	element_index.add_theme_stylebox_override("focus", theme.get_stylebox("focus", "Button"))
	_preview = Preview.new() as Control
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_host.add_child(_preview)
	section_option.item_selected.connect(_on_section_selected)
	element_index.item_selected.connect(_on_element_selected)
	previous_button.pressed.connect(_previous_page)
	next_button.pressed.connect(_next_page)
	back_button.pressed.connect(_request_back)
	refresh_language()


func open_for(section: StringName, keyboard_mode: bool) -> void:
	_section = section if Catalog.PAGES.has(section) else StringName(Catalog.SECTION_ORDER[0])
	_keyboard_mode = keyboard_mode
	_page_index = 0
	refresh_language()
	element_index.grab_focus()


func refresh_language() -> void:
	title_label.text = tr(str(Catalog.LABELS["title"]))
	index_label.text = tr(str(Catalog.LABELS["index"]))
	previous_button.text = tr(str(Catalog.LABELS["previous"]))
	next_button.text = tr(str(Catalog.LABELS["next"]))
	back_button.text = tr(str(Catalog.LABELS["back"]))
	section_option.clear()
	for section_index in range(Catalog.SECTION_ORDER.size()):
		var section: StringName = StringName(Catalog.SECTION_ORDER[section_index])
		section_option.add_item(tr(str(Catalog.SECTION_TITLES[section])))
		if section == _section:
			section_option.select(section_index)
	var pages: Array = Catalog.PAGES[_section]
	element_index.clear()
	for page_value in pages:
		var page: Dictionary = page_value
		var item_title: String = tr(str(page["title"]))
		var item_index: int = element_index.add_item(item_title)
		element_index.set_item_tooltip(item_index, item_title)
	_render_page()


func _render_page() -> void:
	var pages: Array = Catalog.PAGES[_section]
	var page: Dictionary = pages[_page_index]
	element_index.select(_page_index)
	element_index.ensure_current_is_visible()
	element_title.text = tr(str(page["title"]))
	purpose_label.text = tr(str(page["body"]))
	var operation_key: String = str(page.get("keyboard", page.get("mouse", ""))) if _keyboard_mode else str(page.get("mouse", ""))
	controls_label.text = tr(operation_key) if not operation_key.is_empty() else ""
	controls_label.visible = not operation_key.is_empty()
	page_label.text = tr(str(Catalog.LABELS["page"])) % [_page_index + 1, pages.size()]
	previous_button.disabled = _page_index == 0
	next_button.disabled = _page_index == pages.size() - 1
	var preview_spec: Dictionary = page["preview"]
	_preview.call("show_element", preview_spec, _section)
	_apply_locale_style()
	# Font changes can alter row heights after a language switch.
	element_index.call_deferred("ensure_current_is_visible")


func _apply_locale_style() -> void:
	var locale: String = TranslationServer.get_locale()
	LocalizationStyle.apply(self, locale)
	var english: bool = locale.begins_with("en")
	var font: Font = ENGLISH_FONT if english else CHINESE_FONT
	var scale: float = LocalizationStyle.ENGLISH_SIZE_SCALE if english else 1.0
	element_index.add_theme_font_override("font", font)
	element_index.add_theme_font_size_override("font_size", roundi(INDEX_FONT_SIZE * scale))
	var popup: PopupMenu = section_option.get_popup()
	popup.add_theme_font_override("font", font)
	popup.add_theme_font_size_override("font_size", roundi(POPUP_FONT_SIZE * scale))


func _on_section_selected(section_index: int) -> void:
	_section = StringName(Catalog.SECTION_ORDER[section_index])
	_page_index = 0
	refresh_language()
	element_index.grab_focus()


func _on_element_selected(item_index: int) -> void:
	if item_index == _page_index:
		return
	_page_index = item_index
	_render_page()


func _previous_page() -> void:
	_change_page(_page_index - 1)


func _next_page() -> void:
	_change_page(_page_index + 1)


func _change_page(page_index: int) -> void:
	var pages: Array = Catalog.PAGES[_section]
	if page_index < 0 or page_index >= pages.size() or page_index == _page_index:
		return
	_page_index = page_index
	_render_page()


func _request_back() -> void:
	back_requested.emit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.alt_pressed or key_event.ctrl_pressed or key_event.meta_pressed:
		return
	if section_option.has_focus() or section_option.get_popup().visible:
		return
	# Handle directory arrows before ItemList's native selection can consume them.
	# Escape, fullscreen shortcuts and all other shell input remain untouched.
	if event.is_action_pressed("ui_left", true):
		_previous_page()
	elif event.is_action_pressed("ui_right", true):
		_next_page()
	elif element_index.has_focus() and event.is_action_pressed("ui_up", true):
		_previous_page()
	elif element_index.has_focus() and event.is_action_pressed("ui_down", true):
		_next_page()
	else:
		return
	get_viewport().set_input_as_handled()
