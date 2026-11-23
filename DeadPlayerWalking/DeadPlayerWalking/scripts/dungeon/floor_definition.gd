extends Resource
class_name FloorDefinition

@export_range(1, 10, 1) var floor_number: int = 1
@export var floor_name: String = "Upper Dungeon"
@export_range(1, 8, 1) var room_count: int = 2
@export_range(1, 6, 1) var base_enemy_count: int = 1
@export_range(-1, 7, 1) var healing_room_index: int = -1
@export var boss_id: StringName = &""
@export var theme_color: Color = Color("263338")
