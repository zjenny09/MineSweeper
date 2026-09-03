extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene := packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	var board := main_scene.get_node("%Board") as MinesweeperBoard

	for level_index in GreenSweeperLevels.PLAYABLE_LEVELS.size():
		var first_streaks := {}
		first_streaks[level_index] = 2
		main_scene.set("_first_click_mine_streaks", first_streaks)
		main_scene.set("_early_loss_streaks", {})
		main_scene.call("_load_level", level_index)
		await process_frame
		_expect(
			board.opening_assist_mode == MinesweeperBoard.OpeningAssist.SAFE_FIRST,
			"Every level can arm same-level safe-first assistance."
		)
		var early_streaks := {}
		early_streaks[level_index] = 3
		main_scene.set("_first_click_mine_streaks", {})
		main_scene.set("_early_loss_streaks", early_streaks)
		main_scene.restart_level()
		_expect(
			board.opening_assist_mode == MinesweeperBoard.OpeningAssist.OPEN_REGION,
			"Every level can arm same-level region-opening assistance."
		)

	main_scene.set("_first_click_mine_streaks", {})
	main_scene.set("_early_loss_streaks", {})
	main_scene.call("_load_level", 2)
	await process_frame

	for attempt in 2:
		var first_core := board.mines.find(true)
		board.reveal_cell(first_core)
		_expect(board.game_state == MinesweeperBoard.GameState.LOST, "The setup loses on its first reveal.")
		if attempt < 1:
			main_scene.restart_level()
	main_scene.restart_level()
	_expect(
		board.opening_assist_mode == MinesweeperBoard.OpeningAssist.SAFE_FIRST,
		"Two consecutive first-reveal losses arm safe-first assistance."
	)
	var assisted_core := board.mines.find(true)
	board.reveal_cell(assisted_core)
	_expect(not board.mines[assisted_core], "Safe-first assistance relocates the selected core.")
	_expect(board.game_state != MinesweeperBoard.GameState.LOST, "Safe-first assistance prevents only the assisted opening loss.")
	_expect(board.mines.count(true) == board.core_count, "Safe-first assistance preserves the configured core count.")

	main_scene.set("_first_click_mine_streaks", {})
	main_scene.set("_early_loss_streaks", {})
	main_scene.restart_level()
	for attempt in 3:
		var safe_number := _find_safe_number(board)
		_expect(safe_number >= 0, "The early-loss setup has a safe numbered opening.")
		if safe_number < 0:
			break
		board.reveal_cell(safe_number)
		var later_core := board.mines.find(true)
		board.reveal_cell(later_core)
		_expect(board.game_state == MinesweeperBoard.GameState.LOST, "The setup loses after surviving its first reveal.")
		_expect(board.move_count <= 5, "The setup loss occurs within five moves.")
		if attempt < 2:
			main_scene.restart_level()
	main_scene.restart_level()
	_expect(
		board.opening_assist_mode == MinesweeperBoard.OpeningAssist.OPEN_REGION,
		"Three consecutive non-opening early losses arm region-opening assistance."
	)
	var region_core := board.mines.find(true)
	board.reveal_cell(region_core)
	_expect(not board.mines[region_core], "Region-opening assistance relocates a selected core.")
	_expect(board.adjacent_counts[region_core] == 0, "Region-opening assistance makes the selected cell a zero.")
	_expect(board.revealed_safe_count > 1, "Region-opening assistance reveals a connected opening area.")
	_expect(board.mines.count(true) == board.core_count, "Region-opening assistance preserves the configured core count.")

	main_scene.set("_first_click_mine_streaks", {})
	main_scene.set("_early_loss_streaks", {})
	main_scene.call("_load_level", 5)
	var unassisted_ocean_core := board.mines.find(true)
	board.reveal_cell(unassisted_ocean_core)
	_expect(
		board.game_state == MinesweeperBoard.GameState.LOST,
		"Ocean levels no longer have an independent unconditional safe first click."
	)

	main_scene.set("_first_click_mine_streaks", {5: 2})
	main_scene.set("_early_loss_streaks", {})
	main_scene.call("_load_level", 6)
	_expect(
		board.opening_assist_mode == MinesweeperBoard.OpeningAssist.NONE,
		"A Level 6 loss streak does not grant assistance in the next level."
	)
	main_scene.call("_load_level", 5)
	_expect(
		board.opening_assist_mode == MinesweeperBoard.OpeningAssist.SAFE_FIRST,
		"The Level 6 streak grants assistance only in the next Level 6 game."
	)
	var assisted_ocean_core := board.mines.find(true)
	board.reveal_cell(assisted_ocean_core)
	_expect(
		board.game_state != MinesweeperBoard.GameState.LOST,
		"Same-level safe-first assistance works on an ocean board."
	)

	main_scene.set("_first_click_mine_streaks", {})
	main_scene.set("_early_loss_streaks", {9: 3})
	main_scene.call("_load_level", 9)
	var ocean_region_core := board.mines.find(true)
	board.reveal_cell(ocean_region_core)
	_expect(not board.mines[ocean_region_core], "Ocean region assistance relocates the selected core.")
	_expect(board.adjacent_counts[ocean_region_core] == 0, "Ocean region assistance clears all six neighboring positions.")
	_expect(board.revealed_safe_count > 1, "Ocean region assistance reveals a connected hex area.")
	_expect(board.mines.count(true) == board.core_count, "Ocean region assistance preserves the core count.")

	main_scene.queue_free()
	if failures == 0:
		print("Adaptive opening assistance tests passed.")
		quit(0)
	else:
		push_error("%d adaptive opening assistance test(s) failed." % failures)
		quit(1)


func _find_safe_number(board: MinesweeperBoard) -> int:
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and board.adjacent_counts[cell_index] > 0:
			return cell_index
	return -1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
