extends Control

const ART := preload("res://scripts/art_catalog.gd")
const CELL_SCRIPT := preload("res://scripts/cell.gd")
const LOCALIZATION_STYLE := preload("res://scripts/localization_style.gd")
const UI_FONT := preload(ART.UI_FONT)
const CHARGE_LIGHT_STYLE := preload("res://themes/victory_light_dot_style.tres")
const LAND_STATES := [&"hidden", &"number", &"flagged", &"polluted", &"obstacle", &"nodule", &"root", &"cleansed_nodule", &"cleansed_root", &"confirmed", &"scan_target"]
const OCEAN_STATES := [&"hidden", &"number", &"flagged", &"polluted", &"floating", &"tide", &"confirmed", &"scan_target"]

var _content: Control
var _design_size := Vector2.ONE


# Only the isolated MineCell is instantiated. No board, model, save or actor
# controller is used; all other specimens are textures, labels or static drawing.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	set_process(false)
	resized.connect(_layout_content)


func show_element(spec: Dictionary, section: StringName) -> void:
	if is_instance_valid(_content):
		_content.free()
	_content = _static_content(self)
	_build_preview(spec, section)
	LOCALIZATION_STYLE.apply(_content, TranslationServer.get_locale())
	_layout_content()


func _static_content(parent: Control) -> Control:
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.focus_mode = Control.FOCUS_NONE
	content.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(content)
	return content


func _build_preview(spec: Dictionary, section: StringName) -> void:
	var kind := StringName(spec.get("kind", &""))
	match kind:
		&"group":
			_build_group(spec, section)
		&"grid":
			_build_grid(spec, section)
		&"cell":
			_build_cell(spec, section)
		&"texture":
			_build_texture(spec)
		&"readout":
			_build_readout(spec)
		&"top_hud":
			_build_top_hud(spec, section)
		&"meter":
			_build_meter(spec)
		&"links":
			_build_links(spec)
		&"sky_effect":
			_build_sky_effect(spec)
		_:
			assert(false, "Unsupported help preview kind: %s" % kind)


# Existing leaf builders share one drawing target. Temporarily select a child
# target so groups and grids reuse exactly the same frozen specimens.
func _build_in(target: Control, spec: Dictionary, section: StringName) -> Vector2:
	var previous_content := _content
	var previous_size := _design_size
	_content = target
	_build_preview(spec, section)
	var result := _design_size
	target.size = result
	_content = previous_content
	_design_size = previous_size
	return result


func _build_group(spec: Dictionary, section: StringName) -> void:
	var items: Array = spec.get("items", [])
	assert(items.size() >= 1 and items.size() <= 3, "Help groups require 1–3 items")
	_design_size = Vector2(700.0, 220.0)
	var slot_width := _design_size.x / float(items.size())
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var preview: Dictionary = item["preview"]
		var kind := StringName(preview.get("kind", &""))
		assert(kind != &"group", "Help groups cannot contain nested groups")
		var specimen := _static_content(_content)
		var specimen_size := _build_in(specimen, preview, section)
		var has_caption := item.has("caption")
		var visual_height := 180.0 if has_caption else 212.0
		var fit := minf((slot_width - 16.0) / specimen_size.x, visual_height / specimen_size.y)
		# Standalone cell art should not become an oversized icon; wide
		# illustrations may use the full slot rather than a leaf-size ceiling.
		if kind == &"cell":
			fit = minf(fit, 1.4)
		specimen.scale = Vector2.ONE * fit
		specimen.position = Vector2(
			slot_width * float(index) + (slot_width - specimen_size.x * fit) * 0.5,
			(visual_height - specimen_size.y * fit) * 0.5 + 4.0
		)
		if has_caption:
			var caption := _label(_translated_key(item["caption"]), 20)
			caption.position = Vector2(slot_width * float(index) + 8.0, 184.0)
			caption.size = Vector2(slot_width - 16.0, 36.0)
			_content.add_child(caption)


func _build_grid(spec: Dictionary, section: StringName) -> void:
	var cell_theme := StringName(spec.get("theme", section))
	var preset := StringName(spec.get("preset", &"neighbors"))
	assert(cell_theme in [&"land", &"ocean"], "Help grid theme must be land or ocean")
	assert(preset in [&"neighbors", &"expand_before", &"expand_after"], "Unsupported help grid preset")
	var ocean := cell_theme == &"ocean"
	# Axial coordinates give the ocean center exactly six real neighbors.
	# Both layouts use the same two actual mines for every preview state.
	var coordinates: Array[Vector2i] = []
	var mines: Array[Vector2i] = []
	if ocean:
		coordinates.assign([
			Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
		])
		mines.assign([Vector2i(1, 0), Vector2i(-1, 0)])
		_design_size = Vector2(192.0, 184.0)
	else:
		for row in range(-1, 2):
			for column in range(-1, 2):
				coordinates.append(Vector2i(column, row))
		mines.assign([Vector2i(-1, -1), Vector2i(1, 1)])
		_design_size = Vector2(180.0, 180.0)
	for coordinate in coordinates:
		var is_mine := coordinate in mines
		var state: StringName = &"hidden"
		if is_mine:
			state = &"polluted" if preset == &"neighbors" else &"flagged"
		elif coordinate == Vector2i.ZERO or preset == &"expand_after":
			state = &"number"
		var adjacent_count := 0
		for mine in mines:
			var delta := coordinate - mine
			var distance: int
			if ocean:
				distance = maxi(maxi(absi(delta.x), absi(delta.y)), absi(delta.x + delta.y))
			else:
				distance = maxi(absi(delta.x), absi(delta.y))
			if distance == 1:
				adjacent_count += 1
		var specimen := _static_content(_content)
		var specimen_size := _build_in(specimen, {
			"kind": &"cell", "theme": cell_theme, "state": state, "number": adjacent_count
		}, section)
		var cell_size := Vector2(62.0, 72.0) if ocean else Vector2(60.0, 60.0)
		var center: Vector2
		if ocean:
			center = _design_size * 0.5 + Vector2(
				62.353829 * (float(coordinate.x) + float(coordinate.y) * 0.5),
				54.0 * float(coordinate.y)
			)
		else:
			center = _design_size * 0.5 + Vector2(coordinate) * 60.0
		specimen.scale = cell_size / specimen_size
		specimen.position = center - cell_size * 0.5


func _build_cell(spec: Dictionary, section: StringName) -> void:
	var cell_theme := StringName(spec.get("theme", section))
	var state := StringName(spec.get("state", &"hidden"))
	assert(cell_theme in [&"land", &"ocean"], "Help cell theme must be land or ocean")
	var ocean := cell_theme == &"ocean"
	assert(state in (OCEAN_STATES if ocean else LAND_STATES), "Unsupported help cell state: %s/%s" % [cell_theme, state])
	_design_size = Vector2(124.0, 144.0) if ocean else Vector2(132.0, 132.0)
	var cell := CELL_SCRIPT.new() as MineCell
	var nodule := state in [&"nodule", &"root", &"cleansed_nodule", &"cleansed_root"]
	var level_number := 8 if ocean else 1
	if state == &"obstacle":
		level_number = 3
	elif state in [&"nodule", &"cleansed_nodule"]:
		level_number = 5
	elif state in [&"root", &"cleansed_root"]:
		level_number = 7
	elif state == &"floating":
		level_number = 11
	elif state == &"tide":
		level_number = 13
	# setup and root configuration must precede add_child/_ready so the
	# component loads the correct special-cell resources and style boxes.
	cell.setup(0, level_number, &"hex_pointy_odd_r" if ocean else &"square", state == &"obstacle", 0, nodule)
	if state in [&"root", &"cleansed_root"]:
		cell.configure_boss_root_segment(true, MineCell.OBSTACLE_EAST | MineCell.OBSTACLE_WEST)
	cell.set_tooltips_enabled(false)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.focus_mode = Control.FOCUS_NONE
	cell.process_mode = Node.PROCESS_MODE_DISABLED
	cell.custom_minimum_size = Vector2.ZERO
	_content.add_child(cell)
	cell.position = Vector2.ZERO
	cell.size = _design_size
	if state == &"floating":
		cell.configure_mobile_current(true, true, 0.0, false)
	elif state == &"tide":
		var empty_sides: Array[int] = []
		var boundary_sides: Array[int] = [0, 1]
		cell.configure_ocean_mechanics(empty_sides, empty_sides, empty_sides, empty_sides, boundary_sides, 2, true)
	cell.render_state(
		state == &"number", state == &"flagged", state == &"polluted",
		int(spec.get("number", 2)) if state == &"number" else 0,
		state != &"scan_target", false, false, false, state == &"confirmed",
		nodule, state in [&"cleansed_nodule", &"cleansed_root"], false, false,
		state == &"tide"
	)
	if state == &"scan_target":
		# The component hides target feedback when its gameplay lock is set.
		# Keep only that visual flag unlocked; disabled + ignored mouse +
		# no focus + disabled processing still prohibit every input route.
		cell.set_scan_target_mode(true, true)
		cell.disabled = true
	# Freeze completed marker/appearance poses, not their zero-size first frame.
	if state == &"flagged":
		cell.biosensor_progress = 1.0
	elif state == &"polluted":
		cell.set("_oil_time", 0.42)
	cell.set_process(false)
	cell.set_physics_process(false)
	cell.set_process_input(false)
	cell.set_process_unhandled_input(false)
	cell.set_process_unhandled_key_input(false)
	cell.queue_redraw()


func _build_texture(spec: Dictionary) -> void:
	_design_size = Vector2(440.0, 142.0)
	var texture := _texture(str(spec["path"]), Rect2(Vector2.ZERO, _design_size))
	var artwork_size := texture.texture.get_size()
	var artwork_fit := minf(_design_size.x / artwork_size.x, _design_size.y / artwork_size.y)
	_design_size = artwork_size * artwork_fit
	texture.size = _design_size
	if spec.has("caption"):
		# A blank button's translated caption is part of its recognizable UI.
		var caption := _label(_translated_key(spec["caption"]), 25)
		caption.position = Vector2(12.0, 8.0)
		caption.size = _design_size - Vector2(24.0, 16.0)
		texture.add_child(caption)


func _build_readout(spec: Dictionary) -> void:
	var lines := PackedStringArray()
	for line_value in spec["lines"]:
		var line: Dictionary = line_value
		var text := _translated_key(line["text"])
		if line.has("args"):
			text = text % line["args"]
		lines.append(text)
	_design_size = Vector2(640.0 if bool(spec.get("wide", false)) else 300.0, 192.0)
	var paper := _texture(ART.LEVEL_01_NOTE_STRAIGHT, Rect2(Vector2.ZERO, _design_size))
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	var value := _label("\n".join(lines), 24)
	value.position = Vector2(_design_size.x * 0.14, 8.0)
	value.size = Vector2(_design_size.x * 0.72, _design_size.y - 16.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.add_theme_constant_override("line_spacing", 0)
	_content.add_child(value)

func _build_top_hud(spec: Dictionary, section: StringName) -> void:
	var field := StringName(spec["field"])
	assert(field in [&"flags", &"timer"] and section in [&"land", &"ocean", &"sky"])
	var timer := field == &"timer"
	var frame_path: String = ART.LAND_V2_COUNTER_FRAME
	var icon_path: String = ART.LAND_V2_TIMER_ICON if timer else ART.LAND_V2_COUNTER_ICON
	if section == &"ocean":
		frame_path = ART.OCEAN_V2_COUNTER_FRAME
		icon_path = ART.OCEAN_V2_TIMER_ICON if timer else ART.OCEAN_V2_COUNTER_ICON
	elif section == &"sky":
		frame_path = ART.SKY_V2_COUNTER_FRAME
		icon_path = ART.SKY_V2_TIMER_ICON if timer else ART.SKY_V2_COUNTER_ICON
	# Match the real TopHud frames, icon positions and label typography.
	_design_size = Vector2(228.2857 if timer else 206.8571, 90.0)
	var frame := _texture(frame_path, Rect2(Vector2.ZERO, _design_size))
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	var icon_rect := Rect2(26.1428, 15.1429, 52.0, 58.0) if timer else Rect2(17.1428, 23.7143, 61.4286, 49.1429)
	_texture(icon_path, icon_rect)
	var value := _label("00:12.3" if timer else "2/10", 22 if timer else 26)
	value.position = Vector2(91.1429, 15.7143) if timer else Vector2(80.8571, 18.0)
	value.size = Vector2(104.0 if timer else 112.0, 58.0)
	var ocean := section == &"ocean"
	value.add_theme_color_override("font_color", Color(0.91, 0.98, 1.0) if ocean else Color(0.9725, 0.9255, 0.7882))
	value.add_theme_color_override("font_shadow_color", Color(0.03, 0.12, 0.18, 0.7) if ocean else Color(0.0863, 0.0667, 0.0431, 0.7))
	value.add_theme_constant_override("shadow_offset_x", 1)
	value.add_theme_constant_override("shadow_offset_y", 2)
	_content.add_child(value)



func _build_meter(spec: Dictionary) -> void:
	_design_size = Vector2(170.0, 146.0)
	_texture(str(spec["path"]), Rect2(30.0, 28.0, 110.0, 112.0))
	# Same 8x8 panels, style and unfilled tint as LandTabletopActors.
	var light_positions: Array[Vector2] = [Vector2(63.0, 18.0), Vector2(81.0, 10.0), Vector2(99.0, 18.0)]
	for index in range(3):
		var light := Panel.new()
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.focus_mode = Control.FOCUS_NONE
		light.position = light_positions[index]
		light.size = Vector2(8.0, 8.0)
		light.add_theme_stylebox_override("panel", CHARGE_LIGHT_STYLE)
		if index == 2:
			light.modulate = Color(0.42, 0.56, 0.47, 0.30)
		_content.add_child(light)


func _build_links(spec: Dictionary) -> void:
	_design_size = Vector2(360.0, 144.0)
	var illustration := UniverseIllustration.new()
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.focus_mode = Control.FOCUS_NONE
	illustration.variant = StringName(spec.get("variant", &"normal"))
	illustration.state = StringName(spec.get("state", &""))
	illustration.number = int(spec.get("number", 2))
	illustration.hub = bool(spec.get("hub", false))
	assert(illustration.variant in [&"normal", &"wormhole", &"bridge"], "Unsupported universe link variant")
	assert(illustration.state in [&"", &"hidden", &"number", &"flagged", &"polluted", &"shield"], "Unsupported universe star state")
	illustration.size = _design_size
	_content.add_child(illustration)


func _build_sky_effect(spec: Dictionary) -> void:
	_design_size = Vector2(320.0, 144.0)
	var illustration := SkyEffectIllustration.new()
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.focus_mode = Control.FOCUS_NONE
	illustration.variant = StringName(spec["variant"])
	assert(illustration.variant in [&"breeze", &"shield", &"eye_arrow"], "Unsupported sky feedback variant")
	illustration.size = _design_size
	_content.add_child(illustration)


func _texture(path: String, rect: Rect2) -> TextureRect:
	var texture := load(path) as Texture2D
	assert(texture != null, "Help artwork could not be loaded: %s" % path)
	var image := TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.focus_mode = Control.FOCUS_NONE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = texture
	image.position = rect.position
	image.size = rect.size
	_content.add_child(image)
	return image


func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.text = text_value
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("294d3c"))
	return label


func _translated_key(value: Variant) -> String:
	var key := str(value)
	assert(key.begins_with("TXT_"), "Help captions must use permanent TXT keys")
	return tr(key)


func _layout_content() -> void:
	if not is_instance_valid(_content):
		return
	var available := (size - Vector2(16.0, 12.0)).max(Vector2.ZERO)
	var fit := minf(available.x / _design_size.x, available.y / _design_size.y)
	# Let broad specimens fill the illustration area, but keep isolated icons
	# within a modest enlargement of their original rendering size.
	fit = minf(fit, 1.4)
	_content.size = _design_size
	_content.scale = Vector2.ONE * fit
	_content.position = (size - _design_size * fit) * 0.5


# Frozen copies of UniverseEndlessBoard's node, beacon, pollution, shield,
# ordinary-edge, bridge and wormhole drawing. The real board uses procedural
# circles/curves rather than a star texture. No model or elapsed time is needed.
class UniverseIllustration:
	extends Control

	const FONT := preload("res://assets/art/common/fonts/ui_handwritten_zh.ttf")
	const NUMBER_COLORS := [Color("2d6f91"), Color("3d7d5a"), Color("9a742c"), Color("a64f62"), Color("6f5a9d"), Color("397b7a"), Color("a66536"), Color("384857")]

	var variant: StringName = &"normal"
	var state: StringName = &""
	var number := 2
	var hub := false


	func _draw() -> void:
		if not state.is_empty():
			var specimen_scale := 1.45 if state == &"shield" else 2.0
			draw_set_transform(size * 0.5, 0.0, Vector2.ONE * specimen_scale)
			_draw_node(Vector2.ZERO, state, hub)
			if state == &"shield":
				for ring_index in range(3):
					var radius := 27.0 + float(ring_index) * 8.0
					draw_arc(Vector2.ZERO, radius, -0.3 + float(ring_index) * 0.7, -0.3 + float(ring_index) * 0.7 + TAU * 0.82, 40, Color(0.45, 0.84, 1.0, 0.61), 2.8)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		var from := Vector2(68.0, 83.0)
		var to := Vector2(292.0, 83.0)
		if variant == &"normal":
			draw_line(from + Vector2(22.0 if hub else 17.0, 0.0), to - Vector2(17.0, 0.0), Color(0.70, 0.76, 0.77, 0.58), 1.45, true)
		else:
			_draw_curve(from, to)
		_draw_node(from, &"hidden", hub)
		_draw_node(to, &"hidden")


	func _draw_curve(from: Vector2, to: Vector2) -> void:
		var wormhole := variant == &"wormhole"
		var curve_from := from if wormhole else from + Vector2(22.0 if hub else 17.0, 0.0)
		var curve_to := to if wormhole else to - Vector2(17.0, 0.0)
		var direction := curve_to - curve_from
		var perpendicular := Vector2(-direction.y, direction.x).normalized()
		var bend := minf(96.0, direction.length() * 0.22) if wormhole else clampf(direction.length() * 0.13, 18.0, 58.0)
		var control := (curve_from + curve_to) * 0.5 - perpendicular * bend
		var steps := 24 if wormhole else 18
		var curve := PackedVector2Array()
		for step in range(steps + 1):
			var t := float(step) / float(steps)
			var inverse := 1.0 - t
			curve.append(inverse * inverse * curve_from + 2.0 * inverse * t * control + t * t * curve_to)
		if wormhole:
			draw_polyline(curve, Color(0.70, 0.35, 0.96, 0.70), 4.2, true)
			draw_polyline(curve, Color(0.88, 0.72, 1.0, 0.504), 1.25, true)
			draw_circle(curve[12], 2.7, Color(0.94, 0.82, 1.0, 0.70))
			for endpoint in [from, to]:
				draw_arc(endpoint, 20.5, 0.0, TAU * 0.76, 24, Color(0.74, 0.43, 1.0, 0.70), 2.0)
		else:
			draw_polyline(curve, Color(0.38, 0.72, 0.86, 0.50), 2.2, true)
			draw_polyline(curve, Color(0.78, 0.91, 0.94, 0.36), 1.0, true)
			draw_circle(curve[9], 2.0, Color(0.88, 0.96, 0.95, 0.50))


	func _draw_node(center: Vector2, node_state: StringName, is_hub: bool = false) -> void:
		var radius := 20.0 if is_hub else 15.0
		if is_hub:
			draw_circle(center, radius + 8.0, Color(0.76, 0.68, 0.45, 0.18))
			draw_arc(center, radius + 5.0, 0.0, TAU * 0.78, 32, Color(0.88, 0.76, 0.43, 0.82), 2.0)
		var fill := Color("e8e1d0")
		var edge := Color("8297a0")
		if node_state in [&"number", &"shield"]:
			fill = Color("badce2")
			edge = Color("568996")
		elif node_state == &"polluted":
			fill = Color("70506f")
			edge = Color("b46b91")
		elif node_state == &"flagged":
			fill = Color("d9e1db")
			edge = Color("c49535")
		draw_circle(center, radius + 2.0, Color(edge, 0.24))
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 32, edge, 2.0)
		draw_circle(center + Vector2(-radius * 0.34, -radius * 0.38), 2.6, Color(1.0, 1.0, 1.0, 0.42))
		match node_state:
			&"number":
				var color: Color = NUMBER_COLORS[clampi(number - 1, 0, NUMBER_COLORS.size() - 1)]
				var font_size := 18 if is_hub else 15
				draw_string(FONT, center + Vector2(-radius, float(font_size) * 0.36), str(number), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, color)
			&"flagged":
				draw_arc(center, radius + 5.0, 0.0, TAU * 0.70, 24, Color("ffd166"), 2.2)
				draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -8.0), center + Vector2(7.0, 6.0), center + Vector2(-7.0, 6.0)]), Color("ffe58a"))
			&"polluted":
				for arm_index in range(5):
					var angle := float(arm_index) * TAU / 5.0
					var direction := Vector2(cos(angle), sin(angle))
					draw_line(center + direction * 3.0, center + direction * (radius - 3.0), Color(0.87, 0.36, 0.73, 0.72), 2.0)
				draw_circle(center, 5.0, Color("d455a6"))
				draw_circle(center - Vector2(1.5, 1.5), 1.8, Color(1.0, 0.78, 0.95, 0.85))


# SkySphereBoard's transient overlays frozen at their visible midpoint, over
# the same real cloud-face art. These helpers never create a sphere or model.
class SkyEffectIllustration:
	extends Control

	const HIDDEN_FACE := preload("res://assets/art/sky_levels/board/pentagon_hidden_surface.png")
	const REVEALED_FACE := preload("res://assets/art/sky_levels/board/pentagon_revealed_surface.png")

	var variant: StringName = &"breeze"


	func _draw() -> void:
		var center := size * 0.5
		var face_size := Vector2.ONE * 118.0
		var face := REVEALED_FACE if variant == &"breeze" else HIDDEN_FACE
		draw_texture_rect(face, Rect2(center - face_size * 0.5, face_size), false)
		match variant:
			&"breeze":
				_draw_breeze(center)
			&"shield":
				_draw_shield(center)
			&"eye_arrow":
				var direction := Vector2.RIGHT
				var hint_center := center + direction * minf(size.x, size.y) * 0.43
				var sideways := direction.orthogonal()
				var arrow := PackedVector2Array([
					hint_center + direction * 11.0,
					hint_center - direction * 9.0 + sideways * 8.0,
					hint_center - direction * 5.0,
					hint_center - direction * 9.0 - sideways * 8.0,
				])
				draw_colored_polygon(arrow, Color(0.42, 0.86, 0.94, 0.90))


	func _draw_breeze(center: Vector2) -> void:
		# Same five lanes, wavelengths, lengths, widths and color as the
		# real wind sweep; only its time-dependent x coordinate is frozen.
		var sweep_x := center.x + 52.0
		for lane_index in range(5):
			var lane_offset := float(lane_index - 2) * 31.0
			var line_length := 104.0 + float(lane_index % 2) * 34.0
			var points := PackedVector2Array()
			for point_index in range(9):
				var point_progress := float(point_index) / 8.0
				points.append(Vector2(
					sweep_x - line_length + point_progress * line_length,
					center.y + lane_offset + sin(point_progress * PI * 2.0 + float(lane_index)) * 5.0
				))
			draw_polyline(points, Color(0.76, 0.96, 1.0, 0.82), 2.2 + float(lane_index % 2) * 0.7, true)


	func _draw_shield(center: Vector2) -> void:
		var progress := 0.5
		var shield_radius := 38.0
		draw_circle(center, shield_radius, Color(0.78, 0.95, 1.0, 0.18))
		draw_arc(center, shield_radius, 0.0, TAU, 48, Color(0.90, 0.99, 1.0, 0.88), 3.2, true)
		draw_arc(center, shield_radius + 7.0, -progress * 1.8, PI * 1.15 - progress * 1.8, 28, Color(0.62, 0.88, 0.97, 0.72), 2.0, true)
		for puff_index in range(9):
			var angle := float(puff_index) * TAU / 9.0 + progress * 1.35
			var orbit_radius := shield_radius + 6.0 + float(puff_index % 2) * 3.0
			var puff_center := center + Vector2.RIGHT.rotated(angle) * orbit_radius
			var puff_radius := 4.5 + float((puff_index + 1) % 3) * 1.4
			draw_circle(puff_center, puff_radius, Color(0.94, 0.99, 1.0, 0.78))
