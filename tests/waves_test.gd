extends SceneTree

var failures := 0


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
	game.player.set_physics_process(false)
	return game


func _resolve_rewards(game) -> void:
	await process_frame
	for reward in range(20):
		if game._pending_levels.is_empty():
			break
		game.level_up_panel.get_node("%Choices").get_child(0).pressed.emit()
		await process_frame


func _accept_focused_button() -> void:
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = true
	root.push_input(event)
	event = InputEventAction.new()
	event.action = &"ui_accept"
	root.push_input(event)


func _click_button(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event)
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	root.push_input(event)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var probe = load("res://game/game.tscn").instantiate()
	root.add_child(probe)
	_expect(probe.get_node_or_null("WaveDirector") != null, "Game must connect finite wave scheduling instead of endless timers")
	if failures:
		probe.free()
		quit(1)
		return
	probe.free()
	var game = _new_game()
	var director = game.get_node("WaveDirector")
	var label = game.get_node("CanvasLayer/WaveLabel")
	var status = game.get_node("CanvasLayer/WaveStatus")
	var next_button = game.get_node("CanvasLayer/NextWaveButton")
	var victory = game.get_node("CanvasLayer/VictoryPanel")
	_expect(label.text == "WAVE 1" and get_nodes_in_group("enemies").is_empty(), "Fresh run must announce wave one without enemies")
	_expect(not next_button.visible and not victory.visible, "Skip and victory controls must stay hidden during preparation")
	director.advance(2.0)
	_expect(get_nodes_in_group("enemies").size() == 2 and label.text == "WAVE 1", "Announcement must start the first real group")
	_expect(label.text == "WAVE 1", "Wave HUD must display only its number, without enemy counts")
	game.player.take_damage(15, false)
	for wave in range(1, 6):
		var kills := 0
		var bosses := 0
		for tick in range(50):
			if director.phase != director.Phase.ACTIVE:
				break
			var enemies := get_nodes_in_group("enemies")
			# In the finale, kill the boss first and verify its adds still block victory.
			if wave == 5 and bosses == 0:
				var boss = get_nodes_in_group("minibosses")[0]
				boss.take_damage(10000)
				bosses += 1
				kills += 1
				_expect(director.phase == director.Phase.ACTIVE and not victory.visible, "Boss death must not win while adds remain or are pending")
			for enemy in enemies:
				if enemy.health <= 0:
					continue
				enemy.set_physics_process(false)
				# Force a reward on the final enemy, after clearing any earlier choices.
				if wave == 5 and director.remaining_spawns == 0 and director.living_enemies == 1:
					game.progression.xp = game.progression.xp_required - 10
				enemy.take_damage(10000)
				kills += 1
			if wave == 5 and director.phase == director.Phase.COMPLETE:
				await process_frame
				_expect(game.level_up_panel.visible and paused and not victory.visible, "Final-kill upgrade must be selectable before victory")
			await _resolve_rewards(game)
			if director.phase == director.Phase.ACTIVE:
				director.advance(3.0)
		_expect(kills == [8, 12, 16, 20, 7][wave - 1], "Real waves must contain exactly their agreed enemies")
		if wave < 5:
			_expect(director.phase == director.Phase.INTERMISSION and next_button.visible, "Cleared wave must offer a skippable break")
			_expect(status.text.begins_with("WAVE CLEARED") and label.text == "WAVE %d" % wave, "Break must show completion and only the wave number")
			var time_before: float = director.phase_left
			game.progression.add_xp(game.progression.xp_required)
			await process_frame
			director.set_process(true)
			await create_timer(0.1).timeout
			director.set_process(false)
			_expect(is_equal_approx(director.phase_left, time_before), "Upgrade selection must freeze the break countdown")
			await _resolve_rewards(game)
			var score_before: int = game.score
			var level_before: int = game.progression.level
			var health_before: int = game.player.health
			if wave == 1:
				_accept_focused_button()
			elif wave == 2:
				_click_button(next_button)
			else:
				next_button.pressed.emit()
			await process_frame
			_expect(director.wave_number == wave + 1 and not next_button.visible, "Next-wave button must start exactly the next wave and hide")
			if director.wave_number != wave + 1:
				game.free()
				quit(1)
				return
			_expect(game.score == score_before and game.progression.level == level_before and game.player.health == health_before, "Wave transitions must preserve score, XP and HP")
			_expect(label.text == "WAVE %d" % (wave + 1), "HUD must advance with the next wave")
	await process_frame
	_expect(victory.visible and paused and not game.player.can_process(), "Final clear must display victory and freeze combat")
	var replay = victory.get_node("%PlayAgainButton")
	_expect(replay.can_process() and replay.has_focus(), "Replay must accept keyboard and pointer input during victory pause")
	_expect(victory.get_node("%VictoryScore").text == "SCORE: 720", "Victory must report score from all 62 skeletons and the boss")
	current_scene = game
	_click_button(replay)
	await process_frame
	await process_frame
	game = current_scene
	director = game.get_node("WaveDirector")
	director.set_process(false)
	game.player.set_physics_process(false)
	_expect(not paused and game.score == 0 and game.progression.level == 1 and game.player.health == 100, "Replay must reset and unpause the whole run")
	_expect(director.phase == director.Phase.PREPARING and director.wave_number == 0, "Replay must restart from the first announcement")
	game.player.take_damage(100, false)
	director.advance(100.0)
	_expect(director.phase == director.Phase.STOPPED and get_nodes_in_group("enemies").is_empty(), "Death during announcement must prevent every future spawn")
	_expect(game.get_node("CanvasLayer/GameOverLabel").visible and not game.get_node("CanvasLayer/VictoryPanel").visible, "Death must retain game over and never show victory")
	game.free()
	current_scene = null

	game = _new_game()
	director = game.get_node("WaveDirector")
	director.advance(2.0)
	game.player.take_damage(100, false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.take_damage(10000)
	director.advance(100.0)
	await process_frame
	_expect(director.phase == director.Phase.STOPPED and not paused, "Late kills after death must not advance waves, show rewards or pause")
	game.free()
	if failures == 0:
		print("PASS: five real waves, HUD, intermissions, keyboard/mouse input, upgrades, boss-first finale, victory, replay and death")
	quit(1 if failures else 0)
