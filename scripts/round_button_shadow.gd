extends Control

const SOURCE_CANVAS_SIZE := Vector2(700.0, 709.0)
const SOURCE_BUTTON_RECT := Rect2(36.0, 41.0, 606.0, 607.0)
const CIRCLE_SEGMENTS := 48
const SOFT_LAYER_COUNT := 3
const NOTE_SHADOW_SCALE := 0.20
const NOTE_PAPER_SIZE := Vector2(224.0, 361.0)
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

	var button_rect := Rect2(
		SOURCE_BUTTON_RECT.position / SOURCE_CANVAS_SIZE * size,
		SOURCE_BUTTON_RECT.size / SOURCE_CANVAS_SIZE * size
	)
	var outline := _circle_points(button_rect)
	var projected := _project_outline(outline, button_rect)
	var center := button_rect.get_center()

	for layer_index in range(SOFT_LAYER_COUNT, 0, -1):
		var spread := float(layer_index) * 0.40
		var expanded := PackedVector2Array()
		for point in projected:
			expanded.append(point + (point - center).normalized() * spread)
		draw_polygon(expanded, _shadow_colors(outline, button_rect, 0.055))

	draw_polygon(projected, _shadow_colors(outline, button_rect, 0.56))


func _circle_points(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius := rect.size * 0.5
	for point_index in CIRCLE_SEGMENTS:
		var angle := TAU * float(point_index) / float(CIRCLE_SEGMENTS)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _project_outline(points: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var corner_offsets := [
		Vector2(NOTE_PAPER_SIZE.x * 0.0164, NOTE_PAPER_SIZE.y * 0.0173) * NOTE_SHADOW_SCALE,
		Vector2(NOTE_PAPER_SIZE.x * 0.0528, NOTE_PAPER_SIZE.y * 0.0232) * NOTE_SHADOW_SCALE,
		Vector2(NOTE_PAPER_SIZE.x * 0.0692, NOTE_PAPER_SIZE.y * 0.0571) * NOTE_SHADOW_SCALE,
		Vector2(NOTE_PAPER_SIZE.x * 0.0189, NOTE_PAPER_SIZE.y * 0.0425) * NOTE_SHADOW_SCALE,
	]
	var projected := PackedVector2Array()
	for point in points:
		var uv := (point - rect.position) / rect.size
		var top_offset: Vector2 = corner_offsets[0].lerp(corner_offsets[1], uv.x)
		var bottom_offset: Vector2 = corner_offsets[3].lerp(corner_offsets[2], uv.x)
		projected.append(point + top_offset.lerp(bottom_offset, uv.y))
	return projected


func _shadow_colors(
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
