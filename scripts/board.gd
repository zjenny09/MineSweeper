class_name MinesweeperBoard
extends Control

signal state_changed(state: int)
signal flags_changed(used_flags: int, max_flags: int)
signal reveal_completed(cell_index: int, newly_revealed_count: int)
signal flag_completed(cell_index: int, is_flagged: bool, is_first_placement: bool)
signal chord_completed(cell_index: int, newly_revealed_count: int)
signal scan_target_requested(cell_index: int)
signal scan_cancel_requested
signal scan_completed(cell_index: int, result: int, newly_revealed_count: int)
signal pollution_nodes_changed(cleansed_count: int, total_count: int)
signal tidal_zone_changed(active_zone_index: int, zone_count: int)

const ART := preload("res://scripts/art_catalog.gd")
const OCEAN_REEF_STRIP_FULL_PATH := ART.OCEAN_REEF_STRIP_FULL
const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")
const BOSS_TREE_ACTIVE_PATH := ART.LEVEL_05_BOSS_TREE_ACTIVE
const BOSS_TREE_CLEANSED_PATH := ART.LEVEL_05_BOSS_TREE_CLEANSED
const LEVEL_ONE_BOARD_SIZE := Vector2(620.0, 587.0)
const LEVEL_ONE_CELL_SLOT_FILL := 0.98
const LAND_BOARD_PAPER_MARGIN := 28.0
const LAND_BOARD_PAPER_COLOR := Color(0.94, 0.91, 0.80, 1.0)
const LAND_BOARD_PAPER_EDGE := Color(0.25, 0.43, 0.24, 0.38)
const LAND_BOARD_CREASE_LIGHT := Color(1.0, 0.98, 0.90, 0.58)
const LAND_BOARD_CREASE_GREEN := Color(0.18, 0.38, 0.19, 0.42)
const LEVEL_ONE_CELL_ROTATIONS := [
	-0.9, 0.35, -0.45, 0.70, -0.25,
	0.45, -0.55, 0.20, -0.75, 0.55,
	-0.30, 0.65, -0.15, 0.35, -0.60,
	0.70, -0.20, 0.50, -0.40, 0.20,
	-0.55, 0.30, -0.70, 0.55, -0.15,
]
const LEVEL_ONE_CELL_OFFSETS := [
	Vector2(-0.010, -0.006), Vector2(0.004, 0.006), Vector2(-0.004, -0.002), Vector2(0.007, 0.004), Vector2(-0.005, -0.006),
	Vector2(0.006, 0.002), Vector2(-0.007, 0.005), Vector2(0.003, -0.004), Vector2(-0.006, 0.003), Vector2(0.006, -0.002),
	Vector2(-0.003, 0.005), Vector2(0.006, -0.003), Vector2.ZERO, Vector2(-0.004, 0.004), Vector2(0.005, -0.005),
	Vector2(0.005, -0.003), Vector2(-0.006, 0.002), Vector2(0.004, 0.005), Vector2(-0.005, -0.004), Vector2(0.003, 0.003),
	Vector2(-0.006, 0.004), Vector2(0.004, -0.005), Vector2(-0.003, 0.003), Vector2(0.006, -0.002), Vector2(-0.004, -0.004),
]
const POLLUTION_STEP_DELAY := 0.22
const POLLUTION_CELL_DURATION := 0.95
const HEX_TOPOLOGY := &"hex_pointy_odd_r"
const HEX_HORIZONTAL_FACTOR := 1.7320508
const HEX_CELL_FILL := 0.94
const OCEAN_REEF_CELL_FILL := 0.84
const OCEAN_REEF_GAP_FACTOR := 0.60
const OCEAN_CURRENT_WASH_COLOR := Color(0.52, 0.78, 0.80, 0.38)
const OCEAN_CURRENT_INK_COLOR := Color(0.16, 0.46, 0.54, 0.62)
const OCEAN_CURRENT_OFFSET_FACTOR := 0.18
const OCEAN_REEF_BASE_COLOR := Color("8d785d")
const OCEAN_REEF_SAND_COLOR := Color("ead3a2")
const OCEAN_REEF_CORAL_COLOR := Color("d46d63")
const OCEAN_REEF_HIGHLIGHT_COLOR := Color("f2af78")
const OBSTACLE_NORTH := 1
const OBSTACLE_EAST := 2
const OBSTACLE_SOUTH := 4
const OBSTACLE_WEST := 8
const LEVEL_FOUR_OBSTACLE_SHAPES := [
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)],
]
const BOSS_OBSTACLE_SHAPES := [
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
]
const BOSS_TREE_GRID_SIZE := 3
const OCEAN_BOARD_PAPER_SAFE_RECT := Rect2(76.0, 36.0, 472.0, 428.0)
const OCEAN_BOARD_PAPER_MARGIN := Vector2(16.0, 18.0)
const OCEAN_BOARD_PAPER_MIN_SIZE := Vector2(456.0, 410.0)
const OCEAN_BOARD_PAPER_COLOR := Color(0.973, 0.956, 0.851, 1.0)
const OCEAN_BOARD_PAPER_EDGE := Color(0.35, 0.66, 0.72, 0.62)
const OCEAN_BOARD_CREASE_COLOR := Color(0.36, 0.72, 0.80, 0.70)
const OCEAN_BOARD_CORNER_CUT := 12.0


enum OperationMode {
	MOUSE,
	KEYBOARD,
}


enum OpeningAssist {
	NONE,
	SAFE_FIRST,
	OPEN_REGION,
}


enum GameState {
	READY,
	PLAYING,
	WON,
	LOST,
}


enum ScanResult {
	SAFE,
	MINE,
}

var level_number := 0
var level_name := ""
var row_count := 0
var column_count := 0
var core_count := 0
var cell_count := 0
var safe_cell_count := 0
var obstacle_count := 0
var pollution_node_count := 0
var pollution_node_cell_count := 0
var cleansed_pollution_node_count := 0
var _obstacle_cluster_count := 0
var _random_pollution_node_count := 0
var _extra_obstacle_count := 0
var boss_level := false
var topology: StringName = &"square"
var first_move_guide_enabled := false
var guide_cell_index := -1

var game_state: int = GameState.READY
var used_flags := 0
var revealed_safe_count := 0
var move_count := 0
var reveal_action_count := 0
var opening_assist_mode: int = OpeningAssist.NONE
var interaction_enabled := true
var operation_mode: int = OperationMode.MOUSE
var keyboard_cell_index := -1
var scan_target_mode := false
var pollution_tint_progress := 0.0
var ocean_hex_bounds := Rect2()
var ocean_paper_rect := Rect2()
var ocean_shared_edge_count := 0
var reef_edge_count := 0
var active_tidal_zone_index := 0
var tidal_zone_count := 0
var _pollution_animation_active := false
var _pollution_elapsed := 0.0
var _pollution_origin_index := -1

var mines: Array[bool] = []
var obstacles: Array[bool] = []
var boss_tree_cells: Array[bool] = []
var pollution_nodes: Array[bool] = []
var pollution_node_groups: Array[int] = []
var pollution_node_group_cleansed: Array[bool] = []
var pollution_nodes_cleansed: Array[bool] = []
var revealed: Array[bool] = []
var flagged: Array[bool] = []
var ever_flagged: Array[bool] = []
var confirmed: Array[bool] = []
var adjacent_counts: Array[int] = []
var number_neighbor_indices: Array[PackedInt32Array] = []
var tidal_zone_indices: Array[int] = []
var cell_nodes: Array[MineCell] = []

var reef_edges: Dictionary = {}
var reef_dividers: Array[int] = []
var reef_segments: Array[Dictionary] = []
var current_paths: Array = []
var current_path_mine_totals: Array[int] = []
var _random := RandomNumberGenerator.new()
var _loaded_level_data: Dictionary = {}
var _handmade_surface: Control
var _boss_tree_overlay: TextureRect
var _ocean_reef_texture: Texture2D
var _reef_line_nodes: Array[Line2D] = []
var _current_line_nodes: Array[Dictionary] = []
var _current_arrow_nodes: Array[Polygon2D] = []
var _ocean_shared_edges: Array[PackedVector2Array] = []


func _ready() -> void:
	_random.randomize()
	_ocean_reef_texture = load(OCEAN_REEF_STRIP_FULL_PATH) as Texture2D
	resized.connect(_layout_cells)
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
		if scan_target_mode:
			scan_target_requested.emit(keyboard_cell_index)
		else:
			_keyboard_primary_action()
		get_viewport().set_input_as_handled()
	elif action_key == KEY_X:
		if scan_target_mode:
			scan_cancel_requested.emit()
		else:
			toggle_flag(keyboard_cell_index)
		get_viewport().set_input_as_handled()


func load_level(level: Dictionary) -> void:
	_loaded_level_data = level.duplicate(true)
	level_number = level.number
	level_name = level.name
	var board_size: Vector2i = level.size
	column_count = board_size.x
	row_count = board_size.y
	cell_count = row_count * column_count
	core_count = level.core_count
	topology = StringName(level.get("topology", &"square"))
	boss_level = bool(level.get("boss", false))
	_extra_obstacle_count = int(level.get("extra_obstacle_count", 0))
	_configure_ocean_mechanics(level)
	_configure_pollution_nodes(level)
	_configure_obstacles(level)
	safe_cell_count = (
		cell_count
		- core_count
		- obstacle_count
		- pollution_node_cell_count
	)
	first_move_guide_enabled = level.get("first_move_guide", false)

	_clear_cells()
	_create_cells()
	new_game(false)


func _configure_ocean_mechanics(level: Dictionary) -> void:
	reef_edges.clear()
	reef_dividers.clear()
	reef_segments.clear()
	current_paths.clear()
	current_path_mine_totals.clear()
	reef_edge_count = 0
	active_tidal_zone_index = 0
	tidal_zone_count = 0
	_reset_array(tidal_zone_indices, 0)
	var reef_layout := _randomized_reef_segments(level.get("reef_segments", []))
	_configure_reef_segments(reef_layout)
	_append_reef_edges(level.get("reef_edges", []))
	reef_edge_count = reef_edges.size()
	_configure_tidal_zones(level.get("tidal_zones", []))
	var current_layout := _randomized_current_paths(level.get("current_paths", []))
	_configure_current_paths(current_layout)
	_rebuild_number_neighbor_graph()


func _randomized_reef_segments(value: Variant) -> Array:
	if topology != HEX_TOPOLOGY or not value is Array:
		return []
	var randomized_segments: Array = []
	for segment_value in value:
		if not segment_value is Dictionary:
			continue
		var segment: Dictionary = segment_value
		var base_start := int(segment.get("start_row", 1))
		var base_end := int(segment.get("end_row", base_start + 2))
		var maximum_length := maxi(2, row_count - 2)
		var segment_length := clampi(
			base_end - base_start + 1 + _random.randi_range(-1, 1),
			2,
			maximum_length
		)
		var maximum_start := maxi(1, row_count - segment_length - 1)
		var start_row := clampi(
			base_start + _random.randi_range(-1, 1),
			1,
			maximum_start
		)
		var minimum_divider := 1 if column_count >= 5 else 0
		var maximum_divider := maxi(minimum_divider, column_count - 3)
		var divider_column := clampi(
			int(segment.get("divider", minimum_divider)) + _random.randi_range(-1, 1),
			minimum_divider,
			maximum_divider
		)
		randomized_segments.append({
			"divider": divider_column,
			"start_row": start_row,
			"end_row": start_row + segment_length - 1,
		})
	return randomized_segments


func _randomized_current_paths(value: Variant) -> Array:
	if topology != HEX_TOPOLOGY or not value is Array:
		return []
	var source_paths: Array = value
	var randomized_paths: Array = []
	var occupied_cells: Dictionary = {}
	var blocked_path_index := -1
	if not reef_segments.is_empty() and not source_paths.is_empty() and _random.randf() < 0.72:
		blocked_path_index = _random.randi_range(0, source_paths.size() - 1)
	for path_index in source_paths.size():
		var source_sequence := _extract_coordinate_sequence(source_paths[path_index])
		if source_sequence.is_empty():
			continue
		var generated_path: Array = []
		for _attempt in 6:
			generated_path = _build_random_current_path(
				source_sequence,
				path_index,
				path_index == blocked_path_index,
				occupied_cells
			)
			if _coordinate_sequence_has_turn(generated_path):
				break
		if not _coordinate_sequence_has_turn(generated_path):
			continue
		randomized_paths.append(generated_path)
		for coordinate_value in generated_path:
			var cell_index := _coordinate_to_index(coordinate_value)
			if cell_index >= 0:
				occupied_cells[cell_index] = true
	return randomized_paths


func _build_random_current_path(
	source_sequence: Array,
	_path_index: int,
	allow_reef_collision: bool,
	occupied_cells: Dictionary
) -> Array:
	var source_start_index := _coordinate_to_index(source_sequence[0])
	var tidal_zone_index := (
		tidal_zone_indices[source_start_index]
		if source_start_index >= 0 and tidal_zone_count > 0
		else 0
	)
	var minimum_row := 0
	var maximum_row := row_count - 1
	if tidal_zone_count > 0:
		minimum_row = row_count - 1
		maximum_row = 0
		for cell_index in cell_count:
			if tidal_zone_indices[cell_index] != tidal_zone_index:
				continue
			var row := int(cell_index / column_count)
			minimum_row = mini(minimum_row, row)
			maximum_row = maxi(maximum_row, row)

	var reachable_reefs: Array[Dictionary] = []
	for segment_value in reef_segments:
		var segment: Dictionary = segment_value
		if (
			int(segment["end_row"]) >= minimum_row
			and int(segment["start_row"]) <= maximum_row
		):
			reachable_reefs.append(segment)
	var collide_with_reef := (
		allow_reef_collision
		and not reachable_reefs.is_empty()
	)
	var direction := 1 if _random.randi_range(0, 1) == 0 else -1
	var start_column := 0 if direction > 0 else column_count - 1
	var target_column := column_count - 1 if direction > 0 else 0
	var target_row := _random.randi_range(minimum_row, maximum_row)

	if collide_with_reef:
		var reef: Dictionary = reachable_reefs[
			_random.randi_range(0, reachable_reefs.size() - 1)
		]
		var divider_column := int(reef["divider"])
		var left_capacity := divider_column + 1
		var right_capacity := column_count - divider_column - 1
		if left_capacity < 3 and right_capacity >= 3:
			direction = -1
		elif right_capacity < 3 and left_capacity >= 3:
			direction = 1
		var available_prefix := left_capacity if direction > 0 else right_capacity
		var prefix_length := _random.randi_range(3, mini(6, available_prefix))
		start_column = (
			divider_column - prefix_length + 1
			if direction > 0
			else divider_column + prefix_length
		)
		target_column = divider_column + 1 if direction > 0 else divider_column
		var reef_minimum_row := maxi(minimum_row, int(reef["start_row"]))
		var reef_maximum_row := mini(maximum_row, int(reef["end_row"]))
		target_row = _random.randi_range(reef_minimum_row, reef_maximum_row)

	var start_row := clampi(
		target_row + _random.randi_range(-1, 1),
		minimum_row,
		maximum_row
	)
	var current_index := start_row * column_count + start_column
	var path: Array = [Vector2i(start_column, start_row)]
	var visited_cells: Dictionary = {current_index: true}
	var first_side := -1
	var maximum_steps := column_count * 3
	for step_index in maximum_steps:
		var candidate_records: Array = []
		var best_score := INF
		for record in _get_raw_hex_neighbor_records(current_index):
			var candidate_index := int(record["index"])
			if visited_cells.has(candidate_index) or occupied_cells.has(candidate_index):
				continue
			if tidal_zone_count > 0 and tidal_zone_indices[candidate_index] != tidal_zone_index:
				continue
			var current_column := current_index % column_count
			var current_row := int(current_index / column_count)
			var candidate_column := candidate_index % column_count
			var candidate_row := int(candidate_index / column_count)
			if (candidate_column - current_column) * direction < 0:
				continue
			if step_index == 0 and candidate_row == current_row:
				continue
			if step_index == 1 and int(record["side"]) == first_side:
				continue
			var crosses_reef := _has_reef_edge(current_index, candidate_index)
			if crosses_reef and not collide_with_reef:
				continue
			if crosses_reef and path.size() < 3:
				continue
			var score := (
				absf(float(target_column - candidate_column)) * 3.0
				+ absf(float(target_row - candidate_row)) * 1.7
				+ _random.randf_range(0.0, 1.8)
			)
			if score < best_score - 0.35:
				best_score = score
				candidate_records = [record]
			elif absf(score - best_score) <= 0.35:
				candidate_records.append(record)
		if candidate_records.is_empty():
			break
		var selected_record: Dictionary = candidate_records[
			_random.randi_range(0, candidate_records.size() - 1)
		]
		if step_index == 0:
			first_side = int(selected_record["side"])
		var next_index := int(selected_record["index"])
		path.append(Vector2i(next_index % column_count, int(next_index / column_count)))
		visited_cells[next_index] = true
		if _has_reef_edge(current_index, next_index):
			break
		current_index = next_index
		if current_index % column_count == target_column:
			break
	return path


func _coordinate_sequence_has_turn(sequence: Array) -> bool:
	var connected_run: Array[int] = []
	for coordinate_value in sequence:
		var cell_index := _coordinate_to_index(coordinate_value)
		if cell_index < 0:
			break
		if connected_run.is_empty():
			connected_run.append(cell_index)
			continue
		var previous_index: int = connected_run.back()
		if (
			_get_hex_side_between(previous_index, cell_index) < 0
			or _has_reef_edge(previous_index, cell_index)
		):
			break
		connected_run.append(cell_index)
	return _current_run_has_turn(connected_run)


func _coordinate_to_index(value: Variant) -> int:
	var coordinate := Vector2i(-1, -1)
	match typeof(value):
		TYPE_VECTOR2I:
			coordinate = value
		TYPE_VECTOR2:
			var vector_value: Vector2 = value
			coordinate = Vector2i(roundi(vector_value.x), roundi(vector_value.y))
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() >= 2 and (
				typeof(array_value[0]) in [TYPE_INT, TYPE_FLOAT]
				and typeof(array_value[1]) in [TYPE_INT, TYPE_FLOAT]
			):
				coordinate = Vector2i(int(array_value[0]), int(array_value[1]))
		TYPE_DICTIONARY:
			var dictionary_value: Dictionary = value
			for nested_key in ["position", "coordinate", "coord", "cell"]:
				if dictionary_value.has(nested_key):
					return _coordinate_to_index(dictionary_value[nested_key])
			if dictionary_value.has("x") and dictionary_value.has("y"):
				coordinate = Vector2i(
					int(dictionary_value["x"]),
					int(dictionary_value["y"])
				)
			elif dictionary_value.has("column") and dictionary_value.has("row"):
				coordinate = Vector2i(
					int(dictionary_value["column"]),
					int(dictionary_value["row"])
				)
			elif dictionary_value.has("col") and dictionary_value.has("row"):
				coordinate = Vector2i(
					int(dictionary_value["col"]),
					int(dictionary_value["row"])
				)
	if (
		coordinate.x < 0
		or coordinate.x >= column_count
		or coordinate.y < 0
		or coordinate.y >= row_count
	):
		return -1
	return coordinate.y * column_count + coordinate.x


func _configure_reef_segments(value: Variant) -> void:
	if not value is Array:
		return
	for segment_value in value:
		if not segment_value is Dictionary:
			continue
		var segment: Dictionary = segment_value
		var divider_column := int(segment.get("divider", -1))
		var start_row := clampi(int(segment.get("start_row", 0)), 0, row_count - 1)
		var end_row := clampi(
			int(segment.get("end_row", row_count - 1)),
			0,
			row_count - 1
		)
		if divider_column < 0 or divider_column >= column_count - 1:
			continue
		if start_row > end_row:
			var swap_row := start_row
			start_row = end_row
			end_row = swap_row
		reef_segments.append({
			"divider": divider_column,
			"start_row": start_row,
			"end_row": end_row,
		})
		if not reef_dividers.has(divider_column):
			reef_dividers.append(divider_column)
	reef_dividers.sort()
	for cell_index in cell_count:
		for record in _get_raw_hex_neighbor_records(cell_index):
			var neighbor_index := int(record["index"])
			if neighbor_index <= cell_index:
				continue
			for segment in reef_segments:
				if _edge_crosses_reef_segment(cell_index, neighbor_index, segment):
					reef_edges[_cell_pair_key(cell_index, neighbor_index)] = true
					break


func _edge_crosses_reef_segment(
	first_index: int,
	second_index: int,
	segment: Dictionary
) -> bool:
	var first_column := first_index % column_count
	var second_column := second_index % column_count
	var divider_column := int(segment["divider"])
	var crosses_divider := (
		(first_column <= divider_column and second_column > divider_column)
		or (second_column <= divider_column and first_column > divider_column)
	)
	if not crosses_divider:
		return false
	var first_row := int(first_index / column_count)
	var second_row := int(second_index / column_count)
	var edge_row := (float(first_row) + float(second_row)) * 0.5
	return (
		edge_row >= float(segment["start_row"])
		and edge_row <= float(segment["end_row"])
	)


func _crosses_reef_divider(first_index: int, second_index: int) -> bool:
	var first_column := first_index % column_count
	var second_column := second_index % column_count
	for divider_column in reef_dividers:
		if (
			(first_column <= divider_column and second_column > divider_column)
			or (second_column <= divider_column and first_column > divider_column)
		):
			return true
	return false


func _reef_expansion_boundary_pairs() -> Array:
	var boundary_pairs: Array = []
	for segment in reef_segments:
		var divider_column := int(segment["divider"])
		for boundary_row in [
			int(segment["start_row"]) - 1,
			int(segment["end_row"]) + 1,
		]:
			if boundary_row < 0 or boundary_row >= row_count:
				continue
			boundary_pairs.append([
				boundary_row * column_count + divider_column,
				boundary_row * column_count + divider_column + 1,
			])
	return boundary_pairs


func _reef_boundary_pair_for_cell(cell_index: int) -> Array[int]:
	for pair_value in _reef_expansion_boundary_pairs():
		var pair: Array = pair_value
		if pair.has(cell_index):
			return [int(pair[0]), int(pair[1])]
	return []


func _is_near_reef_expansion_boundary(cell_index: int) -> bool:
	for pair_value in _reef_expansion_boundary_pairs():
		var pair: Array = pair_value
		for boundary_cell_value in pair:
			var boundary_cell := int(boundary_cell_value)
			if boundary_cell == cell_index:
				return true
			if _get_hex_neighbors(boundary_cell).has(cell_index):
				return true
	return false


func _append_reef_edges(value: Variant) -> void:
	if value is Dictionary:
		var edge: Dictionary = value
		var endpoints: Array = []
		for pair in [
			["from", "to"],
			["start", "end"],
			["a", "b"],
			["cell_a", "cell_b"],
		]:
			if edge.has(pair[0]) and edge.has(pair[1]):
				endpoints = [edge[pair[0]], edge[pair[1]]]
				break
		if endpoints.is_empty():
			for list_key in ["cells", "edge", "coordinates", "points"]:
				if edge.has(list_key) and edge[list_key] is Array:
					var endpoint_values: Array = edge[list_key]
					if endpoint_values.size() == 2:
						endpoints = endpoint_values
					break
		if not endpoints.is_empty():
			_register_reef_edge(endpoints[0], endpoints[1])
			return
		for key in edge:
			var start_index := _coordinate_to_index(key)
			var target_value: Variant = edge[key]
			if start_index >= 0:
				if _coordinate_to_index(target_value) >= 0:
					_register_reef_edge(key, target_value)
				elif target_value is Array:
					for target in target_value:
						_register_reef_edge(key, target)
			else:
				_append_reef_edges(target_value)
		return
	if not value is Array:
		return
	var entries: Array = value
	if entries.size() == 2 \
			and _coordinate_to_index(entries[0]) >= 0 \
			and _coordinate_to_index(entries[1]) >= 0:
		_register_reef_edge(entries[0], entries[1])
		return
	for entry in entries:
		_append_reef_edges(entry)


func _register_reef_edge(start_value: Variant, end_value: Variant) -> void:
	var start_index := _coordinate_to_index(start_value)
	var end_index := _coordinate_to_index(end_value)
	if (
		start_index < 0
		or end_index < 0
		or start_index == end_index
		or _get_hex_side_between(start_index, end_index) < 0
	):
		return
	reef_edges[_cell_pair_key(start_index, end_index)] = true


func _configure_current_paths(value: Variant) -> void:
	if value is Dictionary:
		var paths_dictionary: Dictionary = value
		for container_key in ["paths", "currents"]:
			if paths_dictionary.has(container_key):
				_configure_current_paths(paths_dictionary[container_key])
				return
		var sequence := _extract_coordinate_sequence(paths_dictionary)
		if not sequence.is_empty():
			_append_current_path(sequence)
			return
		for path_value in paths_dictionary.values():
			_configure_current_paths(path_value)
		return
	if not value is Array:
		return
	var path_values: Array = value
	var is_single_path := not path_values.is_empty()
	for path_value in path_values:
		if _coordinate_to_index(path_value) < 0:
			is_single_path = false
			break
	if is_single_path:
		_append_current_path(path_values)
		return
	for path_value in path_values:
		_append_current_path(_extract_coordinate_sequence(path_value))


func _extract_coordinate_sequence(value: Variant) -> Array:
	if value is Array:
		return value
	if not value is Dictionary:
		return []
	var path: Dictionary = value
	for list_key in ["cells", "path", "points", "coordinates"]:
		if path.has(list_key) and path[list_key] is Array:
			return path[list_key]
	for pair in [["from", "to"], ["start", "end"]]:
		if path.has(pair[0]) and path.has(pair[1]):
			return [path[pair[0]], path[pair[1]]]
	return []


func _append_current_path(sequence: Array) -> void:
	var connected_run: Array[int] = []
	for coordinate_value in sequence:
		var cell_index := _coordinate_to_index(coordinate_value)
		if cell_index < 0:
			_commit_current_run(connected_run)
			connected_run = []
			continue
		if connected_run.is_empty():
			connected_run.append(cell_index)
			continue
		var previous_index: int = connected_run.back()
		if cell_index == previous_index:
			continue
		if _get_hex_side_between(previous_index, cell_index) < 0:
			_commit_current_run(connected_run)
			return
		if _has_reef_edge(previous_index, cell_index):
			_commit_current_run(connected_run)
			return
		connected_run.append(cell_index)
	_commit_current_run(connected_run)


func _commit_current_run(connected_run: Array[int]) -> void:
	if connected_run.size() < 3 or not _current_run_has_turn(connected_run):
		return
	current_paths.append(connected_run.duplicate())
	current_path_mine_totals.append(0)


func _current_run_has_turn(connected_run: Array[int]) -> bool:
	if connected_run.size() < 3:
		return false
	var first_side := _get_hex_side_between(connected_run[0], connected_run[1])
	for position in range(2, connected_run.size()):
		var side := _get_hex_side_between(
			connected_run[position - 1],
			connected_run[position]
		)
		if side >= 0 and side != first_side:
			return true
	return false


func _configure_tidal_zones(value: Variant) -> void:
	if value is Dictionary:
		var zones_dictionary: Dictionary = value
		if zones_dictionary.has("zones"):
			_configure_tidal_zones(zones_dictionary["zones"])
			return
		if (
			(zones_dictionary.has("origin") and zones_dictionary.has("size"))
			or zones_dictionary.has("cells")
		):
			_assign_tidal_zone_entries([zones_dictionary])
			return
		var coordinate_map := not zones_dictionary.is_empty()
		var highest_zone := -1
		for key in zones_dictionary:
			var cell_index := _coordinate_to_index(key)
			var zone_value: Variant = zones_dictionary[key]
			if cell_index < 0 or typeof(zone_value) not in [TYPE_INT, TYPE_FLOAT]:
				coordinate_map = false
				break
			highest_zone = maxi(highest_zone, int(zone_value))
		if coordinate_map:
			tidal_zone_count = highest_zone + 1
			for key in zones_dictionary:
				var cell_index := _coordinate_to_index(key)
				tidal_zone_indices[cell_index] = maxi(0, int(zones_dictionary[key]))
			return
		var ordered_keys: Array = zones_dictionary.keys()
		ordered_keys.sort()
		var ordered_zones: Array = []
		for key in ordered_keys:
			ordered_zones.append(zones_dictionary[key])
		_assign_tidal_zone_entries(ordered_zones)
		return
	if not value is Array:
		return
	var zones: Array = value
	var is_single_zone := not zones.is_empty()
	for zone_value in zones:
		if _coordinate_to_index(zone_value) < 0:
			is_single_zone = false
			break
	_assign_tidal_zone_entries([zones] if is_single_zone else zones)


func _assign_tidal_zone_entries(zones: Array) -> void:
	tidal_zone_count = zones.size()
	for zone_index in zones.size():
		var zone_cells := _extract_zone_cells(zones[zone_index])
		for coordinate_value in zone_cells:
			var cell_index := _coordinate_to_index(coordinate_value)
			if cell_index >= 0:
				tidal_zone_indices[cell_index] = zone_index


func _extract_zone_cells(value: Variant) -> Array:
	if value is Array:
		return value
	if not value is Dictionary:
		return []
	var zone: Dictionary = value
	for list_key in ["cells", "coordinates", "points", "area"]:
		if zone.has(list_key) and zone[list_key] is Array:
			return zone[list_key]
	if zone.has("origin") and zone.has("size"):
		var origin_index := _coordinate_to_index(zone["origin"])
		var size_value: Variant = zone["size"]
		var zone_size := Vector2i.ZERO
		if typeof(size_value) == TYPE_VECTOR2I:
			zone_size = size_value
		elif typeof(size_value) == TYPE_VECTOR2:
			var vector_size: Vector2 = size_value
			zone_size = Vector2i(roundi(vector_size.x), roundi(vector_size.y))
		elif size_value is Array and size_value.size() >= 2:
			zone_size = Vector2i(int(size_value[0]), int(size_value[1]))
		elif size_value is Dictionary:
			var size_dictionary: Dictionary = size_value
			if size_dictionary.has("x") and size_dictionary.has("y"):
				zone_size = Vector2i(int(size_dictionary["x"]), int(size_dictionary["y"]))
		if origin_index >= 0 and zone_size.x > 0 and zone_size.y > 0:
			var origin := Vector2i(origin_index % column_count, int(origin_index / column_count))
			var cells: Array[Vector2i] = []
			for row in range(origin.y, mini(row_count, origin.y + zone_size.y)):
				for column in range(origin.x, mini(column_count, origin.x + zone_size.x)):
					cells.append(Vector2i(column, row))
			return cells
	return []


func _cell_pair_key(first_index: int, second_index: int) -> String:
	return "%d:%d" % [
		mini(first_index, second_index),
		maxi(first_index, second_index),
	]


func _has_reef_edge(first_index: int, second_index: int) -> bool:
	if reef_edges.has(_cell_pair_key(first_index, second_index)):
		return true
	if topology != HEX_TOPOLOGY:
		return false
	for segment in reef_segments:
		if _edge_crosses_reef_segment(first_index, second_index, segment):
			return true
	return false


func _cell_touches_reef(cell_index: int) -> bool:
	for record in _get_raw_hex_neighbor_records(cell_index):
		if _has_reef_edge(cell_index, int(record["index"])):
			return true
	return false


func _configure_obstacles(level: Dictionary) -> void:
	_reset_array(obstacles, false)
	_reset_array(boss_tree_cells, false)
	obstacle_count = 0
	_obstacle_cluster_count = int(level.get("obstacle_cluster_count", 0))
	if boss_level and topology != HEX_TOPOLOGY:
		_configure_boss_obstacles()
		return
	if _obstacle_cluster_count > 0:
		_randomize_obstacle_clusters()
		return
	var obstacle_values: Array = level.get("obstacles", [])
	if level_number == 3:
		var layout_key := "obstacles_four"
		if OS.get_cmdline_user_args().has("--obstacles=3"):
			layout_key = "obstacles_three"
		obstacle_values = level.get(layout_key, [])
	for value in obstacle_values:
		var obstacle_index := int(value)
		if (
			not _is_valid_index(obstacle_index)
			or pollution_nodes[obstacle_index]
			or obstacles[obstacle_index]
		):
			continue
		obstacles[obstacle_index] = true
		obstacle_count += 1


func _configure_boss_obstacles() -> void:
	_reset_array(obstacles, false)
	_reset_array(boss_tree_cells, false)
	var tree_start_row := int((row_count - BOSS_TREE_GRID_SIZE) / 2)
	var tree_start_column := int((column_count - BOSS_TREE_GRID_SIZE) / 2)
	for row_offset in BOSS_TREE_GRID_SIZE:
		for column_offset in BOSS_TREE_GRID_SIZE:
			var tree_index := (
				(tree_start_row + row_offset) * column_count
				+ tree_start_column
				+ column_offset
			)
			boss_tree_cells[tree_index] = true
			obstacles[tree_index] = true

	var placed_cluster_count := 0
	for cluster_index in _obstacle_cluster_count:
		if not _try_place_obstacle_cluster():
			break
		placed_cluster_count += 1
	obstacle_count = obstacles.count(true)
	assert(
		placed_cluster_count == _obstacle_cluster_count,
		"The boss board needs two L-shaped obstacle clusters."
	)


func _touches_boss_tree(cell_index: int) -> bool:
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			var nearby_row := row + row_offset
			var nearby_column := column + column_offset
			if (
				nearby_row < 0
				or nearby_row >= row_count
				or nearby_column < 0
				or nearby_column >= column_count
			):
				continue
			if boss_tree_cells[nearby_row * column_count + nearby_column]:
				return true
	return false


func _touches_pollution_node(cell_index: int) -> bool:
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			var nearby_row := row + row_offset
			var nearby_column := column + column_offset
			if (
				nearby_row < 0
				or nearby_row >= row_count
				or nearby_column < 0
				or nearby_column >= column_count
			):
				continue
			if pollution_nodes[nearby_row * column_count + nearby_column]:
				return true
	return false


func _randomize_obstacle_clusters() -> void:
	for layout_attempt in 96:
		_reset_array(obstacles, false)
		var placed_cluster_count := 0
		for cluster_index in _obstacle_cluster_count:
			if not _try_place_obstacle_cluster():
				break
			placed_cluster_count += 1
		if (
			placed_cluster_count == _obstacle_cluster_count
			and _pollution_nodes_have_space()
		):
			obstacle_count = obstacles.count(true)
			return

	_reset_array(obstacles, false)
	var fallback_clusters := [
		[11, 21, 31, 32],
		[68, 78, 88, 87],
	]
	for cluster_index in mini(_obstacle_cluster_count, fallback_clusters.size()):
		for obstacle_index in fallback_clusters[cluster_index]:
			if not pollution_nodes[obstacle_index]:
				obstacles[obstacle_index] = true
	obstacle_count = obstacles.count(true)


func _try_place_obstacle_cluster() -> bool:
	for placement_attempt in 128:
		var available_shapes: Array = (
			BOSS_OBSTACLE_SHAPES if boss_level else LEVEL_FOUR_OBSTACLE_SHAPES
		)
		var shape: Array = available_shapes[
			_random.randi_range(0, available_shapes.size() - 1)
		]
		var max_column := 0
		var max_row := 0
		for offset_value in shape:
			var offset: Vector2i = offset_value
			max_column = maxi(max_column, offset.x)
			max_row = maxi(max_row, offset.y)
		var origin_column := _random.randi_range(1, column_count - max_column - 2)
		var origin_row := _random.randi_range(1, row_count - max_row - 2)
		var candidate_cells: Array[int] = []
		var valid_candidate := true
		for offset_value in shape:
			var offset: Vector2i = offset_value
			var cell_index := (
				(origin_row + offset.y) * column_count
				+ origin_column
				+ offset.x
			)
			if (
				pollution_nodes[cell_index]
				or obstacles[cell_index]
				or _touches_existing_obstacle(cell_index)
				or (boss_level and _touches_pollution_node(cell_index))
			):
				valid_candidate = false
				break
			candidate_cells.append(cell_index)
		if not valid_candidate:
			continue
		for cell_index in candidate_cells:
			obstacles[cell_index] = true
		if boss_level or _pollution_nodes_have_space():
			return true
		for cell_index in candidate_cells:
			obstacles[cell_index] = false
	return false


func _touches_existing_obstacle(cell_index: int) -> bool:
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			var nearby_row := row + row_offset
			var nearby_column := column + column_offset
			if (
				nearby_row < 0
				or nearby_row >= row_count
				or nearby_column < 0
				or nearby_column >= column_count
			):
				continue
			if obstacles[nearby_row * column_count + nearby_column]:
				return true
	return false


func _pollution_nodes_have_space() -> bool:
	for node_index in cell_count:
		if not pollution_nodes[node_index]:
			continue
		var available_neighbor_count := 0
		for neighbor in _get_neighbors(node_index):
			if not obstacles[neighbor] and not pollution_nodes[neighbor]:
				available_neighbor_count += 1
		if available_neighbor_count < 5:
			return false
	return true


func _randomize_boss_anchor_nodes() -> void:
	var tree_start_row := int((row_count - BOSS_TREE_GRID_SIZE) / 2)
	var tree_start_column := int((column_count - BOSS_TREE_GRID_SIZE) / 2)
	var root_variants := [
		[
			[
				Vector2i(tree_start_column, tree_start_row - 1),
				Vector2i(tree_start_column, tree_start_row - 2),
				Vector2i(tree_start_column - 1, tree_start_row - 3),
			],
			[
				Vector2i(tree_start_column + 1, tree_start_row - 1),
				Vector2i(tree_start_column + 1, tree_start_row - 2),
				Vector2i(tree_start_column + 2, tree_start_row - 3),
			],
		],
		[
			[
				Vector2i(tree_start_column - 1, tree_start_row + 1),
				Vector2i(tree_start_column - 2, tree_start_row + 2),
				Vector2i(tree_start_column - 3, tree_start_row + 3),
			],
			[
				Vector2i(tree_start_column - 1, tree_start_row),
				Vector2i(tree_start_column - 2, tree_start_row + 1),
				Vector2i(tree_start_column - 3, tree_start_row + 2),
			],
		],
		[
			[
				Vector2i(tree_start_column + 3, tree_start_row + 1),
				Vector2i(tree_start_column + 4, tree_start_row + 2),
				Vector2i(tree_start_column + 5, tree_start_row + 3),
			],
			[
				Vector2i(tree_start_column + 3, tree_start_row),
				Vector2i(tree_start_column + 4, tree_start_row + 1),
				Vector2i(tree_start_column + 5, tree_start_row + 2),
			],
		],
	]
	for root_group_index in root_variants.size():
		var variants: Array = root_variants[root_group_index]
		var root_cells: Array = variants[_random.randi_range(0, variants.size() - 1)]
		for position_value in root_cells:
			var root_position: Vector2i = position_value
			var root_index := root_position.y * column_count + root_position.x
			pollution_nodes[root_index] = true
			pollution_node_groups[root_index] = root_group_index
			pollution_node_cell_count += 1
		pollution_node_count += 1
	assert(
		pollution_node_count == _random_pollution_node_count,
		"The boss board requires three root anchors."
	)


func _randomize_pollution_nodes() -> void:
	_reset_array(pollution_nodes, false)
	_reset_array(pollution_node_groups, -1)
	_reset_array(pollution_node_group_cleansed, false)
	_reset_array(pollution_nodes_cleansed, false)
	pollution_node_count = 0
	pollution_node_cell_count = 0
	cleansed_pollution_node_count = 0
	if boss_level:
		_randomize_boss_anchor_nodes()
		return
	var reserved_obstacle_cells := {
		11: true, 21: true, 31: true, 32: true,
		68: true, 78: true, 88: true, 87: true,
	}
	var candidates: Array[int] = []
	for row in range(1, row_count - 1):
		for column in range(1, column_count - 1):
			var cell_index := row * column_count + column
			if not reserved_obstacle_cells.has(cell_index):
				candidates.append(cell_index)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	for candidate_index in candidates:
		var candidate_row := int(candidate_index / column_count)
		var candidate_column := candidate_index % column_count
		var sufficiently_separated := true
		for existing_index in cell_count:
			if not pollution_nodes[existing_index]:
				continue
			var existing_row := int(existing_index / column_count)
			var existing_column := existing_index % column_count
			if (
				absi(candidate_row - existing_row) < 3
				and absi(candidate_column - existing_column) < 3
			):
				sufficiently_separated = false
				break
		if not sufficiently_separated:
			continue
		pollution_nodes[candidate_index] = true
		pollution_node_groups[candidate_index] = pollution_node_count
		pollution_node_count += 1
		pollution_node_cell_count += 1
		if pollution_node_count == _random_pollution_node_count:
			return
	assert(
		pollution_node_count == _random_pollution_node_count,
		"The board needs enough separated pollution-node positions."
	)


func _configure_pollution_nodes(level: Dictionary) -> void:
	_reset_array(pollution_nodes, false)
	_reset_array(pollution_node_groups, -1)
	_reset_array(pollution_node_group_cleansed, false)
	_reset_array(pollution_nodes_cleansed, false)
	pollution_node_count = 0
	pollution_node_cell_count = 0
	cleansed_pollution_node_count = 0
	_random_pollution_node_count = int(level.get("pollution_node_count", 0))
	if _random_pollution_node_count > 0:
		_randomize_pollution_nodes()
		return
	for value in level.get("pollution_nodes", []):
		var node_index := int(value)
		if not _is_valid_index(node_index) or pollution_nodes[node_index]:
			continue
		pollution_nodes[node_index] = true
		pollution_node_groups[node_index] = pollution_node_count
		pollution_node_count += 1
		pollution_node_cell_count += 1


func new_game(refresh_dynamic_layout: bool = true) -> void:
	_reset_pollution_animation()
	var rebuild_cells := false
	if (
		refresh_dynamic_layout
		and topology == HEX_TOPOLOGY
		and not _loaded_level_data.is_empty()
		and (
			not _loaded_level_data.get("reef_segments", []).is_empty()
			or not _loaded_level_data.get("current_paths", []).is_empty()
		)
	):
		_configure_ocean_mechanics(_loaded_level_data)
		rebuild_cells = true
	if refresh_dynamic_layout and _random_pollution_node_count > 0:
		_randomize_pollution_nodes()
		rebuild_cells = true
	if refresh_dynamic_layout and boss_level and topology != HEX_TOPOLOGY:
		_configure_boss_obstacles()
		rebuild_cells = true
	elif refresh_dynamic_layout and _obstacle_cluster_count > 0:
		_randomize_obstacle_clusters()
		rebuild_cells = true
	if rebuild_cells:
		safe_cell_count = (
			cell_count
			- core_count
			- obstacle_count
			- pollution_node_cell_count
		)
		_clear_cells()
		_create_cells()
	game_state = GameState.READY
	used_flags = 0
	revealed_safe_count = 0
	move_count = 0
	reveal_action_count = 0
	cleansed_pollution_node_count = 0
	scan_target_mode = false
	guide_cell_index = -1
	active_tidal_zone_index = 0
	for cell in cell_nodes:
		cell.reset_transient_visuals()
	_reset_array(mines, false)
	_reset_array(revealed, false)
	_reset_array(flagged, false)
	_reset_array(ever_flagged, false)
	_reset_array(confirmed, false)
	_reset_array(pollution_node_group_cleansed, false)
	_reset_array(pollution_nodes_cleansed, false)
	_reset_array(adjacent_counts, 0)
	_place_random_cores()
	_calculate_adjacent_counts()
	_calculate_current_path_mine_totals()
	_advance_tidal_zone_if_complete(false)
	_refresh_current_endpoint_cells()
	if first_move_guide_enabled:
		guide_cell_index = _choose_guide_cell()
	_reset_keyboard_cursor()
	_refresh_all_cells()
	state_changed.emit(game_state)
	flags_changed.emit(used_flags, core_count)
	pollution_nodes_changed.emit(
		cleansed_pollution_node_count,
		pollution_node_count
	)
	if tidal_zone_count > 0:
		tidal_zone_changed.emit(active_tidal_zone_index, tidal_zone_count)


func set_opening_assist_mode(mode: int) -> void:
	opening_assist_mode = clampi(mode, OpeningAssist.NONE, OpeningAssist.OPEN_REGION)


func reveal_cell(cell_index: int) -> void:
	if (
		not interaction_enabled
		or not _is_valid_index(cell_index)
		or _is_tidal_cell_locked(cell_index)
		or obstacles[cell_index]
		or pollution_nodes[cell_index]
	):
		return
	_sync_keyboard_cursor(cell_index)
	if game_state == GameState.WON or game_state == GameState.LOST:
		return
	if revealed[cell_index] or flagged[cell_index]:
		return

	move_count += 1
	reveal_action_count += 1
	if game_state == GameState.READY:
		if opening_assist_mode != OpeningAssist.NONE:
			_apply_opening_assist(cell_index)
		opening_assist_mode = OpeningAssist.NONE
		guide_cell_index = -1
		game_state = GameState.PLAYING
		state_changed.emit(game_state)

	if mines[cell_index]:
		revealed[cell_index] = true
		game_state = GameState.LOST
		_start_pollution_animation(cell_index)
		_refresh_all_cells()
		state_changed.emit(game_state)
		reveal_completed.emit(cell_index, 0)
		return

	var previous_revealed_count := revealed_safe_count
	_reveal_area(cell_index)
	_refresh_pollution_nodes()
	_advance_tidal_zone_if_complete()
	var completed_game := _is_game_complete()
	if completed_game:
		game_state = GameState.WON
	_refresh_all_cells()
	reveal_completed.emit(cell_index, revealed_safe_count - previous_revealed_count)
	if completed_game:
		state_changed.emit(game_state)


func try_scan_cell(cell_index: int) -> bool:
	if (
		not interaction_enabled
		or not scan_target_mode
		or game_state != GameState.PLAYING
		or reveal_action_count <= 0
		or not is_scan_candidate(cell_index)
	):
		return false
	_sync_keyboard_cursor(cell_index)
	set_scan_target_mode(false)
	move_count += 1

	if mines[cell_index]:
		flagged[cell_index] = true
		confirmed[cell_index] = true
		used_flags += 1
		_refresh_pollution_nodes()
		_advance_tidal_zone_if_complete()
		var mine_completed_game := _is_game_complete()
		if mine_completed_game:
			game_state = GameState.WON
			_refresh_all_cells()
		else:
			_refresh_cell(cell_index)
		cell_nodes[cell_index].play_scan_result(ScanResult.MINE)
		flags_changed.emit(used_flags, core_count)
		scan_completed.emit(cell_index, ScanResult.MINE, 0)
		if mine_completed_game:
			state_changed.emit(game_state)
		return true

	var previous_revealed_count := revealed_safe_count
	_reveal_area(cell_index)
	_refresh_pollution_nodes()
	_advance_tidal_zone_if_complete()
	var completed_game := _is_game_complete()
	if completed_game:
		game_state = GameState.WON
	_refresh_all_cells()
	cell_nodes[cell_index].play_scan_result(ScanResult.SAFE)
	scan_completed.emit(
		cell_index,
		ScanResult.SAFE,
		revealed_safe_count - previous_revealed_count
	)
	if completed_game:
		state_changed.emit(game_state)
	return true


func is_scan_candidate(cell_index: int) -> bool:
	return (
		_is_valid_index(cell_index)
		and not _is_tidal_cell_locked(cell_index)
		and not obstacles[cell_index]
		and not pollution_nodes[cell_index]
		and not revealed[cell_index]
		and not flagged[cell_index]
	)


func set_scan_target_mode(enabled: bool) -> void:
	var next_mode := (
		enabled
		and interaction_enabled
		and game_state == GameState.PLAYING
		and reveal_action_count > 0
	)
	if scan_target_mode == next_mode:
		return
	scan_target_mode = next_mode
	for cell_index in cell_nodes.size():
		cell_nodes[cell_index].set_scan_target_mode(
			scan_target_mode,
			is_scan_candidate(cell_index)
		)


func toggle_flag(cell_index: int) -> void:
	if (
		not interaction_enabled
		or not _is_valid_index(cell_index)
		or _is_tidal_cell_locked(cell_index)
		or obstacles[cell_index]
		or pollution_nodes[cell_index]
	):
		return
	_sync_keyboard_cursor(cell_index)
	if game_state == GameState.WON or game_state == GameState.LOST:
		return
	if revealed[cell_index] or confirmed[cell_index]:
		return

	var is_first_placement := false
	if flagged[cell_index]:
		flagged[cell_index] = false
		used_flags -= 1
	elif used_flags < core_count:
		flagged[cell_index] = true
		used_flags += 1
		is_first_placement = not ever_flagged[cell_index]
		ever_flagged[cell_index] = true
	else:
		return

	move_count += 1
	_refresh_cell(cell_index)
	flags_changed.emit(used_flags, core_count)
	_refresh_pollution_nodes()
	_advance_tidal_zone_if_complete()
	var completed_game := game_state == GameState.PLAYING and _is_game_complete()
	if completed_game:
		game_state = GameState.WON
		_refresh_all_cells()
	flag_completed.emit(cell_index, flagged[cell_index], is_first_placement)
	if completed_game:
		state_changed.emit(game_state)


func chord_cell(cell_index: int) -> void:
	if (
		not interaction_enabled
		or not _is_valid_index(cell_index)
		or _is_tidal_cell_locked(cell_index)
		or obstacles[cell_index]
		or pollution_nodes[cell_index]
		or game_state != GameState.PLAYING
	):
		return
	_sync_keyboard_cursor(cell_index)
	if not revealed[cell_index] or adjacent_counts[cell_index] <= 0:
		return

	var number_neighbors := _get_number_neighbors(cell_index)
	var resolved_pollution_count := 0
	for neighbor in number_neighbors:
		if pollution_nodes[neighbor]:
			resolved_pollution_count += 1
			continue
		if not flagged[neighbor]:
			continue
		if not mines[neighbor]:
			return
		resolved_pollution_count += 1

	if resolved_pollution_count != adjacent_counts[cell_index]:
		return

	move_count += 1
	var previous_revealed_count := revealed_safe_count
	for neighbor in _get_neighbors(cell_index):
		if (
			not mines[neighbor]
			and not obstacles[neighbor]
			and not pollution_nodes[neighbor]
			and not flagged[neighbor]
			and not revealed[neighbor]
		):
			_reveal_area(neighbor)

	_refresh_pollution_nodes()
	_advance_tidal_zone_if_complete()
	var completed_game := _is_game_complete()
	if completed_game:
		game_state = GameState.WON
	if revealed_safe_count != previous_revealed_count:
		_refresh_all_cells()
		chord_completed.emit(cell_index, revealed_safe_count - previous_revealed_count)
	if completed_game:
		state_changed.emit(game_state)


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
	elif (
		_is_valid_index(guide_cell_index)
		and not obstacles[guide_cell_index]
		and not pollution_nodes[guide_cell_index]
		and not _is_tidal_cell_locked(guide_cell_index)
	):
		keyboard_cell_index = guide_cell_index
	else:
		keyboard_cell_index = -1
		for cell_index in cell_count:
			if (
				not obstacles[cell_index]
				and not pollution_nodes[cell_index]
				and not _is_tidal_cell_locked(cell_index)
			):
				keyboard_cell_index = cell_index
				break
	_refresh_keyboard_cursor()


func _move_keyboard_cursor(movement: Vector2i) -> void:
	if not _is_valid_index(keyboard_cell_index):
		_reset_keyboard_cursor()
		return
	var row := int(keyboard_cell_index / column_count)
	var column := keyboard_cell_index % column_count
	var next_row := row + movement.y
	var next_column := column + movement.x
	while (
		next_row >= 0
		and next_row < row_count
		and next_column >= 0
		and next_column < column_count
	):
		var next_index := next_row * column_count + next_column
		if (
			not obstacles[next_index]
			and not pollution_nodes[next_index]
			and not _is_tidal_cell_locked(next_index)
		):
			_set_keyboard_cursor(next_index)
			return
		next_row += movement.y
		next_column += movement.x


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
	if (
		not _is_valid_index(cell_index)
		or _is_tidal_cell_locked(cell_index)
		or obstacles[cell_index]
		or pollution_nodes[cell_index]
		or keyboard_cell_index == cell_index
	):
		return
	keyboard_cell_index = cell_index
	_refresh_keyboard_cursor()


func _refresh_keyboard_cursor() -> void:
	var selected_index := keyboard_cell_index if operation_mode == OperationMode.KEYBOARD else -1
	for cell_index in cell_nodes.size():
		cell_nodes[cell_index].set_keyboard_selected(cell_index == selected_index)


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
	for arrow in _current_arrow_nodes:
		if is_instance_valid(arrow):
			var arrow_parent := arrow.get_parent()
			if arrow_parent != null:
				arrow_parent.remove_child(arrow)
			arrow.free()
	_current_arrow_nodes.clear()
	for line_pair in _current_line_nodes:
		for line_key in ["wash", "ink"]:
			var current_line := line_pair.get(line_key) as Line2D
			if is_instance_valid(current_line):
				var current_parent := current_line.get_parent()
				if current_parent != null:
					current_parent.remove_child(current_line)
				current_line.free()
	_current_line_nodes.clear()
	for reef_line in _reef_line_nodes:
		if is_instance_valid(reef_line):
			var line_parent := reef_line.get_parent()
			if line_parent != null:
				line_parent.remove_child(reef_line)
			reef_line.free()
	_reef_line_nodes.clear()
	for cell in cell_nodes:
		if is_instance_valid(cell):
			var parent := cell.get_parent()
			if parent != null:
				parent.remove_child(cell)
			cell.free()
	cell_nodes.clear()
	ocean_hex_bounds = Rect2()
	ocean_paper_rect = Rect2()
	ocean_shared_edge_count = 0
	_ocean_shared_edges.clear()
	if is_instance_valid(_boss_tree_overlay):
		var overlay_parent := _boss_tree_overlay.get_parent()
		if overlay_parent != null:
			overlay_parent.remove_child(_boss_tree_overlay)
		_boss_tree_overlay.free()
	_boss_tree_overlay = null
	var handmade_surface := get_node_or_null("CellSurfaceHost") as Control
	if is_instance_valid(handmade_surface):
		handmade_surface.visible = false
	_handmade_surface = null


func _create_cells() -> void:
	_create_handmade_cells()


func _create_handmade_cells() -> void:
	_validate_handmade_geometry()
	custom_minimum_size = LEVEL_ONE_BOARD_SIZE

	_handmade_surface = get_node_or_null("CellSurfaceHost") as Control
	assert(
		is_instance_valid(_handmade_surface),
		"The handmade board requires an editable CellSurfaceHost child."
	)
	_handmade_surface.visible = true
	_create_reef_line_nodes()

	for cell_index in cell_count:
		var cell := _make_cell(cell_index)
		cell.custom_minimum_size = Vector2.ZERO
		_handmade_surface.add_child(cell)
	_create_current_line_nodes()
	_create_boss_tree_overlay()

	_layout_cells()
	call_deferred("_layout_cells")


func _create_reef_line_nodes() -> void:
	_reef_line_nodes.clear()
	if (
		topology != HEX_TOPOLOGY
		or _ocean_reef_texture == null
		or not is_instance_valid(_handmade_surface)
	):
		return
	for segment_index in reef_segments.size():
		var reef_line := Line2D.new()
		reef_line.name = "OceanReefLine%02d" % segment_index
		reef_line.texture = _ocean_reef_texture
		reef_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		reef_line.joint_mode = Line2D.LINE_JOINT_ROUND
		reef_line.begin_cap_mode = Line2D.LINE_CAP_NONE
		reef_line.end_cap_mode = Line2D.LINE_CAP_NONE
		reef_line.antialiased = true
		reef_line.default_color = Color.WHITE
		_handmade_surface.add_child(reef_line)
		_reef_line_nodes.append(reef_line)


func _create_current_line_nodes() -> void:
	_current_line_nodes.clear()
	_current_arrow_nodes.clear()
	if topology != HEX_TOPOLOGY or not is_instance_valid(_handmade_surface):
		return
	for path_index in current_paths.size():
		var wash_line := Line2D.new()
		wash_line.name = "OceanCurrentWash%02d" % path_index
		wash_line.joint_mode = Line2D.LINE_JOINT_ROUND
		wash_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		wash_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		wash_line.antialiased = true
		wash_line.default_color = OCEAN_CURRENT_WASH_COLOR
		wash_line.z_index = 1
		_handmade_surface.add_child(wash_line)

		var ink_line := Line2D.new()
		ink_line.name = "OceanCurrentInk%02d" % path_index
		ink_line.joint_mode = Line2D.LINE_JOINT_ROUND
		ink_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ink_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		ink_line.antialiased = true
		ink_line.default_color = OCEAN_CURRENT_INK_COLOR
		ink_line.z_index = 2
		_handmade_surface.add_child(ink_line)
		_current_line_nodes.append({"wash": wash_line, "ink": ink_line})

		var arrow := Polygon2D.new()
		arrow.name = "OceanCurrentArrow%02d" % path_index
		arrow.color = OCEAN_CURRENT_INK_COLOR
		arrow.z_index = 3
		_handmade_surface.add_child(arrow)
		_current_arrow_nodes.append(arrow)


func _create_boss_tree_overlay() -> void:
	if not boss_level or topology == HEX_TOPOLOGY or not is_instance_valid(_handmade_surface):
		return
	_boss_tree_overlay = TextureRect.new()
	_boss_tree_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_tree_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_tree_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_tree_overlay.z_index = 4
	_boss_tree_overlay.texture = load(BOSS_TREE_ACTIVE_PATH) as Texture2D
	_handmade_surface.add_child(_boss_tree_overlay)
	_update_boss_tree_visual()


func _layout_boss_tree_overlay() -> void:
	if not is_instance_valid(_boss_tree_overlay) or not is_instance_valid(_handmade_surface):
		return
	var slot_size := _handmade_surface.size / Vector2(column_count, row_count)
	var tree_start_row := int((row_count - BOSS_TREE_GRID_SIZE) / 2)
	var tree_start_column := int((column_count - BOSS_TREE_GRID_SIZE) / 2)
	_boss_tree_overlay.position = Vector2(tree_start_column, tree_start_row) * slot_size
	_boss_tree_overlay.size = slot_size * float(BOSS_TREE_GRID_SIZE)


func _update_boss_tree_visual() -> void:
	if not is_instance_valid(_boss_tree_overlay):
		return
	if game_state == GameState.WON:
		_boss_tree_overlay.texture = load(BOSS_TREE_CLEANSED_PATH) as Texture2D
		_boss_tree_overlay.modulate = Color.WHITE
		return
	_boss_tree_overlay.texture = load(BOSS_TREE_ACTIVE_PATH) as Texture2D
	var damage_progress := (
		float(cleansed_pollution_node_count) / float(pollution_node_count)
		if pollution_node_count > 0
		else 0.0
	)
	_boss_tree_overlay.modulate = Color("a66abd").lerp(
		Color("d5c2a8"),
		damage_progress * 0.72
	)


func _get_obstacle_connections(cell_index: int) -> int:
	if not _is_valid_index(cell_index) or not obstacles[cell_index]:
		return 0
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	var connections := 0
	if row > 0 and obstacles[cell_index - column_count]:
		connections |= OBSTACLE_NORTH
	if column < column_count - 1 and obstacles[cell_index + 1]:
		connections |= OBSTACLE_EAST
	if row < row_count - 1 and obstacles[cell_index + column_count]:
		connections |= OBSTACLE_SOUTH
	if column > 0 and obstacles[cell_index - 1]:
		connections |= OBSTACLE_WEST
	return connections


func _make_cell(cell_index: int) -> MineCell:
	var cell := CELL_SCENE.instantiate() as MineCell
	cell.focus_mode = Control.FOCUS_NONE
	cell.setup(
		cell_index,
		level_number,
		topology,
		obstacles[cell_index],
		_get_obstacle_connections(cell_index),
		pollution_nodes[cell_index],
		boss_tree_cells[cell_index]
	)
	_configure_cell_ocean_mechanics(cell, cell_index)
	cell.reveal_requested.connect(reveal_cell)
	cell.flag_requested.connect(toggle_flag)
	cell.chord_requested.connect(chord_cell)
	cell.scan_requested.connect(_on_cell_scan_requested)
	cell.scan_cancel_requested.connect(_on_cell_scan_cancel_requested)
	cell_nodes.append(cell)
	return cell


func _configure_cell_ocean_mechanics(cell: MineCell, cell_index: int) -> void:
	if topology != HEX_TOPOLOGY:
		return
	var reef_sides: Array[int] = []
	var tide_sides: Array[int] = []
	for neighbor_record in _get_raw_hex_neighbor_records(cell_index):
		var neighbor_index := int(neighbor_record["index"])
		var side := int(neighbor_record["side"])
		if (
			_has_reef_edge(cell_index, neighbor_index)
			and not _crosses_reef_divider(cell_index, neighbor_index)
		):
			reef_sides.append(side)
		if (
			tidal_zone_count > 0
			and tidal_zone_indices[cell_index] != tidal_zone_indices[neighbor_index]
		):
			tide_sides.append(side)

	var current_in_sides: Array[int] = []
	var current_out_sides: Array[int] = []
	var endpoint_totals: Array[int] = []
	for path_index in current_paths.size():
		var path: Array = current_paths[path_index]
		for position_index in path.size():
			if int(path[position_index]) != cell_index:
				continue
			if position_index > 0:
				var incoming_side := _get_hex_side_between(
					cell_index,
					int(path[position_index - 1])
				)
				if incoming_side >= 0 and not current_in_sides.has(incoming_side):
					current_in_sides.append(incoming_side)
			if position_index < path.size() - 1:
				var outgoing_side := _get_hex_side_between(
					cell_index,
					int(path[position_index + 1])
				)
				if outgoing_side >= 0 and not current_out_sides.has(outgoing_side):
					current_out_sides.append(outgoing_side)
			else:
				endpoint_totals.append(current_path_mine_totals[path_index])
	cell.configure_ocean_mechanics(
		reef_sides,
		current_in_sides,
		current_out_sides,
		endpoint_totals,
		tide_sides,
		tidal_zone_indices[cell_index],
		_is_tidal_cell_locked(cell_index)
	)


func _refresh_current_endpoint_cells() -> void:
	_refresh_current_line_visibility()
	for cell_index in cell_nodes.size():
		_configure_cell_ocean_mechanics(cell_nodes[cell_index], cell_index)


func _on_cell_scan_requested(cell_index: int) -> void:
	if scan_target_mode:
		scan_target_requested.emit(cell_index)


func _on_cell_scan_cancel_requested() -> void:
	if scan_target_mode:
		scan_cancel_requested.emit()


func _validate_handmade_geometry() -> void:
	assert(row_count > 0 and column_count > 0, "The handmade board requires a non-empty grid.")
	if level_number == 1:
		assert(
			LEVEL_ONE_CELL_ROTATIONS.size() == cell_count
			and LEVEL_ONE_CELL_OFFSETS.size() == cell_count,
			"The 5x5 opening board needs one placement variation per cell."
		)
	var surface := get_node_or_null("CellSurfaceHost") as Control
	assert(is_instance_valid(surface), "The handmade board requires CellSurfaceHost.")
	assert(
		Rect2(Vector2.ZERO, LEVEL_ONE_BOARD_SIZE).encloses(
			Rect2(surface.position, surface.size)
		),
		"CellSurfaceHost must stay inside the board tray."
	)


func _layout_cells() -> void:
	if topology == HEX_TOPOLOGY:
		_layout_hex_cells()
	else:
		_layout_handmade_cells()


func _layout_handmade_cells() -> void:
	if not is_instance_valid(_handmade_surface):
		return
	if cell_nodes.size() != row_count * column_count or size.x <= 0.0 or size.y <= 0.0:
		return

	var play_rect := Rect2(Vector2.ZERO, _handmade_surface.size)
	var slot_size := play_rect.size / Vector2(column_count, row_count)
	for cell_index in cell_nodes.size():
		var row := int(cell_index / column_count)
		var column := cell_index % column_count
		var slot_rect := Rect2(
			play_rect.position + Vector2(column, row) * slot_size,
			slot_size
		)
		var fill_ratio := 1.0 if obstacles[cell_index] else LEVEL_ONE_CELL_SLOT_FILL
		var side := minf(slot_rect.size.x, slot_rect.size.y) * fill_ratio
		var cell_size := Vector2(side, side)
		var placement_offset := Vector2.ZERO
		var rotation_degrees := 0.0
		if level_number == 1:
			placement_offset = LEVEL_ONE_CELL_OFFSETS[cell_index] * slot_size
			rotation_degrees = LEVEL_ONE_CELL_ROTATIONS[cell_index]
		var cell := cell_nodes[cell_index]
		cell.position = slot_rect.position + (slot_rect.size - cell_size) * 0.5 + placement_offset
		cell.size = cell_size
		cell.pivot_offset = cell_size * 0.5
		cell.rotation = deg_to_rad(rotation_degrees)
		cell.add_theme_font_size_override("font_size", clampi(roundi(side * 0.42), 10, 30))
		cell.add_theme_constant_override("outline_size", clampi(roundi(side * 0.04), 1, 3))
	_layout_boss_tree_overlay()
	queue_redraw()


func _layout_hex_cells() -> void:
	if not is_instance_valid(_handmade_surface):
		return
	if cell_nodes.size() != row_count * column_count:
		return
	var surface_size := _handmade_surface.size
	if surface_size.x <= 0.0 or surface_size.y <= 0.0:
		return

	var width_factor := HEX_HORIZONTAL_FACTOR * (
		float(column_count) + (0.5 if row_count > 1 else 0.0)
	)
	var height_factor := 2.0 + 1.5 * float(maxi(row_count - 1, 0))
	var radius := minf(surface_size.x / width_factor, surface_size.y / height_factor)
	var hex_size := Vector2(HEX_HORIZONTAL_FACTOR * radius, 2.0 * radius)
	var used_size := Vector2(
		width_factor * radius,
		height_factor * radius
	)
	var origin := (surface_size - used_size) * 0.5

	for cell_index in cell_nodes.size():
		var row := int(cell_index / column_count)
		var column := cell_index % column_count
		var row_shift := hex_size.x * 0.5 if row % 2 == 1 else 0.0
		var cell := cell_nodes[cell_index]
		cell.position = origin + Vector2(
			float(column) * hex_size.x + row_shift,
			float(row) * radius * 1.5
		)
		cell.size = hex_size
		cell.pivot_offset = hex_size * 0.5
		cell.rotation = 0.0
		cell.set_hex_fill_ratio(
			OCEAN_REEF_CELL_FILL
			if _cell_touches_reef(cell_index)
			else HEX_CELL_FILL
		)
		cell.add_theme_font_size_override(
			"font_size",
			clampi(roundi(radius * 0.72), 11, 30)
		)
		cell.add_theme_constant_override("outline_size", 2)
	_layout_reef_line_nodes(radius)
	_layout_current_line_nodes(radius)
	_update_ocean_paper_geometry()
	queue_redraw()


func _layout_reef_line_nodes(radius: float) -> void:
	if (
		_reef_line_nodes.size() != reef_segments.size()
		or not is_instance_valid(_handmade_surface)
	):
		return
	for segment_index in reef_segments.size():
		var segment: Dictionary = reef_segments[segment_index]
		var divider_column := int(segment["divider"])
		var start_row := int(segment["start_row"])
		var end_row := int(segment["end_row"])
		var path_points := PackedVector2Array()
		for row in range(start_row, end_row + 1):
			var left_points := _full_hex_points(
				cell_nodes[row * column_count + divider_column]
			)
			var right_points := _full_hex_points(
				cell_nodes[row * column_count + divider_column + 1]
			)
			var top_point := (
				(left_points[1] + right_points[5]) * 0.5
				- _handmade_surface.position
			)
			var bottom_point := (
				(left_points[2] + right_points[4]) * 0.5
				- _handmade_surface.position
			)
			path_points.append(top_point)
			path_points.append(bottom_point)
		var reef_line := _reef_line_nodes[segment_index]
		reef_line.points = path_points
		reef_line.width = radius * OCEAN_REEF_GAP_FACTOR * 0.72


func _layout_current_line_nodes(radius: float) -> void:
	if (
		_current_line_nodes.size() != current_paths.size()
		or _current_arrow_nodes.size() != current_paths.size()
	):
		return
	for path_index in current_paths.size():
		var path: Array = current_paths[path_index]
		var control_points := PackedVector2Array()
		for cell_value in path:
			var cell_index := int(cell_value)
			if not _is_valid_index(cell_index):
				continue
			var cell := cell_nodes[cell_index]
			control_points.append(cell.position + cell.size * 0.5)

		var offset_points := PackedVector2Array()
		for point_index in control_points.size():
			var previous_point := control_points[maxi(0, point_index - 1)]
			var next_point := control_points[mini(control_points.size() - 1, point_index + 1)]
			var tangent := (next_point - previous_point).normalized()
			var normal := Vector2(-tangent.y, tangent.x)
			offset_points.append(
				control_points[point_index]
				+ normal * radius * OCEAN_CURRENT_OFFSET_FACTOR
			)
		var smooth_points := _smooth_current_points(offset_points)
		var line_entry: Dictionary = _current_line_nodes[path_index]
		var wash_line := line_entry["wash"] as Line2D
		var ink_line := line_entry["ink"] as Line2D
		wash_line.points = smooth_points
		wash_line.width = radius * 0.30
		ink_line.points = smooth_points
		ink_line.width = maxf(1.5, radius * 0.075)

		var arrow := _current_arrow_nodes[path_index]
		if smooth_points.size() < 3:
			arrow.visible = false
			continue
		var arrow_index := clampi(
			roundi(float(smooth_points.size() - 1) * 0.64),
			1,
			smooth_points.size() - 2
		)
		var arrow_tangent := (
			smooth_points[arrow_index + 1] - smooth_points[arrow_index - 1]
		).normalized()
		var arrow_length := radius * 0.34
		var arrow_half_height := radius * 0.13
		arrow.polygon = PackedVector2Array([
			Vector2(arrow_length * 0.58, 0.0),
			Vector2(-arrow_length * 0.42, -arrow_half_height),
			Vector2(-arrow_length * 0.12, 0.0),
			Vector2(-arrow_length * 0.42, arrow_half_height),
		])
		arrow.position = smooth_points[arrow_index]
		arrow.rotation = arrow_tangent.angle()
		arrow.visible = true
	_refresh_current_line_visibility()


func _smooth_current_points(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var smooth_points := PackedVector2Array()
	var samples_per_segment := 6
	for segment_index in points.size() - 1:
		var point_0 := points[maxi(0, segment_index - 1)]
		var point_1 := points[segment_index]
		var point_2 := points[segment_index + 1]
		var point_3 := points[mini(points.size() - 1, segment_index + 2)]
		for sample_index in samples_per_segment:
			var t := float(sample_index) / float(samples_per_segment)
			var t_squared := t * t
			var t_cubed := t_squared * t
			smooth_points.append(
				0.5 * (
					2.0 * point_1
					+ (-point_0 + point_2) * t
					+ (2.0 * point_0 - 5.0 * point_1 + 4.0 * point_2 - point_3)
					* t_squared
					+ (-point_0 + 3.0 * point_1 - 3.0 * point_2 + point_3)
					* t_cubed
				)
			)
	smooth_points.append(points[points.size() - 1])
	return smooth_points


func _refresh_current_line_visibility() -> void:
	for path_index in mini(current_paths.size(), _current_line_nodes.size()):
		var path: Array = current_paths[path_index]
		var path_locked := (
			not path.is_empty()
			and _is_tidal_cell_locked(int(path[0]))
		)
		var line_entry: Dictionary = _current_line_nodes[path_index]
		var wash_line := line_entry["wash"] as Line2D
		var ink_line := line_entry["ink"] as Line2D
		wash_line.visible = not path_locked
		ink_line.visible = not path_locked
		if path_index < _current_arrow_nodes.size():
			_current_arrow_nodes[path_index].visible = not path_locked


func _update_ocean_paper_geometry() -> void:
	ocean_hex_bounds = Rect2()
	ocean_paper_rect = Rect2()
	ocean_shared_edge_count = 0
	_ocean_shared_edges.clear()
	if topology != HEX_TOPOLOGY or cell_nodes.is_empty() or not is_instance_valid(_handmade_surface):
		return

	var edge_records: Dictionary = {}
	var has_bounds := false
	for cell in cell_nodes:
		var points := _full_hex_points(cell)
		for point in points:
			if not has_bounds:
				ocean_hex_bounds = Rect2(point, Vector2.ZERO)
				has_bounds = true
			else:
				ocean_hex_bounds = ocean_hex_bounds.expand(point)
		for point_index in 6:
			var edge_start := points[point_index]
			var edge_end := points[(point_index + 1) % 6]
			var key := _ocean_edge_key(edge_start, edge_end)
			if edge_records.has(key):
				var record: Dictionary = edge_records[key]
				record["count"] = int(record["count"]) + 1
				edge_records[key] = record
			else:
				edge_records[key] = {
					"start": edge_start,
					"end": edge_end,
					"count": 1,
				}

	for record_value in edge_records.values():
		var record: Dictionary = record_value
		if int(record["count"]) != 2:
			continue
		var edge_start: Vector2 = record["start"]
		var edge_end: Vector2 = record["end"]
		_ocean_shared_edges.append(PackedVector2Array([edge_start, edge_end]))
	ocean_shared_edge_count = _ocean_shared_edges.size()

	var paper_size := Vector2(
		maxf(
			ocean_hex_bounds.size.x + OCEAN_BOARD_PAPER_MARGIN.x * 2.0,
			OCEAN_BOARD_PAPER_MIN_SIZE.x
		),
		maxf(
			ocean_hex_bounds.size.y + OCEAN_BOARD_PAPER_MARGIN.y * 2.0,
			OCEAN_BOARD_PAPER_MIN_SIZE.y
		)
	)
	paper_size.x = minf(paper_size.x, OCEAN_BOARD_PAPER_SAFE_RECT.size.x)
	paper_size.y = minf(paper_size.y, OCEAN_BOARD_PAPER_SAFE_RECT.size.y)
	var paper_position := ocean_hex_bounds.get_center() - paper_size * 0.5
	paper_position.x = clampf(
		paper_position.x,
		OCEAN_BOARD_PAPER_SAFE_RECT.position.x,
		OCEAN_BOARD_PAPER_SAFE_RECT.end.x - paper_size.x
	)
	paper_position.y = clampf(
		paper_position.y,
		OCEAN_BOARD_PAPER_SAFE_RECT.position.y,
		OCEAN_BOARD_PAPER_SAFE_RECT.end.y - paper_size.y
	)
	ocean_paper_rect = Rect2(paper_position, paper_size)


func _full_hex_points(cell: MineCell) -> PackedVector2Array:
	var points := PackedVector2Array()
	var center := _handmade_surface.position + cell.position + cell.size * 0.5
	var radius := minf(cell.size.y * 0.5, cell.size.x / HEX_HORIZONTAL_FACTOR)
	for point_index in 6:
		var angle := deg_to_rad(-90.0 + float(point_index) * 60.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ocean_edge_key(edge_start: Vector2, edge_end: Vector2) -> String:
	var start_key := Vector2i(roundi(edge_start.x * 10.0), roundi(edge_start.y * 10.0))
	var end_key := Vector2i(roundi(edge_end.x * 10.0), roundi(edge_end.y * 10.0))
	if start_key.x > end_key.x or (start_key.x == end_key.x and start_key.y > end_key.y):
		var swap := start_key
		start_key = end_key
		end_key = swap
	return "%d:%d|%d:%d" % [start_key.x, start_key.y, end_key.x, end_key.y]


func _handmade_play_rect() -> Rect2:
	if not is_instance_valid(_handmade_surface):
		return Rect2()
	return Rect2(_handmade_surface.position, _handmade_surface.size)


func _ocean_paper_points() -> PackedVector2Array:
	var rect := ocean_paper_rect
	var cut := minf(
		OCEAN_BOARD_CORNER_CUT,
		minf(rect.size.x, rect.size.y) * 0.16
	)
	return PackedVector2Array([
		rect.position + Vector2(cut, 0.0),
		Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.position.y + cut),
		Vector2(rect.end.x, rect.end.y - cut),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut),
		Vector2(rect.position.x, rect.position.y + cut),
	])


func _draw_ocean_paper() -> void:
	if ocean_paper_rect.size.x <= 0.0 or ocean_paper_rect.size.y <= 0.0:
		return
	var paper_points := _ocean_paper_points()
	draw_colored_polygon(paper_points, OCEAN_BOARD_PAPER_COLOR)
	var paper_outline := paper_points.duplicate()
	paper_outline.append(paper_points[0])
	draw_polyline(paper_outline, OCEAN_BOARD_PAPER_EDGE, 1.5, true)
	for edge in _ocean_shared_edges:
		draw_dashed_line(
			edge[0],
			edge[1],
			OCEAN_BOARD_CREASE_COLOR,
			1.5,
			5.5,
			true,
			true
		)


func _draw() -> void:
	if row_count <= 0 or column_count <= 0:
		return
	if topology == HEX_TOPOLOGY:
		_draw_ocean_paper()
		return
	if level_number < 1 or level_number > 7:
		return
	var play_rect := _handmade_play_rect()
	var paper_rect := play_rect.grow(LAND_BOARD_PAPER_MARGIN)
	draw_rect(paper_rect, LAND_BOARD_PAPER_COLOR, true)
	draw_dashed_line(
		paper_rect.position,
		Vector2(paper_rect.end.x, paper_rect.position.y),
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		Vector2(paper_rect.end.x, paper_rect.position.y),
		paper_rect.end,
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		paper_rect.end,
		Vector2(paper_rect.position.x, paper_rect.end.y),
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		Vector2(paper_rect.position.x, paper_rect.end.y),
		paper_rect.position,
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	var slot_size := play_rect.size / Vector2(column_count, row_count)
	for column in range(1, column_count):
		var x := play_rect.position.x + slot_size.x * column
		var line_start := Vector2(x, play_rect.position.y + 3.0)
		var line_end := Vector2(x, play_rect.end.y - 3.0)
		draw_line(
			line_start - Vector2(0.9, 0.0),
			line_end - Vector2(0.9, 0.0),
			LAND_BOARD_CREASE_LIGHT,
			2.2,
			true
		)
		draw_dashed_line(
			line_start,
			line_end,
			LAND_BOARD_CREASE_GREEN,
			1.3,
			5.5,
			true,
			true
		)
	for row in range(1, row_count):
		var y := play_rect.position.y + slot_size.y * row
		var line_start := Vector2(play_rect.position.x + 3.0, y)
		var line_end := Vector2(play_rect.end.x - 3.0, y)
		draw_line(
			line_start - Vector2(0.0, 0.9),
			line_end - Vector2(0.0, 0.9),
			LAND_BOARD_CREASE_LIGHT,
			2.2,
			true
		)
		draw_dashed_line(
			line_start,
			line_end,
			LAND_BOARD_CREASE_GREEN,
			1.3,
			5.5,
			true,
			true
		)
	draw_rect(play_rect.grow(-1.5), LAND_BOARD_PAPER_EDGE, false, 1.2, true)


func _apply_opening_assist(cell_index: int) -> void:
	var protected_cells: Array[int] = [cell_index]
	if (
		opening_assist_mode == OpeningAssist.OPEN_REGION
		and not _is_near_reef_expansion_boundary(cell_index)
	):
		protected_cells.append_array(_get_neighbors(cell_index))

	var relocated_core_count := 0
	var relocated_core_bands: Array[int] = []
	var relocated_core_boundary_pairs: Array = []
	for protected_index in protected_cells:
		if mines[protected_index]:
			mines[protected_index] = false
			relocated_core_count += 1
			relocated_core_bands.append(_reef_band_index(protected_index))
			relocated_core_boundary_pairs.append(
				_reef_boundary_pair_for_cell(protected_index)
			)
	if relocated_core_count == 0:
		return

	var relocation_candidates: Array[int] = []
	for candidate_index in cell_count:
		if (
			not mines[candidate_index]
			and not obstacles[candidate_index]
			and not pollution_nodes[candidate_index]
			and not protected_cells.has(candidate_index)
		):
			relocation_candidates.append(candidate_index)
	for index in range(relocation_candidates.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var temporary := relocation_candidates[index]
		relocation_candidates[index] = relocation_candidates[swap_index]
		relocation_candidates[swap_index] = temporary
	assert(
		relocation_candidates.size() >= relocated_core_count,
		"Opening assistance requires enough unprotected cells for relocated cores."
	)
	var relocated_count := 0
	while relocated_count < relocated_core_count:
		var selected_index := -1
		var required_boundary_pair: Array = relocated_core_boundary_pairs[relocated_count]
		var required_band := (
			relocated_core_bands[relocated_count]
			if (
				topology == HEX_TOPOLOGY
				and not reef_dividers.is_empty()
				and required_boundary_pair.is_empty()
			)
			else -1
		)
		for relocation_index in relocation_candidates:
			if (
				mines[relocation_index]
				or _would_complete_four_core_square(relocation_index)
				or (
					required_band >= 0
					and _reef_band_index(relocation_index) != required_band
				)
				or (
					not required_boundary_pair.is_empty()
					and not required_boundary_pair.has(relocation_index)
				)
				or (
					required_boundary_pair.is_empty()
					and not _reef_boundary_pair_for_cell(relocation_index).is_empty()
				)
			):
				continue
			selected_index = relocation_index
			break
		assert(selected_index >= 0, "Opening assistance needs a valid relocation position.")
		mines[selected_index] = true
		relocated_count += 1
	assert(
		relocated_count == relocated_core_count,
		"Opening assistance must relocate every protected core."
	)
	_ensure_current_paths_have_cores(protected_cells)
	_reset_array(adjacent_counts, 0)
	_calculate_adjacent_counts()
	_calculate_current_path_mine_totals()
	_refresh_current_endpoint_cells()
	assert(mines.count(true) == core_count, "Opening assistance must preserve the core count.")


func _ensure_current_paths_have_cores(excluded_cells: Array[int] = []) -> void:
	if current_paths.is_empty():
		return
	for path_value in current_paths:
		var path: Array = path_value
		var path_has_core := false
		for cell_value in path:
			if mines[int(cell_value)]:
				path_has_core = true
				break
		if path_has_core or path.is_empty():
			continue

		var placed_path_core := false
		var target_offset := _random.randi_range(0, path.size() - 1)
		for target_step in path.size():
			var target_index := int(path[(target_offset + target_step) % path.size()])
			if (
				mines[target_index]
				or obstacles[target_index]
				or pollution_nodes[target_index]
				or excluded_cells.has(target_index)
				or not _reef_boundary_pair_for_cell(target_index).is_empty()
			):
				continue
			var source_offset := _random.randi_range(0, cell_count - 1)
			for source_step in cell_count:
				var source_index := (source_offset + source_step) % cell_count
				if (
					not mines[source_index]
					or not _reef_boundary_pair_for_cell(source_index).is_empty()
					or _is_cell_in_current_path(source_index)
					or (
						not reef_dividers.is_empty()
						and _reef_band_index(source_index) != _reef_band_index(target_index)
					)
					or (
						tidal_zone_count > 0
						and tidal_zone_indices[source_index] != tidal_zone_indices[target_index]
					)
				):
					continue
				mines[source_index] = false
				mines[target_index] = true
				placed_path_core = true
				break
			if placed_path_core:
				break
		assert(placed_path_core, "Each current path needs at least one pollution core.")


func _is_cell_in_current_path(cell_index: int) -> bool:
	for path_value in current_paths:
		var path: Array = path_value
		if path.has(cell_index):
			return true
	return false


func _reef_band_index(cell_index: int) -> int:
	var column := cell_index % column_count
	var band_index := 0
	for divider_column in reef_dividers:
		if column > divider_column:
			band_index += 1
	return band_index


func _place_balanced_ocean_cores(candidates: Array[int]) -> bool:
	if topology != HEX_TOPOLOGY or reef_dividers.is_empty():
		return false
	var band_candidates: Array = []
	for band_index in reef_dividers.size() + 1:
		band_candidates.append([])
	for candidate_index in candidates:
		band_candidates[_reef_band_index(candidate_index)].append(candidate_index)

	var band_targets: Array[int] = []
	var band_remainders: Array[float] = []
	var assigned_count := 0
	for band in band_candidates:
		var exact_target := float(core_count) * float(band.size()) / float(candidates.size())
		var base_target := floori(exact_target)
		band_targets.append(base_target)
		band_remainders.append(exact_target - float(base_target))
		assigned_count += base_target
	while assigned_count < core_count:
		var selected_band := -1
		var highest_remainder := -1.0
		for band_index in band_candidates.size():
			if (
				band_targets[band_index] >= band_candidates[band_index].size()
				or band_remainders[band_index] <= highest_remainder
			):
				continue
			selected_band = band_index
			highest_remainder = band_remainders[band_index]
		if selected_band < 0:
			return false
		band_targets[selected_band] += 1
		band_remainders[selected_band] = -1.0
		assigned_count += 1

	var placed_by_band: Array[int] = []
	for band_index in band_candidates.size():
		placed_by_band.append(0)

	var boundary_pairs := _reef_expansion_boundary_pairs()
	var boundary_safe_cells: Dictionary = {}
	var boundary_side_offset := _random.randi_range(0, 1)
	for pair_index in boundary_pairs.size():
		var pair: Array = boundary_pairs[pair_index]
		var preferred_position := (pair_index + boundary_side_offset) % 2
		var ordered_candidates := [
			int(pair[preferred_position]),
			int(pair[1 - preferred_position]),
		]
		for candidate_index in ordered_candidates:
			var band_index := _reef_band_index(candidate_index)
			if (
				mines[candidate_index]
				or placed_by_band[band_index] >= band_targets[band_index]
			):
				continue
			mines[candidate_index] = true
			placed_by_band[band_index] += 1
			for pair_cell_value in pair:
				var pair_cell := int(pair_cell_value)
				if pair_cell != candidate_index:
					boundary_safe_cells[pair_cell] = true
			break

	for band_index in band_candidates.size():
		var band: Array = band_candidates[band_index]
		for index in range(band.size() - 1, 0, -1):
			var swap_index := _random.randi_range(0, index)
			var temporary = band[index]
			band[index] = band[swap_index]
			band[swap_index] = temporary
		for candidate_value in band:
			if placed_by_band[band_index] >= band_targets[band_index]:
				break
			var candidate_index := int(candidate_value)
			if mines[candidate_index] or boundary_safe_cells.has(candidate_index):
				continue
			mines[candidate_index] = true
			placed_by_band[band_index] += 1
	return mines.count(true) == core_count


func _place_random_cores() -> void:
	var candidates: Array[int] = []
	for cell_index in cell_count:
		if not obstacles[cell_index] and not pollution_nodes[cell_index]:
			candidates.append(cell_index)
	assert(candidates.size() >= core_count, "The board needs enough playable cells for all cores.")
	_reset_array(mines, false)
	if _place_balanced_ocean_cores(candidates):
		_ensure_current_paths_have_cores()
		assert(mines.count(true) == core_count, "The board must contain the configured pollution core count.")
		return
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary

	var placed_core_count := 0
	if level_number == 3:
		for candidate_index in candidates:
			if _is_near_obstacle(candidate_index):
				mines[candidate_index] = true
				placed_core_count = 1
				break
	for candidate_index in candidates:
		if mines[candidate_index] or _would_complete_four_core_square(candidate_index):
			continue
		if (
			level_number == 3
			and _is_near_obstacle(candidate_index)
			and _count_cores_near_obstacles() >= 3
		):
			continue
		mines[candidate_index] = true
		placed_core_count += 1
		if placed_core_count == core_count:
			break

	_ensure_current_paths_have_cores()
	assert(placed_core_count == core_count, "The board needs enough valid core positions.")
	assert(mines.count(true) == core_count, "The board must contain the configured pollution core count.")
	assert(not _has_four_core_square(), "A 2x2 area cannot be completely polluted.")


func _has_four_core_square() -> bool:
	if topology == HEX_TOPOLOGY:
		return false
	for row in range(row_count - 1):
		for column in range(column_count - 1):
			var top_left := row * column_count + column
			var top_left_hazard := mines[top_left] or pollution_nodes[top_left]
			var top_right_hazard := mines[top_left + 1] or pollution_nodes[top_left + 1]
			var bottom_left_hazard := (
				mines[top_left + column_count]
				or pollution_nodes[top_left + column_count]
			)
			var bottom_right_hazard := (
				mines[top_left + column_count + 1]
				or pollution_nodes[top_left + column_count + 1]
			)
			if (
				top_left_hazard
				and top_right_hazard
				and bottom_left_hazard
				and bottom_right_hazard
			):
				return true
	return false


func _would_complete_four_core_square(cell_index: int) -> bool:
	if topology == HEX_TOPOLOGY or mines[cell_index]:
		return false
	mines[cell_index] = true
	var completes_square := _has_four_core_square()
	mines[cell_index] = false
	return completes_square


func _is_near_obstacle(cell_index: int) -> bool:
	for neighbor in _get_neighbors(cell_index):
		if obstacles[neighbor]:
			return true
	return false


func _count_cores_near_obstacles() -> int:
	var nearby_cells := {}
	for obstacle_index in cell_count:
		if not obstacles[obstacle_index]:
			continue
		for neighbor in _get_neighbors(obstacle_index):
			if not obstacles[neighbor]:
				nearby_cells[neighbor] = true
	var nearby_core_count := 0
	for cell_index in nearby_cells:
		if mines[int(cell_index)]:
			nearby_core_count += 1
	return nearby_core_count


func _choose_guide_cell() -> int:
	var zero_cells: Array[int] = []
	var lowest_number_cells: Array[int] = []
	var lowest_number := 9

	for cell_index in cell_count:
		if (
			mines[cell_index]
			or obstacles[cell_index]
			or pollution_nodes[cell_index]
			or _is_tidal_cell_locked(cell_index)
		):
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


func _refresh_pollution_nodes() -> void:
	if pollution_node_count == 0:
		return
	var changed := false
	for group_index in pollution_node_count:
		if pollution_node_group_cleansed[group_index]:
			continue
		var checked_neighbors := {}
		var resolved := true
		for node_index in cell_count:
			if pollution_node_groups[node_index] != group_index:
				continue
			for neighbor in _get_neighbors(node_index):
				if (
					obstacles[neighbor]
					or pollution_nodes[neighbor]
					or checked_neighbors.has(neighbor)
				):
					continue
				checked_neighbors[neighbor] = true
				if mines[neighbor]:
					if not flagged[neighbor]:
						resolved = false
						break
				elif not revealed[neighbor]:
					resolved = false
					break
			if not resolved:
				break
		if not resolved:
			continue
		pollution_node_group_cleansed[group_index] = true
		cleansed_pollution_node_count += 1
		for node_index in cell_count:
			if pollution_node_groups[node_index] == group_index:
				pollution_nodes_cleansed[node_index] = true
				_refresh_cell(node_index)
		changed = true
	if changed:
		_update_boss_tree_visual()
		pollution_nodes_changed.emit(
			cleansed_pollution_node_count,
			pollution_node_count
		)


func _is_game_complete() -> bool:
	return (
		revealed_safe_count == safe_cell_count
		and cleansed_pollution_node_count == pollution_node_count
	)


func _calculate_current_path_mine_totals() -> void:
	current_path_mine_totals.resize(current_paths.size())
	for path_index in current_paths.size():
		var mine_total := 0
		var counted_cells: Dictionary = {}
		var path: Array = current_paths[path_index]
		for cell_value in path:
			var cell_index := int(cell_value)
			if counted_cells.has(cell_index):
				continue
			counted_cells[cell_index] = true
			if mines[cell_index]:
				mine_total += 1
		current_path_mine_totals[path_index] = mine_total


func _is_tidal_cell_locked(cell_index: int) -> bool:
	return (
		tidal_zone_count > 0
		and _is_valid_index(cell_index)
		and tidal_zone_indices[cell_index] > active_tidal_zone_index
	)


func _is_tidal_zone_complete(zone_index: int) -> bool:
	if tidal_zone_count <= 0 or zone_index < 0 or zone_index >= tidal_zone_count:
		return false
	for cell_index in cell_count:
		if tidal_zone_indices[cell_index] != zone_index:
			continue
		if obstacles[cell_index] or pollution_nodes[cell_index] or mines[cell_index]:
			continue
		if not revealed[cell_index]:
			return false
	return true


func _advance_tidal_zone_if_complete(emit_change: bool = true) -> void:
	if tidal_zone_count <= 0:
		return
	var previous_zone := active_tidal_zone_index
	var resolved_zone := 0
	while (
		resolved_zone < tidal_zone_count - 1
		and _is_tidal_zone_complete(resolved_zone)
	):
		resolved_zone += 1
	active_tidal_zone_index = resolved_zone
	if active_tidal_zone_index == previous_zone:
		return
	if emit_change:
		_refresh_current_endpoint_cells()
		_refresh_all_cells()
		for cell_index in cell_nodes.size():
			cell_nodes[cell_index].set_scan_target_mode(
				scan_target_mode,
				is_scan_candidate(cell_index)
			)
		tidal_zone_changed.emit(active_tidal_zone_index, tidal_zone_count)


func _calculate_adjacent_counts() -> void:
	for cell_index in cell_count:
		adjacent_counts[cell_index] = _adjacent_hazard_count(cell_index)


func _adjacent_hazard_count(cell_index: int) -> int:
	var count := 0
	for neighbor in _get_number_neighbors(cell_index):
		if mines[neighbor] or pollution_nodes[neighbor]:
			count += 1
	return count


func _reveal_area(start_index: int) -> void:
	var queue: Array[int] = [start_index]
	var queued: Array[bool] = []
	_reset_array(queued, false)
	queued[start_index] = true

	while not queue.is_empty():
		var current: int = queue.pop_front()
		if (
			revealed[current]
			or flagged[current]
			or mines[current]
			or obstacles[current]
			or pollution_nodes[current]
		):
			continue

		revealed[current] = true
		revealed_safe_count += 1

		if adjacent_counts[current] > 0:
			continue

		for neighbor in _get_neighbors(current):
			if _has_reef_edge(current, neighbor):
				continue
			if (
				not queued[neighbor]
				and not revealed[neighbor]
				and not flagged[neighbor]
				and not mines[neighbor]
				and not obstacles[neighbor]
				and not pollution_nodes[neighbor]
			):
				queued[neighbor] = true
				queue.push_back(neighbor)


func _rebuild_number_neighbor_graph() -> void:
	number_neighbor_indices.clear()
	for cell_index in cell_count:
		var candidates := (
			_get_hex_neighbors(cell_index)
			if topology == HEX_TOPOLOGY
			else _get_square_neighbors(cell_index)
		)
		var cell_neighbors := PackedInt32Array()
		for neighbor in candidates:
			if not _has_reef_edge(cell_index, neighbor):
				cell_neighbors.append(neighbor)
		number_neighbor_indices.append(cell_neighbors)


func _get_number_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	if not _is_valid_index(cell_index) or number_neighbor_indices.size() != cell_count:
		return neighbors
	for neighbor in number_neighbor_indices[cell_index]:
		neighbors.append(int(neighbor))
	return neighbors


func _get_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	for neighbor in _get_number_neighbors(cell_index):
		if (
			tidal_zone_count > 0
			and tidal_zone_indices[cell_index] != tidal_zone_indices[neighbor]
			and (
				_is_tidal_cell_locked(cell_index)
				or _is_tidal_cell_locked(neighbor)
			)
		):
			continue
		neighbors.append(neighbor)
	return neighbors


func _get_raw_hex_neighbor_records(cell_index: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not _is_valid_index(cell_index):
		return records
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	var offsets: Array = (
		[
			Vector2i(-1, -1), Vector2i(0, -1),
			Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(-1, 1), Vector2i(0, 1),
		]
		if row % 2 == 0
		else [
			Vector2i(0, -1), Vector2i(1, -1),
			Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(0, 1), Vector2i(1, 1),
		]
	)
	var sides := [5, 0, 4, 1, 3, 2]
	for offset_index in offsets.size():
		var offset: Vector2i = offsets[offset_index]
		var neighbor_column: int = column + offset.x
		var neighbor_row: int = row + offset.y
		if neighbor_row < 0 or neighbor_row >= row_count:
			continue
		if neighbor_column < 0 or neighbor_column >= column_count:
			continue
		records.append({
			"index": neighbor_row * column_count + neighbor_column,
			"side": sides[offset_index],
		})
	return records


func _get_hex_side_between(cell_index: int, neighbor_index: int) -> int:
	if topology != HEX_TOPOLOGY:
		return -1
	for record in _get_raw_hex_neighbor_records(cell_index):
		if int(record["index"]) == neighbor_index:
			return int(record["side"])
	return -1


func _get_hex_neighbors(cell_index: int) -> Array[int]:
	var neighbors: Array[int] = []
	var row := int(cell_index / column_count)
	var column := cell_index % column_count
	var offsets: Array = (
		[
			Vector2i(-1, -1), Vector2i(0, -1),
			Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(-1, 1), Vector2i(0, 1),
		]
		if row % 2 == 0
		else [
			Vector2i(0, -1), Vector2i(1, -1),
			Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(0, 1), Vector2i(1, 1),
		]
	)
	for offset_value in offsets:
		var offset: Vector2i = offset_value
		var neighbor_column: int = column + offset.x
		var neighbor_row: int = row + offset.y
		if neighbor_row < 0 or neighbor_row >= row_count:
			continue
		if neighbor_column < 0 or neighbor_column >= column_count:
			continue
		neighbors.append(neighbor_row * column_count + neighbor_column)
	return neighbors


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


func _refresh_all_cells() -> void:
	for cell_index in cell_count:
		_refresh_cell(cell_index)
	_refresh_keyboard_cursor()
	_update_boss_tree_visual()


func _refresh_cell(cell_index: int) -> void:
	var game_finished := game_state == GameState.WON or game_state == GameState.LOST or not interaction_enabled
	var core_visible := game_state == GameState.LOST and mines[cell_index]
	var wrong_flag := game_state == GameState.LOST and flagged[cell_index] and not mines[cell_index]
	var solved_core := game_state == GameState.WON and mines[cell_index]
	var display_adjacent_count := adjacent_counts[cell_index]
	if not cell_nodes.is_empty():
		cell_nodes[cell_index].render_state(
			revealed[cell_index],
			flagged[cell_index],
			core_visible,
			display_adjacent_count,
			game_finished,
			wrong_flag,
			solved_core,
			cell_index == guide_cell_index,
			confirmed[cell_index],
			pollution_nodes[cell_index],
			pollution_nodes_cleansed[cell_index],
			game_state == GameState.WON,
			game_state == GameState.LOST,
			_is_tidal_cell_locked(cell_index)
		)


func _reset_array(array: Array, value: Variant) -> void:
	array.resize(cell_count)
	array.fill(value)


func _is_valid_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < cell_count
