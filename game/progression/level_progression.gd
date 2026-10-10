extends Node

signal xp_changed(current: int, required: int)
signal leveled_up(new_level: int)

var level: int = 1
var xp: int = 0
var xp_required: int:
	get:
		return 50 + 30 * (level - 1)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_required)
