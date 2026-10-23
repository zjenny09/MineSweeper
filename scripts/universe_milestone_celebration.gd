class_name UniverseMilestoneCelebration
extends Control

signal finished

const TITLE_DURATION := 2.6
const CRAWL_DURATION := 18.0
const TROPHY_REVEAL_DURATION := 0.8
const TROPHY_HOLD_DURATION := 2.2
const HORIZON_RATIO := 0.16
const CRAWL_FONT_SIZE := 34
const LINE_SPACING := 56.0
const DISPLAY_FONT := preload("res://assets/art/common/fonts/ui_handwritten_zh.ttf")

@onready var title_label: Label = %TitleLabel
@onready var trophy: TextureRect = %Trophy
@onready var trophy_name_label: Label = %TrophyNameLabel

var _elapsed := 0.0
var _playing := false
var _trophy_reveal_started := false
var _finished_emitted := false
var _crawl_lines: PackedStringArray = []
var _stars: Array[Vector3] = []
var _trophy_rest_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_initialize_stars()
	title_label.add_theme_font_override("font", DISPLAY_FONT)
	trophy_name_label.add_theme_font_override("font", DISPLAY_FONT)
	_trophy_rest_position = trophy.position
	refresh_localized_text()
	set_process(false)


func play() -> void:
	if _playing:
		return
	refresh_localized_text()
	_elapsed = 0.0
	_playing = true
	_trophy_reveal_started = false
	_finished_emitted = false
	visible = true
	title_label.visible = true
	title_label.modulate = Color.TRANSPARENT
	trophy.visible = false
	trophy.position = _trophy_rest_position
	trophy.modulate = Color.TRANSPARENT
	trophy.scale = Vector2(0.86, 0.86)
	trophy_name_label.visible = false
	trophy_name_label.modulate = Color.TRANSPARENT
	_set_title_progress(0.0)
	set_process(true)
	queue_redraw()


func refresh_localized_text() -> void:
	title_label.text = tr("TXT_0476")
	trophy_name_label.text = tr("TXT_0478")
	_crawl_lines = tr("TXT_0477").split("\n", true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += maxf(0.0, delta)
	if _elapsed < TITLE_DURATION:
		_set_title_progress(_elapsed / TITLE_DURATION)
		queue_redraw()
		return
	title_label.visible = false
	var crawl_elapsed := _elapsed - TITLE_DURATION
	if crawl_elapsed < CRAWL_DURATION:
		queue_redraw()
		return
	if not _trophy_reveal_started:
		_start_trophy_reveal()


func _set_title_progress(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	var alpha := sin(normalized * PI)
	title_label.modulate = Color(1.0, 0.87, 0.38, alpha)
	var scale_value := lerpf(0.92, 1.04, smoothstep(0.0, 1.0, normalized))
	title_label.scale = Vector2.ONE * scale_value


func _initialize_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000
	for index in range(180):
		_stars.append(Vector3(
			rng.randf(),
			rng.randf(),
			rng.randf_range(0.55, 1.75)
		))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("03050e"))
	for star in _stars:
		var center := Vector2(star.x * size.x, star.y * size.y)
		var pulse := 0.62 + sin(_elapsed * 0.8 + star.x * 17.0) * 0.18
		draw_circle(
			center,
			star.z,
			Color(0.72, 0.84, 1.0, pulse)
		)
	if not _playing or _elapsed < TITLE_DURATION \
			or _elapsed >= TITLE_DURATION + CRAWL_DURATION:
		return
	var crawl_progress := clampf(
		(_elapsed - TITLE_DURATION) / CRAWL_DURATION,
		0.0,
		1.0
	)
	var horizon_y := size.y * HORIZON_RATIO
	var total_height := float(maxi(1, _crawl_lines.size())) * LINE_SPACING
	var travel_distance := size.y + total_height + 190.0
	var first_line_y := size.y + 80.0 - crawl_progress * travel_distance
	for line_index in range(_crawl_lines.size()):
		var line := _crawl_lines[line_index]
		var raw_y := first_line_y + float(line_index) * LINE_SPACING
		if raw_y < horizon_y - 35.0 or raw_y > size.y + 80.0:
			continue
		var depth := clampf(
			(size.y - raw_y) / maxf(1.0, size.y - horizon_y),
			0.0,
			1.0
		)
		var perspective_scale := lerpf(1.08, 0.24, depth)
		var alpha := 1.0
		if raw_y < horizon_y + 105.0:
			alpha = clampf((raw_y - horizon_y) / 105.0, 0.0, 1.0)
		elif raw_y > size.y - 70.0:
			alpha = clampf((size.y + 20.0 - raw_y) / 90.0, 0.0, 1.0)
		if line.is_empty():
			continue
		var line_width := DISPLAY_FONT.get_string_size(
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			CRAWL_FONT_SIZE
		).x
		draw_set_transform(
			Vector2(size.x * 0.5, raw_y),
			0.0,
			Vector2(perspective_scale, perspective_scale * 0.72)
		)
		draw_string(
			DISPLAY_FONT,
			Vector2(-line_width * 0.5, 0.0),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			CRAWL_FONT_SIZE,
			Color(1.0, 0.83, 0.28, alpha)
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _start_trophy_reveal() -> void:
	_trophy_reveal_started = true
	trophy.visible = true
	trophy_name_label.visible = true
	trophy.pivot_offset = trophy.size * 0.5
	trophy_name_label.pivot_offset = trophy_name_label.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		trophy,
		"modulate",
		Color.WHITE,
		TROPHY_REVEAL_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		trophy,
		"scale",
		Vector2.ONE,
		TROPHY_REVEAL_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		trophy,
		"position:y",
		trophy.position.y - 16.0,
		TROPHY_REVEAL_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		trophy_name_label,
		"modulate",
		Color.WHITE,
		TROPHY_REVEAL_DURATION
	).set_delay(0.25)
	tween.set_parallel(false)
	tween.tween_interval(TROPHY_HOLD_DURATION)
	tween.tween_callback(_finish_once)


func _finish_once() -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	_playing = false
	set_process(false)
	finished.emit()
