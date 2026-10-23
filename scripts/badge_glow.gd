extends Control

var _phase := 0.0


func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var pulse := 0.5 + 0.5 * sin(_phase * 2.4)
	var ray_count := 28
	for ray_index in ray_count:
		var angle := (
			TAU * float(ray_index) / float(ray_count)
			+ _phase * 0.16
		)
		var half_angle := 0.018 + 0.012 * pulse
		var inner_radius := 112.0
		var outer_radius := 500.0 + 26.0 * pulse
		var points := PackedVector2Array([
			center + Vector2.from_angle(angle - half_angle) * inner_radius,
			center + Vector2.from_angle(angle - half_angle * 0.24) * outer_radius,
			center + Vector2.from_angle(angle + half_angle * 0.24) * outer_radius,
			center + Vector2.from_angle(angle + half_angle) * inner_radius,
		])
		var alpha := 0.055 if ray_index % 2 == 0 else 0.026
		draw_colored_polygon(points, Color(1.0, 0.76, 0.16, alpha))

	for layer in range(8, 0, -1):
		var ratio := float(layer) / 8.0
		var radius := 72.0 + ratio * (240.0 + pulse * 18.0)
		var alpha := (1.0 - ratio) * 0.045 + 0.012
		draw_circle(center, radius, Color(1.0, 0.72, 0.12, alpha))

	for ring_index in range(3):
		var radius := 176.0 + float(ring_index) * 48.0 + pulse * 8.0
		draw_arc(
			center,
			radius,
			0.0,
			TAU,
			128,
			Color(1.0, 0.86, 0.36, 0.22 - float(ring_index) * 0.05),
			3.0,
			true
		)
