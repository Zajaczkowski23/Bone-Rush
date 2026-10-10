extends Node

signal spawn_requested(is_miniboss: bool)
signal phase_changed
signal completed

enum Phase { IDLE, PREPARING, ACTIVE, INTERMISSION, COMPLETE, STOPPED }

const WAVES: Array[Dictionary] = [
	{"skeletons": 8, "group_size": 2, "interval": 2.0},
	{"skeletons": 12, "group_size": 2, "interval": 1.8},
	{"skeletons": 16, "group_size": 3, "interval": 1.4},
	{"skeletons": 20, "group_size": 4, "interval": 1.0},
	{"skeletons": 6, "group_size": 2, "interval": 2.0},
]

var max_enemies: int = 10
var phase: Phase = Phase.IDLE
var wave_number: int = 0
var phase_left: float = 0.0
var remaining_spawns: int = 0
var living_enemies: int = 0
var _spawn_left: float = 0.0


func start() -> void:
	if phase != Phase.IDLE:
		return
	phase = Phase.PREPARING
	phase_left = 2.0
	phase_changed.emit()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if phase == Phase.PREPARING or phase == Phase.INTERMISSION:
		phase_left = maxf(phase_left - delta, 0.0)
		if phase_left == 0.0:
			_start_wave()
	elif phase == Phase.ACTIVE:
		_spawn_left -= delta
		if _spawn_left <= 0.0:
			_spawn_group()


func start_next_wave() -> void:
	if phase == Phase.INTERMISSION:
		_start_wave()


func _start_wave() -> void:
	wave_number += 1
	phase = Phase.ACTIVE
	phase_left = 0.0
	remaining_spawns = WAVES[wave_number - 1].skeletons
	living_enemies = 0
	phase_changed.emit()
	if wave_number == WAVES.size():
		living_enemies += 1
		spawn_requested.emit(true)
	_spawn_group()


func _spawn_group() -> void:
	var wave := WAVES[wave_number - 1]
	var slots := maxi(max_enemies, 1) - living_enemies
	var count := mini(int(wave.group_size), mini(remaining_spawns, slots))
	for index in range(count):
		remaining_spawns -= 1
		living_enemies += 1
		spawn_requested.emit(false)
	_spawn_left = wave.interval


func enemy_defeated() -> void:
	if phase != Phase.ACTIVE or living_enemies <= 0:
		return
	living_enemies -= 1
	if remaining_spawns > 0 or living_enemies > 0:
		return
	if wave_number == WAVES.size():
		phase = Phase.COMPLETE
		phase_changed.emit()
		completed.emit()
	else:
		phase = Phase.INTERMISSION
		phase_left = 5.0
		phase_changed.emit()


func stop() -> void:
	phase = Phase.STOPPED
	phase_left = 0.0
	phase_changed.emit()
