class_name AntigravityPad
extends Node3D

## Magical Antigravity Pad
## Features glowing runic dais, upward energy column, floating energy ring,
## and a buoyancy lift field for players, bots, and physics objects.

@export var lift_speed: float = 6.5
@export var max_lift_height: float = 4.2
@export var is_active: bool = true
@export var energy_color: Color = Color(0.1, 0.85, 1.0)
@export var energy_accent: Color = Color(0.65, 0.35, 1.0)

var _levitating_bodies: Array[CharacterBody3D] = []
var _base_y: float = 0.0

@onready var trigger_area: Area3D = $TriggerArea
@onready var energy_column: MeshInstance3D = $Visuals/EnergyColumn
@onready var floating_ring: MeshInstance3D = $Visuals/FloatingRing
@onready var runes_mesh: MeshInstance3D = $Visuals/RunicRing
@onready var light: OmniLight3D = $Visuals/OmniLight3D

func _ready() -> void:
	_base_y = global_position.y
	if trigger_area:
		trigger_area.body_entered.connect(_on_body_entered)
		trigger_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Visual animations: Rotating ring and subtle pulse
	if floating_ring:
		floating_ring.rotation.y += 1.8 * delta
		floating_ring.position.y = 0.6 + sin(Time.get_ticks_msec() * 0.004) * 0.12

	if energy_column:
		energy_column.rotation.y -= 0.6 * delta
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08
		energy_column.scale.x = pulse
		energy_column.scale.z = pulse

	# Apply smooth levitation / buoyancy to entities inside the beam
	for body in _levitating_bodies:
		if not is_instance_valid(body):
			continue
		
		var height_above_pad: float = body.global_position.y - _base_y
		if height_above_pad < max_lift_height:
			# Upward lift force counteracting gravity and gently ascending
			body.velocity.y = move_toward(body.velocity.y, lift_speed, 22.0 * delta)
		else:
			# Soft hover plateau at apex
			body.velocity.y = move_toward(body.velocity.y, 0.0, 15.0 * delta)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and not _levitating_bodies.has(body):
		_levitating_bodies.append(body as CharacterBody3D)
		_pulse_activation()

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and _levitating_bodies.has(body):
		_levitating_bodies.erase(body as CharacterBody3D)

func _pulse_activation() -> void:
	if light:
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 3.5, 0.15)
		tween.tween_property(light, "light_energy", 1.8, 0.35)
