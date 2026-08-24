extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene.call("_load_level", 5)
	await process_frame
	var board := main_scene.get_node("%Board") as MinesweeperBoard
	var triangle_view = board.get_triangle_view()

	_test_level_setup(main_scene, board, triangle_view)
	_test_topology(board)
	_test_geometry(triangle_view)
	_test_input_hit(board, triangle_view)
	_test_keyboard_input(board, triangle_view)
	_test_triangle_opening(board)
	_test_triangle_chord(board)
	_test_end_states(main_scene, board)
	_test_level_transition(main_scene, board)

	main_scene.queue_free()
	if failures == 0:
		print("Green Sweeper triangle board tests passed.")
		quit(0)
	else:
		push_error("%d triangle board test(s) failed." % failures)
		quit(1)


func _test_level_setup(main_scene: Node, board: MinesweeperBoard, triangle_view) -> void:
	_expect(board.level_number == 6 and board.level_name == "山脉", "Level 6 is Mountains.")
	_expect(board.topology == "triangle", "Level 6 uses triangle topology.")
	_expect(board.row_count == 9 and board.column_count == 24, "Level 6 uses a 9x24 board.")
	_expect(board.cell_count == 216 and board.safe_cell_count == 136, "Level 6 contains 216 triangle cells.")
	_expect(board.core_count == 80 and board.mines.count(true) == 80, "Level 6 contains 80 pollution cores.")
	_expect(board.cell_nodes.is_empty(), "Triangle topology does not create rectangular buttons.")
	_expect(triangle_view != null and triangle_view.cell_count == 216, "The unified triangle view contains every cell.")
	_expect(board.revealed.count(true) == 0 and board.guide_cell_index == -1, "Level 6 starts closed and unguided.")
	_expect(TriangleBoardView.SPROUT_TEXTURE.resource_path == "res://assets/gameplay/markers/sprout_marker.png", "Triangle marks use the shared sprout texture.")
	_expect(TriangleBoardView.SLIME_TEXTURE.resource_path == "res://assets/gameplay/markers/pollution_slime.png", "Triangle cores use the shared slime texture.")
	var subtitle := main_scene.get_node("%SubtitleLabel") as Label
	_expect(subtitle.text.contains("第6关 · 山脉"), "The header identifies the mountain level.")
	var summary := main_scene.get_node("%LevelSummaryLabel") as Label
	_expect(summary.text.contains("24列 × 9排") and summary.text.contains("80"), "The environment panel shows the triangle board dimensions and core count.")


func _test_topology(board: MinesweeperBoard) -> void:
	var upward_count := 0
	var degree_sum := 0
	var six_neighbor_cells := 0
	for cell_index in board.cell_count:
		var row := int(cell_index / board.column_count)
		var column := cell_index % board.column_count
		if (row + column) % 2 == 0:
			upward_count += 1
		var neighbors := board._get_neighbors(cell_index)
		degree_sum += neighbors.size()
		if neighbors.size() == 6:
			six_neighbor_cells += 1
		_expect(neighbors.size() <= 6, "Triangle cell %d has at most six nearby neighbors." % cell_index)
		var unique_neighbors: Dictionary = {}
		for neighbor in neighbors:
			_expect(neighbor >= 0 and neighbor < board.cell_count, "Triangle neighbors stay inside the board.")
			_expect(neighbor != cell_index, "A triangle is not its own neighbor.")
			unique_neighbors[neighbor] = true
			_expect(board._get_neighbors(neighbor).has(cell_index), "Triangle adjacency is bidirectional.")
		_expect(unique_neighbors.size() == neighbors.size(), "Triangle neighbors contain no duplicates.")
	_expect(upward_count == 108, "The board contains 108 upward and 108 downward triangles.")
	_expect(six_neighbor_cells == 140, "Every non-edge triangle has six nearby neighbors.")
	_expect(degree_sum / 2 == 597, "The complete triangle grid has the expected six-neighbor links.")
	_expect(board._get_neighbors(108) == [106, 107, 109, 110, 84, 132], "An interior triangle counts four horizontal and two vertical neighbors.")
	_expect(board._get_neighbors(0) == [1, 2, 24], "A corner triangle naturally has fewer than six neighbors.")
	for adjacent_count in board.adjacent_counts:
		_expect(adjacent_count >= 0 and adjacent_count <= 6, "Triangle numbers stay in the 0-6 range.")


func _test_geometry(triangle_view) -> void:
	var upward_count := 0
	for cell_index in triangle_view.cell_count:
		var points: PackedVector2Array = triangle_view.get_triangle_points(cell_index)
		_expect(points.size() == 3, "Every visible cell is a real triangle.")
		var center: Vector2 = triangle_view.get_triangle_center(cell_index)
		_expect(triangle_view.get_cell_at_point(center) == cell_index, "A triangle center hits its own cell.")
		if triangle_view.is_upward(cell_index):
			upward_count += 1
	_expect(upward_count == 108, "The view alternates 108 upward triangles with 108 downward triangles.")
	_expect(triangle_view.get_cell_at_point(Vector2.ZERO) == -1, "Clicks outside the triangle grid hit no cell.")
	var first_points: PackedVector2Array = triangle_view.get_triangle_points(0)
	var outside_first := Vector2(first_points[1].x + 0.5, first_points[0].y + 0.5)
	_expect(triangle_view.get_cell_at_point(outside_first) == -1, "The empty corner of a triangle bounding box is not clickable.")


func _test_input_hit(board: MinesweeperBoard, triangle_view) -> void:
	board._random.seed = 9059
	board.new_game()
	var safe_index := board.mines.find(false)
	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.pressed = true
	left_click.position = triangle_view.get_triangle_center(safe_index)
	triangle_view._gui_input(left_click)
	_expect(board.revealed[safe_index], "Clicking a triangle center reveals that triangle.")

	var core_index := board.mines.find(true)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	right_click.position = triangle_view.get_triangle_center(core_index)
	triangle_view._gui_input(right_click)
	_expect(board.flagged[core_index], "Right-clicking a triangle center marks that triangle.")
	_expect(triangle_view.flagged_states[core_index], "The marked triangle renders the shared sprout state.")

	var revealed_before := board.revealed_safe_count
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	outside_click.position = Vector2.ZERO
	triangle_view._gui_input(outside_click)
	_expect(board.revealed_safe_count == revealed_before, "Clicking outside all triangles changes no cell.")
	board._random.randomize()


func _test_keyboard_input(board: MinesweeperBoard, triangle_view) -> void:
	board._random.seed = 9063
	board.new_game()
	board.set_operation_mode(MinesweeperBoard.OperationMode.KEYBOARD)
	_expect(board.get_keyboard_cell_index() == 0, "The triangle keyboard cursor starts at cell zero.")
	_expect(triangle_view.get_keyboard_cursor() == 0, "The triangle view displays the board cursor.")
	board._input(_key_event(KEY_RIGHT))
	_expect(board.get_keyboard_cell_index() == 1 and triangle_view.get_keyboard_cursor() == 1, "Arrow movement keeps the triangle cursor synchronized.")
	board._input(_key_event(0, KEY_X))
	_expect(board.flagged[1], "X marks the selected triangle.")
	board._input(_key_event(0, KEY_X))
	_expect(not board.flagged[1], "X removes a triangle mark.")
	var safe_index := board.mines.find(false)
	board._set_keyboard_cursor(safe_index)
	board._input(_key_event(0, KEY_Z))
	_expect(board.revealed[safe_index], "Z reveals the selected triangle.")
	board.set_operation_mode(MinesweeperBoard.OperationMode.MOUSE)
	_expect(triangle_view.get_keyboard_cursor() == -1, "Mouse mode hides the triangle keyboard outline.")
	board._random.randomize()


func _key_event(keycode: int, physical_keycode: int = 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = physical_keycode
	event.pressed = true
	return event


func _test_triangle_opening(board: MinesweeperBoard) -> void:
	board._random.seed = 9060
	board.new_game()
	var zero_index := -1
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and board.adjacent_counts[cell_index] == 0:
			zero_index = cell_index
			break
	_expect(zero_index >= 0, "A seeded triangle layout provides a zero cell for expansion testing.")
	if zero_index >= 0:
		var expected := _expected_opening(board, zero_index)
		board.reveal_cell(zero_index)
		_expect(board.revealed == expected, "Zero expansion follows the six-neighbor triangle topology.")
	board._random.randomize()


func _test_triangle_chord(board: MinesweeperBoard) -> void:
	board._random.seed = 9061
	board.new_game()
	var number_index := _find_chord_candidate(board)
	_expect(number_index >= 0, "A triangle number has both core and safe neighbors for chord testing.")
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
	_expect(board.revealed_safe_count == before_count, "Triangle chord waits for all correct marks.")
	for core_index in mine_neighbors:
		board.toggle_flag(core_index)
	board.chord_cell(number_index)
	_expect(board.revealed_safe_count > before_count, "Correct triangle marks allow chord expansion.")
	for safe_index in safe_neighbors:
		_expect(board.revealed[safe_index], "Triangle chord opens every adjacent safe cell.")

	board._random.seed = 9061
	board.new_game()
	number_index = _find_chord_candidate(board)
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
	_expect(board.revealed_safe_count == before_count, "A wrong triangle mark blocks chord expansion even when the count matches.")
	_expect(board.game_state == MinesweeperBoard.GameState.PLAYING, "A blocked triangle chord does not cause a loss.")
	board._random.randomize()


func _test_end_states(main_scene: Node, board: MinesweeperBoard) -> void:
	board._random.seed = 9062
	board.new_game()
	var core_index := board.mines.find(true)
	board.reveal_cell(core_index)
	_expect(board.game_state == MinesweeperBoard.GameState.LOST, "A triangle core causes a loss.")
	_expect(board.get_triangle_view().core_visible_states[core_index], "A revealed triangle core renders the shared slime state.")
	board.new_game()
	_expect(board.game_state == MinesweeperBoard.GameState.READY and board.revealed.count(true) == 0, "Restart closes the complete triangle board.")
	for cell_index in board.cell_count:
		if board.game_state == MinesweeperBoard.GameState.WON:
			break
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Opening all triangle safe cells wins level 6.")
	var primary_button := main_scene.get_node("%RestartButton") as Button
	_expect(primary_button.text == "再来一局", "Level 6 remains the current final level.")
	board._random.randomize()


func _test_level_transition(main_scene: Node, board: MinesweeperBoard) -> void:
	main_scene.call("_load_level", 4)
	for cell_index in board.cell_count:
		if board.game_state == MinesweeperBoard.GameState.WON:
			break
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			board.reveal_cell(cell_index)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "Level 5 can be completed before the mountain level.")
	main_scene.call("_on_primary_button_pressed")
	_expect(board.level_number == 6 and board.topology == "triangle", "The fifth-level next button loads the triangle mountain level.")
	_expect(board.get_triangle_view() != null and board.cell_nodes.is_empty(), "Transitioning replaces square buttons with the triangle view.")
	main_scene.call("_load_level", 0)
	_expect(board.topology == "square" and board.cell_nodes.size() == 25, "Returning to level 1 restores the square button grid.")
	_expect(board.get_triangle_view() == null, "Returning to a square level removes the triangle input view.")


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


func _expected_opening(board: MinesweeperBoard, start_index: int) -> Array[bool]:
	var expected: Array[bool] = []
	expected.resize(board.cell_count)
	expected.fill(false)
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
