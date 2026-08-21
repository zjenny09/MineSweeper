class_name MinesweeperBoard
extends GridContainer

signal state_changed(state: int)
signal flags_changed(used_flags: int, max_flags: int)

const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")

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

var game_state: int = GameState.READY
var used_flags := 0
var revealed_safe_count := 0

var mines: Array[bool] = []
var revealed: Array[bool] = []
var flagged: Array[bool] = []
var adjacent_counts: Array[int] = []
var cell_nodes: Array[MineCell] = []

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	load_level(GreenSweeperLevels.LEVEL_1)


func load_level(level: Dictionary) -> void:
	level_number = level.number
	level_name = level.name
	var board_size: Vector2i = level.size
	column_count = board_size.x
	row_count = board_size.y
	columns = column_count
	cell_count = row_count * column_count
	core_count = level.core_count
	safe_cell_count = cell_count - core_count
	first_move_guide_enabled = level.get("first_move_guide", false)

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
	if not _is_valid_index(cell_index):
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
	if not _is_valid_index(cell_index):
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


func _clear_cells() -> void:
	for cell in cell_nodes:
		cell.queue_free()
	cell_nodes.clear()


func _create_cells() -> void:
	var cell_size := clampf(360.0 / max(row_count, column_count), 28.0, 64.0)
	for cell_index in cell_count:
		var cell := CELL_SCENE.instantiate() as MineCell
		cell.custom_minimum_size = Vector2(cell_size, cell_size)
		cell.setup(cell_index)
		cell.reveal_requested.connect(reveal_cell)
		cell.flag_requested.connect(toggle_flag)
		add_child(cell)
		cell_nodes.append(cell)


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


func _refresh_all_cells() -> void:
	for cell_index in cell_count:
		_refresh_cell(cell_index)


func _refresh_cell(cell_index: int) -> void:
	if cell_nodes.is_empty():
		return
	var game_finished := game_state == GameState.WON or game_state == GameState.LOST
	var core_visible := game_state == GameState.LOST and mines[cell_index]
	var wrong_flag := game_state == GameState.LOST and flagged[cell_index] and not mines[cell_index]
	var solved_core := game_state == GameState.WON and mines[cell_index]
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
