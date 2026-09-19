extends SceneTree

func _init() -> void:
	print("=== RENDERING 360° CHARACTER SHOWCASE VIEWS ===")
	var showcase_res = load("res://scenes/ui/character_showcase_3d.tscn")
	if showcase_res == null:
		printerr("Failed to load showcase scene!")
		quit(1)
		return
		
	var showcase = showcase_res.instantiate()
	
	var viewport = SubViewport.new()
	viewport.size = Vector2i(720, 960)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(showcase)
	
	var angles = [
		["front", 0.0],
		["left_profile", deg_to_rad(90.0)],
		["back", deg_to_rad(180.0)],
		["right_profile", deg_to_rad(270.0)],
		["diagonal_front_left", deg_to_rad(45.0)],
		["diagonal_front_right", deg_to_rad(315.0)]
	]
	
	var out_dir = "c:/Projects/ludosforge/assets/screenshots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	
	for item in angles:
		var view_name: String = item[0]
		var angle: float = item[1]
		if showcase.character_pivot:
			showcase.character_pivot.rotation.y = angle
		
		var img = viewport.get_texture().get_image()
		if img:
			var path = "%s/character_%s.png" % [out_dir, view_name]
			var err = img.save_png(path)
			if err == OK:
				print("[SAVED] %s -> %s" % [view_name, path])
			else:
				printerr("Error saving image: ", err)
	
	print("=== RENDER COMPLETE ===")
	quit(0)
