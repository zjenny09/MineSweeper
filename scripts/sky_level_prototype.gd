extends Control

signal level_started(level_number: int)
signal level_completed(level_number: int, elapsed_ms: int)
signal level_select_requested
signal chapter_advance_requested
signal main_menu_requested
signal settings_requested
signal exit_game_requested
signal pause_changed(is_paused: bool)
signal scan_energy_changed(energy: int)

const SKY_SPHERE_BOARD_SCRIPT := preload("res://scripts/sky_sphere_board.gd")
const LEVELS := preload("res://scripts/level_data.gd")
const ART := preload("res://scripts/art_catalog.gd")
const SCAN_CAPACITY := 12

enum ScanPhase {
	LOCKED_FIRST_REVEAL,
	CHARGING,
	READY,
	TARGETING,
	RESOLVING,
	FINISHED,
}

@export var auto_start := true

@onready var board_center := find_child("BoardCenter", true, false) as CenterContainer
@onready var board_host := find_child("Board", true, false) as Control
@onready var subtitle_label := find_child("SubtitleLabel", true, false) as Label
@onready var level_summary_label := find_child("LevelSummaryLabel", true, false) as Label
@onready var objective_label := find_child("ObjectiveLabel", true, false) as Label
@onready var instructions_label := find_child("InstructionsLabel", true, false) as Label
@onready var flags_label := find_child("FlagsLabel", true, false) as Label
@onready var status_label := find_child("StatusLabel", true, false) as Label
@onready var timer_label := find_child("TimerLabel", true, false) as Label
@onready var pause_button := find_child("PauseButton", true, false) as TextureButton
@onready var restart_button := find_child("RestartButton", true, false) as TextureButton
@onready var pause_overlay := find_child("PauseOverlay", true, false) as Control
@onready var resume_button := find_child("ResumeButton", true, false) as Button
@onready var pause_restart_button := find_child("PauseRestartButton", true, false) as Button
@onready var exit_game_button := find_child("ExitGameButton", true, false) as Button
@onready var level_select_button := find_child("LevelSelectButton", true, false) as Button
@onready var pause_settings_button := find_child("PauseSettingsButton", true, false) as Button
@onready var main_menu_button := find_child("MainMenuButton", true, false) as Button
@onready var restart_button_label := find_child("RestartButtonLabel", true, false) as Label
@onready var tabletop_actors := find_child("LandTabletopActors", true, false) as Control

var current_level_index := 14
var _sky_board: Control
var _elapsed_before_segment_ms := 0
var _segment_started_ms := 0
var _timer_running := false
var _paused := false
var _round_finished := false
var _round_started := false
var _gameplay_state := 0
var _scan_phase: int = ScanPhase.LOCKED_FIRST_REVEAL
var _scan_energy := 0
var _scan_target_global_position := Vector2.ZERO


func _ready() -> void:
	_prepare_copied_interface()
	_mount_sky_sphere()
	tabletop_actors.call("configure_for_sky")
	tabletop_actors.connect("scan_activation_requested", _request_scan_mode)
	_initialize_scan_ability()
	pause_button.pressed.connect(_set_paused.bind(true))
	restart_button.pressed.connect(_on_primary_button_pressed)
	resume_button.pressed.connect(_set_paused.bind(false))
	pause_restart_button.pressed.connect(_restart_from_pause)
	level_select_button.pressed.connect(_on_level_select_pressed)
	pause_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_game_button.pressed.connect(func() -> void: exit_game_requested.emit())
	set_process(true)
	if auto_start:
		start_level(14, 0)


func _prepare_copied_interface() -> void:
	var sky_background := find_child("SkyDeskBackground", true, false) as TextureRect
	var latest_background := _load_source_texture(ART.SKY_DESKTOP_BACKGROUND)
	if sky_background != null and latest_background != null:
		sky_background.texture = latest_background
	var sky_frame := find_child("SkyBoardFrame", true, false) as TextureRect
	var latest_frame := _load_source_texture(ART.SKY_BOARD_FRAME)
	if sky_frame != null and latest_frame != null:
		sky_frame.texture = latest_frame
	for node_name in [
		"SkyStage",
	]:
		(find_child(node_name, true, false) as CanvasItem).visible = true
	for node_name in [
		"OceanBoardPaper",
		"LandDeskBackground",
		"LevelOneBackground",
		"LandUnifiedShadow",
		"EcoShowcase",
		"FirstMoveGuide",
		"ScanFallbackRow",
	]:
		(find_child(node_name, true, false) as CanvasItem).visible = false
	for node_name in [
		"LeftDecorativeSprout",
		"LeftSproutVictoryDots",
		"LeftSproutGuardianLeftShadow",
		"LeftSproutGuardianRightShadow",
		"LeftSproutGuardianLeft",
		"LeftSproutGuardianRight",
		"BudSproutDecorationA",
		"RightGuardianAShadow",
		"RightGuardianBShadow",
		"RightGuardianA",
		"RightGuardianB",
	]:
		var node := find_child(node_name, true, false) as CanvasItem
		if node != null:
			node.visible = false
	_apply_ocean_button_art()
	subtitle_label.text = "第15关 · 云冠"
	level_summary_label.text = "12个五边形 + 20个六边形\n污染核心 6"
	objective_label.text = "旋转球面，净化全部安全面"
	instructions_label.text = (
		"拖拽旋转 · 左键净化 · 右键标记 · C扫描\n"
		+ "方向键选择 · WASD旋转 · Enter翻开 · F标记"
	)
	flags_label.text = "0/6"
	status_label.text = "旋转球面，寻找安全起点"
	pause_overlay.visible = false
	_update_timer_label()


func _load_source_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_texture := load(path) as Texture2D
		if imported_texture != null:
			return imported_texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _apply_ocean_button_art() -> void:
	pause_button.texture_normal = load(ART.OCEAN_PAUSE_NORMAL)
	pause_button.texture_hover = load(ART.OCEAN_PAUSE_HOVER)
	pause_button.texture_focused = load(ART.OCEAN_PAUSE_FOCUS)
	pause_button.texture_pressed = load(ART.OCEAN_PAUSE_PRESSED)
	restart_button.texture_normal = load(ART.OCEAN_REGENERATE_NORMAL)
	restart_button.texture_hover = load(ART.OCEAN_REGENERATE_HOVER)
	restart_button.texture_focused = load(ART.OCEAN_REGENERATE_FOCUS)
	restart_button.texture_pressed = load(ART.OCEAN_REGENERATE_PRESSED)
	(find_child("PauseButtonLabel", true, false) as Label).add_theme_color_override("font_color", Color("123f5e"))
	(find_child("RestartButtonLabel", true, false) as Label).add_theme_color_override("font_color", Color("123f5e"))


func _mount_sky_sphere() -> void:
	_sky_board = SKY_SPHERE_BOARD_SCRIPT.new() as Control
	_sky_board.custom_minimum_size = board_host.custom_minimum_size
	_sky_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sky_board.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	board_center.add_child(_sky_board)
	_sky_board.connect(
		"flags_changed",
		func(used_flags: int, max_flags: int) -> void:
			flags_label.text = "%d/%d" % [used_flags, max_flags]
	)
	_sky_board.connect(
		"status_changed",
		func(text: String) -> void:
			status_label.text = text
	)
	_sky_board.connect("first_reveal", _on_first_reveal)
	_sky_board.connect("scan_energy_earned", _award_scan_energy)
	_sky_board.connect("scan_target_requested", _on_scan_target_requested)
	_sky_board.connect("scan_cancel_requested", _cancel_scan_targeting)
	_sky_board.connect("scan_completed", _on_scan_completed)
	_sky_board.connect("gameplay_state_changed", _on_gameplay_state_changed)
	_sky_board.connect("boss_eye_hit", _on_boss_eye_hit)
	board_host.queue_free()


func start_level(level_index: int, initial_scan_energy: int = -1) -> void:
	current_level_index = clampi(
		level_index,
		14,
		LEVELS.PLAYABLE_LEVELS.size() - 1
	)
	var level: Dictionary = LEVELS.PLAYABLE_LEVELS[current_level_index]
	var level_number := int(level["number"])
	var core_count := int(level["core_count"])
	var face_count := int(level.get("face_count", 32))
	var structure_name := str(level.get("structure_name", "%d格云球" % face_count))
	var breeze_uses := int(level.get("breeze_assists", 0))
	var breeze_chance := float(level.get("breeze_trigger_chance", 0.0))
	var storm_guard_uses := int(level.get("storm_guard_assists", 0))
	var storm_guard_chance := float(level.get("storm_guard_trigger_chance", 0.0))
	var boss_eye_count := int(level.get("boss_eye_count", 0))
	_round_finished = false
	_round_started = false
	_gameplay_state = 0
	tabletop_actors.call("configure_for_sky", level_number)
	tabletop_actors.call("play_reaction", false, false)
	_set_paused(false)
	_reset_timer()
	if initial_scan_energy >= 0:
		_scan_energy = clampi(initial_scan_energy, 0, SCAN_CAPACITY)
	_sky_board.call(
		"configure_level",
		core_count,
		face_count,
		breeze_uses,
		breeze_chance,
		storm_guard_uses,
		storm_guard_chance,
		boss_eye_count
	)
	subtitle_label.text = "第%d关 · %s" % [level_number, str(level["name"])]
	level_summary_label.text = "%s · 共%d格\n污染核心 %d" % [
		structure_name,
		face_count,
		core_count,
	]
	objective_label.text = "旋转球面，净化全部安全面"
	if boss_eye_count > 0:
		objective_label.text = "追踪雷眼 · 正确标记周围污染并双击击破 0/%d" % boss_eye_count
	elif storm_guard_uses != 0:
		objective_label.text = "随机助益翻格或标雷 · 云盾保护概率拦截踩雷"
	elif breeze_uses != 0:
		objective_label.text = "净化时可能触发随机翻格或自动标雷"
	flags_label.text = "0/%d" % core_count
	status_label.text = "旋转球面，寻找安全起点"
	restart_button_label.text = "重新生成"
	_initialize_scan_ability()
	visible = true
	level_started.emit(level_number)


func set_operation_mode(_mode: int) -> void:
	pass


func set_first_move_guide_enabled(_enabled: bool) -> void:
	pass


func _process(_delta: float) -> void:
	if _timer_running:
		_update_timer_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
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
	if event.is_action_pressed("ui_cancel"):
		if _scan_phase == ScanPhase.TARGETING:
			_cancel_scan_targeting()
		else:
			_set_paused(not _paused)
		get_viewport().set_input_as_handled()


func _on_boss_eye_hit(
	_face_index: int,
	cleared_eyes: int,
	total_eyes: int
) -> void:
	objective_label.text = (
		"追踪雷眼 · 正确标记周围污染并双击击破 %d/%d"
		% [cleared_eyes, total_eyes]
	)


func _on_gameplay_state_changed(state: int) -> void:
	_gameplay_state = state
	_round_finished = state >= 2
	if not _round_finished:
		return
	_pause_timer()
	_finish_scan_ability()
	tabletop_actors.call("play_reaction", state == 2, state > 2)
	if state == 2:
		level_completed.emit(current_level_index + 1, _elapsed_before_segment_ms)
		restart_button_label.text = (
			"下一关"
			if current_level_index < LEVELS.PLAYABLE_LEVELS.size() - 1
			else "返回地图"
		)
	else:
		restart_button_label.text = "重新生成"


func _on_primary_button_pressed() -> void:
	if _gameplay_state == 2:
		if current_level_index < LEVELS.PLAYABLE_LEVELS.size() - 1:
			start_level(current_level_index + 1, _scan_energy)
		else:
			level_select_requested.emit()
		return
	_restart_sky_board()


func _on_level_select_pressed() -> void:
	_pause_timer()
	level_select_requested.emit()


func _on_main_menu_pressed() -> void:
	_pause_timer()
	main_menu_requested.emit()


func _restart_sky_board() -> void:
	_round_finished = false
	_round_started = false
	_gameplay_state = 0
	tabletop_actors.call("play_reaction", false, false)
	restart_button_label.text = "重新生成"
	var level: Dictionary = LEVELS.PLAYABLE_LEVELS[current_level_index]
	var boss_eye_count := int(level.get("boss_eye_count", 0))
	if boss_eye_count > 0:
		objective_label.text = (
			"追踪雷眼 · 正确标记周围污染并双击击破 0/%d"
			% boss_eye_count
		)
	_reset_timer()
	_sky_board.call("new_game")
	_initialize_scan_ability()


func _restart_from_pause() -> void:
	_set_paused(false)
	_restart_sky_board()


func _set_paused(value: bool) -> void:
	_paused = value
	pause_overlay.visible = value
	_sky_board.process_mode = (
		Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	)
	tabletop_actors.call("set_scan_paused", value)
	if value:
		_pause_timer()
	else:
		_resume_timer()
	pause_changed.emit(value)


func _on_first_reveal() -> void:
	_start_timer()
	if _scan_phase == ScanPhase.LOCKED_FIRST_REVEAL:
		_scan_phase = (
			ScanPhase.READY
			if _scan_energy >= SCAN_CAPACITY
			else ScanPhase.CHARGING
		)
	_refresh_scan_ui()


func _initialize_scan_ability() -> void:
	_scan_energy = clampi(_scan_energy, 0, SCAN_CAPACITY)
	_scan_phase = ScanPhase.LOCKED_FIRST_REVEAL
	_scan_target_global_position = Vector2.ZERO
	if is_instance_valid(_sky_board):
		_sky_board.call("set_scan_target_mode", false)
	tabletop_actors.call("finish_scan_visuals")
	_refresh_scan_ui()


func _award_scan_energy() -> void:
	if _scan_phase in [ScanPhase.FINISHED, ScanPhase.RESOLVING]:
		return
	_scan_energy = mini(SCAN_CAPACITY, _scan_energy + 1)
	scan_energy_changed.emit(_scan_energy)
	if _round_started:
		_scan_phase = (
			ScanPhase.READY
			if _scan_energy >= SCAN_CAPACITY
			else ScanPhase.CHARGING
		)
	_refresh_scan_ui()


func _request_scan_mode() -> void:
	if _scan_phase != ScanPhase.READY or _paused or _round_finished:
		_refresh_scan_ui()
		return
	_scan_phase = ScanPhase.TARGETING
	_sky_board.call("set_scan_target_mode", true)
	tabletop_actors.call("begin_scan_targeting")
	status_label.text = "选择一个隐藏格进行生态扫描"
	_refresh_scan_ui()


func _on_scan_target_requested(face_index: int) -> void:
	if _scan_phase != ScanPhase.TARGETING:
		return
	_scan_target_global_position = _sky_board.call(
		"get_face_global_position",
		face_index
	)
	_scan_phase = ScanPhase.RESOLVING
	var previous_energy := _scan_energy
	_scan_energy = 0
	scan_energy_changed.emit(_scan_energy)
	_refresh_scan_ui()
	if not bool(_sky_board.call("try_scan_face", face_index)):
		_scan_energy = previous_energy
		scan_energy_changed.emit(_scan_energy)
		_scan_phase = ScanPhase.TARGETING
		_refresh_scan_ui()


func _on_scan_completed(_face_index: int, result: int) -> void:
	_scan_phase = ScanPhase.FINISHED if _round_finished else ScanPhase.CHARGING
	tabletop_actors.call("play_scan_result", result, _scan_target_global_position)
	status_label.text = "扫描确认：污染核心" if result == 1 else "扫描确认：安全面"
	_refresh_scan_ui()


func _cancel_scan_targeting() -> void:
	if _scan_phase != ScanPhase.TARGETING:
		return
	_sky_board.call("set_scan_target_mode", false)
	_scan_phase = ScanPhase.READY
	tabletop_actors.call("cancel_scan_targeting")
	status_label.text = "净化进行中"
	_refresh_scan_ui()


func _finish_scan_ability() -> void:
	_sky_board.call("set_scan_target_mode", false)
	_scan_phase = ScanPhase.FINISHED
	tabletop_actors.call("finish_scan_visuals")
	_refresh_scan_ui()


func _refresh_scan_ui() -> void:
	var locked := _scan_phase == ScanPhase.LOCKED_FIRST_REVEAL
	var finished := _scan_phase == ScanPhase.FINISHED
	tabletop_actors.call(
		"set_scan_meter",
		_scan_energy,
		SCAN_CAPACITY,
		locked,
		finished,
		true
	)
	var enabled := (
		_scan_phase == ScanPhase.READY
		and not _paused
		and not _round_finished
	)
	var tooltip := "完成首次净化后可使用生态扫描"
	match _scan_phase:
		ScanPhase.CHARGING:
			tooltip = "扫描充能 %d/%d" % [_scan_energy, SCAN_CAPACITY]
		ScanPhase.READY:
			tooltip = "点击机器人或按 C，选择隐藏格扫描"
		ScanPhase.TARGETING:
			tooltip = "选择隐藏格；Esc、右键或 C 取消"
		ScanPhase.RESOLVING:
			tooltip = "正在扫描"
		ScanPhase.FINISHED:
			tooltip = "本局已经结束"
	tabletop_actors.call("set_scan_activation_enabled", enabled, tooltip)


func _start_timer() -> void:
	if _timer_running or _paused or _round_finished:
		return
	_round_started = true
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true


func _pause_timer() -> void:
	if not _timer_running:
		return
	_elapsed_before_segment_ms += int(Time.get_ticks_msec()) - _segment_started_ms
	_timer_running = false
	_update_timer_label()


func _resume_timer() -> void:
	if not _round_started or _round_finished:
		return
	_segment_started_ms = int(Time.get_ticks_msec())
	_timer_running = true


func _reset_timer() -> void:
	_elapsed_before_segment_ms = 0
	_segment_started_ms = 0
	_timer_running = false
	_update_timer_label()


func _update_timer_label() -> void:
	var elapsed_ms := _elapsed_before_segment_ms
	if _timer_running:
		elapsed_ms += int(Time.get_ticks_msec()) - _segment_started_ms
	var minutes := int(elapsed_ms / 60000)
	var seconds := int(elapsed_ms / 1000) % 60
	var tenths := int(elapsed_ms / 100) % 10
	timer_label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]
