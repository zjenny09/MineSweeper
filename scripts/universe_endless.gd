extends Control

const ART := preload("res://scripts/art_catalog.gd")
const MECHANIC_DIALOGUE_SCENE := preload("res://scenes/mechanic_dialogue.tscn")
const UNIVERSE_GUIDE := {
	"id": &"universe_star_chains",
	"pages": [
		{"title": "小芽：宇宙棋盘要看连线", "text": "两颗星核之间有线才算相邻，距离远近并不重要。", "hint": "没有连线的星核互不影响。"},
		{"title": "小芽：直线和弧线都有效", "text": "银灰色直线和青蓝色弧线都表示正常相邻。", "hint": "数字是所有直接相连星核中的污染总数。"},
		{"title": "小芽：星舰有两层护盾", "text": "误触污染会消耗一层护盾，并自动标记那颗星核。", "hint": "两层护盾都用完后，再误触才会结束远征。"},
	],
}
const WORMHOLE_GUIDE := {
	"id": &"universe_wormholes",
	"pages": [
		{"title": "小芽：紫色连线是虫洞", "text": "虫洞两端的星核即使离得很远，也算直接相邻。", "hint": "数字会把虫洞另一端的污染计算进去。"},
		{"title": "小芽：把它当成普通连线", "text": "判断数字时，沿紫色线找到另一端一起计算。", "hint": "除了距离很远，规则和其他连线完全相同。"},
	],
}

signal level_select_requested
signal main_menu_requested
signal settings_requested
signal exit_game_requested
signal scan_energy_changed(energy: int)
signal mechanic_guide_completed(guide_id: StringName)

@export var auto_start := true

@onready var board = %UniverseBoard
@onready var parallax_stars: Control = %ParallaxStars
@onready var craft_root: Control = %CraftRoot
@onready var regions_label: Label = %RegionsLabel
@onready var stars_label: Label = %StarsLabel
@onready var distance_label: Label = %DistanceLabel
@onready var disturbance_label: Label = %DisturbanceLabel
@onready var shield_label: Label = %ShieldLabel
@onready var flags_label: Label = %FlagsLabel
@onready var status_label: Label = %StatusLabel
@onready var timer_label: Label = %TimerLabel
@onready var pause_button: Button = %PauseButton
@onready var restart_button: Button = %RestartButton
@onready var map_button: Button = %MapButton
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var pause_restart_button: Button = %PauseRestartButton
@onready var pause_settings_button: Button = %PauseSettingsButton
@onready var pause_main_menu_button: Button = %PauseMainMenuButton
@onready var pause_exit_button: Button = %PauseExitButton
@onready var failure_overlay: Control = %FailureOverlay
@onready var failure_summary: Label = %FailureSummary
@onready var new_universe_button: Button = %NewUniverseButton
@onready var failure_map_button: Button = %FailureMapButton

var current_level_index := 21
var _elapsed_ms := 0
var _segment_started_ms := 0
var _timer_running := false
var _paused := false
var _regions := 0
var _purified_stars := 0
var _distance := 0
var _craft_time := 0.0
var _warp_active := false
var _nebula_speed := 0.055
var _mechanic_dialogue: FirstMoveGuide
var _seen_mechanic_guides: Dictionary = {}
var _active_mechanic_guide_id := &""


func _ready() -> void:
	_mechanic_dialogue = MECHANIC_DIALOGUE_SCENE.instantiate() as FirstMoveGuide
	add_child(_mechanic_dialogue)
	_mechanic_dialogue.dialogue_completed.connect(_on_mechanic_dialogue_completed)
	board.flags_changed.connect(_on_flags_changed)
	board.board_interacted.connect(_on_board_interacted)
	board.shield_changed.connect(_on_shield_changed)
	board.status_changed.connect(func(text: String) -> void:
		status_label.text = text
	)
	board.voyage_stats_changed.connect(_on_voyage_stats_changed)
	board.expedition_failed.connect(_on_expedition_failed)
	board.warp_changed.connect(_on_warp_changed)
	board.region_started.connect(_on_region_started)
	pause_button.pressed.connect(_set_paused.bind(true))
	restart_button.pressed.connect(_start_new_universe)
	map_button.pressed.connect(func() -> void: level_select_requested.emit())
	resume_button.pressed.connect(_set_paused.bind(false))
	pause_restart_button.pressed.connect(_restart_from_pause)
	pause_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	pause_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	pause_exit_button.pressed.connect(func() -> void: exit_game_requested.emit())
	new_universe_button.pressed.connect(_start_new_universe)
	failure_map_button.pressed.connect(func() -> void: level_select_requested.emit())
	_apply_interface_style()
	set_process(true)
	if auto_start:
		start_endless()


func start_endless(_initial_scan_energy: int = 0) -> void:
	visible = true
	_start_new_universe()


func set_operation_mode(_mode: int) -> void:
	pass


func set_seen_mechanic_guides(guide_ids: Array) -> void:
	_seen_mechanic_guides.clear()
	for guide_id in guide_ids:
		var normalized_id := StringName(str(guide_id))
		if not normalized_id.is_empty():
			_seen_mechanic_guides[normalized_id] = true


func set_first_move_guide_enabled(_enabled: bool) -> void:
	pass


func _on_region_started(region_index: int, wormhole_count: int) -> void:
	if region_index == 0:
		_request_mechanic_guide(UNIVERSE_GUIDE)
	elif wormhole_count > 0:
		_request_mechanic_guide(WORMHOLE_GUIDE)


func _request_mechanic_guide(guide_data: Dictionary) -> void:
	var guide_id := StringName(str(guide_data.get("id", "")))
	var pages = guide_data.get("pages", [])
	if guide_id.is_empty() or not pages is Array or pages.is_empty() \
			or _seen_mechanic_guides.has(guide_id) \
			or not _active_mechanic_guide_id.is_empty():
		return
	_active_mechanic_guide_id = guide_id
	pause_button.disabled = false
	restart_button.disabled = false
	pause_restart_button.disabled = false
	map_button.disabled = true
	var target_position: Vector2 = board.call(
		"get_mechanic_guide_target_global_position",
		guide_id
	)
	_mechanic_dialogue.show_dialogue(
		guide_id,
		pages,
		false,
		target_position
	)


func _on_board_interacted() -> void:
	if _active_mechanic_guide_id.is_empty() \
			or not _mechanic_dialogue.is_dialogue_mode():
		return
	_mechanic_dialogue.complete_dialogue()


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
	map_button.disabled = false
	if not _paused and not failure_overlay.visible:
		board.call("set_interaction_enabled", true)
		_resume_timer()


func _process(delta: float) -> void:
	if _timer_running:
		_update_timer_label()
	_craft_time += delta
	var target_speed := 0.19 if _warp_active else 0.055
	_nebula_speed = move_toward(
		_nebula_speed,
		target_speed,
		delta * (0.22 if _warp_active else 0.10)
	)
	var nebula_material := $Background.material as ShaderMaterial
	if nebula_material != null:
		nebula_material.set_shader_parameter("flow_speed", _nebula_speed)
	var flight_position := Vector2(
		202.0 + (24.0 if _warp_active else 0.0),
		505.0 + sin(_craft_time * 1.45) * 4.0
	)
	craft_root.position = flight_position
	var target_rotation := (
		-0.075
		if _warp_active
		else sin(_craft_time * 0.82) * 0.018
	)
	craft_root.rotation = lerp_angle(
		craft_root.rotation,
		target_rotation,
		minf(1.0, delta * 4.0)
	)


func _unhandled_input(event: InputEvent) -> void:
	if not _active_mechanic_guide_id.is_empty() \
			and event.is_action_pressed("ui_cancel"):
		_set_paused(not _paused)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not _paused)
		get_viewport().set_input_as_handled()


func _start_new_universe() -> void:
	_set_paused(false)
	failure_overlay.visible = false
	_regions = 0
	_purified_stars = 0
	_distance = 0
	_elapsed_ms = 0
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true
	board.new_expedition()
	if not _active_mechanic_guide_id.is_empty():
		call_deferred("_refresh_active_mechanic_guide_target")
	_refresh_stats()
	_update_timer_label()


func _refresh_active_mechanic_guide_target() -> void:
	if _active_mechanic_guide_id.is_empty() \
			or not _mechanic_dialogue.is_dialogue_mode():
		return
	var target_position: Vector2 = board.call(
		"get_mechanic_guide_target_global_position",
		_active_mechanic_guide_id
	)
	_mechanic_dialogue.set_dialogue_target_global_position(target_position)


func _restart_from_pause() -> void:
	_set_paused(false)
	_start_new_universe()


func _set_paused(value: bool) -> void:
	_paused = value
	pause_overlay.visible = value
	board.process_mode = (
		Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	)
	board.call("set_interaction_enabled", not value)
	if value:
		_pause_timer()
		resume_button.grab_focus()
	elif not failure_overlay.visible:
		_resume_timer()


func _on_warp_changed(active: bool) -> void:
	_warp_active = active
	parallax_stars.call("set_warp_active", active)


func _on_shield_changed(remaining: int, capacity: int) -> void:
	shield_label.text = "航行护盾\n%d/%d" % [remaining, capacity]


func _on_flags_changed(used_flags: int, total_mines: int) -> void:
	flags_label.text = "污染标记 %d/%d" % [used_flags, total_mines]


func _on_voyage_stats_changed(
	regions: int,
	purified_stars: int,
	distance: int
) -> void:
	_regions = regions
	_purified_stars = purified_stars
	_distance = distance
	_refresh_stats()


func _on_expedition_failed(
	regions: int,
	purified_stars: int,
	distance: int
) -> void:
	_regions = regions
	_purified_stars = purified_stars
	_distance = distance
	_pause_timer()
	AudioManager.play_fail()
	_refresh_stats()
	failure_summary.text = (
		"本次远征抵达 %d 光年\n净化星云 %d 片 · 净化星核 %d 颗"
		% [distance, regions, purified_stars]
	)
	failure_overlay.visible = true
	new_universe_button.grab_focus()


func _refresh_stats() -> void:
	regions_label.text = "已净化星云\n%d" % _regions
	stars_label.text = "净化星核\n%d" % _purified_stars
	distance_label.text = "航行距离\n%d 光年" % _distance
	disturbance_label.text = "宇宙扰动\n%d/5" % clampi(
		1 + int(_regions / 2),
		1,
		5
	)


func _pause_timer() -> void:
	if not _timer_running:
		return
	_elapsed_ms += int(Time.get_ticks_msec()) - _segment_started_ms
	_timer_running = false
	_update_timer_label()


func _resume_timer() -> void:
	if _timer_running:
		return
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true


func _update_timer_label() -> void:
	var elapsed := _elapsed_ms
	if _timer_running:
		elapsed += int(Time.get_ticks_msec()) - _segment_started_ms
	var hours := int(elapsed / 3600000)
	var minutes := int(elapsed / 60000) % 60
	var seconds := int(elapsed / 1000) % 60
	timer_label.text = "%02d:%02d:%02d" % [hours, minutes, seconds]


func _apply_interface_style() -> void:
	var font := load(ART.UI_FONT) as Font
	var paper_panel := _make_paper_panel(
		Color(0.055, 0.09, 0.18, 0.78),
		Color("7186a4"),
		12
	)
	var pale_panel := _make_paper_panel(
		Color(0.07, 0.10, 0.21, 0.97),
		Color("8d79a5"),
		12
	)
	for panel in [$Header, $LeftPanel, $RightPanel, $StatusPanel]:
		panel.add_theme_stylebox_override("panel", paper_panel.duplicate())
	$BoardFrame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	$PauseOverlay/PausePanel.add_theme_stylebox_override(
		"panel",
		pale_panel.duplicate()
	)
	$FailureOverlay/FailurePanel.add_theme_stylebox_override(
		"panel",
		pale_panel.duplicate()
	)
	for label in [
		%TitleLabel,
		%SubtitleLabel,
		regions_label,
		stars_label,
		distance_label,
		disturbance_label,
		shield_label,
		flags_label,
		status_label,
		timer_label,
		failure_summary,
		%PauseTitle,
		$FailureOverlay/FailurePanel/FailureVBox/FailureTitle,
		$RightPanel/RightMargin/Controls/RuleLabel,
	]:
		label.add_theme_font_override("font", font)
	%TitleLabel.add_theme_color_override("font_color", Color("c8ebf5"))
	%SubtitleLabel.add_theme_color_override("font_color", Color("91a9c0"))
	for label in [regions_label, stars_label, distance_label]:
		label.add_theme_color_override("font_color", Color("a9dbe4"))
	flags_label.add_theme_color_override("font_color", Color("efc76f"))
	shield_label.add_theme_color_override("font_color", Color("8ed8ff"))
	disturbance_label.add_theme_color_override("font_color", Color("c6a4f0"))
	status_label.add_theme_color_override("font_color", Color("b9e2ec"))
	timer_label.add_theme_color_override("font_color", Color("c8ebf5"))
	%PauseTitle.add_theme_color_override("font_color", Color("c8ebf5"))
	failure_summary.add_theme_color_override("font_color", Color("bfd3e2"))
	$FailureOverlay/FailurePanel/FailureVBox/FailureTitle.add_theme_color_override(
		"font_color",
		Color("f09bc3")
	)
	$RightPanel/RightMargin/Controls/RuleLabel.add_theme_color_override(
		"font_color",
		Color("94adbd")
	)
	var normal_style := _make_paper_button_style(ART.MENU_SECONDARY_NORMAL)
	var hover_style := _make_paper_button_style(ART.MENU_SECONDARY_HOVER)
	var pressed_style := _make_paper_button_style(ART.MENU_SECONDARY_PRESSED)
	for button in [
		pause_button,
		restart_button,
		map_button,
		resume_button,
		pause_restart_button,
		pause_settings_button,
		pause_main_menu_button,
		pause_exit_button,
		new_universe_button,
		failure_map_button,
	]:
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("31583f"))
		button.add_theme_color_override("font_hover_color", Color("193f33"))
		button.add_theme_color_override("font_pressed_color", Color("193f33"))
		button.add_theme_color_override("font_focus_color", Color("193f33"))
		button.add_theme_stylebox_override("normal", normal_style.duplicate())
		button.add_theme_stylebox_override("hover", hover_style.duplicate())
		button.add_theme_stylebox_override("pressed", pressed_style.duplicate())
		button.add_theme_stylebox_override("focus", hover_style.duplicate())


func _make_paper_panel(
	background: Color,
	border: Color,
	corner_radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


func _make_paper_button_style(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style
