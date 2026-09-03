extends SceneTree

const ART := preload("res://scripts/art_catalog.gd")
const TEST_SAVE_PATH := "user://green_sweeper_desktop_layout_test.json"

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_cleanup()
	root.size = Vector2i(1280, 720)
	var shell_scene: PackedScene = load("res://scenes/shell.tscn")
	var shell := shell_scene.instantiate()
	shell.save_path = TEST_SAVE_PATH
	root.add_child(shell)
	await process_frame

	_test_menu_columns(shell)
	await _test_settings_layout(shell)
	await _test_first_guide_layout(shell)
	await _test_game_columns(shell)
	await _test_ocean_stage_layout(shell)
	await _test_steam_deck_height(shell)

	shell.queue_free()
	await process_frame
	_cleanup()
	if failures == 0:
		print("Green Sweeper desktop layout tests passed.")
		quit(0)
	else:
		push_error("%d desktop layout test(s) failed." % failures)
		quit(1)


func _test_menu_columns(shell) -> void:
	var menu_panel := shell.get_node("%MenuPanel") as Control
	var showcase_panel := shell.get_node("%ShowcasePanel") as Control
	var welcome_artwork := shell.get_node("%EcoShowcase") as Control
	_expect(_inside_viewport(menu_panel), "The floating menu stays inside 1280x720.")
	_expect(_inside_viewport(showcase_panel), "The full-screen ecology artwork stays inside 1280x720.")
	_expect(showcase_panel.get_global_rect().encloses(menu_panel.get_global_rect()), "The title and actions float over the ecology artwork.")
	_expect(showcase_panel.size.x >= 1279.0 and showcase_panel.size.y >= 719.0, "The welcome artwork fills the 1280x720 viewport.")
	_expect(welcome_artwork is WelcomeShowcase and welcome_artwork.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The layered welcome artwork fills the background without intercepting input.")
	_expect(welcome_artwork.is_processing(), "Welcome animation runs while the main menu is visible.")


func _test_settings_layout(shell) -> void:
	var welcome_artwork := shell.get_node("%EcoShowcase") as Control
	shell.show_settings()
	await process_frame
	var operation_mode := shell.get_node("%OperationModeOption") as Control
	var back_button := shell.get_node("%SettingsBackButton") as Control
	_expect(_inside_viewport(operation_mode), "The operation-mode selector fits inside 1280x720 settings.")
	_expect(_inside_viewport(back_button), "The enlarged settings panel keeps its back button inside 1280x720.")
	_expect(not welcome_artwork.is_processing(), "Welcome animation pauses while its page is hidden.")
	shell.show_main_menu()
	await process_frame
	_expect(welcome_artwork.is_processing(), "Welcome animation resumes with the main menu.")


func _test_first_guide_layout(shell) -> void:
	shell.start_cli_level(1)
	await process_frame
	await process_frame
	var game = shell.get_active_game()
	var guide = game.get_node("%FirstMoveGuide")
	var next_button := game.get_node("%TutorialNextButton") as Button
	var exit_button := game.get_node("%TutorialExitButton") as Button
	var board := game.get_node("%Board") as MinesweeperBoard
	var bubble_rect: Rect2 = guide.get_stable_bubble_rect()
	var target_center: Vector2 = guide.get_target_center()
	var target_size: Vector2 = board.cell_nodes[board.guide_cell_index].size
	var target_rect := Rect2(target_center - target_size * 0.5, target_size)
	var vertical_gap := minf(
		absf(target_rect.position.y - bubble_rect.end.y),
		absf(bubble_rect.position.y - target_rect.end.y)
	)
	_expect(guide.visible and guide.target_cell_index == board.guide_cell_index, "The Level-1 tutorial targets the suggested cell.")
	_expect(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The tutorial drawing remains click-through.")
	_expect(exit_button.visible and exit_button.mouse_filter == Control.MOUSE_FILTER_STOP, "The exit control alone captures its own mouse area.")
	_expect(
		guide.get_node("%GuideBubbleRoot").get_global_rect().encloses(exit_button.get_global_rect()),
		"The exit button stays inside the tutorial bubble."
	)
	_expect(not next_button.visible and next_button.mouse_filter == Control.MOUSE_FILTER_STOP, "The next button is reserved for explanation steps.")
	_expect(Rect2(Vector2.ZERO, guide.size).encloses(bubble_rect), "The stable guide bubble remains inside the board panel at 1280x720.")
	_expect(not bubble_rect.intersects(target_rect), "The guide bubble does not cover the suggested cell.")
	_expect(vertical_gap <= 13.0, "The guide bubble floats directly beside the suggested cell without a long connector.")
	_expect(board.custom_minimum_size == Vector2(620.0, 587.0), "The guide overlay does not change the shared handmade board size.")


func _test_game_columns(shell) -> void:
	shell.start_cli_level(5)
	await process_frame
	var game = shell.get_active_game()
	var eco_showcase := game.get_node("%EcoShowcase") as Control
	var desk_background := game.get_node("%LandDeskBackground") as Control
	var level_background := game.get_node("%LevelOneBackground") as Control
	var board_tray := game.get_node("%BoardTray") as Control
	var environment_panel := game.get_node("%EnvironmentPanel") as Control
	var board_panel := game.get_node("%BoardPanel") as Control
	var hud_panel := game.get_node("%HudPanel") as Control
	var tabletop_actors := game.get_node("%LandTabletopActors") as Control
	var robot_hotspot := tabletop_actors.get_node("DesignPlane/RobotSlot/RobotHotspot") as Control
	var scan_fallback_row := game.get_node("%ScanFallbackRow") as Control
	var quick_buttons := game.get_node("%QuickButtons") as Control
	var pause_button := game.get_node("%PauseButton") as Control
	var restart_button := game.get_node("%RestartButton") as Control
	_expect(_inside_viewport(environment_panel) and _inside_viewport(board_panel) and _inside_viewport(hud_panel), "All gameplay regions stay inside the viewport.")
	_expect(
		desk_background.visible
		and desk_background.get_global_rect() == Rect2(Vector2.ZERO, Vector2(root.size)),
		"Level 5 uses the full-viewport desktop background."
	)
	_expect(
		level_background.visible
		and _inside_viewport(level_background)
		and is_equal_approx(level_background.scale.x, 0.84),
		"Level 5 keeps the scaled unified interface artwork inside the desktop."
	)
	_expect(tabletop_actors.visible and _inside_viewport(robot_hotspot), "The tabletop actors and robot scanner hotspot stay on the desktop.")
	_expect(robot_hotspot.mouse_filter == Control.MOUSE_FILTER_STOP, "Only the robot scanner hotspot captures actor-layer clicks.")
	_expect(not scan_fallback_row.visible, "Land levels use the robot instead of the ocean fallback row.")
	_expect(
		quick_buttons.get_global_rect().encloses(pause_button.get_global_rect())
		and quick_buttons.get_global_rect().encloses(restart_button.get_global_rect()),
		"The widened quick-action row contains both buttons."
	)
	_expect(
		not pause_button.get_global_rect().intersects(restart_button.get_global_rect()),
		"Pause and regenerate buttons never overlap."
	)
	_expect(
		quick_buttons.position == Vector2(-10.0, 458.0)
		and pause_button.texture_normal.resource_path == ART.LAND_PAUSE_NORMAL
		and restart_button.texture_normal.resource_path == ART.LAND_REGENERATE_NORMAL,
		"Land levels retain the established quick-button position and artwork."
	)
	_expect(not board_tray.visible, "Level 5 uses the unified stage instead of the legacy board tray node.")
	_expect(not eco_showcase.visible, "The former procedural level background stays hidden.")
	_expect(
		environment_panel.get_theme_stylebox("panel") is StyleBoxFlat
		and board_panel.get_theme_stylebox("panel") is StyleBoxFlat
		and hud_panel.get_theme_stylebox("panel") is StyleBoxEmpty,
		"Gameplay regions use the current unified paper-stage styles."
	)
	_expect(
		environment_panel.get_global_rect().end.x
		<= board_panel.get_global_rect().position.x + 8.0,
		"The environment column remains aligned to the left edge of the board."
	)
	_expect(
		board_panel.get_global_rect().end.x < hud_panel.get_global_rect().position.x,
		"The HUD column sits right of the board."
	)
	var board := game.get_node("%Board") as MinesweeperBoard
	_expect(board.custom_minimum_size == Vector2(620.0, 587.0), "Level 5 keeps the shared handmade board stage.")

	game.set_session_paused(true)
	await process_frame
	var overlay := game.get_node("%PauseOverlay") as Control
	_expect(overlay.visible and overlay.global_position == Vector2.ZERO, "Pause overlay starts at the viewport origin.")
	_expect(overlay.size == Vector2(root.size), "Pause overlay covers the complete three-column viewport.")
	game.set_session_paused(false)


func _test_ocean_stage_layout(shell) -> void:
	shell.start_cli_level(6)
	await process_frame
	await process_frame
	var game = shell.get_active_game()
	var ocean_stage := game.get_node("%OceanStage") as Control
	var ocean_background := game.get_node("%OceanDeskBackground") as TextureRect
	var ocean_paper := game.get_node("%OceanBoardPaper") as Control
	var ocean_tray := game.get_node("%OceanBoardTrayFrame") as TextureRect
	var page_margin := game.get_node("PageMargin") as MarginContainer
	var board := game.get_node("%Board") as MinesweeperBoard
	var quick_buttons := game.get_node("%QuickButtons") as HBoxContainer
	var pause_button := game.get_node("%PauseButton") as TextureButton
	var restart_button := game.get_node("%RestartButton") as TextureButton
	var tabletop_actors := game.get_node("%LandTabletopActors") as LandTabletopActors
	var robot_hotspot := tabletop_actors.get_node("DesignPlane/RobotSlot/RobotHotspot") as Control
	var plant_sprite := tabletop_actors.get_node("DesignPlane/PlantSlot/PlantMotion/PlantSprite") as Sprite2D
	var plant_shadow := tabletop_actors.get_node("DesignPlane/PlantSlot/PlantShadow") as Control
	var scan_fallback_row := game.get_node("%ScanFallbackRow") as Control
	_expect(ocean_stage.visible, "Level 6 enables the shared ocean stage.")
	_expect(
		not game.get_node("%LandDeskBackground").visible
		and not game.get_node("%LevelOneBackground").visible
		and not game.get_node("%LandUnifiedShadow").visible,
		"Level 6 hides every land-stage layer."
	)
	_expect(not game.get_node("%EcoShowcase").visible, "Level 6 retires the former procedural showcase.")
	_expect(
		tabletop_actors.visible
		and tabletop_actors.uses_ocean_ecology()
		and _inside_viewport(robot_hotspot),
		"Level 6 keeps the shared robot and ocean ecology actor layer on screen."
	)
	_expect(not scan_fallback_row.visible, "Level 6 uses the robot instead of the fallback scan row.")
	_expect(
		plant_sprite.texture != null
		and plant_sprite.texture.resource_path == ART.OCEAN_ACTOR_ANEMONE_HEALTHY,
		"Level 6 loads the accepted healthy anemone actor."
	)
	_expect(
		is_equal_approx(plant_sprite.scale.x, plant_sprite.scale.y)
		and not plant_shadow.visible,
		"Ocean ecology remains proportional and does not receive an extra generated shadow."
	)
	_expect(
		ocean_stage.get_global_rect() == Rect2(Vector2.ZERO, Vector2(root.size))
		and ocean_background.get_global_rect() == ocean_stage.get_global_rect()
		and ocean_tray.get_global_rect() == ocean_stage.get_global_rect(),
		"The ocean background and tray share the 1280x720 design plane."
	)
	_expect(
		ocean_stage.position == page_margin.position
		and ocean_stage.scale == page_margin.scale,
		"The ocean artwork and interactive columns use one transform."
	)
	_expect(
		ocean_stage.get_global_rect().encloses(ocean_paper.get_global_rect()),
		"The temporary ocean paper stays inside the tray stage."
	)
	_expect(
		ocean_background.texture != null
		and ocean_tray.texture != null,
		"The confirmed ocean background and transparent tray are loaded."
	)
	_expect(
		quick_buttons.position == Vector2(-8.0, 446.0)
		and pause_button.texture_normal.resource_path == ART.OCEAN_PAUSE_NORMAL
		and pause_button.texture_hover.resource_path == ART.OCEAN_PAUSE_HOVER
		and restart_button.texture_normal.resource_path == ART.OCEAN_REGENERATE_NORMAL
		and restart_button.texture_pressed.resource_path == ART.OCEAN_REGENERATE_PRESSED,
		"Ocean levels apply their button states and slight upper-right offset."
	)
	_expect(
		not pause_button.get_global_rect().intersects(restart_button.get_global_rect()),
		"The shifted ocean quick buttons remain separate."
	)
	_expect(
		board.topology == &"hex_pointy_odd_r",
		"The ocean stage keeps the pointy odd-row hex board."
	)


func _test_steam_deck_height(shell) -> void:
	shell.show_main_menu()
	root.size = Vector2i(1280, 800)
	await process_frame
	await process_frame
	var menu_panel := shell.get_node("%MenuPanel") as Control
	var showcase_panel := shell.get_node("%ShowcasePanel") as Control
	_expect(_inside_viewport(menu_panel) and _inside_viewport(showcase_panel), "The menu remains inside a 1280x800 viewport.")
	_expect(menu_panel.size.y > 680.0 and showcase_panel.size.y > 680.0, "Steam Deck height becomes usable page space.")
	shell.show_settings()
	await process_frame
	_expect(_inside_viewport(shell.get_node("%OperationModeOption") as Control), "The operation selector remains inside the 1280x800 settings page.")
	shell.start_cli_level(1)
	await process_frame
	await process_frame
	var game = shell.get_active_game()
	var desk_background := game.get_node("%LandDeskBackground") as Control
	var game_background := game.get_node("%LevelOneBackground") as Control
	var guide = game.get_node("%FirstMoveGuide")
	_expect(
		desk_background.get_global_rect() == Rect2(Vector2.ZERO, Vector2(root.size)),
		"The desktop background expands to 1280x800."
	)
	_expect(
		_inside_viewport(game_background) and is_equal_approx(game_background.scale.x, 0.84),
		"The scaled unified interface remains inside 1280x800."
	)
	_expect(Rect2(Vector2.ZERO, guide.size).encloses(guide.get_stable_bubble_rect()), "The first-move guide remains inside the board panel at 1280x800.")

	shell.start_cli_level(6)
	await process_frame
	await process_frame
	game = shell.get_active_game()
	var ocean_stage := game.get_node("%OceanStage") as Control
	var ocean_background := game.get_node("%OceanDeskBackground") as Control
	var ocean_tray := game.get_node("%OceanBoardTrayFrame") as Control
	var ocean_page_margin := game.get_node("PageMargin") as MarginContainer
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	var expected_scale := 800.0 / 720.0
	_expect(
		is_equal_approx(ocean_stage.scale.x, expected_scale)
		and is_equal_approx(ocean_stage.scale.y, expected_scale),
		"The ocean design plane uses aspect-cover scaling at 1280x800."
	)
	_expect(
		ocean_stage.get_global_rect().encloses(viewport_rect)
		and ocean_background.get_global_rect() == ocean_stage.get_global_rect()
		and ocean_tray.get_global_rect() == ocean_stage.get_global_rect(),
		"The ocean background and tray cover the complete 1280x800 viewport together."
	)
	_expect(
		ocean_stage.position == ocean_page_margin.position
		and ocean_stage.scale == ocean_page_margin.scale,
		"Ocean art and gameplay columns remain aligned at 1280x800."
	)


func _inside_viewport(control: Control) -> bool:
	var rect := control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	return viewport_rect.encloses(rect)


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
