extends Camera3D

## 360-Degree Orbit & Pinch-to-Zoom Isometric Follow Camera

@export var target: Node3D
@export var follow_speed: float = 8.0

# Zoom Settings
@export var min_distance: float = 5.5
@export var max_distance: float = 24.0
@export var zoom_speed: float = 1.5
var current_distance: float = 11.0
var target_distance: float = 11.0

# Orbit / 360-Degree Rotation
var yaw: float = 0.0 # Horizontal 360 degree rotation
var pitch: float = -42.0 # Isometric tilt angle down
var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var touch_start_dist: float = 0.0
var active_touches: Dictionary = {}

func _ready() -> void:
	if not target:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Wheel Zoom
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_distance = clampf(target_distance - zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_distance = clampf(target_distance + zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = mb.pressed

	# Mouse Drag Rotation (360 degrees)
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		yaw -= mm.relative.x * 0.008
		pitch = clampf(pitch - mm.relative.y * 0.005, -75.0, -20.0)

	# Mobile Touch Pinch-to-Zoom and Swipe Orbit
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
		
		# Two fingers = Pinch to Zoom
		if active_touches.size() >= 2:
			var touch_keys: Array = active_touches.keys()
			var p1: Vector2 = active_touches[touch_keys[0]]
			var p2: Vector2 = active_touches[touch_keys[1]]
			var dist: float = p1.distance_to(p2)
			
			if touch_start_dist > 0.0:
				var delta_dist: float = dist - touch_start_dist
				target_distance = clampf(target_distance - delta_dist * 0.04, min_distance, max_distance)
			touch_start_dist = dist
		# One finger drag on right screen (outside joystick) = 360 Camera Orbit
		elif active_touches.size() == 1 and sd.position.x > get_viewport().size.x * 0.35 and sd.position.y < get_viewport().size.y * 0.7:
			yaw -= sd.relative.x * 0.006

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D
		return

	# Smooth Zoom Interpolation
	current_distance = lerpf(current_distance, target_distance, delta * 8.0)

	# Calculate 360-Degree Camera Position around Player
	var pitch_rad: float = deg_to_rad(pitch)
	var yaw_rad: float = yaw
	
	var offset := Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		-sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	) * current_distance

	var target_cam_pos: Vector3 = target.global_position + offset
	global_position = global_position.lerp(target_cam_pos, follow_speed * delta)
	
	# Look at the player's chest height
	look_at(target.global_position + Vector3(0, 1.2, 0), Vector3.UP)
