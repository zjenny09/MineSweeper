@tool
extends Control

const CELL_TEXTURE: Texture2D = preload(
	"res://assets/art/level_01/board/cells/cell_hidden.png"
)
const PAPER_MARGIN := 28.0

@export_range(5, 12, 1) var grid_size := 5:
	set(value):
		grid_size = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_grid_size(value: int) -> void:
	grid_size = clampi(value, 5, 12)


func _draw() -> void:
	var paper_rect := Rect2(Vector2.ZERO, size).grow(PAPER_MARGIN)
	draw_rect(paper_rect, Color(0.94, 0.91, 0.80, 1.0), true)
	draw_rect(paper_rect, Color(0.25, 0.43, 0.24, 0.38), false, 1.5, true)
	var slot_size := size / float(grid_size)
	for row in grid_size:
		for column in grid_size:
			var slot := Rect2(Vector2(column, row) * slot_size, slot_size)
			var inset := maxf(0.8, slot_size.x * 0.012)
			draw_texture_rect(CELL_TEXTURE, slot.grow(-inset), false)
