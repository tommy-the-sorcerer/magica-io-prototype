class_name ElectroBlastSpell
extends Projectile

## Crackling Blue Lightning Plasma Orb - Arcane Apprentice Basic Attack
@onready var core_mesh: MeshInstance3D = find_child("CoreMesh", true, false) as MeshInstance3D
@onready var ring_mesh: MeshInstance3D = find_child("RingMesh", true, false) as MeshInstance3D
@onready var omni_light: OmniLight3D = find_child("OmniLight3D", true, false) as OmniLight3D

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if _has_exploded:
		return
	
	var time_ms := Time.get_ticks_msec()
	
	if ring_mesh:
		ring_mesh.rotation.z += 12.0 * delta
		ring_mesh.rotation.x += 8.0 * delta
	
	if core_mesh:
		var pulse: float = 1.0 + sin(time_ms * 0.02) * 0.1
		core_mesh.scale = Vector3(pulse, pulse, pulse)
	
	if omni_light:
		omni_light.light_energy = 2.5 + sin(time_ms * 0.025) * 0.5
