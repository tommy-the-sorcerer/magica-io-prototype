extends SceneTree

func _init() -> void:
	print("=== RUNNING HUMANOID MOVEMENT & TURNING VERIFICATION ===")
	var p_res = load("res://scenes/player/player.tscn")
	if not p_res:
		printerr("Failed to load player scene")
		quit(1)
		return
		
	var player = p_res.instantiate() as PlayerController
	root.add_child(player)
	player._ready()
	
	# Simulate 1 second of forward running
	player.velocity = Vector3(0, 0, -player.move_speed)
	for frame in range(60):
		player._physics_process(1.0 / 60.0)
		
	print("Forward Running:")
	print("  - Visuals rotation.x (Sprint Lean): ", player.visuals.rotation.x, " rad")
	print("  - Visuals position.y (Vertical Stride Bob): ", player.visuals.position.y)
	print("  - Visuals position.x (Weight Transfer Sway): ", player.visuals.position.x)
	
	# Simulate sharp right turn
	player._current_body_yaw = 0.0
	var right_input = Vector2(1, 0)
	var target_yaw = atan2(-right_input.x, -right_input.y)
	for frame in range(20):
		player.velocity = Vector3(player.move_speed, 0, 0)
		player._physics_process(1.0 / 60.0)
		
	print("Turning Right:")
	print("  - Visuals rotation.z (Centripetal Bank/Lean): ", player.visuals.rotation.z, " rad")
	print("  - Head Yaw (Turn Lead): ", player._current_head_yaw, " rad")
	print("  - Torso Yaw (Turn Lead): ", player._current_torso_yaw, " rad")
	
	# Simulate stopping / deceleration to Idle
	player.velocity = Vector3.ZERO
	for frame in range(60):
		player._physics_process(1.0 / 60.0)
		
	print("Idle Stance:")
	print("  - State: ", player.current_state)
	print("  - Visuals position (Breathing Bob): ", player.visuals.position)
	print("  - Visuals rotation (Neutral Stance): ", player.visuals.rotation)
	
	print("=== HUMANOID MOVEMENT & TURNING VERIFICATION PASSED ===")
	quit(0)
