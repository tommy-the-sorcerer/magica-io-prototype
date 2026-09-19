extends Node

var angles = [
	["front", 0.0],
	["diagonal_front_left", deg_to_rad(45.0)],
	["left_profile", deg_to_rad(90.0)],
	["back", deg_to_rad(180.0)],
	["right_profile", deg_to_rad(270.0)],
	["diagonal_front_right", deg_to_rad(315.0)]
]
var current_idx = 0
var frame_count = 0
var showcase: Node3D = null

func _ready() -> void:
	print("=== RUNNING LIVE SHOWCASE VIEW CAPTURE ===")
	var sc_res = load("res://scenes/ui/character_showcase_3d.tscn")
	if sc_res:
		showcase = sc_res.instantiate()
		add_child(showcase)
		if showcase.has_node("Pedestal/RunicRing"):
			showcase.get_node("Pedestal/RunicRing").visible = true

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count % 10 == 0 and current_idx < angles.size():
		var item = angles[current_idx]
		var view_name: String = item[0]
		var angle: float = item[1]
		if showcase and showcase.character_pivot:
			showcase.character_pivot.rotation.y = angle
			
		var img = get_viewport().get_texture().get_image()
		if img:
			var out_dir = "c:/Projects/ludosforge/assets/screenshots"
			DirAccess.make_dir_recursive_absolute(out_dir)
			var path = "%s/character_%s.png" % [out_dir, view_name]
			var err = img.save_png(path)
			if err == OK:
				print("[SAVED FRAME] %s -> %s" % [view_name, path])
		current_idx += 1
	elif current_idx >= angles.size() and frame_count > 80:
		print("=== ALL VIEWS CAPTURED SUCCESSFULLY ===")
		get_tree().quit(0)
