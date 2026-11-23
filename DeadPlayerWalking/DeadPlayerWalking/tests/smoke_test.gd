extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var clean_save := ConfigFile.new()
	clean_save.set_value("progress", "points", 37)
	clean_save.set_value("progress", "attempts", 4)
	clean_save.set_value("progress", "upgrades", {
		"health": 2,
		"damage": 1,
		"speed": 0,
		"dungeon_edge": 0,
		"warden_crossbow": 0,
	})
	clean_save.set_value("history", "echoes", [])
	clean_save.set_value("settings", "music_volume", 1.0)
	clean_save.set_value("settings", "sfx_volume", 1.0)
	clean_save.save(PersistentRunManager.SAVE_PATH)

	var main_scene := load("res://scenes/core/main.tscn") as PackedScene
	_expect(main_scene != null, "The main scene should load.")
	if main_scene == null:
		quit(1)
		return

	var main := main_scene.instantiate() as Control
	root.add_child(main)
	await process_frame

	_expect(main.name == "Main", "The project should use a single Main scene root.")
	var profile_root := main.get_node_or_null("ProfileLayer/ProfileRoot") as Control
	var profile_selector := main.get_node_or_null("ProfileLayer/ProfileRoot/Card/SavedProfiles") as OptionButton
	var continue_profile_button := main.get_node_or_null("ProfileLayer/ProfileRoot/Card/ContinueProfile") as Button
	var profile_username := main.get_node_or_null("ProfileLayer/ProfileRoot/Card/UsernameInput") as LineEdit
	var create_profile_button := main.get_node_or_null("ProfileLayer/ProfileRoot/Card/CreateProfile") as Button
	var profile_manager := main.get_node("RunManager") as PersistentRunManager
	_expect(
		profile_root != null
		and profile_selector != null
		and continue_profile_button != null
		and profile_username != null
		and create_profile_button != null
		and profile_root.visible,
		"The authored profile chooser should appear before the game menu."
	)
	_expect(
		profile_manager.get_profiles() == ["Survivor"]
		and _select_profile_option(profile_selector, "Survivor")
		and not continue_profile_button.disabled,
		"Existing single-profile saves should migrate into a selectable Survivor profile."
	)
	continue_profile_button.emit_signal("pressed")
	await process_frame
	_expect(
		profile_manager.active_profile_name == "Survivor"
		and profile_manager.points == 37
		and profile_manager.attempts == 4
		and profile_manager.get_upgrade_level("health") == 2,
		"Selecting the migrated profile should preserve its old progress."
	)
	var profile_button := main.get_node("TutorialLayer/TutorialRoot/ProfileButton") as Button
	profile_button.emit_signal("pressed")
	await process_frame
	profile_username.text = "New Runner"
	create_profile_button.emit_signal("pressed")
	await process_frame
	_expect(
		profile_manager.active_profile_name == "New Runner"
		and profile_manager.points == 0
		and profile_manager.attempts == 0
		and not profile_manager.entry_tutorial_completed
		and profile_manager.get_upgrade_level("health") == 0
		and profile_manager.get_progress_snapshot()["echo_count"] == 0,
		"A newly created username should begin with no progress or previous selves."
	)
	_expect(
		not profile_manager.validate_profile_name(" new runner ").is_empty()
		and not profile_manager.validate_profile_name("").is_empty(),
		"Profile names should reject duplicates and blank usernames."
	)
	profile_button.emit_signal("pressed")
	await process_frame
	_expect(
		_select_profile_option(profile_selector, "Survivor"),
		"Existing and newly created profiles should both be available to select."
	)
	continue_profile_button.emit_signal("pressed")
	await process_frame
	_expect(
		profile_manager.active_profile_name == "Survivor" and profile_manager.points == 37,
		"Switching users should restore the selected profile's saved progress."
	)
	profile_button.emit_signal("pressed")
	await process_frame
	_expect(_select_profile_option(profile_selector, "New Runner"), "The new profile should remain selectable after switching users.")
	continue_profile_button.emit_signal("pressed")
	await process_frame
	_expect(
		profile_manager.active_profile_name == "New Runner" and profile_manager.points == 0,
		"Returning to a new profile should not inherit another user's progress."
	)
	var reloaded_manager := PersistentRunManager.new()
	root.add_child(reloaded_manager)
	await process_frame
	_expect(
		reloaded_manager.get_profiles() == ["New Runner", "Survivor"]
		and reloaded_manager.select_profile("Survivor")
		and reloaded_manager.points == 37
		and not reloaded_manager.entry_tutorial_completed
		and reloaded_manager.get_upgrade_level("health") == 2,
		"Profiles should reload their saved progress from disk in a new manager instance."
	)
	_expect(
		reloaded_manager.select_profile("New Runner")
		and reloaded_manager.points == 0
		and not reloaded_manager.entry_tutorial_completed
		and reloaded_manager.get_upgrade_level("health") == 0,
		"Reloading and switching profiles should keep the new user's progress isolated."
	)
	reloaded_manager.queue_free()
	await process_frame
	_expect(
		int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280
		and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720,
		"The game should use a native 1280 by 720 landscape design viewport."
	)
	var title_root := main.get("_screen_root") as Control
	var title_background := title_root.get_node_or_null("Background") as TextureRect if title_root != null else null
	_expect(
		title_background != null
		and title_background.texture.resource_path == "res://ASSETS/UI ASSETS/Asset 47 — Main menu background.png",
		"The title redesign should preserve its existing background asset."
	)
	_expect(
		title_root.get_node_or_null("TitleFrame") is PanelContainer
		and title_root.get_node_or_null("TitleEmblem") is PanelContainer,
		"The title design should include the thin frame and upper-right emblem."
	)
	var tutorial_root := main.get_node_or_null("TutorialLayer/TutorialRoot") as Control
	var tutorial_panel := tutorial_root.get_node_or_null("TutorialPanel") as Control if tutorial_root != null else null
	var tutorial_button := tutorial_root.get_node_or_null("TutorialButton") as Button if tutorial_root != null else null
	var title_profile_button := tutorial_root.get_node_or_null("ProfileButton") as Button if tutorial_root != null else null
	var tutorial_card := tutorial_panel.get_node_or_null("Card") as Control if tutorial_panel != null else null
	_expect(
		tutorial_root != null
		and tutorial_panel != null
		and tutorial_card != null
		and tutorial_card.get_node_or_null("StepCounter") is Label
		and tutorial_card.get_node_or_null("TargetTitle") is Label
		and tutorial_card.get_node_or_null("Description") is Label
		and tutorial_card.get_node_or_null("StartRun") is Button,
		"The step-by-step tutorial UI should be authored in the Main scene tree."
	)
	_expect(
		tutorial_panel.get_node_or_null("FocusFrame") is Panel
		and tutorial_panel.get_node_or_null("PointerLine") is Line2D
		and tutorial_panel.get_node_or_null("PointerHead") is Polygon2D,
		"Tutorial highlight and pointer nodes should be authored in the Main scene tree."
	)
	_expect(
		tutorial_panel != null and tutorial_button != null
		and not tutorial_panel.visible and tutorial_button.visible
		and title_profile_button != null and title_profile_button.visible,
		"The title menu should expose the tutorial and profile switcher without opening the tutorial automatically."
	)
	var title_line_one := title_root.get_node_or_null("TitleLineOne") as Label
	var title_line_two := title_root.get_node_or_null("TitleLineTwo") as Label
	_expect(
		title_line_one != null
		and title_line_one.text == "DEAD PLAYER"
		and title_line_one.get_theme_color("font_color") == Color("f0e9df")
		and title_line_two != null
		and title_line_two.text == "WALKING"
		and title_line_two.get_theme_color("font_color") == Color("ff405a"),
		"The title should use the reference's separate warm-white and red lines."
	)
	_expect(
		title_root.get_node_or_null("RunsCard") is PanelContainer
		and title_root.get_node_or_null("ScrapCard") is PanelContainer
		and title_root.get_node_or_null("EchoesCard") is PanelContainer
		and (title_root.find_child("RunsTitle", true, false) as Label).text == "RUNS"
		and (title_root.find_child("ScrapTitle", true, false) as Label).text == "SCRAP"
		and (title_root.find_child("EchoesTitle", true, false) as Label).text == "ECHOES",
		"The title screen should show the three compact progression cards."
	)
	var saved_level := main.get_node_or_null("Level01") as Level01Controller
	_expect(saved_level != null, "The saved Main scene should contain its gameplay level.")
	_expect(
		saved_level != null and saved_level.process_mode == Node.PROCESS_MODE_PAUSABLE,
		"The gameplay scene should opt into pausing beneath the always-processing menu."
	)
	_expect(saved_level != null and not saved_level.visible, "The saved gameplay scene should stay off-screen at the title.")
	_expect(
		saved_level != null and not (saved_level.get_node("HUD") as CanvasLayer).visible,
		"The gameplay HUD should stay off-screen at the title."
	)
	_expect(
		saved_level != null and saved_level.get_node_or_null("HUD/UI") is Control,
		"The HUD interface should be organized under its UI control."
	)
	var hud_root := saved_level.find_child("HudRoot", true, false) as Control if saved_level != null else null
	var top_hud_art := hud_root.find_child("TopHudArtwork", true, false) as TextureRect if hud_root != null else null
	_expect(
		hud_root != null
		and not hud_root is ColorRect
		and top_hud_art != null
		and top_hud_art.texture is AtlasTexture
		and (top_hud_art.texture as AtlasTexture).atlas.resource_path.contains("Top HUD@2x.png")
		and hud_root.find_child("PauseButton", true, false) is Button,
		"The top HUD should use the supplied Top HUD banner artwork."
	)
	_expect(
		saved_level != null and saved_level.get_node_or_null("Player/CollisionShape2D") is CollisionShape2D,
		"The saved Main scene tree should expose the player's body collision."
	)
	_expect(
		saved_level != null and saved_level.get_node_or_null("Player/MeleeHitbox/CollisionShape2D") is CollisionShape2D,
		"The saved Main scene tree should expose the player's melee collision."
	)
	_expect(
		saved_level != null
		and saved_level.get_node_or_null("Player/HealingEffect") is Sprite2D
		and saved_level.get_node_or_null("Rooms/DungeonRoom/HealingCollectionEffect") is Sprite2D
		and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/DungeonBoss/TargetTelegraph") is Sprite2D
		and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/DungeonBoss/SweepTelegraph") is Sprite2D
		and saved_level.get_node_or_null("Player/ReloadIndicator") is ProgressBar
		and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/Enemy01/ReloadIndicator") == null
		and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/PreviousSelf/Art") is Sprite2D,
		"Potion effects, boss AOE markers, player reload feedback, and the original PreviousSelf art should be authored in the Scene Dock."
	)
	_expect(
		saved_level != null
		and saved_level.get_node_or_null("Rooms/DungeonRoom/WorldGeometry/BoundaryLeft/CollisionShape2D") is CollisionShape2D
		and saved_level.get_node_or_null("Rooms/DungeonRoom/WorldGeometry/LockedExit/CollisionShape2D") is CollisionShape2D
		and saved_level.get_node_or_null("Rooms/DungeonRoom/ExitTrigger/CollisionShape2D") is CollisionShape2D,
		"The saved Main scene tree should expose room boundary, gate, and exit collisions."
	)
	_expect(
		saved_level != null
		and saved_level.get_node_or_null("Rooms/DungeonRoom/WorldGeometry/SuppliedWalls/WallTop04") is Sprite2D,
		"The saved Main scene tree should expose all nine authored top-wall segments."
	)
	var mob_health_bar := saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/Enemy01/MobHealthBar") as MobHealthBar if saved_level != null else null
	var echo_health_bar := saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/PreviousSelf/MobHealthBar") as MobHealthBar if saved_level != null else null
	var mob_health_bar_asset := load("res://ASSETS/ORDINARY ENEMY ASSETS/Mob Health Bars@2x.png") as Texture2D
	_expect(
		mob_health_bar != null
		and echo_health_bar != null
		and mob_health_bar.position.is_equal_approx(Vector2(0.0, -66.0))
		and echo_health_bar.position.is_equal_approx(Vector2(0.0, -92.0))
		and mob_health_bar.get_script().resource_path == "res://scripts/ui/mob_health_bar.gd"
		and echo_health_bar.get_script().resource_path == "res://scripts/ui/mob_health_bar.gd"
		and mob_health_bar_asset != null
		and mob_health_bar_asset.get_size() == Vector2(2200.0, 1320.0),
		"Ordinary enemies and previous selves should expose the supplied health bar above their heads in the Scene Dock."
	)
	if mob_health_bar != null:
		mob_health_bar.set_health(21, 42)
		_expect(
			is_equal_approx(mob_health_bar._health_ratio, 0.5)
			and mob_health_bar._chip_time > 0.0,
			"The mob health bar should update its segmented fill and damage chip dynamically."
		)
		mob_health_bar.set_health(42, 42)
	_expect(
		saved_level != null and (saved_level.get_node("Rooms/DungeonRoom/WorldGeometry/Obstacles") as Node2D).get_child_count() == 6,
		"The saved Main scene tree should expose collision nodes for every room obstacle layout."
	)
	for echo_index in 3:
		var echo_name := "PreviousSelf" if echo_index == 0 else "PreviousSelf%02d" % (echo_index + 1)
		_expect(
			saved_level != null
			and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/" + echo_name) is FacilityEnemy
			and saved_level.get_node_or_null("Rooms/DungeonRoom/Enemies/EchoGrave%02d" % (echo_index + 1)) is Node2D,
			"Every previous-self and grave slot should be authored and visible in the saved Scene Dock tree."
		)
	var authored_grave := load("res://scenes/dungeon/echo_grave.tscn") as PackedScene
	var grave_probe := authored_grave.instantiate() as Node2D if authored_grave != null else null
	var grave_sprite := grave_probe.get_node_or_null("GraveMarker") as Sprite2D if grave_probe != null else null
	_expect(
		grave_sprite != null
		and (grave_sprite.texture as AtlasTexture).atlas.resource_path.contains("Asset 33")
		and (grave_sprite.texture as AtlasTexture).region == Rect2(48.0, 16.0, 192.0, 400.0),
		"Each grave marker should use the authored monument region from the supplied dungeon prop sheet."
	)
	if is_instance_valid(grave_probe):
		grave_probe.free()

	var audio_manager := root.get_node("AudioManager") as GameAudioManager
	var manager := main.get_node("RunManager") as PersistentRunManager
	_expect(manager != null, "The persistent run manager should be present.")
	var main_menu_settings := _find_button(main, "SETTINGS")
	_expect(main_menu_settings != null, "The main menu should expose Settings.")
	_expect(_find_button(main, "EXIT GAME") != null, "The main menu should expose Exit.")
	_expect(
		_find_button(main, "ENTER THE DUNGEON") != null
		and _find_button(main, "PERMANENT UPGRADES") != null
		and (main_menu_settings.position.y > 0.0 if main_menu_settings != null else false),
		"The title menu should retain its four working options in the reference layout."
	)
	if main_menu_settings != null:
		main_menu_settings.emit_signal("pressed")
		await process_frame
		var main_screen := main.get("_screen_root") as Control
		var music_slider := main_screen.find_child("MusicVolume", true, false) as HSlider
		var effects_slider := main_screen.find_child("SfxVolume", true, false) as HSlider
		_expect(music_slider != null and effects_slider != null, "Settings should expose music and effect volume controls.")
		var settings_action := _find_button(main_screen, "SAVE AND RETURN")
		var action_style := settings_action.get_theme_stylebox("normal") as StyleBoxFlat if settings_action != null else null
		_expect(
			action_style != null and action_style.border_color == Color("56303b"),
			"Settings actions should use the shared dark-and-red button treatment."
		)
		if music_slider != null and effects_slider != null:
			music_slider.value = 0.65
			effects_slider.value = 0.75
			_expect(is_equal_approx(audio_manager.music_volume, 0.65), "The music slider should update live audio.")
			_expect(is_equal_approx(audio_manager.sfx_volume, 0.75), "The effects slider should update live audio.")
			main.call("_leave_settings")
			_expect(is_equal_approx(manager.music_volume, 0.65), "Settings should persist music volume.")
			_expect(is_equal_approx(manager.sfx_volume, 0.75), "Settings should persist effects volume.")
			var settings_save := ConfigFile.new()
			_expect(settings_save.load(PersistentRunManager.SAVE_PATH) == OK, "Audio settings should be written to the save file.")
			_expect(is_equal_approx(float(settings_save.get_value("settings", "music_volume", 0.0)), 0.65), "The saved music level should match the slider.")
			_expect(is_equal_approx(float(settings_save.get_value("settings", "sfx_volume", 0.0)), 0.75), "The saved effects level should match the slider.")
			manager.set_audio_volumes(1.0, 1.0)
			manager.save_settings()
			audio_manager.set_music_volume(1.0)
			audio_manager.set_sfx_volume(1.0)
	main.call("_show_workshop", false, 0, false)
	await process_frame
	var workshop_screen := main.get("_screen_root") as Control
	var unaffordable_weapon_purchase := _find_button(workshop_screen, "30  /  BUY")
	_expect(unaffordable_weapon_purchase != null and unaffordable_weapon_purchase.disabled, "Weapon upgrades should be visible but unaffordable without currency.")
	_expect(_contains_label(workshop_screen, "+12% sword damage"), "Weapon upgrades should display their descriptions.")
	_expect(_contains_label(workshop_screen, "+12% bolt damage"), "Both weapon upgrade descriptions should be displayed.")
	var upgrade_card := workshop_screen.find_child("UpgradeCard", true, false) as PanelContainer
	var upgrade_card_style := upgrade_card.get_theme_stylebox("panel") as StyleBoxFlat if upgrade_card != null else null
	_expect(
		upgrade_card_style != null and is_equal_approx(upgrade_card_style.bg_color.a, 1.0),
		"Workshop text and controls should sit on an opaque card rather than bleed into the background art."
	)
	var health_upgrade_icon := workshop_screen.find_child("healthIcon", true, false) as TextureRect
	_expect(
		health_upgrade_icon != null
		and (health_upgrade_icon.texture as AtlasTexture).atlas.resource_path.contains("Asset 46")
		and health_upgrade_icon.stretch_mode == TextureRect.STRETCH_SCALE
		and health_upgrade_icon.size.is_equal_approx(Vector2(48.0, 48.0))
		and health_upgrade_icon.position.is_equal_approx(Vector2(22.0, 117.0)),
		"Upgrade icons should use the supplied icon sheet and fit their aligned 48-pixel slots."
	)
	main.call("show_title_screen")
	var canvas_sizes := [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(1600.0, 900.0), Vector2(1024.0, 768.0)]
	for canvas_size in canvas_sizes:
		var canvas_layout: Dictionary = main.call("get_design_canvas_layout_for_size", canvas_size)
		var fitted_size := Vector2(1280.0, 720.0) * float(canvas_layout["scale"])
		var canvas_offset: Vector2 = canvas_layout["offset"]
		_expect(
			canvas_offset.x >= 0.0
			and canvas_offset.y >= 0.0
			and canvas_offset.x + fitted_size.x <= canvas_size.x + 0.01
			and canvas_offset.y + fitted_size.y <= canvas_size.y + 0.01,
			"Menu and pause canvases should fit supported viewport sizes."
		)

	var sword_config := load("res://resources/weapons/dungeon_edge.tres") as WeaponConfig
	var crossbow_config := load("res://resources/weapons/warden_crossbow.tres") as WeaponConfig
	_expect(sword_config != null and sword_config.projectile_scene == null, "The sword configuration should load.")
	_expect(crossbow_config != null and crossbow_config.projectile_scene != null, "The crossbow projectile configuration should load.")
	_expect(
		audio_manager._music_theme == &"menu"
		and audio_manager._music_player.stream == audio_manager._music_stream,
		"The title should select its own music theme."
	)
	var distinct_music_streams: Dictionary = {}
	for theme_name in ["menu", "exploration", "combat", "boss", "death", "victory"]:
		audio_manager.set_music_theme(theme_name)
		distinct_music_streams[audio_manager._music_player.stream.get_instance_id()] = true
		_expect(
			audio_manager._music_theme == StringName(theme_name)
			and audio_manager._music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"Every game-flow music theme should play as a loop: %s." % theme_name
		)
	_expect(
		distinct_music_streams.size() == 6,
		"Menu, exploration, combat, boss, death, and victory should use distinct music streams."
	)
	audio_manager.set_music_theme("menu")
	_expect(audio_manager._sfx_players.size() == GameAudioManager.SFX_CHANNEL_COUNT, "The sound pool should initialize.")
	for effect_name in [
		"attack",
		"melee_impact",
		"crossbow_fire",
		"projectile_impact",
		"enemy_hit",
		"enemy_down",
		"healing",
		"door_lock",
		"door_unlock",
		"weapon_switch",
		"boss_entrance",
		"boss_attack",
		"upgrade_purchase",
	]:
		_expect(
			audio_manager._effects.has(effect_name),
			"Audio should provide the %s gameplay sound cue." % effect_name
		)
	_expect(InputMap.has_action("pause"), "Pause should be a named InputMap action.")
	_expect(InputMap.has_action("switch_weapon"), "Weapon switching should be a named InputMap action.")

	var floor_definitions := Level01Controller.FLOOR_DEFINITIONS
	var combat_balance_probe := FacilityEnemy.new()
	combat_balance_probe.configure_for_floor(1)
	_expect(combat_balance_probe.max_health == 42, "Floor one enemy health should match the baseline tuning.")
	_expect(combat_balance_probe.attack_damage == 8, "Floor one enemy damage should match the baseline tuning.")
	_expect(
		is_equal_approx(combat_balance_probe.movement_speed, 128.8),
		"Melee enemies should pursue at 1.4 times their archetype speed."
	)
	combat_balance_probe.configure_for_floor(10)
	_expect(combat_balance_probe.max_health == 70, "Floor ten enemy health should rise gradually to the tested cap.")
	_expect(combat_balance_probe.attack_damage == 12, "Floor ten enemy damage should stay near one-eighth of base player health.")
	_expect(
		is_equal_approx(combat_balance_probe.movement_speed, 166.6),
		"Melee enemy speed should rise with floor depth while retaining the mobility multiplier."
	)
	var room_scaling_player := RunnerController.new()
	room_scaling_player.max_health = 200
	room_scaling_player.attack_damage = 20
	room_scaling_player.movement_speed = 250.0
	combat_balance_probe.configure_player(room_scaling_player)
	combat_balance_probe.configure_for_floor(1, 10)
	_expect(
		combat_balance_probe.max_health == 62
		and combat_balance_probe.attack_damage == 10
		and is_equal_approx(combat_balance_probe.movement_speed, 153.8),
		"Each entered room should add 1% of current player health, damage, and speed per room to mob stats."
	)
	room_scaling_player.free()
	combat_balance_probe.free()
	_expect(floor_definitions.size() == 10, "The dungeon should define ten floors.")
	var total_rooms := 0
	var previous_room_count := 0
	for floor_index in floor_definitions.size():
		var definition := floor_definitions[floor_index] as FloorDefinition
		_expect(definition.floor_number == floor_index + 1, "Floor definitions should be ordered.")
		_expect(definition.room_count >= previous_room_count, "Room counts should not decrease on deeper floors.")
		_expect(definition.base_enemy_count >= 1, "Each floor should have combat encounters.")
		_expect(
			definition.healing_room_index >= 0
			and definition.healing_room_index < definition.room_count
			and (definition.boss_id == &"" or definition.healing_room_index < definition.room_count - 1),
			"Every floor should place one fixed healing pickup outside its boss arena."
		)
		previous_room_count = definition.room_count
		total_rooms += definition.room_count
	_expect(total_rooms == 38, "The ten floors should contain the configured 38 deterministic rooms.")
	_expect((floor_definitions[3] as FloorDefinition).floor_name == "Upper Dungeon", "Floors one through four should use the upper theme.")
	_expect((floor_definitions[4] as FloorDefinition).floor_name == "Deep Dungeon", "Floor five should begin the deep theme.")
	_expect((floor_definitions[4] as FloorDefinition).boss_id == &"", "Floor five should be a regular floor, with previous selves placed only at saved death locations.")
	_expect((floor_definitions[9] as FloorDefinition).boss_id == &"hollow_warden", "Floor ten should be configured for its final boss.")

	_expect(manager.get_player_stats() == {
		"max_health": 100,
		"attack_damage": 10,
		"move_speed": 200.0,
		"sword_damage_multiplier": 1.0,
		"crossbow_damage_multiplier": 1.0,
		"mob_stat_multiplier": 1.0,
	}, "A fresh save should use its default starting stats.")

	_find_button(main, "ENTER THE DUNGEON").emit_signal("pressed")
	await process_frame
	var stage := main.get("_stage") as Level01Controller
	var tutorial_counter := tutorial_card.get_node("StepCounter") as Label
	var tutorial_focus := tutorial_panel.get_node("FocusFrame") as Panel
	var tutorial_next := tutorial_card.get_node("StartRun") as Button
	_expect(
		tutorial_panel.visible
		and stage != null
		and stage.visible
		and paused
		and not manager.run_active
		and manager.attempts == 0,
		"Entering the dungeon should show the tutorial over a frozen live room without starting an attempt."
	)
	_expect(
		tutorial_counter.text == "01 / 07"
		and tutorial_focus.visible
		and tutorial_panel.get_node("PointerLine") is Line2D,
		"The tutorial should begin with a highlighted gameplay target and a step counter."
	)
	var tutorial_player := stage.get_node("Player") as RunnerController
	var tutorial_player_position := tutorial_player.global_position
	tutorial_player.velocity = Vector2(220.0, 0.0)
	await physics_frame
	await physics_frame
	_expect(
		tutorial_player.global_position.is_equal_approx(tutorial_player_position),
		"The dungeon player and world should remain frozen while the tutorial is open."
	)
	tutorial_player.velocity = Vector2.ZERO
	var tutorial_total_steps := int(tutorial_counter.text.get_slice("/", 1).strip_edges())
	var prior_focus_position := tutorial_focus.position
	for step_number in range(2, tutorial_total_steps + 1):
		tutorial_next.emit_signal("pressed")
		await process_frame
		_expect(
			tutorial_counter.text == "%02d / %02d" % [step_number, tutorial_total_steps]
			and tutorial_focus.visible
			and not tutorial_focus.position.is_equal_approx(prior_focus_position),
			"Tutorial Next should move its highlight to step %d." % step_number
		)
		if step_number == 6:
			_expect(
				(tutorial_card.get_node("TargetTitle") as Label).text.begins_with("ENEMY: ")
				and not (tutorial_card.get_node("Description") as Label).text.is_empty(),
				"The mob tutorial should identify the highlighted enemy and explain its attack style."
			)
		prior_focus_position = tutorial_focus.position
	_expect(
		(tutorial_card.get_node("TargetTitle") as Label).text == "CLEAR ROOMS & DESCEND"
		and tutorial_next.text == "START RUN",
		"The final tutorial step should explain the exit and offer to begin the run."
	)
	tutorial_next.emit_signal("pressed")
	await process_frame
	_expect(stage != null, "Starting a run should load the dungeon.")
	_expect(
		not paused
		and manager.entry_tutorial_completed,
		"Completing the mandatory tutorial should save its state for this profile and resume the run."
	)
	_expect(audio_manager._music_theme == &"combat", "Starting a run should switch to dungeon combat music.")
	_expect(stage == saved_level and stage.visible, "Starting a run should use the visible level already saved under Main.")
	_expect((stage.get_node("HUD") as CanvasLayer).visible, "Starting a run should show the gameplay HUD.")
	var tutorial_profile_reload := PersistentRunManager.new()
	root.add_child(tutorial_profile_reload)
	await process_frame
	_expect(
		tutorial_profile_reload.select_profile("New Runner")
		and tutorial_profile_reload.entry_tutorial_completed
		and tutorial_profile_reload.select_profile("Survivor")
		and not tutorial_profile_reload.entry_tutorial_completed,
		"Tutorial completion should persist per profile without affecting other characters."
	)
	tutorial_profile_reload.queue_free()
	await process_frame
	if stage == null:
		quit(1)
		return

	_expect(stage.get_current_floor_number() == 1, "A new run should begin on floor one.")
	_expect(stage.get_current_room_number() == 1, "A new run should begin in the first room.")
	_expect(not stage.is_processing(), "Exit monitoring should stay idle during active combat.")
	var camera := stage.get_node("Player/Camera2D") as Camera2D
	_expect(
		camera.enabled
		and camera.limit_left < 0
		and camera.limit_top < 0
		and camera.limit_right > 1280
		and camera.limit_bottom > 720,
		"The gameplay camera should follow the player without being clamped to one room."
	)
	var touch_pause := stage.find_child("PauseButton", true, false) as Button
	_expect(touch_pause != null, "The HUD should have an on-screen pause button.")
	touch_pause.emit_signal("pressed")
	_expect(paused and audio_manager.gameplay_paused, "Pause should stop both gameplay and gameplay audio.")
	var paused_player := stage.get_node("Player") as RunnerController
	var paused_position := paused_player.global_position
	paused_player.velocity = Vector2(220.0, 0.0)
	await physics_frame
	await physics_frame
	_expect(
		paused_player.global_position.is_equal_approx(paused_position),
		"Pausing the run should stop player physics and movement, not only show the pause menu."
	)
	paused_player.velocity = Vector2.ZERO
	main.call("_show_settings", true)
	var pause_root := main.get("_pause_root") as Control
	var pause_music_slider := pause_root.find_child("MusicVolume", true, false) as HSlider
	_expect(pause_music_slider != null, "The pause menu should offer Settings.")
	if pause_music_slider != null:
		pause_music_slider.value = 0.55
		main.call("_leave_pause_settings")
		_expect(is_equal_approx(audio_manager.music_volume, 0.55), "Pause settings should update music volume.")
	_expect(_find_button(pause_root, "RETURN TO MAIN MENU") != null, "The pause menu should offer a return action.")
	main.call("_show_abandon_confirmation")
	await process_frame
	var abandon_confirmation := pause_root.get_node_or_null("AbandonConfirmation") as Control
	var abandon_description := abandon_confirmation.find_child("AbandonDescription", true, false) as Label if abandon_confirmation != null else null
	var abandon_content := abandon_description.get_parent() as Control if abandon_description != null else null
	var abandon_panel := abandon_content.get_parent() as PanelContainer if abandon_content != null else null
	_expect(abandon_confirmation != null, "Returning to the main menu should require confirmation.")
	var abandon_description_fits := abandon_panel != null and abandon_description != null and abandon_content != null
	if abandon_description_fits:
		abandon_description_fits = (
			abandon_description.get_line_count() >= 2
			and abandon_description.position.x >= 0.0
			and abandon_description.position.y >= 0.0
			and abandon_description.position.x + abandon_description.size.x <= abandon_content.size.x
			and abandon_description.position.y + abandon_description.size.y <= abandon_content.size.y
		)
	_expect(
		abandon_description_fits,
		"Abandon-dialog copy should wrap and remain inside its framed panel (lines=%d, rect=%s, parent=%s)." % [
			abandon_description.get_line_count() if abandon_description != null else -1,
			abandon_description.get_rect() if abandon_description != null else Rect2(),
			abandon_content.size if abandon_content != null else Vector2.ZERO,
		]
	)
	main.call("_show_pause_menu")
	main.call("_toggle_pause")
	_expect(not paused and not audio_manager.gameplay_paused, "Resume should restore gameplay and audio.")
	manager.set_audio_volumes(1.0, 1.0)
	manager.save_settings()
	audio_manager.set_music_volume(1.0)
	audio_manager.set_sfx_volume(1.0)

	var player := stage.get_node("Player") as RunnerController
	var player_sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var touch_controls := stage.get_node("HUD/UI/Screen/TouchControls") as TouchControls
	var hud := stage.get_node("HUD") as CanvasLayer
	_expect(
		touch_controls.get_interact_icon() == null,
		"The USE button should remain an empty slot when the player has no potions."
	)
	var zone_status := hud.find_child("ZoneStatus", true, false) as Label
	var floor_transition := hud.get_node("UI/Screen").get_node_or_null("FloorTransition") as Control
	var transition_portal := floor_transition.get_node_or_null("PortalEffect") as TextureRect if floor_transition != null else null
	_expect(
		floor_transition != null
		and transition_portal != null
		and transition_portal.texture.resource_path.contains("Asset 42"),
		"Floor transitions should use the supplied transition artwork in the authored HUD subtree."
	)
	if floor_transition != null:
		var transition_test_room := stage.get_current_room()
		var transition_test_enemies := _get_active_combatants(transition_test_room.get_node("Enemies"))
		for enemy_node in transition_test_enemies:
			(enemy_node as FacilityEnemy).set_physics_process(false)
		hud.call("show_floor_transition", 2, "TEST DESCENT")
		await create_timer(1.7).timeout
		_expect(
			floor_transition.visible
			and (floor_transition.get_node("FloorTitle") as Label).text == "FLOOR 02  /  TEST DESCENT"
			and (floor_transition.get_node("FloorSubtitle") as Label).visible
			and (floor_transition.get_node("TopCurtain") as ColorRect).position.y == 0.0,
			"The floor transition should animate its authored title, portal, and curtains before changing rooms."
		)
		hud.call("hide_floor_transition")
		await create_timer(0.65).timeout
		_expect(not floor_transition.visible, "The animated floor transition should reveal the new room afterward.")
		for enemy_node in transition_test_enemies:
			(enemy_node as FacilityEnemy).set_physics_process(true)
	var idle_frame := player_sprite.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
	var weapon_icon := hud.find_child("WeaponIcon", true, false) as TextureRect
	var weapon_name := hud.find_child("WeaponName", true, false) as Label
	var weapon_name_backdrop := hud.find_child("WeaponNameBackdrop", true, false) as ColorRect
	_expect(
		idle_frame != null and idle_frame.atlas.resource_path.begins_with("res://ASSETS/PLAYER ASSETS/"),
		"Player animations should use the supplied Assets artwork."
	)
	_expect(
		weapon_icon.texture is AtlasTexture
		and (weapon_icon.texture as AtlasTexture).atlas.resource_path.contains("Asset 16"),
		"The HUD should display the supplied icon for the equipped weapon."
	)
	_expect(
		weapon_name != null
		and weapon_name_backdrop != null
		and weapon_name.text == "DUNGEON EDGE"
		and weapon_name.position.x > weapon_name_backdrop.position.x
		and weapon_name_backdrop.position.x <= 64.0
		and weapon_name.size.x >= 260.0,
		"The weapon row should draw one dynamic name over the baked artwork, without duplicating it."
	)
	_expect(
		(player.get_node("WeaponPivot/SwordSprite") as Sprite2D).texture.resource_path.begins_with("res://ASSETS/WEAPON ASSETS/"),
		"The equipped weapon should use the supplied Assets artwork."
	)
	var layout_sizes := [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(1600.0, 900.0), Vector2(1024.0, 768.0)]
	for layout_size in layout_sizes:
		var centers: Dictionary = touch_controls.get_action_centers_for_size(layout_size)
		for control_center in centers.values():
			var point: Vector2 = control_center
			_expect(
				point.x >= 0.0 and point.x <= layout_size.x and point.y >= 0.0 and point.y <= layout_size.y,
				"Touch controls should remain on-screen at supported viewport sizes."
			)
	_expect(
		hud._health_segments.size() == 10 and hud._health_segment_width > 0.0,
		"The Top HUD health bar should use its ten responsive segments."
	)
	var joystick_center: Vector2 = touch_controls.get_action_centers()["joystick"]
	touch_controls.set_keyboard_movement(Vector2.RIGHT)
	var keyboard_knob_position: Vector2 = touch_controls.call("_get_joystick_knob_position")
	_expect(
		is_equal_approx(
			keyboard_knob_position.x - joystick_center.x,
			TouchControls.JOYSTICK_RADIUS * touch_controls._layout_scale()
		)
		and is_equal_approx(keyboard_knob_position.y, joystick_center.y),
		"The virtual joystick knob should follow keyboard movement without changing the movement input."
	)
	touch_controls.set_keyboard_movement(Vector2.ZERO)
	touch_controls.call("_handle_press", joystick_center + Vector2(50.0, 0.0), -3)
	_expect(touch_controls.get_movement_vector().x > 0.7, "The lower-left virtual joystick should return directional movement.")
	touch_controls.call("_handle_release", -3)
	_expect(touch_controls.get_movement_vector() == Vector2.ZERO, "Releasing the virtual joystick should clear movement.")
	player.request_dodge()
	_expect(
		is_equal_approx(player._dodge_cooldown, 3.0)
		and is_equal_approx(touch_controls._dash_cooldown_remaining, 3.0),
		"Using dash should start a 3-second cooldown and show it on the DASH button."
	)
	player._dodge_time = 0.0
	player._action_animation = &""
	player.set_controls_enabled(false)
	player._physics_process(0.5)
	player.set_controls_enabled(true)
	player._update_facing_pose(0.0)
	player._update_equipped_sprites()
	player._update_sprite_animation()
	_expect(
		is_equal_approx(player._dodge_cooldown, 2.5)
		and is_equal_approx(touch_controls._dash_cooldown_remaining, 2.5),
		"The DASH button's cooldown display should count down with the character's timer."
	)
	player._dodge_cooldown = 0.1
	player.set_controls_enabled(false)
	player._physics_process(0.1)
	player.set_controls_enabled(true)
	_expect(
		is_zero_approx(player._dodge_cooldown)
		and is_zero_approx(touch_controls._dash_cooldown_remaining),
		"The DASH cooldown display should clear when the cooldown expires."
	)
	player._invulnerability_time = 0.0
	player._update_dash_cooldown_indicator()
	_expect(player.get_current_weapon_id() == &"dungeon_edge", "The sword should be equipped at run start.")
	_expect((player.get_node("WeaponPivot/SwordSprite") as Sprite2D).visible, "The equipped sword should be visible.")
	_expect(not (player.get_node("WeaponPivot/CrossbowSprite") as Sprite2D).visible, "The unequipped crossbow should be hidden.")
	var sword_sprite := player.get_node("WeaponPivot/SwordSprite") as Sprite2D
	var weapon_pivot := player.get_node("WeaponPivot") as Node2D
	_expect(
		sword_sprite.texture.resource_path.contains("Asset 10")
		and sword_sprite.offset.y > 0.0
		and is_equal_approx(sword_sprite.scale.x, 0.034)
		and weapon_pivot.get_parent() == player
		and absf(weapon_pivot.position.y) < 24.0
		and sword_sprite.position == Vector2.ZERO,
		"The supplied sword should pivot from a hand anchor that follows the player's direction."
	)
	var directional_sprite := player.get_node("DirectionalSprite") as AnimatedSprite2D
	_expect(
		is_equal_approx(player_sprite.scale.x, 0.13)
		and is_equal_approx(directional_sprite.scale.x, 1.15)
		and directional_sprite.sprite_frames.get_frame_count("walk_left") == 8
		and directional_sprite.sprite_frames.get_frame_count("walk_up") == 8
		and directional_sprite.sprite_frames.get_frame_count("ranged_attack_right") == 6,
		"The larger player should have eight-frame movement and directional combat animations."
	)
	player._facing = Vector2.LEFT
	player.velocity = Vector2.ZERO
	player.call("_update_facing_pose", 1.0)
	player.call("_update_equipped_sprites")
	_expect(
		is_zero_approx(player_sprite.rotation)
		and not player_sprite.visible
		and directional_sprite.visible
		and directional_sprite.animation == "idle_left"
		and weapon_pivot.position.x < 0.0,
		"The left idle pose should use its animated left-facing art without rotating the character."
	)
	player._facing = Vector2.RIGHT
	player.call("_update_facing_pose", 1.0)
	player.call("_update_equipped_sprites")
	_expect(
		directional_sprite.animation == "idle_right"
		and weapon_pivot.position.x > 0.0,
		"Rightward movement should select the right-facing animation and hand position."
	)
	player._facing = Vector2.DOWN
	player.call("_update_facing_pose", 1.0)
	player.call("_update_equipped_sprites")
	player._facing = Vector2.UP
	player.call("_update_facing_pose", 1.0)
	_expect(
		directional_sprite.visible
		and directional_sprite.animation == "idle_up"
		and is_zero_approx(player_sprite.rotation),
		"Upward movement should show the animated back-facing pose without rotating the sprite."
	)
	player._facing = Vector2.DOWN
	player.call("_update_facing_pose", 1.0)
	player.call("_update_equipped_sprites")
	_expect(player_sprite.visible and not directional_sprite.visible, "Downward movement should restore the high-resolution front-facing sprites.")
	_expect(player.get_node_or_null("MeleeHitbox") is Area2D, "The player should have a dedicated melee hitbox.")
	var damage_flash := player.get_node_or_null("DamageFlash") as Sprite2D
	_expect(
		damage_flash != null and damage_flash.texture.resource_path.contains("Asset 37"),
		"The player should use the supplied damage flash effect."
	)
	_expect(player_sprite.sprite_frames.get_frame_count("idle") == 4, "The idle sheet should have four frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("walk") == 8, "The walk sheet should have eight frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("melee_attack") == 6, "The melee sheet should have six frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("ranged_attack") == 6, "The ranged sheet should have six frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("hurt") == 3, "The hurt sheet should have three frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("death") == 6, "The death sheet should have six frames.")
	_expect(player_sprite.sprite_frames.get_frame_count("dodge") == 4, "The dodge sheet should have four frames.")
	player.velocity = Vector2.RIGHT * player.movement_speed * 0.5
	player.call("_update_sprite_animation")
	_expect(
		player_sprite.animation == "walk" and is_equal_approx(player_sprite.speed_scale, 0.55),
		"Player walk-cycle playback should slow smoothly with movement speed."
	)
	player.velocity = Vector2.ZERO
	player.call("_update_sprite_animation")

	var room := stage.get_current_room()
	var enemies := room.get_node("Enemies")
	var active_enemies := _get_active_combatants(enemies)
	var rendering_enemy := active_enemies[0] as FacilityEnemy
	var rendering_animation := rendering_enemy.get_node("Animation") as AnimatedSprite2D
	_expect(
		rendering_animation.visible
		and rendering_animation.sprite_frames.get_frame_count("idle") > 0
		and rendering_animation.z_as_relative
		and rendering_animation.z_index == 1
		and rendering_enemy.z_index == 2,
		"Spawned monsters should have visible animated art above room props."
	)
	_expect(
		rendering_animation.scale.x >= 0.46,
		"Monster animation sprites should be large enough to read at the gameplay camera's native zoom."
	)
	var camera_start := camera.get_screen_center_position()
	for enemy_node in active_enemies:
		var camera_test_enemy := enemy_node as FacilityEnemy
		if camera_test_enemy != null:
			camera_test_enemy.target = null
	player.global_position += Vector2(0.0, -120.0)
	for _frame in 30:
		await process_frame
	var camera_end := camera.get_screen_center_position()
	_expect(
		camera_end.y < camera_start.y - 60.0,
		"The camera should move upward with the player inside a room (start %.1f, end %.1f)." % [
			camera_start.y,
			camera_end.y,
		]
	)
	player.global_position = room.to_global(Vector2(640.0, 610.0))
	camera.reset_smoothing()
	for enemy_node in active_enemies:
		var camera_test_enemy := enemy_node as FacilityEnemy
		if camera_test_enemy != null:
			camera_test_enemy.target = player
	var exit_door := room.get_node_or_null("WorldGeometry/ExitDoor") as Sprite2D
	_expect(room.get_layout_index() == 0, "The first deterministic room should use the open layout.")
	_expect(room.get_obstacle_count() == 0, "The open room layout should not add obstacles.")
	_expect(
		exit_door != null
		and (exit_door.texture as AtlasTexture).atlas.resource_path.contains("Asset 31")
		and (exit_door.texture as AtlasTexture).region == DungeonRoom.LOCKED_DOOR_REGION,
		"Normal rooms should show the supplied locked dungeon door artwork while combat continues."
	)
	_expect(
		exit_door != null and exit_door.position.y > DungeonRoom.EXIT_Y,
		"The doorway should remain visible beneath the landscape HUD while aligning with its exit trigger."
	)
	_expect(
		room.get_node_or_null("WorldGeometry/WallTorch1") is Sprite2D
		and room.get_node_or_null("WorldGeometry/WallTorch2") is Sprite2D,
		"Normal rooms should decorate their walls with the supplied torch artwork."
	)
	var missing_top_wall := room.get_node_or_null("WorldGeometry/SuppliedWalls/WallTop04") as Sprite2D
	_expect(
		missing_top_wall != null
		and missing_top_wall.visible
		and missing_top_wall.position.is_equal_approx(Vector2(497.0, 45.0))
		and (missing_top_wall.texture as AtlasTexture).atlas.resource_path.contains("Asset 29"),
		"The top wall should have no unplanned gap left of its centered exit."
	)
	active_enemies = _get_active_combatants(enemies)
	_expect(active_enemies.size() == 2, "The first room should spawn its configured enemies.")
	_expect(not room.is_exit_unlocked(), "A room exit should stay locked while enemies remain.")
	var first_enemy := active_enemies[0] as FacilityEnemy
	var second_enemy := active_enemies[1] as FacilityEnemy
	_expect(
		(first_enemy.collision_mask & 2) != 0 and (second_enemy.collision_mask & 2) != 0,
		"Enemies should collide with each other instead of collapsing into one pile."
	)
	var enemy_animation := first_enemy.get_node("Animation") as AnimatedSprite2D
	var creature_animation := second_enemy.get_node("Animation") as AnimatedSprite2D
	var enemy_idle_frame := enemy_animation.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
	var creature_idle_frame := creature_animation.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
	_expect(
		first_enemy.archetype.archetype_id == &"skeleton"
		and second_enemy.archetype.archetype_id == &"dungeon_creature",
		"Room one should place its melee enemy archetypes in a stable authored order."
	)
	_expect(
		enemy_animation.sprite_frames.has_animation("idle")
		and enemy_animation.sprite_frames.has_animation("walk")
		and enemy_animation.sprite_frames.has_animation("attack")
		and enemy_animation.sprite_frames.has_animation("hurt"),
		"Ordinary enemies should animate their idle, movement, attack, and hurt states."
	)
	_expect(
		enemy_animation.sprite_frames.has_animation("death")
		and enemy_animation.sprite_frames.get_animation_speed("walk") > 0.0,
		"Ordinary enemies should provide an animated death and configurable animation speed."
	)
	_expect(
		(first_enemy.get_node("Art") as Sprite2D).texture.resource_path.begins_with("res://ASSETS/ORDINARY ENEMY ASSETS/"),
		"Ordinary enemies should retain their supplied static character artwork as a fallback."
	)
	_expect(
		enemy_idle_frame != null and enemy_idle_frame.atlas.resource_path.contains("Asset 18"),
		"Ordinary enemy animations should use the supplied skeleton animation sheet."
	)
	_expect(
		creature_idle_frame != null and creature_idle_frame.atlas.resource_path.contains("Asset 20"),
		"Dungeon creatures should animate with their own supplied sprite sheet."
	)
	first_enemy.take_damage(1)
	_expect(enemy_animation.animation == "hurt", "Enemy damage should play the supplied hurt animation.")
	first_enemy._hit_flash = 0.0
	first_enemy._attack_cooldown = 0.0
	first_enemy._begin_attack_telegraph(false)
	_expect(
		is_equal_approx(first_enemy._windup_time, 0.34) and enemy_animation.animation == "attack",
		"An ordinary enemy telegraph should keep its readable attack animation active."
	)
	first_enemy._windup_time = 0.0
	first_enemy._attack_cooldown = 0.7
	player.global_position = room.to_global(first_enemy.position + Vector2(0, -42))
	var enemy_health := first_enemy.health
	var attack_center: Vector2 = touch_controls.get_action_centers()["attack"]
	touch_controls.call("_handle_press", attack_center, -3)
	touch_controls.call("_handle_release", -3)
	var melee_area := player.get_node("MeleeHitbox") as Area2D
	var melee_shape := (melee_area.get_node("CollisionShape2D") as CollisionShape2D).shape as CapsuleShape2D
	_expect(
		melee_shape != null
		and is_equal_approx(melee_shape.radius, sword_config.hitbox_radius)
		and is_equal_approx(melee_shape.height, sword_config.hitbox_length)
		and melee_area.position.is_equal_approx(Vector2.DOWN * sword_config.hitbox_offset)
		and is_zero_approx(melee_area.rotation),
		"The melee hit shape should be resized and aimed from the equipped weapon config for each swing."
	)
	_expect(player_sprite.animation == "melee_attack", "The sword attack should use its matching animation.")
	_expect(
		not sword_sprite.visible,
		"The separate equipped sword should hide when the supplied melee animation already depicts its swing."
	)
	_expect((player.get_node("SlashEffect") as Sprite2D).visible, "A sword swing should show its slash effect.")
	_expect(first_enemy.health == enemy_health, "The sword should not damage before its active attack frames.")
	for _frame in 3:
		await physics_frame
	_expect(first_enemy.health == enemy_health, "The sword should remain harmless during windup.")
	for _frame in 15:
		await physics_frame
	_expect(first_enemy.health == enemy_health - player.attack_damage, "The active sword hitbox should damage an enemy.")
	_expect(not (player.get_node("MeleeHitbox") as Area2D).monitoring, "The sword hitbox should close after the attack window.")

	for _frame in 10:
		await physics_frame
	var first_enemy_position := first_enemy.global_position
	var second_enemy_position := second_enemy.global_position
	var first_enemy_mask := first_enemy.collision_mask
	var second_enemy_mask := second_enemy.collision_mask
	var first_enemy_health := first_enemy.health
	var second_enemy_health := second_enemy.health
	first_enemy.set_physics_process(false)
	second_enemy.set_physics_process(false)
	first_enemy.collision_mask = 0
	second_enemy.collision_mask = 0
	second_enemy.global_position = first_enemy_position + Vector2(0.0, 20.0)
	player.global_position = first_enemy_position + Vector2(0.0, -42.0)
	player._facing = Vector2.DOWN
	player.request_attack()
	for _frame in 18:
		await physics_frame
	_expect(
		first_enemy.health == first_enemy_health - player.attack_damage
		and second_enemy.health == second_enemy_health - player.attack_damage,
		"One active sword swing should hit each distinct enemy overlapped by its hitbox."
	)
	first_enemy.set_physics_process(true)
	second_enemy.set_physics_process(true)
	first_enemy.collision_mask = first_enemy_mask
	second_enemy.collision_mask = second_enemy_mask
	first_enemy.global_position = first_enemy_position
	second_enemy.global_position = second_enemy_position

	player.global_position = room.to_global(Vector2(640.0, 76.0))
	await physics_frame
	_expect(stage.get_current_room_number() == 1, "An uncleared room must not allow its exit to advance.")
	player.global_position = room.to_global(Vector2(640.0, 610.0))
	touch_controls.call("_handle_press", touch_controls.call("_weapon_switch_center"), -2)
	_expect(player.get_current_weapon_id() == &"warden_crossbow", "The touch swap control should equip the crossbow.")
	_expect((player.get_node("WeaponPivot/CrossbowSprite") as Sprite2D).visible, "The equipped crossbow should be visible.")
	var crossbow_sprite := player.get_node("WeaponPivot/CrossbowSprite") as Sprite2D
	_expect(
		crossbow_sprite.texture.resource_path.contains("Asset 13")
		and crossbow_sprite.offset.y < 0.0
		and is_equal_approx(crossbow_sprite.rotation, Vector2.DOWN.angle() + PI * 0.5),
		"The supplied crossbow should be gripped at its stock and aim in the player's facing direction."
	)
	_expect(not (player.get_node("WeaponPivot/SwordSprite") as Sprite2D).visible, "Switching should hide the sword.")
	_expect(touch_controls._attack_label == "BOLT", "The touch attack button should show the equipped weapon.")
	_expect(_contains_label(stage, "WARDEN CROSSBOW"), "The HUD should show the selected weapon.")

	player.global_position = room.to_global(first_enemy.position + Vector2(0, -150))
	first_enemy.set_physics_process(false)
	second_enemy.set_physics_process(false)
	enemy_health = first_enemy.health
	var inactive_enemy := room.get_node("Enemies/Enemy06") as FacilityEnemy
	player.set_locked_target(inactive_enemy)
	_expect(
		player._locked_target != inactive_enemy,
		"Auto-aim should reject invisible Scene Dock enemy placeholders."
	)
	var second_enemy_saved_position := second_enemy.global_position
	player.set_locked_target(second_enemy)
	second_enemy.global_position = player.global_position + Vector2(crossbow_config.projectile_range + 80.0, 0.0)
	var in_range_target := player._get_ranged_target(crossbow_config.projectile_range)
	_expect(
		in_range_target != second_enemy and player._locked_target == null,
		"An out-of-range lock should be cleared so the bolt can retarget a visible enemy in range."
	)
	second_enemy.global_position = second_enemy_saved_position
	player.request_attack()
	_expect(player_sprite.animation == "ranged_attack", "The crossbow shot should use its matching animation.")
	var player_reload_indicator := player.get_node("ReloadIndicator") as ProgressBar
	_expect(
		is_equal_approx(float(player._weapon_cooldowns[&"warden_crossbow"]), 1.5)
		and player_reload_indicator.visible
		and is_equal_approx(player_reload_indicator.value, 100.0),
		"Firing the player's crossbow should start its 1.5-second reload indicator beside the character."
	)
	_expect(first_enemy.health == enemy_health, "A bolt should not damage before colliding.")
	var projectile := stage.get_node_or_null("CrossbowProjectile") as CrossbowProjectile
	_expect(projectile != null, "A crossbow attack should instantiate its independent projectile scene.")
	_expect(
		projectile != null
		and projectile.direction.dot((first_enemy.global_position - player.global_position).normalized()) > 0.99,
		"Crossbow bolts should automatically aim at the nearest enemy when no target is locked."
	)
	var projectile_visuals_ok := (
		projectile != null
		and is_equal_approx(projectile._projectile_sprite.scale.x, 0.06)
		and projectile._glow_sprite.visible
		and projectile._trail.width >= 10.0
	)
	_expect(
		projectile_visuals_ok,
		"Player bolts should have a larger glowing arrowhead and a clearly visible trail (scale %.3f, glow %s, trail %.1f)."
		% [
			projectile._projectile_sprite.scale.x if projectile != null else -1.0,
			projectile._glow_sprite.visible if projectile != null else false,
			projectile._trail.width if projectile != null else -1.0,
		]
	)
	if projectile != null:
		for _frame in 3:
			await physics_frame
		_expect(
			projectile._trail.get_point_count() >= 3 and projectile._trail.default_color == Color("8cecff"),
			"Crossbow bolts should leave a colored trail that follows their actual flight path."
		)
	var camera_transform := (player.get_node("Camera2D") as Camera2D).get_canvas_transform()
	touch_controls.call("_handle_press", camera_transform * second_enemy.global_position, -30)
	_expect(
		player._locked_target == second_enemy and second_enemy.get_node_or_null("TargetLockIndicator") is Line2D,
		"Tapping an enemy should lock onto it and show a target indicator."
	)
	touch_controls.call("_handle_release", -30)
	touch_controls.call("_handle_press", camera_transform * first_enemy.global_position, -31)
	_expect(player._locked_target == first_enemy, "Tapping a different enemy should switch the ranged lock-on target.")
	touch_controls.call("_handle_release", -31)
	for _frame in 15:
		await physics_frame
	_expect(first_enemy.health == enemy_health - player.attack_damage, "The bolt should damage its target on collision.")
	_expect(
		player_reload_indicator.visible and player_reload_indicator.value < 100.0,
		"The player's crossbow reload bar should count down after the shot."
	)
	_expect(is_instance_valid(projectile) and projectile._impact_sprite.visible, "A collision should display the projectile impact.")
	_expect(
		projectile != null
		and not projectile._trail.visible
		and projectile._impact_sprite.scale.x > 0.035,
		"Projectile impacts should replace the trail with an expanding hit effect."
	)
	first_enemy.set_physics_process(true)
	second_enemy.set_physics_process(true)
	touch_controls.call("_handle_release", -2)
	touch_controls.call("_handle_press", touch_controls.call("_weapon_switch_center"), -2)
	_expect(player.get_current_weapon_id() == &"dungeon_edge", "The touch control should switch back to the sword.")
	_expect(
		float(player._weapon_cooldowns[&"warden_crossbow"]) > 0.0
		and player_reload_indicator.visible,
		"The player's crossbow reload should remain visible while the sword is available."
	)
	player.request_attack()
	_expect(player_sprite.animation == "melee_attack", "The sword should remain usable while the crossbow cools down.")
	touch_controls.call("_handle_release", -2)
	for _frame in 15:
		await physics_frame
	_expect(not is_instance_valid(projectile), "The bolt should clean itself up after impact.")
	_expect(touch_controls._pressed_action.is_empty(), "Releasing the swap control should clear its pressed state.")
	_expect(touch_controls._attack_label == "STRIKE", "The attack button should update after switching back.")

	var healing_pickup := room.get_node_or_null("HealingPickup") as HealingPickup
	_expect(healing_pickup != null, "The first floor's authored room should contain its healing pickup.")
	if healing_pickup != null:
		var pickup_art := healing_pickup.get_node("Art") as AnimatedSprite2D
		var pickup_frame := pickup_art.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
		_expect(
			pickup_frame != null and pickup_frame.atlas.resource_path.contains("Asset 35"),
			"Healing pickups should animate from the supplied healing sprite sheet."
		)
		_expect(
			pickup_art.visible and pickup_art.z_index > 0 and pickup_art.scale.x >= 0.06,
			"The animated potion should render clearly above the floor instead of showing a placeholder marker."
		)
		player.global_position = healing_pickup.global_position
		for _frame in 2:
			await physics_frame
		await process_frame
		_expect(
			player.potion_count == 1
			and player.health == player.max_health
			and room.get_node_or_null("HealingPickup") == null,
			"Picking up a potion at full health should add it to inventory without consuming its healing effect."
		)
		_expect(
			zone_status.visible and zone_status.text == "POTION ACQUIRED  /  USE ×1",
			"Picking up a potion should briefly show its pickup instruction."
		)
		hud.call("show_zone_message", "POTION ACQUIRED  /  USE ×1")
		hud.call("_process", 1.99)
		_expect(zone_status.visible, "A potion notice should remain visible until its two-second duration ends.")
		hud.call("_process", 0.02)
		_expect(not zone_status.visible, "A potion pickup notice should disappear after two seconds.")
		player.global_position = room.to_global(Vector2(640.0, 610.0))
		for _frame in 2:
			await physics_frame
		player._invulnerability_time = 0.0
		player.take_damage(40)
		_expect(
			damage_flash != null and damage_flash.visible,
			"Taking damage should show the imported player impact effect."
		)
		var health_before_use := player.health
		player.add_potion()
		var potion_button_icon := touch_controls.get_interact_icon()
		_expect(
			player.potion_count == 2
			and touch_controls._potion_count == 2
			and potion_button_icon != null
			and potion_button_icon.resource_path.contains("Asset 34"),
			"Potions should stack and show their icon and count on the mobile USE button."
		)
		stage.call("_try_interact")
		_expect(
			player.health == health_before_use + 25
			and player.potion_count == 1
			and touch_controls._potion_count == 1,
			"Using a potion should heal 25% of maximum health and consume exactly one stack."
		)
		_expect(
			zone_status.visible
			and zone_status.text == "POTION USED  /  1 LEFT",
			"Using a potion should briefly show the remaining stack."
		)
		_expect(
			(room.get_node("HealingCollectionEffect") as Sprite2D).visible
			and (player.get_node("HealingEffect") as Sprite2D).visible,
			"Collecting and using a potion should play the authored healing effects."
		)
		hud.call("_process", 2.0)
		_expect(not zone_status.visible, "A potion use notice should disappear after two seconds.")

	player.global_position = room.to_global(Vector2(640.0, 76.0))
	for enemy in _get_active_combatants(enemies):
		var defeated_enemy := enemy as FacilityEnemy
		defeated_enemy.take_damage(10000)
		if not defeated_enemy.is_previous_self:
			_expect(
				(defeated_enemy.get_node("Animation") as AnimatedSprite2D).animation == "death",
				"Defeated skeletons should play the supplied death animation before despawning."
			)
	var death_effect := enemies.find_child("EnemyDeathEffect", true, false) as AnimatedSprite2D
	var death_effect_frame := death_effect.sprite_frames.get_frame_texture("burst", 0) as AtlasTexture if death_effect != null else null
	_expect(
		death_effect_frame != null and death_effect_frame.atlas.resource_path.contains("Asset 38"),
		"Defeated enemies should emit the supplied death effect animation."
	)
	_expect(room.is_exit_unlocked(), "Defeating every enemy should unlock the room exit.")
	_expect(
		exit_door != null and (exit_door.texture as AtlasTexture).region == DungeonRoom.OPEN_DOOR_REGION,
		"Clearing a normal room should replace its locked door with the supplied open doorway."
	)
	var door_state_effect := room.get_node_or_null("WorldGeometry/DoorStateEffect") as Sprite2D
	_expect(
		door_state_effect != null
		and (door_state_effect.texture as AtlasTexture).atlas.resource_path.contains("Asset 41"),
		"Locking and unlocking room doors should use the supplied door-effect artwork."
	)
	_expect(room.get_remaining_enemy_count() == 0, "The room should track zero remaining enemies.")
	_expect(
		audio_manager._music_theme == &"exploration",
		"A cleared room should switch from combat to exploration music."
	)
	_expect(manager.points == 0, "Clearing a non-final room should not grant its floor reward early.")
	await physics_frame
	await process_frame
	var first_room_transition_completed := await _wait_for_stage_room(stage, 1, 2)
	_expect(
		first_room_transition_completed,
		"Unlocking the exit should finish the authored room transition before loading room two."
	)
	if not first_room_transition_completed:
		quit(1)
		return
	room = stage.get_current_room()
	_expect(room.get_layout_index() == 1, "The next room should use the next deterministic layout.")
	_expect(room.get_obstacle_count() == 2, "The staggered layout should add visible, collidable cover.")
	var obstacle := room.get_node("WorldGeometry/Obstacles/Obstacle01") as StaticBody2D
	var obstacle_collision := obstacle.get_node("CollisionShape2D") as CollisionShape2D
	var obstacle_shape := obstacle_collision.shape as RectangleShape2D
	_expect(
		not obstacle_collision.disabled
		and (obstacle.collision_layer & 4) != 0
		and obstacle_shape.size.y >= 38.0
		and obstacle_collision.position.y >= 18.0,
		"Crate collision should cover the visible base and footprint, not just a thin strip through the prop."
	)
	var room_two_enemies := room.get_node("Enemies")
	var room_two_active := _get_active_combatants(room_two_enemies)
	_expect(not room_two_active.is_empty(), "The connected room should have active enemies.")
	if room_two_active.is_empty():
		quit(1)
		return
	var blocking_enemy := room_two_active[0] as FacilityEnemy
	for enemy_node in room_two_active:
		var combatant := enemy_node as FacilityEnemy
		if combatant != null and combatant != blocking_enemy:
			combatant.target = null
	blocking_enemy.global_position = obstacle.global_position + Vector2(
		0.0,
		obstacle_collision.position.y - 50.0
	)
	blocking_enemy.call("_update_obstacle_draw_order")
	_expect(
		blocking_enemy.z_index == 0,
		"An enemy behind a crate should render behind its visible prop."
	)
	blocking_enemy.global_position = obstacle.global_position + Vector2(
		0.0,
		obstacle_collision.position.y + 50.0
	)
	blocking_enemy.call("_update_obstacle_draw_order")
	_expect(
		blocking_enemy.z_index == 2,
		"An enemy in front of a crate should render in front of its visible prop."
	)
	blocking_enemy.global_position = obstacle.global_position + Vector2(
		-obstacle_shape.size.x * 0.5 - 45.0,
		obstacle_collision.position.y
	)
	player.global_position = obstacle.global_position + Vector2(
		obstacle_shape.size.x * 0.5 + 80.0,
		obstacle_collision.position.y
	)
	blocking_enemy.target = player
	var enemy_hit_cover := false
	var enemy_stayed_outside_cover := true
	for _frame in 60:
		await physics_frame
		enemy_hit_cover = enemy_hit_cover or blocking_enemy.get_slide_collision_count() > 0
		var enemy_offset := blocking_enemy.global_position - obstacle.global_position
		enemy_offset.y -= obstacle_collision.position.y
		var nearest_cover_point := Vector2(
			clampf(enemy_offset.x, -obstacle_shape.size.x * 0.5, obstacle_shape.size.x * 0.5),
			clampf(enemy_offset.y, -obstacle_shape.size.y * 0.5, obstacle_shape.size.y * 0.5)
		)
		if enemy_offset.distance_to(nearest_cover_point) < 15.0:
			enemy_stayed_outside_cover = false
	_expect(enemy_hit_cover, "An enemy pursuing the player should collide with a crate instead of passing through it.")
	_expect(enemy_stayed_outside_cover, "Enemy collision should keep its body outside the crate footprint.")
	blocking_enemy.target = null

	player._invulnerability_time = 0.0
	player.take_damage(10000)
	_expect(player_sprite.animation == "death", "Lethal damage should play the death animation.")
	await player.player_died
	await process_frame
	_expect(manager.points == 10, "Death should grant exactly ten scrap.")
	_expect(audio_manager._music_theme == &"death", "A defeated run should switch to its death theme.")
	var echo_records := manager.get_echo_records()
	_expect(echo_records.size() == 1, "Death should store one character snapshot.")
	var saved_snapshot: Dictionary = echo_records[0] if not echo_records.is_empty() else {}
	var saved_death_position: Variant = saved_snapshot.get("death_position", {})
	_expect(
		saved_snapshot.has("max_health")
		and saved_snapshot.has("attack_damage")
		and saved_snapshot.has("move_speed"),
		"A death snapshot should preserve character combat stats."
	)
	_expect(
		int(saved_snapshot.get("death_floor", 0)) == 1
		and int(saved_snapshot.get("death_room", 0)) == 2
		and typeof(saved_death_position) == TYPE_DICTIONARY
		and saved_death_position.has("x")
		and saved_death_position.has("y")
		and float(saved_death_position.get("x", -1.0)) >= 32.0
		and float(saved_death_position.get("x", -1.0)) <= 1248.0
		and float(saved_death_position.get("y", -1.0)) >= 32.0
		and float(saved_death_position.get("y", -1.0)) <= 688.0,
		"A death snapshot should retain the floor, room, and bounded room-local death position."
	)
	_expect(
		saved_snapshot.get("weapon_archetypes", []) == ["dungeon_edge", "warden_crossbow"],
		"A death snapshot should preserve its weapon archetypes."
	)
	_expect(
		not saved_snapshot.has("samples") and not saved_snapshot.has("equipped_weapon"),
		"A death snapshot should contain no replayed actions or extra loadout state."
	)
	_expect(main.get("_stage") == null, "A death outcome should return to the workshop.")
	_expect(not saved_level.visible, "Ending a run should hide the saved gameplay scene.")
	_expect(_contains_label(main, "SURVIVOR LOST"), "The death screen should report the run outcome.")
	_expect(_find_button(main, "START THE NEXT RUN") != null, "The defeat flow should offer a restart/continue action.")
	_expect(_contains_label(main, "DUNGEON EDGE"), "The defeat workshop should expose weapon upgrades.")

	main.call("_start_run")
	await process_frame
	stage = main.get("_stage") as Level01Controller
	_expect(stage != null, "A second run should start.")
	_expect(audio_manager._music_theme == &"combat", "Restarting should restore the combat music theme.")
	_expect(stage == saved_level, "The next run should reuse the saved gameplay scene.")
	if stage == null:
		quit(1)
		return

	var traversed_rooms := 0
	var room_layout_mask := 0
	var room_layout_seed := 0
	var echo_combat_verified := false
	var floor5_regular_verified := false
	var final_boss_verified := false
	var completed_by_final_boss := false
	var expected_points := manager.points
	var enemy_archetypes_seen: Dictionary = {}
	for floor_index in floor_definitions.size():
		var floor_definition := floor_definitions[floor_index] as FloorDefinition
		for room_index in floor_definition.room_count:
			room = stage.get_current_room()
			var room_is_in_expected_location := (
				stage.get_current_floor_number() == floor_index + 1
				and stage.get_current_room_number() == room_index + 1
				and room != null
			)
			_expect(
				room_is_in_expected_location,
				"Floor/room transition order should match the traversal (expected %d/%d, got %d/%d)." % [
					floor_index + 1,
					room_index + 1,
					stage.get_current_floor_number(),
					stage.get_current_room_number(),
				]
			)
			if not room_is_in_expected_location:
				quit(1)
				return
			_expect(
				is_equal_approx(room.position.y, -float(traversed_rooms) * DungeonRoom.ROOM_SIZE.y),
				"Each connected room should extend the dungeon upward in world space."
			)
			_expect(
				player.global_position.is_equal_approx(
					room.to_global(Vector2(640.0, 610.0))
				),
				"Room transitions should place the player at the connected room entrance."
			)
			var floor_layer := room.get_node_or_null("FloorLayer") as TileMapLayer
			_expect(floor_layer != null, "Every room should render its floor through a TileMapLayer.")
			if not room.is_boss_encounter():
				var wall_art := room.get_node_or_null("WorldGeometry/SuppliedWalls/WallTop01") as Sprite2D
				var expected_wall_asset := "Asset 29" if floor_index < 4 else "Asset 30"
				_expect(
					wall_art != null
					and (wall_art.texture as AtlasTexture).atlas.resource_path.contains(expected_wall_asset),
					"Regular rooms should use the supplied upper- or deep-dungeon wall artwork."
				)
			if floor_layer != null:
				var floor_tile_set := floor_layer.tile_set
				var floor_atlas := floor_tile_set.get_source(0) as TileSetAtlasSource if floor_tile_set != null else null
				var expected_floor_atlas := "Asset 27" if floor_index < 4 else "Asset 28"
				_expect(
					floor_atlas != null
					and floor_atlas.texture.resource_path.contains(expected_floor_atlas),
					"Each floor theme should use its matching supplied dungeon-floor tileset."
				)
				_expect(
					floor_atlas != null
					and floor_atlas.texture_region_size == Vector2i(176, 176)
					and floor_atlas.margins == Vector2i(8, 8)
					and floor_atlas.separation == Vector2i(16, 16)
					and floor_tile_set.tile_size == Vector2i(176, 176),
					"Floor atlas gutters should be cropped so supplied stone tiles meet cleanly."
				)
				_expect(
					floor_layer.get_used_cells().size() == 28,
					"Each room should fill its full floor with deterministic tiles."
				)
				for y in range(4):
					var row_atlas_columns: Dictionary = {}
					for x in range(7):
						row_atlas_columns[floor_layer.get_cell_atlas_coords(Vector2i(x, y)).x] = true
					_expect(
						row_atlas_columns.size() > 1,
						"Floor tiles should vary across each row instead of forming color bands."
					)
				_expect(
					floor_layer.visible != room.is_boss_encounter(),
					"Boss rooms should keep their dedicated arena artwork instead of the standard floor tiles."
				)
			var room_enemies := room.get_node("Enemies")
			var room_exit_door := room.get_node_or_null("WorldGeometry/ExitDoor") as Sprite2D
			var visible_echo_count := 0
			for echo_index in 3:
				var echo_name := "PreviousSelf" if echo_index == 0 else "PreviousSelf%02d" % (echo_index + 1)
				var echo_slot := room_enemies.get_node_or_null(echo_name) as FacilityEnemy
				if echo_slot != null and echo_slot.visible:
					visible_echo_count += 1
			var echo_should_spawn := (
				int(saved_snapshot.get("death_floor", 0)) == floor_index + 1
				and int(saved_snapshot.get("death_room", 0)) == room_index + 1
			)
			_expect(
				visible_echo_count == (1 if echo_should_spawn else 0),
				"Saved PreviousSelf should appear only in the floor and room where its source run ended."
			)
			var boss_animation: AnimatedSprite2D
			if room.is_boss_encounter():
				_expect(audio_manager._music_theme == &"boss", "Boss encounters should use their dedicated music theme.")
				var boss_room_entrance := room.get_node_or_null("WorldGeometry/BossRoomEntrance") as Sprite2D
				_expect(
					boss_room_entrance != null
					and (boss_room_entrance.texture as AtlasTexture).atlas.resource_path.contains("Asset 32"),
					"Boss arenas should use the supplied dungeon entrance artwork."
				)
				_expect(room_exit_door == null or not room_exit_door.visible, "Dedicated boss arenas should keep their own entrance artwork.")
				_expect(room.get_layout_index() == -1, "Boss arenas should remain open and obstacle-free.")
				_expect(room.get_obstacle_count() == 0, "Boss arenas should not contain cover obstacles.")
				_expect(room.get_encounter_state() == DungeonRoom.EncounterState.BOSS, "Boss rooms should enter their dedicated encounter state.")
				_expect(not room.is_exit_unlocked(), "A boss room exit must remain locked until its boss is defeated.")
				_expect(stage.get_node("HUD").call("is_boss_health_visible"), "Boss encounters should display the boss health bar.")
				var boss_combatants := _get_active_combatants(room_enemies)
				var boss := boss_combatants[0] as DungeonBoss
				_expect(boss != null, "A configured boss room should spawn a DungeonBoss.")
				if boss != null:
					var expected_boss_art := "Asset 23" if floor_index == 4 else "Asset 25"
					_expect(
						(boss.get_node("Art") as Sprite2D).texture.resource_path.contains(expected_boss_art),
						"Each boss should use its supplied Assets portrait."
					)
					_expect(
						(boss.get_node("Aura") as Sprite2D).texture.resource_path.contains("Asset 39"),
						"Bosses should display the supplied aura artwork."
					)
					boss_animation = boss.get_node("Animation") as AnimatedSprite2D
					_expect(
						boss_animation.sprite_frames.has_animation("idle")
						and boss_animation.sprite_frames.has_animation("walk")
						and boss_animation.sprite_frames.has_animation("attack"),
						"Bosses should animate their idle, movement, and telegraphed attack states."
					)
					_expect(
						boss_animation.sprite_frames.get_animation_speed("idle") > 0.0,
						"Boss animation playback speed should be configurable."
					)
					var expected_animation_sheet := "Asset 26"
					var boss_idle_frame := boss_animation.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
					_expect(
						boss_idle_frame != null and boss_idle_frame.atlas.resource_path.contains(expected_animation_sheet),
						"Each boss should use its matching supplied animation sheet."
					)
				if boss != null and floor_index == 9:
					_expect(boss.boss_id == &"hollow_warden", "Floor ten should spawn the final boss.")
					_expect(
						boss.max_health == player.max_health * 5,
						"The final boss should have five times the current player's maximum health."
					)
					_expect(
						boss.attack_damage == roundi(float(player.max_health) / 5.0),
						"The final boss should deal one-fifth of the current player's maximum health."
					)
					boss.begin_attack_telegraph(&"rift_volley")
					_expect(
						boss._telegraph_sprite.visible
						and not boss._target_telegraph.visible
						and boss._telegraph_sprite.z_index >= 0
						and boss._telegraph_sprite.modulate.a >= 0.6,
						"Rift Volley should telegraph its projectile lane with the supplied beam marker."
					)
					boss._windup_time = 0.0
					boss._hide_skill_telegraphs()
					boss.begin_attack_telegraph(&"sigil_burst")
					_expect(
						boss._target_telegraph.visible
						and boss._target_telegraph.z_index >= 0
						and boss._target_telegraph.modulate.a >= 0.6
						and (boss._target_telegraph.texture as AtlasTexture).region == DungeonBoss.TELEGRAPH_CIRCLE_REGION,
						"Sigil Burst should mark its captured ground target with a bright, visible circular AOE."
					)
					boss._windup_time = 0.0
					boss._hide_skill_telegraphs()
					boss.begin_attack_telegraph(&"sanguine_sweep")
					_expect(
						boss._sweep_telegraph.visible
						and boss._sweep_telegraph.z_index >= 0
						and boss._sweep_telegraph.modulate.a >= 0.6,
						"Sanguine Sweep should telegraph its directional cone before striking."
					)
					boss._windup_time = 0.0
					boss._hide_skill_telegraphs()
					player.health = player.max_health
					player.health_changed.emit(player.health, player.max_health)
					player.global_position = boss.global_position + Vector2(100.0, 0.0)
					boss._active_skill_index = 1
					boss._skill_target_position = player.global_position
					player.global_position += Vector2(180.0, 0.0)
					var health_before_dodged_burst := player.health
					boss._fire_attack()
					_expect(
						player.health == health_before_dodged_burst,
						"Moving out of Sigil Burst's marked circle before detonation should avoid damage."
					)
					player.global_position = boss.global_position + Vector2(100.0, 0.0)
					var health_before_burst := player.health
					boss._fire_attack()
					_expect(
						player.health == health_before_burst - boss.attack_damage,
						"Sigil Burst should damage a player who remains inside its marked circle."
					)
					boss._active_skill_index = 2
					boss._attack_direction = Vector2.RIGHT
					player.global_position = boss.global_position + Vector2(0.0, 200.0)
					var health_outside_sweep := player.health
					boss._fire_attack()
					_expect(
						player.health == health_outside_sweep,
						"A player outside Sanguine Sweep's cone should not take damage."
					)
					player.global_position = boss.global_position + Vector2(100.0, 0.0)
					var health_inside_sweep := player.health
					boss._fire_attack()
					_expect(
						player.health == health_inside_sweep - boss.attack_damage,
						"Sanguine Sweep should damage a player caught inside its telegraphed cone."
					)
					player.health = player.max_health
					player.health_changed.emit(player.health, player.max_health)
					player.global_position = room.to_global(Vector2(640.0, 610.0))
					boss.take_damage(100000)
					_expect(room.is_exit_unlocked(), "Defeating the final boss should clear its locked room.")
					expected_points += 130
					_expect(
						manager.points == expected_points,
						"Clearing Floor ten should award its floor reward and final boss bonus."
					)
					_expect(not stage.is_processing(), "Exit monitoring should stop when the run finishes.")
					final_boss_verified = true
					completed_by_final_boss = true
				else:
					_expect(false, "A boss should appear only in the configured Floor ten room.")
				if completed_by_final_boss:
					await process_frame
					traversed_rooms += 1
					break
				await physics_frame
				_expect(room.is_exit_unlocked(), "Every boss room should unlock only after the boss is defeated.")
				_expect(
					room_exit_door == null or not room_exit_door.visible,
					"Final boss rooms should keep their supplied arena backdrop after the fight."
				)
				player = stage.get_node("Player") as RunnerController
				player.global_position = room.to_global(Vector2(640.0, 76.0))
				stage.call("_process", 0.0)
				await physics_frame
				await process_frame
				traversed_rooms += 1
				room_layout_seed += 1
				continue
			_expect(
				room_exit_door != null
				and (room_exit_door.texture as AtlasTexture).region == DungeonRoom.LOCKED_DOOR_REGION,
				"Every regular room should keep its supplied exit door visibly locked during combat."
			)
			var expected_layout_index := room_layout_seed % 4
			_expect(room.get_layout_index() == expected_layout_index, "Room layouts should follow a repeatable four-layout sequence.")
			room_layout_mask = room_layout_mask | (1 << expected_layout_index)
			if floor_index == 4 and room_index == floor_definition.room_count - 1:
				_expect(not room.is_boss_encounter(), "Floor five should no longer contain a fixed PreviousSelf boss.")
				floor5_regular_verified = not room.is_boss_encounter()
			if floor_index == 0 and room_index == 1:
				var echo := room_enemies.get_node_or_null("PreviousSelf") as FacilityEnemy
				var grave := room_enemies.get_node_or_null("EchoGrave01") as Node2D
				var expected_echo_position := Vector2(
					float(saved_death_position.get("x", 640.0)),
					float(saved_death_position.get("y", 320.0))
				)
				_expect(
					echo != null
					and grave != null
					and grave.visible
					and echo.visible
					and grave.position.is_equal_approx(expected_echo_position)
					and absf(echo.position.x - expected_echo_position.x) < 0.01,
					"PreviousSelf should emerge from an authored grave at the exact location of its earlier death."
				)
				if echo != null:
					var echo_art := echo.get_node("Art") as Sprite2D
					_expect(
						echo.max_health > int(saved_snapshot.get("max_health", 100))
						and echo.attack_damage > int(saved_snapshot.get("attack_damage", 10))
						and echo.movement_speed > float(saved_snapshot.get("move_speed", 200.0)),
						"A previous self should be stronger in health, damage, and speed than its saved source."
					)
					_expect(
						echo_art.texture.resource_path.contains("Asset 09")
						and echo_art.scale.y >= 0.09
						and (echo.get_node("CollisionShape2D").shape as CircleShape2D).radius == 22.0,
						"Previous Selves should keep their supplied character art, enlarged with a matching collider."
					)
					echo.velocity = Vector2.LEFT * echo.movement_speed
					echo._facing = Vector2.LEFT
					echo._previous_self_animation_time = 0.0
					echo._update_previous_self_animation(0.1)
					var first_walk_pose := echo_art.position
					echo._update_previous_self_animation(0.1)
					_expect(
						echo_art.flip_h and not echo_art.position.is_equal_approx(first_walk_pose),
						"The original PreviousSelf art should bob through its walk cycle and flip while pursuing left."
					)
					echo.velocity = Vector2.ZERO
					echo._facing = Vector2.UP
					echo._update_previous_self_animation(0.1)
					_expect(echo._has_crossbow, "A previous self should use its saved crossbow archetype.")
					echo.target = null
					for enemy_node in _get_active_combatants(room_enemies):
						var combatant := enemy_node as FacilityEnemy
						if combatant != null and combatant != echo:
							combatant.target = null
					await create_timer(1.25).timeout
					_expect(
						not (echo.get_node("CollisionShape2D") as CollisionShape2D).disabled,
						"A previous self should become attackable only after its grave emergence animation."
					)
					var firing_lane_x := 640.0
					echo.global_position = room.to_global(Vector2(firing_lane_x, 250.0))
					player = stage.get_node("Player") as RunnerController
					player.global_position = room.to_global(Vector2(firing_lane_x, 450.0))
					var health_before_echo_shot := player.health
					echo._spawn_echo_projectile(Vector2.DOWN)
					for _frame in 30:
						await physics_frame
					_expect(player.health < health_before_echo_shot, "A previous-self projectile should collide with and damage the player.")
					echo_combat_verified = true
			if floor_index == 0 and room_index == 1:
				var room_archers := _get_active_combatants(room_enemies)
				var archer := room_archers[1] as FacilityEnemy
				var archer_animation := archer.get_node("Animation") as AnimatedSprite2D
				var archer_idle_frame := archer_animation.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture
				_expect(
					archer.archetype.archetype_id == &"dungeon_archer"
					and archer.archetype.is_ranged
					and archer.max_health == 36
					and is_equal_approx(archer.movement_speed, 82.0)
					and archer._get_attack_range() == 360.0,
					"Room two should apply player-stat room scaling without the melee speed multiplier to archers."
				)
				_expect(
					archer_idle_frame != null and archer_idle_frame.atlas.resource_path.contains("Asset 22"),
					"Archers should animate with their own supplied sprite sheet."
				)
				archer._begin_attack_telegraph(true)
				_expect(
					archer._windup_is_ranged and archer_animation.animation == "attack",
					"An archer telegraph should show its bow attack before firing."
				)
				var firing_lane_x := 640.0
				archer._windup_time = 0.0
				for combatant_node in room_archers:
					var combatant := combatant_node as FacilityEnemy
					if combatant != null:
						combatant.target = null
				archer.global_position = room.to_global(Vector2(firing_lane_x, 250.0))
				player.global_position = room.to_global(Vector2(firing_lane_x, 450.0))
				var health_before_archer_shot := player.health
				archer._spawn_enemy_projectile(Vector2.DOWN)
				for _frame in 30:
					await physics_frame
				_expect(
					player.health == health_before_archer_shot - archer.attack_damage,
					"An archer arrow should travel to and damage the player through projectile collision."
				)
			for enemy in _get_active_combatants(room_enemies):
				var combatant := enemy as FacilityEnemy
				if combatant != null:
					if not combatant.is_previous_self:
						enemy_archetypes_seen[combatant.archetype.archetype_id] = true
					combatant.take_damage(10000)
			await physics_frame
			_expect(room.is_exit_unlocked(), "Every room should unlock its exit when its enemies are defeated.")
			if room_index == floor_definition.room_count - 1:
				expected_points += 30
				_expect(
					manager.points == expected_points,
					"Clearing each non-boss floor should award thirty scrap exactly once."
				)
			player = stage.get_node("Player") as RunnerController
			player.global_position = room.to_global(Vector2(640.0, 76.0))
			stage.call("_process", 0.0)
			await physics_frame
			await process_frame
			var expected_next_floor := floor_index + 1
			var expected_next_room := room_index + 2
			if expected_next_room > floor_definition.room_count:
				expected_next_floor += 1
				expected_next_room = 1
			var transition_completed := await _wait_for_stage_room(
				stage,
				expected_next_floor,
				expected_next_room
			)
			_expect(
				transition_completed,
				"Room/floor %d/%d should load after its transition." % [
					expected_next_floor,
					expected_next_room,
				]
			)
			if not transition_completed:
				quit(1)
				return
			traversed_rooms += 1
			room_layout_seed += 1
		if completed_by_final_boss:
			break
	_expect(traversed_rooms == 38, "The test run should traverse all 38 rooms.")
	_expect(
		enemy_archetypes_seen.has(&"skeleton")
		and enemy_archetypes_seen.has(&"dungeon_creature")
		and enemy_archetypes_seen.has(&"dungeon_archer"),
		"The full run should use all three deterministic enemy archetypes."
	)
	_expect(room_layout_mask == 0b1111, "The complete run should exercise all four deterministic room layouts.")
	_expect(echo_combat_verified, "The full run should verify snapshot echo combat.")
	_expect(floor5_regular_verified, "Floor five should remain a normal floor rather than a fixed PreviousSelf encounter.")
	_expect(final_boss_verified and completed_by_final_boss, "Defeating the Floor ten boss should directly complete the run.")
	await process_frame
	_expect(audio_manager._music_theme == &"victory", "Defeating the final boss should switch to victory music.")
	_expect(main.get("_stage") == null, "Clearing floor ten should complete the run.")
	_expect(_contains_label(main, "FACILITY CLEARED"), "The end screen should report a completed run.")
	_expect(manager.points == 410 and manager.points == expected_points, "Floor and boss rewards should accumulate with the prior death reward.")
	_expect(manager.purchase_upgrade("health"), "The health upgrade should be purchasable.")
	_expect(int(manager.get_player_stats()["max_health"]) == 110, "The health upgrade should add ten maximum HP.")
	_expect(manager.points == 390, "The health upgrade should deduct its configured price.")
	var upgraded_boss_player := RunnerController.new()
	upgraded_boss_player.max_health = int(manager.get_player_stats()["max_health"])
	var upgraded_boss_probe := DungeonBoss.new()
	upgraded_boss_probe.configure(upgraded_boss_player, {}, true)
	_expect(
		upgraded_boss_probe.max_health == 550 and upgraded_boss_probe.attack_damage == 22,
		"Boss health and damage should increase dynamically with a player's health upgrade."
	)
	upgraded_boss_probe.free()
	upgraded_boss_player.free()
	manager.points = 20
	_expect(not manager.purchase_upgrade("warden_crossbow"), "Weapon upgrades should reject purchases without enough currency.")
	manager.points = 30
	_expect(manager.purchase_upgrade("warden_crossbow"), "The crossbow damage upgrade should be purchasable when affordable.")
	_expect(is_equal_approx(float(manager.get_player_stats()["crossbow_damage_multiplier"]), 1.12), "The crossbow upgrade should improve bolt damage.")
	_expect(
		is_equal_approx(float(manager.get_player_stats()["mob_stat_multiplier"]), pow(1.003, 2.0)),
		"Every permanent upgrade level should add a compounding 0.3% multiplier to mob stats."
	)
	var scaling_player := RunnerController.new()
	scaling_player.mob_stat_multiplier = pow(1.003, 100.0)
	var scaling_enemy := FacilityEnemy.new()
	scaling_enemy.configure_player(scaling_player)
	scaling_enemy.configure_for_floor(10)
	_expect(
		scaling_enemy.max_health == roundi(70.0 * scaling_player.mob_stat_multiplier)
		and scaling_enemy.attack_damage == roundi(12.0 * scaling_player.mob_stat_multiplier)
		and is_equal_approx(
			scaling_enemy.movement_speed,
			minf(119.0 * 1.4 * scaling_player.mob_stat_multiplier, 400.0)
		),
		"Ordinary mob health, damage, and speed should inherit the persistent upgrade multiplier (health %d, damage %d, speed %.1f, scale %.3f)."
		% [
			scaling_enemy.max_health,
			scaling_enemy.attack_damage,
			scaling_enemy.movement_speed,
			scaling_player.mob_stat_multiplier,
		]
	)
	scaling_enemy.free()
	scaling_player.free()
	_expect(manager.is_upgrade_maxed("warden_crossbow") == false, "A weapon upgrade should remain below maximum after one purchase.")
	_expect(manager.entry_tutorial_completed, "The active profile should retain its completed entry tutorial.")
	main.call("show_title_screen")
	await process_frame
	var available_tutorial_button := main.get_node("TutorialLayer/TutorialRoot/TutorialButton") as Button
	_expect(available_tutorial_button.visible, "HOW TO PLAY should remain available after the mandatory tutorial.")
	var attempts_before_repeat_entry := manager.attempts
	_find_button(main, "ENTER THE DUNGEON").emit_signal("pressed")
	await process_frame
	stage = main.get("_stage") as Level01Controller
	_expect(
		manager.run_active
		and manager.attempts == attempts_before_repeat_entry + 1
		and not tutorial_panel.visible,
		"Later ENTER THE DUNGEON clicks should start directly without reopening the mandatory tutorial."
	)
	main.call("_abandon_run")
	await process_frame
	main.call("show_title_screen")
	await process_frame
	var attempts_before_replay := manager.attempts
	available_tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(
		tutorial_panel.visible
		and paused
		and not manager.run_active
		and manager.attempts == attempts_before_replay
		and manager.entry_tutorial_completed,
		"HOW TO PLAY should replay the tutorial without changing the saved entry state or counting a run."
	)
	tutorial_card.get_node("BackToMenu").emit_signal("pressed")
	await process_frame
	_expect(
		not tutorial_panel.visible
		and not paused
		and manager.entry_tutorial_completed
		and manager.attempts == attempts_before_replay,
		"Exiting a tutorial replay should return to the title without resetting its completion state."
	)

	if is_instance_valid(main):
		main.queue_free()
	var audio_autoload := root.get_node_or_null("AudioManager")
	if is_instance_valid(audio_autoload):
		audio_autoload.queue_free()
	await process_frame
	await process_frame
	if _failed:
		quit(1)
	else:
		print("PASS: GDD gameplay, UI/mobile systems, all room layouts, and the complete ten-floor run.")
		quit(0)


func _get_active_combatants(container: Node) -> Array[Node]:
	var active: Array[Node] = []
	for child in container.get_children():
		var combatant := child as Node2D
		if combatant == null or not combatant.visible:
			continue
		var collision := combatant.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled:
			continue
		active.append(combatant)
	return active


func _wait_for_stage_room(stage: Level01Controller, floor_number: int, room_number: int) -> bool:
	for _frame in 240:
		if (
			stage.get_current_floor_number() == floor_number
			and stage.get_current_room_number() == room_number
			and stage.get_current_room() != null
			and not stage._transition_pending
		):
			return true
		await physics_frame
	return false


func _expect(condition: bool, description: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FAIL: %s" % description)


func _contains_label(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	for child in node.get_children():
		if _contains_label(child, expected):
			return true
	return false


func _select_profile_option(selector: OptionButton, username: String) -> bool:
	if selector == null:
		return false
	for index in selector.item_count:
		if selector.get_item_text(index) == username:
			selector.select(index)
			return true
	return false


func _find_button(node: Node, expected_text: String) -> Button:
	if node is Button and (node as Button).text == expected_text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, expected_text)
		if found != null:
			return found
	return null
