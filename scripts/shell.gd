@tool
extends Control

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SAVE_STORE_SCRIPT: Script = preload("res://scripts/save_store.gd")
const ART := preload("res://scripts/art_catalog.gd")
const MENU_PRIMARY_PATH := ART.MENU_PRIMARY_NORMAL
const MENU_PRIMARY_SELECTED_PATH := ART.MENU_PRIMARY_HOVER
const MENU_PRIMARY_PRESSED_PATH := ART.MENU_PRIMARY_PRESSED
const MENU_PAPER_PATH := ART.MENU_SECONDARY_NORMAL
const MENU_PAPER_SELECTED_PATH := ART.MENU_SECONDARY_HOVER
const MENU_PAPER_PRESSED_PATH := ART.MENU_SECONDARY_PRESSED
const MENU_FONT_PATH := ART.UI_FONT
const LEVEL_SELECT_BACKGROUND_PATH := ART.LEVEL_SELECT_DESKTOP_BACKGROUND
const LEVEL_SELECT_MAP_PATH := ART.LEVEL_SELECT_LAND_MAP
const LEVEL_SELECT_INFO_PATH := ART.LEVEL_SELECT_BOTTOM_INFO_BAR
const LEVEL_SELECT_MARKER_PATH := ART.LEVEL_SELECT_MARKER_BUTTON
const LEVEL_SELECT_SHORTCUT_PATH := ART.LEVEL_SELECT_SHORTCUT_BUTTON
const LEVEL_MARKER_POSITIONS := [
	Vector2(111, 316),
	Vector2(317, 234),
	Vector2(478, 225),
	Vector2(638, 178),
	Vector2(814, 146),
]

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
@onready var progress_label: Label = %ProgressLabel
@onready var level_select_background: TextureRect = %LevelSelectBackground
@onready var level_map_artwork: TextureRect = %LevelMapArtwork
@onready var level_info_artwork: TextureRect = %LevelInfoArtwork
@onready var selected_level_label: Label = %SelectedLevelLabel
@onready var selected_level_status_label: Label = %SelectedLevelStatusLabel
@onready var selected_best_time_label: Label = %SelectedBestTimeLabel
@onready var level_back_button: Button = %LevelBackButton
@onready var level_welcome_button: Button = %LevelWelcomeButton
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var operation_mode_option: OptionButton = %OperationModeOption
@onready var settings_back_button: Button = %SettingsBackButton

var save_store
var active_game: Control
var _record_progress := true
var _settings_return_to_game := false
var _level_select_return_to_game := false
var _selected_level_number := 1
var _level_marker_buttons: Dictionary = {}
var _level_marker_texture: Texture2D
var _runtime_texture_cache: Dictionary = {}


func _ready() -> void:
	_apply_menu_typography()
	_apply_menu_button_art()
	_apply_level_select_art()
	if Engine.is_editor_hint():
		return
	save_store = SAVE_STORE_SCRIPT.new(save_path)
	save_store.load_data()
	volume_slider.value = save_store.get_master_volume()
	display_mode_option.add_item("窗口模式（1280 × 720）", 0)
	display_mode_option.add_item("最大化窗口", 1)
	display_mode_option.add_item("无边框全屏", 2)
	display_mode_option.select(save_store.get_window_mode())
	operation_mode_option.add_item("鼠标操作", 0)
	operation_mode_option.add_item("键盘操作", 1)
	operation_mode_option.select(save_store.get_operation_mode())
	_on_volume_changed(volume_slider.value)
	_apply_display_mode(display_mode_option.selected)
	_connect_controls()

	var requested_level := parse_level_argument(OS.get_cmdline_user_args())
	if requested_level > 0:
		start_cli_level(requested_level)
	else:
		if requested_level < 0:
			push_error("无效的 --level 参数；请使用 --level=1 至 --level=5。")
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
	level_select_background.texture = _load_runtime_texture(LEVEL_SELECT_BACKGROUND_PATH)
	level_map_artwork.texture = _load_runtime_texture(LEVEL_SELECT_MAP_PATH)
	level_info_artwork.texture = _load_runtime_texture(LEVEL_SELECT_INFO_PATH)
	_level_marker_texture = _load_runtime_texture(LEVEL_SELECT_MARKER_PATH)
	var shortcut_texture := _load_runtime_texture(LEVEL_SELECT_SHORTCUT_PATH)
	if shortcut_texture == null:
		return
	for button in [level_back_button, level_welcome_button]:
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
	if settings_page.visible:
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
	_refresh_continue_button()
	start_button.grab_focus()


func show_level_select(preserve_active_game: bool = false) -> void:
	_settings_return_to_game = false
	_level_select_return_to_game = preserve_active_game and is_instance_valid(active_game)
	if not _level_select_return_to_game:
		_destroy_active_game()
	_rebuild_level_cards()
	_show_only(level_select)
	level_back_button.text = "返回关卡"
	level_back_button.grab_focus()


func show_settings(return_to_game: bool = false) -> void:
	_settings_return_to_game = return_to_game and is_instance_valid(active_game)
	_show_only(settings_page)
	volume_slider.grab_focus()


func _close_settings() -> void:
	save_store.save_data()
	if _settings_return_to_game and is_instance_valid(active_game):
		_settings_return_to_game = false
		_show_only(game_host)
		active_game.get_node("%ResumeButton").grab_focus()
	else:
		show_main_menu()


func start_normal_level(level_number: int) -> void:
	_start_level_number(level_number, true)


func start_cli_level(level_number: int) -> void:
	_start_level_number(level_number, false)


func get_active_game() -> Control:
	return active_game


func is_cli_read_only() -> bool:
	return active_game != null and not _record_progress


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
	start_button.pressed.connect(func() -> void: start_normal_level(1))
	continue_button.pressed.connect(_on_continue_pressed)
	choose_level_button.pressed.connect(show_level_select)
	settings_button.pressed.connect(show_settings)
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	level_back_button.pressed.connect(_on_level_back_pressed)
	level_welcome_button.pressed.connect(show_main_menu)
	settings_back_button.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	display_mode_option.item_selected.connect(_on_display_mode_selected)
	operation_mode_option.item_selected.connect(_on_operation_mode_selected)


func _start_level_number(level_number: int, record_progress: bool) -> void:
	if not GreenSweeperLevels.is_valid_level_number(level_number):
		return
	if record_progress and not save_store.is_level_unlocked(level_number):
		return

	_level_select_return_to_game = false
	_destroy_active_game()
	_record_progress = record_progress
	active_game = GAME_SCENE.instantiate() as Control
	active_game.set("auto_start", false)
	game_host.add_child(active_game)
	active_game.level_started.connect(_on_game_level_started)
	active_game.level_completed.connect(_on_game_level_completed)
	active_game.level_select_requested.connect(_on_game_level_select_requested)
	active_game.main_menu_requested.connect(show_main_menu)
	active_game.settings_requested.connect(_on_game_settings_requested)
	active_game.exit_game_requested.connect(func() -> void: get_tree().quit())
	active_game.call(
		"set_first_move_guide_enabled",
		not save_store.has_seen_first_move_guide()
	)
	_show_only(game_host)
	active_game.start_level(GreenSweeperLevels.level_index_from_number(level_number))
	active_game.call("set_operation_mode", save_store.get_operation_mode())


func _on_continue_pressed() -> void:
	var level_number: int = save_store.get_last_played_level()
	if level_number > 0 and save_store.is_level_unlocked(level_number):
		start_normal_level(level_number)


func _on_game_level_started(level_number: int) -> void:
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


func _on_game_level_select_requested() -> void:
	show_level_select(true)


func _on_game_settings_requested() -> void:
	show_settings(true)


func _rebuild_level_cards() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
		child.free()
	_level_marker_buttons.clear()

	var completed_count := 0
	for level in GreenSweeperLevels.LEVELS:
		if save_store.is_level_completed(int(level.number)):
			completed_count += 1

	if not GreenSweeperLevels.is_valid_level_number(_selected_level_number) \
			or not save_store.is_level_unlocked(_selected_level_number):
		var last_played: int = save_store.get_last_played_level()
		_selected_level_number = (
			last_played
			if GreenSweeperLevels.is_valid_level_number(last_played)
					and save_store.is_level_unlocked(last_played)
			else 1
		)

	for level in GreenSweeperLevels.LEVELS:
		_create_level_marker(level)
	progress_label.text = "已完成：%d / %d" % [
		completed_count,
		GreenSweeperLevels.LEVELS.size(),
	]
	_refresh_level_marker_states()
	_update_level_selection_info()


func _create_level_marker(level: Dictionary) -> void:
	var level_number: int = level.number
	var marker_root := Control.new()
	marker_root.name = "LevelMarker%02d" % level_number
	marker_root.position = LEVEL_MARKER_POSITIONS[level_number - 1] - Vector2(52.0, 52.0)
	marker_root.size = Vector2(104.0, 104.0)
	marker_root.pivot_offset = marker_root.size * 0.5
	marker_root.rotation = deg_to_rad(4.5)
	marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_grid.add_child(marker_root)

	var glow := Panel.new()
	glow.name = "Glow"
	glow.position = Vector2(-7.0, -7.0)
	glow.size = Vector2(118.0, 118.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.98, 0.84, 0.25, 0.30)
	glow_style.corner_radius_top_left = 59
	glow_style.corner_radius_top_right = 59
	glow_style.corner_radius_bottom_left = 59
	glow_style.corner_radius_bottom_right = 59
	glow_style.shadow_color = Color(0.98, 0.84, 0.25, 0.48)
	glow_style.shadow_size = 12
	glow.add_theme_stylebox_override("panel", glow_style)
	marker_root.add_child(glow)

	var button := Button.new()
	button.name = "LevelButton%02d" % level_number
	button.position = Vector2(8.0, 8.0)
	button.size = Vector2(88.0, 88.0)
	button.pivot_offset = button.size * 0.5
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = str(level.name)
	button.tooltip_text = "选择第%d关 · %s" % [level_number, str(level.name)]
	if _level_marker_texture != null:
		var marker_style := StyleBoxTexture.new()
		marker_style.texture = _level_marker_texture
		marker_style.content_margin_left = 12.0
		marker_style.content_margin_top = 12.0
		marker_style.content_margin_right = 12.0
		marker_style.content_margin_bottom = 12.0
		button.add_theme_stylebox_override("normal", marker_style)
		button.add_theme_stylebox_override("hover", marker_style.duplicate())
		button.add_theme_stylebox_override("pressed", marker_style.duplicate())
		button.add_theme_stylebox_override("disabled", marker_style.duplicate())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 15)
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
	for level in GreenSweeperLevels.LEVELS:
		var level_number: int = level.number
		var marker: Dictionary = _level_marker_buttons[level_number]
		var root_control := marker["root"] as Control
		var button := marker["button"] as Button
		var glow := marker["glow"] as Control
		var unlocked: bool = save_store.is_level_unlocked(level_number)
		var completed: bool = save_store.is_level_completed(level_number)
		var selected: bool = level_number == _selected_level_number
		var in_progress: bool = level_number == last_played and not completed
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
		button.add_theme_color_override("font_hover_color", Color("174d35"))
		button.add_theme_color_override("font_pressed_color", Color("174d35"))
		button.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.88, 0.72))


func _on_level_marker_pressed(level_number: int) -> void:
	if not save_store.is_level_unlocked(level_number):
		return
	if _selected_level_number == level_number:
		start_normal_level(level_number)
		return
	_selected_level_number = level_number
	_refresh_level_marker_states()
	_update_level_selection_info()


func _update_level_selection_info() -> void:
	var level: Dictionary = GreenSweeperLevels.get_level_by_number(_selected_level_number)
	if level.is_empty():
		return
	selected_level_label.text = "当前关卡：%02d %s" % [
		_selected_level_number,
		str(level.name),
	]
	var unlocked: bool = save_store.is_level_unlocked(_selected_level_number)
	var completed: bool = save_store.is_level_completed(_selected_level_number)
	var in_progress: bool = (
		_selected_level_number == save_store.get_last_played_level()
		and not completed
	)
	var status: String = "未解锁"
	if completed:
		status = "已完成"
	elif in_progress:
		status = "正在进行"
	elif unlocked:
		status = "已解锁"
	selected_level_status_label.text = "状态：%s" % status
	var best_time: int = save_store.get_best_time_ms(_selected_level_number)
	selected_best_time_label.text = (
		"最佳时间：%s" % _format_time(best_time)
		if best_time >= 0
		else "最佳时间：--:--.-"
	)


func _on_level_back_pressed() -> void:
	if _level_select_return_to_game and is_instance_valid(active_game):
		_level_select_return_to_game = false
		_show_only(game_host)
		return
	if save_store.is_level_unlocked(_selected_level_number):
		start_normal_level(_selected_level_number)


func _refresh_continue_button() -> void:
	var last_level: int = save_store.get_last_played_level()
	var can_continue: bool = last_level > 0 and save_store.is_level_unlocked(last_level)
	continue_button.disabled = not can_continue
	if can_continue:
		var level: Dictionary = GreenSweeperLevels.get_level_by_number(last_level)
		continue_button.text = "继续游戏 · %02d %s" % [last_level, level.name]
		continue_button.tooltip_text = "重新生成上次游玩的关卡"
	else:
		continue_button.text = "继续游戏"
		continue_button.tooltip_text = "开始第一局后即可继续"


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
	game_host.visible = page == game_host


func _destroy_active_game() -> void:
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
