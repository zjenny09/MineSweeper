extends Control

const BADGE_HALL_SCENE := preload("res://scenes/badge_hall.tscn")

var _hall: BadgeHall


func _ready() -> void:
	_hall = BADGE_HALL_SCENE.instantiate() as BadgeHall
	add_child(_hall)
	_hall.set_universe_progress(1000, true)
	_hall.exit_requested.connect(func() -> void: get_tree().quit())
	_hall.call_deferred("play_universe_trophy_placement")
