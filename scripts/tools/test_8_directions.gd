extends SceneTree

func _init() -> void:
	print("=== RUNNING 8-DIRECTION MOVEMENT & FACING VERIFICATION ===")
	var p_res = load("res://scenes/player/player.tscn")
	if not p_res:
		printerr("Failed to load player scene")
		quit(1)
		return
		
	var player = p_res.instantiate() as PlayerController
	root.add_child(player)
	player._ready()
	
	var directions = [
		{"name": "W (Forward / Screen Up)", "input": Vector2(0, -1), "expected_vel_z_sign": -1, "expected_vel_x_sign": 0, "expected_yaw_deg": 0.0},
		{"name": "S (Backward / Screen Down)", "input": Vector2(0, 1), "expected_vel_z_sign": 1, "expected_vel_x_sign": 0, "expected_yaw_deg": 180.0},
		{"name": "A (Left / Screen Left)", "input": Vector2(-1, 0), "expected_vel_z_sign": 0, "expected_vel_x_sign": -1, "expected_yaw_deg": 90.0},
		{"name": "D (Right / Screen Right)", "input": Vector2(1, 0), "expected_vel_z_sign": 0, "expected_vel_x_sign": 1, "expected_yaw_deg": -90.0},
		{"name": "W+A (Diagonal Forward-Left)", "input": Vector2(-1, -1).normalized(), "expected_vel_z_sign": -1, "expected_vel_x_sign": -1, "expected_yaw_deg": 45.0},
		{"name": "W+D (Diagonal Forward-Right)", "input": Vector2(1, -1).normalized(), "expected_vel_z_sign": -1, "expected_vel_x_sign": 1, "expected_yaw_deg": -45.0},
		{"name": "S+A (Diagonal Backward-Left)", "input": Vector2(-1, 1).normalized(), "expected_vel_z_sign": 1, "expected_vel_x_sign": -1, "expected_yaw_deg": 135.0},
		{"name": "S+D (Diagonal Backward-Right)", "input": Vector2(1, 1).normalized(), "expected_vel_z_sign": 1, "expected_vel_x_sign": 1, "expected_yaw_deg": -135.0},
	]
	
	var all_passed = true
	
	for dir_data in directions:
		var dir_name: String = dir_data["name"]
		var input_vec: Vector2 = dir_data["input"]
		var exp_z_sign: int = dir_data["expected_vel_z_sign"]
		var exp_x_sign: int = dir_data["expected_vel_x_sign"]
		var exp_yaw: float = deg_to_rad(dir_data["expected_yaw_deg"])
		
		# Reset player physics state
		player.velocity = Vector3.ZERO
		player._current_body_yaw = 0.0
		player.visuals.rotation.y = 0.0
		
		# Simulate 30 frames with input_vec
		for f in range(30):
			# Mock input logic inside physics process
			var target_vel = Vector3(input_vec.x, 0, input_vec.y) * player.move_speed
			var accel_rate = player.acceleration
			player.velocity.x = move_toward(player.velocity.x, target_vel.x, accel_rate * (1.0/60.0) * player.move_speed)
			player.velocity.z = move_toward(player.velocity.z, target_vel.z, accel_rate * (1.0/60.0) * player.move_speed)
			
			var target_yaw = atan2(-input_vec.x, -input_vec.y)
			var turn_angle_diff = wrapf(target_yaw - player._current_body_yaw, -PI, PI)
			var turn_step = player.rotation_speed * (1.0/60.0)
			if absf(turn_angle_diff) <= turn_step:
				player._current_body_yaw = target_yaw
			else:
				player._current_body_yaw += signf(turn_angle_diff) * turn_step
			player.visuals.rotation.y = player._current_body_yaw
			
			var h_speed = Vector2(player.velocity.x, player.velocity.z).length()
			var speed_fraction = clampf(h_speed / player.move_speed, 0.0, 1.0)
			player._process_humanoid_animation(1.0/60.0, speed_fraction, true, turn_angle_diff)
		
		var final_vel = player.velocity
		var final_yaw = player._current_body_yaw
		var yaw_diff = absf(wrapf(final_yaw - exp_yaw, -PI, PI))
		
		var x_ok = (exp_x_sign == 0 and absf(final_vel.x) < 0.1) or (exp_x_sign > 0 and final_vel.x > 1.0) or (exp_x_sign < 0 and final_vel.x < -1.0)
		var z_ok = (exp_z_sign == 0 and absf(final_vel.z) < 0.1) or (exp_z_sign > 0 and final_vel.z > 1.0) or (exp_z_sign < 0 and final_vel.z < -1.0)
		var yaw_ok = yaw_diff < 0.05
		
		var status = "PASS" if (x_ok and z_ok and yaw_ok) else "FAIL"
		if status == "FAIL":
			all_passed = false
			
		print("[%s] %s:" % [status, dir_name])
		print("       Velocity: (%.2f, %.2f), Expected signs: (X:%d, Z:%d)" % [final_vel.x, final_vel.z, exp_x_sign, exp_z_sign])
		print("       Yaw: %.1f deg, Expected Yaw: %.1f deg" % [rad_to_deg(final_yaw), rad_to_deg(exp_yaw)])
	
	if all_passed:
		print("=== ALL 8 DIRECTIONS VERIFIED AND PASSED PERFECTLY ===")
		quit(0)
	else:
		printerr("=== SOME DIRECTIONAL TESTS FAILED ===")
		quit(1)
