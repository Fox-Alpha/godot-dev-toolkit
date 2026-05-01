extends Node

# Hauptschleife, Input-Koordination, Kamera-Steuerung.
# Multiplayer: manages connection state and routes input commands.

@warning_ignore_start("unused_signal")
signal game_started
signal game_paused
signal game_resumed
signal level_changed(new_level: int)
@warning_ignore_restore("unused_signal")

var _tick_timer: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if World.is_paused:
		return
	_tick_timer += delta
	var tick_interval := _get_tick_interval()
	while _tick_timer >= tick_interval:
		_tick_timer -= tick_interval
		World.process_tick()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		toggle_pause()
	elif event.is_action_pressed("level_up"):
		change_level(1)
	elif event.is_action_pressed("level_down"):
		change_level(-1)
	elif event.is_action_pressed("speed_up"):
		set_speed(World.game_speed + 1)
	elif event.is_action_pressed("speed_down"):
		set_speed(World.game_speed - 1)


func toggle_pause() -> void:
	World.is_paused = !World.is_paused
	if World.is_paused:
		game_paused.emit()
	else:
		game_resumed.emit()


func change_level(delta: int) -> void:
	var new_level: int = clamp(
		World.current_level + delta,
		0,
		World.MAP_DEPTH - 1,
	)
	if new_level != World.current_level:
		World.current_level = new_level
		level_changed.emit(new_level)


func set_speed(speed: int) -> void:
	World.game_speed = clamp(speed, World.SPEED_MIN, World.SPEED_MAX)


func _get_tick_interval() -> float:
	# Schnellere Geschwindigkeit = kürzeres Intervall
	match World.game_speed:
		1:
			return 2.0
		2:
			return 1.0
		3:
			return 0.5
		4:
			return 0.25
		5:
			return 0.1
		_:
			return 0.5
