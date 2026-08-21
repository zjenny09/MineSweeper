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
	"name": "草丛",
	"size": Vector2i(6, 6),
	"core_count": 8,
	"first_move_guide": false,
}

const LEVELS := [LEVEL_1, LEVEL_2]
