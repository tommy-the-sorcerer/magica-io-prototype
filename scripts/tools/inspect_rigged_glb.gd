extends SceneTree

func _init() -> void:
	print("=== DETAILED INSPECTION OF Arcane_Apprentice_Rigged.glb ===")
	var glb_path = "res://assets/models/Arcane_Apprentice_Rigged.glb"
	var res = load(glb_path)
	var inst = res.instantiate()
	
	# Find AnimationPlayers
	var anim_players = inst.find_children("*", "AnimationPlayer", true, false)
	print("AnimationPlayers found: ", anim_players.size())
	for ap in anim_players:
		print("  - ", ap.name, " Animations: ", (ap as AnimationPlayer).get_animation_list())
	
	# Find Skeletons
	var skeletons = inst.find_children("*", "Skeleton3D", true, false)
	print("Skeletons found: ", skeletons.size())
	for sk in skeletons:
		print("  - ", sk.name, " (Bones: ", (sk as Skeleton3D).get_bone_count(), ")")
	
	# Find Meshes & Materials
	var meshes = inst.find_children("*", "MeshInstance3D", true, false)
	print("MeshInstance3Ds found: ", meshes.size())
	for m in meshes:
		var mi := m as MeshInstance3D
		var mat_names = []
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(s)
				mat_names.append(mat.resource_name if mat else "null")
		print("  - ", mi.name, " (Surfaces: ", mi.mesh.get_surface_count() if mi.mesh else 0, ", Mats: ", mat_names, ", Skin: ", mi.skin != null, ")")
		
	# Check AABB / bounding size
	var aabb: AABB = AABB()
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh:
			aabb = aabb.merge(mi.get_aabb())
	print("Total Model AABB: ", aabb)
	print("Model Height approx: ", aabb.size.y, " (Position: ", aabb.position, ")")
	
	inst.free()
	quit(0)
