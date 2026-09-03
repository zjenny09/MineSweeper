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
@export var cast_offset := Vector2(6.0, 2.0):
	set(value):
		cast_offset = value
		queue_redraw()
@export_range(-0.40, 0.40, 0.01) var cast_rotation := 0.04:
	set(value):
		cast_rotation = value
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
		center + cast_offset,
		Vector2(size.x * width_ratio * 1.08, size.y * height_ratio * 0.92),
		Color(0.11, 0.09, 0.06, 0.09 * opacity_multiplier),
		cast_rotation
	)
	_draw_ellipse(
		center + cast_offset * 0.45,
		Vector2(size.x * width_ratio * 0.78, size.y * height_ratio * 0.68),
		Color(0.10, 0.075, 0.05, 0.15 * opacity_multiplier),
		cast_rotation * 0.5
	)
	_draw_ellipse(
		center,
		Vector2(size.x * width_ratio * 0.46, size.y * height_ratio * 0.42),
		Color(0.075, 0.055, 0.04, 0.26 * opacity_multiplier),
		0.0
	)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, rotation: float) -> void:
	var points := PackedVector2Array()
	for point_index in range(SEGMENTS):
		var angle := TAU * float(point_index) / float(SEGMENTS)
		var point := Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		points.append(center + point.rotated(rotation))
	draw_colored_polygon(points, color)
