extends Area2D
class_name CrossbowProjectile

const IMPACT_DURATION := 0.2

var direction := Vector2.RIGHT
var damage := 1
var speed := 720.0
var maximum_distance := 520.0
var target_group: StringName = &"enemies"
var _distance_travelled := 0.0
var _resolved := false
var _trail_positions: Array[Vector2] = []
var _flight_time := 0.0
var _projectile_base_scale := Vector2.ONE
var _glow_base_scale := Vector2.ONE

@onready var _projectile_sprite := $ProjectileSprite as Sprite2D
@onready var _glow_sprite := $ArrowGlow as Sprite2D
@onready var _impact_sprite := $ImpactSprite as Sprite2D
@onready var _trail := $Trail as Line2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_impact_sprite.visible = false
	_projectile_base_scale = _projectile_sprite.scale
	_glow_base_scale = _glow_sprite.scale
	_projectile_sprite.rotation = direction.angle()
	var trail_color := Color("ff526e") if target_group == &"player" else Color("8cecff")
	_trail.default_color = trail_color
	var trail_gradient := Gradient.new()
	var tail_color := trail_color
	tail_color.a = 0.08
	trail_gradient.set_color(0, tail_color)
	trail_gradient.set_color(1, trail_color)
	_trail.gradient = trail_gradient
	_trail.visible = true


func configure(
	projectile_direction: Vector2,
	projectile_damage: int,
	projectile_speed: float,
	projectile_range: float,
	project_group: StringName = &"enemies"
) -> void:
	direction = projectile_direction.normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.DOWN
	damage = maxi(1, projectile_damage)
	speed = maxf(1.0, projectile_speed)
	maximum_distance = maxf(1.0, projectile_range)
	target_group = project_group
	set_collision_mask_value(1, target_group == &"player")
	set_collision_mask_value(2, target_group == &"enemies")
	set_collision_mask_value(3, true)


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	_flight_time += delta
	var pulse := 1.0 + 0.1 * (0.5 + 0.5 * sin(_flight_time * TAU * 7.0))
	_projectile_sprite.scale = _projectile_base_scale * pulse
	_glow_sprite.scale = _glow_base_scale * (pulse + 0.12)
	var step_distance := speed * delta
	global_position += direction * step_distance
	_distance_travelled += step_distance
	_trail_positions.append(global_position)
	if _trail_positions.size() > 7:
		_trail_positions.pop_front()
	var trail_points := PackedVector2Array()
	for trail_position in _trail_positions:
		trail_points.append(to_local(trail_position))
	trail_points.append(Vector2.ZERO)
	_trail.points = trail_points
	if _distance_travelled >= maximum_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _resolved:
		return
	var did_hit_target := body.is_in_group(target_group) and body.has_method("take_damage")
	if did_hit_target:
		body.call("take_damage", damage)
	(get_node("/root/AudioManager") as GameAudioManager).play_sfx("projectile_impact")
	_resolved = true
	set_deferred("monitoring", false)
	_projectile_sprite.visible = false
	_glow_sprite.visible = false
	_trail.visible = false
	_impact_sprite.visible = true
	_impact_sprite.scale = Vector2.ONE * 0.035
	_impact_sprite.modulate = Color("ffb0bd") if target_group == &"player" else Color("c7f7ff")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_impact_sprite, "scale", Vector2.ONE * 0.14, IMPACT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_impact_sprite, "modulate:a", 0.0, IMPACT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_impact_sprite, "rotation", direction.angle() + 0.45, IMPACT_DURATION)
	tween.chain()
	tween.tween_callback(queue_free)
