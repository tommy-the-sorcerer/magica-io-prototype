class_name ForestStorm
extends BaseStorm

## Chapter 1 Supernatural Forest Storm with leaf particles and electric cyan/purple ring

@onready var leaf_particles: GPUParticles3D = $LeafParticles
@onready var inner_energy_ring: MeshInstance3D = $InnerEnergyRing

func _ready() -> void:
	super._ready()
	start_radius = 48.0
	min_radius = 8.0
	damage_per_second = 6.0
	current_radius = start_radius
	target_radius = start_radius

func _update_visual_radius(rad: float) -> void:
	super._update_visual_radius(rad)
	if inner_energy_ring:
		inner_energy_ring.scale.x = rad
		inner_energy_ring.scale.z = rad
	if leaf_particles:
		# Adjust particle emitter radius as storm contracts
		leaf_particles.position.y = 1.5
