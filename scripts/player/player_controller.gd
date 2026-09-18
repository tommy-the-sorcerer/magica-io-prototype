class_name PlayerController
extends CharacterBody3D

## Playable Wizard Hero with Dual Mobile Virtual Joysticks & Isometric Aiming/Casting

signal spell_cast(spell_scene: PackedScene, origin_position: Vector3, forward_direction: Vector3)

@export_group("Movement Settings")
@export var move_speed: float = 7.0
@export var acceleration: float = 20.0
@export var deceleration: float = 25.0
@export var rotation_speed: float = 12.0

@export_group("Combat & Spell Settings")
@export var spell_scene: PackedScene
@export var aim_threshold: float = 0.3

@export_group("Node References")
@export var move_joystick: VirtualJoystick
@export var aim_joystick: VirtualJoystick
@export var cast_point: Marker3D

var display_name: String = "Player#51393"

@onready var visuals: Node3D = $Visuals if has_node("Visuals") else null
@onready var health_component: HealthComponent = $HealthComponent if has_node("HealthComponent") else null
@onready var nameplate: Label3D = $Nameplate3D if has_node("Nameplate3D") else null

var _mouse_aim_start: Vector2 = Vector2.ZERO
var _is_mouse_aiming: bool = false
var _last_mouse_aim_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_nameplate(health_component.current_health, health_component.max_health)

	if not cast_point and visuals:
		cast_point = visuals.find_child("CastPoint", true, false) as Marker3D
	if not cast_point:
		cast_point = find_child("CastPoint", true, false) as Marker3D

	_setup_joysticks()

func _setup_joysticks() -> void:
	if not move_joystick:
		move_joystick = get_tree().current_scene.find_child("MoveJoystick", true, false) as VirtualJoystick
		if not move_joystick:
			move_joystick = get_tree().current_scene.find_child("LeftJoystick", true, false) as VirtualJoystick

	if not aim_joystick:
		aim_joystick = get_tree().current_scene.find_child("AimJoystick", true, false) as VirtualJoystick
		if not aim_joystick:
			aim_joystick = get_tree().current_scene.find_child("RightJoystick", true, false) as VirtualJoystick

	if aim_joystick and not aim_joystick.joystick_released.is_connected(_on_aim_joystick_released):
		aim_joystick.joystick_released.connect(_on_aim_joystick_released)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s" % [int(curr), int(max_hp), display_name]
		nameplate.modulate = Color(0.6, 0.95, 0.3) if curr > 30 else Color(0.95, 0.3, 0.3)

func _physics_process(delta: float) -> void:
	if not move_joystick or not aim_joystick:
		_setup_joysticks()

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# --- 1. Movement Input (Joystick + WASD Fallback) ---
	var input_dir := Vector2.ZERO
	if move_joystick:
		input_dir = move_joystick.get_output()

	if input_dir.length_squared() < 0.01:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_dir.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_dir.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_dir.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_dir.x += 1

	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	# Map joystick X -> world X, joystick Y -> world Z
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	var target_vel := move_dir * move_speed

	if move_dir.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta * move_speed)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta * move_speed)

	move_and_slide()

	# --- 2. Aiming Input (Right Joystick + Mouse Fallback) ---
	var aim_input := Vector2.ZERO
	if aim_joystick:
		aim_input = aim_joystick.get_output()

	var is_aiming := false
	var active_aim_dir := Vector3.ZERO

	if aim_input.length() >= aim_threshold:
		active_aim_dir = Vector3(aim_input.x, 0.0, aim_input.y).normalized()
		is_aiming = true
	elif _is_mouse_aiming:
		var mouse_dir := _get_mouse_world_dir()
		if mouse_dir.length_squared() > 0.01:
			active_aim_dir = mouse_dir
			_last_mouse_aim_dir = mouse_dir
			is_aiming = true

	# --- 3. Rotation & Wobble Walk ---
	if visuals:
		if is_aiming and active_aim_dir.length_squared() > 0.01:
			var target_angle := atan2(active_aim_dir.x, active_aim_dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
		elif move_dir.length_squared() > 0.01:
			var target_angle := atan2(move_dir.x, move_dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)

		# Voxel Wobble Walk
		var speed_sq := Vector2(velocity.x, velocity.z).length_squared()
		if speed_sq > 0.1:
			var wobble := sin(Time.get_ticks_msec() * 0.015) * 0.087 # ~5 degrees roll
			visuals.rotation.z = wobble
		else:
			visuals.rotation.z = move_toward(visuals.rotation.z, 0.0, 8.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	# Desktop Mouse Aiming & Casting Fallback
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_LEFT:
			if not aim_joystick or aim_joystick.get_output().length() < aim_threshold:
				if mb.pressed:
					_mouse_aim_start = mb.position
					_is_mouse_aiming = true
				else:
					if _is_mouse_aiming:
						_is_mouse_aiming = false
						var cast_dir := _last_mouse_aim_dir
						if cast_dir.length_squared() > 0.01:
							_trigger_spell_cast(cast_dir)

func _get_mouse_world_dir() -> Vector3:
	var viewport := get_viewport()
	if not viewport:
		return Vector3.ZERO
	var camera := viewport.get_camera_3d()
	if not camera:
		return Vector3.ZERO
	
	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	
	var ground_plane := Plane(Vector3.UP, global_position.y)
	var hit_pos = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit_pos:
		var dir := (hit_pos - global_position)
		dir.y = 0.0
		return dir.normalized()
	return Vector3.ZERO

func _on_aim_joystick_released(final_output: Vector2) -> void:
	if final_output.length() >= aim_threshold:
		var cast_dir := Vector3(final_output.x, 0.0, final_output.y).normalized()
		_trigger_spell_cast(cast_dir)

func _trigger_spell_cast(direction: Vector3) -> void:
	if direction.length_squared() < 0.01:
		return

	if visuals:
		visuals.rotation.y = atan2(direction.x, direction.z)

	var origin := global_position + Vector3(0, 0.8, 0)
	if cast_point:
		origin = cast_point.global_position

	spell_cast.emit(spell_scene, origin, direction)

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
