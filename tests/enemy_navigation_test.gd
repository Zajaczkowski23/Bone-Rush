extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func _run() -> void:
	var game = load("res://game/game.tscn").instantiate()
	root.add_child(game)
	game.get_node("EnemySpawnTimer").stop()
	for spawned in get_nodes_in_group("enemies"):
		spawned.free()
	var player = game.get_node("Player")
	player.set_physics_process(false)
	var enemy = load("res://characters/enemies/enemy/enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.set_physics_process(false)
	_expect(enemy.get_node_or_null("NavigationAgent2D") != null, "Skeleton must follow a navigation path")
	if failures:
		quit(1)
		return
	await create_timer(0.1).timeout
	player.global_position = Vector2(931, 470)
	enemy.global_position = Vector2(955, 470)
	enemy._physics_process(0.01)
	_expect(enemy.sprite.animation != &"attack", "Skeleton must not start a swing through a cliff")

	player.global_position = Vector2(897, 490)
	enemy.global_position = Vector2(897, 610)
	var went_around := false
	for i in range(500):
		await physics_frame
		var before: Vector2 = enemy.global_position
		enemy._physics_process(1.0 / 60.0)
		var query = PhysicsRayQueryParameters2D.create(before, enemy.global_position, 2)
		_expect(enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty(), "Skeleton path must not cross a cliff")
		if absf(enemy.global_position.x - 897) > 55:
			went_around = true
		if enemy.global_position.distance_to(player.global_position) <= 40 and enemy.sprite.animation == &"attack":
			break
	_expect(went_around, "Skeleton must take the side ramp instead of crossing the front wall")
	_expect(enemy.global_position.distance_to(player.global_position) <= 40, "Skeleton must reach player on hilltop")
	await create_timer(0.35).timeout
	_expect(player.health == 90, "Skeleton must attack after reaching the hilltop")

	# A wall appearing during the windup must also prevent damage.
	await create_timer(0.3).timeout
	player.global_position = Vector2(500, 300)
	enemy.global_position = Vector2(528, 300)
	enemy._physics_process(1.0)
	var wall = StaticBody2D.new()
	wall.collision_layer = 2
	wall.position = Vector2(514, 300)
	var collision = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(4, 80)
	collision.shape = rectangle
	wall.add_child(collision)
	game.add_child(wall)
	await create_timer(0.35).timeout
	_expect(player.health == 90, "Wall must block damage at the actual swing frame")
	if failures == 0:
		print("PASS: hill ramp navigation, no wall crossing, hilltop attack and blocked sword damage")
	quit(1 if failures else 0)
