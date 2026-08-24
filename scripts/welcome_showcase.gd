class_name WelcomeShowcase
extends Control

const SOURCE_SIZE := Vector2(2720.0, 1530.0)
const SUN_SOURCE_RECT := Rect2(2160.0, 66.0, 358.0, 358.0)

const BACKGROUND_PATH := "res://assets/ui/welcome/layers/background_clean.png"
const SUN_PATH := "res://assets/ui/welcome/layers/sun.png"
const LEAF_GREEN_PATH := "res://assets/ui/welcome/layers/leaf_green.png"
const LEAF_YELLOW_PATH := "res://assets/ui/welcome/layers/leaf_yellow.png"
const POLLEN_PATH := "res://assets/ui/welcome/layers/pollen.png"
const WATER_GLINT_PATH := "res://assets/ui/welcome/layers/water_glint.png"

var _background: Texture2D
var _sun: Texture2D
var _leaf_green: Texture2D
var _leaf_yellow: Texture2D
var _pollen: Texture2D
var _water_glint: Texture2D

const LEAF_STARTS := [
	Vector2(1870.0, 610.0),
	Vector2(2135.0, 690.0),
	Vector2(2480.0, 575.0),
]
const POLLEN_STARTS := [
	Vector2(1510.0, 770.0),
	Vector2(1740.0, 690.0),
	Vector2(1970.0, 805.0),
	Vector2(2240.0, 735.0),
	Vector2(2520.0, 825.0),
]

var _elapsed := 0.0


func _ready() -> void:
	_background = load(BACKGROUND_PATH) as Texture2D
	_sun = load(SUN_PATH) as Texture2D
	_leaf_green = load(LEAF_GREEN_PATH) as Texture2D
	_leaf_yellow = load(LEAF_YELLOW_PATH) as Texture2D
	_pollen = load(POLLEN_PATH) as Texture2D
	_water_glint = load(WATER_GLINT_PATH) as Texture2D
	visibility_changed.connect(_sync_processing)
	_sync_processing()


func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, 120.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var cover_scale := maxf(size.x / SOURCE_SIZE.x, size.y / SOURCE_SIZE.y)
	var artwork_size := SOURCE_SIZE * cover_scale
	var artwork_origin := (size - artwork_size) * 0.5
	var artwork_rect := Rect2(artwork_origin, artwork_size)

	draw_texture_rect(_background, artwork_rect, false)
	_draw_sun(artwork_origin, cover_scale)
	_draw_water_glint(artwork_rect)
	_draw_leaves(artwork_origin, cover_scale)
	_draw_pollen(artwork_origin, cover_scale)


func _draw_sun(artwork_origin: Vector2, cover_scale: float) -> void:
	var pulse := (sin(_elapsed * 0.72) + 1.0) * 0.5
	var sun_scale := cover_scale * lerpf(0.992, 1.008, pulse)
	var sun_size := SUN_SOURCE_RECT.size * sun_scale
	var source_center := SUN_SOURCE_RECT.get_center()
	var sun_center := artwork_origin + source_center * cover_scale
	sun_center.y += sin(_elapsed * 0.58) * 3.5
	var sun_rect := Rect2(sun_center - sun_size * 0.5, sun_size)
	draw_texture_rect(_sun, sun_rect, false, Color(1.0, 1.0, 1.0, lerpf(0.96, 1.0, pulse)))


func _draw_water_glint(artwork_rect: Rect2) -> void:
	var shimmer := (sin(_elapsed * 1.15) + 1.0) * 0.5
	draw_texture_rect(
		_water_glint,
		artwork_rect,
		false,
		Color(1.0, 1.0, 1.0, lerpf(0.12, 0.52, shimmer))
	)


func _draw_leaves(artwork_origin: Vector2, cover_scale: float) -> void:
	for index in LEAF_STARTS.size():
		var phase := fmod(_elapsed * (15.0 + float(index) * 2.0) + float(index) * 91.0, 280.0)
		var source_position: Vector2 = LEAF_STARTS[index]
		source_position.x += sin(_elapsed * 0.74 + float(index) * 1.9) * 34.0
		source_position.y += phase
		var fade := sin(phase / 280.0 * PI)
		var texture := _leaf_green if index % 2 == 0 else _leaf_yellow
		var position := artwork_origin + source_position * cover_scale
		var rotation := sin(_elapsed * 1.05 + float(index)) * 0.24
		draw_set_transform(position, rotation, Vector2.ONE * cover_scale * 0.72)
		draw_texture(texture, -texture.get_size() * 0.5, Color(1.0, 1.0, 1.0, fade * 0.72))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pollen(artwork_origin: Vector2, cover_scale: float) -> void:
	for index in POLLEN_STARTS.size():
		var source_position: Vector2 = POLLEN_STARTS[index]
		source_position.x += sin(_elapsed * 0.55 + float(index) * 1.4) * 26.0
		source_position.y += sin(_elapsed * 0.82 + float(index) * 0.9) * 20.0
		var alpha := 0.28 + (sin(_elapsed * 1.4 + float(index)) + 1.0) * 0.16
		var position := artwork_origin + source_position * cover_scale
		draw_set_transform(position, 0.0, Vector2.ONE * cover_scale * 0.76)
		draw_texture(_pollen, -_pollen.get_size() * 0.5, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sync_processing() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		queue_redraw()
