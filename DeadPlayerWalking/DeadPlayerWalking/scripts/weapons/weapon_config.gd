extends Resource
class_name WeaponConfig

@export var weapon_id: StringName
@export var display_name: String
@export var attack_animation: StringName
@export_range(0.0, 5.0, 0.01) var cooldown: float = 0.4
@export_range(0.1, 4.0, 0.1) var damage_multiplier: float = 1.0
@export var hitbox_offset: float = 32.0
@export_range(4.0, 32.0, 1.0) var hitbox_radius: float = 14.0
@export_range(24.0, 96.0, 1.0) var hitbox_length: float = 52.0
@export var windup_time: float = 0.07
@export var active_time: float = 0.14
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 720.0
@export var projectile_range: float = 520.0
