@tool
class_name BadgeHall
extends Control

signal chapter_book_requested(chapter: StringName)
signal exit_requested

const UNIVERSE_COMPLETION_PROGRESS := 1000
const GALAXY_OUTER_ROTATION_SPEED := 0.18
const GALAXY_SPIRAL_ROTATION_SPEED := 0.28
const GALAXY_CORE_BREATH_SPEED := 0.62
const GALAXY_CORE_LIGHT_AMOUNT := 0.10
const GALAXY_ROTATION_SHADER := preload(
	"res://shaders/badge_hall_galaxy_rotation.gdshader"
)
const UNIVERSE_STAGE_ALPHA_LIMIT := 0.08
const UNIVERSE_LAYOUT_ATTEMPTS := 140
const UNIVERSE_LAYOUT_SPACING := 5.0

@export var completion_glow_enabled := true:
	set(value):
		completion_glow_enabled = value
		_queue_visual_refresh()

@onready var land_stage_initial: TextureRect = %LandStageInitial
@onready var land_completion_glow: ColorRect = %LandCompletionGlow
@onready var land_ecology_elements: Array[TextureRect] = [
	%LandEcologySprout,
	%LandEcologyShrub,
	%LandEcologyWetland,
	%LandEcologyGrassland,
	%LandEcologyForestEdge,
	%LandEcologyDenseForest,
	%LandEcologyAncientForest,
]
@onready var land_book_button: Button = %LandBookButton

@onready var ocean_stage_initial: TextureRect = %OceanStageInitial
@onready var ocean_completion_glow: ColorRect = %OceanCompletionGlow
@onready var ocean_ecology_elements: Array[TextureRect] = [
	%OceanEcologyAnemone,
	%OceanEcologySeagrass,
	%OceanEcologyCoral,
	%OceanEcologyJellyfish,
	%OceanEcologyFishSchool,
	%OceanEcologyTrench,
	%OceanEcologyWhaleFall,
]
@onready var ocean_book_button: Button = %OceanBookButton

@onready var sky_stage_initial: TextureRect = %SkyStageInitial
@onready var sky_completion_glow: ColorRect = %SkyCompletionGlow
@onready var sky_ecology_elements: Array[TextureRect] = [
	%SkyEcologyCloudCrown,
	%SkyEcologyWindRing,
	%SkyEcologyRainbowBridge,
	%SkyEcologyFloatingIsles,
	%SkyEcologyCloudRidge,
	%SkyEcologyStormEye,
	%SkyEcologySkyPalace,
]
@onready var sky_book_button: Button = %SkyBookButton

@onready var universe_stage: TextureRect = %UniverseStage
@onready var universe_asteroids: Array[TextureRect] = [
	%UniverseAsteroid01,
	%UniverseAsteroid02,
	%UniverseAsteroid03,
	%UniverseAsteroid04,
	%UniverseAsteroid05,
	%UniverseAsteroid06,
	%UniverseAsteroid07,
	%UniverseAsteroid08,
	%UniverseAsteroid09,
]
@onready var universe_planets: Array[TextureRect] = [
	%UniversePlanet01,
	%UniversePlanet02,
	%UniversePlanet03,
	%UniversePlanet04,
	%UniversePlanet05,
	%UniversePlanet06,
	%UniversePlanet07,
	%UniversePlanet08,
	%UniversePlanet09,
]
@onready var universe_clusters: Array[TextureRect] = [
	%UniverseCluster01,
	%UniverseCluster02,
	%UniverseCluster03,
	%UniverseCluster04,
	%UniverseCluster05,
	%UniverseCluster06,
	%UniverseCluster07,
	%UniverseCluster08,
	%UniverseCluster09,
]
@onready var universe_galaxy_outer: TextureRect = %UniverseGalaxyOuter
@onready var universe_galaxy_spiral: TextureRect = %UniverseGalaxySpiral
@onready var universe_galaxy_core: TextureRect = %UniverseGalaxyCore
@onready var universe_trophy: TextureRect = %UniverseTrophy
@onready var universe_title := get_node_or_null("%UniverseTitle") as Label
@onready var universe_total_value: Label = %UniverseTotalValue
@onready var hall_title: Label = %HallTitle
@onready var showcase_stages: Array[TextureRect] = [
	land_stage_initial,
	ocean_stage_initial,
	sky_stage_initial,
	universe_stage,
]

var _completed_levels: Dictionary = {}
var _glow_time := 0.0
var _universe_progress := 0
var _universe_completed := false
var _universe_trophy_placement_played := false
var _universe_trophy_tween: Tween
var _universe_trophy_rest_position := Vector2.ZERO
var _universe_trophy_rest_scale := Vector2.ONE
var _universe_galaxy_outer_rest_rotation := 0.0
var _universe_galaxy_spiral_rest_rotation := 0.0
var _universe_galaxy_core_rest_scale := Vector2.ONE
var _universe_galaxy_core_rest_modulate := Color.WHITE
var _universe_galaxy_center := Vector2.ZERO
var _universe_galaxy_outer_material: ShaderMaterial
var _universe_galaxy_spiral_material: ShaderMaterial


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	_store_universe_layout()
	land_book_button.pressed.connect(_on_chapter_book_pressed.bind(&"land"))
	ocean_book_button.pressed.connect(_on_chapter_book_pressed.bind(&"ocean"))
	sky_book_button.pressed.connect(_on_chapter_book_pressed.bind(&"sky"))
	refresh_language()
	_refresh_visuals()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree() \
			or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index not in [
		MOUSE_BUTTON_LEFT,
		MOUSE_BUTTON_RIGHT,
	]:
		return
	if _is_point_inside_showcase(mouse_event.position):
		return
	get_viewport().set_input_as_handled()
	exit_requested.emit()


func _is_point_inside_showcase(global_point: Vector2) -> bool:
	for stage in showcase_stages:
		if stage.visible and stage.get_global_rect().has_point(global_point):
			return true
	for element_group in [
		land_ecology_elements,
		ocean_ecology_elements,
		sky_ecology_elements,
		universe_asteroids,
		universe_planets,
		universe_clusters,
	]:
		for element in element_group:
			if element.visible and element.get_global_rect().has_point(global_point):
				return true
	for book_button in [land_book_button, ocean_book_button, sky_book_button]:
		if book_button.visible and book_button.get_global_rect().has_point(global_point):
			return true
	return false


func _process(delta: float) -> void:
	var has_visible_animation := false
	_glow_time += maxf(0.0, delta)
	if is_instance_valid(land_completion_glow) and land_completion_glow.visible:
		var land_pulse := sin(_glow_time * 1.15) * 0.5 + 0.5
		land_completion_glow.modulate.a = lerpf(0.76, 0.96, land_pulse)
		has_visible_animation = true
	if is_instance_valid(ocean_completion_glow) and ocean_completion_glow.visible:
		var ocean_pulse := sin(_glow_time * 1.08 + 0.8) * 0.5 + 0.5
		ocean_completion_glow.modulate.a = lerpf(0.76, 0.96, ocean_pulse)
		has_visible_animation = true
	if is_instance_valid(sky_completion_glow) and sky_completion_glow.visible:
		var sky_pulse := sin(_glow_time * 1.04 + 1.6) * 0.5 + 0.5
		sky_completion_glow.modulate.a = lerpf(0.76, 0.96, sky_pulse)
		has_visible_animation = true
	if is_instance_valid(universe_galaxy_outer) and universe_galaxy_outer.visible:
		if is_instance_valid(_universe_galaxy_outer_material):
			_universe_galaxy_outer_material.set_shader_parameter(
				"rotation_angle",
				fposmod(_glow_time * GALAXY_OUTER_ROTATION_SPEED, TAU)
			)
		if is_instance_valid(_universe_galaxy_spiral_material):
			_universe_galaxy_spiral_material.set_shader_parameter(
				"rotation_angle",
				fposmod(_glow_time * GALAXY_SPIRAL_ROTATION_SPEED, TAU)
			)
		universe_galaxy_core.scale = _universe_galaxy_core_rest_scale
		var core_light := smoothstep(
			0.0,
			1.0,
			sin(_glow_time * GALAXY_CORE_BREATH_SPEED) * 0.5 + 0.5
		)
		var core_brightness := lerpf(
			1.0 - GALAXY_CORE_LIGHT_AMOUNT,
			1.0,
			core_light
		)
		var core_modulate := _universe_galaxy_core_rest_modulate
		core_modulate.r *= core_brightness
		core_modulate.g *= core_brightness
		core_modulate.b *= core_brightness
		universe_galaxy_core.modulate = core_modulate
		has_visible_animation = true
	if not has_visible_animation:
		set_process(false)


func set_completed_levels(completed_levels: Array) -> void:
	_completed_levels.clear()
	for level_value in completed_levels:
		_completed_levels[int(level_value)] = true
	_queue_visual_refresh()


func set_universe_progress(
	progress: int,
	milestone_unlocked: bool = false
) -> void:
	_universe_progress = maxi(0, progress)
	if milestone_unlocked or _universe_progress >= UNIVERSE_COMPLETION_PROGRESS:
		_universe_completed = true
	_queue_visual_refresh()


func play_universe_trophy_placement() -> void:
	if (
		not is_node_ready()
		or not _universe_completed
		or _universe_trophy_placement_played
	):
		return
	_universe_trophy_placement_played = true
	universe_total_value.text = tr("TXT_0479")
	if is_instance_valid(_universe_trophy_tween):
		_universe_trophy_tween.kill()

	var target_position := _universe_trophy_rest_position
	var target_scale := _universe_trophy_rest_scale
	var galaxy_center := _universe_galaxy_center
	universe_trophy.visible = true
	universe_trophy.position = galaxy_center - universe_trophy.pivot_offset
	universe_trophy.scale = target_scale * 0.16
	universe_trophy.modulate.a = 0.0

	_universe_trophy_tween = create_tween()
	_universe_trophy_tween.set_parallel(true)
	_universe_trophy_tween.tween_property(
		universe_trophy,
		"position",
		target_position,
		0.72
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_universe_trophy_tween.tween_property(
		universe_trophy,
		"scale",
		target_scale,
		0.72
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_universe_trophy_tween.tween_property(
		universe_trophy,
		"modulate:a",
		1.0,
		0.28
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_universe_trophy_tween.set_parallel(false)
	_universe_trophy_tween.tween_interval(1.8)
	_universe_trophy_tween.tween_callback(
		func() -> void:
			universe_total_value.text = tr("TXT_0475") % _universe_progress
	)


func focus_chapter(chapter: StringName) -> void:
	if not is_node_ready():
		return
	match chapter:
		&"ocean":
			ocean_book_button.grab_focus()
		&"sky":
			sky_book_button.grab_focus()
		&"universe":
			grab_focus()
		_:
			land_book_button.grab_focus()


func refresh_language() -> void:
	if not is_node_ready():
		return
	hall_title.text = tr("TXT_0473")
	if universe_title != null:
		universe_title.text = tr("TXT_0474")
	universe_total_value.text = tr("TXT_0475") % _universe_progress


func _queue_visual_refresh() -> void:
	if is_inside_tree() and not Engine.is_editor_hint():
		call_deferred("_refresh_visuals")


func _refresh_visuals() -> void:
	if not is_node_ready() or Engine.is_editor_hint():
		return
	land_stage_initial.visible = true
	ocean_stage_initial.visible = true
	sky_stage_initial.visible = true
	universe_stage.visible = true

	var land_complete := _apply_chapter_progress(land_ecology_elements, 1)
	var ocean_complete := _apply_chapter_progress(ocean_ecology_elements, 8)
	var sky_complete := _apply_chapter_progress(sky_ecology_elements, 15)
	land_completion_glow.visible = land_complete and completion_glow_enabled
	ocean_completion_glow.visible = ocean_complete and completion_glow_enabled
	sky_completion_glow.visible = sky_complete and completion_glow_enabled
	_refresh_universe_visuals()

	_glow_time = 0.0
	land_completion_glow.modulate.a = 0.86
	ocean_completion_glow.modulate.a = 0.86
	sky_completion_glow.modulate.a = 0.86
	_update_process_state()


func _store_universe_layout() -> void:
	_universe_trophy_rest_position = universe_trophy.position
	_universe_trophy_rest_scale = universe_trophy.scale
	_universe_galaxy_outer_rest_rotation = universe_galaxy_outer.rotation
	_universe_galaxy_spiral_rest_rotation = universe_galaxy_spiral.rotation
	_universe_galaxy_core_rest_scale = universe_galaxy_core.scale
	_universe_galaxy_core_rest_modulate = universe_galaxy_core.modulate
	_universe_galaxy_center = (
		universe_galaxy_outer.position + universe_galaxy_outer.size * 0.5
		+ universe_galaxy_spiral.position + universe_galaxy_spiral.size * 0.5
		+ universe_galaxy_core.position + universe_galaxy_core.size * 0.5
	) / 3.0
	for element in universe_clusters + universe_planets + universe_asteroids:
		element.pivot_offset = element.size * 0.5
	universe_galaxy_outer.pivot_offset = universe_galaxy_outer.size * 0.5
	universe_galaxy_spiral.pivot_offset = universe_galaxy_spiral.size * 0.5
	universe_galaxy_core.pivot_offset = universe_galaxy_core.size * 0.5
	_universe_galaxy_outer_material = _create_galaxy_rotation_material(
		universe_galaxy_outer
	)
	_universe_galaxy_spiral_material = _create_galaxy_rotation_material(
		universe_galaxy_spiral
	)
	universe_galaxy_outer.material = _universe_galaxy_outer_material
	universe_galaxy_spiral.material = _universe_galaxy_spiral_material
	universe_galaxy_outer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	universe_galaxy_spiral.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	universe_galaxy_core.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	universe_trophy.pivot_offset = universe_trophy.size * 0.5


func _create_galaxy_rotation_material(layer: TextureRect) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GALAXY_ROTATION_SHADER
	material.set_shader_parameter(
		"aspect_ratio",
		layer.size.x / maxf(1.0, layer.size.y)
	)
	material.set_shader_parameter(
		"pivot_uv",
		Vector2(
			(_universe_galaxy_center.x - layer.position.x)
			/ maxf(1.0, layer.size.x),
			(_universe_galaxy_center.y - layer.position.y)
			/ maxf(1.0, layer.size.y)
		)
	)
	return material


func _refresh_universe_visuals() -> void:
	universe_total_value.text = tr("TXT_0475") % _universe_progress
	if _universe_completed:
		_set_visible_count(universe_asteroids, 0)
		_set_visible_count(universe_planets, 0)
		_set_visible_count(universe_clusters, 0)
		universe_galaxy_outer.visible = true
		universe_galaxy_spiral.visible = true
		universe_galaxy_core.visible = true
		universe_trophy.visible = true
		return

	var asteroid_count := _universe_progress % 10
	var planet_count := int(_universe_progress / 10.0) % 10
	var cluster_count := int(_universe_progress / 100.0) % 10
	_set_visible_count(universe_asteroids, asteroid_count)
	_set_visible_count(universe_planets, planet_count)
	_set_visible_count(universe_clusters, cluster_count)
	_layout_universe_progress_elements(
		asteroid_count,
		planet_count,
		cluster_count
	)
	universe_galaxy_outer.visible = false
	universe_galaxy_spiral.visible = false
	universe_galaxy_core.visible = false
	universe_galaxy_outer.rotation = _universe_galaxy_outer_rest_rotation
	universe_galaxy_spiral.rotation = _universe_galaxy_spiral_rest_rotation
	if is_instance_valid(_universe_galaxy_outer_material):
		_universe_galaxy_outer_material.set_shader_parameter("rotation_angle", 0.0)
	if is_instance_valid(_universe_galaxy_spiral_material):
		_universe_galaxy_spiral_material.set_shader_parameter("rotation_angle", 0.0)
	universe_galaxy_core.scale = _universe_galaxy_core_rest_scale
	universe_galaxy_core.modulate = _universe_galaxy_core_rest_modulate
	universe_trophy.visible = false
	universe_trophy.position = _universe_trophy_rest_position
	universe_trophy.scale = _universe_trophy_rest_scale
	universe_trophy.modulate.a = 1.0


func _layout_universe_progress_elements(
	asteroid_count: int,
	planet_count: int,
	cluster_count: int
) -> void:
	if asteroid_count + planet_count + cluster_count <= 0:
		return
	if universe_stage.texture == null:
		return
	var stage_image := universe_stage.texture.get_image()
	if stage_image == null or stage_image.is_empty():
		return
	var texture_size := Vector2(stage_image.get_width(), stage_image.get_height())
	var texture_scale := minf(
		universe_stage.size.x / texture_size.x,
		universe_stage.size.y / texture_size.y
	)
	if texture_scale <= 0.0:
		return
	var content_size := texture_size * texture_scale
	var content_rect := Rect2(
		universe_stage.position + (universe_stage.size - content_size) * 0.5,
		content_size
	)
	var open_spans: Dictionary = {}
	for image_y in range(
		int(texture_size.y * 0.31),
		int(texture_size.y * 0.62) + 1
	):
		var span := _universe_open_span_at_y(stage_image, image_y)
		if span.x >= 0.0:
			open_spans[image_y] = span
	var open_rows := open_spans.keys()
	if open_rows.is_empty():
		return
	var elements: Array[TextureRect] = []
	for index in cluster_count:
		elements.append(universe_clusters[index])
	for index in planet_count:
		elements.append(universe_planets[index])
	for index in asteroid_count:
		elements.append(universe_asteroids[index])
	var rng := RandomNumberGenerator.new()
	rng.seed = 86243 + _universe_progress * 104729
	var occupied_rects: Array[Rect2] = []
	for element in elements:
		var placed := false
		var half_image_size := element.size * 0.5 / texture_scale
		for _attempt in UNIVERSE_LAYOUT_ATTEMPTS:
			var image_y := int(open_rows[rng.randi_range(0, open_rows.size() - 1)])
			var open_span: Vector2 = open_spans[image_y]
			var minimum_x := ceili(open_span.x + half_image_size.x + 8.0)
			var maximum_x := floori(open_span.y - half_image_size.x - 8.0)
			if minimum_x > maximum_x:
				continue
			var image_center := Vector2(
				rng.randi_range(minimum_x, maximum_x),
				image_y
			)
			if not _universe_stage_area_is_clear(
				stage_image,
				image_center,
				half_image_size
			):
				continue
			var local_center := content_rect.position + Vector2(
				image_center.x / texture_size.x * content_rect.size.x,
				image_center.y / texture_size.y * content_rect.size.y
			)
			var candidate_rect := Rect2(
				local_center - element.size * 0.5,
				element.size
			).grow(UNIVERSE_LAYOUT_SPACING)
			var overlaps_existing := false
			for occupied in occupied_rects:
				if occupied.intersects(candidate_rect):
					overlaps_existing = true
					break
			if overlaps_existing:
				continue
			element.position = local_center - element.size * 0.5
			var rotation_limit := 0.16 if element in universe_asteroids else 0.07
			element.rotation = rng.randf_range(-rotation_limit, rotation_limit)
			occupied_rects.append(candidate_rect)
			placed = true
			break
		if not placed:
			occupied_rects.append(
				Rect2(element.position, element.size).grow(UNIVERSE_LAYOUT_SPACING)
			)


func _universe_open_span_at_y(image: Image, y: int) -> Vector2:
	var width := image.get_width()
	var center_x := int(width / 2)
	if image.get_pixel(center_x, y).a > UNIVERSE_STAGE_ALPHA_LIMIT:
		return Vector2(-1.0, -1.0)
	var left_boundary := -1
	for x in range(center_x, 0, -1):
		if image.get_pixel(x, y).a > UNIVERSE_STAGE_ALPHA_LIMIT:
			left_boundary = x + 1
			break
	var right_boundary := -1
	for x in range(center_x, width):
		if image.get_pixel(x, y).a > UNIVERSE_STAGE_ALPHA_LIMIT:
			right_boundary = x - 1
			break
	if left_boundary < 0 or right_boundary <= left_boundary:
		return Vector2(-1.0, -1.0)
	return Vector2(left_boundary, right_boundary)


func _universe_stage_area_is_clear(
	image: Image,
	center: Vector2,
	half_size: Vector2
) -> bool:
	for y_step in range(5):
		var y_ratio := float(y_step) / 4.0
		for x_step in range(5):
			var x_ratio := float(x_step) / 4.0
			var sample := center + Vector2(
				lerpf(-half_size.x, half_size.x, x_ratio),
				lerpf(-half_size.y, half_size.y, y_ratio)
			)
			var sample_x := roundi(sample.x)
			var sample_y := roundi(sample.y)
			if sample_x < 0 or sample_x >= image.get_width() \
					or sample_y < 0 or sample_y >= image.get_height():
				return false
			if image.get_pixel(sample_x, sample_y).a \
					> UNIVERSE_STAGE_ALPHA_LIMIT:
				return false
	return true


func _set_visible_count(elements: Array[TextureRect], visible_count: int) -> void:
	for element_index in elements.size():
		elements[element_index].visible = element_index < visible_count


func _update_process_state() -> void:
	set_process(
		land_completion_glow.visible
		or ocean_completion_glow.visible
		or sky_completion_glow.visible
		or universe_galaxy_outer.visible
	)


func _apply_chapter_progress(
	elements: Array[TextureRect],
	first_level: int
) -> bool:
	var completed_count := 0
	for ecology_index in elements.size():
		var is_completed := _completed_levels.has(first_level + ecology_index)
		elements[ecology_index].visible = is_completed
		if is_completed:
			completed_count += 1
	return completed_count == elements.size()


func _on_chapter_book_pressed(chapter: StringName) -> void:
	chapter_book_requested.emit(chapter)
