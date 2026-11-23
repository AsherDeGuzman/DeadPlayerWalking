extends CharacterBody2D
class_name DungeonBoss

signal health_changed(boss_name: String, current: int, maximum: int)
signal defeated(boss_id: StringName)

const PROJECTILE_SCENE := preload("res://scenes/projectiles/crossbow_projectile.tscn")
const PREVIOUS_SELF_ART := preload("res://ASSETS/BOSS ASSETS/Asset 23 — Floor 5 boss_ corrupted previous self.png")
const FINAL_BOSS_ART := preload("res://ASSETS/BOSS ASSETS/Asset 25 — Floor 10 final boss.png")
const PREVIOUS_SELF_ANIMATIONS := preload("res://ASSETS/BOSS ASSETS/Asset 24 — Floor 5 boss animations.png")
const FINAL_BOSS_ANIMATIONS := preload("res://ASSETS/BOSS ASSETS/Asset 26 — Floor 10 boss animations.png")
const BOSS_AURA_ART := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 39 — Boss Aura.png")
const BOSS_TELEGRAPH_ART := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 40 — Boss Attack Telegraphs.png")
const TELEGRAPH_BEAM_REGION := Rect2(780.0, 174.0, 710.0, 170.0)
const TELEGRAPH_CIRCLE_REGION := Rect2(140.0, 0.0, 520.0, 510.0)
const TELEGRAPH_FAN_REGION := Rect2(80.0, 520.0, 680.0, 480.0)
const TELEGRAPH_BURST_REGION := Rect2(970.0, 520.0, 420.0, 480.0)
const BOSS_SKILL_IDS: Array[StringName] = [&"rift_volley", &"sigil_burst", &"sanguine_sweep"]
const BOSS_SKILL_NAMES := ["RIFT VOLLEY", "SIGIL BURST", "SANGUINE SWEEP"]
const SWEEP_RANGE := 330.0
const SWEEP_HALF_ANGLE := 0.9
const SIGIL_BURST_RADIUS := 92.0
const BOSS_ANIMATION_LAYOUT := {
	"idle": {
		"y": 0.0,
		"height": 216.0,
		"centers": [122.0, 311.0, 504.0, 687.0, 858.0, 1042.0, 1240.0, 1423.0],
		"speed": 5.0,
	},
	"walk": {
		"y": 212.0,
		"height": 202.0,
		"centers": [116.0, 303.0, 483.0, 665.0, 846.0, 1030.0, 1212.0, 1390.0],
		"speed": 7.0,
	},
	"attack": {
		"y": 414.0,
		"height": 196.0,
		"centers": [164.0, 430.0, 700.0, 930.0, 1130.0, 1400.0],
		"speed": 8.0,
	},
}
const BOSS_FRAME_WIDTH := 182.0
const FINAL_BOSS_FRAME_WIDTH := 140.0
const FINAL_BOSS_IDLE_CENTERS := [86.0, 226.0, 367.0, 506.0, 642.0, 781.0, 922.0, 1062.0]
const FINAL_BOSS_WALK_CENTERS := [82.0, 222.0, 364.0, 504.0, 644.0, 784.0, 924.0, 1064.0, 1204.0, 1360.0]
const FINAL_BOSS_ATTACK_CENTERS := [110.0, 335.0, 535.0, 735.0, 945.0, 1135.0, 1370.0]

static var _previous_self_frames: SpriteFrames
static var _final_boss_frames: SpriteFrames

var target: RunnerController
var boss_id: StringName = &"previous_self"
var boss_name := "THE PREVIOUS SELF"
var is_final_boss := false
var max_health := 220
var health := 220
var attack_damage := 12
var movement_speed := 92.0
var _audio_manager: GameAudioManager
var _is_active := false
var _windup_time := 0.0
var _attack_cooldown := 1.0
var _facing := Vector2.DOWN
var _hit_flash := 0.0
var _art_sprite: Sprite2D
var _aura_sprite: Sprite2D
var _telegraph_sprite: Sprite2D
var _animation_sprite: AnimatedSprite2D
var _target_telegraph: Sprite2D
var _sweep_telegraph: Sprite2D
var _circle_telegraph_texture: AtlasTexture
var _burst_telegraph_texture: AtlasTexture
var _aura_time := 0.0
var _windup_duration := 1.0
var _attack_direction := Vector2.DOWN
var _attack_distance := 0.0
var _skill_target_position := Vector2.ZERO
var _skill_effect_time := 0.0
var _active_skill_index := 0
var _next_skill_index := 0


func _ready() -> void:
	_audio_manager = get_node("/root/AudioManager") as GameAudioManager
	_aura_sprite = $Aura as Sprite2D
	_art_sprite = $Art as Sprite2D
	_telegraph_sprite = $Telegraph as Sprite2D
	_target_telegraph = $TargetTelegraph as Sprite2D
	_sweep_telegraph = $SweepTelegraph as Sprite2D
	_animation_sprite = get_node_or_null("Animation") as AnimatedSprite2D
	_aura_sprite.texture = BOSS_AURA_ART
	_aura_sprite.scale = Vector2.ONE * 0.1
	_aura_sprite.modulate = Color(1.0, 1.0, 1.0, 0.52)
	_telegraph_sprite.texture = _create_telegraph_texture(TELEGRAPH_BEAM_REGION)
	_telegraph_sprite.scale.y = 0.45
	_circle_telegraph_texture = _create_telegraph_texture(TELEGRAPH_CIRCLE_REGION)
	_burst_telegraph_texture = _create_telegraph_texture(TELEGRAPH_BURST_REGION)
	_target_telegraph.texture = _circle_telegraph_texture
	_sweep_telegraph.texture = _create_telegraph_texture(TELEGRAPH_FAN_REGION)
	_update_art()
	add_to_group("enemies")
	set_physics_process(false)


func configure(player: RunnerController, source_snapshot: Dictionary, final_boss: bool) -> void:
	if player == null:
		push_error("A dungeon boss cannot be configured without the current player.")
		return
	target = player
	is_final_boss = final_boss
	boss_id = &"hollow_warden" if is_final_boss else &"previous_self"
	boss_name = "THE HOLLOW WARDEN" if is_final_boss else "THE PREVIOUS SELF"
	var source_speed := clampf(float(source_snapshot.get("move_speed", 200.0)), 80.0, 400.0)
	max_health = maxi(1, player.max_health * 5)
	attack_damage = maxi(1, roundi(float(player.max_health) / 5.0))
	if is_final_boss:
		movement_speed = minf(source_speed * 0.55, 150.0)
	else:
		movement_speed = minf(source_speed * 0.5, 120.0)
	health = max_health
	_windup_time = 0.0
	_attack_cooldown = 1.0
	_skill_effect_time = 0.0
	_next_skill_index = 0
	_hide_skill_telegraphs()
	if is_instance_valid(_art_sprite):
		_update_art()
	health_changed.emit(boss_name, health, max_health)
	queue_redraw()


func start_encounter() -> void:
	_is_active = true
	set_physics_process(true)


func is_attack_telegraphed() -> bool:
	return _windup_time > 0.0


func begin_attack_telegraph(skill_id: StringName = &"") -> void:
	if skill_id == &"":
		_active_skill_index = _next_skill_index
		_next_skill_index = (_next_skill_index + 1) % BOSS_SKILL_IDS.size()
	else:
		_active_skill_index = BOSS_SKILL_IDS.find(skill_id)
		if _active_skill_index < 0:
			push_error("Unknown boss skill requested: %s" % skill_id)
			return
		_next_skill_index = (_active_skill_index + 1) % BOSS_SKILL_IDS.size()
	_windup_duration = 0.82 if is_final_boss else 1.0
	if _active_skill_index == 1:
		_windup_duration += 0.12
	elif _active_skill_index == 2:
		_windup_duration += 0.08
	_windup_time = _windup_duration
	_skill_effect_time = 0.0
	_skill_target_position = target.global_position if is_instance_valid(target) else global_position
	var target_offset := _skill_target_position - global_position
	_attack_distance = minf(target_offset.length(), 640.0)
	_attack_direction = target_offset.normalized() if target_offset.length_squared() > 0.01 else _facing
	_play_animation("attack")
	_audio_manager.play_sfx("boss_attack")
	_update_attack_telegraph()
	queue_redraw()


func take_damage(amount: int) -> void:
	if not _is_active or health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	_hit_flash = 0.16
	health_changed.emit(boss_name, health, max_health)
	queue_redraw()
	if health == 0:
		_is_active = false
		set_physics_process(false)
		defeated.emit(boss_id)
		queue_free()


func _physics_process(delta: float) -> void:
	_aura_time += delta
	var aura_pulse := (sin(_aura_time * 2.4) + 1.0) * 0.5
	_aura_sprite.modulate.a = 0.42 + aura_pulse * 0.16
	_aura_sprite.scale = Vector2.ONE * (0.095 + aura_pulse * 0.012)
	if _skill_effect_time > 0.0:
		_skill_effect_time = maxf(0.0, _skill_effect_time - delta)
		_target_telegraph.modulate.a = _skill_effect_time / 0.3
		if _skill_effect_time <= 0.0 and _windup_time <= 0.0:
			_target_telegraph.visible = false
	if target == null or not is_instance_valid(target) or not target.is_alive:
		velocity = Vector2.ZERO
		move_and_slide()
		_hide_skill_telegraphs()
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_art_sprite.modulate = Color("fff0d4") if _hit_flash > 0.0 else Color.WHITE
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > 0.01:
		_facing = offset.normalized()
	velocity = offset.normalized() * movement_speed if distance > 210.0 else Vector2.ZERO
	move_and_slide()
	if _windup_time <= 0.0:
		_play_animation("walk" if velocity.length_squared() > 0.0 else "idle")

	if _attack_cooldown <= 0.0 and _windup_time <= 0.0 and distance <= 640.0:
		begin_attack_telegraph()
	if _windup_time > 0.0:
		_update_attack_telegraph()
		_windup_time = maxf(0.0, _windup_time - delta)
		if _windup_time <= 0.0:
			_fire_attack()
			_attack_cooldown = 1.65 if is_final_boss else 2.0
	queue_redraw()


func _update_attack_telegraph() -> void:
	if _windup_time <= 0.0 or target == null or not is_instance_valid(target):
		_hide_skill_telegraphs()
		return
	var progress := 1.0 - _windup_time / _windup_duration
	var pulse := (sin(_aura_time * 18.0) + 1.0) * 0.5
	_telegraph_sprite.visible = _active_skill_index == 0
	_target_telegraph.visible = _active_skill_index == 1
	_sweep_telegraph.visible = _active_skill_index == 2
	match _active_skill_index:
		0:
			_target_telegraph.texture = _circle_telegraph_texture
			_telegraph_sprite.position = _attack_direction * _attack_distance * 0.5
			_telegraph_sprite.rotation = _attack_direction.angle()
			_telegraph_sprite.scale.x = maxf(_attack_distance, 80.0) / TELEGRAPH_BEAM_REGION.size.x
			_telegraph_sprite.scale.y = 0.38 + progress * 0.16 + pulse * 0.08
			_telegraph_sprite.modulate.a = 0.62 + progress * 0.28 + pulse * 0.1
		1:
			_target_telegraph.texture = _circle_telegraph_texture
			_target_telegraph.global_position = _skill_target_position
			_target_telegraph.scale = Vector2.ONE * (0.3 + progress * 0.06 + pulse * 0.02)
			_target_telegraph.modulate = Color(1.0, 0.28, 0.34, 0.65 + progress * 0.3 + pulse * 0.05)
		2:
			_sweep_telegraph.position = _attack_direction * SWEEP_RANGE * 0.5
			_sweep_telegraph.rotation = _attack_direction.angle() + PI * 0.5
			_sweep_telegraph.scale = Vector2.ONE * (0.63 + progress * 0.04)
			_sweep_telegraph.modulate = Color(1.0, 0.24, 0.32, 0.62 + progress * 0.3 + pulse * 0.08)


func _fire_attack() -> void:
	match _active_skill_index:
		0:
			_telegraph_sprite.visible = false
			_fire_rift_volley()
		1:
			_telegraph_sprite.visible = false
			_sweep_telegraph.visible = false
			_fire_sigil_burst()
		2:
			_telegraph_sprite.visible = false
			_target_telegraph.visible = false
			_sweep_telegraph.visible = false
			_fire_sanguine_sweep()


func _fire_rift_volley() -> void:
	if target == null or not is_instance_valid(target):
		return
	var spread := [-0.2, 0.0, 0.2] if is_final_boss else [0.0]
	for angle in spread:
		var projectile := PROJECTILE_SCENE.instantiate() as CrossbowProjectile
		if projectile == null:
			push_error("The boss projectile scene could not be instantiated.")
			continue
		projectile.name = "BossProjectile"
		projectile.configure(_attack_direction.rotated(angle), attack_damage, 470.0, 640.0, &"player")
		get_parent().add_child(projectile)
		projectile.global_position = global_position + _attack_direction * 34.0


func _fire_sigil_burst() -> void:
	_target_telegraph.texture = _burst_telegraph_texture
	_target_telegraph.global_position = _skill_target_position
	_target_telegraph.scale = Vector2.ONE * 0.36
	_target_telegraph.modulate = Color.WHITE
	_target_telegraph.visible = true
	_skill_effect_time = 0.3
	if is_instance_valid(target) and target.global_position.distance_to(_skill_target_position) <= SIGIL_BURST_RADIUS:
		target.take_damage(attack_damage)


func _fire_sanguine_sweep() -> void:
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	if (
		offset.length() <= SWEEP_RANGE
		and offset.length_squared() > 0.01
		and absf(_attack_direction.angle_to(offset.normalized())) <= SWEEP_HALF_ANGLE
	):
		target.take_damage(attack_damage)


func _hide_skill_telegraphs() -> void:
	if is_instance_valid(_telegraph_sprite):
		_telegraph_sprite.visible = false
	if is_instance_valid(_target_telegraph):
		_target_telegraph.visible = false
	if is_instance_valid(_sweep_telegraph):
		_sweep_telegraph.visible = false


func _create_telegraph_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = BOSS_TELEGRAPH_ART
	texture.region = region
	return texture


func _update_art() -> void:
	_art_sprite.texture = FINAL_BOSS_ART if is_final_boss else PREVIOUS_SELF_ART
	var art_size := _art_sprite.texture.get_size()
	var target_height := 106.0 if is_final_boss else 98.0
	_art_sprite.scale = Vector2.ONE * target_height / art_size.y
	if _animation_sprite != null:
		if is_final_boss:
			if _final_boss_frames == null:
				_final_boss_frames = _build_boss_animations(true)
			_animation_sprite.sprite_frames = _final_boss_frames
		else:
			if _previous_self_frames == null:
				_previous_self_frames = _build_boss_animations(false)
			_animation_sprite.sprite_frames = _previous_self_frames
		_animation_sprite.scale = Vector2.ONE * target_height / 196.0
		_art_sprite.visible = false
		_play_animation("idle")


static func _build_boss_animations(final_boss: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var atlas := FINAL_BOSS_ANIMATIONS if final_boss else PREVIOUS_SELF_ANIMATIONS
	for animation_name in BOSS_ANIMATION_LAYOUT:
		var layout: Dictionary = BOSS_ANIMATION_LAYOUT[animation_name]
		var centers: Array = layout["centers"]
		var row_y := float(layout["y"])
		var row_height := float(layout["height"])
		var frame_width := BOSS_FRAME_WIDTH
		if final_boss and animation_name == "idle":
			centers = FINAL_BOSS_IDLE_CENTERS
			row_y = 0.0
			row_height = 170.0
			frame_width = FINAL_BOSS_FRAME_WIDTH
		elif final_boss and animation_name == "walk":
			centers = FINAL_BOSS_WALK_CENTERS
			row_y = 176.0
			row_height = 154.0
			frame_width = FINAL_BOSS_FRAME_WIDTH
		elif final_boss and animation_name == "attack":
			centers = FINAL_BOSS_ATTACK_CENTERS
			row_y = 334.0
			row_height = 165.0
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(layout["speed"]))
		frames.set_animation_loop(animation_name, animation_name != "attack")
		for center_x in centers:
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = atlas
			atlas_frame.region = Rect2(
				float(center_x) - frame_width * 0.5,
				row_y,
				frame_width,
				row_height
			)
			frames.add_frame(animation_name, atlas_frame)
	return frames


func _play_animation(animation_name: String) -> void:
	if _animation_sprite == null or _animation_sprite.sprite_frames == null:
		return
	if _animation_sprite.animation != animation_name or not _animation_sprite.is_playing():
		_animation_sprite.play(animation_name)
	_animation_sprite.speed_scale = (
		clampf(velocity.length() / maxf(movement_speed, 1.0), 0.7, 1.25)
		if animation_name == "walk"
		else 1.0
	)
	_animation_sprite.flip_h = _facing.x < -0.15
	_animation_sprite.modulate = Color("fff0d4") if _hit_flash > 0.0 else Color.WHITE


func _draw() -> void:
	if is_attack_telegraphed():
		var progress := 1.0 - _windup_time / _windup_duration
		var telegraph_color := Color(1.0, 0.75, 0.38, 0.45 + progress * 0.5)
		draw_arc(Vector2.ZERO, 61.0 + progress * 12.0, 0.0, TAU, 40, telegraph_color, 4.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-92.0, -63.0), boss_name, HORIZONTAL_ALIGNMENT_CENTER, 184.0, 10, Color("f5d9e8"))
	if is_attack_telegraphed():
		draw_string(
			font,
			Vector2(-110.0, -78.0),
			BOSS_SKILL_NAMES[_active_skill_index],
			HORIZONTAL_ALIGNMENT_CENTER,
			220.0,
			10,
			Color("ff8996")
		)
