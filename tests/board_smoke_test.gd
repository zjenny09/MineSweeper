extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	var board := main_scene.get_node("%Board") as MinesweeperBoard

	_test_level_setup(board)
	_test_guide_behavior(main_scene, board)
	_test_rebellious_first_click(board)
	_test_random_layouts(board)
	_test_flags_win_and_restart(board)
	_test_player_facing_terms(main_scene, board)
	_test_level_transition(main_scene, board)
	_test_level_2(main_scene, board)
	_test_land_level_data(main_scene, board)
	_test_chord_behavior(main_scene, board)
	_test_keyboard_controls(main_scene, board)
	_test_level_one_visuals(main_scene, board)

	main_scene.queue_free()
	if failures == 0:
		print("Green Sweeper level framework tests passed.")
		quit(0)
	else:
		push_error("%d Green Sweeper test(s) failed." % failures)
		quit(1)


func _test_level_setup(board: MinesweeperBoard) -> void:
	_expect(board.level_number == 1 and board.level_name == "萌芽", "Level 1 is Sprout.")
	_expect(board.row_count == 5 and board.column_count == 5, "Level 1 uses a 5x5 board.")
	_expect(board.cell_nodes.size() == 25, "Level 1 creates 25 cells.")
	_expect(board.core_count == 5 and board.safe_cell_count == 20, "Level 1 uses five pollution cores.")
	board._random.seed = 100
	board.new_game()
	_expect(board.game_state == MinesweeperBoard.GameState.READY, "A new game waits for a player choice.")
	_expect(board.mines.count(true) == 5, "The complete random layout exists before the first click.")
	_expect(board.revealed.count(true) == 0, "No cells are open before the first click.")
	_validate_numbers(board)


func _test_guide_behavior(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 0)
	board._random.seed = 1000
	main_scene.call("restart_level")
	var guide = main_scene.get_node("%FirstMoveGuide")
	var next_button := main_scene.get_node("%TutorialNextButton") as Button
	var exit_button := main_scene.get_node("%TutorialExitButton") as Button
	var guide_index := board.guide_cell_index
	_expect(guide_index >= 0 and not board.mines[guide_index], "Level 1 starts with a genuinely safe suggestion.")
	_expect(guide.visible and guide.target_cell_index == guide_index, "The continuous tutorial starts at the safe suggestion.")
	_expect(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The tutorial overlay never blocks board input.")
	_expect(exit_button.visible and exit_button.mouse_filter == Control.MOUSE_FILTER_STOP, "Only the tutorial exit button captures its own clicks.")
	_expect(not next_button.visible, "The action-led opening step does not need a next button.")

	main_scene.call("set_operation_mode", MinesweeperBoard.OperationMode.KEYBOARD)
	_expect(guide.is_keyboard_mode() and guide.get_action_text().contains("Z"), "Keyboard mode explains the Z reveal action.")
	_expect(board.get_keyboard_cell_index() == guide_index, "Keyboard selection starts on the suggested cell.")
	board._input(_key_event(KEY_RIGHT))
	_expect(guide.visible, "Moving the keyboard cursor does not dismiss the tutorial.")
	main_scene.call("set_operation_mode", MinesweeperBoard.OperationMode.MOUSE)
	_expect(not guide.is_keyboard_mode() and guide.get_action_text().contains("左键"), "Mouse mode explains the left-click reveal action.")

	var reveal_events: Array = []
	board.reveal_completed.connect(func(index: int, count: int) -> void: reveal_events.append([index, count]), CONNECT_ONE_SHOT)
	var expected := _expected_opening(board, guide_index)
	board.reveal_cell(guide_index)
	_expect(board.revealed == expected, "Following the guide uses the classic number-or-zero opening rule.")
	_expect(reveal_events.size() == 1 and reveal_events[0][0] == guide_index and reveal_events[0][1] > 0, "A valid reveal emits one post-action tutorial event.")
	_expect(board.guide_cell_index == -1, "The initial yellow suggestion clears after the first reveal.")
	_expect(guide.visible and next_button.visible, "The tutorial continues with the numbered-cell explanation.")
	var number_index: int = main_scene.get("_tutorial_number_index")
	_expect(number_index >= 0 and board.revealed[number_index] and board.adjacent_counts[number_index] > 0, "The explanation points at a revealed frontier number.")
	_expect(guide.target_cell_index == number_index, "The bubble moves next to the number it explains.")

	main_scene.call("_on_tutorial_next_requested")
	_expect(guide.visible and not next_button.visible, "Next advances from explanation to an operation step.")
	var core_neighbors: Array[int] = []
	for neighbor in board.get_neighbor_indices(number_index):
		if board.mines[neighbor]:
			core_neighbors.append(neighbor)
	for core_index in core_neighbors:
		if not board.flagged[core_index]:
			board.toggle_flag(core_index)
	_expect(guide.visible and guide.target_cell_index == number_index, "After all required seeds are placed, the guide returns to the number.")
	_expect(guide.get_action_text().contains("双击"), "Mouse mode explains quick expansion with a double-click.")
	var chord_events: Array = []
	board.chord_completed.connect(func(index: int, count: int) -> void: chord_events.append([index, count]), CONNECT_ONE_SHOT)
	board.chord_cell(number_index)
	_expect(chord_events.size() == 1 and chord_events[0][0] == number_index and chord_events[0][1] > 0, "A successful quick expansion emits a post-action tutorial event.")
	_expect(not guide.visible, "The tutorial hides after quick expansion is learned.")

	main_scene.call("restart_level")
	_expect(not guide.visible and board.guide_cell_index == -1, "A completed tutorial stays dismissed when the same level restarts.")
	main_scene.call("_load_level", 1)
	_expect(not guide.visible, "Later levels do not show the Level 1 tutorial.")
	main_scene.call("_load_level", 0)
	_expect(guide.visible and board.guide_cell_index >= 0, "Entering Level 1 again starts a fresh tutorial session.")
	main_scene.call("_on_tutorial_exit_requested")
	_expect(not guide.visible and board.guide_cell_index == -1, "Exit hides the tutorial and clears the yellow suggestion immediately.")
	main_scene.call("restart_level")
	_expect(not guide.visible and board.guide_cell_index == -1, "An exited tutorial stays dismissed across restart.")
	main_scene.call("set_operation_mode", MinesweeperBoard.OperationMode.MOUSE)
	board._random.randomize()


func _test_rebellious_first_click(board: MinesweeperBoard) -> void:
	board._random.seed = 2026
	board.new_game()
	var suggested_index := board.guide_cell_index
	var core_index := board.mines.find(true)
	_expect(core_index != suggested_index, "The guide never points to a pollution core.")
	board.reveal_cell(core_index)
	_expect(board.game_state == MinesweeperBoard.GameState.LOST, "Ignoring the guide can hit a pollution core immediately.")
	_expect(board.guide_cell_index == -1, "The guide disappears even when the player ignores it.")

	board._random.seed = 2027
	board.new_game()
	var other_safe_index := -1
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and cell_index != board.guide_cell_index:
			other_safe_index = cell_index
			break
	_expect(other_safe_index >= 0, "There is another safe choice besides the guide.")
	board.reveal_cell(other_safe_index)
	_expect(board.game_state != MinesweeperBoard.GameState.LOST, "A safe rebellious choice still plays normally.")
	_expect(board.guide_cell_index == -1, "Any first click dismisses the guide.")
	board._random.randomize()


func _test_random_layouts(board: MinesweeperBoard) -> void:
	var layouts: Dictionary = {}
	for trial in 12:
		board._random.seed = 5000 + trial
		board.new_game()
		layouts[_core_layout_key(board)] = true
	_expect(layouts.size() > 1, "Restarting can generate different pollution layouts.")
	board._random.randomize()


func _test_flags_win_and_restart(board: MinesweeperBoard) -> void:
	board._random.seed = 42
	board.new_game()
	var hidden_index := 0
	board.toggle_flag(hidden_index)
	_expect(board.flagged[hidden_index] and board.used_flags == 1, "A hidden cell can be marked before opening.")
	board.toggle_flag(hidden_index)
	_expect(not board.flagged[hidden_index] and board.used_flags == 0, "A mark can be removed.")

	var safe_index := board.guide_cell_index
	board.reveal_cell(safe_index)
	for cell_index in board.cell_count:
		if board.game_state != MinesweeperBoard.GameState.PLAYING:
			break
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Opening all safe cells wins the game.")

	board.new_game()
	_expect(board.game_state == MinesweeperBoard.GameState.READY, "Restart returns to the unopened guided state.")
	_expect(board.mines.count(true) == 5 and board.revealed.count(true) == 0, "Restart creates a closed five-core layout.")
	_expect(board.used_flags == 0 and board.guide_cell_index >= 0, "Restart clears marks and restores guidance.")
	board._random.randomize()


func _test_player_facing_terms(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 0)
	var flags_label := main_scene.get_node("%FlagsLabel") as Label
	var status_label := main_scene.get_node("%StatusLabel") as Label
	_expect(flags_label.text == "0/5", "The counter shows used and available marks.")
	_expect(status_label.text in ["引导中", "准备中"], "The initial status reports the ready tutorial state.")
	_expect(board.cell_nodes[board.guide_cell_index].tooltip_text.contains("也可以忽略"), "The guide explicitly remains optional.")


func _test_level_transition(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 0)
	board.reveal_cell(board.guide_cell_index)
	for cell_index in board.cell_count:
		if board.game_state != MinesweeperBoard.GameState.PLAYING:
			break
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Level 1 can be completed before advancing.")
	var primary_button_label := main_scene.get_node("%RestartButtonLabel") as Label
	_expect(primary_button_label.text == "下一关", "Finishing level 1 offers the next level.")
	main_scene.call("_on_primary_button_pressed")
	_expect(board.level_number == 2 and board.level_name == "灌木", "The next-level button loads Shrubland.")


func _test_level_2(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 1)
	_expect(board.row_count == 6 and board.column_count == 6, "Level 2 uses a 6x6 board.")
	_expect(board.cell_nodes.size() == 36, "Level 2 creates 36 cells.")
	_expect(board.core_count == 8 and board.safe_cell_count == 28, "Level 2 uses eight pollution cores.")
	_expect(not board.first_move_guide_enabled and board.guide_cell_index == -1, "Level 2 removes first-move guidance.")
	_expect(not _any_arrow_visible(board), "Level 2 shows no obsolete safe arrow.")
	_expect(not main_scene.get_node("%FirstMoveGuide").visible, "Level 2 never shows the first-move sprout guide.")
	_expect(board.mines.count(true) == 8 and board.revealed.count(true) == 0, "Level 2 starts as a complete closed random board.")
	var status_label := main_scene.get_node("%StatusLabel") as Label
	var instructions_label := main_scene.get_node("%InstructionsLabel") as Label
	_expect(status_label.text == "准备中", "Level 2 starts in the ready state.")
	_expect(instructions_label.text.contains("首点可能污染"), "Level 2 warns that the first choice is unprotected.")

	board._random.seed = 6202
	board.new_game()
	var first_core := board.mines.find(true)
	board.reveal_cell(first_core)
	_expect(board.game_state == MinesweeperBoard.GameState.LOST, "Level 2 can lose on the first click.")

	var layouts: Dictionary = {}
	for trial in 10:
		board._random.seed = 7000 + trial
		board.new_game()
		layouts[_core_layout_key(board)] = true
		_expect(board.mines.count(true) == 8, "Every level 2 board contains eight cores.")
	_expect(layouts.size() > 1, "Level 2 restart produces different layouts.")
	board._random.randomize()


func _test_land_level_data(main_scene: Node, board: MinesweeperBoard) -> void:
	var expected_levels := [
		{"index": 2, "number": 3, "name": "湿地", "size": 8, "cores": 9},
		{"index": 3, "number": 4, "name": "草原", "size": 10, "cores": 17},
		{"index": 4, "number": 5, "name": "森林", "size": 12, "cores": 28},
	]
	for expected in expected_levels:
		main_scene.call("_load_level", expected.index)
		_expect(board.level_number == expected.number and board.level_name == expected.name, "The expected land level loads.")
		_expect(board.row_count == expected.size and board.column_count == expected.size, "%s uses its configured square size." % expected.name)
		_expect(board.cell_nodes.size() == expected.size * expected.size, "%s creates the correct cell count." % expected.name)
		_expect(board.core_count == expected.cores and board.mines.count(true) == expected.cores, "%s creates the configured pollution cores." % expected.name)
		_expect(not board.first_move_guide_enabled and board.guide_cell_index == -1, "%s has no first-move guide." % expected.name)
		_expect(board.revealed.count(true) == 0, "%s starts completely closed." % expected.name)
		_validate_numbers(board)
	var subtitle_label := main_scene.get_node("%SubtitleLabel") as Label
	_expect(subtitle_label.text.contains("第5关 · 森林"), "The header updates for the fifth level.")


func _test_chord_behavior(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 1)
	board._random.seed = 8100
	board.new_game()
	var number_index := _find_chord_candidate(board)
	_expect(number_index >= 0, "A numbered cell with safe and core neighbors exists for chord testing.")
	if number_index < 0:
		return
	board.reveal_cell(number_index)
	var mine_neighbors: Array[int] = []
	var safe_neighbors: Array[int] = []
	for neighbor in board._get_neighbors(number_index):
		if board.mines[neighbor]:
			mine_neighbors.append(neighbor)
		else:
			safe_neighbors.append(neighbor)

	var before_count := board.revealed_safe_count
	board.chord_cell(number_index)
	_expect(board.revealed_safe_count == before_count, "Double-click does nothing while core marks are missing.")

	for core_index in mine_neighbors:
		board.toggle_flag(core_index)
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	board.cell_nodes[number_index]._gui_input(double_click)
	_expect(board.revealed_safe_count > before_count, "Double-click opens safe neighbors after every adjacent core is marked.")
	for safe_index in safe_neighbors:
		_expect(board.revealed[safe_index], "Every adjacent safe cell is opened by a valid double-click.")

	board._random.seed = 8101
	board.new_game()
	number_index = _find_chord_candidate(board)
	_expect(number_index >= 0, "A second chord candidate exists for wrong-mark testing.")
	if number_index < 0:
		return
	board.reveal_cell(number_index)
	mine_neighbors.clear()
	safe_neighbors.clear()
	for neighbor in board._get_neighbors(number_index):
		if board.mines[neighbor]:
			mine_neighbors.append(neighbor)
		else:
			safe_neighbors.append(neighbor)
	for index in range(1, mine_neighbors.size()):
		board.toggle_flag(mine_neighbors[index])
	board.toggle_flag(safe_neighbors[0])
	before_count = board.revealed_safe_count
	board.chord_cell(number_index)
	_expect(board.revealed_safe_count == before_count, "A wrong mark prevents double-click expansion even when the count matches.")
	_expect(board.game_state == MinesweeperBoard.GameState.PLAYING, "Wrong chord marks do not trigger a loss.")
	board._random.randomize()


func _test_keyboard_controls(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 1)
	board._random.seed = 8300
	board.new_game()
	board.set_operation_mode(MinesweeperBoard.OperationMode.MOUSE)
	_expect(board.get_keyboard_cell_index() == -1, "Mouse mode hides the keyboard cursor.")
	board.set_operation_mode(MinesweeperBoard.OperationMode.KEYBOARD)
	_expect(board.get_keyboard_cell_index() == 0, "An unguided keyboard board starts at cell zero.")
	_expect(board.cell_nodes[0]._is_keyboard_selected, "The selected square cell shows its keyboard outline.")

	board._input(_key_event(KEY_RIGHT))
	_expect(board.get_keyboard_cell_index() == 1, "Right arrow moves the keyboard cursor one column.")
	board._input(_key_event(0, KEY_A))
	_expect(board.get_keyboard_cell_index() == 0, "Physical A moves the keyboard cursor left.")
	board._input(_key_event(KEY_UP))
	_expect(board.get_keyboard_cell_index() == 0, "Keyboard movement stops at the top edge.")

	board._input(_key_event(0, KEY_X))
	_expect(board.flagged[0], "X marks the selected hidden cell.")
	board._input(_key_event(0, KEY_X))
	_expect(not board.flagged[0], "X removes a mark from the selected cell.")

	var safe_index := board.mines.find(false)
	board._set_keyboard_cursor(safe_index)
	board._input(_key_event(0, KEY_Z))
	_expect(board.revealed[safe_index], "Z reveals the selected hidden cell.")

	board._random.seed = 8301
	board.new_game()
	var number_index := _find_chord_candidate(board)
	_expect(number_index >= 0, "A keyboard chord candidate exists.")
	if number_index >= 0:
		board.reveal_cell(number_index)
		for neighbor in board._get_neighbors(number_index):
			if board.mines[neighbor]:
				board.toggle_flag(neighbor)
		var before_count := board.revealed_safe_count
		board._set_keyboard_cursor(number_index)
		board._input(_key_event(0, KEY_Z))
		_expect(board.revealed_safe_count > before_count, "Z chords an opened number after every adjacent core is marked.")

	board.new_game()
	var selected_before := board.get_keyboard_cell_index()
	board.set_interaction_enabled(false)
	board._input(_key_event(KEY_RIGHT))
	_expect(board.get_keyboard_cell_index() == selected_before, "A paused board ignores keyboard movement.")
	board.set_interaction_enabled(true)

	var mouse_target := mini(5, board.cell_count - 1)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	board.cell_nodes[mouse_target]._gui_input(right_click)
	_expect(board.get_keyboard_cell_index() == mouse_target, "Mouse actions synchronize the keyboard cursor.")
	_expect(board.flagged[mouse_target], "Mouse marking remains available in keyboard mode.")

	board.set_operation_mode(MinesweeperBoard.OperationMode.MOUSE)
	_expect(board.get_keyboard_cell_index() == -1, "Returning to mouse mode clears the keyboard cursor.")
	_expect(not board.cell_nodes[mouse_target]._is_keyboard_selected, "Mouse mode removes the square selection outline.")
	board._random.randomize()


func _test_level_one_visuals(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 0)
	var eco_showcase = main_scene.get_node("%EcoShowcase")
	var level_background = main_scene.get_node("%LevelOneBackground")
	var board_tray = main_scene.get_node("%BoardTray")
	_expect(level_background.visible and not board_tray.visible and not eco_showcase.visible, "Level 1 uses the unified handmade stage.")
	board._random.seed = 8400
	board.new_game()
	var marked_index := 0
	var marked_cell := board.cell_nodes[marked_index]
	_expect(marked_cell.uses_level_one_art(), "Level 1 cells enable the biosensor theme.")

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	marked_cell._gui_input(right_click)
	_expect(board.flagged[marked_index], "Right-click still marks a Level 1 cell.")
	_expect(marked_cell.procedural_visual == MineCell.ProceduralVisual.BIOSENSOR and marked_cell.text.is_empty(), "Level 1 marking uses a seed instead of an exclamation mark.")
	marked_cell.advance_biosensor_animation(1.0)
	_expect(is_equal_approx(marked_cell.biosensor_progress, 1.0), "The detection seed can complete its sprouting animation.")
	board.toggle_flag(marked_index)
	marked_cell.advance_biosensor_animation(1.0)
	_expect(marked_cell.procedural_visual == MineCell.ProceduralVisual.NONE and is_zero_approx(marked_cell.biosensor_progress), "Removing a mark reverses and clears the sprout.")

	board.set_operation_mode(MinesweeperBoard.OperationMode.KEYBOARD)
	var keyboard_index := 1
	board._set_keyboard_cursor(keyboard_index)
	board._input(_key_event(0, KEY_X))
	_expect(board.flagged[keyboard_index] and board.cell_nodes[keyboard_index].procedural_visual == MineCell.ProceduralVisual.BIOSENSOR, "Keyboard X starts the same seed animation.")
	board.cell_nodes[keyboard_index].advance_biosensor_animation(1.0)
	board.new_game()
	_expect(board.cell_nodes[keyboard_index].procedural_visual == MineCell.ProceduralVisual.NONE and is_zero_approx(board.cell_nodes[keyboard_index].biosensor_progress), "Restart clears all seed animation state immediately.")

	var safe_index := board.mines.find(false)
	board.toggle_flag(safe_index)
	board.cell_nodes[safe_index].advance_biosensor_animation(1.0)
	var flagged_core := board.mines.find(true)
	board.toggle_flag(flagged_core)
	board.cell_nodes[flagged_core].advance_biosensor_animation(1.0)
	var core_index := -1
	for candidate in board.cell_count:
		if board.mines[candidate] and candidate != flagged_core:
			core_index = candidate
			break
	board.reveal_cell(core_index)
	_expect(board.cell_nodes[core_index].procedural_visual == MineCell.ProceduralVisual.SLUDGE_CORE and board.cell_nodes[core_index].text.is_empty(), "A hit Level 1 core becomes an animated sludge creature instead of a dot.")
	_expect(eco_showcase.get_reaction() == 2, "The full-bleed ecology background becomes sad after a loss.")
	_expect(
		board.cell_nodes[safe_index].procedural_visual == MineCell.ProceduralVisual.UPROOTED_SPROUT,
		"A wrong mark becomes the uprooted-sprout failure state."
	)
	_expect(
		board.cell_nodes[flagged_core].procedural_visual == MineCell.ProceduralVisual.WILTED_SPROUT,
		"A correctly marked core becomes the wilted-sprout failure state."
	)
	board.advance_pollution_animation(4.0)
	board.cell_nodes[safe_index].advance_biosensor_animation(1.0)
	board.cell_nodes[flagged_core].advance_biosensor_animation(1.0)
	_expect(is_equal_approx(board.pollution_tint_progress, 1.0) and board.modulate == Color.WHITE, "A Level 1 loss changes individual cells instead of applying one board overlay.")
	for polluted_cell in board.cell_nodes:
		_expect(is_equal_approx(polluted_cell.pollution_progress, 1.0), "Pollution eventually reaches every Level 1 cell.")
	_expect(
		board.cell_nodes[safe_index].procedural_visual == MineCell.ProceduralVisual.UPROOTED_SPROUT
		and board.cell_nodes[flagged_core].procedural_visual == MineCell.ProceduralVisual.WILTED_SPROUT,
		"Visible failure sprouts retain their final static states."
	)

	board.new_game()
	_expect(eco_showcase.get_reaction() == 0, "Restart returns the compact ecology illustration to neutral.")
	_expect(board.modulate == Color.WHITE and is_zero_approx(board.pollution_tint_progress), "Restart immediately restores the clean board colors.")
	_expect(not board.cell_nodes[safe_index].is_sprout_wilting() and is_zero_approx(board.cell_nodes[safe_index].sprout_wilt_progress), "Restart clears every wilt state.")
	for cell_index in board.cell_count:
		if board.game_state == MinesweeperBoard.GameState.WON:
			break
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Level 1 can still be completed with procedural markers.")
	_expect(eco_showcase.get_reaction() == 1, "The full-bleed ecology background becomes happy after a win.")
	for mine_index in board.cell_count:
		if board.mines[mine_index]:
			_expect(board.cell_nodes[mine_index].procedural_visual == MineCell.ProceduralVisual.BIOSENSOR and is_equal_approx(board.cell_nodes[mine_index].biosensor_progress, 1.0), "Every solved Level 1 core becomes a completed sprout.")

	for level_index in range(1, 5):
		main_scene.call("_load_level", level_index)
		var marker_cell := board.cell_nodes[0]
		_expect(marker_cell.uses_level_one_art(), "Levels 2–5 reuse the Level-1 cell artwork.")
		_expect(level_background.visible and not board_tray.visible and not eco_showcase.visible, "Levels 2–5 reuse the unified handmade stage.")
		board.toggle_flag(0)
		_expect(marker_cell.text.is_empty() and marker_cell.procedural_visual == MineCell.ProceduralVisual.BIOSENSOR, "Every square level uses the shared sprout marker instead of an exclamation mark.")
		board.new_game()
		core_index = board.mines.find(true)
		board.reveal_cell(core_index)
		_expect(board.cell_nodes[core_index].text.is_empty() and board.cell_nodes[core_index].procedural_visual == MineCell.ProceduralVisual.SLUDGE_CORE, "Every square level uses the shared slime instead of a pollution dot.")
		board.advance_pollution_animation(10.0)
		_expect(is_equal_approx(board.pollution_tint_progress, 1.0), "Every square level uses the shared pollution spread.")
	board.set_operation_mode(MinesweeperBoard.OperationMode.MOUSE)
	board._random.randomize()


func _key_event(keycode: int, physical_keycode: int = 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = physical_keycode
	event.pressed = true
	return event


func _find_chord_candidate(board: MinesweeperBoard) -> int:
	for cell_index in board.cell_count:
		if board.mines[cell_index] or board.adjacent_counts[cell_index] <= 0:
			continue
		var has_core_neighbor := false
		var has_safe_neighbor := false
		for neighbor in board._get_neighbors(cell_index):
			if board.mines[neighbor]:
				has_core_neighbor = true
			else:
				has_safe_neighbor = true
		if has_core_neighbor and has_safe_neighbor:
			return cell_index
	return -1


func _validate_numbers(board: MinesweeperBoard) -> void:
	for cell_index in board.cell_count:
		var expected_count := 0
		for neighbor in board._get_neighbors(cell_index):
			if board.mines[neighbor]:
				expected_count += 1
		_expect(board.adjacent_counts[cell_index] == expected_count, "Cell %d has the correct number." % cell_index)


func _expected_opening(board: MinesweeperBoard, start_index: int) -> Array[bool]:
	var expected: Array[bool] = []
	expected.resize(board.cell_count)
	expected.fill(false)
	if board.adjacent_counts[start_index] > 0:
		expected[start_index] = true
		return expected

	var queued: Array[bool] = expected.duplicate()
	var queue: Array[int] = [start_index]
	queued[start_index] = true
	while not queue.is_empty():
		var current: int = queue.pop_front()
		expected[current] = true
		if board.adjacent_counts[current] > 0:
			continue
		for neighbor in board._get_neighbors(current):
			if not board.mines[neighbor] and not queued[neighbor]:
				queued[neighbor] = true
				queue.push_back(neighbor)
	return expected


func _any_arrow_visible(board: MinesweeperBoard) -> bool:
	for cell in board.cell_nodes:
		if cell.text == "↓":
			return true
	return false


func _core_layout_key(board: MinesweeperBoard) -> String:
	var key := ""
	for has_core in board.mines:
		key += "1" if has_core else "0"
	return key


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
