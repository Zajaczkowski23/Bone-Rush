extends CharacterBody2D

const PlayArea = preload("res://game/play_area.gd")
const EDGE_MARGIN: float = 24.0

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var damage_cooldown: float = 0.75
@export var fire_range: float = 300.0
@export var fire_interval: float = 0.7
@export var beam_damage: int = 10

var health: int
var has_weapon_drop: bool = false
var _damage_cooldown_left: float = 0.0
var _fire_cooldown_left: float = 0.0

@onready var health_bar: ProgressBar = $"../CanvasLayer/PlayerHealthBar"
@onready var game_over_label: Label = $"../CanvasLayer/GameOverLabel"
@onready var pickup_label: Label = $"../CanvasLayer/PickupLabel"


func _ready() -> void:
	global_position = PlayArea.center_for(self)
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health


func _physics_process(delta: float) -> void:
	_damage_cooldown_left = maxf(_damage_cooldown_left - delta, 0.0)
	_fire_cooldown_left = maxf(_fire_cooldown_left - delta, 0.0)

	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).limit_length(1.0)

	velocity = direction * move_speed
	move_and_slide()
	PlayArea.keep_inside(self, EDGE_MARGIN)

	if direction != Vector2.ZERO:
		rotation = direction.angle()

	if _fire_cooldown_left == 0.0:
		var target := _nearest_enemy()
		if target != null:
			_fire_beam(target)
			_fire_cooldown_left = fire_interval


func _nearest_enemy() -> Area2D:
	var nearest: Area2D = null
	var nearest_distance_squared := fire_range * fire_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Area2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= nearest_distance_squared:
			nearest = enemy
			nearest_distance_squared = distance_squared
	return nearest


func _fire_beam(target: Area2D) -> void:
	var beam := Line2D.new()
	beam.width = 6.0
	beam.default_color = Color(0.45, 1.0, 1.0)
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	get_parent().add_child(beam)
	beam.points = PackedVector2Array([
		beam.to_local(global_position),
		beam.to_local(target.global_position)
	])
	target.call("take_damage", beam_damage)
	var tween := beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.15)
	tween.tween_callback(beam.queue_free)


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0 or _damage_cooldown_left > 0.0:
		return

	health = maxi(health - amount, 0)
	health_bar.value = health
	_damage_cooldown_left = damage_cooldown
	if health == 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		game_over_label.show()


func collect_weapon_drop() -> bool:
	if has_weapon_drop:
		return false
	has_weapon_drop = true
	pickup_label.show()
	return true
