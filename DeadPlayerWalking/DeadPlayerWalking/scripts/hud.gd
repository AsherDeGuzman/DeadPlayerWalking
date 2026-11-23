extends CanvasLayer

const TOP_HUD_ART := preload("res://ASSETS/UI ASSETS/Top HUD@2x.png")
const FLOOR_TRANSITION_ART := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 42 — Floor transition effect.png")
const WEAPON_ICON_ATLAS := preload("res://ASSETS/WEAPON ASSETS/Asset 16 — Weapon inventory icons.png")
const TOP_HUD_REGION := Rect2(0.0, 0.0, 2548.0, 246.0)
const WEAPON_ICON_REGIONS := {
	&"dungeon_edge": Rect2(0.0, 0.0, 887.0, 887.0),
	&"warden_crossbow": Rect2(887.0, 0.0, 887.0, 887.0),
}
const HUD_BACKGROUND_COLOR := Color("080508")

signal attack_pressed
signal weapon_switch_pressed
signal dodge_pressed
signal interact_pressed
signal pause_pressed

var _health_label: Label
var _points_label: Label
var _floor_number_label: Label
var _floor_name_label: Label
var _room_number_label: Label
var _floor_number_backdrop: ColorRect
var _floor_name_backdrop: ColorRect
var _room_number_backdrop: ColorRect
var _zone_status_label: Label
var _zone_status_backdrop: ColorRect
var _weapon_label: Label
var _weapon_name_backdrop: ColorRect
var _weapon_icon: TextureRect
var _weapon_icon_backdrop: ColorRect
var _touch_controls: TouchControls
var _screen: Control
var _boss_panel: Control
var _boss_fill: ColorRect
var _boss_label: Label
var _hud_root: Control
var _pause_button: Button
var _top_hud_art: TextureRect
var _health_track: Polygon2D
var _health_segments: Array[ColorRect] = []
var _health_segment_width := 0.0
var _health_value_backdrop: ColorRect
var _points_value_backdrop: ColorRect
var _boss_track: ColorRect
var _health_ratio := 1.0
var _boss_health_ratio := 1.0
var _zone_status_seconds_remaining := 0.0
@onready var _floor_transition := $UI/Screen/FloorTransition as Control
@onready var _transition_backdrop := $UI/Screen/FloorTransition/Backdrop as ColorRect
@onready var _transition_portal := $UI/Screen/FloorTransition/PortalEffect as TextureRect
@onready var _transition_top := $UI/Screen/FloorTransition/TopCurtain as ColorRect
@onready var _transition_bottom := $UI/Screen/FloorTransition/BottomCurtain as ColorRect
@onready var _transition_title := $UI/Screen/FloorTransition/FloorTitle as Label
@onready var _transition_subtitle := $UI/Screen/FloorTransition/FloorSubtitle as Label


func _ready() -> void:
	layer = 2
	_screen = $UI/Screen as Control
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_transition.visible = false
	_transition_portal.texture = FLOOR_TRANSITION_ART
	_transition_portal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_transition_portal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_transition_portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_transition_title.add_theme_font_size_override("font_size", 34)
	_transition_title.add_theme_color_override("font_color", Color("f6e8df"))
	_transition_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_transition_subtitle.add_theme_font_size_override("font_size", 15)
	_transition_subtitle.add_theme_color_override("font_color", Color("ff6878"))

	_hud_root = Control.new()
	_hud_root.position = Vector2.ZERO
	_hud_root.size = Vector2(1280, 112)
	_hud_root.name = "HudRoot"
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_hud_root)
	_top_hud_art = _create_top_hud_art()
	_top_hud_art.name = "TopHudArtwork"
	_hud_root.add_child(_top_hud_art)

	_floor_number_backdrop = _create_hud_backdrop("FloorNumberBackdrop")
	_hud_root.add_child(_floor_number_backdrop)
	_floor_name_backdrop = _create_hud_backdrop("FloorNameBackdrop")
	_hud_root.add_child(_floor_name_backdrop)
	_room_number_backdrop = _create_hud_backdrop("RoomNumberBackdrop")
	_hud_root.add_child(_room_number_backdrop)
	_weapon_name_backdrop = _create_hud_backdrop("WeaponNameBackdrop")
	_hud_root.add_child(_weapon_name_backdrop)
	_health_value_backdrop = _create_hud_backdrop("HealthValueBackdrop")
	_hud_root.add_child(_health_value_backdrop)
	_points_value_backdrop = _create_hud_backdrop("ScrapValueBackdrop")
	_hud_root.add_child(_points_value_backdrop)

	_floor_number_label = _create_hud_value("FloorNumber", "01", 20, Color("f2edf0"))
	_hud_root.add_child(_floor_number_label)
	_floor_name_label = _create_hud_value("FloorName", "UPPER\nDUNGEON", 14, Color("f2edf0"))
	_floor_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_root.add_child(_floor_name_label)
	_room_number_label = _create_hud_value("RoomNumber", "01/02", 12, Color("d1c9cf"))
	_room_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_root.add_child(_room_number_label)

	_zone_status_backdrop = ColorRect.new()
	_zone_status_backdrop.name = "ZoneStatusBackdrop"
	_zone_status_backdrop.color = HUD_BACKGROUND_COLOR
	_zone_status_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone_status_backdrop.visible = false
	_hud_root.add_child(_zone_status_backdrop)
	_zone_status_label = _create_hud_value("ZoneStatus", "", 13, Color("f1e9ed"))
	_zone_status_label.visible = false
	_hud_root.add_child(_zone_status_label)

	_weapon_icon_backdrop = _create_hud_backdrop("WeaponIconBackdrop")
	_hud_root.add_child(_weapon_icon_backdrop)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = ""
	_pause_button.tooltip_text = "Pause the run"
	var pause_style := StyleBoxEmpty.new()
	_pause_button.add_theme_stylebox_override("normal", pause_style)
	_pause_button.add_theme_stylebox_override("hover", pause_style)
	_pause_button.add_theme_stylebox_override("pressed", pause_style)
	_pause_button.add_theme_stylebox_override("focus", pause_style)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_hud_root.add_child(_pause_button)

	_health_track = Polygon2D.new()
	_health_track.name = "HealthTrack"
	_health_track.color = Color("260d13")
	_hud_root.add_child(_health_track)
	for segment_index in range(10):
		var segment := ColorRect.new()
		segment.name = "HealthSegment%02d" % segment_index
		segment.color = Color("ed3e53")
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_root.add_child(segment)
		_health_segments.append(segment)

	_health_label = _create_hud_value("HealthValue", "100 / 100", 18, Color("eee9ec"))
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_root.add_child(_health_label)
	_points_label = _create_hud_value("ScrapValue", "0", 28, Color("ffd28d"))
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_root.add_child(_points_label)

	_weapon_label = _create_hud_value("WeaponName", "DUNGEON EDGE", 12, Color("e8dfe4"))
	_hud_root.add_child(_weapon_label)
	_weapon_icon = TextureRect.new()
	_weapon_icon.name = "WeaponIcon"
	_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(_weapon_icon)

	_boss_panel = PanelContainer.new()
	_boss_panel.name = "BossHealth"
	_boss_panel.position = Vector2(390, 104)
	_boss_panel.size = Vector2(500, 58)
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.visible = false
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Color(0.025, 0.014, 0.021, 0.96)
	boss_style.border_color = Color("69404b")
	boss_style.set_border_width_all(1)
	_boss_panel.add_theme_stylebox_override("panel", boss_style)
	_screen.add_child(_boss_panel)
	var boss_content := Control.new()
	boss_content.name = "Content"
	boss_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_content.clip_contents = true
	_boss_panel.add_child(boss_content)
	_boss_track = ColorRect.new()
	_boss_track.position = Vector2(0, 31)
	_boss_track.size = Vector2(500, 15)
	_boss_track.color = Color("352633")
	_boss_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_content.add_child(_boss_track)
	_boss_fill = ColorRect.new()
	_boss_fill.position = _boss_track.position
	_boss_fill.size = _boss_track.size
	_boss_fill.color = Color("d36c9a")
	_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_content.add_child(_boss_fill)
	_boss_label = _label("", Vector2(0, 0), Vector2(500, 25), 14, Color("f3d9e8"))
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_content.add_child(_boss_label)

	_touch_controls = TouchControls.new()
	_touch_controls.name = "TouchControls"
	_screen.add_child(_touch_controls)
	_touch_controls.attack_pressed.connect(func() -> void: attack_pressed.emit())
	_touch_controls.weapon_switch_pressed.connect(func() -> void: weapon_switch_pressed.emit())
	_touch_controls.dodge_pressed.connect(func() -> void: dodge_pressed.emit())
	_touch_controls.interact_pressed.connect(func() -> void: interact_pressed.emit())
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func set_health(current: int, maximum: int) -> void:
	if _health_label == null:
		return
	var safe_maximum := maxi(1, maximum)
	var safe_current := clampi(current, 0, safe_maximum)
	_health_label.text = "%d / %d" % [safe_current, safe_maximum]
	_health_ratio = clampf(float(current) / float(safe_maximum), 0.0, 1.0)
	_update_health_segments()
	var low_health := _health_ratio <= 0.25
	_health_track.color = Color("4b1721") if low_health else Color("260d13")
	for segment in _health_segments:
		segment.color = Color("ff687b") if low_health else Color("ed3e53")
	_health_label.add_theme_color_override(
		"font_color",
		Color("ff7588") if low_health else Color("eee9ec")
	)


func set_points(value: int) -> void:
	if _points_label != null:
		_points_label.text = str(maxi(0, value))
		_update_points_font_size()


func set_potion_count(count: int) -> void:
	if _touch_controls != null:
		_touch_controls.set_potion_count(count)


func set_zone(title: String) -> void:
	_zone_status_seconds_remaining = 0.0
	var parts := title.split("  ·  ")
	if parts.size() == 3:
		var floor_parts := parts[0].split(" / ")
		var room_parts := parts[2].split(" / ")
		if floor_parts.size() == 2 and room_parts.size() == 2:
			_floor_number_label.text = floor_parts[0].trim_prefix("FLOOR ")
			_floor_name_label.text = parts[1].to_upper()
			_room_number_label.text = "%s/%s" % [
				room_parts[0].trim_prefix("ROOM "),
				room_parts[1],
			]
			_zone_status_backdrop.visible = false
			_zone_status_label.visible = false
			return
	_zone_status_backdrop.visible = true
	_zone_status_label.visible = true
	_zone_status_label.text = title.to_upper()


func show_zone_message(title: String) -> void:
	set_zone(title)
	_zone_status_seconds_remaining = 2.0


func _process(delta: float) -> void:
	if _zone_status_seconds_remaining <= 0.0:
		return
	_zone_status_seconds_remaining = maxf(0.0, _zone_status_seconds_remaining - delta)
	if _zone_status_seconds_remaining == 0.0:
		_zone_status_backdrop.visible = false
		_zone_status_label.visible = false


func _update_points_font_size() -> void:
	var scale_factor := get_viewport().get_visible_rect().size.x / 1280.0
	var point_count_length := maxf(float(_points_label.text.length()), 2.0)
	var font_size := minf(28.0, 74.0 / point_count_length) * scale_factor
	_points_label.add_theme_font_size_override("font_size", maxi(14, roundi(font_size)))


func _update_health_segments() -> void:
	var filled_segments := _health_ratio * float(_health_segments.size())
	for index in range(_health_segments.size()):
		var segment_fill := clampf(filled_segments - float(index), 0.0, 1.0)
		_health_segments[index].size.x = _health_segment_width * segment_fill


func set_boss_health(boss_name: String, current: int, maximum: int) -> void:
	if _boss_panel == null:
		return
	var safe_maximum := maxi(1, maximum)
	_boss_panel.visible = true
	_boss_label.text = "%s  /  %d%%" % [boss_name, roundi(float(current) / float(safe_maximum) * 100.0)]
	_boss_health_ratio = clampf(float(current) / float(safe_maximum), 0.0, 1.0)
	_boss_fill.size.x = _boss_track.size.x * _boss_health_ratio


func hide_boss_health() -> void:
	if _boss_panel != null:
		_boss_panel.visible = false


func is_boss_health_visible() -> bool:
	return _boss_panel != null and _boss_panel.visible


func show_room_transition() -> void:
	_floor_transition.visible = true
	_floor_transition.mouse_filter = Control.MOUSE_FILTER_STOP
	_transition_title.visible = false
	_transition_subtitle.visible = false
	_transition_portal.visible = false
	_transition_backdrop.color = Color(0.008, 0.006, 0.012, 0.0)
	var tween := create_tween()
	tween.tween_property(_transition_backdrop, "color:a", 0.92, 0.16)
	await tween.finished


func hide_room_transition() -> void:
	var tween := create_tween()
	tween.tween_property(_transition_backdrop, "color:a", 0.0, 0.16)
	await tween.finished
	_floor_transition.visible = false
	_floor_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_floor_transition(floor_number: int, floor_name: String) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_layout_floor_transition(viewport_size)
	_floor_transition.visible = true
	_floor_transition.mouse_filter = Control.MOUSE_FILTER_STOP
	_transition_title.visible = true
	_transition_subtitle.visible = true
	_transition_portal.visible = true
	_transition_title.text = "FLOOR %02d  /  %s" % [floor_number, floor_name.to_upper()]
	_transition_subtitle.text = "DESCENDING DEEPER  ·  THE DUNGEON REMEMBERS"
	_transition_backdrop.color = Color(0.008, 0.006, 0.012, 0.0)
	_transition_portal.modulate.a = 0.0
	_transition_portal.scale = Vector2.ONE * 0.72
	_transition_portal.rotation = -0.035
	_transition_title.modulate.a = 0.0
	_transition_subtitle.modulate.a = 0.0
	_transition_top.position.y = -_transition_top.size.y
	_transition_bottom.position.y = viewport_size.y

	var arrival := create_tween().set_parallel(true)
	arrival.tween_property(_transition_backdrop, "color:a", 0.68, 0.48)
	arrival.tween_property(_transition_portal, "modulate:a", 0.92, 0.62)
	arrival.tween_property(_transition_portal, "scale", Vector2.ONE * 1.04, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(_transition_portal, "rotation", 0.012, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(_transition_title, "modulate:a", 1.0, 0.36).set_delay(0.24)
	arrival.tween_property(_transition_subtitle, "modulate:a", 1.0, 0.36).set_delay(0.42)
	arrival.tween_property(_transition_top, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(_transition_bottom, "position:y", viewport_size.y - _transition_bottom.size.y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await arrival.finished

	var hold := create_tween()
	hold.tween_interval(0.32)
	await hold.finished

	var cover := create_tween().set_parallel(true)
	cover.tween_property(_transition_backdrop, "color:a", 1.0, 0.28)
	cover.tween_property(_transition_portal, "modulate:a", 0.0, 0.28)
	cover.tween_property(_transition_title, "modulate:a", 0.0, 0.2)
	cover.tween_property(_transition_subtitle, "modulate:a", 0.0, 0.2)
	await cover.finished


func hide_floor_transition() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(_transition_top, "position:y", -_transition_top.size.y, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	reveal.tween_property(_transition_bottom, "position:y", viewport_size.y, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	reveal.tween_property(_transition_backdrop, "color:a", 0.0, 0.58)
	reveal.tween_property(_transition_portal, "modulate:a", 0.0, 0.4)
	await reveal.finished
	_floor_transition.visible = false
	_floor_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_weapon(display_name: String, weapon_id: StringName) -> void:
	if _weapon_label != null:
		_weapon_label.text = display_name.to_upper()
		_weapon_label.add_theme_color_override(
			"font_color",
			Color("d8cde0") if weapon_id == &"warden_crossbow" else Color("e8dfe4")
		)
	if _weapon_icon != null:
		var icon_texture := AtlasTexture.new()
		icon_texture.atlas = WEAPON_ICON_ATLAS
		icon_texture.region = WEAPON_ICON_REGIONS.get(weapon_id, WEAPON_ICON_REGIONS[&"dungeon_edge"])
		_weapon_icon.texture = icon_texture
	if _touch_controls != null:
		_touch_controls.set_weapon(weapon_id)


func get_touch_controls() -> TouchControls:
	return _touch_controls


func _apply_responsive_layout() -> void:
	if _screen == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := viewport_size.x / 1280.0
	var top_height := viewport_size.x * TOP_HUD_REGION.size.y / TOP_HUD_REGION.size.x
	_hud_root.size = viewport_size
	_top_hud_art.size = Vector2(viewport_size.x, top_height)

	_floor_number_backdrop.position = Vector2(76.0, 17.0) * scale_factor
	_floor_number_backdrop.size = Vector2(28.0, 28.0) * scale_factor
	_floor_number_label.position = Vector2(77.0, 17.0) * scale_factor
	_floor_number_label.size = Vector2(26.0, 28.0) * scale_factor
	_floor_number_label.add_theme_font_size_override("font_size", roundi(20.0 * scale_factor))
	_floor_name_backdrop.position = Vector2(151.0, 8.0) * scale_factor
	_floor_name_backdrop.size = Vector2(87.0, 46.0) * scale_factor
	_floor_name_label.position = Vector2(153.0, 9.0) * scale_factor
	_floor_name_label.size = Vector2(83.0, 44.0) * scale_factor
	_floor_name_label.add_theme_font_size_override("font_size", maxi(10, roundi(14.0 * scale_factor)))
	_room_number_backdrop.position = Vector2(386.0, 22.0) * scale_factor
	_room_number_backdrop.size = Vector2(39.0, 23.0) * scale_factor
	_room_number_label.position = Vector2(387.0, 22.0) * scale_factor
	_room_number_label.size = Vector2(38.0, 23.0) * scale_factor
	_room_number_label.add_theme_font_size_override("font_size", maxi(9, roundi(12.0 * scale_factor)))
	_zone_status_backdrop.position = Vector2(25.0, 12.0) * scale_factor
	_zone_status_backdrop.size = Vector2(411.0, 44.0) * scale_factor
	_zone_status_label.position = Vector2(30.0, 13.0) * scale_factor
	_zone_status_label.size = Vector2(401.0, 42.0) * scale_factor
	_zone_status_label.add_theme_font_size_override("font_size", maxi(10, roundi(13.0 * scale_factor)))
	_weapon_icon_backdrop.position = Vector2(27.0, 58.0) * scale_factor
	_weapon_icon_backdrop.size = Vector2(33.0, 32.0) * scale_factor
	_weapon_icon.position = Vector2(29.0, 60.0) * scale_factor
	_weapon_icon.size = Vector2(29.0, 28.0) * scale_factor
	_weapon_name_backdrop.position = Vector2(64.0, 58.0) * scale_factor
	_weapon_name_backdrop.size = Vector2(360.0, 32.0) * scale_factor
	_weapon_label.position = Vector2(136.0, 64.0) * scale_factor
	_weapon_label.size = Vector2(270.0, 23.0) * scale_factor
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_weapon_label.add_theme_font_size_override("font_size", maxi(1, roundi(12.0 * scale_factor)))
	_health_value_backdrop.position = Vector2(807.0, 20.0) * scale_factor
	_health_value_backdrop.size = Vector2(105.0, 34.0) * scale_factor
	_health_label.position = Vector2(808.0, 20.0) * scale_factor
	_health_label.size = Vector2(103.0, 34.0) * scale_factor
	_health_label.add_theme_font_size_override("font_size", maxi(12, roundi(18.0 * scale_factor)))
	_points_value_backdrop.position = Vector2(1117.0, 53.0) * scale_factor
	_points_value_backdrop.size = Vector2(47.0, 43.0) * scale_factor
	_points_label.position = Vector2(1117.0, 53.0) * scale_factor
	_points_label.size = Vector2(47.0, 43.0) * scale_factor
	_update_points_font_size()

	var bar_scale := scale_factor
	_health_track.polygon = PackedVector2Array([
		Vector2(510.0, 80.0) * bar_scale,
		Vector2(519.0, 64.0) * bar_scale,
		Vector2(917.0, 64.0) * bar_scale,
		Vector2(927.0, 80.0) * bar_scale,
		Vector2(917.0, 96.0) * bar_scale,
		Vector2(519.0, 96.0) * bar_scale,
	])
	var segment_gap := 2.0 * bar_scale
	_health_segment_width = (402.0 * bar_scale - segment_gap * 9.0) / 10.0
	for index in range(_health_segments.size()):
		var segment := _health_segments[index]
		segment.position = Vector2(
			516.0 * bar_scale + float(index) * (_health_segment_width + segment_gap),
			66.0 * bar_scale
		)
		segment.size = Vector2(_health_segment_width, 28.0 * bar_scale)
	_update_health_segments()

	_pause_button.position = Vector2(1194.0, 25.0) * scale_factor
	_pause_button.size = Vector2(62.0, 70.0) * scale_factor
	_boss_panel.position = Vector2((viewport_size.x - 500.0 * scale_factor) * 0.5, top_height + 8.0 * scale_factor)
	_boss_panel.size = Vector2(500.0 * scale_factor, 58.0 * scale_factor)
	_boss_track.size = Vector2(_boss_panel.size.x, 15.0 * scale_factor)
	_boss_fill.position = _boss_track.position
	_boss_fill.size = Vector2(_boss_track.size.x * _boss_health_ratio, _boss_track.size.y)
	_boss_label.size = Vector2(_boss_panel.size.x, 25.0 * scale_factor)
	_boss_label.add_theme_font_size_override("font_size", roundi(14.0 * scale_factor))
	_touch_controls.queue_redraw()
	_layout_floor_transition(viewport_size)


func _layout_floor_transition(viewport_size: Vector2) -> void:
	var curtain_height := 112.0
	_transition_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_portal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_transition_bottom.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_transition_title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_transition_subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_transition_top.size = Vector2(viewport_size.x, curtain_height)
	_transition_bottom.size = Vector2(viewport_size.x, curtain_height)
	_transition_portal.position = Vector2.ZERO
	_transition_portal.size = viewport_size
	_transition_portal.pivot_offset = viewport_size * 0.5
	_transition_title.size = Vector2(minf(viewport_size.x - 48.0, 1000.0), 52.0)
	_transition_title.position = Vector2((viewport_size.x - _transition_title.size.x) * 0.5, viewport_size.y * 0.43)
	_transition_subtitle.size = Vector2(minf(viewport_size.x - 48.0, 920.0), 34.0)
	_transition_subtitle.position = Vector2((viewport_size.x - _transition_subtitle.size.x) * 0.5, viewport_size.y * 0.43 + 56.0)


func _create_top_hud_art() -> TextureRect:
	var artwork := TextureRect.new()
	var atlas_region := AtlasTexture.new()
	atlas_region.atlas = TOP_HUD_ART
	atlas_region.region = TOP_HUD_REGION
	artwork.texture = atlas_region
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return artwork


func _create_hud_backdrop(node_name: String) -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.name = node_name
	backdrop.color = HUD_BACKGROUND_COLOR
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return backdrop


func _create_hud_value(
	node_name: String,
	text: String,
	font_size: int,
	color: Color
) -> Label:
	var value := _label(text, Vector2.ZERO, Vector2.ZERO, font_size, color)
	value.name = node_name
	return value


func _label(text: String, position: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
