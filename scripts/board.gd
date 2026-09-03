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

const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")
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
var _pollution_animation_active := false
var _pollution_elapsed := 0.0
var _pollution_origin_index := -1

var mines: Array[bool] = []
var revealed: Array[bool] = []
var flagged: Array[bool] = []
var ever_flagged: Array[bool] = []
var confirmed: Array[bool] = []
var adjacent_counts: Array[int] = []
var cell_nodes: Array[MineCell] = []

var _random := RandomNumberGenerator.new()
var _handmade_surface: Control
var _ocean_shared_edges: Array[PackedVector2Array] = []


func _ready() -> void:
	_random.randomize()
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
	level_number = level.number
	level_name = level.name
	var board_size: Vector2i = level.size
	column_count = board_size.x
	row_count = board_size.y
	cell_count = row_count * column_count
	core_count = level.core_count
	safe_cell_count = cell_count - core_count
	topology = StringName(level.get("topology", &"square"))
	first_move_guide_enabled = level.get("first_move_guide", false)

	_clear_cells()
	_create_cells()
	new_game()


func new_game() -> void:
	_reset_pollution_animation()
	game_state = GameState.READY
	used_flags = 0
	revealed_safe_count = 0
	move_count = 0
	reveal_action_count = 0
	scan_target_mode = false
	guide_cell_index = -1
	for cell in cell_nodes:
		cell.reset_transient_visuals()
	_reset_array(mines, false)
	_reset_array(revealed, false)
	_reset_array(flagged, false)
	_reset_array(ever_flagged, false)
	_reset_array(confirmed, false)
	_reset_array(adjacent_counts, 0)
	_place_random_cores()
	_calculate_adjacent_counts()
	if first_move_guide_enabled:
		guide_cell_index = _choose_guide_cell()
	_reset_keyboard_cursor()
	_refresh_all_cells()
	state_changed.emit(game_state)
	flags_changed.emit(used_flags, core_count)


func set_opening_assist_mode(mode: int) -> void:
	opening_assist_mode = clampi(mode, OpeningAssist.NONE, OpeningAssist.OPEN_REGION)


func reveal_cell(cell_index: int) -> void:
	if not interaction_enabled or not _is_valid_index(cell_index):
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
	var completed_game := revealed_safe_count == safe_cell_count
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
		_refresh_cell(cell_index)
		cell_nodes[cell_index].play_scan_result(ScanResult.MINE)
		flags_changed.emit(used_flags, core_count)
		scan_completed.emit(cell_index, ScanResult.MINE, 0)
		return true

	var previous_revealed_count := revealed_safe_count
	_reveal_area(cell_index)
	var completed_game := revealed_safe_count == safe_cell_count
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
	if not interaction_enabled or not _is_valid_index(cell_index):
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
	flag_completed.emit(cell_index, flagged[cell_index], is_first_placement)


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

	move_count += 1
	var previous_revealed_count := revealed_safe_count
	for neighbor in neighbors:
		if not mines[neighbor] and not flagged[neighbor] and not revealed[neighbor]:
			_reveal_area(neighbor)

	var completed_game := revealed_safe_count == safe_cell_count
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

	for cell_index in cell_count:
		var cell := _make_cell(cell_index)
		cell.custom_minimum_size = Vector2.ZERO
		_handmade_surface.add_child(cell)

	_layout_cells()
	call_deferred("_layout_cells")


func _make_cell(cell_index: int) -> MineCell:
	var cell := CELL_SCENE.instantiate() as MineCell
	cell.focus_mode = Control.FOCUS_NONE
	cell.setup(cell_index, level_number, topology)
	cell.reveal_requested.connect(reveal_cell)
	cell.flag_requested.connect(toggle_flag)
	cell.chord_requested.connect(chord_cell)
	cell.scan_requested.connect(_on_cell_scan_requested)
	cell.scan_cancel_requested.connect(_on_cell_scan_cancel_requested)
	cell_nodes.append(cell)
	return cell


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
		var side := minf(slot_rect.size.x, slot_rect.size.y) * LEVEL_ONE_CELL_SLOT_FILL
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
		cell.set_hex_fill_ratio(HEX_CELL_FILL)
		cell.add_theme_font_size_override(
			"font_size",
			clampi(roundi(radius * 0.72), 11, 30)
		)
		cell.add_theme_constant_override("outline_size", 2)
	_update_ocean_paper_geometry()
	queue_redraw()


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
	if level_number < 1 or level_number > 5:
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
	if opening_assist_mode == OpeningAssist.OPEN_REGION:
		protected_cells.append_array(_get_neighbors(cell_index))

	var relocated_core_count := 0
	for protected_index in protected_cells:
		if mines[protected_index]:
			mines[protected_index] = false
			relocated_core_count += 1
	if relocated_core_count == 0:
		return

	var relocation_candidates: Array[int] = []
	for candidate_index in cell_count:
		if not mines[candidate_index] and not protected_cells.has(candidate_index):
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
	for index in relocated_core_count:
		mines[relocation_candidates[index]] = true
	_reset_array(adjacent_counts, 0)
	_calculate_adjacent_counts()
	assert(mines.count(true) == core_count, "Opening assistance must preserve the core count.")


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
	if topology == HEX_TOPOLOGY:
		return _get_hex_neighbors(cell_index)
	return _get_square_neighbors(cell_index)


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


func _refresh_cell(cell_index: int) -> void:
	var game_finished := game_state == GameState.WON or game_state == GameState.LOST or not interaction_enabled
	var core_visible := game_state == GameState.LOST and mines[cell_index]
	var wrong_flag := game_state == GameState.LOST and flagged[cell_index] and not mines[cell_index]
	var solved_core := game_state == GameState.WON and mines[cell_index]
	if not cell_nodes.is_empty():
		cell_nodes[cell_index].render_state(
			revealed[cell_index],
			flagged[cell_index],
			core_visible,
			adjacent_counts[cell_index],
			game_finished,
			wrong_flag,
			solved_core,
			cell_index == guide_cell_index,
			confirmed[cell_index]
		)


func _reset_array(array: Array, value: Variant) -> void:
	array.resize(cell_count)
	array.fill(value)


func _is_valid_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < cell_count
