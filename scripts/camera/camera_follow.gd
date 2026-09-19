class_name CameraFollow
extends Camera3D

## High-Quality Smooth Tracking Camera with 360° Orbit Rotation & Dynamic Screenshake
@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 10.5, 9.5)
@export var follow_speed: float = 7.0
@export var orbit_sensitivity: float = 0.007
@export var zoom_sensitivity: float = 1.2

var orbit_angle: float = 0.0
var orbit_distance: float = 12.0
var orbit_height: float = 10.5
var is_orbiting: bool = false
var _has_dragged: bool = false

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
	orbit_distance = Vector2(offset.x, offset.z).length()
	if orbit_distance < 4.0:
		orbit_distance = 12.0
	orbit_height = offset.y
	orbit_angle = atan2(offset.x, offset.z)
	if not target:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			orbit_distance = clampf(orbit_distance - zoom_sensitivity, 6.0, 24.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			orbit_distance = clampf(orbit_distance + zoom_sensitivity, 6.0, 24.0)
			
	elif event is InputEventMouseMotion and is_orbiting:
		var mm := event as InputEventMouseMotion
		orbit_angle = wrapf(orbit_angle - mm.relative.x * orbit_sensitivity, -PI, PI)
		orbit_height = clampf(orbit_height - mm.relative.y * 0.025, 4.0, 18.0)

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D
		if not target:
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				target = players[0] as Node3D
		return
	
	_time += delta * 45.0
	var rot_x := sin(orbit_angle) * orbit_distance
	var rot_z := cos(orbit_angle) * orbit_distance
	var desired_pos := target.global_position + Vector3(rot_x, orbit_height, rot_z)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	look_at(target.global_position + Vector3(0, 1.2, 0), Vector3.UP)
	
	# Apply dynamic screenshake
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - _trauma_reduction_rate * delta)
		var shake_amount: float = _trauma * _trauma # Non-linear shake curve for punchy feel
		var shake_x: float = sin(_time * 1.3) * _max_shake_offset * shake_amount
		var shake_y: float = cos(_time * 1.7) * _max_shake_offset * shake_amount
		var shake_z: float = sin(_time * 2.1) * (_max_shake_offset * 0.5) * shake_amount
		global_position += Vector3(shake_x, shake_y, shake_z)
		rotation.z = sin(_time * 1.5) * _max_shake_angle * shake_amount
	
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

