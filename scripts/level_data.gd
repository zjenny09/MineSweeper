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
}

const LEVEL_4 := {
	"number": 4,
	"name": "草原",
	"size": Vector2i(10, 10),
	"core_count": 17,
	"first_move_guide": false,
}

const LEVEL_5 := {
	"number": 5,
	"name": "森林",
	"size": Vector2i(12, 12),
	"core_count": 28,
	"first_move_guide": false,
}

const OCEAN_LEVEL_1 := {
	"number": 6,
	"name": "潮池",
	"size": Vector2i(5, 5),
	"core_count": 5,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_2 := {
	"number": 7,
	"name": "海草",
	"size": Vector2i(6, 6),
	"core_count": 7,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_3 := {
	"number": 8,
	"name": "珊瑚",
	"size": Vector2i(7, 7),
	"core_count": 10,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_4 := {
	"number": 9,
	"name": "海藻",
	"size": Vector2i(8, 8),
	"core_count": 14,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const OCEAN_LEVEL_5 := {
	"number": 10,
	"name": "鲸落",
	"size": Vector2i(10, 9),
	"core_count": 22,
	"first_move_guide": false,
	"topology": &"hex_pointy_odd_r",
}

const LAND_LEVELS := [LEVEL_1, LEVEL_2, LEVEL_3, LEVEL_4, LEVEL_5]
const OCEAN_LEVELS := [
	OCEAN_LEVEL_1,
	OCEAN_LEVEL_2,
	OCEAN_LEVEL_3,
	OCEAN_LEVEL_4,
	OCEAN_LEVEL_5,
]
const PLAYABLE_LEVELS := LAND_LEVELS + OCEAN_LEVELS
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
