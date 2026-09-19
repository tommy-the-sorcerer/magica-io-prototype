class_name CameraFollow
extends Camera3D

## High-Quality Smooth Tracking Camera with Dynamic Screenshake
@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 10.5, 9.5)
@export var follow_speed: float = 7.0

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
	if not target:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D
		return
	
	_time += delta * 45.0
	var desired_pos: Vector3 = target.global_position + offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
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

