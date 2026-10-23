@tool
extends Control

const LEVEL_PREVIEWS := [
	{"name": "TXT_0073", "grid": 5, "cores": 5},
	{"name": "TXT_0074", "grid": 6, "cores": 8},
	{"name": "TXT_0075", "grid": 8, "cores": 9},
	{"name": "TXT_0076", "grid": 10, "cores": 17},
	{"name": "TXT_0077", "grid": 12, "cores": 28},
]

@export_enum("TXT_0443", "TXT_0444", "TXT_0445", "TXT_0446", "TXT_0447") var preview_level := 1:
	set(value):
		preview_level = clampi(value, 1, 5)
		if is_inside_tree():
			call_deferred("_refresh_preview")

var _last_preview_level := -1

@onready var preview_background: ColorRect = $PreviewBackground
@onready var reference_art: TextureRect = $ReferenceArt
@onready var preview_grid: Control = $PreviewGrid
@onready var left_preview_text: Label = $LeftPreviewText
@onready var right_preview_text: Label = $RightPreviewText


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and _last_preview_level != preview_level:
		_refresh_preview()


func show_level(level_index: int, show_victory_sticker: bool) -> void:
	preview_level = clampi(level_index + 1, 1, 5)
	_refresh_preview()
	var victory_sticker := get_node_or_null(
		"Level1Stickers/VictoryLeafSticker"
	) as TextureRect
	if victory_sticker != null:
		victory_sticker.visible = preview_level == 1 and show_victory_sticker


func _preview_copy(key: String, chinese: String, english: String) -> String:
	var translated := tr(key)
	if translated != key:
		return translated
	return chinese if TranslationServer.get_locale().begins_with("zh") else english


func _refresh_preview() -> void:
	if not is_inside_tree():
		return
	_last_preview_level = preview_level
	var edited_root := get_tree().edited_scene_root
	var standalone_editor_preview := (
		Engine.is_editor_hint()
		and edited_root != null
		and edited_root.scene_file_path == "res://scenes/land_sticker_sets.tscn"
	)
	var show_active_stickers := standalone_editor_preview or not Engine.is_editor_hint()
	if is_instance_valid(preview_background):
		preview_background.visible = standalone_editor_preview
	if is_instance_valid(reference_art):
		reference_art.visible = standalone_editor_preview
	var level_data: Dictionary = LEVEL_PREVIEWS[preview_level - 1]
	if is_instance_valid(preview_grid):
		preview_grid.visible = standalone_editor_preview
		preview_grid.call("set_grid_size", int(level_data["grid"]))
	if is_instance_valid(left_preview_text):
		left_preview_text.visible = standalone_editor_preview
		if standalone_editor_preview:
			var heading := _preview_copy(
				"TXT_0436",
				"第%d关 · %s\n%d × %d 棋盘\n污染核心 %d\n\n",
				"Level %d · %s\n%d × %d Board\nPollution Cores %d\n\n"
			)
			var objective := _preview_copy(
				"TXT_0392",
				"净化目标\n清除所有污染核心\n恢复%s生态\n\n",
				"Objective\nClear every Pollution Core\nRestore the %s ecosystem\n\n"
			)
			var controls := _preview_copy(
				"TXT_0165",
				"操作方法\n左键净化 · 右键标记\n双击数字快速展开",
				"Controls\nLeft: Reveal · Right: Flag\nDouble-click numbers to expand"
			)
			left_preview_text.text = (heading + objective + controls) % [
				preview_level,
				tr(str(level_data["name"])),
				int(level_data["grid"]),
				int(level_data["grid"]),
				int(level_data["cores"]),
				tr(str(level_data["name"])),
			]
	if is_instance_valid(right_preview_text):
		right_preview_text.visible = standalone_editor_preview
		if standalone_editor_preview:
			var status := _preview_copy(
				"TXT_0391",
				"净化时间\n00:00.0\n\n污染核心    0/%d\n\n净化状态\n准备中",
				"Clear Time\n00:00.0\n\nPollution Cores    0/%d\n\nStatus\nReady"
			)
			right_preview_text.text = status % int(level_data["cores"])
	for level_number in range(1, 6):
		var sticker_group := get_node_or_null("Level%dStickers" % level_number) as Control
		if sticker_group != null:
			sticker_group.visible = (
				show_active_stickers
				and level_number == preview_level
			)
	if standalone_editor_preview:
		var victory_sticker := get_node_or_null(
			"Level1Stickers/VictoryLeafSticker"
		) as TextureRect
		if victory_sticker != null:
			victory_sticker.visible = preview_level == 1
