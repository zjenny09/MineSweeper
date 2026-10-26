@tool
extends Control

const LAND_BOARD_PAPER_EDGE := Color(0.25, 0.43, 0.24, 0.38)
const LAND_BOARD_CREASE_LIGHT := Color(1.0, 0.98, 0.90, 0.58)
const LAND_BOARD_CREASE_GREEN := Color(0.18, 0.38, 0.19, 0.42)

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


func configure_grid(column_count: int, row_count: int) -> void:
	columns = maxi(column_count, 1)
	rows = maxi(row_count, 1)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var play_rect := Rect2(Vector2.ZERO, size)
	draw_dashed_line(
		play_rect.position,
		Vector2(play_rect.end.x, play_rect.position.y),
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		Vector2(play_rect.end.x, play_rect.position.y),
		play_rect.end,
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		play_rect.end,
		Vector2(play_rect.position.x, play_rect.end.y),
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	draw_dashed_line(
		Vector2(play_rect.position.x, play_rect.end.y),
		play_rect.position,
		LAND_BOARD_PAPER_EDGE,
		1.6,
		7.0,
		true,
		true
	)
	var slot_size := play_rect.size / Vector2(columns, rows)
	for column in range(1, columns):
		var x := slot_size.x * column
		var line_start := Vector2(x, 3.0)
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
	for row in range(1, rows):
		var y := slot_size.y * row
		var line_start := Vector2(3.0, y)
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
