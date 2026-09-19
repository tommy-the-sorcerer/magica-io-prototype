extends SceneTree

func _init() -> void:
	var res = load("res://assets/models/Arcane_Apprentice_Rigged.glb")
	var inst = res.instantiate()
	root.add_child(inst)
	
	var meshes = inst.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		print("Mesh: ", mi.name, " Global Transform: ", mi.global_transform, " AABB: ", mi.get_aabb())
		print("  Global AABB: ", mi.global_transform * mi.get_aabb())
		
	var sk = inst.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk:
		print("Skeleton found with ", sk.get_bone_count(), " bones")
		for b in range(sk.get_bone_count()):
			var bname = sk.get_bone_name(b)
			if "hand" in bname.to_lower() or "head" in bname.to_lower() or "foot" in bname.to_lower() or "staff" in bname.to_lower():
				print("  Bone [", b, "]: ", bname, " Rest: ", sk.get_bone_rest(b).origin)
				
	inst.free()
	quit(0)
