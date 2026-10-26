@tool
extends Control

signal level_started(level_number: int)
signal level_completed(level_number: int, elapsed_ms: int)
signal level_select_requested
signal chapter_advance_requested
signal main_menu_requested
signal settings_requested
signal help_requested
signal badge_book_requested(level_number: int)
signal exit_game_requested
signal pause_changed(is_paused: bool)
signal scan_energy_changed(energy: int)
signal mechanic_guide_completed(guide_id: StringName)

const ART := preload("res://scripts/art_catalog.gd")
const BADGE_CELEBRATION_SCENE := preload("res://scenes/badge_celebration.tscn")

const LAND_DESK_BACKGROUND_PATH := ART.LAND_V2_BACKGROUND
const OCEAN_DESK_BACKGROUND_PATH := ART.OCEAN_V2_BACKGROUND
const OCEAN_STAGE_BODY_PATH := ART.OCEAN_V2_STAGE_BODY
const LEVEL_ONE_BACKGROUND_PATH := ART.LAND_V2_STAGE_BODY
const LAND_UNIFIED_SHADOW_PATH := ART.LAND_UNIFIED_STAGE_SHADOW
const LAND_PAUSE_NORMAL_PATH := ART.LAND_V2_PAUSE_BUTTON
const LAND_PAUSE_HOVER_PATH := ART.LAND_V2_PAUSE_BUTTON
const LAND_PAUSE_FOCUS_PATH := ART.LAND_V2_PAUSE_BUTTON
const LAND_PAUSE_PRESSED_PATH := ART.LAND_V2_PAUSE_BUTTON
const LAND_REGENERATE_NORMAL_PATH := ART.LAND_V2_RESTART_BUTTON
const LAND_REGENERATE_HOVER_PATH := ART.LAND_V2_RESTART_BUTTON
const LAND_REGENERATE_FOCUS_PATH := ART.LAND_V2_RESTART_BUTTON
const LAND_REGENERATE_PRESSED_PATH := ART.LAND_V2_RESTART_BUTTON
const LAND_SETTINGS_NORMAL_PATH := ART.LAND_V2_SETTINGS_BUTTON
const LAND_SETTINGS_HOVER_PATH := ART.LAND_V2_SETTINGS_BUTTON
const LAND_SETTINGS_FOCUS_PATH := ART.LAND_V2_SETTINGS_BUTTON
const LAND_SETTINGS_PRESSED_PATH := ART.LAND_V2_SETTINGS_BUTTON
const OCEAN_PAUSE_NORMAL_PATH := ART.OCEAN_V2_RESTART_BUTTON
const OCEAN_PAUSE_HOVER_PATH := ART.OCEAN_V2_RESTART_BUTTON
const OCEAN_PAUSE_FOCUS_PATH := ART.OCEAN_V2_RESTART_BUTTON
const OCEAN_PAUSE_PRESSED_PATH := ART.OCEAN_V2_RESTART_BUTTON
const OCEAN_REGENERATE_NORMAL_PATH := ART.OCEAN_V2_SETTINGS_BUTTON
const OCEAN_REGENERATE_HOVER_PATH := ART.OCEAN_V2_SETTINGS_BUTTON
const OCEAN_REGENERATE_FOCUS_PATH := ART.OCEAN_V2_SETTINGS_BUTTON
const OCEAN_REGENERATE_PRESSED_PATH := ART.OCEAN_V2_SETTINGS_BUTTON
const BOSS_ANCHOR_ACTIVE_PATH := ART.LEVEL_04_POLLUTION_NODE_ACTIVE
const BOSS_ANCHOR_CLEANSED_PATH := ART.LEVEL_04_POLLUTION_NODE_CLEANSED
const LAND_TOP_ATTACHMENT_PATH := ART.LAND_V2_TOP_ATTACHMENT
const LAND_COUNTER_FRAME_PATH := ART.LAND_V2_COUNTER_FRAME
const LAND_ROBOT_EMBLEM_PATH := ART.LAND_V2_ROBOT_EMBLEM
const LAND_COUNTER_ICON_PATH := ART.LAND_V2_COUNTER_ICON
const LAND_TIMER_ICON_PATH := ART.LAND_V2_TIMER_ICON
const OCEAN_TOP_ATTACHMENT_PATH := ART.OCEAN_V2_TOP_ATTACHMENT
const OCEAN_COUNTER_FRAME_PATH := ART.OCEAN_V2_COUNTER_FRAME
const OCEAN_ROBOT_EMBLEM_PATH := ART.OCEAN_V2_ROBOT_EMBLEM
const OCEAN_COUNTER_ICON_PATH := ART.OCEAN_V2_COUNTER_ICON
const OCEAN_TIMER_ICON_PATH := ART.OCEAN_V2_TIMER_ICON
const LAND_DECORATIVE_HEALTHY_PATHS := ART.LAND_V2_VICTORY_ECOLOGY_PATHS
const LAND_DECORATIVE_FAILED_PATHS := ART.LAND_V2_ECOLOGY_POLLUTED_PATHS
const LAND_INTERFACE_SCALE := 1.0
const LAND_INTERFACE_DESIGN_WIDTH := 1280.0
const LAND_INTERFACE_TOP_OFFSET := 0.0
const OCEAN_INTERFACE_DESIGN_SIZE := Vector2(1280.0, 720.0)
const LAND_QUICK_BUTTON_LABEL_COLOR := Color("71371d")
const OCEAN_QUICK_BUTTON_LABEL_COLOR := Color("123f5e")
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
const FIRST_CLICK_MINE_STREAK_THRESHOLD := 2
const EARLY_LOSS_STREAK_THRESHOLD := 3
const EARLY_LOSS_MOVE_LIMIT := 5
const SCAN_CAPACITY := 12
const LEVEL_MECHANIC_GUIDES := {
	3: {
		"id": &"land_obstacles",
		"pages": [
			{"title": "TXT_0253", "text": "TXT_0254", "hint": "TXT_0255"},
			{"title": "TXT_0256", "text": "TXT_0448", "hint": "TXT_0257"},
		],
	},
	5: {
		"id": &"pollution_nodes",
		"pages": [
			{"title": "TXT_0258", "text": "TXT_0259", "hint": "TXT_0404"},
			{"title": "TXT_0260", "text": "TXT_0261", "hint": "TXT_0262"},
			{"title": "TXT_0484", "text": "TXT_0485", "hint": "TXT_0486"},
			{"title": "TXT_0487", "text": "TXT_0488", "hint": "TXT_0489"},
			{"title": "TXT_0490", "text": "TXT_0491", "hint": "TXT_0492"},
		],
	},
	7: {
		"id": &"ancient_tree_roots",
		"pages": [
			{"title": "TXT_0263", "text": "TXT_0264", "hint": "TXT_0265"},
			{"title": "TXT_0266", "text": "TXT_0267", "hint": "TXT_0268"},
			{"title": "TXT_0484", "text": "TXT_0485", "hint": "TXT_0486"},
			{"title": "TXT_0487", "text": "TXT_0488", "hint": "TXT_0489"},
			{"title": "TXT_0490", "text": "TXT_0491", "hint": "TXT_0492"},
		],
	},
	8: {
		"id": &"hex_ocean_board",
		"pages": [
			{"title": "TXT_0274", "text": "TXT_0275", "hint": "TXT_0388"},
			{"title": "TXT_0277", "text": "TXT_0413", "hint": "TXT_0276"},
		],
	},
	9: {
		"id": &"coral_reefs",
		"pages": [
			{"title": "TXT_0279", "text": "TXT_0280", "hint": "TXT_0284"},
			{"title": "TXT_0282", "text": "TXT_0283", "hint": "TXT_0281"},
		],
	},
	11: {
		"id": &"drifting_mines",
		"pages": [
			{"title": "TXT_0285", "text": "TXT_0286", "hint": "TXT_0278"},
			{"title": "TXT_0290", "text": "TXT_0291", "hint": "TXT_0292"},
			{"title": "TXT_0287", "text": "TXT_0288", "hint": "TXT_0289"},
		],
	},
	13: {
		"id": &"tidal_zones",
		"pages": [
			{"title": "TXT_0293", "text": "TXT_0294", "hint": "TXT_0295"},
			{"title": "TXT_0296", "text": "TXT_0297", "hint": "TXT_0298"},
		],
	},
}
const SCAN_GUIDE := {
	"id": &"eco_scan",
	"pages": [
		{"title": "TXT_0269", "text": "TXT_0270", "hint": "TXT_0273"},
		{"title": "TXT_0271", "text": "TXT_0272", "hint": "TXT_0398"},
	],
}


enum ScanPhase {
	INACTIVE,
	LOCKED_FIRST_REVEAL,
	CHARGING,
	READY,
	TARGETING,
	RESOLVING,
	USED,
	FINISHED,
}


@onready var land_board: MinesweeperBoard = %Board
@onready var ocean_board: MinesweeperBoard = %OceanBoard
@onready var board: MinesweeperBoard = land_board
@onready var land_board_center: CenterContainer = %BoardCenter
@onready var land_layout: Control = %LandLayout
@onready var ocean_layout: Control = %OceanLayout
@onready var ocean_desk_background: TextureRect = %OceanDeskBackground
@onready var ocean_stage_art: TextureRect = %OceanStageArt
@onready var land_desk_background: TextureRect = %LandDeskBackground
@onready var level_one_background: TextureRect = %Stage
@onready var land_unified_shadow: TextureRect = %LandUnifiedShadow
@onready var land_top_hud: Control = %TopHud
@onready var ocean_top_hud: Control = %OceanTopHud
@onready var land_top_attachment: TextureRect = %LandTopAttachment
@onready var land_mine_counter_frame: TextureRect = %LandMineCounterFrame
@onready var land_timer_counter_frame: TextureRect = %LandTimerCounterFrame
@onready var land_robot_emblem: TextureRect = %LandRobotEmblem
@onready var land_mine_counter_icon: TextureRect = %LandMineCounterIcon
@onready var land_timer_counter_icon: TextureRect = %LandTimerCounterIcon
@onready var land_mine_counter_label: Label = %LandMineCounterLabel
@onready var land_timer_counter_label: Label = %LandTimerCounterLabel
@onready var ocean_mine_counter_label: Label = %OceanMineCounterLabel
@onready var ocean_timer_counter_label: Label = %OceanTimerCounterLabel
@onready var mine_counter_label: Label = land_mine_counter_label
@onready var top_timer_counter_label: Label = land_timer_counter_label
@onready var land_robot_layout: TextureRect = %LandRobot
@onready var land_ecology_layout: TextureRect = %LandEcology
@onready var land_monster_layout: TextureRect = %LandMonster
@onready var ocean_robot_layout: TextureRect = %OceanRobot
@onready var ocean_ecology_layout: TextureRect = %OceanEcology
@onready var ocean_monster_layout: TextureRect = %OceanMonster
@onready var land_tabletop_actors: LandTabletopActors = %LandAnimationController
@onready var land_environment_panel: Control = %LeftInfo
@onready var ocean_environment_panel: Control = %OceanLeftInfo
@onready var environment_panel: Control = land_environment_panel
@onready var land_hud_panel: Control = %RightInfo
@onready var ocean_hud_panel: Control = %OceanRightInfo
@onready var hud_panel: Control = land_hud_panel
@onready var land_time_title: Label = _optional_label("%TimeTitle")
@onready var time_title: Label = land_time_title
@onready var land_time_separator: HSeparator = _optional_separator("%TimeSeparator")
@onready var time_separator: HSeparator = land_time_separator
@onready var land_flags_row: HBoxContainer = %FlagsRow
@onready var ocean_flags_row: HBoxContainer = %OceanFlagsRow
@onready var flags_row: HBoxContainer = land_flags_row
@onready var land_subtitle_label: Label = %SubtitleLabel
@onready var ocean_subtitle_label: Label = %OceanSubtitleLabel
@onready var subtitle_label: Label = land_subtitle_label
@onready var land_level_summary_label: Label = %LevelSummaryLabel
@onready var ocean_level_summary_label: Label = %OceanLevelSummaryLabel
@onready var level_summary_label: Label = land_level_summary_label
@onready var land_objective_label: Label = %ObjectiveLabel
@onready var ocean_objective_label: Label = %OceanObjectiveLabel
@onready var objective_label: Label = land_objective_label
@onready var boss_stage: Control = %BossStage
@onready var boss_portrait: TextureRect = %BossPortrait
@onready var boss_anchor_icons: Array[TextureRect] = [
	%BossAnchorA,
	%BossAnchorB,
	%BossAnchorC,
]
@onready var boss_root_lines: Array[Line2D] = [
	%BossRootLineA,
	%BossRootLineB,
	%BossRootLineC,
]
@onready var land_status_label: Label = %StatusLabel
@onready var ocean_status_label: Label = %OceanStatusLabel
@onready var status_label: Label = land_status_label
@onready var land_flags_label: Label = _optional_label("%FlagsLabel")
@onready var flags_label: Label = land_flags_label
@onready var land_timer_label: Label = _optional_label("%TimerLabel")
@onready var timer_label: Label = land_timer_label
@onready var land_instructions_label: Label = %InstructionsLabel
@onready var ocean_instructions_label: Label = %OceanInstructionsLabel
@onready var instructions_label: Label = land_instructions_label
@onready var land_scan_fallback_row: HBoxContainer = %ScanFallbackRow
@onready var ocean_scan_fallback_row: HBoxContainer = %OceanScanFallbackRow
@onready var scan_fallback_row: HBoxContainer = land_scan_fallback_row
@onready var land_scan_fallback_status: Label = %ScanFallbackStatus
@onready var ocean_scan_fallback_status: Label = %OceanScanFallbackStatus
@onready var scan_fallback_status: Label = land_scan_fallback_status
@onready var land_scan_fallback_button: Button = %ScanFallbackButton
@onready var ocean_scan_fallback_button: Button = %OceanScanFallbackButton
@onready var scan_fallback_button: Button = land_scan_fallback_button
@onready var land_scan_dots: Array[Control] = [
	%OceanScanDotA,
	%OceanScanDotB,
	%OceanScanDotC,
]
@onready var ocean_v2_scan_dots: Array[Control] = [
	%OceanV2ScanDotA,
	%OceanV2ScanDotB,
	%OceanV2ScanDotC,
]
@onready var ocean_scan_dots: Array[Control] = land_scan_dots
@onready var land_quick_buttons: Control = %QuickActions
@onready var ocean_quick_buttons: Control = %OceanQuickActions
@onready var quick_buttons: Control = land_quick_buttons
@onready var land_pause_button: TextureButton = %PauseButton
@onready var ocean_pause_button: TextureButton = %OceanPauseButton
@onready var pause_button: TextureButton = land_pause_button
@onready var land_restart_button: TextureButton = %RestartButton
@onready var ocean_restart_button: TextureButton = %OceanRestartButton
@onready var restart_button: TextureButton = land_restart_button
@onready var land_pause_button_label: Label = %PauseButtonLabel
@onready var ocean_pause_button_label: Label = %OceanPauseButtonLabel
@onready var pause_button_label: Label = land_pause_button_label
@onready var land_restart_button_label: Label = %RestartButtonLabel
@onready var ocean_restart_button_label: Label = %OceanRestartButtonLabel
@onready var restart_button_label: Label = land_restart_button_label
@onready var first_move_guide = %FirstMoveGuide
@onready var pause_overlay: Control = %PauseOverlay
@onready var pause_menu_frame_artwork: NinePatchRect = %PauseMenuFrameArtwork
@onready var resume_button: Button = %ResumeButton
@onready var pause_restart_button: Button = %PauseRestartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var pause_settings_button: Button = %PauseSettingsButton
@onready var pause_help_button: Button = %PauseHelpButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var exit_game_button: Button = %ExitGameButton

var current_level_index := 0
var _first_click_mine_streaks: Dictionary = {}
var _early_loss_streaks: Dictionary = {}
var _pending_opening_assist_mode: int = MinesweeperBoard.OpeningAssist.NONE
var _advance_available := false
var _chapter_advance_available := false
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
var _scan_phase: int = ScanPhase.INACTIVE
var _scan_energy := 0
var _scan_threshold := SCAN_CAPACITY
var _ordinary_reveal_seen := false
var _scan_target_index := -1
var _scan_target_global_position := Vector2.ZERO
var _seen_mechanic_guides: Dictionary = {}
var _queued_mechanic_guides: Array[StringName] = []
var _active_mechanic_guide_id := &""
var _land_board_center_offsets := Vector4.ZERO
var _land_board_center_scale := Vector2.ONE
var _land_quick_actions_position := Vector2.ZERO
var _badge_celebration: BadgeCelebration


func _optional_label(path: NodePath) -> Label:
	var existing := get_node_or_null(path) as Label
	return existing if existing != null else Label.new()


func _optional_separator(path: NodePath) -> HSeparator:
	var existing := get_node_or_null(path) as HSeparator
	return existing if existing != null else HSeparator.new()


func _ready() -> void:
	_capture_land_editor_layout()
	if Engine.is_editor_hint():
		land_tabletop_actors.visible = false
		pause_overlay.visible = editor_preview_pause_menu
		return
	_badge_celebration = BADGE_CELEBRATION_SCENE.instantiate() as BadgeCelebration
	add_child(_badge_celebration)
	_badge_celebration.book_requested.connect(
		func(level_number: int) -> void:
			badge_book_requested.emit(level_number)
	)
	for layout_preview in [
		land_robot_layout,
		land_ecology_layout,
		land_monster_layout,
		ocean_robot_layout,
		ocean_ecology_layout,
		ocean_monster_layout,
	]:
		layout_preview.visible = false
	_apply_handmade_interface()
	resized.connect(_on_main_resized)
	call_deferred("_apply_land_interface_transform")
	for chapter_board in [land_board, ocean_board]:
		_connect_board_signals(chapter_board)
	land_tabletop_actors.scan_activation_requested.connect(_request_scan_mode)
	land_scan_fallback_button.pressed.connect(_request_scan_mode)
	ocean_scan_fallback_button.pressed.connect(_request_scan_mode)
	first_move_guide.exit_requested.connect(_on_tutorial_exit_requested)
	first_move_guide.next_requested.connect(_on_tutorial_next_requested)
	first_move_guide.dialogue_completed.connect(_on_mechanic_dialogue_completed)
	land_pause_button.pressed.connect(_on_left_quick_button_pressed)
	land_restart_button.pressed.connect(_on_right_quick_button_pressed)
	ocean_pause_button.pressed.connect(_on_left_quick_button_pressed)
	ocean_restart_button.pressed.connect(_on_right_quick_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)
	pause_help_button.pressed.connect(func() -> void: help_requested.emit())
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_game_button_pressed)
	if auto_start:
		start_level(_requested_level_index())
	else:
		visible = false
	set_process(true)


func _connect_board_signals(target_board: MinesweeperBoard) -> void:
	target_board.state_changed.connect(_on_state_changed)
	target_board.board_interacted.connect(_on_board_interacted)
	target_board.flags_changed.connect(_on_flags_changed)
	target_board.reveal_completed.connect(_on_reveal_completed)
	target_board.flag_completed.connect(_on_flag_completed)
	target_board.chord_completed.connect(_on_chord_completed)
	target_board.scan_target_requested.connect(_on_scan_target_requested)
	target_board.scan_cancel_requested.connect(_cancel_scan_targeting)
	target_board.scan_completed.connect(_on_scan_completed)
	target_board.pollution_nodes_changed.connect(_on_pollution_nodes_changed)
	target_board.tidal_zone_changed.connect(_on_tidal_zone_changed)
	target_board.current_path_feedback.connect(_on_current_path_feedback)
	target_board.mobile_current_state_changed.connect(_on_mobile_current_state_changed)
	target_board.drifting_mine_state_changed.connect(_on_drifting_mine_state_changed)


func _apply_handmade_interface() -> void:
	land_desk_background.texture = _load_runtime_texture(LAND_DESK_BACKGROUND_PATH)
	ocean_desk_background.texture = _load_runtime_texture(OCEAN_DESK_BACKGROUND_PATH)
	ocean_stage_art.texture = _load_runtime_texture(OCEAN_STAGE_BODY_PATH)
	level_one_background.texture = _load_runtime_texture(LEVEL_ONE_BACKGROUND_PATH)
	land_unified_shadow.texture = _load_runtime_texture(LAND_UNIFIED_SHADOW_PATH)
	land_unified_shadow.visible = false
	land_top_attachment.texture = _load_runtime_texture(LAND_TOP_ATTACHMENT_PATH)
	land_mine_counter_frame.texture = _load_runtime_texture(LAND_COUNTER_FRAME_PATH)
	land_timer_counter_frame.texture = _load_runtime_texture(LAND_COUNTER_FRAME_PATH)
	land_robot_emblem.texture = _load_runtime_texture(LAND_ROBOT_EMBLEM_PATH)
	land_mine_counter_icon.texture = _load_runtime_texture(LAND_COUNTER_ICON_PATH)
	land_timer_counter_icon.texture = _load_runtime_texture(LAND_TIMER_ICON_PATH)
	_apply_land_decorative_texture(LAND_DECORATIVE_HEALTHY_PATHS[0])
	pause_menu_frame_artwork.visible = false
	var pause_panel := pause_menu_frame_artwork.get_parent() as PanelContainer
	var pause_panel_style := StyleBoxFlat.new()
	pause_panel_style.bg_color = Color("f3ead8")
	pause_panel_style.border_color = Color(0.45, 0.40, 0.33, 0.48)
	pause_panel_style.set_border_width_all(2)
	pause_panel_style.set_corner_radius_all(28)
	pause_panel_style.anti_aliasing = true
	pause_panel.add_theme_stylebox_override("panel", pause_panel_style)
	_apply_texture_button_states(
		pause_button,
		_load_runtime_texture(LAND_REGENERATE_NORMAL_PATH),
		_load_runtime_texture(LAND_REGENERATE_HOVER_PATH),
		_load_runtime_texture(LAND_REGENERATE_FOCUS_PATH),
		_load_runtime_texture(LAND_REGENERATE_PRESSED_PATH)
	)
	_apply_texture_button_states(
		restart_button,
		_load_runtime_texture(LAND_SETTINGS_NORMAL_PATH),
		_load_runtime_texture(LAND_SETTINGS_HOVER_PATH),
		_load_runtime_texture(LAND_SETTINGS_FOCUS_PATH),
		_load_runtime_texture(LAND_SETTINGS_PRESSED_PATH)
	)
	_apply_handmade_typography()
	var paper_normal := _load_texture_style(PAPER_BUTTON_PATH)
	var paper_selected := _load_texture_style(PAPER_BUTTON_SELECTED_PATH)
	var paper_pressed := _load_texture_style(PAPER_BUTTON_PRESSED_PATH)
	if paper_normal != null and paper_selected != null and paper_pressed != null:
		paper_normal.modulate_color = Color("fffaf0")
		paper_selected.modulate_color = Color("ffe59a")
		paper_pressed.modulate_color = Color("e7c96f")
		for button in [
			resume_button,
			pause_restart_button,
			level_select_button,
			pause_settings_button,
			pause_help_button,
			main_menu_button,
			exit_game_button,
		]:
			_apply_paper_button(button, paper_normal, paper_selected, paper_pressed)


func _capture_land_editor_layout() -> void:
	_land_board_center_offsets = Vector4(
		land_board_center.offset_left,
		land_board_center.offset_top,
		land_board_center.offset_right,
		land_board_center.offset_bottom
	)
	_land_board_center_scale = land_board_center.scale
	_land_quick_actions_position = land_quick_buttons.position


func _apply_land_actor_layout() -> void:
	land_tabletop_actors.configure_land_layout(
		Rect2(land_robot_layout.position, land_robot_layout.size),
		Rect2(land_ecology_layout.position, land_ecology_layout.size),
		Rect2(land_monster_layout.position, land_monster_layout.size)
	)


func _apply_ocean_actor_layout() -> void:
	land_tabletop_actors.configure_ocean_layout(
		Rect2(ocean_robot_layout.position, ocean_robot_layout.size),
		Rect2(ocean_ecology_layout.position, ocean_ecology_layout.size),
		Rect2(ocean_monster_layout.position, ocean_monster_layout.size)
	)


func _select_chapter_interface(uses_land_stage: bool) -> void:
	board = land_board if uses_land_stage else ocean_board
	environment_panel = land_environment_panel if uses_land_stage else ocean_environment_panel
	hud_panel = land_hud_panel if uses_land_stage else ocean_hud_panel
	time_title = land_time_title
	time_separator = land_time_separator
	flags_row = land_flags_row if uses_land_stage else ocean_flags_row
	subtitle_label = land_subtitle_label if uses_land_stage else ocean_subtitle_label
	level_summary_label = land_level_summary_label if uses_land_stage else ocean_level_summary_label
	objective_label = land_objective_label if uses_land_stage else ocean_objective_label
	status_label = land_status_label if uses_land_stage else ocean_status_label
	flags_label = land_flags_label
	timer_label = land_timer_label
	instructions_label = land_instructions_label if uses_land_stage else ocean_instructions_label
	scan_fallback_row = land_scan_fallback_row if uses_land_stage else ocean_scan_fallback_row
	scan_fallback_status = land_scan_fallback_status if uses_land_stage else ocean_scan_fallback_status
	scan_fallback_button = land_scan_fallback_button if uses_land_stage else ocean_scan_fallback_button
	ocean_scan_dots = land_scan_dots if uses_land_stage else ocean_v2_scan_dots
	quick_buttons = land_quick_buttons if uses_land_stage else ocean_quick_buttons
	pause_button = land_pause_button if uses_land_stage else ocean_pause_button
	restart_button = land_restart_button if uses_land_stage else ocean_restart_button
	pause_button_label = land_pause_button_label if uses_land_stage else ocean_pause_button_label
	restart_button_label = land_restart_button_label if uses_land_stage else ocean_restart_button_label
	mine_counter_label = land_mine_counter_label if uses_land_stage else ocean_mine_counter_label
	top_timer_counter_label = land_timer_counter_label if uses_land_stage else ocean_timer_counter_label


func _restore_land_editor_layout() -> void:
	land_board_center.offset_left = _land_board_center_offsets.x
	land_board_center.offset_top = _land_board_center_offsets.y
	land_board_center.offset_right = _land_board_center_offsets.z
	land_board_center.offset_bottom = _land_board_center_offsets.w
	land_board_center.scale = _land_board_center_scale
	land_quick_buttons.position = _land_quick_actions_position


func _on_main_resized() -> void:
	call_deferred("_apply_land_interface_transform")


func _apply_land_interface_transform() -> void:
	if not is_instance_valid(land_layout) or not is_instance_valid(ocean_layout):
		return
	var viewport_fit := minf(
		size.x / LAND_INTERFACE_DESIGN_WIDTH,
		size.y / OCEAN_INTERFACE_DESIGN_SIZE.y
	)
	var interface_scale := LAND_INTERFACE_SCALE * viewport_fit
	var interface_position := Vector2(
		(size.x - LAND_INTERFACE_DESIGN_WIDTH * interface_scale) * 0.5,
		LAND_INTERFACE_TOP_OFFSET * viewport_fit
	)
	land_layout.scale = Vector2.ONE * interface_scale
	land_layout.position = interface_position
	ocean_layout.scale = Vector2.ONE * interface_scale
	ocean_layout.position = interface_position


func _apply_handmade_typography() -> void:
	var font := load(HANDMADE_FONT_PATH) as FontFile
	if font == null:
		push_error("Level interface font could not be loaded: %s" % HANDMADE_FONT_PATH)
		return
	for interface_root in [
		land_environment_panel,
		ocean_environment_panel,
		land_hud_panel,
		ocean_hud_panel,
		land_top_hud,
		ocean_top_hud,
		land_quick_buttons,
		ocean_quick_buttons,
		pause_overlay,
	]:
		_apply_font_to_tree(interface_root, font)


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
	if is_instance_valid(land_tabletop_actors):
		land_tabletop_actors.set_plant_texture(path)


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
	button.add_theme_color_override("font_color", Color("403b34"))
	button.add_theme_color_override("font_hover_color", Color("332f2a"))
	button.add_theme_color_override("font_pressed_color", Color("332f2a"))
	button.add_theme_color_override("font_focus_color", Color("332f2a"))
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


func _apply_chapter_quick_buttons(uses_land_stage: bool) -> void:
	if uses_land_stage:
		_apply_texture_button_states(
			pause_button,
			_load_runtime_texture(LAND_REGENERATE_NORMAL_PATH),
			_load_runtime_texture(LAND_REGENERATE_HOVER_PATH),
			_load_runtime_texture(LAND_REGENERATE_FOCUS_PATH),
			_load_runtime_texture(LAND_REGENERATE_PRESSED_PATH)
		)
		_apply_texture_button_states(
			restart_button,
			_load_runtime_texture(LAND_SETTINGS_NORMAL_PATH),
			_load_runtime_texture(LAND_SETTINGS_HOVER_PATH),
			_load_runtime_texture(LAND_SETTINGS_FOCUS_PATH),
			_load_runtime_texture(LAND_SETTINGS_PRESSED_PATH)
		)
		pause_button_label.add_theme_color_override("font_color", LAND_QUICK_BUTTON_LABEL_COLOR)
		restart_button_label.add_theme_color_override("font_color", LAND_QUICK_BUTTON_LABEL_COLOR)
		pause_button.tooltip_text = "TXT_0143"
		restart_button.tooltip_text = "TXT_0146"
		pause_button_label.text = tr("TXT_0144")
		restart_button_label.text = tr("TXT_0148")
		return

	_apply_texture_button_states(
		pause_button,
		_load_runtime_texture(OCEAN_PAUSE_NORMAL_PATH),
		_load_runtime_texture(OCEAN_PAUSE_HOVER_PATH),
		_load_runtime_texture(OCEAN_PAUSE_FOCUS_PATH),
		_load_runtime_texture(OCEAN_PAUSE_PRESSED_PATH)
	)
	_apply_texture_button_states(
		restart_button,
		_load_runtime_texture(OCEAN_REGENERATE_NORMAL_PATH),
		_load_runtime_texture(OCEAN_REGENERATE_HOVER_PATH),
		_load_runtime_texture(OCEAN_REGENERATE_FOCUS_PATH),
		_load_runtime_texture(OCEAN_REGENERATE_PRESSED_PATH)
	)
	pause_button_label.add_theme_color_override("font_color", OCEAN_QUICK_BUTTON_LABEL_COLOR)
	restart_button_label.add_theme_color_override("font_color", OCEAN_QUICK_BUTTON_LABEL_COLOR)
	pause_button.tooltip_text = "TXT_0143"
	restart_button.tooltip_text = "TXT_0146"
	pause_button_label.text = tr("TXT_0144")
	restart_button_label.text = tr("TXT_0148")


func _apply_guardian_state(state: int) -> void:
	if is_instance_valid(land_tabletop_actors):
		land_tabletop_actors.set_failure(
			state == MinesweeperBoard.GameState.LOST
		)


func _set_level_one_reaction(state: int) -> void:
	_apply_guardian_state(state)
	if is_instance_valid(land_tabletop_actors):
		land_tabletop_actors.play_reaction(
			state == MinesweeperBoard.GameState.WON,
			state == MinesweeperBoard.GameState.LOST
		)


func _process(_delta: float) -> void:
	if _timer_running:
		_update_timer_label()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not _active_mechanic_guide_id.is_empty() \
			and event.is_action_pressed("ui_cancel"):
		set_session_paused(not _session_paused)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and not key_event.ctrl_pressed
			and not key_event.alt_pressed
			and not key_event.meta_pressed
		):
			var keycode := key_event.physical_keycode
			if keycode == 0:
				keycode = key_event.keycode
			if keycode == KEY_C:
				if _scan_phase == ScanPhase.TARGETING:
					_cancel_scan_targeting()
				else:
					_request_scan_mode()
				get_viewport().set_input_as_handled()
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
	if _scan_phase == ScanPhase.TARGETING:
		_cancel_scan_targeting()
	else:
		set_session_paused(not _session_paused)
	get_viewport().set_input_as_handled()


func start_level(level_index: int, initial_scan_energy: int = -1) -> void:
	if is_instance_valid(_badge_celebration):
		_badge_celebration.hide_award()
	_clear_scan_ability()
	_active_mechanic_guide_id = &""
	_queued_mechanic_guides.clear()
	first_move_guide.hide_guide()
	if initial_scan_energy >= 0:
		_scan_energy = clampi(initial_scan_energy, 0, SCAN_CAPACITY)
	current_level_index = clampi(
		level_index,
		0,
		GreenSweeperLevels.PLAYABLE_LEVELS.size() - 1
	)
	var uses_level_one_stage := current_level_index < GreenSweeperLevels.LAND_LEVELS.size()
	_select_chapter_interface(uses_level_one_stage)
	land_board.set_interaction_enabled(false)
	ocean_board.set_interaction_enabled(false)
	_restore_land_editor_layout()
	call_deferred("_apply_land_interface_transform")
	land_layout.visible = uses_level_one_stage
	ocean_layout.visible = not uses_level_one_stage
	land_desk_background.visible = uses_level_one_stage
	land_unified_shadow.visible = false
	land_top_hud.visible = uses_level_one_stage
	ocean_top_hud.visible = not uses_level_one_stage
	time_title.visible = false
	timer_label.visible = false
	time_separator.visible = false
	flags_row.visible = false
	land_tabletop_actors.visible = true
	scan_fallback_row.visible = false
	_apply_chapter_quick_buttons(uses_level_one_stage)
	if uses_level_one_stage:
		_apply_land_actor_layout()
	else:
		_apply_ocean_actor_layout()
	land_tabletop_actors.configure_for_level(current_level_index + 1)
	_set_level_one_reaction(MinesweeperBoard.GameState.READY)
	if uses_level_one_stage:
		_apply_land_decorative_texture(
			str(LAND_DECORATIVE_HEALTHY_PATHS[current_level_index])
		)
	boss_stage.visible = false
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
	_pending_opening_assist_mode = _take_opening_assist_mode(current_level_index)
	board.set_opening_assist_mode(_pending_opening_assist_mode)
	board.load_level(level)
	board.scale = Vector2.ONE
	board.set_interaction_enabled(true)
	_initialize_scan_ability()
	subtitle_label.text = tr("TXT_0095") % [
		board.level_number,
		tr(board.level_name),
	]
	level_summary_label.text = tr("TXT_0099") % [
		board.column_count,
		board.row_count,
		tr("TXT_0102") if board.topology == &"hex_pointy_odd_r" else tr("TXT_0101"),
		board.core_count,
	]
	_on_pollution_nodes_changed(
		board.cleansed_pollution_node_count,
		board.pollution_node_count
	)
	_on_tidal_zone_changed(
		board.active_tidal_zone_index,
		board.tidal_zone_count
	)
	_refresh_instructions()
	_refresh_first_move_guide()
	visible = true
	level_started.emit(board.level_number)
	call_deferred("_show_level_mechanic_guide")


func restart_level() -> void:
	_clear_scan_ability()
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
	_pending_opening_assist_mode = _take_opening_assist_mode(current_level_index)
	board.set_opening_assist_mode(_pending_opening_assist_mode)
	board.new_game()
	_initialize_scan_ability()
	if not _active_mechanic_guide_id.is_empty():
		board.set_tooltips_enabled(false)
		land_tabletop_actors.set_scan_paused(true)
		call_deferred("_refresh_active_mechanic_guide_target")
	if _tutorial_dismissed_for_session:
		board.clear_guide_cell()
	_refresh_instructions()
	_refresh_first_move_guide()


func _refresh_active_mechanic_guide_target() -> void:
	if _active_mechanic_guide_id.is_empty() \
			or not first_move_guide.is_dialogue_mode():
		return
	first_move_guide.set_dialogue_target_global_position(
		_mechanic_guide_target_global_position(_active_mechanic_guide_id)
	)


func _take_opening_assist_mode(level_index: int) -> int:
	if level_index < ADAPTIVE_ASSIST_FIRST_LEVEL_INDEX \
			or level_index >= GreenSweeperLevels.PLAYABLE_LEVELS.size():
		return MinesweeperBoard.OpeningAssist.NONE
	var early_loss_streak := int(_early_loss_streaks.get(level_index, 0))
	if early_loss_streak >= EARLY_LOSS_STREAK_THRESHOLD:
		return MinesweeperBoard.OpeningAssist.OPEN_REGION
	var first_click_streak := int(_first_click_mine_streaks.get(level_index, 0))
	if first_click_streak >= FIRST_CLICK_MINE_STREAK_THRESHOLD:
		return MinesweeperBoard.OpeningAssist.SAFE_FIRST
	return MinesweeperBoard.OpeningAssist.NONE


func _record_adaptive_attempt_result(state: int) -> void:
	if (
		current_level_index < ADAPTIVE_ASSIST_FIRST_LEVEL_INDEX
		or current_level_index >= GreenSweeperLevels.PLAYABLE_LEVELS.size()
	):
		return
	if state == MinesweeperBoard.GameState.PLAYING:
		if _pending_opening_assist_mode == MinesweeperBoard.OpeningAssist.SAFE_FIRST:
			_first_click_mine_streaks[current_level_index] = 0
		elif _pending_opening_assist_mode == MinesweeperBoard.OpeningAssist.OPEN_REGION:
			_first_click_mine_streaks[current_level_index] = 0
			_early_loss_streaks[current_level_index] = 0
		_pending_opening_assist_mode = MinesweeperBoard.OpeningAssist.NONE
		return
	if state == MinesweeperBoard.GameState.WON:
		_first_click_mine_streaks[current_level_index] = 0
		_early_loss_streaks[current_level_index] = 0
		_pending_opening_assist_mode = MinesweeperBoard.OpeningAssist.NONE
		return
	if state != MinesweeperBoard.GameState.LOST:
		return
	var lost_on_first_reveal := board.reveal_action_count == 1
	if lost_on_first_reveal:
		_first_click_mine_streaks[current_level_index] = int(
			_first_click_mine_streaks.get(current_level_index, 0)
		) + 1
	else:
		_first_click_mine_streaks[current_level_index] = 0
	if board.move_count <= EARLY_LOSS_MOVE_LIMIT:
		_early_loss_streaks[current_level_index] = int(
			_early_loss_streaks.get(current_level_index, 0)
		) + 1
	else:
		_early_loss_streaks[current_level_index] = 0


func set_operation_mode(mode: int) -> void:
	_operation_mode = 1 if mode == 1 else 0
	land_board.set_operation_mode(_operation_mode)
	ocean_board.set_operation_mode(_operation_mode)
	_refresh_instructions()
	_refresh_first_move_guide()


func get_operation_mode() -> int:
	return _operation_mode


func refresh_localized_interface() -> void:
	if not is_instance_valid(board):
		return
	subtitle_label.text = tr("TXT_0095") % [
		board.level_number,
		tr(board.level_name),
	]
	level_summary_label.text = tr("TXT_0099") % [
		board.column_count,
		board.row_count,
		tr("TXT_0102") if board.topology == &"hex_pointy_odd_r" else tr("TXT_0101"),
		board.core_count,
	]
	_refresh_instructions()
	_refresh_scan_ui()
	_on_pollution_nodes_changed(
		board.cleansed_pollution_node_count,
		board.pollution_node_count
	)
	_refresh_localized_state_copy()
	if board.tidal_zone_count > 0:
		_on_tidal_zone_changed(
			board.active_tidal_zone_index,
			board.tidal_zone_count
		)
	_on_flags_changed(board.used_flags, board.get_runtime_mine_count())
	first_move_guide.refresh_localized_text()
	if board.has_method("refresh_localized_text"):
		board.call("refresh_localized_text")
	if is_instance_valid(_badge_celebration):
		_badge_celebration.refresh_language()


func _refresh_localized_state_copy() -> void:
	match board.game_state:
		MinesweeperBoard.GameState.READY:
			var tutorial_ready := (
				board.level_number == 1
				and not _tutorial_dismissed_for_session
				and _tutorial_step == TutorialStep.FIRST_REVEAL
			)
			status_label.text = tr("TXT_0133") if tutorial_ready else tr("TXT_0129")
			restart_button_label.text = tr("TXT_0144")
			pause_button_label.text = tr("TXT_0147")
		MinesweeperBoard.GameState.PLAYING:
			status_label.text = tr("TXT_0130")
			restart_button_label.text = tr("TXT_0145")
			pause_button_label.text = tr("TXT_0147")
		MinesweeperBoard.GameState.WON:
			pause_button_label.text = tr("TXT_0148")
			if board.level_number == 7:
				status_label.text = tr("TXT_0138")
				restart_button_label.text = tr("TXT_0051")
			elif board.level_number == 14:
				status_label.text = tr("TXT_0139")
				restart_button_label.text = tr("TXT_0053")
			elif _has_next_level_in_chapter():
				status_label.text = tr("TXT_0136")
				restart_button_label.text = tr("TXT_0052")
			else:
				status_label.text = tr("TXT_0137") % tr(board.level_name)
				restart_button_label.text = tr("TXT_0141")
		MinesweeperBoard.GameState.LOST:
			var wrong_flag_count := board.get_wrong_flag_count()
			status_label.text = (
				tr("TXT_0151") % wrong_flag_count
				if wrong_flag_count > 0
				else tr("TXT_0150")
			)
			restart_button_label.text = tr("TXT_0145")
			pause_button_label.text = tr("TXT_0148")
	_apply_land_quick_button_copy()


func _apply_land_quick_button_copy() -> void:
	pause_button_label.text = restart_button_label.text
	restart_button_label.text = tr("TXT_0148")


func set_seen_mechanic_guides(guide_ids: Array) -> void:
	_seen_mechanic_guides.clear()
	for guide_id in guide_ids:
		var normalized_id := StringName(str(guide_id))
		if not normalized_id.is_empty():
			_seen_mechanic_guides[normalized_id] = true


func set_first_move_guide_enabled(enabled: bool) -> void:
	_first_move_guide_enabled = enabled


func _refresh_instructions() -> void:
	if not is_instance_valid(instructions_label) or not is_instance_valid(board):
		return
	if (
		board.topology == &"hex_pointy_odd_r"
		and (
			board.reef_edge_count > 0
			or board.mobile_current_enabled
			or board.drifting_mine_enabled
			or board.tidal_zone_count > 0
		)
	):
		var ocean_rules := PackedStringArray()
		if board.reef_edge_count > 0:
			ocean_rules.append(
				tr("TXT_0166")
			)
		if board.mobile_current_enabled:
			var mobile_group_count := board.mobile_current_group_count
			var candidates_per_group := int(
				board.mobile_current_shape.size() / maxi(1, mobile_group_count)
			)
			var cores_per_group := int(
				board.mobile_current_core_count / maxi(1, mobile_group_count)
			)
			var mobile_group_label := (
				tr("TXT_0167")
				if mobile_group_count == 2
				else (
					tr("TXT_0168")
					if mobile_group_count == 3
					else tr("TXT_0169") % mobile_group_count
				)
			)
			ocean_rules.append(
				tr("TXT_0170")
				% [mobile_group_label, candidates_per_group, cores_per_group]
			)
			ocean_rules.append(
				tr("TXT_0171")
			)
			ocean_rules.append(
				tr("TXT_0172")
				% [mobile_group_label, roundi(board.mobile_current_step_seconds)]
			)
			ocean_rules.append(
				tr("TXT_0173")
			)
		if board.drifting_mine_enabled:
			ocean_rules.append(
				tr("TXT_0174")
			)
			ocean_rules.append(
				tr("TXT_0175")
			)
			ocean_rules.append(
				tr("TXT_0176")
			)
		if board.tidal_zone_count > 0:
			ocean_rules.append(
				tr("TXT_0177")
			)
			ocean_rules.append(
				tr("TXT_0178")
			)
		ocean_rules.append(
			tr("TXT_0158")
			if _operation_mode == 1
			else tr("TXT_0157")
		)
		instructions_label.text = "\n".join(ocean_rules)
		return
	if board.pollution_node_count > 0:
		var node_rule := (
			tr("TXT_0179")
			if board.level_number == 7
			else tr("TXT_0180")
		)
		instructions_label.text = (
			node_rule
			+ tr("TXT_0181")
			+ (
				tr("TXT_0480") % roundi(board.pollution_reset_seconds)
				if board.pollution_reset_seconds > 0.0
				else ""
			)
			+ (
				tr("TXT_0386")
				if _operation_mode == 1
				else tr("TXT_0162")
			)
		)
		return
	var tutorial_active := (
		board.level_number == 1
		and not _tutorial_dismissed_for_session
		and _tutorial_step != TutorialStep.INACTIVE
		and _tutorial_step != TutorialStep.COMPLETE
	)
	if _operation_mode == 1:
		instructions_label.text = (
			tr("TXT_0159")
			+ tr("TXT_0160")
			+ tr("TXT_0161")
		)
	else:
		instructions_label.text = (
			(tr("TXT_0135") if tutorial_active else tr("TXT_0164"))
			+ tr("TXT_0162")
			+ tr("TXT_0163")
		)


func _show_level_mechanic_guide() -> void:
	var guide_data = LEVEL_MECHANIC_GUIDES.get(board.level_number)
	if guide_data is Dictionary:
		_request_mechanic_guide(guide_data)


func _request_mechanic_guide(guide_data: Dictionary) -> void:
	var guide_id := StringName(str(guide_data.get("id", "")))
	var pages = guide_data.get("pages", [])
	if guide_id.is_empty() or not pages is Array or pages.is_empty() \
			or _seen_mechanic_guides.has(guide_id) \
			or _active_mechanic_guide_id == guide_id:
		return
	if first_move_guide.visible:
		if guide_id not in _queued_mechanic_guides:
			_queued_mechanic_guides.append(guide_id)
		return
	_active_mechanic_guide_id = guide_id
	board.set_tooltips_enabled(false)
	land_tabletop_actors.set_scan_paused(true)
	pause_button.disabled = false
	restart_button.disabled = false
	pause_restart_button.disabled = false
	first_move_guide.show_dialogue(
		guide_id,
		pages,
		_operation_mode == 1,
		_mechanic_guide_target_global_position(guide_id)
	)


func _mechanic_guide_target_global_position(
	guide_id: StringName
) -> Vector2:
	if guide_id == &"eco_scan":
		var robot_hotspot := land_tabletop_actors.find_child(
			"RobotHotspot",
			true,
			false
		) as Control
		if is_instance_valid(robot_hotspot):
			return robot_hotspot.get_global_rect().get_center()
	return board.get_mechanic_guide_target_global_position(guide_id)


func _on_board_interacted() -> void:
	if _active_mechanic_guide_id.is_empty() \
			or not first_move_guide.is_dialogue_mode():
		return
	first_move_guide.complete_dialogue()


func _on_mechanic_dialogue_completed(guide_id: StringName) -> void:
	if guide_id.is_empty():
		return
	_seen_mechanic_guides[guide_id] = true
	mechanic_guide_completed.emit(guide_id)
	if _active_mechanic_guide_id == guide_id:
		_active_mechanic_guide_id = &""
	pause_button.disabled = false
	restart_button.disabled = false
	pause_restart_button.disabled = false
	if not _session_paused:
		board.set_tooltips_enabled(true)
		land_tabletop_actors.set_scan_paused(false)
		if board.game_state in [
			MinesweeperBoard.GameState.READY,
			MinesweeperBoard.GameState.PLAYING,
		]:
			board.set_interaction_enabled(true)
			_resume_timer_if_playing()
	call_deferred("_show_next_queued_mechanic_guide")


func _show_next_queued_mechanic_guide() -> void:
	if first_move_guide.visible or not _active_mechanic_guide_id.is_empty():
		return
	while not _queued_mechanic_guides.is_empty():
		var guide_id: StringName = _queued_mechanic_guides.pop_front()
		if _seen_mechanic_guides.has(guide_id):
			continue
		var guide_data := _mechanic_guide_by_id(guide_id)
		if not guide_data.is_empty():
			_request_mechanic_guide(guide_data)
		return


func _mechanic_guide_by_id(guide_id: StringName) -> Dictionary:
	if StringName(str(SCAN_GUIDE.get("id", ""))) == guide_id:
		return SCAN_GUIDE
	for guide_data in LEVEL_MECHANIC_GUIDES.values():
		if guide_data is Dictionary \
				and StringName(str(guide_data.get("id", ""))) == guide_id:
			return guide_data
	return {}


func _refresh_first_move_guide() -> void:
	if not is_instance_valid(first_move_guide) or not is_instance_valid(board):
		return
	if not _active_mechanic_guide_id.is_empty() \
			and first_move_guide.is_dialogue_mode():
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
				title = "TXT_0399"
				action = "TXT_0434" if _operation_mode == 1 else "TXT_0401"
				hint = "TXT_0432"
			else:
				target_index = _find_unrevealed_safe_index()
				title = "TXT_0449"
				action = "TXT_0435" if _operation_mode == 1 else "TXT_0390"
				hint = "TXT_0406"
		TutorialStep.NUMBER_INFO:
			target_index = _tutorial_number_index
			title = "TXT_0453"
			action = "TXT_0450"
			hint = "TXT_0410" if _operation_mode == 1 else "TXT_0389"
			show_next = true
		TutorialStep.MARK_CORE:
			target_index = _tutorial_target_index
			title = "TXT_0418"
			var removing_wrong_flag := (
				_is_valid_tutorial_index(target_index)
				and board.flagged[target_index]
				and not board.mines[target_index]
			)
			if removing_wrong_flag:
				action = "TXT_0411" if _operation_mode == 1 else "TXT_0396"
				hint = "TXT_0433"
			else:
				action = "TXT_0412" if _operation_mode == 1 else "TXT_0397"
				hint = "TXT_0407"
		TutorialStep.CHORD:
			target_index = _tutorial_number_index
			title = "TXT_0403"
			action = "TXT_0454" if _operation_mode == 1 else "TXT_0394"
			hint = "TXT_0417"

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
	if newly_revealed_count > 0 and board.level_number >= 8:
		AudioManager.play_ocean_reveal()
	if not _ordinary_reveal_seen:
		_ordinary_reveal_seen = true
	if newly_revealed_count > 0:
		_award_scan_energy()
	_unlock_scan_after_first_reveal()
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


func _on_flag_completed(
	_cell_index: int,
	is_flagged: bool,
	is_first_placement: bool
) -> void:
	if is_flagged and is_first_placement:
		_award_scan_energy()
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _on_chord_completed(_cell_index: int, newly_revealed_count: int) -> void:
	if newly_revealed_count > 0 and board.level_number >= 8:
		AudioManager.play_ocean_reveal()
	if newly_revealed_count > 0:
		_award_scan_energy()
	if _tutorial_dismissed_for_session or board.level_number != 1:
		return
	if _tutorial_step == TutorialStep.CHORD and newly_revealed_count > 0:
		_complete_tutorial()
	elif _tutorial_step in [TutorialStep.MARK_CORE, TutorialStep.CHORD]:
		_revalidate_tutorial_frontier()
		_refresh_first_move_guide()


func _clear_scan_ability() -> void:
	if is_instance_valid(board):
		board.set_scan_target_mode(false)
	_scan_phase = ScanPhase.INACTIVE
	_scan_threshold = SCAN_CAPACITY
	_ordinary_reveal_seen = false
	_scan_target_index = -1
	_scan_target_global_position = Vector2.ZERO
	if is_instance_valid(land_tabletop_actors):
		land_tabletop_actors.finish_scan_visuals()
		land_tabletop_actors.set_scan_meter(
			_scan_energy,
			_scan_threshold,
			true,
			false
		)
		land_tabletop_actors.set_scan_activation_enabled(false, tr("TXT_0184"))


func _initialize_scan_ability() -> void:
	_scan_threshold = SCAN_CAPACITY
	_scan_energy = clampi(_scan_energy, 0, _scan_threshold)
	_ordinary_reveal_seen = false
	_scan_target_index = -1
	_scan_phase = ScanPhase.LOCKED_FIRST_REVEAL
	board.set_scan_target_mode(false)
	_refresh_scan_ui()


func _unlock_scan_after_first_reveal() -> void:
	if (
		not _ordinary_reveal_seen
		or board.game_state != MinesweeperBoard.GameState.PLAYING
		or _scan_phase in [ScanPhase.INACTIVE, ScanPhase.FINISHED]
	):
		return
	_scan_phase = (
		ScanPhase.READY
		if _scan_energy >= _scan_threshold
		else ScanPhase.CHARGING
	)
	_refresh_scan_ui()
	if _scan_phase == ScanPhase.READY:
		_request_mechanic_guide(SCAN_GUIDE)


func _award_scan_energy() -> void:
	if (
		_scan_phase == ScanPhase.INACTIVE
		or board.game_state == MinesweeperBoard.GameState.LOST
		or _scan_energy >= _scan_threshold
	):
		return
	_scan_energy += 1
	scan_energy_changed.emit(_scan_energy)
	if (
		_ordinary_reveal_seen
		and board.game_state == MinesweeperBoard.GameState.PLAYING
		and _scan_phase in [
			ScanPhase.LOCKED_FIRST_REVEAL,
			ScanPhase.CHARGING,
			ScanPhase.READY,
		]
	):
		_scan_phase = (
			ScanPhase.READY
			if _scan_energy >= _scan_threshold
			else ScanPhase.CHARGING
		)
	_refresh_scan_ui()
	if _scan_phase == ScanPhase.READY:
		_request_mechanic_guide(SCAN_GUIDE)


func _request_scan_mode() -> void:
	if (
		_scan_phase != ScanPhase.READY
		or _session_paused
		or board.game_state != MinesweeperBoard.GameState.PLAYING
	):
		_refresh_scan_ui()
		return
	_scan_phase = ScanPhase.TARGETING
	board.set_scan_target_mode(true)
	if not board.scan_target_mode:
		_scan_phase = ScanPhase.READY
		_refresh_scan_ui()
		return
	land_tabletop_actors.begin_scan_targeting()
	_refresh_scan_ui()


func _on_scan_target_requested(cell_index: int) -> void:
	if _scan_phase != ScanPhase.TARGETING or not board.is_scan_candidate(cell_index):
		return
	_scan_target_index = cell_index
	_scan_target_global_position = board.cell_nodes[cell_index].get_global_rect().get_center()
	_scan_phase = ScanPhase.RESOLVING
	var previous_energy := _scan_energy
	_scan_energy = 0
	_refresh_scan_ui()
	if not board.try_scan_cell(cell_index):
		_scan_energy = previous_energy
		_scan_phase = ScanPhase.TARGETING
		_refresh_scan_ui()
		return
	scan_energy_changed.emit(_scan_energy)


func _on_scan_completed(
	cell_index: int,
	result: int,
	_newly_revealed_count: int
) -> void:
	if _scan_phase != ScanPhase.RESOLVING or cell_index != _scan_target_index:
		return
	_scan_phase = (
		ScanPhase.FINISHED
		if board.game_state in [
			MinesweeperBoard.GameState.WON,
			MinesweeperBoard.GameState.LOST,
		]
		else ScanPhase.CHARGING
	)
	_scan_target_index = -1
	land_tabletop_actors.set_scan_meter(0, _scan_threshold, false, false)
	land_tabletop_actors.play_scan_result(result, _scan_target_global_position)
	_refresh_scan_ui()


func _cancel_scan_targeting() -> void:
	if _scan_phase != ScanPhase.TARGETING:
		return
	board.set_scan_target_mode(false)
	_scan_phase = ScanPhase.READY
	_scan_target_index = -1
	land_tabletop_actors.cancel_scan_targeting()
	_refresh_scan_ui()


func _finish_scan_ability() -> void:
	if _scan_phase == ScanPhase.INACTIVE:
		return
	board.set_scan_target_mode(false)
	_scan_phase = ScanPhase.FINISHED
	_scan_target_index = -1
	land_tabletop_actors.finish_scan_visuals()
	_refresh_scan_ui()


func _refresh_scan_ui() -> void:
	if not is_instance_valid(land_tabletop_actors):
		return
	var locked := _scan_phase == ScanPhase.LOCKED_FIRST_REVEAL
	var finished := _scan_phase == ScanPhase.FINISHED
	land_tabletop_actors.set_scan_meter(
		_scan_energy,
		_scan_threshold,
		locked,
		finished,
		true
	)
	var activation_enabled := (
		_scan_phase == ScanPhase.READY
		and not _session_paused
		and board.game_state == MinesweeperBoard.GameState.PLAYING
	)
	var tooltip := tr("TXT_0184")
	match _scan_phase:
		ScanPhase.LOCKED_FIRST_REVEAL:
			tooltip = tr("TXT_0185")
		ScanPhase.CHARGING:
			tooltip = tr("TXT_0186") % [_scan_energy, _scan_threshold]
		ScanPhase.READY:
			tooltip = tr("TXT_0187")
		ScanPhase.TARGETING:
			tooltip = tr("TXT_0189")
		ScanPhase.RESOLVING:
			tooltip = tr("TXT_0191")
		ScanPhase.FINISHED:
			tooltip = tr("TXT_0192")
	land_tabletop_actors.set_scan_activation_enabled(
		activation_enabled,
		tooltip
	)
	if is_instance_valid(scan_fallback_row):
		scan_fallback_row.visible = false
		scan_fallback_button.disabled = not activation_enabled
		scan_fallback_button.tooltip_text = tooltip
		var fallback_text := tr("TXT_0193")
		match _scan_phase:
			ScanPhase.LOCKED_FIRST_REVEAL:
				fallback_text = tr("TXT_0194")
			ScanPhase.CHARGING:
				fallback_text = "%d/%d" % [_scan_energy, _scan_threshold]
			ScanPhase.READY:
				fallback_text = tr("TXT_0195")
			ScanPhase.TARGETING:
				fallback_text = tr("TXT_0196")
			ScanPhase.RESOLVING:
				fallback_text = tr("TXT_0197")
			ScanPhase.FINISHED:
				fallback_text = tr("TXT_0198")
		scan_fallback_status.text = fallback_text
		var filled_count := mini(
			3,
			int(floor(float(_scan_energy) * 3.0 / float(maxi(1, _scan_threshold))))
		)
		for dot_index in ocean_scan_dots.size():
			var dot := ocean_scan_dots[dot_index]
			if finished:
				dot.modulate = Color(0.42, 0.47, 0.40, 0.22)
			elif dot_index < filled_count:
				dot.modulate = (
					Color(0.62, 0.74, 0.66, 0.52)
					if locked
					else Color.WHITE
				)
			else:
				dot.modulate = Color(0.42, 0.56, 0.47, 0.30)


func get_scan_phase() -> int:
	return _scan_phase


func get_scan_energy() -> int:
	return _scan_energy


func get_scan_threshold() -> int:
	return _scan_threshold


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
		status_label.text = tr("TXT_0132")
	call_deferred("_show_next_queued_mechanic_guide")


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
	_refresh_scan_ui()
	if board.game_state == MinesweeperBoard.GameState.PLAYING:
		status_label.text = tr("TXT_0134")
	call_deferred("_show_next_queued_mechanic_guide")


func set_session_paused(paused: bool) -> void:
	if _session_paused == paused:
		return
	_session_paused = paused
	var guide_active := not _active_mechanic_guide_id.is_empty()
	if paused:
		_pause_timer()
	else:
		_resume_timer_if_playing()
	board.set_interaction_enabled(not paused)
	board.set_tooltips_enabled(not paused and not guide_active)
	land_tabletop_actors.set_scan_paused(paused or guide_active)
	pause_overlay.visible = paused
	_refresh_scan_ui()
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
	_chapter_advance_available = false
	if state in [MinesweeperBoard.GameState.WON, MinesweeperBoard.GameState.LOST]:
		_finish_scan_ability()
	_record_adaptive_attempt_result(state)
	_set_level_one_reaction(state)
	if current_level_index < LAND_DECORATIVE_HEALTHY_PATHS.size():
		var decorative_sprout_path: String = (
			LAND_DECORATIVE_FAILED_PATHS[current_level_index]
			if state == MinesweeperBoard.GameState.LOST
			else LAND_DECORATIVE_HEALTHY_PATHS[current_level_index]
		)
		_apply_land_decorative_texture(decorative_sprout_path)
	match state:
		MinesweeperBoard.GameState.READY:
			_reset_timer()
			var tutorial_ready := (
				board.level_number == 1
				and not _tutorial_dismissed_for_session
				and _tutorial_step == TutorialStep.FIRST_REVEAL
			)
			status_label.text = (
				tr("TXT_0182") % [
					board.active_tidal_zone_index + 1,
					board.tidal_zone_count,
				]
				if board.tidal_zone_count > 0
				else (tr("TXT_0133") if tutorial_ready else tr("TXT_0129"))
			)
			restart_button_label.text = tr("TXT_0144")
			pause_button_label.text = tr("TXT_0147")
			pause_button.disabled = false
		MinesweeperBoard.GameState.PLAYING:
			_start_timer()
			status_label.text = (
				tr("TXT_0183") % [
					board.active_tidal_zone_index + 1,
					board.tidal_zone_count,
				]
				if board.tidal_zone_count > 0
				else tr("TXT_0130")
			)
			restart_button_label.text = tr("TXT_0145")
			pause_button_label.text = tr("TXT_0147")
			pause_button.disabled = false
		MinesweeperBoard.GameState.WON:
			_pause_timer()
			pause_button_label.text = tr("TXT_0148")
			pause_button.disabled = false
			if board.level_number == 7:
				status_label.text = tr("TXT_0138")
				restart_button_label.text = tr("TXT_0051")
				_chapter_advance_available = true
			elif board.level_number == 14:
				status_label.text = tr("TXT_0139")
				restart_button_label.text = tr("TXT_0053")
				_chapter_advance_available = true
			elif _has_next_level_in_chapter():
				status_label.text = tr("TXT_0136")
				restart_button_label.text = tr("TXT_0052")
				_advance_available = true
			else:
				status_label.text = tr("TXT_0137") % tr(board.level_name)
				restart_button_label.text = tr("TXT_0141")
			if not _completion_emitted:
				_completion_emitted = true
				AudioManager.play_level_win(board.level_number)
				level_completed.emit(board.level_number, get_elapsed_ms())
				if board.level_number <= 14:
					call_deferred("_show_badge_celebration", board.level_number)
		MinesweeperBoard.GameState.LOST:
			AudioManager.play_fail()
			_pause_timer()
			pause_button_label.text = tr("TXT_0148")
			pause_button.disabled = false
			var wrong_flag_count := board.get_wrong_flag_count()
			status_label.text = (
				tr("TXT_0151") % wrong_flag_count
				if wrong_flag_count > 0
				else tr("TXT_0150")
			)
			_on_flags_changed(board.used_flags, board.get_runtime_mine_count())
			restart_button_label.text = tr("TXT_0145")
	_apply_land_quick_button_copy()
	_refresh_first_move_guide()


func _show_badge_celebration(level_number: int) -> void:
	if (
		is_instance_valid(_badge_celebration)
		and board.game_state == MinesweeperBoard.GameState.WON
		and board.level_number == level_number
	):
		_badge_celebration.show_award(level_number)


func continue_after_badge_book() -> void:
	if board.game_state != MinesweeperBoard.GameState.WON:
		return
	_on_primary_button_pressed()


func _has_next_level_in_chapter() -> bool:
	if current_level_index < GreenSweeperLevels.LAND_LEVELS.size():
		return current_level_index + 1 < GreenSweeperLevels.LAND_LEVELS.size()
	return current_level_index + 1 < GreenSweeperLevels.PLAYABLE_LEVELS.size()


func _on_pollution_nodes_changed(cleansed_count: int, total_count: int) -> void:
	if board.drifting_mine_enabled:
		objective_label.text = (
			tr("TXT_0121")
			if board.drifting_mine_resolved
			else tr("TXT_0119")
		)
	elif board.mobile_current_enabled:
		var group_count := board.mobile_current_group_count
		var group_core_count := int(
			board.mobile_current_core_count / maxi(1, group_count)
		)
		objective_label.text = tr("TXT_0118") % [
			group_count,
			group_core_count,
		]
	elif board.level_number == 7 and total_count > 0:
		objective_label.text = tr("TXT_0117") % [
			cleansed_count,
			total_count,
		]
	elif total_count > 0:
		objective_label.text = tr("TXT_0116") % [
			cleansed_count,
			total_count,
			tr(board.level_name),
		]
	else:
		objective_label.text = tr("TXT_0115") % tr(board.level_name)


func _on_current_path_feedback(text: String) -> void:
	status_label.text = text


func _on_mobile_current_state_changed(resolved: bool) -> void:
	if resolved and board.game_state == MinesweeperBoard.GameState.PLAYING:
		objective_label.text = tr("TXT_0120")


func _on_drifting_mine_state_changed(resolved: bool) -> void:
	if resolved and board.game_state == MinesweeperBoard.GameState.PLAYING:
		objective_label.text = tr("TXT_0121")


func _on_tidal_zone_changed(active_zone_index: int, zone_count: int) -> void:
	if zone_count <= 0:
		return
	objective_label.text = tr("TXT_0122") % [
		active_zone_index + 1,
		zone_count,
	]
	if board.game_state == MinesweeperBoard.GameState.READY:
		status_label.text = tr("TXT_0182") % [active_zone_index + 1, zone_count]
	elif board.game_state == MinesweeperBoard.GameState.PLAYING:
		status_label.text = tr("TXT_0183") % [active_zone_index + 1, zone_count]
	_refresh_instructions()


func _on_flags_changed(used_flags: int, max_flags: int) -> void:
	flags_label.text = "%d/%d" % [used_flags, max_flags]
	mine_counter_label.text = "%d/%d" % [used_flags, max_flags]
	if board.game_state == MinesweeperBoard.GameState.LOST:
		var wrong_flag_count := board.get_wrong_flag_count()
		if wrong_flag_count > 0:
			flags_label.text += tr("TXT_0152") % wrong_flag_count


func _on_left_quick_button_pressed() -> void:
	_on_primary_button_pressed()


func _on_right_quick_button_pressed() -> void:
	_on_pause_button_pressed()


func _on_primary_button_pressed() -> void:
	if _chapter_advance_available:
		chapter_advance_requested.emit()
	elif _advance_available:
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
	var display_time := "%02d:%02d.%d" % [minutes, seconds, tenths]
	timer_label.text = display_time
	top_timer_counter_label.text = display_time


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
