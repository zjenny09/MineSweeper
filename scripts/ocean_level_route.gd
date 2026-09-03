class_name OceanLevelRoute
extends Control

var marker_positions := PackedVector2Array():
	set(value):
		marker_positions = value
		queue_redraw()


func _draw() -> void:
	if marker_positions.size() < 2:
		return
	var curve_points := _sample_curve(marker_positions)
	_draw_dashed_curve(curve_points, Color(0.10, 0.30, 0.36, 0.22), 5.0, 12.0, 8.0)
	_draw_dashed_curve(curve_points, Color("d77b5a"), 2.6, 12.0, 8.0)


func _sample_curve(control_points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for segment in range(control_points.size() - 1):
		var p0 := control_points[maxi(segment - 1, 0)]
		var p1 := control_points[segment]
		var p2 := control_points[segment + 1]
		var p3 := control_points[mini(segment + 2, control_points.size() - 1)]
		for step in range(25):
			var t := float(step) / 24.0
			var t2 := t * t
			var t3 := t2 * t
			result.append(0.5 * (
				2.0 * p1
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	return result


func _draw_dashed_curve(
	curve_points: PackedVector2Array,
	color: Color,
	width: float,
	dash_length: float,
	gap_length: float
) -> void:
	var cycle := dash_length + gap_length
	var distance_along := 0.0
	for index in range(curve_points.size() - 1):
		var segment_start := curve_points[index]
		var segment_end := curve_points[index + 1]
		var segment_vector := segment_end - segment_start
		var segment_length := segment_vector.length()
		if segment_length <= 0.001:
			continue
		var direction := segment_vector / segment_length
		var local_distance := 0.0
		while local_distance < segment_length:
			var cycle_position := fposmod(distance_along + local_distance, cycle)
			var step_length: float
			if cycle_position < dash_length:
				step_length = minf(dash_length - cycle_position, segment_length - local_distance)
				var from := segment_start + direction * local_distance
				var to := from + direction * step_length
				draw_line(from, to, color, width, true)
			else:
				step_length = minf(cycle - cycle_position, segment_length - local_distance)
			local_distance += maxf(step_length, 0.001)
		distance_along += segment_length
