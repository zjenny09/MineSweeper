class_name GreenSweeperLevels
extends RefCounted

const LEVEL_1 := {
	"number": 1,
	"name": "TXT_0073",
	"size": Vector2i(5, 5),
	"core_count": 5,
	"first_move_guide": true,
}

const LEVEL_2 := {
	"number": 2,
	"name": "TXT_0074",
	"size": Vector2i(6, 6),
	"core_count": 8,
	"first_move_guide": false,
}

const LEVEL_3 := {
	"number": 3,
	"name": "TXT_0075",
	"size": Vector2i(8, 8),
	"core_count": 9,
	"first_move_guide": false,
	"obstacles_three": [27, 35, 36],
	"obstacles_four": [19, 27, 35, 36],
}

const LEVEL_4 := {
	"number": 4,
	"name": "TXT_0076",
	"size": Vector2i(9, 9),
	"core_count": 12,
	"first_move_guide": false,
	"obstacle_cluster_count": 2,
}

const LEVEL_5 := {
	"number": 5,
	"name": "TXT_0415",
	"size": Vector2i(10, 10),
	"core_count": 13,
	"first_move_guide": false,
	"obstacle_cluster_count": 1,
	"pollution_node_count": 2,
	"pollution_reset_seconds": 45.0,
}

const LEVEL_6 := {
	"number": 6,
	"name": "TXT_0078",
	"size": Vector2i(12, 12),
	"core_count": 17,
	"first_move_guide": false,
	"obstacle_cluster_count": 2,
	"pollution_node_count": 3,
	"pollution_reset_seconds": 40.0,
}

const LEVEL_7 := {
	"number": 7,
	"name": "TXT_0079",
	"size": Vector2i(13, 13),
	"core_count": 20,
	"first_move_guide": false,
	"pollution_node_count": 3,
	"pollution_reset_seconds": 60.0,
	"boss": true,
}

const OCEAN_LEVEL_1 := {
	"number": 8,
	"name": "TXT_0082",
	"size": Vector2i(6, 6),
	"core_count": 7,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_2 := {
	"number": 9,
	"name": "TXT_0080",
	"size": Vector2i(8, 7),
	"core_count": 10,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"reef_segments": [
		{"divider": 3, "start_row": 2, "end_row": 4},
	],
}

const OCEAN_LEVEL_3 := {
	"number": 10,
	"name": "TXT_0081",
	"size": Vector2i(9, 8),
	"core_count": 14,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"reef_segments": [
		{"divider": 2, "start_row": 1, "end_row": 3},
		{"divider": 5, "start_row": 4, "end_row": 6},
	],
}

const OCEAN_LEVEL_4 := {
	"number": 11,
	"name": "TXT_0083",
	"size": Vector2i(10, 9),
	"core_count": 17,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"mobile_current": {
		"shape": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			Vector2i(0, 5), Vector2i(1, 5), Vector2i(0, 6), Vector2i(1, 6),
		],
		"group_ids": [0, 0, 0, 0, 1, 1, 1, 1],
		"start_position": Vector2i(1, 0),
		"end_column": 9,
		"core_count": 4,
		"step_seconds": 7.0,
	},
}

const OCEAN_LEVEL_5 := {
	"number": 12,
	"name": "TXT_0084",
	"size": Vector2i(11, 10),
	"core_count": 21,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"mobile_current": {
		"shape": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4),
			Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 7),
		],
		"group_ids": [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2],
		"start_position": Vector2i(1, 0),
		"end_column": 10,
		"core_count": 6,
		"step_seconds": 6.0,
	},
}

const OCEAN_LEVEL_6 := {
	"number": 13,
	"name": "TXT_0085",
	"size": Vector2i(12, 11),
	"core_count": 25,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"reef_segments": [
		{"divider": 5, "start_row": 2, "end_row": 7},
	],
	"tidal_zones": [
		{
			"origin": Vector2i(0, 0),
			"size": Vector2i(12, 5),
		},
		{
			"origin": Vector2i(0, 5),
			"size": Vector2i(12, 6),
		},
	],
}

const OCEAN_LEVEL_7 := {
	"number": 14,
	"name": "TXT_0086",
	"size": Vector2i(13, 12),
	"core_count": 30,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"boss": true,
	"reef_segments": [
		{"divider": 3, "start_row": 1, "end_row": 4},
		{"divider": 8, "start_row": 6, "end_row": 10},
	],
	"tidal_zones": [
		{
			"origin": Vector2i(0, 0),
			"size": Vector2i(13, 4),
		},
		{
			"origin": Vector2i(0, 4),
			"size": Vector2i(13, 4),
		},
		{
			"origin": Vector2i(0, 8),
			"size": Vector2i(13, 4),
		},
	],
}

const SKY_LEVEL_1 := {
	"number": 15,
	"name": "TXT_0087",
	"core_count": 6,
	"face_count": 32,
	"structure_name": "TXT_0104",
	"topology": &"fullerene_32",
}

const SKY_LEVEL_2 := {
	"number": 16,
	"name": "TXT_0088",
	"core_count": 8,
	"face_count": 42,
	"structure_name": "TXT_0105",
	"topology": &"goldberg_42",
}

const SKY_LEVEL_3 := {
	"number": 17,
	"name": "TXT_0089",
	"core_count": 15,
	"face_count": 92,
	"structure_name": "TXT_0106",
	"topology": &"goldberg_92",
	"breeze_assists": -1,
	"breeze_trigger_chance": 0.20,
}

const SKY_LEVEL_4 := {
	"number": 18,
	"name": "TXT_0090",
	"core_count": 26,
	"face_count": 162,
	"structure_name": "TXT_0107",
	"topology": &"goldberg_162",
	"breeze_assists": -1,
	"breeze_trigger_chance": 0.20,
}

const SKY_LEVEL_5 := {
	"number": 19,
	"name": "TXT_0091",
	"core_count": 40,
	"face_count": 252,
	"structure_name": "TXT_0108",
	"topology": &"goldberg_252",
	"breeze_assists": -1,
	"breeze_trigger_chance": 0.20,
	"storm_guard_assists": 1,
	"storm_guard_trigger_chance": 0.70,
}

const SKY_LEVEL_6 := {
	"number": 20,
	"name": "TXT_0092",
	"core_count": 58,
	"face_count": 362,
	"structure_name": "TXT_0109",
	"topology": &"goldberg_362",
	"breeze_assists": -1,
	"breeze_trigger_chance": 0.20,
	"storm_guard_assists": 1,
	"storm_guard_trigger_chance": 0.70,
	"boss_eye_count": 3,
}

const SKY_LEVEL_7 := {
	"number": 21,
	"name": "TXT_0093",
	"core_count": 78,
	"face_count": 492,
	"structure_name": "TXT_0110",
	"topology": &"goldberg_492",
	"breeze_assists": -1,
	"breeze_trigger_chance": 0.20,
	"storm_guard_assists": 1,
	"storm_guard_trigger_chance": 0.70,
	"boss_eye_count": 5,
	"boss": true,
}

const LAND_LEVELS := [
	LEVEL_1,
	LEVEL_2,
	LEVEL_3,
	LEVEL_4,
	LEVEL_5,
	LEVEL_6,
	LEVEL_7,
]
const OCEAN_LEVELS := [
	OCEAN_LEVEL_1,
	OCEAN_LEVEL_2,
	OCEAN_LEVEL_3,
	OCEAN_LEVEL_4,
	OCEAN_LEVEL_5,
	OCEAN_LEVEL_6,
	OCEAN_LEVEL_7,
]
const SKY_LEVELS := [
	SKY_LEVEL_1,
	SKY_LEVEL_2,
	SKY_LEVEL_3,
	SKY_LEVEL_4,
	SKY_LEVEL_5,
	SKY_LEVEL_6,
	SKY_LEVEL_7,
]
const PLAYABLE_LEVELS := LAND_LEVELS + OCEAN_LEVELS + SKY_LEVELS
const LEVELS := PLAYABLE_LEVELS


static func is_valid_level_number(level_number: int) -> bool:
	return level_number >= 1 and level_number <= PLAYABLE_LEVELS.size()


static func level_index_from_number(level_number: int) -> int:
	return level_number - 1 if is_valid_level_number(level_number) else -1


static func level_number_from_index(level_index: int) -> int:
	return level_index + 1 if level_index >= 0 and level_index < PLAYABLE_LEVELS.size() else -1


static func get_level_by_number(level_number: int) -> Dictionary:
	var level_index := level_index_from_number(level_number)
	return PLAYABLE_LEVELS[level_index] if level_index >= 0 else {}
