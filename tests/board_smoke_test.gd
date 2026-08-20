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

	_expect(board.cell_nodes.size() == MinesweeperBoard.CELL_COUNT, "The board creates 81 cells.")
	_test_first_click_safety(board)
	_test_every_safe_click_works(board)
	_test_flag_limit(board)
	_test_loss_and_reset(board)
	_test_win(board)

	main_scene.queue_free()
	if failures == 0:
		print("Minesweeper smoke tests passed.")
		quit(0)
	else:
		push_error("%d Minesweeper smoke test(s) failed." % failures)
		quit(1)


func _test_first_click_safety(board: MinesweeperBoard) -> void:
	for first_index in MinesweeperBoard.CELL_COUNT:
		board.new_game()
		board.reveal_cell(first_index)
		_expect(not board.mines[first_index], "First click %d is safe." % first_index)
		var revealed_count := board.revealed.count(true)
		if board.adjacent_counts[first_index] > 0:
			_expect(revealed_count == 1, "Clicking a numbered cell reveals only that cell.")
		else:
			_expect(_zero_expansion_matches_expected(board, first_index), "A zero cell expands through connected zeroes and their numbered boundary.")
		_expect(_all_revealed_cells_are_safe(board), "Automatically revealed cells are always safe.")
		_expect(_revealed_numbers_are_rendered(board), "Every revealed numbered cell displays its number.")
		_expect(_revealed_region_is_connected(board, first_index), "Automatically revealed cells form one connected region.")
		_expect(board.mines.count(true) == MinesweeperBoard.MINE_COUNT, "Board %d contains 10 mines." % first_index)
		_validate_adjacent_counts(board)


func _test_every_safe_click_works(board: MinesweeperBoard) -> void:
	for trial in 100:
		board.new_game()
		board.reveal_cell(trial % MinesweeperBoard.CELL_COUNT)
		if board.game_state == MinesweeperBoard.GameState.WON:
			continue
		var safe_hidden_index := -1
		for cell_index in MinesweeperBoard.CELL_COUNT:
			if not board.mines[cell_index] and not board.revealed[cell_index] and not board.flagged[cell_index]:
				safe_hidden_index = cell_index
				break
		if safe_hidden_index == -1:
			continue
		var before_count := board.revealed.count(true)
		board.reveal_cell(safe_hidden_index)
		_expect(board.revealed.count(true) > before_count, "Every valid hidden safe-cell click reveals at least one cell.")


func _test_flag_limit(board: MinesweeperBoard) -> void:
	board.new_game()
	for cell_index in MinesweeperBoard.MINE_COUNT:
		board.toggle_flag(cell_index)
	_expect(board.used_flags == MinesweeperBoard.MINE_COUNT, "The player can place 10 flags.")
	board.toggle_flag(MinesweeperBoard.MINE_COUNT)
	_expect(board.used_flags == MinesweeperBoard.MINE_COUNT, "An eleventh flag is rejected.")
	board.reveal_cell(0)
	_expect(board.mines.count(true) == 0, "Clicking a flagged cell does not start the game.")
	board.toggle_flag(0)
	board.toggle_flag(MinesweeperBoard.MINE_COUNT)
	_expect(board.used_flags == MinesweeperBoard.MINE_COUNT, "A removed flag can be placed elsewhere.")


func _test_loss_and_reset(board: MinesweeperBoard) -> void:
	board.new_game()
	board.reveal_cell(0)
	var mine_index := board.mines.find(true)
	board.reveal_cell(mine_index)
	_expect(board.game_state == MinesweeperBoard.GameState.LOST, "Revealing a mine loses the game.")
	board.new_game()
	_expect(board.game_state == MinesweeperBoard.GameState.READY, "Restart returns to the ready state.")
	_expect(board.mines.count(true) == 0, "Restart clears all mines until the next first click.")
	_expect(board.revealed.count(true) == 0, "Restart hides every cell.")
	_expect(board.flagged.count(true) == 0, "Restart removes every flag.")


func _test_win(board: MinesweeperBoard) -> void:
	board.new_game()
	board.reveal_cell(0)
	for cell_index in MinesweeperBoard.CELL_COUNT:
		if not board.mines[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Revealing every safe cell wins the game.")
	_expect(board.revealed_safe_count == MinesweeperBoard.SAFE_CELL_COUNT, "A win reveals all 71 safe cells.")


func _validate_adjacent_counts(board: MinesweeperBoard) -> void:
	for cell_index in MinesweeperBoard.CELL_COUNT:
		var expected_count := 0
		for neighbor in board._get_neighbors(cell_index):
			if board.mines[neighbor]:
				expected_count += 1
		_expect(board.adjacent_counts[cell_index] == expected_count, "Cell %d has the correct adjacent count." % cell_index)


func _all_revealed_cells_are_safe(board: MinesweeperBoard) -> bool:
	for cell_index in MinesweeperBoard.CELL_COUNT:
		if board.revealed[cell_index] and board.mines[cell_index]:
			return false
	return true


func _revealed_numbers_are_rendered(board: MinesweeperBoard) -> bool:
	for cell_index in MinesweeperBoard.CELL_COUNT:
		if not board.revealed[cell_index]:
			continue
		var expected_text := "" if board.adjacent_counts[cell_index] == 0 else str(board.adjacent_counts[cell_index])
		if board.cell_nodes[cell_index].text != expected_text:
			return false
	return true


func _zero_expansion_matches_expected(board: MinesweeperBoard, start_index: int) -> bool:
	var expected: Array[bool] = []
	expected.resize(MinesweeperBoard.CELL_COUNT)
	expected.fill(false)
	var queued: Array[bool] = []
	queued.resize(MinesweeperBoard.CELL_COUNT)
	queued.fill(false)
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

	for cell_index in MinesweeperBoard.CELL_COUNT:
		if expected[cell_index] != board.revealed[cell_index]:
			return false
	return true


func _revealed_region_is_connected(board: MinesweeperBoard, start_index: int) -> bool:
	if not board.revealed[start_index]:
		return false
	var visited: Array[bool] = []
	visited.resize(MinesweeperBoard.CELL_COUNT)
	visited.fill(false)
	var queue: Array[int] = [start_index]
	visited[start_index] = true
	var visited_revealed := 0
	while not queue.is_empty():
		var current: int = queue.pop_front()
		visited_revealed += 1
		for neighbor in board._get_neighbors(current):
			if board.revealed[neighbor] and not visited[neighbor]:
				visited[neighbor] = true
				queue.push_back(neighbor)
	return visited_revealed == board.revealed.count(true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
