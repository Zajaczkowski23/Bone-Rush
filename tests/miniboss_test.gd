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
	game.get_node("WaveDirector").set_process(false)
	for spawned in get_nodes_in_group("enemies"): spawned.free()
	game.player.set_physics_process(false)
	_expect(game.has_method("_spawn_miniboss"), "Game must spawn the distinct skeleton miniboss")
	if failures:
		quit(1)
		return
	_expect(get_nodes_in_group("minibosses").is_empty(), "Miniboss must wait for the final wave instead of spawning on a timer")
	game._spawn_miniboss()
	var bosses = get_nodes_in_group("minibosses")
	_expect(bosses.size() == 1, "Miniboss factory must create one distinct boss")
	var boss = bosses[0]
	boss.set_physics_process(false)
	game._spawn_miniboss()
	_expect(get_nodes_in_group("minibosses").size() == 1, "Only one living miniboss may exist")
	_expect(boss.health == 240 and boss.contact_damage == 25, "Miniboss must be tougher and hit harder")
	_expect(boss.get_node("AnimatedSprite2D").sprite_frames != load("res://characters/enemies/enemy/skeleton_frames.tres"), "Miniboss must have its own design and animations")
	for animation in [&"idle", &"run", &"attack", &"death"]:
		var frames: SpriteFrames = boss.sprite.sprite_frames
		_expect(frames.get_frame_count(animation) == 6, "Miniboss must have all four animations")
		for i in range(6):
			_expect(not frames.get_frame_texture(animation, i).get_image().is_invisible(), "Miniboss animation frames must be visible")
	await create_timer(0.1).timeout
	game.player.global_position = Vector2(500, 300)
	boss.global_position = Vector2(550, 300)
	boss._physics_process(1.0)
	_expect(boss.sprite.animation == &"attack", "Close miniboss must start its heavy attack")
	await create_timer(0.35).timeout
	_expect(game.player.health == 100, "Heavy attack must allow time to dodge")
	await create_timer(0.25).timeout
	_expect(game.player.health == 75, "Heavy sword must deal 25 damage at impact")
	await create_timer(0.5).timeout
	_expect(game.player.health == 75, "One heavy attack must hit once")
	boss.take_damage(10)
	_expect(boss.health == 230, "Miniboss must survive an ordinary sword hit")
	var score_before: int = game.score
	boss.take_damage(1000)
	_expect(game.score == score_before + 100, "Defeating miniboss must award bonus score")
	_expect(game.progression.level == 2 and game.progression.xp == 30, "Miniboss must award 80 XP through normal leveling")
	_expect(boss.sprite.animation == &"death", "Miniboss must play death animation")
	# Reward selection pauses the game; close it before waiting for the death animation.
	await process_frame
	game._on_upgrade_selected(game.UPGRADES[0])
	await create_timer(0.9).timeout
	_expect(not is_instance_valid(boss), "Miniboss must disappear after its death animation")
	game._spawn_miniboss()
	_expect(get_nodes_in_group("minibosses").size() == 1, "A new miniboss must be allowed after the previous death")
	if failures == 0: print("PASS: miniboss spawning, unique visuals, heavy windup, damage, death and XP reward")
	quit(1 if failures else 0)
