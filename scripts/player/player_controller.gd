class_name PlayerController
extends CharacterBody3D

## High-Detail Voxel Hero with WASD movement, Spacebar spellcasting, Right-Click Dash, and animated limbs

@export var move_speed: float = 7.0
@export var acceleration: float = 14.0

var display_name: String = "Player#51393"
var walk_cycle_time: float = 0.0

# Spellcasting & Dash
var can_shoot: bool = true
var shoot_cooldown: float = 0.35
var can_dash: bool = true
var dash_cooldown: float = 1.8
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD

@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D

# Animated Limbs
@onready var left_leg_pivot: Node3D = $Visuals/LeftLegPivot
@onready var right_leg_pivot: Node3D = $Visuals/RightLegPivot
@onready var left_arm_pivot: Node3D = $Visuals/LeftArmPivot
@onready var right_arm_pivot: Node3D = $Visuals/RightArmPivot
@onready var wand_flame: MeshInstance3D = $Visuals/RightArmPivot/Wand/FlameTip

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_nameplate(health_component.current_health, health_component.max_health)
		
	call_deferred("_connect_hud_touch_buttons")

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
			dash_btn.text = "⚡" # Dash icon
			dash_btn.pressed.connect(dash)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s" % [int(curr), int(max_hp), display_name]
		nameplate.modulate = Color(0.65, 0.95, 0.3) if curr > 30 else Color(0.95, 0.3, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	# Spacebar to Shoot Spell
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			shoot_spell()
		elif event.keycode == KEY_SHIFT:
			dash()

	# Right Mouse Click to Dash
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dash()

func shoot_spell() -> void:
	if not can_shoot or is_dashing:
		return
	can_shoot = false
	
	# Spawn Fireball Projectile
	var fireball_scene := load("res://scenes/spells/fireball.tscn")
	if fireball_scene:
		var proj := fireball_scene.instantiate() as Projectile
		proj.caster = self
		get_tree().current_scene.add_child(proj)
		
		# Position at wand flame tip
		var spawn_pos: Vector3 = wand_flame.global_position if wand_flame else global_position + Vector3(0, 0.8, 0)
		proj.global_position = spawn_pos
		
		# Shoot forward in player's facing direction
		var forward_dir: Vector3 = -visuals.global_transform.basis.z
		proj.look_at(spawn_pos + forward_dir, Vector3.UP)
	
	# Punchy recoil animation on right arm
	if right_arm_pivot:
		var tween := create_tween()
		tween.tween_property(right_arm_pivot, "rotation:x", -1.2, 0.08)
		tween.tween_property(right_arm_pivot, "rotation:x", 0.0, 0.15)
		
	# Cooldown
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func dash() -> void:
	if not can_dash or is_dashing:
		return
	can_dash = false
	is_dashing = true
	dash_time_left = 0.22
	
	# Dash in current movement direction or facing direction
	dash_direction = -visuals.global_transform.basis.z
	
	# Ghost dash trail effect
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.3, 0.7, 1.3), 0.08)
	tween.tween_property(visuals, "scale", Vector3.ONE, 0.14)
	
	# Cooldown timer
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Handle Active Dash
	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_direction.x * 22.0
		velocity.z = dash_direction.z * 22.0
		if dash_time_left <= 0.0:
			is_dashing = false
		move_and_slide()
		return

	# Input: WASD / Arrow keys
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
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

	var move_vector: Vector3 = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
	var target_vel := move_vector * move_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta * move_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta * move_speed)

	# Face movement direction and animate walk cycle
	if input_dir.length_squared() > 0.05:
		var look_target := global_position + move_vector
		visuals.look_at(look_target, Vector3.UP)
		
		# Walk cycle animations (legs, arms, wobble)
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
		# Return to idle
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 8.0 * delta)
		if left_leg_pivot:
			left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0, 10.0 * delta)
		if right_leg_pivot:
			right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0, 10.0 * delta)
		if left_arm_pivot:
			left_arm_pivot.rotation.x = move_toward(left_arm_pivot.rotation.x, 0, 10.0 * delta)
		if right_arm_pivot and can_shoot:
			right_arm_pivot.rotation.x = move_toward(right_arm_pivot.rotation.x, 0, 10.0 * delta)

	move_and_slide()

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
