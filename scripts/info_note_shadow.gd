extends Control

const SOURCE_CANVAS_SIZE := Vector2(1000.0, 1320.0)
const SOURCE_BACK_RECT := Rect2(190.0, 70.0, 715.0, 1118.0)
const SOURCE_FRONT_RECT := Rect2(80.0, 180.0, 690.0, 1040.0)
const SOURCE_BACK_RADIUS := 78.0
const SOURCE_FRONT_RADIUS := 76.0
const FRONT_ROTATION := deg_to_rad(-4.0)
const FRONT_ROTATION_CENTER := Vector2(425.0, 700.0)
const CORNER_SEGMENTS := 8
const SOFT_LAYER_COUNT := 5
const BOARD_SHADOW_COLORS := [
	Color(0.063, 0.051, 0.039, 0.54),
	Color(0.090, 0.071, 0.055, 0.48),
	Color(0.165, 0.125, 0.094, 0.36),
	Color(0.129, 0.094, 0.067, 0.44),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var source_points: Array[Vector2] = []
	for point in _rounded_rect_points(SOURCE_BACK_RECT, SOURCE_BACK_RADIUS):
		source_points.append(point)
	for point in _rounded_rect_points(SOURCE_FRONT_RECT, SOURCE_FRONT_RADIUS):
		source_points.append(
			FRONT_ROTATION_CENTER
			+ (point - FRONT_ROTATION_CENTER).rotated(FRONT_ROTATION)
		)
	var source_hull := _convex_hull(source_points)
	var outline := PackedVector2Array()
	for point in source_hull:
		outline.append(point / SOURCE_CANVAS_SIZE * size)

	var bounds := _polygon_bounds(outline)
	var projected := _project_outline(outline, bounds)
	var center := _polygon_center(projected)

	for layer_index in range(SOFT_LAYER_COUNT, 0, -1):
		var spread := float(layer_index) * 1.1
		var softness := float(SOFT_LAYER_COUNT - layer_index + 1) / float(SOFT_LAYER_COUNT)
		var expanded := _expand_polygon(projected, center, spread)
		draw_polygon(
			expanded,
			_shadow_colors(outline, bounds, lerpf(0.035, 0.075, softness))
		)

	draw_polygon(projected, _shadow_colors(outline, bounds, 0.60))


func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
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


func _convex_hull(points: Array[Vector2]) -> Array[Vector2]:
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y)
	)
	if points.size() <= 2:
		return points
	var lower: Array[Vector2] = []
	for point in points:
		while lower.size() >= 2 and _cross(lower[-2], lower[-1], point) <= 0.0:
			lower.pop_back()
		lower.append(point)
	var upper: Array[Vector2] = []
	for point_index in range(points.size() - 1, -1, -1):
		var point := points[point_index]
		while upper.size() >= 2 and _cross(upper[-2], upper[-1], point) <= 0.0:
			upper.pop_back()
		upper.append(point)
	lower.pop_back()
	upper.pop_back()
	lower.append_array(upper)
	return lower


func _cross(origin: Vector2, a: Vector2, b: Vector2) -> float:
	return (a - origin).cross(b - origin)


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _project_outline(points: PackedVector2Array, bounds: Rect2) -> PackedVector2Array:
	var corner_offsets := [
		Vector2(bounds.size.x * 0.0164, bounds.size.y * 0.0173),
		Vector2(bounds.size.x * 0.0528, bounds.size.y * 0.0232),
		Vector2(bounds.size.x * 0.0692, bounds.size.y * 0.0571),
		Vector2(bounds.size.x * 0.0189, bounds.size.y * 0.0425),
	]
	var projected := PackedVector2Array()
	for point in points:
		var uv := (point - bounds.position) / bounds.size
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


func _shadow_colors(
	points: PackedVector2Array,
	bounds: Rect2,
	alpha_multiplier: float
) -> PackedColorArray:
	var colors := PackedColorArray()
	for point in points:
		var uv := (point - bounds.position) / bounds.size
		var top_color: Color = BOARD_SHADOW_COLORS[0].lerp(BOARD_SHADOW_COLORS[1], uv.x)
		var bottom_color: Color = BOARD_SHADOW_COLORS[3].lerp(BOARD_SHADOW_COLORS[2], uv.x)
		var color := top_color.lerp(bottom_color, uv.y)
		color.a *= alpha_multiplier
		colors.append(color)
	return colors
