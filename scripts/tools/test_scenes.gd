extends SceneTree

func _init() -> void:
	print("--- SCENE VALIDATION TEST START ---")
	var test_scenes := [
		"res://scenes/ui/character_showcase_3d.tscn",
		"res://scenes/ui/character_preview_screen.tscn",
		"res://scenes/ui/home_screen.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/arena/arena.tscn"
	]
	
	var all_ok := true
	for path in test_scenes:
		print("Testing scene load: ", path)
		var res = load(path)
		if res == null:
			printerr("FAILED to load scene: ", path)
			all_ok = false
			continue
		var instance = res.instantiate()
		if instance == null:
			printerr("FAILED to instantiate scene: ", path)
			all_ok = false
			continue
		print("  -> OK: Instantiated ", instance.name, " (Type: ", instance.get_class(), ")")
		instance.free()
	
	if all_ok:
		print("--- ALL SCENES LOADED AND INSTANTIATED SUCCESSFULLY! ---")
	else:
		printerr("--- SOME SCENES FAILED VALIDATION! ---")
	quit(0 if all_ok else 1)
