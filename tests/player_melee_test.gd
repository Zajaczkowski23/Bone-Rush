extends SceneTree

var failures: int = 0

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
	var sprite = player.get_node("AnimatedSprite2D")
	var enemy = load("res://characters/enemies/enemy/enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(200, 0)
	player._physics_process(0.01)
	_expect(enemy.health == 30, "Distant enemy must not take damage")
	for child in game.get_children():
		_expect(not child is Line2D, "Player must not create a laser")
	if failures > 0:
		quit(1)
		return

	var surrounding: Array[Area2D] = []
	for offset in [Vector2(40, 0), Vector2(0, -40), Vector2(0, 40), Vector2(80, 80)]:
		var other = load("res://characters/enemies/enemy/enemy.tscn").instantiate()
		game.add_child(other)
		other.set_physics_process(false)
		other.global_position = player.global_position + offset
		surrounding.append(other)
	sprite.flip_h = false
	enemy.global_position = player.global_position + Vector2(-20, 0)
	player._physics_process(1.0)
	_expect(sprite.animation == &"attack", "Nearby enemy must start sword animation")
	_expect(not sprite.flip_h, "Circular swing must preserve player facing")
	_expect(enemy.health == 30, "Damage must wait for sword swing")
	player._physics_process(0.01)
	_expect(sprite.animation == &"attack", "Movement update must not interrupt attack")
	await create_timer(0.22).timeout
	_expect(enemy.health == 20, "Swing must hit nearby enemy once")
	for i in range(surrounding.size()):
		_expect(surrounding[i].health == (30 if i == 3 else 20), "Swing must hit every direction and exclude enemies outside circle")
	await create_timer(0.25).timeout
	_expect(enemy.health == 20, "Animation must not hit more than once")
	for i in range(surrounding.size()):
		_expect(surrounding[i].health == (30 if i == 3 else 20), "Each surrounding enemy must be hit only once")
		surrounding[i].free()
	_expect(sprite.animation == &"idle", "Finished attack must return to idle")
	player._physics_process(0.1)
	_expect(sprite.animation == &"idle", "Attack cooldown must prevent immediate repeat")
	player._physics_process(1.0)
	enemy.global_position = player.global_position + Vector2(200, 0)
	await create_timer(0.45).timeout
	_expect(enemy.health == 20, "Enemy escaping sword range must not take damage")
	enemy.global_position = player.global_position + Vector2(40, 0)
	player._physics_process(1.0)
	enemy.free()
	await create_timer(0.45).timeout
	_expect(sprite.animation == &"idle", "Deleted attack target must be handled safely")

	enemy = load("res://characters/enemies/enemy/enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(40, 0)
	player._physics_process(1.0)
	player.take_damage(100, false)
	await create_timer(0.3).timeout
	_expect(enemy.health == 30, "Dead player must not finish a damaging attack")
	if failures == 0:
		print("PASS: melee range, sword timing, single hit, cooldown, circular damage, preserved facing, escape, deleted target and death")
	quit(1 if failures > 0 else 0)
