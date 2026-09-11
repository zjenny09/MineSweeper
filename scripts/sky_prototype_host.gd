extends Control

const GAME_SCENE := preload("res://scenes/main.tscn")
const SKY_SPHERE_BOARD_SCRIPT := preload("res://scripts/sky_sphere_board.gd")

var _game: Control
var _sky_board: Control


func _ready() -> void:
	_game = GAME_SCENE.instantiate() as Control
	_game.set("auto_start", false)
	add_child(_game)
	await get_tree().process_frame
	_prepare_sky_interface()
	_mount_sky_board()


func _prepare_sky_interface() -> void:
	_game.visible = true
	(_game.get_node("%OceanStage") as Control).visible = true
	(_game.get_node("%OceanBoardTrayFrame") as Control).visible = false
	(_game.get_node("%LandDeskBackground") as Control).visible = false
	(_game.get_node("%LevelOneBackground") as Control).visible = false
	(_game.get_node("%LandUnifiedShadow") as Control).visible = false
	(_game.get_node("%EcoShowcase") as Control).visible = false
	(_game.get_node("%BoardTray") as Control).visible = false
	(_game.get_node("%BoardShadow") as Control).visible = false
	(_game.get_node("%LandTabletopActors") as Control).visible = false
	(_game.get_node("%FirstMoveGuide") as Control).visible = false
	(_game.get_node("%ScanFallbackRow") as Control).visible = false


func _mount_sky_board() -> void:
	var board := _game.get_node("%Board") as Control
	var board_center := board.get_parent() as CenterContainer
	board.visible = false

	_sky_board = SKY_SPHERE_BOARD_SCRIPT.new() as Control
	_sky_board.custom_minimum_size = board.custom_minimum_size
	_sky_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sky_board.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	board_center.add_child(_sky_board)

	var flags_label := _game.get_node("%FlagsLabel") as Label
	var status_label := _game.get_node("%StatusLabel") as Label
	_sky_board.connect(
		"flags_changed",
		func(used_flags: int, max_flags: int) -> void:
			flags_label.text = "%d/%d" % [used_flags, max_flags]
	)
	_sky_board.connect(
		"status_changed",
		func(text: String) -> void:
			status_label.text = text
	)
	_sky_board.connect("first_reveal", Callable(_game, "_start_timer"))

	(_game.get_node("%SubtitleLabel") as Label).text = "第15关 · 云冠（球面原型）"
	(_game.get_node("%LevelSummaryLabel") as Label).text = (
		"12个五边形 + 20个六边形\n污染核心 6"
	)
	(_game.get_node("%ObjectiveLabel") as Label).text = (
		"旋转足球烯球面，净化全部安全面"
	)
	(_game.get_node("%InstructionsLabel") as Label).text = (
		"拖拽旋转 · 左键净化 · 右键标记\n"
		+ "方向键选择 · WASD旋转 · Enter翻开 · F标记"
	)
	flags_label.text = "0/6"
	status_label.text = "旋转球面，寻找安全起点"

	var restart_button := _game.get_node("%RestartButton") as BaseButton
	for connection in restart_button.pressed.get_connections():
		restart_button.pressed.disconnect(connection.callable)
	restart_button.pressed.connect(Callable(_sky_board, "new_game"))
	var pause_restart_button := _game.get_node("%PauseRestartButton") as BaseButton
	for connection in pause_restart_button.pressed.get_connections():
		pause_restart_button.pressed.disconnect(connection.callable)
	pause_restart_button.pressed.connect(Callable(_sky_board, "new_game"))
