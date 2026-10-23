extends Control
class_name BadgeBook

signal closed
signal hall_requested
signal next_level_requested
signal return_to_victory_requested

const ART := preload("res://scripts/art_catalog.gd")
const BOOK_SCALE := Vector2(0.82, 0.82)
const BADGE_COVER_SCALE := Vector2(1.06, 1.06)

@onready var book_visual: Control = %BookVisual
@onready var book_art: TextureRect = %BookArt
@onready var title_label: Label = %TitleLabel
@onready var page_label: Label = %PageLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var page_turn_button: TextureButton = %PageTurnButton
@onready var back_button: Button = %BadgeBookBackButton
@onready var badge_slots: Array[TextureRect] = [
	%Badge1,
	%Badge2,
	%Badge3,
	%Badge4,
	%Badge5,
	%Badge6,
	%Badge7,
]

var _completed_levels: Dictionary = {}
var _return_page := &"level_select"
var _victory_level := 0
var _page_index := 0


func _ready() -> void:
	book_art.texture = load(ART.LAND_BADGE_BOOK) as Texture2D
	page_turn_button.texture_normal = load(ART.LAND_BADGE_PAGE_TURN) as Texture2D
	for badge in badge_slots:
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		badge.pivot_offset = badge.size * 0.5
		badge.scale = BADGE_COVER_SCALE
	page_turn_button.pressed.connect(_request_hall)
	back_button.pressed.connect(_close_from_button)
	visible = false
	refresh_language()


func open_book(
	completed_levels: Array,
	return_page: StringName,
	victory_level: int = 0,
	chapter: StringName = &""
) -> void:
	_completed_levels.clear()
	for level_number in completed_levels:
		_completed_levels[int(level_number)] = true
	_return_page = return_page
	_victory_level = victory_level
	_page_index = (
		_chapter_page_index(chapter)
		if chapter != &""
		else (2 if _victory_level >= 15 else (1 if _victory_level >= 8 else 0))
	)
	refresh_language()
	_refresh_badges()
	visible = true
	move_to_front()
	book_visual.pivot_offset = book_visual.size * 0.5
	book_visual.scale = BOOK_SCALE * 0.9
	book_visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var opening := create_tween()
	opening.set_parallel(true)
	opening.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	opening.tween_property(book_visual, "scale", BOOK_SCALE, 0.42)
	opening.tween_property(book_visual, "modulate:a", 1.0, 0.24)
	if _victory_level >= 1 and _victory_level <= 21:
		var awarded_badge := badge_slots[(_victory_level - 1) % badge_slots.size()]
		awarded_badge.pivot_offset = awarded_badge.size * 0.5
		awarded_badge.scale = BADGE_COVER_SCALE * 0.12
		opening.tween_property(
			awarded_badge,
			"scale",
			BADGE_COVER_SCALE,
			0.62
		).set_delay(0.16)
	page_turn_button.release_focus()


func _chapter_page_index(chapter: StringName) -> int:
	match chapter:
		&"ocean":
			return 1
		&"sky":
			return 2
		_:
			return 0


func refresh_language() -> void:
	title_label.text = tr("TXT_0463")
	match _page_index:
		1:
			page_label.text = tr("TXT_0471")
		2:
			page_label.text = tr("TXT_0472")
		_:
			page_label.text = tr("TXT_0464")
	back_button.text = tr("TXT_0465")
	instruction_label.text = tr("TXT_0467") if is_victory_context() else tr("TXT_0468")
	page_turn_button.tooltip_text = tr("TXT_0469")
	_refresh_badges()


func is_victory_context() -> bool:
	return _return_page == &"game" and _victory_level > 0


func request_close() -> void:
	if not visible:
		return
	if is_victory_context():
		return_to_victory_requested.emit()
	else:
		closed.emit()


func _refresh_badges() -> void:
	if not is_node_ready():
		return
	var english := TranslationServer.get_locale().begins_with("en")
	var paths: Array
	var first_level: int
	if _page_index == 2:
		paths = ART.SKY_BADGE_EN_PATHS if english else ART.SKY_BADGE_ZH_PATHS
		first_level = 15
	elif _page_index == 1:
		paths = ART.OCEAN_BADGE_EN_PATHS if english else ART.OCEAN_BADGE_ZH_PATHS
		first_level = 8
	else:
		paths = ART.LAND_BADGE_EN_PATHS if english else ART.LAND_BADGE_ZH_PATHS
		first_level = 1
	for index in badge_slots.size():
		var badge := badge_slots[index]
		badge.texture = (
			load(str(paths[index])) as Texture2D
			if _completed_levels.has(first_level + index)
			else null
		)
		badge.pivot_offset = badge.size * 0.5
		badge.scale = BADGE_COVER_SCALE


func _request_hall() -> void:
	if visible:
		hall_requested.emit()


func _close_from_button() -> void:
	request_close()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		request_close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			request_close()
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if page_turn_button.get_global_rect().has_point(mouse_event.position):
			return
		if is_victory_context():
			next_level_requested.emit()
			get_viewport().set_input_as_handled()
		return
	if not is_victory_context():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
		):
			next_level_requested.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		next_level_requested.emit()
		get_viewport().set_input_as_handled()
