class_name ExplosionParticles
extends Node3D

## Self-destroying Explosion Visual Effect
## Automatically triggers particles, light flash, and frees itself upon completion.

@onready var embers: GPUParticles3D = $Embers
@onready var shockwave: GPUParticles3D = $Shockwave
@onready var flash_light: OmniLight3D = $FlashLight

func _ready() -> void:
	if embers:
		embers.emitting = true
		embers.finished.connect(_check_cleanup)
	if shockwave:
		shockwave.emitting = true
	
	if flash_light:
		var tween := create_tween()
		tween.tween_property(flash_light, "light_energy", 0.0, 0.25)
	
	# Safety timer fallback to guarantee cleanup
	get_tree().create_timer(0.85).timeout.connect(queue_free)

func _check_cleanup() -> void:
	queue_free()
