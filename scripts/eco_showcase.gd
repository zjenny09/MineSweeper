class_name EcoShowcase
extends Control

const GREEN := Color("469d65")
const YELLOW := Color("fadf3c")
const LIGHT_GREEN := Color("a3e086")
const INK := Color("1b2d22")
const DARK_GREEN := Color("2a6243")
const WHITE := Color("ffffff")

const START_BACKGROUND := Color("f6fbf9")
const START_FAR_MOUNTAIN := Color("cfead4")
const START_NEAR_MOUNTAIN := Color("82c888")
const START_LIGHT_HILL := Color("b5e38e")
const START_FRONT_HILL := Color("3f8e5c")
const START_TREE_COLORS := [
	Color("469d65"),
	Color("f4d44b"),
	Color("ed806f"),
	Color("72c6d3"),
]

@export_range(0, 6) var environment_number := 0:
	set(value):
		environment_number = clampi(value, 0, 6)
		queue_redraw()

@export var compact := false:
	set(value):
		compact = value
		queue_redraw()

var _animation_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if environment_number != 0 or not is_visible_in_tree():
		return
	_animation_time += delta
	queue_redraw()


func set_environment(level_number: int) -> void:
	environment_number = clampi(level_number, 0, 6)


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if environment_number == 0:
		draw_rect(Rect2(Vector2.ZERO, size), START_BACKGROUND)
		_draw_start_landscape()
	else:
		draw_rect(Rect2(Vector2.ZERO, size), WHITE)
		_draw_abstract_preview()


func _draw_abstract_preview() -> void:
	_draw_blob(
		Vector2(size.x * 0.72, size.y * 0.60),
		Vector2(size.x * 0.38, size.y * 0.46),
		LIGHT_GREEN,
		0.8
	)
	_draw_blob(
		Vector2(size.x * 0.13, size.y * 0.70),
		Vector2(size.x * 0.30, size.y * 0.43),
		GREEN,
		1.7
	)
	_draw_blob(
		Vector2(size.x * 0.48, size.y * 0.96),
		Vector2(size.x * 0.36, size.y * 0.39),
		YELLOW,
		2.8
	)
	_draw_blob(
		Vector2(size.x * 0.95, size.y * 0.90),
		Vector2(size.x * 0.18, size.y * 0.31),
		GREEN,
		4.1
	)
	_draw_face(Vector2(size.x * 0.18, size.y * 0.60), GREEN)
	_draw_face(Vector2(size.x * 0.68, size.y * 0.46), LIGHT_GREEN)
	_draw_face(Vector2(size.x * 0.50, size.y * 0.80), YELLOW)
	_draw_environment_motif()


func _draw_start_landscape() -> void:
	var sun_center := Vector2(
		size.x * 0.78,
		size.y * 0.19 + sin(_animation_time * 0.75) * 5.0
	)
	var sun_radius := (
		minf(size.x, size.y)
		* 0.075
		* (1.0 + sin(_animation_time * 1.15) * 0.025)
	)
	draw_circle(sun_center, sun_radius, YELLOW)
	draw_circle(sun_center - Vector2(sun_radius * 0.24, 0.0), sun_radius * 0.07, INK)
	draw_circle(sun_center + Vector2(sun_radius * 0.24, 0.0), sun_radius * 0.07, INK)

	var far_mountains := PackedVector2Array([
		Vector2(0.0, size.y * 0.67),
		Vector2(size.x * 0.14, size.y * 0.40),
		Vector2(size.x * 0.25, size.y * 0.59),
		Vector2(size.x * 0.40, size.y * 0.31),
		Vector2(size.x * 0.55, size.y * 0.63),
		Vector2(size.x * 0.71, size.y * 0.38),
		Vector2(size.x * 0.84, size.y * 0.60),
		Vector2(size.x, size.y * 0.34),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(far_mountains, START_FAR_MOUNTAIN)

	var near_mountains := PackedVector2Array([
		Vector2(0.0, size.y * 0.76),
		Vector2(size.x * 0.18, size.y * 0.53),
		Vector2(size.x * 0.34, size.y * 0.73),
		Vector2(size.x * 0.53, size.y * 0.47),
		Vector2(size.x * 0.72, size.y * 0.72),
		Vector2(size.x * 0.89, size.y * 0.50),
		Vector2(size.x, size.y * 0.65),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(near_mountains, START_NEAR_MOUNTAIN)

	_draw_blob(
		Vector2(size.x * 0.42, size.y * 0.96),
		Vector2(size.x * 0.62, size.y * 0.25),
		START_LIGHT_HILL,
		2.2
	)
	_draw_blob(
		Vector2(size.x * 0.77, size.y * 1.04),
		Vector2(size.x * 0.54, size.y * 0.25),
		START_FRONT_HILL,
		3.4
	)

	var tree_x_positions := [0.075, 0.17, 0.305, 0.405, 0.55, 0.665, 0.805, 0.93]
	var tree_scales := [0.052, 0.037, 0.061, 0.045, 0.034, 0.058, 0.048, 0.040]
	for index in tree_x_positions.size():
		var scale := minf(size.x, size.y) * float(tree_scales[index])
		var x := size.x * float(tree_x_positions[index])
		var ground_y := _get_start_ground_y(x)
		var position := Vector2(x, ground_y - scale * 1.05)
		var canopy_color: Color = START_TREE_COLORS[index % START_TREE_COLORS.size()]
		_draw_flat_tree(position, scale, canopy_color, index)

	var grass_x_positions := [0.05, 0.14, 0.23, 0.36, 0.46, 0.59, 0.69, 0.78, 0.89, 0.96]
	for index in grass_x_positions.size():
		var x := size.x * float(grass_x_positions[index])
		var y := _get_front_ground_y(x) + 2.0
		_draw_grass_cluster(
			Vector2(x, y),
			minf(size.x, size.y) * 0.018,
			index
		)


func _draw_flat_tree(
	position: Vector2,
	scale: float,
	canopy_color: Color,
	variant: int
) -> void:
	var sway := sin(_animation_time * 1.25 + float(variant) * 0.83) * scale * 0.10
	var sway_offset := Vector2(sway, 0.0)
	var root := position + Vector2(0.0, scale * 1.05)
	var trunk_top := position - Vector2(0.0, scale * 0.12) + sway_offset * 0.65
	draw_line(
		root,
		trunk_top,
		DARK_GREEN,
		maxf(3.0, scale * 0.20),
		true
	)
	var main_radii := [0.60, 0.68, 0.55, 0.63, 0.58, 0.66, 0.57, 0.64]
	var left_radii := [0.46, 0.35, 0.51, 0.39, 0.44, 0.48, 0.36, 0.43]
	var right_radii := [0.37, 0.50, 0.39, 0.52, 0.34, 0.41, 0.49, 0.38]
	var main_heights := [0.52, 0.58, 0.45, 0.55, 0.49, 0.61, 0.47, 0.56]
	var left_offsets := [0.47, 0.40, 0.52, 0.43, 0.49, 0.45, 0.41, 0.50]
	var right_offsets := [0.39, 0.53, 0.42, 0.48, 0.37, 0.51, 0.46, 0.40]
	var crown_center := position - Vector2(0.0, scale * float(main_heights[variant])) + sway_offset
	var left_center := position + Vector2(
		-scale * float(left_offsets[variant]),
		-scale * (0.18 + 0.04 * float(variant % 3))
	) + sway_offset * 0.88
	var right_center := position + Vector2(
		scale * float(right_offsets[variant]),
		-scale * (0.20 + 0.035 * float((variant + 1) % 3))
	) + sway_offset * 1.08
	var breathe := 1.0 + sin(_animation_time * 1.45 + float(variant) * 0.70) * 0.025
	var crown_radius := scale * float(main_radii[variant]) * breathe
	var left_radius := scale * float(left_radii[variant]) * breathe
	var right_radius := scale * float(right_radii[variant]) * breathe
	draw_circle(crown_center, crown_radius, canopy_color)
	draw_circle(left_center, left_radius, canopy_color)
	draw_circle(right_center, right_radius, canopy_color)
	var outline_width := maxf(2.0, scale * 0.065)
	draw_arc(crown_center, crown_radius, 0.0, TAU, 28, DARK_GREEN, outline_width, true)
	draw_arc(left_center, left_radius, 0.0, TAU, 24, DARK_GREEN, outline_width, true)
	draw_arc(right_center, right_radius, 0.0, TAU, 24, DARK_GREEN, outline_width, true)


func _draw_grass_cluster(position: Vector2, scale: float, variant: int) -> void:
	var sway := sin(_animation_time * 1.70 + float(variant) * 0.92) * scale * 0.34
	draw_line(
		position,
		position + Vector2(-scale * 0.55 + sway, -scale),
		DARK_GREEN,
		2.0,
		true
	)
	draw_line(
		position,
		position + Vector2(sway * 0.72, -scale * 1.15),
		DARK_GREEN,
		2.0,
		true
	)
	draw_line(
		position,
		position + Vector2(scale * 0.62 + sway * 0.45, -scale * 0.88),
		DARK_GREEN,
		2.0,
		true
	)


func _draw_blob(
	center: Vector2,
	radius: Vector2,
	color: Color,
	phase: float
) -> void:
	draw_colored_polygon(_make_blob_points(center, radius, phase), color)


func _make_blob_points(
	center: Vector2,
	radius: Vector2,
	phase: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 64:
		var angle := TAU * float(index) / 64.0
		var wobble := (
			1.0
			+ 0.055 * sin(angle * 3.0 + phase)
			+ 0.025 * sin(angle * 5.0 - phase * 0.6)
		)
		points.append(center + Vector2(
			cos(angle) * radius.x * wobble,
			sin(angle) * radius.y * wobble
		))
	return points


func _get_start_ground_y(x: float) -> float:
	var light_top := _get_blob_top_y(
		x,
		Vector2(size.x * 0.42, size.y * 0.96),
		Vector2(size.x * 0.62, size.y * 0.25),
		2.2
	)
	var front_top := _get_blob_top_y(
		x,
		Vector2(size.x * 0.77, size.y * 1.04),
		Vector2(size.x * 0.54, size.y * 0.25),
		3.4
	)
	return minf(light_top, front_top)


func _get_front_ground_y(x: float) -> float:
	var front_top := _get_blob_top_y(
		x,
		Vector2(size.x * 0.77, size.y * 1.04),
		Vector2(size.x * 0.54, size.y * 0.25),
		3.4
	)
	if front_top < size.y:
		return front_top
	return _get_start_ground_y(x)


func _get_blob_top_y(
	x: float,
	center: Vector2,
	radius: Vector2,
	phase: float
) -> float:
	var points := _make_blob_points(center, radius, phase)
	var top_y := size.y
	for index in points.size():
		var first := points[index]
		var second := points[(index + 1) % points.size()]
		var left := minf(first.x, second.x)
		var right := maxf(first.x, second.x)
		if x < left or x > right or is_equal_approx(first.x, second.x):
			continue
		var ratio := (x - first.x) / (second.x - first.x)
		var y := lerpf(first.y, second.y, ratio)
		top_y = minf(top_y, y)
	return top_y


func _draw_face(position: Vector2, background_color: Color) -> void:
	var radius := minf(size.x, size.y) * (0.010 if compact else 0.008)
	var spacing := radius * 2.4
	var eye_color := INK
	if background_color == GREEN:
		eye_color = Color("14231a")
	draw_circle(position - Vector2(spacing, 0.0), radius, eye_color)
	draw_circle(position + Vector2(spacing, 0.0), radius, eye_color)


func _draw_environment_motif() -> void:
	if environment_number <= 0:
		return
	var center := Vector2(size.x * 0.50, size.y * 0.62)
	var unit := minf(size.x, size.y) * (0.055 if compact else 0.045)
	match environment_number:
		1:
			_draw_sprout(center, unit)
		2:
			_draw_shrub(center, unit)
		3:
			_draw_reeds(center, unit)
		4:
			_draw_grass(center, unit)
		5:
			_draw_tree(center, unit)
		6:
			_draw_mountains(center, unit)


func _draw_sprout(center: Vector2, unit: float) -> void:
	draw_line(center + Vector2(0.0, unit), center - Vector2(0.0, unit), INK, 3.0)
	draw_circle(center - Vector2(unit * 0.55, unit * 0.55), unit * 0.48, GREEN)
	draw_circle(center + Vector2(unit * 0.55, -unit * 0.30), unit * 0.48, LIGHT_GREEN)


func _draw_shrub(center: Vector2, unit: float) -> void:
	for offset in [
		Vector2(-0.8, 0.2), Vector2(-0.35, -0.35),
		Vector2(0.25, -0.45), Vector2(0.75, 0.10), Vector2(0.0, 0.25)
	]:
		draw_circle(center + offset * unit, unit * 0.58, GREEN)


func _draw_reeds(center: Vector2, unit: float) -> void:
	for index in 5:
		var x := center.x + (float(index) - 2.0) * unit * 0.42
		var top := center.y - unit * (0.9 + 0.20 * float(index % 2))
		draw_line(Vector2(x, center.y + unit), Vector2(x, top), GREEN, 3.0)
		draw_circle(Vector2(x, top), unit * 0.18, YELLOW)


func _draw_grass(center: Vector2, unit: float) -> void:
	for index in 7:
		var x := center.x + (float(index) - 3.0) * unit * 0.28
		var lean := unit * (0.32 if index % 2 == 0 else -0.26)
		draw_line(
			Vector2(x, center.y + unit),
			Vector2(x + lean, center.y - unit * (0.55 + 0.08 * index)),
			GREEN,
			3.0
		)


func _draw_tree(center: Vector2, unit: float) -> void:
	draw_rect(Rect2(center.x - unit * 0.12, center.y, unit * 0.24, unit * 1.1), INK)
	draw_circle(center - Vector2(0.0, unit * 0.32), unit * 0.85, GREEN)
	draw_circle(center - Vector2(unit * 0.62, 0.0), unit * 0.60, LIGHT_GREEN)
	draw_circle(center + Vector2(unit * 0.62, 0.0), unit * 0.60, GREEN)


func _draw_mountains(center: Vector2, unit: float) -> void:
	var back := PackedVector2Array([
		center + Vector2(-unit * 2.0, unit),
		center + Vector2(-unit * 0.65, -unit),
		center + Vector2(unit * 0.35, unit),
	])
	var front := PackedVector2Array([
		center + Vector2(-unit * 0.35, unit),
		center + Vector2(unit * 0.70, -unit * 1.20),
		center + Vector2(unit * 2.0, unit),
	])
	draw_colored_polygon(back, LIGHT_GREEN)
	draw_colored_polygon(front, GREEN)
