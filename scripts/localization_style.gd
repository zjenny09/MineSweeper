class_name GreenSweeperLocalizationStyle
extends RefCounted

const ENGLISH_FONT_PATH := "res://assets/fonts/PatrickHand-Regular.ttf"
const ENGLISH_SIZE_SCALE := 0.78
const META_INITIALIZED := &"localization_style_initialized"
const META_HAD_FONT := &"localization_style_had_font"
const META_FONT := &"localization_style_font"
const META_HAD_SIZE := &"localization_style_had_size"
const META_SIZE := &"localization_style_size"

static var _english_font: Font


static func apply(root: Node, locale: String) -> void:
	if not is_instance_valid(root):
		return
	if _english_font == null:
		if ResourceLoader.exists(ENGLISH_FONT_PATH):
			_english_font = load(ENGLISH_FONT_PATH) as Font
		if _english_font == null:
			var dynamic_font := FontFile.new()
			if dynamic_font.load_dynamic_font(
				ProjectSettings.globalize_path(ENGLISH_FONT_PATH)
			) == OK:
				_english_font = dynamic_font
	_apply_to_node(root, locale.begins_with("en"))


static func _apply_to_node(node: Node, english: bool) -> void:
	if node is Label or node is Button or node is LineEdit:
		_apply_to_control(node as Control, english)
	for child in node.get_children():
		_apply_to_node(child, english)


static func _apply_to_control(control: Control, english: bool) -> void:
	if not control.has_meta(META_INITIALIZED):
		var had_font := control.has_theme_font_override("font")
		var had_size := control.has_theme_font_size_override("font_size")
		control.set_meta(META_INITIALIZED, true)
		control.set_meta(META_HAD_FONT, had_font)
		control.set_meta(META_HAD_SIZE, had_size)
		if had_font:
			control.set_meta(META_FONT, control.get_theme_font("font"))
		if had_size:
			control.set_meta(
				META_SIZE,
				control.get_theme_font_size("font_size")
			)
	if english:
		if _english_font != null:
			control.add_theme_font_override("font", _english_font)
		var base_size := (
			int(control.get_meta(META_SIZE))
			if bool(control.get_meta(META_HAD_SIZE))
			else control.get_theme_font_size("font_size")
		)
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * ENGLISH_SIZE_SCALE))
		)
		return
	if bool(control.get_meta(META_HAD_FONT)):
		control.add_theme_font_override(
			"font",
			control.get_meta(META_FONT) as Font
		)
	else:
		control.remove_theme_font_override("font")
	if bool(control.get_meta(META_HAD_SIZE)):
		control.add_theme_font_size_override(
			"font_size",
			int(control.get_meta(META_SIZE))
		)
	else:
		control.remove_theme_font_size_override("font_size")
