extends Node2D
class_name Level01Controller

signal choice_requested(choice_kind: String)
signal level_finished(completed: bool, record: Dictionary)
signal pause_requested
signal floor_cleared(floor_number: int)
signal potion_collected(stack_count: int)

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var previous_self_scene: PackedScene
@export var room_scene: PackedScene
@export var boss_scene: PackedScene

const FLOOR_DEFINITIONS := [
	preload("res://resources/dungeon/floor_01.tres"),
	preload("res://resources/dungeon/floor_02.tres"),
	preload("res://resources/dungeon/floor_03.tres"),
	preload("res://resources/dungeon/floor_04.tres"),
	preload("res://resources/dungeon/floor_05.tres"),
	preload("res://resources/dungeon/floor_06.tres"),
	preload("res://resources/dungeon/floor_07.tres"),
	preload("res://resources/dungeon/floor_08.tres"),
	preload("res://resources/dungeon/floor_09.tres"),
	preload("res://resources/dungeon/floor_10.tres"),
]

var run_stats: Dictionary = {}
var saved_echoes: Array[Dictionary] = []
var run_number: int = 1
var points_total: int = 0

var _player: RunnerController
var _hud: CanvasLayer
var _audio_manager: GameAudioManager
var _touch_controls: TouchControls
var _room_container: Node2D
var _current_room: DungeonRoom
var _previous_room: DungeonRoom
var _preview_room: DungeonRoom
var _floor_index := 0
var _room_index := 0
var _transition_pending := false
var _run_over := false
var _completed_floor_rewards: Dictionary = {}
var _last_known_player_health := -1


func _process(_delta: float) -> void:
	if _current_room != null and _current_room.is_exit_unlocked() and _current_room.is_player_at_exit(_player):
		_on_room_exit_entered()


func _ready() -> void:
	set_process(false)
	_audio_manager = get_node("/root/AudioManager") as GameAudioManager
	_player = $Player as RunnerController
	_hud = $HUD as CanvasLayer
	_hud.visible = false
	_room_container = $Rooms as Node2D
	_preview_room = $Rooms/DungeonRoom as DungeonRoom
	if room_scene == null or enemy_scene == null:
		push_error("The dungeon scene requires room and enemy scenes.")
		return

	if run_stats.is_empty():
		run_stats = {"max_health": 100, "attack_damage": 10, "move_speed": 200.0}

	_touch_controls = _hud.call("get_touch_controls") as TouchControls
	_player.configure(run_stats, _touch_controls)
	_player.set_controls_enabled(false)
	_last_known_player_health = _player.health
	_player.health_changed.connect(func(current: int, maximum: int) -> void:
		_hud.call("set_health", current, maximum)
		_on_player_health_changed(current)
	)
	_player.potion_count_changed.connect(_hud.set_potion_count)
	_player.attack_performed.connect(func() -> void:
		var effect_name := "crossbow_fire" if _player.get_current_weapon_id() == &"warden_crossbow" else "attack"
		_audio_manager.play_sfx(effect_name)
	)
	_player.dodge_started.connect(_audio_manager.play_sfx.bind("dash"))
	_player.player_died.connect(_on_player_died)
	_player.weapon_changed.connect(_hud.set_weapon)
	_player.position = Vector2(640.0, 610.0)
	_hud.call("set_health", _player.health, _player.max_health)
	_hud.call("set_potion_count", _player.potion_count)
	_hud.call("set_weapon", _player.get_current_weapon_name(), _player.get_current_weapon_id())
	_hud.call("set_points", points_total)

	if _touch_controls != null:
		_touch_controls.attack_pressed.connect(_player.request_attack)
		_touch_controls.weapon_switch_pressed.connect(_player.switch_weapon)
		_touch_controls.dodge_pressed.connect(_player.request_dodge)
		_touch_controls.interact_pressed.connect(_try_interact)
		_touch_controls.target_tapped.connect(_on_target_tapped)
		_hud.pause_pressed.connect(func() -> void: pause_requested.emit())


func begin_run(
	stats: Dictionary,
	echoes: Array[Dictionary],
	new_run_number: int,
	starting_points: int
) -> void:
	run_stats = stats.duplicate(true)
	saved_echoes = echoes.duplicate(true)
	run_number = new_run_number
	points_total = starting_points
	_floor_index = 0
	_room_index = 0
	_transition_pending = false
	_run_over = false
	_completed_floor_rewards.clear()
	_player.configure(run_stats, _touch_controls)
	_player.position = Vector2(640.0, 610.0)
	_player.velocity = Vector2.ZERO
	_hud.visible = true
	_last_known_player_health = _player.health
	_hud.call("set_health", _player.health, _player.max_health)
	_hud.call("set_weapon", _player.get_current_weapon_name(), _player.get_current_weapon_id())
	_hud.call("set_points", points_total)
	_load_current_room()


func end_run() -> void:
	_run_over = true
	set_process(false)
	_hud.visible = false
	if _player != null:
		_player.set_controls_enabled(false)
	if is_instance_valid(_current_room):
		_current_room.queue_free()
	if is_instance_valid(_previous_room):
		_previous_room.queue_free()
	_current_room = null
	_previous_room = null
	_transition_pending = false
	_preview_room = null


func get_current_floor_number() -> int:
	return _floor_index + 1


func get_current_room_number() -> int:
	return _room_index + 1


func get_current_room() -> DungeonRoom:
	return _current_room


func set_choice_paused(paused: bool) -> void:
	if _player != null:
		_player.set_controls_enabled(not paused)


func set_points_total(value: int) -> void:
	points_total = maxi(0, value)
	if _hud != null:
		_hud.call("set_points", points_total)


func show_floor_reward(floor_number: int, reward: int) -> void:
	if _hud != null:
		_hud.call("set_zone", "FLOOR %02d CLEARED  /  +%d SCRAP" % [floor_number, reward])


func choose_route(_route: String) -> void:
	push_warning("Route selection is not part of the ten-floor dungeon flow.")


func choose_previous_self(_response: String) -> void:
	push_warning("Previous-self encounters use stat snapshots and do not have a pre-fight response choice.")


func _load_current_room() -> void:
	set_process(false)
	_player.set_locked_target(null)
	var floor_definition := FLOOR_DEFINITIONS[_floor_index] as FloorDefinition
	if is_instance_valid(_preview_room):
		_current_room = _preview_room
		_preview_room = null
	else:
		_current_room = room_scene.instantiate() as DungeonRoom
	if _current_room == null:
		push_error("The configured room scene is not a DungeonRoom.")
		return
	_audio_manager.set_music_theme("combat")
	_current_room.position = Vector2(
		0.0,
		-float(_get_global_room_index()) * DungeonRoom.ROOM_SIZE.y
	)
	_current_room.configure(
		floor_definition,
		_room_index,
		_player,
		enemy_scene,
		previous_self_scene,
		boss_scene,
		saved_echoes,
		_get_room_layout_seed()
	)
	_current_room.room_cleared.connect(_on_room_cleared)
	_current_room.exit_entered.connect(_on_room_exit_entered)
	_current_room.potion_collected.connect(_on_potion_collected)
	_current_room.boss_encounter_started.connect(_on_boss_encounter_started)
	_current_room.boss_health_changed.connect(_hud.set_boss_health)
	_current_room.boss_defeated.connect(_on_boss_defeated)
	if _current_room.get_parent() != _room_container:
		_room_container.add_child(_current_room)
	_player.global_position = _current_room.to_global(Vector2(640.0, 610.0))
	_player.velocity = Vector2.ZERO
	_update_hud_location(floor_definition)


func _on_target_tapped(screen_position: Vector2) -> void:
	if not _player.controls_enabled or _current_room == null:
		return
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	var enemy_container := _current_room.get_node_or_null("Enemies") as Node2D
	if camera == null or enemy_container == null:
		return
	var nearest_target: Node2D
	var nearest_distance := 72.0
	for candidate in enemy_container.get_children():
		var enemy := candidate as Node2D
		if (
			enemy == null
			or not enemy.is_in_group("enemies")
			or not enemy.has_method("take_damage")
			or int(enemy.get("health")) <= 0
		):
			continue
		var enemy_screen_position := camera.get_canvas_transform() * enemy.global_position
		var distance := screen_position.distance_to(enemy_screen_position)
		if distance < nearest_distance:
			nearest_target = enemy
			nearest_distance = distance
	if nearest_target != null:
		_player.set_locked_target(nearest_target)


func _get_global_room_index() -> int:
	var global_room_index := _room_index
	for previous_floor_index in range(_floor_index):
		var previous_floor := FLOOR_DEFINITIONS[previous_floor_index] as FloorDefinition
		global_room_index += previous_floor.room_count
	return global_room_index


func _get_room_layout_seed() -> int:
	var seed := _room_index
	for previous_floor_index in range(_floor_index):
		var previous_floor := FLOOR_DEFINITIONS[previous_floor_index] as FloorDefinition
		seed += previous_floor.room_count
	return seed


func _on_room_cleared(floor_number: int, room_number: int) -> void:
	var floor_definition := FLOOR_DEFINITIONS[floor_number - 1] as FloorDefinition
	if room_number == floor_definition.room_count:
		_complete_floor(floor_number)
	if _run_over:
		return
	_audio_manager.set_music_theme("exploration")
	set_process(not _run_over)
	if room_number != floor_definition.room_count:
		_hud.call("set_zone", "FLOOR %02d  /  ROOM %02d CLEARED" % [floor_number, room_number])


func _on_boss_encounter_started(boss: DungeonBoss) -> void:
	_audio_manager.set_music_theme("boss")
	_audio_manager.play_sfx("boss_entrance")
	boss.start_encounter()


func _on_boss_defeated(boss_id: StringName) -> void:
	_hud.hide_boss_health()
	if boss_id == &"hollow_warden":
		_complete_floor(10)
		_finish_run(true)


func _complete_floor(floor_number: int) -> void:
	if _completed_floor_rewards.has(floor_number):
		return
	_completed_floor_rewards[floor_number] = true
	floor_cleared.emit(floor_number)


func _on_room_exit_entered() -> void:
	if _run_over or _transition_pending or _current_room == null or not _current_room.is_exit_unlocked():
		return
	_transition_pending = true
	set_process(false)
	call_deferred("_advance_from_exit")


func _advance_from_exit() -> void:
	if _run_over or _current_room == null or not _current_room.is_exit_unlocked():
		_transition_pending = false
		set_process(_current_room != null and _current_room.is_exit_unlocked())
		return
	var floor_definition := FLOOR_DEFINITIONS[_floor_index] as FloorDefinition
	var changes_floor := (
		_room_index + 1 >= floor_definition.room_count
		and _floor_index + 1 < FLOOR_DEFINITIONS.size()
	)
	var changes_room := _room_index + 1 < floor_definition.room_count
	if changes_floor:
		var next_floor := FLOOR_DEFINITIONS[_floor_index + 1] as FloorDefinition
		_player.set_controls_enabled(false)
		await _hud.call("show_floor_transition", next_floor.floor_number, next_floor.floor_name)
	elif changes_room:
		_player.set_controls_enabled(false)
		await _hud.call("show_room_transition")
	if _run_over:
		return

	if _room_index + 1 < floor_definition.room_count:
		_room_index += 1
	elif _floor_index + 1 < FLOOR_DEFINITIONS.size():
		_floor_index += 1
		_room_index = 0
	else:
		_finish_run(true)
		_transition_pending = false
		return
	if is_instance_valid(_previous_room):
		_previous_room.queue_free()
	_previous_room = _current_room
	_current_room = null
	_load_current_room()
	if changes_floor:
		await _hud.call("hide_floor_transition")
	elif changes_room:
		await _hud.call("hide_room_transition")
	if _run_over:
		return
	_player.set_controls_enabled(true)
	_transition_pending = false


func _update_hud_location(floor_definition: FloorDefinition) -> void:
	_hud.call(
		"set_zone",
		"FLOOR %02d / 10  ·  %s  ·  ROOM %02d / %02d" % [
			floor_definition.floor_number,
			floor_definition.floor_name.to_upper(),
			_room_index + 1,
			floor_definition.room_count,
		]
	)


func _try_interact() -> void:
	if _current_room != null and _current_room.is_exit_unlocked() and _current_room.is_player_at_exit(_player):
		_on_room_exit_entered()
		return
	if _player != null and _player.use_potion():
		_hud.call("show_zone_message", "POTION USED  /  %d LEFT" % _player.potion_count)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


func _on_player_health_changed(current: int) -> void:
	if current < _last_known_player_health:
		_audio_manager.play_sfx("damage")
	_last_known_player_health = current


func _on_potion_collected(stack_count: int) -> void:
	potion_collected.emit(stack_count)
	_hud.call("show_zone_message", "POTION ACQUIRED  /  USE ×%d" % stack_count)


func _on_player_died() -> void:
	_finish_run(false)


func _finish_run(completed: bool) -> void:
	if _run_over:
		return
	_run_over = true
	set_process(false)
	_player.set_controls_enabled(false)
	_audio_manager.play_sfx("victory" if completed else "defeat")
	var run_record := _player.build_run_record()
	if not completed and is_instance_valid(_current_room):
		var death_position := _current_room.to_local(_player.global_position)
		run_record["death_floor"] = _floor_index + 1
		run_record["death_room"] = _room_index + 1
		run_record["death_position"] = {"x": death_position.x, "y": death_position.y}
	level_finished.emit(completed, run_record)
