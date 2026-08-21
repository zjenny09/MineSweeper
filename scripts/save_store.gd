class_name GreenSweeperSaveStore
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_SAVE_PATH := "user://save_v1.json"

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
	if number == 1:
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


func set_master_volume(value: float) -> void:
	if is_finite(value):
		_data["settings"]["master_volume"] = clampf(value, 0.0, 1.0)
	else:
		_data["settings"]["master_volume"] = 1.0


func set_fullscreen(value: bool) -> void:
	_data["settings"]["fullscreen"] = value


func get_master_volume() -> float:
	return float(_data["settings"]["master_volume"])


func is_fullscreen() -> bool:
	return bool(_data["settings"]["fullscreen"])


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
		"levels": levels,
		"settings": {
			"master_volume": 1.0,
			"fullscreen": false,
		},
	}


func _normalize_data(source: Dictionary) -> Dictionary:
	var normalized := _make_default_data()

	var last_played := _normalized_int(source.get("last_played_level"), 0)
	if last_played == 0 or _is_valid_level(last_played):
		normalized["last_played_level"] = last_played

	var source_levels = source.get("levels")
	if source_levels is Dictionary:
		for level in GreenSweeperLevels.LEVELS:
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
		var fullscreen = source_settings.get("fullscreen")
		if fullscreen is bool:
			normalized["settings"]["fullscreen"] = fullscreen

	return normalized


func _is_valid_serialized_data(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var serialized: Dictionary = value
	if _normalized_int(serialized.get("schema_version"), -1) != SCHEMA_VERSION:
		return false

	var last_played := _normalized_int(serialized.get("last_played_level"), -1)
	if last_played != 0 and not _is_valid_level(last_played):
		return false

	var levels = serialized.get("levels")
	if not levels is Dictionary:
		return false
	for level in GreenSweeperLevels.LEVELS:
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
	return settings.get("fullscreen") is bool


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
