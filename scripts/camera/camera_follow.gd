class_name CameraFollow
extends Camera3D

## 360-Degree Camera Orbit with Dynamic Screenshake, FOV Kick, and Multi-Input Control
## Supports Laptop Trackpad Two-Finger Pan, Mouse Drag, Touch Swipe, Q/E Keys, Pinch & Wheel Zoom
@export var target: Node3D
@export var follow_speed: float = 8.0

# Zoom Settings
@export var min_distance: float = 5.0
@export var max_distance: float = 24.0
@export var zoom_speed: float = 1.5
var current_distance: float = 16.0
var target_distance: float = 16.0

# Orbit / 360-Degree Rotation
var yaw: float = 0.0
var pitch: float = -45.0
var is_dragging: bool = false
var touch_start_dist: float = 0.0
var active_touches: Dictionary = {}

var _trauma: float = 0.0
var _trauma_reduction_rate: float = 2.2
var _max_shake_offset: float = 0.45
var _max_shake_angle: float = 0.03
var _time: float = 0.0

var _base_fov: float = 75.0
var _target_fov_offset: float = 0.0
var _current_fov_offset: float = 0.0

func _ready() -> void:
	_base_fov = fov
	_find_target()

func _find_target() -> void:
	if not target:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D
	if not target:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D

func _unhandled_input(event: InputEvent) -> void:
	# 1. LAPTOP TRACKPAD TWO-FINGER PAN GESTURE (Moving 2 fingers left/right on mousepad)
	if event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		yaw -= pan.delta.x * 0.06
		pitch = clampf(pitch - pan.delta.y * 0.04, -75.0, -18.0)

	# 2. LAPTOP TRACKPAD PINCH-TO-ZOOM GESTURE
	elif event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		target_distance = clampf(target_distance / mag.factor, min_distance, max_distance)

	# 3. MOUSE WHEEL & HORIZONTAL TRACKPAD WHEEL EVENTS
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_distance = clampf(target_distance - zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_distance = clampf(target_distance + zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_LEFT and mb.pressed:
			yaw -= 0.18
		elif mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT and mb.pressed:
			yaw += 0.18
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = mb.pressed

	# 4. MOUSE DRAG MOTION (When holding left/right click and moving)
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		yaw -= mm.relative.x * 0.007
		pitch = clampf(pitch - mm.relative.y * 0.004, -75.0, -18.0)

	# 5. MOBILE TOUCH EVENTS (Two-finger pinch-to-zoom & single-finger swipe orbit)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			active_touches[st.index] = st.position
		else:
			active_touches.erase(st.index)
			if active_touches.size() < 2:
				touch_start_dist = 0.0

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		active_touches[sd.index] = sd.position
		
		if active_touches.size() >= 2:
			var touch_keys: Array = active_touches.keys()
			var p1: Vector2 = active_touches[touch_keys[0]]
			var p2: Vector2 = active_touches[touch_keys[1]]
			var dist: float = p1.distance_to(p2)
			
			if touch_start_dist > 0.0:
				var delta_dist: float = dist - touch_start_dist
				target_distance = clampf(target_distance - delta_dist * 0.04, min_distance, max_distance)
			touch_start_dist = dist
		elif active_touches.size() == 1 and sd.position.x > get_viewport().size.x * 0.25 and sd.position.x < get_viewport().size.x * 0.75:
			yaw -= sd.relative.x * 0.006

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_find_target()
		return

	current_distance = lerpf(current_distance, target_distance, delta * 8.0)

	var pitch_rad: float = deg_to_rad(pitch)
	var yaw_rad: float = yaw
	
	var offset := Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		-sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	) * current_distance

	var target_cam_pos: Vector3 = target.global_position + offset
	global_position = global_position.lerp(target_cam_pos, follow_speed * delta)
	
	look_at(target.global_position + Vector3(0, 1.2, 0), Vector3.UP)
	
	# Apply dynamic screenshake
	_time += delta * 45.0
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - _trauma_reduction_rate * delta)
		var shake_amount: float = _trauma * _trauma # Non-linear shake curve
		var shake_x: float = sin(_time * 1.3) * _max_shake_offset * shake_amount
		var shake_y: float = cos(_time * 1.7) * _max_shake_offset * shake_amount
		var shake_z: float = sin(_time * 2.1) * (_max_shake_offset * 0.5) * shake_amount
		global_position += Vector3(shake_x, shake_y, shake_z)
		rotation.z += sin(_time * 1.5) * _max_shake_angle * shake_amount
	
	# Dynamic FOV kick interpolation
	_current_fov_offset = lerp(_current_fov_offset, _target_fov_offset, 14.0 * delta)
	_target_fov_offset = lerp(_target_fov_offset, 0.0, 6.0 * delta)
	fov = _base_fov + _current_fov_offset

## Adds impact screenshake trauma (0.0 to 1.0)
func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

## Triggers cinematic FOV expansion during supersonic dashes
func trigger_fov_kick(kick_degrees: float = 5.5) -> void:
	_target_fov_offset = kick_degrees
