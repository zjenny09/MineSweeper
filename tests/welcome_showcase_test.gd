extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	root.size = Vector2i(1280, 720)
	var showcase := WelcomeShowcase.new()
	showcase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(showcase)
	await process_frame

	_test_timeline(showcase)
	_test_story_staging(showcase)
	_test_actor_textures(showcase)
	await _test_motes(showcase)
	_test_cover_layout(showcase)
	await _test_visibility_pause(showcase)

	showcase.queue_free()
	await process_frame
	if failures == 0:
		print("Green Sweeper welcome showcase tests passed.")
		quit(0)
	else:
		push_error("%d welcome showcase test(s) failed." % failures)
		quit(1)


func _test_timeline(showcase: WelcomeShowcase) -> void:
	var boundaries := {
		0.0: "idle_front",
		1.5: "flip_to_plant",
		2.1: "pull_sprout",
		3.2: "plant",
		4.1: "regrow",
		4.9: "admire",
		5.9: "slime_appear",
		6.7: "notice_turn",
		7.3: "chase_right",
		8.2: "flip_away",
		8.6: "chase_distance",
		10.9: "reset",
		12.0: "idle_front",
	}
	for time in boundaries:
		_expect(
			showcase.get_story_state_name_at(time) == boundaries[time],
			"The welcome story enters %s at %.1f seconds." % [boundaries[time], time]
		)
	showcase.set_story_time_for_test(13.5)
	_expect(showcase.get_story_state_name_at(showcase.get_story_time()) == "flip_to_plant", "Story time wraps cleanly after one complete loop.")


func _test_story_staging(showcase: WelcomeShowcase) -> void:
	_expect(WelcomeShowcase.ROBOT_HOME.x < WelcomeShowcase.SOURCE_SIZE.x * 0.45, "The robot starts on the center-left grass instead of at canvas center.")
	_expect(WelcomeShowcase.ROBOT_HEIGHT <= WelcomeShowcase.SOURCE_SIZE.y * 0.20, "The robot remains small enough to belong to the landscape.")
	for pose in ["front", "plant", "right", "back"]:
		var head_anchor := showcase.get_head_anchor_for_pose(pose)
		_expect(head_anchor.y <= WelcomeShowcase.ROBOT_HOME.y - WelcomeShowcase.ROBOT_HEIGHT * 0.94, "The %s head sprout attaches to the top opening instead of floating below it." % pose)
	var upright_head_offset := showcase.get_head_anchor_for_pose("front") - WelcomeShowcase.ROBOT_HOME
	var tilted_head_offset := showcase.get_head_anchor_for_pose("front", WelcomeShowcase.ROBOT_HOME, 0.2) - WelcomeShowcase.ROBOT_HOME
	var half_scale_head_offset := showcase.get_head_anchor_for_pose("front", WelcomeShowcase.ROBOT_HOME, 0.0, Vector2.ONE * 0.5) - WelcomeShowcase.ROBOT_HOME
	_expect(tilted_head_offset.distance_to(upright_head_offset.rotated(0.2)) < 0.01, "The head sprout marker follows the robot's local rotation during regrowth.")
	_expect(half_scale_head_offset.distance_to(upright_head_offset * 0.5) < 0.01, "The head sprout marker follows the robot's local scale.")
	var raised_hand := showcase.get_planting_hand_position(WelcomeShowcase.PLANT_ARM_RAISED_ROTATION)
	_expect(raised_hand.distance_to(showcase.get_head_anchor_for_pose("plant")) <= 45.0, "The side-view planting hand reaches the head sprout before pulling it free.")
	var lowered_hand := showcase.get_planting_hand_position(WelcomeShowcase.PLANT_ARM_LOWERED_ROTATION)
	_expect(lowered_hand.distance_to(showcase.get_plant_position()) <= 75.0, "The planting hand lowers close enough to place the sprout in the grass.")

	var plant_position := showcase.get_plant_position()
	var plant_offset := plant_position - WelcomeShowcase.ROBOT_HOME
	_expect(plant_offset.x > 0.0 and plant_offset.x <= WelcomeShowcase.ROBOT_HEIGHT, "The robot plants the sprout within reach on its right side.")
	_expect(absf(plant_offset.y) <= WelcomeShowcase.ROBOT_HEIGHT * 0.25, "The planted sprout shares the robot's local grass level.")

	var previous_scale := 2.0
	for progress in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var sample := showcase.get_chase_sample(progress)
		_expect(float(sample.robot_road_t) < float(sample.slime_road_t), "The slime stays ahead of the robot during the chase.")
		_expect(sample.robot_position == showcase.get_road_position(float(sample.robot_road_t)), "The robot ground anchor follows the road curve.")
		_expect(sample.slime_position == showcase.get_road_position(float(sample.slime_road_t)), "The slime ground anchor follows the same road curve.")
		_expect(sample.robot_position.distance_to(sample.slime_position) >= 80.0, "The chase keeps a visible front-to-back gap instead of moving side by side.")
		_expect(float(sample.scale) <= previous_scale, "Both actors shrink proportionally while moving into the distance.")
		_expect(sample.slime_contents_position != sample.slime_position, "The slime contents use a slightly delayed position.")
		previous_scale = float(sample.scale)
	_expect(previous_scale <= 0.20, "Both actors shrink to a distant point before the reset fade begins.")


func _test_actor_textures(showcase: WelcomeShowcase) -> void:
	for path in showcase.get_actor_texture_paths():
		var texture := load(path) as Texture2D
		_expect(texture != null, "Welcome actor texture loads: %s" % path)
		if texture == null:
			continue
		var image := texture.get_image()
		_expect(image != null and image.get_pixel(0, 0).a < 0.05, "Welcome actor keeps transparent outer corners: %s" % path)


func _test_motes(showcase: WelcomeShowcase) -> void:
	var motes := showcase.get_mote_specs()
	_expect(motes.size() == WelcomeShowcase.MOTE_COUNT, "The welcome landscape uses the configured varied light-mote count.")
	for mote in motes:
		var position: Vector2 = mote.position
		var drift: Vector2 = mote.drift
		_expect(position.x >= 780.0 and position.x <= 2630.0 and position.y >= 150.0 and position.y <= 1240.0, "Light motes start inside the intended landscape area.")
		_expect(float(mote.scale) >= 0.35 and float(mote.scale) <= 1.35, "Light-mote sizes remain varied but bounded.")
		_expect(float(mote.alpha) >= 0.15 and float(mote.alpha) <= 0.55, "Light-mote opacity remains soft.")
		_expect(drift.x >= 16.0 and drift.x <= 70.0 and drift.y >= 12.0 and drift.y <= 54.0, "Light-mote drift remains slow and local.")
		_expect(float(mote.period) >= 8.0 and float(mote.period) <= 25.0, "Light-mote periods remain slow.")

	var second := WelcomeShowcase.new()
	root.add_child(second)
	await process_frame
	_expect(second.get_mote_specs() == motes, "The random-looking light-mote layout is deterministic between runs.")
	second.queue_free()


func _test_cover_layout(showcase: WelcomeShowcase) -> void:
	for viewport_size in [Vector2(1280.0, 720.0), Vector2(1280.0, 800.0)]:
		var cover_rect := showcase.get_cover_rect(viewport_size)
		_expect(cover_rect.encloses(Rect2(Vector2.ZERO, viewport_size)), "The story background covers the complete supported viewport.")
		var scale := cover_rect.size.x / WelcomeShowcase.SOURCE_SIZE.x
		var road_anchor := showcase.get_source_anchor_in_viewport(WelcomeShowcase.ROAD_CENTER_NEAR, viewport_size)
		var robot_anchor := showcase.get_source_anchor_in_viewport(WelcomeShowcase.ROBOT_HOME, viewport_size)
		_expect(
			(robot_anchor - road_anchor).distance_to(WelcomeShowcase.ROBOT_GRASS_OFFSET * scale) < 0.01,
			"The robot keeps the same terrain-relative offset from the road center after cover scaling."
		)
		for source_anchor_value in [
			WelcomeShowcase.ROBOT_HOME,
			WelcomeShowcase.PLANTED_SPROUT_POSITION,
			Vector2(2265.0, 875.0),
		]:
			var source_anchor: Vector2 = source_anchor_value
			var viewport_anchor: Vector2 = cover_rect.position + source_anchor * scale
			_expect(Rect2(Vector2.ZERO, viewport_size).has_point(viewport_anchor), "Important story anchors remain visible after cover cropping.")


func _test_visibility_pause(showcase: WelcomeShowcase) -> void:
	showcase.visible = false
	await process_frame
	_expect(not showcase.is_processing(), "The story animation pauses when the welcome page is hidden.")
	showcase.visible = true
	await process_frame
	_expect(showcase.is_processing(), "The story animation resumes when the welcome page returns.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
