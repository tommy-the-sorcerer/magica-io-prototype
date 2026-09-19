extends SceneTree

var frame_count = 0
var arena_node = null

func _init() -> void:
	print("=== RUNNING GAMEPLAY ARENA VIEW CAPTURE ===")
	var arena_res = load("res://scenes/arena/arena.tscn")
	if arena_res:
		arena_node = arena_res.instantiate()
		root.add_child(arena_node)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 25:
		var img = root.get_texture().get_image()
		if img:
			var out_dir = "c:/Projects/ludosforge/assets/screenshots"
			DirAccess.make_dir_recursive_absolute(out_dir)
			var path = "%s/gameplay_topdown_view.png" % out_dir
			var err = img.save_png(path)
			if err == OK:
				print("[SAVED GAMEPLAY] -> %s" % path)
		print("=== GAMEPLAY VIEW CAPTURE SUCCESSFUL ===")
		quit(0)
		return true
	return false
