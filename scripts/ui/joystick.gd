class_name MobileVirtualJoystick
extends Control

## Reusable Multi-Touch & Desktop Virtual Analog Joystick for Godot 4.3 Mobile Games

signal joystick_released(output: Vector2)

@export var max_radius: float = 80.0
@export var deadzone: float = 0.12
@export var recenter_speed: float = 15.0
@export var base_color: Color = Color(0.1, 0.15, 0.22, 0.45)
@export var base_outline_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var knob_color: Color = Color(0.9, 0.92, 1.0, 0.65)
@export var knob_outline_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var knob_radius: float = 30.0

var _touch_index: int = -1 # -1 = inactive, >= 0 = touch index, -2 = mouse
var _knob_position: Vector2 = Vector2.ZERO # Local offset from center
var _output: Vector2 = Vector2.ZERO

@onready var _base_node: Control = $Base if has_node("Base") else null
@onready var _knob_node: Control = $Knob if has_node("Knob") else null

func _ready() -> void:
	custom_minimum_size = Vector2(max_radius * 2.5, max_radius * 2.5)
	pivot_offset = size * 0.5
	
	if _base_node:
		_base_node.position = size * 0.5
		_base_node.draw.connect(_draw_base)
		_base_node.queue_redraw()
	if _knob_node:
		_knob_node.position = size * 0.5
		_knob_node.draw.connect(_draw_knob)
		_knob_node.queue_redraw()
	
	resized.connect(_on_resized)

func _on_resized() -> void:
	pivot_offset = size * 0.5
	var center := size * 0.5
	if _base_node:
		_base_node.position = center
		_base_node.queue_redraw()
	if _knob_node:
		_knob_node.position = center + _knob_position
		_knob_node.queue_redraw()

func _draw_base() -> void:
	if _base_node:
		_base_node.draw_circle(Vector2.ZERO, max_radius, base_color)
		_base_node.draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 48, base_outline_color, 3.0)

func _draw_knob() -> void:
	if _knob_node:
		_knob_node.draw_circle(Vector2.ZERO, knob_radius, knob_color)
		_knob_node.draw_arc(Vector2.ZERO, knob_radius, 0.0, TAU, 32, knob_outline_color, 2.0)

func _input(event: InputEvent) -> void:
	# Screen Touch
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if _touch_index == -1 and _is_point_inside(touch_event.position):
				_touch_index = touch_event.index
				_update_from_global_pos(touch_event.position)
				get_viewport().set_input_as_handled()
		elif not touch_event.pressed and touch_event.index == _touch_index:
			_release_joystick()
			get_viewport().set_input_as_handled()

	# Screen Drag
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == _touch_index:
			_update_from_global_pos(drag_event.position)
			get_viewport().set_input_as_handled()

	# Desktop Mouse Button
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if _touch_index == -1 and _is_point_inside(mouse_event.position):
					_touch_index = -2
					_update_from_global_pos(mouse_event.position)
					get_viewport().set_input_as_handled()
			elif not mouse_event.pressed and _touch_index == -2:
				_release_joystick()
				get_viewport().set_input_as_handled()

	# Desktop Mouse Motion
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if _touch_index == -2:
			_update_from_global_pos(motion_event.position)
			get_viewport().set_input_as_handled()

func _is_point_inside(global_pos: Vector2) -> bool:
	var center_pos := get_global_center()
	return global_pos.distance_to(center_pos) <= max_radius * 1.3

func get_global_center() -> Vector2:
	return global_position + (size * 0.5)

func _update_from_global_pos(global_pos: Vector2) -> void:
	var center_pos := get_global_center()
	var offset := global_pos - center_pos
	var dist := offset.length()
	
	if dist > max_radius:
		offset = offset.normalized() * max_radius
		
	_knob_position = offset
	
	if _knob_node:
		_knob_node.position = (size * 0.5) + _knob_position
		
	_calculate_output(offset)

func _calculate_output(offset: Vector2) -> void:
	var raw_output := offset / max_radius
	var len := raw_output.length()
	
	if len < deadzone:
		_output = Vector2.ZERO
	else:
		var scaled_len := (len - deadzone) / (1.0 - deadzone)
		_output = raw_output.normalized() * minf(1.0, scaled_len)

func _release_joystick() -> void:
	var final_out := get_output()
	_touch_index = -1
	joystick_released.emit(final_out)

func _process(delta: float) -> void:
	if _touch_index == -1 and _knob_position.length_squared() > 0.001:
		_knob_position = _knob_position.lerp(Vector2.ZERO, recenter_speed * delta)
		if _knob_position.length_squared() < 0.25:
			_knob_position = Vector2.ZERO
			
		if _knob_node:
			_knob_node.position = (size * 0.5) + _knob_position
			
		_calculate_output(_knob_position)

func get_output() -> Vector2:
	return _output
