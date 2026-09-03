extends TextureButton

@export var hover_scale := 1.04
@export var pressed_scale := 0.97

var _hovered := false
var _focused := false
var _pressed := false
var _motion_tween: Tween
var _base_normal_texture: Texture2D


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	call_deferred("_capture_visual_baseline")


func _capture_visual_baseline() -> void:
	_base_normal_texture = texture_normal
	texture_focused = null
	pivot_offset = size * 0.5
	_apply_motion(false)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_motion()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_motion()


func _on_focus_entered() -> void:
	_focused = true
	_apply_motion()


func _on_focus_exited() -> void:
	_focused = false
	_apply_motion()


func _on_button_down() -> void:
	_pressed = true
	_apply_motion()


func _on_button_up() -> void:
	_pressed = false
	_apply_motion()


func _apply_motion(animate := true) -> void:
	if _base_normal_texture != null:
		texture_normal = texture_hover if _focused and not _pressed else _base_normal_texture
	var target_scale := Vector2.ONE
	if _pressed:
		target_scale = Vector2.ONE * pressed_scale
	elif _hovered or _focused:
		target_scale = Vector2.ONE * hover_scale
	if is_instance_valid(_motion_tween):
		_motion_tween.kill()
	if not animate:
		scale = target_scale
		return
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, 0.08)
