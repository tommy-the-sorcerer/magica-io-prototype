class_name DragonboundController
extends CharacterBody3D

## Dragonbound - Ruthless Draconic Overlord
## Features massive animated dragon wings, spiked tail, molten dragonfang blade,
## spectral dragon spirit, Hellfire Slash [LMB], Magma Burst [RMB],
## Abyssal Dragon Breath [E], Obsidian Aegis [R], and Infernal Wing Dash [Q].

@export_group("Movement")
@export var move_speed: float = 7.5
@export var acceleration: float = 35.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 720.0

@export_group("Spells")
@export var hellfire_slash_scene: PackedScene = preload("res://characters/dragonbound/skills/hellfire_slash.tscn")
@export var magma_burst_scene: PackedScene = preload("res://characters/dragonbound/skills/magma_burst.tscn")
@export var dragon_breath_scene: PackedScene = preload("res://characters/dragonbound/skills/dragon_breath.tscn")
@export var dragon_aegis_scene: PackedScene = preload("res://characters/dragonbound/skills/dragon_aegis.tscn")
@export var dash_burst_scene: PackedScene = preload("res://characters/dragonbound/vfx/dragon_dash_burst.tscn")
@export var dash_ghost_scene: PackedScene = preload("res://characters/dragonbound/vfx/dragon_dash_ghost.tscn")

@export var slash_cooldown: float = 0.35
@export var magma_cooldown: float = 0.65
@export var breath_cooldown: float = 4.0
@export var aegis_cooldown: float = 8.0
@export var dash_cooldown: float = 3.5
@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.22

# Pipeline Standards
const INPUT_BUFFER_WINDOW: float = 0.08
const CAST_START_DELAY: float = 0.08
const ATTACK_RELEASE_TIME: float = 0.16
const TOTAL_ATTACK_ANIM_TIME: float = 0.35

var display_name: String = "🐲 Dragonbound"
var can_cast: bool = true

var _slash_timer: float = 0.0
var _magma_timer: float = 0.0
var _breath_timer: float = 0.0
var _aegis_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _active_aegis: Node3D = null

var _is_casting_attack: bool = false
var _attack_timer: float = 0.0
var _attack_released: bool = false
var _pending_spell_type: String = ""
var _buffered_attack: bool = false
var _buffered_spell_type: String = ""

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _ghost_spawn_timer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _stagger_timer: float = 0.0
var _speed_modifier: float = 1.0
var _slow_timer: float = 0.0
var _is_slowed: bool = false

# Visual Rig References
@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate
@onready var left_arm: Node3D = find_child("LeftArm", true, false) as Node3D
@onready var right_arm: Node3D = find_child("RightArm", true, false) as Node3D
@onready var left_wing: Node3D = find_child("LeftWing", true, false) as Node3D
@onready var right_wing: Node3D = find_child("RightWing", true, false) as Node3D
@onready var dragon_tail: Node3D = find_child("DragonTail", true, false) as Node3D
@onready var dragon_blade: Node3D = find_child("DragonBlade", true, false) as Node3D
@onready var dragon_spirit: Node3D = find_child("DragonSpirit", true, false) as Node3D
@onready var blade_light: OmniLight3D = find_child("BladeLight", true, false) as OmniLight3D
@onready var left_leg: Node3D = find_child("LeftLeg", true, false) as Node3D
@onready var right_leg: Node3D = find_child("RightLeg", true, false) as Node3D

var _orig_right_arm_rot: Vector3 = Vector3.ZERO
var _orig_left_arm_rot: Vector3 = Vector3.ZERO
var _orig_spirit_pos: Vector3 = Vector3.ZERO
var _orig_visuals_pos_y: float = 0.0
const HOVER_ALTITUDE: float = 0.55

func _ready() -> void:
	add_to_group("players")
	add_to_group("combatants")
	
	if visuals: _orig_visuals_pos_y = visuals.position.y
	if right_arm: _orig_right_arm_rot = right_arm.rotation
	if left_arm: _orig_left_arm_rot = left_arm.rotation
	if dragon_spirit: _orig_spirit_pos = dragon_spirit.position
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_player_died)
		_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if not nameplate:
		return
	var status_tag: String = " ❄️" if _is_slowed else ""
	var aegis_tag: String = " | 🛡️ [R]" if _aegis_timer <= 0.0 else ""
	var breath_tag: String = " | 🐲 [E]" if _breath_timer <= 0.0 else ""
	var dash_tag: String = " | ⚡ [Q]" if _dash_cd_timer <= 0.0 else ""
	nameplate.text = "🔥 [ %d / %d ]%s%s%s%s\n%s (Epic Lvl 23)" % [int(curr), int(max_hp), status_tag, aegis_tag, breath_tag, dash_tag, display_name]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_request_attack("slash")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_request_attack("magma")
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		var keycode: int = event.keycode
		if keycode == KEY_Q and _dash_cd_timer <= 0.0 and not _is_dashing:
			_perform_dash()
		elif keycode == KEY_E and _breath_timer <= 0.0:
			_cast_dragon_breath()
		elif (keycode == KEY_R or keycode == KEY_C) and _aegis_timer <= 0.0:
			_cast_dragon_aegis()

func _physics_process(delta: float) -> void:
	# Timers
	if _slash_timer > 0.0: _slash_timer -= delta
	if _magma_timer > 0.0: _magma_timer -= delta
	if _breath_timer > 0.0:
		_breath_timer -= delta
		if _breath_timer <= 0.0: _breath_timer = 0.0; _refresh_nameplate()
	if _aegis_timer > 0.0:
		_aegis_timer -= delta
		if _aegis_timer <= 0.0: _aegis_timer = 0.0; _refresh_nameplate()
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
		if _dash_cd_timer <= 0.0: _dash_cd_timer = 0.0; _refresh_nameplate()
	
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_is_slowed = false
			_speed_modifier = 1.0
			_refresh_nameplate()
	
	# Attack Pipeline processing
	if _is_casting_attack:
		_attack_timer += delta
		if _attack_timer >= ATTACK_RELEASE_TIME and not _attack_released:
			_attack_released = true
			_execute_attack_release()
		if _attack_timer >= TOTAL_ATTACK_ANIM_TIME:
			_is_casting_attack = false
			can_cast = true
			if _buffered_attack:
				_buffered_attack = false
				_start_attack_pipeline(_buffered_spell_type)
	
	# Active Dash Processing
	if _is_dashing:
		_dash_timer -= delta
		_ghost_spawn_timer -= delta
		if _ghost_spawn_timer <= 0.0:
			_ghost_spawn_timer = 0.04
			_spawn_dash_ghost()
		
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
		move_and_slide()
		_animate_character(delta, true)
		
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity = Vector3.ZERO
		return
	
	# Standard Movement
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	input_dir = input_dir.normalized()
	
	var effective_speed: float = move_speed * _speed_modifier
	var is_moving: bool = input_dir.length_squared() > 0.01
	
	if is_moving:
		var target_vel := Vector3(input_dir.x, 0, input_dir.y) * effective_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	
	# Rotate towards mouse aim
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir.length_squared() > 0.01:
		var target_rot_y := atan2(-aim_dir.x, -aim_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot_y, deg_to_rad(rotation_speed) * delta)
	elif is_moving:
		var move_rot_y := atan2(-input_dir.x, -input_dir.y)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, move_rot_y, deg_to_rad(rotation_speed) * delta)
	
	# Gravity - Grounded Dark Lord (Firmly on earth, never floating like a bird/angel)
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()
	_animate_character(delta, is_moving)

func _animate_character(delta: float, is_moving: bool) -> void:
	var time_ms := Time.get_ticks_msec()
	
	# Flap rhythm and wing mechanics
	var flap_speed: float = 0.012 if is_moving else 0.0055
	var flap_sin: float = sin(time_ms * flap_speed)
	var flap_cos: float = cos(time_ms * flap_speed)
	
	# Airborne Flight Hovering: Clamped at stable flight height, never drifts up into the sky
	var lift_bob: float = (flap_cos * 0.5 + 0.5) * (0.06 if is_moving else 0.04)
	var target_hover_y: float = _orig_visuals_pos_y + HOVER_ALTITUDE + lift_bob
	if visuals:
		visuals.position.y = lerp(visuals.position.y, target_hover_y, 8.0 * delta)
		
		# Draconic Flight Banking & Pitch (Leans forward into flight path, banks into lateral movement)
		var target_pitch: float = -0.15 if is_moving else 0.0
		visuals.rotation.x = lerp_angle(visuals.rotation.x, target_pitch, 8.0 * delta)
		
		var bank_amount: float = 0.0
		if is_moving and abs(velocity.x) > 0.1:
			bank_amount = clamp(-velocity.x / (move_speed + 0.01) * 0.22, -0.22, 0.22)
		visuals.rotation.z = lerp_angle(visuals.rotation.z, bank_amount, 6.0 * delta)
	
	# Dynamic 3D Draconic Wing Flapping Movement
	if left_wing and right_wing:
		if _is_dashing:
			# Supersonic Aerodynamic Delta Flare with High-Frequency Fiery Vibration
			var dash_flutter: float = sin(time_ms * 0.075) * 0.08
			left_wing.rotation.y = -1.25 + dash_flutter
			right_wing.rotation.y = 1.25 - dash_flutter
			left_wing.rotation.z = 0.15
			right_wing.rotation.z = -0.15
			left_wing.rotation.x = 0.08
			right_wing.rotation.x = 0.08
		elif _is_casting_attack and _attack_timer < 0.22:
			# Powerful wing flare bracing against spell recoil
			left_wing.rotation.y = lerp_angle(left_wing.rotation.y, -0.85, 16.0 * delta)
			right_wing.rotation.y = lerp_angle(right_wing.rotation.y, 0.85, 16.0 * delta)
			left_wing.rotation.z = lerp_angle(left_wing.rotation.z, 0.45, 16.0 * delta)
			right_wing.rotation.z = lerp_angle(right_wing.rotation.z, -0.45, 16.0 * delta)
		else:
			# Multi-axis Wing Stroke (Horizontal sweep Y, Vertical lift/downstroke Z, Feathering twist X)
			var flap_amp_y: float = 0.48 if is_moving else 0.28
			var flap_amp_z: float = 0.38 if is_moving else 0.22
			
			var wing_y: float = -0.38 + (flap_sin * flap_amp_y)
			var wing_z: float = 0.20 - (flap_cos * flap_amp_z)
			var wing_x: float = -0.10 + (flap_sin * 0.14)
			
			left_wing.rotation.y = lerp_angle(left_wing.rotation.y, wing_y, 14.0 * delta)
			left_wing.rotation.z = lerp_angle(left_wing.rotation.z, wing_z, 14.0 * delta)
			left_wing.rotation.x = lerp_angle(left_wing.rotation.x, wing_x, 14.0 * delta)
			
			right_wing.rotation.y = lerp_angle(right_wing.rotation.y, -wing_y, 14.0 * delta)
			right_wing.rotation.z = lerp_angle(right_wing.rotation.z, -wing_z, 14.0 * delta)
			right_wing.rotation.x = lerp_angle(right_wing.rotation.x, wing_x, 14.0 * delta)
	
	# Aerial Flight Leg Posture (Legs gracefully suspended & trailing in mid-air, NOT running on ground)
	if left_leg and right_leg:
		if is_moving and not _is_dashing:
			var leg_drift: float = sin(time_ms * 0.008) * 0.08
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.38 + leg_drift, 6.0 * delta)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.32 - leg_drift, 6.0 * delta)
			left_leg.rotation.z = lerp_angle(left_leg.rotation.z, -0.06, 6.0 * delta)
			right_leg.rotation.z = lerp_angle(right_leg.rotation.z, 0.06, 6.0 * delta)
		else:
			var idle_drift: float = sin(time_ms * 0.003) * 0.04
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.26 + idle_drift, 5.0 * delta)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.26 + idle_drift, 5.0 * delta)
			left_leg.rotation.z = lerp_angle(left_leg.rotation.z, -0.05, 5.0 * delta)
			right_leg.rotation.z = lerp_angle(right_leg.rotation.z, 0.05, 5.0 * delta)
	
	# Aerodynamic Dragon Tail Slipstream
	if dragon_tail:
		var tail_sway: float = sin(time_ms * (0.012 if is_moving else 0.004)) * (0.28 if is_moving else 0.10)
		dragon_tail.rotation.y = tail_sway
		dragon_tail.rotation.x = (-0.18 if is_moving else -0.32) + sin(time_ms * 0.006) * 0.06
	
	# Spectral Dragon Spirit Hovering
	if dragon_spirit:
		var spirit_hover_y: float = _orig_spirit_pos.y + sin(time_ms * 0.005) * 0.08
		dragon_spirit.position.y = lerp(dragon_spirit.position.y, spirit_hover_y, 8.0 * delta)
		dragon_spirit.rotation.z = sin(time_ms * 0.006) * 0.14
	
	# Weapon Ember Glow
	if blade_light:
		blade_light.light_energy = 3.0 + sin(time_ms * 0.01) * 0.6

func _request_attack(type: String) -> void:
	if type == "slash" and _slash_timer > 0.0: return
	if type == "magma" and _magma_timer > 0.0: return
	
	if _is_casting_attack:
		var time_left: float = TOTAL_ATTACK_ANIM_TIME - _attack_timer
		if time_left <= INPUT_BUFFER_WINDOW:
			_buffered_attack = true
			_buffered_spell_type = type
		return
	_start_attack_pipeline(type)

func _start_attack_pipeline(type: String) -> void:
	_is_casting_attack = true
	_attack_timer = 0.0
	_attack_released = false
	_pending_spell_type = type
	can_cast = false
	
	if type == "slash":
		_slash_timer = slash_cooldown
		# Animate right arm blade slash
		if right_arm:
			var at := create_tween()
			at.tween_property(right_arm, "rotation:x", -1.4, 0.08)
			at.tween_property(right_arm, "rotation:y", 0.8, 0.08)
			at.tween_property(right_arm, "rotation", _orig_right_arm_rot, 0.18)
	elif type == "magma":
		_magma_timer = magma_cooldown
		# Animate left claw thrust
		if left_arm:
			var lt := create_tween()
			lt.tween_property(left_arm, "rotation:x", -1.2, 0.08)
			lt.tween_property(left_arm, "rotation", _orig_left_arm_rot, 0.18)

func _execute_attack_release() -> void:
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir.length_squared() < 0.01:
		aim_dir = -visuals.global_transform.basis.z
		aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	if _pending_spell_type == "slash" and hellfire_slash_scene:
		var slash: Projectile = hellfire_slash_scene.instantiate() as Projectile
		if slash:
			slash.caster = self
			get_tree().current_scene.add_child(slash)
			slash.global_position = global_position + Vector3(0, 0.95, 0) + aim_dir * 0.8
			slash.look_at(slash.global_position + aim_dir, Vector3.UP)
	elif _pending_spell_type == "magma" and magma_burst_scene:
		var magma: Projectile = magma_burst_scene.instantiate() as Projectile
		if magma:
			magma.caster = self
			get_tree().current_scene.add_child(magma)
			magma.global_position = global_position + Vector3(0, 0.95, 0) + aim_dir * 0.8
			magma.look_at(magma.global_position + aim_dir, Vector3.UP)

func _cast_dragon_breath() -> void:
	if not dragon_breath_scene or _breath_timer > 0.0:
		return
	_breath_timer = breath_cooldown
	_refresh_nameplate()
	
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir.length_squared() < 0.01:
		aim_dir = -visuals.global_transform.basis.z
		aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	# Spectral dragon spirit surges forward roaring!
	if dragon_spirit:
		var st := create_tween()
		st.tween_property(dragon_spirit, "position:z", _orig_spirit_pos.z - 0.7, 0.10)
		st.tween_property(dragon_spirit, "position", _orig_spirit_pos, 0.35)
	
	var breath: Projectile = dragon_breath_scene.instantiate() as Projectile
	if breath:
		breath.caster = self
		get_tree().current_scene.add_child(breath)
		breath.global_position = global_position + Vector3(0, 1.0, 0) + aim_dir * 1.0
		breath.look_at(breath.global_position + aim_dir, Vector3.UP)

func _cast_dragon_aegis() -> void:
	if not dragon_aegis_scene or _aegis_timer > 0.0:
		return
	_aegis_timer = aegis_cooldown
	_refresh_nameplate()
	
	if _active_aegis and is_instance_valid(_active_aegis):
		if _active_aegis.has_method("fade_out"):
			_active_aegis.call("fade_out")
		else:
			_active_aegis.queue_free()
		_active_aegis = null
	
	var aegis: Node3D = dragon_aegis_scene.instantiate() as Node3D
	if not aegis:
		return
	aegis.set("caster", self)
	get_tree().current_scene.add_child(aegis)
	aegis.global_position = global_position + Vector3(0, 0.85, 0)
	_active_aegis = aegis
	aegis.tree_exited.connect(func(): _active_aegis = null)

func _perform_dash() -> void:
	if _dash_cd_timer > 0.0 or _is_dashing:
		return
	_dash_cd_timer = dash_cooldown
	_is_dashing = true
	_dash_timer = dash_duration
	_ghost_spawn_timer = 0.0
	_refresh_nameplate()
	
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	
	if input_dir.length_squared() > 0.01:
		_dash_direction = input_dir.normalized()
	else:
		_dash_direction = _get_mouse_aim_direction()
		if _dash_direction.length_squared() < 0.01:
			_dash_direction = -visuals.global_transform.basis.z
			_dash_direction.y = 0.0
		_dash_direction = _dash_direction.normalized()
	
	# Spawn burst VFX
	if dash_burst_scene:
		var burst: Node3D = dash_burst_scene.instantiate() as Node3D
		if burst:
			get_tree().current_scene.add_child(burst)
			burst.global_position = global_position
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.20)

func _spawn_dash_ghost() -> void:
	if not dash_ghost_scene:
		return
	var ghost: Node3D = dash_ghost_scene.instantiate() as Node3D
	if ghost:
		get_tree().current_scene.add_child(ghost)
		ghost.global_transform = visuals.global_transform
		ghost.global_position = visuals.global_position

func _get_mouse_aim_direction() -> Vector3:
	var viewport := get_viewport()
	if not viewport:
		return -visuals.global_transform.basis.z
	var camera := viewport.get_camera_3d()
	if not camera:
		return -visuals.global_transform.basis.z
	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, global_position.y)
	var hit_pos = plane.intersects_ray(ray_origin, ray_dir)
	if hit_pos != null:
		var dir: Vector3 = (hit_pos - global_position)
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			return dir.normalized()
	return -visuals.global_transform.basis.z

func _refresh_nameplate() -> void:
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)

func apply_knockback(impulse: Vector3, stagger_duration: float = 0.2) -> void:
	_knockback_velocity = impulse
	_stagger_timer = stagger_duration

func apply_slow(multiplier: float, duration: float) -> void:
	_speed_modifier = clampf(1.0 - multiplier, 0.2, 0.85)
	_slow_timer = duration
	_is_slowed = true
	_refresh_nameplate()

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_player_died(_killer: Node) -> void:
	collision_layer = 0
	collision_mask = 0
