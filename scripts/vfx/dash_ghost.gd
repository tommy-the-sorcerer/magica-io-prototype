class_name DashGhost
extends Node3D

## Luminous Seraph Holographic Afterimage
## Features full angelic silhouette, additive chromatic glow, and smooth dissolve dissipation.

@export var ghost_color: Color = Color(0.3, 0.85, 1.0, 0.8)

@onready var mesh_instances: Array[Node] = []

func _ready() -> void:
	# Collect all mesh instances inside this ghost
	mesh_instances = find_children("*", "MeshInstance3D", true, false)
	
	# Apply unique additive material with chromatic tint to all meshes
	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.blend_mode = StandardMaterial3D.BLEND_MODE_ADD
	ghost_mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	ghost_mat.albedo_color = ghost_color
	
	for m in mesh_instances:
		if m is MeshInstance3D:
			(m as MeshInstance3D).material_override = ghost_mat
	
	# Dissolve & dissipate animation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost_mat, "albedo_color:a", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.12, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Halo spin during dissolve if present
	var ghost_halo: Node3D = find_child("Halo", true, false) as Node3D
	if ghost_halo:
		tween.tween_property(ghost_halo, "rotation:y", ghost_halo.rotation.y + 1.8, 0.28)
	
	tween.chain().tween_callback(queue_free)

## Configure chromatic color before adding to tree
func setup_color(tint: Color) -> void:
	ghost_color = tint
