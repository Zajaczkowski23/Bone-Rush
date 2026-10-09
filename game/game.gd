extends Node2D

const PlayArea = preload("res://game/play_area.gd")
const ENEMY_SCENE: PackedScene = preload("res://characters/enemies/enemy/enemy.tscn")

@export var max_enemies: int = 10

var score: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel


func _ready() -> void:
	$EnemySpawnTimer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	enemy.connect("defeated", _on_enemy_defeated)
	add_child(enemy)
	enemy.global_position = PlayArea.random_edge_position(self, 36.0)


func _on_enemy_defeated(points: int) -> void:
	score += points
	score_label.text = "SCORE: %d" % score
