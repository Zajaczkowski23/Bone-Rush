extends Area2D

const PlayArea = preload("res://game/play_area.gd")

@export var speed: float = 360.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(origin: Vector2, aim_position: Vector2) -> void:
	global_position = origin
	direction = origin.direction_to(aim_position)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if not PlayArea.bounds_for(self, -32.0).has_point(global_position):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.call("take_damage", damage, false)
		queue_free()
