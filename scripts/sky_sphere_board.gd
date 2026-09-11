class_name SkySphereBoard
extends Control

signal flags_changed(used_flags: int, max_flags: int)
signal status_changed(text: String)
signal gameplay_state_changed(state: int)
signal first_reveal
signal scan_energy_earned
signal scan_target_requested(face_index: int)
signal scan_cancel_requested
signal scan_completed(face_index: int, result: int)

const GRAPH_MODEL_SCRIPT := preload("res://scripts/sky_graph_board_model.gd")
const STRUCTURE_DATA_PATH := "res://assets/data/sky_sphere_structures.json"
const BASE_FACE_COUNT := 32
const FACE_RADIUS := 2.05
const CORE_COUNT := 6
const DRAG_THRESHOLD := 6.0
const FRONT_FACE_EPSILON := 0.001
const LABEL_FADE_START := 0.12
const LABEL_FADE_END := 0.42
const CORE_MONSTER_MIN_FRONTNESS := 0.32
const CORE_MONSTER_FADE_END := 0.56
const MIN_LABEL_SIZE := 18
const MAX_LABEL_SIZE := 32
const DASH_LENGTH := 7.0
const DASH_GAP := 4.5

const OUTLINE_COLOR := Color("667b85")
const HOVER_COLOR := Color("fff0a8")
const FOCUS_COLOR := Color("ffc857")
const SKY_FLAG_NORMAL_TEXTURE := preload(
	"res://assets/art/sky_levels/markers/sky_flag_plane_normal.png"
)
const SKY_FLAG_FAILED_TEXTURE := preload(
	"res://assets/art/sky_levels/markers/sky_flag_plane_failed.png"
)
const SKY_MARKER_WRONG_TEXTURE := preload(
	"res://assets/art/sky_levels/markers/sky_marker_wrong_cloud.png"
)
const CORE_MONSTER_TEXTURE := preload(
	"res://assets/art/sky_levels/markers/sky_pollution_core_cloud.png"
)
const PENTAGON_HIDDEN_TEXTURE := preload(
	"res://assets/art/sky_levels/board/pentagon_hidden_surface.png"
)
const PENTAGON_REVEALED_TEXTURE := preload(
	"res://assets/art/sky_levels/board/pentagon_revealed_surface.png"
)
const PENTAGON_POLLUTED_TEXTURE := preload(
	"res://assets/art/sky_levels/board/pentagon_polluted_surface.png"
)
const HEXAGON_HIDDEN_TEXTURE := preload(
	"res://assets/art/sky_levels/board/hexagon_hidden_surface.png"
)
const HEXAGON_REVEALED_TEXTURE := preload(
	"res://assets/art/sky_levels/board/hexagon_revealed_surface.png"
)
const HEXAGON_POLLUTED_TEXTURE := preload(
	"res://assets/art/sky_levels/board/hexagon_polluted_surface.png"
)
const SKY_NUMBER_FONT := preload(
	"res://assets/art/common/fonts/ui_handwritten_zh.ttf"
)
const SKY_NUMBER_COLORS := {
	1: Color("315f8a"),
	2: Color("3d7547"),
	3: Color("a3473f"),
	4: Color("66508a"),
	5: Color("81443c"),
	6: Color("337576"),
}
const LIGHT_DIRECTION := Vector3(-0.43, 0.48, 0.76)

var _faces: Array[Dictionary] = []
var _shared_edges: Array[Dictionary] = []
var _structure_data: Dictionary = {}
var _active_face_count := BASE_FACE_COUNT
var _core_count := CORE_COUNT
var _model: RefCounted
var _rotation := Quaternion.IDENTITY
var _dragging := false
var _left_double_click_pending := false
var _drag_distance := 0.0
var _last_drag_position := Vector2.ZERO
var _hovered_face := -1
var _focused_face := -1
var _joy_rotation := Vector2.ZERO
var _interaction_enabled := true
var _scan_target_mode := false
var _flagged_once := {}
var _instruction_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(620.0, 587.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	_rotation = Basis.from_euler(Vector3(-0.18, -0.32, 0.02)).get_rotation_quaternion()
	_rebuild_sphere(BASE_FACE_COUNT)
	_create_board_model()
	mouse_exited.connect(_clear_hover)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(_on_focus_exited)
	new_game()
	grab_focus()
	set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_instruction_label_rect()
		queue_redraw()


func _draw() -> void:
	_draw_projected_board()


func _create_instruction_label() -> void:
	_instruction_label = Label.new()
	_instruction_label.text = "拖拽旋转 · 左键净化 · 右键标记 · 方向键选择 · WASD旋转"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.add_theme_color_override("font_color", Color("315b68"))
	_instruction_label.add_theme_font_override("font", SKY_NUMBER_FONT)
	_instruction_label.add_theme_font_size_override("font_size", 12)
	_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_instruction_label)
	_update_instruction_label_rect()


func _update_instruction_label_rect() -> void:
	if not is_instance_valid(_instruction_label):
		return
	_instruction_label.position = Vector2(62.0, size.y - 48.0)
	_instruction_label.size = Vector2(maxf(0.0, size.x - 124.0), 26.0)


func _board_rect() -> Rect2:
	return Rect2(
		Vector2(50.0, 6.0),
		Vector2(maxf(1.0, size.x - 100.0), maxf(1.0, size.y - 96.0))
	)


func _projection_scale() -> float:
	return minf(_board_rect().size.x, _board_rect().size.y) * 0.40 / FACE_RADIUS


func _project_point(point: Vector3) -> Vector2:
	var rotated := _rotation_basis() * point
	return _board_rect().get_center() + Vector2(rotated.x, -rotated.y) * _projection_scale()


func _rotation_basis() -> Basis:
	return Basis(_rotation).orthonormalized()


func _create_fullerene() -> void:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var vertices: Array[Vector3] = [
		Vector3(-1, phi, 0), Vector3(1, phi, 0),
		Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi),
		Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1),
		Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	]
	for index in range(vertices.size()):
		vertices[index] = vertices[index].normalized()
	var triangles: Array[Array] = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	var vertex_neighbors: Array[Array] = []
	for _index in range(vertices.size()):
		vertex_neighbors.append([])
	for triangle in triangles:
		for corner in range(3):
			var a: int = triangle[corner]
			var b: int = triangle[(corner + 1) % 3]
			if b not in vertex_neighbors[a]:
				vertex_neighbors[a].append(b)
			if a not in vertex_neighbors[b]:
				vertex_neighbors[b].append(a)

	for vertex_index in range(vertices.size()):
		var normal := vertices[vertex_index]
		var axis_x := normal.cross(Vector3.UP)
		if axis_x.length() < 0.1:
			axis_x = normal.cross(Vector3.RIGHT)
		axis_x = axis_x.normalized()
		var axis_y := normal.cross(axis_x).normalized()
		var ordered: Array[Dictionary] = []
		for neighbor_value in vertex_neighbors[vertex_index]:
			var neighbor: int = neighbor_value
			var point := _truncated_point(vertices, vertex_index, neighbor)
			var tangent := (point - normal * point.dot(normal)).normalized()
			ordered.append({
				"point": point,
				"angle": atan2(tangent.dot(axis_y), tangent.dot(axis_x)),
			})
		ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["angle"]) < float(b["angle"])
		)
		var pentagon: Array[Vector3] = []
		for record in ordered:
			pentagon.append(record["point"])
		_add_face(_oriented_polygon(pentagon), true)

	for triangle in triangles:
		var a: int = triangle[0]
		var b: int = triangle[1]
		var c: int = triangle[2]
		var hexagon: Array[Vector3] = [
			_truncated_point(vertices, a, b),
			_truncated_point(vertices, b, a),
			_truncated_point(vertices, b, c),
			_truncated_point(vertices, c, b),
			_truncated_point(vertices, c, a),
			_truncated_point(vertices, a, c),
		]
		_add_face(_oriented_polygon(hexagon), false)

	for triangle_index in range(triangles.size()):
		var hex_index := vertices.size() + triangle_index
		for vertex_index in triangles[triangle_index]:
			_connect_faces(hex_index, int(vertex_index))
	var edge_owner: Dictionary = {}
	for triangle_index in range(triangles.size()):
		var triangle: Array = triangles[triangle_index]
		for corner in range(3):
			var a: int = triangle[corner]
			var b: int = triangle[(corner + 1) % 3]
			var edge_key := "%d:%d" % [mini(a, b), maxi(a, b)]
			if edge_owner.has(edge_key):
				_connect_faces(
					vertices.size() + triangle_index,
					vertices.size() + int(edge_owner[edge_key])
				)
			else:
				edge_owner[edge_key] = triangle_index


func _rebuild_sphere(face_count: int) -> void:
	_faces.clear()
	_shared_edges.clear()
	var requested_face_count := maxi(BASE_FACE_COUNT, face_count)
	if requested_face_count == BASE_FACE_COUNT:
		_create_fullerene()
	elif not _create_generated_sphere(requested_face_count):
		_faces.clear()
		_create_fullerene()
	_build_shared_edges()
	_connect_neighbors_from_shared_edges()
	_active_face_count = _faces.size()
	_validate_topology()


func _create_generated_sphere(face_count: int) -> bool:
	if not _load_structure_data() or not _structure_data.has(str(face_count)):
		push_error("Missing generated sky sphere structure for %d faces." % face_count)
		return false
	var structure: Dictionary = _structure_data[str(face_count)]
	var raw_vertices: Array = structure.get("vertices", [])
	var raw_faces: Array = structure.get("faces", [])
	var vertices: Array[Vector3] = []
	for vertex_value in raw_vertices:
		var coordinates: Array = vertex_value
		vertices.append(Vector3(
			float(coordinates[0]),
			float(coordinates[1]),
			float(coordinates[2])
		) * FACE_RADIUS)
	for face_value in raw_faces:
		var indices: Array = face_value
		var polygon: Array[Vector3] = []
		for vertex_index in indices:
			polygon.append(vertices[int(vertex_index)])
		if polygon.size() not in [5, 6]:
			push_error("Sky sphere contains a face other than a pentagon or hexagon.")
			return false
		_add_face(_oriented_polygon(polygon), polygon.size() == 5)
	return _faces.size() == face_count


func _load_structure_data() -> bool:
	if not _structure_data.is_empty():
		return true
	var file := FileAccess.open(STRUCTURE_DATA_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	_structure_data = parsed
	return true


func _truncated_point(vertices: Array[Vector3], from_index: int, to_index: int) -> Vector3:
	return vertices[from_index].lerp(vertices[to_index], 1.0 / 3.0).normalized() * FACE_RADIUS


func _oriented_polygon(points: Array[Vector3]) -> Array[Vector3]:
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	if normal.dot(center) < 0.0:
		points.reverse()
	return points


func _add_face(points: Array[Vector3], is_pentagon: bool) -> void:
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var axis_u := (points[0] - center).normalized()
	var axis_v := normal.cross(axis_u).normalized()
	var texture_points := PackedVector2Array()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point in points:
		var local_point := point - center
		var coordinate := Vector2(local_point.dot(axis_u), local_point.dot(axis_v))
		texture_points.append(coordinate)
		minimum = minimum.min(coordinate)
		maximum = maximum.max(coordinate)
	var uvs := PackedVector2Array()
	for coordinate in texture_points:
		uvs.append(Vector2(
			inverse_lerp(minimum.x, maximum.x, coordinate.x),
			1.0 - inverse_lerp(minimum.y, maximum.y, coordinate.y)
		))
	_faces.append({
		"vertices": points,
		"center": center,
		"normal": normal,
		"pentagon": is_pentagon,
		"uvs": uvs,
		"neighbors": [],
	})


func _connect_faces(first: int, second: int) -> void:
	var first_neighbors: Array = _faces[first]["neighbors"]
	var second_neighbors: Array = _faces[second]["neighbors"]
	if second not in first_neighbors:
		first_neighbors.append(second)
	if first not in second_neighbors:
		second_neighbors.append(first)


func _build_shared_edges() -> void:
	var edge_map: Dictionary = {}
	for face_index in range(_faces.size()):
		var vertices: Array = _faces[face_index]["vertices"]
		for vertex_index in range(vertices.size()):
			var start: Vector3 = vertices[vertex_index]
			var finish: Vector3 = vertices[(vertex_index + 1) % vertices.size()]
			var key := _shared_edge_key(start, finish)
			if edge_map.has(key):
				var existing: Dictionary = edge_map[key]
				var owners: Array = existing["faces"]
				owners.append(face_index)
			else:
				edge_map[key] = {
					"start": start,
					"finish": finish,
					"faces": [face_index],
				}
	_shared_edges.clear()
	for edge in edge_map.values():
		_shared_edges.append(edge)


func _connect_neighbors_from_shared_edges() -> void:
	for edge in _shared_edges:
		var owners: Array = edge["faces"]
		if owners.size() == 2:
			_connect_faces(int(owners[0]), int(owners[1]))


func _shared_edge_key(start: Vector3, finish: Vector3) -> String:
	var endpoint_keys: Array[String] = [_point_key(start), _point_key(finish)]
	endpoint_keys.sort()
	return "%s|%s" % endpoint_keys


func _point_key(point: Vector3) -> String:
	return "%d,%d,%d" % [
		roundi(point.x * 100000.0),
		roundi(point.y * 100000.0),
		roundi(point.z * 100000.0),
	]


func _validate_topology() -> void:
	if _faces.size() != _active_face_count:
		push_error("Sky sphere face count does not match the selected structure.")
	var pentagon_count := 0
	var hexagon_count := 0
	for face in _faces:
		var side_count := (face["vertices"] as Array).size()
		var neighbor_count := (face["neighbors"] as Array).size()
		if bool(face["pentagon"]):
			pentagon_count += 1
		elif side_count == 6:
			hexagon_count += 1
		if side_count not in [5, 6] or neighbor_count != side_count:
			push_error("Sky sphere faces must be pentagons or hexagons with matching adjacency.")
	if _active_face_count == BASE_FACE_COUNT \
			and (pentagon_count != 12 or hexagon_count != 20):
		push_error("Base sky sphere topology is not a truncated icosahedron.")
	for edge in _shared_edges:
		if (edge["faces"] as Array).size() != 2:
			push_error("Sky sphere contains a non-shared edge.")


func _create_board_model() -> void:
	var topology: Array[PackedInt32Array] = []
	for face in _faces:
		var face_neighbors := PackedInt32Array()
		for neighbor in face["neighbors"]:
			face_neighbors.append(int(neighbor))
		topology.append(face_neighbors)
	_model = GRAPH_MODEL_SCRIPT.new()
	_model.call("configure", topology, _core_count)
	_model.connect("board_changed", _refresh_all_faces)
	_model.connect(
		"flags_changed",
		func(used_flags: int, max_flags: int) -> void:
			flags_changed.emit(used_flags, max_flags)
	)
	_model.connect("state_changed", _on_model_state_changed)
	_model.connect("first_reveal", func() -> void: first_reveal.emit())


func configure_level(core_count: int, face_count: int = BASE_FACE_COUNT) -> void:
	if maxi(BASE_FACE_COUNT, face_count) != _active_face_count:
		_rebuild_sphere(face_count)
	_core_count = clampi(core_count, 1, _faces.size() - 1)
	var topology: Array[PackedInt32Array] = []
	for face in _faces:
		var face_neighbors := PackedInt32Array()
		for neighbor in face["neighbors"]:
			face_neighbors.append(int(neighbor))
		topology.append(face_neighbors)
	_model.call("configure", topology, _core_count)
	new_game()


func get_core_count() -> int:
	return _core_count


func new_game() -> void:
	_interaction_enabled = true
	_scan_target_mode = false
	_flagged_once.clear()
	_dragging = false
	_left_double_click_pending = false
	_joy_rotation = Vector2.ZERO
	_hovered_face = -1
	_focused_face = _frontmost_face()
	_model.call("new_game")
	status_changed.emit("旋转球面，寻找安全起点")
	_refresh_all_faces()


func _draw_projected_board() -> void:
	if _model == null:
		return
	var visible_faces := _visible_face_records()
	var mines: PackedByteArray = _model.get("mines")
	var revealed: PackedByteArray = _model.get("revealed")
	var flagged: PackedByteArray = _model.get("flagged")
	var adjacent_counts: PackedInt32Array = _model.get("adjacent_counts")

	for record in visible_faces:
		var face_index: int = record["index"]
		var polygon: PackedVector2Array = record["polygon"]
		var texture := _face_texture(face_index, revealed, flagged, mines)
		var brightness := _face_brightness(face_index)
		draw_colored_polygon(
			polygon,
			Color(brightness, brightness, brightness, 1.0),
			_faces[face_index]["uvs"],
			texture
		)
		_draw_material_gloss(
			face_index,
			polygon,
			float(record["frontness"])
		)
		if face_index == _hovered_face:
			draw_colored_polygon(polygon, Color(HOVER_COLOR, 0.28))

	_draw_shared_edge_separators()

	for record in visible_faces:
		var face_index: int = record["index"]
		var polygon: PackedVector2Array = record["polygon"]
		if face_index == _hovered_face:
			_draw_closed_polyline(polygon, Color("f0af45"), 2.8)
		if face_index == _focused_face:
			var focus_color := FOCUS_COLOR if has_focus() else Color("dfac58")
			_draw_closed_polyline(polygon, focus_color, 4.0)

	for record in visible_faces:
		_draw_face_mark(
			int(record["index"]),
			revealed,
			flagged,
			mines,
			adjacent_counts,
			float(record["frontness"]),
			record["polygon"]
		)


func _visible_face_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var basis := _rotation_basis()
	for face_index in range(_faces.size()):
		var normal: Vector3 = basis * Vector3(_faces[face_index]["normal"])
		if normal.z <= FRONT_FACE_EPSILON:
			continue
		var polygon := PackedVector2Array()
		for vertex_value in _faces[face_index]["vertices"]:
			polygon.append(_project_point(Vector3(vertex_value)))
		var center: Vector3 = basis * Vector3(_faces[face_index]["center"])
		records.append({
			"index": face_index,
			"polygon": polygon,
			"depth": center.z,
			"frontness": normal.z,
		})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["depth"]) < float(b["depth"])
	)
	return records


func _face_texture(
	face_index: int,
	revealed: PackedByteArray,
	flagged: PackedByteArray,
	mines: PackedByteArray
) -> Texture2D:
	var is_pentagon := bool(_faces[face_index]["pentagon"])
	var gameplay_state := int(_model.get("state"))
	if gameplay_state == 2:
		return PENTAGON_REVEALED_TEXTURE if is_pentagon else HEXAGON_REVEALED_TEXTURE
	if gameplay_state == 3:
		if mines[face_index] == 1 or flagged[face_index] == 1:
			return PENTAGON_HIDDEN_TEXTURE if is_pentagon else HEXAGON_HIDDEN_TEXTURE
		return PENTAGON_POLLUTED_TEXTURE if is_pentagon else HEXAGON_POLLUTED_TEXTURE
	if revealed[face_index] == 0:
		return PENTAGON_HIDDEN_TEXTURE if is_pentagon else HEXAGON_HIDDEN_TEXTURE
	return PENTAGON_REVEALED_TEXTURE if is_pentagon else HEXAGON_REVEALED_TEXTURE


func _draw_material_gloss(
	face_index: int,
	polygon: PackedVector2Array,
	frontness: float
) -> void:
	if polygon.size() < 3:
		return
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= float(polygon.size())
	var screen_light := Vector2(LIGHT_DIRECTION.x, -LIGHT_DIRECTION.y).normalized()
	var light_amount := maxf(0.0, _rotated_normal(face_index).dot(LIGHT_DIRECTION.normalized()))
	var colors := PackedColorArray()
	for point in polygon:
		var direction := (point - center).normalized()
		var directional_gloss := clampf(0.48 + direction.dot(screen_light) * 0.52, 0.0, 1.0)
		var alpha := directional_gloss * (0.015 + light_amount * 0.035)
		colors.append(Color(1.0, 1.0, 1.0, alpha))
	draw_polygon(polygon, colors)
	var rim_alpha := 0.10 + (1.0 - clampf(frontness, 0.0, 1.0)) * 0.10
	_draw_closed_polyline(polygon, Color(0.94, 0.99, 1.0, rim_alpha), 1.3)


func _face_brightness(face_index: int) -> float:
	var rotated_normal := _rotated_normal(face_index)
	var light_amount := rotated_normal.dot(LIGHT_DIRECTION.normalized())
	return clampf(0.97 + light_amount * 0.018, 0.95, 0.987)


func _counted_neighbor_set(
	revealed: PackedByteArray,
	adjacent_counts: PackedInt32Array
) -> Dictionary:
	var counted_neighbors := {}
	if _dragging or _focused_face < 0:
		return counted_neighbors
	if revealed[_focused_face] == 0 or adjacent_counts[_focused_face] <= 0:
		return counted_neighbors
	for neighbor in _model.call("get_neighbor_faces", _focused_face):
		counted_neighbors[int(neighbor)] = true
	return counted_neighbors


func _draw_shared_edge_separators() -> void:
	for edge in _shared_edges:
		var should_draw := false
		for face_value in edge["faces"]:
			if _face_frontness(int(face_value)) > FRONT_FACE_EPSILON:
				should_draw = true
				break
		if not should_draw:
			continue
		_draw_dashed_line(
			_project_point(Vector3(edge["start"])),
			_project_point(Vector3(edge["finish"])),
			OUTLINE_COLOR,
			2.0
		)


func _draw_dashed_line(start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var segment := finish - start
	var length := segment.length()
	if length <= 0.001:
		return
	var direction := segment / length
	var offset := 0.0
	while offset < length:
		var dash_end := minf(offset + DASH_LENGTH, length)
		draw_line(
			start + direction * offset,
			start + direction * dash_end,
			color,
			width,
			true
		)
		offset += DASH_LENGTH + DASH_GAP


func _draw_closed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _draw_face_mark(
	face_index: int,
	revealed: PackedByteArray,
	flagged: PackedByteArray,
	mines: PackedByteArray,
	adjacent_counts: PackedInt32Array,
	frontness: float,
	polygon: PackedVector2Array
) -> void:
	var text := ""
	var color := Color("31515b")
	var gameplay_state := int(_model.get("state"))
	if gameplay_state == 2 and mines[face_index] == 1:
		_draw_marker_texture(
			face_index,
			frontness,
			polygon,
			SKY_FLAG_NORMAL_TEXTURE
		)
		return
	if flagged[face_index] == 1:
		var marker_texture := SKY_FLAG_NORMAL_TEXTURE
		if gameplay_state == 3:
			marker_texture = (
				SKY_FLAG_FAILED_TEXTURE
				if mines[face_index] == 1
				else SKY_MARKER_WRONG_TEXTURE
			)
		_draw_marker_texture(face_index, frontness, polygon, marker_texture)
		return
	if revealed[face_index] == 1 and mines[face_index] == 1:
		_draw_core_monster(face_index, frontness, polygon)
		return
	if revealed[face_index] == 1:
		if adjacent_counts[face_index] > 0:
			text = str(adjacent_counts[face_index])
			color = SKY_NUMBER_COLORS.get(adjacent_counts[face_index], Color("31515b"))
	if text.is_empty() or frontness <= LABEL_FADE_START:
		return
	var alpha := smoothstep(LABEL_FADE_START, LABEL_FADE_END, frontness)
	color.a *= alpha
	var center := _project_face_center(face_index)
	var nearest_vertex_distance := INF
	for point in polygon:
		nearest_vertex_distance = minf(nearest_vertex_distance, center.distance_to(point))
	var font_size := clampi(
		roundi(nearest_vertex_distance * 0.82),
		MIN_LABEL_SIZE,
		MAX_LABEL_SIZE
	)
	_draw_centered_text(text, center, font_size, color, alpha)


func _draw_marker_texture(
	face_index: int,
	frontness: float,
	polygon: PackedVector2Array,
	texture: Texture2D
) -> void:
	if frontness <= LABEL_FADE_START:
		return
	var center := _project_face_center(face_index)
	var nearest_vertex_distance := INF
	for point in polygon:
		nearest_vertex_distance = minf(nearest_vertex_distance, center.distance_to(point))
	var source_size := texture.get_size()
	var is_wrong_marker := texture == SKY_MARKER_WRONG_TEXTURE
	var extent_multiplier := 1.72 if is_wrong_marker else 1.48
	var extent_limit := 54.0 if is_wrong_marker else 46.0
	var max_extent := clampf(
		nearest_vertex_distance * extent_multiplier,
		25.0,
		extent_limit
	)
	var marker_scale := max_extent / maxf(source_size.x, source_size.y)
	var marker_size := source_size * marker_scale
	var alpha := smoothstep(LABEL_FADE_START, LABEL_FADE_END, frontness)
	draw_texture_rect(
		texture,
		Rect2(center - marker_size * 0.5, marker_size),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)


func _draw_core_monster(
	face_index: int,
	frontness: float,
	polygon: PackedVector2Array
) -> void:
	if frontness <= CORE_MONSTER_MIN_FRONTNESS:
		return
	var center := _project_face_center(face_index)
	var nearest_vertex_distance := INF
	for point in polygon:
		nearest_vertex_distance = minf(nearest_vertex_distance, center.distance_to(point))
	var icon_size := clampf(nearest_vertex_distance * 1.48, 27.0, 50.0)
	var alpha := smoothstep(
		CORE_MONSTER_MIN_FRONTNESS,
		CORE_MONSTER_FADE_END,
		frontness
	)
	var radial_direction := center - _board_rect().get_center()
	var texture_rotation := (
		radial_direction.angle() + PI * 0.5
		if radial_direction.length_squared() > 1.0
		else 0.0
	)
	draw_set_transform(center, texture_rotation, Vector2.ONE)
	draw_texture_rect(
		CORE_MONSTER_TEXTURE,
		Rect2(Vector2.ONE * -icon_size * 0.5, Vector2.ONE * icon_size),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_centered_text(
	text: String,
	center: Vector2,
	font_size: int,
	color: Color,
	alpha: float
) -> void:
	var text_size := SKY_NUMBER_FONT.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	)
	var baseline := center + Vector2(
		-text_size.x * 0.5,
		(SKY_NUMBER_FONT.get_ascent(font_size) - SKY_NUMBER_FONT.get_descent(font_size)) * 0.5
	)
	var outline_color := Color(1.0, 0.98, 0.90, 0.78 * alpha)
	for offset in [
		Vector2(-1.5, 0.0), Vector2(1.5, 0.0),
		Vector2(0.0, -1.5), Vector2(0.0, 1.5),
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0),
		Vector2(-1.0, 1.0), Vector2(1.0, 1.0),
	]:
		draw_string(
			SKY_NUMBER_FONT,
			baseline + offset,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			font_size,
			outline_color
		)
	draw_string(
		SKY_NUMBER_FONT,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_dragging = true
				_left_double_click_pending = mouse_event.double_click
				_drag_distance = 0.0
				_last_drag_position = mouse_event.position
				_hovered_face = -1
				grab_focus()
			else:
				if _interaction_enabled and _dragging and _drag_distance < DRAG_THRESHOLD:
					var face_index := _pick_face(mouse_event.position)
					if face_index >= 0:
						_focused_face = face_index
						var revealed: PackedByteArray = _model.get("revealed")
						if revealed[face_index] == 0 or _left_double_click_pending:
							_activate_face(face_index)
				_dragging = false
				_left_double_click_pending = false
				queue_redraw()
			accept_event()
		elif (
			_interaction_enabled
			and mouse_event.button_index == MOUSE_BUTTON_RIGHT
			and mouse_event.pressed
		):
			grab_focus()
			if _scan_target_mode:
				scan_cancel_requested.emit()
			else:
				var face_index := _pick_face(mouse_event.position)
				if face_index >= 0:
					_focused_face = face_index
					_toggle_flag(face_index)
			queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _dragging:
			_drag_distance += motion.relative.length()
			_rotate_arcball(_last_drag_position, motion.position)
			_last_drag_position = motion.position
			_hovered_face = -1
		else:
			var next_hover := _pick_face(motion.position)
			if next_hover != _hovered_face:
				_hovered_face = next_hover
				queue_redraw()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_LEFT:
			_move_focus(Vector2.LEFT)
		elif key_event.keycode == KEY_RIGHT:
			_move_focus(Vector2.RIGHT)
		elif key_event.keycode == KEY_UP:
			_move_focus(Vector2.UP)
		elif key_event.keycode == KEY_DOWN:
			_move_focus(Vector2.DOWN)
		elif key_event.keycode == KEY_A:
			_rotate_ball(Vector2(-0.11, 0.0))
		elif key_event.keycode == KEY_D:
			_rotate_ball(Vector2(0.11, 0.0))
		elif key_event.keycode == KEY_W:
			_rotate_ball(Vector2(0.0, -0.11))
		elif key_event.keycode == KEY_S:
			_rotate_ball(Vector2(0.0, 0.11))
		elif key_event.keycode in [KEY_ENTER, KEY_SPACE]:
			_activate_face(_focused_face)
		elif key_event.keycode == KEY_F:
			_toggle_flag(_focused_face)
		elif key_event.keycode == KEY_R:
			_center_focused_face()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if motion.axis == JOY_AXIS_RIGHT_X:
			_joy_rotation.x = motion.axis_value
		elif motion.axis == JOY_AXIS_RIGHT_Y:
			_joy_rotation.y = motion.axis_value
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		var button := event as InputEventJoypadButton
		if button.button_index == JOY_BUTTON_A:
			_activate_face(_focused_face)
		elif button.button_index == JOY_BUTTON_X:
			_toggle_flag(_focused_face)
		elif button.button_index == JOY_BUTTON_RIGHT_STICK:
			_center_focused_face()
		elif button.button_index == JOY_BUTTON_DPAD_LEFT:
			_move_focus(Vector2.LEFT)
		elif button.button_index == JOY_BUTTON_DPAD_RIGHT:
			_move_focus(Vector2.RIGHT)
		elif button.button_index == JOY_BUTTON_DPAD_UP:
			_move_focus(Vector2.UP)
		elif button.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_focus(Vector2.DOWN)
		else:
			return
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if has_focus() and _joy_rotation.length() > 0.2:
		_rotate_ball(_joy_rotation * delta * 1.8)


func _rotate_arcball(from_position: Vector2, to_position: Vector2) -> void:
	var from_vector := _arcball_vector(from_position)
	var to_vector := _arcball_vector(to_position)
	var axis := from_vector.cross(to_vector)
	if axis.length() < 0.0001:
		return
	var angle := acos(clampf(from_vector.dot(to_vector), -1.0, 1.0))
	_rotation = (Quaternion(axis.normalized(), angle) * _rotation).normalized()
	queue_redraw()


func _arcball_vector(control_position: Vector2) -> Vector3:
	var board := _board_rect()
	var radius := maxf(1.0, minf(board.size.x, board.size.y) * 0.46)
	var offset := control_position - board.get_center()
	var point := Vector2(offset.x / radius, -offset.y / radius)
	var length_squared := point.length_squared()
	if length_squared <= 1.0:
		return Vector3(point.x, point.y, sqrt(1.0 - length_squared))
	point = point.normalized()
	return Vector3(point.x, point.y, 0.0)


func _rotate_ball(delta_rotation: Vector2) -> void:
	var yaw := Quaternion(Vector3.UP, delta_rotation.x)
	var pitch := Quaternion(Vector3.RIGHT, delta_rotation.y)
	_rotation = (pitch * yaw * _rotation).normalized()
	_hovered_face = -1
	queue_redraw()


func _move_focus(direction: Vector2) -> void:
	if _focused_face < 0:
		_focused_face = _frontmost_face()
		queue_redraw()
		return
	var current_position := _project_face_center(_focused_face)
	var best_index := -1
	var best_score := -INF
	for neighbor_value in _faces[_focused_face]["neighbors"]:
		var neighbor := int(neighbor_value)
		if _face_frontness(neighbor) <= 0.02:
			continue
		var offset := _project_face_center(neighbor) - current_position
		if offset.length() < 0.1:
			continue
		var directional_score := offset.normalized().dot(direction)
		if directional_score > 0.2 and directional_score > best_score:
			best_score = directional_score
			best_index = neighbor
	if best_index >= 0:
		_focused_face = best_index
	else:
		_rotate_ball(direction * 0.13)
	queue_redraw()


func _center_focused_face() -> void:
	if _focused_face < 0:
		return
	var rotated_center := (_rotation_basis() * Vector3(_faces[_focused_face]["center"])).normalized()
	var target := Vector3(0.0, 0.0, 1.0)
	var axis := rotated_center.cross(target)
	if axis.length() < 0.001:
		return
	_rotation = (
		Quaternion(axis.normalized(), rotated_center.angle_to(target)) * _rotation
	).normalized()
	_hovered_face = -1
	queue_redraw()


func _activate_face(face_index: int) -> void:
	if not _interaction_enabled or face_index < 0:
		return
	if _scan_target_mode:
		if is_scan_candidate(face_index):
			scan_target_requested.emit(face_index)
		return
	_reveal_face(face_index)


func _reveal_face(face_index: int) -> void:
	if face_index < 0:
		return
	var revealed_before := _count_active(_model.get("revealed"))
	_model.call("reveal_face", face_index)
	if _count_active(_model.get("revealed")) > revealed_before:
		scan_energy_earned.emit()


func _toggle_flag(face_index: int) -> void:
	if not _interaction_enabled or face_index < 0:
		return
	var flagged: PackedByteArray = _model.get("flagged")
	var was_flagged := flagged[face_index] == 1
	_model.call("toggle_flag", face_index)
	flagged = _model.get("flagged")
	if not was_flagged and flagged[face_index] == 1 and not _flagged_once.has(face_index):
		_flagged_once[face_index] = true
		scan_energy_earned.emit()


func set_scan_target_mode(enabled: bool) -> void:
	_scan_target_mode = (
		enabled
		and _interaction_enabled
		and int(_model.get("state")) == 1
	)
	queue_redraw()


func is_scan_candidate(face_index: int) -> bool:
	if face_index < 0 or face_index >= _faces.size():
		return false
	var revealed: PackedByteArray = _model.get("revealed")
	var flagged: PackedByteArray = _model.get("flagged")
	return revealed[face_index] == 0 and flagged[face_index] == 0


func try_scan_face(face_index: int) -> bool:
	if not _scan_target_mode or not is_scan_candidate(face_index):
		return false
	_scan_target_mode = false
	var mines: PackedByteArray = _model.get("mines")
	var result := 1 if mines[face_index] == 1 else 0
	if result == 1:
		_model.call("toggle_flag", face_index)
	else:
		_model.call("reveal_face", face_index)
	scan_completed.emit(face_index, result)
	queue_redraw()
	return true


func get_face_global_position(face_index: int) -> Vector2:
	if face_index < 0 or face_index >= _faces.size():
		return global_position
	return get_global_transform() * _project_face_center(face_index)


func _count_active(values: PackedByteArray) -> int:
	var count := 0
	for value in values:
		count += int(value)
	return count


func _on_model_state_changed(state: int) -> void:
	_interaction_enabled = state < 2
	if not _interaction_enabled:
		_scan_target_mode = false
		_dragging = false
		_joy_rotation = Vector2.ZERO
	gameplay_state_changed.emit(state)
	match state:
		0:
			status_changed.emit("旋转球面，寻找安全起点")
		1:
			status_changed.emit("净化进行中")
		2:
			status_changed.emit("球面净化完成")
		3:
			status_changed.emit("污染扩散，重新生成后再试")
	queue_redraw()


func _refresh_all_faces() -> void:
	queue_redraw()


func _frontmost_face() -> int:
	var best_index := 0
	var best_frontness := -INF
	for index in range(_faces.size()):
		var frontness := _face_frontness(index)
		if frontness > best_frontness:
			best_frontness = frontness
			best_index = index
	return best_index


func _rotated_normal(face_index: int) -> Vector3:
	return (_rotation_basis() * Vector3(_faces[face_index]["normal"])).normalized()


func _face_frontness(face_index: int) -> float:
	return _rotated_normal(face_index).z


func _project_face_center(face_index: int) -> Vector2:
	return _project_point(Vector3(_faces[face_index]["center"]))


func _pick_face(control_position: Vector2) -> int:
	if not _board_rect().has_point(control_position):
		return -1
	var best_index := -1
	var best_depth := -INF
	var basis := _rotation_basis()
	for index in range(_faces.size()):
		if _face_frontness(index) <= FRONT_FACE_EPSILON:
			continue
		var polygon := PackedVector2Array()
		for vertex_value in _faces[index]["vertices"]:
			polygon.append(_project_point(Vector3(vertex_value)))
		if not Geometry2D.is_point_in_polygon(control_position, polygon):
			continue
		var depth := (basis * Vector3(_faces[index]["center"])).z
		if depth > best_depth:
			best_index = index
			best_depth = depth
	return best_index


func _clear_hover() -> void:
	if _hovered_face == -1:
		return
	_hovered_face = -1
	queue_redraw()


func _on_focus_exited() -> void:
	_joy_rotation = Vector2.ZERO
	queue_redraw()
