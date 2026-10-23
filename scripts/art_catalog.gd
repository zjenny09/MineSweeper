class_name ArtCatalog
extends RefCounted

const STABLE_IDS := preload("res://scripts/art_ids.gd")


static func path_for(asset_id: StringName) -> String:
	return STABLE_IDS.path_for(asset_id)


static func short_name_for(asset_id: StringName) -> StringName:
	return STABLE_IDS.short_name_for(asset_id)


static func id_for_path(path: String) -> StringName:
	return STABLE_IDS.id_for_path(path)

const UI_FONT := "res://assets/art/common/fonts/ui_handwritten_zh.ttf"

const MENU_PRIMARY_NORMAL := "res://assets/art/common/buttons/menu_primary_normal.svg"
const MENU_PRIMARY_HOVER := "res://assets/art/common/buttons/menu_primary_hover.svg"
const MENU_PRIMARY_PRESSED := "res://assets/art/common/buttons/menu_primary_pressed.svg"
const MENU_SECONDARY_NORMAL := "res://assets/art/common/buttons/menu_secondary_normal.svg"
const MENU_SECONDARY_HOVER := "res://assets/art/common/buttons/menu_secondary_hover.svg"
const MENU_SECONDARY_PRESSED := "res://assets/art/common/buttons/menu_secondary_pressed.svg"

const TUTORIAL_GUIDE_ROBOT_AVATAR := \
		"res://assets/art/tutorial/first_move_guide_robot_avatar.png"
const TUTORIAL_GUIDE_FRAME := \
		"res://assets/art/tutorial/first_move_guide_frame.png"
const TUTORIAL_GUIDE_BUTTON_PRIMARY := \
		"res://assets/art/tutorial/first_move_button_primary.png"
const TUTORIAL_GUIDE_BUTTON_SECONDARY := \
		"res://assets/art/tutorial/first_move_button_secondary.png"

const MARKER_FLAG_SPROUT_HEALTHY := \
		"res://assets/art/gameplay/markers/flag_sprout_healthy.png"
const MARKER_FLAG_SPROUT_WILTED := \
		"res://assets/art/gameplay/markers/flag_sprout_wilted.png"
const MARKER_FLAG_SPROUT_UPROOTED := \
		"res://assets/art/gameplay/markers/flag_sprout_uprooted.png"
const MARKER_POLLUTION_CORE_SLIME := \
		"res://assets/art/gameplay/markers/pollution_core_slime.png"
const OCEAN_MARKER_CORAL_NORMAL := \
		"res://assets/art/ocean_levels/markers/ocean_flag_coral_normal.png"
const OCEAN_MARKER_CORAL_FAILED := \
		"res://assets/art/ocean_levels/markers/ocean_flag_coral_failed.png"
const OCEAN_MARKER_CORAL_WRONG := \
		"res://assets/art/ocean_levels/markers/ocean_flag_coral_wrong.png"
const OCEAN_POLLUTION_CORE_MONSTER := \
		"res://assets/art/ocean_levels/markers/ocean_pollution_core_monster.png"
const OCEAN_MARKER_MONSTER_WRONG := \
		"res://assets/art/ocean_levels/markers/ocean_marker_monster_wrong.png"

const LEVEL_01_LAND_BACKGROUND := \
		"res://assets/art/level_01/background/land_paper_background.png"
const LAND_TABLETOP_BACKGROUND := \
		"res://assets/art/land_levels/background/land_tabletop_background5_clean.png"
const OCEAN_DESKTOP_BACKGROUND := \
		"res://assets/art/ocean_levels/background/ocean_desktop_clean.png"
const SKY_DESKTOP_BACKGROUND := \
		"res://assets/art/sky_levels/background/sky_desktop_clean.png"
const SKY_BOARD_FRAME := \
		"res://assets/art/sky_levels/stage/sky_board_frame.png"
const SKY_V2_BACKGROUND := \
		"res://assets/art/sky_v2/background/sky_background.png"
const SKY_V2_STAGE_BODY := \
		"res://assets/art/sky_v2/stage/sky_triptych_stage.png"
const SKY_V2_TOP_ATTACHMENT := \
		"res://assets/art/sky_v2/hud/top_attachment_strip.png"
const SKY_V2_COUNTER_FRAME := \
		"res://assets/art/land_v2/hud/counter_frame.png"
const SKY_V2_ROBOT_EMBLEM := \
		"res://assets/art/land_v2/hud/robot_emblem_smile.png"
const SKY_V2_COUNTER_ICON := \
		"res://assets/art/sky_v2/hud/plane_counter_icon.png"
const SKY_V2_TIMER_ICON := \
		"res://assets/art/land_v2/hud/timer_icon.png"
const SKY_V2_RESTART_BUTTON := \
		"res://assets/art/sky_v2/buttons/restart_button.png"
const SKY_V2_SETTINGS_BUTTON := \
		"res://assets/art/sky_v2/buttons/settings_button.png"
const SKY_V2_MARKER := "res://assets/art/sky_v2/markers/sky_marker.png"
const SKY_V2_MARKER_FAILED := \
		"res://assets/art/sky_v2/markers/sky_marker_failed.png"
const SKY_V2_MARKER_WRONG := \
		"res://assets/art/sky_v2/markers/sky_marker_wrong.png"
const SKY_V2_STORM_EYE_BODY := \
		"res://assets/art/sky_v2/mechanics/storm_eye_body.png"
const SKY_V2_STORM_EYE_RING := \
		"res://assets/art/sky_v2/mechanics/storm_eye_ring.png"
const SKY_V2_STORM_EYE_STAR := \
		"res://assets/art/sky_v2/mechanics/storm_eye_star.png"
const SKY_V2_STORM_EYE_LIGHTNING := \
		"res://assets/art/sky_v2/mechanics/storm_eye_lightning.png"
const SKY_V2_DIGIT_PATHS := [
	"res://assets/art/sky_v2/digits/digit_1.png",
	"res://assets/art/sky_v2/digits/digit_2.png",
	"res://assets/art/sky_v2/digits/digit_3.png",
	"res://assets/art/sky_v2/digits/digit_4.png",
	"res://assets/art/sky_v2/digits/digit_5.png",
	"res://assets/art/sky_v2/digits/digit_6.png",
]
const SKY_V2_HAZE_ALERT := \
		"res://assets/art/sky_v2/characters/haze_alert.png"
const SKY_V2_HAZE_DEFIANT_PATHS := [
	"res://assets/art/sky_v2/characters/haze_defiant.png",
	"res://assets/art/sky_v2/characters/haze_defiant_left.png",
]
const SKY_V2_HAZE_MOCK_PATHS := [
	"res://assets/art/sky_v2/characters/haze_mock.png",
	"res://assets/art/sky_v2/characters/haze_mock_left.png",
	"res://assets/art/sky_v2/characters/haze_mock_right.png",
]
const SKY_V2_HAZE_DEFEATED := \
		"res://assets/art/sky_v2/characters/haze_defeated.png"
const SKY_V2_SKYCRAFT := "res://assets/art/sky_v2/characters/skycraft.png"
const SKY_V2_ECOLOGY_PATHS := [
	"res://assets/art/sky_v2/ecology/level_15_cloud_crown.png",
	"res://assets/art/sky_v2/ecology/level_16_wind_ring.png",
	"res://assets/art/sky_v2/ecology/level_17_rainbow_bridge.png",
	"res://assets/art/sky_v2/ecology/level_18_floating_isles.png",
	"res://assets/art/sky_v2/ecology/level_19_cloud_ridge.png",
	"res://assets/art/sky_v2/ecology/level_20_storm_eye.png",
	"res://assets/art/sky_v2/ecology/level_21_sky_palace.png",
]
const SKY_V2_ECOLOGY_POLLUTED_PATHS := [
	"res://assets/art/sky_v2/ecology/polluted/level_15_cloud_crown.png",
	"res://assets/art/sky_v2/ecology/polluted/level_16_wind_ring.png",
	"res://assets/art/sky_v2/ecology/polluted/level_17_rainbow_bridge.png",
	"res://assets/art/sky_v2/ecology/polluted/level_18_floating_isles.png",
	"res://assets/art/sky_v2/ecology/polluted/level_19_cloud_ridge.png",
	"res://assets/art/sky_v2/ecology/polluted/level_20_storm_eye.png",
	"res://assets/art/sky_v2/ecology/polluted/level_21_sky_palace.png",
]
const SKY_BADGE_ZH_PATHS := [
	"res://assets/art/sky_v2/badges/zh/level_15_cloud_crown.png",
	"res://assets/art/sky_v2/badges/zh/level_16_wind_ring.png",
	"res://assets/art/sky_v2/badges/zh/level_17_rainbow_bridge.png",
	"res://assets/art/sky_v2/badges/zh/level_18_floating_isles.png",
	"res://assets/art/sky_v2/badges/zh/level_19_cloud_ridge.png",
	"res://assets/art/sky_v2/badges/zh/level_20_storm_eye.png",
	"res://assets/art/sky_v2/badges/zh/level_21_sky_palace.png",
]
const SKY_BADGE_EN_PATHS := [
	"res://assets/art/sky_v2/badges/en/level_15_cloud_crown.png",
	"res://assets/art/sky_v2/badges/en/level_16_wind_ring.png",
	"res://assets/art/sky_v2/badges/en/level_17_rainbow_bridge.png",
	"res://assets/art/sky_v2/badges/en/level_18_floating_isles.png",
	"res://assets/art/sky_v2/badges/en/level_19_cloud_ridge.png",
	"res://assets/art/sky_v2/badges/en/level_20_storm_eye.png",
	"res://assets/art/sky_v2/badges/en/level_21_sky_palace.png",
]
const OCEAN_BOARD_TRAY_FRAME := \
		"res://assets/art/ocean_levels/stage/ocean_board_tray_frame.png"
const OCEAN_CELL_HIDDEN := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_hidden.png"
const OCEAN_CELL_REVEALED := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_revealed.png"
const OCEAN_CELL_POLLUTED := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_polluted.png"
const OCEAN_REEF_STRIP_FULL := \
		"res://assets/art/ocean_levels/obstacles/ocean_reef_strip_full.png"
const LEVEL_01_BOARD_TRAY := "res://assets/art/level_01/board/board_tray.png"
const LEVEL_01_BOARD_SHADOW := "res://assets/art/level_01/board/board_shadow.png"
const LEVEL_01_CELL_HIDDEN := "res://assets/art/level_01/board/cells/cell_hidden.png"
const LEVEL_01_CELL_HOVER := "res://assets/art/level_01/board/cells/cell_hover.png"
const LEVEL_01_CELL_KEYBOARD_FOCUS := \
		"res://assets/art/level_01/board/cells/cell_keyboard_focus.png"
const LEVEL_01_CELL_REVEALED := \
		"res://assets/art/level_01/board/cells/cell_revealed.png"
const LEVEL_01_CELL_POLLUTED := \
		"res://assets/art/level_01/board/cells/cell_polluted.png"
const LEVEL_03_OBSTACLE_RUIN := \
		"res://assets/art/land_levels/obstacles/level_03_short_wall.png"
const LEVEL_03_OBSTACLE_BROKEN_WALL_01 := \
		"res://assets/art/land_levels/obstacles/level_03_obstacle_broken_wall_01.png"
const LEVEL_03_OBSTACLE_BROKEN_WALL_02 := \
		"res://assets/art/land_levels/obstacles/level_03_obstacle_broken_wall_02.png"
const LEVEL_03_OBSTACLE_WEB_01 := \
		"res://assets/art/land_levels/obstacles/level_03_obstacle_web_01.png"
const LEVEL_03_OBSTACLE_WEB_02 := \
		"res://assets/art/land_levels/obstacles/level_03_obstacle_web_02.png"
const LEVEL_03_OBSTACLE_MOSSY_STONE := \
		"res://assets/art/land_levels/obstacles/level_03_obstacle_mossy_stone.png"
const LEVEL_04_POLLUTION_NODE_ACTIVE := \
		"res://assets/art/land_levels/pollution_nodes/level_04_pollution_node_active.png"
const LEVEL_04_POLLUTION_NODE_CLEANSED := \
		"res://assets/art/land_levels/pollution_nodes/level_04_pollution_node_cleansed.png"

const LEVEL_01_NOTE_CURVED := "res://assets/art/level_01/interface/notes/note_curved.png"
const LEVEL_01_NOTE_STRAIGHT := "res://assets/art/level_01/interface/notes/note_straight.png"
const LEVEL_01_PAUSE_MENU_FRAME := \
		"res://assets/art/level_01/interface/pause/pause_menu_frame.png"
const LEVEL_01_ROUND_ACTION_NORMAL := \
		"res://assets/art/level_01/interface/buttons/round_action_normal.png"
const LEVEL_01_ROUND_ACTION_HOVER := \
		"res://assets/art/level_01/interface/buttons/round_action_hover.png"

const LEVEL_01_DECOR_BACKGROUND_SEED := \
		"res://assets/art/level_01/decorations/background_seed_sticker.png"
const LEVEL_01_DECOR_STATUS_NOTE_BUD := \
		"res://assets/art/level_01/decorations/status_note_bud_sticker.png"
const LEVEL_01_DECOR_BACKGROUND_LEAF_SPROUT := \
		"res://assets/art/level_01/decorations/background_leaf_sprout_sticker.png"
const LEVEL_01_DECOR_BACKGROUND_GREEN_LEAF := \
		"res://assets/art/level_01/decorations/background_green_leaf.png"
const LEVEL_01_DECOR_LEFT_SPROUT_HEALTHY := \
		"res://assets/art/level_01/decorations/left_panel_sprout_healthy.png"
const LEVEL_01_DECOR_LEFT_SPROUT_WILTED := \
		"res://assets/art/level_01/decorations/left_panel_sprout_wilted.png"

const LAND_UNIFIED_STAGE_BODY := \
		"res://assets/art/land_levels/stage/unified_land_stage_body_grayblue.png"
const LAND_UNIFIED_STAGE_SHADOW := \
		"res://assets/art/land_levels/stage/unified_land_stage_shadow_grayblue.png"

const LAND_V2_BACKGROUND := "res://assets/art/land_v2/background/land_valley_background.png"
const LAND_V2_STAGE_BODY := "res://assets/art/land_v2/stage/land_triptych_stage.png"
const LAND_V2_TOP_ATTACHMENT := "res://assets/art/land_v2/hud/top_attachment_strip.png"
const LAND_V2_COUNTER_FRAME := "res://assets/art/land_v2/hud/counter_frame.png"
const LAND_V2_ROBOT_EMBLEM := "res://assets/art/land_v2/hud/robot_emblem_smile.png"
const LAND_V2_COUNTER_ICON := "res://assets/art/land_v2/hud/sprout_counter_icon.png"
const LAND_V2_TIMER_ICON := "res://assets/art/land_v2/hud/timer_icon.png"
const LAND_V2_PAUSE_BUTTON := "res://assets/art/land_v2/buttons/pause_button.png"
const LAND_V2_RESTART_BUTTON := "res://assets/art/land_v2/buttons/restart_button.png"
const LAND_V2_SETTINGS_BUTTON := "res://assets/art/land_v2/buttons/settings_button.png"
const LAND_V2_VINE_LEFT := "res://assets/art/land_v2/decorations/vine_left.png"
const LAND_V2_VINE_RIGHT := "res://assets/art/land_v2/decorations/vine_right.png"
const LAND_V2_CELL_HIDDEN := "res://assets/art/land_v2/cells/cell_hidden.png"
const LAND_V2_CELL_REVEALED := "res://assets/art/land_v2/cells/cell_revealed.png"
const LAND_V2_CELL_POLLUTED := "res://assets/art/land_v2/cells/cell_polluted.png"
const LAND_V2_DIGIT_1 := "res://assets/art/land_v2/digits/digit_1.png"
const LAND_V2_DIGIT_2 := "res://assets/art/land_v2/digits/digit_2.png"
const LAND_V2_DIGIT_3 := "res://assets/art/land_v2/digits/digit_3.png"
const LAND_V2_DIGIT_4 := "res://assets/art/land_v2/digits/digit_4.png"
const LAND_V2_DIGIT_5 := "res://assets/art/land_v2/digits/digit_5.png"
const LAND_V2_DIGIT_6 := "res://assets/art/land_v2/digits/digit_6.png"
const LAND_V2_DIGIT_7 := "res://assets/art/land_v2/digits/digit_7.png"
const LAND_V2_DIGIT_8 := "res://assets/art/land_v2/digits/digit_8.png"
const LAND_V2_DIGIT_PATHS := [
	LAND_V2_DIGIT_1,
	LAND_V2_DIGIT_2,
	LAND_V2_DIGIT_3,
	LAND_V2_DIGIT_4,
	LAND_V2_DIGIT_5,
	LAND_V2_DIGIT_6,
	LAND_V2_DIGIT_7,
	LAND_V2_DIGIT_8,
]
const LAND_V2_MARKER_HEALTHY := "res://assets/art/land_v2/markers/sprout_healthy.png"
const LAND_V2_MARKER_WILTED := "res://assets/art/land_v2/markers/sprout_wilted.png"
const LAND_V2_MARKER_WRONG := "res://assets/art/land_v2/markers/wrong_flag_feedback.png"
const LAND_V2_POLLUTION_SLIME := \
		"res://assets/art/land_v2/characters/pollution_slime_alert.png"
const LAND_V2_SLIME_DEFIANT_A := \
		"res://assets/art/land_v2/characters/pollution_slime_defiant_a.png"
const LAND_V2_SLIME_DEFIANT_B := \
		"res://assets/art/land_v2/characters/pollution_slime_defiant_b.png"
const LAND_V2_SLIME_DEFIANT_C := \
		"res://assets/art/land_v2/characters/pollution_slime_defiant_c.png"
const LAND_V2_SLIME_DEFIANT_PATHS := [
	LAND_V2_SLIME_DEFIANT_A,
	LAND_V2_SLIME_DEFIANT_B,
	LAND_V2_SLIME_DEFIANT_C,
]
const LAND_V2_SLIME_MOCK := \
		"res://assets/art/land_v2/characters/pollution_slime_mock.png"
const LAND_V2_SLIME_DEFEATED := \
		"res://assets/art/land_v2/characters/pollution_slime_defeated.png"
const LAND_V2_ROBOT_LEFT_FRONT := \
		"res://assets/art/land_v2/characters/sprout_robot_left_front.png"
const LAND_V2_ROBOT_FRONT := "res://assets/art/land_v2/characters/sprout_robot_front.png"
const LAND_V2_ROBOT_RIGHT_FRONT := \
		"res://assets/art/land_v2/characters/sprout_robot_right_front.png"
const LAND_V2_ROBOT_IDLE_PATHS := [
	LAND_V2_ROBOT_LEFT_FRONT,
	LAND_V2_ROBOT_FRONT,
	LAND_V2_ROBOT_RIGHT_FRONT,
]
const LAND_V2_ROBOT_RIGHT_FRONT_TORSO := \
		"res://assets/art/land_v2/characters/sprout_robot_right_front_torso.png"
const LAND_V2_ROBOT_ARM := "res://assets/art/land_v2/characters/sprout_robot_arm.png"
const LAND_V2_ROBOT_CLAW := "res://assets/art/land_v2/characters/sprout_robot_claw.png"
const LAND_V2_L01_SPROUT_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_01_sprout_healthy.png"
const LAND_V2_L01_SPROUT_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_01_sprout_polluted.png"
const LAND_V2_L02_SHRUB_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_02_shrub_healthy.png"
const LAND_V2_L02_SHRUB_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_02_shrub_polluted.png"
const LAND_V2_L03_WETLAND_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_03_wetland_healthy.png"
const LAND_V2_L03_WETLAND_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_03_wetland_polluted.png"
const LAND_V2_L04_GRASSLAND_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_04_grassland_healthy.png"
const LAND_V2_L04_GRASSLAND_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_04_grassland_polluted.png"
const LAND_V2_L05_FOREST_EDGE_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_05_forest_edge_healthy.png"
const LAND_V2_L05_FOREST_EDGE_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_05_forest_edge_polluted.png"
const LAND_V2_L06_DENSE_FOREST_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_06_dense_forest_healthy.png"
const LAND_V2_L06_DENSE_FOREST_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_06_dense_forest_polluted.png"
const LAND_V2_L07_ANCIENT_FOREST_HEALTHY := \
		"res://assets/art/land_v2/ecology/level_07_ancient_forest_healthy.png"
const LAND_V2_L07_ANCIENT_FOREST_POLLUTED := \
		"res://assets/art/land_v2/ecology/level_07_ancient_forest_polluted.png"
const LAND_V2_ECOLOGY_HEALTHY_PATHS := [
	LAND_V2_L01_SPROUT_HEALTHY,
	LAND_V2_L02_SHRUB_HEALTHY,
	LAND_V2_L03_WETLAND_HEALTHY,
	LAND_V2_L04_GRASSLAND_HEALTHY,
	LAND_V2_L05_FOREST_EDGE_HEALTHY,
	LAND_V2_L06_DENSE_FOREST_HEALTHY,
	LAND_V2_L07_ANCIENT_FOREST_HEALTHY,
]
const LAND_V2_ECOLOGY_POLLUTED_PATHS := [
	LAND_V2_L01_SPROUT_POLLUTED,
	LAND_V2_L02_SHRUB_POLLUTED,
	LAND_V2_L03_WETLAND_POLLUTED,
	LAND_V2_L04_GRASSLAND_POLLUTED,
	LAND_V2_L05_FOREST_EDGE_POLLUTED,
	LAND_V2_L06_DENSE_FOREST_POLLUTED,
	LAND_V2_L07_ANCIENT_FOREST_POLLUTED,
]

const LAND_V2_L01_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_01_sprout_victory.png"
const LAND_V2_L02_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_02_shrub_victory.png"
const LAND_V2_L03_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_03_wetland_victory.png"
const LAND_V2_L04_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_04_grassland_victory.png"
const LAND_V2_L05_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_05_forest_edge_victory.png"
const LAND_V2_L06_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_06_dense_forest_victory.png"
const LAND_V2_L07_VICTORY_ECOLOGY := \
		"res://assets/art/land_v2/ecology/victory/level_07_ancient_forest_victory.png"
const LAND_V2_VICTORY_ECOLOGY_PATHS := [
	LAND_V2_L01_VICTORY_ECOLOGY,
	LAND_V2_L02_VICTORY_ECOLOGY,
	LAND_V2_L03_VICTORY_ECOLOGY,
	LAND_V2_L04_VICTORY_ECOLOGY,
	LAND_V2_L05_VICTORY_ECOLOGY,
	LAND_V2_L06_VICTORY_ECOLOGY,
	LAND_V2_L07_VICTORY_ECOLOGY,
]

const BADGE_HALL_BACKGROUND := "res://assets/art/badge_hall/background.png"
const BADGE_HALL_LAND_STAGE_INITIAL := \
		"res://assets/art/badge_hall/land/stage_initial.png"
const BADGE_HALL_LAND_STAGE_COMPLETE := \
		"res://assets/art/badge_hall/land/stage_complete.png"
const BADGE_HALL_LAND_ECOLOGY_PATHS := [
	"res://assets/art/badge_hall/land/ecology/01_sprout.png",
	"res://assets/art/badge_hall/land/ecology/02_shrub.png",
	"res://assets/art/badge_hall/land/ecology/03_wetland.png",
	"res://assets/art/badge_hall/land/ecology/04_grassland.png",
	"res://assets/art/badge_hall/land/ecology/05_forest_edge.png",
	"res://assets/art/badge_hall/land/ecology/06_dense_forest.png",
	"res://assets/art/badge_hall/land/ecology/07_ancient_forest.png",
]
const BADGE_HALL_LAND_BOOK_COVER := \
		"res://assets/art/badge_hall/land/book_cover.png"
const BADGE_HALL_OCEAN_STAGE_INITIAL := \
		"res://assets/art/badge_hall/ocean/stage_initial.png"
const BADGE_HALL_OCEAN_STAGE_COMPLETE := \
		"res://assets/art/badge_hall/ocean/stage_complete.png"
const BADGE_HALL_OCEAN_ECOLOGY_PATHS := [
	"res://assets/art/badge_hall/ocean/ecology/01_anemone.png",
	"res://assets/art/badge_hall/ocean/ecology/02_seagrass.png",
	"res://assets/art/badge_hall/ocean/ecology/03_coral.png",
	"res://assets/art/badge_hall/ocean/ecology/04_jellyfish.png",
	"res://assets/art/badge_hall/ocean/ecology/05_fish_school.png",
	"res://assets/art/badge_hall/ocean/ecology/06_trench.png",
	"res://assets/art/badge_hall/ocean/ecology/07_whale_fall.png",
]
const BADGE_HALL_OCEAN_BOOK_COVER := \
		"res://assets/art/badge_hall/ocean/book_cover.png"
const BADGE_HALL_OCEAN_SHELL_FRAME_TOP := \
		"res://assets/art/badge_hall/ocean/shell_frame_top.png"
const BADGE_HALL_SKY_STAGE_INITIAL := \
		"res://assets/art/badge_hall/sky/stage_initial.png"
const BADGE_HALL_SKY_STAGE_COMPLETE := \
		"res://assets/art/badge_hall/sky/stage_complete.png"
const BADGE_HALL_SKY_ECOLOGY_PATHS := [
	"res://assets/art/badge_hall/sky/ecology/01_cloud_crown.png",
	"res://assets/art/badge_hall/sky/ecology/02_wind_ring.png",
	"res://assets/art/badge_hall/sky/ecology/03_rainbow_bridge.png",
	"res://assets/art/badge_hall/sky/ecology/04_floating_isles.png",
	"res://assets/art/badge_hall/sky/ecology/05_cloud_ridge.png",
	"res://assets/art/badge_hall/sky/ecology/06_storm_eye.png",
	"res://assets/art/badge_hall/sky/ecology/07_sky_palace.png",
]
const BADGE_HALL_SKY_BOOK_COVER := \
		"res://assets/art/badge_hall/sky/book_cover.png"
const BADGE_HALL_UNIVERSE_STAGE := \
		"res://assets/art/badge_hall/universe/stage.png"
const BADGE_HALL_UNIVERSE_ASTEROID := \
		"res://assets/art/badge_hall/universe/ecology/01_asteroid.png"
const BADGE_HALL_UNIVERSE_PLANET := \
		"res://assets/art/badge_hall/universe/ecology/02_planet.png"
const BADGE_HALL_UNIVERSE_CLUSTER := \
		"res://assets/art/badge_hall/universe/ecology/03_star_cluster.png"
const BADGE_HALL_UNIVERSE_GALAXY_OUTER := \
		"res://assets/art/badge_hall/universe/ecology/04_galaxy_outer.png"
const BADGE_HALL_UNIVERSE_GALAXY_SPIRAL := \
		"res://assets/art/badge_hall/universe/ecology/05_galaxy_spiral.png"
const BADGE_HALL_UNIVERSE_GALAXY_CORE := \
		"res://assets/art/badge_hall/universe/ecology/06_galaxy_core.png"
const BADGE_HALL_UNIVERSE_TROPHY := \
		"res://assets/art/badge_hall/universe/ecology/07_trophy.png"

const LAND_BADGE_BOOK := "res://assets/art/land_v2/badges/badge_book.png"
const LAND_BADGE_PAGE_TURN := "res://assets/art/land_v2/badges/page_turn.png"
const LAND_BADGE_ZH_PATHS := [
	"res://assets/art/land_v2/badges/zh/level_01_sprout.png",
	"res://assets/art/land_v2/badges/zh/level_02_shrub.png",
	"res://assets/art/land_v2/badges/zh/level_03_wetland.png",
	"res://assets/art/land_v2/badges/zh/level_04_grassland.png",
	"res://assets/art/land_v2/badges/zh/level_05_forest_edge.png",
	"res://assets/art/land_v2/badges/zh/level_06_dense_forest.png",
	"res://assets/art/land_v2/badges/zh/level_07_ancient_forest.png",
]
const LAND_BADGE_EN_PATHS := [
	"res://assets/art/land_v2/badges/en/level_01_sprout.png",
	"res://assets/art/land_v2/badges/en/level_02_shrub.png",
	"res://assets/art/land_v2/badges/en/level_03_wetland.png",
	"res://assets/art/land_v2/badges/en/level_04_grassland.png",
	"res://assets/art/land_v2/badges/en/level_05_forest_edge.png",
	"res://assets/art/land_v2/badges/en/level_06_dense_forest.png",
	"res://assets/art/land_v2/badges/en/level_07_ancient_forest.png",
]

const LAND_V2_MECHANIC_OBSTACLE := "res://assets/art/land_v2/mechanics/obstacle.png"
const LAND_V2_POLLUTION_NODE_ACTIVE := "res://assets/art/land_v2/mechanics/pollution_node_active.png"
const LAND_V2_POLLUTION_NODE_CLEANSED := "res://assets/art/land_v2/mechanics/pollution_node_cleansed.png"
const LAND_V2_ROOT_ACTIVE_STRAIGHT := "res://assets/art/land_v2/mechanics/root_active_straight.png"
const LAND_V2_ROOT_ACTIVE_CORNER := "res://assets/art/land_v2/mechanics/root_active_corner.png"
const LAND_V2_ROOT_CLEANSED_STRAIGHT := "res://assets/art/land_v2/mechanics/root_cleansed_straight.png"
const LAND_V2_ROOT_CLEANSED_CORNER := "res://assets/art/land_v2/mechanics/root_cleansed_corner.png"
const LAND_V2_BOSS_TREE_ACTIVE := "res://assets/art/land_v2/mechanics/boss_tree_active.png"
const LAND_V2_BOSS_TREE_CLEANSED := "res://assets/art/land_v2/mechanics/boss_tree_cleansed.png"

const OCEAN_V2_BACKGROUND := "res://assets/art/ocean_v2/background/ocean_background.png"
const OCEAN_V2_STAGE_BODY := "res://assets/art/ocean_v2/stage/ocean_triptych_stage.png"
const OCEAN_V2_TOP_ATTACHMENT := "res://assets/art/ocean_v2/hud/top_attachment_strip.png"
const OCEAN_V2_COUNTER_FRAME := "res://assets/art/ocean_v2/hud/counter_frame.png"
const OCEAN_V2_ROBOT_EMBLEM := "res://assets/art/ocean_v2/hud/robot_emblem_smile.png"
const OCEAN_V2_COUNTER_ICON := "res://assets/art/ocean_v2/hud/shell_counter_icon.png"
const OCEAN_V2_TIMER_ICON := "res://assets/art/ocean_v2/hud/timer_icon.png"
const OCEAN_V2_RESTART_BUTTON := "res://assets/art/ocean_v2/buttons/restart_button.png"
const OCEAN_V2_SETTINGS_BUTTON := "res://assets/art/ocean_v2/buttons/settings_button.png"
const OCEAN_V2_SEAWEED_LEFT := "res://assets/art/ocean_v2/decorations/seaweed_left.png"
const OCEAN_V2_CELL_HIDDEN := "res://assets/art/ocean_v2/cells/cell_hidden.png"
const OCEAN_V2_CELL_REVEALED := "res://assets/art/ocean_v2/cells/cell_revealed.png"
const OCEAN_V2_CELL_POLLUTED := "res://assets/art/ocean_v2/cells/cell_polluted.png"
const OCEAN_V2_MINE := "res://assets/art/ocean_v2/mechanics/mine.png"
const OCEAN_V2_MINE_FLOATING_CELL := \
		"res://assets/art/ocean_v2/mechanics/mine_floating_cell.png"
const OCEAN_V2_MINE_STOP_LINE := "res://assets/art/ocean_v2/mechanics/mine_stop_line.png"
const OCEAN_V2_TIDAL_LOCKED_CELL := "res://assets/art/ocean_v2/mechanics/tidal_locked_cell.png"
const OCEAN_V2_DIGIT_PATHS := [
	"res://assets/art/ocean_v2/digits/digit_1.png",
	"res://assets/art/ocean_v2/digits/digit_2.png",
	"res://assets/art/ocean_v2/digits/digit_3.png",
	"res://assets/art/ocean_v2/digits/digit_4.png",
	"res://assets/art/ocean_v2/digits/digit_5.png",
	"res://assets/art/ocean_v2/digits/digit_6.png",
]
const OCEAN_V2_MARKER := "res://assets/art/ocean_v2/markers/ocean_marker.png"
const OCEAN_V2_MARKER_FAILED := "res://assets/art/ocean_v2/markers/ocean_marker_failed.png"
const OCEAN_V2_MARKER_WRONG := "res://assets/art/ocean_v2/markers/ocean_marker_wrong.png"
const OCEAN_V2_ECOLOGY_PATHS := [
	"res://assets/art/ocean_v2/ecology/level_08_anemone.png",
	"res://assets/art/ocean_v2/ecology/level_09_seagrass.png",
	"res://assets/art/ocean_v2/ecology/level_10_coral.png",
	"res://assets/art/ocean_v2/ecology/level_11_jellyfish.png",
	"res://assets/art/ocean_v2/ecology/level_12_fish_school.png",
	"res://assets/art/ocean_v2/ecology/level_13_trench.png",
	"res://assets/art/ocean_v2/ecology/level_14_whale_fall.png",
]
const OCEAN_V2_ECOLOGY_POLLUTED_PATHS := [
	"res://assets/art/ocean_v2/ecology/polluted/level_08_anemone.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_09_seagrass.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_10_coral.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_11_jellyfish.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_12_fish_school.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_13_trench.png",
	"res://assets/art/ocean_v2/ecology/polluted/level_14_whale_fall.png",
]
const OCEAN_BADGE_ZH_PATHS := [
	"res://assets/art/ocean_v2/badges/zh/level_08_anemone.png",
	"res://assets/art/ocean_v2/badges/zh/level_09_seagrass.png",
	"res://assets/art/ocean_v2/badges/zh/level_10_coral.png",
	"res://assets/art/ocean_v2/badges/zh/level_11_jellyfish.png",
	"res://assets/art/ocean_v2/badges/zh/level_12_fish_school.png",
	"res://assets/art/ocean_v2/badges/zh/level_13_trench.png",
	"res://assets/art/ocean_v2/badges/zh/level_14_whale_fall.png",
]
const OCEAN_BADGE_EN_PATHS := [
	"res://assets/art/ocean_v2/badges/en/level_08_anemone.png",
	"res://assets/art/ocean_v2/badges/en/level_09_seagrass.png",
	"res://assets/art/ocean_v2/badges/en/level_10_coral.png",
	"res://assets/art/ocean_v2/badges/en/level_11_jellyfish.png",
	"res://assets/art/ocean_v2/badges/en/level_12_fish_school.png",
	"res://assets/art/ocean_v2/badges/en/level_13_trench.png",
	"res://assets/art/ocean_v2/badges/en/level_14_whale_fall.png",
]
const OCEAN_V2_ROBOT_FRONT := "res://assets/art/ocean_v2/characters/ocean_robot_front.png"
const OCEAN_V2_ROBOT_LEFT_FRONT := "res://assets/art/ocean_v2/characters/ocean_robot_left_front.png"
const OCEAN_V2_ROBOT_RIGHT_FRONT := "res://assets/art/ocean_v2/characters/ocean_robot_right_front.png"
const OCEAN_V2_ROBOT_IDLE_PATHS := [
	OCEAN_V2_ROBOT_LEFT_FRONT,
	OCEAN_V2_ROBOT_FRONT,
	OCEAN_V2_ROBOT_RIGHT_FRONT,
]
const OCEAN_V2_ROBOT_FRONT_TORSO := "res://assets/art/ocean_v2/characters/ocean_robot_front_torso.png"
const OCEAN_V2_ROBOT_ARM := "res://assets/art/ocean_v2/characters/ocean_robot_arm.png"
const OCEAN_V2_OCTOPUS_ALERT := "res://assets/art/ocean_v2/characters/octopus_alert.png"
const OCEAN_V2_OCTOPUS_DEFIANT_PATHS := [
	"res://assets/art/ocean_v2/characters/octopus_defiant_left.png",
	"res://assets/art/ocean_v2/characters/octopus_defiant.png",
	"res://assets/art/ocean_v2/characters/octopus_defiant_right.png",
]
const OCEAN_V2_OCTOPUS_MOCK_PATHS := [
	"res://assets/art/ocean_v2/characters/octopus_mock_left.png",
	"res://assets/art/ocean_v2/characters/octopus_mock.png",
	"res://assets/art/ocean_v2/characters/octopus_mock_right.png",
]
const OCEAN_V2_OCTOPUS_DEFEATED := "res://assets/art/ocean_v2/characters/octopus_defeated.png"

const LAND_PAUSE_NORMAL := "res://assets/art/land_levels/buttons/pause_normal.png"
const LAND_PAUSE_HOVER := "res://assets/art/land_levels/buttons/pause_hover.png"
const LAND_PAUSE_FOCUS := "res://assets/art/land_levels/buttons/pause_focus.png"
const LAND_PAUSE_PRESSED := "res://assets/art/land_levels/buttons/pause_pressed.png"
const LAND_REGENERATE_NORMAL := "res://assets/art/land_levels/buttons/regenerate_normal.png"
const LAND_REGENERATE_HOVER := "res://assets/art/land_levels/buttons/regenerate_hover.png"
const LAND_REGENERATE_FOCUS := "res://assets/art/land_levels/buttons/regenerate_focus.png"
const LAND_REGENERATE_PRESSED := "res://assets/art/land_levels/buttons/regenerate_pressed.png"
const OCEAN_PAUSE_NORMAL := "res://assets/art/ocean_levels/buttons/ocean_pause_normal.png"
const OCEAN_PAUSE_HOVER := "res://assets/art/ocean_levels/buttons/ocean_pause_hover.png"
const OCEAN_PAUSE_FOCUS := "res://assets/art/ocean_levels/buttons/ocean_pause_focus.png"
const OCEAN_PAUSE_PRESSED := "res://assets/art/ocean_levels/buttons/ocean_pause_pressed.png"
const OCEAN_REGENERATE_NORMAL := \
		"res://assets/art/ocean_levels/buttons/ocean_regenerate_normal.png"
const OCEAN_REGENERATE_HOVER := \
		"res://assets/art/ocean_levels/buttons/ocean_regenerate_hover.png"
const OCEAN_REGENERATE_FOCUS := \
		"res://assets/art/ocean_levels/buttons/ocean_regenerate_focus.png"
const OCEAN_REGENERATE_PRESSED := \
		"res://assets/art/ocean_levels/buttons/ocean_regenerate_pressed.png"

const LEVEL_02_DECOR_SHRUB_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_02_shrub_healthy.png"
const LEVEL_02_DECOR_SHRUB_WILTED := \
		"res://assets/art/land_levels/decorations/level_02_shrub_wilted.png"
const LEVEL_03_DECOR_WETLAND_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_03_wetland_healthy.png"
const LEVEL_03_DECOR_WETLAND_POLLUTED := \
		"res://assets/art/land_levels/decorations/level_03_wetland_polluted.png"
const LEVEL_04_DECOR_GRASS_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_04_grass_healthy.png"
const LEVEL_04_DECOR_GRASS_WILTED := \
		"res://assets/art/land_levels/decorations/level_04_grass_wilted.png"
const LEVEL_05_DECOR_TREE_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_05_tree_healthy.png"
const LEVEL_05_DECOR_TREE_WILTED := \
		"res://assets/art/land_levels/decorations/level_05_tree_wilted.png"
const LEVEL_05_FOREST_EDGE_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_05_forest_edge_healthy.png"
const LEVEL_05_FOREST_EDGE_WILTED := \
		"res://assets/art/land_levels/decorations/level_05_forest_edge_wilted.png"
const LEVEL_07_ANCIENT_FOREST_HEALTHY := \
		"res://assets/art/land_levels/decorations/level_07_ancient_forest_healthy.png"
const LEVEL_07_ANCIENT_FOREST_WILTED := \
		"res://assets/art/land_levels/decorations/level_07_ancient_forest_wilted.png"
const LEVEL_05_BOSS_TREE_ACTIVE := \
		"res://assets/art/land_levels/decorations/level_05_boss_tree_active.png"
const LEVEL_05_BOSS_TREE_CLEANSED := \
		"res://assets/art/land_levels/decorations/level_05_boss_tree_cleansed.png"

const LEVEL_02_STICKER_01 := \
		"res://assets/art/land_levels/stickers/level_02_sticker_01.png"
const LEVEL_02_STICKER_02 := \
		"res://assets/art/land_levels/stickers/level_02_sticker_02.png"
const LEVEL_03_STICKER_01 := \
		"res://assets/art/land_levels/stickers/level_03_sticker_01.png"
const LEVEL_03_STICKER_02 := \
		"res://assets/art/land_levels/stickers/level_03_sticker_02.png"
const LEVEL_04_STICKER_01 := \
		"res://assets/art/land_levels/stickers/level_04_sticker_01.png"
const LEVEL_04_STICKER_02 := \
		"res://assets/art/land_levels/stickers/level_04_sticker_02.png"
const LEVEL_04_STICKER_03 := \
		"res://assets/art/land_levels/stickers/level_04_sticker_03.png"
const LEVEL_05_STICKER_01 := \
		"res://assets/art/land_levels/stickers/level_05_sticker_01.png"
const LEVEL_05_STICKER_02 := \
		"res://assets/art/land_levels/stickers/level_05_sticker_02.png"
const LEVEL_05_STICKER_03 := \
		"res://assets/art/land_levels/stickers/level_05_sticker_03.png"

const LEVEL_01_GUARDIAN_TOP_WHITE := \
		"res://assets/art/level_01/guardians/top_guardian_white_standing.png"
const LEVEL_01_GUARDIAN_TOP_YELLOW := \
		"res://assets/art/level_01/guardians/top_guardian_yellow_standing.png"
const LEVEL_01_GUARDIAN_TOP_LIGHT_GREEN := \
		"res://assets/art/level_01/guardians/top_guardian_light_green_standing.png"
const LEVEL_01_GUARDIAN_TOP_DARK_GREEN := \
		"res://assets/art/level_01/guardians/top_guardian_dark_green_standing.png"
const LEVEL_01_GUARDIAN_RIGHT_WHITE_SITTING := \
		"res://assets/art/level_01/guardians/right_panel_guardian_white_sitting.png"
const LEVEL_01_GUARDIAN_RIGHT_YELLOW_STANDING := \
		"res://assets/art/level_01/guardians/right_panel_guardian_yellow_standing.png"
const LEVEL_01_GUARDIAN_LEFT_ROBOT := \
		"res://assets/art/land_levels/guardians/left_robot_guardian.png"
const LAND_TABLETOP_PAPER_MONSTER := \
		"res://assets/art/land_levels/guardians/tabletop_paper_monster.png"
const LEVEL_01_GUARDIAN_LEFT_SPROUT_FACING_RIGHT := \
		"res://assets/art/level_01/guardians/left_sprout_guardian_facing_right.png"
const LEVEL_01_GUARDIAN_LEFT_SPROUT_FACING_LEFT := \
		"res://assets/art/level_01/guardians/left_sprout_guardian_facing_left.png"
const LAND_GUARDIAN_LEFT_CRYING := \
		"res://assets/art/land_levels/guardians/left_guardian_crying.png"
const LAND_ROBOT_FAILURE_BODY := \
		"res://assets/art/land_levels/guardians/robot_reaction_body_with_sprout.png"
const OCEAN_PROTAGONIST_ROBOT := \
		"res://assets/art/ocean_levels/actors/ocean_robot_helmet.png"
const OCEAN_PROTAGONIST_REACTION_BODY := \
		"res://assets/art/ocean_levels/actors/ocean_robot_reaction_body.png"
const OCEAN_PROTAGONIST_MONSTER := \
		"res://assets/art/ocean_levels/actors/ocean_bubble_monster.png"
const OCEAN_PROTAGONIST_MONSTER_CRYING := \
		"res://assets/art/ocean_levels/actors/ocean_bubble_monster_crying.png"
const SKY_PROTAGONIST_ROBOT := \
		"res://assets/art/sky_levels/actors/sky_robot_upright.png"
const SKY_PROTAGONIST_VICTORY_BODY := \
		"res://assets/art/sky_levels/actors/sky_robot_victory_body.png"
const SKY_PROTAGONIST_FAILURE_BODY := \
		"res://assets/art/sky_levels/actors/sky_robot_failure_body.png"
const SKY_PROTAGONIST_PLANE := \
		"res://assets/art/sky_levels/actors/sky_robot_plane.png"
const SKY_PROTAGONIST_MONSTER := \
		"res://assets/art/sky_levels/actors/sky_monster_paper_plane.png"
const SKY_ECOLOGY_CLOUD_CROWN_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_15_ecology_healthy.png"
const SKY_ECOLOGY_CLOUD_CROWN_FAILED := \
		"res://assets/art/sky_levels/ecology/level_15_ecology_failed.png"
const SKY_ECOLOGY_WIND_RING_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_16_ecology_healthy.png"
const SKY_ECOLOGY_WIND_RING_FAILED := \
		"res://assets/art/sky_levels/ecology/level_16_ecology_failed.png"
const SKY_ECOLOGY_RAINBOW_BRIDGE_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_17_ecology_healthy.png"
const SKY_ECOLOGY_RAINBOW_BRIDGE_FAILED := \
		"res://assets/art/sky_levels/ecology/level_17_ecology_failed.png"
const SKY_ECOLOGY_FLOATING_ISLAND_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_18_ecology_healthy.png"
const SKY_ECOLOGY_FLOATING_ISLAND_FAILED := \
		"res://assets/art/sky_levels/ecology/level_18_ecology_failed.png"
const SKY_ECOLOGY_CLOUD_RIDGE_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_19_ecology_healthy.png"
const SKY_ECOLOGY_CLOUD_RIDGE_FAILED := \
		"res://assets/art/sky_levels/ecology/level_19_ecology_failed.png"
const SKY_ECOLOGY_STORM_EYE_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_20_ecology_healthy.png"
const SKY_ECOLOGY_STORM_EYE_FAILED := \
		"res://assets/art/sky_levels/ecology/level_20_ecology_failed.png"
const SKY_ECOLOGY_SKY_PALACE_HEALTHY := \
		"res://assets/art/sky_levels/ecology/level_21_ecology_healthy.png"
const SKY_ECOLOGY_SKY_PALACE_FAILED := \
		"res://assets/art/sky_levels/ecology/level_21_ecology_failed.png"
const SKY_ECOLOGY_HEALTHY_PATHS := [
	SKY_ECOLOGY_CLOUD_CROWN_HEALTHY,
	SKY_ECOLOGY_WIND_RING_HEALTHY,
	SKY_ECOLOGY_RAINBOW_BRIDGE_HEALTHY,
	SKY_ECOLOGY_FLOATING_ISLAND_HEALTHY,
	SKY_ECOLOGY_CLOUD_RIDGE_HEALTHY,
	SKY_ECOLOGY_STORM_EYE_HEALTHY,
	SKY_ECOLOGY_SKY_PALACE_HEALTHY,
]
const SKY_ECOLOGY_FAILED_PATHS := [
	SKY_ECOLOGY_CLOUD_CROWN_FAILED,
	SKY_ECOLOGY_WIND_RING_FAILED,
	SKY_ECOLOGY_RAINBOW_BRIDGE_FAILED,
	SKY_ECOLOGY_FLOATING_ISLAND_FAILED,
	SKY_ECOLOGY_CLOUD_RIDGE_FAILED,
	SKY_ECOLOGY_STORM_EYE_FAILED,
	SKY_ECOLOGY_SKY_PALACE_FAILED,
]
const OCEAN_ACTOR_ANEMONE_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_06_anemone_healthy.png"
const OCEAN_ACTOR_ANEMONE_WILTED := \
		"res://assets/art/ocean_levels/actors/level_06_anemone_wilted.png"
const OCEAN_ACTOR_SEAGRASS_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_07_seagrass_healthy.png"
const OCEAN_ACTOR_SEAGRASS_WILTED := \
		"res://assets/art/ocean_levels/actors/level_07_seagrass_wilted.png"
const OCEAN_ACTOR_CORAL_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_08_coral_healthy.png"
const OCEAN_ACTOR_CORAL_WILTED := \
		"res://assets/art/ocean_levels/actors/level_08_coral_wilted.png"
const OCEAN_ACTOR_KELP_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_09_kelp_healthy.png"
const OCEAN_ACTOR_KELP_WILTED := \
		"res://assets/art/ocean_levels/actors/level_09_kelp_wilted.png"
const OCEAN_ACTOR_WHALE_FALL_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_10_whale_fall_healthy.png"
const OCEAN_ACTOR_WHALE_FALL_WILTED := \
		"res://assets/art/ocean_levels/actors/level_10_whale_fall_wilted.png"
const OCEAN_ACTOR_JELLYFISH_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_11_jellyfish_healthy.png"
const OCEAN_ACTOR_JELLYFISH_WILTED := \
		"res://assets/art/ocean_levels/actors/level_11_jellyfish_wilted.png"
const OCEAN_ACTOR_FISH_SCHOOL_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_12_fish_school_healthy.png"
const OCEAN_ACTOR_FISH_SCHOOL_WILTED := \
		"res://assets/art/ocean_levels/actors/level_12_fish_school_wilted.png"
const OCEAN_ACTOR_TRENCH_HEALTHY := \
		"res://assets/art/ocean_levels/actors/level_13_trench_healthy.png"
const OCEAN_ACTOR_TRENCH_WILTED := \
		"res://assets/art/ocean_levels/actors/level_13_trench_wilted.png"
const OCEAN_ACTOR_HEALTHY_PATHS := [
	OCEAN_ACTOR_ANEMONE_HEALTHY,
	OCEAN_ACTOR_SEAGRASS_HEALTHY,
	OCEAN_ACTOR_CORAL_HEALTHY,
	OCEAN_ACTOR_JELLYFISH_HEALTHY,
	OCEAN_ACTOR_FISH_SCHOOL_HEALTHY,
	OCEAN_ACTOR_TRENCH_HEALTHY,
	OCEAN_ACTOR_WHALE_FALL_HEALTHY,
]
const OCEAN_ACTOR_WILTED_PATHS := [
	OCEAN_ACTOR_ANEMONE_WILTED,
	OCEAN_ACTOR_SEAGRASS_WILTED,
	OCEAN_ACTOR_CORAL_WILTED,
	OCEAN_ACTOR_JELLYFISH_WILTED,
	OCEAN_ACTOR_FISH_SCHOOL_WILTED,
	OCEAN_ACTOR_TRENCH_WILTED,
	OCEAN_ACTOR_WHALE_FALL_WILTED,
]
const LAND_GUARDIAN_RIGHT_YELLOW_CRYING := \
		"res://assets/art/land_levels/guardians/right_yellow_guardian_crying.png"
const LAND_GUARDIAN_RIGHT_WHITE_CRYING := \
		"res://assets/art/land_levels/guardians/right_white_guardian_crying.png"

const LEVEL_SELECT_DESKTOP_BACKGROUND := \
		"res://assets/art/level_select/desktop_background2_clean.png"
const LEVEL_SELECT_LAND_MAP := \
		"res://assets/art/level_select/land_map2_rebuilt.png"
const LEVEL_SELECT_BOTTOM_INFO_BAR := \
		"res://assets/art/level_select/bottom_info_bar.png"
const LEVEL_SELECT_MARKER_BUTTON := \
		"res://assets/art/level_select/level_marker_button.png"
const LEVEL_SELECT_SHORTCUT_BUTTON := \
		"res://assets/art/level_select/shortcut_button_dark.png"
const OCEAN_LEVEL_SELECT_BACKGROUND := \
		"res://assets/art/level_select/ocean_level_select_background_clean.png"
const OCEAN_LEVEL_SELECT_MAP := \
		"res://assets/art/level_select/ocean_level_map_rebuilt.png"
const OCEAN_LEVEL_SELECT_MARKER := \
		"res://assets/art/level_select/ocean_level_marker_star.png"
const OCEAN_LEVEL_SELECT_FINAL_MARKER := \
		"res://assets/art/level_select/ocean_level_marker_final.png"
const SKY_LEVEL_SELECT_MAP := \
		"res://assets/art/level_select/sky_level_map_clean.png"

const WELCOME_LANDSCAPE_BASE := "res://assets/art/welcome/background/landscape_base.png"
const WELCOME_SUN_GLOW := "res://assets/art/welcome/effects/sun_glow.png"
const WELCOME_POLLEN_PARTICLES := "res://assets/art/welcome/effects/pollen_particles.png"
const WELCOME_WATER_GLINT := "res://assets/art/welcome/effects/water_glint.png"
const WELCOME_ROBOT_HEAD_SPROUT := "res://assets/art/welcome/actors/robot_head_sprout.png"
const WELCOME_ROBOT_FRONT := "res://assets/art/welcome/actors/robot_front.png"
const WELCOME_ROBOT_BACK := "res://assets/art/welcome/actors/robot_back.png"
const WELCOME_ROBOT_RIGHT := "res://assets/art/welcome/actors/robot_right.png"
const WELCOME_ROBOT_PLANTING := "res://assets/art/welcome/actors/robot_planting.png"
const WELCOME_ROBOT_FRONT_SMILING := \
		"res://assets/art/welcome/actors/robot_front_smiling.png"
const WELCOME_ROBOT_CHASING := "res://assets/art/welcome/actors/robot_chasing.png"
const WELCOME_ROBOT_ARM_LEFT := "res://assets/art/welcome/actors/robot_arm_left.png"
const WELCOME_ROBOT_ARM_RIGHT := "res://assets/art/welcome/actors/robot_arm_right.png"
const WELCOME_ROBOT_SHOULDER_LEFT := \
		"res://assets/art/welcome/actors/robot_shoulder_left.png"
const WELCOME_SLIME_FRONT := "res://assets/art/welcome/actors/slime_front.png"
const WELCOME_SLIME_BACK := "res://assets/art/welcome/actors/slime_back.png"
const WELCOME_SLIME_RIGHT := "res://assets/art/welcome/actors/slime_right.png"
const WELCOME_SLIME_SQUASHED := "res://assets/art/welcome/actors/slime_squashed.png"
const WELCOME_SLIME_CHASE_SHELL := \
		"res://assets/art/welcome/actors/slime_chase_shell.png"
const WELCOME_SLIME_CHASE_CONTENTS := \
		"res://assets/art/welcome/actors/slime_chase_contents.png"
