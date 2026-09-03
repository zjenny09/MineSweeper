extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene := packed_scene.instantiate()
	main_scene.auto_start = false
	root.add_child(main_scene)
	await process_frame
	main_scene.set_first_move_guide_enabled(false)
	var board := main_scene.get_node("%Board") as MinesweeperBoard

	_test_fixed_capacity_and_lock(main_scene, board)
	_test_action_charging(main_scene, board)
	_test_chord_charging(main_scene, board)
	_test_repeatable_scan(main_scene, board)
	_test_winning_reveal_charges(main_scene, board)
	_test_robot_and_keyboard_activation(main_scene, board)
	_test_ocean_robot(main_scene, board)

	main_scene.queue_free()
	if failures == 0:
		print("Scan ability tests passed.")
		quit(0)
	else:
		push_error("%d scan ability test(s) failed." % failures)
		quit(1)


func _test_fixed_capacity_and_lock(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(0, 12)
	_expect(main_scene.get_scan_threshold() == 12, "Every level uses the fixed 12-charge capacity.")
	_expect(main_scene.get_scan_energy() == 12, "A supplied first-level grant starts full.")
	_expect(
		main_scene.get_scan_phase() == main_scene.ScanPhase.LOCKED_FIRST_REVEAL,
		"Full energy remains locked until an ordinary reveal."
	)
	main_scene.call("_request_scan_mode")
	_expect(not board.scan_target_mode, "A scan cannot target before the first ordinary reveal.")
	var opening := _find_hidden_safe_number(board)
	_expect(opening >= 0, "The lock test finds a safe opening.")
	board.reveal_cell(opening)
	_expect(main_scene.get_scan_energy() == 12, "A full meter stays clamped after a valid reveal.")
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.READY, "The first reveal unlocks full energy.")
	main_scene.call("_request_scan_mode")
	var revealed_index := board.revealed.find(true)
	main_scene.call("_on_scan_target_requested", revealed_index)
	_expect(board.scan_target_mode, "An invalid revealed target keeps target mode active.")
	_expect(main_scene.get_scan_energy() == 12, "An invalid target consumes no energy.")
	main_scene.call("_cancel_scan_targeting")
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.READY, "Cancel returns to ready.")
	_expect(main_scene.get_scan_energy() == 12, "Cancel consumes no energy.")


func _test_action_charging(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(2, 0)
	var flag_target := _find_hidden_unflagged_mine(board)
	_expect(flag_target >= 0, "The flag-charge test finds a hidden cell.")
	board.toggle_flag(flag_target)
	_expect(main_scene.get_scan_energy() == 1, "A cell's first flag placement adds exactly one.")
	_expect(
		main_scene.get_scan_phase() == main_scene.ScanPhase.LOCKED_FIRST_REVEAL,
		"Flag energy can accumulate while scanning remains first-reveal locked."
	)
	board.toggle_flag(flag_target)
	_expect(main_scene.get_scan_energy() == 1, "Removing a flag adds no energy.")
	board.toggle_flag(flag_target)
	_expect(main_scene.get_scan_energy() == 1, "Reflagging the same cell adds no energy.")
	board.toggle_flag(flag_target)
	var opening := _find_hidden_safe_number(board)
	var revealed_before := board.revealed_safe_count
	board.reveal_cell(opening)
	_expect(board.revealed_safe_count > revealed_before, "The charging reveal opens safe cells.")
	_expect(main_scene.get_scan_energy() == 2, "A valid reveal adds one regardless of flood size.")
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.CHARGING, "The first reveal unlocks charging.")
	var energy_before_invalid: int = main_scene.get_scan_energy()
	board.reveal_cell(opening)
	_expect(main_scene.get_scan_energy() == energy_before_invalid, "Revealing an open cell adds no energy.")


func _test_chord_charging(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(2, 0)
	var opening := _find_hidden_safe_number(board)
	board.reveal_cell(opening)
	var chord_target := _prepare_chord(board)
	_expect(chord_target >= 0, "The chord-charge test finds a valid numbered cell.")
	if chord_target < 0:
		return
	var energy_before: int = main_scene.get_scan_energy()
	board.chord_cell(chord_target)
	_expect(main_scene.get_scan_energy() == mini(12, energy_before + 1), "A productive chord adds exactly one.")
	var energy_after: int = main_scene.get_scan_energy()
	board.chord_cell(chord_target)
	_expect(main_scene.get_scan_energy() == energy_after, "A repeated unproductive chord adds no energy.")


func _test_repeatable_scan(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(2, 12)
	var opening := _find_hidden_safe_number(board)
	board.reveal_cell(opening)
	var ordinary_flags: Array[int] = []
	for cell_index in board.cell_count:
		if ordinary_flags.size() >= board.core_count:
			break
		if board.revealed[cell_index] or board.mines[cell_index]:
			continue
		board.toggle_flag(cell_index)
		if board.flagged[cell_index]:
			ordinary_flags.append(cell_index)
	_expect(ordinary_flags.size() == board.core_count, "The repeat-scan fixture fills the ordinary flag cap.")
	var mine_index := _find_hidden_unflagged_mine(board)
	_expect(mine_index >= 0, "The first scan finds an unflagged mine.")
	var flag_events := [0]
	var flag_callback := func(_index: int, _flagged: bool, _first: bool) -> void:
		flag_events[0] += 1
	board.flag_completed.connect(flag_callback)
	main_scene.call("_request_scan_mode")
	main_scene.call("_on_scan_target_requested", mine_index)
	_expect(board.confirmed[mine_index], "Scanning a mine creates an authoritative marker.")
	_expect(board.used_flags == board.core_count + 1, "A scanned mine may exceed the ordinary flag cap.")
	_expect(flag_events[0] == 0, "A scan-created marker is not a manual flag action.")
	_expect(main_scene.get_scan_energy() == 0, "A valid scan atomically consumes all 12 energy.")
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.CHARGING, "A scan returns to charging.")
	_fill_scan_energy(main_scene)
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.READY, "The same board can recharge to ready.")
	var second_mine := _find_hidden_unflagged_mine(board)
	_expect(second_mine >= 0, "The repeat scan finds a second mine.")
	main_scene.call("_request_scan_mode")
	main_scene.call("_on_scan_target_requested", second_mine)
	_expect(board.confirmed[second_mine], "A second scan works in the same board.")
	_expect(main_scene.get_scan_energy() == 0, "The second valid scan consumes the refilled meter.")
	board.flag_completed.disconnect(flag_callback)


func _test_winning_reveal_charges(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(2, 0)
	var final_safe := -1
	for cell_index in board.cell_count:
		if board.mines[cell_index]:
			board.revealed[cell_index] = false
		else:
			board.revealed[cell_index] = true
			final_safe = cell_index
	if final_safe < 0:
		_expect(false, "The winning-reveal fixture finds a safe cell.")
		return
	board.revealed[final_safe] = false
	board.revealed_safe_count = board.safe_cell_count - 1
	board.game_state = MinesweeperBoard.GameState.PLAYING
	board.reveal_action_count = 1
	board.reveal_cell(final_safe)
	_expect(board.game_state == MinesweeperBoard.GameState.WON, "The fixture completes the board.")
	_expect(main_scene.get_scan_energy() == 1, "The final winning manual reveal still adds one.")
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.FINISHED, "Winning closes scan targeting after charging.")


func _test_robot_and_keyboard_activation(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(3, 12)
	board.reveal_cell(_find_hidden_safe_number(board))
	var hotspot := main_scene.get_node(
		"%LandTabletopActors/DesignPlane/RobotSlot/RobotHotspot"
	) as Button
	hotspot.pressed.emit()
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.TARGETING, "Robot click enters targeting.")
	main_scene.call("_cancel_scan_targeting")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_C
	key_event.physical_keycode = KEY_C
	main_scene.call("_unhandled_input", key_event)
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.TARGETING, "C enters the same targeting state.")
	main_scene.call("_cancel_scan_targeting")


func _test_ocean_robot(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(5, 12)
	var actors := main_scene.get_node("%LandTabletopActors") as LandTabletopActors
	var fallback_row := main_scene.get_node("%ScanFallbackRow") as Control
	_expect(main_scene.get_scan_threshold() == 12, "Ocean levels use the same fixed capacity.")
	_expect(actors.visible and actors.uses_ocean_ecology(), "Ocean levels show the shared robot/ecology actor layer.")
	_expect(not fallback_row.visible, "Ocean levels retire the fallback scan row.")
	board.reveal_cell(_find_hidden_safe_number(board))
	_expect(main_scene.get_scan_phase() == main_scene.ScanPhase.READY, "An ocean first reveal unlocks saved full energy.")
	var hotspot := main_scene.get_node(
		"%LandTabletopActors/DesignPlane/RobotSlot/RobotHotspot"
	) as Button
	_expect(not hotspot.disabled, "The ocean robot enables when scanning is ready.")
	hotspot.pressed.emit()
	_expect(board.scan_target_mode, "Clicking the ocean robot enters board target mode.")
	main_scene.call("_cancel_scan_targeting")


func _fill_scan_energy(main_scene: Control) -> void:
	for _step in range(12):
		main_scene.call("_award_scan_energy")


func _prepare_chord(board: MinesweeperBoard) -> int:
	for cell_index in board.cell_count:
		if not board.revealed[cell_index] or board.adjacent_counts[cell_index] <= 0:
			continue
		var neighbors := board.get_neighbor_indices(cell_index)
		var hidden_safe_count := 0
		var mine_neighbors: Array[int] = []
		for neighbor in neighbors:
			if board.mines[neighbor]:
				mine_neighbors.append(neighbor)
			elif not board.revealed[neighbor] and not board.flagged[neighbor]:
				hidden_safe_count += 1
		if hidden_safe_count == 0 or mine_neighbors.size() != board.adjacent_counts[cell_index]:
			continue
		if board.used_flags + mine_neighbors.size() > board.core_count:
			continue
		for mine_index in mine_neighbors:
			if not board.flagged[mine_index]:
				board.toggle_flag(mine_index)
		return cell_index
	return -1


func _find_hidden_safe_number(board: MinesweeperBoard) -> int:
	for cell_index in board.cell_count:
		if (
			not board.mines[cell_index]
			and not board.revealed[cell_index]
			and not board.flagged[cell_index]
			and board.adjacent_counts[cell_index] > 0
		):
			return cell_index
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and not board.revealed[cell_index] and not board.flagged[cell_index]:
			return cell_index
	return -1


func _find_hidden_unflagged_mine(board: MinesweeperBoard) -> int:
	for cell_index in board.cell_count:
		if board.mines[cell_index] and not board.revealed[cell_index] and not board.flagged[cell_index]:
			return cell_index
	return -1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
