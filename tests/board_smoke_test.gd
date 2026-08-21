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

	main_scene.queue_free()
	if failures == 0:
		print("Green Sweeper level 1 guided-board tests passed.")
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
