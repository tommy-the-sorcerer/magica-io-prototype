class_name PlayerController
extends CharacterBody3D

## High-Detail Voxel Hero with animated swinging arms, legs, and Magica.io wobble

@export var move_speed: float = 7.0
@export var acceleration: float = 14.0

var display_name: String = "Player#51393"
var walk_cycle_time: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D

# Animated Limbs
@onready var left_leg_pivot: Node3D = $Visuals/LeftLegPivot
@onready var right_leg_pivot: Node3D = $Visuals/RightLegPivot
@onready var left_arm_pivot: Node3D = $Visuals/LeftArmPivot
@onready var right_arm_pivot: Node3D = $Visuals/RightArmPivot

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s" % [int(curr), int(max_hp), display_name]
		nameplate.modulate = Color(0.65, 0.95, 0.3) if curr > 30 else Color(0.95, 0.3, 0.3)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

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
		if right_arm_pivot:
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
		if right_arm_pivot:
			right_arm_pivot.rotation.x = move_toward(right_arm_pivot.rotation.x, 0, 10.0 * delta)

	move_and_slide()

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
