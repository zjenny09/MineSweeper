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
	var tray := board.get_node("BoardTray") as TextureRect
	var surface := board.get_node("CellSurfaceHost") as Control

	_expect(tray.texture != null, "The level-1 tray remains a standalone texture.")
	_expect(surface.visible, "The editable cell surface is visible on level 1.")
	_expect(surface.size.x > 0.0 and surface.size.y > 0.0, "The editable cell surface has a usable size.")
	_expect(board.cell_nodes.size() == 25, "Level 1 creates 25 dynamic cells.")
	var local_surface_rect := Rect2(Vector2.ZERO, surface.size).grow(1.0)
	for cell_index in board.cell_nodes.size():
		var cell := board.cell_nodes[cell_index]
		_expect(cell.get_parent() == surface, "Every level-1 cell is parented to CellSurfaceHost.")
		_expect(
			local_surface_rect.encloses(cell.get_rect()),
			"Level-1 cell %d stays inside CellSurfaceHost: %s." % [cell_index, cell.get_rect()]
		)

	main_scene.call("_load_level", 1)
	await process_frame
	_expect(surface.visible, "CellSurfaceHost remains visible on later handmade boards.")
	_expect(board.cell_nodes.size() == 36, "Level 2 redraws its 6x6 board.")
	for cell in board.cell_nodes:
		_expect(cell.get_parent() == surface, "Later square levels reuse the handmade cell surface.")
		_expect(cell.uses_level_one_art(), "Later square levels reuse the level-1 cell artwork.")

	main_scene.call("_load_level", 0)
	await process_frame
	_expect(surface.visible, "CellSurfaceHost returns when level 1 is loaded again.")
	_expect(board.cell_nodes.size() == 25, "Returning to level 1 recreates 25 dynamic cells.")
	for cell in board.cell_nodes:
		_expect(cell.get_parent() == surface, "Recreated level-1 cells return to CellSurfaceHost.")

	main_scene.queue_free()
	if failures == 0:
		print("Level-1 board surface tests passed.")
		quit(0)
	else:
		push_error("%d level-1 board surface test(s) failed." % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
