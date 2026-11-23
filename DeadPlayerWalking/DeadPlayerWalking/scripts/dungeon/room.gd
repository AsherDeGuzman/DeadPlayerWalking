extends Node2D
class_name DungeonRoom

enum EncounterState { COMBAT, BOSS, CLEARED }

signal room_cleared(floor_number: int, room_number: int)
signal exit_entered
signal potion_collected(stack_count: int)
signal boss_encounter_started(boss: DungeonBoss)
signal boss_health_changed(boss_name: String, current: int, maximum: int)
signal boss_defeated(boss_id: StringName)

const ROOM_SIZE := Vector2(1280.0, 720.0)
const BOSS_ARENA_BACKGROUND := preload("res://ASSETS/Floor 5 Reveal Cutscenes/Asset 50 — Floor 5 boss arena background.png")
const BOSS_ROOM_ENTRANCE_SHEET := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 32 — Dungeon entrances and exits.png")
const UPPER_FLOOR_ATLAS := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 27 — Upper dungeon floor tileset.png")
const DEEP_FLOOR_ATLAS := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 28 — Deep dungeon floor tileset.png")
const UPPER_WALL_ATLAS := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 29 - Dungeon Walls and Corners.png")
const DEEP_WALL_ATLAS := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 30 — Deep dungeon walls.png")
const ENEMY_ARCHETYPES: Array[EnemyArchetype] = [
	preload("res://resources/enemies/skeleton_warrior.tres"),
	preload("res://resources/enemies/dungeon_creature.tres"),
	preload("res://resources/enemies/dungeon_archer.tres"),
]
const FLOOR_TILE_SIZE := Vector2i(176, 176)
const FLOOR_ATLAS_MARGIN := Vector2i(8, 8)
const FLOOR_ATLAS_SEPARATION := Vector2i(16, 16)
const FLOOR_ATLAS_COLUMNS := 8
const FLOOR_ATLAS_ROWS := 3
const FLOOR_LAYER_COLUMNS := 7
const FLOOR_LAYER_ROWS := 4
const WALL_TILE_REGION := Rect2(0.0, 0.0, 150.0, 120.0)
const BOSS_ROOM_ENTRANCE_REGION := Rect2(365.0, 455.0, 470.0, 545.0)
const DOOR_STATE_EFFECT_SHEET := preload("res://ASSETS/VISUAL EFFECTS ASSETS/Asset 41 — Door Lock and Unlock Effects.png")
const DOOR_STATE_EFFECT_FRAME_SIZE := Vector2(887.0, 887.0)
const EXIT_Y := 76.0
const DUNGEON_DOOR_SHEET := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 31 — Dungeon doors.png")
const LOCKED_DOOR_REGION := Rect2(0.0, 512.0, 768.0, 512.0)
const OPEN_DOOR_REGION := Rect2(768.0, 0.0, 768.0, 512.0)
const PROP_SHEET := preload("res://ASSETS/DUNGEON ENVIRONMENT ASSETS/Asset 33 - Dungeon Pillars and Props.png")
const WALL_TORCH_REGION := Rect2(1060.0, 430.0, 210.0, 270.0)
const MAX_ECHO_RECORDS := 3
const ROOM_OBSTACLE_LAYOUTS := [
	[],
	[Rect2(256.0, 284.0, 112.0, 30.0), Rect2(912.0, 390.0, 112.0, 30.0)],
	[Rect2(180.0, 330.0, 92.0, 32.0), Rect2(1008.0, 280.0, 92.0, 32.0)],
	[Rect2(430.0, 280.0, 124.0, 30.0), Rect2(726.0, 388.0, 124.0, 30.0)],
]

static var _floor_tile_sets: Dictionary = {}

var floor_definition: FloorDefinition
var room_index := 0
var layout_seed := 0
var player: RunnerController
var enemy_scene: PackedScene
var previous_self_scene: PackedScene
var boss_scene: PackedScene
var echo_records: Array[Dictionary] = []
var echo_snapshot: Dictionary = {}
var _remaining_enemies := 0
var _is_cleared := false
var _encounter_state := EncounterState.COMBAT
var _exit_gate: StaticBody2D
var _exit_door_sprite: Sprite2D
var _enemy_container: Node2D
var _world_geometry: Node2D
var _layout_index := -1
var _obstacle_rects: Array[Rect2] = []
var _is_initialized := false


func configure(
	definition: FloorDefinition,
	index: int,
	player_node: RunnerController,
	enemy_packed_scene: PackedScene,
	echo_packed_scene: PackedScene,
	boss_packed_scene: PackedScene,
	snapshots: Array[Dictionary],
	room_layout_seed: int = 0
) -> void:
	floor_definition = definition
	room_index = index
	player = player_node
	enemy_scene = enemy_packed_scene
	previous_self_scene = echo_packed_scene
	boss_scene = boss_packed_scene
	echo_records = snapshots.duplicate(true)
	echo_snapshot = echo_records.back() if not echo_records.is_empty() else {}
	layout_seed = room_layout_seed
	if is_inside_tree():
		_initialize_room()


func _ready() -> void:
	_initialize_room()


func _initialize_room() -> void:
	if _is_initialized or floor_definition == null or player == null or enemy_scene == null:
		return
	if not has_node("WorldGeometry") or not has_node("Enemies"):
		push_error("A dungeon room was added without its floor, player, or enemy configuration.")
		return
	_world_geometry = $WorldGeometry as Node2D
	_enemy_container = $Enemies as Node2D
	_configure_floor_layer()
	_build_room_geometry()
	_spawn_enemies()
	_spawn_healing_pickup()
	_create_exit_trigger()
	_is_initialized = true
	queue_redraw()


func get_remaining_enemy_count() -> int:
	return _remaining_enemies


func is_exit_unlocked() -> bool:
	return _is_cleared


func is_boss_encounter() -> bool:
	return _encounter_state == EncounterState.BOSS


func get_encounter_state() -> EncounterState:
	return _encounter_state


func get_layout_index() -> int:
	return _layout_index


func get_obstacle_count() -> int:
	return _obstacle_rects.size()


func is_player_at_exit(player_node: Node2D) -> bool:
	if player_node == null:
		return false
	var offset := player_node.global_position - global_position - Vector2(ROOM_SIZE.x * 0.5, EXIT_Y)
	return absf(offset.x) <= 100.0 and absf(offset.y) <= 62.0


func _spawn_enemies() -> void:
	if floor_definition.boss_id != &"" and room_index == floor_definition.room_count - 1:
		_spawn_boss()
		return

	var enemy_count := floor_definition.base_enemy_count + mini(floori(float(room_index) / 2.0), 2)
	_remaining_enemies = 0
	var spawn_columns := [320.0, 640.0, 960.0]
	for enemy_index in enemy_count:
		var enemy_name := "Enemy%02d" % (enemy_index + 1)
		var enemy := _enemy_container.get_node_or_null(enemy_name) as FacilityEnemy
		if enemy == null:
			push_error("The dungeon room scene is missing static enemy node %s." % enemy_name)
			continue
		var archetype_index := posmod(
			enemy_index + floor_definition.floor_number - 1 + room_index,
			ENEMY_ARCHETYPES.size()
		)
		enemy.visible = true
		enemy.collision_layer = 2
		enemy.collision_mask = 6
		enemy.get_node("CollisionShape2D").set_deferred("disabled", false)
		enemy.configure_archetype(ENEMY_ARCHETYPES[archetype_index])
		enemy.position = Vector2(
			spawn_columns[enemy_index % spawn_columns.size()],
			248.0 + floorf(float(enemy_index) / float(spawn_columns.size())) * 112.0
		)
		enemy.configure_player(player)
		enemy.configure_for_floor(floor_definition.floor_number, layout_seed + 1)
		if not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated)
		_remaining_enemies += 1
	for enemy_index in range(enemy_count, 6):
		var unused_enemy := _enemy_container.get_node_or_null("Enemy%02d" % (enemy_index + 1)) as FacilityEnemy
		if unused_enemy != null:
			unused_enemy.visible = false
			unused_enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	_spawn_saved_echoes()
	if _remaining_enemies == 0:
		_unlock_exit()


func _spawn_boss() -> void:
	_encounter_state = EncounterState.BOSS
	_remaining_enemies = 1
	for enemy_index in range(1, 7):
		var ordinary_placeholder := _enemy_container.get_node_or_null("Enemy%02d" % enemy_index) as FacilityEnemy
		if ordinary_placeholder != null:
			ordinary_placeholder.visible = false
			ordinary_placeholder.get_node("CollisionShape2D").set_deferred("disabled", true)
	_hide_echo_placeholders()
	if boss_scene == null:
		push_error("A boss floor reached its encounter room without a boss scene.")
		return
	var boss := _enemy_container.get_node_or_null("DungeonBoss") as DungeonBoss
	if boss == null:
		push_error("The dungeon room scene is missing the static DungeonBoss node.")
		return
	boss.position = Vector2(640.0, 250.0)
	boss.visible = true
	boss.get_node("CollisionShape2D").set_deferred("disabled", false)
	var source_snapshot := echo_snapshot if not echo_snapshot.is_empty() else player.build_run_record()
	boss.configure(player, source_snapshot, floor_definition.boss_id == &"hollow_warden")
	if not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)
	if not boss.defeated.is_connected(_on_boss_defeated):
		boss.defeated.connect(_on_boss_defeated)
	_on_boss_health_changed(boss.boss_name, boss.health, boss.max_health)
	_spawn_saved_echoes()
	boss_encounter_started.emit(boss)


func _spawn_saved_echoes() -> void:
	if previous_self_scene == null:
		return
	var occupied_positions: Array[Vector2] = []
	for echo_index in MAX_ECHO_RECORDS:
		var echo_name := "PreviousSelf" if echo_index == 0 else "PreviousSelf%02d" % (echo_index + 1)
		var grave_name := "EchoGrave%02d" % (echo_index + 1)
		var echo := _enemy_container.get_node_or_null(echo_name) as FacilityEnemy
		var grave := _enemy_container.get_node_or_null(grave_name) as Node2D
		if echo == null or grave == null:
			push_error("The dungeon room is missing authored echo/grave slot %d." % (echo_index + 1))
			continue
		_hide_echo_slot(echo, grave)
		if echo_index >= echo_records.size():
			continue
		var record: Dictionary = echo_records[echo_index]
		if (
			int(record.get("death_floor", 0)) != floor_definition.floor_number
			or int(record.get("death_room", 0)) != room_index + 1
		):
			continue
		var position_data: Variant = record.get("death_position", {})
		if typeof(position_data) != TYPE_DICTIONARY:
			continue
		var x_position: Variant = position_data.get("x")
		var y_position: Variant = position_data.get("y")
		if (
			typeof(x_position) not in [TYPE_INT, TYPE_FLOAT]
			or typeof(y_position) not in [TYPE_INT, TYPE_FLOAT]
		):
			continue
		var spawn_position := Vector2(
			clampf(float(x_position), 32.0, ROOM_SIZE.x - 32.0),
			clampf(float(y_position), 32.0, ROOM_SIZE.y - 32.0)
		)
		for occupied_position in occupied_positions:
			if occupied_position.distance_to(spawn_position) < 44.0:
				spawn_position.x = clampf(spawn_position.x + 48.0, 32.0, ROOM_SIZE.x - 32.0)
		occupied_positions.append(spawn_position)
		echo.configure_player(player, record, layout_seed + 1)
		echo.position = spawn_position + Vector2(0.0, 32.0)
		echo.modulate.a = 0.0
		echo.visible = true
		echo.set_physics_process(false)
		var collision := echo.get_node("CollisionShape2D") as CollisionShape2D
		collision.set_deferred("disabled", true)
		grave.position = spawn_position
		grave.scale = Vector2.ZERO
		grave.modulate.a = 1.0
		grave.visible = true
		if not echo.defeated.is_connected(_on_enemy_defeated):
			echo.defeated.connect(_on_enemy_defeated)
		_remaining_enemies += 1
		var emergence := create_tween()
		emergence.tween_property(grave, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		emergence.tween_interval(0.12)
		emergence.tween_property(echo, "position:y", spawn_position.y, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		emergence.parallel().tween_property(echo, "modulate:a", 1.0, 0.56)
		emergence.tween_callback(_activate_echo.bind(echo, collision))


func _hide_echo_placeholders() -> void:
	for echo_index in MAX_ECHO_RECORDS:
		var echo_name := "PreviousSelf" if echo_index == 0 else "PreviousSelf%02d" % (echo_index + 1)
		var echo := _enemy_container.get_node_or_null(echo_name) as FacilityEnemy
		var grave := _enemy_container.get_node_or_null("EchoGrave%02d" % (echo_index + 1)) as Node2D
		if echo == null or grave == null:
			push_error("The dungeon room is missing authored echo/grave slot %d." % (echo_index + 1))
			continue
		_hide_echo_slot(echo, grave)


func _hide_echo_slot(echo: FacilityEnemy, grave: Node2D) -> void:
	echo.visible = false
	echo.modulate = Color.WHITE
	echo.set_physics_process(false)
	var collision := echo.get_node("CollisionShape2D") as CollisionShape2D
	collision.set_deferred("disabled", true)
	grave.visible = false
	grave.scale = Vector2.ONE
	grave.modulate = Color.WHITE


func _activate_echo(echo: FacilityEnemy, collision: CollisionShape2D) -> void:
	if not is_instance_valid(echo):
		return
	echo.set_physics_process(true)
	collision.set_deferred("disabled", false)


func _spawn_healing_pickup() -> void:
	var pickup := get_node_or_null("HealingPickup") as HealingPickup
	if pickup == null:
		push_error("The dungeon room scene is missing its HealingPickup node.")
		return

	var is_healing_room := floor_definition.healing_room_index == room_index
	pickup.visible = is_healing_room
	var collision := pickup.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", not is_healing_room)
	if not is_healing_room:
		return
	pickup.position = Vector2(640.0, 540.0)
	pickup.collected.connect(_on_potion_collected)


func _on_potion_collected(stack_count: int) -> void:
	var pickup := get_node_or_null("HealingPickup") as HealingPickup
	var effect := get_node_or_null("HealingCollectionEffect") as Sprite2D
	if pickup == null or effect == null:
		push_error("The dungeon room is missing its authored potion collection effect.")
		return
	effect.global_position = pickup.global_position
	effect.visible = true
	effect.modulate = Color.WHITE
	effect.scale = Vector2.ONE * 0.055
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "modulate:a", 0.0, 0.65)
	tween.tween_property(effect, "scale", Vector2.ONE * 0.09, 0.65)
	tween.chain().tween_callback(func() -> void: effect.visible = false)
	potion_collected.emit(stack_count)


func _on_boss_health_changed(boss_name: String, current: int, maximum: int) -> void:
	boss_health_changed.emit(boss_name, current, maximum)


func _on_boss_defeated(boss_id: StringName) -> void:
	boss_defeated.emit(boss_id)
	_on_enemy_defeated(String(boss_id))


func _on_enemy_defeated(_enemy_type: String) -> void:
	(get_node("/root/AudioManager") as GameAudioManager).play_sfx("enemy_down")
	_remaining_enemies = maxi(0, _remaining_enemies - 1)
	if _remaining_enemies == 0:
		_unlock_exit()


func _unlock_exit() -> void:
	if _is_cleared:
		return
	_is_cleared = true
	_encounter_state = EncounterState.CLEARED
	_set_exit_door_state(true)
	if is_instance_valid(_exit_gate):
		_exit_gate.queue_free()
	room_cleared.emit(floor_definition.floor_number, room_index + 1)
	var audio_manager := get_node_or_null("/root/AudioManager") as GameAudioManager
	if audio_manager != null:
		audio_manager.play_sfx("ui")
	queue_redraw()
	if is_player_at_exit(player):
		call_deferred("_emit_exit_for_waiting_player")


func _emit_exit_for_waiting_player() -> void:
	if _is_cleared and is_instance_valid(player) and is_player_at_exit(player):
		exit_entered.emit()


func _create_exit_trigger() -> void:
	var exit_trigger := get_node_or_null("ExitTrigger") as Area2D
	if exit_trigger == null:
		push_error("The dungeon room scene is missing its ExitTrigger node.")
		return
	exit_trigger.position = Vector2(ROOM_SIZE.x * 0.5, EXIT_Y)
	exit_trigger.body_entered.connect(_on_exit_body_entered)


func _on_exit_body_entered(body: Node2D) -> void:
	if _is_cleared and body == player:
		exit_entered.emit()


func _build_room_geometry() -> void:
	_exit_gate = _world_geometry.get_node("LockedExit") as StaticBody2D

	if floor_definition.boss_id != &"" and room_index == floor_definition.room_count - 1:
		var boss_exit_door := _world_geometry.get_node_or_null("ExitDoor") as Sprite2D
		if boss_exit_door != null:
			boss_exit_door.visible = false
		_create_boss_room_entrance()
		return
	_create_room_wall_art()
	_create_exit_door()
	_create_wall_torches()
	_layout_index = posmod(layout_seed, ROOM_OBSTACLE_LAYOUTS.size())
	var layout: Array = ROOM_OBSTACLE_LAYOUTS[_layout_index]
	var obstacle_container := _world_geometry.get_node("Obstacles") as Node2D
	for obstacle_index in obstacle_container.get_child_count():
		var obstacle := obstacle_container.get_child(obstacle_index) as StaticBody2D
		var collision := obstacle.get_node("CollisionShape2D") as CollisionShape2D
		var is_active := obstacle_index < layout.size()
		collision.set_deferred("disabled", not is_active)
		var prop := obstacle.get_node_or_null("SuppliedDungeonProp") as Sprite2D
		if prop != null:
			prop.visible = is_active
		if is_active:
			var bounds: Rect2 = layout[obstacle_index]
			obstacle.position = bounds.position + bounds.size * 0.5
			collision.position = Vector2(0.0, bounds.size.y * 0.65)
			_obstacle_rects.append(bounds)
			var active_prop := obstacle.get_node_or_null("SuppliedDungeonProp") as Sprite2D
			if active_prop == null:
				push_error("The dungeon room scene is missing a static SuppliedDungeonProp node.")
				continue
			var prop_texture := AtlasTexture.new()
			prop_texture.atlas = PROP_SHEET
			prop_texture.region = Rect2(276.0, 430.0, 226.0, 254.0)
			active_prop.texture = prop_texture
			active_prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			active_prop.scale = Vector2(0.52, 0.52)
			active_prop.position = Vector2(0.0, -30.0)
			active_prop.z_index = 2
			active_prop.visible = true


func _create_room_wall_art() -> void:
	var is_deep_dungeon := floor_definition.floor_number >= 5
	var atlas := DEEP_WALL_ATLAS if is_deep_dungeon else UPPER_WALL_ATLAS
	var walls := _world_geometry.get_node_or_null("SuppliedWalls") as Node2D
	if walls == null:
		push_error("The dungeon room scene is missing its static SuppliedWalls node.")
		return
	for wall_node in walls.get_children():
		var wall := wall_node as Sprite2D
		if wall == null:
			continue
		var wall_texture := AtlasTexture.new()
		wall_texture.atlas = atlas
		wall_texture.region = WALL_TILE_REGION
		wall.texture = wall_texture
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall.visible = true


func _create_wall_tile(atlas: Texture2D, tile_position: Vector2, tile_rotation: float = 0.0) -> Sprite2D:
	var wall := Sprite2D.new()
	var wall_texture := AtlasTexture.new()
	wall_texture.atlas = atlas
	wall_texture.region = WALL_TILE_REGION
	wall.texture = wall_texture
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall.position = tile_position
	wall.rotation = tile_rotation
	wall.scale = Vector2.ONE * 0.95
	wall.z_index = 0
	_world_geometry.add_child(wall)
	return wall


func _create_boss_room_entrance() -> void:
	var entrance := _world_geometry.get_node_or_null("BossRoomEntrance") as Sprite2D
	if entrance == null:
		push_error("The dungeon room scene is missing its static BossRoomEntrance node.")
		return
	var entrance_texture := AtlasTexture.new()
	entrance_texture.atlas = BOSS_ROOM_ENTRANCE_SHEET
	entrance_texture.region = BOSS_ROOM_ENTRANCE_REGION
	entrance.texture = entrance_texture
	entrance.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	entrance.position = Vector2(ROOM_SIZE.x * 0.5, 116.0)
	entrance.scale = Vector2.ONE * 0.22
	entrance.z_index = 0
	entrance.visible = true


func _create_exit_door() -> void:
	_exit_door_sprite = _world_geometry.get_node_or_null("ExitDoor") as Sprite2D
	if _exit_door_sprite == null:
		push_error("The dungeon room scene is missing its static ExitDoor node.")
		return
	_exit_door_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_exit_door_sprite.position = Vector2(ROOM_SIZE.x * 0.5, EXIT_Y + 34.0)
	_exit_door_sprite.scale = Vector2(0.3, 0.3)
	_set_exit_door_state(false)


func _set_exit_door_state(is_open: bool) -> void:
	if not is_instance_valid(_exit_door_sprite):
		return
	var door_texture := AtlasTexture.new()
	door_texture.atlas = DUNGEON_DOOR_SHEET
	door_texture.region = OPEN_DOOR_REGION if is_open else LOCKED_DOOR_REGION
	_exit_door_sprite.texture = door_texture
	(get_node("/root/AudioManager") as GameAudioManager).play_sfx(
		"door_unlock" if is_open else "door_lock"
	)
	_spawn_door_state_effect(is_open)


func _spawn_door_state_effect(is_open: bool) -> void:
	var effect_texture := AtlasTexture.new()
	effect_texture.atlas = DOOR_STATE_EFFECT_SHEET
	effect_texture.region = Rect2(
		Vector2(DOOR_STATE_EFFECT_FRAME_SIZE.x if is_open else 0.0, 0.0),
		DOOR_STATE_EFFECT_FRAME_SIZE
	)
	var effect := _world_geometry.get_node_or_null("DoorStateEffect") as Sprite2D
	if effect == null:
		push_error("The dungeon room scene is missing its static DoorStateEffect node.")
		return
	effect.texture = effect_texture
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.position = _exit_door_sprite.position
	effect.scale = Vector2.ONE * 0.12
	effect.z_index = 2
	effect.visible = true
	effect.modulate.a = 1.0
	var tween := effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func() -> void: effect.visible = false)


func _create_wall_torches() -> void:
	for torch_index in 2:
		var torch_name := "WallTorch%d" % (torch_index + 1)
		var torch := _world_geometry.get_node_or_null(torch_name) as Sprite2D
		if torch == null:
			push_error("The dungeon room scene is missing static node %s." % torch_name)
			continue
		var torch_texture := AtlasTexture.new()
		torch_texture.atlas = PROP_SHEET
		torch_texture.region = WALL_TORCH_REGION
		torch.texture = torch_texture
		torch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		torch.position = Vector2(96.0 if torch_index == 0 else ROOM_SIZE.x - 96.0, 210.0)
		torch.scale = Vector2(0.32, 0.32)
		torch.flip_h = torch_index == 1
		torch.z_index = 1
		torch.visible = true


func _configure_floor_layer() -> void:
	var floor_layer := get_node_or_null("FloorLayer") as TileMapLayer
	if floor_layer == null:
		push_error("A dungeon room is missing its FloorLayer TileMapLayer.")
		return

	var is_deep_dungeon := floor_definition.floor_number >= 5
	floor_layer.tile_set = _get_floor_tile_set(is_deep_dungeon)
	floor_layer.position = Vector2(
		(ROOM_SIZE.x - FLOOR_TILE_SIZE.x * FLOOR_LAYER_COLUMNS) * 0.5,
		(ROOM_SIZE.y - FLOOR_TILE_SIZE.y * FLOOR_LAYER_ROWS) * 0.5
	)
	floor_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_layer.clear()
	for y in range(FLOOR_LAYER_ROWS):
		for x in range(FLOOR_LAYER_COLUMNS):
			var tile_index := posmod(layout_seed + x * 5 + y * 7 + x * y * 2, FLOOR_ATLAS_COLUMNS * FLOOR_ATLAS_ROWS)
			var atlas_coords := Vector2i(
				posmod(tile_index, FLOOR_ATLAS_COLUMNS),
				floori(float(tile_index) / FLOOR_ATLAS_COLUMNS)
			)
			floor_layer.set_cell(Vector2i(x, y), 0, atlas_coords)

	var is_boss_room := floor_definition.boss_id != &"" and room_index == floor_definition.room_count - 1
	floor_layer.visible = not is_boss_room


static func _get_floor_tile_set(is_deep_dungeon: bool) -> TileSet:
	var cache_key := "deep" if is_deep_dungeon else "upper"
	if _floor_tile_sets.has(cache_key):
		return _floor_tile_sets[cache_key] as TileSet

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = DEEP_FLOOR_ATLAS if is_deep_dungeon else UPPER_FLOOR_ATLAS
	atlas_source.texture_region_size = FLOOR_TILE_SIZE
	atlas_source.margins = FLOOR_ATLAS_MARGIN
	atlas_source.separation = FLOOR_ATLAS_SEPARATION
	for y in range(FLOOR_ATLAS_ROWS):
		for x in range(FLOOR_ATLAS_COLUMNS):
			atlas_source.create_tile(Vector2i(x, y))

	var tile_set := TileSet.new()
	tile_set.tile_size = FLOOR_TILE_SIZE
	tile_set.add_source(atlas_source, 0)
	_floor_tile_sets[cache_key] = tile_set
	return tile_set


func _draw() -> void:
	if floor_definition == null:
		return
	var is_boss_room := floor_definition.boss_id != &"" and room_index == floor_definition.room_count - 1
	if is_boss_room:
		var texture_size := BOSS_ARENA_BACKGROUND.get_size()
		var cover_scale := maxf(ROOM_SIZE.x / texture_size.x, ROOM_SIZE.y / texture_size.y)
		var source_size := ROOM_SIZE / cover_scale
		var source_origin := (texture_size - source_size) * 0.5
		draw_texture_rect_region(
			BOSS_ARENA_BACKGROUND,
			Rect2(Vector2.ZERO, ROOM_SIZE),
			Rect2(source_origin, source_size),
			Color(0.82, 0.82, 0.9, 1.0)
		)
		draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.02, 0.015, 0.03, 0.2))
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.02, 0.015, 0.03, 0.12))
