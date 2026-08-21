extends Control

@onready var board: MinesweeperBoard = %Board
@onready var status_label: Label = %StatusLabel
@onready var flags_label: Label = %FlagsLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	board.state_changed.connect(_on_state_changed)
	board.flags_changed.connect(_on_flags_changed)
	restart_button.pressed.connect(board.new_game)
	_on_state_changed(board.game_state)
	_on_flags_changed(board.used_flags, board.core_count)


func _on_state_changed(state: int) -> void:
	match state:
		MinesweeperBoard.GameState.READY:
			status_label.text = "点击绿色箭头试试（也可自由选择）" if board.first_move_guide_enabled else "选择第一块净化区域"
		MinesweeperBoard.GameState.PLAYING:
			status_label.text = "净化进行中"
		MinesweeperBoard.GameState.WON:
			status_label.text = "净化完成！萌芽重新生长"
		MinesweeperBoard.GameState.LOST:
			status_label.text = "触碰污染核心，请重新开始"


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "标记：%d/%d" % [used_flags, max_flags]
