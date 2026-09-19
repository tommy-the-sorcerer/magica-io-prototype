extends SceneTree

func _init() -> void:
	var res = load("res://assets/models/Arcane_Apprentice_Rigged.glb")
	var inst = res.instantiate()
	
	var cube = inst.find_child("Cube", true, false) as MeshInstance3D
	if cube:
		print("Cube: visible=", cube.visible, " cast_shadow=", cube.cast_shadow)
		if cube.mesh:
			print("Cube mesh faces: ", cube.mesh.get_faces().size())
			var mat = cube.mesh.surface_get_material(0)
			if mat:
				print("Cube material: ", mat.resource_name, " class: ", mat.get_class())
				if mat is StandardMaterial3D:
					print("  Albedo texture: ", mat.albedo_texture)
					print("  Albedo color: ", mat.albedo_color)
					print("  Transparency: ", mat.transparency)

	var geom = inst.find_child("geometry_0_001", true, false) as MeshInstance3D
	if geom:
		print("geometry_0_001: visible=", geom.visible)
		if geom.mesh:
			print("geom mesh faces: ", geom.mesh.get_faces().size())
			var mat = geom.mesh.surface_get_material(0)
			if mat:
				print("geom material: ", mat.resource_name, " class: ", mat.get_class())
				if mat is StandardMaterial3D:
					print("  Albedo texture: ", mat.albedo_texture)
					print("  Albedo color: ", mat.albedo_color)
	
	inst.free()
	quit(0)
