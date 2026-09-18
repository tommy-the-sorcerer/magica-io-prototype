class_name PlayerController
extends CharacterBody3D

## Playable Wizard Hero with WASD/Joystick movement and overhead Magica.io health bar

@export var move_speed: float = 7.0
@export var acceleration: float = 14.0

var display_name: String = "Player#51393"

@onready var visuals: Node3D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("player")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_nameplate(health_component.current_health, health_component.max_health)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if nameplate:
		nameplate.text = "[ %d / %d ]\n%s" % [int(curr), int(max_hp), display_name]
		nameplate.modulate = Color(0.6, 0.95, 0.3) if curr > 30 else Color(0.95, 0.3, 0.3)

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

	# Isometric 45-degree movement mapping
	var target_vel := Vector3(input_dir.x, 0, input_dir.y) * move_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta * move_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta * move_speed)

	# Face movement direction
	if input_dir.length_squared() > 0.05:
		var look_target := global_position + Vector3(input_dir.x, 0, input_dir.y)
		visuals.look_at(look_target, Vector3.UP)
		# Wobble walk animation
		var wobble := sin(Time.get_ticks_msec() * 0.015) * 0.15
		visuals.rotation.z = wobble
	else:
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 8.0 * delta)

	move_and_slide()

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
