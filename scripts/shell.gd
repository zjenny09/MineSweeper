@tool
extends Control

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SKY_GAME_SCENE: PackedScene = preload("res://scenes/sky_level_15_prototype.tscn")
const UNIVERSE_GAME_SCENE: PackedScene = preload("res://scenes/universe_endless.tscn")
const BADGE_BOOK_SCENE: PackedScene = preload("res://scenes/badge_book.tscn")
const BADGE_HALL_SCENE: PackedScene = preload("res://scenes/badge_hall.tscn")
const SAVE_STORE_SCRIPT: Script = preload("res://scripts/save_store.gd")
const OCEAN_ROUTE_SCRIPT: Script = preload("res://scripts/ocean_level_route.gd")
const ART := preload("res://scripts/art_catalog.gd")
const LOCALIZATION_STYLE := preload("res://scripts/localization_style.gd")
const MENU_PRIMARY_PATH := ART.MENU_PRIMARY_NORMAL
const MENU_PRIMARY_SELECTED_PATH := ART.MENU_PRIMARY_HOVER
const MENU_PRIMARY_PRESSED_PATH := ART.MENU_PRIMARY_PRESSED
const MENU_PAPER_PATH := ART.MENU_SECONDARY_NORMAL
const MENU_PAPER_SELECTED_PATH := ART.MENU_SECONDARY_HOVER
const MENU_PAPER_PRESSED_PATH := ART.MENU_SECONDARY_PRESSED
const MENU_FONT_PATH := ART.UI_FONT
const LANGUAGE_CHINESE := "zh_CN"
const LANGUAGE_ENGLISH := "en"
const LEVEL_SELECT_BACKGROUND_PATH := ART.LEVEL_SELECT_DESKTOP_BACKGROUND
const LEVEL_SELECT_MAP_PATH := ART.LEVEL_SELECT_LAND_MAP
const LEVEL_SELECT_INFO_PATH := ART.LEVEL_SELECT_BOTTOM_INFO_BAR
const LEVEL_SELECT_MARKER_PATH := ART.LEVEL_SELECT_MARKER_BUTTON
const LEVEL_SELECT_SHORTCUT_PATH := ART.LEVEL_SELECT_SHORTCUT_BUTTON
const OCEAN_LEVEL_SELECT_BACKGROUND_PATH := ART.OCEAN_LEVEL_SELECT_BACKGROUND
const OCEAN_LEVEL_SELECT_MAP_PATH := ART.OCEAN_LEVEL_SELECT_MAP
const OCEAN_LEVEL_SELECT_MARKER_PATH := ART.OCEAN_LEVEL_SELECT_MARKER
const OCEAN_LEVEL_SELECT_FINAL_MARKER_PATH := ART.OCEAN_LEVEL_SELECT_FINAL_MARKER
const SKY_LEVEL_SELECT_MAP_PATH := ART.SKY_LEVEL_SELECT_MAP
const LAND_LEVEL_MARKER_POSITIONS := [
	Vector2(110, 325),
	Vector2(230, 250),
	Vector2(330, 270),
	Vector2(410, 180),
	Vector2(505, 245),
	Vector2(610, 175),
	Vector2(825, 145),
]
const OCEAN_LEVEL_MARKER_POSITIONS := [
	Vector2(105, 230),
	Vector2(230, 135),
	Vector2(355, 232),
	Vector2(480, 130),
	Vector2(605, 232),
	Vector2(730, 135),
	Vector2(855, 232),
]

const SKY_LEVEL_MARKER_POSITIONS := [
	Vector2(92, 326),
	Vector2(225, 248),
	Vector2(360, 270),
	Vector2(468, 184),
	Vector2(575, 250),
	Vector2(710, 178),
	Vector2(842, 112),
]
const MECHANIC_GUIDE_FIRST_LEVELS := {
	&"eco_scan": 1,
	&"land_obstacles": 3,
	&"pollution_nodes": 5,
	&"ancient_tree_roots": 7,
	&"hex_ocean_board": 8,
	&"coral_reefs": 9,
	&"drifting_mines": 11,
	&"tidal_zones": 13,
	&"sky_sphere": 15,
	&"sky_breeze": 17,
	&"storm_shield": 19,
	&"storm_eyes": 20,
}

@export var save_path := "user://save_v1.json"

@onready var game_host: Control = %GameHost
@onready var main_menu: Control = %MainMenu
@onready var level_select: Control = %LevelSelect
@onready var settings_page: Control = %Settings
@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var choose_level_button: Button = %ChooseLevelButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var menu_title: Label = \
		$MainMenu/PageMargin/Columns/MenuPanel/Margin/VBox/Title
@onready var menu_chinese_title: Label = \
		$MainMenu/PageMargin/Columns/MenuPanel/Margin/VBox/ChineseTitle
@onready var menu_tagline: Label = \
		$MainMenu/PageMargin/Columns/MenuPanel/Margin/VBox/Tagline
@onready var level_grid: Control = %LevelGrid
@onready var level_map_root: Control = $LevelSelect/LevelMapRoot
@onready var level_select_title: Label = $LevelSelect/LevelSelectTitle
@onready var progress_label: Label = %ProgressLabel
@onready var level_select_background: TextureRect = %LevelSelectBackground
@onready var level_map_artwork: TextureRect = %LevelMapArtwork
@onready var level_info_artwork: TextureRect = %LevelInfoArtwork
@onready var selected_level_label: Label = %SelectedLevelLabel
@onready var selected_level_status_label: Label = %SelectedLevelStatusLabel
@onready var selected_best_time_label: Label = %SelectedBestTimeLabel
@onready var level_back_button: Button = %LevelBackButton
@onready var level_help_button: Button = %LevelHelpButton
@onready var level_badge_book_button: Button = %LevelBadgeBookButton
@onready var level_previous_chapter_button: Button = %LevelPreviousChapterButton
@onready var level_next_chapter_button: Button = %LevelNextChapterButton
@onready var level_welcome_button: Button = %LevelWelcomeButton
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var bgm_toggle_button: CheckButton = %BgmToggleButton
@onready var sfx_toggle_button: CheckButton = %SfxToggleButton
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var operation_mode_option: OptionButton = %OperationModeOption
@onready var language_option: OptionButton = %LanguageOption
@onready var settings_help_button: Button = %SettingsHelpButton
@onready var settings_badge_book_button: Button = %SettingsBadgeBookButton
@onready var settings_back_button: Button = %SettingsBackButton
@onready var help_page: Control = %Help
@onready var help_text: RichTextLabel = %HelpText
@onready var help_back_button: Button = %HelpBackButton

var save_store
var active_game: Control
var badge_book: BadgeBook
var badge_hall: BadgeHall
var _record_progress := true
var _persist_scan_state := true
var _persist_guide_state := true
var _persist_universe_progress := true
var _universe_milestone_hall_pending := false
var _session_seen_mechanic_guides: Dictionary = {}
var _settings_return_to_game := false
var _help_return_page := &"level_select"
var _badge_hall_return_page := &"main_menu"
var _badge_book_return_page := &"level_select"
var _badge_book_victory_level := 0
var _badge_book_chapter := &"land"
var _level_select_return_to_game := false
var _level_select_chapter := &"land"
var _selected_level_number := 1
var _selected_land_level_number := 1
var _selected_ocean_level_number := 8
var _selected_sky_level_number := 15
var _level_marker_buttons: Dictionary = {}
var _level_marker_texture: Texture2D
var _ocean_level_marker_texture: Texture2D
var _ocean_final_marker_texture: Texture2D
var _level_select_land_background: Texture2D
var _level_select_land_map: Texture2D
var _level_select_ocean_background: Texture2D
var _level_select_ocean_map: Texture2D
var _level_select_sky_map: Texture2D
var _runtime_texture_cache: Dictionary = {}
var _chapter_transition_running := false


func _ready() -> void:
	_apply_menu_typography()
	_apply_menu_button_art()
	_apply_level_select_art()
	if Engine.is_editor_hint():
		return
	badge_book = BADGE_BOOK_SCENE.instantiate() as BadgeBook
	add_child(badge_book)
	badge_book.closed.connect(_close_badge_book)
	badge_book.next_level_requested.connect(_continue_from_badge_book)
	badge_book.return_to_victory_requested.connect(_return_to_victory_from_badge_book)
	badge_book.hall_requested.connect(_show_badge_hall_from_book)
	badge_hall = BADGE_HALL_SCENE.instantiate() as BadgeHall
	add_child(badge_hall)
	badge_hall.chapter_book_requested.connect(
		_on_badge_hall_chapter_book_requested
	)
	badge_hall.exit_requested.connect(_close_badge_hall)
	save_store = SAVE_STORE_SCRIPT.new(save_path)
	save_store.load_data()
	TranslationServer.set_locale(save_store.get_language())
	volume_slider.value = save_store.get_master_volume()
	AudioManager.set_bgm_enabled(save_store.is_bgm_enabled())
	AudioManager.set_sfx_enabled(save_store.is_sfx_enabled())
	_refresh_settings_options()
	_refresh_audio_toggle_buttons()
	_on_volume_changed(volume_slider.value)
	LOCALIZATION_STYLE.apply(self, save_store.get_language())
	_apply_display_mode(display_mode_option.selected)
	_connect_controls()

	var user_arguments := OS.get_cmdline_user_args()
	if user_arguments.has("--universe"):
		_start_universe_mode(false)
		return
	var requested_level := parse_level_argument(user_arguments)
	if requested_level > 0:
		start_cli_level(requested_level)
	else:
		if requested_level < 0:
			push_error(tr("TXT_0414"))
		show_main_menu()


func _apply_menu_typography() -> void:
	var menu_font := load(MENU_FONT_PATH) as FontFile
	if menu_font == null:
		push_error("Menu display font could not be loaded: %s" % MENU_FONT_PATH)
		return
	for label in [menu_title, menu_chinese_title, menu_tagline]:
		label.add_theme_font_override("font", menu_font)


func _apply_menu_button_art() -> void:
	var primary_normal := _load_menu_style(MENU_PRIMARY_PATH)
	var primary_selected := _load_menu_style(MENU_PRIMARY_SELECTED_PATH)
	var primary_pressed := _load_menu_style(MENU_PRIMARY_PRESSED_PATH)
	var paper_normal := _load_menu_style(MENU_PAPER_PATH)
	var paper_selected := _load_menu_style(MENU_PAPER_SELECTED_PATH)
	var paper_pressed := _load_menu_style(MENU_PAPER_PRESSED_PATH)
	if primary_normal == null or primary_selected == null \
			or primary_pressed == null or paper_normal == null \
			or paper_selected == null or paper_pressed == null:
		return
	_apply_button_styles(
		start_button,
		primary_normal,
		primary_selected,
		primary_pressed,
		Color(1.0, 1.0, 1.0),
		Color(0.04, 0.16, 0.08, 0.72),
		18
	)
	_apply_button_styles(
		continue_button,
		primary_normal,
		primary_selected,
		primary_pressed,
		Color(1.0, 1.0, 1.0),
		Color(0.04, 0.16, 0.08, 0.72),
		18
	)
	for button in [choose_level_button, settings_button, exit_button]:
		_apply_button_styles(
			button,
			paper_normal,
			paper_selected,
			paper_pressed,
			Color(0.1059, 0.302, 0.176),
			Color(1.0, 0.98, 0.87, 0.88),
			17
		)


func _apply_level_select_art() -> void:
	_level_select_land_background = _load_runtime_texture(LEVEL_SELECT_BACKGROUND_PATH)
	_level_select_land_map = _load_runtime_texture(LEVEL_SELECT_MAP_PATH)
	_level_select_ocean_background = _load_runtime_texture(
		OCEAN_LEVEL_SELECT_BACKGROUND_PATH
	)
	_level_select_ocean_map = _load_runtime_texture(OCEAN_LEVEL_SELECT_MAP_PATH)
	_level_select_sky_map = _load_runtime_texture(SKY_LEVEL_SELECT_MAP_PATH)
	_level_marker_texture = _load_runtime_texture(LEVEL_SELECT_MARKER_PATH)
	_ocean_level_marker_texture = _load_runtime_texture(
		OCEAN_LEVEL_SELECT_MARKER_PATH
	)
	_ocean_final_marker_texture = _load_runtime_texture(
		OCEAN_LEVEL_SELECT_FINAL_MARKER_PATH
	)
	level_info_artwork.texture = _load_runtime_texture(LEVEL_SELECT_INFO_PATH)
	_apply_level_select_chapter_art()
	var shortcut_texture := _load_runtime_texture(LEVEL_SELECT_SHORTCUT_PATH)
	if shortcut_texture == null:
		return
	for button in [
		level_back_button,
		level_help_button,
		level_badge_book_button,
		level_previous_chapter_button,
		level_next_chapter_button,
		level_welcome_button,
	]:
		var style := StyleBoxTexture.new()
		style.texture = shortcut_texture
		style.content_margin_left = 8.0
		style.content_margin_top = 4.0
		style.content_margin_right = 8.0
		style.content_margin_bottom = 4.0
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style.duplicate())
		button.add_theme_stylebox_override("pressed", style.duplicate())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", Color("fff7df"))
		button.add_theme_color_override("font_focus_color", Color("fff7df"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color("e8f2d8"))
		button.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.65))
		button.add_theme_constant_override("outline_size", 1)
		button.add_theme_font_size_override("font_size", 12)


func _apply_level_select_chapter_art() -> void:
	var ocean := _level_select_chapter == &"ocean"
	var sky := _level_select_chapter == &"sky"
	level_select_background.texture = (
		_level_select_ocean_background
		if ocean
		else _level_select_land_background
	)
	if sky:
		level_map_artwork.texture = _level_select_sky_map
	elif ocean:
		level_map_artwork.texture = _level_select_ocean_map
	else:
		level_map_artwork.texture = _level_select_land_map
	level_map_artwork.stretch_mode = (
		TextureRect.STRETCH_SCALE
		if ocean
		else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	if sky:
		level_select_title.text = tr("TXT_0056")
		level_select_title.add_theme_color_override("font_color", Color("49658f"))
		level_previous_chapter_button.text = tr("TXT_0044")
		level_previous_chapter_button.tooltip_text = tr("TXT_0037")
		level_next_chapter_button.text = tr("TXT_0048")
		level_next_chapter_button.tooltip_text = tr("TXT_0042")
	elif ocean:
		level_select_title.text = tr("TXT_0055")
		level_select_title.add_theme_color_override("font_color", Color("175c70"))
		level_previous_chapter_button.text = tr("TXT_0043")
		level_previous_chapter_button.tooltip_text = tr("TXT_0036")
		level_next_chapter_button.text = tr("TXT_0047")
		level_next_chapter_button.tooltip_text = tr("TXT_0040")
	else:
		level_select_title.text = tr("TXT_0054")
		level_select_title.add_theme_color_override("font_color", Color("1b4d2d"))
		level_previous_chapter_button.text = tr("TXT_0045")
		level_previous_chapter_button.tooltip_text = tr("TXT_0038")
		level_next_chapter_button.text = tr("TXT_0046")
		level_next_chapter_button.tooltip_text = tr("TXT_0039")
	var shortcut_font_size := (
		10
		if save_store != null and save_store.get_language() == LANGUAGE_ENGLISH
		else 12
	)
	for button in [
		level_back_button,
		level_help_button,
		level_badge_book_button,
		level_previous_chapter_button,
		level_next_chapter_button,
		level_welcome_button,
	]:
		button.add_theme_font_size_override("font_size", shortcut_font_size)
	if ocean:
		level_select_title.offset_top = 96.0
		level_select_title.offset_bottom = 152.0
		level_map_root.offset_left = -490.0
		level_map_root.offset_top = -210.0
		level_map_root.offset_right = 490.0
		level_map_root.offset_bottom = 225.0
		level_map_root.rotation = deg_to_rad(-1.0)
	elif sky:
		level_select_title.offset_top = 108.0
		level_select_title.offset_bottom = 164.0
		level_map_root.offset_left = -490.0
		level_map_root.offset_top = -205.0
		level_map_root.offset_right = 490.0
		level_map_root.offset_bottom = 225.0
		level_map_root.rotation = deg_to_rad(-1.0)
	else:
		level_select_title.offset_top = 125.0
		level_select_title.offset_bottom = 181.0
		level_map_root.offset_left = -470.0
		level_map_root.offset_top = -190.0
		level_map_root.offset_right = 470.0
		level_map_root.offset_bottom = 230.0
		level_map_root.rotation = deg_to_rad(-4.5)


func _load_runtime_texture(path: String) -> Texture2D:
	if _runtime_texture_cache.has(path):
		return _runtime_texture_cache[path] as Texture2D
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Shell artwork could not be loaded: %s" % path)
		return null
	_runtime_texture_cache[path] = texture
	return texture


func _load_menu_style(path: String) -> StyleBoxTexture:
	var texture := _load_runtime_texture(path)
	if texture == null:
		push_error("Menu paper artwork could not be loaded: %s" % path)
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	style.expand_margin_left = 3.0
	style.expand_margin_top = 3.0
	style.expand_margin_right = 3.0
	style.expand_margin_bottom = 5.0
	return style


func _apply_button_styles(
	button: Button,
	normal_style: StyleBoxTexture,
	hover_style: StyleBoxTexture,
	pressed_style: StyleBoxTexture,
	focus_font_color: Color,
	outline_color: Color,
	font_size: int
) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_focus_color", focus_font_color)
	button.add_theme_color_override("font_outline_color", outline_color)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", font_size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and save_store != null:
		save_store.save_data()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var toggles_display := key_event.keycode == KEY_F11 \
					or (key_event.keycode == KEY_ENTER and key_event.alt_pressed)
			if toggles_display:
				_toggle_display_mode()
				get_viewport().set_input_as_handled()
				return
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_instance_valid(badge_book) and badge_book.visible:
		badge_book.request_close()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(badge_hall) and badge_hall.visible:
		_close_badge_hall()
		get_viewport().set_input_as_handled()
	elif help_page.visible:
		_close_help()
		get_viewport().set_input_as_handled()
	elif settings_page.visible:
		_close_settings()
		get_viewport().set_input_as_handled()
	elif level_select.visible:
		_on_level_back_pressed()
		get_viewport().set_input_as_handled()


func show_main_menu() -> void:
	if is_instance_valid(settings_page) and settings_page.visible and save_store != null:
		save_store.save_data()
	_settings_return_to_game = false
	_level_select_return_to_game = false
	_destroy_active_game()
	_show_only(main_menu)
	AudioManager.play_menu_bgm()
	_refresh_continue_button()
	start_button.grab_focus()


func show_level_select(preserve_active_game: bool = false) -> void:
	_settings_return_to_game = false
	_level_select_return_to_game = preserve_active_game and is_instance_valid(active_game)
	if _level_select_return_to_game:
		var active_level_number := int(active_game.get("current_level_index")) + 1
		if active_level_number >= 15:
			_level_select_chapter = &"sky"
		elif active_level_number >= 8:
			_level_select_chapter = &"ocean"
		else:
			_level_select_chapter = &"land"
	else:
		_level_select_chapter = &"land"
		_destroy_active_game()
	if _level_select_chapter == &"sky":
		_selected_level_number = _selected_sky_level_number
	elif _level_select_chapter == &"ocean":
		_selected_level_number = _selected_ocean_level_number
	else:
		_selected_level_number = _selected_land_level_number
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	_show_only(level_select)
	AudioManager.play_menu_bgm()
	level_back_button.text = tr("TXT_0034")
	level_back_button.grab_focus()


func show_settings(return_to_game: bool = false) -> void:
	_settings_return_to_game = return_to_game and is_instance_valid(active_game)
	_show_only(settings_page)
	volume_slider.grab_focus()


func _show_help(return_page: StringName) -> void:
	_help_return_page = return_page
	_show_only(help_page)
	help_text.scroll_to_line(0)
	help_text.grab_focus()


func _close_help() -> void:
	if _help_return_page == &"game" and is_instance_valid(active_game):
		_show_only(game_host)
		var pause_help := active_game.get_node_or_null("%PauseHelpButton") as Button
		if pause_help != null:
			pause_help.grab_focus()
		return
	if _help_return_page == &"settings":
		_show_only(settings_page)
		settings_help_button.grab_focus()
		return
	_show_only(level_select)
	level_help_button.grab_focus()


func _completed_level_numbers(extra_level: int = 0) -> Array[int]:
	var completed_levels: Array[int] = []
	for level_number in range(1, 22):
		if save_store.is_level_completed(level_number):
			completed_levels.append(level_number)
	if extra_level > 0 and extra_level not in completed_levels:
		completed_levels.append(extra_level)
	return completed_levels


func _show_badge_hall(
	return_page: StringName,
	focus_chapter: StringName = &"land"
) -> void:
	_badge_hall_return_page = return_page
	badge_hall.set_completed_levels(_completed_level_numbers())
	badge_hall.set_universe_progress(
		save_store.get_universe_boards_created(),
		save_store.has_triggered_universe_thousand_milestone()
	)
	_show_only(badge_hall)
	badge_hall.focus_chapter(focus_chapter)


func _close_badge_hall() -> void:
	badge_hall.visible = false
	if _badge_hall_return_page == &"settings":
		_show_only(settings_page)
		settings_badge_book_button.grab_focus()
		return
	if _badge_hall_return_page == &"game" and is_instance_valid(active_game):
		_show_only(game_host)
		if _universe_milestone_hall_pending:
			_universe_milestone_hall_pending = false
			if active_game.has_method("continue_after_universe_milestone_hall"):
				active_game.call("continue_after_universe_milestone_hall")
		var advance_button := active_game.get_node_or_null("%RestartButton") as Control
		if advance_button != null:
			advance_button.grab_focus()
		return
	if _badge_hall_return_page == &"main_menu":
		_show_only(main_menu)
		choose_level_button.grab_focus()
		return
	_show_only(level_select)
	level_badge_book_button.grab_focus()


func _on_badge_hall_chapter_book_requested(chapter: StringName) -> void:
	_show_badge_book(&"badge_hall", 0, chapter)


func _show_badge_hall_from_book() -> void:
	var return_page := _badge_hall_return_page
	if _badge_book_return_page == &"game":
		return_page = &"game"
	elif _badge_book_return_page != &"badge_hall":
		return_page = _badge_book_return_page
	badge_book.visible = false
	_show_badge_hall(return_page, _badge_book_chapter)


func _show_badge_book(
	return_page: StringName,
	victory_level: int = 0,
	chapter: StringName = &""
) -> void:
	_badge_book_return_page = return_page
	_badge_book_victory_level = victory_level
	if chapter != &"":
		_badge_book_chapter = chapter
	elif victory_level >= 15:
		_badge_book_chapter = &"sky"
	elif victory_level >= 8:
		_badge_book_chapter = &"ocean"
	else:
		_badge_book_chapter = &"land"
	_show_only(badge_book)
	badge_book.open_book(
		_completed_level_numbers(victory_level),
		return_page,
		victory_level,
		chapter
	)


func _close_badge_book() -> void:
	badge_book.visible = false
	if _badge_book_return_page == &"badge_hall":
		_show_badge_hall(_badge_hall_return_page, _badge_book_chapter)
		return
	if _badge_book_return_page == &"settings":
		_show_only(settings_page)
		settings_badge_book_button.grab_focus()
		return
	if _badge_book_return_page == &"game" and is_instance_valid(active_game):
		_return_to_victory_from_badge_book()
		return
	if _badge_book_return_page == &"main_menu":
		_show_only(main_menu)
		choose_level_button.grab_focus()
		return
	_show_only(level_select)
	level_badge_book_button.grab_focus()


func _continue_from_badge_book() -> void:
	if _badge_book_return_page != &"game" or not is_instance_valid(active_game):
		return
	badge_book.visible = false
	_show_only(game_host)
	active_game.call("continue_after_badge_book")
	_badge_book_return_page = &"level_select"
	_badge_book_victory_level = 0


func _return_to_victory_from_badge_book() -> void:
	if not is_instance_valid(active_game):
		show_level_select()
		return
	badge_book.visible = false
	_show_only(game_host)
	var advance_button := active_game.get_node_or_null("%RestartButton") as Control
	if advance_button != null:
		advance_button.grab_focus()
	_badge_book_return_page = &"level_select"
	_badge_book_victory_level = 0


func _close_settings() -> void:
	save_store.save_data()
	if _settings_return_to_game and is_instance_valid(active_game):
		_settings_return_to_game = false
		_show_only(game_host)
		active_game.get_node("%ResumeButton").grab_focus()
	else:
		show_main_menu()


func start_normal_level(level_number: int) -> void:
	_start_level_number(level_number, true, true)


func start_cli_level(level_number: int) -> void:
	_start_level_number(level_number, false, false)


func _start_universe_mode(persist_guides: bool = true) -> void:
	_level_select_return_to_game = false
	_destroy_active_game()
	AudioManager.play_universe_bgm()
	_record_progress = false
	_persist_scan_state = false
	_persist_guide_state = persist_guides
	_persist_universe_progress = persist_guides
	active_game = UNIVERSE_GAME_SCENE.instantiate() as Control
	active_game.set("auto_start", false)
	game_host.add_child(active_game)
	active_game.level_select_requested.connect(_on_universe_return_to_sky)
	active_game.main_menu_requested.connect(show_main_menu)
	active_game.settings_requested.connect(_on_game_settings_requested)
	active_game.help_requested.connect(_on_game_help_requested)
	active_game.mechanic_guide_completed.connect(_on_game_mechanic_guide_completed)
	active_game.universe_board_created.connect(_on_universe_board_created)
	active_game.universe_milestone_finished.connect(
		_on_universe_milestone_finished
	)
	active_game.exit_game_requested.connect(func() -> void: get_tree().quit())
	active_game.call(
		"set_seen_mechanic_guides",
		_combined_seen_mechanic_guides()
	)
	_show_only(game_host)
	active_game.call("start_endless", 0)
	active_game.call("set_operation_mode", save_store.get_operation_mode())
	LOCALIZATION_STYLE.apply(active_game, save_store.get_language())


func _on_universe_board_created() -> void:
	if not _persist_universe_progress:
		return
	var should_trigger: bool = bool(
		save_store.record_universe_board_created()
	)
	if not save_store.save_data():
		save_store.load_data()
		push_error("Universe lifetime progress could not be saved.")
		return
	if should_trigger and is_instance_valid(active_game) \
			and active_game.has_method("show_thousand_board_celebration"):
		active_game.call("show_thousand_board_celebration")


func _on_universe_milestone_finished() -> void:
	if not is_instance_valid(active_game):
		return
	_universe_milestone_hall_pending = true
	_show_badge_hall(&"game", &"universe")
	if badge_hall.has_method("play_universe_trophy_placement"):
		badge_hall.call("play_universe_trophy_placement")


func _on_universe_return_to_sky() -> void:
	_level_select_return_to_game = false
	_destroy_active_game()
	_level_select_chapter = &"sky"
	_selected_sky_level_number = 21
	_selected_level_number = 21
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	_show_only(level_select)
	AudioManager.play_menu_bgm()
	level_back_button.text = tr("TXT_0034")
	level_back_button.grab_focus()


func get_active_game() -> Control:
	return active_game


func is_cli_read_only() -> bool:
	return active_game != null and not _persist_scan_state


func parse_level_argument(arguments: PackedStringArray) -> int:
	var requested := 0
	for argument in arguments:
		if not argument.begins_with("--level="):
			continue
		if requested != 0:
			return -1
		var raw_value := argument.trim_prefix("--level=")
		if raw_value.is_empty() or not raw_value.is_valid_int():
			return -1
		requested = int(raw_value)
		if not GreenSweeperLevels.is_valid_level_number(requested):
			return -1
	return requested


func _connect_controls() -> void:
	start_button.pressed.connect(_on_start_journey_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	choose_level_button.pressed.connect(_show_badge_hall.bind(&"main_menu"))
	settings_button.pressed.connect(show_settings)
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	level_back_button.pressed.connect(_on_level_back_pressed)
	level_help_button.pressed.connect(_show_help.bind(&"level_select"))
	level_badge_book_button.pressed.connect(
		_show_badge_hall.bind(&"level_select")
	)
	level_previous_chapter_button.pressed.connect(_on_previous_chapter_pressed)
	level_next_chapter_button.pressed.connect(_on_next_chapter_pressed)
	level_welcome_button.pressed.connect(show_main_menu)
	settings_help_button.pressed.connect(_show_help.bind(&"settings"))
	settings_badge_book_button.pressed.connect(
		_show_badge_hall.bind(&"settings")
	)
	settings_back_button.pressed.connect(_close_settings)
	help_back_button.pressed.connect(_close_help)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	bgm_toggle_button.toggled.connect(_on_bgm_toggled)
	sfx_toggle_button.toggled.connect(_on_sfx_toggled)
	display_mode_option.item_selected.connect(_on_display_mode_selected)
	operation_mode_option.item_selected.connect(_on_operation_mode_selected)
	language_option.item_selected.connect(_on_language_selected)


func _start_level_number(
	level_number: int,
	record_progress: bool,
	persist_scan_state: bool
) -> void:
	if not GreenSweeperLevels.is_valid_level_number(level_number):
		return
	if record_progress and not save_store.is_level_unlocked(level_number):
		return

	_level_select_return_to_game = false
	_destroy_active_game()
	_record_progress = record_progress
	_persist_scan_state = persist_scan_state
	_persist_guide_state = record_progress
	AudioManager.play_level_bgm(level_number)
	var game_scene := SKY_GAME_SCENE if level_number >= 15 else GAME_SCENE
	active_game = game_scene.instantiate() as Control
	active_game.set("auto_start", false)
	game_host.add_child(active_game)
	active_game.level_started.connect(_on_game_level_started)
	active_game.level_completed.connect(_on_game_level_completed)
	active_game.scan_energy_changed.connect(_on_game_scan_energy_changed)
	active_game.level_select_requested.connect(_on_game_level_select_requested)
	active_game.chapter_advance_requested.connect(_on_game_chapter_advance_requested)
	active_game.main_menu_requested.connect(show_main_menu)
	active_game.settings_requested.connect(_on_game_settings_requested)
	active_game.help_requested.connect(_on_game_help_requested)
	if active_game.has_signal("badge_book_requested"):
		active_game.connect("badge_book_requested", _on_game_badge_book_requested)
	active_game.mechanic_guide_completed.connect(_on_game_mechanic_guide_completed)
	active_game.exit_game_requested.connect(func() -> void: get_tree().quit())
	active_game.call(
		"set_seen_mechanic_guides",
		_seen_mechanic_guides_for_level(level_number, not record_progress)
	)
	active_game.call(
		"set_first_move_guide_enabled",
		not save_store.has_seen_first_move_guide()
	)
	var initial_scan_energy := 0
	if _persist_scan_state:
		if level_number == 1 and save_store.claim_level_one_scan_grant():
			save_store.save_data()
		initial_scan_energy = save_store.get_scan_energy()
	_show_only(game_host)
	active_game.start_level(
		GreenSweeperLevels.level_index_from_number(level_number),
		initial_scan_energy
	)
	active_game.call("set_operation_mode", save_store.get_operation_mode())
	LOCALIZATION_STYLE.apply(active_game, save_store.get_language())


func _on_start_journey_pressed() -> void:
	_selected_land_level_number = 1
	_selected_level_number = 1
	_level_select_chapter = &"land"
	show_level_select()


func _on_continue_pressed() -> void:
	var level_number: int = save_store.get_last_played_level()
	if level_number > 0 and save_store.is_level_unlocked(level_number):
		start_normal_level(level_number)


func _on_game_level_started(level_number: int) -> void:
	AudioManager.play_level_bgm(level_number)
	if not _record_progress:
		return
	save_store.mark_level_started(level_number)
	if level_number == 1:
		save_store.mark_first_move_guide_seen()
	save_store.save_data()


func _on_game_level_completed(level_number: int, elapsed_ms: int) -> void:
	if not _record_progress:
		return
	save_store.record_completion(level_number, elapsed_ms)
	save_store.save_data()


func _transition_to_ocean_chapter() -> void:
	if _chapter_transition_running:
		return
	_chapter_transition_running = true
	if not is_instance_valid(active_game):
		_chapter_transition_running = false
		return

	_selected_land_level_number = 7
	_selected_level_number = 7
	_level_select_chapter = &"land"
	_level_select_return_to_game = false
	_destroy_active_game()
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	_show_only(level_select)
	await get_tree().process_frame
	level_select.pivot_offset = level_select.size * 0.5
	level_select.scale = Vector2.ONE
	level_select.rotation = 0.0
	await get_tree().create_timer(0.45).timeout

	var close_tween := create_tween()
	close_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	close_tween.tween_property(level_select, "scale:x", 0.06, 0.34)
	close_tween.parallel().tween_property(level_select, "rotation", deg_to_rad(-1.8), 0.34)
	await close_tween.finished

	_level_select_chapter = &"ocean"
	_selected_ocean_level_number = 8
	_selected_level_number = 8
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	level_select.rotation = deg_to_rad(1.8)

	var open_tween := create_tween()
	open_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	open_tween.tween_property(level_select, "scale:x", 1.0, 0.42)
	open_tween.parallel().tween_property(level_select, "rotation", 0.0, 0.42)
	await open_tween.finished
	level_select.scale = Vector2.ONE
	level_select.rotation = 0.0
	_chapter_transition_running = false
	level_next_chapter_button.grab_focus()


func _transition_to_sky_chapter() -> void:
	if _chapter_transition_running:
		return
	_chapter_transition_running = true
	if not is_instance_valid(active_game):
		_chapter_transition_running = false
		return

	_selected_ocean_level_number = 14
	_selected_level_number = 14
	_level_select_chapter = &"ocean"
	_level_select_return_to_game = false
	_destroy_active_game()
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	_show_only(level_select)
	await get_tree().process_frame
	level_select.pivot_offset = level_select.size * 0.5
	level_select.scale = Vector2.ONE
	level_select.rotation = 0.0
	await get_tree().create_timer(0.85).timeout

	var close_tween := create_tween()
	close_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	close_tween.tween_property(level_select, "scale:x", 0.06, 0.34)
	close_tween.parallel().tween_property(level_select, "rotation", deg_to_rad(-1.8), 0.34)
	await close_tween.finished

	_level_select_chapter = &"sky"
	_selected_sky_level_number = 15
	_selected_level_number = 15
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	level_select.rotation = deg_to_rad(1.8)

	var open_tween := create_tween()
	open_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	open_tween.tween_property(level_select, "scale:x", 1.0, 0.42)
	open_tween.parallel().tween_property(level_select, "rotation", 0.0, 0.42)
	await open_tween.finished
	level_select.scale = Vector2.ONE
	level_select.rotation = 0.0
	_chapter_transition_running = false
	level_next_chapter_button.grab_focus()


func _on_game_scan_energy_changed(energy: int) -> void:
	if not _persist_scan_state:
		return
	save_store.set_scan_energy(energy)
	save_store.save_data()


func _combined_seen_mechanic_guides() -> Array[String]:
	var guide_ids: Array[String] = save_store.get_seen_mechanic_guides()
	for stored_id in _session_seen_mechanic_guides:
		var guide_id := str(stored_id)
		if not guide_id.is_empty() and guide_id not in guide_ids:
			guide_ids.append(guide_id)
	return guide_ids


func _seen_mechanic_guides_for_level(
	level_number: int,
	assume_previous_guides: bool
) -> Array[String]:
	var guide_ids := _combined_seen_mechanic_guides()
	for guide_key in MECHANIC_GUIDE_FIRST_LEVELS:
		var first_level := int(MECHANIC_GUIDE_FIRST_LEVELS[guide_key])
		var guide_id := str(guide_key)
		if first_level == level_number:
			guide_ids.erase(guide_id)
		elif assume_previous_guides and first_level < level_number \
				and guide_id not in guide_ids:
			guide_ids.append(guide_id)
	return guide_ids


func _on_game_mechanic_guide_completed(guide_id: StringName) -> void:
	if guide_id.is_empty():
		return
	_session_seen_mechanic_guides[guide_id] = true
	if not _persist_guide_state:
		return
	save_store.mark_mechanic_guide_seen(guide_id)
	save_store.save_data()


func _on_game_chapter_advance_requested() -> void:
	if not is_instance_valid(active_game):
		return
	var level_number := int(active_game.get("current_level_index")) + 1
	if level_number == 7 \
			and (not _record_progress or save_store.is_level_completed(7)):
		call_deferred("_transition_to_ocean_chapter")
	elif level_number == 14 \
			and (not _record_progress or save_store.is_level_completed(14)):
		call_deferred("_transition_to_sky_chapter")
	elif level_number == 21 \
			and (not _record_progress or save_store.is_level_completed(21)):
		call_deferred("_start_universe_mode")


func _on_game_level_select_requested() -> void:
	show_level_select(true)


func _on_game_settings_requested() -> void:
	show_settings(true)


func _on_game_help_requested() -> void:
	_show_help(&"game")


func _on_game_badge_book_requested(level_number: int) -> void:
	_show_badge_book(&"game", level_number)


func _rebuild_level_cards() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
		child.free()
	_level_marker_buttons.clear()

	var chapter_levels: Array = _chapter_levels()
	if _level_select_chapter == &"ocean":
		var route := OCEAN_ROUTE_SCRIPT.new() as Control
		route.name = "OceanLevelRoute"
		route.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_grid.add_child(route)
		route.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		route.set("marker_positions", PackedVector2Array(OCEAN_LEVEL_MARKER_POSITIONS))

	var completed_count := 0
	for level in chapter_levels:
		if _is_select_level_completed(int(level.number)):
			completed_count += 1

	if not _is_level_in_current_chapter(_selected_level_number) \
			or not _is_select_level_unlocked(_selected_level_number):
		match _level_select_chapter:
			&"sky":
				_selected_level_number = 15
			&"ocean":
				_selected_level_number = 8
			_:
				var last_played: int = save_store.get_last_played_level()
				_selected_level_number = (
					last_played
					if last_played >= 1 and last_played <= 7 \
							and save_store.is_level_unlocked(last_played)
					else 1
				)

	for level in chapter_levels:
		_create_level_marker(level)
	progress_label.text = tr("TXT_0062") % [
		completed_count,
		chapter_levels.size(),
	]
	_refresh_level_marker_states()
	_update_level_selection_info()
	if save_store != null:
		LOCALIZATION_STYLE.apply(level_select, save_store.get_language())


func _chapter_levels() -> Array:
	match _level_select_chapter:
		&"sky":
			return GreenSweeperLevels.SKY_LEVELS
		&"ocean":
			return GreenSweeperLevels.OCEAN_LEVELS
	return GreenSweeperLevels.LAND_LEVELS


func _chapter_marker_positions() -> Array:
	match _level_select_chapter:
		&"sky":
			return SKY_LEVEL_MARKER_POSITIONS
		&"ocean":
			return OCEAN_LEVEL_MARKER_POSITIONS
	return LAND_LEVEL_MARKER_POSITIONS


func _is_level_in_current_chapter(level_number: int) -> bool:
	match _level_select_chapter:
		&"sky":
			return level_number >= 15 and level_number <= 21
		&"ocean":
			return level_number >= 8 and level_number <= 14
	return level_number >= 1 and level_number <= 7


func _is_select_level_unlocked(level_number: int) -> bool:
	return save_store.is_level_unlocked(level_number)


func _is_select_level_completed(level_number: int) -> bool:
	return save_store.is_level_completed(level_number)


func _marker_texture_for_level(level_number: int) -> Texture2D:
	if _level_select_chapter == &"ocean":
		return (
			_ocean_final_marker_texture
			if level_number == 14
			else _ocean_level_marker_texture
		)
	return _level_marker_texture


func _create_level_marker(level: Dictionary) -> void:
	var level_number: int = level.number
	var marker_root := Control.new()
	marker_root.name = "LevelMarker%02d" % level_number
	var marker_positions := _chapter_marker_positions()
	var first_level_number := 1
	if _level_select_chapter == &"ocean":
		first_level_number = 8
	elif _level_select_chapter == &"sky":
		first_level_number = 15
	var position_index := level_number - first_level_number
	marker_root.position = marker_positions[position_index] - Vector2(44.0, 44.0)
	marker_root.size = Vector2(88.0, 88.0)
	marker_root.pivot_offset = marker_root.size * 0.5
	var marker_rotation := 4.5 if _level_select_chapter == &"land" else 1.2
	marker_root.rotation = deg_to_rad(marker_rotation)
	marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_grid.add_child(marker_root)

	var glow := Panel.new()
	glow.name = "Glow"
	glow.position = Vector2(-6.0, -6.0)
	glow.size = Vector2(100.0, 100.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.98, 0.84, 0.25, 0.30)
	glow_style.corner_radius_top_left = 50
	glow_style.corner_radius_top_right = 50
	glow_style.corner_radius_bottom_left = 50
	glow_style.corner_radius_bottom_right = 50
	glow_style.shadow_color = Color(0.98, 0.84, 0.25, 0.48)
	glow_style.shadow_size = 10
	glow.add_theme_stylebox_override("panel", glow_style)
	marker_root.add_child(glow)

	var button := Button.new()
	button.name = "LevelButton%02d" % level_number
	button.position = Vector2(8.0, 8.0)
	button.size = Vector2(72.0, 72.0)
	button.pivot_offset = button.size * 0.5
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var marker_name := tr(str(level.name))
	button.text = (
		"%02d" % level_number
		if save_store.get_language() == LANGUAGE_ENGLISH
		else marker_name
	)
	button.tooltip_text = tr("TXT_0061") % [level_number, marker_name]
	var marker_texture := _marker_texture_for_level(level_number)
	if marker_texture != null:
		var marker_style := StyleBoxTexture.new()
		marker_style.texture = marker_texture
		marker_style.content_margin_left = 12.0
		marker_style.content_margin_top = 12.0
		marker_style.content_margin_right = 12.0
		marker_style.content_margin_bottom = 12.0
		button.add_theme_stylebox_override("normal", marker_style)
		button.add_theme_stylebox_override("hover", marker_style.duplicate())
		button.add_theme_stylebox_override("pressed", marker_style.duplicate())
		button.add_theme_stylebox_override("disabled", marker_style.duplicate())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_constant_override("outline_size", 1)
	button.pressed.connect(_on_level_marker_pressed.bind(level_number))
	marker_root.add_child(button)
	_level_marker_buttons[level_number] = {
		"root": marker_root,
		"button": button,
		"glow": glow,
	}


func _refresh_level_marker_states() -> void:
	var last_played: int = save_store.get_last_played_level()
	for level in _chapter_levels():
		var level_number: int = level.number
		var marker: Dictionary = _level_marker_buttons[level_number]
		var root_control := marker["root"] as Control
		var button := marker["button"] as Button
		var glow := marker["glow"] as Control
		var unlocked: bool = _is_select_level_unlocked(level_number)
		var completed: bool = _is_select_level_completed(level_number)
		var selected: bool = level_number == _selected_level_number
		var in_progress: bool = (
			level_number == last_played
			and not completed
		)
		button.disabled = not unlocked
		glow.visible = selected
		root_control.scale = Vector2.ONE * (1.10 if selected else 1.0)
		if not unlocked:
			button.modulate = Color(0.47, 0.45, 0.40, 0.82)
			button.add_theme_color_override("font_color", Color("756f63"))
			button.add_theme_color_override("font_disabled_color", Color("756f63"))
		elif selected:
			button.modulate = Color(1.0, 0.91, 0.48, 1.0)
			button.add_theme_color_override("font_color", Color("195536"))
		elif in_progress:
			button.modulate = Color(0.66, 0.94, 0.82, 1.0)
			button.add_theme_color_override("font_color", Color("174d35"))
		elif completed:
			button.modulate = Color(0.72, 0.94, 0.58, 1.0)
			button.add_theme_color_override("font_color", Color("174d35"))
		else:
			button.modulate = Color(1.0, 0.98, 0.88, 1.0)
			button.add_theme_color_override("font_color", Color("5b4935"))
		var interaction_color := Color("174d35")
		if _level_select_chapter == &"ocean":
			interaction_color = Color("0e5368")
		elif _level_select_chapter == &"sky":
			interaction_color = Color("49658f")
		button.add_theme_color_override("font_hover_color", interaction_color)
		button.add_theme_color_override("font_pressed_color", interaction_color)
		button.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.88, 0.82))


func _on_level_marker_pressed(level_number: int) -> void:
	if not _is_select_level_unlocked(level_number):
		return
	if _selected_level_number == level_number:
		_start_level_number(
			level_number,
			true,
			true
		)
		return
	_selected_level_number = level_number
	if _level_select_chapter == &"sky":
		_selected_sky_level_number = level_number
	elif _level_select_chapter == &"ocean":
		_selected_ocean_level_number = level_number
	else:
		_selected_land_level_number = level_number
	_refresh_level_marker_states()
	_update_level_selection_info()


func _update_level_selection_info() -> void:
	var level: Dictionary = GreenSweeperLevels.get_level_by_number(_selected_level_number)
	if level.is_empty():
		return
	selected_level_label.text = tr("TXT_0060") % [
		_selected_level_number,
		tr(str(level.name)),
	]
	var unlocked: bool = _is_select_level_unlocked(_selected_level_number)
	var completed: bool = _is_select_level_completed(_selected_level_number)
	var in_progress: bool = (
		_selected_level_number == save_store.get_last_played_level()
		and not completed
	)
	var status: String = tr("TXT_0066")
	if completed:
		status = tr("TXT_0069")
	elif in_progress:
		status = tr("TXT_0068")
	elif unlocked:
		status = tr("TXT_0067")
	selected_level_status_label.text = tr("TXT_0064") % status
	var best_time: int = save_store.get_best_time_ms(_selected_level_number)
	selected_best_time_label.text = (
		tr("TXT_0070") % _format_time(best_time)
		if best_time >= 0
		else tr("TXT_0071")
	)


func _on_previous_chapter_pressed() -> void:
	match _level_select_chapter:
		&"sky":
			_selected_sky_level_number = _selected_level_number
			_level_select_chapter = &"ocean"
			_selected_level_number = _selected_ocean_level_number
		&"ocean":
			_selected_ocean_level_number = _selected_level_number
			_level_select_chapter = &"land"
			_selected_level_number = _selected_land_level_number
		_:
			_selected_land_level_number = _selected_level_number
			_level_select_chapter = &"sky"
			_selected_level_number = _selected_sky_level_number
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	level_previous_chapter_button.grab_focus()


func _on_next_chapter_pressed() -> void:
	match _level_select_chapter:
		&"sky":
			_selected_sky_level_number = _selected_level_number
			_start_universe_mode()
			return
		&"ocean":
			_selected_ocean_level_number = _selected_level_number
			_level_select_chapter = &"sky"
			_selected_level_number = _selected_sky_level_number
		_:
			_selected_land_level_number = _selected_level_number
			_level_select_chapter = &"ocean"
			_selected_level_number = _selected_ocean_level_number
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	level_next_chapter_button.grab_focus()


func _on_level_back_pressed() -> void:
	if _level_select_return_to_game and is_instance_valid(active_game):
		_level_select_return_to_game = false
		_show_only(game_host)
		AudioManager.play_level_bgm(int(active_game.get("current_level_index")) + 1)
		return
	if _is_select_level_unlocked(_selected_level_number):
		_start_level_number(
			_selected_level_number,
			true,
			true
		)


func _refresh_continue_button() -> void:
	var last_level: int = save_store.get_last_played_level()
	var can_continue: bool = last_level > 0 and save_store.is_level_unlocked(last_level)
	continue_button.disabled = not can_continue
	if can_continue:
		var level: Dictionary = GreenSweeperLevels.get_level_by_number(last_level)
		continue_button.text = tr("TXT_0004") % [
			last_level,
			tr(str(level.name)),
		]
		continue_button.tooltip_text = tr("TXT_0011")
	else:
		continue_button.text = tr("TXT_0003")
		continue_button.tooltip_text = tr("TXT_0010")


func _refresh_settings_options() -> void:
	display_mode_option.clear()
	display_mode_option.add_item(tr("TXT_0022"), 0)
	display_mode_option.add_item(tr("TXT_0023"), 1)
	display_mode_option.add_item(tr("TXT_0024"), 2)
	display_mode_option.select(save_store.get_window_mode())
	operation_mode_option.clear()
	operation_mode_option.add_item(tr("TXT_0026"), 0)
	operation_mode_option.add_item(
		tr("TXT_0027"),
		1
	)
	operation_mode_option.select(save_store.get_operation_mode())
	language_option.clear()
	language_option.add_item(tr("TXT_0029"), 0)
	language_option.add_item(tr("TXT_0460"), 1)
	language_option.select(1 if save_store.get_language() == LANGUAGE_ENGLISH else 0)


func _on_volume_changed(value: float) -> void:
	volume_value_label.text = "%d%%" % roundi(value * 100.0)
	_apply_master_volume(value)
	if save_store != null:
		save_store.set_master_volume(value)


func _on_volume_drag_ended(value_changed: bool) -> void:
	if not value_changed:
		return
	save_store.set_master_volume(volume_slider.value)
	save_store.save_data()


func _on_bgm_toggled(enabled: bool) -> void:
	AudioManager.play_menu_select()
	AudioManager.set_bgm_enabled(enabled)
	save_store.set_bgm_enabled(enabled)
	_refresh_audio_toggle_buttons()
	save_store.save_data()


func _on_sfx_toggled(enabled: bool) -> void:
	if enabled:
		AudioManager.set_sfx_enabled(true)
		AudioManager.play_menu_select()
	else:
		AudioManager.play_menu_select()
		AudioManager.set_sfx_enabled(false)
	save_store.set_sfx_enabled(enabled)
	_refresh_audio_toggle_buttons()
	save_store.save_data()


func _refresh_audio_toggle_buttons() -> void:
	var bgm_enabled: bool = save_store.is_bgm_enabled()
	var sfx_enabled: bool = save_store.is_sfx_enabled()
	bgm_toggle_button.set_pressed_no_signal(bgm_enabled)
	sfx_toggle_button.set_pressed_no_signal(sfx_enabled)
	bgm_toggle_button.text = tr("TXT_0016") % (
		tr("TXT_0019") if bgm_enabled else tr("TXT_0020")
	)
	sfx_toggle_button.text = tr("TXT_0018") % (
		tr("TXT_0019") if sfx_enabled else tr("TXT_0020")
	)


func _on_display_mode_selected(index: int) -> void:
	_apply_display_mode(index)
	save_store.set_window_mode(index)
	save_store.save_data()


func _on_operation_mode_selected(index: int) -> void:
	save_store.set_operation_mode(index)
	operation_mode_option.select(save_store.get_operation_mode())
	if is_instance_valid(active_game):
		active_game.call("set_operation_mode", save_store.get_operation_mode())
	save_store.save_data()


func _on_language_selected(index: int) -> void:
	var language := LANGUAGE_ENGLISH if index == 1 else LANGUAGE_CHINESE
	if save_store.get_language() == language:
		return
	save_store.set_language(language)
	save_store.save_data()
	TranslationServer.set_locale(language)
	_refresh_settings_options()
	_refresh_audio_toggle_buttons()
	_apply_level_select_chapter_art()
	_rebuild_level_cards()
	_refresh_continue_button()
	if is_instance_valid(active_game) \
			and active_game.has_method("refresh_localized_interface"):
		active_game.call("refresh_localized_interface")
	if is_instance_valid(badge_book):
		badge_book.refresh_language()
	if is_instance_valid(badge_hall):
		badge_hall.refresh_language()
	LOCALIZATION_STYLE.apply(self, language)


func _toggle_display_mode() -> void:
	var next_mode := 1 if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else 2
	display_mode_option.select(next_mode)
	_on_display_mode_selected(next_mode)


func _apply_master_volume(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _apply_display_mode(mode: int) -> void:
	match mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var window_size := Vector2i(1280, 720)
			DisplayServer.window_set_size(window_size)
			var screen := DisplayServer.window_get_current_screen()
			var usable_rect := DisplayServer.screen_get_usable_rect(screen)
			DisplayServer.window_set_position(usable_rect.position + (usable_rect.size - window_size) / 2)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _show_only(page: Control) -> void:
	main_menu.visible = page == main_menu
	level_select.visible = page == level_select
	settings_page.visible = page == settings_page
	help_page.visible = page == help_page
	game_host.visible = page == game_host
	if is_instance_valid(badge_book):
		badge_book.visible = page == badge_book
	if is_instance_valid(badge_hall):
		badge_hall.visible = page == badge_hall
	if page == main_menu or page == level_select:
		AudioManager.play_menu_bgm()


func _destroy_active_game() -> void:
	_universe_milestone_hall_pending = false
	if not is_instance_valid(active_game):
		active_game = null
		return
	game_host.remove_child(active_game)
	active_game.queue_free()
	active_game = null


func _format_time(elapsed_ms: int) -> String:
	var minutes := int(elapsed_ms / 60000)
	var seconds := int(elapsed_ms / 1000) % 60
	var tenths := int(elapsed_ms / 100) % 10
	return "%02d:%02d.%d" % [minutes, seconds, tenths]
