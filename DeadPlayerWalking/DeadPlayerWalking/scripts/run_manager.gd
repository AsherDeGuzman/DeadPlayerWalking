extends Node
class_name PersistentRunManager

signal run_finished(completed: bool, reward: int, total_points: int, recorded_echo: bool)
signal progression_changed

const SAVE_PATH := "user://dead_player_walking.cfg"
const MAX_ECHO_RECORDS := 3
const MAX_PROFILE_NAME_LENGTH := 20
const LEGACY_PROFILE_NAME := "Survivor"
const FLOOR_CLEAR_REWARD := 30
const DEATH_REWARD := 10
const FLOOR_BOSS_BONUSES := {10: 100}
const FLOOR_COUNT := 10
const MAX_ROOMS_PER_FLOOR := 8
const UPGRADE_COSTS := {
	"health": 20,
	"damage": 25,
	"speed": 20,
	"dungeon_edge": 30,
	"warden_crossbow": 30,
}
const UPGRADE_MAX_LEVELS := {
	"health": 99,
	"damage": 99,
	"speed": 99,
	"dungeon_edge": 5,
	"warden_crossbow": 5,
}
const UPGRADE_DEFINITIONS := {
	"health": {"name": "VITALS", "description": "+10 maximum health", "stat": "max_health"},
	"damage": {"name": "EDGE", "description": "+2 base attack damage", "stat": "attack_damage"},
	"speed": {"name": "MOBILITY", "description": "+10 movement speed", "stat": "move_speed"},
	"dungeon_edge": {"name": "DUNGEON EDGE", "description": "+12% sword damage", "stat": "sword_damage_multiplier"},
	"warden_crossbow": {"name": "WARDEN CROSSBOW", "description": "+12% bolt damage", "stat": "crossbow_damage_multiplier"},
}

var points: int = 0
var attempts: int = 0
var upgrade_levels: Dictionary = {
	"health": 0,
	"damage": 0,
	"speed": 0,
	"dungeon_edge": 0,
	"warden_crossbow": 0,
}
var echo_records: Array[Dictionary] = []
var run_active: bool = false
var music_volume := 1.0
var sfx_volume := 1.0
var active_profile_name := ""
var entry_tutorial_completed := false
var _run_reward := 0
var _cleared_floors: Dictionary = {}
var _profiles: Dictionary = {}


func _ready() -> void:
	_load_progress()


func get_player_stats() -> Dictionary:
	var total_upgrade_levels := 0
	for level in upgrade_levels.values():
		total_upgrade_levels += int(level)
	return {
		"max_health": 100 + int(upgrade_levels["health"]) * 10,
		"attack_damage": 10 + int(upgrade_levels["damage"]) * 2,
		"move_speed": 200.0 + int(upgrade_levels["speed"]) * 10.0,
		"sword_damage_multiplier": 1.0 + int(upgrade_levels["dungeon_edge"]) * 0.12,
		"crossbow_damage_multiplier": 1.0 + int(upgrade_levels["warden_crossbow"]) * 0.12,
		"mob_stat_multiplier": pow(1.003, float(total_upgrade_levels)),
	}


func get_progress_snapshot() -> Dictionary:
	return {
		"profile": active_profile_name,
		"points": points,
		"attempts": attempts,
		"upgrades": upgrade_levels.duplicate(true),
		"echo_count": echo_records.size(),
		"entry_tutorial_completed": entry_tutorial_completed,
	}


func get_profiles() -> Array[String]:
	var names: Array[String] = []
	for profile in _profiles.values():
		if typeof(profile) == TYPE_DICTIONARY:
			var username := str(profile.get("username", ""))
			if not username.is_empty():
				names.append(username)
	names.sort()
	return names


func mark_entry_tutorial_completed() -> bool:
	if entry_tutorial_completed:
		return true
	if active_profile_name.is_empty():
		push_warning("The entry tutorial cannot be recorded without an active profile.")
		return false

	entry_tutorial_completed = true
	if _save_progress():
		return true

	entry_tutorial_completed = false
	var profile_key := _profile_key(active_profile_name)
	if _profiles.has(profile_key):
		var profile: Dictionary = (_profiles[profile_key] as Dictionary).duplicate(true)
		profile["entry_tutorial_completed"] = false
		_profiles[profile_key] = profile
	return false


func validate_profile_name(username: String) -> String:
	var normalized_name := username.strip_edges()
	if normalized_name.is_empty():
		return "Enter a username."
	if normalized_name.length() > MAX_PROFILE_NAME_LENGTH:
		return "Use %d characters or fewer." % MAX_PROFILE_NAME_LENGTH
	if normalized_name.contains("\n") or normalized_name.contains("\r"):
		return "Usernames must fit on one line."
	if _profiles.has(_profile_key(normalized_name)):
		return "That username already exists. Select it from saved profiles."
	return ""


func create_profile(username: String) -> bool:
	var validation_error := validate_profile_name(username)
	if not validation_error.is_empty():
		return false
	var previous_profile_name := active_profile_name
	if not previous_profile_name.is_empty() and not _save_progress():
		return false

	var normalized_name := username.strip_edges()
	var profile_key := _profile_key(normalized_name)
	_profiles[profile_key] = _empty_profile_data(normalized_name)
	active_profile_name = normalized_name
	_apply_profile(_profiles[profile_key] as Dictionary)
	if _save_progress():
		return true

	_profiles.erase(profile_key)
	active_profile_name = previous_profile_name
	if previous_profile_name.is_empty():
		_reset_progress()
	else:
		_apply_profile(_profiles[_profile_key(previous_profile_name)] as Dictionary)
	return false


func select_profile(username: String) -> bool:
	var profile_key := _profile_key(username)
	if not _profiles.has(profile_key):
		return false
	if not active_profile_name.is_empty() and not _save_progress():
		return false
	active_profile_name = str((_profiles[profile_key] as Dictionary).get("username", username))
	_apply_profile(_profiles[profile_key] as Dictionary)
	return true


func set_audio_volumes(music: float, effects: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(effects, 0.0, 1.0)


func save_settings() -> void:
	_save_progress()


func get_upgrade_level(upgrade: String) -> int:
	if not upgrade_levels.has(upgrade):
		return 0
	return int(upgrade_levels[upgrade])


func is_upgrade_maxed(upgrade: String) -> bool:
	return UPGRADE_MAX_LEVELS.has(upgrade) and get_upgrade_level(upgrade) >= int(UPGRADE_MAX_LEVELS[upgrade])


func get_echo_records() -> Array[Dictionary]:
	return echo_records.duplicate(true)


func begin_run() -> int:
	if run_active:
		push_warning("A run is already active; the duplicate start request was ignored.")
		return attempts
	run_active = true
	_run_reward = 0
	_cleared_floors.clear()
	attempts += 1
	_save_progress()
	return attempts


func award_floor_clear(floor_number: int) -> int:
	if not run_active:
		push_warning("A floor reward was requested while no run was active.")
		return 0
	if floor_number < 1 or floor_number > FLOOR_COUNT:
		push_warning("A floor reward was requested for an invalid floor: %d." % floor_number)
		return 0
	if _cleared_floors.has(floor_number):
		push_warning("Floor %d was awarded more than once in a run." % floor_number)
		return 0
	if floor_number != _cleared_floors.size() + 1:
		push_warning("Floor %d was cleared out of order." % floor_number)
		return 0

	var reward := FLOOR_CLEAR_REWARD + int(FLOOR_BOSS_BONUSES.get(floor_number, 0))
	_cleared_floors[floor_number] = true
	_run_reward += reward
	points += reward
	_save_progress()
	progression_changed.emit()
	return reward


func finish_run(completed: bool, run_record: Dictionary) -> void:
	if not run_active:
		push_warning("A run outcome was received while no run was active.")
		return

	run_active = false
	if not completed:
		_run_reward += DEATH_REWARD
		points += DEATH_REWARD
	var reward := _run_reward
	var recorded_echo := false

	if not completed:
		var safe_record := _sanitize_record(run_record)
		if not safe_record.is_empty():
			echo_records.append(safe_record)
			while echo_records.size() > MAX_ECHO_RECORDS:
				echo_records.pop_front()
			recorded_echo = true

	_save_progress()
	run_finished.emit(completed, reward, points, recorded_echo)
	progression_changed.emit()


func purchase_upgrade(upgrade: String) -> bool:
	if not UPGRADE_COSTS.has(upgrade) or not upgrade_levels.has(upgrade):
		push_warning("Unknown permanent upgrade requested: %s" % upgrade)
		return false
	if is_upgrade_maxed(upgrade):
		return false

	var cost: int = UPGRADE_COSTS[upgrade]
	if points < cost:
		return false

	points -= cost
	upgrade_levels[upgrade] = int(upgrade_levels[upgrade]) + 1
	_save_progress()
	progression_changed.emit()
	return true


func get_upgrade_cost(upgrade: String) -> int:
	if not UPGRADE_COSTS.has(upgrade):
		return 0
	return int(UPGRADE_COSTS[upgrade])


func _sanitize_record(source: Dictionary) -> Dictionary:
	var safe_record := _sanitize_snapshot(source)
	if safe_record.is_empty():
		push_warning("A death snapshot had invalid character statistics and was not saved.")
		return {}
	_copy_death_location(source, safe_record)
	var record_number := maxi(1, attempts)
	safe_record["label"] = "ECHO-%02d" % record_number
	return safe_record


func _load_progress() -> void:
	var config := ConfigFile.new()
	var result := config.load(SAVE_PATH)
	if result == ERR_FILE_NOT_FOUND:
		return
	if result != OK:
		push_warning("Save data could not be loaded (%s); starting with safe defaults." % error_string(result))
		return

	points = maxi(0, int(config.get_value("progress", "points", 0)))
	attempts = maxi(0, int(config.get_value("progress", "attempts", 0)))
	music_volume = clampf(float(config.get_value("settings", "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx_volume", 1.0)), 0.0, 1.0)

	var saved_profiles: Variant = config.get_value("profiles", "records", {})
	if typeof(saved_profiles) == TYPE_DICTIONARY:
		for raw_key in saved_profiles:
			if typeof(raw_key) != TYPE_STRING or typeof(saved_profiles[raw_key]) != TYPE_DICTIONARY:
				push_warning("A saved player profile had an invalid key or data and was ignored.")
				continue
			var source: Dictionary = saved_profiles[raw_key]
			var username := str(source.get("username", "")).strip_edges()
			if username.is_empty() or _profile_key(username) != str(raw_key):
				push_warning("A saved player profile had an invalid username and was ignored.")
				continue
			_profiles[str(raw_key)] = _sanitize_profile_data(username, source)
	if not _profiles.is_empty():
		return

	var has_legacy_progress := (
		config.has_section_key("progress", "points")
		or config.has_section_key("progress", "attempts")
		or config.has_section_key("history", "echoes")
	)
	if not has_legacy_progress:
		return

	var legacy_data := {
		"username": LEGACY_PROFILE_NAME,
		"points": config.get_value("progress", "points", 0),
		"attempts": config.get_value("progress", "attempts", 0),
		"upgrades": config.get_value("progress", "upgrades", {}),
		"echoes": config.get_value("history", "echoes", []),
	}
	_profiles[_profile_key(LEGACY_PROFILE_NAME)] = _sanitize_profile_data(LEGACY_PROFILE_NAME, legacy_data)
	_write_store()


func _profile_key(username: String) -> String:
	return username.strip_edges().to_lower()


func _empty_profile_data(username: String) -> Dictionary:
	var empty_upgrades: Dictionary = {}
	for key in upgrade_levels:
		empty_upgrades[key] = 0
	return {
		"username": username,
		"points": 0,
		"attempts": 0,
		"upgrades": empty_upgrades,
		"echoes": [],
		"entry_tutorial_completed": false,
	}


func _sanitize_profile_data(username: String, source: Dictionary) -> Dictionary:
	var safe_upgrades: Dictionary = {}
	var loaded_upgrades: Variant = source.get("upgrades", {})
	for key in upgrade_levels:
		var level := 0
		if typeof(loaded_upgrades) == TYPE_DICTIONARY:
			level = int(loaded_upgrades.get(key, 0))
		safe_upgrades[key] = clampi(level, 0, int(UPGRADE_MAX_LEVELS[key]))

	var safe_echoes: Array[Dictionary] = []
	var loaded_records: Variant = source.get("echoes", [])
	if typeof(loaded_records) == TYPE_ARRAY:
		for item in loaded_records:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var record := _sanitize_loaded_record(item)
			if not record.is_empty():
				safe_echoes.append(record)
			if safe_echoes.size() >= MAX_ECHO_RECORDS:
				break
	var saved_tutorial_state: Variant = source.get("entry_tutorial_completed", false)

	return {
		"username": username,
		"points": maxi(0, int(source.get("points", 0))),
		"attempts": maxi(0, int(source.get("attempts", 0))),
		"upgrades": safe_upgrades,
		"echoes": safe_echoes,
		"entry_tutorial_completed": (
			bool(saved_tutorial_state) if typeof(saved_tutorial_state) == TYPE_BOOL else false
		),
	}


func _apply_profile(profile: Dictionary) -> void:
	points = int(profile.get("points", 0))
	attempts = int(profile.get("attempts", 0))
	var saved_upgrades: Variant = profile.get("upgrades", {})
	for key in upgrade_levels:
		upgrade_levels[key] = int(saved_upgrades.get(key, 0)) if typeof(saved_upgrades) == TYPE_DICTIONARY else 0
	echo_records.clear()
	var saved_echoes: Variant = profile.get("echoes", [])
	if typeof(saved_echoes) == TYPE_ARRAY:
		for record in saved_echoes:
			if typeof(record) == TYPE_DICTIONARY:
				echo_records.append(record.duplicate(true))
	entry_tutorial_completed = bool(profile.get("entry_tutorial_completed", false))
	run_active = false
	_run_reward = 0
	_cleared_floors.clear()


func _reset_progress() -> void:
	points = 0
	attempts = 0
	for key in upgrade_levels:
		upgrade_levels[key] = 0
	echo_records.clear()
	entry_tutorial_completed = false
	run_active = false
	_run_reward = 0
	_cleared_floors.clear()


func _sanitize_loaded_record(source: Dictionary) -> Dictionary:
	var safe_record := _sanitize_snapshot(source)
	if not safe_record.is_empty():
		_copy_death_location(source, safe_record)
	return safe_record


func _copy_death_location(source: Dictionary, target: Dictionary) -> void:
	var floor_number := int(source.get("death_floor", 0))
	var room_number := int(source.get("death_room", 0))
	var source_position: Variant = source.get("death_position", {})
	if (
		floor_number < 1
		or floor_number > FLOOR_COUNT
		or room_number < 1
		or room_number > MAX_ROOMS_PER_FLOOR
		or typeof(source_position) != TYPE_DICTIONARY
	):
		return
	var x_position: Variant = source_position.get("x")
	var y_position: Variant = source_position.get("y")
	if (
		typeof(x_position) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(y_position) not in [TYPE_INT, TYPE_FLOAT]
	):
		return
	target["death_floor"] = floor_number
	target["death_room"] = room_number
	target["death_position"] = {
		"x": clampf(float(x_position), 32.0, 1248.0),
		"y": clampf(float(y_position), 32.0, 688.0),
	}


func _sanitize_snapshot(source: Dictionary) -> Dictionary:
	if not source.has("max_health") or not source.has("attack_damage") or not source.has("move_speed"):
		return {}

	var raw_weapons: Variant = source.get("weapon_archetypes", ["dungeon_edge", "warden_crossbow"])
	if typeof(raw_weapons) != TYPE_ARRAY:
		return {}
	var weapon_archetypes: Array[String] = []
	for item in raw_weapons:
		var weapon_id := str(item)
		if weapon_id in ["dungeon_edge", "warden_crossbow"] and weapon_id not in weapon_archetypes:
			weapon_archetypes.append(weapon_id)
	if weapon_archetypes.is_empty():
		return {}

	return {
		"label": str(source.get("label", "ECHO")),
		"max_health": clampi(int(source["max_health"]), 1, 2000),
		"attack_damage": clampi(int(source["attack_damage"]), 1, 500),
		"move_speed": clampf(float(source["move_speed"]), 80.0, 400.0),
		"weapon_archetypes": weapon_archetypes,
	}


func _save_progress() -> bool:
	if not active_profile_name.is_empty():
		_profiles[_profile_key(active_profile_name)] = {
			"username": active_profile_name,
			"points": points,
			"attempts": attempts,
			"upgrades": upgrade_levels.duplicate(true),
			"echoes": echo_records.duplicate(true),
			"entry_tutorial_completed": entry_tutorial_completed,
		}
	return _write_store()


func _write_store() -> bool:
	var config := ConfigFile.new()
	var load_result := config.load(SAVE_PATH)
	if load_result != OK and load_result != ERR_FILE_NOT_FOUND:
		push_error("Existing save data could not be opened for update (%s)." % error_string(load_result))
		return false
	config.set_value("profiles", "records", _profiles)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)

	var result := config.save(SAVE_PATH)
	if result != OK:
		push_error("Could not save progression to %s (%s)." % [SAVE_PATH, error_string(result)])
		return false
	return true
