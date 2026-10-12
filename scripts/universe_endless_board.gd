class_name UniverseEndlessBoard
extends Control

signal flags_changed(used_flags: int, total_mines: int)
signal shield_changed(remaining: int, capacity: int)
signal status_changed(text: String)
signal board_interacted
signal voyage_stats_changed(regions: int, purified_stars: int, distance: int)
signal expedition_failed(regions: int, purified_stars: int, distance: int)
signal warp_changed(active: bool)
signal region_started(region_index: int, wormhole_count: int)

const MODEL_SCRIPT := preload("res://scripts/universe_graph_model.gd")
const UI_FONT := preload("res://assets/art/common/fonts/ui_handwritten_zh.ttf")
const REGION_SPACING := 690.0
const REGION_TRANSITION_DELAY := 1.05
const CAMERA_TRANSITION_DURATION := 1.10
const SHIELD_EFFECT_DURATION := 0.78
const NUMBER_COLORS := [
	Color("2d6f91"),
	Color("3d7d5a"),
	Color("9a742c"),
	Color("a64f62"),
	Color("6f5a9d"),
	Color("397b7a"),
	Color("a66536"),
	Color("384857"),
]

var model := MODEL_SCRIPT.new()
var archived_regions: Array[Dictionary] = []
var hovered_node := -1
var _camera_x := 0.0
var _camera_start_x := 0.0
var _camera_target_x := 0.0
var _camera_transition_time := CAMERA_TRANSITION_DURATION
var _region_transition_time := 0.0
var _transition_pending := false
var _warp_active := false
var _shield_effect_node := -1
var _shield_effect_time := 0.0
var _elapsed := 0.0
var _background_stars := PackedVector2Array()
var _background_star_sizes := PackedFloat32Array()
var _background_rng := RandomNumberGenerator.new()
var _interaction_enabled := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	model.changed.connect(_on_model_changed)
	model.flags_changed.connect(func(used: int, total: int) -> void:
		flags_changed.emit(used, total)
	)
	model.shield_changed.connect(func(remaining: int, capacity: int) -> void:
		shield_changed.emit(remaining, capacity)
	)
	model.shield_used.connect(_on_shield_used)
	model.status_changed.connect(func(text: String) -> void:
		status_changed.emit(text)
	)
	model.region_completed.connect(_on_region_completed)
	model.expedition_failed.connect(_on_expedition_failed)
	_generate_background_stars()
	set_process(true)


func new_expedition(seed_value: int = 0) -> void:
	archived_regions.clear()
	hovered_node = -1
	_camera_x = 0.0
	_camera_start_x = 0.0
	_camera_target_x = 0.0
	_camera_transition_time = CAMERA_TRANSITION_DURATION
	_region_transition_time = 0.0
	_transition_pending = false
	_shield_effect_node = -1
	_shield_effect_time = 0.0
	if _warp_active:
		_warp_active = false
		warp_changed.emit(false)
	model.new_expedition(seed_value)
	region_started.emit(model.region_index, model.wormhole_edges.size())
	_emit_voyage_stats()
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _shield_effect_time > 0.0:
		_shield_effect_time = maxf(0.0, _shield_effect_time - delta)
		if _shield_effect_time <= 0.0:
			_shield_effect_node = -1
	if _transition_pending:
		_region_transition_time += delta
		if _region_transition_time >= REGION_TRANSITION_DELAY:
			_finish_region_transition()
	if _camera_transition_time < CAMERA_TRANSITION_DURATION:
		_camera_transition_time = minf(
			CAMERA_TRANSITION_DURATION,
			_camera_transition_time + delta
		)
		var progress := _camera_transition_time / CAMERA_TRANSITION_DURATION
		var eased := 1.0 - pow(1.0 - progress, 3.0)
		_camera_x = lerpf(_camera_start_x, _camera_target_x, eased)
		if _camera_transition_time >= CAMERA_TRANSITION_DURATION and _warp_active:
			_warp_active = false
			warp_changed.emit(false)
	queue_redraw()


func _draw() -> void:
	for archive in archived_regions:
		_draw_archived_region(archive)
	_draw_current_region()
	if _shield_effect_node >= 0 and _shield_effect_time > 0.0:
		_draw_shield_effect()
	if _transition_pending:
		_draw_frontier_glow()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		hovered_node = -1
	queue_redraw()


func get_mechanic_guide_target_global_position(
	guide_id: StringName
) -> Vector2:
	var edge := Vector2i(-1, -1)
	if guide_id == &"universe_wormholes" and not model.wormhole_edges.is_empty():
		edge = model.wormhole_edges[0]
	elif not model.edges.is_empty():
		edge = model.edges[0]
	if edge.x < 0 or edge.y < 0 \
			or edge.x >= model.positions.size() \
			or edge.y >= model.positions.size():
		return get_global_rect().get_center()
	var region_offset := Vector2(float(model.region_index) * REGION_SPACING, 0.0)
	var local_target := (
		_world_to_screen(region_offset + model.positions[edge.x])
		+ _world_to_screen(region_offset + model.positions[edge.y])
	) * 0.5
	return get_global_transform_with_canvas() * local_target


func _gui_input(event: InputEvent) -> void:
	if not _interaction_enabled:
		return
	if event is InputEventMouseMotion:
		var next_hover := _node_at_position(
			(event as InputEventMouseMotion).position
		)
		if next_hover != hovered_node:
			hovered_node = next_hover
			if hovered_node >= 0:
				var live_count := int(model.call(
					"get_adjacent_mine_count",
					hovered_node
				))
				var wormhole_count := int(model.call(
					"get_adjacent_wormhole_mine_count",
					hovered_node
				))
				if model.revealed[hovered_node] == 1 and live_count > 0:
					status_changed.emit(
						"数字%d = 普通星链污染%d + 虫洞污染%d · 共%d个邻星"
						% [
							live_count,
							live_count - wormhole_count,
							wormhole_count,
							model.neighbors[hovered_node].size(),
						]
					)
				else:
					status_changed.emit(
						"当前星核连接%d颗邻星 · 数字只统计这些线的另一端"
						% model.neighbors[hovered_node].size()
					)
		queue_redraw()
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or _transition_pending:
		return
	var node_index := _node_at_position(mouse_event.position)
	if node_index < 0:
		return
	if mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		board_interacted.emit()
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		model.reveal_node(node_index)
		accept_event()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		model.toggle_flag(node_index)
		accept_event()


func _draw_space_background() -> void:
	var center := size * 0.5
	for radius in [215.0, 315.0, 420.0]:
		draw_arc(
			center + Vector2(32.0, -8.0),
			radius,
			-0.35,
			TAU * 0.66,
			96,
			Color(0.72, 0.69, 0.55, 0.055),
			1.0
		)


func _draw_travel_path() -> void:
	if model.region_index <= 0:
		return
	for region_number in range(maxi(0, model.region_index - 5), model.region_index):
		var from_world := Vector2(float(region_number) * REGION_SPACING, 0.0)
		var to_world := Vector2(float(region_number + 1) * REGION_SPACING, 0.0)
		var from_screen := _world_to_screen(from_world)
		var to_screen := _world_to_screen(to_world)
		draw_dashed_line(
			from_screen,
			to_screen,
			Color(0.70, 0.73, 0.67, 0.28),
			2.0,
			12.0
		)


func _draw_archived_region(archive: Dictionary) -> void:
	var region_number := int(archive["region_index"])
	if region_number < model.region_index - 3:
		return
	var offset := Vector2(float(region_number) * REGION_SPACING, 0.0)
	var archive_positions: PackedVector2Array = archive["positions"]
	var archive_edges: Array = archive["edges"]
	for edge_value in archive_edges:
		var edge: Vector2i = edge_value
		draw_line(
			_world_to_screen(offset + archive_positions[edge.x]),
			_world_to_screen(offset + archive_positions[edge.y]),
			Color(0.67, 0.72, 0.72, 0.24),
			1.0
		)
	for node_index in range(archive_positions.size()):
		var center := _world_to_screen(offset + archive_positions[node_index])
		var glow := 4.4 + sin(_elapsed * 0.8 + float(node_index)) * 0.7
		draw_circle(center, glow, Color(0.72, 0.78, 0.74, 0.20))
		draw_circle(center, 2.2, Color(0.94, 0.91, 0.80, 0.74))


func _draw_current_region() -> void:
	var offset := Vector2(float(model.region_index) * REGION_SPACING, 0.0)
	for edge in model.edges:
		var emphasized := hovered_node == edge.x or hovered_node == edge.y
		var raw_from := _world_to_screen(offset + model.positions[edge.x])
		var raw_to := _world_to_screen(offset + model.positions[edge.y])
		var endpoints := _trimmed_edge_endpoints(raw_from, raw_to, edge)
		if model.wormhole_edges.has(edge):
			_draw_wormhole_edge(
				raw_from,
				raw_to,
				edge,
				emphasized
			)
			continue
		if model.bridge_edges.has(edge):
			_draw_bridge_edge(
				endpoints[0],
				endpoints[1],
				edge,
				emphasized
			)
			continue
		var color := (
			Color(0.96, 0.78, 0.33, 0.92)
			if emphasized
			else (
				Color(0.70, 0.76, 0.77, 0.16)
				if hovered_node >= 0
				else Color(0.70, 0.76, 0.77, 0.58)
			)
		)
		draw_line(
			endpoints[0],
			endpoints[1],
			color,
			2.8 if emphasized else 1.45,
			true
		)
	for node_index in range(model.positions.size()):
		_draw_current_node(node_index, offset + model.positions[node_index])


func _trimmed_edge_endpoints(
	from_position: Vector2,
	to_position: Vector2,
	edge: Vector2i
) -> PackedVector2Array:
	var direction := (to_position - from_position).normalized()
	var from_radius := 22.0 if model.hubs[edge.x] == 1 else 17.0
	var to_radius := 22.0 if model.hubs[edge.y] == 1 else 17.0
	return PackedVector2Array([
		from_position + direction * from_radius,
		to_position - direction * to_radius,
	])


func _draw_bridge_edge(
	from_position: Vector2,
	to_position: Vector2,
	edge: Vector2i,
	emphasized: bool
) -> void:
	var direction := to_position - from_position
	var perpendicular := Vector2(-direction.y, direction.x).normalized()
	var bend_direction := -1.0 if (edge.x * 3 + edge.y) % 2 == 0 else 1.0
	var control := (
		(from_position + to_position) * 0.5
		+ perpendicular * clampf(direction.length() * 0.13, 18.0, 58.0) * bend_direction
	)
	var curve := PackedVector2Array()
	for step in range(19):
		var t := float(step) / 18.0
		var inverse := 1.0 - t
		curve.append(
			inverse * inverse * from_position
			+ 2.0 * inverse * t * control
			+ t * t * to_position
		)
	var alpha := 0.90 if emphasized else (0.14 if hovered_node >= 0 else 0.50)
	draw_polyline(curve, Color(0.38, 0.72, 0.86, alpha), 3.2 if emphasized else 2.2, true)
	draw_polyline(curve, Color(0.78, 0.91, 0.94, alpha * 0.72), 1.0, true)
	draw_circle(curve[9], 2.8 if emphasized else 2.0, Color(0.88, 0.96, 0.95, alpha))


func _draw_wormhole_edge(
	from_position: Vector2,
	to_position: Vector2,
	edge: Vector2i,
	emphasized: bool
) -> void:
	var direction := to_position - from_position
	var perpendicular := Vector2(-direction.y, direction.x).normalized()
	var bend_direction := -1.0 if (edge.x + edge.y) % 2 == 0 else 1.0
	var control := (
		(from_position + to_position) * 0.5
		+ perpendicular * minf(96.0, direction.length() * 0.22) * bend_direction
	)
	var curve := PackedVector2Array()
	for step in range(25):
		var t := float(step) / 24.0
		var inverse := 1.0 - t
		curve.append(
			inverse * inverse * from_position
			+ 2.0 * inverse * t * control
			+ t * t * to_position
		)
	var alpha := 0.92 if emphasized else (0.22 if hovered_node >= 0 else 0.70)
	draw_polyline(curve, Color(0.70, 0.35, 0.96, alpha), 4.2, true)
	draw_polyline(curve, Color(0.88, 0.72, 1.0, alpha * 0.72), 1.25, true)
	var pulse_t := fposmod(_elapsed * 0.52 + float(edge.x) * 0.13, 1.0)
	var pulse_inverse := 1.0 - pulse_t
	var pulse_position := (
		pulse_inverse * pulse_inverse * from_position
		+ 2.0 * pulse_inverse * pulse_t * control
		+ pulse_t * pulse_t * to_position
	)
	draw_circle(pulse_position, 3.8 if emphasized else 2.7, Color(0.94, 0.82, 1.0, alpha))
	for endpoint_value in [from_position, to_position]:
		var endpoint: Vector2 = endpoint_value
		draw_arc(endpoint, 20.5, _elapsed, _elapsed + TAU * 0.76, 24, Color(0.74, 0.43, 1.0, alpha), 2.0)


func _draw_current_node(node_index: int, world_position: Vector2) -> void:
	var center := _world_to_screen(world_position)
	var is_hub := model.hubs[node_index] == 1
	var radius := 20.0 if is_hub else 15.0
	var live_adjacent_count := int(model.call("get_adjacent_mine_count", node_index))
	var is_hovered := node_index == hovered_node
	var is_linked_to_hover := (
		hovered_node >= 0
		and model.neighbors[hovered_node].has(node_index)
	)
	if is_hub:
		draw_circle(center, radius + 8.0, Color(0.76, 0.68, 0.45, 0.18))
		draw_arc(
			center,
			radius + 5.0,
			_elapsed * 0.32,
			_elapsed * 0.32 + TAU * 0.78,
			32,
			Color(0.88, 0.76, 0.43, 0.82),
			2.0
		)
	if is_linked_to_hover:
		draw_circle(center, radius + 5.0, Color(0.95, 0.77, 0.30, 0.18))
	var fill := Color("e8e1d0")
	var edge := Color("8297a0")
	if model.revealed[node_index] == 1:
		if model.mines[node_index] == 1:
			fill = Color("70506f")
			edge = Color("b46b91")
		else:
			fill = Color("badce2")
			edge = Color("568996")
	elif model.flagged[node_index] == 1:
		fill = Color("d9e1db")
		edge = Color("c49535")
	if is_hovered:
		edge = Color("d2a23b")
		draw_circle(center, radius + 5.0, Color(0.91, 0.70, 0.22, 0.20))
	draw_circle(center, radius + 2.0, Color(edge, 0.24))
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 32, edge, 2.0)
	draw_circle(center + Vector2(-radius * 0.34, -radius * 0.38), 2.6, Color(1, 1, 1, 0.42))
	if model.flagged[node_index] == 1 and model.revealed[node_index] == 0:
		_draw_beacon(center, radius)
	elif model.revealed[node_index] == 1 and model.mines[node_index] == 1:
		_draw_pollution_core(center, radius)
	elif model.revealed[node_index] == 1 and live_adjacent_count > 0:
		_draw_number(center, live_adjacent_count, radius)
	if model.state == MODEL_SCRIPT.State.LOST and model.flagged[node_index] == 1 \
			and model.mines[node_index] == 0:
		draw_line(center + Vector2(-7, -7), center + Vector2(7, 7), Color("ff718e"), 2.5)
		draw_line(center + Vector2(7, -7), center + Vector2(-7, 7), Color("ff718e"), 2.5)


func _draw_beacon(center: Vector2, radius: float) -> void:
	draw_arc(
		center,
		radius + 5.0,
		_elapsed * 1.7,
		_elapsed * 1.7 + TAU * 0.70,
		24,
		Color("ffd166"),
		2.2
	)
	var triangle := PackedVector2Array([
		center + Vector2(0.0, -8.0),
		center + Vector2(7.0, 6.0),
		center + Vector2(-7.0, 6.0),
	])
	draw_colored_polygon(triangle, Color("ffe58a"))


func _draw_pollution_core(center: Vector2, radius: float) -> void:
	for arm_index in range(5):
		var angle := _elapsed * 0.8 + float(arm_index) * TAU / 5.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(
			center + direction * 3.0,
			center + direction * (radius - 3.0),
			Color(0.87, 0.36, 0.73, 0.72),
			2.0
		)
	draw_circle(center, 5.0, Color("d455a6"))
	draw_circle(center - Vector2(1.5, 1.5), 1.8, Color(1, 0.78, 0.95, 0.85))


func _draw_number(center: Vector2, value: int, radius: float) -> void:
	var text := str(value)
	var font_size := 18 if radius > 16.0 else 15
	var color: Color = NUMBER_COLORS[clampi(value - 1, 0, NUMBER_COLORS.size() - 1)]
	draw_string(
		UI_FONT,
		center + Vector2(-radius, float(font_size) * 0.36),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		radius * 2.0,
		font_size,
		color
	)


func _draw_shield_effect() -> void:
	if _shield_effect_node < 0 or _shield_effect_node >= model.positions.size():
		return
	var offset := Vector2(float(model.region_index) * REGION_SPACING, 0.0)
	var center := _world_to_screen(offset + model.positions[_shield_effect_node])
	var progress := 1.0 - _shield_effect_time / SHIELD_EFFECT_DURATION
	for ring_index in range(3):
		var radius := 24.0 + progress * 34.0 + float(ring_index) * 8.0
		draw_arc(
			center,
			radius,
			-progress * 2.0 + float(ring_index) * 0.7,
			-progress * 2.0 + float(ring_index) * 0.7 + TAU * 0.82,
			40,
			Color(0.45, 0.84, 1.0, (1.0 - progress) * 0.76),
			2.8
		)


func _draw_frontier_glow() -> void:
	var center := _world_to_screen(
		Vector2(float(model.region_index) * REGION_SPACING + 375.0, 0.0)
	)
	var progress := clampf(_region_transition_time / REGION_TRANSITION_DELAY, 0.0, 1.0)
	for ring_index in range(4):
		var radius := 28.0 + float(ring_index) * 17.0 + progress * 30.0
		draw_arc(
			center,
			radius,
			-progress * 1.8 + float(ring_index),
			-progress * 1.8 + float(ring_index) + TAU * 0.72,
			40,
			Color(0.44, 0.83, 1.0, 0.46 - float(ring_index) * 0.08),
			2.4
		)


func _node_at_position(screen_position: Vector2) -> int:
	if model.state in [MODEL_SCRIPT.State.REGION_COMPLETE, MODEL_SCRIPT.State.LOST]:
		return -1
	var offset := Vector2(float(model.region_index) * REGION_SPACING, 0.0)
	var best_index := -1
	var best_distance := INF
	for node_index in range(model.positions.size()):
		var center := _world_to_screen(offset + model.positions[node_index])
		var radius := 25.0 if model.hubs[node_index] == 1 else 20.0
		var distance := center.distance_to(screen_position)
		if distance <= radius and distance < best_distance:
			best_distance = distance
			best_index = node_index
	return best_index


func _world_to_screen(world_position: Vector2) -> Vector2:
	return world_position - Vector2(_camera_x, 0.0) + size * 0.5


func _on_shield_used(node_index: int, _remaining: int) -> void:
	_shield_effect_node = node_index
	_shield_effect_time = SHIELD_EFFECT_DURATION
	queue_redraw()


func _on_model_changed() -> void:
	queue_redraw()


func _on_region_completed(region_index: int, purified_stars: int) -> void:
	_transition_pending = true
	_region_transition_time = 0.0
	hovered_node = -1
	_warp_active = true
	warp_changed.emit(true)
	voyage_stats_changed.emit(
		region_index + 1,
		purified_stars,
		(region_index + 1) * 1000
	)


func _finish_region_transition() -> void:
	_transition_pending = false
	archived_regions.append(model.get_snapshot())
	while archived_regions.size() > 4:
		archived_regions.pop_front()
	model.advance_region()
	region_started.emit(model.region_index, model.wormhole_edges.size())
	_camera_start_x = _camera_x
	_camera_target_x = float(model.region_index) * REGION_SPACING
	_camera_transition_time = 0.0
	_emit_voyage_stats()


func _on_expedition_failed(region_index: int, purified_stars: int) -> void:
	hovered_node = -1
	expedition_failed.emit(
		region_index,
		purified_stars,
		region_index * 1000
	)


func _emit_voyage_stats() -> void:
	voyage_stats_changed.emit(
		model.region_index,
		model.purified_stars,
		model.region_index * 1000
	)


func _generate_background_stars() -> void:
	_background_rng.seed = 732451
	_background_stars.resize(0)
	_background_star_sizes.resize(0)
	for _index in range(86):
		_background_stars.append(Vector2(
			_background_rng.randf_range(0.0, 920.0),
			_background_rng.randf_range(0.0, 560.0)
		))
		_background_star_sizes.append(_background_rng.randf_range(0.6, 1.8))
