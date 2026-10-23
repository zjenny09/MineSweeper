extends Control
class_name BadgeCelebration

signal book_requested(level_number: int)

const ART := preload("res://scripts/art_catalog.gd")

@onready var medal: TextureRect = %Medal
@onready var prompt_label: Label = %PromptLabel

var _level_number := 0
var _accepts_input := false
var _transitioning := false


func _ready() -> void:
	visible = false
	set_process_input(true)


func show_award(level_number: int) -> void:
	if level_number < 1 or level_number > 21:
		return
	_level_number = level_number
	_accepts_input = false
	_transitioning = false
	_refresh_medal_texture()
	prompt_label.text = tr("TXT_0466")
	prompt_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	medal.pivot_offset = medal.size * 0.5
	medal.rotation_degrees = 0.0
	_apply_vertical_reveal(0.0)
	medal.modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = true
	move_to_front()

	var reveal := create_tween()
	reveal.set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_method(_apply_vertical_reveal, 0.0, 1.0, 0.96)
	reveal.tween_property(medal, "modulate:a", 1.0, 0.32)
	reveal.set_parallel(false)
	reveal.tween_interval(0.08)
	reveal.tween_property(prompt_label, "modulate:a", 1.0, 0.24)
	await reveal.finished
	if visible and not _transitioning:
		_accepts_input = true


func hide_award() -> void:
	_accepts_input = false
	_transitioning = false
	visible = false


func refresh_language() -> void:
	prompt_label.text = tr("TXT_0466")
	if _level_number > 0:
		_refresh_medal_texture()


func _refresh_medal_texture() -> void:
	var english := TranslationServer.get_locale().begins_with("en")
	var paths: Array
	var badge_index: int
	if _level_number >= 15:
		paths = ART.SKY_BADGE_EN_PATHS if english else ART.SKY_BADGE_ZH_PATHS
		badge_index = _level_number - 15
	elif _level_number >= 8:
		paths = ART.OCEAN_BADGE_EN_PATHS if english else ART.OCEAN_BADGE_ZH_PATHS
		badge_index = _level_number - 8
	else:
		paths = ART.LAND_BADGE_EN_PATHS if english else ART.LAND_BADGE_ZH_PATHS
		badge_index = _level_number - 1
	medal.texture = load(str(paths[badge_index])) as Texture2D


func _apply_vertical_reveal(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	var growth := lerpf(0.045, 1.0, smoothstep(0.0, 1.0, normalized))
	var facing := absf(cos(normalized * TAU * 1.5))
	var width_factor := maxf(0.035, facing)
	medal.scale = Vector2(growth * width_factor, growth)
	var brightness := lerpf(0.72, 1.0, facing)
	medal.modulate = Color(brightness, brightness, brightness, medal.modulate.a)


func _apply_vertical_store(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	var shrink := lerpf(1.0, 0.055, smoothstep(0.0, 1.0, normalized))
	var facing := absf(cos(normalized * PI))
	medal.scale = Vector2(shrink * maxf(0.035, facing), shrink)
	var brightness := lerpf(0.72, 1.0, facing)
	medal.modulate = Color(brightness, brightness, brightness, medal.modulate.a)


func _input(event: InputEvent) -> void:
	if not visible or not _accepts_input or _transitioning:
		return
	var accepted := false
	if event is InputEventMouseButton:
		accepted = (event as InputEventMouseButton).pressed
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		accepted = (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
		)
	elif event is InputEventJoypadButton:
		accepted = (event as InputEventJoypadButton).pressed
	if not accepted:
		return
	get_viewport().set_input_as_handled()
	_store_in_book()


func _store_in_book() -> void:
	if _transitioning:
		return
	_transitioning = true
	_accepts_input = false
	prompt_label.visible = false
	var store := create_tween()
	store.set_parallel(true)
	store.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	store.tween_method(_apply_vertical_store, 0.0, 1.0, 0.46)
	store.tween_property(medal, "modulate:a", 0.0, 0.38)
	store.set_parallel(false)
	await store.finished
	visible = false
	prompt_label.visible = true
	_transitioning = false
	book_requested.emit(_level_number)
