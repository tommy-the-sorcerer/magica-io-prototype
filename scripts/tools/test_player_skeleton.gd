extends SceneTree

func _init() -> void:
	var player_sc = load("res://scenes/player/player.tscn")
	if player_sc:
		var player = player_sc.instantiate() as CharacterBody3D
		root.add_child(player)
		print("=== PLAYER SCENE LOADED SUCCESSFULLY ===")
		var sk = player.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk:
			print("Skeleton found with %d bones" % sk.get_bone_count())
			# Test rotating bones
			var thigh_l = sk.find_bone("thigh.L")
			var thigh_r = sk.find_bone("thigh.R")
			var spine = sk.find_bone("spine")
			var chest = sk.find_bone("spine.003")
			var arm_l = sk.find_bone("upper_arm.L")
			var arm_r = sk.find_bone("upper_arm.R")
			print("thigh.L: %d, thigh.R: %d, spine: %d, chest: %d, arm.L: %d, arm.R: %d" % [thigh_l, thigh_r, spine, chest, arm_l, arm_r])
	quit(0)
