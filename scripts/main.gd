extends Control

@onready var board: MinesweeperBoard = %Board
@onready var subtitle_label: Label = %SubtitleLabel
@onready var status_label: Label = %StatusLabel
@onready var flags_label: Label = %FlagsLabel
@onready var instructions_label: Label = %InstructionsLabel
@onready var restart_button: Button = %RestartButton

var current_level_index := 0
var _advance_available := false


func _ready() -> void:
	board.state_changed.connect(_on_state_changed)
	board.flags_changed.connect(_on_flags_changed)
	restart_button.pressed.connect(_on_primary_button_pressed)
	_load_level(_requested_level_index())


func _load_level(level_index: int) -> void:
	current_level_index = clampi(level_index, 0, GreenSweeperLevels.LEVELS.size() - 1)
	var level: Dictionary = GreenSweeperLevels.LEVELS[current_level_index]
	board.load_level(level)
	subtitle_label.text = "第%d关 · %s  ｜  %d × %d · %d 个随机污染核心" % [
		board.level_number,
		board.level_name,
		board.column_count,
		board.row_count,
		board.core_count,
	]
	instructions_label.text = (
		"绿色箭头为安全建议  ·  双击数字快速展开  ·  右键标记"
		if board.first_move_guide_enabled
		else "无安全提示  ·  首点可能污染  ·  双击数字快速展开"
	)


func _on_state_changed(state: int) -> void:
	_advance_available = false
	match state:
		MinesweeperBoard.GameState.READY:
			status_label.text = "点击绿色箭头试试（也可自由选择）" if board.first_move_guide_enabled else "选择第一块净化区域"
			restart_button.text = "重新生成"
		MinesweeperBoard.GameState.PLAYING:
			status_label.text = "净化进行中"
			restart_button.text = "重新开始"
		MinesweeperBoard.GameState.WON:
			if current_level_index + 1 < GreenSweeperLevels.LEVELS.size():
				status_label.text = "净化完成！新的陆地区域已解锁"
				restart_button.text = "进入下一关"
				_advance_available = true
			else:
				status_label.text = "%s净化完成！" % board.level_name
				restart_button.text = "再来一局"
		MinesweeperBoard.GameState.LOST:
			status_label.text = "触碰污染核心，请重新开始"
			restart_button.text = "重新开始"


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "标记：%d/%d" % [used_flags, max_flags]


func _on_primary_button_pressed() -> void:
	if _advance_available:
		_load_level(current_level_index + 1)
	else:
		board.new_game()


func _requested_level_index() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			var requested_level := int(argument.trim_prefix("--level="))
			return requested_level - 1
	return 0
