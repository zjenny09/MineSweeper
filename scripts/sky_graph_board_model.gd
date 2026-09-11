class_name SkyGraphBoardModel
extends RefCounted

signal board_changed
signal flags_changed(used_flags: int, max_flags: int)
signal state_changed(state: int)
signal first_reveal

enum State {
	READY,
	PLAYING,
	WON,
	LOST,
}

var neighbors: Array[PackedInt32Array] = []
var mines: PackedByteArray
var revealed: PackedByteArray
var flagged: PackedByteArray
var adjacent_counts: PackedInt32Array
var core_count := 0
var state := State.READY
var _rng := RandomNumberGenerator.new()


func configure(face_neighbors: Array[PackedInt32Array], mine_count: int) -> void:
	neighbors = face_neighbors
	core_count = clampi(mine_count, 1, maxi(1, neighbors.size() - 1))
	mines.resize(neighbors.size())
	revealed.resize(neighbors.size())
	flagged.resize(neighbors.size())
	adjacent_counts.resize(neighbors.size())
	new_game()


func new_game() -> void:
	mines.fill(0)
	revealed.fill(0)
	flagged.fill(0)
	adjacent_counts.fill(0)
	state = State.READY
	var candidates: Array[int] = []
	for index in range(neighbors.size()):
		candidates.append(index)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	for index in range(core_count):
		mines[candidates[index]] = 1
	_calculate_adjacent_counts()
	flags_changed.emit(0, core_count)
	state_changed.emit(state)
	board_changed.emit()


func reveal_face(face_index: int) -> void:
	if not _is_valid_face(face_index) or state in [State.WON, State.LOST]:
		return
	if flagged[face_index] == 1:
		return
	if revealed[face_index] == 1:
		_chord_face(face_index)
		return
	if state == State.READY:
		_move_first_core(face_index)
		state = State.PLAYING
		state_changed.emit(state)
		first_reveal.emit()
	if mines[face_index] == 1:
		revealed[face_index] = 1
		state = State.LOST
		_reveal_all_cores()
		state_changed.emit(state)
		board_changed.emit()
		return
	_expand_from(face_index)
	_check_win()
	board_changed.emit()


func toggle_flag(face_index: int) -> void:
	if not _is_valid_face(face_index) or revealed[face_index] == 1 \
			or state in [State.WON, State.LOST]:
		return
	flagged[face_index] = 0 if flagged[face_index] == 1 else 1
	flags_changed.emit(get_used_flags(), core_count)
	board_changed.emit()


func get_used_flags() -> int:
	var total := 0
	for value in flagged:
		total += int(value)
	return total


func get_neighbor_faces(face_index: int) -> PackedInt32Array:
	return neighbors[face_index] if _is_valid_face(face_index) else PackedInt32Array()


func _move_first_core(face_index: int) -> void:
	if mines[face_index] == 0:
		return
	for candidate in range(mines.size()):
		if candidate != face_index and mines[candidate] == 0:
			mines[face_index] = 0
			mines[candidate] = 1
			_calculate_adjacent_counts()
			return


func _calculate_adjacent_counts() -> void:
	adjacent_counts.fill(0)
	for face_index in range(neighbors.size()):
		var total := 0
		for neighbor in neighbors[face_index]:
			total += int(mines[neighbor])
		adjacent_counts[face_index] = total


func _expand_from(start_index: int) -> void:
	var pending: Array[int] = [start_index]
	var visited := {}
	while not pending.is_empty():
		var face_index: int = pending.pop_back()
		if visited.has(face_index):
			continue
		visited[face_index] = true
		if flagged[face_index] == 1 or revealed[face_index] == 1 \
				or mines[face_index] == 1:
			continue
		revealed[face_index] = 1
		if adjacent_counts[face_index] == 0:
			for neighbor in neighbors[face_index]:
				if not visited.has(neighbor):
					pending.append(neighbor)


func _chord_face(face_index: int) -> void:
	if adjacent_counts[face_index] <= 0:
		return
	var adjacent_flags := 0
	for neighbor in neighbors[face_index]:
		adjacent_flags += int(flagged[neighbor])
	if adjacent_flags != adjacent_counts[face_index]:
		return
	for neighbor in neighbors[face_index]:
		if (flagged[neighbor] == 1) != (mines[neighbor] == 1):
			return
	for neighbor in neighbors[face_index]:
		if flagged[neighbor] == 0 and revealed[neighbor] == 0:
			_expand_from(neighbor)
	_check_win()
	board_changed.emit()


func _check_win() -> void:
	for face_index in range(mines.size()):
		if mines[face_index] == 0 and revealed[face_index] == 0:
			return
	state = State.WON
	state_changed.emit(state)


func _reveal_all_cores() -> void:
	for face_index in range(mines.size()):
		if mines[face_index] == 1:
			revealed[face_index] = 1


func _is_valid_face(face_index: int) -> bool:
	return face_index >= 0 and face_index < neighbors.size()
