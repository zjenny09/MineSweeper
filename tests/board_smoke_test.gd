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
	_test_guide_behavior(board)
	_test_rebellious_first_click(board)
	_test_random_layouts(board)
	_test_flags_win_and_restart(board)
	_test_player_facing_terms(main_scene, board)
	_test_level_transition(main_scene, board)
	_test_level_2(main_scene, board)
	_test_land_level_data(main_scene, board)
	_test_chord_behavior(main_scene, board)
	_test_keyboard_controls(main_scene, board)

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


func _test_guide_behavior(board: MinesweeperBoard) -> void:
	for trial in 40:
		board._random.seed = 1000 + trial
		board.new_game()
		var guide_index := board.guide_cell_index
		_expect(guide_index >= 0, "Level 1 provides a suggested first cell.")
		_expect(not board.mines[guide_index], "The suggested cell is truly safe.")
		_expect(board.cell_nodes[guide_index].text == "↓", "The suggested cell displays a green arrow.")

		var has_zero := false
		for cell_index in board.cell_count:
			if not board.mines[cell_index] and board.adjacent_counts[cell_index] == 0:
				has_zero = true
				break
		if has_zero:
			_expect(board.adjacent_counts[guide_index] == 0, "The guide prefers a zero cell when one exists.")

		var expected := _expected_opening(board, guide_index)
		board.reveal_cell(guide_index)
		_expect(board.guide_cell_index == -1, "The guide disappears after the first click.")
		_expect(board.revealed == expected, "Following the guide uses the classic number-or-zero opening rule.")
		_expect(not _any_arrow_visible(board), "No guide arrow remains after play begins.")
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
	board.new_game()
	var flags_label := main_scene.get_node("%FlagsLabel") as Label
	var status_label := main_scene.get_node("%StatusLabel") as Label
	_expect(flags_label.text == "标记：0/5", "The counter uses marking terminology.")
	_expect(status_label.text.contains("绿色箭头"), "The initial status explains the optional guide.")
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
	var primary_button := main_scene.get_node("%RestartButton") as Button
	_expect(primary_button.text == "进入下一关", "Finishing level 1 offers the next level.")
	main_scene.call("_on_primary_button_pressed")
	_expect(board.level_number == 2 and board.level_name == "灌木", "The next-level button loads Shrubland.")


func _test_level_2(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 1)
	_expect(board.row_count == 6 and board.column_count == 6, "Level 2 uses a 6x6 board.")
	_expect(board.cell_nodes.size() == 36, "Level 2 creates 36 cells.")
	_expect(board.core_count == 8 and board.safe_cell_count == 28, "Level 2 uses eight pollution cores.")
	_expect(not board.first_move_guide_enabled and board.guide_cell_index == -1, "Level 2 removes first-move guidance.")
	_expect(not _any_arrow_visible(board), "Level 2 shows no safe arrow.")
	_expect(board.mines.count(true) == 8 and board.revealed.count(true) == 0, "Level 2 starts as a complete closed random board.")
	var status_label := main_scene.get_node("%StatusLabel") as Label
	var instructions_label := main_scene.get_node("%InstructionsLabel") as Label
	_expect(status_label.text == "选择第一块净化区域", "Level 2 asks the player to choose freely.")
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
		{"index": 2, "number": 3, "name": "湿地", "size": 8, "cores": 14},
		{"index": 3, "number": 4, "name": "草原", "size": 10, "cores": 23},
		{"index": 4, "number": 5, "name": "森林", "size": 12, "cores": 35},
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
