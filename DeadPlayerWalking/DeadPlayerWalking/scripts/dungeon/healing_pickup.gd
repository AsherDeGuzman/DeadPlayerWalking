extends Area2D
class_name HealingPickup

signal collected(amount: int)

const HEALING_ANIMATION_SHEET := preload("res://ASSETS/PICKUPS AND GAMEPLAY ASSETS/Asset 35 — Healing pickup animation.png")
const HEALING_FRAME_SIZE := Vector2(362.0, 724.0)

var _art: AnimatedSprite2D


func _ready() -> void:
	_art = $Art as AnimatedSprite2D
	_art.sprite_frames = _build_sprite_frames()
	_art.play("idle")
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	var player := body as RunnerController
	if player == null:
		return

	if not player.add_potion():
		return

	(get_node("/root/AudioManager") as GameAudioManager).play_sfx("healing")
	collected.emit(player.potion_count)
	queue_free()


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	frames.set_animation_loop("idle", true)
	for frame_index in 6:
		var frame := AtlasTexture.new()
		frame.atlas = HEALING_ANIMATION_SHEET
		frame.region = Rect2(
			Vector2(frame_index * HEALING_FRAME_SIZE.x, 0.0),
			HEALING_FRAME_SIZE
		)
		frames.add_frame("idle", frame)
	return frames
