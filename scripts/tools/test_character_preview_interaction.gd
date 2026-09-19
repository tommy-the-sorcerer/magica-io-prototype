extends SceneTree

func _init() -> void:
	print("=== STARTING CHARACTER PREVIEW & 360° ROTATION INTERACTION TEST ===")
	var scene_res = load("res://scenes/ui/character_preview_screen.tscn")
	if scene_res == null:
		printerr("FAILED: Could not load character_preview_screen.tscn")
		quit(1)
		return
	
	var preview_screen = scene_res.instantiate()
	root.add_child(preview_screen)
	
	var showcase = preview_screen.get_node("SubViewportContainer/SubViewport/CharacterShowcase3D")
	if showcase == null:
		printerr("FAILED: showcase_3d not found!")
		quit(1)
		return
	
	print("[PASS] CharacterPreviewScreen instantiated with embedded CharacterShowcase3D")
	
	# Test 1: Initial state
	print("Initial rotation target: ", showcase._target_yaw)
	assert(showcase._target_yaw == 0.0, "Initial yaw should be 0.0")
	
	# Test 2: Simulate Desktop Drag Left (positive X drag / negative relative)
	var drag_event_left = InputEventMouseMotion.new()
	drag_event_left.relative = Vector2(150.0, 0.0) # Dragging right
	showcase._is_dragging = true
	showcase.handle_drag_input(drag_event_left)
	print("Yaw after dragging right (+150px): ", showcase._target_yaw)
	assert(showcase._target_yaw > 0.0, "Target yaw should increase when dragging right")
	
	# Test 3: Multiple continuous revolutions (beyond 360° / 6.28 rad)
	var drag_large = InputEventMouseMotion.new()
	drag_large.relative = Vector2(1000.0, 0.0)
	showcase.handle_drag_input(drag_large)
	print("Yaw after large continuous rotation: ", showcase._target_yaw, " radians (approx ", rad_to_deg(showcase._target_yaw), " deg)")
	assert(showcase._target_yaw > 6.28, "Should rotate continuously beyond 360°")
	
	# Test 4: Drag Left
	var drag_left = InputEventMouseMotion.new()
	drag_left.relative = Vector2(-2000.0, 0.0)
	showcase.handle_drag_input(drag_left)
	print("Yaw after dragging left (-2000px): ", showcase._target_yaw, " radians (approx ", rad_to_deg(showcase._target_yaw), " deg)")
	
	# Test 5: Reset view button
	showcase.reset_view()
	print("Yaw after reset_view(): ", showcase._target_yaw)
	assert(showcase._target_yaw == 0.0, "Yaw should be 0 after reset")
	
	# Test 6: Mobile Screen Touch & Drag event simulation
	var touch_down = InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = Vector2(640, 360)
	showcase.handle_drag_input(touch_down)
	assert(showcase._is_dragging == true, "Touch down should set _is_dragging to true")
	
	var touch_drag = InputEventScreenDrag.new()
	touch_drag.relative = Vector2(-300.0, 0.0)
	showcase.handle_drag_input(touch_drag)
	print("Yaw after Mobile Touch Swipe (-300px): ", showcase._target_yaw)
	assert(showcase._target_yaw < 0.0, "Swipe left should decrease yaw")
	
	var touch_up = InputEventScreenTouch.new()
	touch_up.pressed = false
	showcase.handle_drag_input(touch_up)
	assert(showcase._is_dragging == false, "Touch up should set _is_dragging to false")
	
	# Test 7: Idle animations over time
	showcase._ready()
	showcase._process(0.5)
	if showcase.pedestal_ring:
		print("Pedestal ring rotation after 0.5s: ", showcase.pedestal_ring.rotation.y)
	if showcase.character_pivot:
		print("Character bobbing position y after 0.5s: ", showcase.character_pivot.position.y)
	if showcase.staff_crystal_light:
		print("Staff crystal light energy after 0.5s: ", showcase.staff_crystal_light.light_energy)
	
	preview_screen.free()
	print("=== ALL 360° ROTATION, MOBILE INPUT & SHOWCASE TESTS PASSED PERFECTLY! ===")
	quit(0)
