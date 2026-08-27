class_name WelcomeShowcase
extends Control


enum StoryState {
	IDLE_FRONT,
	FLIP_TO_PLANT,
	PULL_SPROUT,
	PLANT,
	REGROW,
	ADMIRE,
	SLIME_APPEAR,
	NOTICE_TURN,
	CHASE_RIGHT,
	FLIP_AWAY,
	CHASE_DISTANCE,
	RESET,
}

const SOURCE_SIZE := Vector2(2720.0, 1530.0)
const SUN_SOURCE_RECT := Rect2(2160.0, 66.0, 358.0, 358.0)
const STORY_DURATION := 12.0
const MOTE_COUNT := 21
const ROBOT_HEIGHT := 290.0
const HEAD_SPROUT_HEIGHT := 76.0
const PLANTED_SPROUT_HEIGHT := 90.0
const SLIME_HEIGHT := 135.0

const ART := preload("res://scripts/art_catalog.gd")
const BACKGROUND_PATH := ART.WELCOME_LANDSCAPE_BASE
const SUN_PATH := ART.WELCOME_SUN_GLOW
const POLLEN_PATH := ART.WELCOME_POLLEN_PARTICLES
const WATER_GLINT_PATH := ART.WELCOME_WATER_GLINT
const SPROUT_PATH := ART.MARKER_FLAG_SPROUT_HEALTHY
const HEAD_SPROUT_PATH := ART.WELCOME_ROBOT_HEAD_SPROUT
const ROBOT_FRONT_PATH := ART.WELCOME_ROBOT_FRONT
const ROBOT_BACK_PATH := ART.WELCOME_ROBOT_BACK
const ROBOT_RIGHT_PATH := ART.WELCOME_ROBOT_RIGHT
const ROBOT_PLANT_PATH := ART.WELCOME_ROBOT_PLANTING
const ROBOT_FRONT_SMILE_PATH := ART.WELCOME_ROBOT_FRONT_SMILING
const ROBOT_CHASE_BODY_PATH := ART.WELCOME_ROBOT_CHASING
const ROBOT_ARM_LEFT_PATH := ART.WELCOME_ROBOT_ARM_LEFT
const ROBOT_ARM_RIGHT_PATH := ART.WELCOME_ROBOT_ARM_RIGHT
const ROBOT_SHOULDER_JOINT_LEFT_PATH := ART.WELCOME_ROBOT_SHOULDER_LEFT
const SLIME_FRONT_PATH := ART.WELCOME_SLIME_FRONT
const SLIME_BACK_PATH := ART.WELCOME_SLIME_BACK
const SLIME_RIGHT_PATH := ART.WELCOME_SLIME_RIGHT
const SLIME_SQUASHED_PATH := ART.WELCOME_SLIME_SQUASHED
const SLIME_CHASE_SHELL_PATH := ART.WELCOME_SLIME_CHASE_SHELL
const SLIME_CHASE_CONTENTS_PATH := ART.WELCOME_SLIME_CHASE_CONTENTS

const STATE_STARTS := [
	0.0,
	1.5,
	2.1,
	3.2,
	4.1,
	4.9,
	5.9,
	6.7,
	7.3,
	8.2,
	8.6,
	10.9,
]
const STATE_NAMES := [
	"idle_front",
	"flip_to_plant",
	"pull_sprout",
	"plant",
	"regrow",
	"admire",
	"slime_appear",
	"notice_turn",
	"chase_right",
	"flip_away",
	"chase_distance",
	"reset",
]

const ROAD_CENTER_NEAR := Vector2(1280.0, 1310.0)
const ROBOT_GRASS_OFFSET := Vector2(-560.0, 0.0)
const ROBOT_HOME := ROAD_CENTER_NEAR + ROBOT_GRASS_OFFSET
const PLANTED_SPROUT_POSITION := ROBOT_HOME + Vector2(140.0, -15.0)
const ROAD_PATH_POINTS := [
	Vector2(1620.0, 1500.0),
	Vector2(1430.0, 1380.0),
	Vector2(1290.0, 1250.0),
	Vector2(1180.0, 1130.0),
	Vector2(1140.0, 1030.0),
	Vector2(1260.0, 950.0),
	Vector2(1460.0, 890.0),
	Vector2(1690.0, 850.0),
	Vector2(1880.0, 835.0),
]
const SLIME_APPEAR_ROAD_T := 0.35

const HEAD_ANCHOR_FRONT := Vector2(-0.050, -0.962)
const HEAD_ANCHOR_PLANT := Vector2(-0.145, -0.966)
const HEAD_ANCHOR_RIGHT := Vector2(-0.167, -0.957)
const HEAD_ANCHOR_BACK := Vector2(0.018, -0.969)

const LEFT_ARM_SHOULDER_OFFSET := Vector2(-114.0, -177.0)
const RIGHT_ARM_SHOULDER_OFFSET := Vector2(86.0, -177.0)
const PLANT_ARM_SHOULDER_OFFSET := Vector2(-45.0, -175.0)
const LEFT_HAND_REACH := Vector2(0.0, 108.0)
const PLANT_ARM_RAISED_ROTATION := 2.45
const PLANT_ARM_TRANSFER_ROTATION := 3.8
const PLANT_ARM_LOWERED_ROTATION := 5.63
const LEFT_ARM_PIVOT := Vector2(174.0, 22.0)
const RIGHT_ARM_PIVOT := Vector2(47.0, 20.0)
const LEFT_SHOULDER_JOINT_PIVOT := Vector2(74.0, 22.0)
const ROBOT_SOURCE_PIXEL_HEIGHT := 831.0

var _background: Texture2D
var _sun: Texture2D
var _pollen: Texture2D
var _water_glint: Texture2D
var _sprout: Texture2D
var _head_sprout: Texture2D
var _robot_front: Texture2D
var _robot_back: Texture2D
var _robot_right: Texture2D
var _robot_plant: Texture2D
var _robot_front_smile: Texture2D
var _robot_chase_body: Texture2D
var _robot_arm_left: Texture2D
var _robot_arm_right: Texture2D
var _robot_shoulder_joint_left: Texture2D
var _slime_front: Texture2D
var _slime_back: Texture2D
var _slime_right: Texture2D
var _slime_squashed: Texture2D
var _slime_chase_shell: Texture2D
var _slime_chase_contents: Texture2D

var _ambient_time := 0.0
var _story_time := 0.0
var _motes: Array[Dictionary] = []


func _ready() -> void:
	_load_textures()
	_generate_motes()
	visibility_changed.connect(_sync_processing)
	_sync_processing()


func _process(delta: float) -> void:
	var step := maxf(0.0, delta)
	_ambient_time = fmod(_ambient_time + step, 120.0)
	_story_time = fmod(_story_time + step, STORY_DURATION)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _background == null:
		return
	var breath := (sin(_ambient_time * 0.48) + 1.0) * 0.5
	var cover_scale := maxf(size.x / SOURCE_SIZE.x, size.y / SOURCE_SIZE.y)
	cover_scale *= lerpf(1.0, 1.003, breath)
	var artwork_size := SOURCE_SIZE * cover_scale
	var artwork_origin := (size - artwork_size) * 0.5
	var artwork_rect := Rect2(artwork_origin, artwork_size)

	draw_texture_rect(_background, artwork_rect, false)
	_draw_sun(artwork_origin, cover_scale)
	_draw_water_glint(artwork_rect)
	_draw_motes(artwork_origin, cover_scale)
	_draw_story(artwork_origin, cover_scale)
	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color(1.0, 0.93, 0.72, lerpf(0.006, 0.026, breath))
	)


func get_story_state_at(time: float) -> int:
	var wrapped := fposmod(time, STORY_DURATION)
	for index in range(STATE_STARTS.size() - 1, -1, -1):
		if wrapped >= float(STATE_STARTS[index]):
			return index
	return StoryState.IDLE_FRONT


func get_story_state_name_at(time: float) -> String:
	return STATE_NAMES[get_story_state_at(time)]


func get_story_time() -> float:
	return _story_time


func set_story_time_for_test(value: float) -> void:
	_story_time = fposmod(value, STORY_DURATION)
	queue_redraw()


func get_mote_specs() -> Array[Dictionary]:
	return _motes.duplicate(true)


func get_cover_rect(viewport_size: Vector2) -> Rect2:
	var cover_scale := maxf(viewport_size.x / SOURCE_SIZE.x, viewport_size.y / SOURCE_SIZE.y)
	var artwork_size := SOURCE_SIZE * cover_scale
	return Rect2((viewport_size - artwork_size) * 0.5, artwork_size)


func get_source_anchor_in_viewport(source_anchor: Vector2, viewport_size: Vector2) -> Vector2:
	var cover_rect := get_cover_rect(viewport_size)
	var cover_scale := cover_rect.size.x / SOURCE_SIZE.x
	return cover_rect.position + source_anchor * cover_scale


func get_road_position(value: float) -> Vector2:
	var progress := clampf(value, 0.0, 1.0)
	var last_index := ROAD_PATH_POINTS.size() - 1
	var scaled_progress := progress * float(last_index)
	var index := mini(int(floorf(scaled_progress)), last_index - 1)
	var local_progress := scaled_progress - float(index)
	var p0: Vector2 = ROAD_PATH_POINTS[maxi(index - 1, 0)]
	var p1: Vector2 = ROAD_PATH_POINTS[index]
	var p2: Vector2 = ROAD_PATH_POINTS[index + 1]
	var p3: Vector2 = ROAD_PATH_POINTS[mini(index + 2, last_index)]
	var local_squared := local_progress * local_progress
	var local_cubed := local_squared * local_progress
	return 0.5 * (
		2.0 * p1
		+ (-p0 + p2) * local_progress
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * local_squared
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * local_cubed
	)


func get_chase_sample(progress: float) -> Dictionary:
	var eased := _smooth(progress)
	var slime_path_progress := _smooth(clampf(progress / 0.72, 0.0, 1.0))
	var robot_road_t := lerpf(0.04, 1.0, eased)
	var slime_road_t := lerpf(SLIME_APPEAR_ROAD_T, 1.0, slime_path_progress)
	var robot_scale := lerpf(1.0, 0.18, eased)
	var slime_scale := lerpf(1.0, 0.12, slime_path_progress)
	var slime_alpha := 1.0 - _smooth(clampf((progress - 0.66) / 0.12, 0.0, 1.0))
	return {
		"robot_road_t": robot_road_t,
		"slime_road_t": slime_road_t,
		"robot_position": get_road_position(robot_road_t),
		"slime_position": get_road_position(slime_road_t),
		"slime_contents_position": get_road_position(maxf(0.0, slime_road_t - 0.012)),
		"scale": robot_scale,
		"slime_scale": slime_scale,
		"slime_alpha": slime_alpha,
	}


func get_head_anchor_for_pose(
	pose: String,
	robot_position: Vector2 = ROBOT_HOME,
	rotation: float = 0.0,
	actor_scale: Vector2 = Vector2.ONE
) -> Vector2:
	var local_anchor := _get_head_anchor_ratio(pose) * ROBOT_HEIGHT * actor_scale
	return robot_position + local_anchor.rotated(rotation)


func get_plant_position() -> Vector2:
	return PLANTED_SPROUT_POSITION


func get_planting_hand_position(arm_rotation: float, robot_position: Vector2 = ROBOT_HOME) -> Vector2:
	return robot_position + PLANT_ARM_SHOULDER_OFFSET + LEFT_HAND_REACH.rotated(arm_rotation)


func get_actor_texture_paths() -> Array[String]:
	return [
		ROBOT_FRONT_PATH,
		ROBOT_BACK_PATH,
		ROBOT_RIGHT_PATH,
		ROBOT_PLANT_PATH,
		ROBOT_FRONT_SMILE_PATH,
		ROBOT_CHASE_BODY_PATH,
		ROBOT_ARM_LEFT_PATH,
		ROBOT_ARM_RIGHT_PATH,
		SLIME_FRONT_PATH,
		SLIME_BACK_PATH,
		SLIME_RIGHT_PATH,
		SLIME_SQUASHED_PATH,
		SLIME_CHASE_SHELL_PATH,
		SLIME_CHASE_CONTENTS_PATH,
		HEAD_SPROUT_PATH,
	]


func _load_textures() -> void:
	_background = load(BACKGROUND_PATH) as Texture2D
	_sun = load(SUN_PATH) as Texture2D
	_pollen = load(POLLEN_PATH) as Texture2D
	_water_glint = load(WATER_GLINT_PATH) as Texture2D
	_sprout = load(SPROUT_PATH) as Texture2D
	_head_sprout = load(HEAD_SPROUT_PATH) as Texture2D
	_robot_front = _load_runtime_texture(ROBOT_FRONT_PATH)
	_robot_back = _load_runtime_texture(ROBOT_BACK_PATH)
	_robot_right = _load_runtime_texture(ROBOT_RIGHT_PATH)
	_robot_plant = _load_runtime_texture(ROBOT_PLANT_PATH)
	_robot_front_smile = _load_runtime_texture(ROBOT_FRONT_SMILE_PATH)
	_robot_chase_body = _load_runtime_texture(ROBOT_CHASE_BODY_PATH)
	_robot_arm_left = _load_runtime_texture(ROBOT_ARM_LEFT_PATH)
	_robot_arm_right = _load_runtime_texture(ROBOT_ARM_RIGHT_PATH)
	_robot_shoulder_joint_left = _load_runtime_texture(ROBOT_SHOULDER_JOINT_LEFT_PATH)
	_slime_front = load(SLIME_FRONT_PATH) as Texture2D
	_slime_back = load(SLIME_BACK_PATH) as Texture2D
	_slime_right = load(SLIME_RIGHT_PATH) as Texture2D
	_slime_squashed = load(SLIME_SQUASHED_PATH) as Texture2D
	_slime_chase_shell = load(SLIME_CHASE_SHELL_PATH) as Texture2D
	_slime_chase_contents = load(SLIME_CHASE_CONTENTS_PATH) as Texture2D


func _load_runtime_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Welcome artwork could not be loaded: %s" % path)
	return texture


func _generate_motes() -> void:
	_motes.clear()
	var random := RandomNumberGenerator.new()
	random.seed = 334_933
	for index in MOTE_COUNT:
		_motes.append({
			"position": Vector2(
				random.randf_range(780.0, 2630.0),
				random.randf_range(480.0, 1370.0)
			),
			"scale": random.randf_range(0.62, 1.85),
			"alpha": random.randf_range(0.48, 0.95),
			"drift": Vector2(
				random.randf_range(16.0, 70.0),
				random.randf_range(12.0, 54.0)
			),
			"period": random.randf_range(8.0, 25.0),
			"phase": random.randf_range(0.0, TAU),
			"pulse_speed": random.randf_range(0.75, 1.35),
		})


func _draw_sun(artwork_origin: Vector2, cover_scale: float) -> void:
	var pulse := (sin(_ambient_time * 0.72) + 1.0) * 0.5
	var sun_scale := cover_scale * lerpf(0.992, 1.008, pulse)
	var sun_size := SUN_SOURCE_RECT.size * sun_scale
	var source_center := SUN_SOURCE_RECT.get_center()
	var sun_center := artwork_origin + source_center * cover_scale
	sun_center.y += sin(_ambient_time * 0.58) * 3.5
	var sun_rect := Rect2(sun_center - sun_size * 0.5, sun_size)
	draw_texture_rect(_sun, sun_rect, false, Color(1.0, 1.0, 1.0, lerpf(0.96, 1.0, pulse)))


func _draw_water_glint(artwork_rect: Rect2) -> void:
	var shimmer := (sin(_ambient_time * 1.15) + 1.0) * 0.5
	draw_texture_rect(
		_water_glint,
		artwork_rect,
		false,
		Color(1.0, 1.0, 1.0, lerpf(0.12, 0.52, shimmer))
	)


func _draw_motes(artwork_origin: Vector2, cover_scale: float) -> void:
	for mote in _motes:
		var period: float = mote.period
		var phase: float = mote.phase
		var drift: Vector2 = mote.drift
		var angle := _ambient_time / period * TAU + phase
		var source_position: Vector2 = mote.position
		source_position += Vector2(sin(angle) * drift.x, cos(angle * 0.83) * drift.y)
		var pulse := (sin(_ambient_time * float(mote.pulse_speed) + phase) + 1.0) * 0.5
		var alpha: float = float(mote.alpha) * lerpf(0.86, 1.0, pulse)
		var position := artwork_origin + source_position * cover_scale
		draw_set_transform(position, 0.0, Vector2.ONE * cover_scale * float(mote.scale))
		draw_texture(
			_pollen,
			-_pollen.get_size() * 0.5,
			Color(1.0, 1.0, 1.0, alpha)
		)
		draw_circle(
			Vector2.ZERO,
			4.5,
			Color(1.0, 0.96, 0.58, minf(1.0, alpha * 0.88))
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_story(artwork_origin: Vector2, cover_scale: float) -> void:
	var state := get_story_state_at(_story_time)
	var progress := _get_state_progress(_story_time, state)
	match state:
		StoryState.IDLE_FRONT:
			var rock := sin(progress * TAU * 1.5) * 0.025
			_draw_robot_with_head(_robot_front_smile, "front", ROBOT_HOME, artwork_origin, cover_scale, rock)
		StoryState.FLIP_TO_PLANT:
			var flip_x := absf(cos(progress * PI))
			var texture := _robot_front_smile if progress < 0.5 else _robot_plant
			var pose := "front" if progress < 0.5 else "plant"
			_draw_robot_with_head(texture, pose, ROBOT_HOME, artwork_origin, cover_scale, 0.0, flip_x)
		StoryState.PULL_SPROUT:
			var action_progress := _stepped_progress(progress, 8)
			var arm_rotation := lerpf(0.0, PLANT_ARM_RAISED_ROTATION, _smooth(action_progress / 0.55)) if action_progress < 0.55 \
					else lerpf(PLANT_ARM_RAISED_ROTATION, PLANT_ARM_TRANSFER_ROTATION, _smooth((action_progress - 0.55) / 0.45))
			_draw_planting_robot(arm_rotation, artwork_origin, cover_scale)
			var sprout_start := get_head_anchor_for_pose("plant")
			var hand_position := get_planting_hand_position(arm_rotation)
			var grip_progress := _smooth(clampf((action_progress - 0.45) / 0.55, 0.0, 1.0))
			_draw_sprout_prop(_head_sprout, sprout_start.lerp(hand_position, grip_progress), HEAD_SPROUT_HEIGHT, artwork_origin, cover_scale, -0.18 * grip_progress)
		StoryState.PLANT:
			var action_progress := _stepped_progress(progress, 8)
			var arm_rotation := lerpf(PLANT_ARM_TRANSFER_ROTATION, PLANT_ARM_LOWERED_ROTATION, _smooth(action_progress))
			_draw_planting_robot(arm_rotation, artwork_origin, cover_scale)
			var hand_position := get_planting_hand_position(arm_rotation)
			var place_progress := _smooth(clampf((action_progress - 0.72) / 0.28, 0.0, 1.0))
			var sprout_position := _arc_lerp(hand_position, PLANTED_SPROUT_POSITION, place_progress, 20.0)
			_draw_sprout_prop(_head_sprout, sprout_position, HEAD_SPROUT_HEIGHT, artwork_origin, cover_scale, lerpf(-0.18, 0.0, place_progress))
		StoryState.REGROW:
			_draw_planted_sprout(artwork_origin, cover_scale)
			_draw_planting_robot(PLANT_ARM_LOWERED_ROTATION, artwork_origin, cover_scale)
			_draw_head_sprout("plant", ROBOT_HOME, artwork_origin, cover_scale, _pop_scale(progress))
			var bounce := 1.0 + sin(progress * TAU * 2.0) * 0.18 * (1.0 - progress)
			var slime_texture := _slime_squashed if progress < 0.48 else _slime_front
			_draw_actor(slime_texture, get_road_position(SLIME_APPEAR_ROAD_T), SLIME_HEIGHT, artwork_origin, cover_scale, 0.0, _smooth(progress), bounce, _smooth(progress))
		StoryState.ADMIRE, StoryState.SLIME_APPEAR:
			_draw_planted_sprout(artwork_origin, cover_scale)
			_draw_planting_robot(PLANT_ARM_LOWERED_ROTATION, artwork_origin, cover_scale)
			_draw_head_sprout("plant", ROBOT_HOME, artwork_origin, cover_scale, 1.0)
			var bounce := 1.0 + sin(progress * TAU * 2.0) * 0.08
			_draw_actor(_slime_front, get_road_position(SLIME_APPEAR_ROAD_T), SLIME_HEIGHT, artwork_origin, cover_scale, 0.0, 1.0, bounce)
		StoryState.NOTICE_TURN:
			_draw_planted_sprout(artwork_origin, cover_scale)
			var move_progress := _smooth(progress)
			var robot_position := ROBOT_HOME.lerp(get_road_position(0.04), move_progress)
			var shake := sin(progress * TAU * 4.0) * 0.075 * (1.0 - progress)
			if progress < 0.5:
				_draw_planting_robot(PLANT_ARM_LOWERED_ROTATION, artwork_origin, cover_scale)
				_draw_head_sprout("plant", ROBOT_HOME, artwork_origin, cover_scale, 1.0)
			else:
				_draw_chase_robot(robot_position, artwork_origin, cover_scale, shake, 1.0, 1.0, progress * TAU * 2.0)
			_draw_layered_slime(get_road_position(SLIME_APPEAR_ROAD_T), get_road_position(SLIME_APPEAR_ROAD_T - 0.012), 1.0, -0.055, 0.035, artwork_origin, cover_scale)
		StoryState.CHASE_RIGHT:
			_draw_planted_sprout(artwork_origin, cover_scale)
			var overall := _stepped_progress(progress * 0.25, 20)
			_draw_chase_sample(overall, progress * TAU * 4.5, artwork_origin, cover_scale)
		StoryState.FLIP_AWAY:
			_draw_planted_sprout(artwork_origin, cover_scale)
			var sample := get_chase_sample(0.25)
			var flip_x := absf(cos(progress * PI))
			if progress < 0.5:
				_draw_chase_robot(sample.robot_position, artwork_origin, cover_scale, 0.10, flip_x * float(sample.scale), float(sample.scale), progress * TAU * 3.0)
				_draw_layered_slime(sample.slime_position, sample.slime_contents_position, float(sample.slime_scale), -0.08, 0.05, artwork_origin, cover_scale, flip_x, float(sample.slime_alpha))
			else:
				_draw_robot_with_head(_robot_back, "back", sample.robot_position, artwork_origin, cover_scale, 0.0, flip_x * float(sample.scale), float(sample.scale))
				_draw_actor(_slime_back, sample.slime_position, SLIME_HEIGHT, artwork_origin, cover_scale, 0.0, flip_x * float(sample.slime_scale), float(sample.slime_scale), float(sample.slime_alpha))
		StoryState.CHASE_DISTANCE:
			_draw_planted_sprout(artwork_origin, cover_scale)
			var overall := _stepped_progress(0.25 + progress * 0.75, 20)
			var sample := get_chase_sample(overall)
			var tilt := _cardboard_tilt(progress, 11, 0.115)
			var robot_position: Vector2 = sample.robot_position
			var slime_position: Vector2 = sample.slime_position
			_draw_robot_with_head(_robot_back, "back", robot_position, artwork_origin, cover_scale, tilt, float(sample.scale), float(sample.scale))
			_draw_actor(_slime_back, slime_position, SLIME_HEIGHT, artwork_origin, cover_scale, -tilt * 0.85, float(sample.slime_scale), float(sample.slime_scale), float(sample.slime_alpha))
		StoryState.RESET:
			var alpha := 1.0 - clampf(progress / 0.80, 0.0, 1.0)
			var sample := get_chase_sample(1.0)
			_draw_planted_sprout(artwork_origin, cover_scale, alpha)
			_draw_robot_with_head(_robot_back, "back", sample.robot_position, artwork_origin, cover_scale, 0.0, float(sample.scale), float(sample.scale), alpha)
			_draw_actor(_slime_back, sample.slime_position, SLIME_HEIGHT, artwork_origin, cover_scale, 0.0, float(sample.slime_scale), float(sample.slime_scale), alpha * float(sample.slime_alpha))


func _draw_robot_with_head(
	texture: Texture2D,
	pose: String,
	source_position: Vector2,
	artwork_origin: Vector2,
	cover_scale: float,
	rotation: float = 0.0,
	scale_x: float = 1.0,
	scale_y: float = 1.0,
	alpha: float = 1.0
) -> void:
	_draw_actor(texture, source_position, ROBOT_HEIGHT, artwork_origin, cover_scale, rotation, scale_x, scale_y, alpha)
	var head_base := get_head_anchor_for_pose(pose, source_position, rotation, Vector2(scale_x, scale_y))
	_draw_sprout_prop(_head_sprout, head_base, HEAD_SPROUT_HEIGHT, artwork_origin, cover_scale, rotation, scale_x, scale_y, alpha)


func _draw_head_sprout(
	pose: String,
	robot_position: Vector2,
	artwork_origin: Vector2,
	cover_scale: float,
	sprout_scale: float,
	robot_rotation: float = 0.0
) -> void:
	var head_base := get_head_anchor_for_pose(pose, robot_position, robot_rotation)
	_draw_sprout_prop(_head_sprout, head_base, HEAD_SPROUT_HEIGHT, artwork_origin, cover_scale, robot_rotation, sprout_scale, sprout_scale)


func _draw_planted_sprout(artwork_origin: Vector2, cover_scale: float, alpha: float = 1.0) -> void:
	_draw_sprout_prop(_sprout, PLANTED_SPROUT_POSITION, PLANTED_SPROUT_HEIGHT, artwork_origin, cover_scale, 0.0, 1.0, 1.0, alpha)


func _draw_chase_sample(
	overall_progress: float,
	motion_phase: float,
	artwork_origin: Vector2,
	cover_scale: float
) -> void:
	var sample := get_chase_sample(overall_progress)
	var tilt := _cardboard_tilt(overall_progress, 12, 0.145)
	var robot_position: Vector2 = sample.robot_position
	var slime_position: Vector2 = sample.slime_position
	var contents_position: Vector2 = sample.slime_contents_position
	var actor_scale: float = sample.scale
	var slime_scale: float = sample.slime_scale
	var squash := 1.0 - absf(sin(motion_phase)) * 0.08
	_draw_chase_robot(robot_position, artwork_origin, cover_scale, tilt, actor_scale / squash, actor_scale * squash, motion_phase)
	_draw_layered_slime(slime_position, contents_position, slime_scale, -tilt * 0.90, tilt * 0.48, artwork_origin, cover_scale, 1.0, float(sample.slime_alpha))


func _draw_planting_robot(
	left_arm_rotation: float,
	artwork_origin: Vector2,
	cover_scale: float
) -> void:
	_draw_actor(_robot_plant, ROBOT_HOME, ROBOT_HEIGHT, artwork_origin, cover_scale)
	var shoulder := ROBOT_HOME + PLANT_ARM_SHOULDER_OFFSET
	_draw_arm(
		_robot_arm_left,
		shoulder,
		LEFT_ARM_PIVOT,
		left_arm_rotation,
		1.0,
		1.0,
		artwork_origin,
		cover_scale,
		1.0,
		float(_robot_plant.get_height())
	)
	_draw_arm(
		_robot_shoulder_joint_left,
		shoulder,
		LEFT_SHOULDER_JOINT_PIVOT,
		0.0,
		1.0,
		1.0,
		artwork_origin,
		cover_scale,
		1.0,
		float(_robot_plant.get_height())
	)


func _draw_chase_robot(
	source_position: Vector2,
	artwork_origin: Vector2,
	cover_scale: float,
	rotation: float,
	scale_x: float,
	scale_y: float,
	motion_phase: float,
	alpha: float = 1.0
) -> void:
	var left_shoulder := source_position + (LEFT_ARM_SHOULDER_OFFSET * Vector2(scale_x, scale_y)).rotated(rotation)
	var right_shoulder := source_position + (RIGHT_ARM_SHOULDER_OFFSET * Vector2(scale_x, scale_y)).rotated(rotation)
	var arm_swing := sin(motion_phase) * 0.30
	_draw_arm(_robot_arm_left, left_shoulder, LEFT_ARM_PIVOT, rotation + 2.28 + arm_swing, scale_x, scale_y, artwork_origin, cover_scale, alpha)
	_draw_arm(_robot_arm_right, right_shoulder, RIGHT_ARM_PIVOT, rotation - 2.28 - arm_swing, scale_x, scale_y, artwork_origin, cover_scale, alpha)
	_draw_actor(_robot_chase_body, source_position, ROBOT_HEIGHT, artwork_origin, cover_scale, rotation, scale_x, scale_y, alpha)
	var head_base := get_head_anchor_for_pose("front", source_position, rotation, Vector2(scale_x, scale_y))
	_draw_sprout_prop(_head_sprout, head_base, HEAD_SPROUT_HEIGHT, artwork_origin, cover_scale, rotation, scale_x, scale_y, alpha)


func _draw_arm(
	texture: Texture2D,
	source_pivot_position: Vector2,
	pivot_pixels: Vector2,
	rotation: float,
	scale_x: float,
	scale_y: float,
	artwork_origin: Vector2,
	cover_scale: float,
	alpha: float,
	reference_pixel_height: float = ROBOT_SOURCE_PIXEL_HEIGHT
) -> void:
	if texture == null or alpha <= 0.0:
		return
	var pixel_scale := ROBOT_HEIGHT / reference_pixel_height * cover_scale
	var target_size := texture.get_size() * pixel_scale
	var target_pivot := pivot_pixels * pixel_scale
	var viewport_pivot := artwork_origin + source_pivot_position * cover_scale
	draw_set_transform(viewport_pivot, rotation, Vector2(scale_x, scale_y))
	draw_texture_rect(texture, Rect2(-target_pivot, target_size), false, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_layered_slime(
	shell_position: Vector2,
	contents_position: Vector2,
	actor_scale: float,
	shell_rotation: float,
	contents_rotation: float,
	artwork_origin: Vector2,
	cover_scale: float,
	flip_x: float = 1.0,
	alpha: float = 1.0
) -> void:
	_draw_actor(_slime_chase_shell, shell_position, SLIME_HEIGHT, artwork_origin, cover_scale, shell_rotation, actor_scale * flip_x, actor_scale, alpha)
	_draw_actor(_slime_chase_contents, contents_position, SLIME_HEIGHT, artwork_origin, cover_scale, contents_rotation, actor_scale * flip_x, actor_scale, alpha)


func _draw_actor(
	texture: Texture2D,
	source_ground_position: Vector2,
	source_height: float,
	artwork_origin: Vector2,
	cover_scale: float,
	rotation: float = 0.0,
	scale_x: float = 1.0,
	scale_y: float = 1.0,
	alpha: float = 1.0
) -> void:
	if texture == null or alpha <= 0.0:
		return
	var texture_size := texture.get_size()
	var target_height := source_height * cover_scale
	var target_size := Vector2(target_height * texture_size.x / texture_size.y, target_height)
	var ground_position := artwork_origin + source_ground_position * cover_scale
	draw_set_transform(ground_position, rotation, Vector2(scale_x, scale_y))
	draw_texture_rect(texture, Rect2(Vector2(-target_size.x * 0.5, -target_size.y), target_size), false, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sprout_prop(
	texture: Texture2D,
	source_base_position: Vector2,
	source_height: float,
	artwork_origin: Vector2,
	cover_scale: float,
	rotation: float = 0.0,
	scale_x: float = 1.0,
	scale_y: float = 1.0,
	alpha: float = 1.0
) -> void:
	_draw_actor(texture, source_base_position, source_height, artwork_origin, cover_scale, rotation, scale_x, scale_y, alpha)


func _get_head_anchor_ratio(pose: String) -> Vector2:
	match pose:
		"plant":
			return HEAD_ANCHOR_PLANT
		"right":
			return HEAD_ANCHOR_RIGHT
		"back":
			return HEAD_ANCHOR_BACK
	return HEAD_ANCHOR_FRONT


func _get_state_progress(time: float, state: int) -> float:
	var wrapped := fposmod(time, STORY_DURATION)
	var start: float = STATE_STARTS[state]
	var end := STORY_DURATION if state == StoryState.RESET else float(STATE_STARTS[state + 1])
	return clampf((wrapped - start) / (end - start), 0.0, 1.0)


func _smooth(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _arc_lerp(start: Vector2, end: Vector2, progress: float, lift: float) -> Vector2:
	var eased := _smooth(progress)
	var position := start.lerp(end, eased)
	position.y -= sin(progress * PI) * lift
	return position


func _pop_scale(progress: float) -> float:
	if progress < 0.58:
		return lerpf(0.0, 1.18, _smooth(progress / 0.58))
	return lerpf(1.18, 1.0, _smooth((progress - 0.58) / 0.42))


func _stepped_progress(progress: float, steps: int) -> float:
	return floorf(clampf(progress, 0.0, 1.0) * float(steps)) / float(steps)


func _cardboard_tilt(progress: float, steps: int, amount: float) -> float:
	var step := mini(int(floorf(progress * float(steps))), steps - 1)
	return amount if step % 2 == 0 else -amount


func _sync_processing() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		queue_redraw()
