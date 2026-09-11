class_name SkyGraphBoardModel
extends RefCounted

signal board_changed
signal flags_changed(used_flags: int, max_flags: int)
signal state_changed(state: int)
signal first_reveal
signal breeze_assist_used(face_index: int, result: int, remaining_uses: int)
signal storm_guard_used(face_index: int, remaining_uses: int)
signal boss_eye_changed(face_index: int, eye_number: int, total_eyes: int)
signal boss_eye_hit(face_index: int, cleared_eyes: int, total_eyes: int)

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
var breeze_capacity := 0
var breeze_remaining := 0
var breeze_trigger_chance := 0.0
var pending_breeze_face := -1
var pending_breeze_result := -1
var storm_guard_capacity := 0
var storm_guard_remaining := 0
var storm_guard_trigger_chance := 0.0
var pending_storm_guard_face := -1
var boss_eye_total := 0
var boss_eyes_cleared := 0
var boss_eye_face := -1
var boss_eye_used_faces := {}
var _rng := RandomNumberGenerator.new()


func configure(
	face_neighbors: Array[PackedInt32Array],
	mine_count: int,
	breeze_uses: int = 0,
	breeze_chance: float = 0.0,
	storm_guard_uses: int = 0,
	storm_guard_chance: float = 0.0,
	boss_eye_count: int = 0
) -> void:
	neighbors = face_neighbors
	core_count = clampi(mine_count, 1, maxi(1, neighbors.size() - 1))
	breeze_capacity = breeze_uses if breeze_uses < 0 else maxi(0, breeze_uses)
	breeze_trigger_chance = clampf(breeze_chance, 0.0, 1.0)
	storm_guard_capacity = (
		storm_guard_uses
		if storm_guard_uses < 0
		else maxi(0, storm_guard_uses)
	)
	storm_guard_trigger_chance = clampf(storm_guard_chance, 0.0, 1.0)
	boss_eye_total = maxi(0, boss_eye_count)
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
	breeze_remaining = breeze_capacity
	pending_breeze_face = -1
	pending_breeze_result = -1
	storm_guard_remaining = storm_guard_capacity
	pending_storm_guard_face = -1
	boss_eyes_cleared = 0
	boss_eye_face = -1
	boss_eye_used_faces.clear()
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
	if boss_eye_total > 0:
		boss_eye_changed.emit(-1, 1, boss_eye_total)
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
		if _try_storm_guard(face_index):
			board_changed.emit()
			return
		revealed[face_index] = 1
		state = State.LOST
		_reveal_all_cores()
		state_changed.emit(state)
		board_changed.emit()
		return
	_expand_from(face_index)
	_ensure_boss_eye()
	_try_breeze_assist()
	if pending_breeze_face < 0:
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
	var hits_boss_eye := boss_eye_total > 0 and face_index == boss_eye_face
	for neighbor in neighbors[face_index]:
		if flagged[neighbor] == 0 and revealed[neighbor] == 0:
			_expand_from(neighbor)
	if hits_boss_eye:
		_hit_boss_eye(face_index)
	else:
		_ensure_boss_eye()
	if state != State.WON:
		_check_win()
	board_changed.emit()


func _try_storm_guard(face_index: int) -> bool:
	if pending_storm_guard_face >= 0 or storm_guard_remaining == 0 \
			or storm_guard_trigger_chance <= 0.0:
		return false
	if _rng.randf() >= storm_guard_trigger_chance:
		return false
	pending_storm_guard_face = face_index
	if storm_guard_remaining > 0:
		storm_guard_remaining -= 1
	storm_guard_used.emit(face_index, storm_guard_remaining)
	return true


func resolve_storm_guard() -> void:
	if pending_storm_guard_face < 0:
		return
	var face_index := pending_storm_guard_face
	pending_storm_guard_face = -1
	if revealed[face_index] == 0 and flagged[face_index] == 0:
		flagged[face_index] = 1
		flags_changed.emit(get_used_flags(), core_count)
	board_changed.emit()


func _try_breeze_assist() -> void:
	if pending_breeze_face >= 0 or breeze_remaining == 0 \
			or breeze_trigger_chance <= 0.0:
		return
	if _rng.randf() >= breeze_trigger_chance:
		return
	var candidates: Array[int] = []
	for face_index in range(revealed.size()):
		if revealed[face_index] == 0 and flagged[face_index] == 0:
			candidates.append(face_index)
	if candidates.is_empty():
		return
	var target_face := candidates[_rng.randi_range(0, candidates.size() - 1)]
	pending_breeze_face = target_face
	pending_breeze_result = 1 if mines[target_face] == 1 else 0
	if breeze_remaining > 0:
		breeze_remaining -= 1
	breeze_assist_used.emit(
		target_face,
		pending_breeze_result,
		breeze_remaining
	)


func resolve_breeze_assist() -> void:
	if pending_breeze_face < 0:
		return
	var target_face := pending_breeze_face
	var result := pending_breeze_result
	pending_breeze_face = -1
	pending_breeze_result = -1
	if result == 1:
		if revealed[target_face] == 0 and flagged[target_face] == 0:
			flagged[target_face] = 1
			flags_changed.emit(get_used_flags(), core_count)
	elif revealed[target_face] == 0 and flagged[target_face] == 0:
		_expand_from(target_face)
	_ensure_boss_eye()
	_check_win()
	board_changed.emit()


func _ensure_boss_eye() -> void:
	if boss_eye_total <= 0 or boss_eye_face >= 0 \
			or boss_eyes_cleared >= boss_eye_total \
			or state in [State.WON, State.LOST]:
		return
	var next_face := (
		_pick_first_boss_eye()
		if boss_eyes_cleared == 0
		else _pick_distant_boss_eye(3)
	)
	if next_face < 0 and boss_eyes_cleared > 0:
		next_face = _pick_distant_boss_eye(1)
	if next_face < 0:
		return
	boss_eye_face = next_face
	if revealed[boss_eye_face] == 0:
		revealed[boss_eye_face] = 1
	boss_eye_changed.emit(
		boss_eye_face,
		boss_eyes_cleared + 1,
		boss_eye_total
	)


func _pick_first_boss_eye() -> int:
	var preferred: Array[int] = []
	var fallback: Array[int] = []
	for face_index in range(revealed.size()):
		if revealed[face_index] == 0 or adjacent_counts[face_index] <= 0 \
				or boss_eye_used_faces.has(face_index):
			continue
		fallback.append(face_index)
		for neighbor in neighbors[face_index]:
			if revealed[neighbor] == 0 and flagged[neighbor] == 0:
				preferred.append(face_index)
				break
	var candidates := preferred if not preferred.is_empty() else fallback
	if candidates.is_empty():
		return -1
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _pick_distant_boss_eye(minimum_hidden_neighbors: int) -> int:
	var distance_maps: Array[PackedInt32Array] = []
	for used_face in boss_eye_used_faces.keys():
		distance_maps.append(_graph_distances_from(int(used_face)))
	var best_score := -INF
	var best_faces: Array[int] = []
	for face_index in range(revealed.size()):
		if mines[face_index] == 1 or flagged[face_index] == 1 \
				or adjacent_counts[face_index] <= 0 \
				or boss_eye_used_faces.has(face_index):
			continue
		var hidden_neighbors := 0
		for neighbor in neighbors[face_index]:
			if revealed[neighbor] == 0 and flagged[neighbor] == 0:
				hidden_neighbors += 1
		if hidden_neighbors < minimum_hidden_neighbors:
			continue
		var distance_from_previous := neighbors.size()
		for distances in distance_maps:
			distance_from_previous = mini(
				distance_from_previous,
				distances[face_index]
			)
		var score := (
			float(distance_from_previous) * 100.0
			+ float(hidden_neighbors) * 8.0
			+ (25.0 if revealed[face_index] == 0 else 0.0)
		)
		if score > best_score + 0.01:
			best_score = score
			best_faces = [face_index]
		elif absf(score - best_score) <= 0.01:
			best_faces.append(face_index)
	if best_faces.is_empty():
		return -1
	return best_faces[_rng.randi_range(0, best_faces.size() - 1)]


func _graph_distances_from(start_face: int) -> PackedInt32Array:
	var distances := PackedInt32Array()
	distances.resize(neighbors.size())
	distances.fill(-1)
	distances[start_face] = 0
	var pending: Array[int] = [start_face]
	var cursor := 0
	while cursor < pending.size():
		var face_index := pending[cursor]
		cursor += 1
		for neighbor in neighbors[face_index]:
			if distances[neighbor] >= 0:
				continue
			distances[neighbor] = distances[face_index] + 1
			pending.append(neighbor)
	return distances


func _hit_boss_eye(face_index: int) -> void:
	boss_eye_used_faces[face_index] = true
	boss_eyes_cleared += 1
	boss_eye_face = -1
	boss_eye_hit.emit(face_index, boss_eyes_cleared, boss_eye_total)
	if boss_eyes_cleared >= boss_eye_total:
		state = State.WON
		state_changed.emit(state)
		return
	_ensure_boss_eye()


func _check_win() -> void:
	if boss_eye_total > 0:
		if boss_eyes_cleared < boss_eye_total:
			return
		if state != State.WON:
			state = State.WON
			state_changed.emit(state)
		return
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
