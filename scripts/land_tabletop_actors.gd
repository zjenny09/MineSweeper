@tool
class_name LandTabletopActors
extends Control

signal scan_activation_requested

const ART := preload("res://scripts/art_catalog.gd")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const TABLETOP_BACK_Y := 616.0
const TABLETOP_FRONT_Y := 682.0
const LAND_ROBOT_SLOT_POSITION := Vector2(570.0, 656.0)
const LAND_PLANT_SLOT_POSITION := Vector2(640.0, 656.0)
const LAND_MONSTER_SLOT_POSITION := Vector2(710.0, 648.0)
const OCEAN_ROBOT_SLOT_POSITION := Vector2(530.0, 700.0)
const SKY_ROBOT_SLOT_POSITION := Vector2(500.0, 696.0)
const SKY_MONSTER_SLOT_POSITION := Vector2(755.0, 698.0)
const SKY_DOT_SLOT_POSITION := Vector2(640.0, 696.0)
const ANEMONE_SLOT_POSITION := Vector2(625.0, 700.0)
const OCEAN_ECOLOGY_SLOT_POSITION := Vector2(665.0, 700.0)
const LAND_ECOLOGY_MAX_SIZE := Vector2(60.0, 52.0)
const ANEMONE_MAX_SIZE := Vector2(59.0, 46.0)
const OCEAN_ECOLOGY_MAX_SIZE := Vector2(59.0, 46.0)
const JELLYFISH_MAX_SIZE := Vector2(78.0, 64.0)
const FISH_SCHOOL_MAX_SIZE := Vector2(95.0, 54.0)
const TRENCH_MAX_SIZE := Vector2(88.0, 58.0)
const WHALE_FALL_MAX_SIZE := Vector2(95.0, 48.0)
const SKY_ECOLOGY_MAX_SIZE := Vector2(58.0, 40.0)
const VICTORY_CYCLE := 1.2
const VICTORY_ROBOT_HEIGHT := 26.0
const VICTORY_ARM_RAISE := 1.92
const SCAN_RESULT_DURATION := 0.95
const FAILURE_FALL_DURATION := 0.62
const FAILURE_SETTLE_DURATION := 0.20
const FAILURE_FALL_ROTATION := deg_to_rad(-96.0)
const FAILURE_REST_ROTATION := deg_to_rad(-88.0)
const FAILURE_BODY_PATH := ART.LAND_ROBOT_FAILURE_BODY
const FAILURE_LEFT_ARM_PATH := ART.WELCOME_ROBOT_ARM_LEFT
const FAILURE_RIGHT_ARM_PATH := ART.WELCOME_ROBOT_ARM_RIGHT
const FAILURE_BODY_MAX_SIZE := Vector2(68.0, 90.0)
const FAILURE_SPROUT_MAX_SIZE := Vector2(22.0, 22.0)
const FAILURE_SPROUT_OFFSET := Vector2(-10.0, -62.0)
const FAILURE_ARM_REFERENCE_HEIGHT := 831.0
const FAILURE_ARM_TARGET_HEIGHT := 90.0
const FAILURE_LEFT_SHOULDER := Vector2(-35.4, -54.9)
const FAILURE_RIGHT_SHOULDER := Vector2(26.7, -54.9)
const SKY_VICTORY_LEFT_SHOULDER := Vector2(-38.0, -80.0)
const SKY_VICTORY_RIGHT_SHOULDER := Vector2(31.0, -80.0)
const FAILURE_LEFT_ARM_PIVOT := Vector2(174.0, 22.0)
const FAILURE_RIGHT_ARM_PIVOT := Vector2(47.0, 20.0)
const FAILURE_JOLT_X := [0.0, -1.8, 1.4, -0.8, 1.8, -0.4]
const FAILURE_JOLT_ROTATION := [0.0, -2.4, 1.6, -1.4, 2.2, -0.8]
const FAILURE_LAND_POSITION := Vector2(-8.0, 11.0)
const FAILURE_REST_POSITION := Vector2(-25.0, 6.0)
const MONSTER_IDLE_CYCLE := 5.2
const MONSTER_IDLE_HOP_DURATION := 0.62
const VICTORY_DOT_BASES: Array[Vector2] = [
	Vector2(-20.0, -58.0),
	Vector2(-4.0, -66.0),
	Vector2(12.0, -58.0),
]

enum ReactionMode {
	READY,
	VICTORY,
	FAILURE,
}

enum ScanAnimation {
	NONE,
	TARGETING,
	RESULT_SAFE,
	RESULT_MINE,
}

const LAND_ROBOT_PATH := ART.LEVEL_01_GUARDIAN_LEFT_ROBOT
const LAND_MONSTER_PATH := ART.LAND_TABLETOP_PAPER_MONSTER
const OCEAN_ROBOT_PATH := ART.OCEAN_PROTAGONIST_ROBOT
const OCEAN_REACTION_BODY_PATH := ART.OCEAN_PROTAGONIST_REACTION_BODY
const OCEAN_MONSTER_PATH := ART.OCEAN_PROTAGONIST_MONSTER
const OCEAN_MONSTER_CRYING_PATH := ART.OCEAN_PROTAGONIST_MONSTER_CRYING
const SKY_ROBOT_PATH := ART.SKY_PROTAGONIST_ROBOT
const SKY_VICTORY_BODY_PATH := ART.SKY_PROTAGONIST_VICTORY_BODY
const SKY_FAILURE_BODY_PATH := ART.SKY_PROTAGONIST_FAILURE_BODY
const SKY_PLANE_PATH := ART.SKY_PROTAGONIST_PLANE
const SKY_MONSTER_PATH := ART.SKY_PROTAGONIST_MONSTER
const LAND_ROBOT_MAX_SIZE := Vector2(60.0, 90.0)
const OCEAN_ROBOT_MAX_SIZE := Vector2(68.0, 94.0)
const SKY_ROBOT_MAX_SIZE := Vector2(120.0, 108.0)
const SKY_FAILURE_ROBOT_MAX_SIZE := Vector2(126.0, 70.0)
const SKY_PLANE_MAX_SIZE := Vector2(154.0, 58.0)
const SKY_ROBOT_RIDE_OFFSET := Vector2(0.0, -18.0)
const SKY_PLANE_RIDE_OFFSET := Vector2(0.0, 8.0)
const LAND_MONSTER_MAX_SIZE := Vector2(52.0, 52.0)
const OCEAN_MONSTER_MAX_SIZE := Vector2(68.0, 68.0)
const OCEAN_MONSTER_LEFT_EYE_PIXEL := Vector2(193.4, 296.2)
const OCEAN_MONSTER_RIGHT_EYE_PIXEL := Vector2(273.2, 305.6)
const SKY_MONSTER_MAX_SIZE := Vector2(112.0, 84.0)

@onready var design_plane: Node2D = %DesignPlane
@onready var robot_sprite: Sprite2D = %RobotSprite
@onready var plant_sprite: Sprite2D = %PlantSprite
@onready var monster_sprite: Sprite2D = %MonsterSprite
@onready var sky_robot_plane_motion: Node2D = %SkyRobotPlaneMotion
@onready var sky_robot_plane_sprite: Sprite2D = %SkyRobotPlaneSprite
@onready var robot_motion: Node2D = %RobotMotion
@onready var robot_failure_motion: Node2D = %RobotFailureMotion
@onready var robot_scan_motion: Node2D = %RobotScanMotion
@onready var robot_fallen_pose: Node2D = %RobotFallenPose
@onready var robot_failure_body: Sprite2D = %RobotFailureBody
@onready var robot_failure_sprout: Sprite2D = %RobotFailureSprout
@onready var robot_failure_left_arm: Node2D = %RobotFailureLeftArm
@onready var robot_failure_left_arm_sprite: Sprite2D = %RobotFailureLeftArmSprite
@onready var robot_failure_right_arm: Node2D = %RobotFailureRightArm
@onready var robot_failure_right_arm_sprite: Sprite2D = %RobotFailureRightArmSprite
@onready var robot_failure_sparks: Node2D = %RobotFailureSparks
@onready var robot_failure_spark_a: Line2D = %RobotFailureSparkA
@onready var robot_failure_spark_b: Line2D = %RobotFailureSparkB
@onready var robot_failure_spark_c: Line2D = %RobotFailureSparkC
@onready var plant_motion: Node2D = %PlantMotion
@onready var monster_motion: Node2D = %MonsterMotion
@onready var monster_tears: Node2D = %MonsterTears
@onready var ocean_cry_mouth_cover: Polygon2D = %OceanCryMouthCover
@onready var ocean_cry_mouth: Line2D = %OceanCryMouth
@onready var monster_tear_left: Line2D = %MonsterTearLeft
@onready var monster_tear_right: Line2D = %MonsterTearRight
@onready var robot_shadow: Control = %RobotShadow
@onready var plant_shadow: Control = %PlantShadow
@onready var monster_shadow: Control = %MonsterShadow
@onready var robot_hotspot: Button = %RobotHotspot
@onready var scan_hint_button: Button = %ScanHintButton
@onready var scan_beam: Line2D = %ScanBeam
@onready var victory_dots: Node2D = %VictoryDots
@onready var victory_dot_a: Control = %VictoryDotA
@onready var victory_dot_b: Control = %VictoryDotB
@onready var victory_dot_c: Control = %VictoryDotC

@onready var actor_slots: Array[Node2D] = [
	%RobotSlot,
	%PlantSlot,
	%MonsterSlot,
]
@onready var motion_roots: Array[Node2D] = [
	sky_robot_plane_motion,
	robot_motion,
	robot_failure_motion,
	robot_fallen_pose,
	plant_motion,
	monster_motion,
]
@onready var actor_shadows: Array[Control] = [
	robot_shadow,
	plant_shadow,
	monster_shadow,
]
@onready var dot_nodes: Array[Control] = [
	victory_dot_a,
	victory_dot_b,
	victory_dot_c,
]

var _texture_cache: Dictionary = {}
var _level_number := 1
var _uses_ocean_ecology := false
var _uses_sky_actors := false
var _healthy_ecology_path := ""
var _wilted_ecology_path := ""
var _ecology_max_size := LAND_ECOLOGY_MAX_SIZE
var _victory_dot_bases: Array[Vector2] = VICTORY_DOT_BASES.duplicate()
var _reaction_mode := ReactionMode.READY
var _reaction_time := 0.0
var _reaction_processing := false
var _scan_animation := ScanAnimation.NONE
var _scan_time := 0.0
var _sky_flight_time := 0.0
var _scan_target_local := Vector2.ZERO
var _scan_paused := false
var _scan_energy := 0
var _scan_threshold := 1
var _scan_locked := true
var _scan_used := false
var _scan_available := false
var _scan_show_charge_status := false
var _filled_dot_count := 0
var _dot_pop_index := -1
var _dot_pop_time := 0.0
var _charge_pulse_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_design_transform)
	robot_hotspot.pressed.connect(_on_robot_hotspot_pressed)
	scan_hint_button.pressed.connect(_on_robot_hotspot_pressed)
	_setup_actor(robot_sprite, LAND_ROBOT_PATH, LAND_ROBOT_MAX_SIZE)
	_setup_actor(robot_failure_body, FAILURE_BODY_PATH, FAILURE_BODY_MAX_SIZE)
	_setup_actor(
		robot_failure_sprout,
		ART.WELCOME_ROBOT_HEAD_SPROUT,
		FAILURE_SPROUT_MAX_SIZE
	)
	robot_failure_sprout.position += FAILURE_SPROUT_OFFSET
	robot_failure_sprout.visible = false
	_setup_failure_arm(
		robot_failure_left_arm_sprite,
		FAILURE_LEFT_ARM_PATH,
		FAILURE_LEFT_ARM_PIVOT
	)
	_setup_failure_arm(
		robot_failure_right_arm_sprite,
		FAILURE_RIGHT_ARM_PATH,
		FAILURE_RIGHT_ARM_PIVOT
	)
	robot_failure_left_arm.position = FAILURE_LEFT_SHOULDER
	robot_failure_right_arm.position = FAILURE_RIGHT_SHOULDER
	_setup_actor(monster_sprite, LAND_MONSTER_PATH, LAND_MONSTER_MAX_SIZE)
	_apply_perspective_scales()
	_update_design_transform()
	_reset_reaction()
	set_scan_meter(0, 1, true, false)
	set_scan_activation_enabled(false, "完成首次净化后可使用生态扫描")


func _process(delta: float) -> void:
	if _scan_paused:
		return
	var step := maxf(0.0, delta)
	if _uses_sky_actors:
		_sky_flight_time += step
	if _reaction_processing:
		_reaction_time += step
		match _reaction_mode:
			ReactionMode.VICTORY:
				_update_victory_reaction()
			ReactionMode.FAILURE:
				_update_failure_reaction()
	if _reaction_mode == ReactionMode.READY:
		_update_scan_visuals(step)
		_update_ocean_robot_idle()
	if _uses_sky_actors:
		_update_sky_robot_plane_flight()
	_refresh_processing()


func set_plant_texture(path: String) -> void:
	if _uses_ocean_ecology:
		return
	_setup_actor(plant_sprite, path, LAND_ECOLOGY_MAX_SIZE)


func set_land_plant_visible(visible: bool) -> void:
	if _uses_ocean_ecology:
		return
	actor_slots[1].visible = visible
	plant_shadow.visible = visible


func _configure_protagonists(use_ocean_art: bool) -> void:
	robot_failure_left_arm.position = FAILURE_LEFT_SHOULDER
	robot_failure_right_arm.position = FAILURE_RIGHT_SHOULDER
	_setup_actor(
		robot_sprite,
		OCEAN_ROBOT_PATH if use_ocean_art else LAND_ROBOT_PATH,
		OCEAN_ROBOT_MAX_SIZE if use_ocean_art else LAND_ROBOT_MAX_SIZE
	)
	_setup_actor(
		robot_failure_body,
		OCEAN_REACTION_BODY_PATH if use_ocean_art else FAILURE_BODY_PATH,
		OCEAN_ROBOT_MAX_SIZE if use_ocean_art else FAILURE_BODY_MAX_SIZE
	)
	_setup_actor(
		monster_sprite,
		OCEAN_MONSTER_PATH if use_ocean_art else LAND_MONSTER_PATH,
		OCEAN_MONSTER_MAX_SIZE if use_ocean_art else LAND_MONSTER_MAX_SIZE
	)
	robot_failure_sprout.visible = false
	robot_failure_left_arm.visible = true
	robot_failure_right_arm.visible = true
	ocean_cry_mouth_cover.visible = false
	ocean_cry_mouth.visible = false
	sky_robot_plane_motion.visible = false


func _setup_sky_reaction_body(path: String, maximum_size: Vector2) -> void:
	_setup_actor(robot_failure_body, path, maximum_size)
	robot_failure_body.position += SKY_ROBOT_RIDE_OFFSET


func _configure_sky_protagonists() -> void:
	_sky_flight_time = 0.0
	robot_failure_left_arm.position = SKY_VICTORY_LEFT_SHOULDER
	robot_failure_right_arm.position = SKY_VICTORY_RIGHT_SHOULDER
	_setup_actor(robot_sprite, SKY_ROBOT_PATH, SKY_ROBOT_MAX_SIZE)
	robot_sprite.position += SKY_ROBOT_RIDE_OFFSET
	_setup_sky_reaction_body(SKY_VICTORY_BODY_PATH, SKY_ROBOT_MAX_SIZE)
	_setup_actor(sky_robot_plane_sprite, SKY_PLANE_PATH, SKY_PLANE_MAX_SIZE)
	_setup_actor(monster_sprite, SKY_MONSTER_PATH, SKY_MONSTER_MAX_SIZE)
	sky_robot_plane_motion.visible = true
	robot_failure_sprout.visible = false
	robot_failure_left_arm.visible = true
	robot_failure_right_arm.visible = true
	ocean_cry_mouth_cover.visible = false
	ocean_cry_mouth.visible = false


func configure_for_level(level_number: int) -> void:
	_level_number = level_number
	_uses_ocean_ecology = level_number >= 8
	_uses_sky_actors = false
	_configure_protagonists(_uses_ocean_ecology)
	plant_sprite.visible = true
	actor_slots[1].visible = true
	actor_slots[0].position = (
		OCEAN_ROBOT_SLOT_POSITION
		if _uses_ocean_ecology
		else LAND_ROBOT_SLOT_POSITION
	)
	if level_number == 8:
		actor_slots[1].position = ANEMONE_SLOT_POSITION
	elif _uses_ocean_ecology:
		actor_slots[1].position = OCEAN_ECOLOGY_SLOT_POSITION
	else:
		actor_slots[1].position = LAND_PLANT_SLOT_POSITION
	if _uses_ocean_ecology:
		var ecology_x := actor_slots[1].position.x
		var robot_x := actor_slots[0].position.x
		actor_slots[2].position = Vector2(
			ecology_x + (ecology_x - robot_x),
			OCEAN_ECOLOGY_SLOT_POSITION.y
		)
	else:
		actor_slots[2].position = LAND_MONSTER_SLOT_POSITION
	actor_slots[2].visible = true
	plant_shadow.visible = not _uses_ocean_ecology and level_number != 7
	_victory_dot_bases = VICTORY_DOT_BASES.duplicate()
	if level_number == 7:
		_victory_dot_bases = [
			Vector2(-16.0, -58.0),
			Vector2(0.0, -66.0),
			Vector2(16.0, -58.0),
		]
	if _uses_ocean_ecology:
		var ecology_index := clampi(
			level_number - 8,
			0,
			ART.OCEAN_ACTOR_HEALTHY_PATHS.size() - 1
		)
		_healthy_ecology_path = str(ART.OCEAN_ACTOR_HEALTHY_PATHS[ecology_index])
		_wilted_ecology_path = str(ART.OCEAN_ACTOR_WILTED_PATHS[ecology_index])
		if level_number == 8:
			_ecology_max_size = ANEMONE_MAX_SIZE
		elif level_number == 11:
			_ecology_max_size = JELLYFISH_MAX_SIZE
		elif level_number == 12:
			_ecology_max_size = FISH_SCHOOL_MAX_SIZE
		elif level_number == 13:
			_ecology_max_size = TRENCH_MAX_SIZE
		elif level_number == 14:
			_ecology_max_size = WHALE_FALL_MAX_SIZE
		else:
			_ecology_max_size = OCEAN_ECOLOGY_MAX_SIZE
		var dot_y := -_ecology_max_size.y - 24.0
		_victory_dot_bases = [
			Vector2(-20.0, dot_y + 8.0),
			Vector2(-4.0, dot_y),
			Vector2(12.0, dot_y + 8.0),
		]
		_setup_actor(plant_sprite, _healthy_ecology_path, _ecology_max_size)
	else:
		_healthy_ecology_path = ""
		_wilted_ecology_path = ""
		_ecology_max_size = LAND_ECOLOGY_MAX_SIZE
	_apply_perspective_scales()
	_reset_reaction()


func configure_for_sky(level_number: int = 15) -> void:
	_level_number = clampi(level_number, 15, 21)
	_uses_ocean_ecology = false
	_uses_sky_actors = true
	_configure_sky_protagonists()
	actor_slots[0].position = SKY_ROBOT_SLOT_POSITION
	actor_slots[0].visible = true
	actor_slots[1].position = SKY_DOT_SLOT_POSITION
	actor_slots[1].visible = true
	plant_sprite.visible = true
	actor_slots[2].position = SKY_MONSTER_SLOT_POSITION
	actor_slots[2].visible = true
	robot_shadow.visible = false
	plant_shadow.visible = false
	monster_shadow.visible = false
	var ecology_index := clampi(
		_level_number - 15,
		0,
		ART.SKY_ECOLOGY_HEALTHY_PATHS.size() - 1
	)
	_healthy_ecology_path = str(ART.SKY_ECOLOGY_HEALTHY_PATHS[ecology_index])
	_wilted_ecology_path = str(ART.SKY_ECOLOGY_FAILED_PATHS[ecology_index])
	_ecology_max_size = SKY_ECOLOGY_MAX_SIZE
	var dot_y := -_ecology_max_size.y - 18.0
	_victory_dot_bases = [
		Vector2(-20.0, dot_y + 8.0),
		Vector2(-4.0, dot_y),
		Vector2(12.0, dot_y + 8.0),
	]
	_setup_actor(plant_sprite, _healthy_ecology_path, _ecology_max_size)
	_apply_perspective_scales()
	_reset_reaction()


func get_ecology_texture_path() -> String:
	return plant_sprite.texture.resource_path if plant_sprite.texture != null else ""


func uses_ocean_ecology() -> bool:
	return _uses_ocean_ecology


func set_failure(failed: bool) -> void:
	if _healthy_ecology_path.is_empty():
		return
	_apply_ecology_texture(
		_wilted_ecology_path
		if failed
		else _healthy_ecology_path
	)


func set_scan_meter(
	energy: int,
	threshold: int,
	locked: bool,
	used: bool,
	show_charge_status: bool = false
) -> void:
	var previous_count := _filled_dot_count
	_scan_threshold = maxi(1, threshold)
	_scan_energy = clampi(energy, 0, _scan_threshold)
	_scan_locked = locked
	_scan_used = used
	_scan_show_charge_status = show_charge_status
	_filled_dot_count = mini(
		3,
		int(floor(float(_scan_energy) * 3.0 / float(_scan_threshold)))
	)
	if _filled_dot_count > previous_count and not _scan_locked and not _scan_used:
		_dot_pop_index = _filled_dot_count - 1
		_dot_pop_time = 0.38
		_charge_pulse_time = 0.42
	_apply_scan_meter_visuals()
	_refresh_processing()


func set_scan_activation_enabled(enabled: bool, tooltip: String) -> void:
	_scan_available = enabled
	robot_hotspot.disabled = not enabled
	robot_hotspot.tooltip_text = tooltip
	scan_hint_button.disabled = not enabled
	scan_hint_button.tooltip_text = tooltip
	scan_hint_button.visible = (
		_scan_animation == ScanAnimation.TARGETING
		or (_reaction_mode == ReactionMode.READY and not _scan_used)
	)
	if _scan_animation == ScanAnimation.TARGETING:
		scan_hint_button.text = "选择格子 · Esc取消"
	elif _scan_show_charge_status and not enabled:
		scan_hint_button.text = "扫描 %d/%d · C" % [_scan_energy, _scan_threshold]
	elif _scan_locked:
		scan_hint_button.text = "首翻后扫描 · C"
	elif _scan_energy < _scan_threshold:
		scan_hint_button.text = "扫描 %d/%d · C" % [_scan_energy, _scan_threshold]
	else:
		scan_hint_button.text = "点机器人扫描 · C"
	_refresh_processing()


func begin_scan_targeting() -> void:
	if _reaction_mode != ReactionMode.READY:
		return
	_scan_animation = ScanAnimation.TARGETING
	_scan_time = 0.0
	scan_hint_button.visible = true
	scan_hint_button.text = "选择格子 · Esc取消"
	scan_beam.visible = false
	_refresh_processing()


func cancel_scan_targeting() -> void:
	if _scan_animation != ScanAnimation.TARGETING:
		return
	_reset_scan_animation()


func play_scan_result(result: int, target_global_position: Vector2) -> void:
	if _reaction_mode != ReactionMode.READY:
		return
	_scan_animation = (
		ScanAnimation.RESULT_MINE
		if result == 1
		else ScanAnimation.RESULT_SAFE
	)
	_scan_time = 0.0
	_scan_target_local = design_plane.to_local(target_global_position)
	var beam_start := _scan_beam_start()
	scan_beam.points = PackedVector2Array([beam_start, beam_start])
	scan_beam.visible = true
	_refresh_processing()


func finish_scan_visuals() -> void:
	_reset_scan_animation()
	robot_hotspot.disabled = true
	scan_hint_button.disabled = true
	scan_hint_button.visible = false


func set_scan_paused(paused: bool) -> void:
	_scan_paused = paused
	_refresh_processing()


func play_reaction(won: bool, failed: bool) -> void:
	_reset_scan_animation()
	_reset_reaction()
	if not _healthy_ecology_path.is_empty():
		_apply_ecology_texture(
			_wilted_ecology_path
			if failed
			else _healthy_ecology_path
		)
	if _uses_sky_actors and (won or failed):
		_setup_sky_reaction_body(
			SKY_FAILURE_BODY_PATH if failed else SKY_VICTORY_BODY_PATH,
			SKY_FAILURE_ROBOT_MAX_SIZE if failed else SKY_ROBOT_MAX_SIZE
		)
		robot_failure_left_arm.visible = not failed
		robot_failure_right_arm.visible = not failed
	if _uses_ocean_ecology and failed:
		_setup_actor(
			monster_sprite,
			OCEAN_MONSTER_CRYING_PATH,
			OCEAN_MONSTER_MAX_SIZE
		)
	if won:
		_reaction_mode = ReactionMode.VICTORY
		_reaction_processing = true
		robot_failure_motion.visible = false
		robot_fallen_pose.visible = true
		victory_dots.visible = true
		for dot in dot_nodes:
			dot.modulate = Color.WHITE
	elif failed:
		_reaction_mode = ReactionMode.FAILURE
		_reaction_processing = true
		robot_failure_motion.visible = false
		robot_fallen_pose.visible = true
		victory_dots.visible = false
	_refresh_processing()


func get_design_scale() -> float:
	return design_plane.scale.x if is_instance_valid(design_plane) else 1.0


func get_slot_design_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for slot in actor_slots:
		positions.append(slot.position)
	return positions


func _on_robot_hotspot_pressed() -> void:
	if not robot_hotspot.disabled:
		scan_activation_requested.emit()


func _reset_reaction() -> void:
	_reaction_mode = ReactionMode.READY
	_reaction_time = 0.0
	_reaction_processing = false
	robot_failure_motion.visible = true
	robot_fallen_pose.visible = false
	robot_failure_left_arm.rotation = 0.0
	robot_failure_right_arm.rotation = 0.0
	robot_failure_body.modulate = Color.WHITE
	robot_failure_sprout.modulate = Color.WHITE
	robot_failure_left_arm_sprite.modulate = Color.WHITE
	robot_failure_right_arm_sprite.modulate = Color.WHITE
	robot_failure_sparks.visible = false
	robot_failure_sparks.position = Vector2.ZERO
	for spark in [robot_failure_spark_a, robot_failure_spark_b, robot_failure_spark_c]:
		spark.visible = false
		spark.points = PackedVector2Array()
	monster_tears.visible = false
	monster_tears.modulate = Color.WHITE
	monster_tear_left.points = PackedVector2Array()
	monster_tear_right.points = PackedVector2Array()
	for motion_root in motion_roots:
		motion_root.position = Vector2.ZERO
		motion_root.scale = Vector2.ONE
		motion_root.rotation = 0.0
	for shadow in actor_shadows:
		shadow.scale = Vector2.ONE
		shadow.modulate = Color.WHITE
	if _uses_ocean_ecology:
		_setup_actor(monster_sprite, OCEAN_MONSTER_PATH, OCEAN_MONSTER_MAX_SIZE)
	_apply_scan_meter_visuals()
	_refresh_processing()


func _update_robot_celebration(cycle_time: float, cycle_phase: float) -> void:
	var robot_lift := _bounce_lift(cycle_time, 0.0, 0.58)
	_apply_victory_bounce(
		robot_motion,
		robot_shadow,
		robot_lift,
		VICTORY_ROBOT_HEIGHT
	)
	if _uses_ocean_ecology or _uses_sky_actors:
		robot_motion.position.x += sin(cycle_phase * 2.0) * 2.4
		robot_motion.rotation = sin(cycle_phase) * 0.12
	else:
		robot_motion.rotation = sin(cycle_phase) * 0.075
	robot_failure_left_arm.rotation = (
		VICTORY_ARM_RAISE + sin(cycle_phase * 2.0) * 0.22
	)
	robot_failure_right_arm.rotation = (
		-VICTORY_ARM_RAISE - sin(cycle_phase * 2.0 + 0.8) * 0.22
	)


func _update_victory_reaction() -> void:
	var cycle_time := fmod(_reaction_time, VICTORY_CYCLE)
	var cycle_phase := cycle_time / VICTORY_CYCLE * TAU
	var plant_lift := _bounce_lift(cycle_time, 0.18, 0.48)
	var monster_lift := _bounce_lift(cycle_time, 0.36, 0.48)
	_update_robot_celebration(cycle_time, cycle_phase)
	_apply_victory_bounce(plant_motion, plant_shadow, plant_lift, 8.0)
	_apply_victory_bounce(monster_motion, monster_shadow, monster_lift, 7.0)
	monster_motion.rotation = -sin(cycle_phase) * 0.025
	for dot_index in dot_nodes.size():
		var phase := cycle_phase + float(dot_index) * 2.1
		dot_nodes[dot_index].position = (
			_victory_dot_bases[dot_index] + Vector2(0.0, sin(phase) * 5.0)
		)


func _centered_rotation_position(visual_center: Vector2, rotation_angle: float) -> Vector2:
	return visual_center - visual_center.rotated(rotation_angle)


func _update_failure_sparks(shock_frame: int) -> void:
	robot_failure_sparks.visible = true
	var phase := shock_frame % 6
	var jitter := float((shock_frame * 3) % 5 - 2)
	robot_failure_spark_a.visible = phase != 1 and phase != 4
	robot_failure_spark_a.points = PackedVector2Array([
		Vector2(-49.0, -58.0),
		Vector2(-58.0 + jitter, -52.0),
		Vector2(-53.0, -45.0),
		Vector2(-64.0 - jitter, -40.0),
	])
	robot_failure_spark_b.visible = phase == 0 or phase == 2 or phase == 5
	robot_failure_spark_b.points = PackedVector2Array([
		Vector2(25.0, -58.0),
		Vector2(36.0 - jitter, -63.0),
		Vector2(33.0, -53.0),
		Vector2(46.0 + jitter, -49.0),
	])
	robot_failure_spark_c.visible = phase == 1 or phase == 3
	robot_failure_spark_c.points = PackedVector2Array([
		Vector2(-10.0, -72.0),
		Vector2(-5.0 + jitter, -82.0),
		Vector2(1.0, -76.0),
		Vector2(6.0 - jitter, -87.0),
	])


func _sprite_pixel_to_parent(sprite: Sprite2D, pixel: Vector2) -> Vector2:
	if sprite.texture == null:
		return Vector2.ZERO
	return (
		sprite.position
		+ (pixel - sprite.texture.get_size() * 0.5) * sprite.scale
	)


func _update_monster_failure() -> void:
	var cry_time := maxf(0.0, _reaction_time - 0.12)
	var cry_frame := int(floor(cry_time * 8.0))
	var tremble: float = float([-0.7, 0.6, -0.4, 0.8, -0.6, 0.3][cry_frame % 6])
	monster_motion.position = Vector2(float(tremble), 2.0)
	monster_motion.rotation = deg_to_rad(float(tremble) * 1.6)
	monster_motion.scale = Vector2(1.03, 0.95)
	monster_shadow.scale = Vector2(1.06, 0.88)
	monster_shadow.modulate.a = 0.78
	monster_tears.visible = cry_time > 0.0
	var tear_phase := fmod(cry_time, 0.72) / 0.72
	if _uses_ocean_ecology:
		var ocean_drop := tear_phase * 3.0
		var left_eye := _sprite_pixel_to_parent(
			monster_sprite,
			OCEAN_MONSTER_LEFT_EYE_PIXEL
		)
		var right_eye := _sprite_pixel_to_parent(
			monster_sprite,
			OCEAN_MONSTER_RIGHT_EYE_PIXEL
		)
		monster_tear_left.width = 1.15
		monster_tear_right.width = 1.15
		monster_tear_left.points = PackedVector2Array([
			left_eye + Vector2(0.0, 0.8),
			left_eye + Vector2(-0.2, 3.2 + ocean_drop * 0.20),
			left_eye + Vector2(0.2, 6.0 + ocean_drop),
		])
		monster_tear_right.points = PackedVector2Array([
			right_eye + Vector2(0.0, 0.8),
			right_eye + Vector2(0.2, 3.2 + ocean_drop * 0.20),
			right_eye + Vector2(-0.2, 6.0 + ocean_drop),
		])
	else:
		var tear_drop := tear_phase * 5.0
		var tear_start_y := -42.0 if _uses_sky_actors else -22.0
		monster_tear_left.width = 1.8
		monster_tear_right.width = 1.8
		monster_tear_left.points = PackedVector2Array([
			Vector2(-6.0, tear_start_y),
			Vector2(-6.5, tear_start_y + 7.0 + tear_drop * 0.25),
			Vector2(-5.5, tear_start_y + 12.0 + tear_drop),
		])
		monster_tear_right.points = PackedVector2Array([
			Vector2(6.0, tear_start_y),
			Vector2(6.5, tear_start_y + 8.0 + tear_drop * 0.20),
			Vector2(5.5, tear_start_y + 14.0 + tear_drop),
		])
	monster_tears.modulate.a = 0.62 + sin(tear_phase * PI) * 0.38


func _update_failure_reaction() -> void:
	_update_monster_failure()
	if _uses_sky_actors:
		_update_sky_robot_failure()
		return
	_update_land_robot_failure()


func _update_sky_robot_failure() -> void:
	var drop_progress := clampf(_reaction_time / 0.42, 0.0, 1.0)
	var drop_eased := 1.0 - pow(1.0 - drop_progress, 3.0)
	robot_motion.position = Vector2(
		sin(drop_progress * PI) * -3.0,
		lerpf(-26.0, 2.0, drop_eased)
	)
	robot_motion.scale = Vector2.ONE.lerp(Vector2(1.02, 0.98), drop_eased)
	robot_fallen_pose.rotation = deg_to_rad(lerpf(-4.0, 0.0, drop_eased))
	robot_shadow.visible = false
	if drop_progress < 1.0:
		return
	var shock_time := _reaction_time - 0.42
	var shock_frame := int(floor(shock_time * 12.0))
	var jolt_index := shock_frame % FAILURE_JOLT_X.size()
	robot_motion.position = Vector2(
		float(FAILURE_JOLT_X[jolt_index]) * 0.75,
		2.0 + float((shock_frame * 2) % 3 - 1)
	)
	robot_fallen_pose.rotation = deg_to_rad(
		float(FAILURE_JOLT_ROTATION[jolt_index]) * 0.42
	)
	var electric_tint := (
		Color(0.76, 0.95, 1.0, 1.0)
		if shock_frame % 4 == 1
		else Color.WHITE
	)
	robot_failure_body.modulate = electric_tint
	robot_failure_sparks.position = Vector2(0.0, 12.0)
	_update_failure_sparks(shock_frame)


func _update_land_robot_failure() -> void:
	var fall_progress := clampf(_reaction_time / FAILURE_FALL_DURATION, 0.0, 1.0)
	var fall_eased := fall_progress * fall_progress * (3.0 - 2.0 * fall_progress)
	var fall_rotation := lerpf(0.0, FAILURE_FALL_ROTATION, fall_eased)
	robot_motion.position = (FAILURE_LAND_POSITION + Vector2(0.0, 1.0)) * fall_eased
	robot_motion.rotation = 0.0
	robot_motion.scale = Vector2.ONE.lerp(Vector2.ONE * 0.98, fall_eased)
	robot_fallen_pose.rotation = fall_rotation
	robot_fallen_pose.position = _centered_rotation_position(
		robot_failure_body.position,
		fall_rotation
	)
	robot_failure_left_arm.rotation = -0.16 * fall_eased
	robot_failure_right_arm.rotation = 0.16 * fall_eased
	robot_shadow.scale = Vector2.ONE.lerp(Vector2(1.38, 0.60), fall_eased)
	robot_shadow.modulate.a = lerpf(1.0, 0.70, fall_eased)
	if fall_progress < 1.0:
		return

	var settle_progress := clampf(
		(_reaction_time - FAILURE_FALL_DURATION) / FAILURE_SETTLE_DURATION,
		0.0,
		1.0
	)
	var settle_eased := 1.0 - pow(1.0 - settle_progress, 3.0)
	var settle_rotation := lerpf(
		FAILURE_FALL_ROTATION,
		FAILURE_REST_ROTATION,
		settle_eased
	)
	robot_motion.position = (
		FAILURE_LAND_POSITION + Vector2(0.0, 1.0)
	).lerp(FAILURE_REST_POSITION, settle_eased)
	robot_fallen_pose.rotation = settle_rotation
	robot_fallen_pose.position = _centered_rotation_position(
		robot_failure_body.position,
		settle_rotation
	)
	robot_shadow.scale = Vector2(
		lerpf(1.38, 1.46, settle_eased),
		lerpf(0.60, 0.54, settle_eased)
	)
	if settle_progress < 1.0:
		return

	var flail_time := _reaction_time - FAILURE_FALL_DURATION - FAILURE_SETTLE_DURATION
	var shock_frame := int(floor(flail_time * 10.0))
	var stepped_time := float(shock_frame) / 10.0
	var jolt_index := shock_frame % FAILURE_JOLT_X.size()
	var body_rotation := (
		FAILURE_REST_ROTATION
		+ deg_to_rad(float(FAILURE_JOLT_ROTATION[jolt_index]))
	)
	robot_motion.position = FAILURE_REST_POSITION + Vector2(
		float(FAILURE_JOLT_X[jolt_index]),
		0.0
	)
	robot_motion.scale = Vector2.ONE * 0.98
	robot_fallen_pose.rotation = body_rotation
	robot_fallen_pose.position = _centered_rotation_position(
		robot_failure_body.position,
		body_rotation
	)
	robot_failure_left_arm.rotation = clampf(
		-0.12
		+ sin(stepped_time * 9.4) * 0.90
		+ sin(stepped_time * 4.1 + 0.3) * 0.22,
		-1.18,
		1.18
	)
	robot_failure_right_arm.rotation = clampf(
		0.12
		- sin(stepped_time * 10.2 + 0.9) * 0.86
		- sin(stepped_time * 4.8) * 0.24,
		-1.15,
		1.15
	)
	var electric_tint := (
		Color(0.78, 0.96, 1.0, 1.0)
		if shock_frame % 4 == 1
		else Color.WHITE
	)
	robot_failure_body.modulate = electric_tint
	robot_failure_left_arm_sprite.modulate = electric_tint
	robot_failure_right_arm_sprite.modulate = electric_tint
	robot_shadow.scale = Vector2(1.46, 0.54)
	_update_failure_sparks(shock_frame)


func _update_monster_idle() -> void:
	if _uses_sky_actors:
		var sky_phase := _scan_time * 1.18
		monster_motion.position = Vector2(
			sin(sky_phase * 0.62) * 3.6,
			-5.0 + sin(sky_phase) * 5.5
		)
		monster_motion.rotation = sin(sky_phase * 0.74) * 0.055
		monster_motion.scale = Vector2.ONE
		monster_shadow.scale = Vector2.ONE
		monster_shadow.modulate = Color.WHITE
		return
	if _uses_ocean_ecology:
		var float_phase := _scan_time * 1.35
		var float_lift := sin(float_phase)
		monster_motion.position = Vector2(
			sin(float_phase * 0.57) * 3.2,
			-7.0 + float_lift * 6.5
		)
		monster_motion.rotation = sin(float_phase * 0.72) * 0.045
		monster_motion.scale = Vector2(
			1.0 + sin(float_phase * 0.83) * 0.014,
			1.0 - sin(float_phase * 0.83) * 0.016
		)
		monster_shadow.scale = Vector2(
			1.0 - float_lift * 0.10,
			1.0 - float_lift * 0.05
		)
		monster_shadow.modulate.a = 0.70 - float_lift * 0.12
		return
	var breath := sin(_scan_time * TAU / 3.6)
	var cycle_time := fmod(_scan_time + 1.1, MONSTER_IDLE_CYCLE)
	var hop := 0.0
	if cycle_time < MONSTER_IDLE_HOP_DURATION:
		hop = sin(cycle_time / MONSTER_IDLE_HOP_DURATION * PI)
	monster_motion.position = Vector2(0.0, -4.5 * hop)
	monster_motion.rotation = sin(_scan_time * 1.15) * 0.018 + hop * 0.055
	monster_motion.scale = Vector2(
		1.0 - breath * 0.012 - hop * 0.018,
		1.0 + breath * 0.018 + hop * 0.035
	)
	monster_shadow.scale = Vector2(
		1.0 - hop * 0.18,
		1.0 - hop * 0.10
	)
	monster_shadow.modulate.a = lerpf(1.0, 0.62, hop)


func _update_scan_visuals(delta: float) -> void:
	if _dot_pop_time > 0.0:
		_dot_pop_time = maxf(0.0, _dot_pop_time - delta)
	if _charge_pulse_time > 0.0:
		_charge_pulse_time = maxf(0.0, _charge_pulse_time - delta)

	if _scan_animation == ScanAnimation.RESULT_SAFE or _scan_animation == ScanAnimation.RESULT_MINE:
		_update_scan_result(delta)
		return
	if _scan_animation == ScanAnimation.TARGETING:
		_scan_time += delta
		robot_scan_motion.position = Vector2(0.0, -2.0)
		robot_scan_motion.rotation = -0.045 + sin(_scan_time * 4.0) * 0.008
		monster_motion.position = Vector2.ZERO
		monster_motion.scale = Vector2.ONE
		monster_motion.rotation = -0.05
		monster_shadow.scale = Vector2.ONE
		monster_shadow.modulate = Color.WHITE
	else:
		robot_scan_motion.position = Vector2.ZERO
		robot_scan_motion.rotation = 0.0
		robot_scan_motion.scale = (
			Vector2.ONE * (1.0 + sin(_scan_time * 3.0) * 0.012)
			if _scan_available
			else Vector2.ONE
		)
		_scan_time += delta
		_update_monster_idle()

	_update_ocean_ecology_idle()
	if _charge_pulse_time > 0.0:
		var pulse := sin((1.0 - _charge_pulse_time / 0.42) * PI)
		plant_motion.scale = Vector2(1.0 - pulse * 0.03, 1.0 + pulse * 0.05)
		monster_motion.rotation += pulse * 0.035
	elif not (_uses_ocean_ecology and _level_number in [11, 12]):
		plant_motion.scale = Vector2.ONE
	_update_scan_dot_positions()


func _update_sky_robot_plane_flight() -> void:
	var flight_phase := _sky_flight_time * 0.92
	var shared_position := Vector2(
		sin(flight_phase * 0.56) * 1.8,
		sin(flight_phase) * 2.6
	)
	var shared_rotation := sin(flight_phase * 0.63) * 0.012
	sky_robot_plane_motion.position = SKY_PLANE_RIDE_OFFSET + shared_position
	sky_robot_plane_motion.rotation = shared_rotation
	if _reaction_mode == ReactionMode.READY:
		robot_failure_motion.position = shared_position
		robot_failure_motion.scale = Vector2.ONE
		robot_failure_motion.rotation = shared_rotation
	else:
		robot_motion.position += shared_position
		if _reaction_mode == ReactionMode.FAILURE:
			robot_motion.rotation = shared_rotation
		else:
			robot_motion.rotation += shared_rotation


func _update_ocean_robot_idle() -> void:
	if _uses_sky_actors:
		return
	if not _uses_ocean_ecology:
		robot_failure_motion.position = Vector2.ZERO
		robot_failure_motion.scale = Vector2.ONE
		robot_failure_motion.rotation = 0.0
		return
	var water_phase := _scan_time * 1.42
	var refraction := sin(water_phase * 0.91)
	robot_failure_motion.position = Vector2(
		sin(water_phase * 0.64) * 1.8,
		sin(water_phase) * 1.4
	)
	robot_failure_motion.scale = Vector2(
		1.0 + refraction * 0.012,
		1.0 - refraction * 0.014
	)
	robot_failure_motion.rotation = sin(water_phase * 0.53) * 0.009


func _update_ocean_ecology_idle() -> void:
	if _uses_sky_actors:
		var sky_ecology_phase := _scan_time * 0.88
		plant_motion.position = Vector2(
			sin(sky_ecology_phase * 0.61) * 1.2,
			-2.0 + sin(sky_ecology_phase) * 2.4
		)
		plant_motion.rotation = sin(sky_ecology_phase * 0.73) * 0.012
		return
	if not _uses_ocean_ecology:
		plant_motion.position = Vector2.ZERO
		plant_motion.rotation = 0.0
		return
	match _level_number:
		11:
			var float_phase := _scan_time * 1.55
			plant_motion.position = Vector2(
				sin(float_phase * 0.73) * 1.3,
				sin(float_phase) * 2.2 - 1.0
			)
			plant_motion.rotation = sin(float_phase * 0.61) * 0.025
			var pulse := sin(float_phase * 1.18)
			plant_motion.scale = Vector2(1.0 + pulse * 0.012, 1.0 - pulse * 0.016)
		12:
			var swim_phase := _scan_time * 1.35
			plant_motion.position = Vector2(
				sin(swim_phase) * 2.4,
				sin(swim_phase * 1.7) * 0.8
			)
			plant_motion.rotation = sin(swim_phase * 0.82) * 0.014
			plant_motion.scale = Vector2.ONE
		_:
			plant_motion.position = Vector2.ZERO
			plant_motion.rotation = 0.0


func _update_scan_result(delta: float) -> void:
	_scan_time += delta
	monster_shadow.scale = Vector2.ONE
	monster_shadow.modulate = Color.WHITE
	var progress := clampf(_scan_time / SCAN_RESULT_DURATION, 0.0, 1.0)
	var beam_progress := 1.0 - pow(1.0 - minf(progress / 0.42, 1.0), 3.0)
	var beam_start := _scan_beam_start()
	scan_beam.points = PackedVector2Array([
		beam_start,
		beam_start.lerp(_scan_target_local, beam_progress),
	])
	scan_beam.modulate.a = 1.0 - clampf((progress - 0.55) / 0.25, 0.0, 1.0)
	scan_beam.visible = progress < 0.80
	var impact := sin(minf(progress / 0.72, 1.0) * PI)
	robot_scan_motion.rotation = -0.08 * impact
	robot_scan_motion.scale = Vector2(1.0 + impact * 0.04, 1.0 - impact * 0.05)
	if _scan_animation == ScanAnimation.RESULT_SAFE:
		monster_motion.position = Vector2(0.0, -6.0 * impact)
	else:
		monster_motion.position = Vector2(-4.0 * impact, 0.0)
		monster_motion.scale = Vector2.ONE * (1.0 - impact * 0.06)
	if progress >= 1.0:
		_reset_scan_animation()


func _update_scan_dot_positions() -> void:
	if _reaction_mode != ReactionMode.READY:
		return
	for dot_index in dot_nodes.size():
		var position := _victory_dot_bases[dot_index]
		if _scan_available:
			position.y += sin(_scan_time * 3.2 + float(dot_index) * 1.8) * 2.2
		dot_nodes[dot_index].position = position
		var pop := 0.0
		if dot_index == _dot_pop_index and _dot_pop_time > 0.0:
			pop = sin((1.0 - _dot_pop_time / 0.38) * PI) * 0.34
		dot_nodes[dot_index].scale = Vector2.ONE * (1.0 + pop)


func _apply_scan_meter_visuals() -> void:
	if not is_instance_valid(victory_dots) or _reaction_mode != ReactionMode.READY:
		return
	victory_dots.visible = true
	for dot_index in dot_nodes.size():
		var dot := dot_nodes[dot_index]
		dot.position = _victory_dot_bases[dot_index]
		dot.scale = Vector2.ONE
		if _scan_used:
			dot.modulate = Color(0.42, 0.47, 0.40, 0.22)
		elif dot_index < _filled_dot_count:
			dot.modulate = (
				Color(0.62, 0.74, 0.66, 0.52)
				if _scan_locked
				else Color.WHITE
			)
		else:
			dot.modulate = Color(0.42, 0.56, 0.47, 0.30)


func _reset_scan_animation() -> void:
	_scan_animation = ScanAnimation.NONE
	_scan_time = 0.0
	scan_beam.visible = false
	scan_beam.modulate = Color.WHITE
	scan_hint_button.visible = _scan_available
	scan_hint_button.text = "点机器人扫描 · C"
	robot_scan_motion.position = Vector2.ZERO
	robot_scan_motion.scale = Vector2.ONE
	robot_scan_motion.rotation = 0.0
	if _reaction_mode == ReactionMode.READY:
		monster_motion.position = Vector2.ZERO
		monster_motion.scale = Vector2.ONE
		monster_motion.rotation = 0.0
		monster_shadow.scale = Vector2.ONE
		monster_shadow.modulate = Color.WHITE
		plant_motion.scale = Vector2.ONE
	_apply_scan_meter_visuals()
	_refresh_processing()


func _scan_beam_start() -> Vector2:
	if robot_sprite.texture == null:
		return actor_slots[0].position + Vector2(0.0, -60.0)
	var local_emitter := Vector2(0.0, -float(robot_sprite.texture.get_height()) * 0.30)
	return design_plane.to_local(robot_sprite.to_global(local_emitter))


func _refresh_processing() -> void:
	if not is_node_ready():
		return
	var scan_processing := (
		_scan_animation != ScanAnimation.NONE
		or _scan_available
		or _dot_pop_time > 0.0
		or _charge_pulse_time > 0.0
	)
	var idle_processing := _reaction_mode == ReactionMode.READY
	set_process(
		not _scan_paused
		and (_reaction_processing or scan_processing or idle_processing)
	)


func _bounce_lift(cycle_time: float, delay: float, duration: float) -> float:
	var local_time := fmod(cycle_time - delay + VICTORY_CYCLE, VICTORY_CYCLE)
	if local_time > duration:
		return 0.0
	return sin(local_time / duration * PI)


func _apply_victory_bounce(
	motion_root: Node2D,
	shadow: Control,
	lift: float,
	height: float
) -> void:
	motion_root.position = Vector2(0.0, -height * lift)
	motion_root.scale = Vector2(
		lerpf(1.0, 0.98, lift),
		lerpf(1.0, 1.04, lift)
	)
	shadow.scale = Vector2(
		lerpf(1.0, 0.72, lift),
		lerpf(1.0, 0.82, lift)
	)
	shadow.modulate.a = lerpf(1.0, 0.55, lift)


func _setup_failure_arm(
	sprite: Sprite2D,
	path: String,
	pivot_pixels: Vector2
) -> void:
	var texture := _load_texture(path)
	if texture == null:
		return
	var arm_scale := FAILURE_ARM_TARGET_HEIGHT / FAILURE_ARM_REFERENCE_HEIGHT
	sprite.texture = texture
	sprite.scale = Vector2.ONE * arm_scale
	sprite.position = (texture.get_size() * 0.5 - pivot_pixels) * arm_scale


func _apply_ecology_texture(path: String) -> void:
	var texture := _load_texture(path)
	if texture != null:
		plant_sprite.texture = texture


func _setup_actor(sprite: Sprite2D, path: String, maximum_size: Vector2) -> void:
	var texture := _load_texture(path)
	if texture == null:
		return
	sprite.texture = texture
	var texture_size := texture.get_size()
	var visible_rect := _get_visible_rect(texture)
	var visible_size := Vector2(visible_rect.size)
	var fit_scale := minf(
		maximum_size.x / visible_size.x,
		maximum_size.y / visible_size.y
	)
	var texture_center := texture_size * 0.5
	var visible_center_x := float(visible_rect.position.x) + visible_size.x * 0.5
	var visible_bottom := float(visible_rect.position.y + visible_rect.size.y)
	sprite.scale = Vector2.ONE * fit_scale
	sprite.position = Vector2(
		(texture_center.x - visible_center_x) * fit_scale,
		(texture_center.y - visible_bottom) * fit_scale
	)


func _get_visible_rect(texture: Texture2D) -> Rect2i:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.02:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null and path.get_extension().to_lower() == "png":
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture == null:
		push_error("Tabletop actor texture could not be loaded: %s" % path)
		return null
	_texture_cache[path] = texture
	return texture


func _apply_perspective_scales() -> void:
	for slot in actor_slots:
		var depth := clampf(
			(slot.position.y - TABLETOP_BACK_Y)
			/ (TABLETOP_FRONT_Y - TABLETOP_BACK_Y),
			0.0,
			1.0
		)
		var perspective_scale := lerpf(0.93, 1.04, depth)
		slot.scale = Vector2.ONE * perspective_scale


func _update_design_transform() -> void:
	if not is_instance_valid(design_plane) or size.x <= 0.0 or size.y <= 0.0:
		return
	var cover_scale := maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	design_plane.scale = Vector2.ONE * cover_scale
	design_plane.position = (size - DESIGN_SIZE * cover_scale) * 0.5
