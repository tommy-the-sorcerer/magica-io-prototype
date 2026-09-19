class_name DragonImpactVFX
extends Node3D

## Cataclysmic Dragon Hellfire Impact VFX
## Features explosive magma burst, scorched ground ring, radial molten embers, and dark smoke.

@onready var flash_light: OmniLight3D = $FlashLight
@onready var core_burst: MeshInstance3D = $CoreBurst
@onready var shockwave: MeshInstance3D = $Shockwave
@onready var sparks: GPUParticles3D = $Sparks
@onready var smoke: GPUParticles3D = $Smoke

func _ready() -> void:
	if sparks:
		sparks.restart()
		sparks.emitting = true
	if smoke:
		smoke.restart()
		smoke.emitting = true
	
	# Light flash pulse
	if flash_light:
		flash_light.light_energy = 5.0
		var lt := create_tween()
		lt.tween_property(flash_light, "light_energy", 0.0, 0.28)
	
	# Expanding fiery core
	if core_burst:
		core_burst.scale = Vector3(0.3, 0.3, 0.3)
		var ct := create_tween()
		ct.tween_property(core_burst, "scale", Vector3(2.4, 2.4, 2.4), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(core_burst, "transparency", 1.0, 0.18)
	
	# Expanding horizontal shockwave
	if shockwave:
		shockwave.scale = Vector3(0.2, 0.2, 0.2)
		var st := create_tween()
		st.tween_property(shockwave, "scale", Vector3(3.2, 3.2, 3.2), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(shockwave, "transparency", 1.0, 0.22)
		st.chain().tween_callback(queue_free)
	else:
		get_tree().create_timer(0.4).timeout.connect(queue_free)
