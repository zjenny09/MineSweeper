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
	_test_schema_one_scan_migration()
	_test_schema_two_ocean_migration()
	_test_scan_limits_and_grant()
	_test_legacy_display_migration()
	_test_removed_level_migration()
	_test_backup_recovery()
	_test_structural_corruption_uses_backup()
	_test_corrupt_file_falls_back()
	_test_unlocking()
	_test_best_time_only_improves()
	_test_ocean_progress_persistence()
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
	_check(data["schema_version"] == 3, "default schema version should be 3")
	_check(store.get_last_played_level() == 0, "default last played level should be 0")
	_check(not store.has_seen_first_move_guide(), "new saves should show the first-move guide")
	_check(store.get_scan_energy() == 0, "new saves should start with empty scan energy")
	_check(not store.has_claimed_level_one_scan_grant(), "new saves should not pre-claim the level-one grant")
	_check(data["levels"].size() == 10, "defaults should contain all ten levels")
	for number in range(1, 11):
		_check(not store.is_level_completed(number), "level %d should default to incomplete" % number)
		_check(store.get_best_time_ms(number) == -1, "level %d should default to no best time" % number)
	_check(is_equal_approx(store.get_master_volume(), 1.0), "default volume should be 1")
	_check(not store.is_fullscreen(), "fullscreen should default to false")
	_check(store.get_window_mode() == 1, "new saves should default to a maximized window")
	_check(store.get_operation_mode() == 0, "new saves should default to mouse operation")


func _test_save_and_load() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.mark_level_started(2)
	store.record_completion(1, 4200)
	store.mark_level_started(2)
	store.mark_first_move_guide_seen()
	_check(store.claim_level_one_scan_grant(), "the first level-one grant claim should succeed")
	store.set_scan_energy(7)
	store.set_master_volume(0.35)
	store.set_fullscreen(true)
	store.set_operation_mode(1)
	_check(store.save_data(), "save_data should succeed")

	var loaded = SaveStore.new(TEST_PATH)
	loaded.load_data()
	_check(loaded.get_last_played_level() == 2, "last played level should persist")
	_check(loaded.has_seen_first_move_guide(), "first-move guide state should persist")
	_check(loaded.get_scan_energy() == 7, "shared scan energy should persist")
	_check(loaded.has_claimed_level_one_scan_grant(), "the one-time scan grant should persist")
	_check(loaded.is_level_completed(1), "completion should persist")
	_check(loaded.get_best_time_ms(1) == 4200, "best time should persist")
	_check(is_equal_approx(loaded.get_master_volume(), 0.35), "volume should persist")
	_check(loaded.is_fullscreen(), "fullscreen should persist")
	_check(loaded.get_window_mode() == 2, "legacy fullscreen API should map to borderless fullscreen")
	_check(loaded.get_operation_mode() == 1, "keyboard operation mode should persist")


func _test_schema_one_scan_migration() -> void:
	_cleanup()
	var source_store = SaveStore.new(TEST_PATH)
	var legacy_data: Dictionary = source_store.get_data()
	legacy_data["schema_version"] = 1
	legacy_data.erase("scan")
	legacy_data["last_played_level"] = 2
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_data))
	file.close()
	var loaded = SaveStore.new(TEST_PATH)
	var migrated: Dictionary = loaded.load_data()
	_check(migrated["schema_version"] == 3, "schema-one saves should normalize to schema three")
	_check(loaded.get_last_played_level() == 2, "schema migration should preserve progress")
	_check(loaded.get_scan_energy() == 0, "schema-one saves should migrate with empty energy")
	_check(not loaded.has_claimed_level_one_scan_grant(), "schema-one saves should leave the one-time grant available")
	_cleanup()


func _test_schema_two_ocean_migration() -> void:
	_cleanup()
	var source_store = SaveStore.new(TEST_PATH)
	var schema_two_data: Dictionary = source_store.get_data()
	schema_two_data["schema_version"] = 2
	for number in range(6, 11):
		schema_two_data["levels"].erase(str(number))
	schema_two_data["last_played_level"] = 2
	schema_two_data["levels"]["1"] = {
		"completed": true,
		"best_time_ms": 4100,
	}
	schema_two_data["scan"]["energy"] = 7
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(schema_two_data))
	file.close()
	var loaded = SaveStore.new(TEST_PATH)
	var migrated: Dictionary = loaded.load_data()
	_check(migrated["schema_version"] == 3, "schema-two saves should normalize to schema three")
	_check(loaded.get_last_played_level() == 2, "schema-two migration should preserve land progress")
	_check(loaded.is_level_completed(1), "schema-two migration should preserve land completion")
	_check(loaded.get_scan_energy() == 7, "schema-two migration should preserve scan energy")
	_check(migrated["levels"].size() == 10, "schema-two migration should add five ocean levels")
	for number in range(6, 11):
		_check(not loaded.is_level_completed(number), "migrated ocean level %d should start incomplete" % number)
	_cleanup()


func _test_scan_limits_and_grant() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.set_scan_energy(-4)
	_check(store.get_scan_energy() == 0, "scan energy should clamp at zero")
	store.set_scan_energy(30)
	_check(store.get_scan_energy() == 12, "scan energy should clamp at twelve")
	store.set_scan_energy(3)
	_check(store.claim_level_one_scan_grant(), "the unclaimed grant should fill the meter")
	_check(store.get_scan_energy() == 12, "claiming the grant should atomically fill twelve energy")
	store.set_scan_energy(4)
	_check(not store.claim_level_one_scan_grant(), "the level-one grant should only be claimable once")
	_check(store.get_scan_energy() == 4, "a repeated grant claim should not refill energy")


func _test_legacy_display_migration() -> void:
	_cleanup()
	var legacy_store = SaveStore.new(TEST_PATH)
	var legacy_data: Dictionary = legacy_store.get_data()
	legacy_data["settings"].erase("window_mode")
	legacy_data["settings"].erase("operation_mode")
	legacy_data["settings"]["fullscreen"] = false
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_data))
	file.close()
	var loaded = SaveStore.new(TEST_PATH)
	loaded.load_data()
	_check(loaded.get_window_mode() == 1, "legacy windowed saves should migrate to maximized window")
	_check(loaded.get_operation_mode() == 0, "legacy saves should default to mouse operation")
	legacy_data["settings"]["fullscreen"] = true
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_data))
	file.close()
	loaded.load_data()
	_check(loaded.get_window_mode() == 2, "legacy fullscreen saves should migrate to borderless fullscreen")
	_cleanup()


func _test_removed_level_migration() -> void:
	_cleanup()
	var legacy_store = SaveStore.new(TEST_PATH)
	var legacy_data: Dictionary = legacy_store.get_data()
	legacy_data["schema_version"] = 1
	legacy_data.erase("scan")
	for number in range(7, 11):
		legacy_data["levels"].erase(str(number))
	legacy_data["last_played_level"] = 6
	legacy_data.erase("first_move_guide_seen")
	legacy_data["levels"]["6"] = {
		"completed": true,
		"best_time_ms": 7200,
	}
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_data))
	file.close()
	var loaded = SaveStore.new(TEST_PATH)
	loaded.load_data()
	_check(loaded.get_last_played_level() == 0, "removed level 6 should not remain the continue target")
	_check(loaded.has_seen_first_move_guide(), "legacy play progress should keep the guide dismissed")
	_check(loaded.get_data()["levels"].size() == 10, "migration should create all current level records")
	_check(not loaded.is_level_completed(6), "removed level 6 should not become ocean level 6 progress")
	_cleanup()


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
	for number in range(6, 11):
		_check(store.is_level_unlocked(number), "ocean level %d should remain directly available" % number)
	_check(not store.is_level_unlocked(11), "out-of-range level should not be unlocked")


func _test_best_time_only_improves() -> void:
	var store = SaveStore.new(TEST_PATH)
	store.record_completion(1, 5000)
	store.record_completion(1, 7000)
	_check(store.get_best_time_ms(1) == 5000, "slower completion should not replace best time")
	store.record_completion(1, 3000)
	_check(store.get_best_time_ms(1) == 3000, "faster completion should replace best time")


func _test_ocean_progress_persistence() -> void:
	_cleanup()
	var store = SaveStore.new(TEST_PATH)
	store.mark_level_started(6)
	store.record_completion(6, 6800)
	store.record_completion(6, 7200)
	_check(store.get_last_played_level() == 6, "ocean play should become the continue target")
	_check(store.is_level_completed(6), "ocean completion should be recorded")
	_check(store.get_best_time_ms(6) == 6800, "slower ocean times should not replace the best time")
	_check(store.save_data(), "ocean progress should save")
	var loaded = SaveStore.new(TEST_PATH)
	loaded.load_data()
	_check(loaded.get_last_played_level() == 6, "ocean continue target should survive reload")
	_check(loaded.is_level_completed(6), "ocean completion should survive reload")
	_check(loaded.get_best_time_ms(6) == 6800, "ocean best time should survive reload")
	_cleanup()


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
	_check(store.get_window_mode() == 1, "legacy false fullscreen should map to maximized window")
	store.set_window_mode(0)
	_check(store.get_window_mode() == 0, "windowed mode should be stored")
	store.set_window_mode(2)
	_check(store.get_window_mode() == 2 and store.is_fullscreen(), "borderless fullscreen mode should be stored")
	store.set_window_mode(99)
	_check(store.get_window_mode() == 1, "invalid display modes should fall back to maximized")
	store.set_operation_mode(1)
	_check(store.get_operation_mode() == 1, "keyboard operation mode should be stored")
	store.set_operation_mode(99)
	_check(store.get_operation_mode() == 0, "invalid operation modes should fall back to mouse")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup() -> void:
	for path in [TEST_PATH, TEMP_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
