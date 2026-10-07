extends Area2D

const PlayArea = preload("res://game/play_area.gd")
const EDGE_MARGIN: float = 36.0

@export var move_speed: float = 110.0
@export var max_health: int = 30
@export var contact_damage: int = 10

var health: int

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > 18.0:
		global_position = global_position.move_toward(
			player.global_position,
			minf(move_speed * delta, distance - 18.0)
		)
	PlayArea.keep_inside(self, EDGE_MARGIN)

	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.call("take_damage", contact_damage)


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_bar.value = health
	if health == 0:
		queue_free()
