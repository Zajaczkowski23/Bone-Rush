extends Node2D

const PlayArea = preload("res://game/play_area.gd")
const ENEMY_SCENE: PackedScene = preload("res://characters/enemies/enemy/enemy.tscn")

@export var max_enemies: int = 10


func _ready() -> void:
	$WeaponDrop.global_position = $Player.global_position + Vector2(160, 0)
	PlayArea.keep_inside($WeaponDrop, 32.0)
	$EnemySpawnTimer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	add_child(enemy)
	enemy.global_position = PlayArea.random_edge_position(self, 36.0)
