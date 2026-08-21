class_name EcoShowcase
extends Control

@export_range(0, 6) var environment_number := 0:
	set(value):
		environment_number = clampi(value, 0, 6)
		queue_redraw()

@export var compact := false:
	set(value):
		compact = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func set_environment(level_number: int) -> void:
	environment_number = clampi(level_number, 0, 6)


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var palette := _palette()
	_draw_sky(palette)
	_draw_sun(palette)
	_draw_far_land(palette)
	_draw_near_land(palette)
	if environment_number == 3:
		_draw_wetland(palette)
	elif environment_number == 6 or environment_number == 0:
		_draw_mountain_caps(palette)
	_draw_vegetation(palette)
	_draw_restoration_glow(palette)
	draw_rect(Rect2(Vector2.ZERO, size), Color(palette.border), false, 2.0)


func _draw_sky(palette: Dictionary) -> void:
	var bands := 8
	for band in bands:
		var ratio := float(band) / float(bands)
		var color: Color = Color(palette.sky_top).lerp(Color(palette.sky_bottom), ratio)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / float(bands) + 1.0), color)


func _draw_sun(palette: Dictionary) -> void:
	var center := Vector2(size.x * 0.77, size.y * (0.20 if compact else 0.18))
	var radius := minf(size.x, size.y) * (0.09 if compact else 0.075)
	draw_circle(center, radius * 1.7, Color(Color(palette.glow), 0.10))
	draw_circle(center, radius, Color(Color(palette.glow), 0.82))


func _draw_far_land(palette: Dictionary) -> void:
	var horizon := size.y * (0.56 if compact else 0.58)
	var points := PackedVector2Array([
		Vector2(0.0, horizon),
		Vector2(size.x * 0.13, size.y * 0.38),
		Vector2(size.x * 0.25, horizon * 0.90),
		Vector2(size.x * 0.40, size.y * 0.29),
		Vector2(size.x * 0.56, horizon * 0.94),
		Vector2(size.x * 0.72, size.y * 0.34),
		Vector2(size.x * 0.86, horizon * 0.88),
		Vector2(size.x, size.y * 0.31),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	if environment_number == 4:
		points = PackedVector2Array([
			Vector2(0.0, horizon), Vector2(size.x * 0.24, horizon * 0.87),
			Vector2(size.x * 0.48, horizon), Vector2(size.x * 0.73, horizon * 0.84),
			Vector2(size.x, horizon * 0.96), Vector2(size.x, size.y), Vector2(0.0, size.y),
		])
	draw_colored_polygon(points, Color(palette.far_land))


func _draw_near_land(palette: Dictionary) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, size.y * 0.73),
		Vector2(size.x * 0.18, size.y * 0.61),
		Vector2(size.x * 0.38, size.y * 0.74),
		Vector2(size.x * 0.58, size.y * 0.57),
		Vector2(size.x * 0.78, size.y * 0.71),
		Vector2(size.x, size.y * 0.59),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(points, Color(palette.near_land))
	var foreground := PackedVector2Array([
		Vector2(0.0, size.y * 0.88), Vector2(size.x * 0.25, size.y * 0.82),
		Vector2(size.x * 0.50, size.y * 0.89), Vector2(size.x * 0.76, size.y * 0.80),
		Vector2(size.x, size.y * 0.86), Vector2(size.x, size.y), Vector2(0.0, size.y),
	])
	draw_colored_polygon(foreground, Color(palette.foreground))


func _draw_mountain_caps(palette: Dictionary) -> void:
	var peaks := [
		[Vector2(0.32, 0.36), Vector2(0.40, 0.29), Vector2(0.48, 0.45)],
		[Vector2(0.65, 0.43), Vector2(0.72, 0.34), Vector2(0.79, 0.47)],
		[Vector2(0.91, 0.40), Vector2(1.0, 0.31), Vector2(1.0, 0.49)],
	]
	for peak in peaks:
		var points := PackedVector2Array()
		for point in peak:
			points.append(Vector2(point.x * size.x, point.y * size.y))
		draw_colored_polygon(points, Color(Color(palette.glow), 0.50))


func _draw_wetland(palette: Dictionary) -> void:
	for index in 3:
		var y := size.y * (0.72 + float(index) * 0.07)
		draw_line(Vector2(size.x * 0.08, y), Vector2(size.x * (0.58 + 0.12 * index), y), Color(Color(palette.glow), 0.35), 3.0)
	for index in 12:
		var x := size.x * (0.06 + float(index) * 0.075)
		var base := size.y * (0.88 - float(index % 3) * 0.015)
		draw_line(Vector2(x, base), Vector2(x + size.x * 0.012, base - size.y * 0.11), Color(palette.border), 2.0)


func _draw_vegetation(palette: Dictionary) -> void:
	var tree_count := 7 if compact else 15
	if environment_number == 4:
		tree_count = 5 if compact else 9
	elif environment_number == 5:
		tree_count = 11 if compact else 22
	elif environment_number == 6:
		tree_count = 4 if compact else 8
	for index in tree_count:
		var t := float(index + 1) / float(tree_count + 1)
		var x := size.x * t
		var y := size.y * (0.76 + 0.07 * sin(float(index) * 2.13))
		var scale := minf(size.x, size.y) * (0.032 + 0.010 * float(index % 3))
		_draw_tree(Vector2(x, y), scale, palette)
	if environment_number == 1 or environment_number == 0:
		var sprout_center := Vector2(size.x * 0.50, size.y * 0.78)
		draw_line(sprout_center, sprout_center - Vector2(0.0, size.y * 0.12), Color(palette.border), 4.0)
		draw_circle(sprout_center - Vector2(size.x * 0.025, size.y * 0.10), minf(size.x, size.y) * 0.025, Color(palette.glow))
		draw_circle(sprout_center + Vector2(size.x * 0.025, -size.y * 0.075), minf(size.x, size.y) * 0.025, Color(palette.glow))


func _draw_tree(position: Vector2, scale: float, palette: Dictionary) -> void:
	draw_rect(Rect2(position.x - scale * 0.10, position.y - scale * 0.1, scale * 0.20, scale * 1.0), Color(palette.trunk))
	draw_circle(position - Vector2(0.0, scale * 0.45), scale * 0.60, Color(palette.foliage_dark))
	draw_circle(position - Vector2(scale * 0.38, scale * 0.20), scale * 0.42, Color(palette.foliage))
	draw_circle(position + Vector2(scale * 0.35, -scale * 0.28), scale * 0.45, Color(palette.foliage))


func _draw_restoration_glow(palette: Dictionary) -> void:
	var glow_count := 5 if compact else 11
	for index in glow_count:
		var x := size.x * (0.08 + 0.083 * float(index))
		var y := size.y * (0.20 + 0.10 * float((index * 7) % 5))
		var radius := minf(size.x, size.y) * (0.006 + 0.002 * float(index % 2))
		draw_circle(Vector2(x, y), radius * 2.4, Color(Color(palette.glow), 0.10))
		draw_circle(Vector2(x, y), radius, Color(Color(palette.glow), 0.75))


func _palette() -> Dictionary:
	var palettes := [
		{"sky_top": "102720", "sky_bottom": "244d3c", "far_land": "315c49", "near_land": "3f765a", "foreground": "183c2d", "foliage": "69b578", "foliage_dark": "397a4d", "trunk": "604d37", "glow": "d5ef83", "border": "73b890"},
		{"sky_top": "17302a", "sky_bottom": "31584a", "far_land": "54705a", "near_land": "60825f", "foreground": "294a34", "foliage": "8bcf76", "foliage_dark": "4c8c55", "trunk": "735b3d", "glow": "dff58d", "border": "82c793"},
		{"sky_top": "132b25", "sky_bottom": "2b5245", "far_land": "3f6752", "near_land": "416f50", "foreground": "1d432e", "foliage": "5fa96c", "foliage_dark": "326d45", "trunk": "66503a", "glow": "c9e982", "border": "6eb283"},
		{"sky_top": "17313a", "sky_bottom": "32616a", "far_land": "52756c", "near_land": "477767", "foreground": "1c4e42", "foliage": "77aa68", "foliage_dark": "3e7550", "trunk": "65543f", "glow": "b9e6c4", "border": "76b7a6"},
		{"sky_top": "18342d", "sky_bottom": "41705b", "far_land": "70865d", "near_land": "6f985f", "foreground": "345b3c", "foliage": "89bd67", "foliage_dark": "4a8050", "trunk": "735b3d", "glow": "e2ef94", "border": "8ac88b"},
		{"sky_top": "0d211c", "sky_bottom": "24483b", "far_land": "315441", "near_land": "2f6043", "foreground": "153624", "foliage": "3f8654", "foliage_dark": "245e3d", "trunk": "584637", "glow": "9fda7a", "border": "5aa875"},
		{"sky_top": "101e24", "sky_bottom": "354c51", "far_land": "526260", "near_land": "3f6256", "foreground": "1e4035", "foliage": "527b59", "foliage_dark": "315442", "trunk": "594c42", "glow": "d8e7d4", "border": "7fa899"},
	]
	return palettes[environment_number]
