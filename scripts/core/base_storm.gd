class_name BaseStorm
extends Node3D

## Reusable Battle Royale Shrinking Storm Zone with damage ticks, radius interpolation, and particle hooks

signal storm_phase_started(phase: int, target_radius: float)
signal storm_shrink_completed

@export var start_radius: float = 48.0
@export var min_radius: float = 8.0
@export var shrink_duration: float = 120.0
@export var damage_per_second: float = 6.0
@export var tick_interval: float = 0.5

var current_radius: float = 48.0
var target_radius: float = 48.0
var is_shrinking: bool = false
var elapsed_time: float = 0.0
var tick_timer: float = 0.0

@onready var barrier_mesh: MeshInstance3D = $BarrierMesh

func _ready() -> void:
	current_radius = start_radius
	target_radius = start_radius
	_update_visual_radius(current_radius)

func start_shrink(new_target_radius: float, duration: float) -> void:
	target_radius = maxf(min_radius, new_target_radius)
	shrink_duration = duration
	elapsed_time = 0.0
	is_shrinking = true
	storm_phase_started.emit(1, target_radius)

func _physics_process(delta: float) -> void:
	# Shrink interpolation
	if is_shrinking:
		elapsed_time += delta
		var t := clampf(elapsed_time / maxf(shrink_duration, 0.1), 0.0, 1.0)
		# Smooth step interpolation
		current_radius = lerpf(current_radius, target_radius, delta * 0.8)
		_update_visual_radius(current_radius)
		
		if absf(current_radius - target_radius) < 0.2:
			current_radius = target_radius
			is_shrinking = false
			storm_shrink_completed.emit()

	# Tick damage calculation
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_storm_damage()

func _apply_storm_damage() -> void:
	var damage_amount: float = damage_per_second * tick_interval
	var combatants := get_tree().get_nodes_in_group("combatants")
	
	for c in combatants:
		if is_instance_valid(c) and (c is Node3D):
			var node3d := c as Node3D
			var dist := Vector2(node3d.global_position.x - global_position.x, node3d.global_position.z - global_position.z).length()
			if dist > current_radius:
				var hp: HealthComponent = node3d.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(damage_amount, self)

func _update_visual_radius(rad: float) -> void:
	if barrier_mesh:
		# Barrier is a cylinder mesh with default radius = 1.0
		barrier_mesh.scale.x = rad
		barrier_mesh.scale.z = rad
