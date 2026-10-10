extends SceneTree

var failures := 0
var spawns: Array[bool] = []
var completions := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	if not ResourceLoader.exists("res://game/wave_director.gd"):
		_expect(false, "Run must provide finite wave scheduling")
		quit(1)
		return
	var director = load("res://game/wave_director.gd").new()
	root.add_child(director)
	director.set_process(false)
	director.spawn_requested.connect(func(boss: bool): spawns.append(boss))
	director.completed.connect(func(): completions += 1)
	director.start()
	_expect(director.wave_number == 0 and spawns.is_empty(), "First wave must wait for its announcement")
	director.advance(1.0)
	_expect(spawns.is_empty(), "Countdown must not spawn early")
	director.advance(1.0)
	_expect(director.wave_number == 1 and spawns.size() == 2, "First wave must open with two skeletons after two seconds")
	director.advance(1.9)
	_expect(spawns.size() == 2, "Groups must respect the wave interval")
	director.advance(0.11)
	_expect(spawns.size() == 4, "The next first-wave group must arrive after two seconds")
	director.start_next_wave()
	_expect(director.wave_number == 1, "Early-start input must not skip a living wave")

	var expected_totals := [8, 12, 16, 20, 7]
	var expected_openings := [2, 2, 3, 4, 3]
	var expected_intervals := [2.0, 1.8, 1.4, 1.0, 2.0]
	for wave in range(1, 6):
		if wave > 1:
			spawns.clear()
			director.start_next_wave()
			_expect(director.wave_number == wave, "Break must allow starting the next sequential wave")
			_expect(spawns.size() == expected_openings[wave - 1], "Each wave must open with its planned group and optional boss")
			var opening_count := spawns.size()
			director.advance(expected_intervals[wave - 1] - 0.1)
			_expect(spawns.size() == opening_count, "Later waves must also respect their configured intervals")
			director.advance(0.11)
			_expect(spawns.size() > opening_count, "Later wave intervals must actually release the next group")
		# Fill the arena without kills; deferred spawns must keep their budget.
		for tick in range(12):
			director.advance(3.0)
		_expect(director.living_enemies <= 10, "Simultaneous enemies, including the boss, must respect the cap")
		_expect(director.phase == director.Phase.ACTIVE, "A wave with living enemies must not end")
		for tick in range(50):
			if director.remaining_spawns == 0:
				break
			while director.living_enemies > 1:
				director.enemy_defeated()
			director.advance(3.0)
		_expect(spawns.size() == expected_totals[wave - 1], "Every wave must spend exactly its full quota despite the cap")
		_expect(spawns.count(true) == (1 if wave == 5 else 0), "Only the fifth wave must contain exactly one miniboss")
		while director.living_enemies > 1:
			director.enemy_defeated()
		_expect(director.phase == director.Phase.ACTIVE, "The final living enemy must block wave completion")
		director.enemy_defeated()
		var count_after_clear := spawns.size()
		director.enemy_defeated()
		if wave < 5:
			_expect(director.phase == director.Phase.INTERMISSION and director.phase_left == 5.0, "Clearing a wave must start a five-second break")
			director.advance(4.9)
			_expect(director.wave_number == wave and spawns.size() == count_after_clear, "Intermission must not spawn or advance early")
		else:
			_expect(director.phase == director.Phase.COMPLETE and completions == 1, "Final clear must complete the run exactly once")
			director.advance(100.0)
			director.start_next_wave()
			_expect(director.wave_number == 5 and spawns.size() == 7, "Victory must never start a sixth wave")
	director.free()

	# Automatic countdown and stop guards use a fresh run.
	director = load("res://game/wave_director.gd").new()
	root.add_child(director)
	director.set_process(false)
	director.start()
	director.advance(2.0)
	for tick in range(8):
		director.advance(2.0)
		while director.living_enemies > 0:
			director.enemy_defeated()
		if director.phase == director.Phase.INTERMISSION:
			break
	director.advance(5.0)
	_expect(director.wave_number == 2 and director.phase == director.Phase.ACTIVE, "Break countdown must automatically start wave two")
	director.stop()
	director.advance(100.0)
	director.start_next_wave()
	director.enemy_defeated()
	_expect(director.phase == director.Phase.STOPPED and director.wave_number == 2, "Stopped runs must ignore ticks, skips and late deaths")
	director.free()
	if failures == 0:
		print("PASS: wave countdowns, groups, quotas, cap, breaks, boss finale and stop guards")
	quit(1 if failures else 0)
