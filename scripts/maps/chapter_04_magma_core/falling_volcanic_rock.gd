class_name FallingVolcanicRock
extends Node3D

## Volcanic bomb that erupts out of the volcano crater in a high parabolic arc and explodes with AOE damage
@export var flight_duration: float = 1.8
@export var arc_height: float = 24.0
@export var impact_damage: float = 30.0
@export var impact_radius: float = 4.5
@export var knockback_force: float = 16.0

@onready var warning_decal: MeshInstance3D = $WarningDecal
@onready var rock_mesh: MeshInstance3D = $RockMesh
@onready var fire_trail: CPUParticles3D = $FireTrail

var start_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var is_in_flight: bool = false
var flight_progress: float = 0.0

func launch_arc(from_pos: Vector3, to_pos: Vector3, duration: float = 1.8) -> void:
	start_position = from_pos
	target_position = to_pos
	flight_duration = duration
	flight_progress = 0.0
	global_position = from_pos
	
	if warning_decal:
		warning_decal.top_level = true
		warning_decal.global_position = target_position + Vector3(0, 0.05, 0)
		warning_decal.scale = Vector3.ZERO
		var tw := create_tween()
		tw.tween_property(warning_decal, "scale", Vector3(1, 1, 1), flight_duration)
		
	if fire_trail:
		fire_trail.emitting = true
		
	is_in_flight = true

func launch_toward(target: Vector3) -> void:
	var volcano_pos := Vector3(0, 6.5, 0)
	launch_arc(volcano_pos, target, 1.8)

func _physics_process(delta: float) -> void:
	if not is_in_flight:
		return
		
	flight_progress += delta / flight_duration
	if flight_progress >= 1.0:
		global_position = target_position
		_explode()
		return
		
	var t: float = flight_progress
	var horizontal_pos: Vector3 = start_position.lerp(target_position, t)
	# Parabolic arc formula: 4 * h * t * (1 - t)
	var arc_y: float = 4.0 * arc_height * t * (1.0 - t)
	horizontal_pos.y += arc_y
	global_position = horizontal_pos
	
	if rock_mesh:
		rock_mesh.rotate_x(6.0 * delta)
		rock_mesh.rotate_y(4.0 * delta)

func _explode() -> void:
	is_in_flight = false
	if warning_decal:
		warning_decal.visible = false
	if rock_mesh:
		rock_mesh.visible = false
	if fire_trail:
		fire_trail.emitting = false
		
	# AOE Impact Damage
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = impact_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), target_position)
	query.collision_mask = 2 # Combatants
	
	var hits := space.intersect_shape(query, 16)
	for hit in hits:
		var collider: Node = hit.collider
		if collider and collider.is_in_group("combatants"):
			var hp: HealthComponent = collider.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(impact_damage, self)
			if collider is Node3D and "velocity" in collider:
				var push_dir: Vector3 = (collider.global_position - target_position)
				push_dir.y = 0.0
				collider.velocity += push_dir.normalized() * knockback_force + Vector3.UP * 7.0
				
	# Flash impact light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.4, 0.1)
	light.light_energy = 4.0
	light.omni_range = 8.0
	add_child(light)
	light.global_position = target_position + Vector3(0, 1.0, 0)
	
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.5)
	await tw.finished
	queue_free()
