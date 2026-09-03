extends SceneTree

const ART := preload("res://scripts/art_catalog.gd")

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
		{"index": 5, "number": 6, "name": "潮池", "size": Vector2i(5, 5), "cores": 5, "healthy": ART.OCEAN_ACTOR_ANEMONE_HEALTHY, "wilted": ART.OCEAN_ACTOR_ANEMONE_WILTED},
		{"index": 6, "number": 7, "name": "海草", "size": Vector2i(6, 6), "cores": 7, "healthy": ART.OCEAN_ACTOR_SEAGRASS_HEALTHY, "wilted": ART.OCEAN_ACTOR_SEAGRASS_WILTED},
		{"index": 7, "number": 8, "name": "珊瑚", "size": Vector2i(7, 7), "cores": 10, "healthy": ART.OCEAN_ACTOR_CORAL_HEALTHY, "wilted": ART.OCEAN_ACTOR_CORAL_WILTED},
		{"index": 8, "number": 9, "name": "海藻", "size": Vector2i(8, 8), "cores": 14, "healthy": ART.OCEAN_ACTOR_KELP_HEALTHY, "wilted": ART.OCEAN_ACTOR_KELP_WILTED},
		{"index": 9, "number": 10, "name": "鲸落", "size": Vector2i(10, 9), "cores": 22, "healthy": ART.OCEAN_ACTOR_WHALE_FALL_HEALTHY, "wilted": ART.OCEAN_ACTOR_WHALE_FALL_WILTED},
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
		_validate_ocean_paper(board, str(expected.name))
		_validate_ocean_cell_theme(board, str(expected.name))
		_validate_ocean_actor(main_scene, expected)

	main_scene.call("_load_level", 5)
	_validate_failure_pollution(main_scene, board)
	_validate_land_to_ocean_progression(main_scene, board)

	main_scene.queue_free()
	if failures == 0:
		print("Ocean level prototype tests passed.")
		quit(0)
	else:
		push_error("%d ocean level prototype test(s) failed." % failures)
		quit(1)


func _validate_land_to_ocean_progression(main_scene: Control, board: MinesweeperBoard) -> void:
	main_scene.start_level(4, 7)
	var final_safe := -1
	for cell_index in board.cell_count:
		if board.mines[cell_index]:
			board.revealed[cell_index] = false
		else:
			board.revealed[cell_index] = true
			final_safe = cell_index
	board.revealed[final_safe] = false
	board.revealed_safe_count = board.safe_cell_count - 1
	board.game_state = MinesweeperBoard.GameState.PLAYING
	board.reveal_action_count = 1
	board.reveal_cell(final_safe)
	_expect(bool(main_scene.get("_advance_available")), "Level 5 victory exposes the next-level action.")
	_expect(main_scene.get_scan_energy() == 8, "The final Level 5 reveal adds one shared energy.")
	main_scene.call("_on_primary_button_pressed")
	_expect(board.level_number == 6, "The Level 5 next action enters Level 6 directly.")
	_expect(main_scene.get_scan_energy() == 8, "Level 5 to 6 progression preserves shared energy.")
	_expect(
		(main_scene.get_node("%LandTabletopActors") as LandTabletopActors).uses_ocean_ecology(),
		"The direct Level 6 transition configures the ocean actor layer."
	)


func _validate_ocean_actor(main_scene: Control, expected: Dictionary) -> void:
	var actors := main_scene.get_node("%LandTabletopActors") as LandTabletopActors
	var plant_sprite := actors.get_node("DesignPlane/PlantSlot/PlantMotion/PlantSprite") as Sprite2D
	var plant_shadow := actors.get_node("DesignPlane/PlantSlot/PlantShadow") as Control
	_expect(actors.visible and actors.uses_ocean_ecology(), "%s shows the shared actor layer." % expected.name)
	_expect(actors.get_ecology_texture_path() == str(expected.healthy), "%s loads its accepted healthy ecology." % expected.name)
	_expect(is_equal_approx(plant_sprite.scale.x, plant_sprite.scale.y), "%s keeps uniform ecology scaling." % expected.name)
	_expect(not plant_shadow.visible, "%s does not add a generated ecology shadow." % expected.name)
	actors.set_failure(true)
	_expect(actors.get_ecology_texture_path() == str(expected.wilted), "%s switches to its aligned wilted ecology." % expected.name)
	actors.set_failure(false)
	main_scene.call("_set_level_one_reaction", MinesweeperBoard.GameState.WON)
	_expect(actors.get_ecology_texture_path() == str(expected.healthy), "%s victory keeps the healthy ecology." % expected.name)
	_expect(
		actors.get_node("DesignPlane/PlantSlot/VictoryDots").visible,
		"%s victory shows the yellow light dots." % expected.name
	)
	main_scene.call("_set_level_one_reaction", MinesweeperBoard.GameState.READY)


func _validate_failure_pollution(main_scene: Control, board: MinesweeperBoard) -> void:
	var opening_index := -1
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and board.adjacent_counts[cell_index] > 0:
			opening_index = cell_index
			break
	_expect(opening_index >= 0, "Failure pollution setup finds a safe first-reveal target.")
	if opening_index < 0:
		return
	board.reveal_cell(opening_index)
	_expect(board.game_state == MinesweeperBoard.GameState.PLAYING, "The ocean failure setup survives its chosen safe opening.")
	var marked_index := -1
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and not board.revealed[cell_index]:
			marked_index = cell_index
			break
	var mine_index := board.mines.find(true)
	_expect(marked_index >= 0 and mine_index >= 0, "Failure pollution setup finds a flag and a later core target.")
	if marked_index < 0 or mine_index < 0:
		return
	board.toggle_flag(marked_index)
	board.reveal_cell(mine_index)
	board.advance_pollution_animation(999.0)
	_expect(board.game_state == MinesweeperBoard.GameState.LOST, "Failure pollution setup reaches the lost state.")
	var actors := main_scene.get_node("%LandTabletopActors") as LandTabletopActors
	_expect(
		actors.get_ecology_texture_path() == ART.OCEAN_ACTOR_ANEMONE_WILTED,
		"A real ocean loss switches to the matching wilted ecology."
	)
	_expect(
		actors.get_node("DesignPlane/RobotSlot/RobotMotion/RobotFallenPose").visible,
		"A real ocean loss starts the shared robot failure pose."
	)
	for cell_index in board.cell_count:
		var pollution_amount := float(board.cell_nodes[cell_index].call("_ocean_pollution_amount"))
		if board.flagged[cell_index]:
			_expect(
				is_zero_approx(pollution_amount),
				"Every marked ocean cell keeps its non-polluted marker base after loss."
			)
		else:
			_expect(
				is_equal_approx(pollution_amount, 1.0),
				"Every unmarked ocean cell switches fully to the polluted texture after loss."
			)


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


func _validate_ocean_cell_theme(board: MinesweeperBoard, level_name: String) -> void:
	var cell := board.cell_nodes[0]
	var expected_paths := {
		&"hidden": ART.OCEAN_CELL_HIDDEN,
		&"revealed": ART.OCEAN_CELL_REVEALED,
		&"polluted": ART.OCEAN_CELL_POLLUTED,
	}
	for state in expected_paths:
		var texture := cell.call("_ocean_texture_for_state", state) as Texture2D
		_expect(texture != null, "%s loads its %s cell texture." % [level_name, state])
		if texture != null:
			_expect(
				texture.resource_path == expected_paths[state],
				"%s maps %s to the confirmed ocean artwork." % [level_name, state]
			)
	cell.render_state(false, false, false, 0, false)
	_expect(
		(cell.call("_ocean_base_texture") as Texture2D).resource_path == ART.OCEAN_CELL_HIDDEN,
		"%s uses cell 1 for hidden cells." % level_name
	)
	cell.render_state(true, false, false, 1, false)
	_expect(
		(cell.call("_ocean_base_texture") as Texture2D).resource_path == ART.OCEAN_CELL_REVEALED,
		"%s uses cell 2 for revealed cells." % level_name
	)
	_expect(
		cell.get_theme_font("font") != null
		and cell.get_theme_color("font_color") == MineCell.OCEAN_NUMBER_COLORS[1],
		"%s applies the ocean handwritten number theme." % level_name
	)
	var normal_marker := cell.call("_ocean_marker_texture", &"normal") as Texture2D
	var failed_marker := cell.call("_ocean_marker_texture", &"failed") as Texture2D
	var wrong_marker := cell.call("_ocean_marker_texture", &"wrong") as Texture2D
	_expect(
		normal_marker != null and normal_marker.resource_path == ART.OCEAN_MARKER_CORAL_NORMAL,
		"%s maps normal flags to coral marker 1." % level_name
	)
	_expect(
		failed_marker != null and failed_marker.resource_path == ART.OCEAN_MARKER_CORAL_FAILED,
		"%s maps correctly flagged failed cores to coral marker 2." % level_name
	)
	_expect(
		wrong_marker != null and wrong_marker.resource_path == ART.OCEAN_MARKER_CORAL_WRONG,
		"%s maps incorrect flags to coral marker 3." % level_name
	)
	cell.render_state(false, true, false, 0, false)
	_expect(
		cell.procedural_visual == MineCell.ProceduralVisual.BIOSENSOR,
		"%s uses the normal coral while a flag is active." % level_name
	)
	cell.render_state(false, true, true, 0, true)
	_expect(
		cell.procedural_visual == MineCell.ProceduralVisual.WILTED_SPROUT,
		"%s changes a flagged core to the failed coral after loss." % level_name
	)
	cell.render_state(false, true, false, 0, true, true)
	_expect(
		cell.procedural_visual == MineCell.ProceduralVisual.UPROOTED_SPROUT,
		"%s also uses the failed coral for an incorrect flag." % level_name
	)
	cell.set_pollution_progress(1.0)
	_expect(
		is_zero_approx(float(cell.call("_ocean_pollution_amount"))),
		"%s keeps marked cells off the polluted base after loss." % level_name
	)
	cell.render_state(false, false, false, 0, true)
	_expect(
		is_equal_approx(float(cell.call("_ocean_pollution_amount")), 1.0),
		"%s applies the polluted texture to unmarked cells after loss." % level_name
	)
	cell.set_pollution_progress(0.0)
	cell.render_state(false, false, false, 0, false)


func _validate_ocean_paper(board: MinesweeperBoard, level_name: String) -> void:
	var safe_rect := MinesweeperBoard.OCEAN_BOARD_PAPER_SAFE_RECT
	_expect(
		board.ocean_hex_bounds.size.x > 0.0 and board.ocean_hex_bounds.size.y > 0.0,
		"%s records its rendered hex bounds." % level_name
	)
	_expect(
		board.ocean_paper_rect.encloses(board.ocean_hex_bounds),
		"%s keeps every hex inside the dynamic cream paper." % level_name
	)
	_expect(
		safe_rect.encloses(board.ocean_paper_rect),
		"%s constrains the paper to the tray's central window." % level_name
	)
	_expect(
		board.ocean_paper_rect.size.x > board.ocean_hex_bounds.size.x
		and board.ocean_paper_rect.size.y > board.ocean_hex_bounds.size.y,
		"%s preserves visible cream paper around the grid." % level_name
	)
	var neighbor_links := 0
	for cell_index in board.cell_count:
		neighbor_links += board.get_neighbor_indices(cell_index).size()
	_expect(
		board.ocean_shared_edge_count == int(neighbor_links / 2),
		"%s draws each neighboring hex crease exactly once." % level_name
	)


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
