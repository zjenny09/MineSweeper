class_name GreenSweeperSaveStore
extends RefCounted

const SCHEMA_VERSION := 3
const LEGACY_SCHEMA_VERSION := 1
const SCAN_SCHEMA_VERSION := 2
const DEFAULT_SAVE_PATH := "user://save_v1.json"
const SCAN_CAPACITY := 12
const WINDOW_MODE_WINDOWED := 0
const WINDOW_MODE_MAXIMIZED := 1
const WINDOW_MODE_FULLSCREEN := 2
const OPERATION_MODE_MOUSE := 0
const OPERATION_MODE_KEYBOARD := 1

var _save_path: String
var _data: Dictionary


func _init(save_path: String = DEFAULT_SAVE_PATH) -> void:
	_save_path = save_path
	_data = _make_default_data()


func load_data() -> Dictionary:
	_data = _make_default_data()
	var loaded := _read_normalized_file(_save_path)
	if loaded.is_empty():
		loaded = _read_normalized_file(_save_path + ".bak")
	if not loaded.is_empty():
		_data = loaded
	return get_data()


func save_data() -> bool:
	var normalized := _normalize_data(_data)
	var temporary_path := _save_path + ".tmp"
	var parent_path := ProjectSettings.globalize_path(_save_path.get_base_dir())
	if not DirAccess.dir_exists_absolute(parent_path):
		if DirAccess.make_dir_recursive_absolute(parent_path) != OK:
			return false

	if FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))

	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalized))
	file.close()

	var validation_file := FileAccess.open(temporary_path, FileAccess.READ)
	if validation_file == null:
		_remove_file(temporary_path)
		return false
	var json := JSON.new()
	var parse_error := json.parse(validation_file.get_as_text())
	validation_file.close()
	if parse_error != OK or not _is_valid_serialized_data(json.data):
		_remove_file(temporary_path)
		return false

	var backup_path := _save_path + ".bak"
	var absolute_save_path := ProjectSettings.globalize_path(_save_path)
	var absolute_temporary_path := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup_path := ProjectSettings.globalize_path(backup_path)
	var had_previous_save := FileAccess.file_exists(_save_path)
	if had_previous_save:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup_path)
		if DirAccess.rename_absolute(absolute_save_path, absolute_backup_path) != OK:
			_remove_file(temporary_path)
			return false
	if DirAccess.rename_absolute(absolute_temporary_path, absolute_save_path) != OK:
		if had_previous_save:
			DirAccess.rename_absolute(absolute_backup_path, absolute_save_path)
		_remove_file(temporary_path)
		return false

	_data = normalized
	return true


func get_data() -> Dictionary:
	return _data.duplicate(true)


func mark_level_started(number: int) -> void:
	if _is_valid_level(number):
		_data["last_played_level"] = number


func record_completion(number: int, elapsed_ms: int) -> void:
	if not _is_valid_level(number) or elapsed_ms < 0:
		return
	var key := str(number)
	var level_data: Dictionary = _data["levels"][key]
	level_data["completed"] = true
	var previous_best: int = level_data["best_time_ms"]
	if previous_best < 0 or elapsed_ms < previous_best:
		level_data["best_time_ms"] = elapsed_ms
	_data["last_played_level"] = number


func is_level_unlocked(number: int) -> bool:
	if not _is_valid_level(number):
		return false
	if number == 1 or number >= 6:
		return true
	return is_level_completed(number - 1)


func is_level_completed(number: int) -> bool:
	if not _is_valid_level(number):
		return false
	return bool(_data["levels"][str(number)]["completed"])


func get_best_time_ms(number: int) -> int:
	if not _is_valid_level(number):
		return -1
	return int(_data["levels"][str(number)]["best_time_ms"])


func get_last_played_level() -> int:
	return int(_data["last_played_level"])


func has_seen_first_move_guide() -> bool:
	return bool(_data["first_move_guide_seen"])


func mark_first_move_guide_seen() -> void:
	_data["first_move_guide_seen"] = true


func get_scan_energy() -> int:
	return int(_data["scan"]["energy"])


func set_scan_energy(value: int) -> void:
	_data["scan"]["energy"] = clampi(value, 0, SCAN_CAPACITY)


func has_claimed_level_one_scan_grant() -> bool:
	return bool(_data["scan"]["level_one_grant_claimed"])


func claim_level_one_scan_grant() -> bool:
	if has_claimed_level_one_scan_grant():
		return false
	_data["scan"]["level_one_grant_claimed"] = true
	_data["scan"]["energy"] = SCAN_CAPACITY
	return true


func set_master_volume(value: float) -> void:
	if is_finite(value):
		_data["settings"]["master_volume"] = clampf(value, 0.0, 1.0)
	else:
		_data["settings"]["master_volume"] = 1.0


func set_fullscreen(value: bool) -> void:
	set_window_mode(WINDOW_MODE_FULLSCREEN if value else WINDOW_MODE_MAXIMIZED)


func set_window_mode(value: int) -> void:
	var mode := value if value >= WINDOW_MODE_WINDOWED and value <= WINDOW_MODE_FULLSCREEN else WINDOW_MODE_MAXIMIZED
	_data["settings"]["window_mode"] = mode
	_data["settings"]["fullscreen"] = mode == WINDOW_MODE_FULLSCREEN


func set_operation_mode(value: int) -> void:
	var mode := value if value >= OPERATION_MODE_MOUSE and value <= OPERATION_MODE_KEYBOARD else OPERATION_MODE_MOUSE
	_data["settings"]["operation_mode"] = mode


func get_master_volume() -> float:
	return float(_data["settings"]["master_volume"])


func get_window_mode() -> int:
	return int(_data["settings"]["window_mode"])


func get_operation_mode() -> int:
	return int(_data["settings"]["operation_mode"])


func is_fullscreen() -> bool:
	return get_window_mode() == WINDOW_MODE_FULLSCREEN


func _read_normalized_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not _is_valid_serialized_data(json.data):
		return {}
	return _normalize_data(json.data as Dictionary)


func _make_default_data() -> Dictionary:
	var levels := {}
	for level in GreenSweeperLevels.LEVELS:
		levels[str(int(level["number"]))] = {
			"completed": false,
			"best_time_ms": -1,
		}
	return {
		"schema_version": SCHEMA_VERSION,
		"last_played_level": 0,
		"first_move_guide_seen": false,
		"scan": {
			"energy": 0,
			"level_one_grant_claimed": false,
		},
		"levels": levels,
		"settings": {
			"master_volume": 1.0,
			"fullscreen": false,
			"window_mode": WINDOW_MODE_MAXIMIZED,
			"operation_mode": OPERATION_MODE_MOUSE,
		},
	}


func _normalize_data(source: Dictionary) -> Dictionary:
	var normalized := _make_default_data()
	var source_schema := _normalized_int(
		source.get("schema_version"),
		LEGACY_SCHEMA_VERSION
	)

	var last_played := _normalized_int(source.get("last_played_level"), 0)
	var can_restore_last_played := (
		_is_valid_level(last_played)
		if source_schema == SCHEMA_VERSION
		else last_played >= 1 and last_played <= 5
	)
	if last_played == 0 or can_restore_last_played:
		normalized["last_played_level"] = last_played

	var guide_seen = source.get("first_move_guide_seen")
	if guide_seen is bool:
		normalized["first_move_guide_seen"] = guide_seen
	else:
		# Older saves predate this field. Any recorded play means the guide
		# must stay dismissed after upgrading.
		normalized["first_move_guide_seen"] = last_played != 0

	var source_scan = source.get("scan")
	if source_scan is Dictionary:
		var scan_energy := _normalized_int(source_scan.get("energy"), 0)
		normalized["scan"]["energy"] = clampi(scan_energy, 0, SCAN_CAPACITY)
		var grant_claimed = source_scan.get("level_one_grant_claimed")
		if grant_claimed is bool:
			normalized["scan"]["level_one_grant_claimed"] = grant_claimed

	var source_levels = source.get("levels")
	if source_levels is Dictionary:
		var migratable_levels := (
			GreenSweeperLevels.PLAYABLE_LEVELS
			if source_schema == SCHEMA_VERSION
			else GreenSweeperLevels.LAND_LEVELS
		)
		for level in migratable_levels:
			var key := str(int(level["number"]))
			var source_level = source_levels.get(key)
			if not source_level is Dictionary:
				continue
			var completed: Variant = source_level.get("completed")
			var best_time := _normalized_int(source_level.get("best_time_ms"), -1)
			if completed is bool and completed and best_time >= 0:
				normalized["levels"][key]["completed"] = true
				normalized["levels"][key]["best_time_ms"] = best_time

	var source_settings = source.get("settings")
	if source_settings is Dictionary:
		var volume = source_settings.get("master_volume")
		if (typeof(volume) == TYPE_INT or typeof(volume) == TYPE_FLOAT) and is_finite(float(volume)):
			normalized["settings"]["master_volume"] = clampf(float(volume), 0.0, 1.0)
		var mode := _normalized_int(source_settings.get("window_mode"), -1)
		if mode < WINDOW_MODE_WINDOWED or mode > WINDOW_MODE_FULLSCREEN:
			var legacy_fullscreen = source_settings.get("fullscreen")
			mode = WINDOW_MODE_FULLSCREEN if legacy_fullscreen is bool and legacy_fullscreen else WINDOW_MODE_MAXIMIZED
		normalized["settings"]["window_mode"] = mode
		normalized["settings"]["fullscreen"] = mode == WINDOW_MODE_FULLSCREEN
		var operation_mode := _normalized_int(
			source_settings.get("operation_mode"),
			OPERATION_MODE_MOUSE
		)
		if operation_mode < OPERATION_MODE_MOUSE or operation_mode > OPERATION_MODE_KEYBOARD:
			operation_mode = OPERATION_MODE_MOUSE
		normalized["settings"]["operation_mode"] = operation_mode

	return normalized


func _is_valid_serialized_data(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var serialized: Dictionary = value
	var schema_version := _normalized_int(serialized.get("schema_version"), -1)
	if schema_version not in [
		LEGACY_SCHEMA_VERSION,
		SCAN_SCHEMA_VERSION,
		SCHEMA_VERSION,
	]:
		return false

	var last_played := _normalized_int(serialized.get("last_played_level"), -1)
	var valid_last_played := (
		last_played == 0 or _is_valid_level(last_played)
		if schema_version == SCHEMA_VERSION
		else last_played >= 0 and last_played <= 6
	)
	if not valid_last_played:
		return false
	if serialized.has("first_move_guide_seen") \
			and not serialized.get("first_move_guide_seen") is bool:
		return false
	if schema_version >= SCAN_SCHEMA_VERSION:
		var scan = serialized.get("scan")
		if not scan is Dictionary:
			return false
		var scan_energy := _normalized_int(scan.get("energy"), -1)
		if scan_energy < 0 or scan_energy > SCAN_CAPACITY:
			return false
		if not scan.get("level_one_grant_claimed") is bool:
			return false

	var levels = serialized.get("levels")
	if not levels is Dictionary:
		return false
	var required_levels := (
		GreenSweeperLevels.PLAYABLE_LEVELS
		if schema_version == SCHEMA_VERSION
		else GreenSweeperLevels.LAND_LEVELS
	)
	for level in required_levels:
		var key := str(int(level["number"]))
		var entry = levels.get(key)
		if not entry is Dictionary or not entry.get("completed") is bool:
			return false
		var best_time := _normalized_int(entry.get("best_time_ms"), -2)
		if entry["completed"]:
			if best_time < 0:
				return false
		elif best_time != -1:
			return false

	var settings = serialized.get("settings")
	if not settings is Dictionary:
		return false
	var volume = settings.get("master_volume")
	if not (typeof(volume) == TYPE_INT or typeof(volume) == TYPE_FLOAT):
		return false
	if not is_finite(float(volume)) or float(volume) < 0.0 or float(volume) > 1.0:
		return false
	if not settings.get("fullscreen") is bool:
		return false
	if settings.has("window_mode"):
		var mode := _normalized_int(settings.get("window_mode"), -1)
		if mode < WINDOW_MODE_WINDOWED or mode > WINDOW_MODE_FULLSCREEN:
			return false
	if settings.has("operation_mode"):
		var operation_mode := _normalized_int(settings.get("operation_mode"), -1)
		if operation_mode < OPERATION_MODE_MOUSE or operation_mode > OPERATION_MODE_KEYBOARD:
			return false
	return true


func _normalized_int(value: Variant, fallback: int) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)):
		var rounded := roundi(float(value))
		if is_equal_approx(float(value), float(rounded)):
			return rounded
	return fallback


func _is_valid_level(number: int) -> bool:
	for level in GreenSweeperLevels.LEVELS:
		if int(level["number"]) == number:
			return true
	return false


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
