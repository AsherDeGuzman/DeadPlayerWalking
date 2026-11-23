extends Resource
class_name EnemyArchetype

@export var archetype_id: StringName = &"skeleton"
@export var display_name := "WALKER"
@export var animation_profile: StringName = &"skeleton"
@export_range(1, 2000, 1) var maximum_health := 42
@export_range(1, 100, 1) var attack_damage := 8
@export_range(1.0, 400.0, 1.0) var movement_speed := 92.0
@export_range(1.0, 1000.0, 1.0) var detection_range := 560.0
@export_range(1.0, 600.0, 1.0) var attack_range := 54.0
@export_range(1.0, 400.0, 1.0) var preferred_attack_distance := 46.0
@export_range(0.1, 5.0, 0.05) var attack_cooldown := 0.7
@export var is_ranged := false
