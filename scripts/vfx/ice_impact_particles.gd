class_name IceImpactParticles
extends Node3D

## Self-destroying Ice Impact Effect
## Triggers crystalline frost burst and light pulse upon impact.

@onready var crystals: GPUParticles3D = $Crystals
@onready var shockwave: GPUParticles3D = $FrostRing
@onready var flash_light: OmniLight3D = $FlashLight

func _ready() -> void:
	if crystals:
		crystals.emitting = true
		crystals.finished.connect(_check_cleanup)
	if shockwave:
		shockwave.emitting = true
	if flash_light:
		var tween := create_tween()
		tween.tween_property(flash_light, "light_energy", 0.0, 0.22)
	
	get_tree().create_timer(0.8).timeout.connect(queue_free)

func _check_cleanup() -> void:
	queue_free()
