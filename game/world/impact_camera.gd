extends Camera2D

@export_range(0.0, 20.0) var shake_strength: float = 6.0
@export_range(0.05, 1.0) var shake_duration: float = 0.32
@export_range(1.0, 1000.0) var shake_radius: float = 320.0

var _elapsed: float = 0.0
var _strength: float = 0.0
@onready var _rest_offset: Vector2 = offset


func _ready() -> void:
	set_process(false)


func shake_from(world_position: Vector2) -> void:
	var proximity := clampf(1.0 - global_position.distance_to(world_position) / shake_radius, 0.0, 1.0)
	if proximity <= 0.0 or shake_strength <= 0.0:
		return
	_strength = shake_strength * proximity
	_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= shake_duration or _strength == 0.0:
		offset = _rest_offset
		_strength = 0.0
		set_process(false)
		return
	# Continuous oscillation avoids the jitter of a new random offset each frame.
	var fade := pow(1.0 - _elapsed / shake_duration, 2.0)
	offset = _rest_offset + Vector2(sin(_elapsed * 73.0), sin(_elapsed * 59.0)) * _strength * fade
