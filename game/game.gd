extends Node2D

const PlayArea = preload("res://game/world/play_area.gd")
const MINIBOSS_SCENE: PackedScene = preload("res://characters/enemies/miniboss/miniboss.tscn")
const ENEMY_SCENE: PackedScene = preload("res://characters/enemies/enemy/enemy.tscn")
const UPGRADES: Array[Resource] = [
	preload("res://game/progression/upgrades/damage.tres"),
	preload("res://game/progression/upgrades/health.tres"),
	preload("res://game/progression/upgrades/range.tres"),
	preload("res://game/progression/upgrades/speed.tres"),
]

@export var max_enemies: int = 10

var score: int = 0
var _pending_levels: Array[int] = []
var _reward_pause_active: bool = false
var _victory_pause_active: bool = false
var _wave_enemies: Dictionary = {}
var _wave_edge: int = 0
var _wave_spawn_index: int = 0
var _wave_banner_left: float = 0.0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var progression: Node = $LevelProgression
@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = $CanvasLayer/XPBar
@onready var level_label: Label = $CanvasLayer/LevelLabel
@onready var level_up_panel: Control = $CanvasLayer/LevelUpPanel
@onready var waves: Node = $WaveDirector
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var wave_status: Label = $CanvasLayer/WaveStatus
@onready var next_wave_button: Button = $CanvasLayer/NextWaveButton
@onready var victory_panel: Control = $CanvasLayer/VictoryPanel
@onready var replay_button: Button = victory_panel.get_node("%PlayAgainButton")


func _ready() -> void:
	progression.xp_changed.connect(_update_xp_hud)
	progression.leveled_up.connect(_on_leveled_up)
	level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
	_update_xp_hud(progression.xp, progression.xp_required)
	player.died.connect(_on_player_died)
	waves.max_enemies = maxi(max_enemies, 1)
	waves.spawn_requested.connect(_spawn_wave_enemy)
	waves.phase_changed.connect(_on_wave_phase_changed)
	waves.completed.connect(_on_run_completed)
	next_wave_button.pressed.connect(waves.start_next_wave)
	replay_button.pressed.connect(_restart_run)
	waves.start()


func _process(delta: float) -> void:
	_wave_banner_left = maxf(_wave_banner_left - delta, 0.0)
	_update_wave_ui()


func _spawn_enemy() -> Area2D:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return null

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	enemy.connect("defeated", _on_enemy_defeated.bind(enemy))
	add_child(enemy)
	enemy.global_position = PlayArea.random_edge_position(self, 36.0)
	return enemy


func _spawn_miniboss() -> Area2D:
	if player.health <= 0 or not get_tree().get_nodes_in_group("minibosses").is_empty():
		return null
	var miniboss := MINIBOSS_SCENE.instantiate() as Area2D
	miniboss.defeated.connect(_on_enemy_defeated.bind(miniboss))
	miniboss.heavy_sword_impact.connect($Player/Camera2D.shake_from)
	add_child(miniboss)
	miniboss.global_position = PlayArea.random_edge_position(self, 36.0)
	return miniboss


func _spawn_wave_enemy(is_miniboss: bool) -> void:
	if player.health <= 0:
		return
	var enemy := _spawn_miniboss() if is_miniboss else _spawn_enemy()
	if enemy == null:
		return
	_wave_enemies[enemy.get_instance_id()] = true
	if waves.wave_number >= 2:
		var edge := (_wave_edge + (_wave_spawn_index % 2) * 2) % 4
		if waves.wave_number >= 3:
			edge = (_wave_edge + _wave_spawn_index) % 4
		enemy.global_position = PlayArea.edge_position(self, edge, 36.0)
	_wave_spawn_index += 1


func _on_enemy_defeated(points: int, enemy: Area2D) -> void:
	score += points
	score_label.text = "SCORE: %d" % score
	if player.health > 0:
		progression.add_xp(int(enemy.get("xp_value")))
	if _wave_enemies.erase(enemy.get_instance_id()):
		waves.enemy_defeated()


func _on_wave_phase_changed() -> void:
	if waves.phase == waves.Phase.ACTIVE:
		_wave_edge = randi_range(0, 3)
		_wave_spawn_index = 0
		_wave_banner_left = 1.5
	_update_wave_ui()
	if next_wave_button.visible:
		next_wave_button.grab_focus()


func _update_wave_ui() -> void:
	wave_label.text = "WAVE %d" % maxi(waves.wave_number, 1)
	next_wave_button.visible = waves.phase == waves.Phase.INTERMISSION
	match waves.phase:
		waves.Phase.PREPARING:
			wave_status.text = "WAVE 1\nStarting in %d" % ceili(waves.phase_left)
		waves.Phase.INTERMISSION:
			wave_status.text = "WAVE CLEARED\nNext wave in %d" % ceili(waves.phase_left)
		waves.Phase.ACTIVE:
			wave_status.text = "BONE KING" if waves.wave_number == 5 else "WAVE %d" % waves.wave_number
		_:
			wave_status.text = ""
	wave_status.visible = waves.phase in [waves.Phase.PREPARING, waves.Phase.INTERMISSION] or (waves.phase == waves.Phase.ACTIVE and _wave_banner_left > 0.0)


func _on_player_died() -> void:
	waves.stop()
	_pending_levels.clear()
	_finish_reward_pause()
	$CanvasLayer/VirtualJoystickDX.release()


func _on_run_completed() -> void:
	_show_victory.call_deferred()


func _show_victory() -> void:
	if player.health <= 0 or waves.phase != waves.Phase.COMPLETE or _victory_pause_active:
		return
	if not _pending_levels.is_empty() or _reward_pause_active:
		return
	$CanvasLayer/VirtualJoystickDX.release()
	victory_panel.get_node("%VictoryScore").text = "SCORE: %d" % score
	_victory_pause_active = true
	get_tree().paused = true
	victory_panel.show()
	replay_button.grab_focus()


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _update_xp_hud(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	xp_bar.tooltip_text = "%d / %d XP" % [current, required]
	level_label.text = "LEVEL %d" % progression.level


func _on_leveled_up(new_level: int) -> void:
	if _victory_pause_active or player.health <= 0:
		return
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
		if waves.phase == waves.Phase.COMPLETE:
			_show_victory.call_deferred()
	else:
		_show_next_reward.call_deferred()


func _finish_reward_pause() -> void:
	level_up_panel.hide()
	if _reward_pause_active:
		_reward_pause_active = false
		get_tree().paused = false
	if next_wave_button.visible:
		next_wave_button.grab_focus()


func _exit_tree() -> void:
	if _reward_pause_active or _victory_pause_active:
		get_tree().paused = false
