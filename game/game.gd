extends Node2D

const PlayArea = preload("res://game/play_area.gd")
const ENEMY_SCENE: PackedScene = preload("res://characters/enemies/enemy/enemy.tscn")
const UPGRADES: Array[Resource] = [
	preload("res://game/upgrades/damage.tres"),
	preload("res://game/upgrades/health.tres"),
	preload("res://game/upgrades/range.tres"),
	preload("res://game/upgrades/speed.tres"),
]

@export var max_enemies: int = 10

var score: int = 0
var _pending_levels: Array[int] = []
var _reward_pause_active: bool = false

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var progression: Node = $LevelProgression
@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = $CanvasLayer/XPBar
@onready var level_label: Label = $CanvasLayer/LevelLabel
@onready var level_up_panel: Control = $CanvasLayer/LevelUpPanel


func _ready() -> void:
	progression.xp_changed.connect(_update_xp_hud)
	progression.leveled_up.connect(_on_leveled_up)
	level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
	_update_xp_hud(progression.xp, progression.xp_required)
	$EnemySpawnTimer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	enemy.connect("defeated", _on_enemy_defeated.bind(enemy))
	add_child(enemy)
	enemy.global_position = PlayArea.random_edge_position(self, 36.0)


func _on_enemy_defeated(points: int, enemy: Area2D) -> void:
	score += points
	score_label.text = "SCORE: %d" % score
	if player.health > 0:
		progression.add_xp(int(enemy.get("xp_value")))


func _update_xp_hud(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	xp_bar.tooltip_text = "%d / %d XP" % [current, required]
	level_label.text = "LEVEL %d" % progression.level


func _on_leveled_up(new_level: int) -> void:
	_pending_levels.append(new_level)
	_show_next_reward.call_deferred()


func _show_next_reward() -> void:
	if player.health <= 0:
		_pending_levels.clear()
		_finish_reward_pause()
		return
	if _pending_levels.is_empty() or level_up_panel.visible:
		return
	var choices: Array[Resource] = UPGRADES.duplicate()
	choices.shuffle()
	choices.resize(3)
	$CanvasLayer/VirtualJoystickDX.release()
	_reward_pause_active = true
	get_tree().paused = true
	level_up_panel.show_choices(_pending_levels.front(), choices)


func _on_upgrade_selected(upgrade: Resource) -> void:
	if _pending_levels.is_empty() or not _reward_pause_active:
		return
	if not player.apply_upgrade(upgrade):
		_pending_levels.clear()
		_finish_reward_pause()
		return
	_pending_levels.pop_front()
	if _pending_levels.is_empty():
		_finish_reward_pause()
	else:
		_show_next_reward.call_deferred()


func _finish_reward_pause() -> void:
	level_up_panel.hide()
	if _reward_pause_active:
		_reward_pause_active = false
		get_tree().paused = false


func _exit_tree() -> void:
	if _reward_pause_active:
		get_tree().paused = false
