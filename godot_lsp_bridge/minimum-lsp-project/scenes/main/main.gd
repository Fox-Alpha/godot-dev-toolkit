class_name Main
extends Control

## Emitted when the greeting changes.
signal text_changed(new_text: String)

const GREETING: String = "Hello, LSP!"

@export var display_name: String = "Tester"

var _click_count: int = 0


func _ready() -> void:
	text_changed.emit(GREETING)
	print(_build_message(0))


func increment() -> void:
	_click_count += 1
	var msg: String = _build_message(_click_count)
	text_changed.emit(msg)
	print(msg)


func _build_message(count: int) -> String:
	return "%s: click #%d" % [display_name, count]
