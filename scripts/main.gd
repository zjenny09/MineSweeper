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
	_on_flags_changed(board.used_flags, MinesweeperBoard.MINE_COUNT)


func _on_state_changed(state: int) -> void:
	match state:
		MinesweeperBoard.GameState.READY:
			status_label.text = "准备：点击任意格开始"
		MinesweeperBoard.GameState.PLAYING:
			status_label.text = "游戏中"
		MinesweeperBoard.GameState.WON:
			status_label.text = "胜利！所有安全格都已翻开"
		MinesweeperBoard.GameState.LOST:
			status_label.text = "踩雷了！点击按钮重新开始"


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "旗帜：%d/%d" % [used_flags, max_flags]
