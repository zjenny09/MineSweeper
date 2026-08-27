@tool
extends Control

const SEGMENTS := 48

@export_range(0.0, 1.0, 0.01) var center_y_ratio := 0.70:
	set(value):
		center_y_ratio = value
		queue_redraw()
@export_range(0.05, 0.60, 0.01) var width_ratio := 0.36:
	set(value):
		width_ratio = value
		queue_redraw()
@export_range(0.01, 0.25, 0.005) var height_ratio := 0.095:
	set(value):
		height_ratio = value
		queue_redraw()
@export_range(0.20, 2.0, 0.05) var opacity_multiplier := 1.0:
	set(value):
		opacity_multiplier = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var center := Vector2(size.x * 0.5, size.y * center_y_ratio)
	_draw_ellipse(
		center,
		Vector2(size.x * width_ratio, size.y * height_ratio),
		Color(0.10, 0.07, 0.045, 0.10 * opacity_multiplier),
		0.0
	)
	_draw_ellipse(
		center,
		Vector2(size.x * width_ratio * 0.81, size.y * height_ratio * 0.74),
		Color(0.10, 0.07, 0.045, 0.16 * opacity_multiplier),
		0.0
	)
	_draw_ellipse(
		center,
		Vector2(size.x * width_ratio * 0.56, size.y * height_ratio * 0.47),
		Color(0.08, 0.055, 0.035, 0.24 * opacity_multiplier),
		0.0
	)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, rotation: float) -> void:
	var points := PackedVector2Array()
	for point_index in range(SEGMENTS):
		var angle := TAU * float(point_index) / float(SEGMENTS)
		var point := Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		points.append(center + point.rotated(rotation))
	draw_colored_polygon(points, color)
