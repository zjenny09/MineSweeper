class_name MinesweeperBoard
extends GridContainer

signal state_changed(state: int)
signal flags_changed(used_flags: int, max_flags: int)

const ROWS := 9
const COLUMNS := 9
const MINE_COUNT := 10
const CELL_COUNT := ROWS * COLUMNS
const SAFE_CELL_COUNT := CELL_COUNT - MINE_COUNT
const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")

enum GameState {
	READY,
	PLAYING,
	WON,
	LOST,
}

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
	columns = COLUMNS
	_random.randomize()
	_create_cells()
	new_game()


func new_game() -> void:
	game_state = GameState.READY
	used_flags = 0
	revealed_safe_count = 0
	_reset_array(mines, false)
	_reset_array(revealed, false)
	_reset_array(flagged, false)
	_reset_array(adjacent_counts, 0)
	_refresh_all_cells()
	state_changed.emit(game_state)
	flags_changed.emit(used_flags, MINE_COUNT)


func reveal_cell(cell_index: int) -> void:
	if not _is_valid_index(cell_index):
		return
	if game_state == GameState.WON or game_state == GameState.LOST:
		return
	if revealed[cell_index] or flagged[cell_index]:
		return

	if game_state == GameState.READY:
		_place_mines(cell_index)
		_calculate_adjacent_counts()
		game_state = GameState.PLAYING
		state_changed.emit(game_state)

	if mines[cell_index]:
		revealed[cell_index] = true
		game_state = GameState.LOST
		_refresh_all_cells()
		state_changed.emit(game_state)
		return

	_reveal_area(cell_index)
	if revealed_safe_count == SAFE_CELL_COUNT:
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
	elif used_flags < MINE_COUNT:
		flagged[cell_index] = true
		used_flags += 1
	else:
		return

	_refresh_cell(cell_index)
	flags_changed.emit(used_flags, MINE_COUNT)


func _create_cells() -> void:
	for cell_index in CELL_COUNT:
		var cell := CELL_SCENE.instantiate() as MineCell
		cell.setup(cell_index)
		cell.reveal_requested.connect(reveal_cell)
		cell.flag_requested.connect(toggle_flag)
		add_child(cell)
		cell_nodes.append(cell)


func _place_mines(excluded_index: int) -> void:
	var candidates: Array[int] = []
	for cell_index in CELL_COUNT:
		if cell_index != excluded_index:
			candidates.append(cell_index)

	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary

	for index in MINE_COUNT:
		mines[candidates[index]] = true

	assert(not mines[excluded_index], "The first revealed cell must be safe.")
	assert(mines.count(true) == MINE_COUNT, "The board must contain exactly 10 mines.")


func _calculate_adjacent_counts() -> void:
	for cell_index in CELL_COUNT:
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

		# Numbered cells form the visible boundary of an empty region.
		if adjacent_counts[current] > 0:
			continue

		for neighbor in _get_neighbors(current):
			if not queued[neighbor] and not revealed[neighbor] and not flagged[neighbor] and not mines[neighbor]:
				queued[neighbor] = true
				queue.push_back(neighbor)


func _get_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	var row := int(cell_index / COLUMNS)
	var column := cell_index % COLUMNS

	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			if row_offset == 0 and column_offset == 0:
				continue
			var neighbor_row := row + row_offset
			var neighbor_column := column + column_offset
			if neighbor_row < 0 or neighbor_row >= ROWS:
				continue
			if neighbor_column < 0 or neighbor_column >= COLUMNS:
				continue
			neighbors.append(neighbor_row * COLUMNS + neighbor_column)

	return neighbors


func _refresh_all_cells() -> void:
	for cell_index in CELL_COUNT:
		_refresh_cell(cell_index)


func _refresh_cell(cell_index: int) -> void:
	if cell_nodes.is_empty():
		return
	var game_finished := game_state == GameState.WON or game_state == GameState.LOST
	var mine_visible := game_state == GameState.LOST and mines[cell_index]
	var wrong_flag := game_state == GameState.LOST and flagged[cell_index] and not mines[cell_index]
	var solved_mine := game_state == GameState.WON and mines[cell_index]
	cell_nodes[cell_index].render_state(
		revealed[cell_index],
		flagged[cell_index],
		mine_visible,
		adjacent_counts[cell_index],
		game_finished,
		wrong_flag,
		solved_mine
	)


func _reset_array(array: Array, value: Variant) -> void:
	array.resize(CELL_COUNT)
	array.fill(value)


func _is_valid_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < CELL_COUNT
