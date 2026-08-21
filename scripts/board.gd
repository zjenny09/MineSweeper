class_name MinesweeperBoard
extends Control

signal state_changed(state: int)
signal flags_changed(used_flags: int, max_flags: int)

const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")
const TRIANGLE_BOARD_VIEW_SCRIPT: Script = preload("res://scripts/triangle_board_view.gd")
const SQUARE_TOPOLOGY := "square"
const TRIANGLE_TOPOLOGY := "triangle"
const TRIANGLE_BOARD_SIZE := Vector2(620.0, 460.0)


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
	game_state = GameState.READY
	used_flags = 0
	revealed_safe_count = 0
	guide_cell_index = -1
	_reset_array(mines, false)
	_reset_array(revealed, false)
	_reset_array(flagged, false)
	_reset_array(adjacent_counts, 0)
	_place_random_cores()
	_calculate_adjacent_counts()
	if first_move_guide_enabled:
		guide_cell_index = _choose_guide_cell()
	_refresh_all_cells()
	state_changed.emit(game_state)
	flags_changed.emit(used_flags, core_count)


func reveal_cell(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index):
		return
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
		_refresh_all_cells()
		state_changed.emit(game_state)
		return

	_reveal_area(cell_index)
	if revealed_safe_count == safe_cell_count:
		game_state = GameState.WON
		state_changed.emit(game_state)
	_refresh_all_cells()


func toggle_flag(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index):
		return
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


func chord_cell(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index) or game_state != GameState.PLAYING:
		return
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


func set_interaction_enabled(enabled: bool) -> void:
	if interaction_enabled == enabled:
		return
	interaction_enabled = enabled
	_refresh_all_cells()


func get_triangle_view():
	return _triangle_view


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
		cell.setup(cell_index)
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

	if column > 0:
		neighbors.append(cell_index - 1)
	if column + 1 < column_count:
		neighbors.append(cell_index + 1)

	var vertical_row := row + 1 if (row + column) % 2 == 0 else row - 1
	if vertical_row >= 0 and vertical_row < row_count:
		neighbors.append(vertical_row * column_count + column)
	return neighbors


func _refresh_all_cells() -> void:
	for cell_index in cell_count:
		_refresh_cell(cell_index)


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
