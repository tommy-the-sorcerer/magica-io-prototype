class_name ApprenticeController
extends CharacterBody3D

## Arcane Apprentice - Lightning / Electro Sorcerer
## Features floating crackling Electro Ball, blue cowl & cape, Electro Blast attack, Lightning Dash [Q], and Electro Sphere Shield [R].
## [E] Special ability is disabled per specification.

@export_group("Movement")
@export var move_speed: float = 7.5
@export var acceleration: float = 35.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 720.0

@export_group("Spells")
@export var electro_blast_scene: PackedScene = preload("res://characters/arcane_apprentice/skills/electro_blast.tscn")
@export var electro_shield_scene: PackedScene = preload("res://characters/arcane_apprentice/skills/electro_shield.tscn")
@export var dash_burst_scene: PackedScene = preload("res://characters/arcane_apprentice/vfx/electro_dash_burst.tscn")
@export var dash_ghost_scene: PackedScene = preload("res://characters/arcane_apprentice/vfx/electro_dash_ghost.tscn")
@export var spell_cooldown: float = 0.38
@export var shield_cooldown: float = 7.0
@export var dash_cooldown: float = 3.0
@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.22

# Core Gameplay Attack Release Pipeline Standards
const INPUT_BUFFER_WINDOW: float = 0.08
const CAST_START_DELAY: float = 0.12
const ATTACK_RELEASE_TIME: float = 0.20
const ATTACK_RECOVERY_TIME: float = 0.18
const TOTAL_ATTACK_ANIM_TIME: float = 0.38

var _is_casting_attack: bool = false
var _attack_timer: float = 0.0
var _attack_released: bool = false
var _buffered_attack: bool = false

var display_name: String = "⚡ Arcane Apprentice"
var can_cast: bool = true
var _shield_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _active_shield: Node3D = null

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _ghost_spawn_timer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _stagger_timer: float = 0.0
var _invulnerable_buffer: float = 0.0

var _speed_modifier: float = 1.0
var _slow_timer: float = 0.0
var _is_slowed: bool = false

@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D

# Visual sub-nodes
@onready var head_node: Node3D = $Visuals.find_child("Head", true, false) as Node3D
@onready var left_arm: Node3D = $Visuals.find_child("LeftArm", true, false) as Node3D
@onready var right_arm: Node3D = $Visuals.find_child("RightArm", true, false) as Node3D
@onready var left_leg: Node3D = $Visuals.find_child("LeftLeg", true, false) as Node3D
@onready var right_leg: Node3D = $Visuals.find_child("RightLeg", true, false) as Node3D
@onready var cape: Node3D = $Visuals.find_child("Cape", true, false) as Node3D
@onready var electro_ball: Node3D = $Visuals.find_child("ElectroBall", true, false) as Node3D
@onready var electro_ring: Node3D = $Visuals.find_child("Ring", true, false) as Node3D
@onready var ball_light: OmniLight3D = $Visuals.find_child("BallLight", true, false) as OmniLight3D

var _orig_left_arm_rot: Vector3 = Vector3.ZERO
var _orig_right_arm_rot: Vector3 = Vector3.ZERO
var _orig_electro_ball_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if left_arm: _orig_left_arm_rot = left_arm.rotation
	if right_arm: _orig_right_arm_rot = right_arm.rotation
	if electro_ball: _orig_electro_ball_pos = electro_ball.position
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_player_died)
		_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if not nameplate:
		return
	var status_tag: String = " ❄️" if _is_slowed else ""
	var shield_tag: String = " | 🛡️ [R]" if _shield_timer <= 0.0 else ""
	var dash_tag: String = " | ⚡ [Q]" if _dash_cd_timer <= 0.0 else ""
	nameplate.text = "⚡ [ %d / %d ]%s%s%s\n%s (Lvl 1)" % [int(curr), int(max_hp), status_tag, shield_tag, dash_tag, display_name]
	nameplate.modulate = Color(0.4, 0.9, 1.0) if _is_slowed else (Color(0.4, 0.85, 1.0) if curr > 40 else Color(0.95, 0.3, 0.3))

func _unhandled_input(event: InputEvent) -> void:
	if not health_component or not health_component.is_alive():
		return
	
	# Primary attack: Electro Blast (follows Attack Release Standards)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_request_electro_blast()
	elif event is InputEventKey and event.pressed and not event.echo:
		var keycode: int = (event as InputEventKey).keycode
		if keycode == KEY_SPACE:
			_request_electro_blast()
		elif (keycode == KEY_R or keycode == KEY_C) and _shield_timer <= 0.0:
			_cast_electro_shield()
		elif keycode == KEY_Q and _dash_cd_timer <= 0.0:
			_perform_dash()
		# NOTE: [E] key is deliberately NOT bound (no special attack per user request)

## Computes world-space aiming direction pointing directly toward mouse cursor
func _get_mouse_aim_direction() -> Vector3:
	var viewport := get_viewport()
	if not viewport:
		return -visuals.global_transform.basis.z
	var mouse_pos := viewport.get_mouse_position()
	var cam := viewport.get_camera_3d()
	if not cam:
		return -visuals.global_transform.basis.z
	var ray_origin := cam.project_ray_origin(mouse_pos)
	var ray_normal := cam.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, global_position.y)
	var hit_pos = plane.intersects_ray(ray_origin, ray_normal)
	if hit_pos != null:
		var dir: Vector3 = (hit_pos as Vector3) - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			return dir.normalized()
	return -visuals.global_transform.basis.z

## Requests Electro Blast with 0.08s input buffering
func _request_electro_blast() -> void:
	if not _is_casting_attack:
		_start_electro_blast_pipeline()
	else:
		# Check if button pressed during the 0.08s Input Buffer window before recovery completes
		var time_remaining: float = TOTAL_ATTACK_ANIM_TIME - _attack_timer
		if time_remaining <= INPUT_BUFFER_WINDOW:
			_buffered_attack = true

func _start_electro_blast_pipeline() -> void:
	if not can_cast:
		return
	can_cast = false
	_is_casting_attack = true
	_attack_timer = 0.0
	_attack_released = false
	_buffered_attack = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Cooldown timers
	if _shield_timer > 0.0:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_timer = 0.0
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)
	
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
		if _dash_cd_timer <= 0.0:
			_dash_cd_timer = 0.0
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)
	
	if _invulnerable_buffer > 0.0:
		_invulnerable_buffer -= delta
		if _invulnerable_buffer <= 0.0 and not _is_dashing:
			if health_component:
				health_component.invulnerable = false
	
	if _knockback_velocity.length_squared() > 0.01:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 38.0 * delta)
	
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
	
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_modifier = 1.0
			_is_slowed = false
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)
	
	# Attack Release Standards Pipeline
	# 0.00s: Press | 0.12s: Cast Start Delay | 0.20s: Attack Release | 0.18s Recovery -> 0.38s Total
	if _is_casting_attack:
		_attack_timer += delta
		
		# Phase 1: Cast Start Delay (0.0s to 0.12s) - Electro ball surges and draws back
		if _attack_timer < CAST_START_DELAY:
			if electro_ball:
				electro_ball.position.z = lerp(electro_ball.position.z, _orig_electro_ball_pos.z + 0.14, 20.0 * delta)
		# Phase 2: Attack Release Time (at 0.20s after button press)
		elif _attack_timer >= ATTACK_RELEASE_TIME and not _attack_released:
			_attack_released = true
			_spawn_electro_blast()
		# Phase 3: Recovery Time (0.20s to 0.38s)
		elif _attack_timer >= ATTACK_RELEASE_TIME:
			if electro_ball:
				electro_ball.position.z = lerp(electro_ball.position.z, _orig_electro_ball_pos.z, 14.0 * delta)
		
		# Minimum Total Animation Time (0.38s) reached
		if _attack_timer >= TOTAL_ATTACK_ANIM_TIME:
			_is_casting_attack = false
			can_cast = true
			if _buffered_attack:
				_buffered_attack = false
				_start_electro_blast_pipeline()
	
	# Active Dash Processing (Dash Standard: Speed 16.0 units/s, Duration 0.22s)
	if _is_dashing:
		_dash_timer -= delta
		
		# Spawn lightning afterimages
		_ghost_spawn_timer -= delta
		if _ghost_spawn_timer <= 0.0:
			_ghost_spawn_timer = 0.04
			_spawn_dash_ghost()
		
		var progress: float = clampf(1.0 - (_dash_timer / dash_duration), 0.0, 1.0)
		var speed_mult: float = lerp(1.18, 0.92, progress)
		var current_speed: float = dash_speed * speed_mult
		velocity.x = _dash_direction.x * current_speed
		velocity.z = _dash_direction.z * current_speed
		
		visuals.rotation.x = lerp_angle(visuals.rotation.x, -0.36, 20.0 * delta)
		
		move_and_slide()
		_animate_apprentice(delta, true)
		
		if _dash_timer <= 0.0:
			_end_dash()
		return
	
	# Standard movement (Players can move during casting per specifications)
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	input_dir = input_dir.normalized()
	
	var effective_speed: float = move_speed * _speed_modifier
	var is_moving: bool = input_dir.length_squared() > 0.01
	
	# Core Movement: Acceleration 35 units/s², Deceleration 45 units/s²
	if is_moving:
		var target_vel := Vector3(input_dir.x, 0, input_dir.y) * effective_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	
	# Core Rotation: Rotation Speed (towards mouse): 720°/second
	var aim_dir := _get_mouse_aim_direction()
	var target_rot_y: float = visuals.rotation.y
	if aim_dir.length_squared() > 0.01:
		target_rot_y = atan2(-aim_dir.x, -aim_dir.z)
	elif is_moving:
		target_rot_y = atan2(-input_dir.x, -input_dir.y)
	
	var angle_diff: float = wrapf(target_rot_y - visuals.rotation.y, -PI, PI)
	var max_rot: float = deg_to_rad(rotation_speed) * delta
	if absf(angle_diff) <= max_rot:
		visuals.rotation.y = target_rot_y
	else:
		visuals.rotation.y += signf(angle_diff) * max_rot
	visuals.rotation.y = wrapf(visuals.rotation.y, -PI, PI)
	
	if is_moving:
		visuals.rotation.z = sin(Time.get_ticks_msec() * 0.018) * 0.08
	else:
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 8.0 * delta)
		visuals.rotation.x = move_toward(visuals.rotation.x, 0, 8.0 * delta)
	
	move_and_slide()
	_animate_apprentice(delta, is_moving)

## Casts crackling Electro Blast from the floating ball (released at 0.20s)
func _spawn_electro_blast() -> void:
	if not electro_blast_scene:
		return
	
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir.length_squared() < 0.01:
		aim_dir = -visuals.global_transform.basis.z
		aim_dir.y = 0.0
		if aim_dir.length_squared() < 0.01:
			aim_dir = Vector3.FORWARD
	aim_dir = aim_dir.normalized()
	
	var proj: Node3D = electro_blast_scene.instantiate() as Node3D
	if proj:
		proj.set("caster", self)
		get_tree().current_scene.add_child(proj)
		
		if _active_shield and is_instance_valid(_active_shield):
			# Fire directly from the golden center boss of the active shield!
			proj.global_position = _active_shield.global_position + aim_dir * 0.25
		else:
			var cast_pt: Node3D = visuals.find_child("CastPoint", true, false) as Node3D
			if cast_pt:
				proj.global_position = cast_pt.global_position
			else:
				proj.global_position = global_position + aim_dir * 0.8 + Vector3(0, 0.6, 0)
		
		proj.look_at(proj.global_position + aim_dir, Vector3.UP)
	
	# Animate left arm & electro ball casting impulse
	if electro_ball and electro_ball.visible:
		var bt := create_tween()
		bt.tween_property(electro_ball, "position:z", _orig_electro_ball_pos.z - 0.24, 0.06)
		bt.tween_property(electro_ball, "position:z", _orig_electro_ball_pos.z, 0.12)

## Animates floating electro ball, walking legs, running cape sway
func _animate_apprentice(delta: float, is_moving: bool) -> void:
	var time_ms := Time.get_ticks_msec()
	
	# Floating Electro Ball hover & gyro rotation (only when in hand and shield is inactive)
	if electro_ball and electro_ball.visible and not _active_shield:
		var hover_y: float = _orig_electro_ball_pos.y + sin(time_ms * 0.005) * 0.04
		electro_ball.position.y = lerp(electro_ball.position.y, hover_y, 8.0 * delta)
	
	if electro_ring:
		electro_ring.rotation.z += 9.0 * delta
		electro_ring.rotation.y += 6.0 * delta
	
	if ball_light and electro_ball and electro_ball.visible:
		ball_light.light_energy = 2.2 + sin(time_ms * 0.012) * 0.4
	
	# Cape flutter
	if cape:
		var cape_flutter: float = sin(time_ms * (0.015 if is_moving else 0.006)) * (0.28 if is_moving else 0.08)
		cape.rotation.x = lerp_angle(cape.rotation.x, 0.25 + cape_flutter, 8.0 * delta)
	
	# Running legs
	if is_moving and not _is_dashing:
		var walk_cycle: float = sin(time_ms * 0.018) * 0.65
		if left_leg: left_leg.rotation.x = walk_cycle
		if right_leg: right_leg.rotation.x = -walk_cycle
		if right_arm: right_arm.rotation.x = -walk_cycle * 0.5
	else:
		if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, 8.0 * delta)
		if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, 8.0 * delta)
		if right_arm: right_arm.rotation.x = lerp_angle(right_arm.rotation.x, _orig_right_arm_rot.x, 8.0 * delta)

## Casts Ornate Electro Shield [R]
## The Electro Ball leaps into the air with a cinematic arc & trail animation, transforming into the giant shield!
func _cast_electro_shield() -> void:
	if not electro_shield_scene or _shield_timer > 0.0:
		return
	
	_shield_timer = shield_cooldown
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)
	
	if _active_shield and is_instance_valid(_active_shield):
		if _active_shield.has_method("fade_out"):
			_active_shield.call("fade_out")
		else:
			_active_shield.queue_free()
		_active_shield = null
	
	# 1. Raise left arm upward in a dynamic casting impulse
	if left_arm:
		var arm_tween := create_tween()
		arm_tween.tween_property(left_arm, "rotation:x", -1.25, 0.10)
		arm_tween.tween_property(left_arm, "rotation:x", _orig_left_arm_rot.x, 0.28)
	
	# Compute aim direction and destination in front of hero
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir.length_squared() < 0.01:
		aim_dir = -visuals.global_transform.basis.z
		aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	var target_pos: Vector3 = global_position + Vector3(0, 0.95, 0) + aim_dir * 1.75
	
	# 2. Animate the ball traveling through the air with electric trails and spinning gyros!
	if electro_ball and is_instance_valid(electro_ball):
		var start_pos: Vector3 = electro_ball.global_position
		electro_ball.visible = false
		_animate_ball_flight_to_shield(start_pos, target_pos, aim_dir)
	else:
		_spawn_transformed_shield(target_pos, aim_dir)

func _animate_ball_flight_to_shield(start_pos: Vector3, target_pos: Vector3, aim_dir: Vector3) -> void:
	# Create a dedicated traveling projectile in world space
	var traveling_ball := Node3D.new()
	traveling_ball.name = "TravelingElectroBall"
	get_tree().current_scene.add_child(traveling_ball)
	traveling_ball.global_position = start_pos
	
	# 1. Luminous Core Sphere
	var core_mesh := MeshInstance3D.new()
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = Color(0.75, 0.95, 1.0, 1.0)
	var sphere := SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.48
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.material = core_mat
	core_mesh.mesh = sphere
	traveling_ball.add_child(core_mesh)
	
	# 2. Glowing Gyro Orbiting Ring
	var ring_mesh := MeshInstance3D.new()
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(0.3, 0.82, 1.0, 1.0)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.35
	torus.rings = 24
	torus.ring_segments = 12
	torus.material = ring_mat
	ring_mesh.mesh = torus
	traveling_ball.add_child(ring_mesh)
	
	# 3. Dynamic OmniLight
	var flight_light := OmniLight3D.new()
	flight_light.light_color = Color(0.35, 0.85, 1.0)
	flight_light.light_energy = 4.5
	flight_light.omni_range = 5.0
	traveling_ball.add_child(flight_light)
	
	# Dynamic camera screenshake on launch
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.12)
	
	# Parabolic Ballistic Tween
	var flight_duration: float = 0.30
	var tween := create_tween()
	tween.tween_method(func(progress: float):
		if not is_instance_valid(traveling_ball):
			return
		# Parabolic trajectory in world space: leaps up 0.85m then descends to target
		var current_pos: Vector3 = start_pos.lerp(target_pos, progress)
		current_pos.y += sin(progress * PI) * 0.85
		traveling_ball.global_position = current_pos
		
		# Energetic multi-axis gyro spin during flight
		ring_mesh.rotation.x = progress * 22.0
		ring_mesh.rotation.y = progress * 35.0
		ring_mesh.rotation.z = progress * 16.0
		
		# Kinetic pulse expansion at arc apex
		var scale_mult: float = 1.0 + sin(progress * PI) * 0.45
		traveling_ball.scale = Vector3.ONE * scale_mult
	, 0.0, 1.0, flight_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		if is_instance_valid(traveling_ball):
			_spawn_transformation_shockwave(target_pos)
			traveling_ball.queue_free()
		_spawn_transformed_shield(target_pos, aim_dir)
	)

func _spawn_transformation_shockwave(pos: Vector3) -> void:
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.24)
	
	var shockwave := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.38
	torus.rings = 32
	torus.ring_segments = 12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.95, 1.0, 0.9)
	torus.material = mat
	shockwave.mesh = torus
	shockwave.rotation.x = PI * 0.5
	shockwave.global_position = pos
	get_tree().current_scene.add_child(shockwave)
	
	var sw_tween := create_tween()
	sw_tween.set_parallel(true)
	sw_tween.tween_property(shockwave, "scale", Vector3(3.2, 3.2, 3.2), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sw_tween.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	sw_tween.chain().tween_callback(shockwave.queue_free)

func _spawn_transformed_shield(target_pos: Vector3, aim_dir: Vector3) -> void:
	var shield: Node3D = electro_shield_scene.instantiate() as Node3D
	if not shield:
		return
	
	shield.set("caster", self)
	get_tree().current_scene.add_child(shield)
	shield.global_position = target_pos
	
	# QuadMesh front face is +Z: align +Z with aim_dir
	shield.rotation.y = atan2(aim_dir.x, aim_dir.z)
	
	# Elastic pop-in expansion animation
	shield.scale = Vector3(0.05, 0.05, 0.05)
	var st := create_tween()
	st.tween_property(shield, "scale", Vector3(1.12, 1.12, 1.12), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(shield, "scale", Vector3.ONE, 0.08)
	
	_active_shield = shield
	shield.tree_exited.connect(_on_shield_ended)

func _on_shield_ended() -> void:
	var shield_last_pos := global_position + Vector3(0, 0.95, 0)
	if _active_shield and is_instance_valid(_active_shield):
		shield_last_pos = _active_shield.global_position
	_active_shield = null
	
	# When shield ends, an electric orb zips from the shield back into the hero's hand!
	if electro_ball and is_instance_valid(electro_ball):
		_animate_ball_return_to_hand(shield_last_pos)
	else:
		if electro_ball:
			electro_ball.visible = true

func _animate_ball_return_to_hand(from_pos: Vector3) -> void:
	var return_orb := Node3D.new()
	get_tree().current_scene.add_child(return_orb)
	return_orb.global_position = from_pos
	
	var orb_mesh := MeshInstance3D.new()
	var orb_mat := StandardMaterial3D.new()
	orb_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	orb_mat.albedo_color = Color(0.7, 0.92, 1.0, 0.9)
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	sphere.material = orb_mat
	orb_mesh.mesh = sphere
	return_orb.add_child(orb_mesh)
	
	var return_light := OmniLight3D.new()
	return_light.light_color = Color(0.3, 0.8, 1.0)
	return_light.light_energy = 3.5
	return_light.omni_range = 3.0
	return_orb.add_child(return_light)
	
	var duration: float = 0.22
	var rt := create_tween()
	rt.tween_method(func(p: float):
		if not is_instance_valid(return_orb) or not is_instance_valid(electro_ball):
			return
		var dest: Vector3 = electro_ball.global_position
		var p_pos := from_pos.lerp(dest, p)
		p_pos.y += sin(p * PI) * 0.4
		return_orb.global_position = p_pos
		return_orb.scale = Vector3.ONE * (1.0 - p * 0.3)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	rt.tween_callback(func():
		if is_instance_valid(return_orb):
			return_orb.queue_free()
		if electro_ball:
			electro_ball.visible = true
			electro_ball.scale = Vector3(0.3, 0.3, 0.3)
			var bt := create_tween()
			bt.tween_property(electro_ball, "scale", Vector3(1.25, 1.25, 1.25), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			bt.tween_property(electro_ball, "scale", Vector3.ONE, 0.08)
	)

## Performs Lightning Dash [Q]
func _perform_dash() -> void:
	if _dash_cd_timer > 0.0 or _is_dashing:
		return
	
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	
	if input_dir.length_squared() > 0.05:
		_dash_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		_dash_direction = -visuals.global_transform.basis.z
		_dash_direction.y = 0.0
		if _dash_direction.length_squared() < 0.01:
			_dash_direction = Vector3.FORWARD
		_dash_direction = _dash_direction.normalized()
	
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	_ghost_spawn_timer = 0.0
	_invulnerable_buffer = dash_duration + 0.05
	
	if health_component:
		health_component.invulnerable = true
		_update_nameplate(health_component.current_health, health_component.max_health)
	
	visuals.look_at(global_position + _dash_direction, Vector3.UP)
	
	# Spawn start burst
	if dash_burst_scene:
		var burst: Node3D = dash_burst_scene.instantiate() as Node3D
		if burst:
			get_tree().current_scene.add_child(burst)
			burst.global_position = global_position
	
	_spawn_dash_ghost()
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.trigger_fov_kick(5.0)
		cam.add_shake(0.1)

func _end_dash() -> void:
	_is_dashing = false
	visuals.rotation.x = 0.0
	
	var effective_speed: float = move_speed * _speed_modifier
	velocity.x = _dash_direction.x * effective_speed
	velocity.z = _dash_direction.z * effective_speed

func _spawn_dash_ghost() -> void:
	if not dash_ghost_scene:
		return
	var ghost: Node3D = dash_ghost_scene.instantiate() as Node3D
	if ghost:
		get_tree().current_scene.add_child(ghost)
		ghost.global_transform = visuals.global_transform
		ghost.global_position = visuals.global_position

func apply_knockback(impulse: Vector3, stagger_duration: float = 0.2) -> void:
	_knockback_velocity = impulse
	_stagger_timer = stagger_duration

func apply_slow(multiplier: float, duration: float) -> void:
	_speed_modifier = clampf(1.0 - multiplier, 0.2, 0.85)
	_slow_timer = duration
	_is_slowed = true
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_player_died(_killer: Node) -> void:
	collision_layer = 0
	collision_mask = 0
