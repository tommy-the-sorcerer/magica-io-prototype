extends SceneTree

func _init() -> void:
	var sc = load("res://assets/models/Arcane_Apprentice_Rigged.glb")
	if sc:
		var inst = sc.instantiate()
		var sk = inst.find_child("Skeleton3D", true, false) as Skeleton3D
		if not sk:
			sk = inst.find_child("GeneralSkeleton", true, false) as Skeleton3D
		if sk:
			var test_bones = ["spine", "spine.003", "upper_arm.L", "upper_arm.R", "thigh.L", "thigh.R", "shin.L", "shin.R", "spine.006"]
			for b_name in test_bones:
				var idx = sk.find_bone(b_name)
				if idx >= 0:
					var rest = sk.get_bone_rest(idx)
					print("Bone '%s' (idx %d): rest origin = %s, rest basis = %s" % [b_name, idx, rest.origin, rest.basis])
	quit(0)
