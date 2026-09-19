class_name DragonDashBurstVFX
extends Node3D

## Volcanic Wing Burst Dash VFX
## Fiery shock ring, dark volcanic smoke, and molten embers erupting as wings thrust forward.

@onready var shock_ring: MeshInstance3D = $ShockRing
@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var sparks: GPUParticles3D = $Sparks

func _ready() -> void:
	if shock_ring:
		shock_ring.scale = Vector3(0.1, 0.1, 0.1)
		var dt := create_tween()
		dt.tween_property(shock_ring, "scale", Vector3(3.5, 0.8, 3.5), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if shock_ring.mesh and shock_ring.mesh.material:
			var mat: StandardMaterial3D = shock_ring.mesh.material.duplicate() as StandardMaterial3D
			shock_ring.material_override = mat
			dt.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	
	if omni_light:
		var ot := create_tween()
		ot.tween_property(omni_light, "light_energy", 0.0, 0.22)
	
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	get_tree().create_timer(0.35).timeout.connect(queue_free)
