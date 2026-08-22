extends Control

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SAVE_STORE_SCRIPT: Script = preload("res://scripts/save_store.gd")

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
@onready var level_grid: GridContainer = %LevelGrid
@onready var progress_label: Label = %ProgressLabel
@onready var level_back_button: Button = %LevelBackButton
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var settings_back_button: Button = %SettingsBackButton

var save_store
var active_game: Control
var _record_progress := true
var _settings_return_to_game := false


func _ready() -> void:
	save_store = SAVE_STORE_SCRIPT.new(save_path)
	save_store.load_data()
	volume_slider.value = save_store.get_master_volume()
	display_mode_option.add_item("窗口模式（1280 × 720）", 0)
	display_mode_option.add_item("最大化窗口", 1)
	display_mode_option.add_item("无边框全屏", 2)
	display_mode_option.select(save_store.get_window_mode())
	_on_volume_changed(volume_slider.value)
	_apply_display_mode(display_mode_option.selected)
	_connect_controls()

	var requested_level := parse_level_argument(OS.get_cmdline_user_args())
	if requested_level > 0:
		start_cli_level(requested_level)
	else:
		if requested_level < 0:
			push_error("无效的 --level 参数；请使用 --level=1 至 --level=6。")
		show_main_menu()


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
		show_main_menu()
		get_viewport().set_input_as_handled()


func show_main_menu() -> void:
	if is_instance_valid(settings_page) and settings_page.visible and save_store != null:
		save_store.save_data()
	_settings_return_to_game = false
	_destroy_active_game()
	_show_only(main_menu)
	_refresh_continue_button()
	start_button.grab_focus()


func show_level_select() -> void:
	_settings_return_to_game = false
	_destroy_active_game()
	_rebuild_level_cards()
	_show_only(level_select)
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
	level_back_button.pressed.connect(show_main_menu)
	settings_back_button.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	display_mode_option.item_selected.connect(_on_display_mode_selected)


func _start_level_number(level_number: int, record_progress: bool) -> void:
	if not GreenSweeperLevels.is_valid_level_number(level_number):
		return
	if record_progress and not save_store.is_level_unlocked(level_number):
		return

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
	_show_only(game_host)
	active_game.start_level(GreenSweeperLevels.level_index_from_number(level_number))


func _on_continue_pressed() -> void:
	var level_number: int = save_store.get_last_played_level()
	if level_number > 0 and save_store.is_level_unlocked(level_number):
		start_normal_level(level_number)


func _on_game_level_started(level_number: int) -> void:
	if not _record_progress:
		return
	save_store.mark_level_started(level_number)
	save_store.save_data()


func _on_game_level_completed(level_number: int, elapsed_ms: int) -> void:
	if not _record_progress:
		return
	save_store.record_completion(level_number, elapsed_ms)
	save_store.save_data()


func _on_game_level_select_requested() -> void:
	show_level_select()


func _on_game_settings_requested() -> void:
	show_settings(true)


func _rebuild_level_cards() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
		child.free()

	var completed_count := 0
	for level in GreenSweeperLevels.LEVELS:
		var level_number: int = level.number
		var completed: bool = save_store.is_level_completed(level_number)
		var unlocked: bool = save_store.is_level_unlocked(level_number)
		if completed:
			completed_count += 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(235.0, 220.0)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = not unlocked
		button.text = _level_card_text(level_number, str(level.name), completed, unlocked)
		button.tooltip_text = "尚未解锁" if not unlocked else "进入第%d关" % level_number
		button.pressed.connect(_on_level_button_pressed.bind(level_number))
		level_grid.add_child(button)
	progress_label.text = "已净化：%d/%d" % [completed_count, GreenSweeperLevels.LEVELS.size()]


func _level_card_text(level_number: int, level_name: String, completed: bool, unlocked: bool) -> String:
	if not unlocked:
		return "%02d  %s\n[锁定] 尚未解锁" % [level_number, level_name]
	var best_time: int = save_store.get_best_time_ms(level_number)
	if completed and best_time >= 0:
		return "%02d  %s\n已净化  ·  %s" % [level_number, level_name, _format_time(best_time)]
	return "%02d  %s\n等待净化" % [level_number, level_name]


func _on_level_button_pressed(level_number: int) -> void:
	if save_store.is_level_unlocked(level_number):
		start_normal_level(level_number)


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
