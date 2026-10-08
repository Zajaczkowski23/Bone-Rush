extends Node2D

const PlayArea = preload("res://game/play_area.gd")
const ENEMY_SCENE: PackedScene = preload("res://characters/enemies/enemy/enemy.tscn")
const SHOOTER_SCENE: PackedScene = preload("res://characters/enemies/shooter/shooter.tscn")

@export var max_enemies: int = 10

var score: int = 0
var _spawn_count: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel


func _ready() -> void:
	$WeaponDrop.global_position = $Player.global_position + Vector2(160, 0)
	PlayArea.keep_inside($WeaponDrop, 32.0)
	$EnemySpawnTimer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var scene := SHOOTER_SCENE if _spawn_count % 3 == 0 else ENEMY_SCENE
	_spawn_count += 1
	var enemy := scene.instantiate() as Area2D
	enemy.connect("defeated", _on_enemy_defeated)
	add_child(enemy)
	enemy.global_position = PlayArea.random_edge_position(self, 36.0)


func _on_enemy_defeated(points: int) -> void:
	score += points
	score_label.text = "SCORE: %d" % score
