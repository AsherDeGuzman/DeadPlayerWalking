extends CharacterBody2D
class_name RunnerController

signal health_changed(current: int, maximum: int)
signal player_died
signal attack_performed
signal dodge_started
signal weapon_changed(display_name: String, weapon_id: StringName)
signal potion_count_changed(count: int)

const WEAPON_CONFIGS := [
	preload("res://resources/weapons/dungeon_edge.tres"),
	preload("res://resources/weapons/warden_crossbow.tres"),
]
const PLAYER_SWORD_PATH := "res://ASSETS/WEAPON ASSETS/Asset 10 — Dungeon Edge sword.png"
const PLAYER_CROSSBOW_PATH := "res://ASSETS/WEAPON ASSETS/Asset 13 — Warden Crossbow.png"
const SWORD_SLASH_PATH := "res://ASSETS/WEAPON ASSETS/Asset 11 — Sword slash effect.png"
const MELEE_IMPACT_PATH := "res://ASSETS/WEAPON ASSETS/Asset 12 — Melee impact effect.png"
const DAMAGE_FLASH_ART := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 37 — Player damage flash.png")
const HEALING_EFFECT_ART := preload("res://ASSETS/PICKUPS AND GAMEPLAY ASSETS/Asset 36 — Healing effect.png")
const HEALING_POTION_FRACTION := 0.25
const CROSSBOW_RELOAD_DURATION := 1.5
const DODGE_COOLDOWN_DURATION := 3.0
const PLAYER_MASTER_SHEET := preload("res://ASSETS/PLAYER ASSETS/MASTER LIST PLAYER SPRITES .png")
const PLAYER_DIRECTIONS := [&"down", &"left", &"right", &"up"]
const PLAYER_DIRECTIONAL_ANIMATIONS := {
	&"idle": {
		"frames": 4,
		"fps": 6.0,
		"loop": true,
		"x": 94.0,
		"step_x": 62.0,
		"frame_width": 62.0,
		"frame_height": 80.0,
		"row_y": [64.0, 148.0, 232.0, 318.0],
	},
	&"walk": {
		"frames": 8,
		"fps": 12.0,
		"loop": true,
		"x": 484.0,
		"step_x": 60.0,
		"frame_width": 60.0,
		"frame_height": 82.0,
		"row_y": [62.0, 148.0, 232.0, 318.0],
	},
	&"melee_attack": {
		"frames": 6,
		"fps": 24.0,
		"loop": false,
		"x": 1056.0,
		"step_x": 68.0,
		"frame_width": 68.0,
		"frame_height": 80.0,
		"row_y": [64.0, 148.0, 232.0, 316.0],
	},
	&"ranged_attack": {
		"frames": 6,
		"fps": 18.0,
		"loop": false,
		"x": 72.0,
		"step_x": 80.0,
		"frame_width": 80.0,
		"frame_height": 72.0,
		"row_y": [477.0, 549.0, 621.0, 693.0],
	},
}
const PLAYER_ANIMATIONS := {
	"idle": {"path": "res://ASSETS/PLAYER ASSETS/Asset 02 — Player idle animation.png", "frames": 4, "fps": 6.0, "loop": true},
	"walk": {"path": "res://ASSETS/PLAYER ASSETS/Asset 03 — Player walking animation.png", "frames": 8, "fps": 12.0, "loop": true},
	"melee_attack": {"path": "res://ASSETS/PLAYER ASSETS/Asset 04 — Player melee attack.png", "frames": 6, "fps": 24.0, "loop": false},
	"ranged_attack": {"path": "res://ASSETS/PLAYER ASSETS/Asset 05 — Player ranged attack.png", "frames": 6, "fps": 18.0, "loop": false},
	"hurt": {"path": "res://ASSETS/PLAYER ASSETS/Asset 06 — Player hurt animation.png", "frames": 3, "fps": 16.0, "loop": false},
	"death": {"path": "res://ASSETS/PLAYER ASSETS/Asset 07 — Player death animation.png", "frames": 6, "fps": 12.0, "loop": false},
	"dodge": {"path": "res://ASSETS/PLAYER ASSETS/Asset 08 — Optional dodge animation.png", "frames": 4, "fps": 20.0, "loop": false},
}

var max_health: int = 100
var health: int = 100
var attack_damage: int = 10
var movement_speed: float = 200.0
var mob_stat_multiplier := 1.0
var potion_count := 0
var _sword_damage_multiplier := 1.0
var _crossbow_damage_multiplier := 1.0
var _audio_manager: GameAudioManager
var touch_controls: Node
var controls_enabled: bool = true
var is_alive: bool = true

var _active_weapon_index := 0
var _weapon_cooldowns: Dictionary = {}
var _locked_target: Node2D
var _target_indicator: Line2D
var _facing := Vector2.DOWN
var _facing_direction: StringName = &"down"
var _weapon_pose_time := 0.0
var _dodge_direction := Vector2.DOWN
var _dodge_time := 0.0
var _invulnerability_time := 0.0
var _dodge_cooldown := 0.0
var _footstep_time := 0.0
var _melee_windup_time := 0.0
var _melee_active_time := 0.0
var _melee_window_open := false
var _melee_hit_targets: Dictionary = {}
var _melee_damage := 1
var _melee_shape: CapsuleShape2D
var _action_animation: StringName = &""
var _death_signal_pending := false
var _slash_time := 0.0
var _melee_impact_time := 0.0
var _damage_effect: Sprite2D
var _damage_effect_tween: Tween
var _healing_effect_tween: Tween

@onready var _animated_sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var _directional_sprite := $DirectionalSprite as AnimatedSprite2D
@onready var _weapon_pivot := $WeaponPivot as Node2D
@onready var _sword_sprite := $WeaponPivot/SwordSprite as Sprite2D
@onready var _crossbow_sprite := $WeaponPivot/CrossbowSprite as Sprite2D
@onready var _melee_hitbox := $MeleeHitbox as Area2D
@onready var _melee_collision_shape := $MeleeHitbox/CollisionShape2D as CollisionShape2D
@onready var _slash_effect := $SlashEffect as Sprite2D
@onready var _melee_impact_effect := $MeleeImpactEffect as Sprite2D
@onready var _healing_effect := $HealingEffect as Sprite2D
@onready var _reload_indicator := get_node_or_null("ReloadIndicator") as ProgressBar


func _ready() -> void:
	_audio_manager = get_node("/root/AudioManager") as GameAudioManager
	_animated_sprite.sprite_frames = _build_sprite_frames()
	_animated_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_directional_sprite.sprite_frames = _build_directional_sprite_frames()
	_directional_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_directional_sprite.play("idle_down")
	_damage_effect = get_node_or_null("DamageFlash") as Sprite2D
	if _damage_effect == null:
		push_error("The player scene is missing its static DamageFlash node.")
	else:
		_damage_effect.texture = DAMAGE_FLASH_ART
	if _healing_effect == null:
		push_error("The player scene is missing its authored HealingEffect node.")
	else:
		_healing_effect.texture = HEALING_EFFECT_ART
		_healing_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_healing_effect.visible = false
	var scene_melee_shape := _melee_collision_shape.shape as CapsuleShape2D
	if scene_melee_shape == null:
		push_error("The player's melee hitbox requires a CapsuleShape2D.")
	else:
		_melee_shape = scene_melee_shape.duplicate() as CapsuleShape2D
		_melee_collision_shape.shape = _melee_shape
	_melee_hitbox.body_entered.connect(_on_melee_hitbox_body_entered)
	_animated_sprite.play("idle")
	_setup_weapon_art()
	_configure_reload_indicator()
	for weapon in WEAPON_CONFIGS:
		_weapon_cooldowns[weapon.weapon_id] = 0.0
	_update_reload_indicator()
	_update_equipped_sprites()
	add_to_group("player")
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = -10000000
		camera.limit_right = 10000000
		camera.limit_top = -10000000
		camera.limit_bottom = 10000000
		camera.position_smoothing_speed = 8.0
		camera.drag_horizontal_enabled = false
		camera.drag_vertical_enabled = false
		camera.enabled = true
		camera.make_current()
	health_changed.emit(health, max_health)


func configure(stats: Dictionary, controls: Node) -> void:
	set_locked_target(null)
	_facing = Vector2.DOWN
	_facing_direction = &"down"
	_action_animation = &""
	_animated_sprite.rotation = 0.0
	_animated_sprite.position = Vector2(0.0, -35.0)
	_animated_sprite.visible = true
	_directional_sprite.visible = false
	_animated_sprite.play("idle")
	_directional_sprite.play("idle_down")
	max_health = maxi(1, int(stats.get("max_health", 100)))
	health = max_health
	attack_damage = maxi(1, int(stats.get("attack_damage", 10)))
	movement_speed = clampf(float(stats.get("move_speed", 200.0)), 80.0, 400.0)
	mob_stat_multiplier = maxf(1.0, float(stats.get("mob_stat_multiplier", 1.0)))
	_sword_damage_multiplier = clampf(float(stats.get("sword_damage_multiplier", 1.0)), 1.0, 2.0)
	_crossbow_damage_multiplier = clampf(float(stats.get("crossbow_damage_multiplier", 1.0)), 1.0, 2.0)
	touch_controls = controls
	_dodge_time = 0.0
	_dodge_cooldown = 0.0
	_update_dash_cooldown_indicator()
	is_alive = true
	controls_enabled = true
	potion_count = 0
	potion_count_changed.emit(potion_count)
	_active_weapon_index = 0
	for weapon in WEAPON_CONFIGS:
		_weapon_cooldowns[weapon.weapon_id] = 0.0
	_update_reload_indicator()
	_update_equipped_sprites()
	health_changed.emit(health, max_health)


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_end_melee_attack()
		if touch_controls is TouchControls:
			(touch_controls as TouchControls).set_keyboard_movement(Vector2.ZERO)
		queue_redraw()


func request_attack() -> void:
	var weapon := _current_weapon()
	if not controls_enabled or not is_alive or float(_weapon_cooldowns.get(weapon.weapon_id, 0.0)) > 0.0:
		return

	if weapon.projectile_scene != null:
		var aim_target := _get_ranged_target(weapon.projectile_range)
		if aim_target != null:
			_facing = (aim_target.global_position - global_position).normalized()
			if _facing.length_squared() < 0.01:
				_facing = Vector2.DOWN
		_update_facing_direction()
	if not _play_action_animation(weapon.attack_animation):
		return

	if weapon.projectile_scene == null:
		_weapon_cooldowns[weapon.weapon_id] = weapon.cooldown
		_start_melee_attack(weapon)
	else:
		_fire_projectile(weapon)
		_weapon_cooldowns[weapon.weapon_id] = maxf(
			weapon.cooldown,
			CROSSBOW_RELOAD_DURATION
		)
		_update_reload_indicator()
	attack_performed.emit()
	queue_redraw()

func switch_weapon() -> void:
	if not controls_enabled or not is_alive:
		return
	_end_melee_attack()
	_active_weapon_index = (_active_weapon_index + 1) % WEAPON_CONFIGS.size()
	_update_equipped_sprites()
	var weapon := _current_weapon()
	_audio_manager.play_sfx("weapon_switch")
	weapon_changed.emit(weapon.display_name, weapon.weapon_id)


func get_current_weapon_id() -> StringName:
	return _current_weapon().weapon_id


func get_current_weapon_name() -> String:
	return _current_weapon().display_name


func _current_weapon() -> WeaponConfig:
	return WEAPON_CONFIGS[_active_weapon_index] as WeaponConfig


func _update_equipped_sprites() -> void:
	if _sword_sprite == null or _crossbow_sprite == null:
		return
	var is_sword_equipped := _active_weapon_index == 0
	var uses_baked_melee_pose := _action_animation == &"melee_attack"
	var uses_baked_ranged_pose := _action_animation == &"ranged_attack"
	var movement_ratio := clampf(velocity.length() / maxf(movement_speed, 1.0), 0.0, 1.0)
	var sway := sin(_weapon_pose_time * (11.0 if movement_ratio > 0.05 else 2.8))
	var hand_side := -1.0 if _facing_direction == &"left" else 1.0
	_weapon_pivot.position = Vector2(hand_side * 14.0, -22.0 + sway * lerpf(0.5, 1.2, movement_ratio))
	_weapon_pivot.rotation = _facing.angle() + PI * 0.5
	_weapon_pivot.z_index = -1 if _facing_direction == &"up" else 1
	_sword_sprite.visible = is_sword_equipped and not uses_baked_melee_pose
	_sword_sprite.position = Vector2.ZERO
	_sword_sprite.rotation = 0.0
	_crossbow_sprite.visible = not is_sword_equipped and not uses_baked_ranged_pose
	_crossbow_sprite.position = Vector2.ZERO
	_crossbow_sprite.rotation = PI


func _start_melee_attack(weapon: WeaponConfig) -> void:
	_melee_hit_targets.clear()
	_melee_window_open = false
	_melee_damage = maxi(1, roundi(attack_damage * weapon.damage_multiplier * _sword_damage_multiplier))
	_melee_windup_time = weapon.windup_time
	_melee_active_time = 0.0
	if _melee_shape != null:
		var radius := clampf(weapon.hitbox_radius, 4.0, 32.0)
		_melee_shape.radius = radius
		_melee_shape.height = maxf(clampf(weapon.hitbox_length, 24.0, 96.0), radius * 2.0)
	_update_melee_hitbox_transform(weapon)
	_melee_hitbox.set_deferred("monitoring", false)
	_show_slash_effect()


func _update_melee_hitbox_transform(weapon: WeaponConfig) -> void:
	var attack_direction := _facing.normalized()
	if attack_direction.length_squared() < 0.01:
		attack_direction = Vector2.DOWN
	_melee_hitbox.position = attack_direction * weapon.hitbox_offset
	_melee_hitbox.rotation = attack_direction.angle() - PI * 0.5


func _end_melee_attack() -> void:
	_melee_windup_time = 0.0
	_melee_active_time = 0.0
	_melee_window_open = false
	if _melee_hitbox != null:
		_melee_hitbox.set_deferred("monitoring", false)


func _fire_projectile(weapon: WeaponConfig) -> void:
	var projectile := weapon.projectile_scene.instantiate() as CrossbowProjectile
	if projectile == null:
		push_error("The configured projectile scene could not be instantiated.")
		return
	projectile.name = "CrossbowProjectile"
	projectile.configure(
		_facing,
		roundi(attack_damage * weapon.damage_multiplier * _crossbow_damage_multiplier),
		weapon.projectile_speed,
		weapon.projectile_range
	)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + _facing * 30.0


func _configure_reload_indicator() -> void:
	if _reload_indicator == null:
		push_error("The player scene is missing its authored ReloadIndicator node.")
		return
	_reload_indicator.min_value = 0.0
	_reload_indicator.max_value = 100.0
	_reload_indicator.value = 0.0
	_reload_indicator.show_percentage = true
	_reload_indicator.visible = false
	_reload_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reload_indicator.z_index = 4
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1b211f")
	background.border_color = Color("63887b")
	background.set_border_width_all(1)
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("81edc8")
	fill.set_corner_radius_all(2)
	_reload_indicator.add_theme_stylebox_override("background", background)
	_reload_indicator.add_theme_stylebox_override("fill", fill)
	_reload_indicator.add_theme_font_size_override("font_size", 8)
	_reload_indicator.add_theme_color_override("font_color", Color("eafff6"))
	_reload_indicator.add_theme_color_override("font_outline_color", Color("15201d"))
	_reload_indicator.add_theme_constant_override("outline_size", 1)


func _update_reload_indicator() -> void:
	if _reload_indicator == null:
		return
	var reload_time := float(_weapon_cooldowns.get(&"warden_crossbow", 0.0))
	_reload_indicator.visible = reload_time > 0.0
	_reload_indicator.value = clampf(
		reload_time / CROSSBOW_RELOAD_DURATION * 100.0,
		0.0,
		100.0
	)


func set_locked_target(target: Node2D) -> void:
	if target != null and (
		not is_instance_valid(target)
		or not target.is_in_group("enemies")
		or not target.is_inside_tree()
		or not target.is_visible_in_tree()
		or int(target.get("health")) <= 0
	):
		target = null
	if _locked_target == target:
		return
	if is_instance_valid(_target_indicator):
		_target_indicator.queue_free()
	_target_indicator = null
	_locked_target = target
	if _locked_target == null:
		return

	_target_indicator = Line2D.new()
	_target_indicator.name = "TargetLockIndicator"
	_target_indicator.width = 3.0
	_target_indicator.default_color = Color("72f0cb")
	_target_indicator.z_index = 10
	_target_indicator.closed = true
	var points := PackedVector2Array()
	for point_index in 32:
		var angle := TAU * float(point_index) / 32.0
		points.append(Vector2(cos(angle) * 27.0, 24.0 + sin(angle) * 12.0))
	_target_indicator.points = points
	_locked_target.add_child(_target_indicator)


func _get_ranged_target(maximum_range: float) -> Node2D:
	if _is_ranged_target_valid(_locked_target, maximum_range):
		return _locked_target
	set_locked_target(null)
	var nearest_target: Node2D
	var nearest_distance := maximum_range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node2D
		if not _is_ranged_target_valid(enemy, maximum_range):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_target = enemy
			nearest_distance = distance
	return nearest_target


func _is_ranged_target_valid(candidate: Node2D, maximum_range: float) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.is_inside_tree()
		or not candidate.is_visible_in_tree()
		or not candidate.is_in_group("enemies")
		or not candidate.has_method("take_damage")
		or int(candidate.get("health")) <= 0
	):
		return false
	var offset := candidate.global_position - global_position
	if offset.length_squared() > maximum_range * maximum_range:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position)
	query.collision_mask = 2 | 4
	query.exclude = [get_rid()]
	var ray_hit := get_world_2d().direct_space_state.intersect_ray(query)
	return ray_hit.is_empty() or ray_hit.get("collider") == candidate


func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if not _melee_window_open:
		return
	if not body.is_in_group("enemies") or not body.has_method("take_damage"):
		return
	if int(body.get("health")) <= 0:
		return
	var body_id := body.get_instance_id()
	if _melee_hit_targets.has(body_id):
		return
	_melee_hit_targets[body_id] = true
	body.call("take_damage", _melee_damage)
	_audio_manager.play_sfx("melee_impact")
	_show_impact_effect(_melee_impact_effect, to_local(body.global_position), 0.045)


func _setup_weapon_art() -> void:
	_sword_sprite.texture = load(PLAYER_SWORD_PATH) as Texture2D
	_crossbow_sprite.texture = load(PLAYER_CROSSBOW_PATH) as Texture2D
	_slash_effect.texture = load(SWORD_SLASH_PATH) as Texture2D
	_melee_impact_effect.texture = load(MELEE_IMPACT_PATH) as Texture2D
	for weapon_sprite in [_sword_sprite, _crossbow_sprite, _slash_effect, _melee_impact_effect]:
		if weapon_sprite.texture == null:
			push_error("A player weapon texture could not be loaded: %s" % weapon_sprite.name)
		weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sword_sprite.scale = Vector2(0.034, 0.034)
	_sword_sprite.offset = Vector2(0.0, 478.0)
	_crossbow_sprite.scale = Vector2(0.03, 0.03)
	_crossbow_sprite.offset = Vector2(0.0, -475.0)
	_slash_effect.scale = Vector2(0.045, 0.045)
	_slash_effect.visible = false
	_melee_impact_effect.scale = Vector2.ZERO
	_melee_impact_effect.visible = false


func _show_slash_effect() -> void:
	_slash_effect.position = _facing * 27.0
	_slash_effect.rotation = _facing.angle()
	_slash_effect.modulate = Color.WHITE
	_slash_effect.scale = Vector2.ONE * 0.022
	_slash_effect.visible = true
	_slash_time = 0.18


func _show_impact_effect(effect: Sprite2D, offset: Vector2, sprite_scale: float) -> void:
	effect.position = offset
	effect.scale = Vector2.ONE * sprite_scale * 0.45
	effect.modulate = Color.WHITE
	effect.visible = true
	_melee_impact_time = 0.16


func request_dodge() -> void:
	if not controls_enabled or not is_alive or _dodge_cooldown > 0.0:
		return

	var direction := _movement_input()
	if direction.length_squared() < 0.01:
		direction = _facing
	_dodge_direction = direction.normalized()
	_dodge_time = 0.18
	_invulnerability_time = 0.34
	_dodge_cooldown = DODGE_COOLDOWN_DURATION
	_update_dash_cooldown_indicator()
	_play_action_animation(&"dodge")
	dodge_started.emit()
	queue_redraw()


func _update_dash_cooldown_indicator() -> void:
	if touch_controls is TouchControls:
		(touch_controls as TouchControls).set_dash_cooldown(
			_dodge_cooldown,
			DODGE_COOLDOWN_DURATION
		)


func take_damage(amount: int) -> void:
	if not is_alive or _invulnerability_time > 0.0 or amount <= 0:
		return

	health = maxi(0, health - amount)
	_end_melee_attack()
	health_changed.emit(health, max_health)
	_show_damage_effect()
	queue_redraw()
	if health == 0:
		is_alive = false
		velocity = Vector2.ZERO
		controls_enabled = false
		_death_signal_pending = _play_action_animation(&"death")
		if not _death_signal_pending:
			player_died.emit()
	else:
		_play_action_animation(&"hurt")


func _show_damage_effect() -> void:
	if not is_instance_valid(_damage_effect):
		return
	if _damage_effect_tween != null and _damage_effect_tween.is_running():
		_damage_effect_tween.kill()
	_damage_effect.visible = true
	_damage_effect.modulate.a = 0.82
	_damage_effect_tween = create_tween()
	_damage_effect_tween.tween_property(_damage_effect, "modulate:a", 0.0, 0.2)
	_damage_effect_tween.tween_callback(func() -> void: _damage_effect.visible = false)


func restore_health(amount: int) -> int:
	if not is_alive or amount <= 0:
		return 0

	var recoverable_health := maxi(0, max_health - health - 1)
	var restored_health := mini(amount, recoverable_health)
	if restored_health <= 0:
		return 0

	health += restored_health
	health_changed.emit(health, max_health)
	queue_redraw()
	return restored_health


func add_potion() -> bool:
	if not is_alive:
		return false
	potion_count += 1
	potion_count_changed.emit(potion_count)
	return true


func use_potion() -> bool:
	if potion_count <= 0 or not is_alive:
		return false
	var restored_health := restore_health(roundi(float(max_health) * HEALING_POTION_FRACTION))
	if restored_health <= 0:
		return false
	potion_count -= 1
	potion_count_changed.emit(potion_count)
	_audio_manager.play_sfx("healing")
	_show_healing_effect()
	return true


func _show_healing_effect() -> void:
	if not is_instance_valid(_healing_effect):
		return
	if _healing_effect_tween != null and _healing_effect_tween.is_running():
		_healing_effect_tween.kill()
	_healing_effect.visible = true
	_healing_effect.modulate = Color.WHITE
	_healing_effect.scale = Vector2.ONE * 0.04
	_healing_effect_tween = create_tween()
	_healing_effect_tween.set_parallel(true)
	_healing_effect_tween.tween_property(_healing_effect, "modulate:a", 0.0, 0.55)
	_healing_effect_tween.tween_property(_healing_effect, "scale", Vector2.ONE * 0.085, 0.55)
	_healing_effect_tween.chain().tween_callback(func() -> void: _healing_effect.visible = false)


func build_run_record() -> Dictionary:
	return {
		"max_health": max_health,
		"attack_damage": maxi(
			roundi(attack_damage * _sword_damage_multiplier),
			roundi(attack_damage * _crossbow_damage_multiplier)
		),
		"move_speed": movement_speed,
		"weapon_archetypes": ["dungeon_edge", "warden_crossbow"],
	}


func _physics_process(delta: float) -> void:
	_weapon_pose_time += delta
	if is_instance_valid(_locked_target) and int(_locked_target.get("health")) <= 0:
		set_locked_target(null)
	for weapon_id in _weapon_cooldowns:
		_weapon_cooldowns[weapon_id] = maxf(0.0, float(_weapon_cooldowns[weapon_id]) - delta)
	_update_reload_indicator()
	if _melee_windup_time > 0.0:
		_melee_windup_time = maxf(0.0, _melee_windup_time - delta)
		if _melee_windup_time == 0.0 and controls_enabled and is_alive:
			_melee_window_open = true
			_melee_active_time = _current_weapon().active_time
			_melee_hitbox.set_deferred("monitoring", true)
	if _melee_window_open:
		_melee_active_time = maxf(0.0, _melee_active_time - delta)
		if _melee_active_time == 0.0:
			_end_melee_attack()
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_update_dash_cooldown_indicator()
	_invulnerability_time = maxf(0.0, _invulnerability_time - delta)
	_footstep_time = maxf(0.0, _footstep_time - delta)
	_slash_time = maxf(0.0, _slash_time - delta)
	_melee_impact_time = maxf(0.0, _melee_impact_time - delta)
	var slash_progress := 1.0 - _slash_time / 0.18
	_slash_effect.modulate.a = (1.0 - slash_progress) * 0.92
	_slash_effect.scale = Vector2.ONE * lerpf(0.022, 0.06, sin(slash_progress * PI * 0.5))
	_slash_effect.rotation = _facing.angle() - 0.4 + slash_progress * 0.8
	var impact_progress := 1.0 - _melee_impact_time / 0.16
	var impact_scale := 1.0 + sin(impact_progress * PI * 0.5) * 0.8
	_melee_impact_effect.modulate.a = 1.0 - impact_progress
	_melee_impact_effect.scale = Vector2.ONE * 0.045 * impact_scale
	if _slash_time == 0.0:
		_slash_effect.visible = false
	if _melee_impact_time == 0.0:
		_melee_impact_effect.visible = false
	_animated_sprite.modulate = Color("d3fff2") if _invulnerability_time > 0.0 else Color.WHITE

	if not controls_enabled or not is_alive:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_facing_pose(delta)
		_update_sprite_animation()
		queue_redraw()
		return

	var movement := _movement_input()
	if movement.length_squared() > 0.01:
		_facing = movement.normalized()

	if Input.is_action_just_pressed("attack"):
		request_attack()
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	if Input.is_action_just_pressed("dodge"):
		request_dodge()

	if _dodge_time > 0.0:
		_dodge_time = maxf(0.0, _dodge_time - delta)
		velocity = _dodge_direction * movement_speed * 3.2
	else:
		velocity = movement * movement_speed

	move_and_slide()
	_update_facing_pose(delta)
	_update_equipped_sprites()
	_update_sprite_animation()
	if velocity.length_squared() > 900.0 and _dodge_time <= 0.0 and _footstep_time <= 0.0:
		_audio_manager.play_sfx("footstep")
		_footstep_time = 0.38
	queue_redraw()


func _movement_input() -> Vector2:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_controls is TouchControls:
		(touch_controls as TouchControls).set_keyboard_movement(movement)
	if touch_controls != null and touch_controls.has_method("get_movement_vector"):
		var touch_movement: Vector2 = touch_controls.call("get_movement_vector")
		if touch_movement.length_squared() > movement.length_squared():
			movement = touch_movement
	return movement.limit_length(1.0)


func _update_facing_pose(delta: float) -> void:
	if _facing.length_squared() < 0.01:
		return
	_update_facing_direction()
	var uses_directional_animation := (
		_facing_direction != &"down"
		and (_action_animation == &"" or PLAYER_DIRECTIONAL_ANIMATIONS.has(_action_animation))
	)
	_animated_sprite.rotation = 0.0
	_animated_sprite.position = Vector2(0.0, -35.0)
	_animated_sprite.flip_h = false
	_animated_sprite.visible = not uses_directional_animation
	_directional_sprite.visible = uses_directional_animation
	if uses_directional_animation:
		var animation := _action_animation
		if animation == &"":
			animation = &"walk" if velocity.length_squared() > 0.01 else &"idle"
		_play_directional_animation(animation)
		var walking := velocity.length_squared() > 0.01
		var bob := absf(sin(_weapon_pose_time * 12.0)) * 1.1 if walking else 0.0
		_directional_sprite.position = Vector2(0.0, -29.0 - bob)


func _update_facing_direction() -> void:
	if absf(_facing.x) > absf(_facing.y):
		_facing_direction = &"left" if _facing.x < 0.0 else &"right"
	else:
		_facing_direction = &"up" if _facing.y < 0.0 else &"down"


func _play_directional_animation(animation: StringName) -> void:
	var directional_animation := StringName("%s_%s" % [animation, _facing_direction])
	if not _directional_sprite.sprite_frames.has_animation(directional_animation):
		push_error("Player directional animation is unavailable: %s" % directional_animation)
		return
	if _directional_sprite.animation != directional_animation or not _directional_sprite.is_playing():
		_directional_sprite.play(directional_animation)


func _build_directional_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for animation_key in PLAYER_DIRECTIONAL_ANIMATIONS:
		var configuration: Dictionary = PLAYER_DIRECTIONAL_ANIMATIONS[animation_key]
		for direction_index in PLAYER_DIRECTIONS.size():
			var animation_name := StringName("%s_%s" % [animation_key, PLAYER_DIRECTIONS[direction_index]])
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, float(configuration["fps"]))
			sprite_frames.set_animation_loop(animation_name, bool(configuration["loop"]))
			for frame_index in int(configuration["frames"]):
				var frame := AtlasTexture.new()
				frame.atlas = PLAYER_MASTER_SHEET
				frame.region = Rect2(
					float(configuration["x"]) + float(frame_index) * float(configuration["step_x"]),
					float(configuration["row_y"][direction_index]),
					float(configuration["frame_width"]),
					float(configuration["frame_height"])
				)
				sprite_frames.add_frame(animation_name, frame)
	return sprite_frames


func _build_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for animation_key in PLAYER_ANIMATIONS:
		var animation_name := StringName(animation_key)
		var config: Dictionary = PLAYER_ANIMATIONS[animation_key]
		var texture := load(str(config["path"])) as Texture2D
		if texture == null:
			push_error("Could not load player animation sheet: %s" % config["path"])
			continue

		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, float(config["fps"]))
		sprite_frames.set_animation_loop(animation_name, bool(config["loop"]))
		var frame_count := int(config["frames"])
		for frame_index in frame_count:
			var start_x := floori(float(frame_index) * texture.get_width() / frame_count)
			var end_x := floori(float(frame_index + 1) * texture.get_width() / frame_count)
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(start_x, 0, end_x - start_x, texture.get_height())
			sprite_frames.add_frame(animation_name, frame)

	if not sprite_frames.has_animation("idle"):
		push_error("The player idle animation is unavailable.")
	return sprite_frames


func _play_action_animation(animation: StringName) -> bool:
	if _animated_sprite.sprite_frames == null or not _animated_sprite.sprite_frames.has_animation(animation):
		push_error("Player animation is not available: %s" % animation)
		return false
	_action_animation = animation
	_animated_sprite.visible = true
	_animated_sprite.rotation = 0.0
	_animated_sprite.position = Vector2(0.0, -35.0)
	_update_facing_direction()
	var use_directional_animation := (
		_facing_direction != &"down" and PLAYER_DIRECTIONAL_ANIMATIONS.has(animation)
	)
	_directional_sprite.visible = use_directional_animation
	_animated_sprite.visible = not use_directional_animation
	if use_directional_animation:
		_directional_sprite.speed_scale = 1.0
		_play_directional_animation(animation)
	else:
		_directional_sprite.visible = false
		_animated_sprite.speed_scale = 1.0
		_animated_sprite.play(animation)
	_update_equipped_sprites()
	return true


func _update_sprite_animation() -> void:
	if _action_animation != &"":
		return
	var next_animation: StringName = &"walk" if velocity.length_squared() > 0.01 else &"idle"
	var animation_speed := (
		clampf(velocity.length() / maxf(movement_speed, 1.0), 0.55, 1.35)
		if next_animation == &"walk"
		else 1.0
	)
	if _facing_direction != &"down":
		_directional_sprite.speed_scale = animation_speed
		_play_directional_animation(next_animation)
	else:
		_animated_sprite.speed_scale = animation_speed
		if _animated_sprite.animation != next_animation:
			_animated_sprite.play(next_animation)


func _on_sprite_animation_finished() -> void:
	if _action_animation == &"death":
		if _death_signal_pending:
			_death_signal_pending = false
			player_died.emit()
		return
	_action_animation = &""
	_update_facing_pose(0.0)
	_update_equipped_sprites()
	_update_sprite_animation()


func _draw() -> void:
	draw_circle(Vector2(0, 7), 22, Color(0.008, 0.016, 0.022, 0.48))
	if _dodge_time > 0.0:
		draw_arc(Vector2.ZERO, 25, 0.0, TAU, 28, Color(0.43, 0.9, 0.78, 0.8), 2.0, true)
