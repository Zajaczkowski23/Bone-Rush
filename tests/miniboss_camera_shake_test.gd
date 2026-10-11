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
	game.waves.set_process(false)
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(500, 300)
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.set_process(false)
	_expect(camera.has_method("shake_from"), "Player camera must support miniboss impact shake")
	if failures:
		quit(1)
		return
	var boss = game._spawn_miniboss()
	boss.set_physics_process(false)
	boss.global_position = Vector2(550, 300)
	boss._physics_process(1.0)
	boss.sprite.pause()
	boss.sprite.frame = 2
	camera._process(0.04)
	_expect(camera.offset == Vector2.ZERO, "Windup must not shake the camera")
	# Dodge the damage while staying near the heavy sword impact.
	game.player.global_position = Vector2(450, 300)
	boss.sprite.frame = 3
	camera._process(0.04)
	var early_offset: float = camera.offset.length()
	_expect(early_offset > 0.1, "A dodged nearby miniboss impact must still shake the camera")
	_expect(game.player.health == 100, "Camera shake must not add damage to a dodged attack")
	camera._process(0.22)
	_expect(camera.offset.length() < early_offset, "Shake must fade smoothly")
	# Repeated frame notifications must not restart a completed swing's shake.
	boss._on_attack_frame_changed()
	camera._process(0.1)
	_expect(camera.offset == Vector2.ZERO, "One swing must shake once and return exactly to rest")
	var hud_position: Vector2 = game.score_label.global_position
	camera.shake_from(camera.global_position)
	camera._process(0.04)
	var near_offset: float = camera.offset.length()
	_expect(game.score_label.global_position == hud_position, "HUD must remain fixed while the world shakes")
	camera._process(1.0)
	camera.shake_from(camera.global_position + Vector2(200, 0))
	camera._process(0.04)
	_expect(camera.offset.length() > 0 and camera.offset.length() < near_offset, "More distant impacts must shake less")
	camera._process(1.0)
	camera.shake_from(camera.global_position + Vector2(1000, 0))
	camera._process(0.04)
	_expect(camera.offset == Vector2.ZERO, "Far away impacts must not shake the camera")
	var enemy = game._spawn_enemy()
	enemy.set_physics_process(false)
	enemy.global_position = game.player.global_position + Vector2(20, 0)
	enemy._physics_process(1.0)
	enemy.sprite.pause()
	enemy.sprite.frame = 3
	camera._process(0.04)
	_expect(camera.offset == Vector2.ZERO, "Ordinary skeleton attacks must not shake the camera")
	if failures == 0:
		print("PASS: miniboss impact timing, dodging, single shake, fade, distance and fixed HUD")
	quit(1 if failures else 0)
