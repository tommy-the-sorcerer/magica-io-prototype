class_name CelestialBeam
extends Projectile

## Heaven's Ascendant Solar Beam - Legendary Ascendant Projectile
## Flying golden solar comet orb with brilliant sun core, dual rotating celestial gyro rings,
## a trailing comet teardrop cone, and an epic 15-meter streaming golden tail!

@onready var core_mesh: MeshInstance3D = find_child("CoreOrb", true, false) as MeshInstance3D
@onready var corona_mesh: MeshInstance3D = find_child("CoronaAura", true, false) as MeshInstance3D
@onready var ring_h: MeshInstance3D = find_child("RingH", true, false) as MeshInstance3D
@onready var ring_v: MeshInstance3D = find_child("RingV", true, false) as MeshInstance3D
@onready var omni_light: OmniLight3D = find_child("OmniLight3D", true, false) as OmniLight3D

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if _has_exploded:
		return
	
	var time_ms := Time.get_ticks_msec()
	
	# Animate rotating celestial gyro rings
	if ring_h:
		ring_h.rotation.z += 8.5 * delta
		ring_h.rotation.y += 5.5 * delta
	if ring_v:
		ring_v.rotation.x += 10.5 * delta
		ring_v.rotation.z -= 6.5 * delta
		
	# Celestial core and corona pulsation
	var pulse: float = 1.0 + sin(time_ms * 0.012) * 0.08
	if core_mesh:
		core_mesh.scale = Vector3(pulse, pulse, pulse)
	if corona_mesh:
		var corona_pulse: float = 1.0 + sin(time_ms * 0.015 + 1.2) * 0.12
		corona_mesh.scale = Vector3(corona_pulse, corona_pulse, corona_pulse)
		
	# Dynamic golden solar luminescence
	if omni_light:
		omni_light.light_energy = 4.2 + sin(time_ms * 0.02) * 0.7
