extends Control

signal level_started(level_number: int)
signal level_completed(level_number: int, elapsed_ms: int)
signal level_select_requested
signal main_menu_requested
signal settings_requested
signal exit_game_requested
signal pause_changed(is_paused: bool)

@export var auto_start := true

@onready var board: MinesweeperBoard = %Board
@onready var eco_showcase: Control = %EcoShowcase
@onready var subtitle_label: Label = %SubtitleLabel
@onready var level_summary_label: Label = %LevelSummaryLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var status_label: Label = %StatusLabel
@onready var flags_label: Label = %FlagsLabel
@onready var timer_label: Label = %TimerLabel
@onready var instructions_label: Label = %InstructionsLabel
@onready var restart_button: Button = %RestartButton
@onready var pause_button: Button = %PauseButton
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var pause_restart_button: Button = %PauseRestartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var pause_settings_button: Button = %PauseSettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var exit_game_button: Button = %ExitGameButton

var current_level_index := 0
var _advance_available := false
var _session_paused := false
var _completion_emitted := false
var _elapsed_before_segment_ms := 0
var _segment_started_ms := 0
var _timer_running := false
var _operation_mode := 0


func _ready() -> void:
	board.state_changed.connect(_on_state_changed)
	board.flags_changed.connect(_on_flags_changed)
	restart_button.pressed.connect(_on_primary_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_game_button_pressed)
	if auto_start:
		start_level(_requested_level_index())
	else:
		visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if _timer_running:
		_update_timer_label()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	set_session_paused(not _session_paused)
	get_viewport().set_input_as_handled()


func start_level(level_index: int) -> void:
	current_level_index = clampi(level_index, 0, GreenSweeperLevels.LEVELS.size() - 1)
	_completion_emitted = false
	set_session_paused(false)
	_reset_timer()
	var level: Dictionary = GreenSweeperLevels.LEVELS[current_level_index]
	board.load_level(level)
	board.set_interaction_enabled(true)
	eco_showcase.call("set_environment", board.level_number)
	subtitle_label.text = "第%d关 · %s" % [
		board.level_number,
		board.level_name,
	]
	level_summary_label.text = "%d列 × %d排\n%d个随机污染核心" % [
		board.column_count,
		board.row_count,
		board.core_count,
	]
	objective_label.text = "打开全部%d个安全区域，恢复%s生态。" % [
		board.safe_cell_count,
		board.level_name,
	]
	_refresh_instructions()
	visible = true
	level_started.emit(board.level_number)


func restart_level() -> void:
	_completion_emitted = false
	set_session_paused(false)
	_reset_timer()
	board.set_interaction_enabled(true)
	board.new_game()


func set_operation_mode(mode: int) -> void:
	_operation_mode = 1 if mode == 1 else 0
	board.set_operation_mode(_operation_mode)
	_refresh_instructions()


func get_operation_mode() -> int:
	return _operation_mode


func _refresh_instructions() -> void:
	if not is_instance_valid(instructions_label) or not is_instance_valid(board):
		return
	var guide_text := (
		"绿色箭头为安全建议"
		if board.first_move_guide_enabled
		else "无安全提示 · 首点可能污染"
	)
	if _operation_mode == 1:
		instructions_label.text = (
			guide_text
			+ "\n方向键/WASD移动"
			+ "\nZ净化/展开 · X标记"
			+ "\n鼠标操作仍可使用"
		)
	else:
		instructions_label.text = (
			guide_text
			+ "\n左键净化 · 右键标记"
			+ "\n双击数字快速展开"
		)


func set_session_paused(paused: bool) -> void:
	if _session_paused == paused:
		return
	_session_paused = paused
	if paused:
		_pause_timer()
	else:
		_resume_timer_if_playing()
	board.set_interaction_enabled(not paused)
	pause_overlay.visible = paused
	if paused:
		resume_button.grab_focus()
	pause_changed.emit(paused)


func is_session_paused() -> bool:
	return _session_paused


func get_elapsed_ms() -> int:
	if _timer_running:
		return _elapsed_before_segment_ms + int(Time.get_ticks_msec()) - _segment_started_ms
	return _elapsed_before_segment_ms


func _load_level(level_index: int) -> void:
	start_level(level_index)


func _on_state_changed(state: int) -> void:
	_advance_available = false
	match state:
		MinesweeperBoard.GameState.READY:
			_reset_timer()
			status_label.text = "点击绿色箭头试试（也可自由选择）" if board.first_move_guide_enabled else "选择第一块净化区域"
			restart_button.text = "重新生成"
			pause_button.text = "暂停  ·  Esc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.PLAYING:
			_start_timer()
			status_label.text = "净化进行中"
			restart_button.text = "重新开始"
			pause_button.text = "暂停  ·  Esc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.WON:
			_pause_timer()
			pause_button.text = "菜单  ·  Esc"
			pause_button.disabled = false
			if current_level_index + 1 < GreenSweeperLevels.LEVELS.size():
				status_label.text = "净化完成！新的陆地区域已解锁"
				restart_button.text = "进入下一关"
				_advance_available = true
			else:
				status_label.text = "%s净化完成！" % board.level_name
				restart_button.text = "再来一局"
			if not _completion_emitted:
				_completion_emitted = true
				level_completed.emit(board.level_number, get_elapsed_ms())
		MinesweeperBoard.GameState.LOST:
			_pause_timer()
			pause_button.text = "菜单  ·  Esc"
			pause_button.disabled = false
			status_label.text = "触碰污染核心，请重新开始"
			restart_button.text = "重新开始"


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "标记：%d/%d" % [used_flags, max_flags]


func _on_primary_button_pressed() -> void:
	if _advance_available:
		start_level(current_level_index + 1)
	else:
		restart_level()


func _on_pause_button_pressed() -> void:
	set_session_paused(true)


func _on_resume_button_pressed() -> void:
	set_session_paused(false)
	pause_button.grab_focus()


func _on_pause_restart_button_pressed() -> void:
	restart_level()


func _on_level_select_button_pressed() -> void:
	_pause_timer()
	board.set_interaction_enabled(false)
	level_select_requested.emit()


func _on_pause_settings_button_pressed() -> void:
	settings_requested.emit()


func _on_main_menu_button_pressed() -> void:
	_pause_timer()
	board.set_interaction_enabled(false)
	main_menu_requested.emit()


func _on_exit_game_button_pressed() -> void:
	exit_game_requested.emit()


func _start_timer() -> void:
	if _timer_running or _session_paused:
		return
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true


func _pause_timer() -> void:
	if not _timer_running:
		_update_timer_label()
		return
	_elapsed_before_segment_ms += int(Time.get_ticks_msec()) - _segment_started_ms
	_timer_running = false
	_update_timer_label()


func _resume_timer_if_playing() -> void:
	if board.game_state == MinesweeperBoard.GameState.PLAYING:
		_start_timer()


func _reset_timer() -> void:
	_elapsed_before_segment_ms = 0
	_segment_started_ms = 0
	_timer_running = false
	_update_timer_label()


func _update_timer_label() -> void:
	var elapsed_ms := get_elapsed_ms()
	var minutes := int(elapsed_ms / 60000)
	var seconds := int(elapsed_ms / 1000) % 60
	var tenths := int(elapsed_ms / 100) % 10
	timer_label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]


func _requested_level_index() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			var requested_level := int(argument.trim_prefix("--level="))
			return requested_level - 1
	return 0
