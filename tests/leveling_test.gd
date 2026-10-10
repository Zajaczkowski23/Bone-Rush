extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _new_game():
	var game = load("res://game/game.tscn").instantiate()
	root.add_child(game)
	game.get_node("WaveDirector").set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	game.get_node("Player").set_physics_process(false)
	return game


func _run() -> void:
	var game = _new_game()
	var progression = game.get_node_or_null("LevelProgression")
	_expect(progression != null, "Game must include run progression and connect it to rewards")
	if progression == null:
		game.free()
		quit(1)
		return
	var player = game.get_node("Player")
	var panel = game.get_node("CanvasLayer/LevelUpPanel")
	var bar = game.get_node("CanvasLayer/XPBar")
	var label = game.get_node("CanvasLayer/LevelLabel")
	_expect(bar.value == 0 and bar.max_value == 50 and label.text == "LEVEL 1", "HUD must show fresh progression")
	game._spawn_enemy()
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.set_physics_process(false)
	enemy.score_value = 42
	enemy.xp_value = 10
	enemy.take_damage(100)
	enemy.take_damage(100)
	_expect(game.score == 42 and progression.xp == 10, "Kill must award independent score/XP once")
	_expect(bar.value == 10 and not paused and not panel.visible, "Subthreshold XP must update HUD without pausing")
	var joystick = game.get_node("CanvasLayer/VirtualJoystickDX")
	joystick.haptic_enabled = false
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.position = joystick.global_position + joystick.size / 2.0 + Vector2(60, 0)
	touch.pressed = true
	# Headless viewports do not dispatch screen touches to this control.
	joystick._input(touch)
	await process_frame
	_expect(joystick.is_active() and Input.is_action_pressed("ui_right"), "Regression setup must activate touch movement before level up")
	progression.add_xp(235)
	_expect(progression.level == 4 and progression.xp == 5, "Large XP grant must preserve every crossed level")
	_expect(not paused, "Reward UI must defer pause until the current combat callback finishes")
	await process_frame
	_expect(paused and panel.visible, "Level up must pause combat and show reward choices")
	_expect(label.text == "LEVEL 4" and bar.value == 5 and bar.max_value == 140, "HUD must display final XP after multiple levels")
	_expect(panel.get_node("%Title").text == "LEVEL 2", "Reward queue must start with the earliest earned level")
	var choices = panel.get_node("%Choices")
	var descriptions: Array[String] = []
	for button in choices.get_children():
		_expect(button is Button and not button.disabled and button.is_visible_in_tree(), "All three choices must be usable during pause")
		descriptions.append(button.text)
	_expect(descriptions.size() == 3 and descriptions[0] != descriptions[1] and descriptions[0] != descriptions[2] and descriptions[1] != descriptions[2], "Reward choices must be three distinct upgrades")
	_expect(panel.can_process() and not player.can_process(), "Reward panel must accept input while gameplay is paused")
	touch.pressed = false
	Input.parse_input_event(touch)
	await process_frame
	_expect(root.gui_get_focus_owner() is Button, "Keyboard focus must start on an upgrade button")
	var director = game.get_node("WaveDirector")
	director.set_process(true)
	var remaining: float = director.phase_left
	await create_timer(0.15).timeout
	_expect(is_equal_approx(director.phase_left, remaining) and get_nodes_in_group("enemies").is_empty(), "Spawning must freeze throughout reward selection")
	director.set_process(false)
	panel._select_upgrade(-1)
	panel._select_upgrade(3)
	_expect(panel.visible and paused, "Invalid selections must not dismiss or consume a reward")
	for reward_level in [2, 3, 4]:
		_expect(panel.get_node("%Title").text == "LEVEL %d" % reward_level, "Queued rewards must be shown in order")
		var selected_title: String = choices.get_child(0).text.get_slice("\n", 0)
		var before_choice = [player.sword_damage, player.max_health, player.health, player.attack_range, player.move_speed]
		choices.get_child(0).pressed.emit()
		match selected_title:
			"SHARP BLADE":
				_expect(player.sword_damage == before_choice[0] + 5, "Selecting damage must apply it through the game")
			"VITALITY":
				_expect(player.max_health == before_choice[1] + 20 and player.health == before_choice[2] + 20, "Selecting vitality must increase HP through the game")
			"WIDE SWING":
				_expect(player.attack_range == before_choice[3] + 15, "Selecting range must apply it through the game")
			"SWIFT FEET":
				_expect(is_equal_approx(player.move_speed, before_choice[4] * 1.1), "Selecting speed must apply it through the game")
			_:
				_expect(false, "Only supported upgrades may be offered")
		var stats_after_choice = [player.sword_damage, player.max_health, player.health, player.attack_range, player.move_speed]
		choices.get_child(0).pressed.emit()
		_expect(stats_after_choice == [player.sword_damage, player.max_health, player.health, player.attack_range, player.move_speed], "Double selection must not apply an upgrade twice")
		await process_frame
		_expect(paused == (reward_level < 4), "Gameplay must resume only after the last queued reward")
	_expect(not panel.visible, "Panel must hide after consuming all rewards")
	_expect(not joystick.is_active() and not Input.is_action_pressed("ui_right"), "Touch released during reward pause must not leave movement stuck after resuming")
	joystick.release()
	game.free()

	game = _new_game()
	player = game.get_node("Player")
	_expect(player.sword_damage == 10 and player.max_health == 100 and player.move_speed == 260, "New run must reset upgraded player stats")
	player.take_damage(40, false)
	for upgrade_id in ["damage", "health", "range", "speed"]:
		var upgrade = load("res://game/upgrades/%s.tres" % upgrade_id)
		_expect(player.apply_upgrade(upgrade), "Living player must accept available upgrades")
	_expect(player.sword_damage == 15 and player.attack_range == 115, "Damage and range upgrades must affect combat stats")
	_expect(player.max_health == 120 and player.health == 80, "Health upgrade must raise maximum and heal by twenty")
	_expect(game.get_node("CanvasLayer/PlayerHealthBar").max_value == 120 and game.get_node("CanvasLayer/PlayerHealthBar").value == 80, "Health HUD must immediately show the upgraded values")
	_expect(is_equal_approx(player.move_speed, 286.0), "Speed upgrade must increase current speed by ten percent")
	player.apply_upgrade(load("res://game/upgrades/speed.tres"))
	_expect(is_equal_approx(player.move_speed, 314.6), "Repeated speed upgrades must multiply current speed")
	player.health = player.max_health
	player.apply_upgrade(load("res://game/upgrades/health.tres"))
	_expect(player.health == 140 and player.max_health == 140, "Health upgrade at full health must stay within the new maximum")
	game.free()

	game = _new_game()
	player = game.get_node("Player")
	player.sword_damage = 100
	for i in range(3):
		game._spawn_enemy()
		enemy = get_nodes_in_group("enemies")[i]
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position + Vector2(20, i * 10)
		enemy.xp_value = 80
	player._start_sword_attack()
	player.get_node("AnimatedSprite2D").frame = 2
	_expect(game.score == 30 and game.get_node("LevelProgression").level == 4 and get_nodes_in_group("enemies").is_empty(), "Circular attack must finish every kill and award XP before pausing")
	await process_frame
	_expect(paused, "Area attack rewards must open after the complete swing callback")
	game.free()
	_expect(not paused, "Removing a paused game must release its reward pause")

	game = _new_game()
	player = game.get_node("Player")
	progression = game.get_node("LevelProgression")
	_expect(progression.level == 1 and progression.xp == 0 and not paused, "Reload must start a playable level one run")
	progression.add_xp(50)
	player.take_damage(100, false)
	await process_frame
	_expect(not paused and not game.get_node("CanvasLayer/LevelUpPanel").visible, "Death before deferred reward UI must not pause or show upgrades")
	game._spawn_enemy()
	enemy = get_nodes_in_group("enemies")[0]
	enemy.take_damage(100)
	_expect(progression.xp == 0, "Dead player must not receive further kill XP")
	_expect(not player.apply_upgrade(load("res://game/upgrades/health.tres")) and player.health == 0, "Health upgrade must not revive a dead player")
	game.free()
	if failures == 0:
		print("PASS: independent kill XP, HUD, upgrade effects, paused choices, multiple rewards, selection guards, area kills, death and reset")
	quit(1 if failures else 0)
