extends SceneTree

var failures: int = 0
var levels: Array[int] = []
var xp_updates: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	if not ResourceLoader.exists("res://game/progression/level_progression.gd"):
		_expect(false, "Run must provide an XP progression component")
		quit(1)
		return
	var progression = load("res://game/progression/level_progression.gd").new()
	root.add_child(progression)
	progression.leveled_up.connect(func(value: int): levels.append(value))
	progression.xp_changed.connect(func(current: int, required: int): xp_updates.append([current, required]))
	progression.add_xp(49)
	_expect(progression.level == 1 and progression.xp == 49, "XP below threshold must not level up")
	progression.add_xp(1)
	_expect(progression.level == 2 and progression.xp == 0 and progression.xp_required == 80, "Exact threshold must advance and update next cost")
	_expect(levels == [2] and xp_updates.back() == [0, 80], "Signals must report the new level and HUD values")
	progression.add_xp(0)
	progression.add_xp(-20)
	_expect(progression.xp == 0 and levels == [2] and xp_updates.size() == 2, "Nonpositive XP must not change progression or emit updates")
	var fresh = load("res://game/progression/level_progression.gd").new()
	root.add_child(fresh)
	_expect(fresh.level == 1 and fresh.xp == 0, "New run must start with independent progression")
	levels.clear()
	fresh.leveled_up.connect(func(value: int): levels.append(value))
	fresh.add_xp(245)
	_expect(fresh.level == 4 and fresh.xp == 5 and fresh.xp_required == 140, "Large grant must cross 50, 80, 110 and preserve five XP")
	_expect(levels == [2, 3, 4], "Every crossed level must award its own reward")
	progression.free()
	fresh.free()
	if failures == 0:
		print("PASS: XP thresholds, carryover, multiple levels, signals, invalid grants and independent runs")
	quit(1 if failures else 0)
