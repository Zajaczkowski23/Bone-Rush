extends "res://characters/enemies/enemy/enemy.gd"

const BEAM_SCENE: PackedScene = preload("res://characters/enemies/shooter/shooter_beam.tscn")

@export var shot_interval: float = 2.0

var _shot_cooldown: float = 0.5


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_shot_cooldown -= delta
	if _shot_cooldown > 0.0:
		return

	_shot_cooldown = shot_interval
	var aim_position: Vector2 = player.global_position
	$Barrel.rotation = global_position.angle_to_point(aim_position)
	var beam := BEAM_SCENE.instantiate() as Area2D
	get_parent().add_child(beam)
	beam.call("launch", global_position, aim_position)
