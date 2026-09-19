class_name CelestialImpactVFX
extends Node3D

## AAA Unreal-Quality Celestial Judgement Beam Impact VFX
## Features dual shockwave rings, radial solar godray spikes, molten sparks, supernova core, and stardust embers.

@onready var shockwave_h: GPUParticles3D = find_child("ShockwaveH", true, false) as GPUParticles3D
@onready var shockwave_v: GPUParticles3D = find_child("ShockwaveV", true, false) as GPUParticles3D
@onready var radial_rays: GPUParticles3D = find_child("RadialRays", true, false) as GPUParticles3D
@onready var sparks: GPUParticles3D = find_child("Sparks", true, false) as GPUParticles3D
@onready var light_dust: GPUParticles3D = find_child("LightDust", true, false) as GPUParticles3D
@onready var core_flash: MeshInstance3D = find_child("CoreFlash", true, false) as MeshInstance3D
@onready var ground_rune: MeshInstance3D = find_child("GroundRune", true, false) as MeshInstance3D
@onready var flash_light: OmniLight3D = find_child("FlashLight", true, false) as OmniLight3D

func _ready() -> void:
	# Trigger all GPU particle systems
	if shockwave_h:
		shockwave_h.restart()
		shockwave_h.emitting = true
	if shockwave_v:
		shockwave_v.restart()
		shockwave_v.emitting = true
	if radial_rays:
		radial_rays.restart()
		radial_rays.emitting = true
	if sparks:
		sparks.restart()
		sparks.emitting = true
	if light_dust:
		light_dust.restart()
		light_dust.emitting = true
	
	# Animate core flash expansion and fade
	if core_flash:
		core_flash.scale = Vector3(0.2, 0.2, 0.2)
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(core_flash, "scale", Vector3(2.2, 2.2, 2.2), 0.12)
		flash_tween.parallel().tween_property(core_flash, "transparency", 1.0, 0.18)
	
	# Animate ground rune
	if ground_rune:
		ground_rune.scale = Vector3(0.5, 0.5, 0.5)
		var rune_tween: Tween = create_tween()
		rune_tween.tween_property(ground_rune, "scale", Vector3(1.8, 1.8, 1.8), 0.15)
		rune_tween.tween_interval(0.2)
		rune_tween.tween_property(ground_rune, "transparency", 1.0, 0.3)
	
	# Animate light fade
	if flash_light:
		var light_tween: Tween = create_tween()
		light_tween.tween_property(flash_light, "light_energy", 0.0, 0.28)
	
	# Screenshake on impact
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.32)
	
	get_tree().create_timer(0.75).timeout.connect(queue_free)
