extends Control

signal level_started(level_number: int)
signal level_completed(level_number: int, elapsed_ms: int)
signal level_select_requested
signal main_menu_requested
signal settings_requested
signal exit_game_requested
signal pause_changed(is_paused: bool)

@export var auto_start := true


enum TutorialStep {
	INACTIVE,
	FIRST_REVEAL,
	NUMBER_INFO,
	MARK_CORE,
	CHORD,
	COMPLETE,
}


@onready var board: MinesweeperBoard = %Board
@onready var eco_showcase: Control = %EcoShowcase
@onready var subtitle_label: Label = %SubtitleLabel
@onready var level_summary_label: Label = %LevelSummaryLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var status_label: Label = %StatusLabel
@onready var flags_label: Label = %FlagsLabel
@onready var timer_label: Label = %TimerLabel
@onready var instructions_label: Label = %InstructionsLabel
@onready var first_move_guide = %FirstMoveGuide
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
var _tutorial_step: int = TutorialStep.INACTIVE
var _tutorial_dismissed_for_session := false
var _tutorial_number_index := -1
var _tutorial_target_index := -1
var _tutorial_last_revealed_index := -1


func _ready() -> void:
	board.state_changed.connect(_on_state_changed)
	board.flags_changed.connect(_on_flags_changed)
	board.reveal_completed.connect(_on_reveal_completed)
	board.flag_completed.connect(_on_flag_completed)
	board.chord_completed.connect(_on_chord_completed)
	first_move_guide.exit_requested.connect(_on_tutorial_exit_requested)
	first_move_guide.next_requested.connect(_on_tutorial_next_requested)
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
	if not visible:
		return
	if (
		_operation_mode == 1
		and _tutorial_step == TutorialStep.NUMBER_INFO
		and not _tutorial_dismissed_for_session
		and event.is_action_pressed("ui_accept")
	):
		_on_tutorial_next_requested()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	set_session_paused(not _session_paused)
	get_viewport().set_input_as_handled()


func start_level(level_index: int) -> void:
	current_level_index = clampi(level_index, 0, GreenSweeperLevels.LEVELS.size() - 1)
	_tutorial_dismissed_for_session = false
	_tutorial_step = TutorialStep.FIRST_REVEAL if current_level_index == 0 else TutorialStep.INACTIVE
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	_tutorial_last_revealed_index = -1
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
	_refresh_first_move_guide()
	visible = true
	level_started.emit(board.level_number)


func restart_level() -> void:
	_completion_emitted = false
	set_session_paused(false)
	_reset_timer()
	board.set_interaction_enabled(true)
	if board.level_number == 1 and not _tutorial_dismissed_for_session:
		_tutorial_step = TutorialStep.FIRST_REVEAL
	else:
		_tutorial_step = TutorialStep.INACTIVE
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	_tutorial_last_revealed_index = -1
	board.new_game()
	if _tutorial_dismissed_for_session:
		board.clear_guide_cell()
	_refresh_instructions()
	_refresh_first_move_guide()


func set_operation_mode(mode: int) -> void:
	_operation_mode = 1 if mode == 1 else 0
	board.set_operation_mode(_operation_mode)
	_refresh_instructions()
	_refresh_first_move_guide()


func get_operation_mode() -> int:
	return _operation_mode


func _refresh_instructions() -> void:
	if not is_instance_valid(instructions_label) or not is_instance_valid(board):
		return
	var tutorial_active := (
		board.level_number == 1
		and not _tutorial_dismissed_for_session
		and _tutorial_step != TutorialStep.INACTIVE
		and _tutorial_step != TutorialStep.COMPLETE
	)
	var guide_text := (
		"清扫者正在进行连续操作引导"
		if tutorial_active
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


func _refresh_first_move_guide() -> void:
	if not is_instance_valid(first_move_guide) or not is_instance_valid(board):
		return
	var tutorial_visible := (
		board.level_number == 1
		and not _tutorial_dismissed_for_session
		and board.game_state in [
			MinesweeperBoard.GameState.READY,
			MinesweeperBoard.GameState.PLAYING,
		]
		and _tutorial_step not in [TutorialStep.INACTIVE, TutorialStep.COMPLETE]
	)
	if not tutorial_visible:
		first_move_guide.hide_guide()
		return

	var target_index := -1
	var title := ""
	var action := ""
	var hint := ""
	var show_next := false
	match _tutorial_step:
		TutorialStep.FIRST_REVEAL:
			if board.game_state == MinesweeperBoard.GameState.READY:
				target_index = board.guide_cell_index
				title = "先认识棋盘"
				action = "移动到这里按 Z 翻开" if _operation_mode == 1 else "左键翻开这个安全建议格"
				hint = "白色=未净化 · 黄色=安全建议"
			else:
				target_index = _find_unrevealed_safe_index()
				title = "继续观察"
				action = "移动后按 Z 再翻一格" if _operation_mode == 1 else "再左键翻开一个白色格"
				hint = "找到数字后，清扫者会继续说明"
		TutorialStep.NUMBER_INFO:
			target_index = _tutorial_number_index
			title = "这是数字格"
			action = "绿色=安全，数字=周围污染数"
			hint = "按 Enter 或点下一步继续" if _operation_mode == 1 else "例如 1 表示周围有 1 个污染核心"
			show_next = true
		TutorialStep.MARK_CORE:
			target_index = _tutorial_target_index
			title = "检测种子"
			var removing_wrong_flag := (
				_is_valid_tutorial_index(target_index)
				and board.flagged[target_index]
				and not board.mines[target_index]
			)
			if removing_wrong_flag:
				action = "按 X 取消这个错误标记" if _operation_mode == 1 else "右键取消这个错误标记"
				hint = "种子放错会阻止数字快速展开"
			else:
				action = "按 X 放下检测种子" if _operation_mode == 1 else "右键放下检测种子"
				hint = "把数字周围的污染核心全部标记"
		TutorialStep.CHORD:
			target_index = _tutorial_number_index
			title = "快速展开"
			action = "选中数字后按 Z" if _operation_mode == 1 else "双击这个数字"
			hint = "标记正确后，会展开周围安全格"

	if not _is_valid_tutorial_index(target_index):
		first_move_guide.hide_guide()
		return
	first_move_guide.show_for_cell(
		board.cell_nodes[target_index],
		target_index,
		_operation_mode == 1,
		title,
		action,
		hint,
		show_next
	)


func _on_reveal_completed(cell_index: int, newly_revealed_count: int) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if board.game_state in [MinesweeperBoard.GameState.WON, MinesweeperBoard.GameState.LOST]:
		return
	if newly_revealed_count > 0:
		_tutorial_last_revealed_index = cell_index
	if _tutorial_step == TutorialStep.FIRST_REVEAL:
		var candidate := _find_tutorial_frontier()
		if candidate >= 0:
			_tutorial_number_index = candidate
			_tutorial_step = TutorialStep.NUMBER_INFO
	elif _tutorial_step == TutorialStep.NUMBER_INFO:
		_ensure_number_target()
	elif _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
	_refresh_first_move_guide()


func _on_flag_completed(_cell_index: int, _is_flagged: bool) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _on_chord_completed(_cell_index: int, newly_revealed_count: int) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step == TutorialStep.CHORD and newly_revealed_count > 0:
		_complete_tutorial()
	elif _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _on_tutorial_next_requested() -> void:
	if _tutorial_step != TutorialStep.NUMBER_INFO or _tutorial_dismissed_for_session:
		return
	_revalidate_tutorial_frontier()
	_refresh_first_move_guide()


func _on_tutorial_exit_requested() -> void:
	if board.level_number != 1:
		return
	_tutorial_dismissed_for_session = true
	_tutorial_step = TutorialStep.INACTIVE
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	board.clear_guide_cell()
	first_move_guide.hide_guide()
	_refresh_instructions()
	if board.game_state in [MinesweeperBoard.GameState.READY, MinesweeperBoard.GameState.PLAYING]:
		status_label.text = "引导已退出，可以自由净化"


func _ensure_number_target() -> void:
	if _is_useful_number_frontier(_tutorial_number_index):
		return
	_tutorial_number_index = _find_tutorial_frontier()
	if _tutorial_number_index < 0:
		_complete_tutorial()


func _revalidate_tutorial_frontier() -> void:
	_ensure_number_target()
	if _tutorial_step == TutorialStep.COMPLETE:
		return
	var wrong_neighbor := _find_wrong_flag_neighbor(_tutorial_number_index)
	if wrong_neighbor >= 0:
		_tutorial_step = TutorialStep.MARK_CORE
		_tutorial_target_index = wrong_neighbor
		return
	var required_core := _find_unflagged_core_neighbor(_tutorial_number_index)
	if required_core >= 0:
		if board.used_flags >= board.core_count:
			var wrong_flag := _find_wrong_flag()
			if wrong_flag >= 0:
				_tutorial_step = TutorialStep.MARK_CORE
				_tutorial_target_index = wrong_flag
				return
		_tutorial_step = TutorialStep.MARK_CORE
		_tutorial_target_index = required_core
		return
	_tutorial_step = TutorialStep.CHORD
	_tutorial_target_index = _tutorial_number_index


func _find_tutorial_frontier() -> int:
	var best_index := -1
	var best_number_priority := 2
	var best_remaining_cores := 999
	for cell_index in board.cell_count:
		if not _is_useful_number_frontier(cell_index):
			continue
		var number_priority := 0 if board.adjacent_counts[cell_index] == 1 else 1
		var remaining_cores := 0
		for neighbor in board.get_neighbor_indices(cell_index):
			if board.mines[neighbor] and not board.flagged[neighbor]:
				remaining_cores += 1
		if (
			number_priority < best_number_priority
			or (
				number_priority == best_number_priority
				and remaining_cores < best_remaining_cores
			)
		):
			best_index = cell_index
			best_number_priority = number_priority
			best_remaining_cores = remaining_cores
	return best_index


func _is_useful_number_frontier(cell_index: int) -> bool:
	if not _is_valid_tutorial_index(cell_index):
		return false
	if not board.revealed[cell_index] or board.adjacent_counts[cell_index] <= 0:
		return false
	var has_core := false
	var has_hidden_safe := false
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.mines[neighbor]:
			has_core = true
		elif not board.revealed[neighbor]:
			has_hidden_safe = true
	return has_core and has_hidden_safe


func _find_unflagged_core_neighbor(cell_index: int) -> int:
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.mines[neighbor] and not board.flagged[neighbor]:
			return neighbor
	return -1


func _find_wrong_flag_neighbor(cell_index: int) -> int:
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.flagged[neighbor] and not board.mines[neighbor]:
			return neighbor
	return -1


func _find_wrong_flag() -> int:
	for cell_index in board.cell_count:
		if board.flagged[cell_index] and not board.mines[cell_index]:
			return cell_index
	return -1


func _find_unrevealed_safe_index() -> int:
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and not board.revealed[cell_index] and not board.flagged[cell_index]:
			return cell_index
	return _tutorial_last_revealed_index


func _is_valid_tutorial_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < board.cell_nodes.size()


func _complete_tutorial() -> void:
	_tutorial_step = TutorialStep.COMPLETE
	_tutorial_dismissed_for_session = true
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	board.clear_guide_cell()
	first_move_guide.hide_guide()
	_refresh_instructions()
	if board.game_state == MinesweeperBoard.GameState.PLAYING:
		status_label.text = "引导完成，可以自由净化"


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
			eco_showcase.call("set_reaction", 0)
			_reset_timer()
			var tutorial_ready := (
				board.level_number == 1
				and not _tutorial_dismissed_for_session
				and _tutorial_step == TutorialStep.FIRST_REVEAL
			)
			status_label.text = "跟着清扫者认识棋盘（也可自由选择）" if tutorial_ready else "选择第一块净化区域"
			restart_button.text = "重新生成"
			pause_button.text = "暂停  ·  Esc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.PLAYING:
			eco_showcase.call("set_reaction", 0)
			_start_timer()
			status_label.text = "净化进行中"
			restart_button.text = "重新开始"
			pause_button.text = "暂停  ·  Esc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.WON:
			eco_showcase.call("set_reaction", 1)
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
			eco_showcase.call("set_reaction", 2)
			_pause_timer()
			pause_button.text = "菜单  ·  Esc"
			pause_button.disabled = false
			status_label.text = "触碰污染核心，请重新开始"
			restart_button.text = "重新开始"
	_refresh_first_move_guide()


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
