class_name CelestialController
extends CharacterBody3D

## Ascended - Legendary Seraph Archangel Hero
## Features animated 4-wing flight fluttering, floating glowing halo, divine spellcasting, and health tracking

@export_group("Movement")
@export var move_speed: float = 8.8
@export var acceleration: float = 52.0
@export var deceleration: float = 65.0
@export var rotation_speed: float = 900.0

@export_group("Spells")
@export var fireball_scene: PackedScene = preload("res://scenes/spells/fireball.tscn")
@export var ice_lance_scene: PackedScene = preload("res://scenes/spells/ice_lance.tscn")
@export var celestial_beam_scene: PackedScene = preload("res://characters/celestial/skills/celestial_beam.tscn")
@export var celestial_shield_scene: PackedScene = preload("res://characters/celestial/skills/celestial_shield.tscn")
@export var dash_ghost_scene: PackedScene = preload("res://characters/celestial/vfx/dash_ghost.tscn")
@export var dash_burst_scene: PackedScene = preload("res://characters/celestial/vfx/dash_burst_vfx.tscn")
@export var dash_arrival_scene: PackedScene = preload("res://characters/celestial/vfx/dash_arrival_vfx.tscn")
@export var spell_cooldown: float = 0.38
@export var beam_cooldown: float = 3.0
@export var shield_cooldown: float = 8.0
@export var dash_cooldown: float = 3.5
@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.22

# Core Gameplay Attack Release Pipeline Standards
const INPUT_BUFFER_WINDOW: float = 0.08
const CAST_START_DELAY: float = 0.12
const ATTACK_RELEASE_TIME: float = 0.20
const ATTACK_RECOVERY_TIME: float = 0.18
const TOTAL_ATTACK_ANIM_TIME: float = 0.38

var _current_release_time: float = 0.20
var _current_total_time: float = 0.38

var _is_casting_attack: bool = false
var _attack_timer: float = 0.0
var _attack_released: bool = false
var _buffered_attack: bool = false
var _pending_spell_scene: PackedScene = null
var _buffered_spell_scene: PackedScene = null

# Core Gameplay Beam Standards
const BEAM_CHARGE_TIME: float = 0.18
const BEAM_APPEAR_TIME: float = 0.20
const BEAM_ACTIVE_DURATION: float = 0.35
const BEAM_FADE_DURATION: float = 0.10

var _is_charging_beam: bool = false
var _beam_pipeline_timer: float = 0.0
var _beam_has_appeared: bool = false

var display_name: String = "👑 Ascended"
var can_cast: bool = true
var _beam_timer: float = 0.0
var _shield_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _active_shield: Node3D = null

var _is_dashing: bool = false
var _is_dash_recovering: bool = false
var _dash_timer: float = 0.0
var _dash_recovery_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _ghost_spawn_timer: float = 0.0
var _ghost_counter: int = 0
var _invulnerable_buffer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _stagger_timer: float = 0.0

var _speed_modifier: float = 1.0
var _slow_timer: float = 0.0
var _is_slowed: bool = false
var _is_beam_active: bool = false
var _beam_charge_phase: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D

# Visual sub-nodes for Seraph animations
@onready var upper_left_wing: Node3D = $Visuals.find_child("UpperLeftWing", true, false) as Node3D
@onready var upper_right_wing: Node3D = $Visuals.find_child("UpperRightWing", true, false) as Node3D
@onready var lower_left_wing: Node3D = $Visuals.find_child("LowerLeftWing", true, false) as Node3D
@onready var lower_right_wing: Node3D = $Visuals.find_child("LowerRightWing", true, false) as Node3D
@onready var halo: Node3D = $Visuals.find_child("Halo", true, false) as Node3D
@onready var scepter: Node3D = $Visuals.find_child("Scepter", true, false) as Node3D
@onready var head_node: Node3D = $Visuals.find_child("Head", true, false) as Node3D
@onready var left_arm: Node3D = $Visuals.find_child("LeftArm", true, false) as Node3D
@onready var right_arm: Node3D = $Visuals.find_child("RightArm", true, false) as Node3D
@onready var left_leg: Node3D = $Visuals.find_child("LeftLeg", true, false) as Node3D
@onready var right_leg: Node3D = $Visuals.find_child("RightLeg", true, false) as Node3D
@onready var coattail_left: Node3D = $Visuals.find_child("CoattailLeft", true, false) as Node3D
@onready var coattail_right: Node3D = $Visuals.find_child("CoattailRight", true, false) as Node3D
@onready var coattail_back: Node3D = $Visuals.find_child("CoattailBack", true, false) as Node3D
@onready var dash_streamers: GPUParticles3D = $Visuals.find_child("DashStreamers", true, false) as GPUParticles3D

var _orig_left_arm_trans: Transform3D
var _orig_right_arm_trans: Transform3D
var _orig_left_leg_trans: Transform3D
var _orig_right_leg_trans: Transform3D
var _orig_scepter_pos: Vector3 = Vector3.ZERO
var _orig_visuals_pos_y: float = 0.0
var _orig_coattail_l_rot: Vector3 = Vector3.ZERO
var _orig_coattail_r_rot: Vector3 = Vector3.ZERO
var _orig_coattail_b_rot: Vector3 = Vector3.ZERO
var _orig_halo_rot_x: float = 0.0

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if left_arm: _orig_left_arm_trans = left_arm.transform
	if right_arm: _orig_right_arm_trans = right_arm.transform
	if left_leg: _orig_left_leg_trans = left_leg.transform
	if right_leg: _orig_right_leg_trans = right_leg.transform
	if scepter: _orig_scepter_pos = scepter.position
	if visuals: _orig_visuals_pos_y = visuals.position.y
	if coattail_left: _orig_coattail_l_rot = coattail_left.rotation
	if coattail_right: _orig_coattail_r_rot = coattail_right.rotation
	if coattail_back: _orig_coattail_b_rot = coattail_back.rotation
	if halo: _orig_halo_rot_x = halo.rotation.x
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_player_died)
		_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if not nameplate:
		return
	var status_tag: String = " ❄️" if _is_slowed else ""
	var beam_tag: String = " | ☀️ [E]" if _beam_timer <= 0.0 else " | ⏳ %.1fs" % _beam_timer
	var shield_tag: String = " | 🛡️ [R]" if _shield_timer <= 0.0 else ""
	var dash_tag: String = " | ⚡ [Q]" if _dash_cd_timer <= 0.0 else ""
	nameplate.text = "✨ [ %d / %d ]%s%s%s%s\n%s (Lvl 24)" % [int(curr), int(max_hp), status_tag, beam_tag, shield_tag, dash_tag, display_name]
	nameplate.modulate = Color(0.4, 0.9, 1.0) if _is_slowed else (Color(1.0, 0.88, 0.35) if curr > 40 else Color(0.95, 0.3, 0.3))

func _unhandled_input(event: InputEvent) -> void:
	if not health_component or not health_component.is_alive():
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_request_spell(fireball_scene)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_request_spell(ice_lance_scene)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and _beam_timer <= 0.0:
			_request_celestial_beam()
	elif event is InputEventKey and event.pressed and not event.echo:
		var keycode: int = (event as InputEventKey).keycode
		if keycode == KEY_SPACE:
			_request_spell(fireball_scene)
		elif keycode == KEY_SHIFT:
			_request_spell(ice_lance_scene)
		elif (keycode == KEY_E or keycode == KEY_F) and _beam_timer <= 0.0:
			_request_celestial_beam()
		elif (keycode == KEY_R or keycode == KEY_C) and _shield_timer <= 0.0:
			_cast_celestial_shield()
		elif keycode == KEY_Q and _dash_cd_timer <= 0.0:
			_perform_dash()

## UI Power Button Triggers
func trigger_primary_attack() -> void:
	if not health_component or not health_component.is_alive(): return
	_request_spell(fireball_scene)

func trigger_secondary_attack() -> void:
	if not health_component or not health_component.is_alive(): return
	_request_spell(ice_lance_scene)

func trigger_beam_attack() -> void:
	if not health_component or not health_component.is_alive(): return
	if _beam_timer <= 0.0:
		_request_celestial_beam()

func trigger_shield_defense() -> void:
	if not health_component or not health_component.is_alive(): return
	if _shield_timer <= 0.0:
		_cast_celestial_shield()

func trigger_dash() -> void:
	if not health_component or not health_component.is_alive(): return
	if _dash_cd_timer <= 0.0:
		_perform_dash()

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

## Requests spell with 0.08s input buffering
func _request_spell(spell_scene: PackedScene) -> void:
	if not _is_casting_attack:
		_start_spell_pipeline(spell_scene)
	else:
		var time_remaining: float = TOTAL_ATTACK_ANIM_TIME - _attack_timer
		if time_remaining <= INPUT_BUFFER_WINDOW:
			_buffered_attack = true
			_buffered_spell_scene = spell_scene

func _start_spell_pipeline(spell_scene: PackedScene) -> void:
	if not can_cast:
		return
	can_cast = false
	_is_casting_attack = true
	_attack_timer = 0.0
	_attack_released = false
	_buffered_attack = false
	_pending_spell_scene = spell_scene
	
	if spell_scene == fireball_scene:
		_current_release_time = 0.28
		_current_total_time = 0.42
	else:
		_current_release_time = ATTACK_RELEASE_TIME
		_current_total_time = TOTAL_ATTACK_ANIM_TIME

## Requests beam adhering to Beam Standards
func _request_celestial_beam() -> void:
	if not celestial_beam_scene or _beam_timer > 0.0 or _is_charging_beam:
		return
	
	_beam_timer = beam_cooldown
	_is_charging_beam = true
	_beam_pipeline_timer = 0.0
	_beam_has_appeared = false
	_is_beam_active = true
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Process beam cooldown timer
	if _beam_timer > 0.0:
		_beam_timer -= delta
		if _beam_timer <= 0.0:
			_beam_timer = 0.0
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)
	
	# Process shield cooldown timer
	if _shield_timer > 0.0:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_timer = 0.0
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)
	
	# Process dash cooldown timer
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
		if _dash_cd_timer <= 0.0:
			_dash_cd_timer = 0.0
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)

	# Process lingering dash invulnerability buffer
	if _invulnerable_buffer > 0.0:
		_invulnerable_buffer -= delta
		if _invulnerable_buffer <= 0.0 and not _is_dashing:
			if health_component:
				health_component.invulnerable = false

	# Knockback impulse handling
	if _knockback_velocity.length_squared() > 0.01:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 38.0 * delta)

	# Stagger handling
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
	
	# Process slow status timer
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_modifier = 1.0
			_is_slowed = false
			_apply_frost_visual(false)
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)

	# Attack Release Standards Pipeline
	if _is_casting_attack:
		_attack_timer += delta
		
		# Phase 1: Cast Start Delay - Scepter pre-cast tilt
		if _attack_timer < CAST_START_DELAY:
			if scepter:
				scepter.rotation.x = lerp_angle(scepter.rotation.x, -0.22, 20.0 * delta)
		# Phase 2: Attack Release Time
		elif _attack_timer >= _current_release_time and not _attack_released:
			_attack_released = true
			_spawn_spell(_pending_spell_scene)
		# Phase 3: Recovery Time
		elif _attack_timer >= _current_release_time:
			if scepter:
				scepter.rotation.x = lerp_angle(scepter.rotation.x, 0.0, 14.0 * delta)
		
		# Animation complete
		if _attack_timer >= _current_total_time:
			_is_casting_attack = false
			can_cast = true
			if _buffered_attack and _buffered_spell_scene:
				var next_spell := _buffered_spell_scene
				_buffered_attack = false
				_buffered_spell_scene = null
				_start_spell_pipeline(next_spell)

	# Beam Standards Pipeline:
	# Charge: 0.18s | Appears: 0.20s | Active Duration: 0.35s | Disappears: 0.10s smooth fade
	if _is_charging_beam:
		_beam_pipeline_timer += delta
		if _beam_pipeline_timer < BEAM_CHARGE_TIME:
			if scepter:
				scepter.rotation.x = lerp_angle(scepter.rotation.x, -0.65, 20.0 * delta)
		elif _beam_pipeline_timer >= BEAM_APPEAR_TIME and not _beam_has_appeared:
			_beam_has_appeared = true
			_spawn_celestial_beam()
		elif _beam_pipeline_timer >= (BEAM_APPEAR_TIME + BEAM_ACTIVE_DURATION):
			# Scepter recovers
			if scepter:
				scepter.rotation.x = lerp_angle(scepter.rotation.x, 0.0, 16.0 * delta)
		
		var total_beam_time: float = BEAM_APPEAR_TIME + BEAM_ACTIVE_DURATION + BEAM_FADE_DURATION
		if _beam_pipeline_timer >= total_beam_time:
			_is_charging_beam = false
			_is_beam_active = false

	# Active Silky Smooth Dash Processing (Dash Standard: Speed 16.0 units/s, Duration 0.22s)
	if _is_dashing:
		_dash_timer -= delta
		
		# Spawn ethereal chromatic Seraph ghost afterimage every 0.038s
		_ghost_spawn_timer -= delta
		if _ghost_spawn_timer <= 0.0:
			_ghost_spawn_timer = 0.038
			_spawn_dash_ghost()
		
		var progress: float = clampf(1.0 - (_dash_timer / dash_duration), 0.0, 1.0)
		var speed_mult: float = lerp(1.18, 0.92, progress)
		var current_dash_speed: float = dash_speed * speed_mult
		velocity.x = _dash_direction.x * current_dash_speed
		velocity.z = _dash_direction.z * current_dash_speed
		
		# Dynamic Kinetic Squash & Stretch
		if progress < 0.16:
			visuals.scale = visuals.scale.lerp(Vector3(1.12, 0.9, 0.86), 24.0 * delta)
		else:
			visuals.scale = visuals.scale.lerp(Vector3(0.9, 0.92, 1.25), 20.0 * delta)
		
		visuals.rotation.x = lerp_angle(visuals.rotation.x, -0.38, 22.0 * delta)
		
		# Slipstream wake: knock back nearby hostile units and deflect enemy projectiles
		_process_dash_slipstream()
		
		move_and_slide()
		_animate_seraph(delta, true)
		
		if _dash_timer <= 0.0:
			_end_dash()
		return

	# Handle dash recovery spring settle
	if _is_dash_recovering:
		_dash_recovery_timer -= delta
		visuals.scale = visuals.scale.lerp(Vector3.ONE, 16.0 * delta)
		visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, 14.0 * delta)
		if _dash_recovery_timer <= 0.0:
			_is_dash_recovering = false
			visuals.scale = Vector3.ONE
			visuals.rotation.x = 0.0

	# Gather Movement Input (Arrow keys, WASD, InputMap actions, Virtual Joystick)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() < 0.01:
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): input_dir.y += 1.0
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	
	# Mobile Virtual Joystick integration if available in scene
	var hud_node: HUD = get_tree().current_scene.find_child("HUD", true, false) as HUD if get_tree() and get_tree().current_scene else null
	if hud_node:
		var joy_output: Variant = hud_node.get("joystick_output")
		if joy_output != null and (joy_output is Vector2) and (joy_output as Vector2).length_squared() > 0.01:
			input_dir += (joy_output as Vector2)
	
	# Diagonal normalization: diagonal movement is NEVER faster than straight movement
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	var is_moving: bool = input_dir.length_squared() > 0.01
	var effective_speed: float = move_speed * _speed_modifier

	# Transform input direction relative to the camera horizontal yaw
	var move_world_dir := Vector3.ZERO
	if is_moving:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var cam_forward: Vector3 = -cam.global_transform.basis.z
			cam_forward.y = 0.0
			cam_forward = cam_forward.normalized()
			var cam_right: Vector3 = cam.global_transform.basis.x
			cam_right.y = 0.0
			cam_right = cam_right.normalized()
			move_world_dir = (cam_right * input_dir.x + cam_forward * (-input_dir.y)).normalized()
		else:
			move_world_dir = Vector3(input_dir.x, 0.0, input_dir.y).normalized()

		var target_vel: Vector3 = move_world_dir * effective_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	# Core Rotation: strictly driven by WASD / arrow movement keys (NOT mouse or cursor)
	if is_moving:
		var target_rot_y := atan2(-move_world_dir.x, -move_world_dir.z)
		var angle_diff: float = wrapf(target_rot_y - visuals.rotation.y, -PI, PI)
		var max_rot: float = deg_to_rad(rotation_speed) * delta
		if absf(angle_diff) <= max_rot:
			visuals.rotation.y = target_rot_y
		else:
			visuals.rotation.y += signf(angle_diff) * max_rot
		visuals.rotation.y = wrapf(visuals.rotation.y, -PI, PI)

	if is_moving:
		var wobble_rate: float = 0.015 * _speed_modifier
		visuals.rotation.z = sin(Time.get_ticks_msec() * wobble_rate) * 0.1
	else:
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 8.0 * delta)

	# Physically move CharacterBody3D actual 3D world position
	move_and_slide()
	
	# Arena Horizontal Boundary Clamp (keeps player inside playable arena circle)
	var horiz_pos := Vector2(global_position.x, global_position.z)
	const ARENA_RADIUS: float = 48.0
	if horiz_pos.length() > ARENA_RADIUS:
		var clamped := horiz_pos.normalized() * ARENA_RADIUS
		global_position.x = clamped.x
		global_position.z = clamped.y
		velocity.x = 0.0
		velocity.z = 0.0
	
	# Seraph Archangel Wing & Halo Animations
	_animate_seraph(delta, is_moving)

## Animates Seraph wings flapping, rotating halo, and scepter hover
func _animate_seraph(delta: float, is_moving: bool) -> void:
	var time_ms := Time.get_ticks_msec()
	
	var is_shield_active: bool = _active_shield != null and is_instance_valid(_active_shield)
	
	if is_shield_active:
		# Seraph Archangel Meditating Posture (Lotus cross-legged, praying mudra hands, floating levitation, orbiting scepter)
		if visuals:
			var target_levitation: float = _orig_visuals_pos_y + 0.36 + sin(time_ms * 0.003) * 0.05
			visuals.position.y = lerp(visuals.position.y, target_levitation, 6.0 * delta)
		
		# Folded Lotus Legs
		if left_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 1.25, 7.0 * delta)
			left_leg.rotation.z = lerp_angle(left_leg.rotation.z, 0.65, 7.0 * delta)
			left_leg.rotation.y = lerp_angle(left_leg.rotation.y, 0.45, 7.0 * delta)
			left_leg.position.y = lerp(left_leg.position.y, 0.12, 7.0 * delta)
		if right_leg:
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 1.25, 7.0 * delta)
			right_leg.rotation.z = lerp_angle(right_leg.rotation.z, -0.65, 7.0 * delta)
			right_leg.rotation.y = lerp_angle(right_leg.rotation.y, -0.45, 7.0 * delta)
			right_leg.position.y = lerp(right_leg.position.y, 0.12, 7.0 * delta)
		
		# Meditating Prayer / Mudra hands joined in front of chest
		if left_arm:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -0.75, 7.0 * delta)
			left_arm.rotation.y = lerp_angle(left_arm.rotation.y, 0.55, 7.0 * delta)
			left_arm.rotation.z = lerp_angle(left_arm.rotation.z, -0.55, 7.0 * delta)
			left_arm.position = lerp(left_arm.position, Vector3(-0.16, -0.05, -0.22), 7.0 * delta)
		if right_arm:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, -0.75, 7.0 * delta)
			right_arm.rotation.y = lerp_angle(right_arm.rotation.y, -0.55, 7.0 * delta)
			right_arm.rotation.z = lerp_angle(right_arm.rotation.z, 0.55, 7.0 * delta)
			right_arm.position = lerp(right_arm.position, Vector3(0.16, -0.05, -0.22), 7.0 * delta)
		
		# Floating Scepter revolving autonomously in front
		if scepter:
			scepter.position = lerp(scepter.position, Vector3(0.0, 0.85 + sin(time_ms * 0.004) * 0.04, -0.55), 5.0 * delta)
			scepter.rotation.y += 1.8 * delta
			scepter.rotation.x = lerp_angle(scepter.rotation.x, -0.2, 5.0 * delta)
		
		# Seraph Wings in serene protective embrace
		if upper_left_wing:
			upper_left_wing.rotation.y = lerp_angle(upper_left_wing.rotation.y, -0.68 + sin(time_ms * 0.003) * 0.05, 5.0 * delta)
			upper_left_wing.rotation.z = lerp_angle(upper_left_wing.rotation.z, 0.52, 5.0 * delta)
		if upper_right_wing:
			upper_right_wing.rotation.y = lerp_angle(upper_right_wing.rotation.y, 0.68 - sin(time_ms * 0.003) * 0.05, 5.0 * delta)
			upper_right_wing.rotation.z = lerp_angle(upper_right_wing.rotation.z, -0.52, 5.0 * delta)
		if lower_left_wing:
			lower_left_wing.rotation.y = lerp_angle(lower_left_wing.rotation.y, -0.4, 5.0 * delta)
		if lower_right_wing:
			lower_right_wing.rotation.y = lerp_angle(lower_right_wing.rotation.y, 0.4, 5.0 * delta)
		
		# Spinning holy halo
		if halo:
			halo.rotation.y += 5.0 * delta
			halo.position.y = 0.66 + sin(time_ms * 0.005) * 0.03
		
		# Head serene meditation tilt
		if head_node:
			head_node.rotation.x = lerp_angle(head_node.rotation.x, 0.14, 5.0 * delta)
		return

	# Smoothly return from meditation pose to default stance when shield is inactive
	if visuals:
		visuals.position.y = lerp(visuals.position.y, _orig_visuals_pos_y, 7.0 * delta)
	if left_arm:
		left_arm.position = lerp(left_arm.position, _orig_left_arm_trans.origin, 7.0 * delta)
		left_arm.rotation.x = lerp_angle(left_arm.rotation.x, _orig_left_arm_trans.basis.get_euler().x, 7.0 * delta)
		left_arm.rotation.y = lerp_angle(left_arm.rotation.y, _orig_left_arm_trans.basis.get_euler().y, 7.0 * delta)
		left_arm.rotation.z = lerp_angle(left_arm.rotation.z, _orig_left_arm_trans.basis.get_euler().z, 7.0 * delta)
	if right_arm:
		right_arm.position = lerp(right_arm.position, _orig_right_arm_trans.origin, 7.0 * delta)
		right_arm.rotation.x = lerp_angle(right_arm.rotation.x, _orig_right_arm_trans.basis.get_euler().x, 7.0 * delta)
		right_arm.rotation.y = lerp_angle(right_arm.rotation.y, _orig_right_arm_trans.basis.get_euler().y, 7.0 * delta)
		right_arm.rotation.z = lerp_angle(right_arm.rotation.z, _orig_right_arm_trans.basis.get_euler().z, 7.0 * delta)
	if left_leg:
		left_leg.position = lerp(left_leg.position, _orig_left_leg_trans.origin, 7.0 * delta)
		left_leg.rotation.x = lerp_angle(left_leg.rotation.x, _orig_left_leg_trans.basis.get_euler().x, 7.0 * delta)
		left_leg.rotation.y = lerp_angle(left_leg.rotation.y, _orig_left_leg_trans.basis.get_euler().y, 7.0 * delta)
		left_leg.rotation.z = lerp_angle(left_leg.rotation.z, _orig_left_leg_trans.basis.get_euler().z, 7.0 * delta)
	if right_leg:
		right_leg.position = lerp(right_leg.position, _orig_right_leg_trans.origin, 7.0 * delta)
		right_leg.rotation.x = lerp_angle(right_leg.rotation.x, _orig_right_leg_trans.basis.get_euler().x, 7.0 * delta)
		right_leg.rotation.y = lerp_angle(right_leg.rotation.y, _orig_right_leg_trans.basis.get_euler().y, 7.0 * delta)
		right_leg.rotation.z = lerp_angle(right_leg.rotation.z, _orig_right_leg_trans.basis.get_euler().z, 7.0 * delta)
	if head_node:
		head_node.rotation.x = lerp_angle(head_node.rotation.x, 0.0, 7.0 * delta)

	if _is_dashing:
		# Supersonic Aerodynamic Dash Wing Sweep with High-Frequency Flutter
		if upper_left_wing and upper_right_wing:
			upper_left_wing.rotation.y = -1.28 + sin(time_ms * 0.065) * 0.06
			upper_right_wing.rotation.y = 1.28 - sin(time_ms * 0.065) * 0.06
			upper_left_wing.rotation.z = 0.14
			upper_right_wing.rotation.z = -0.14
		if lower_left_wing and lower_right_wing:
			lower_left_wing.rotation.y = -0.92
			lower_right_wing.rotation.y = 0.92
		if right_arm and left_arm:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 1.15, 22.0 * delta)
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 1.15, 22.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.45, 20.0 * delta)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.45, 20.0 * delta)
		if scepter:
			# Scepter held forward like an aerodynamic supersonic spearhead piercing the air
			scepter.position = lerp(scepter.position, Vector3(0.14, 0.64, -0.58), 24.0 * delta)
			scepter.rotation.x = lerp_angle(scepter.rotation.x, -1.4, 24.0 * delta)
			scepter.rotation.y = lerp_angle(scepter.rotation.y, 0.0, 24.0 * delta)
			scepter.rotation.z = lerp_angle(scepter.rotation.z, 0.0, 24.0 * delta)
		if coattail_left:
			coattail_left.rotation.x = lerp_angle(coattail_left.rotation.x, 1.2 + sin(time_ms * 0.06) * 0.18, 26.0 * delta)
		if coattail_right:
			coattail_right.rotation.x = lerp_angle(coattail_right.rotation.x, 1.2 + cos(time_ms * 0.06) * 0.18, 26.0 * delta)
		if coattail_back:
			coattail_back.rotation.x = lerp_angle(coattail_back.rotation.x, 1.38 + sin(time_ms * 0.07) * 0.22, 26.0 * delta)
		if halo:
			halo.rotation.y += 36.0 * delta
			halo.rotation.x = lerp_angle(halo.rotation.x, -0.45, 20.0 * delta)
		return

	if _is_dash_recovering:
		# Deceleration Air-Brake Wing Flare Recoil
		if upper_left_wing and upper_right_wing:
			upper_left_wing.rotation.y = lerp_angle(upper_left_wing.rotation.y, 0.75, 22.0 * delta)
			upper_right_wing.rotation.y = lerp_angle(upper_right_wing.rotation.y, -0.75, 22.0 * delta)
			upper_left_wing.rotation.z = lerp_angle(upper_left_wing.rotation.z, 0.62, 22.0 * delta)
			upper_right_wing.rotation.z = lerp_angle(upper_right_wing.rotation.z, -0.62, 22.0 * delta)
		if lower_left_wing and lower_right_wing:
			lower_left_wing.rotation.y = lerp_angle(lower_left_wing.rotation.y, 0.45, 20.0 * delta)
			lower_right_wing.rotation.y = lerp_angle(lower_right_wing.rotation.y, -0.45, 20.0 * delta)
		if scepter:
			scepter.position = lerp(scepter.position, _orig_scepter_pos, 14.0 * delta)
			scepter.rotation.x = lerp_angle(scepter.rotation.x, 0.0, 14.0 * delta)
		if coattail_left:
			coattail_left.rotation = coattail_left.rotation.lerp(_orig_coattail_l_rot, 16.0 * delta)
		if coattail_right:
			coattail_right.rotation = coattail_right.rotation.lerp(_orig_coattail_r_rot, 16.0 * delta)
		if coattail_back:
			coattail_back.rotation = coattail_back.rotation.lerp(_orig_coattail_b_rot, 16.0 * delta)
		if halo:
			halo.rotation.y += 8.0 * delta
			halo.rotation.x = lerp_angle(halo.rotation.x, _orig_halo_rot_x, 14.0 * delta)
		return

	if _is_beam_active:
		# Hyper-kinetic Archangel Celestial Casting Animation
		if upper_left_wing:
			upper_left_wing.rotation.y = -0.75 + sin(time_ms * 0.03) * 0.35
			upper_left_wing.rotation.z = 0.45
		if upper_right_wing:
			upper_right_wing.rotation.y = 0.75 - sin(time_ms * 0.03) * 0.35
			upper_right_wing.rotation.z = -0.45
		if halo:
			halo.rotation.y += 14.0 * delta
			halo.position.y = 0.65 + sin(time_ms * 0.02) * 0.06
		return

	var flap_speed: float = 0.008 if not is_moving else 0.016
	var flap_amplitude: float = 0.22 if not is_moving else 0.38
	var wing_flap: float = sin(time_ms * flap_speed) * flap_amplitude
	
	# Upper Wings Flap (Y and Z rotation)
	if upper_left_wing:
		upper_left_wing.rotation.y = -0.45 + wing_flap
		upper_left_wing.rotation.z = 0.25 - (wing_flap * 0.4)
	if upper_right_wing:
		upper_right_wing.rotation.y = 0.45 - wing_flap
		upper_right_wing.rotation.z = -0.25 + (wing_flap * 0.4)
		
	# Lower Wings Flutter (complementary phase)
	if lower_left_wing:
		lower_left_wing.rotation.y = -0.3 + (wing_flap * 0.6)
	if lower_right_wing:
		lower_right_wing.rotation.y = 0.3 - (wing_flap * 0.6)
	
	# Halo gentle rotation and vertical floating
	if halo:
		halo.rotation.y += 1.8 * delta
		halo.position.y = 0.54 + sin(time_ms * 0.004) * 0.03
	
	# Scepter mystical idle bob
	if scepter:
		scepter.position.y = 0.58 + sin(time_ms * 0.005) * 0.02

## Public API forwarding to Attack Release Pipeline
func _cast_spell(spell_packed: PackedScene) -> void:
	_request_spell(spell_packed)

## Spawns projectile at Attack Release Time
func _spawn_spell(spell_packed: PackedScene) -> void:
	if not spell_packed:
		return
	
	var aim_dir := -visuals.global_transform.basis.z
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector3.FORWARD
	aim_dir = aim_dir.normalized()
	
	var proj: Node3D = spell_packed.instantiate() as Node3D
	if proj:
		proj.set("caster", self)
		if spell_packed == fireball_scene:
			proj.set("speed", 38.0)
		get_tree().current_scene.add_child(proj)
		
		var cast_pt: Node3D = visuals.find_child("CastPoint", true, false) as Node3D
		if cast_pt:
			proj.global_position = cast_pt.global_position
		else:
			proj.global_position = global_position + aim_dir * 0.85 + Vector3(0, 0.6, 0)
			
		proj.look_at(proj.global_position + aim_dir, Vector3.UP)
	
	if scepter:
		var tween := create_tween()
		tween.tween_property(scepter, "rotation:x", -0.45, 0.06)
		tween.tween_property(scepter, "rotation:x", 0.0, 0.12)

## Public API forwarding to Beam Standards Pipeline
func _cast_celestial_beam() -> void:
	_request_celestial_beam()

## Spawns Heaven's Ascendant Solar Beam at Beam Appear Time
func _spawn_celestial_beam() -> void:
	if not celestial_beam_scene:
		return
	
	var aim_dir := -visuals.global_transform.basis.z
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector3.FORWARD
	aim_dir = aim_dir.normalized()
	
	var proj: Node3D = celestial_beam_scene.instantiate() as Node3D
	if proj:
		proj.set("caster", self)
		get_tree().current_scene.add_child(proj)
		
		var cast_pt: Node3D = visuals.find_child("CastPoint", true, false) as Node3D
		if cast_pt:
			proj.global_position = cast_pt.global_position
		else:
			proj.global_position = global_position + aim_dir * 1.0 + Vector3(0, 0.7, 0)
			
		proj.look_at(proj.global_position + aim_dir, Vector3.UP)
	
	# Camera recoil shake on firing massive solar orb
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.22)
	
	if scepter:
		var charge_tween: Tween = create_tween()
		charge_tween.tween_property(scepter, "rotation:x", 0.35, 0.08)
		charge_tween.tween_property(scepter, "rotation:x", 0.0, 0.12)
		charge_tween.tween_callback(func(): _is_beam_active = false)
	else:
		_is_beam_active = false

## Casts the 4-Sided Celestial Shield with Heaven Signs
func _cast_celestial_shield() -> void:
	if not celestial_shield_scene or _shield_timer > 0.0:
		return
	
	_shield_timer = shield_cooldown
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)
	
	# If an old shield exists, dismiss it
	if _active_shield and is_instance_valid(_active_shield):
		if _active_shield.has_method("fade_out"):
			_active_shield.call("fade_out")
		else:
			_active_shield.queue_free()
	
	var shield: Node3D = celestial_shield_scene.instantiate() as Node3D
	if shield:
		shield.set("caster", self)
		get_tree().current_scene.add_child(shield)
		shield.global_position = global_position
		_active_shield = shield
		shield.tree_exited.connect(func():
			if _active_shield == shield:
				_active_shield = null
		)
	
	# Archangel seraph wing flare and halo spin on shield summon
	if halo:
		halo.rotation.y += 24.0
	if upper_left_wing and upper_right_wing:
		var wing_tween := create_tween()
		wing_tween.tween_property(upper_left_wing, "rotation:z", 0.65, 0.1)
		wing_tween.parallel().tween_property(upper_right_wing, "rotation:z", -0.65, 0.1)
		wing_tween.tween_property(upper_left_wing, "rotation:z", 0.25, 0.2)
		wing_tween.parallel().tween_property(upper_right_wing, "rotation:z", -0.25, 0.2)
	if scepter:
		var scepter_tween := create_tween()
		scepter_tween.tween_property(scepter, "position:y", 0.85, 0.1)
		scepter_tween.tween_property(scepter, "position:y", 0.58, 0.2)

## Performs the silky smooth Celestial Dash (Q Ability)
func _perform_dash() -> void:
	if _dash_cd_timer > 0.0 or _is_dashing:
		return
	
	# Determine dash direction: player input or current visual facing
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	
	if input_dir.length_squared() > 0.05:
		_dash_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		_dash_direction = -visuals.global_transform.basis.z
		_dash_direction.y = 0.0
		if _dash_direction.length_squared() < 0.01:
			_dash_direction = Vector3.FORWARD
		_dash_direction = _dash_direction.normalized()
	
	_is_dashing = true
	_is_dash_recovering = false
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	_ghost_spawn_timer = 0.0
	_ghost_counter = 0
	_invulnerable_buffer = dash_duration + 0.06 # Lingering grace period
	
	# Invulnerability frames during the dash
	if health_component:
		health_component.invulnerable = true
		_update_nameplate(health_component.current_health, health_component.max_health)
	
	# Turn visuals towards dash direction instantly
	visuals.look_at(global_position + _dash_direction, Vector3.UP)
	
	# Initial kinetic launch compression squash
	visuals.scale = Vector3(1.2, 0.85, 0.72)
	
	# Activate supersonic wind streamers
	if dash_streamers:
		dash_streamers.restart()
		dash_streamers.emitting = true
	
	# Spawn start burst shockwave VFX & audio
	if dash_burst_scene:
		var burst: Node3D = dash_burst_scene.instantiate() as Node3D
		if burst:
			get_tree().current_scene.add_child(burst)
			burst.global_position = global_position
			burst.look_at(global_position + _dash_direction, Vector3.UP)
	
	# First afterimage ghost
	_spawn_dash_ghost()
	
	# Camera FOV warp kick + screen punch
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.trigger_fov_kick(6.2)
		cam.add_shake(0.14)

func _end_dash() -> void:
	_is_dashing = false
	_is_dash_recovering = true
	_dash_recovery_timer = 0.16
	
	if dash_streamers:
		dash_streamers.emitting = false
	
	# Air-brake landing impact squash & backwards brake pitch
	visuals.scale = Vector3(1.22, 0.8, 1.14)
	visuals.rotation.x = 0.18
	
	# Spawn deceleration arrival impact VFX
	if dash_arrival_scene:
		var arrival: Node3D = dash_arrival_scene.instantiate() as Node3D
		if arrival:
			get_tree().current_scene.add_child(arrival)
			arrival.global_position = global_position
	
	# Camera subtle arrival settle shake
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.06)
	
	# Seamlessly preserve momentum into running speed if holding movement keys
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	
	var effective_speed: float = move_speed * _speed_modifier
	if input_dir.length_squared() > 0.05:
		var move_dir := Vector3(input_dir.x, 0, input_dir.y).normalized()
		velocity.x = move_dir.x * effective_speed
		velocity.z = move_dir.z * effective_speed
	else:
		velocity.x = _dash_direction.x * (effective_speed * 0.45)
		velocity.z = _dash_direction.z * (effective_speed * 0.45)

func _spawn_dash_ghost() -> void:
	if not dash_ghost_scene:
		return
	var ghost: Node3D = dash_ghost_scene.instantiate() as Node3D
	if ghost:
		# Multi-tier chromatic cycling: cyan -> solar gold -> pure celestial white -> electric teal
		var tints: Array[Color] = [
			Color(0.25, 0.85, 1.0, 0.85),
			Color(1.0, 0.86, 0.35, 0.85),
			Color(0.95, 0.98, 1.0, 0.9),
			Color(0.3, 1.0, 0.9, 0.85)
		]
		var chosen_tint: Color = tints[_ghost_counter % tints.size()]
		_ghost_counter += 1
		
		if ghost.has_method("setup_color"):
			ghost.call("setup_color", chosen_tint)
		
		get_tree().current_scene.add_child(ghost)
		ghost.global_transform = visuals.global_transform
		ghost.global_position = visuals.global_position

## Applies slipstream wake forces to nearby enemies and deflects hostile projectiles
func _process_dash_slipstream() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	for entity in combatants:
		if not is_instance_valid(entity) or entity == self:
			continue
		var to_entity: Vector3 = entity.global_position - global_position
		to_entity.y = 0.0
		var dist: float = to_entity.length()
		if dist <= 2.2:
			var hp: HealthComponent = entity.find_child("HealthComponent", true, false) as HealthComponent
			if hp and hp.is_alive():
				hp.take_damage(5.0, self)
			var push_dir: Vector3 = to_entity.normalized() if dist > 0.01 else _dash_direction.cross(Vector3.UP).normalized()
			var impulse: Vector3 = push_dir * 8.0 + Vector3(0, 1.2, 0)
			if entity.has_method("apply_knockback"):
				entity.call("apply_knockback", impulse, 0.15)
	
	# Deflect projectiles along slipstream
	var projectiles: Array[Node] = get_tree().get_nodes_in_group("projectiles")
	for proj in projectiles:
		if not is_instance_valid(proj) or proj.is_queued_for_deletion():
			continue
		if proj is Projectile:
			var p: Projectile = proj as Projectile
			if p.caster == self:
				continue
			var p_dist: float = global_position.distance_to(p.global_position)
			if p_dist <= 2.2:
				var away_dir: Vector3 = (p.global_position - global_position)
				away_dir.y = 0.0
				away_dir = away_dir.normalized() if away_dir.length_squared() > 0.01 else -_dash_direction
				p.look_at(p.global_position + away_dir, Vector3.UP)
				p.caster = self


func apply_knockback(impulse: Vector3, stagger_duration: float = 0.2) -> void:
	_knockback_velocity = impulse
	_stagger_timer = stagger_duration

## Applies movement slow debuff and displays frost visuals
func apply_slow(multiplier: float, duration: float) -> void:
	_speed_modifier = clampf(1.0 - multiplier, 0.2, 0.85)
	_slow_timer = duration
	_is_slowed = true
	_apply_frost_visual(true)
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)

func _apply_frost_visual(active: bool) -> void:
	if not visuals:
		return
	var mesh_instances: Array[Node] = visuals.find_children("*", "MeshInstance3D", true, false)
	for m in mesh_instances:
		if m is MeshInstance3D:
			if active:
				var frost_mat := StandardMaterial3D.new()
				frost_mat.albedo_color = Color(0.4, 0.88, 1.0, 0.9)
				frost_mat.roughness = 0.15
				frost_mat.emission_enabled = true
				frost_mat.emission = Color(0.25, 0.75, 1.0)
				frost_mat.emission_energy_multiplier = 0.5
				m.material_override = frost_mat
			else:
				m.material_override = null

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_player_died(_killer: Node) -> void:
	collision_layer = 0
	collision_mask = 0
