class_name ElectroDashGhost
extends Node3D

## Blue Lightning Apprentice Hologram Afterimage
@export var ghost_color: Color = Color(0.2, 0.8, 1.0, 0.85)

func _ready() -> void:
	var mesh_instances: Array[Node] = find_children("*", "MeshInstance3D", true, false)
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = StandardMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	mat.albedo_color = ghost_color
	
	for m in mesh_instances:
		if m is MeshInstance3D:
			(m as MeshInstance3D).material_override = mat
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.08, 0.25)
	tween.chain().tween_callback(queue_free)
