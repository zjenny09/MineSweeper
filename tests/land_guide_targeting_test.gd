extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Host mouse position must not affect a geometry-only regression run.
	root.gui_disable_input = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	TranslationServer.set_locale("zh_CN")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	game.set_first_move_guide_enabled(true)
	root.add_child(game)
	await process_frame
	var guide: FirstMoveGuide = game.first_move_guide
	var board: MinesweeperBoard = game.board
	for level_number in range(1, 8):
		game.start_level(level_number - 1)
		await _settle()
		if level_number in [3, 5, 7]:
			for seed_value in [271, 863]:
				board._random.seed = seed_value
				game.restart_level()
				await _settle()
				var selected: Control = guide._target_cell
				var index := board.cell_nodes.find(selected)
				_expect(index >= 0, "Mechanic guide targets a live generated cell after restart")
				if index >= 0:
					if level_number == 3:
						_expect(board.obstacles[index], "Obstacle guide points at an actual obstacle")
					else:
						_expect(board.pollution_nodes[index] and not board.pollution_nodes_cleansed[index], "Nodule/root guide points at a current uncleansed nodule")
					await _check_target(guide, selected, "level %d seed %d" % [level_number, seed_value])
				print("GENERATED_TARGET level=", level_number, " seed=", seed_value, " cell=", index)
			guide.complete_dialogue()
			await _settle()
		elif level_number == 1:
			_expect(guide.get_target_center() == Vector2(-1.0, -1.0), "Greeting has no invented board target")
			guide.next_button.pressed.emit()
			await _settle()
		var safe_index := _safe_cell_index(board)
		_expect(safe_index >= 0, "Generated board has a safe tutorial example")
		if safe_index >= 0:
			var cell: Control = board.cell_nodes[safe_index]
			guide.show_for_cell(cell, safe_index, false)
			await _check_target(guide, cell, "level %d cell tutorial" % level_number)
	await _check_live_transforms(game, guide, board)
	await _check_scan_target(game, guide)
	await _check_point_edges(guide)
	guide.hide_guide()
	_expect(guide.get_target_center() == Vector2(-1.0, -1.0), "Hiding clears the previous live or point target")
	game.queue_free()
	await process_frame
	print("LAND_GUIDE_TARGETING failures=", failures)
	quit(0 if failures == 0 else 1)


func _safe_cell_index(board: MinesweeperBoard) -> int:
	for index in board.cell_count:
		if not board.obstacles[index] and not board.pollution_nodes[index] and not board.mines[index]:
			return index
	return -1


func _check_live_transforms(game, guide: FirstMoveGuide, board: MinesweeperBoard) -> void:
	var index := _safe_cell_index(board)
	if index < 0:
		return
	var cell: Control = board.cell_nodes[index]
	guide.show_dialogue(&"pollution_nodes", game.LEVEL_MECHANIC_GUIDES[5]["pages"], false, cell)
	game.position = Vector2(21.0, 17.0)
	game.scale = Vector2(0.84, 0.88)
	board.scale = Vector2(0.79, 0.86)
	guide.scale = Vector2(0.93, 0.91)
	await _check_target(guide, cell, "independently scaled ancestry")
	var before := guide.get_global_transform_with_canvas() * guide.get_target_center()
	board.scale = Vector2(0.66, 0.72)
	await _check_target(guide, cell, "live target after layout changes")
	var after := guide.get_global_transform_with_canvas() * guide.get_target_center()
	_expect(not before.is_equal_approx(after), "A live target follows the changed board instead of retaining a snapshot")
	game.position = Vector2.ZERO
	game.scale = Vector2.ONE
	board.scale = Vector2.ONE
	guide.scale = Vector2.ONE
	guide.hide_guide()


func _check_scan_target(game, guide: FirstMoveGuide) -> void:
	var robot: Control = game.land_tabletop_actors.find_child("RobotHotspot", true, false)
	guide.show_dialogue(&"eco_scan", game.SCAN_GUIDE["pages"], false, game._mechanic_guide_target(&"eco_scan"))
	await _check_target(guide, robot, "scan keeps the authored robot target")
	guide.hide_guide()


func _check_point_edges(guide: FirstMoveGuide) -> void:
	for corner in [Vector2(4.0, 4.0), Vector2(guide.size.x - 4.0, 4.0), Vector2(4.0, guide.size.y - 4.0), guide.size - Vector2(4.0, 4.0)]:
		var point: Vector2 = guide.get_global_transform() * corner
		guide.show_dialogue(&"edge_example", [{"title": "TXT_0253", "text": "TXT_0254", "hint": "TXT_0255"}], false, point)
		await _settle()
		var observed := guide.get_global_transform_with_canvas() * guide.get_target_center()
		var expected := guide.get_canvas_transform() * point
		_expect(observed.distance_to(expected) < 0.1, "Point targets retain canvas-global coordinates near viewport edges")
		_expect(Rect2(Vector2.ZERO, guide.size).encloses(guide.bubble_root.get_rect()), "Clamped bubble stays inside its guide bounds")
		_check_triangle(guide, Rect2(expected, Vector2.ZERO), "clamped corner")


func _check_target(guide: FirstMoveGuide, target: Control, description: String) -> void:
	await _settle()
	if not is_instance_valid(target):
		_expect(false, description + ": target exists")
		return
	var expected := target.get_global_transform_with_canvas() * (target.size * 0.5)
	var actual := guide.get_global_transform_with_canvas() * guide.get_target_center()
	_expect(actual.distance_to(expected) < 0.1, description + ": rendered target center matches the actual cell/control")
	var bubble: Rect2 = guide.get_global_transform_with_canvas() * guide.bubble_root.get_rect()
	var target_rect: Rect2 = target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, target.size)
	_expect(not bubble.intersects(target_rect), description + ": explanation does not cover its target")
	_expect(Rect2(Vector2.ZERO, guide.size).encloses(guide.bubble_root.get_rect()), description + ": explanation remains within the guide")
	_check_triangle(guide, target_rect, description)


func _check_triangle(guide: FirstMoveGuide, target_rect: Rect2, description: String) -> void:
	var transform := guide.get_global_transform_with_canvas()
	var tip: Vector2 = transform * guide._pointer_vertices[0]
	var base: Vector2 = transform * ((guide._pointer_vertices[1] + guide._pointer_vertices[2]) * 0.5)
	var direction := (tip - base).normalized()
	var towards_target := (target_rect.get_center() - tip).normalized()
	_expect(direction.dot(towards_target) > 0.999, description + ": triangle aims at the actual target even when clamped")
	var nearest := tip.clamp(target_rect.position, target_rect.end)
	_expect(tip.distance_to(nearest) <= 8.0, description + ": triangle tip stays close enough to identify its target")


func _settle() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
