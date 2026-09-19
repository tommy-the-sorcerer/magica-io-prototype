extends SceneTree

func _init() -> void:
	print("=== RUNNING GAMEPLAY DIRECTIONAL CAPTURES ===")
	var arena_res = load("res://scenes/arena/arena.tscn")
	if not arena_res:
		quit(1)
		return
	var arena = arena_res.instantiate()
	root.add_child(arena)
	current_scene = arena
	
	var player = arena.find_child("Player", true, false) as PlayerController
	var camera = arena.find_child("Camera3D", true, false)
	
	var out_dir = "c:/Projects/ludosforge/assets/screenshots/movement_test"
	DirAccess.make_dir_recursive_absolute(out_dir)
	
	var dir_tests = [
		{"name": "move_W_forward", "input": Vector2(0, -1)},
		{"name": "move_S_backward", "input": Vector2(0, 1)},
		{"name": "move_A_left", "input": Vector2(-1, 0)},
		{"name": "move_D_right", "input": Vector2(1, 0)},
	]
	
	for test in dir_tests:
		var name_str: String = test["name"]
		var input_vec: Vector2 = test["input"]
		
		# Reset player pos
		if player:
			player.global_position = Vector3(0, 0.1, 0)
			player.velocity = Vector3(input_vec.x, 0, input_vec.y) * player.move_speed
			var target_yaw = atan2(-input_vec.x, -input_vec.y)
			player._current_body_yaw = target_yaw
			if player.visuals:
				player.visuals.rotation.y = target_yaw
		
		# Advance 20 frames
		for f in range(20):
			await process_frame
			
		var img = root.get_texture().get_image()
		if img:
			var path = "%s/%s.png" % [out_dir, name_str]
			img.save_png(path)
			print("[SAVED GAMEPLAY DIRECTION] -> %s" % path)
			
	print("=== ALL DIRECTIONAL CAPTURES COMPLETED ===")
	quit(0)
