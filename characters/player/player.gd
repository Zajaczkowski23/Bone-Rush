extends CharacterBody2D

const PlayArea = preload("res://game/play_area.gd")
const SwordSweep = preload("res://characters/player/sword_sweep.gd")
const UpgradeDefinition = preload("res://game/upgrades/upgrade_definition.gd")
const EDGE_MARGIN: float = 24.0

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var damage_cooldown: float = 0.75
@export var attack_range: float = 100.0
@export var attack_interval: float = 0.7
@export var sword_damage: int = 10

var _is_attacking: bool = false
var _swing_has_hit: bool = false
var _sword_sweep: Node2D

var health: int
var _damage_cooldown_left: float = 0.0
var _attack_cooldown_left: float = 0.0
var _damage_flash_tween: Tween

@onready var health_bar: ProgressBar = $"../CanvasLayer/PlayerHealthBar"
@onready var game_over_label: Label = $"../CanvasLayer/GameOverLabel"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _sprite_base_color: Color = sprite.modulate


func _ready() -> void:
	global_position = PlayArea.center_for(self)
	sprite.frame_changed.connect(_on_attack_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health


func _physics_process(delta: float) -> void:
	_damage_cooldown_left = maxf(_damage_cooldown_left - delta, 0.0)
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)

	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).limit_length(1.0)

	velocity = direction * move_speed
	move_and_slide()
	PlayArea.keep_inside(self, EDGE_MARGIN)

	if not _is_attacking:
		sprite.play("run" if direction != Vector2.ZERO else "idle")
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0

	if not _is_attacking and _attack_cooldown_left == 0.0:
		if _has_nearby_enemy():
			_start_sword_attack()
			_attack_cooldown_left = attack_interval


func _has_nearby_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Area2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(enemy.global_position) <= attack_range * attack_range:
			return true
	return false


func _start_sword_attack() -> void:
	_is_attacking = true
	_swing_has_hit = false
	sprite.play("attack")
	_sword_sweep = SwordSweep.new()
	_sword_sweep.radius = attack_range
	_sword_sweep.duration = sprite.sprite_frames.get_frame_count(&"attack") / sprite.sprite_frames.get_animation_speed(&"attack")
	add_child(_sword_sweep)


func _on_attack_frame_changed() -> void:
	if not _is_attacking or _swing_has_hit or sprite.animation != &"attack" or sprite.frame != 2:
		return
	_swing_has_hit = true
	if health <= 0:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Area2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(enemy.global_position) <= attack_range * attack_range:
			enemy.call("take_damage", sword_damage)


func _on_animation_finished() -> void:
	if sprite.animation != &"attack":
		return
	_is_attacking = false
	_swing_has_hit = false
	if health > 0:
		sprite.play("run" if velocity != Vector2.ZERO else "idle")


func take_damage(amount: int, use_cooldown: bool = true) -> void:
	if amount <= 0 or health <= 0:
		return
	if use_cooldown and _damage_cooldown_left > 0.0:
		return

	health = maxi(health - amount, 0)
	health_bar.value = health
	_play_damage_flash()
	if use_cooldown:
		_damage_cooldown_left = damage_cooldown
	if health == 0:
		velocity = Vector2.ZERO
		_is_attacking = false
		_swing_has_hit = false
		if is_instance_valid(_sword_sweep):
			_sword_sweep.queue_free()
		sprite.stop()
		set_physics_process(false)
		game_over_label.show()


func apply_upgrade(upgrade: UpgradeDefinition) -> bool:
	if upgrade == null or health <= 0:
		return false
	match upgrade.stat:
		&"sword_damage":
			sword_damage += int(upgrade.amount)
		&"max_health":
			max_health += int(upgrade.amount)
			health = mini(health + int(upgrade.amount), max_health)
			health_bar.max_value = max_health
			health_bar.value = health
		&"attack_range":
			attack_range += upgrade.amount
		&"move_speed":
			move_speed *= upgrade.multiplier
		_:
			return false
	return true


func _play_damage_flash() -> void:
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(sprite, "modulate", _sprite_base_color * Color(1.0, 0.3, 0.3, 1.0), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_damage_flash_tween.tween_property(sprite, "modulate", _sprite_base_color, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
