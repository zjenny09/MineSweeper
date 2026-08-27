class_name LevelOneGuardianAssets
extends RefCounted

const ART := preload("res://scripts/art_catalog.gd")

const POSES: Array[Dictionary] = [
	{
		"id": "top_white_standing",
		"body_layer": ART.LEVEL_01_GUARDIAN_TOP_WHITE,
	},
	{
		"id": "top_yellow_standing",
		"body_layer": ART.LEVEL_01_GUARDIAN_TOP_YELLOW,
	},
	{
		"id": "top_light_green_standing",
		"body_layer": ART.LEVEL_01_GUARDIAN_TOP_LIGHT_GREEN,
	},
	{
		"id": "top_dark_green_standing",
		"body_layer": ART.LEVEL_01_GUARDIAN_TOP_DARK_GREEN,
	},
]

const LINEUP: Array[int] = [0, 2, 3, 1, 2, 3, 0]
