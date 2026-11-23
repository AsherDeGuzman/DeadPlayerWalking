extends Control

const MENU_BACKGROUND_PATH := "res://ASSETS/UI ASSETS/Asset 47 — Main menu background.png"
const DEFEAT_BACKGROUND_PATH := "res://ASSETS/UI ASSETS/Asset 48 — Death Screen Background.png"
const VICTORY_BACKGROUND_PATH := "res://ASSETS/UI ASSETS/Asset 49 — Victory Screen Background.png"
const UPGRADE_ICON_ATLAS := preload("res://ASSETS/UI ASSETS/Asset 46 — Upgrade screen icons.png")
const UPGRADE_ICON_REGIONS := {
	"health": Rect2(0.0, 0.0, 512.0, 512.0),
	"speed": Rect2(512.0, 0.0, 512.0, 512.0),
	"damage": Rect2(1024.0, 0.0, 512.0, 512.0),
	"dungeon_edge": Rect2(0.0, 512.0, 512.0, 512.0),
	"warden_crossbow": Rect2(512.0, 512.0, 512.0, 512.0),
}
const TUTORIAL_STEPS := [
	{
		"target": "health",
		"title": "HEALTH & SCRAP",
		"description": "Your HP is shown here. If it reaches zero, the run ends. Floor clears and run outcomes award scrap for permanent upgrades.",
	},
	{
		"target": "player",
		"title": "MOVE & ATTACK",
		"description": "Move with WASD / arrow keys or the mobile joystick. Press Space or STRIKE to attack.",
	},
	{
		"target": "switch",
		"title": "CHOOSE YOUR WEAPON",
		"description": "Press Q or SWAP to switch between the Dungeon Edge sword and Warden Crossbow. Space attacks with your selected weapon.",
	},
	{
		"target": "dash",
		"title": "DASH TO DODGE",
		"description": "Shift / K or DASH gives a quick dodge with brief invulnerability. It recharges in 3 seconds; use it to escape attacks.",
	},
	{
		"target": "interact",
		"title": "HEAL WITH POTIONS",
		"description": "Collect a potion, then press E or USE to restore up to 25% of your max HP. You can carry several.",
	},
	{
		"target": "enemy",
		"title": "READ YOUR ENEMIES",
		"description": "Rooms mix close-range fighters and ranged archers. Watch their wind-up and dodge. Bosses mark area attacks before they land.",
	},
	{
		"target": "exit",
		"title": "CLEAR ROOMS & DESCEND",
		"description": "Defeat every enemy to unlock the exit. Reach it to descend through ten floors and face the final boss.",
	},
]

@onready var _run_manager: PersistentRunManager = $RunManager
@onready var _level: Level01Controller = $Level01
@onready var _tutorial_root: Control = $TutorialLayer/TutorialRoot
@onready var _tutorial_button: Button = $TutorialLayer/TutorialRoot/TutorialButton
@onready var _tutorial_panel: Control = $TutorialLayer/TutorialRoot/TutorialPanel
@onready var _tutorial_focus_frame: Panel = $TutorialLayer/TutorialRoot/TutorialPanel/FocusFrame
@onready var _tutorial_pointer_line: Line2D = $TutorialLayer/TutorialRoot/TutorialPanel/PointerLine
@onready var _tutorial_pointer_head: Polygon2D = $TutorialLayer/TutorialRoot/TutorialPanel/PointerHead
@onready var _tutorial_card: Control = $TutorialLayer/TutorialRoot/TutorialPanel/Card
@onready var _tutorial_step_counter: Label = $TutorialLayer/TutorialRoot/TutorialPanel/Card/StepCounter
@onready var _tutorial_target_title: Label = $TutorialLayer/TutorialRoot/TutorialPanel/Card/TargetTitle
@onready var _tutorial_description: Label = $TutorialLayer/TutorialRoot/TutorialPanel/Card/Description
@onready var _tutorial_back_button: Button = $TutorialLayer/TutorialRoot/TutorialPanel/Card/BackToMenu
@onready var _tutorial_start_button: Button = $TutorialLayer/TutorialRoot/TutorialPanel/Card/StartRun
@onready var _profile_root: Control = $ProfileLayer/ProfileRoot
@onready var _profile_button: Button = $TutorialLayer/TutorialRoot/ProfileButton
@onready var _profile_selector: OptionButton = $ProfileLayer/ProfileRoot/Card/SavedProfiles
@onready var _profile_continue_button: Button = $ProfileLayer/ProfileRoot/Card/ContinueProfile
@onready var _profile_username: LineEdit = $ProfileLayer/ProfileRoot/Card/UsernameInput
@onready var _profile_create_button: Button = $ProfileLayer/ProfileRoot/Card/CreateProfile
@onready var _profile_status: Label = $ProfileLayer/ProfileRoot/Card/Status

var _stage: Level01Controller
var _audio_manager: GameAudioManager
var _screen_layer: CanvasLayer
var _screen_root: Control
var _overlay_layer: CanvasLayer
var _is_between_runs := false
var _pause_layer: CanvasLayer
var _pause_root: Control
var _is_paused := false
var _settings_from_pause := false
var _tutorial_step := 0
var _tutorial_demo_active := false
var _tutorial_required_for_this_entry := false
var _last_outcome_text := ""
var _last_reward := 0
var _last_echo_recorded := false
var _return_to_menu_after_abandon := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level.visible = false
	_audio_manager = get_node("/root/AudioManager") as GameAudioManager
	_audio_manager.set_music_volume(_run_manager.music_volume)
	_audio_manager.set_sfx_volume(_run_manager.sfx_volume)
	_run_manager.run_finished.connect(_on_run_finished)
	_tutorial_button.pressed.connect(_show_tutorial)
	_tutorial_back_button.pressed.connect(_close_tutorial)
	_tutorial_start_button.pressed.connect(_advance_tutorial_step)
	_profile_button.pressed.connect(_show_profile_screen)
	_profile_continue_button.pressed.connect(_continue_selected_profile)
	_profile_create_button.pressed.connect(_create_profile)
	_profile_username.text_submitted.connect(_on_profile_name_submitted)
	get_viewport().size_changed.connect(_refresh_responsive_layout)
	_show_profile_screen()
	_refresh_responsive_layout()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _stage != null and not _is_between_runs:
		if _tutorial_demo_active:
			get_viewport().set_input_as_handled()
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()


func show_title_screen() -> void:
	_clear_stage()
	_clear_overlay()
	_clear_screen()
	_profile_root.visible = false
	_tutorial_panel.visible = false
	_tutorial_button.visible = true
	_profile_button.visible = true
	_profile_button.text = _run_manager.active_profile_name
	_profile_button.tooltip_text = "Switch player (%s)" % _run_manager.active_profile_name
	_is_between_runs = false
	_audio_manager.set_music_theme("menu")
	_create_screen_layer(MENU_BACKGROUND_PATH)

	_add_title_frame()
	_add_color_rect(_screen_root, "HeaderRule", Vector2(82, 77), Vector2(58, 3), Color("ff405a"))
	_add_label(
		_screen_root,
		"S U R V I V O R   R E C O R D   /   D E S C E N T   0 1",
		Vector2(82, 49),
		Vector2(760, 30),
		15,
		Color("ff5366")
	)
	_add_title_emblem()
	var title_line_one := _add_label(
		_screen_root,
		"DEAD PLAYER",
		Vector2(80, 104),
		Vector2(1030, 112),
		91,
		Color("f0e9df")
	)
	title_line_one.name = "TitleLineOne"
	var title_line_two := _add_label(
		_screen_root,
		"WALKING",
		Vector2(80, 202),
		Vector2(780, 104),
		91,
		Color("ff405a")
	)
	title_line_two.name = "TitleLineTwo"
	_add_label(
		_screen_root,
		"THE PLAYER IMPROVES.\nTHEIR PAST REMAINS.",
		Vector2(84, 310),
		Vector2(600, 68),
		22,
		Color("c5a18e")
	)

	var snapshot: Dictionary = _run_manager.get_progress_snapshot()
	var card_width := 360.0
	var card_gap := 18.0
	var card_y := 390.0
	_add_progress_card(
		"Runs",
		"%02d" % int(snapshot["attempts"]),
		Vector2(82.0, card_y),
		Vector2(card_width, 76.0)
	)
	_add_progress_card(
		"Scrap",
		str(int(snapshot["points"])),
		Vector2(82.0 + card_width + card_gap, card_y),
		Vector2(card_width, 76.0)
	)
	_add_progress_card(
		"Echoes",
		str(int(snapshot["echo_count"])),
		Vector2(82.0 + (card_width + card_gap) * 2.0, card_y),
		Vector2(card_width, 76.0)
	)

	var menu_buttons := [
		{"number": "01", "text": "ENTER THE DUNGEON", "color": Color("751d2d"), "action": _begin_run},
		{"number": "02", "text": "PERMANENT UPGRADES", "color": Color("100d11"), "action": _show_workshop.bind(false, 0, false)},
		{"number": "03", "text": "SETTINGS", "color": Color("100d11"), "action": _show_settings.bind(false)},
		{"number": "04", "text": "EXIT GAME", "color": Color("100d11"), "action": _exit_game},
	]
	for index in menu_buttons.size():
		var menu_button: Dictionary = menu_buttons[index]
		var button := _add_button(
			_screen_root,
			str(menu_button["text"]),
			Vector2(82.0, 484.0 + float(index) * 56.0),
			Vector2(1116.0, 48.0),
			menu_button["color"],
			menu_button["action"]
		)
		button.add_theme_font_size_override("font_size", 21)
		button.add_theme_color_override("font_color", Color("f4eee8"))
		button.add_theme_color_override("font_hover_color", Color("ff6374"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var normal_style := _button_style(Color(menu_button["color"]), Color("35282f"), 0)
		normal_style.content_margin_left = 92
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override(
			"hover",
			_button_style_with_left_margin(Color("21141a"), Color("ff5366"), 92)
		)
		button.add_theme_stylebox_override(
			"pressed",
			_button_style_with_left_margin(Color("32151d"), Color("cf4051"), 92)
		)
		button.add_theme_stylebox_override(
			"focus",
			_button_style_with_left_margin(Color.TRANSPARENT, Color("ff5366"), 92)
		)
		var number_label := _add_label(
			button,
			str(menu_button["number"]),
			Vector2(20.0, 0.0),
			Vector2(46.0, button.size.y),
			14,
			Color("ff6574")
		)
		number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_add_color_rect(
			button,
			"Accent",
			Vector2.ZERO,
			Vector2(4.0, button.size.y),
			Color("ff405a")
		)


func _begin_run() -> void:
	if _run_manager.active_profile_name.is_empty():
		_show_profile_screen()
	elif _run_manager.entry_tutorial_completed:
		_start_run()
	else:
		_tutorial_required_for_this_entry = true
		_start_tutorial_demo()


func _start_run() -> void:
	_tutorial_demo_active = false
	get_tree().paused = false
	_tutorial_panel.visible = false
	_tutorial_button.visible = false
	_profile_button.visible = false
	_resume_run_audio()
	_audio_manager.set_music_theme("combat")
	_clear_screen()
	_clear_overlay()
	_clear_pause_screen()
	_clear_stage()
	var run_number: int = _run_manager.begin_run()
	_audio_manager.play_sfx("echo")

	_stage = _level
	_connect_stage_signals()
	_stage.visible = true
	_stage.begin_run(
		_run_manager.get_player_stats(),
		_run_manager.get_echo_records(),
		run_number,
		int(_run_manager.get_progress_snapshot()["points"])
	)


func _start_tutorial_demo() -> void:
	if _stage != null:
		return
	_tutorial_demo_active = true
	_tutorial_step = 0
	_profile_root.visible = false
	_tutorial_button.visible = false
	_profile_button.visible = false
	_tutorial_panel.visible = true
	_resume_run_audio()
	_clear_screen()
	_clear_overlay()
	_clear_pause_screen()
	_clear_stage()
	_audio_manager.set_music_theme("combat")

	_stage = _level
	_connect_stage_signals()
	_stage.visible = true
	var progress_snapshot := _run_manager.get_progress_snapshot()
	_stage.begin_run(
		_run_manager.get_player_stats(),
		_run_manager.get_echo_records(),
		maxi(1, _run_manager.attempts + 1),
		int(progress_snapshot["points"])
	)
	var demo_player := _stage.get_node("Player") as RunnerController
	var demo_room := _stage.get_current_room()
	if demo_room != null:
		demo_player.global_position = demo_room.to_global(Vector2(640.0, 360.0))
	demo_player.velocity = Vector2.ZERO
	var demo_camera := demo_player.get_node("Camera2D") as Camera2D
	demo_camera.reset_smoothing()

	get_tree().paused = true
	_audio_manager.set_gameplay_paused(true)
	await get_tree().process_frame
	_update_tutorial_step()


func _connect_stage_signals() -> void:
	if not _stage.level_finished.is_connected(_on_level_finished):
		_stage.level_finished.connect(_on_level_finished)
	if not _stage.floor_cleared.is_connected(_on_stage_floor_cleared):
		_stage.floor_cleared.connect(_on_stage_floor_cleared)
	if not _stage.choice_requested.is_connected(_on_choice_requested):
		_stage.choice_requested.connect(_on_choice_requested)
	if not _stage.pause_requested.is_connected(_toggle_pause):
		_stage.pause_requested.connect(_toggle_pause)


func _on_level_finished(completed: bool, record: Dictionary) -> void:
	_run_manager.finish_run(completed, record)


func _on_stage_floor_cleared(floor_number: int) -> void:
	var reward := _run_manager.award_floor_clear(floor_number)
	if reward <= 0 or _stage == null:
		return
	_stage.set_points_total(_run_manager.points)
	_stage.show_floor_reward(floor_number, reward)


func _on_run_finished(completed: bool, reward: int, total_points: int, recorded_echo: bool) -> void:
	_audio_manager.set_music_theme("victory" if completed else "death")
	_resume_run_audio()
	_last_outcome_text = "LEVEL COMPLETE" if completed else "RUN ENDED"
	_last_reward = reward
	_last_echo_recorded = recorded_echo
	if _stage != null:
		_stage.end_run()
		_stage.visible = false
		_stage = null
	_clear_overlay()
	if _return_to_menu_after_abandon:
		_return_to_menu_after_abandon = false
		show_title_screen()
	else:
		_show_workshop(true, reward, recorded_echo)


func _show_workshop(between_runs: bool, reward: int = 0, recorded_echo: bool = false) -> void:
	_clear_screen()
	_is_between_runs = between_runs
	var background_path := MENU_BACKGROUND_PATH
	if between_runs:
		background_path = VICTORY_BACKGROUND_PATH if _last_outcome_text == "LEVEL COMPLETE" else DEFEAT_BACKGROUND_PATH
	_create_screen_layer(background_path)

	var workshop_panel := _make_panel(_screen_root, Vector2(68, 34), Vector2(1144, 650))
	var workshop_content := _panel_content(workshop_panel)
	if between_runs:
		_add_label(workshop_content, "RUN SUMMARY  /  %02d" % int(_run_manager.get_progress_snapshot()["attempts"]), Vector2(34, 48), Vector2(390, 28), 14, Color("e3b57f"))
		var outcome_title := "FACILITY CLEARED" if _last_outcome_text == "LEVEL COMPLETE" else "SURVIVOR LOST"
		var outcome_detail := "OBJECTIVE REACHED  /  +%d SCRAP" % reward if _last_outcome_text == "LEVEL COMPLETE" else "HEALTH DEPLETED  /  +%d SCRAP" % reward
		var outcome_color := Color("b9e2c6") if _last_outcome_text == "LEVEL COMPLETE" else Color("eeaaa1")
		_add_label(workshop_content, outcome_title, Vector2(30, 100), Vector2(390, 68), 36, outcome_color)
		_add_label(workshop_content, outcome_detail, Vector2(34, 186), Vector2(390, 42), 14, Color("d5b887"))
		_add_label(
			workshop_content,
			"%s   ·   %d TOTAL SCRAP" % ["PREVIOUS SELF RECORDED" if recorded_echo else "NO NEW ECHO", int(_run_manager.points)],
			Vector2(34, 246),
			Vector2(390, 44),
			12,
			Color("b18c9a")
		)
	else:
		_add_label(workshop_content, "BETWEEN RUNS  /  WORKSHOP", Vector2(34, 88), Vector2(390, 30), 14, Color("e3b57f"))
		_add_label(workshop_content, "PERMANENT\nUPGRADES", Vector2(30, 140), Vector2(390, 150), 54, Color("f0efe2"))
		_add_label(workshop_content, "Spend scrap now. Every purchase carries into the next attempt.", Vector2(34, 308), Vector2(376, 72), 18, Color("c5a18e"))

	var card := _make_panel(workshop_content, Vector2(464, 34), Vector2(654, 584))
	card.name = "UpgradeCard"
	var card_content := _panel_content(card)

	var snapshot: Dictionary = _run_manager.get_progress_snapshot()
	var points := int(snapshot["points"])
	_add_label(card_content, "AVAILABLE SCRAP", Vector2(26, 14), Vector2(240, 26), 12, Color("e3b57f"))
	_add_label(card_content, "%d" % points, Vector2(26, 43), Vector2(280, 46), 34, Color("f0d39a"))

	var upgrades: Dictionary = snapshot["upgrades"]
	var stats: Dictionary = _run_manager.get_player_stats()
	var rows := [
		{
			"id": "health",
			"detail": "+10 MAX HP  /  NOW %d" % int(stats["max_health"]),
		},
		{
			"id": "damage",
			"detail": "+2 BASE DAMAGE  /  NOW %d" % int(stats["attack_damage"]),
		},
		{
			"id": "speed",
			"detail": "+10 SPEED  /  NOW %d" % int(stats["move_speed"]),
		},
		{"id": "dungeon_edge", "detail": "+12%% SWORD DAMAGE  /  %.0f%% TOTAL" % (float(stats["sword_damage_multiplier"]) * 100.0)},
		{"id": "warden_crossbow", "detail": "+12%% BOLT DAMAGE  /  %.0f%% TOTAL" % (float(stats["crossbow_damage_multiplier"]) * 100.0)},
	]

	var row_y := 102.0
	var row_step := 88.0
	for row in rows:
		var upgrade_id: String = row["id"]
		var definition: Dictionary = PersistentRunManager.UPGRADE_DEFINITIONS[upgrade_id]
		var level := int(upgrades[upgrade_id])
		var maximum_level := int(PersistentRunManager.UPGRADE_MAX_LEVELS[upgrade_id])
		var upgrade_icon := TextureRect.new()
		upgrade_icon.name = "%sIcon" % upgrade_id
		var icon_texture := AtlasTexture.new()
		icon_texture.atlas = UPGRADE_ICON_ATLAS
		icon_texture.region = UPGRADE_ICON_REGIONS[upgrade_id]
		upgrade_icon.texture = icon_texture
		upgrade_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		upgrade_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		upgrade_icon.stretch_mode = TextureRect.STRETCH_SCALE
		upgrade_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_icon.position = Vector2(22.0, row_y + 15.0)
		card_content.add_child(upgrade_icon)
		upgrade_icon.size = Vector2(48.0, 48.0)
		_add_label(
			card_content,
			"%s  /  %02d OF %02d" % [definition["name"], level, maximum_level],
			Vector2(82, row_y),
			Vector2(368, 24),
			13,
			Color("e3e7d8")
		)
		_add_label(card_content, row["detail"], Vector2(82, row_y + 24), Vector2(368, 22), 11, Color("bcb0ad"))
		_add_label(card_content, str(definition["description"]), Vector2(82, row_y + 48), Vector2(368, 20), 10, Color("a89a9e"))
		var price := int(_run_manager.get_upgrade_cost(upgrade_id))
		var maxed := _run_manager.is_upgrade_maxed(upgrade_id)
		var purchase := _add_button(
			card_content,
			"MAXED" if maxed else "%d  /  BUY" % price,
			Vector2(458, row_y + 12),
			Vector2(166, 48),
			Color("31544b"),
			_buy_upgrade.bind(upgrade_id)
		)
		purchase.disabled = maxed or points < price
		row_y += row_step

	if between_runs:
		var echoes := int(snapshot["echo_count"])
		_add_label(card_content, "HISTORY  /  %d OF 3 ECHO RECORDS" % echoes, Vector2(26, 548), Vector2(560, 24), 11, Color("b18c9a"))
		_add_button(workshop_content, "START THE NEXT RUN", Vector2(34, 474), Vector2(370, 60), Color("315b4d"), _start_run)
	else:
		_add_label(card_content, "CHARACTER COSTS 20 / 25 / 20  ·  WEAPONS 30 SCRAP PER LEVEL", Vector2(26, 548), Vector2(600, 24), 10, Color("a89a9e"))
		_add_button(workshop_content, "BACK TO THE FACILITY LOG", Vector2(34, 478), Vector2(370, 56), Color("293c3d"), show_title_screen)


func _buy_upgrade(upgrade_id: String) -> void:
	if _run_manager.purchase_upgrade(upgrade_id):
		_audio_manager.play_sfx("upgrade_purchase")
	_show_workshop(_is_between_runs, _last_reward, _last_echo_recorded)


func _exit_game() -> void:
	get_tree().quit()


func _show_settings(paused: bool) -> void:
	_settings_from_pause = paused
	if paused:
		_show_pause_settings()
		return
	_clear_screen()
	_create_screen_layer(MENU_BACKGROUND_PATH)
	var panel := _make_panel(_screen_root, Vector2(360, 116), Vector2(560, 488))
	var content := _panel_content(panel)
	_add_label(content, "SETTINGS", Vector2(45, 35), Vector2(470, 64), 44, Color("f0efe2"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(content, "Adjust sound levels for this device.", Vector2(48, 106), Vector2(464, 38), 16, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)
	_build_audio_settings(content, 174.0)
	_add_button(content, "SAVE AND RETURN", Vector2(48, 390), Vector2(464, 58), Color("315b4d"), _leave_settings)


func _build_audio_settings(parent: Control, top: float) -> void:
	var left := maxf(64.0, (parent.size.x - 460.0) * 0.5)
	_add_label(parent, "AMBIENCE", Vector2(left, top), Vector2(220, 30), 15, Color("e3e7d8"))
	_add_label(parent, "SOUND EFFECTS", Vector2(left, top + 92.0), Vector2(260, 30), 15, Color("e3e7d8"))
	var music_slider := _create_volume_slider(parent, "MusicVolume", Vector2(left, top + 34.0), _run_manager.music_volume)
	var effects_slider := _create_volume_slider(parent, "SfxVolume", Vector2(left, top + 126.0), _run_manager.sfx_volume)
	_add_label(parent, "Changes are saved on return.", Vector2(left, top + 184.0), Vector2(440, 26), 12, Color("a89a9e"))
	music_slider.value_changed.connect(_on_music_volume_changed)
	effects_slider.value_changed.connect(_on_sfx_volume_changed)


func _create_volume_slider(
	parent: Control,
	slider_name: String,
	position: Vector2,
	value: float
) -> HSlider:
	var slider := HSlider.new()
	slider.name = slider_name
	slider.position = position
	slider.size = Vector2(440, 42)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.tick_count = 11
	slider.ticks_on_borders = true
	parent.add_child(slider)
	return slider


func _add_title_frame() -> void:
	var frame := PanelContainer.new()
	frame.name = "TitleFrame"
	frame.position = Vector2(8.0, 8.0)
	frame.size = Vector2(1264.0, 704.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	frame_style.border_color = Color("31537a")
	frame_style.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	_screen_root.add_child(frame)
	_add_color_rect(_screen_root, "FrameAccentTopLeft", Vector2(8, 8), Vector2(96, 4), Color("ff405a"))
	_add_color_rect(_screen_root, "FrameAccentTopLeftVertical", Vector2(8, 8), Vector2(4, 96), Color("ff405a"))
	_add_color_rect(_screen_root, "FrameAccentBottomRight", Vector2(1176, 708), Vector2(96, 4), Color("ff405a"))
	_add_color_rect(_screen_root, "FrameAccentBottomRightVertical", Vector2(1268, 616), Vector2(4, 96), Color("ff405a"))


func _add_title_emblem() -> void:
	var emblem := PanelContainer.new()
	emblem.name = "TitleEmblem"
	emblem.position = Vector2(1130.0, 48.0)
	emblem.size = Vector2(62.0, 62.0)
	var emblem_style := StyleBoxFlat.new()
	emblem_style.bg_color = Color("35121d")
	emblem_style.border_color = Color("ff5366")
	emblem_style.set_border_width_all(2)
	emblem.add_theme_stylebox_override("panel", emblem_style)
	_screen_root.add_child(emblem)
	var content := _panel_content(emblem)
	var symbol := _add_label(
		content,
		"◇",
		Vector2.ZERO,
		emblem.size,
		37,
		Color("ff5366"),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	symbol.name = "TitleEmblemSymbol"


func _add_progress_card(
	title: String,
	value: String,
	position: Vector2,
	dimensions: Vector2
) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "%sCard" % title
	card.position = position
	card.size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100c10")
	style.border_color = Color("56303b")
	style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)
	_screen_root.add_child(card)
	var content := _panel_content(card)
	var title_label := _add_label(
		content,
		title.to_upper(),
		Vector2(18.0, 7.0),
		Vector2(dimensions.x - 36.0, 24.0),
		13,
		Color("e3b57f")
	)
	title_label.name = "%sTitle" % title
	var value_label := _add_label(
		content,
		value,
		Vector2(18.0, 29.0),
		Vector2(dimensions.x - 36.0, 42.0),
		34,
		Color("f4eee8")
	)
	value_label.name = "%sValue" % title
	return card


func _add_color_rect(
	parent: Control,
	node_name: String,
	position: Vector2,
	dimensions: Vector2,
	color: Color
) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = position
	rect.size = dimensions
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _on_music_volume_changed(value: float) -> void:
	_run_manager.set_audio_volumes(value, _run_manager.sfx_volume)
	_audio_manager.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	_run_manager.set_audio_volumes(_run_manager.music_volume, value)
	_audio_manager.set_sfx_volume(value)


func _leave_settings() -> void:
	_run_manager.save_settings()
	if _settings_from_pause:
		_show_pause_menu()
	else:
		show_title_screen()


func _on_choice_requested(choice_kind: String) -> void:
	if _stage == null:
		return
	_audio_manager.play_sfx("echo" if choice_kind == "previous_self" else "hazard")
	_stage.set_choice_paused(true)
	_clear_overlay()

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 12
	add_child(_overlay_layer)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.03, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var title := "CHOOSE YOUR ROUTE" if choice_kind == "route" else "A FAMILIAR SHAPE"
	var subheading := "The paths reconverge. The cost does not." if choice_kind == "route" else "This one learned from a run you did not survive."
	var panel := _make_panel(overlay, Vector2(352, 154), Vector2(576, 414))
	var content := _panel_content(panel)
	_add_label(content, title, Vector2(46, 34), Vector2(484, 68), 32, Color("f0efe2"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(content, subheading, Vector2(50, 112), Vector2(476, 52), 16, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)

	if choice_kind == "route":
		_add_button(content, "SUPPLY ROUTE  /  LONGER, COVERED", Vector2(54, 190), Vector2(468, 60), Color("315348"), _select_route.bind("supply"))
		_add_label(content, "More cover. Scattered supplies. No active hazard.", Vector2(50, 251), Vector2(476, 30), 12, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_button(content, "HAZARDOUS SHORTCUT  /  FASTER", Vector2(54, 302), Vector2(468, 60), Color("67433a"), _select_route.bind("shortcut"))
		_add_label(content, "Open lane. One live conduit. Both routes rejoin ahead.", Vector2(50, 363), Vector2(476, 30), 12, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_add_button(content, "PRESS THE ATTACK  /  START ADVANTAGE", Vector2(54, 190), Vector2(468, 60), Color("67433a"), _select_previous_self.bind("strike"))
		_add_label(content, "Open with a hit. The echo begins wounded.", Vector2(50, 251), Vector2(476, 30), 12, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_button(content, "KEEP DISTANCE  /  REPOSITION", Vector2(54, 302), Vector2(468, 60), Color("315348"), _select_previous_self.bind("distance"))
		_add_label(content, "No free hit. Start across the room with space to move.", Vector2(50, 363), Vector2(476, 30), 12, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)


func _select_route(route: String) -> void:
	_audio_manager.play_sfx("ui")
	if _stage != null:
		_stage.choose_route(route)
	_clear_overlay()


func _select_previous_self(response: String) -> void:
	_audio_manager.play_sfx("ui")
	if _stage != null:
		_stage.choose_previous_self(response)
	_clear_overlay()


func _create_screen_layer(background_path: String) -> void:
	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 5
	add_child(_screen_layer)
	_screen_root = Control.new()
	_screen_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_screen_root.size = Vector2(1280.0, 720.0)
	_screen_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen_layer.add_child(_screen_root)
	_fit_design_canvas(_screen_root)

	var background_texture := load(background_path) as Texture2D
	if background_texture == null:
		push_error("Could not load screen background: %s" % background_path)
		return
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_root.add_child(background)
	_screen_root.move_child(background, 0)

	var shade := ColorRect.new()
	shade.name = "BackgroundShade"
	shade.color = Color(0.015, 0.025, 0.03, 0.42)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_root.add_child(shade)
	_screen_root.move_child(shade, 1)


func _clear_screen() -> void:
	if _screen_layer != null and is_instance_valid(_screen_layer):
		_screen_layer.queue_free()
	_screen_layer = null
	_screen_root = null


func _show_tutorial() -> void:
	_tutorial_required_for_this_entry = false
	_start_tutorial_demo()


func _close_tutorial() -> void:
	if not _tutorial_demo_active:
		return
	_tutorial_demo_active = false
	_tutorial_required_for_this_entry = false
	get_tree().paused = false
	_resume_run_audio()
	_tutorial_panel.visible = false
	_clear_stage()
	show_title_screen()


func _advance_tutorial_step() -> void:
	if not _tutorial_demo_active:
		return
	if _tutorial_step >= TUTORIAL_STEPS.size() - 1:
		if _tutorial_required_for_this_entry and not _run_manager.mark_entry_tutorial_completed():
			_tutorial_target_title.text = "SAVE FAILED"
			_tutorial_description.text = "Tutorial completion could not be saved. Check available storage, then try START RUN again."
			return
		_tutorial_required_for_this_entry = false
		_start_run()
		return
	_tutorial_step += 1
	_update_tutorial_step()


func _update_tutorial_step() -> void:
	if not _tutorial_demo_active or _tutorial_step >= TUTORIAL_STEPS.size():
		return
	var step: Dictionary = TUTORIAL_STEPS[_tutorial_step]
	_tutorial_target_title.text = str(step["title"])
	_tutorial_description.text = str(step["description"])
	if str(step["target"]) == "enemy":
		var room := _stage.get_current_room()
		var enemy := room.get_node_or_null("Enemies/Enemy01") as FacilityEnemy if room != null else null
		if enemy != null and enemy.archetype != null:
			var attack_style := (
				"fires from a distance"
				if enemy.archetype.is_ranged
				else "rushes in for melee"
			)
			_tutorial_target_title.text = "ENEMY: %s" % enemy.archetype.display_name
			_tutorial_description.text = (
				"%s %s. Dodge its attacks; bosses mark their area strikes before they land."
				% [enemy.archetype.display_name, attack_style]
			)
	_tutorial_step_counter.text = "%02d / %02d" % [
		_tutorial_step + 1,
		TUTORIAL_STEPS.size(),
	]
	_tutorial_start_button.text = (
		"START RUN" if _tutorial_step == TUTORIAL_STEPS.size() - 1 else "NEXT"
	)
	var focus_rect := _get_tutorial_focus_rect(str(step["target"]))
	focus_rect.position = focus_rect.position.clamp(
		Vector2(8.0, 8.0),
		Vector2(1272.0 - focus_rect.size.x, 712.0 - focus_rect.size.y)
	)
	_tutorial_focus_frame.position = focus_rect.position
	_tutorial_focus_frame.size = focus_rect.size
	_tutorial_focus_frame.visible = true

	var focus_center := focus_rect.get_center()
	var card_x := 48.0 if focus_center.x >= 640.0 else 762.0
	var card_y := 118.0 if focus_center.y >= 360.0 else 430.0
	_tutorial_card.position = Vector2(card_x, card_y)
	var card_rect := Rect2(_tutorial_card.position, _tutorial_card.size)
	var line_start := Vector2(
		clampf(focus_center.x, card_rect.position.x, card_rect.end.x),
		clampf(focus_center.y, card_rect.position.y, card_rect.end.y)
	)
	var direction := (focus_center - line_start).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	_tutorial_pointer_line.points = PackedVector2Array([line_start, focus_center])
	_tutorial_pointer_head.position = focus_center
	_tutorial_pointer_head.rotation = direction.angle() + PI


func _get_tutorial_focus_rect(target: String) -> Rect2:
	match target:
		"health":
			var health_label := _stage.find_child("HealthValue", true, false) as Control
			if health_label != null:
				var rect := _control_rect_in_design_canvas(health_label)
				return Rect2(rect.position + Vector2(-380.0, -5.0), Vector2(510.0, 80.0))
		"player":
			return _world_node_focus_rect(_stage.get_node("Player") as Node2D, Vector2(116.0, 144.0))
		"switch":
			return _action_focus_rect("switch", Vector2(112.0, 112.0))
		"dash":
			return _action_focus_rect("dodge", Vector2(112.0, 112.0))
		"interact":
			return _action_focus_rect("interact", Vector2(106.0, 106.0))
		"enemy":
			var room := _stage.get_current_room()
			var enemy := room.get_node_or_null("Enemies/Enemy01") as Node2D if room != null else null
			if enemy != null:
				return _world_node_focus_rect(enemy, Vector2(128.0, 150.0))
		"exit":
			var room := _stage.get_current_room()
			var exit_door := room.get_node_or_null("WorldGeometry/ExitDoor") as Node2D if room != null else null
			if exit_door != null:
				return _world_node_focus_rect(exit_door, Vector2(138.0, 110.0))
	return Rect2(Vector2(560.0, 280.0), Vector2(160.0, 160.0))


func _action_focus_rect(action: String, dimensions: Vector2) -> Rect2:
	var touch_controls := _stage.find_child("TouchControls", true, false) as TouchControls
	if touch_controls == null:
		return Rect2(Vector2(560.0, 280.0), dimensions)
	var action_centers: Dictionary = touch_controls.get_action_centers()
	var viewport_center: Vector2 = action_centers.get(action, Vector2(640.0, 360.0))
	var layout := get_design_canvas_layout_for_size(get_viewport_rect().size)
	var offset: Vector2 = layout["offset"]
	var center := (viewport_center - offset) / float(layout["scale"])
	return Rect2(center - dimensions * 0.5, dimensions)


func _world_node_focus_rect(node: Node2D, dimensions: Vector2) -> Rect2:
	if node == null:
		return Rect2(Vector2(560.0, 280.0), dimensions)
	var viewport_position := get_viewport().get_canvas_transform() * node.global_position
	var layout := get_design_canvas_layout_for_size(get_viewport_rect().size)
	var offset: Vector2 = layout["offset"]
	var center := (viewport_position - offset) / float(layout["scale"])
	return Rect2(center - dimensions * 0.5, dimensions)


func _control_rect_in_design_canvas(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var layout := get_design_canvas_layout_for_size(get_viewport_rect().size)
	var scale_factor := float(layout["scale"])
	var offset: Vector2 = layout["offset"]
	return Rect2(
		(rect.position - offset) / scale_factor,
		rect.size / scale_factor
	)


func _show_profile_screen() -> void:
	_clear_stage()
	_clear_overlay()
	_clear_screen()
	_tutorial_panel.visible = false
	_tutorial_button.visible = false
	_profile_button.visible = false
	_profile_root.visible = true
	_profile_status.text = ""
	_profile_username.clear()
	_refresh_profile_options()
	_audio_manager.set_music_theme("menu")


func _refresh_profile_options() -> void:
	_profile_selector.clear()
	var profiles := _run_manager.get_profiles()
	if profiles.is_empty():
		_profile_selector.add_item("NO SAVED PROFILES")
		_profile_continue_button.disabled = true
		return

	_profile_continue_button.disabled = false
	var selected_index := 0
	for index in profiles.size():
		_profile_selector.add_item(profiles[index])
		if profiles[index] == _run_manager.active_profile_name:
			selected_index = index
	_profile_selector.select(selected_index)


func _continue_selected_profile() -> void:
	var selected_index := _profile_selector.selected
	if selected_index < 0 or selected_index >= _profile_selector.item_count:
		_profile_status.text = "Select a saved profile first."
		return
	var username := _profile_selector.get_item_text(selected_index)
	if not _run_manager.select_profile(username):
		_profile_status.text = "That profile could not be loaded. Please try again."
		return
	show_title_screen()


func _create_profile() -> void:
	var username := _profile_username.text.strip_edges()
	var validation_error := _run_manager.validate_profile_name(username)
	if not validation_error.is_empty():
		_profile_status.text = validation_error
		return
	if not _run_manager.create_profile(username):
		_profile_status.text = "The profile could not be saved. Check available storage and try again."
		return
	show_title_screen()


func _on_profile_name_submitted(_username: String) -> void:
	_create_profile()


func _clear_overlay() -> void:
	if _overlay_layer != null and is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
	_overlay_layer = null


func _toggle_pause() -> void:
	if _is_paused:
		_resume_run_audio()
		_clear_pause_screen()
		get_tree().paused = false
		_audio_manager.play_sfx("ui")
		return

	if _stage == null or _pause_layer != null:
		return

	_is_paused = true
	get_tree().paused = true
	_audio_manager.set_gameplay_paused(true)

	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseMenu"
	_pause_layer.layer = 20
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	_pause_root = Control.new()
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_pause_root.size = Vector2(1280.0, 720.0)
	_pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_layer.add_child(_pause_root)
	_fit_design_canvas(_pause_root)
	_show_pause_menu()


func _show_pause_menu() -> void:
	if _pause_root == null or not is_instance_valid(_pause_root):
		return
	_clear_control_children(_pause_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.03, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(shade)
	var panel := _make_panel(_pause_root, Vector2(390, 158), Vector2(500, 404))
	var content := _panel_content(panel)
	_add_label(content, "RUN PAUSED", Vector2(30, 35), Vector2(440, 64), 38, Color("f0efe2"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(content, "THE FACILITY IS WAITING.", Vector2(30, 104), Vector2(440, 36), 15, Color("c5a18e"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_button(content, "RESUME RUN  /  ESC", Vector2(40, 164), Vector2(420, 54), Color("315b4d"), _toggle_pause)
	_add_button(content, "SETTINGS", Vector2(40, 228), Vector2(420, 54), Color("293c3d"), _show_settings.bind(true))
	_add_button(content, "RETURN TO MAIN MENU", Vector2(40, 292), Vector2(420, 54), Color("67433a"), _show_abandon_confirmation)
	_add_label(
		content,
		"Leaving ends this attempt and records a defeat.",
		Vector2(40, 354),
		Vector2(420, 32),
		12,
		Color("c5a18e"),
		HORIZONTAL_ALIGNMENT_CENTER
	)


func _show_pause_settings() -> void:
	if _pause_root == null or not is_instance_valid(_pause_root):
		return
	_clear_control_children(_pause_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.03, 0.92)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(shade)
	var panel := _make_panel(_pause_root, Vector2(360, 140), Vector2(560, 440))
	var content := _panel_content(panel)
	_add_label(content, "SETTINGS", Vector2(45, 32), Vector2(470, 64), 40, Color("f0efe2"), HORIZONTAL_ALIGNMENT_CENTER)
	_build_audio_settings(content, 130.0)
	_add_button(content, "BACK TO PAUSE MENU", Vector2(48, 360), Vector2(464, 54), Color("315b4d"), _leave_pause_settings)


func _leave_pause_settings() -> void:
	_run_manager.save_settings()
	_show_pause_menu()


func _show_abandon_confirmation() -> void:
	if _pause_root == null or not is_instance_valid(_pause_root):
		return
	var dialog := Control.new()
	dialog.name = "AbandonConfirmation"
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.z_index = 5
	_pause_root.add_child(dialog)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.02, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.add_child(shade)
	var panel := _make_panel(dialog, Vector2(356, 188), Vector2(568, 344))
	var content := _panel_content(panel)
	_add_label(content, "LEAVE THIS RUN?", Vector2(24, 34), Vector2(520, 48), 28, Color("f0efe2"), HORIZONTAL_ALIGNMENT_CENTER)
	var description := _add_label(
		content,
		"Leaving ends the attempt as a defeat.\nYou get 10 scrap and record this survivor as an echo.",
		Vector2(52, 96),
		Vector2(464, 86),
		15,
		Color("c5a18e"),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	description.name = "AbandonDescription"
	_add_button(content, "STAY IN THE DUNGEON", Vector2(46, 220), Vector2(224, 56), Color("315b4d"), _show_pause_menu)
	_add_button(content, "LEAVE RUN", Vector2(294, 220), Vector2(224, 56), Color("67433a"), _confirm_return_to_menu)


func _confirm_return_to_menu() -> void:
	_return_to_menu_after_abandon = true
	_abandon_run()


func _abandon_run() -> void:
	if _stage == null:
		return
	_resume_run_audio()
	_clear_pause_screen()
	get_tree().paused = false
	_stage.call("_finish_run", false)


func _resume_run_audio() -> void:
	if _audio_manager != null:
		_audio_manager.set_gameplay_paused(false)


func _clear_pause_screen() -> void:
	_is_paused = false
	if _pause_layer != null and is_instance_valid(_pause_layer):
		_pause_layer.queue_free()
	_pause_layer = null
	_pause_root = null


func _clear_stage() -> void:
	if _stage != null and is_instance_valid(_stage):
		_stage.end_run()
		_stage.visible = false
	_stage = null


func _add_label(
	parent: Control,
	text: String,
	position: Vector2,
	dimensions: Vector2,
	font_size: int,
	color: Color,
	alignment: int = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = dimensions
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _panel_content(panel: PanelContainer) -> Control:
	var content := Control.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.clip_contents = true
	panel.add_child(content)
	return content


func _clear_control_children(control: Control) -> void:
	for child in control.get_children():
		control.remove_child(child)
		child.queue_free()


func _refresh_responsive_layout() -> void:
	if _screen_root != null and is_instance_valid(_screen_root):
		_fit_design_canvas(_screen_root)
	_fit_design_canvas(_tutorial_root)
	_fit_design_canvas(_profile_root)
	if _pause_root != null and is_instance_valid(_pause_root):
		_fit_design_canvas(_pause_root)


func _fit_design_canvas(control: Control) -> void:
	var layout := get_design_canvas_layout_for_size(get_viewport_rect().size)
	control.scale = Vector2.ONE * float(layout["scale"])
	control.position = layout["offset"]


func get_design_canvas_layout_for_size(viewport_size: Vector2) -> Dictionary:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var scale_factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	return {
		"scale": scale_factor,
		"offset": (viewport_size - Vector2(1280.0, 720.0) * scale_factor) * 0.5,
	}


func _add_button(
	parent: Control,
	text: String,
	position: Vector2,
	dimensions: Vector2,
	_color: Color,
	action: Callable
) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 13)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", Color("f0efe2"))
	button.add_theme_color_override("font_hover_color", Color("ff7080"))
	button.add_theme_color_override("font_disabled_color", Color("81777c"))
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_stylebox_override("normal", _button_style(Color("170f13"), Color("56303b"), 0))
	button.add_theme_stylebox_override("hover", _button_style(Color("28131a"), Color("ff5366"), 0))
	button.add_theme_stylebox_override("pressed", _button_style(Color("3a1520"), Color("c64054"), 0))
	button.add_theme_stylebox_override("disabled", _button_style(Color("1d191d"), Color("40343a"), 0))
	button.add_theme_stylebox_override("focus", _button_style(Color("170f13"), Color("ff5366"), 0))
	button.pressed.connect(func() -> void: _audio_manager.play_sfx("ui"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _make_panel(parent: Control, position: Vector2, dimensions: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.012, 0.022, 1.0)
	style.border_color = Color("69404b")
	style.set_border_width_all(1)
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.78)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _button_style(background: Color, outline: Color, corner_radius: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(1)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


func _button_style_with_left_margin(
	background: Color,
	outline: Color,
	left_margin: float
) -> StyleBoxFlat:
	var style := _button_style(background, outline, 0)
	style.content_margin_left = left_margin
	return style
