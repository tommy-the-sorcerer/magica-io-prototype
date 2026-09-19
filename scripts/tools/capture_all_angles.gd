extends SceneTree

func _init() -> void:
	print("=== RUNNING 360-DEGREE ANGLE CAPTURE ===")
	var sc_res = load("res://scenes/ui/character_showcase_3d.tscn")
	if not sc_res:
		quit(1)
		return
	var showcase = sc_res.instantiate()
	root.add_child(showcase)
	
	var out_dir = "c:/Projects/ludosforge/assets/screenshots/angles"
	DirAccess.make_dir_recursive_absolute(out_dir)
	
	for deg in range(0, 360, 30):
		var rad = deg_to_rad(deg)
		showcase._current_yaw = rad
		showcase._target_yaw = rad
		if showcase.character_pivot:
			showcase.character_pivot.rotation.y = rad
		
		# Wait 2 frames for render
		for i in range(2):
			await process_frame
		
		var img = root.get_texture().get_image()
		if img:
			var path = "%s/angle_%03d.png" % [out_dir, deg]
			img.save_png(path)
			print("[SAVED] Angle %d deg -> %s" % [deg, path])
			
	print("=== ALL 12 ANGLES SAVED ===")
	quit(0)
