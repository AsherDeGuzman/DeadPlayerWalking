extends CharacterBody2D
class_name FacilityEnemy

signal defeated(enemy_type: String)

@export var is_previous_self: bool = false
@export var archetype: EnemyArchetype = preload("res://resources/enemies/skeleton_warrior.tres")

const FALLBACK_HP := 100
const FALLBACK_DAMAGE := 10
const FALLBACK_SPEED := 155.0
const CROSSBOW_PROJECTILE_SCENE := preload("res://scenes/projectiles/crossbow_projectile.tscn")
const SKELETON_ANIMATION_SHEET := preload("res://ASSETS/ORDINARY ENEMY ASSETS/Asset 18 — Skeleton animation sheet.png")
const CREATURE_ANIMATION_SHEET := preload("res://ASSETS/ORDINARY ENEMY ASSETS/Asset 20 — Dungeon creature animation sheet.png")
const ARCHER_ANIMATION_SHEET := preload("res://ASSETS/ORDINARY ENEMY ASSETS/Asset 22 — Dungeon archer animation sheet.png")
const DEATH_EFFECT_SHEET := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 38 — Enemy Death Effect.png")
const DEATH_EFFECT_FRAME_SIZE := Vector2(362.0, 724.0)
const SKELETON_ANIMATION_LAYOUT := {
	"idle": {
		"y": 12.0,
		"height": 200.0,
		"centers": [520.0, 680.0, 823.0, 983.0],
		"widths": [176.0, 176.0, 176.0, 176.0],
		"speed": 6.0,
	},
	"walk": {
		"y": 218.0,
		"height": 210.0,
		"centers": [254.0, 429.0, 597.0, 762.0, 926.0, 1090.0, 1256.0],
		"widths": [176.0, 176.0, 176.0, 176.0, 176.0, 176.0, 176.0],
		"speed": 9.0,
	},
	"attack": {
		"y": 420.0,
		"height": 220.0,
		"centers": [385.0, 618.0, 857.0, 1080.0],
		"widths": [176.0, 176.0, 176.0, 176.0],
		"speed": 12.0,
	},
	"hurt": {
		"y": 668.0,
		"height": 180.0,
		"centers": [562.0, 750.0, 920.0],
		"widths": [176.0, 176.0, 176.0],
		"speed": 10.0,
	},
	"death": {
		"y": 842.0,
		"height": 176.0,
		"centers": [406.0, 590.0, 760.0, 956.0, 1183.0],
		"widths": [176.0, 176.0, 176.0, 176.0, 176.0],
		"speed": 10.0,
	},
}
const CREATURE_ANIMATION_LAYOUT := {
	"idle": {
		"y": 12.0,
		"height": 205.0,
		"centers": [478.0, 665.0, 860.0, 1056.0],
		"widths": [176.0, 176.0, 176.0, 176.0],
		"speed": 6.0,
	},
	"walk": {
		"y": 242.0,
		"height": 195.0,
		"centers": [164.0, 348.0, 523.0, 693.0, 866.0, 1046.0, 1211.0, 1378.0],
		"widths": [176.0, 176.0, 176.0, 176.0, 176.0, 176.0, 164.0, 176.0],
		"speed": 10.0,
	},
	"attack": {
		"y": 448.0,
		"height": 220.0,
		"centers": [370.0, 588.0, 816.0, 1088.0],
		"widths": [176.0, 190.0, 224.0, 288.0],
		"speed": 12.0,
	},
	"hurt": {
		"y": 682.0,
		"height": 174.0,
		"centers": [576.0, 785.0, 958.0],
		"widths": [176.0, 176.0, 176.0],
		"speed": 10.0,
	},
	"death": {
		"y": 840.0,
		"height": 182.0,
		"centers": [353.0, 558.0, 756.0, 983.0, 1222.0],
		"widths": [176.0, 176.0, 176.0, 210.0, 230.0],
		"speed": 8.0,
	},
}
const ARCHER_ANIMATION_LAYOUT := {
	"idle": {
		"y": 8.0,
		"height": 208.0,
		"centers": [516.0, 675.0, 845.0, 1015.0],
		"widths": [150.0, 150.0, 150.0, 150.0],
		"speed": 6.0,
	},
	"walk": {
		"y": 230.0,
		"height": 210.0,
		"centers": [165.0, 330.0, 494.0, 667.0, 836.0, 1019.0, 1200.0, 1371.0],
		"widths": [150.0, 164.0, 160.0, 160.0, 164.0, 164.0, 150.0, 150.0],
		"speed": 10.0,
	},
	"attack": {
		"y": 442.0,
		"height": 236.0,
		"centers": [296.0, 482.0, 684.0, 908.0],
		"widths": [160.0, 180.0, 200.0, 210.0],
		"speed": 10.0,
	},
	"hurt": {
		"y": 690.0,
		"height": 164.0,
		"centers": [550.0, 764.0, 971.0],
		"widths": [150.0, 150.0, 150.0],
		"speed": 10.0,
	},
	"death": {
		"y": 846.0,
		"height": 174.0,
		"centers": [262.0, 506.0, 739.0, 1023.0, 1308.0],
		"widths": [150.0, 200.0, 190.0, 230.0, 250.0],
		"speed": 8.0,
	},
}
const ENEMY_ANIMATION_PROFILES := {
	&"skeleton": {
		"sheet": SKELETON_ANIMATION_SHEET,
		"layout": SKELETON_ANIMATION_LAYOUT,
		"scale": 0.36,
	},
	&"creature": {
		"sheet": CREATURE_ANIMATION_SHEET,
		"layout": CREATURE_ANIMATION_LAYOUT,
		"scale": 0.36,
	},
	&"archer": {
		"sheet": ARCHER_ANIMATION_SHEET,
		"layout": ARCHER_ANIMATION_LAYOUT,
		"scale": 0.36,
	},
}
const ECHO_RANGED_RANGE := 420.0
const ECHO_RANGED_PREFERRED_DISTANCE := 190.0
const ECHO_HEALTH_MULTIPLIER := 1.5
const ECHO_DAMAGE_MULTIPLIER := 1.5
const ECHO_SPEED_MULTIPLIER := 1.15
const MELEE_MOBILITY_MULTIPLIER := 1.4
const PREVIOUS_SELF_RENDER_HEIGHT := 140.0

static var _animation_frames: Dictionary = {}
static var _death_effect_frames: SpriteFrames

var target: RunnerController
var mob_stat_multiplier := 1.0
var _audio_manager: GameAudioManager
var _animation_sprite: AnimatedSprite2D
var max_health: int = 42
var health: int = 42
var attack_damage: int = 8
var movement_speed: float = 92.0
var echo_label: String = "PREVIOUS SELF"

var _has_crossbow := false
var _windup_time := 0.0
var _windup_is_ranged := false
var _attack_cooldown := 0.7
var _death_time := 0.0
var _hit_flash := 0.0
var _facing := Vector2.UP
var _previous_self_base_scale := 1.0
var _previous_self_animation_time := 0.0

@onready var _art_sprite := $Art as Sprite2D
@onready var _mob_health_bar := get_node_or_null("MobHealthBar") as MobHealthBar


func _ready() -> void:
	_audio_manager = get_node("/root/AudioManager") as GameAudioManager
	_animation_sprite = get_node_or_null("Animation") as AnimatedSprite2D
	z_index = 2
	if is_previous_self:
		_configure_previous_self_art()
	else:
		_configure_animation()
	add_to_group("enemies")
	if is_previous_self:
		add_to_group("previous_selves")
		if _mob_health_bar != null:
			_mob_health_bar.position.y = -92.0
	_update_health_bar()


func configure_player(
	player: RunnerController,
	record: Dictionary = {},
	room_entry_count: int = 0
) -> void:
	target = player
	mob_stat_multiplier = maxf(1.0, player.mob_stat_multiplier) if player != null else 1.0
	if not is_previous_self:
		max_health = archetype.maximum_health
		health = max_health
		attack_damage = archetype.attack_damage
		movement_speed = archetype.movement_speed
		_attack_cooldown = archetype.attack_cooldown
		_has_crossbow = false
		_update_health_bar()
		queue_redraw()
		return

	var room_bonus := _get_room_player_stat_bonus(room_entry_count)
	echo_label = str(record.get("label", "PREVIOUS SELF"))
	var raw_weapons: Variant = record.get("weapon_archetypes", [])
	_has_crossbow = typeof(raw_weapons) == TYPE_ARRAY and "warden_crossbow" in raw_weapons
	if record.is_empty():
		push_warning("Previous-self data was missing; safe default snapshot stats will be used.")
		max_health = roundi(
			(float(FALLBACK_HP) * ECHO_HEALTH_MULTIPLIER + room_bonus.x) * mob_stat_multiplier
		)
		health = max_health
		attack_damage = roundi(
			(float(FALLBACK_DAMAGE) * ECHO_DAMAGE_MULTIPLIER + room_bonus.y) * mob_stat_multiplier
		)
		movement_speed = minf(
			(FALLBACK_SPEED * ECHO_SPEED_MULTIPLIER + room_bonus.z) * mob_stat_multiplier,
			600.0
		)
	else:
		max_health = clampi(
			roundi(
				(float(record.get("max_health", FALLBACK_HP)) * ECHO_HEALTH_MULTIPLIER + room_bonus.x)
				* mob_stat_multiplier
			),
			1,
			5000
		)
		health = max_health
		attack_damage = clampi(
			roundi(
				(float(record.get("attack_damage", FALLBACK_DAMAGE)) * ECHO_DAMAGE_MULTIPLIER + room_bonus.y)
				* mob_stat_multiplier
			),
			1,
			1000
		)
		movement_speed = clampf(
			(
				float(record.get("move_speed", FALLBACK_SPEED)) * ECHO_SPEED_MULTIPLIER
				+ room_bonus.z
			) * mob_stat_multiplier,
			60.0,
			600.0
		)
	_configure_previous_self_art()
	_update_health_bar()
	queue_redraw()


func configure_archetype(configuration: EnemyArchetype) -> void:
	if configuration == null:
		push_error("An ordinary enemy was configured without an archetype resource.")
		return
	archetype = configuration
	if not is_previous_self and is_node_ready():
		configure_player(target)
		_configure_animation()


func configure_for_floor(floor_number: int, room_entry_count: int = 0) -> void:
	if is_previous_self:
		return
	var floor_steps := maxi(0, floor_number - 1)
	var floor_health := roundi(float(archetype.maximum_health) * (1.0 + float(floor_steps) * 0.075))
	var floor_damage := roundi(float(archetype.attack_damage) * (1.0 + float(floor_steps) * 0.05))
	var floor_speed := archetype.movement_speed + float(floor_steps) * 3.0
	var room_bonus := _get_room_player_stat_bonus(room_entry_count)
	var melee_mobility := MELEE_MOBILITY_MULTIPLIER if not archetype.is_ranged else 1.0
	max_health = roundi((float(floor_health) + room_bonus.x) * mob_stat_multiplier)
	health = max_health
	attack_damage = roundi((float(floor_damage) + room_bonus.y) * mob_stat_multiplier)
	movement_speed = minf(
		(floor_speed * melee_mobility + room_bonus.z) * mob_stat_multiplier,
		400.0
	)
	_update_health_bar()
	queue_redraw()


func _get_room_player_stat_bonus(room_entry_count: int) -> Vector3:
	if target == null or room_entry_count <= 0:
		return Vector3.ZERO
	var room_factor := float(room_entry_count) * 0.01
	return Vector3(
		float(target.max_health) * room_factor,
		float(target.attack_damage) * room_factor,
		target.movement_speed * room_factor
	)


func weaken_for_opening_strike() -> void:
	var opening_damage := mini(30, maxi(1, max_health / 3))
	health = maxi(1, health - opening_damage)
	_update_health_bar()
	queue_redraw()


func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	_audio_manager.play_sfx("enemy_hit")
	health = maxi(0, health - amount)
	_update_health_bar()
	_hit_flash = 0.16
	if health == 0:
		_spawn_death_effect()
		defeated.emit("previous_self" if is_previous_self else "ordinary")
		if _animation_sprite != null and not is_previous_self:
			_death_time = 0.55
			_animation_sprite.speed_scale = 1.0
			_animation_sprite.play("death")
			$CollisionShape2D.set_deferred("disabled", true)
		else:
			queue_free()
		return
	if _animation_sprite != null and not is_previous_self:
		_play_animation("hurt")
	queue_redraw()


func _spawn_death_effect() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	if _death_effect_frames == null:
		_death_effect_frames = SpriteFrames.new()
		_death_effect_frames.remove_animation("default")
		_death_effect_frames.add_animation("burst")
		_death_effect_frames.set_animation_speed("burst", 10.0)
		_death_effect_frames.set_animation_loop("burst", false)
		for frame_index in 6:
			var frame := AtlasTexture.new()
			frame.atlas = DEATH_EFFECT_SHEET
			frame.region = Rect2(
				Vector2(frame_index * DEATH_EFFECT_FRAME_SIZE.x, 0.0),
				DEATH_EFFECT_FRAME_SIZE
			)
			_death_effect_frames.add_frame("burst", frame)

	var effect := AnimatedSprite2D.new()
	effect.name = "EnemyDeathEffect"
	effect.sprite_frames = _death_effect_frames
	effect.animation = "burst"
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.scale = Vector2.ONE * 0.14
	effect.z_index = 3
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.animation_finished.connect(effect.queue_free)
	effect.play("burst")


func _physics_process(delta: float) -> void:
	if health <= 0:
		_death_time = maxf(0.0, _death_time - delta)
		if _death_time <= 0.0:
			queue_free()
		return
	if target == null or not is_instance_valid(target) or not target.is_alive:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_obstacle_draw_order()
		if is_previous_self:
			_update_previous_self_animation(delta)
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var default_art_color := Color(0.72, 0.62, 0.92, 1.0) if is_previous_self else Color.WHITE
	_art_sprite.modulate = Color("fff3dc") if _hit_flash > 0.0 else default_art_color
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > 0.01:
		_facing = offset.normalized()

	var preferred_distance := _get_preferred_attack_distance()
	if distance > _get_detection_range():
		velocity = Vector2.ZERO
	else:
		velocity = _pursuit_movement(offset, distance, preferred_distance) * movement_speed
	move_and_slide()
	_update_obstacle_draw_order()
	if is_previous_self:
		_update_previous_self_animation(delta)

	var attack_range := _get_attack_range()
	var ranged_attack := (
		(is_previous_self and _has_crossbow and distance > 120.0)
		or (not is_previous_self and archetype.is_ranged)
	)
	if distance <= attack_range and _attack_cooldown <= 0.0 and _windup_time <= 0.0:
		_begin_attack_telegraph(ranged_attack)
	if _animation_sprite != null and _hit_flash <= 0.0:
		if _windup_time > 0.0:
			_play_animation("attack")
		else:
			_play_animation("walk" if velocity.length_squared() > 0.0 else "idle")
	if _windup_time > 0.0:
		_windup_time = maxf(0.0, _windup_time - delta)
		if _windup_time <= 0.0:
			var target_offset := target.global_position - global_position
			if _windup_is_ranged and target_offset.length() <= attack_range:
				if is_previous_self:
					_spawn_echo_projectile(target_offset.normalized())
				else:
					_spawn_enemy_projectile(target_offset.normalized())
			elif target_offset.length() <= 68.0:
				target.take_damage(attack_damage)
			_attack_cooldown = archetype.attack_cooldown if not is_previous_self else 1.15
			_windup_is_ranged = false
	queue_redraw()


func _configure_previous_self_art() -> void:
	if _art_sprite.texture == null:
		push_error("The Previous Self scene is missing its supplied character artwork.")
		return
	var art_size := _art_sprite.texture.get_size()
	if art_size.y <= 0.0:
		push_error("The Previous Self character artwork has an invalid size.")
		return
	_previous_self_base_scale = PREVIOUS_SELF_RENDER_HEIGHT / art_size.y
	_art_sprite.scale = Vector2.ONE * _previous_self_base_scale
	_art_sprite.position = Vector2.ZERO
	_art_sprite.rotation = 0.0
	_art_sprite.flip_h = false
	_art_sprite.z_index = 1
	_art_sprite.visible = true
	_previous_self_animation_time = 0.0


func _update_previous_self_animation(delta: float) -> void:
	_previous_self_animation_time += delta
	_art_sprite.flip_h = _facing.x < -0.15
	var gait := sin(_previous_self_animation_time * 12.0)
	if _windup_time > 0.0:
		_art_sprite.position = Vector2(_facing.x * 3.0, -absf(gait) * 2.0)
		_art_sprite.rotation = gait * 0.035
		_art_sprite.scale = Vector2(
			_previous_self_base_scale * (1.0 + absf(gait) * 0.015),
			_previous_self_base_scale * (1.0 - absf(gait) * 0.015)
		)
	elif velocity.length_squared() > 0.01:
		_art_sprite.position = Vector2(_facing.x * 2.0, -2.0 + absf(gait) * 3.0)
		_art_sprite.rotation = gait * 0.025
		_art_sprite.scale = Vector2(
			_previous_self_base_scale * (1.0 + gait * 0.012),
			_previous_self_base_scale * (1.0 - gait * 0.012)
		)
	else:
		_art_sprite.position = Vector2(0.0, sin(_previous_self_animation_time * 2.6) * 1.2)
		_art_sprite.rotation = 0.0
		_art_sprite.scale = Vector2.ONE * _previous_self_base_scale


func _update_obstacle_draw_order() -> void:
	var obstacle_container := get_node_or_null("../../WorldGeometry/Obstacles") as Node2D
	if obstacle_container == null:
		z_index = 2
		return

	var closest_depth_distance := INF
	var draw_behind_obstacle := false
	for obstacle_node in obstacle_container.get_children():
		var obstacle := obstacle_node as StaticBody2D
		if obstacle == null:
			continue
		var collision := obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not (collision.shape is RectangleShape2D):
			continue
		var shape := collision.shape as RectangleShape2D
		var depth_y := obstacle.global_position.y + collision.position.y
		var local_position := global_position - obstacle.global_position
		if absf(local_position.x) > shape.size.x * 0.5 + 24.0:
			continue
		if absf(local_position.y - collision.position.y) > shape.size.y * 0.5 + 48.0:
			continue
		var depth_distance := absf(global_position.y - depth_y)
		if depth_distance < closest_depth_distance:
			closest_depth_distance = depth_distance
			draw_behind_obstacle = global_position.y < depth_y

	z_index = 0 if draw_behind_obstacle else 2


func _begin_attack_telegraph(ranged_attack: bool) -> void:
	_windup_time = 0.34
	_windup_is_ranged = ranged_attack
	if _animation_sprite != null:
		_play_animation("attack")
	_audio_manager.play_sfx("enemy_windup")


func _configure_animation() -> void:
	if _animation_sprite == null:
		push_error("The ordinary enemy scene is missing its Animation sprite.")
		return
	if archetype == null or not ENEMY_ANIMATION_PROFILES.has(archetype.animation_profile):
		push_error("An ordinary enemy archetype references an unknown animation profile.")
		return
	var animation_profile: Dictionary = ENEMY_ANIMATION_PROFILES[archetype.animation_profile]
	if not _animation_frames.has(archetype.animation_profile):
		_animation_frames[archetype.animation_profile] = _build_animations(
			animation_profile["sheet"],
			animation_profile["layout"]
		)
	_animation_sprite.sprite_frames = _animation_frames[archetype.animation_profile] as SpriteFrames
	_animation_sprite.scale = Vector2.ONE * maxf(float(animation_profile["scale"]), 0.46)
	_animation_sprite.z_index = 1
	_animation_sprite.visible = true
	_art_sprite.visible = false
	_play_animation("idle")


func _build_animations(sheet: Texture2D, animation_layout: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in animation_layout:
		var layout: Dictionary = animation_layout[animation_name]
		var centers: Array = layout["centers"]
		var widths: Array = layout["widths"]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(layout["speed"]))
		frames.set_animation_loop(animation_name, animation_name != "attack" and animation_name != "hurt")
		for frame_index in centers.size():
			var frame_width := float(widths[frame_index])
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = sheet
			atlas_frame.region = Rect2(
				float(centers[frame_index]) - frame_width * 0.5,
				float(layout["y"]),
				frame_width,
				float(layout["height"])
			)
			frames.add_frame(animation_name, atlas_frame)
	return frames


func _play_animation(animation_name: String) -> void:
	if _animation_sprite == null or _animation_sprite.sprite_frames == null:
		return
	if _animation_sprite.animation != animation_name or not _animation_sprite.is_playing():
		_animation_sprite.play(animation_name)
	_animation_sprite.speed_scale = (
		clampf(velocity.length() / maxf(movement_speed, 1.0), 0.65, 1.3)
		if animation_name == "walk"
		else 1.0
	)
	_animation_sprite.flip_h = _facing.x < -0.15
	_animation_sprite.modulate = Color("fff3dc") if _hit_flash > 0.0 else Color.WHITE


func _pursuit_movement(offset: Vector2, distance: float, preferred_distance: float) -> Vector2:
	if distance > preferred_distance:
		return offset.normalized()
	return Vector2.ZERO


func _get_detection_range() -> float:
	if is_previous_self and _has_crossbow:
		return ECHO_RANGED_RANGE
	return archetype.detection_range


func _get_attack_range() -> float:
	if is_previous_self and _has_crossbow:
		return ECHO_RANGED_RANGE
	return archetype.attack_range


func _get_preferred_attack_distance() -> float:
	if is_previous_self and _has_crossbow:
		return ECHO_RANGED_PREFERRED_DISTANCE
	return archetype.preferred_attack_distance


func _spawn_enemy_projectile(direction: Vector2) -> void:
	_spawn_projectile(direction, "DungeonArcherProjectile", _get_attack_range())


func _spawn_echo_projectile(direction: Vector2) -> void:
	_spawn_projectile(direction, "PreviousSelfProjectile", ECHO_RANGED_RANGE)


func _spawn_projectile(direction: Vector2, projectile_name: String, projectile_range: float) -> void:
	var projectile := CROSSBOW_PROJECTILE_SCENE.instantiate() as CrossbowProjectile
	if projectile == null:
		push_error("The previous-self projectile scene could not be instantiated.")
		return
	projectile.name = projectile_name
	projectile.configure(direction, attack_damage, 560.0, projectile_range, &"player")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 24.0


func _draw() -> void:
	if _windup_time > 0.0:
		draw_arc(Vector2.ZERO, 45.0, -PI * 0.5, PI * 0.8, 24, Color("ffc06e"), 3.0, true)

	var font := ThemeDB.fallback_font
	var name_text := echo_label if is_previous_self else archetype.display_name
	var name_y := -109.0 if is_previous_self else -81.0
	draw_string(font, Vector2(-60, name_y), name_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 10, Color("f3e5d7"))


func _update_health_bar() -> void:
	if is_instance_valid(_mob_health_bar):
		_mob_health_bar.set_health(health, max_health)
