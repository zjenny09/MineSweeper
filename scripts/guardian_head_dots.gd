extends Control

const DOT_COLOR := Color("f2c84b")
const DOT_HIGHLIGHT := Color("fff1a3")
const GUARDIAN_CENTERS := [
	72.8571,
	146.5714,
	220.2857,
	294.0,
	367.7143,
	441.4286,
	515.1429,
]

var _wave_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_wave_time += maxf(delta, 0.0)
	queue_redraw()


func _draw() -> void:
	for guardian_index in GUARDIAN_CENTERS.size():
		for dot_index in 3:
			var phase := (
				_wave_time * 3.2
				+ float(guardian_index) * 0.72
				+ float(dot_index) * 0.46
			)
			var position := Vector2(
				GUARDIAN_CENTERS[guardian_index] + float(dot_index - 1) * 7.0,
				38.0 + sin(phase) * 3.5
			)
			draw_circle(position, 2.4, DOT_COLOR)
			draw_circle(position + Vector2(-0.6, -0.7), 0.8, DOT_HIGHLIGHT)
