extends Control

const SOFT_LAYER_COUNT := 5
const SOURCE_CANVAS_SIZE := Vector2(900.0, 1300.0)
const SOURCE_CURVED_PAPER_BOUNDS := Rect2(85.0, 68.0, 715.0, 1125.0)
const SOURCE_STRAIGHT_PAPER_BOUNDS := Rect2(100.0, 70.0, 700.0, 1120.0)
const SOURCE_STRAIGHT_CORNER_RADIUS := 78.0
const CURVE_SEGMENTS := 8
const CORNER_SEGMENTS := 8
const BOARD_SHADOW_COLORS := [
	Color(0.063, 0.051, 0.039, 0.54),
	Color(0.090, 0.071, 0.055, 0.48),
	Color(0.165, 0.125, 0.094, 0.36),
	Color(0.129, 0.094, 0.067, 0.44),
]

@export_range(0.0, 1.0, 0.05) var shadow_scale := 1.0
@export var curved_outline := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var source_bounds := SOURCE_CURVED_PAPER_BOUNDS
	var source_outline := _source_curved_paper_outline()
	if not curved_outline:
		source_bounds = SOURCE_STRAIGHT_PAPER_BOUNDS
		source_outline = _source_straight_paper_outline()
	var paper_rect := Rect2(
		source_bounds.position / SOURCE_CANVAS_SIZE * size,
		source_bounds.size / SOURCE_CANVAS_SIZE * size
	)
	var paper_outline := PackedVector2Array()
	for source_point in source_outline:
		paper_outline.append(source_point / SOURCE_CANVAS_SIZE * size)
	var projected_outline := _project_outline(paper_outline, paper_rect)
	var shadow_center := _polygon_center(projected_outline)

	for layer_index in range(SOFT_LAYER_COUNT, 0, -1):
		var spread := float(layer_index) * 1.1 * shadow_scale
		var softness := float(SOFT_LAYER_COUNT - layer_index + 1) / float(SOFT_LAYER_COUNT)
		var expanded := _expand_polygon(projected_outline, shadow_center, spread)
		draw_polygon(
			expanded,
			_shadow_colors_for_points(paper_outline, paper_rect, lerpf(0.035, 0.075, softness))
		)

	draw_polygon(
		projected_outline,
		_shadow_colors_for_points(paper_outline, paper_rect, 0.60)
	)


func _source_curved_paper_outline() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(178.0, 70.0)])
	_append_cubic(points, Vector2(178.0, 70.0), Vector2(340.0, 68.5), Vector2(559.0, 71.5), Vector2(722.0, 69.5))
	_append_cubic(points, Vector2(722.0, 69.5), Vector2(766.0, 69.5), Vector2(798.0, 101.0), Vector2(800.0, 145.0))
	_append_cubic(points, Vector2(800.0, 145.0), Vector2(798.0, 460.0), Vector2(785.0, 795.0), Vector2(785.0, 1111.0))
	_append_cubic(points, Vector2(785.0, 1111.0), Vector2(786.0, 1154.0), Vector2(752.0, 1187.0), Vector2(707.0, 1190.0))
	_append_cubic(points, Vector2(707.0, 1190.0), Vector2(529.0, 1192.5), Vector2(346.0, 1188.5), Vector2(163.0, 1191.0))
	_append_cubic(points, Vector2(163.0, 1191.0), Vector2(118.0, 1192.0), Vector2(85.0, 1157.0), Vector2(85.0, 1112.0))
	_append_cubic(points, Vector2(85.0, 1112.0), Vector2(85.0, 790.0), Vector2(99.0, 460.0), Vector2(101.0, 150.0))
	_append_cubic(points, Vector2(101.0, 150.0), Vector2(99.0, 105.0), Vector2(132.0, 72.0), Vector2(178.0, 70.0))
	return points


func _source_straight_paper_outline() -> PackedVector2Array:
	var rect := SOURCE_STRAIGHT_PAPER_BOUNDS
	var radius := SOURCE_STRAIGHT_CORNER_RADIUS
	var points := PackedVector2Array()
	var centers := [
		rect.position + Vector2(radius, radius),
		Vector2(rect.end.x - radius, rect.position.y + radius),
		rect.end - Vector2(radius, radius),
		Vector2(rect.position.x + radius, rect.end.y - radius),
	]
	var start_angles := [PI, PI * 1.5, 0.0, PI * 0.5]
	for corner_index in centers.size():
		for segment_index in range(CORNER_SEGMENTS + 1):
			var angle: float = start_angles[corner_index] + PI * 0.5 * (
				float(segment_index) / float(CORNER_SEGMENTS)
			)
			points.append(centers[corner_index] + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _append_cubic(
	points: PackedVector2Array,
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end: Vector2
) -> void:
	for segment_index in range(1, CURVE_SEGMENTS + 1):
		var t := float(segment_index) / float(CURVE_SEGMENTS)
		var inverse_t := 1.0 - t
		points.append(
			start * inverse_t * inverse_t * inverse_t
			+ control_a * 3.0 * inverse_t * inverse_t * t
			+ control_b * 3.0 * inverse_t * t * t
			+ end * t * t * t
		)


func _project_outline(points: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var corner_offsets := [
		Vector2(rect.size.x * 0.0164, rect.size.y * 0.0173) * shadow_scale,
		Vector2(rect.size.x * 0.0528, rect.size.y * 0.0232) * shadow_scale,
		Vector2(rect.size.x * 0.0692, rect.size.y * 0.0571) * shadow_scale,
		Vector2(rect.size.x * 0.0189, rect.size.y * 0.0425) * shadow_scale,
	]
	var projected := PackedVector2Array()
	for point in points:
		var uv := (point - rect.position) / rect.size
		var top_offset: Vector2 = corner_offsets[0].lerp(corner_offsets[1], uv.x)
		var bottom_offset: Vector2 = corner_offsets[3].lerp(corner_offsets[2], uv.x)
		projected.append(point + top_offset.lerp(bottom_offset, uv.y))
	return projected


func _polygon_center(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in points:
		center += point
	return center / float(points.size())


func _expand_polygon(
	points: PackedVector2Array,
	center: Vector2,
	spread: float
) -> PackedVector2Array:
	var expanded := PackedVector2Array()
	for point in points:
		expanded.append(point + (point - center).normalized() * spread)
	return expanded


func _shadow_colors_for_points(
	points: PackedVector2Array,
	rect: Rect2,
	alpha_multiplier: float
) -> PackedColorArray:
	var colors := PackedColorArray()
	for point in points:
		var uv := (point - rect.position) / rect.size
		var top_color: Color = BOARD_SHADOW_COLORS[0].lerp(BOARD_SHADOW_COLORS[1], uv.x)
		var bottom_color: Color = BOARD_SHADOW_COLORS[3].lerp(BOARD_SHADOW_COLORS[2], uv.x)
		var color := top_color.lerp(bottom_color, uv.y)
		color.a *= alpha_multiplier
		colors.append(color)
	return colors
