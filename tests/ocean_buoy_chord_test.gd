extends SceneTree

const BOARD_SCRIPT := preload("res://scripts/board.gd")
var failures := 0
var scenarios := 0

func _init() -> void:
	call_deferred("_run_tests")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _index(board: MinesweeperBoard, x: int, y: int) -> int:
	return y * board.column_count + x

func _board(groups: int = 1, adjacent_base_mine: bool = false) -> MinesweeperBoard:
	var board := BOARD_SCRIPT.new() as MinesweeperBoard
	board.size = Vector2(640, 500)
	var surface := Control.new()
	surface.name = "CellSurfaceHost"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(board)
	board._random.seed = 6144
	var shape: Array = []
	var group_ids: Array = []
	var mobile_mines: Array = []
	for group_id in range(groups):
		for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			shape.append(offset + Vector2i(0, group_id * 3))
			group_ids.append(group_id)
			mobile_mines.append(offset.x == 0)
	board.load_level({
		"number": 11, "name": "TXT_0083", "size": Vector2i(8, 7),
		"core_count": groups * 2 + 1, "topology": &"hex_pointy_odd_r",
		"first_move_guide": false,
		"mobile_current": {
			"shape": shape, "group_ids": group_ids,
			"start_position": Vector2i(2, 1), "end_column": 7,
			"core_count": groups * 2, "step_seconds": 7.0,
		},
	})
	# A valid mid-round state: the two left buoys in each group are marked
	# mines, while both safe buoys are still hidden. Base-route cells are safe.
	board.mines.fill(false)
	board.mines[_index(board, 0, 1) if adjacent_base_mine else _index(board, 7, 6)] = true
	board.revealed.fill(false)
	board.flagged.fill(false)
	board.confirmed.fill(false)
	board.mobile_current_group_positions.fill(Vector2i(2, 1))
	board.mobile_current_group_start_positions.fill(Vector2i(2, 1))
	board.mobile_current_position = Vector2i(2, 1)
	board.mobile_current_mines.assign(mobile_mines)
	board.mobile_current_flagged.assign(mobile_mines)
	board.mobile_current_revealed.fill(false)
	board.mobile_current_confirmed.fill(false)
	board.game_state = MinesweeperBoard.GameState.PLAYING
	board.reveal_action_count = 1
	board.revealed[_index(board, 1, 1)] = true
	board.revealed_safe_count = 1
	board._rebuild_mobile_current_masks()
	board._calculate_adjacent_counts()
	board._calculate_mobile_current_adjacent_counts()
	board._recalculate_used_flags()
	board._refresh_all_cells()
	board.set_interaction_enabled(true)
	board.set_process(false)
	return board

func _double_click(cell: MineCell) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = true
	cell._gui_input(event)

func _drift(board: MinesweeperBoard) -> void:
	board._begin_mobile_current_shift()
	var tween := board._mobile_current_shift_tween
	_expect(tween != null, "An unresolved buoy group starts its real drift tween.")
	if tween != null:
		await tween.finished
	await process_frame

func _test_zero_after_drift(keyboard: bool) -> void:
	var board := _board()
	var target := _index(board, 1, 1)
	var uncovered := _index(board, 2, 1)
	_expect(board.adjacent_counts[target] == 2, "The opened clue initially counts two buoy mines.")
	board._begin_mobile_current_shift()
	_double_click(board.cell_nodes[target])
	_expect(not board.revealed[uncovered], "Expansion remains locked during the drift animation.")
	await board._mobile_current_shift_tween.finished
	await process_frame
	_expect(board.adjacent_counts[target] == 0, "Moving the two mines away turns the opened clue into zero.")
	_expect(not board.revealed[uncovered], "Drift does not automatically reveal the vacated safe cell.")
	if keyboard:
		board.set_operation_mode(MinesweeperBoard.OperationMode.KEYBOARD)
		board.keyboard_cell_index = target
		var event := InputEventKey.new()
		event.keycode = KEY_J
		event.pressed = true
		board._input(event)
	else:
		_double_click(board.cell_nodes[target])
	_expect(board.revealed[uncovered], "The opened zero expands the newly uncovered neighbor after drift.")
	_expect(not board.revealed[_index(board, 7, 6)], "Zero expansion never reveals the remaining base mine.")
	scenarios += 1
	board.free()
	await process_frame

func _test_wrong_flag_on_zero() -> void:
	var board := _board()
	await _drift(board)
	var wrong_flag := _index(board, 0, 1)
	board.toggle_flag(wrong_flag)
	_double_click(board.cell_nodes[_index(board, 1, 1)])
	_expect(not board.revealed[_index(board, 2, 1)], "A zero with an incorrect neighboring flag does not expand.")
	_expect(board.flagged[wrong_flag] and board.game_state == MinesweeperBoard.GameState.PLAYING, "A blocked expansion preserves the flag and does not cause failure.")
	scenarios += 1
	board.free()
	await process_frame

func _test_positive_clue_after_drift() -> void:
	var board := _board(1, true)
	await _drift(board)
	var target := _index(board, 1, 1)
	var uncovered := _index(board, 2, 1)
	_expect(board.adjacent_counts[target] == 1, "A remaining base mine keeps this post-drift clue positive.")
	_double_click(board.cell_nodes[target])
	_expect(not board.revealed[uncovered], "A missing mine flag still blocks positive-clue expansion.")
	var wrong_flag := _index(board, 1, 0)
	board.toggle_flag(wrong_flag)
	_double_click(board.cell_nodes[target])
	_expect(not board.revealed[uncovered], "Matching the count with a wrong flag still blocks expansion.")
	board.toggle_flag(wrong_flag)
	board.toggle_flag(_index(board, 0, 1))
	_double_click(board.cell_nodes[target])
	_expect(board.revealed[uncovered], "Correct flags restore normal positive-clue expansion after drift.")
	_expect(not board.revealed[_index(board, 0, 1)], "The correctly marked mine remains closed.")
	scenarios += 1
	board.free()
	await process_frame

func _test_moving_buoy_clue() -> void:
	var board := _board()
	board._reveal_mobile_current_cell(1)
	await _drift(board)
	_double_click(board._mobile_current_cells[1])
	_expect(board.mobile_current_revealed[3], "A revealed buoy still expands its safe neighboring buoy after moving.")
	_expect(board.mobile_current_flagged[0] and board.mobile_current_flagged[2], "Moving-buoy expansion preserves both mine flags.")
	_expect(board.mobile_current_group_resolved[0], "Opening the last safe buoy stops the correctly marked group.")
	scenarios += 1
	board.free()
	await process_frame

func _test_stopped_group_flags(groups: int) -> void:
	var board := _board(groups)
	await _drift(board)
	board._reveal_mobile_current_cell(1)
	board._reveal_mobile_current_cell(3)
	_expect(board.mobile_current_group_resolved[0], "The first buoy group stops after its safe cells and mines are handled.")
	_expect(board.mobile_current_resolved == (groups == 1), "Other unresolved groups keep the overall buoy mechanism active.")
	var target := _index(board, 2, 1)
	var safe_neighbor := _index(board, 2, 0)
	board.reveal_cell(target)
	_expect(board.adjacent_counts[target] == 2, "The clue still counts both mines in the stopped group.")
	_expect(not board.revealed[safe_neighbor], "The neighboring safe cell remains available for a deliberate expansion.")
	_double_click(board.cell_nodes[target])
	_expect(board.revealed[safe_neighbor], "Mine flags on a stopped group satisfy the neighboring clue.")
	_expect(board.mobile_current_flagged[0] and board.mobile_current_flagged[2], "Expansion preserves stopped-buoy mine markers.")
	scenarios += 1
	board.free()
	await process_frame

func _run_tests() -> void:
	await _test_zero_after_drift(false)
	await _test_zero_after_drift(true)
	await _test_wrong_flag_on_zero()
	await _test_positive_clue_after_drift()
	await _test_moving_buoy_clue()
	await _test_stopped_group_flags(1)
	await _test_stopped_group_flags(2)
	print("OCEAN_BUOY_CHORD scenarios=%d failures=%d" % [scenarios, failures])
	quit(0 if failures == 0 else 1)
