class_name ElectroImpactVFX
extends Node3D

@onready var sparks: GPUParticles3D = $Sparks
@onready var shock_ring: MeshInstance3D = $ShockRing
@onready var omni_light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	if shock_ring:
		shock_ring.scale = Vector3(0.2, 0.2, 0.2)
		var dt := create_tween()
		dt.tween_property(shock_ring, "scale", Vector3(1.8, 1.8, 1.8), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if shock_ring.mesh and shock_ring.mesh.material:
			var mat: StandardMaterial3D = shock_ring.mesh.material.duplicate() as StandardMaterial3D
			shock_ring.material_override = mat
			dt.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.18)
	
	if omni_light:
		var ot := create_tween()
		ot.tween_property(omni_light, "light_energy", 0.0, 0.2)
	
	# Camera zap punch
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.12)
	
	get_tree().create_timer(0.45).timeout.connect(queue_free)
