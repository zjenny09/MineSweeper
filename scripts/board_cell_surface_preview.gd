@tool
extends Control

@export var columns := 5:
	set(value):
		columns = maxi(value, 1)
		queue_redraw()
@export var rows := 5:
	set(value):
		rows = maxi(value, 1)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or size.x <= 0.0 or size.y <= 0.0:
		return
	var line_color := Color(0.18, 0.35, 0.20, 0.42)
	var fill_color := Color(0.72, 0.86, 0.62, 0.12)
	draw_rect(Rect2(Vector2.ZERO, size), fill_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), line_color, false, 2.0)
	for column in range(1, columns):
		var x := size.x * float(column) / float(columns)
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), line_color, 1.0)
	for row in range(1, rows):
		var y := size.y * float(row) / float(rows)
		draw_line(Vector2(0.0, y), Vector2(size.x, y), line_color, 1.0)
