class_name MinesweeperBoard
extends Control

signal state_changed(state: int)
signal flags_changed(used_flags: int, max_flags: int)
signal reveal_completed(cell_index: int, newly_revealed_count: int)
signal flag_completed(cell_index: int, is_flagged: bool)
signal chord_completed(cell_index: int, newly_revealed_count: int)

const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")
const TRIANGLE_BOARD_VIEW_SCRIPT: Script = preload("res://scripts/triangle_board_view.gd")
const SQUARE_TOPOLOGY := "square"
const TRIANGLE_TOPOLOGY := "triangle"
const TRIANGLE_BOARD_SIZE := Vector2(620.0, 460.0)
const POLLUTION_STEP_DELAY := 0.22
const POLLUTION_CELL_DURATION := 0.95


enum OperationMode {
	MOUSE,
	KEYBOARD,
}


enum GameState {
	READY,
	PLAYING,
	WON,
	LOST,
}

var level_number := 0
var level_name := ""
var row_count := 0
var column_count := 0
var core_count := 0
var cell_count := 0
var safe_cell_count := 0
var first_move_guide_enabled := false
var guide_cell_index := -1
var topology := SQUARE_TOPOLOGY

var game_state: int = GameState.READY
var used_flags := 0
var revealed_safe_count := 0
var interaction_enabled := true
var operation_mode: int = OperationMode.MOUSE
var keyboard_cell_index := -1
var pollution_tint_progress := 0.0
var _pollution_animation_active := false
var _pollution_elapsed := 0.0
var _pollution_origin_index := -1

var mines: Array[bool] = []
var revealed: Array[bool] = []
var flagged: Array[bool] = []
var adjacent_counts: Array[int] = []
var cell_nodes: Array[MineCell] = []

var _random := RandomNumberGenerator.new()
var _square_grid: GridContainer
var _triangle_view


func _ready() -> void:
	_random.randomize()
	set_process(false)


func _process(delta: float) -> void:
	advance_pollution_animation(delta)


func advance_pollution_animation(delta: float) -> void:
	if not _pollution_animation_active:
		set_process(false)
		return
	_pollution_elapsed += maxf(0.0, delta)
	var origin_row := int(_pollution_origin_index / column_count)
	var origin_column := _pollution_origin_index % column_count
	var all_complete := true
	for cell_index in cell_nodes.size():
		var row := int(cell_index / column_count)
		var column := cell_index % column_count
		var distance: int = absi(row - origin_row) + absi(column - origin_column)
		var local_progress := clampf(
			(_pollution_elapsed - float(distance) * POLLUTION_STEP_DELAY)
			/ POLLUTION_CELL_DURATION,
			0.0,
			1.0
		)
		cell_nodes[cell_index].set_pollution_progress(local_progress)
		if local_progress < 1.0:
			all_complete = false
	var max_distance := maxi(row_count - 1, 0) + maxi(column_count - 1, 0)
	var total_duration := float(max_distance) * POLLUTION_STEP_DELAY + POLLUTION_CELL_DURATION
	pollution_tint_progress = clampf(_pollution_elapsed / total_duration, 0.0, 1.0)
	if all_complete:
		_pollution_animation_active = false
		set_process(false)


func _start_pollution_animation(origin_index: int) -> void:
	pollution_tint_progress = 0.0
	_pollution_elapsed = 0.0
	_pollution_origin_index = origin_index
	_pollution_animation_active = true
	for cell in cell_nodes:
		cell.set_pollution_progress(0.0)
	set_process(true)


func _reset_pollution_animation() -> void:
	pollution_tint_progress = 0.0
	_pollution_elapsed = 0.0
	_pollution_origin_index = -1
	_pollution_animation_active = false
	modulate = Color.WHITE
	for cell in cell_nodes:
		cell.set_pollution_progress(0.0)
	set_process(false)


func _input(event: InputEvent) -> void:
	if operation_mode != OperationMode.KEYBOARD:
		return
	if not is_visible_in_tree() or not interaction_enabled:
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return
	if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return

	var movement := Vector2i.ZERO
	match key_event.keycode:
		KEY_UP:
			movement = Vector2i(0, -1)
		KEY_DOWN:
			movement = Vector2i(0, 1)
		KEY_LEFT:
			movement = Vector2i(-1, 0)
		KEY_RIGHT:
			movement = Vector2i(1, 0)
	if movement == Vector2i.ZERO:
		var movement_key := key_event.physical_keycode
		if movement_key == 0:
			movement_key = key_event.keycode
		match movement_key:
			KEY_W:
				movement = Vector2i(0, -1)
			KEY_S:
				movement = Vector2i(0, 1)
			KEY_A:
				movement = Vector2i(-1, 0)
			KEY_D:
				movement = Vector2i(1, 0)
	if movement != Vector2i.ZERO:
		_move_keyboard_cursor(movement)
		get_viewport().set_input_as_handled()
		return

	if key_event.echo:
		return
	var action_key := key_event.physical_keycode
	if action_key == 0:
		action_key = key_event.keycode
	if action_key == KEY_Z:
		_keyboard_primary_action()
		get_viewport().set_input_as_handled()
	elif action_key == KEY_X:
		toggle_flag(keyboard_cell_index)
		get_viewport().set_input_as_handled()


func load_level(level: Dictionary) -> void:
	level_number = level.number
	level_name = level.name
	var board_size: Vector2i = level.size
	column_count = board_size.x
	row_count = board_size.y
	cell_count = row_count * column_count
	core_count = level.core_count
	safe_cell_count = cell_count - core_count
	first_move_guide_enabled = level.get("first_move_guide", false)
	topology = level.get("topology", SQUARE_TOPOLOGY)

	_clear_cells()
	_create_cells()
	new_game()


func new_game() -> void:
	_reset_pollution_animation()
	game_state = GameState.READY
	used_flags = 0
	revealed_safe_count = 0
	guide_cell_index = -1
	for cell in cell_nodes:
		cell.reset_transient_visuals()
	_reset_array(mines, false)
	_reset_array(revealed, false)
	_reset_array(flagged, false)
	_reset_array(adjacent_counts, 0)
	_place_random_cores()
	_calculate_adjacent_counts()
	if first_move_guide_enabled:
		guide_cell_index = _choose_guide_cell()
	_reset_keyboard_cursor()
	_refresh_all_cells()
	state_changed.emit(game_state)
	flags_changed.emit(used_flags, core_count)


func reveal_cell(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index):
		return
	_sync_keyboard_cursor(cell_index)
	if game_state == GameState.WON or game_state == GameState.LOST:
		return
	if revealed[cell_index] or flagged[cell_index]:
		return

	if game_state == GameState.READY:
		guide_cell_index = -1
		game_state = GameState.PLAYING
		state_changed.emit(game_state)

	if mines[cell_index]:
		revealed[cell_index] = true
		game_state = GameState.LOST
		if level_number == 1:
			_start_pollution_animation(cell_index)
			for cell in cell_nodes:
				cell.begin_loss_wilt_if_visible()
		_refresh_all_cells()
		state_changed.emit(game_state)
		reveal_completed.emit(cell_index, 0)
		return

	var previous_revealed_count := revealed_safe_count
	_reveal_area(cell_index)
	if revealed_safe_count == safe_cell_count:
		game_state = GameState.WON
		state_changed.emit(game_state)
	_refresh_all_cells()
	reveal_completed.emit(cell_index, revealed_safe_count - previous_revealed_count)


func toggle_flag(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index):
		return
	_sync_keyboard_cursor(cell_index)
	if game_state == GameState.WON or game_state == GameState.LOST:
		return
	if revealed[cell_index]:
		return

	if flagged[cell_index]:
		flagged[cell_index] = false
		used_flags -= 1
	elif used_flags < core_count:
		flagged[cell_index] = true
		used_flags += 1
	else:
		return

	_refresh_cell(cell_index)
	flags_changed.emit(used_flags, core_count)
	flag_completed.emit(cell_index, flagged[cell_index])


func chord_cell(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index) or game_state != GameState.PLAYING:
		return
	_sync_keyboard_cursor(cell_index)
	if not revealed[cell_index] or adjacent_counts[cell_index] <= 0:
		return

	var neighbors := _get_neighbors(cell_index)
	var correctly_flagged_cores := 0
	for neighbor in neighbors:
		if not flagged[neighbor]:
			continue
		if not mines[neighbor]:
			return
		correctly_flagged_cores += 1

	if correctly_flagged_cores != adjacent_counts[cell_index]:
		return

	var previous_revealed_count := revealed_safe_count
	for neighbor in neighbors:
		if not mines[neighbor] and not flagged[neighbor] and not revealed[neighbor]:
			_reveal_area(neighbor)

	if revealed_safe_count == safe_cell_count:
		game_state = GameState.WON
		state_changed.emit(game_state)
	if revealed_safe_count != previous_revealed_count:
		_refresh_all_cells()
		chord_completed.emit(cell_index, revealed_safe_count - previous_revealed_count)


func set_interaction_enabled(enabled: bool) -> void:
	if interaction_enabled == enabled:
		return
	interaction_enabled = enabled
	_refresh_all_cells()


func set_operation_mode(mode: int) -> void:
	operation_mode = OperationMode.KEYBOARD if mode == OperationMode.KEYBOARD else OperationMode.MOUSE
	_reset_keyboard_cursor()


func get_operation_mode() -> int:
	return operation_mode


func get_keyboard_cell_index() -> int:
	return keyboard_cell_index


func _reset_keyboard_cursor() -> void:
	if operation_mode != OperationMode.KEYBOARD or cell_count <= 0:
		keyboard_cell_index = -1
	else:
		keyboard_cell_index = guide_cell_index if _is_valid_index(guide_cell_index) else 0
	_refresh_keyboard_cursor()


func _move_keyboard_cursor(movement: Vector2i) -> void:
	if not _is_valid_index(keyboard_cell_index):
		_reset_keyboard_cursor()
		return
	var row := int(keyboard_cell_index / column_count)
	var column := keyboard_cell_index % column_count
	var next_row := clampi(row + movement.y, 0, row_count - 1)
	var next_column := clampi(column + movement.x, 0, column_count - 1)
	_set_keyboard_cursor(next_row * column_count + next_column)


func _keyboard_primary_action() -> void:
	if not _is_valid_index(keyboard_cell_index):
		return
	if revealed[keyboard_cell_index]:
		chord_cell(keyboard_cell_index)
	else:
		reveal_cell(keyboard_cell_index)


func _sync_keyboard_cursor(cell_index: int) -> void:
	if operation_mode == OperationMode.KEYBOARD:
		_set_keyboard_cursor(cell_index)


func _set_keyboard_cursor(cell_index: int) -> void:
	if not _is_valid_index(cell_index) or keyboard_cell_index == cell_index:
		return
	keyboard_cell_index = cell_index
	_refresh_keyboard_cursor()


func _refresh_keyboard_cursor() -> void:
	var selected_index := keyboard_cell_index if operation_mode == OperationMode.KEYBOARD else -1
	for cell_index in cell_nodes.size():
		cell_nodes[cell_index].set_keyboard_selected(cell_index == selected_index)
	if is_instance_valid(_triangle_view):
		_triangle_view.set_keyboard_cursor(selected_index)


func get_triangle_view():
	return _triangle_view


func get_neighbor_indices(cell_index: int) -> Array[int]:
	if not _is_valid_index(cell_index):
		return []
	return _get_neighbors(cell_index)


func clear_guide_cell() -> void:
	var previous_index := guide_cell_index
	guide_cell_index = -1
	if _is_valid_index(previous_index):
		_refresh_cell(previous_index)


func _clear_cells() -> void:
	cell_nodes.clear()
	if is_instance_valid(_square_grid):
		remove_child(_square_grid)
		_square_grid.free()
	_square_grid = null
	if is_instance_valid(_triangle_view):
		remove_child(_triangle_view)
		_triangle_view.free()
	_triangle_view = null


func _create_cells() -> void:
	if topology == TRIANGLE_TOPOLOGY:
		_create_triangle_view()
	else:
		_create_square_cells()


func _create_square_cells() -> void:
	var cell_size := clampf(480.0 / max(row_count, column_count), 34.0, 82.0)
	var separation := 3.0
	var grid_size := Vector2(
		float(column_count) * cell_size + float(column_count - 1) * separation,
		float(row_count) * cell_size + float(row_count - 1) * separation
	)
	custom_minimum_size = grid_size

	_square_grid = GridContainer.new()
	_square_grid.columns = column_count
	_square_grid.custom_minimum_size = grid_size
	_square_grid.add_theme_constant_override("h_separation", int(separation))
	_square_grid.add_theme_constant_override("v_separation", int(separation))
	add_child(_square_grid)

	for cell_index in cell_count:
		var cell := CELL_SCENE.instantiate() as MineCell
		cell.custom_minimum_size = Vector2(cell_size, cell_size)
		cell.focus_mode = Control.FOCUS_NONE
		cell.setup(cell_index, level_number)
		cell.reveal_requested.connect(reveal_cell)
		cell.flag_requested.connect(toggle_flag)
		cell.chord_requested.connect(chord_cell)
		_square_grid.add_child(cell)
		cell_nodes.append(cell)


func _create_triangle_view() -> void:
	custom_minimum_size = TRIANGLE_BOARD_SIZE
	_triangle_view = TRIANGLE_BOARD_VIEW_SCRIPT.new()
	add_child(_triangle_view)
	_triangle_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_triangle_view.setup(row_count, column_count)
	_triangle_view.reveal_requested.connect(reveal_cell)
	_triangle_view.flag_requested.connect(toggle_flag)
	_triangle_view.chord_requested.connect(chord_cell)


func _place_random_cores() -> void:
	var candidates: Array[int] = []
	for cell_index in cell_count:
		candidates.append(cell_index)

	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary

	for index in core_count:
		mines[candidates[index]] = true

	assert(mines.count(true) == core_count, "The board must contain the configured pollution core count.")


func _choose_guide_cell() -> int:
	var zero_cells: Array[int] = []
	var lowest_number_cells: Array[int] = []
	var lowest_number := 9

	for cell_index in cell_count:
		if mines[cell_index]:
			continue
		var number := adjacent_counts[cell_index]
		if number == 0:
			zero_cells.append(cell_index)
		elif number < lowest_number:
			lowest_number = number
			lowest_number_cells = [cell_index]
		elif number == lowest_number:
			lowest_number_cells.append(cell_index)

	var candidates := zero_cells if not zero_cells.is_empty() else lowest_number_cells
	assert(not candidates.is_empty(), "A guide requires at least one safe cell.")
	return candidates[_random.randi_range(0, candidates.size() - 1)]


func _calculate_adjacent_counts() -> void:
	for cell_index in cell_count:
		var count := 0
		for neighbor in _get_neighbors(cell_index):
			if mines[neighbor]:
				count += 1
		adjacent_counts[cell_index] = count


func _reveal_area(start_index: int) -> void:
	var queue: Array[int] = [start_index]
	var queued: Array[bool] = []
	_reset_array(queued, false)
	queued[start_index] = true

	while not queue.is_empty():
		var current: int = queue.pop_front()
		if revealed[current] or flagged[current] or mines[current]:
			continue

		revealed[current] = true
		revealed_safe_count += 1

		if adjacent_counts[current] > 0:
			continue

		for neighbor in _get_neighbors(current):
			if not queued[neighbor] and not revealed[neighbor] and not flagged[neighbor] and not mines[neighbor]:
				queued[neighbor] = true
				queue.push_back(neighbor)


func _get_neighbors(cell_index: int) -> Array[int]:
	if topology == TRIANGLE_TOPOLOGY:
		return _get_triangle_neighbors(cell_index)
	return _get_square_neighbors(cell_index)


func _get_square_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	var row := int(cell_index / column_count)
	var column := cell_index % column_count

	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			if row_offset == 0 and column_offset == 0:
				continue
			var neighbor_row := row + row_offset
			var neighbor_column := column + column_offset
			if neighbor_row < 0 or neighbor_row >= row_count:
				continue
			if neighbor_column < 0 or neighbor_column >= column_count:
				continue
			neighbors.append(neighbor_row * column_count + neighbor_column)

	return neighbors


func _get_triangle_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	var row := int(cell_index / column_count)
	var column := cell_index % column_count

	# A triangle counts the three cells sharing an edge and the nearest
	# cell across each vertex: four horizontal positions and two vertical.
	for column_offset in [-2, -1, 1, 2]:
		var neighbor_column: int = column + int(column_offset)
		if neighbor_column >= 0 and neighbor_column < column_count:
			neighbors.append(row * column_count + neighbor_column)
	for row_offset in [-1, 1]:
		var neighbor_row: int = row + int(row_offset)
		if neighbor_row >= 0 and neighbor_row < row_count:
			neighbors.append(neighbor_row * column_count + column)
	return neighbors


func _refresh_all_cells() -> void:
	for cell_index in cell_count:
		_refresh_cell(cell_index)
	_refresh_keyboard_cursor()


func _refresh_cell(cell_index: int) -> void:
	var game_finished := game_state == GameState.WON or game_state == GameState.LOST or not interaction_enabled
	var core_visible := game_state == GameState.LOST and mines[cell_index]
	var wrong_flag := game_state == GameState.LOST and flagged[cell_index] and not mines[cell_index]
	var solved_core := game_state == GameState.WON and mines[cell_index]
	if is_instance_valid(_triangle_view):
		_triangle_view.render_state(
			cell_index,
			revealed[cell_index],
			flagged[cell_index],
			core_visible,
			adjacent_counts[cell_index],
			game_finished,
			wrong_flag,
			solved_core
		)
	elif not cell_nodes.is_empty():
		cell_nodes[cell_index].render_state(
			revealed[cell_index],
			flagged[cell_index],
			core_visible,
			adjacent_counts[cell_index],
			game_finished,
			wrong_flag,
			solved_core,
			cell_index == guide_cell_index
		)


func _reset_array(array: Array, value: Variant) -> void:
	array.resize(cell_count)
	array.fill(value)


func _is_valid_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < cell_count
