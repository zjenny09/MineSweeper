extends SceneTree

const TEST_SAVE_PATH := "user://green_sweeper_desktop_layout_test.json"

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_cleanup()
	root.size = Vector2i(1280, 720)
	var shell_scene: PackedScene = load("res://scenes/shell.tscn")
	var shell := shell_scene.instantiate()
	shell.save_path = TEST_SAVE_PATH
	root.add_child(shell)
	await process_frame

	_test_menu_columns(shell)
	await _test_settings_layout(shell)
	await _test_first_guide_layout(shell)
	await _test_game_columns(shell)
	await _test_steam_deck_height(shell)

	shell.queue_free()
	await process_frame
	_cleanup()
	if failures == 0:
		print("Green Sweeper desktop layout tests passed.")
		quit(0)
	else:
		push_error("%d desktop layout test(s) failed." % failures)
		quit(1)


func _test_menu_columns(shell) -> void:
	var menu_panel := shell.get_node("%MenuPanel") as Control
	var showcase_panel := shell.get_node("%ShowcasePanel") as Control
	_expect(_inside_viewport(menu_panel), "The floating menu stays inside 1280x720.")
	_expect(_inside_viewport(showcase_panel), "The full-screen ecology artwork stays inside 1280x720.")
	_expect(showcase_panel.get_global_rect().encloses(menu_panel.get_global_rect()), "The title and actions float over the ecology artwork.")
	_expect(showcase_panel.size.x >= 1279.0 and showcase_panel.size.y >= 719.0, "The welcome artwork fills the 1280x720 viewport.")


func _test_settings_layout(shell) -> void:
	shell.show_settings()
	await process_frame
	var operation_mode := shell.get_node("%OperationModeOption") as Control
	var back_button := shell.get_node("%SettingsBackButton") as Control
	_expect(_inside_viewport(operation_mode), "The operation-mode selector fits inside 1280x720 settings.")
	_expect(_inside_viewport(back_button), "The enlarged settings panel keeps its back button inside 1280x720.")
	shell.show_main_menu()


func _test_first_guide_layout(shell) -> void:
	shell.start_cli_level(1)
	await process_frame
	await process_frame
	var game = shell.get_active_game()
	var guide = game.get_node("%FirstMoveGuide")
	var board := game.get_node("%Board") as MinesweeperBoard
	var bubble_rect: Rect2 = guide.get_stable_bubble_rect()
	var target_center: Vector2 = guide.get_target_center()
	var target_size: Vector2 = board.cell_nodes[board.guide_cell_index].size
	var target_rect := Rect2(target_center - target_size * 0.5, target_size)
	var vertical_gap := minf(
		absf(target_rect.position.y - bubble_rect.end.y),
		absf(bubble_rect.position.y - target_rect.end.y)
	)
	_expect(guide.visible and guide.target_cell_index == board.guide_cell_index, "The level-1 guide targets the suggested cell.")
	_expect(Rect2(Vector2.ZERO, guide.size).encloses(bubble_rect), "The stable guide bubble remains inside the board panel at 1280x720.")
	_expect(not bubble_rect.intersects(target_rect), "The guide bubble does not cover the suggested cell.")
	_expect(vertical_gap <= 13.0, "The guide bubble floats directly beside the suggested cell without a long connector.")
	_expect(board.custom_minimum_size == Vector2(422.0, 422.0), "The guide overlay does not change the level-1 board size.")


func _test_game_columns(shell) -> void:
	shell.start_cli_level(5)
	await process_frame
	var game = shell.get_active_game()
	var environment_panel := game.get_node("%EnvironmentPanel") as Control
	var board_panel := game.get_node("%BoardPanel") as Control
	var hud_panel := game.get_node("%HudPanel") as Control
	_expect(_inside_viewport(environment_panel) and _inside_viewport(board_panel) and _inside_viewport(hud_panel), "All three gameplay columns stay inside the viewport.")
	_expect(environment_panel.global_position.x + environment_panel.size.x < board_panel.global_position.x, "The environment column sits left of the board.")
	_expect(board_panel.global_position.x + board_panel.size.x < hud_panel.global_position.x, "The HUD column sits right of the board.")
	var board := game.get_node("%Board") as MinesweeperBoard
	_expect(board.custom_minimum_size.x >= 480.0 and board.custom_minimum_size.x <= 530.0, "The largest square board uses the expanded desktop target.")

	game.start_level(5)
	await process_frame
	_expect(board.custom_minimum_size == Vector2(620.0, 460.0), "The triangle board uses the 620x460 desktop stage.")
	game.set_session_paused(true)
	await process_frame
	var overlay := game.get_node("%PauseOverlay") as Control
	_expect(overlay.visible and overlay.global_position == Vector2.ZERO, "Pause overlay starts at the viewport origin.")
	_expect(overlay.size == Vector2(root.size), "Pause overlay covers the complete three-column viewport.")
	game.set_session_paused(false)


func _test_steam_deck_height(shell) -> void:
	shell.show_main_menu()
	root.size = Vector2i(1280, 800)
	await process_frame
	await process_frame
	var menu_panel := shell.get_node("%MenuPanel") as Control
	var showcase_panel := shell.get_node("%ShowcasePanel") as Control
	_expect(_inside_viewport(menu_panel) and _inside_viewport(showcase_panel), "The menu remains inside a 1280x800 viewport.")
	_expect(menu_panel.size.y > 680.0 and showcase_panel.size.y > 680.0, "Steam Deck height becomes usable page space.")
	shell.show_settings()
	await process_frame
	_expect(_inside_viewport(shell.get_node("%OperationModeOption") as Control), "The operation selector remains inside the 1280x800 settings page.")
	shell.start_cli_level(1)
	await process_frame
	await process_frame
	var guide = shell.get_active_game().get_node("%FirstMoveGuide")
	_expect(Rect2(Vector2.ZERO, guide.size).encloses(guide.get_stable_bubble_rect()), "The first-move guide remains inside the board panel at 1280x800.")


func _inside_viewport(control: Control) -> bool:
	var rect := control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	return viewport_rect.encloses(rect)


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
