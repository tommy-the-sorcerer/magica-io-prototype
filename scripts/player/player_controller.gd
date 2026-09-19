class_name PlayerController
extends CharacterBody3D

## Arcane Apprentice — Playable Hero Mage
## Features realistic humanoid locomotion & turning physics:
## - Full 360° smooth turning with dynamic centripetal banking/lean into turns
## - Head & torso gaze anticipation leading rotational changes
## - Humanoid skeletal gait (alternating hip strides, knee flexion, ankle push-off, counter-torsion spine)
## - Weight transfer, lateral hip sway, double-bounce stride cadence
## - Natural acceleration/braking physics and idle breathing/weight shift

enum AnimState { IDLE, RUN, CAST, HIT, DEATH }

@export var move_speed: float = 7.2
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var rotation_speed: float = 13.5 # Radians/sec turn interpolation
@export var bank_strength: float = 0.28   # Inward lean into turns
@export var cast_cooldown: float = 0.65
@export var default_spell: PackedScene = preload("res://scenes/spells/arcane_bolt.tscn")

var display_name: String = "Arcane Apprentice"
var current_xp: float = 0.0
var max_xp: float = 50.0
var current_level: int = 1
var can_cast: bool = true
var current_state: AnimState = AnimState.IDLE
var mobile_input_dir: Vector2 = Vector2.ZERO

# Locomotion & Physics state
var _current_body_yaw: float = 0.0
var _current_bank_roll: float = 0.0
var _current_pitch_lean: float = 0.0
var _current_head_yaw: float = 0.0
var _current_torso_yaw: float = 0.0
var _run_phase: float = 0.0
var _anim_time: float = 0.0
var _cast_timer: float = 0.0
var _turn_velocity: float = 0.0
var _prev_target_yaw: float = 0.0

# Node references
@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D
@onready var player_indicator: MeshInstance3D = $PlayerIndicator
@onready var wardrobe_manager: WardrobeManager = get_node_or_null("WardrobeManager") as WardrobeManager

var cast_point: Marker3D
var crystal_light: OmniLight3D
var anim_player: AnimationPlayer
var skeleton: Skeleton3D

# Bone indices for procedural humanoid animation
var _b_spine: int = -1
var _b_chest: int = -1
var _b_neck: int = -1
var _b_head: int = -1
var _b_thigh_l: int = -1
var _b_thigh_r: int = -1
var _b_shin_l: int = -1
var _b_shin_r: int = -1
var _b_foot_l: int = -1
var _b_foot_r: int = -1
var _b_arm_l: int = -1
var _b_arm_r: int = -1
var _b_forearm_l: int = -1

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")

	_bind_visual_nodes()

	if visuals:
		_current_body_yaw = visuals.rotation.y
		_prev_target_yaw = _current_body_yaw

	if health_component:
		if not health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.connect(_on_health_changed)
		if not health_component.died.is_connected(_on_died):
			health_component.died.connect(_on_died)
		if not health_component.damaged.is_connected(_on_damaged):
			health_component.damaged.connect(_on_damaged)
		_update_nameplate(health_component.current_health, health_component.max_health)

	call_deferred("_sync_hud_xp")

func _bind_visual_nodes() -> void:
	if not visuals:
		visuals = get_node_or_null("Visuals") as Node3D
	if not visuals:
		return

	anim_player = visuals.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = visuals.find_child("Skeleton3D", true, false) as Skeleton3D
	if not skeleton:
		skeleton = visuals.find_child("GeneralSkeleton", true, false) as Skeleton3D

	var default_cube := visuals.find_child("Cube", true, false) as Node3D
	if default_cube:
		default_cube.visible = false

	if skeleton:
		_cache_bone_indices()

	cast_point = visuals.find_child("CastPoint", true, false) as Marker3D
	crystal_light = visuals.find_child("StaffCrystalLight", true, false) as OmniLight3D
	if not crystal_light: crystal_light = visuals.find_child("CrystalLight", true, false) as OmniLight3D

func _cache_bone_indices() -> void:
	if not skeleton:
		return
	_b_spine = skeleton.find_bone("spine")
	_b_chest = skeleton.find_bone("spine.003")
	if _b_chest < 0: _b_chest = skeleton.find_bone("spine.002")
	_b_neck = skeleton.find_bone("spine.004")
	_b_head = skeleton.find_bone("spine.006")
	if _b_head < 0: _b_head = skeleton.find_bone("face")

	_b_thigh_l = skeleton.find_bone("thigh.L")
	_b_thigh_r = skeleton.find_bone("thigh.R")
	_b_shin_l = skeleton.find_bone("shin.L")
	_b_shin_r = skeleton.find_bone("shin.R")
	_b_foot_l = skeleton.find_bone("foot.L")
	_b_foot_r = skeleton.find_bone("foot.R")

	_b_arm_l = skeleton.find_bone("upper_arm.L")
	_b_arm_r = skeleton.find_bone("upper_arm.R")
	_b_forearm_l = skeleton.find_bone("forearm.L")

func _sync_hud_xp() -> void:
	if not get_tree().current_scene:
		return
	var hud: HUD = get_tree().current_scene.find_child("HUD", true, false) as HUD
	if hud:
		hud.update_player_xp(current_xp, max_xp, current_level)

func add_xp(amount: float) -> void:
	current_xp += amount
	while current_xp >= max_xp:
		current_xp -= max_xp
		current_level += 1
		max_xp = int(max_xp * 1.35)
		if health_component:
			health_component.heal(30.0)
		_pulse_level_up_vfx()

	if get_tree().current_scene:
		var hud: HUD = get_tree().current_scene.find_child("HUD", true, false) as HUD
		if hud:
			hud.update_player_xp(current_xp, max_xp, current_level)
	_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s (Lv.%d)" % [int(curr), int(max_hp), display_name, current_level]
		nameplate.modulate = Color(0.3, 0.9, 1.0) if curr > 35 else Color(0.95, 0.3, 0.3)

func _physics_process(delta: float) -> void:
	if current_state == AnimState.DEATH:
		return

	_anim_time += delta

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Input: WASD / Arrow keys + Mobile input
	var input_dir: Vector2 = mobile_input_dir
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

	# Humanoid locomotion acceleration and natural braking deceleration
	var target_vel: Vector3 = Vector3(input_dir.x, 0, input_dir.y) * move_speed
	var accel_rate: float = acceleration if input_dir.length_squared() > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_vel.x, accel_rate * delta * move_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, accel_rate * delta * move_speed)

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var speed_fraction: float = clampf(horizontal_speed / move_speed, 0.0, 1.0)
	var is_moving: bool = horizontal_speed > 0.25

	# Smooth 360° Rotational Kinematics with Natural Centripetal Banking
	var turn_angle_diff: float = 0.0
	if input_dir.length_squared() > 0.01:
		var target_yaw: float = atan2(-input_dir.x, -input_dir.y)
		turn_angle_diff = wrapf(target_yaw - _current_body_yaw, -PI, PI)
		
		# Smooth rotational interpolation
		var turn_step: float = rotation_speed * delta
		if absf(turn_angle_diff) <= turn_step:
			_current_body_yaw = target_yaw
		else:
			_current_body_yaw += signf(turn_angle_diff) * turn_step

		_turn_velocity = lerpf(_turn_velocity, turn_angle_diff / maxf(delta, 0.001), 12.0 * delta)

		if current_state != AnimState.CAST:
			current_state = AnimState.RUN
	else:
		turn_angle_diff = 0.0
		_turn_velocity = move_toward(_turn_velocity, 0.0, 10.0 * delta)
		if current_state != AnimState.CAST:
			current_state = AnimState.IDLE

	# Human Turning: Banking (inward roll) and Gaze Anticipation (head/torso lead)
	var target_bank: float = clampf(-turn_angle_diff * bank_strength * speed_fraction, -0.26, 0.26)
	_current_bank_roll = lerpf(_current_bank_roll, target_bank, 9.0 * delta)

	# Forward Sprint Lean: Humans lean forward when running
	var target_pitch: float = 0.12 * speed_fraction
	_current_pitch_lean = lerpf(_current_pitch_lean, target_pitch, 8.0 * delta)

	# Head and Upper-Body Turn Anticipation (Head leads the turn)
	var target_head_yaw: float = clampf(turn_angle_diff * 0.40, -deg_to_rad(32.0), deg_to_rad(32.0))
	var target_torso_yaw: float = clampf(turn_angle_diff * 0.18, -deg_to_rad(14.0), deg_to_rad(14.0))
	_current_head_yaw = lerpf(_current_head_yaw, target_head_yaw, 14.0 * delta)
	_current_torso_yaw = lerpf(_current_torso_yaw, target_torso_yaw, 10.0 * delta)

	# Apply body orientation with banking roll and forward pitch lean
	if visuals:
		visuals.rotation.y = _current_body_yaw
		visuals.rotation.z = _current_bank_roll
		visuals.rotation.x = _current_pitch_lean

	# Spell Cast Input (Space / Left Mouse Button)
	if (Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and can_cast:
		_cast_spell()

	if is_inside_tree():
		move_and_slide()

	# High-Fidelity Humanoid Gait & State Animations
	_process_humanoid_animation(delta, speed_fraction, is_moving, turn_angle_diff)

	# Keep ground indicator decoupled from player body rotation
	if player_indicator and is_inside_tree():
		player_indicator.global_position = global_position + Vector3(0, 0.04, 0)
		player_indicator.global_rotation = Vector3.ZERO

func _process_humanoid_animation(delta: float, speed_fraction: float, is_moving: bool, turn_diff: float) -> void:
	if current_state == AnimState.CAST:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			current_state = AnimState.RUN if is_moving else AnimState.IDLE

	if is_moving:
		# Dynamic stride frequency proportional to speed
		var stride_freq: float = 14.5 * speed_fraction
		_run_phase += delta * stride_freq

		# Double-bounce vertical center-of-mass oscillation (two steps per full cycle)
		var vertical_bob: float = absf(sin(_run_phase)) * 0.055 * speed_fraction
		# Lateral weight transfer hip sway
		var lateral_sway: float = sin(_run_phase) * 0.022 * speed_fraction
		visuals.position = Vector3(lateral_sway, vertical_bob, 0.0)

		# Animate skeleton bones if available
		if skeleton:
			_animate_skeleton_running(speed_fraction, turn_diff)
	else:
		# Idle: Smoothly return to relaxed standing stance with gentle breathing
		var breath: float = sin(_anim_time * 2.4) * 0.015
		var weight_shift: float = sin(_anim_time * 0.7) * 0.008
		visuals.position = Vector3(weight_shift, breath, 0.0)
		_current_pitch_lean = lerpf(_current_pitch_lean, 0.0, 6.0 * delta)
		_current_bank_roll = lerpf(_current_bank_roll, 0.0, 8.0 * delta)

		if skeleton:
			_animate_skeleton_idle(delta)

	# Soft crystal light pulse
	if crystal_light:
		crystal_light.light_energy = 0.8 + sin(_anim_time * 3.5) * 0.25

func _animate_skeleton_running(speed_frac: float, turn_diff: float) -> void:
	if not skeleton:
		return

	# Leg Stride Angles: Alternating forward and back swinging
	var stride_angle: float = sin(_run_phase) * 0.60 * speed_frac
	# Knee flexion: Shins flex during back-swing recovery phase
	var knee_l: float = clampf(-sin(_run_phase) * 0.75, 0.0, 0.85) * speed_frac
	var knee_r: float = clampf(sin(_run_phase) * 0.75, 0.0, 0.85) * speed_frac

	# Arm Swing: Opposite to leg stride
	var arm_l_swing: float = -stride_angle * 0.75
	var arm_r_swing: float = stride_angle * 0.35 # Holding staff

	# Apply to skeletal bones
	if _b_thigh_l >= 0:
		skeleton.set_bone_pose_rotation(_b_thigh_l, Quaternion(Vector3.RIGHT, stride_angle))
	if _b_thigh_r >= 0:
		skeleton.set_bone_pose_rotation(_b_thigh_r, Quaternion(Vector3.RIGHT, -stride_angle))

	if _b_shin_l >= 0:
		skeleton.set_bone_pose_rotation(_b_shin_l, Quaternion(Vector3.RIGHT, knee_l))
	if _b_shin_r >= 0:
		skeleton.set_bone_pose_rotation(_b_shin_r, Quaternion(Vector3.RIGHT, knee_r))

	if _b_arm_l >= 0:
		skeleton.set_bone_pose_rotation(_b_arm_l, Quaternion(Vector3.RIGHT, arm_l_swing))
	if _b_arm_r >= 0:
		skeleton.set_bone_pose_rotation(_b_arm_r, Quaternion(Vector3.RIGHT, arm_r_swing))

	# Spine counter-torsion & chest twist
	if _b_chest >= 0:
		var chest_yaw: float = -sin(_run_phase) * 0.12 * speed_frac + _current_torso_yaw
		skeleton.set_bone_pose_rotation(_b_chest, Quaternion(Vector3.UP, chest_yaw))

	# Head stabilization and turn anticipation
	if _b_head >= 0:
		var head_rot := Quaternion(Vector3.UP, _current_head_yaw)
		skeleton.set_bone_pose_rotation(_b_head, head_rot)

func _animate_skeleton_idle(delta: float) -> void:
	if not skeleton:
		return

	# Gentle breathing on chest & head
	var breath_chest: float = sin(_anim_time * 2.4) * 0.035
	if _b_chest >= 0:
		var cur_rot: Quaternion = skeleton.get_bone_pose_rotation(_b_chest)
		var target_rot := Quaternion(Vector3.RIGHT, breath_chest)
		skeleton.set_bone_pose_rotation(_b_chest, cur_rot.slerp(target_rot, 6.0 * delta))

	if _b_head >= 0:
		var cur_rot: Quaternion = skeleton.get_bone_pose_rotation(_b_head)
		var target_rot := Quaternion(Vector3.RIGHT, -breath_chest * 0.4)
		skeleton.set_bone_pose_rotation(_b_head, cur_rot.slerp(target_rot, 6.0 * delta))

	# Reset limbs smoothly to resting stance
	for b_idx in [_b_thigh_l, _b_thigh_r, _b_shin_l, _b_shin_r, _b_arm_l, _b_arm_r]:
		if b_idx >= 0:
			var cur_rot: Quaternion = skeleton.get_bone_pose_rotation(b_idx)
			skeleton.set_bone_pose_rotation(b_idx, cur_rot.slerp(Quaternion.IDENTITY, 8.0 * delta))

func _cast_spell() -> void:
	can_cast = false
	current_state = AnimState.CAST
	_cast_timer = 0.32

	var forward_dir: Vector3 = -visuals.global_transform.basis.z.normalized()

	var spell_scene: PackedScene = default_spell
	if spell_scene and get_tree().current_scene:
		var proj: Node3D = spell_scene.instantiate() as Node3D
		proj.set("caster", self)
		get_tree().current_scene.add_child(proj)

		var spawn_pos: Vector3 = cast_point.global_position if cast_point else global_position + Vector3(0, 0.8, 0) + forward_dir * 0.9
		proj.global_position = spawn_pos
		proj.look_at(spawn_pos + forward_dir, Vector3.UP)

	# Cast burst glow
	if crystal_light:
		var tween := create_tween()
		tween.tween_property(crystal_light, "light_energy", 4.2, 0.06)
		tween.tween_property(crystal_light, "light_energy", 0.8, 0.22)

	await get_tree().create_timer(cast_cooldown).timeout
	can_cast = true

func _pulse_level_up_vfx() -> void:
	if crystal_light:
		var tween := create_tween()
		tween.tween_property(crystal_light, "light_energy", 5.0, 0.15)
		tween.tween_property(crystal_light, "light_energy", 0.8, 0.4)

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_damaged(_amount: float, _source: Node) -> void:
	var tween := create_tween()
	var shake := Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.12, 0.12))
	tween.tween_property(visuals, "position", shake, 0.04)
	tween.tween_property(visuals, "position", Vector3.ZERO, 0.08)

func _on_died(_killer: Node) -> void:
	current_state = AnimState.DEATH
	set_physics_process(false)

	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3.ZERO, 0.45)
	tween.tween_property(nameplate, "modulate:a", 0.0, 0.3)
	if player_indicator:
		tween.tween_property(player_indicator, "scale", Vector3.ZERO, 0.3)
