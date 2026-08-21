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
	"core_count": 14,
	"first_move_guide": false,
}

const LEVEL_4 := {
	"number": 4,
	"name": "草原",
	"size": Vector2i(10, 10),
	"core_count": 23,
	"first_move_guide": false,
}

const LEVEL_5 := {
	"number": 5,
	"name": "森林",
	"size": Vector2i(12, 12),
	"core_count": 35,
	"first_move_guide": false,
}

const LEVEL_6 := {
	"number": 6,
	"name": "山脉",
	"size": Vector2i(24, 9),
	"core_count": 80,
	"first_move_guide": false,
	"topology": "triangle",
}

const LEVELS := [LEVEL_1, LEVEL_2, LEVEL_3, LEVEL_4, LEVEL_5, LEVEL_6]


static func is_valid_level_number(level_number: int) -> bool:
	return level_number >= 1 and level_number <= LEVELS.size()


static func level_index_from_number(level_number: int) -> int:
	return level_number - 1 if is_valid_level_number(level_number) else -1


static func level_number_from_index(level_index: int) -> int:
	return level_index + 1 if level_index >= 0 and level_index < LEVELS.size() else -1


static func get_level_by_number(level_number: int) -> Dictionary:
	var level_index := level_index_from_number(level_number)
	return LEVELS[level_index] if level_index >= 0 else {}
