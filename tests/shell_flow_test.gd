extends SceneTree

const TEST_SAVE_PATH := "user://green_sweeper_shell_test.json"
const SAVE_STORE_SCRIPT: Script = preload("res://scripts/save_store.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_cleanup_test_files()
	var settings_fixture: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	settings_fixture.set_master_volume(0.72)
	settings_fixture.save_data()
	var packed_scene: PackedScene = load("res://scenes/shell.tscn")
	var shell := packed_scene.instantiate()
	shell.save_path = TEST_SAVE_PATH
	root.add_child(shell)
	await process_frame

	_test_initial_menu(shell)
	_test_level_argument_parser(shell)
	_test_locked_level_cards(shell)
	await _test_start_pause_and_restart(shell)
	_test_completion_and_unlock(shell)
	_test_continue(shell)
	_test_cli_read_only(shell)
	_test_ocean_scan_persistence(shell)
	_test_return_to_level_select(shell)
	_test_pause_settings_round_trip(shell)
	_test_operation_mode_setting(shell)
	_test_return_to_main_menu(shell)
	_test_volume_setting(shell)

	shell.queue_free()
	await process_frame
	_cleanup_test_files()
	if failures == 0:
		print("Green Sweeper shell flow tests passed.")
		quit(0)
	else:
		push_error("%d shell flow test(s) failed." % failures)
		quit(1)


func _test_initial_menu(shell) -> void:
	_expect(shell.get_node("%MainMenu").visible, "A normal launch opens the main menu.")
	_expect(not shell.get_node("%ContinueButton").visible, "The welcome menu keeps Continue out of the primary action list.")
	_expect(shell.get_node("%ChooseLevelButton").visible, "The welcome menu exposes level selection as a primary action.")
	_expect(not shell.get_node("%GameHost").visible, "No game is created before the player chooses one.")
	_expect(shell.get_node("%ContinueButton").disabled, "Continue is disabled for a new save.")
	_expect(shell.get_node("%VolumeValueLabel").text == "72%", "Saved volume updates the settings percentage on startup.")


func _test_level_argument_parser(shell) -> void:
	_expect(shell.parse_level_argument(PackedStringArray(["--level=1"])) == 1, "CLI accepts level 1.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=5"])) == 5, "CLI accepts level 5.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=0"])) == -1, "CLI rejects level 0.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=6"])) == 6, "CLI accepts ocean level 6.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=10"])) == 10, "CLI accepts ocean level 10.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=11"])) == -1, "CLI rejects levels beyond the ocean prototype.")
	_expect(shell.parse_level_argument(PackedStringArray(["--level=forest"])) == -1, "CLI rejects non-numeric levels.")
	_expect(shell.parse_level_argument(PackedStringArray()) == 0, "No CLI level keeps the menu flow.")


func _test_locked_level_cards(shell) -> void:
	shell.show_level_select()
	var markers: Array = shell.get_node("%LevelGrid").get_children()
	_expect(markers.size() == 5, "Level select builds one marker for each land level.")
	_expect(not markers[0].get_node("LevelButton01").disabled, "Level 1 is unlocked for a new save.")
	for index in range(1, markers.size()):
		var button := markers[index].get_node("LevelButton%02d" % (index + 1)) as Button
		_expect(button.disabled, "Later levels begin locked.")


func _test_start_pause_and_restart(shell) -> void:
	shell.start_normal_level(1)
	var game = shell.get_active_game()
	_expect(game != null and shell.get_node("%GameHost").visible, "Start creates the game page.")
	_expect(game.board.level_number == 1, "Start begins at level 1.")
	_expect(shell.save_store.get_last_played_level() == 1, "Starting records the continue target.")
	_expect(shell.save_store.has_seen_first_move_guide(), "Starting the first game persists the guide state.")
	_expect(game.get_scan_energy() == 12, "The first normal level-one entry receives a full scan grant.")
	_expect(shell.save_store.has_claimed_level_one_scan_grant(), "The level-one grant is marked claimed immediately.")
	var grant_reloaded: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	grant_reloaded.load_data()
	_expect(grant_reloaded.get_scan_energy() == 12, "The initial grant is persisted before play continues.")

	var number_index := -1
	for cell_index in game.board.cell_count:
		if not game.board.mines[cell_index] and game.board.adjacent_counts[cell_index] > 0:
			number_index = cell_index
			break
	game.board.reveal_cell(number_index)
	var mine_index := -1
	for cell_index in game.board.cell_count:
		if game.board.mines[cell_index] and not game.board.flagged[cell_index]:
			mine_index = cell_index
			break
	game.call("_request_scan_mode")
	game.call("_on_scan_target_requested", mine_index)
	_expect(game.get_scan_energy() == 0, "A real scan consumes the granted energy.")
	_expect(shell.save_store.get_scan_energy() == 0, "Scan consumption is saved immediately.")
	var first_flag_target := -1
	for cell_index in game.board.cell_count:
		if not game.board.revealed[cell_index] and not game.board.flagged[cell_index]:
			first_flag_target = cell_index
			break
	game.board.toggle_flag(first_flag_target)
	_expect(game.get_scan_energy() == 1, "A first manual flag begins the next charge cycle.")
	_expect(shell.save_store.get_scan_energy() == 1, "Earned scan energy is saved immediately.")
	game.board.toggle_flag(first_flag_target)
	await create_timer(0.08).timeout
	game.set_session_paused(true)
	var paused_elapsed: int = game.get_elapsed_ms()
	var revealed_before: int = game.board.revealed_safe_count
	var another_safe := -1
	for cell_index in game.board.cell_count:
		if not game.board.mines[cell_index] and not game.board.revealed[cell_index]:
			another_safe = cell_index
			break
	game.board.reveal_cell(another_safe)
	await create_timer(0.12).timeout
	_expect(game.is_session_paused(), "The session enters the paused state.")
	_expect(not game.board.interaction_enabled, "Pause locks board interaction.")
	_expect(game.board.revealed_safe_count == revealed_before, "A paused board ignores reveal requests.")
	_expect(abs(game.get_elapsed_ms() - paused_elapsed) <= 15, "Paused time is excluded from the timer.")

	game.set_session_paused(false)
	_expect(game.board.interaction_enabled, "Resume restores board interaction.")
	game.restart_level()
	_expect(game.get_elapsed_ms() == 0 and game.board.revealed.count(true) == 0, "Pause-menu restart resets time and board state.")
	_expect(game.get_scan_energy() == 1, "Restart keeps the shared scan energy.")
	_expect(game.get_scan_phase() == game.ScanPhase.LOCKED_FIRST_REVEAL, "Restart restores the first-reveal scan lock.")


func _test_completion_and_unlock(shell) -> void:
	var game = shell.get_active_game()
	for cell_index in game.board.cell_count:
		if game.board.game_state == MinesweeperBoard.GameState.WON:
			break
		if not game.board.mines[cell_index] and not game.board.revealed[cell_index]:
			game.board.reveal_cell(cell_index)
	_expect(game.board.game_state == MinesweeperBoard.GameState.WON, "The shell receives a real level completion.")
	_expect(shell.save_store.is_level_completed(1), "Completion is saved for level 1.")
	_expect(shell.save_store.is_level_unlocked(2), "Completing level 1 unlocks level 2.")
	_expect(shell.save_store.get_best_time_ms(1) >= 0, "Completion stores a best time.")
	game.set_session_paused(true)
	_expect(game.is_session_paused() and game.get_node("%PauseOverlay").visible, "A completed level can still open the menu.")
	_expect(not game.get_node("%PauseButton").disabled, "The result screen keeps its menu button enabled.")
	game.set_session_paused(false)

	shell.show_level_select()
	var markers: Array = shell.get_node("%LevelGrid").get_children()
	var level_one_button := markers[0].get_node("LevelButton01") as Button
	var level_two_button := markers[1].get_node("LevelButton02") as Button
	var level_three_button := markers[2].get_node("LevelButton03") as Button
	_expect(not level_two_button.disabled, "The newly unlocked level is selectable immediately.")
	_expect(level_three_button.disabled, "Level 3 remains locked until level 2 is complete.")
	_expect(level_one_button.modulate != Color.WHITE, "Completed markers display their completed state color.")


func _test_continue(shell) -> void:
	shell.save_store.set_scan_energy(3)
	shell.save_store.save_data()
	shell.show_main_menu()
	var continue_button := shell.get_node("%ContinueButton") as Button
	_expect(not continue_button.disabled, "Continue is enabled after a normal level starts.")
	continue_button.emit_signal("pressed")
	_expect(shell.get_active_game() != null and shell.get_active_game().board.level_number == 1, "Continue regenerates the last played level.")
	_expect(shell.get_active_game().board.revealed.count(true) == 0, "Continue does not restore an old board snapshot.")
	_expect(shell.get_active_game().get_scan_energy() == 3, "Returning to level one does not grant scan energy twice.")
	_expect(not shell.get_active_game().get_node("%FirstMoveGuide").visible, "Returning players do not see the first-move guide again.")


func _test_cli_read_only(shell) -> void:
	var last_level_before: int = shell.save_store.get_last_played_level()
	var scan_energy_before: int = shell.save_store.get_scan_energy()
	shell.start_cli_level(10)
	var game = shell.get_active_game()
	_expect(
		shell.is_cli_read_only()
		and game.board.level_number == 10
		and game.board.topology == &"hex_pointy_odd_r",
		"CLI mode can bypass locks and enter ocean level 10."
	)
	for cell_index in game.board.cell_count:
		if game.board.game_state == MinesweeperBoard.GameState.WON:
			break
		if not game.board.mines[cell_index] and not game.board.revealed[cell_index]:
			game.board.reveal_cell(cell_index)
	_expect(game.board.game_state == MinesweeperBoard.GameState.WON, "A CLI session remains fully playable.")
	_expect(not shell.save_store.is_level_completed(5), "Ocean CLI completion does not change land progress.")
	_expect(shell.save_store.get_last_played_level() == last_level_before, "CLI sessions do not replace Continue progress.")
	_expect(shell.save_store.get_scan_energy() == scan_energy_before, "CLI sessions do not write shared scan energy.")


func _test_ocean_scan_persistence(shell) -> void:
	var last_level_before: int = shell.save_store.get_last_played_level()
	shell.save_store.set_scan_energy(5)
	shell.save_store.save_data()
	shell.call("_start_level_number", 6, false, true)
	var game = shell.get_active_game()
	_expect(not shell.is_cli_read_only(), "Normal ocean selection persists scan state without becoming CLI mode.")
	_expect(game.get_scan_energy() == 5, "Ocean play receives the shared saved energy.")
	var ocean_opening := -1
	for cell_index in game.board.cell_count:
		if not game.board.mines[cell_index] and game.board.adjacent_counts[cell_index] > 0:
			ocean_opening = cell_index
			break
	game.board.reveal_cell(ocean_opening)
	_expect(game.get_scan_energy() == 6, "A valid ocean reveal adds one shared energy.")
	_expect(shell.save_store.get_scan_energy() == 6, "Normal ocean charge is saved immediately.")
	_expect(shell.save_store.get_last_played_level() == last_level_before, "Ocean scan persistence does not replace land Continue progress.")
	var reloaded: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	reloaded.load_data()
	_expect(reloaded.get_scan_energy() == 6, "Ocean scan energy survives a store reload.")


func _test_return_to_level_select(shell) -> void:
	shell.start_normal_level(1)
	var game = shell.get_active_game()
	game.level_select_requested.emit()
	_expect(shell.get_active_game() == game, "Opening the level map preserves the current game instance.")
	_expect(shell.get_node("%LevelSelect").visible, "The level-select page appears over a retained game.")
	shell.call("_on_level_back_pressed")
	_expect(shell.get_node("%GameHost").visible and shell.get_active_game() == game, "Return to level restores the retained game.")


func _test_pause_settings_round_trip(shell) -> void:
	shell.start_normal_level(1)
	var game = shell.get_active_game()
	game.set_session_paused(true)
	game.settings_requested.emit()
	_expect(shell.get_node("%Settings").visible, "Pause can open the shared settings page.")
	_expect(shell.get_active_game() == game, "Opening settings keeps the current game instance alive.")
	shell.call("_close_settings")
	_expect(shell.get_node("%GameHost").visible, "Closing in-game settings returns to the game page.")
	_expect(shell.get_active_game() == game and game.is_session_paused(), "The same game remains paused after closing settings.")


func _test_operation_mode_setting(shell) -> void:
	var option := shell.get_node("%OperationModeOption") as OptionButton
	_expect(option.item_count == 2, "Settings provides mouse and keyboard operation modes.")
	_expect(option.selected == 0, "A new save defaults to mouse operation.")
	var game = shell.get_active_game()
	game.settings_requested.emit()
	option.select(1)
	shell.call("_on_operation_mode_selected", 1)
	_expect(shell.save_store.get_operation_mode() == 1, "Keyboard operation is stored immediately.")
	_expect(game.get_operation_mode() == 1, "A retained paused game receives the new operation mode.")
	_expect(game.board.get_operation_mode() == MinesweeperBoard.OperationMode.KEYBOARD, "The board enters keyboard mode without restarting.")
	_expect(
		game.get_node("%InstructionsLabel").text.contains("Z 净化")
		and game.get_node("%InstructionsLabel").text.contains("X 标记"),
		"Keyboard mode displays the selected Z/X controls."
	)
	shell.call("_close_settings")
	_expect(game.is_session_paused(), "Changing operation mode preserves the paused game.")
	var reloaded: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	reloaded.load_data()
	_expect(reloaded.get_operation_mode() == 1, "Keyboard operation mode persists on disk.")
	shell.start_cli_level(5)
	var cli_game = shell.get_active_game()
	_expect(cli_game.board.get_operation_mode() == MinesweeperBoard.OperationMode.KEYBOARD, "CLI games receive the saved operation mode.")
	_expect(cli_game.board.get_keyboard_cell_index() >= 0, "The square board shows a keyboard selection cursor.")


func _test_return_to_main_menu(shell) -> void:
	shell.start_normal_level(1)
	var game = shell.get_active_game()
	_expect(game.get_node("%PauseSettingsButton") != null, "Pause provides a standard settings entry.")
	_expect(game.get_node("%ExitGameButton") != null, "Pause provides a visible exit-game control.")
	game.main_menu_requested.emit()
	_expect(shell.get_active_game() == null, "Returning to the main menu releases the game instance.")
	_expect(shell.get_node("%MainMenu").visible, "The main menu appears directly from pause navigation.")


func _test_volume_setting(shell) -> void:
	var slider := shell.get_node("%VolumeSlider") as HSlider
	var display_mode := shell.get_node("%DisplayModeOption") as OptionButton
	_expect(display_mode.item_count == 3, "Settings provides windowed, maximized, and borderless modes.")
	_expect(display_mode.selected == 1 and display_mode.get_item_text(1) == "最大化窗口", "A new install defaults to a maximized window.")
	shell.show_settings()
	slider.value = 0.44
	shell.call("_close_settings")
	_expect(shell.get_node("%MainMenu").visible, "Settings opened from the main menu returns to the main menu.")
	var keyboard_reloaded: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	keyboard_reloaded.load_data()
	_expect(is_equal_approx(keyboard_reloaded.get_master_volume(), 0.44), "Keyboard-style volume changes save when leaving settings.")

	shell.show_settings()
	slider.value = 0.35
	shell.call("_on_volume_drag_ended", true)
	_expect(is_equal_approx(shell.save_store.get_master_volume(), 0.35), "Master volume changes are stored.")
	var reloaded: Variant = SAVE_STORE_SCRIPT.new(TEST_SAVE_PATH)
	reloaded.load_data()
	_expect(is_equal_approx(reloaded.get_master_volume(), 0.35), "Master volume persists on disk.")


func _cleanup_test_files() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
