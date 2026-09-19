class_name CelestialDashArrivalVFX
extends Node3D

@onready var brake_ring: MeshInstance3D = $BrakeRing
@onready var feathers: GPUParticles3D = $Feathers
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	if audio_player:
		audio_player.pitch_scale = randf_range(1.35, 1.45)
		audio_player.play()
	
	if brake_ring:
		brake_ring.scale = Vector3(0.3, 0.3, 0.3)
		var dt := create_tween()
		dt.tween_property(brake_ring, "scale", Vector3(2.6, 0.8, 2.6), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if brake_ring.mesh and brake_ring.mesh.material:
			var mat: StandardMaterial3D = brake_ring.mesh.material.duplicate() as StandardMaterial3D
			brake_ring.material_override = mat
			dt.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	
	if feathers:
		feathers.restart()
		feathers.emitting = true
	
	get_tree().create_timer(0.45).timeout.connect(queue_free)
