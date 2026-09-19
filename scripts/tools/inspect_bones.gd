extends SceneTree

func _init() -> void:
	var sc = load("res://assets/models/Arcane_Apprentice_Rigged.glb")
	if sc:
		var inst = sc.instantiate()
		var sk = inst.find_child("Skeleton3D", true, false) as Skeleton3D
		if not sk:
			sk = inst.find_child("GeneralSkeleton", true, false) as Skeleton3D
		if sk:
			print("=== SKELETON BONES (Total: %d) ===" % sk.get_bone_count())
			for i in range(sk.get_bone_count()):
				var b_name = sk.get_bone_name(i)
				var parent_idx = sk.get_bone_parent(i)
				var parent_name = sk.get_bone_name(parent_idx) if parent_idx >= 0 else "ROOT"
				print("[%d] %s (Parent: %s)" % [i, b_name, parent_name])
	quit(0)
