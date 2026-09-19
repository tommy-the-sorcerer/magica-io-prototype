class_name DashBurstVFX
extends Node3D

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var shock_ring: MeshInstance3D = $ShockRing
@onready var light_shaft: MeshInstance3D = $LightShaft
@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var sparks: GPUParticles3D = $Sparks

func _ready() -> void:
	if audio_player:
		audio_player.pitch_scale = randf_range(0.98, 1.06)
		audio_player.play()
	
	if shock_ring:
		shock_ring.scale = Vector3(0.15, 0.15, 0.15)
		var dt := create_tween()
		dt.tween_property(shock_ring, "scale", Vector3(3.4, 1.2, 3.4), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if shock_ring.mesh and shock_ring.mesh.material:
			var mat: StandardMaterial3D = shock_ring.mesh.material.duplicate() as StandardMaterial3D
			shock_ring.material_override = mat
			dt.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	
	if light_shaft:
		var lt := create_tween()
		if light_shaft.mesh and light_shaft.mesh.material:
			var lmat: StandardMaterial3D = light_shaft.mesh.material.duplicate() as StandardMaterial3D
			light_shaft.material_override = lmat
			lt.tween_property(lmat, "albedo_color:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD)
		lt.parallel().tween_property(light_shaft, "scale:y", 2.2, 0.18)
	
	if omni_light:
		var ot := create_tween()
		ot.tween_property(omni_light, "light_energy", 0.0, 0.2)
	
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	get_tree().create_timer(0.55).timeout.connect(queue_free)
