class_name TouchStick
extends Control
## SC-09 Touch joystick (named TouchStick: Godot 4.7 has its own VirtualJoystick class) for the base map (shown on touch screens). Drag inside the base.

signal moved(dir: Vector2)

const RADIUS := 56.0

var base: TextureRect
var knob: TextureRect
var touch_index := -1


func _ready() -> void:
	custom_minimum_size = Vector2(128, 128)
	size = Vector2(128, 128)
	base = Ui.image("ui_joystick_base")
	base.size = Vector2(128, 128)
	add_child(base)
	knob = Ui.image("ui_joystick_knob")
	knob.size = Vector2(64, 64)
	add_child(knob)
	_set_knob(Vector2.ZERO)


func _set_knob(offset: Vector2) -> void:
	knob.position = Vector2(32, 32) + offset
	moved.emit(offset / RADIUS)


func _gui_input(event: InputEvent) -> void:
	var center := Vector2(64, 64)
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and touch_index == -1:
			touch_index = t.index
			_set_knob((t.position - center).limit_length(RADIUS))
		elif not t.pressed and t.index == touch_index:
			touch_index = -1
			_set_knob(Vector2.ZERO)
		accept_event()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == touch_index:
			_set_knob((d.position - center).limit_length(RADIUS))
		accept_event()
