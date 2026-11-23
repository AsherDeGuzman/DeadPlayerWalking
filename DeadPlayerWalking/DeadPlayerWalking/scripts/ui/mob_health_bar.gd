extends Node2D
class_name MobHealthBar

const BAR_SHEET := preload("res://ASSETS/ORDINARY ENEMY ASSETS/Mob Health Bars@2x.png")
const BAR_FRAME_REGION := Rect2(1576.0, 632.0, 120.0, 20.0)
const SEGMENT_COUNT := 4
const SEGMENT_WIDTH := 26.0
const SEGMENT_GAP := 2.0
const SEGMENT_LEFT := -56.0
const SEGMENT_TOP := -5.0
const TROUGH_COLOR := Color("2a0d12")

var _health_ratio := 1.0
var _chip_ratio := 1.0
var _chip_time := 0.0
var _pulse_time := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


func set_health(current: int, maximum: int) -> void:
	var new_ratio := clampf(float(current) / float(maxi(1, maximum)), 0.0, 1.0)
	if new_ratio < _health_ratio:
		_chip_ratio = maxf(_chip_ratio, _health_ratio)
		_chip_time = 0.24
	elif new_ratio >= _health_ratio:
		_chip_ratio = new_ratio
		_chip_time = 0.0
	_health_ratio = new_ratio
	visible = current > 0
	_update_animation_state()
	queue_redraw()


func _process(delta: float) -> void:
	_chip_time = maxf(0.0, _chip_time - delta)
	_pulse_time += delta
	queue_redraw()
	_update_animation_state()


func _update_animation_state() -> void:
	var is_critical := _health_ratio > 0.0 and _health_ratio <= 0.25
	set_process(_chip_time > 0.0 or is_critical)


func _draw() -> void:
	draw_texture_rect_region(
		BAR_SHEET,
		Rect2(-60.0, -10.0, 120.0, 20.0),
		BAR_FRAME_REGION
	)
	draw_rect(Rect2(-56.0, -6.0, 112.0, 12.0), TROUGH_COLOR)

	var pulse := 1.0
	if _health_ratio > 0.0 and _health_ratio <= 0.25:
		pulse = 0.62 + 0.38 * (0.5 + 0.5 * sin(_pulse_time * TAU * 1.6))
	for segment_index in SEGMENT_COUNT:
		var segment_left := SEGMENT_LEFT + float(segment_index) * (SEGMENT_WIDTH + SEGMENT_GAP)
		var fill_ratio := clampf(_health_ratio * SEGMENT_COUNT - float(segment_index), 0.0, 1.0)
		var fill_width := SEGMENT_WIDTH * fill_ratio
		if fill_width > 0.0:
			draw_rect(
				Rect2(segment_left, SEGMENT_TOP, fill_width, 3.0),
				Color("ff7a7a", pulse)
			)
			draw_rect(
				Rect2(segment_left, SEGMENT_TOP + 3.0, fill_width, 4.0),
				Color("d12b3a", pulse)
			)
			draw_rect(
				Rect2(segment_left, SEGMENT_TOP + 7.0, fill_width, 3.0),
				Color("8e1a28", pulse)
			)

		if _chip_time > 0.0:
			var chip_end := clampf(_chip_ratio * SEGMENT_COUNT - float(segment_index), 0.0, 1.0)
			if chip_end > fill_ratio:
				var chip_alpha := clampf(_chip_time / 0.24, 0.0, 1.0)
				draw_rect(
					Rect2(
						segment_left + fill_width,
						SEGMENT_TOP,
						SEGMENT_WIDTH * (chip_end - fill_ratio),
						10.0
					),
					Color("f3d9d0", chip_alpha)
				)

		if segment_index > 0:
			draw_rect(
				Rect2(segment_left - SEGMENT_GAP, -6.0, SEGMENT_GAP, 12.0),
				TROUGH_COLOR
			)
