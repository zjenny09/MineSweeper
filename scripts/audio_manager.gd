extends Node

const AUDIO_ROOT := "res://assets/audio/"
const BGM_STREAMS := {
	&"menu": preload("res://assets/audio/menu_select_bgm.wav"),
	&"land": preload("res://assets/audio/forest_papercut_bgm.wav"),
	&"ocean": preload("res://assets/audio/ocean_papercut_bgm.wav"),
	&"sky": preload("res://assets/audio/sky_papercut_bgm.wav"),
	&"universe": preload("res://assets/audio/sky_papercut_bgm.wav"),
}
const BGM_VOLUMES := {
	&"menu": 0.76,
	&"land": 0.80,
	&"ocean": 0.78,
	&"sky": 0.78,
	&"universe": 0.72,
}
const MENU_SELECT_PATH := AUDIO_ROOT + "sfx_menu_select.wav"
const MENU_BACK_PATH := AUDIO_ROOT + "sfx_menu_back.wav"
const OCEAN_REVEAL_PATH := AUDIO_ROOT + "sfx_clear_bubbles.wav"
const SKY_REVEAL_PATH := AUDIO_ROOT + "sfx_menu_select.wav"
const SKY_BREEZE_PATH := AUDIO_ROOT + "sfx_sky_wind.wav"
const LAND_WIN_PATH := AUDIO_ROOT + "sfx_win_flower_SUCCESS.wav"
const OCEAN_WIN_PATH := AUDIO_ROOT + "sfx_win_ocean_SUCCESS.wav"
const SKY_WIN_PATH := AUDIO_ROOT + "sfx_win_sky_SUCCESS.wav"
const FAIL_PATH := AUDIO_ROOT + "sfx_fail.wav"

var bgm_enabled := true
var sfx_enabled := true

var _bgm_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _gameplay_player: AudioStreamPlayer
var _result_player: AudioStreamPlayer
var _desired_bgm := &""
var _current_bgm := &""
var _bgm_restart_cooldown := 0.0
var _stream_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player = _create_player("BackgroundMusic")
	_bgm_player.finished.connect(_on_bgm_finished)
	_ui_player = _create_player("InterfaceSfx")
	_gameplay_player = _create_player("GameplaySfx")
	_result_player = _create_player("ResultSfx")
	get_tree().node_added.connect(_on_node_added)
	set_process(true)
	call_deferred("_bind_existing_buttons")


func _process(delta: float) -> void:
	if not bgm_enabled or _desired_bgm.is_empty() or _bgm_player.playing:
		_bgm_restart_cooldown = 0.0
		return
	_bgm_restart_cooldown -= maxf(0.0, delta)
	if _bgm_restart_cooldown <= 0.0:
		_bgm_restart_cooldown = 1.0
		play_bgm(_desired_bgm)


func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	if not bgm_enabled:
		_bgm_player.stop()
	elif not _desired_bgm.is_empty():
		play_bgm(_desired_bgm)


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if sfx_enabled:
		return
	_ui_player.stop()
	_gameplay_player.stop()
	_result_player.stop()


func play_menu_bgm() -> void:
	play_bgm(&"menu")


func play_universe_bgm() -> void:
	play_bgm(&"universe")


func play_level_bgm(level_number: int) -> void:
	if level_number >= 15 and level_number <= 21:
		play_bgm(&"sky")
	elif level_number >= 8 and level_number <= 14:
		play_bgm(&"ocean")
	elif level_number >= 1 and level_number <= 7:
		play_bgm(&"land")
	else:
		stop_bgm()


func play_bgm(track: StringName) -> void:
	_desired_bgm = track
	if track.is_empty():
		stop_bgm()
		return
	if not bgm_enabled:
		return
	if _current_bgm == track and _bgm_player.playing:
		return
	var stream := BGM_STREAMS.get(track) as AudioStream
	if stream == null:
		stop_bgm()
		push_error("Background music stream is unavailable: %s" % track)
		return
	_current_bgm = track
	_bgm_player.stop()
	_bgm_player.stream = stream
	_bgm_player.stream_paused = false
	_bgm_player.volume_db = linear_to_db(float(BGM_VOLUMES.get(track, 0.62)))
	_bgm_player.play(0.0)


func stop_bgm() -> void:
	_desired_bgm = &""
	_current_bgm = &""
	_bgm_player.stop()


func _on_bgm_finished() -> void:
	if bgm_enabled and not _desired_bgm.is_empty():
		play_bgm(_desired_bgm)


func play_menu_select() -> void:
	_play_sfx(_ui_player, MENU_SELECT_PATH, 0.78)


func play_menu_back() -> void:
	_play_sfx(_ui_player, MENU_BACK_PATH, 0.76)


func play_ocean_reveal() -> void:
	_play_sfx(_gameplay_player, OCEAN_REVEAL_PATH, 0.78)


func play_sky_reveal() -> void:
	_play_sfx(_gameplay_player, SKY_REVEAL_PATH, 0.62)


func play_sky_breeze() -> void:
	_play_sfx(_gameplay_player, SKY_BREEZE_PATH, 0.72)


func play_level_win(level_number: int) -> void:
	var path := LAND_WIN_PATH
	if level_number >= 15:
		path = SKY_WIN_PATH
	elif level_number >= 8:
		path = OCEAN_WIN_PATH
	_play_sfx(_result_player, path, 0.9)


func play_fail() -> void:
	_play_sfx(_result_player, FAIL_PATH, 0.88)


func _create_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Master"
	player.max_polyphony = 1
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _play_sfx(
	player: AudioStreamPlayer,
	path: String,
	linear_volume: float
) -> void:
	if not sfx_enabled:
		return
	var stream := _load_audio_stream(path)
	if stream == null:
		return
	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(linear_volume)
	player.play()


func _load_audio_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path] as AudioStream
	var stream := load(path) as AudioStream
	if stream == null:
		push_error("Audio stream could not be loaded: %s" % path)
		return null
	_stream_cache[path] = stream
	return stream


func _on_node_added(node: Node) -> void:
	if node is Button:
		_bind_button(node as Button)


func _bind_existing_buttons() -> void:
	_bind_buttons_below(get_tree().root)


func _bind_buttons_below(node: Node) -> void:
	if node is Button:
		_bind_button(node as Button)
	for child in node.get_children():
		_bind_buttons_below(child)


func _bind_button(button: Button) -> void:
	if button is MineCell \
			or button.name in [&"BgmToggleButton", &"SfxToggleButton"] \
			or button.has_meta("ui_sfx_bound"):
		return
	button.set_meta("ui_sfx_bound", true)
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_pressed(button: Button) -> void:
	if _is_back_button(button):
		play_menu_back()
	else:
		play_menu_select()


func _is_back_button(button: Button) -> bool:
	var description := "%s %s %s" % [
		button.name,
		button.text,
		button.tooltip_text,
	]
	description = description.to_lower()
	for token in [
		"back", "resume", "cancel", "close", "exit", "mainmenu",
		"返回", "关闭", "取消", "退出", "继续航行", "继续游戏",
	]:
		if description.contains(token):
			return true
	return false
