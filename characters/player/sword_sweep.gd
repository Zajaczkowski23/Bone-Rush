extends Node2D

var radius: float = 100.0
var duration: float = 0.4
var _elapsed: float = 0.0


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var head_angle := -PI / 2.0 + progress * TAU
	var trail_length := minf(progress * TAU, PI * 0.85)
	var opacity := sin(progress * PI)
	# A tapered blade trail completes one revolution around the player.
	for segment in range(12):
		var fraction := float(segment) / 12.0
		var start := head_angle - trail_length * (1.0 - fraction)
		var end := start + trail_length / 12.0
		var color := Color(0.85, 1.0, 0.75, opacity * fraction)
		draw_arc(Vector2.ZERO, radius, start, end, 5, color, 2.0 + fraction * 4.0, true)
