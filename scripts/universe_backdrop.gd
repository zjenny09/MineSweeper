extends Control

const STAR_COUNT := 220
const LAYER_SPEEDS := [4.0, 11.0, 25.0]

var _star_positions := PackedVector2Array()
var _star_sizes := PackedFloat32Array()
var _star_phases := PackedFloat32Array()
var _star_layers := PackedInt32Array()
var _elapsed := 0.0
var _speed_multiplier := 1.0
var _target_speed_multiplier := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 874221
	for index in range(STAR_COUNT):
		var layer := index % 3
		_star_positions.append(Vector2(_rng.randf(), _rng.randf()))
		_star_sizes.append(_rng.randf_range(0.55, 1.55) + float(layer) * 0.35)
		_star_phases.append(_rng.randf_range(0.0, TAU))
		_star_layers.append(layer)
	set_process(true)


func set_warp_active(active: bool) -> void:
	_target_speed_multiplier = 4.6 if active else 1.0


func _process(delta: float) -> void:
	_elapsed += delta
	_speed_multiplier = move_toward(
		_speed_multiplier,
		_target_speed_multiplier,
		delta * (3.8 if _target_speed_multiplier > 1.0 else 1.8)
	)
	queue_redraw()


func _draw() -> void:
	for index in range(_star_positions.size()):
		var layer := _star_layers[index]
		var speed: float = float(LAYER_SPEEDS[layer]) * _speed_multiplier
		var travel_width := size.x + 80.0
		var x := fposmod(
			_star_positions[index].x * travel_width - _elapsed * speed,
			travel_width
		) - 40.0
		var y := (
			_star_positions[index].y * size.y
			+ sin(_elapsed * 0.16 + _star_phases[index]) * float(layer + 1) * 1.8
		)
		var center := Vector2(x, y)
		var pulse := 0.58 + sin(_elapsed * 0.76 + _star_phases[index]) * 0.20
		var radius := _star_sizes[index]
		var color := Color(
			0.72 + float(layer) * 0.07,
			0.84 + float(layer) * 0.04,
			1.0,
			pulse * (0.48 + float(layer) * 0.16)
		)
		if layer == 2 and _speed_multiplier > 1.45:
			var streak := 4.0 + (_speed_multiplier - 1.0) * 6.0
			draw_line(
				center + Vector2(streak, 0.0),
				center - Vector2(streak, 0.0),
				Color(color, color.a * 0.62),
				maxf(0.8, radius * 0.72),
				true
			)
		else:
			draw_circle(center, radius, color)
			if layer == 2 and radius > 1.65:
				draw_line(
					center - Vector2(3.5, 0.0),
					center + Vector2(3.5, 0.0),
					Color(color, color.a * 0.45),
					0.8
				)
