extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://Enemy.tscn")

@export var max_enemies: int = 10


func _ready() -> void:
	$EnemySpawnTimer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	add_child(enemy)
	enemy.global_position = _random_edge_position()


func _random_edge_position() -> Vector2:
	var view_size := get_viewport_rect().size
	var margin := 24.0
	match randi_range(0, 3):
		0:
			return Vector2(randf_range(margin, view_size.x - margin), margin)
		1:
			return Vector2(view_size.x - margin, randf_range(margin, view_size.y - margin))
		2:
			return Vector2(randf_range(margin, view_size.x - margin), view_size.y - margin)
		_:
			return Vector2(margin, randf_range(margin, view_size.y - margin))
