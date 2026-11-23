extends Control
class_name TouchControls

signal attack_pressed
signal weapon_switch_pressed
signal dodge_pressed
signal interact_pressed
signal target_tapped(screen_position: Vector2)

const JOYSTICK_RADIUS := 66.0
const JOYSTICK_HIT_RADIUS := 102.0
const HEALING_POTION_ICON := preload("res://ASSETS/PICKUPS AND GAMEPLAY ASSETS/Asset 34 — Healing pickup.png")

var _movement_finger := -1
var _movement_position := Vector2.ZERO
var _mouse_movement_held := false
var _keyboard_movement := Vector2.ZERO
var _potion_count := 0
var _dash_cooldown_remaining := 0.0
var _dash_cooldown_duration := 3.0
var _pressed_action := ""
var _action_finger := -1
var _joystick_art: Texture2D
var _action_art: Texture2D
var _attack_label := "STRIKE"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_art = load("res://ASSETS/UI ASSETS/Asset 44 — Mobile joystick.png") as Texture2D
	_action_art = load("res://ASSETS/UI ASSETS/Asset 45 — Mobile action buttons.png") as Texture2D
	get_viewport().size_changed.connect(queue_redraw)
	if _joystick_art == null or _action_art == null:
		push_error("Could not load the supplied mobile-control artwork.")


func get_movement_vector() -> Vector2:
	if _movement_finger == -1 and not _mouse_movement_held:
		return Vector2.ZERO
	var center := _joystick_center()
	return ((_movement_position - center) / (JOYSTICK_RADIUS * _layout_scale())).limit_length(1.0)


func set_keyboard_movement(movement: Vector2) -> void:
	var normalized_movement := movement.limit_length(1.0)
	if _keyboard_movement.is_equal_approx(normalized_movement):
		return
	_keyboard_movement = normalized_movement
	queue_redraw()


func set_potion_count(count: int) -> void:
	_potion_count = maxi(0, count)
	queue_redraw()


func get_interact_icon() -> Texture2D:
	return HEALING_POTION_ICON if _potion_count > 0 else null


func set_dash_cooldown(remaining: float, duration: float) -> void:
	var safe_duration := maxf(duration, 0.01)
	var safe_remaining := clampf(remaining, 0.0, safe_duration)
	if (
		is_equal_approx(_dash_cooldown_remaining, safe_remaining)
		and is_equal_approx(_dash_cooldown_duration, safe_duration)
	):
		return
	_dash_cooldown_remaining = safe_remaining
	_dash_cooldown_duration = safe_duration
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_handle_press(touch.position, touch.index)
		else:
			_handle_release(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _movement_finger:
			_movement_position = drag.position
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed:
			_handle_press(mouse_button.position, -2)
		else:
			_handle_release(-2)
	elif event is InputEventMouseMotion and _mouse_movement_held:
		_movement_position = (event as InputEventMouseMotion).position
		queue_redraw()


func _handle_press(position: Vector2, finger: int) -> void:
	var scale_factor := _layout_scale()
	if position.distance_to(_joystick_center()) <= JOYSTICK_HIT_RADIUS * scale_factor and _movement_finger == -1:
		_movement_finger = finger
		_movement_position = position
		_mouse_movement_held = finger == -2
		queue_redraw()
		return

	if position.distance_to(_attack_center()) <= 56.0 * scale_factor:
		_pressed_action = "attack"
		_action_finger = finger
		attack_pressed.emit()
	elif position.distance_to(_weapon_switch_center()) <= 42.0 * scale_factor:
		_pressed_action = "weapon_switch"
		_action_finger = finger
		weapon_switch_pressed.emit()
	elif position.distance_to(_dodge_center()) <= 53.0 * scale_factor:
		_pressed_action = "dodge"
		_action_finger = finger
		dodge_pressed.emit()
	elif position.distance_to(_interact_center()) <= 43.0 * scale_factor:
		_pressed_action = "interact"
		_action_finger = finger
		interact_pressed.emit()
	else:
		target_tapped.emit(position)
	queue_redraw()


func _handle_release(finger: int) -> void:
	if finger == _movement_finger:
		_movement_finger = -1
		_mouse_movement_held = false
		_movement_position = Vector2.ZERO
	if finger == _action_finger:
		_pressed_action = ""
		_action_finger = -1
	queue_redraw()


func _joystick_center() -> Vector2:
	return _joystick_center_for_size(get_viewport_rect().size)


func _joystick_center_for_size(viewport_size: Vector2) -> Vector2:
	var scale_factor := _layout_scale_for_size(viewport_size)
	return Vector2(maxf(116.0 * scale_factor, viewport_size.x * 0.14), viewport_size.y - 132.0 * scale_factor)


func _attack_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _layout_scale_for_size(viewport_size)
	return Vector2(viewport_size.x - 145.0 * scale_factor, viewport_size.y - 130.0 * scale_factor)


func _dodge_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _layout_scale_for_size(viewport_size)
	return Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 205.0 * scale_factor)


func _weapon_switch_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _layout_scale_for_size(viewport_size)
	return Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 315.0 * scale_factor)


func _interact_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _layout_scale_for_size(viewport_size)
	return Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 90.0 * scale_factor)


func _layout_scale() -> float:
	return _layout_scale_for_size(get_viewport_rect().size)


func _layout_scale_for_size(viewport_size: Vector2) -> float:
	return clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.72, 1.35)


func get_action_centers() -> Dictionary:
	return get_action_centers_for_size(get_viewport_rect().size)


func get_action_centers_for_size(viewport_size: Vector2) -> Dictionary:
	var scale_factor := _layout_scale_for_size(viewport_size)
	return {
		"joystick": _joystick_center_for_size(viewport_size),
		"attack": Vector2(viewport_size.x - 145.0 * scale_factor, viewport_size.y - 130.0 * scale_factor),
		"switch": Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 315.0 * scale_factor),
		"dodge": Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 205.0 * scale_factor),
		"interact": Vector2(viewport_size.x - 72.0 * scale_factor, viewport_size.y - 90.0 * scale_factor),
	}


func set_weapon(weapon_id: StringName) -> void:
	_attack_label = "BOLT" if weapon_id == &"warden_crossbow" else "STRIKE"
	queue_redraw()


func _get_joystick_knob_position() -> Vector2:
	var center := _joystick_center()
	var joystick_radius := JOYSTICK_RADIUS * _layout_scale()
	if _movement_finger != -1 or _mouse_movement_held:
		return center + (_movement_position - center).limit_length(joystick_radius)
	return center + _keyboard_movement * joystick_radius


func _draw() -> void:
	var scale_factor := _layout_scale()
	var joystick_radius := JOYSTICK_RADIUS * scale_factor
	var center := _joystick_center()
	var knob_position := _get_joystick_knob_position()

	if _joystick_art != null:
		draw_texture_rect_region(
			_joystick_art,
			Rect2(center - Vector2.ONE * joystick_radius, Vector2.ONE * joystick_radius * 2.0),
			Rect2(0.0, 0.0, 860.0, 860.0)
		)
		var knob_region := Rect2(1070.0, 178.0, 466.0, 530.0)
		var knob_size := 49.0 * scale_factor
		draw_texture_rect_region(
			_joystick_art,
			Rect2(knob_position - Vector2.ONE * knob_size * 0.5, Vector2.ONE * knob_size),
			knob_region
		)

	_draw_action(_attack_center(), 62.0 * scale_factor, _attack_label, "attack", _pressed_action == "attack")
	_draw_action(_weapon_switch_center(), 48.0 * scale_factor, "SWAP", "switch", _pressed_action == "weapon_switch")
	_draw_action(_dodge_center(), 48.0 * scale_factor, "DASH", "dodge", _pressed_action == "dodge")
	var interact_label := str(_potion_count) if _potion_count > 0 else ""
	_draw_action(_interact_center(), 43.0 * scale_factor, interact_label, "interact", _pressed_action == "interact")


func _draw_action(center: Vector2, radius: float, title: String, action: String, pressed: bool) -> void:
	var font := ThemeDB.fallback_font
	if action == "interact":
		draw_circle(center, radius, Color("36212a") if pressed else Color("190f14"))
		draw_arc(center, radius, 0.0, TAU, 32, Color("ff5366"), 2.0, true)
		var potion_icon := get_interact_icon()
		if potion_icon != null:
			var icon_size := radius * 1.32
			draw_texture_rect(
				potion_icon,
				Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size),
				false,
				Color("ffc06e") if pressed else Color.WHITE
			)
			var badge_radius := radius * 0.31
			var badge_center := center + Vector2(radius * 0.6, -radius * 0.6)
			draw_circle(badge_center, badge_radius, Color("100b10"))
			draw_arc(badge_center, badge_radius, 0.0, TAU, 24, Color("ff5366"), 1.5, true)
			var badge_width := badge_radius * 2.0
			draw_string(
				font,
				Vector2(badge_center.x - badge_width * 0.5, badge_center.y + badge_radius * 0.38),
				title,
				HORIZONTAL_ALIGNMENT_CENTER,
				badge_width,
				maxi(8, roundi(radius * 0.24)),
				Color("fff3db")
			)
		return

	if _action_art != null and action != "interact":
		var source := Rect2(220.0, 0.0, 550.0, 500.0)
		if action == "switch":
			source = Rect2(220.0, 520.0, 550.0, 490.0)
		elif action == "dodge":
			source = Rect2(800.0, 520.0, 520.0, 490.0)
		elif title == "BOLT":
			source = Rect2(800.0, 0.0, 520.0, 500.0)
		var icon_size := Vector2.ONE * radius * 1.48
		var tint := Color("f5f5e9") if not pressed else Color("ffc06e")
		draw_texture_rect_region(
			_action_art,
			Rect2(center - Vector2(icon_size.x * 0.5, icon_size.y * 0.5 + 6.0), icon_size),
			source,
			tint
		)
		_draw_action_label(center, radius, title, font)
	else:
		draw_circle(center, radius, Color("190f14"))
		draw_arc(center, radius, 0.0, TAU, 32, Color("ff5366"), 2.0, true)
		_draw_action_label(center, radius, title, font)
	if action == "dodge" and _dash_cooldown_remaining > 0.0:
		_draw_dash_cooldown(center, radius, font)


func _draw_action_label(center: Vector2, radius: float, title: String, font: Font) -> void:
	var label_width := radius * 1.8
	draw_string(
		font,
		Vector2(center.x - label_width * 0.5, center.y + radius * 0.72),
		title,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		maxi(8, roundi(radius * 0.2)),
		Color("f5f5e9")
	)


func _draw_dash_cooldown(center: Vector2, radius: float, font: Font) -> void:
	var cooldown_ratio := clampf(
		_dash_cooldown_remaining / _dash_cooldown_duration,
		0.0,
		1.0
	)
	draw_circle(center, radius * 0.55, Color(0.025, 0.035, 0.035, 0.76))
	draw_arc(
		center,
		radius * 0.88,
		0.0,
		TAU,
		32,
		Color(0.05, 0.07, 0.07, 0.9),
		maxf(2.0, radius * 0.07),
		true
	)
	draw_arc(
		center,
		radius * 0.88,
		-PI * 0.5,
		-PI * 0.5 + TAU * cooldown_ratio,
		32,
		Color("ffc06e"),
		maxf(2.0, radius * 0.07),
		true
	)
	draw_string(
		font,
		center + Vector2(-radius * 0.5, 5.0),
		"%.1f" % _dash_cooldown_remaining,
		HORIZONTAL_ALIGNMENT_CENTER,
		radius,
		12,
		Color("fff3db")
	)
