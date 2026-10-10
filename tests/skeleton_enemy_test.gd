extends SceneTree

var failures: int = 0
var defeated_count: int = 0

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
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	_expect(sprite != null, "Enemy must use animated skeleton graphics")
	if sprite == null:
		quit(1)
		return
	for animation in [&"idle", &"run", &"attack", &"death"]:
		for frame in range(sprite.sprite_frames.get_frame_count(animation)):
			var image: Image = sprite.sprite_frames.get_frame_texture(animation, frame).get_image()
			_expect(image.get_size() == Vector2i(256, 256) and not image.is_invisible(), "Every skeleton frame must contain visible correctly sliced graphics")
	await create_timer(0.1).timeout
	enemy.global_position = player.global_position + Vector2(150, 0)
	var initial_position: Vector2 = enemy.global_position
	enemy._physics_process(0.1)
	_expect(enemy.global_position.x < initial_position.x, "Skeleton must approach player")
	_expect(sprite.animation == &"run" and sprite.flip_h, "Skeleton walk must face player")
	enemy.global_position = player.global_position + Vector2(28, 0)
	enemy._physics_process(1.0)
	_expect(sprite.animation == &"attack", "Close skeleton must swing sword")
	_expect(player.health == 100, "Sword damage must wait for windup")
	await create_timer(0.15).timeout
	_expect(player.health == 100, "Windup must not damage player")
	await create_timer(0.2).timeout
	_expect(player.health == 90, "Sword swing must damage nearby player once")
	await create_timer(0.3).timeout
	_expect(player.health == 90, "Skeleton must hit only once per swing")
	enemy._physics_process(0.1)
	_expect(sprite.animation != &"attack", "Skeleton attack must respect cooldown")
	enemy._physics_process(1.0)
	player.global_position += Vector2(-200, 0)
	await create_timer(0.65).timeout
	_expect(player.health == 90, "Escaping sword range must avoid damage")
	enemy.defeated.connect(func(_points: int): defeated_count += 1)
	enemy.take_damage(100)
	enemy.take_damage(100)
	_expect(defeated_count == 1, "Skeleton death must award points once")
	_expect(not enemy.is_in_group("enemies"), "Dying skeleton must not remain a combat target")
	_expect(sprite.animation == &"death", "Killed skeleton must play bone collapse")
	await create_timer(0.75).timeout
	_expect(not is_instance_valid(enemy), "Skeleton must disappear after death animation")
	if failures == 0:
		print("PASS: skeleton visuals, chase, attack windup, single hit, cooldown, dodge and animated death")
	quit(1 if failures > 0 else 0)
