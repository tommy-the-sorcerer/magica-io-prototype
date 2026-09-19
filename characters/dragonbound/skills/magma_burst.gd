class_name MagmaBurst
extends Projectile

## Volcanic Magma Burst Projectile [RMB]
## Heavy explosive draconic fire orb that detonates with massive AoE blast.

@onready var core_mesh: MeshInstance3D = find_child("Core", true, false) as MeshInstance3D
@onready var orb_light: OmniLight3D = find_child("OrbLight", true, false) as OmniLight3D

func _ready() -> void:
	super._ready()
	speed = 20.0
	lifetime = 0.9
	damage = 38.0
	is_aoe = true
	aoe_radius = 4.2
	knockback_force = 18.0
	
	if not explosion_vfx_scene:
		explosion_vfx_scene = load("res://characters/dragonbound/vfx/dragon_impact.tscn")

func _process(delta: float) -> void:
	if core_mesh:
		core_mesh.rotation.y += 8.0 * delta
		core_mesh.rotation.x += 6.0 * delta
	if orb_light:
		orb_light.light_energy = 4.0 + sin(Time.get_ticks_msec() * 0.015) * 0.8
