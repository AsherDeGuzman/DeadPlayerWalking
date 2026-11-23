extends Node
class_name GameAudioManager

const MUSIC_TRACK_PATHS := {
	"menu": "res://assets/audio/menu_music.wav",
	"exploration": "res://assets/audio/dungeon_exploration.wav",
	"combat": "res://assets/audio/dungeon_combat.wav",
	"boss": "res://assets/audio/boss_music.wav",
	"death": "res://assets/audio/death_music.wav",
	"victory": "res://assets/audio/victory_music.wav",
}
const GENERATED_MUSIC_SAMPLE_RATE := 22050
const GENERATED_MUSIC_SECONDS := 8.0
const GENERATED_MUSIC_NOTES := {
	"menu": [55.0, 69.0, 82.0, 110.0],
	"exploration": [49.0, 62.0, 73.0, 98.0],
	"combat": [55.0, 65.0, 82.0, 110.0],
	"boss": [41.0, 49.0, 62.0, 82.0],
	"death": [49.0, 58.0, 69.0, 98.0],
	"victory": [65.0, 82.0, 98.0, 131.0],
}
const EFFECT_PATHS: Dictionary = {
	"attack": "res://assets/audio/strike.wav",
	"melee_impact": "res://assets/audio/melee_impact.wav",
	"crossbow_fire": "res://assets/audio/crossbow_fire.wav",
	"projectile_impact": "res://assets/audio/projectile_impact.wav",
	"enemy_hit": "res://assets/audio/enemy_hit.wav",
	"dash": "res://assets/audio/dash.wav",
	"damage": "res://assets/audio/damage.wav",
	"footstep": "res://assets/audio/footstep.wav",
	"enemy_windup": "res://assets/audio/enemy_windup.wav",
	"enemy_down": "res://assets/audio/enemy_down.wav",
	"healing": "res://assets/audio/healing.wav",
	"door_lock": "res://assets/audio/door_lock.wav",
	"door_unlock": "res://assets/audio/door_unlock.wav",
	"weapon_switch": "res://assets/audio/weapon_switch.wav",
	"boss_entrance": "res://assets/audio/boss_entrance.wav",
	"boss_attack": "res://assets/audio/boss_attack.wav",
	"upgrade_purchase": "res://assets/audio/upgrade_purchase.wav",
	"hazard": "res://assets/audio/hazard_warning.wav",
	"victory": "res://assets/audio/victory.wav",
	"defeat": "res://assets/audio/defeat.wav",
	"ui": "res://assets/audio/ui_confirm.wav",
	"echo": "res://assets/audio/echo.wav",
}
const SFX_CHANNEL_COUNT := 8
const GENERATED_SAMPLE_RATE := 22050
const GENERATED_AMBIENCE_SECONDS := 2.0

var _music_player: AudioStreamPlayer
var _music_stream: AudioStreamWAV
var _music_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _effects: Dictionary = {}
var _next_sfx_channel := 0
var _music_theme: StringName = &""
var gameplay_paused := false
var music_volume := 1.0
var sfx_volume := 1.0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ContextMusic"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.bus = "Master"
	add_child(_music_player)
	set_music_theme("menu")

	for effect_name in EFFECT_PATHS:
		var effect_stream := _load_wave(str(EFFECT_PATHS[effect_name]))
		if effect_stream == null:
			effect_stream = _create_generated_wave(str(effect_name))
		_effects[effect_name] = effect_stream

	for channel_index in range(SFX_CHANNEL_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "SfxChannel%02d" % channel_index
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)


func play_sfx(effect_name: String) -> void:
	if not _effects.has(effect_name):
		push_error("Sound effect is missing or could not be loaded: %s" % effect_name)
		return

	var player := _sfx_players[_next_sfx_channel]
	_next_sfx_channel = (_next_sfx_channel + 1) % SFX_CHANNEL_COUNT
	player.stream = _effects[effect_name]
	player.volume_db = _volume_db(sfx_volume, -8.0)
	player.play()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = _volume_db(music_volume, -13.0)


func set_music_theme(theme_name: String) -> void:
	if not MUSIC_TRACK_PATHS.has(theme_name):
		push_error("Unknown music theme requested: %s" % theme_name)
		return
	if _music_theme == StringName(theme_name) and _music_player.stream != null:
		return

	if not _music_streams.has(theme_name):
		var stream := _load_wave(str(MUSIC_TRACK_PATHS[theme_name]))
		if stream == null:
			stream = _create_generated_music(theme_name)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music_streams[theme_name] = stream

	_music_theme = StringName(theme_name)
	_music_stream = _music_streams[theme_name] as AudioStreamWAV
	_music_player.stream = _music_stream
	_music_player.volume_db = _volume_db(music_volume, -13.0)
	_music_player.stream_paused = gameplay_paused
	_music_player.play()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)


func set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
	if _music_player != null:
		_music_player.stream_paused = paused
	for player in _sfx_players:
		player.stream_paused = paused


func _exit_tree() -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	for player in _sfx_players:
		player.stop()
		player.stream = null
	_effects.clear()
	_music_streams.clear()
	_music_stream = null
	_sfx_players.clear()


func _volume_db(value: float, base_db: float) -> float:
	return -80.0 if value <= 0.001 else base_db + linear_to_db(value)


func _load_wave(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		push_warning("Audio file is unavailable; a synthesized fallback will be used: %s" % path)
		return null
	var stream := AudioStreamWAV.load_from_file(path)
	if stream == null:
		push_warning("Audio file could not be decoded; a synthesized fallback will be used: %s" % path)
	return stream


func _create_generated_wave(effect_name: String, loop: bool = false) -> AudioStreamWAV:
	var duration := GENERATED_AMBIENCE_SECONDS if loop else 0.24
	var start_frequency := 220.0
	var end_frequency := 120.0
	match effect_name:
		"attack":
			start_frequency = 310.0
			end_frequency = 150.0
			duration = 0.18
		"melee_impact":
			start_frequency = 210.0
			end_frequency = 68.0
			duration = 0.16
		"crossbow_fire":
			start_frequency = 470.0
			end_frequency = 155.0
			duration = 0.18
		"projectile_impact":
			start_frequency = 165.0
			end_frequency = 58.0
			duration = 0.2
		"enemy_hit":
			start_frequency = 245.0
			end_frequency = 132.0
			duration = 0.14
		"dash":
			start_frequency = 180.0
			end_frequency = 520.0
			duration = 0.2
		"damage":
			start_frequency = 130.0
			end_frequency = 72.0
			duration = 0.32
		"footstep":
			start_frequency = 92.0
			end_frequency = 62.0
			duration = 0.09
		"enemy_windup":
			start_frequency = 145.0
			end_frequency = 285.0
			duration = 0.34
		"enemy_down":
			start_frequency = 230.0
			end_frequency = 74.0
			duration = 0.28
		"healing":
			start_frequency = 440.0
			end_frequency = 880.0
			duration = 0.48
		"door_lock":
			start_frequency = 205.0
			end_frequency = 84.0
			duration = 0.3
		"door_unlock":
			start_frequency = 185.0
			end_frequency = 465.0
			duration = 0.38
		"weapon_switch":
			start_frequency = 360.0
			end_frequency = 610.0
			duration = 0.12
		"boss_entrance":
			start_frequency = 58.0
			end_frequency = 116.0
			duration = 1.1
		"boss_attack":
			start_frequency = 105.0
			end_frequency = 315.0
			duration = 0.46
		"upgrade_purchase":
			start_frequency = 500.0
			end_frequency = 920.0
			duration = 0.32
		"hazard":
			start_frequency = 440.0
			end_frequency = 220.0
			duration = 0.4
		"victory":
			start_frequency = 330.0
			end_frequency = 660.0
			duration = 0.72
		"defeat":
			start_frequency = 240.0
			end_frequency = 82.0
			duration = 0.72
		"ui":
			start_frequency = 530.0
			end_frequency = 780.0
			duration = 0.12
		"echo":
			start_frequency = 118.0
			end_frequency = 240.0
			duration = 0.55

	var sample_count := roundi(float(GENERATED_SAMPLE_RATE) * duration)
	var pcm_data := PackedByteArray()
	pcm_data.resize(sample_count * 2)
	for sample_index in sample_count:
		var time := float(sample_index) / float(GENERATED_SAMPLE_RATE)
		var progress := time / duration
		var value: float
		if loop:
			var pulse := 0.82 + 0.18 * sin(TAU * time)
			value = (sin(TAU * 55.0 * time) * 0.48 + sin(TAU * 82.5 * time) * 0.3 + sin(TAU * 110.0 * time) * 0.22) * pulse * 0.1
		else:
			var phase := TAU * (start_frequency * time + (end_frequency - start_frequency) * time * time / (2.0 * duration))
			var envelope := pow(1.0 - progress, 2.0)
			value = (sin(phase) * 0.78 + sin(phase * 1.51) * 0.22) * envelope * 0.38
		pcm_data.encode_s16(sample_index * 2, roundi(clampf(value, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = GENERATED_SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm_data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


func _create_generated_music(theme_name: String) -> AudioStreamWAV:
	var notes: Array = GENERATED_MUSIC_NOTES[theme_name]
	var sample_count := roundi(float(GENERATED_MUSIC_SAMPLE_RATE) * GENERATED_MUSIC_SECONDS)
	var pcm_data := PackedByteArray()
	pcm_data.resize(sample_count * 2)
	var theme_gain := 0.075 if theme_name == "boss" else 0.055

	for sample_index in sample_count:
		var time := float(sample_index) / float(GENERATED_MUSIC_SAMPLE_RATE)
		var pulse := 0.78 + 0.22 * sin(TAU * time * 0.5)
		var value := 0.0
		for note_index in notes.size():
			var note_frequency := float(notes[note_index])
			var note_gain := 1.0 / float(note_index + 1)
			value += sin(TAU * note_frequency * time) * note_gain
			value += sin(TAU * note_frequency * 2.0 * time) * note_gain * 0.18
		value = value / 1.75 * pulse * theme_gain
		pcm_data.encode_s16(sample_index * 2, roundi(clampf(value, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = GENERATED_MUSIC_SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm_data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
