@tool
extends Control

signal level_started(level_number: int)
signal level_completed(level_number: int, elapsed_ms: int)
signal level_select_requested
signal main_menu_requested
signal settings_requested
signal exit_game_requested
signal pause_changed(is_paused: bool)

const ART := preload("res://scripts/art_catalog.gd")

const LAND_DESK_BACKGROUND_PATH := ART.LEVEL_01_LAND_BACKGROUND
const LAND_DESK_BACKGROUND_SOURCE_REGION := Rect2i(0, 0, 2848, 1600)
const LEVEL_ONE_BACKGROUND_PATH := ART.LAND_UNIFIED_STAGE_BODY
const LAND_UNIFIED_SHADOW_PATH := ART.LAND_UNIFIED_STAGE_SHADOW
const LEVEL_ONE_BOARD_TRAY_PATH := ART.LEVEL_01_BOARD_TRAY
const LEVEL_ONE_STATUS_NOTE_PATH := ART.LEVEL_01_NOTE_CURVED
const LEVEL_ONE_STRAIGHT_NOTE_PATH := ART.LEVEL_01_NOTE_STRAIGHT
const LEVEL_ONE_PAUSE_MENU_FRAME_PATH := ART.LEVEL_01_PAUSE_MENU_FRAME
const LAND_PAUSE_NORMAL_PATH := ART.LAND_PAUSE_NORMAL
const LAND_PAUSE_HOVER_PATH := ART.LAND_PAUSE_HOVER
const LAND_PAUSE_FOCUS_PATH := ART.LAND_PAUSE_FOCUS
const LAND_PAUSE_PRESSED_PATH := ART.LAND_PAUSE_PRESSED
const LAND_REGENERATE_NORMAL_PATH := ART.LAND_REGENERATE_NORMAL
const LAND_REGENERATE_HOVER_PATH := ART.LAND_REGENERATE_HOVER
const LAND_REGENERATE_FOCUS_PATH := ART.LAND_REGENERATE_FOCUS
const LAND_REGENERATE_PRESSED_PATH := ART.LAND_REGENERATE_PRESSED
const LEVEL_ONE_SEED_STICKER_PATH := ART.LEVEL_01_DECOR_BACKGROUND_SEED
const LEVEL_ONE_BUD_SPROUT_PATH := ART.LEVEL_01_DECOR_STATUS_NOTE_BUD
const LEVEL_ONE_LEAF_SPROUT_PATH := ART.LEVEL_01_DECOR_BACKGROUND_LEAF_SPROUT
const LAND_DECORATIVE_HEALTHY_PATHS := [
	ART.LEVEL_01_DECOR_LEFT_SPROUT_HEALTHY,
	ART.LEVEL_02_DECOR_SHRUB_HEALTHY,
	ART.LEVEL_03_DECOR_WETLAND_HEALTHY,
	ART.LEVEL_04_DECOR_GRASS_HEALTHY,
	ART.LEVEL_05_DECOR_TREE_HEALTHY,
]
const LAND_DECORATIVE_FAILED_PATHS := [
	ART.LEVEL_01_DECOR_LEFT_SPROUT_WILTED,
	ART.LEVEL_02_DECOR_SHRUB_WILTED,
	ART.LEVEL_03_DECOR_WETLAND_POLLUTED,
	ART.LEVEL_04_DECOR_GRASS_WILTED,
	ART.LEVEL_05_DECOR_TREE_WILTED,
]
const LAND_DECORATIVE_CENTER_X := 218.0
const LAND_DECORATIVE_BASELINE_Y := 648.0
const LAND_DECORATIVE_MAX_SIZE := Vector2(68.0, 56.0)
const LEVEL_ONE_SIDE_GUARDIAN_A_PATH := ART.LEVEL_01_GUARDIAN_RIGHT_YELLOW_STANDING
const LEVEL_ONE_SIDE_GUARDIAN_B_PATH := ART.LEVEL_01_GUARDIAN_RIGHT_WHITE_SITTING
const LEVEL_ONE_SPROUT_GUARDIAN_LEFT_PATH := ART.LEVEL_01_GUARDIAN_LEFT_ROBOT
const LEVEL_ONE_SPROUT_GUARDIAN_RIGHT_PATH := ART.LEVEL_01_GUARDIAN_LEFT_SPROUT_FACING_LEFT
const FAILURE_LEFT_GUARDIAN_PATH := ART.LAND_GUARDIAN_LEFT_CRYING
const FAILURE_RIGHT_YELLOW_GUARDIAN_PATH := ART.LAND_GUARDIAN_RIGHT_YELLOW_CRYING
const FAILURE_RIGHT_WHITE_GUARDIAN_PATH := ART.LAND_GUARDIAN_RIGHT_WHITE_CRYING
const HANDMADE_FONT_PATH := ART.UI_FONT
const PAPER_BUTTON_PATH := ART.TUTORIAL_GUIDE_BUTTON_SECONDARY
const PAPER_BUTTON_SELECTED_PATH := ART.TUTORIAL_GUIDE_BUTTON_SECONDARY
const PAPER_BUTTON_PRESSED_PATH := ART.TUTORIAL_GUIDE_BUTTON_SECONDARY
const GREEN_BUTTON_PATH := ART.TUTORIAL_GUIDE_BUTTON_PRIMARY
const GREEN_BUTTON_SELECTED_PATH := ART.TUTORIAL_GUIDE_BUTTON_PRIMARY
const GREEN_BUTTON_PRESSED_PATH := ART.TUTORIAL_GUIDE_BUTTON_PRIMARY

@export var auto_start := true
@export var editor_preview_pause_menu := false


enum TutorialStep {
	INACTIVE,
	FIRST_REVEAL,
	NUMBER_INFO,
	MARK_CORE,
	CHORD,
	COMPLETE,
}

const ADAPTIVE_ASSIST_FIRST_LEVEL_INDEX := 0
const FIRST_CLICK_MINE_STREAK_THRESHOLD := 3
const EARLY_LOSS_STREAK_THRESHOLD := 3
const EARLY_LOSS_MOVE_LIMIT := 5


@onready var board: MinesweeperBoard = %Board
@onready var eco_showcase: Control = %EcoShowcase
@onready var land_desk_background: TextureRect = %LandDeskBackground
@onready var level_one_background: TextureRect = %LevelOneBackground
@onready var land_unified_shadow: TextureRect = %LandUnifiedShadow
@onready var land_sticker_sets: Control = %LandStickerSets
@onready var bud_sprout_decoration_a: TextureRect = %BudSproutDecorationA
@onready var leaf_sprout_decoration_a: TextureRect = \
		$LevelOneBackground/LevelOneDecorations/LeafSproutDecorationA
@onready var seed_decoration_a: TextureRect = \
		$LevelOneBackground/LevelOneDecorations/SeedDecorationA
@onready var seed_decoration_b: TextureRect = \
		$LevelOneBackground/LevelOneDecorations/SeedDecorationB
@onready var environment_panel: Control = %EnvironmentPanel
@onready var hud_panel: PanelContainer = %HudPanel
@onready var info_note_artwork: TextureRect = %InfoNoteArtwork
@onready var info_back_artwork: TextureRect = %InfoBackArtwork
@onready var status_note_artwork: TextureRect = %StatusNoteArtwork
@onready var board_tray: TextureRect = %BoardTray
@onready var board_shadow: Panel = %BoardShadow
@onready var victory_animation_player: AnimationPlayer = %LevelOneAnimationPlayer
@onready var left_decorative_sprout: TextureRect = %LeftDecorativeSprout
@onready var right_guardian_a: TextureRect = %RightGuardianA
@onready var right_guardian_b: TextureRect = %RightGuardianB
@onready var left_sprout_guardian_left: TextureRect = %LeftSproutGuardianLeft
@onready var left_sprout_guardian_right: TextureRect = %LeftSproutGuardianRight
@onready var right_guardian_a_shadow: Control = %RightGuardianAShadow
@onready var right_guardian_b_shadow: Control = %RightGuardianBShadow
@onready var left_sprout_guardian_left_shadow: Control = %LeftSproutGuardianLeftShadow
@onready var left_sprout_guardian_right_shadow: Control = %LeftSproutGuardianRightShadow
@onready var subtitle_label: Label = %SubtitleLabel
@onready var level_summary_label: Label = %LevelSummaryLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var status_label: Label = %StatusLabel
@onready var flags_label: Label = %FlagsLabel
@onready var timer_label: Label = %TimerLabel
@onready var instructions_label: Label = %InstructionsLabel
@onready var quick_buttons: HBoxContainer = %QuickButtons
@onready var pause_button: TextureButton = %PauseButton
@onready var restart_button: TextureButton = %RestartButton
@onready var pause_button_label: Label = %PauseButtonLabel
@onready var restart_button_label: Label = %RestartButtonLabel
@onready var first_move_guide = %FirstMoveGuide
@onready var pause_overlay: Control = %PauseOverlay
@onready var pause_menu_frame_artwork: NinePatchRect = %PauseMenuFrameArtwork
@onready var resume_button: Button = %ResumeButton
@onready var pause_restart_button: Button = %PauseRestartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var pause_settings_button: Button = %PauseSettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var exit_game_button: Button = %ExitGameButton

var current_level_index := 0
var _first_click_mine_streaks: Dictionary = {}
var _early_loss_streaks: Dictionary = {}
var _advance_available := false
var _session_paused := false
var _completion_emitted := false
var _elapsed_before_segment_ms := 0
var _segment_started_ms := 0
var _timer_running := false
var _operation_mode := 0
var _first_move_guide_enabled := true
var _tutorial_step: int = TutorialStep.INACTIVE
var _tutorial_dismissed_for_session := false
var _tutorial_number_index := -1
var _tutorial_target_index := -1
var _tutorial_last_revealed_index := -1
var _runtime_texture_cache: Dictionary = {}


func _ready() -> void:
	_apply_handmade_interface()
	if Engine.is_editor_hint():
		pause_overlay.visible = editor_preview_pause_menu
		return
	board.state_changed.connect(_on_state_changed)
	board.flags_changed.connect(_on_flags_changed)
	board.reveal_completed.connect(_on_reveal_completed)
	board.flag_completed.connect(_on_flag_completed)
	board.chord_completed.connect(_on_chord_completed)
	first_move_guide.exit_requested.connect(_on_tutorial_exit_requested)
	first_move_guide.next_requested.connect(_on_tutorial_next_requested)
	restart_button.pressed.connect(_on_primary_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_game_button_pressed)
	if auto_start:
		start_level(_requested_level_index())
	else:
		visible = false
	set_process(true)


func _apply_handmade_interface() -> void:
	land_desk_background.texture = _load_runtime_texture_region(
		LAND_DESK_BACKGROUND_PATH,
		LAND_DESK_BACKGROUND_SOURCE_REGION
	)
	level_one_background.texture = _load_runtime_texture(LEVEL_ONE_BACKGROUND_PATH)
	land_unified_shadow.texture = _load_runtime_texture(LAND_UNIFIED_SHADOW_PATH)
	board_tray.texture = _load_runtime_texture(LEVEL_ONE_BOARD_TRAY_PATH)
	_apply_land_decorative_texture(LAND_DECORATIVE_HEALTHY_PATHS[0])
	right_guardian_a.texture = _load_runtime_texture(LEVEL_ONE_SIDE_GUARDIAN_B_PATH)
	right_guardian_b.texture = _load_runtime_texture(LEVEL_ONE_SIDE_GUARDIAN_A_PATH)
	left_sprout_guardian_left.texture = _load_runtime_texture(
		LEVEL_ONE_SPROUT_GUARDIAN_LEFT_PATH
	)
	left_sprout_guardian_right.texture = _load_runtime_texture(
		LEVEL_ONE_SPROUT_GUARDIAN_RIGHT_PATH
	)
	var seed_texture := _load_runtime_texture(LEVEL_ONE_SEED_STICKER_PATH)
	seed_decoration_a.texture = seed_texture
	seed_decoration_b.texture = seed_texture
	var bud_sprout_texture := _load_runtime_texture(LEVEL_ONE_BUD_SPROUT_PATH)
	bud_sprout_decoration_a.texture = bud_sprout_texture
	var leaf_sprout_texture := _load_runtime_texture(LEVEL_ONE_LEAF_SPROUT_PATH)
	leaf_sprout_decoration_a.texture = leaf_sprout_texture
	var curved_note_texture := _load_runtime_texture(LEVEL_ONE_STATUS_NOTE_PATH)
	info_note_artwork.texture = curved_note_texture
	status_note_artwork.texture = curved_note_texture
	info_back_artwork.texture = _load_runtime_texture(LEVEL_ONE_STRAIGHT_NOTE_PATH)
	pause_menu_frame_artwork.texture = _load_runtime_texture(
		LEVEL_ONE_PAUSE_MENU_FRAME_PATH
	)
	_apply_texture_button_states(
		pause_button,
		_load_runtime_texture(LAND_PAUSE_NORMAL_PATH),
		_load_runtime_texture(LAND_PAUSE_HOVER_PATH),
		_load_runtime_texture(LAND_PAUSE_FOCUS_PATH),
		_load_runtime_texture(LAND_PAUSE_PRESSED_PATH)
	)
	_apply_texture_button_states(
		restart_button,
		_load_runtime_texture(LAND_REGENERATE_NORMAL_PATH),
		_load_runtime_texture(LAND_REGENERATE_HOVER_PATH),
		_load_runtime_texture(LAND_REGENERATE_FOCUS_PATH),
		_load_runtime_texture(LAND_REGENERATE_PRESSED_PATH)
	)
	_apply_handmade_typography()
	var paper_normal := _load_texture_style(PAPER_BUTTON_PATH)
	var paper_selected := _load_texture_style(PAPER_BUTTON_SELECTED_PATH)
	var paper_pressed := _load_texture_style(PAPER_BUTTON_PRESSED_PATH)
	var green_normal := _load_texture_style(GREEN_BUTTON_PATH)
	var green_selected := _load_texture_style(GREEN_BUTTON_SELECTED_PATH)
	var green_pressed := _load_texture_style(GREEN_BUTTON_PRESSED_PATH)
	if paper_normal != null and paper_selected != null and paper_pressed != null:
		for button in [
			pause_restart_button,
			level_select_button,
			pause_settings_button,
			main_menu_button,
			exit_game_button,
		]:
			_apply_paper_button(button, paper_normal, paper_selected, paper_pressed)
	if green_normal != null and green_selected != null and green_pressed != null:
		for button in [resume_button]:
			_apply_paper_button(button, green_normal, green_selected, green_pressed)


func _apply_handmade_typography() -> void:
	var font := load(HANDMADE_FONT_PATH) as FontFile
	if font == null:
		push_error("Level interface font could not be loaded: %s" % HANDMADE_FONT_PATH)
		return
	_apply_font_to_tree(environment_panel, font)
	_apply_font_to_tree(hud_panel, font)
	_apply_font_to_tree(quick_buttons, font)
	_apply_font_to_tree(pause_overlay, font)


func _apply_font_to_tree(node: Node, font: Font) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font_to_tree(child, font)


func _load_runtime_texture(path: String) -> Texture2D:
	if _runtime_texture_cache.has(path):
		return _runtime_texture_cache[path] as Texture2D
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Level interface artwork could not be loaded: %s" % path)
		return null
	_runtime_texture_cache[path] = texture
	return texture


func _apply_land_decorative_texture(path: String) -> void:
	var texture := _load_runtime_texture(path)
	if texture == null:
		return
	left_decorative_sprout.texture = texture
	var texture_size := texture.get_size()
	var scale_factor := minf(
		LAND_DECORATIVE_MAX_SIZE.x / texture_size.x,
		LAND_DECORATIVE_MAX_SIZE.y / texture_size.y
	)
	var display_size := texture_size * scale_factor
	left_decorative_sprout.position = Vector2(
		LAND_DECORATIVE_CENTER_X - display_size.x * 0.5,
		LAND_DECORATIVE_BASELINE_Y - display_size.y
	)
	left_decorative_sprout.size = display_size
	left_decorative_sprout.pivot_offset = Vector2(
		display_size.x * 0.5,
		display_size.y * 0.91
	)


func _apply_land_stickers(state: int) -> void:
	if not is_instance_valid(land_sticker_sets):
		return
	land_sticker_sets.call(
		"show_level",
		current_level_index,
		state == MinesweeperBoard.GameState.WON
	)


func _load_runtime_texture_region(path: String, region: Rect2i) -> Texture2D:
	var texture := _load_runtime_texture(path)
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("Level interface artwork image is unavailable: %s" % path)
		return null
	var source_rect := Rect2i(Vector2i.ZERO, image.get_size())
	if not source_rect.encloses(region):
		push_error("Level interface artwork crop is outside the source image: %s" % path)
		return null
	return ImageTexture.create_from_image(image.get_region(region))


func _load_texture_style(path: String) -> StyleBoxTexture:
	var texture := _load_runtime_texture(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style


func _apply_paper_button(
	button: Button,
	normal_style: StyleBoxTexture,
	hover_style: StyleBoxTexture,
	pressed_style: StyleBoxTexture
) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.88, 0.72))
	button.add_theme_constant_override("outline_size", 1)


func _apply_texture_button_states(
	button: TextureButton,
	normal_texture: Texture2D,
	hover_texture: Texture2D,
	focus_texture: Texture2D,
	pressed_texture: Texture2D
) -> void:
	if (
		normal_texture == null
		or hover_texture == null
		or focus_texture == null
		or pressed_texture == null
	):
		return
	button.texture_normal = normal_texture
	button.texture_hover = hover_texture
	button.texture_focused = focus_texture
	button.texture_pressed = pressed_texture


func _apply_guardian_state(state: int) -> void:
	var is_failure := state == MinesweeperBoard.GameState.LOST
	left_sprout_guardian_left.texture = _load_runtime_texture(
		LEVEL_ONE_SPROUT_GUARDIAN_LEFT_PATH
	)
	left_sprout_guardian_right.texture = _load_runtime_texture(
		FAILURE_LEFT_GUARDIAN_PATH
		if is_failure
		else LEVEL_ONE_SPROUT_GUARDIAN_RIGHT_PATH
	)
	right_guardian_a.texture = _load_runtime_texture(
		FAILURE_RIGHT_WHITE_GUARDIAN_PATH
		if is_failure
		else LEVEL_ONE_SIDE_GUARDIAN_B_PATH
	)
	right_guardian_b.texture = _load_runtime_texture(
		FAILURE_RIGHT_YELLOW_GUARDIAN_PATH
		if is_failure
		else LEVEL_ONE_SIDE_GUARDIAN_A_PATH
	)


func _set_level_one_reaction(state: int) -> void:
	victory_animation_player.play(&"RESET")
	victory_animation_player.advance(0.0)
	_apply_guardian_state(state)
	seed_decoration_a.visible = false
	seed_decoration_b.visible = false
	leaf_sprout_decoration_a.visible = false
	if current_level_index >= 5:
		return
	match state:
		MinesweeperBoard.GameState.WON:
			victory_animation_player.play(&"victory")
		MinesweeperBoard.GameState.LOST:
			victory_animation_player.play(&"failure")


func _process(_delta: float) -> void:
	if _timer_running:
		_update_timer_label()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (
		_operation_mode == 1
		and _tutorial_step == TutorialStep.NUMBER_INFO
		and not _tutorial_dismissed_for_session
		and event.is_action_pressed("ui_accept")
	):
		_on_tutorial_next_requested()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	set_session_paused(not _session_paused)
	get_viewport().set_input_as_handled()


func start_level(level_index: int) -> void:
	current_level_index = clampi(
		level_index,
		0,
		GreenSweeperLevels.PLAYABLE_LEVELS.size() - 1
	)
	var uses_level_one_stage := current_level_index < GreenSweeperLevels.LAND_LEVELS.size()
	land_desk_background.visible = uses_level_one_stage
	level_one_background.visible = uses_level_one_stage
	land_unified_shadow.visible = uses_level_one_stage
	eco_showcase.visible = not uses_level_one_stage
	board_tray.visible = false
	board_shadow.visible = false
	left_decorative_sprout.visible = uses_level_one_stage
	bud_sprout_decoration_a.visible = false
	right_guardian_a.visible = uses_level_one_stage
	right_guardian_b.visible = uses_level_one_stage
	left_sprout_guardian_left.visible = uses_level_one_stage
	left_sprout_guardian_right.visible = uses_level_one_stage
	right_guardian_a_shadow.visible = uses_level_one_stage
	right_guardian_b_shadow.visible = uses_level_one_stage
	left_sprout_guardian_left_shadow.visible = uses_level_one_stage
	left_sprout_guardian_right_shadow.visible = uses_level_one_stage
	_set_level_one_reaction(MinesweeperBoard.GameState.READY)
	if uses_level_one_stage:
		_apply_land_decorative_texture(
			LAND_DECORATIVE_HEALTHY_PATHS[current_level_index]
		)
		_apply_land_stickers(MinesweeperBoard.GameState.READY)
	_tutorial_dismissed_for_session = false
	_tutorial_step = (
		TutorialStep.FIRST_REVEAL
		if current_level_index == 0 and _first_move_guide_enabled
		else TutorialStep.INACTIVE
	)
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	_tutorial_last_revealed_index = -1
	_completion_emitted = false
	set_session_paused(false)
	_reset_timer()
	var level: Dictionary = GreenSweeperLevels.PLAYABLE_LEVELS[current_level_index].duplicate(true)
	level["first_move_guide"] = bool(level.get("first_move_guide", false)) \
			and _first_move_guide_enabled
	board.set_opening_assist_mode(_take_opening_assist_mode(current_level_index))
	board.load_level(level)
	board.set_interaction_enabled(true)
	eco_showcase.call("set_environment", board.level_number)
	subtitle_label.text = "第%d关 · %s" % [
		board.level_number,
		board.level_name,
	]
	level_summary_label.text = "%d × %d %s\n污染核心 %d" % [
		board.column_count,
		board.row_count,
		"六边形棋盘" if board.topology == &"hex_pointy_odd_r" else "棋盘",
		board.core_count,
	]
	objective_label.text = "清除所有污染核心\n恢复%s生态" % board.level_name
	_refresh_instructions()
	_refresh_first_move_guide()
	visible = true
	level_started.emit(board.level_number)


func restart_level() -> void:
	_completion_emitted = false
	set_session_paused(false)
	_reset_timer()
	board.set_interaction_enabled(true)
	if board.level_number == 1 \
			and _first_move_guide_enabled \
			and not _tutorial_dismissed_for_session:
		_tutorial_step = TutorialStep.FIRST_REVEAL
	else:
		_tutorial_step = TutorialStep.INACTIVE
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	_tutorial_last_revealed_index = -1
	board.set_opening_assist_mode(_take_opening_assist_mode(current_level_index))
	board.new_game()
	if _tutorial_dismissed_for_session:
		board.clear_guide_cell()
	_refresh_instructions()
	_refresh_first_move_guide()


func _take_opening_assist_mode(level_index: int) -> int:
	if (
		level_index < ADAPTIVE_ASSIST_FIRST_LEVEL_INDEX
		or level_index >= GreenSweeperLevels.LAND_LEVELS.size()
	):
		return MinesweeperBoard.OpeningAssist.NONE
	var early_loss_streak := int(_early_loss_streaks.get(level_index, 0))
	if early_loss_streak >= EARLY_LOSS_STREAK_THRESHOLD:
		_early_loss_streaks[level_index] = 0
		return MinesweeperBoard.OpeningAssist.OPEN_REGION
	var first_click_streak := int(_first_click_mine_streaks.get(level_index, 0))
	if first_click_streak >= FIRST_CLICK_MINE_STREAK_THRESHOLD:
		_first_click_mine_streaks[level_index] = 0
		return MinesweeperBoard.OpeningAssist.SAFE_FIRST
	return MinesweeperBoard.OpeningAssist.NONE


func _record_adaptive_attempt_result(state: int) -> void:
	if (
		current_level_index < ADAPTIVE_ASSIST_FIRST_LEVEL_INDEX
		or current_level_index >= GreenSweeperLevels.LAND_LEVELS.size()
	):
		return
	if state == MinesweeperBoard.GameState.WON:
		_first_click_mine_streaks[current_level_index] = 0
		_early_loss_streaks[current_level_index] = 0
		return
	if state != MinesweeperBoard.GameState.LOST:
		return
	var lost_on_first_reveal := board.reveal_action_count == 1
	if lost_on_first_reveal:
		_first_click_mine_streaks[current_level_index] = int(
			_first_click_mine_streaks.get(current_level_index, 0)
		) + 1
		_early_loss_streaks[current_level_index] = 0
	elif board.move_count <= EARLY_LOSS_MOVE_LIMIT:
		_first_click_mine_streaks[current_level_index] = 0
		_early_loss_streaks[current_level_index] = int(
			_early_loss_streaks.get(current_level_index, 0)
		) + 1
	else:
		_first_click_mine_streaks[current_level_index] = 0
		_early_loss_streaks[current_level_index] = 0


func set_operation_mode(mode: int) -> void:
	_operation_mode = 1 if mode == 1 else 0
	board.set_operation_mode(_operation_mode)
	_refresh_instructions()
	_refresh_first_move_guide()


func get_operation_mode() -> int:
	return _operation_mode


func set_first_move_guide_enabled(enabled: bool) -> void:
	_first_move_guide_enabled = enabled


func _refresh_instructions() -> void:
	if not is_instance_valid(instructions_label) or not is_instance_valid(board):
		return
	var tutorial_active := (
		board.level_number == 1
		and not _tutorial_dismissed_for_session
		and _tutorial_step != TutorialStep.INACTIVE
		and _tutorial_step != TutorialStep.COMPLETE
	)
	if _operation_mode == 1:
		instructions_label.text = (
			"方向键/WASD 移动"
			+ "\nZ 净化 · X 标记"
			+ "\n鼠标仍可使用"
		)
	else:
		instructions_label.text = (
			("引导进行中" if tutorial_active else "首点可能污染")
			+ "\n左键净化 · 右键标记"
			+ "\n双击数字快速展开"
		)


func _refresh_first_move_guide() -> void:
	if not is_instance_valid(first_move_guide) or not is_instance_valid(board):
		return
	var tutorial_visible := (
		board.level_number == 1
		and not _tutorial_dismissed_for_session
		and board.game_state in [
			MinesweeperBoard.GameState.READY,
			MinesweeperBoard.GameState.PLAYING,
		]
		and _tutorial_step not in [TutorialStep.INACTIVE, TutorialStep.COMPLETE]
	)
	if not tutorial_visible:
		first_move_guide.hide_guide()
		return

	var target_index := -1
	var title := ""
	var action := ""
	var hint := ""
	var show_next := false
	match _tutorial_step:
		TutorialStep.FIRST_REVEAL:
			if board.game_state == MinesweeperBoard.GameState.READY:
				target_index = board.guide_cell_index
				title = "小芽带你认识棋盘"
				action = "移动到这里按 Z 翻开" if _operation_mode == 1 else "左键翻开这个安全建议格"
				hint = "白色=未净化 · 黄色=安全建议"
			else:
				target_index = _find_unrevealed_safe_index()
				title = "继续观察"
				action = "移动后按 Z 再翻一格" if _operation_mode == 1 else "再左键翻开一个白色格"
				hint = "找到数字后，清扫者会继续说明"
		TutorialStep.NUMBER_INFO:
			target_index = _tutorial_number_index
			title = "这是数字格"
			action = "绿色=安全，数字=周围污染数"
			hint = "按 Enter 或点下一步继续" if _operation_mode == 1 else "例如 1 表示周围有 1 个污染核心"
			show_next = true
		TutorialStep.MARK_CORE:
			target_index = _tutorial_target_index
			title = "检测种子"
			var removing_wrong_flag := (
				_is_valid_tutorial_index(target_index)
				and board.flagged[target_index]
				and not board.mines[target_index]
			)
			if removing_wrong_flag:
				action = "按 X 取消这个错误标记" if _operation_mode == 1 else "右键取消这个错误标记"
				hint = "种子放错会阻止数字快速展开"
			else:
				action = "按 X 放下检测种子" if _operation_mode == 1 else "右键放下检测种子"
				hint = "把数字周围的污染核心全部标记"
		TutorialStep.CHORD:
			target_index = _tutorial_number_index
			title = "快速展开"
			action = "选中数字后按 Z" if _operation_mode == 1 else "双击这个数字"
			hint = "标记正确后，会展开周围安全格"

	if not _is_valid_tutorial_index(target_index):
		first_move_guide.hide_guide()
		return
	first_move_guide.show_for_cell(
		board.cell_nodes[target_index],
		target_index,
		_operation_mode == 1,
		title,
		action,
		hint,
		show_next
	)


func _on_reveal_completed(cell_index: int, newly_revealed_count: int) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if board.game_state in [MinesweeperBoard.GameState.WON, MinesweeperBoard.GameState.LOST]:
		return
	if newly_revealed_count > 0:
		_tutorial_last_revealed_index = cell_index
	if _tutorial_step == TutorialStep.FIRST_REVEAL:
		var candidate := _find_tutorial_frontier()
		if candidate >= 0:
			_tutorial_number_index = candidate
			_tutorial_step = TutorialStep.NUMBER_INFO
	elif _tutorial_step == TutorialStep.NUMBER_INFO:
		_ensure_number_target()
	elif _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
	_refresh_first_move_guide()


func _on_flag_completed(_cell_index: int, _is_flagged: bool) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _on_chord_completed(_cell_index: int, newly_revealed_count: int) -> void:
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step == TutorialStep.CHORD and newly_revealed_count > 0:
		_complete_tutorial()
	elif _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _on_tutorial_next_requested() -> void:
	if _tutorial_dismissed_for_session:
		return
	match _tutorial_step:
		TutorialStep.FIRST_REVEAL:
			if board.guide_cell_index >= 0:
				board.reveal_cell(board.guide_cell_index)
		TutorialStep.NUMBER_INFO:
			_revalidate_tutorial_frontier()
			_refresh_first_move_guide()
		TutorialStep.MARK_CORE:
			if _tutorial_target_index >= 0:
				board.toggle_flag(_tutorial_target_index)
		TutorialStep.CHORD:
			if _tutorial_number_index >= 0:
				board.chord_cell(_tutorial_number_index)


func _on_tutorial_exit_requested() -> void:
	if board.level_number != 1:
		return
	_tutorial_dismissed_for_session = true
	_tutorial_step = TutorialStep.INACTIVE
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	board.clear_guide_cell()
	first_move_guide.hide_guide()
	_refresh_instructions()
	if board.game_state in [MinesweeperBoard.GameState.READY, MinesweeperBoard.GameState.PLAYING]:
		status_label.text = "自由净化"


func _ensure_number_target() -> void:
	if _is_useful_number_frontier(_tutorial_number_index):
		return
	_tutorial_number_index = _find_tutorial_frontier()
	if _tutorial_number_index < 0:
		_complete_tutorial()


func _revalidate_tutorial_frontier() -> void:
	_ensure_number_target()
	if _tutorial_step == TutorialStep.COMPLETE:
		return
	var wrong_neighbor := _find_wrong_flag_neighbor(_tutorial_number_index)
	if wrong_neighbor >= 0:
		_tutorial_step = TutorialStep.MARK_CORE
		_tutorial_target_index = wrong_neighbor
		return
	var required_core := _find_unflagged_core_neighbor(_tutorial_number_index)
	if required_core >= 0:
		if board.used_flags >= board.core_count:
			var wrong_flag := _find_wrong_flag()
			if wrong_flag >= 0:
				_tutorial_step = TutorialStep.MARK_CORE
				_tutorial_target_index = wrong_flag
				return
		_tutorial_step = TutorialStep.MARK_CORE
		_tutorial_target_index = required_core
		return
	_tutorial_step = TutorialStep.CHORD
	_tutorial_target_index = _tutorial_number_index


func _find_tutorial_frontier() -> int:
	var best_index := -1
	var best_number_priority := 2
	var best_remaining_cores := 999
	for cell_index in board.cell_count:
		if not _is_useful_number_frontier(cell_index):
			continue
		var number_priority := 0 if board.adjacent_counts[cell_index] == 1 else 1
		var remaining_cores := 0
		for neighbor in board.get_neighbor_indices(cell_index):
			if board.mines[neighbor] and not board.flagged[neighbor]:
				remaining_cores += 1
		if (
			number_priority < best_number_priority
			or (
				number_priority == best_number_priority
				and remaining_cores < best_remaining_cores
			)
		):
			best_index = cell_index
			best_number_priority = number_priority
			best_remaining_cores = remaining_cores
	return best_index


func _is_useful_number_frontier(cell_index: int) -> bool:
	if not _is_valid_tutorial_index(cell_index):
		return false
	if not board.revealed[cell_index] or board.adjacent_counts[cell_index] <= 0:
		return false
	var has_core := false
	var has_hidden_safe := false
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.mines[neighbor]:
			has_core = true
		elif not board.revealed[neighbor]:
			has_hidden_safe = true
	return has_core and has_hidden_safe


func _find_unflagged_core_neighbor(cell_index: int) -> int:
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.mines[neighbor] and not board.flagged[neighbor]:
			return neighbor
	return -1


func _find_wrong_flag_neighbor(cell_index: int) -> int:
	for neighbor in board.get_neighbor_indices(cell_index):
		if board.flagged[neighbor] and not board.mines[neighbor]:
			return neighbor
	return -1


func _find_wrong_flag() -> int:
	for cell_index in board.cell_count:
		if board.flagged[cell_index] and not board.mines[cell_index]:
			return cell_index
	return -1


func _find_unrevealed_safe_index() -> int:
	for cell_index in board.cell_count:
		if not board.mines[cell_index] and not board.revealed[cell_index] and not board.flagged[cell_index]:
			return cell_index
	return _tutorial_last_revealed_index


func _is_valid_tutorial_index(cell_index: int) -> bool:
	return cell_index >= 0 and cell_index < board.cell_nodes.size()


func _complete_tutorial() -> void:
	_tutorial_step = TutorialStep.COMPLETE
	_tutorial_dismissed_for_session = true
	_tutorial_number_index = -1
	_tutorial_target_index = -1
	board.clear_guide_cell()
	first_move_guide.hide_guide()
	_refresh_instructions()
	if board.game_state == MinesweeperBoard.GameState.PLAYING:
		status_label.text = "引导完成"


func set_session_paused(paused: bool) -> void:
	if _session_paused == paused:
		return
	_session_paused = paused
	if paused:
		_pause_timer()
	else:
		_resume_timer_if_playing()
	board.set_interaction_enabled(not paused)
	pause_overlay.visible = paused
	if paused:
		resume_button.grab_focus()
	pause_changed.emit(paused)


func is_session_paused() -> bool:
	return _session_paused


func get_elapsed_ms() -> int:
	if _timer_running:
		return _elapsed_before_segment_ms + int(Time.get_ticks_msec()) - _segment_started_ms
	return _elapsed_before_segment_ms


func _load_level(level_index: int) -> void:
	start_level(level_index)


func _on_state_changed(state: int) -> void:
	_advance_available = false
	_record_adaptive_attempt_result(state)
	_set_level_one_reaction(state)
	_apply_land_stickers(state)
	if current_level_index < LAND_DECORATIVE_HEALTHY_PATHS.size():
		var decorative_sprout_path: String = (
			LAND_DECORATIVE_FAILED_PATHS[current_level_index]
			if state == MinesweeperBoard.GameState.LOST
			else LAND_DECORATIVE_HEALTHY_PATHS[current_level_index]
		)
		_apply_land_decorative_texture(decorative_sprout_path)
	match state:
		MinesweeperBoard.GameState.READY:
			eco_showcase.call("set_reaction", 0)
			_reset_timer()
			var tutorial_ready := (
				board.level_number == 1
				and not _tutorial_dismissed_for_session
				and _tutorial_step == TutorialStep.FIRST_REVEAL
			)
			status_label.text = "引导中" if tutorial_ready else "准备中"
			restart_button_label.text = "重新\n生成"
			pause_button_label.text = "暂停\nEsc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.PLAYING:
			eco_showcase.call("set_reaction", 0)
			_start_timer()
			status_label.text = "净化中"
			restart_button_label.text = "重新\n开始"
			pause_button_label.text = "暂停\nEsc"
			pause_button.disabled = false
		MinesweeperBoard.GameState.WON:
			eco_showcase.call("set_reaction", 1)
			_pause_timer()
			pause_button_label.text = "菜单\nEsc"
			pause_button.disabled = false
			if _has_next_level_in_chapter():
				status_label.text = "净化完成"
				restart_button_label.text = "下一关"
				_advance_available = true
			else:
				status_label.text = "%s净化完成！" % board.level_name
				restart_button_label.text = "再来一局"
			if not _completion_emitted:
				_completion_emitted = true
				level_completed.emit(board.level_number, get_elapsed_ms())
		MinesweeperBoard.GameState.LOST:
			eco_showcase.call("set_reaction", 2)
			_pause_timer()
			pause_button_label.text = "菜单\nEsc"
			pause_button.disabled = false
			status_label.text = "污染触发"
			restart_button_label.text = "重新\n开始"
	_refresh_first_move_guide()


func _has_next_level_in_chapter() -> bool:
	var next_index := current_level_index + 1
	if next_index >= GreenSweeperLevels.PLAYABLE_LEVELS.size():
		return false
	var land_level_count := GreenSweeperLevels.LAND_LEVELS.size()
	return current_level_index < land_level_count - 1 \
			or current_level_index >= land_level_count


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "%d/%d" % [used_flags, max_flags]


func _on_primary_button_pressed() -> void:
	if _advance_available:
		start_level(current_level_index + 1)
	else:
		restart_level()


func _on_pause_button_pressed() -> void:
	set_session_paused(true)


func _on_resume_button_pressed() -> void:
	set_session_paused(false)
	pause_button.grab_focus()


func _on_pause_restart_button_pressed() -> void:
	restart_level()


func _on_level_select_button_pressed() -> void:
	_pause_timer()
	board.set_interaction_enabled(false)
	level_select_requested.emit()


func _on_pause_settings_button_pressed() -> void:
	settings_requested.emit()


func _on_main_menu_button_pressed() -> void:
	_pause_timer()
	board.set_interaction_enabled(false)
	main_menu_requested.emit()


func _on_exit_game_button_pressed() -> void:
	exit_game_requested.emit()


func _start_timer() -> void:
	if _timer_running or _session_paused:
		return
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true


func _pause_timer() -> void:
	if not _timer_running:
		_update_timer_label()
		return
	_elapsed_before_segment_ms += int(Time.get_ticks_msec()) - _segment_started_ms
	_timer_running = false
	_update_timer_label()


func _resume_timer_if_playing() -> void:
	if board.game_state == MinesweeperBoard.GameState.PLAYING:
		_start_timer()


func _reset_timer() -> void:
	_elapsed_before_segment_ms = 0
	_segment_started_ms = 0
	_timer_running = false
	_update_timer_label()


func _update_timer_label() -> void:
	var elapsed_ms := get_elapsed_ms()
	var minutes := int(elapsed_ms / 60000)
	var seconds := int(elapsed_ms / 1000) % 60
	var tenths := int(elapsed_ms / 100) % 10
	timer_label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]


func _requested_level_index() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			var raw_value := argument.trim_prefix("--level=")
			if not raw_value.is_valid_int():
				return 0
			var requested_level := int(raw_value)
			var level_index := GreenSweeperLevels.level_index_from_number(requested_level)
			return level_index if level_index >= 0 else 0
	return 0
