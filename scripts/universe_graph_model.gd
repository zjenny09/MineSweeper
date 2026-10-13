class_name UniverseGraphModel
extends RefCounted

signal changed
signal flags_changed(used_flags: int, total_mines: int)
signal status_changed(text: String)
signal shield_changed(remaining: int, capacity: int)
signal shield_used(node_index: int, remaining: int)
signal region_completed(region_index: int, purified_stars: int)
signal expedition_failed(region_index: int, purified_stars: int)

enum State {
	READY,
	PLAYING,
	REGION_COMPLETE,
	LOST,
}

const MIN_NODE_DISTANCE := 42.0
const SHIELD_CAPACITY := 2
const EARLY_REGION_NODE_COUNTS := [26, 28, 31, 34, 37, 41, 46]
const EARLY_REGION_DENSITIES := [0.09, 0.115, 0.14, 0.165, 0.19, 0.215, 0.24]
const EARLY_REGION_TOPOLOGIES := [0, 1, 1, 2, 3, 4, 4]
const EARLY_REGION_WORMHOLES := [0, 0, 1, 1, 1, 1, 2]
const EARLY_REGION_PROTECTED_NEIGHBORS := [2, 2, 1, 1, 0, 0, 0]
const EARLY_REGION_DISTURBANCE := [1, 1, 2, 3, 4, 5, 5]
const EARLY_REGION_AVERAGE_DEGREES := [3.2, 3.6, 4.0, 4.5, 5.0, 5.5, 6.0]
const EARLY_REGION_SHAPES := [4, 2, 3, 5, 6, 7, 7]
const SHAPE_NAMES := [
	"星云团", "螺旋星臂", "星环", "双星团", "分叉星河",
	"三岛星群", "星核辐射", "多核星群",
]
const TOPOLOGY_NAMES := ["稀疏星链", "混合星网", "密集星网", "星核辐射网", "多恒星枢纽"]

var positions := PackedVector2Array()
var neighbors: Array[PackedInt32Array] = []
var edges: Array[Vector2i] = []
var bridge_edges: Array[Vector2i] = []
var wormhole_edges: Array[Vector2i] = []
var mines := PackedByteArray()
var revealed := PackedByteArray()
var flagged := PackedByteArray()
var adjacent_counts := PackedInt32Array()
var hubs := PackedByteArray()
var state := State.READY
var region_index := 0
var purified_stars := 0
var mine_count := 0
var shape_index := 0
var shape_cluster_count := 1
var shape_name := "星云团"
var topology_name := "稀疏星链"
var world_seed := 0
var shield_remaining := SHIELD_CAPACITY

var _rng := RandomNumberGenerator.new()
var _recent_shape_indices: Array[int] = []


func new_expedition(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
		world_seed = int(_rng.randi())
	else:
		world_seed = seed_value
		_rng.seed = world_seed
	region_index = 0
	purified_stars = 0
	_recent_shape_indices.clear()
	shield_remaining = SHIELD_CAPACITY
	shield_changed.emit(shield_remaining, SHIELD_CAPACITY)
	_generate_region()


func advance_region() -> void:
	if state != State.REGION_COMPLETE:
		return
	region_index += 1
	_generate_region()


func reveal_node(node_index: int) -> void:
	if not _is_valid_node(node_index) or state in [State.REGION_COMPLETE, State.LOST]:
		return
	if flagged[node_index] == 1:
		return
	if revealed[node_index] == 1:
		_chord_node(node_index)
		return
	if state == State.READY:
		_protect_first_cluster(node_index)
		state = State.PLAYING
	if mines[node_index] == 1:
		if shield_remaining > 0:
			shield_remaining -= 1
			if get_used_flags() >= mine_count:
				for candidate in range(flagged.size()):
					if flagged[candidate] == 1 and mines[candidate] == 0:
						flagged[candidate] = 0
						break
			flagged[node_index] = 1
			shield_changed.emit(shield_remaining, SHIELD_CAPACITY)
			shield_used.emit(node_index, shield_remaining)
			flags_changed.emit(get_used_flags(), mine_count)
			status_changed.emit(
				tr("星舰护盾拦截污染核心 · 已自动放置污染标记 · 护盾%d/%d")
				% [shield_remaining, SHIELD_CAPACITY]
			)
			changed.emit()
			return
		revealed[node_index] = 1
		state = State.LOST
		_reveal_all_mines()
		status_changed.emit(tr("航行中断 · 星舰触碰污染核心"))
		expedition_failed.emit(region_index, purified_stars)
		changed.emit()
		return
	_expand_from(node_index)
	_check_region_complete()
	changed.emit()


func toggle_flag(node_index: int) -> void:
	if not _is_valid_node(node_index) or revealed[node_index] == 1 \
			or state in [State.REGION_COMPLETE, State.LOST]:
		return
	if flagged[node_index] == 0 and get_used_flags() >= mine_count:
		status_changed.emit(tr("本区域的污染标记数量已经用完"))
		return
	flagged[node_index] = 0 if flagged[node_index] == 1 else 1
	flags_changed.emit(get_used_flags(), mine_count)
	changed.emit()


func get_used_flags() -> int:
	var total := 0
	for value in flagged:
		total += int(value)
	return total


func get_adjacent_mine_count(node_index: int) -> int:
	if not _is_valid_node(node_index):
		return 0
	var total := 0
	for edge in edges:
		if edge.x == node_index and mines[edge.y] == 1:
			total += 1
		elif edge.y == node_index and mines[edge.x] == 1:
			total += 1
	return total


func get_adjacent_wormhole_mine_count(node_index: int) -> int:
	if not _is_valid_node(node_index):
		return 0
	var total := 0
	for edge in wormhole_edges:
		if edge.x == node_index and mines[edge.y] == 1:
			total += 1
		elif edge.y == node_index and mines[edge.x] == 1:
			total += 1
	return total


func get_snapshot() -> Dictionary:
	var copied_neighbors: Array[PackedInt32Array] = []
	for node_neighbors in neighbors:
		copied_neighbors.append(node_neighbors.duplicate())
	return {
		"positions": positions.duplicate(),
		"neighbors": copied_neighbors,
		"edges": edges.duplicate(),
		"bridge_edges": bridge_edges.duplicate(),
		"wormhole_edges": wormhole_edges.duplicate(),
		"mines": mines.duplicate(),
		"revealed": revealed.duplicate(),
		"flagged": flagged.duplicate(),
		"adjacent_counts": adjacent_counts.duplicate(),
		"hubs": hubs.duplicate(),
		"shape_index": shape_index,
		"shape_name": shape_name,
		"topology_name": topology_name,
		"region_index": region_index,
	}


func refresh_localized_text() -> void:
	match state:
		State.REGION_COMPLETE:
			status_changed.emit(tr("当前星云已经净化 · 前方宇宙正在展开"))
		State.LOST:
			status_changed.emit(tr("航行中断 · 星舰触碰污染核心"))
		_:
			_emit_region_status()


func _choose_region_shape() -> int:
	var selected_shape := 0
	if region_index < EARLY_REGION_SHAPES.size():
		selected_shape = int(EARLY_REGION_SHAPES[region_index])
	else:
		var candidates: Array[int] = []
		for candidate in range(SHAPE_NAMES.size()):
			if not _recent_shape_indices.has(candidate):
				candidates.append(candidate)
		if candidates.is_empty():
			for candidate in range(SHAPE_NAMES.size()):
				candidates.append(candidate)
		selected_shape = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_recent_shape_indices.append(selected_shape)
	while _recent_shape_indices.size() > 2:
		_recent_shape_indices.pop_front()
	return selected_shape


func _generate_region() -> void:
	var node_count := 46
	if region_index < EARLY_REGION_NODE_COUNTS.size():
		node_count = int(EARLY_REGION_NODE_COUNTS[region_index])
	shape_index = _choose_region_shape()
	shape_cluster_count = 1
	if shape_index == 3:
		shape_cluster_count = 2
	elif shape_index == 5:
		shape_cluster_count = 3
	elif shape_index == 7:
		shape_cluster_count = (
			2 if region_index == 5
			else (3 if region_index == 6 else _rng.randi_range(2, 4))
		)
	shape_name = SHAPE_NAMES[shape_index]
	positions = _generate_positions(node_count, shape_index)
	var generated_neighbors := _build_planar_neighbors(positions)
	_commit_graph(generated_neighbors)
	_add_wormhole_edges()
	mines.resize(node_count)
	revealed.resize(node_count)
	flagged.resize(node_count)
	adjacent_counts.resize(node_count)
	hubs.resize(node_count)
	mines.fill(0)
	revealed.fill(0)
	flagged.fill(0)
	adjacent_counts.fill(0)
	hubs.fill(0)
	for node_index in range(node_count):
		if neighbors[node_index].size() >= 7:
			hubs[node_index] = 1
	var density := 0.24
	if region_index < EARLY_REGION_DENSITIES.size():
		density = float(EARLY_REGION_DENSITIES[region_index])
	mine_count = clampi(roundi(float(node_count) * density), 2, node_count - 4)
	var candidates: Array[int] = []
	for node_index in range(node_count):
		candidates.append(node_index)
	_shuffle(candidates)
	for mine_index in range(mine_count):
		mines[candidates[mine_index]] = 1
	_calculate_adjacent_counts()
	state = State.READY
	flags_changed.emit(0, mine_count)
	_emit_region_status()
	changed.emit()


func _emit_region_status() -> void:
	var disturbance_level := 5
	if region_index < EARLY_REGION_DISTURBANCE.size():
		disturbance_level = int(EARLY_REGION_DISTURBANCE[region_index])
	var wormhole_text := (
		tr(" · 虫洞%d条") % wormhole_edges.size()
		if not wormhole_edges.is_empty()
		else ""
	)
	var minimum_degree := 99
	var maximum_degree := 0
	var total_degree := 0
	for node_neighbors in neighbors:
		minimum_degree = mini(minimum_degree, node_neighbors.size())
		maximum_degree = maxi(maximum_degree, node_neighbors.size())
		total_degree += node_neighbors.size()
	var average_degree := float(total_degree) / maxf(1.0, float(neighbors.size()))
	status_changed.emit(
		tr("%s · %s · 邻接%.1f（%d～%d） · 宇宙扰动%d/5%s")
		% [
			tr(shape_name),
			tr(topology_name),
			average_degree,
			minimum_degree,
			maximum_degree,
			disturbance_level,
			wormhole_text,
		]
	)


func _generate_positions(node_count: int, shape_index: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var attempts := 0
	while result.size() < node_count and attempts < node_count * 240:
		attempts += 1
		var point := _candidate_point(result.size(), node_count, shape_index)
		var separated := true
		for existing in result:
			if point.distance_to(existing) < MIN_NODE_DISTANCE:
				separated = false
				break
		if separated:
			result.append(point)
	while result.size() < node_count:
		var fallback_index := result.size()
		var angle := TAU * float(fallback_index) / float(node_count)
		result.append(Vector2(cos(angle) * 315.0, sin(angle) * 215.0))
	return result


func _candidate_point(index: int, node_count: int, shape_index: int) -> Vector2:
	match shape_index:
		1:
			var progress := float(index) / maxf(1.0, float(node_count - 1))
			var angle := progress * TAU * 1.72 + _rng.randf_range(-0.20, 0.20)
			var radius := 64.0 + progress * 285.0 + _rng.randf_range(-28.0, 28.0)
			return Vector2(cos(angle) * radius, sin(angle) * radius * 0.72)
		2:
			var progress := float(index) / maxf(1.0, float(node_count))
			var angle := progress * TAU + _rng.randf_range(-0.08, 0.08)
			var radius := 235.0 + _rng.randf_range(-28.0, 28.0)
			return Vector2(cos(angle) * radius, sin(angle) * radius * 0.76)
		3:
			var cluster_index := index % 2
			var cluster_x := -190.0 if cluster_index == 0 else 190.0
			var angle := _rng.randf_range(0.0, TAU)
			var radius := sqrt(_rng.randf()) * 145.0
			return Vector2(
				cluster_x + cos(angle) * radius,
				sin(angle) * radius * 0.76
			)
		4:
			var branch := _rng.randi_range(-1, 1)
			var x := _rng.randf_range(-330.0, 330.0)
			var spread := absf(x) / 330.0
			return Vector2(
				x,
				sin(x * 0.012) * 58.0 + float(branch) * spread * 145.0
					+ _rng.randf_range(-42.0, 42.0)
			)
		5:
			var centers: Array[Vector2] = [
				Vector2(-220.0, 85.0),
				Vector2(220.0, 85.0),
				Vector2(0.0, -155.0),
			]
			var cluster_index := index % 3
			var local_index := int(index / 3)
			if local_index == 0:
				return centers[cluster_index] + Vector2(
					_rng.randf_range(-8.0, 8.0),
					_rng.randf_range(-8.0, 8.0)
				)
			var angle := _rng.randf_range(0.0, TAU)
			var radius := sqrt(_rng.randf()) * 105.0
			return centers[cluster_index] + Vector2(
				cos(angle) * radius,
				sin(angle) * radius * 0.74
			)
		6:
			if index == 0:
				return Vector2(
					_rng.randf_range(-8.0, 8.0),
					_rng.randf_range(-8.0, 8.0)
				)
			var ring_index := (index - 1) % 2
			var ring_slot := int((index - 1) / 2)
			var ring_size := ceili(float(node_count - 1) / 2.0)
			var angle := (
				TAU * float(ring_slot) / maxf(1.0, float(ring_size))
				+ float(ring_index) * PI / maxf(1.0, float(ring_size))
				+ _rng.randf_range(-0.07, 0.07)
			)
			var radius := (120.0 if ring_index == 0 else 270.0) \
					+ _rng.randf_range(-18.0, 18.0)
			return Vector2(cos(angle) * radius, sin(angle) * radius * 0.72)
		7:
			var cluster_index := index % shape_cluster_count
			var center_angle := -PI * 0.5 + TAU * float(cluster_index) \
					/ float(shape_cluster_count)
			var cluster_center := Vector2(
				cos(center_angle) * 225.0,
				sin(center_angle) * 145.0
			)
			var local_index := int(index / shape_cluster_count)
			if local_index == 0:
				return cluster_center + Vector2(
					_rng.randf_range(-7.0, 7.0),
					_rng.randf_range(-7.0, 7.0)
				)
			var angle := _rng.randf_range(0.0, TAU)
			var radius := sqrt(_rng.randf()) * 112.0
			return cluster_center + Vector2(
				cos(angle) * radius,
				sin(angle) * radius * 0.76
			)
		_:
			var angle := _rng.randf_range(0.0, TAU)
			var radius := sqrt(_rng.randf())
			return Vector2(
				cos(angle) * radius * 330.0,
				sin(angle) * radius * 220.0
			)


func _build_planar_neighbors(points: PackedVector2Array) -> Array[PackedInt32Array]:
	var adjacency: Array[Dictionary] = []
	for _node_index in range(points.size()):
		adjacency.append({})
	bridge_edges.clear()
	var profile_index := 4
	if region_index < EARLY_REGION_TOPOLOGIES.size():
		profile_index = int(EARLY_REGION_TOPOLOGIES[region_index])
	else:
		profile_index = _rng.randi_range(2, 4)
	topology_name = TOPOLOGY_NAMES[profile_index]
	var degree_targets := _build_node_degree_targets(points, profile_index)
	_build_motif_skeleton(adjacency, points)
	_build_connected_backbone(adjacency, points)
	_fill_degree_targets(adjacency, points, degree_targets, false, false)
	_fill_degree_targets(adjacency, points, degree_targets, true, false)
	_fill_degree_targets(adjacency, points, degree_targets, true, true)
	var symmetric_adjacency := _rebuild_symmetric_adjacency(adjacency)
	var result: Array[PackedInt32Array] = []
	for node_links in symmetric_adjacency:
		var packed := PackedInt32Array()
		for neighbor_value in node_links.keys():
			packed.append(int(neighbor_value))
		packed.sort()
		result.append(packed)
	return result


func _build_motif_skeleton(
	adjacency: Array[Dictionary],
	points: PackedVector2Array
) -> void:
	match shape_index:
		2:
			var ring_nodes: Array[int] = []
			for node_index in range(points.size()):
				ring_nodes.append(node_index)
			_connect_cycle(adjacency, points, ring_nodes)
		3, 5:
			for cluster_index in range(shape_cluster_count):
				var cluster_nodes: Array[int] = []
				for node_index in range(points.size()):
					if node_index % shape_cluster_count == cluster_index:
						cluster_nodes.append(node_index)
				_connect_cycle(adjacency, points, cluster_nodes)
			for cluster_index in range(shape_cluster_count - 1):
				_add_edge(adjacency, cluster_index, cluster_index + 1)
			if shape_index == 5 and shape_cluster_count > 2:
				_add_edge(adjacency, shape_cluster_count - 1, 0)
		4:
			var branch_nodes: Array[int] = []
			for node_index in range(points.size()):
				branch_nodes.append(node_index)
			branch_nodes.sort_custom(func(left: int, right: int) -> bool:
				return points[left].x < points[right].x
			)
			for node_offset in range(branch_nodes.size() - 1):
				_add_edge(
					adjacency,
					branch_nodes[node_offset],
					branch_nodes[node_offset + 1]
				)
		6:
			var inner_ring: Array[int] = []
			var outer_ring: Array[int] = []
			for node_index in range(1, points.size()):
				if (node_index - 1) % 2 == 0:
					inner_ring.append(node_index)
				else:
					outer_ring.append(node_index)
			_connect_cycle(adjacency, points, inner_ring)
			_connect_cycle(adjacency, points, outer_ring)
			for spoke_index in range(mini(6, inner_ring.size())):
				var inner_index := inner_ring[
					int(float(spoke_index) * float(inner_ring.size()) / 6.0)
				]
				_add_edge(adjacency, 0, inner_index)
			for radial_index in range(mini(inner_ring.size(), outer_ring.size())):
				if radial_index % 3 == 0:
					_add_edge(adjacency, inner_ring[radial_index], outer_ring[radial_index])
		7:
			for cluster_index in range(shape_cluster_count):
				var cluster_nodes: Array[int] = []
				for node_index in range(points.size()):
					if node_index % shape_cluster_count == cluster_index:
						cluster_nodes.append(node_index)
				_connect_cycle(adjacency, points, cluster_nodes)
				var hub_index := cluster_index
				var spoke_candidates: Array[int] = cluster_nodes.duplicate()
				spoke_candidates.erase(hub_index)
				spoke_candidates.sort_custom(func(left: int, right: int) -> bool:
					return points[hub_index].distance_squared_to(points[left]) \
							< points[hub_index].distance_squared_to(points[right])
				)
				for spoke_index in range(mini(4, spoke_candidates.size())):
					_add_edge(adjacency, hub_index, spoke_candidates[spoke_index])
			for hub_index in range(shape_cluster_count):
				_add_edge(
					adjacency,
					hub_index,
					(hub_index + 1) % shape_cluster_count
				)


func _connect_cycle(
	adjacency: Array[Dictionary],
	points: PackedVector2Array,
	node_indices: Array[int]
) -> void:
	if node_indices.size() < 2:
		return
	var center := Vector2.ZERO
	for node_index in node_indices:
		center += points[node_index]
	center /= float(node_indices.size())
	node_indices.sort_custom(func(left: int, right: int) -> bool:
		return (points[left] - center).angle() < (points[right] - center).angle()
	)
	for node_offset in range(node_indices.size() - 1):
		_add_edge(adjacency, node_indices[node_offset], node_indices[node_offset + 1])
	if node_indices.size() > 2:
		_add_edge(adjacency, node_indices[node_indices.size() - 1], node_indices[0])


func _refresh_connected_set(
	adjacency: Array[Dictionary],
	connected: PackedByteArray
) -> int:
	connected.fill(0)
	if adjacency.is_empty():
		return 0
	var pending: Array[int] = [0]
	connected[0] = 1
	var connected_count := 0
	while not pending.is_empty():
		var node_index: int = pending.pop_back()
		connected_count += 1
		for neighbor_value in adjacency[node_index].keys():
			var neighbor := int(neighbor_value)
			if connected[neighbor] == 1:
				continue
			connected[neighbor] = 1
			pending.append(neighbor)
	return connected_count


func _build_connected_backbone(
	adjacency: Array[Dictionary],
	points: PackedVector2Array
) -> void:
	if points.is_empty():
		return
	var connected := PackedByteArray()
	connected.resize(points.size())
	var connected_count := _refresh_connected_set(adjacency, connected)
	while connected_count < points.size():
		var best_from := -1
		var best_to := -1
		var best_distance := INF
		for from_index in range(points.size()):
			if connected[from_index] == 0:
				continue
			for to_index in range(points.size()):
				if connected[to_index] == 1:
					continue
				var distance := points[from_index].distance_squared_to(points[to_index])
				if distance < best_distance:
					best_distance = distance
					best_from = from_index
					best_to = to_index
		if best_from < 0 or best_to < 0:
			break
		_add_edge(adjacency, best_from, best_to)
		connected_count = _refresh_connected_set(adjacency, connected)


func _fill_degree_targets(
	adjacency: Array[Dictionary],
	points: PackedVector2Array,
	degree_targets: PackedInt32Array,
	allow_crossing: bool,
	allow_saturated_target: bool
) -> void:
	var maximum_iterations := points.size() * points.size() * 4
	for _iteration in maximum_iterations:
		var best_from := -1
		var best_to := -1
		var best_is_bridge := false
		var best_score := INF
		for from_index in range(points.size()):
			var from_deficit := degree_targets[from_index] - adjacency[from_index].size()
			if from_deficit <= 0:
				continue
			for to_index in range(points.size()):
				if to_index == from_index or adjacency[from_index].has(to_index) \
						or adjacency[to_index].size() >= 8:
					continue
				var to_deficit := degree_targets[to_index] - adjacency[to_index].size()
				if to_deficit <= 0 and not allow_saturated_target:
					continue
				var is_planar := _can_add_planar_edge(
					adjacency,
					points,
					from_index,
					to_index
				)
				if not is_planar and not allow_crossing:
					continue
				var score := points[from_index].distance_to(points[to_index])
				if not is_planar:
					score += 120.0
				if to_deficit <= 0:
					score += 360.0
				score -= float(from_deficit + maxi(to_deficit, 0)) * 24.0
				if score < best_score:
					best_score = score
					best_from = from_index
					best_to = to_index
					best_is_bridge = not is_planar
		if best_from < 0 or best_to < 0:
			break
		_add_edge(adjacency, best_from, best_to)
		if best_is_bridge:
			var bridge := Vector2i(
				mini(best_from, best_to),
				maxi(best_from, best_to)
			)
			if not bridge_edges.has(bridge):
				bridge_edges.append(bridge)


func _build_node_degree_targets(
	points: PackedVector2Array,
	profile_index: int
) -> PackedInt32Array:
	var average_degree := 6.0
	if region_index < EARLY_REGION_AVERAGE_DEGREES.size():
		average_degree = float(EARLY_REGION_AVERAGE_DEGREES[region_index])
	var base_degree := clampi(floori(average_degree), 3, 6)
	var target_total := roundi(average_degree * float(points.size()))
	var targets := PackedInt32Array()
	targets.resize(points.size())
	targets.fill(base_degree)
	var candidates: Array[int] = []
	for node_index in range(points.size()):
		candidates.append(node_index)
	_shuffle(candidates)
	var extra_targets := maxi(0, target_total - base_degree * points.size())
	for candidate_index in range(mini(extra_targets, candidates.size())):
		targets[candidates[candidate_index]] = mini(6, base_degree + 1)
	if profile_index == 3 and points.size() >= 6:
		var radial_order: Array[int] = []
		for node_index in range(points.size()):
			radial_order.append(node_index)
		radial_order.sort_custom(func(left: int, right: int) -> bool:
			return points[left].length_squared() < points[right].length_squared()
		)
		for center_index in range(3):
			targets[radial_order[center_index]] = 6
		for outer_offset in range(3):
			var outer_index := radial_order[radial_order.size() - 1 - outer_offset]
			targets[outer_index] = maxi(4, targets[outer_index] - 1)
	if profile_index == 4:
		var hub_candidates: Array[int] = []
		if shape_index == 7:
			for cluster_index in range(shape_cluster_count):
				hub_candidates.append(cluster_index)
		for node_index in range(points.size()):
			if not hub_candidates.has(node_index):
				hub_candidates.append(node_index)
		if shape_index != 7:
			hub_candidates.sort_custom(func(left: int, right: int) -> bool:
				return points[left].length_squared() < points[right].length_squared()
			)
		var hub_count := 2 if region_index < 6 else 3
		var hub_target := 7 if region_index < 6 else 8
		for hub_index in range(mini(hub_count, hub_candidates.size())):
			targets[hub_candidates[hub_index]] = hub_target
	return targets


func _can_add_planar_edge(
	adjacency: Array[Dictionary],
	points: PackedVector2Array,
	from_index: int,
	to_index: int
) -> bool:
	for edge_start in range(adjacency.size()):
		for edge_end_value in adjacency[edge_start].keys():
			var edge_end := int(edge_end_value)
			if edge_start >= edge_end:
				continue
			if edge_start in [from_index, to_index] \
					or edge_end in [from_index, to_index]:
				continue
			var intersection = Geometry2D.segment_intersects_segment(
				points[from_index],
				points[to_index],
				points[edge_start],
				points[edge_end]
			)
			if intersection != null:
				return false
	return true


func _rebuild_symmetric_adjacency(
	source: Array[Dictionary]
) -> Array[Dictionary]:
	var symmetric: Array[Dictionary] = []
	for _node_index in range(source.size()):
		symmetric.append({})
	var canonical_edges := {}
	for from_index in range(source.size()):
		for neighbor_value in source[from_index].keys():
			var to_index := int(neighbor_value)
			if to_index < 0 or to_index >= source.size() or to_index == from_index:
				continue
			var edge := Vector2i(
				mini(from_index, to_index),
				maxi(from_index, to_index)
			)
			canonical_edges[edge] = true
	for edge_value in canonical_edges.keys():
		var edge: Vector2i = edge_value
		symmetric[edge.x][edge.y] = true
		symmetric[edge.y][edge.x] = true
	return symmetric


func _commit_graph(generated_neighbors: Array[PackedInt32Array]) -> void:
	var canonical_edges := {}
	for from_index in range(generated_neighbors.size()):
		for neighbor_value in generated_neighbors[from_index]:
			var to_index := int(neighbor_value)
			if to_index < 0 or to_index >= generated_neighbors.size() \
					or to_index == from_index:
				continue
			var edge := Vector2i(
				mini(from_index, to_index),
				maxi(from_index, to_index)
			)
			canonical_edges[edge] = true
	edges.clear()
	for edge_value in canonical_edges.keys():
		var edge: Vector2i = edge_value
		edges.append(edge)
	edges.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		return left.x < right.x or (left.x == right.x and left.y < right.y)
	)
	_rebuild_neighbors_from_edges()


func _rebuild_neighbors_from_edges() -> void:
	neighbors.clear()
	for _node_index in range(positions.size()):
		neighbors.append(PackedInt32Array())
	for edge in edges:
		neighbors[edge.x].append(edge.y)
		neighbors[edge.y].append(edge.x)


func _add_wormhole_edges() -> void:
	wormhole_edges.clear()
	var desired_count := 2
	if region_index < EARLY_REGION_WORMHOLES.size():
		desired_count = int(EARLY_REGION_WORMHOLES[region_index])
	if desired_count <= 0:
		return
	var minimum_wormhole_distance := 340.0 if region_index < 7 else 360.0
	var candidates: Array[Vector2i] = []
	for from_index in range(positions.size()):
		if neighbors[from_index].size() >= 8:
			continue
		for to_index in range(from_index + 1, positions.size()):
			if neighbors[to_index].size() >= 8 \
					or neighbors[from_index].has(to_index):
				continue
			if positions[from_index].distance_to(positions[to_index]) \
					< minimum_wormhole_distance:
				continue
			candidates.append(Vector2i(from_index, to_index))
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	var used_nodes := {}
	for candidate in candidates:
		if wormhole_edges.size() >= desired_count:
			break
		if used_nodes.has(candidate.x) or used_nodes.has(candidate.y):
			continue
		wormhole_edges.append(candidate)
		edges.append(candidate)
		used_nodes[candidate.x] = true
		used_nodes[candidate.y] = true
	edges.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		return left.x < right.x or (left.x == right.x and left.y < right.y)
	)
	_rebuild_neighbors_from_edges()


func _add_edge(adjacency: Array[Dictionary], a: int, b: int) -> void:
	if a == b:
		return
	adjacency[a][b] = true
	adjacency[b][a] = true


func _protect_first_cluster(node_index: int) -> void:
	var protected_nodes := {node_index: true}
	var nearby_nodes: Array[int] = []
	for neighbor in neighbors[node_index]:
		nearby_nodes.append(int(neighbor))
	_shuffle(nearby_nodes)
	var protected_neighbor_count := 0
	if region_index < EARLY_REGION_PROTECTED_NEIGHBORS.size():
		protected_neighbor_count = int(EARLY_REGION_PROTECTED_NEIGHBORS[region_index])
	for nearby_index in range(mini(protected_neighbor_count, nearby_nodes.size())):
		protected_nodes[nearby_nodes[nearby_index]] = true
	var mine_sources: Array[int] = []
	var destinations: Array[int] = []
	for candidate in range(mines.size()):
		if protected_nodes.has(candidate):
			if mines[candidate] == 1 and flagged[candidate] == 0:
				mine_sources.append(candidate)
		elif mines[candidate] == 0 and flagged[candidate] == 0:
			destinations.append(candidate)
	_shuffle(destinations)
	for source_index in range(mini(mine_sources.size(), destinations.size())):
		mines[mine_sources[source_index]] = 0
		mines[destinations[source_index]] = 1
	_calculate_adjacent_counts()


func _calculate_adjacent_counts() -> void:
	adjacent_counts.fill(0)
	for node_index in range(adjacent_counts.size()):
		adjacent_counts[node_index] = get_adjacent_mine_count(node_index)


func _expand_from(start_index: int) -> void:
	var pending: Array[int] = [start_index]
	var visited := {}
	while not pending.is_empty():
		var node_index: int = pending.pop_back()
		if visited.has(node_index):
			continue
		visited[node_index] = true
		if flagged[node_index] == 1 or revealed[node_index] == 1 or mines[node_index] == 1:
			continue
		revealed[node_index] = 1
		if get_adjacent_mine_count(node_index) == 0:
			for neighbor in neighbors[node_index]:
				if not visited.has(int(neighbor)):
					pending.append(int(neighbor))


func _chord_node(node_index: int) -> void:
	var adjacent_mines := get_adjacent_mine_count(node_index)
	if adjacent_mines <= 0:
		return
	var adjacent_flags := 0
	for neighbor in neighbors[node_index]:
		adjacent_flags += int(flagged[neighbor])
	if adjacent_flags != adjacent_mines:
		return
	for neighbor in neighbors[node_index]:
		if (flagged[neighbor] == 1) != (mines[neighbor] == 1):
			status_changed.emit(tr("污染标记位置不正确，星链没有展开"))
			return
	for neighbor in neighbors[node_index]:
		if flagged[neighbor] == 0 and revealed[neighbor] == 0:
			_expand_from(int(neighbor))
	_check_region_complete()


func _check_region_complete() -> void:
	for node_index in range(mines.size()):
		if mines[node_index] == 0 and revealed[node_index] == 0:
			return
	var safe_count := mines.size() - mine_count
	purified_stars += safe_count
	var shield_restored := false
	var reaches_shield_checkpoint := (
		region_index >= 6
		and (region_index - 6) % 5 == 0
	)
	if reaches_shield_checkpoint and shield_remaining < SHIELD_CAPACITY:
		shield_remaining += 1
		shield_restored = true
		shield_changed.emit(shield_remaining, SHIELD_CAPACITY)
	state = State.REGION_COMPLETE
	status_changed.emit(
		tr("当前星云已经净化 · 护盾恢复1层 · 前方宇宙正在展开")
		if shield_restored
		else tr("当前星云已经净化 · 前方宇宙正在展开")
	)
	region_completed.emit(region_index, purified_stars)


func _reveal_all_mines() -> void:
	for node_index in range(mines.size()):
		if mines[node_index] == 1:
			revealed[node_index] = 1


func _shuffle(values: Array[int]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _is_valid_node(node_index: int) -> bool:
	return node_index >= 0 and node_index < positions.size()
