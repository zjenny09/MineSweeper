extends SceneTree

const SaveStore = preload("../scripts/save_store.gd")
const TEST_PATH := "user://green_sweeper_save_test.json"
const TEMP_PATH := TEST_PATH + ".tmp"
const BACKUP_PATH := TEST_PATH + ".bak"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_cleanup()
	_test_defaults()
	_test_save_and_load()
	_test_backup_recovery()
	_test_structural_corruption_uses_backup()
	_test_corrupt_file_falls_back()
	_test_unlocking()
	_test_best_time_only_improves()
	_test_settings_limits()
	_cleanup()

	if _failures.is_empty():
		print("GreenSweeperSaveStore: all tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_defaults() -> void:
	var store = SaveStore.new(TEST_PATH)
	var data: Dictionary = store.get_data()
	_check(data["schema_version"] == 1, "default schema version should be 1")
	_check(store.get_last_played_level() == 0, "default last played level should be 0")
	_check(data["levels"].size() == 6, "defaults should contain all six levels")
	for number in range(1, 7):
		_check(not store.is_level_completed(number), "level %d should default to incomplete" % number)
		_check(store.get_best_time_ms(number) == -1, "level %d should default to no best time" % number)
	_check(is_equal_approx(store.get_master_volume(), 1.0), "default volume should be 1")
	_check(not store.is_fullscreen(), "fullscreen should default to false")


func _test_save_and_load() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.mark_level_started(2)
	store.record_completion(1, 4200)
	store.mark_level_started(2)
	store.set_master_volume(0.35)
	store.set_fullscreen(true)
	_check(store.save_data(), "save_data should succeed")

	var loaded = SaveStore.new(TEST_PATH)
	loaded.load_data()
	_check(loaded.get_last_played_level() == 2, "last played level should persist")
	_check(loaded.is_level_completed(1), "completion should persist")
	_check(loaded.get_best_time_ms(1) == 4200, "best time should persist")
	_check(is_equal_approx(loaded.get_master_volume(), 0.35), "volume should persist")
	_check(loaded.is_fullscreen(), "fullscreen should persist")


func _test_backup_recovery() -> void:
	_cleanup()
	var store = SaveStore.new(TEST_PATH)
	store.record_completion(1, 3600)
	_check(store.save_data(), "backup fixture should save")
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEST_PATH),
		ProjectSettings.globalize_path(BACKUP_PATH)
	)
	_check(rename_error == OK, "backup fixture should simulate an interrupted replacement")
	var recovered = SaveStore.new(TEST_PATH)
	recovered.load_data()
	_check(recovered.is_level_completed(1), "a missing primary save should recover from backup")
	_check(recovered.get_best_time_ms(1) == 3600, "backup recovery should preserve the best time")
	recovered.record_completion(2, 4800)
	_check(recovered.save_data(), "saving after backup recovery should succeed")
	_check(FileAccess.file_exists(TEST_PATH), "saving after recovery should create a new primary file")
	_check(FileAccess.file_exists(BACKUP_PATH), "saving after recovery should preserve the only prior backup")
	var saved_again = SaveStore.new(TEST_PATH)
	saved_again.load_data()
	_check(saved_again.is_level_completed(2), "the new primary should contain progress saved after recovery")
	_cleanup()


func _test_structural_corruption_uses_backup() -> void:
	_cleanup()
	var store = SaveStore.new(TEST_PATH)
	store.record_completion(1, 5100)
	_check(store.save_data(), "structural corruption fixture should create its first save")
	store.set_master_volume(0.6)
	_check(store.save_data(), "structural corruption fixture should create a backup")
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_check(file != null, "structurally corrupt fixture should open")
	if file != null:
		file.store_string('{"schema_version":1}')
		file.close()
	var recovered = SaveStore.new(TEST_PATH)
	recovered.load_data()
	_check(recovered.is_level_completed(1), "an incomplete primary structure should fall back to the valid backup")
	_check(recovered.get_best_time_ms(1) == 5100, "structural backup recovery should preserve progress")
	_cleanup()


func _test_corrupt_file_falls_back() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_check(file != null, "corrupt-file fixture should open")
	if file != null:
		file.store_string("{not valid json")
		file.close()
	var store = SaveStore.new(TEST_PATH)
	store.load_data()
	_check(store.get_last_played_level() == 0, "corrupt data should reset last played level")
	_check(not store.is_level_completed(1), "corrupt data should reset completion")
	_check(is_equal_approx(store.get_master_volume(), 1.0), "corrupt data should reset settings")


func _test_unlocking() -> void:
	var store = SaveStore.new(TEST_PATH)
	_check(store.is_level_unlocked(1), "first level should always be unlocked")
	_check(not store.is_level_unlocked(2), "second level should initially be locked")
	store.record_completion(1, 1000)
	_check(store.is_level_unlocked(2), "completing level 1 should unlock level 2")
	_check(not store.is_level_unlocked(3), "level 3 should remain locked")
	_check(not store.is_level_unlocked(0), "invalid level should not be unlocked")
	_check(not store.is_level_unlocked(7), "out-of-range level should not be unlocked")


func _test_best_time_only_improves() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.record_completion(1, 5000)
	store.record_completion(1, 7000)
	_check(store.get_best_time_ms(1) == 5000, "slower completion should not replace best time")
	store.record_completion(1, 3000)
	_check(store.get_best_time_ms(1) == 3000, "faster completion should replace best time")


func _test_settings_limits() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.set_master_volume(-0.5)
	_check(is_equal_approx(store.get_master_volume(), 0.0), "volume should clamp at 0")
	store.set_master_volume(1.5)
	_check(is_equal_approx(store.get_master_volume(), 1.0), "volume should clamp at 1")
	store.set_fullscreen(true)
	_check(store.is_fullscreen(), "fullscreen setter should accept true")
	store.set_fullscreen(false)
	_check(not store.is_fullscreen(), "fullscreen setter should accept false")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup() -> void:
	for path in [TEST_PATH, TEMP_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
