class_name ArtCatalog
extends RefCounted

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

const LEVEL_01_LAND_BACKGROUND := \
		"res://assets/art/level_01/background/land_paper_background.png"
const LAND_TABLETOP_BACKGROUND := \
		"res://assets/art/land_levels/background/land_tabletop_background5_clean.png"
const OCEAN_DESKTOP_BACKGROUND := \
		"res://assets/art/ocean_levels/background/ocean_desktop_clean.png"
const OCEAN_BOARD_TRAY_FRAME := \
		"res://assets/art/ocean_levels/stage/ocean_board_tray_frame.png"
const OCEAN_CELL_HIDDEN := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_hidden.png"
const OCEAN_CELL_REVEALED := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_revealed.png"
const OCEAN_CELL_POLLUTED := \
		"res://assets/art/ocean_levels/board/cells/ocean_cell_polluted.png"
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
		"res://assets/art/land_levels/guardians/robot_failure_body.png"
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
const OCEAN_ACTOR_HEALTHY_PATHS := [
	OCEAN_ACTOR_ANEMONE_HEALTHY,
	OCEAN_ACTOR_SEAGRASS_HEALTHY,
	OCEAN_ACTOR_CORAL_HEALTHY,
	OCEAN_ACTOR_KELP_HEALTHY,
	OCEAN_ACTOR_WHALE_FALL_HEALTHY,
]
const OCEAN_ACTOR_WILTED_PATHS := [
	OCEAN_ACTOR_ANEMONE_WILTED,
	OCEAN_ACTOR_SEAGRASS_WILTED,
	OCEAN_ACTOR_CORAL_WILTED,
	OCEAN_ACTOR_KELP_WILTED,
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
