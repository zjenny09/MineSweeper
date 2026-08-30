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
	var expected_levels := [
		{"index": 5, "number": 6, "name": "潮池初醒", "size": Vector2i(5, 5), "cores": 5},
		{"index": 6, "number": 7, "name": "海草摇篮", "size": Vector2i(6, 6), "cores": 7},
		{"index": 7, "number": 8, "name": "珊瑚花园", "size": Vector2i(7, 7), "cores": 10},
		{"index": 8, "number": 9, "name": "海藻森林", "size": Vector2i(8, 8), "cores": 14},
		{"index": 9, "number": 10, "name": "深海鲸落", "size": Vector2i(10, 9), "cores": 22},
	]

	for expected in expected_levels:
		main_scene.call("_load_level", int(expected.index))
		_expect(board.level_number == int(expected.number), "The configured ocean level number loads.")
		_expect(board.level_name == str(expected.name), "The configured ocean level name loads.")
		_expect(board.topology == &"hex_pointy_odd_r", "%s uses the hex topology." % expected.name)
		var size: Vector2i = expected.size
		_expect(
			board.column_count == size.x and board.row_count == size.y,
			"%s uses its configured dimensions." % expected.name
		)
		_expect(board.cell_count == size.x * size.y, "%s creates the expected number of cells." % expected.name)
		_expect(board.core_count == int(expected.cores), "%s uses its configured core count." % expected.name)
		_expect(board.mines.count(true) == int(expected.cores), "%s generates every configured core." % expected.name)
		_validate_hex_neighbors(board, str(expected.name))

	main_scene.queue_free()
	if failures == 0:
		print("Ocean level prototype tests passed.")
		quit(0)
	else:
		push_error("%d ocean level prototype test(s) failed." % failures)
		quit(1)


func _validate_hex_neighbors(board: MinesweeperBoard, level_name: String) -> void:
	for cell_index in board.cell_count:
		var neighbors := board.get_neighbor_indices(cell_index)
		_expect(neighbors.size() <= 6, "%s cells have no more than six neighbors." % level_name)
		_expect(neighbors.size() == _unique_count(neighbors), "%s neighbor lists contain no duplicates." % level_name)
		for neighbor in neighbors:
			_expect(
				board.get_neighbor_indices(neighbor).has(cell_index),
				"%s hex neighbor links are symmetric." % level_name
			)
		var expected_count := 0
		for neighbor in neighbors:
			if board.mines[neighbor]:
				expected_count += 1
		_expect(
			board.adjacent_counts[cell_index] == expected_count,
			"%s adjacent counts use the six-neighbor layout." % level_name
		)
		_expect(bool(board.cell_nodes[cell_index].get("_is_hex")), "%s cells render as hexagons." % level_name)


func _unique_count(values: Array[int]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
