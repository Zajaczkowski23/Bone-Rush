extends Area2D

signal defeated(points: int)

const PlayArea = preload("res://game/world/play_area.gd")
const EDGE_MARGIN: float = 36.0

@export var move_speed: float = 110.0
@export var max_health: int = 30
@export var contact_damage: int = 10
@export var score_value: int = 10
@export var xp_value: int = 10
@export var attack_range: float = 40.0
@export var attack_interval: float = 0.9
@export_flags_2d_physics var wall_collision_mask: int = 2

var health: int
var _attack_cooldown_left: float = 0.0
var _is_attacking: bool = false
var _swing_has_hit: bool = false
var _path_refresh_left: float = 0.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	sprite.frame_changed.connect(_on_attack_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if not is_instance_valid(player) or player.get("health") <= 0:
		if not _is_attacking:
			sprite.play("idle")
		return
	if _is_attacking:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= attack_range and _has_clear_sword_path():
		var direction := player.global_position - global_position
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		if _attack_cooldown_left == 0.0:
			_is_attacking = true
			_swing_has_hit = false
			_attack_cooldown_left = attack_interval
			sprite.play("attack")
		else:
			sprite.play("idle")
		return

	# Navigation maps synchronize after the first physics frame.
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		sprite.play("idle")
		return
	_path_refresh_left -= delta
	if _path_refresh_left <= 0.0 or navigation_agent.target_position.distance_squared_to(player.global_position) > 256.0:
		navigation_agent.target_position = player.global_position
		_path_refresh_left = 0.2
	var next_position := navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		sprite.play("idle")
		return
	var next_step := global_position.move_toward(next_position, move_speed * delta)
	var query := PhysicsRayQueryParameters2D.create(global_position, next_step, wall_collision_mask)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		sprite.play("idle")
		return
	var movement := next_step - global_position
	global_position = next_step
	PlayArea.keep_inside(self, EDGE_MARGIN)
	if movement.x != 0.0:
		sprite.flip_h = movement.x < 0.0
	sprite.play("run" if movement != Vector2.ZERO else "idle")


func _has_clear_sword_path() -> bool:
	if not is_instance_valid(player):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, wall_collision_mask)
	query.exclude = [player.get_rid(), get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _on_attack_frame_changed() -> void:
	if health <= 0 or not _is_attacking or _swing_has_hit:
		return
	if sprite.animation != &"attack" or sprite.frame != 3:
		return
	_swing_has_hit = true
	if _has_clear_sword_path() and global_position.distance_squared_to(player.global_position) <= attack_range * attack_range:
		player.call("take_damage", contact_damage)


func _on_animation_finished() -> void:
	if sprite.animation == &"death":
		queue_free()
	elif sprite.animation == &"attack":
		_is_attacking = false
		sprite.play("idle")


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_bar.value = health
	if health == 0:
		_is_attacking = false
		set_physics_process(false)
		remove_from_group("enemies")
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		$CollisionShape2D.set_deferred("disabled", true)
		health_bar.hide()
		sprite.play("death")
		defeated.emit(score_value)
