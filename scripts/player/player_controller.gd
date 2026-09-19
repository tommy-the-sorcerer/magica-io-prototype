class_name PlayerController
extends CharacterBody3D

const AntigravityScript = preload("res://scripts/player/antigravity.gd")

## High-Detail Voxel Hero with Dual Mobile Joysticks, WASD movement, 360° Aiming,
## Spacebar Flip Jump, Right-Click/Shift Dash, and Animated Limbs.

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
@export var move_joystick: MobileVirtualJoystick
@export var aim_joystick: MobileVirtualJoystick
@export var cast_point: Marker3D

@export_group("Antigravity Settings")
@export var antigravity_enabled: bool = true

var display_name: String = "Player#5139"
var walk_cycle_time: float = 0.0

# Spellcasting, Dash & Flip State
var can_shoot: bool = true
var shoot_cooldown: float = 0.35
var can_dash: bool = true
var dash_cooldown: float = 1.8
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD

# 360 Flip State
var can_flip: bool = true
var is_flipping: bool = false
var flip_cooldown: float = 1.0

@onready var visuals: Node3D = $Visuals if has_node("Visuals") else null
@onready var health_component: HealthComponent = $HealthComponent if has_node("HealthComponent") else null
@onready var nameplate: Label3D = $Nameplate3D if has_node("Nameplate3D") else null

var _mouse_aim_start: Vector2 = Vector2.ZERO
var _is_mouse_aiming: bool = false
var _last_mouse_aim_dir: Vector3 = Vector3.FORWARD

# Animated Limbs
@onready var left_leg_pivot: Node3D = $Visuals/LeftLegPivot if has_node("Visuals/LeftLegPivot") else null
@onready var right_leg_pivot: Node3D = $Visuals/RightLegPivot if has_node("Visuals/RightLegPivot") else null
@onready var left_arm_pivot: Node3D = $Visuals/LeftArmPivot if has_node("Visuals/LeftArmPivot") else null
@onready var right_arm_pivot: Node3D = $Visuals/RightArmPivot if has_node("Visuals/RightArmPivot") else null
@onready var wand_flame: MeshInstance3D = $Visuals/RightArmPivot/Wand/FlameTip if has_node("Visuals/RightArmPivot/Wand/FlameTip") else null

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_nameplate(health_component.current_health, health_component.max_health)
		
	call_deferred("_connect_hud_touch_buttons")

	if not cast_point and visuals:
		cast_point = visuals.find_child("CastPoint", true, false) as Marker3D
	if not cast_point:
		cast_point = find_child("CastPoint", true, false) as Marker3D

	_setup_joysticks()

func _connect_hud_touch_buttons() -> void:
	var hud := get_tree().current_scene.find_child("HUD", true, false)
	if hud:
		var orb_panel := hud.find_child("Orb", true, false)
		if orb_panel:
			orb_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					shoot_spell()
			)
		var dash_btn := hud.find_child("LockSkill1", true, false) as Button
		if dash_btn:
			dash_btn.text = "⚡"
			if not dash_btn.pressed.is_connected(dash):
				dash_btn.pressed.connect(dash)

func _setup_joysticks() -> void:
	if not move_joystick:
		move_joystick = get_tree().current_scene.find_child("MoveJoystick", true, false) as MobileVirtualJoystick
		if not move_joystick:
			move_joystick = get_tree().current_scene.find_child("LeftJoystick", true, false) as MobileVirtualJoystick

	if not aim_joystick:
		aim_joystick = get_tree().current_scene.find_child("AimJoystick", true, false) as MobileVirtualJoystick
		if not aim_joystick:
			aim_joystick = get_tree().current_scene.find_child("RightJoystick", true, false) as MobileVirtualJoystick

	if aim_joystick and not aim_joystick.joystick_released.is_connected(_on_aim_joystick_released):
		aim_joystick.joystick_released.connect(_on_aim_joystick_released)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s" % [int(curr), int(max_hp), display_name]
		nameplate.modulate = Color(0.65, 0.95, 0.3) if curr > 30 else Color(0.95, 0.3, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_K or event.keycode == KEY_ENTER:
			shoot_spell()
		elif event.keycode == KEY_F:
			perform_flip()
		elif event.keycode == KEY_SHIFT:
			dash()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				dash()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
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

## Reusable 360° Movement Flip Action (SPACEBAR / Mobile Button)
func perform_flip() -> void:
	if not can_flip or is_flipping or not visuals:
		return
	can_flip = false
	is_flipping = true
	
	var tween := create_tween()
	# 1. Prepare / Anticipation Bend
	tween.tween_property(visuals, "position:y", -0.15, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visuals, "scale", Vector3(1.15, 0.82, 1.15), 0.15)
	
	# 2. Jump & Air Movement
	tween.chain().tween_property(visuals, "position:y", 0.85, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visuals, "scale", Vector3(0.9, 1.15, 0.9), 0.18)
	
	# 3. 360° Pitch Rotation through air
	tween.parallel().tween_property(visuals, "rotation:x", -TAU, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 4. Land & Squash
	tween.chain().tween_property(visuals, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(visuals, "rotation:x", 0.0, 0.15)
	tween.parallel().tween_property(visuals, "scale", Vector3(1.2, 0.8, 1.2), 0.10)
	
	# 5. Recovery to Idle
	tween.chain().tween_property(visuals, "scale", Vector3.ONE, 0.15)
	
	await tween.finished
	is_flipping = false
	
	await get_tree().create_timer(flip_cooldown).timeout
	can_flip = true

func shoot_spell() -> void:
	if not can_shoot or is_dashing:
		return
	can_shoot = false
	
	var forward_dir := -visuals.global_transform.basis.z if visuals else Vector3.FORWARD
	var spawn_pos: Vector3 = wand_flame.global_position if wand_flame else (cast_point.global_position if cast_point else global_position + Vector3(0, 0.8, 0))
	
	_trigger_spell_cast(forward_dir)
	
	var fireball_scene: PackedScene = spell_scene if spell_scene else (load("res://scenes/spells/fireball.tscn") as PackedScene)
	if fireball_scene:
		var proj: Projectile = fireball_scene.instantiate() as Projectile
		if proj:
			proj.caster = self
			get_tree().current_scene.add_child(proj)
			proj.global_position = spawn_pos
			proj.look_at(spawn_pos + forward_dir, Vector3.UP)
	
	if right_arm_pivot:
		var tween := create_tween()
		tween.tween_property(right_arm_pivot, "rotation:x", -1.2, 0.08)
		tween.tween_property(right_arm_pivot, "rotation:x", 0.0, 0.15)
		
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func dash() -> void:
	if not can_dash or is_dashing:
		return
	can_dash = false
	is_dashing = true
	dash_time_left = 0.22
	
	dash_direction = -visuals.global_transform.basis.z if visuals else Vector3.FORWARD
	
	if visuals:
		var tween := create_tween()
		tween.tween_property(visuals, "scale", Vector3(1.3, 0.7, 1.3), 0.08)
		tween.tween_property(visuals, "scale", Vector3.ONE, 0.14)
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func _physics_process(delta: float) -> void:
	if not move_joystick or not aim_joystick:
		_setup_joysticks()

	if antigravity_enabled:
		AntigravityScript.apply_antigravity(self, antigravity_enabled, delta)
	elif not is_on_floor():
		velocity.y -= 9.8 * delta

	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_direction.x * 22.0
		velocity.z = dash_direction.z * 22.0
		if dash_time_left <= 0.0:
			is_dashing = false
		move_and_slide()
		return

	# Movement Input (Joystick + WASD Fallback)
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

	# Relative to camera orientation
	var cam: Camera3D = get_viewport().get_camera_3d()
	var cam_forward: Vector3 = Vector3.FORWARD
	var cam_right: Vector3 = Vector3.RIGHT
	if cam:
		var cam_basis := cam.global_transform.basis
		cam_forward = -cam_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()

	var move_vector: Vector3 = (cam_right * input_dir.x + cam_forward * -input_dir.y)
	if move_vector.length_squared() > 1.0:
		move_vector = move_vector.normalized()

	var target_vel := move_vector * move_speed
	if move_vector.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta * move_speed)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta * move_speed)

	move_and_slide()

	# Aiming Input (Right Joystick + Mouse Fallback)
	var aim_input := Vector2.ZERO
	if aim_joystick:
		aim_input = aim_joystick.get_output()

	var is_aiming := false
	var active_aim_dir := Vector3.ZERO

	if aim_input.length() >= aim_threshold:
		active_aim_dir = (cam_right * aim_input.x + cam_forward * -aim_input.y).normalized()
		is_aiming = true
	elif _is_mouse_aiming:
		var mouse_dir := _get_mouse_world_dir()
		if mouse_dir.length_squared() > 0.01:
			active_aim_dir = mouse_dir
			_last_mouse_aim_dir = mouse_dir
			is_aiming = true

	# Rotation & Animations
	if visuals and not is_flipping:
		if is_aiming and active_aim_dir.length_squared() > 0.01:
			var target_angle := atan2(active_aim_dir.x, active_aim_dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
		elif move_vector.length_squared() > 0.01:
			var target_angle := atan2(move_vector.x, move_vector.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)

		# Walk animations & Wobble
		if move_vector.length_squared() > 0.05:
			walk_cycle_time += delta * 14.0
			var leg_swing := sin(walk_cycle_time) * 0.65
			var arm_swing := cos(walk_cycle_time) * 0.55
			var wobble := sin(walk_cycle_time * 0.5) * 0.12
			
			if left_leg_pivot:
				left_leg_pivot.rotation.x = leg_swing
			if right_leg_pivot:
				right_leg_pivot.rotation.x = -leg_swing
			if left_arm_pivot:
				left_arm_pivot.rotation.x = -arm_swing
			if right_arm_pivot and can_shoot:
				right_arm_pivot.rotation.x = arm_swing
				
			visuals.rotation.z = wobble
		else:
			visuals.rotation.z = move_toward(visuals.rotation.z, 0.0, 8.0 * delta)
			if left_leg_pivot:
				left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, 10.0 * delta)
			if right_leg_pivot:
				right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, 10.0 * delta)
			if left_arm_pivot:
				left_arm_pivot.rotation.x = move_toward(left_arm_pivot.rotation.x, 0.0, 10.0 * delta)
			if right_arm_pivot and can_shoot:
				right_arm_pivot.rotation.x = move_toward(right_arm_pivot.rotation.x, 0.0, 10.0 * delta)

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
	var hit_pos: Variant = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit_pos is Vector3:
		var hit_vec: Vector3 = hit_pos
		var dir: Vector3 = hit_vec - global_position
		dir.y = 0.0
		return dir.normalized()
	return Vector3.ZERO

func _on_aim_joystick_released(final_output: Vector2) -> void:
	if final_output.length() >= aim_threshold:
		var cam: Camera3D = get_viewport().get_camera_3d()
		var cam_forward := -cam.global_transform.basis.z if cam else Vector3.FORWARD
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var cam_right := cam.global_transform.basis.x if cam else Vector3.RIGHT
		cam_right.y = 0
		cam_right = cam_right.normalized()

		var cast_dir := (cam_right * final_output.x + cam_forward * -final_output.y).normalized()
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
