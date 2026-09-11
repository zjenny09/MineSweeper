class_name GreenSweeperLevels
extends RefCounted

const LEVEL_1 := {
	"number": 1,
	"name": "萌芽",
	"size": Vector2i(5, 5),
	"core_count": 5,
	"first_move_guide": true,
}

const LEVEL_2 := {
	"number": 2,
	"name": "灌木",
	"size": Vector2i(6, 6),
	"core_count": 8,
	"first_move_guide": false,
}

const LEVEL_3 := {
	"number": 3,
	"name": "湿地",
	"size": Vector2i(8, 8),
	"core_count": 9,
	"first_move_guide": false,
	"obstacles_three": [27, 35, 36],
	"obstacles_four": [19, 27, 35, 36],
}

const LEVEL_4 := {
	"number": 4,
	"name": "草原",
	"size": Vector2i(9, 9),
	"core_count": 12,
	"first_move_guide": false,
	"obstacle_cluster_count": 2,
}

const LEVEL_5 := {
	"number": 5,
	"name": "林缘",
	"size": Vector2i(10, 10),
	"core_count": 15,
	"first_move_guide": false,
	"obstacle_cluster_count": 1,
	"pollution_node_count": 2,
}

const LEVEL_6 := {
	"number": 6,
	"name": "密林",
	"size": Vector2i(12, 12),
	"core_count": 20,
	"first_move_guide": false,
	"obstacle_cluster_count": 2,
	"pollution_node_count": 3,
}

const LEVEL_7 := {
	"number": 7,
	"name": "古林",
	"size": Vector2i(13, 13),
	"core_count": 24,
	"first_move_guide": false,
	"pollution_node_count": 3,
	"boss": true,
	"obstacle_cluster_count": 2,
}

const OCEAN_LEVEL_1 := {
	"number": 8,
	"name": "海葵",
	"size": Vector2i(6, 6),
	"core_count": 7,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_2 := {
	"number": 9,
	"name": "海草",
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
	"name": "珊瑚",
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
	"name": "水母",
	"size": Vector2i(10, 9),
	"core_count": 17,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"reef_segments": [
		{"divider": 4, "start_row": 3, "end_row": 5},
	],
	"current_paths": [
		[
			Vector2i(0, 2),
			Vector2i(1, 2),
			Vector2i(1, 3),
			Vector2i(2, 3),
			Vector2i(3, 2),
			Vector2i(4, 2),
			Vector2i(5, 2),
			Vector2i(6, 2),
			Vector2i(6, 3),
			Vector2i(7, 3),
			Vector2i(8, 3),
			Vector2i(9, 2),
		],
		[
			Vector2i(0, 7),
			Vector2i(1, 7),
			Vector2i(2, 6),
			Vector2i(3, 6),
			Vector2i(4, 6),
			Vector2i(5, 6),
			Vector2i(6, 6),
			Vector2i(6, 5),
			Vector2i(7, 5),
			Vector2i(8, 6),
			Vector2i(9, 6),
		],
	],
}

const OCEAN_LEVEL_5 := {
	"number": 12,
	"name": "鱼群",
	"size": Vector2i(11, 10),
	"core_count": 21,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"reef_segments": [
		{"divider": 5, "start_row": 3, "end_row": 6},
	],
	"current_paths": [
		[
			Vector2i(1, 2),
			Vector2i(2, 2),
			Vector2i(3, 2),
			Vector2i(4, 2),
			Vector2i(5, 2),
		],
		[
			Vector2i(6, 7),
			Vector2i(7, 7),
			Vector2i(8, 7),
			Vector2i(9, 7),
		],
	],
}

const OCEAN_LEVEL_6 := {
	"number": 13,
	"name": "海沟",
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
	"name": "鲸落",
	"size": Vector2i(13, 12),
	"core_count": 30,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
	"boss": true,
	"reef_segments": [
		{"divider": 3, "start_row": 1, "end_row": 4},
		{"divider": 8, "start_row": 6, "end_row": 10},
	],
	"current_paths": [
		[
			Vector2i(0, 1),
			Vector2i(1, 1),
			Vector2i(2, 1),
			Vector2i(3, 1),
		],
		[
			Vector2i(4, 5),
			Vector2i(5, 5),
			Vector2i(6, 5),
			Vector2i(7, 5),
			Vector2i(8, 5),
		],
		[
			Vector2i(9, 9),
			Vector2i(10, 9),
			Vector2i(11, 9),
			Vector2i(12, 9),
		],
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
	"name": "云冠",
	"core_count": 6,
	"face_count": 32,
	"structure_name": "32格足球烯",
	"topology": &"fullerene_32",
}

const SKY_LEVEL_2 := {
	"number": 16,
	"name": "风环",
	"core_count": 8,
	"face_count": 42,
	"structure_name": "42格二频云球",
	"topology": &"goldberg_42",
}

const SKY_LEVEL_3 := {
	"number": 17,
	"name": "虹桥",
	"core_count": 15,
	"face_count": 92,
	"structure_name": "92格三频云球",
	"topology": &"goldberg_92",
}

const SKY_LEVEL_4 := {
	"number": 18,
	"name": "浮岛",
	"core_count": 26,
	"face_count": 162,
	"structure_name": "162格四频云球",
	"topology": &"goldberg_162",
}

const SKY_LEVEL_5 := {
	"number": 19,
	"name": "云脊",
	"core_count": 40,
	"face_count": 252,
	"structure_name": "252格五频云球",
	"topology": &"goldberg_252",
}

const SKY_LEVEL_6 := {
	"number": 20,
	"name": "雷眼",
	"core_count": 58,
	"face_count": 362,
	"structure_name": "362格六频云球",
	"topology": &"goldberg_362",
}

const SKY_LEVEL_7 := {
	"number": 21,
	"name": "天宫",
	"core_count": 78,
	"face_count": 492,
	"structure_name": "492格七频云球",
	"topology": &"goldberg_492",
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
