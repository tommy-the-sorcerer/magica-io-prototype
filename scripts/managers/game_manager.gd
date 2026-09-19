class_name GameManager
extends Node

## Manages Match Spawns, Combatant Tracking, Surrounding Forest Environment,
## Kill Feed, and Victory/Defeat Conditions.

@export var bot_scene: PackedScene
@export var bot_spawn_count: int = 14
@export var spawn_radius: float = 24.0

var total_combatants: int = 15
var alive_combatants: int = 15
var player_node: Node3D = null
var hud: HUD = null

func _ready() -> void:
	if LevelManager.instance:
		var cfg: Dictionary = LevelManager.instance.get_level_config(LevelManager.instance.current_level_id)
		bot_spawn_count = cfg.get("enemy_count", bot_spawn_count)
		
	total_combatants = bot_spawn_count + 1
	alive_combatants = total_combatants
	
	# Find HUD
	hud = get_tree().current_scene.find_child("HUD", true, false) as HUD
	if hud:
		hud.update_alive_count(alive_combatants, total_combatants)
		
	# Find or spawn Player according to selected hero
	var existing_player := get_tree().current_scene.find_child("Player", true, false) as Node3D
	var selected_scene: PackedScene = LevelManager.instance.get_selected_player_scene() if (LevelManager.instance and LevelManager.instance.has_method("get_selected_player_scene")) else null
	if selected_scene and existing_player and existing_player.scene_file_path != selected_scene.resource_path:
		var pos: Vector3 = existing_player.global_position
		var rot: Vector3 = existing_player.rotation
		var p_parent: Node = existing_player.get_parent()
		existing_player.name = "Player_Old"
		existing_player.queue_free()
		
		var new_player := selected_scene.instantiate() as Node3D
		new_player.name = "Player"
		p_parent.add_child(new_player)
		new_player.global_position = pos
		new_player.rotation = rot
		player_node = new_player
	else:
		player_node = existing_player

	if player_node:
		var cam := get_tree().current_scene.find_child("Camera3D", true, false)
		if cam and cam.has_method("set"):
			cam.set("target", player_node)
		var hp_comp: HealthComponent = player_node.find_child("HealthComponent", true, false) as HealthComponent
		if hp_comp:
			hp_comp.died.connect(_on_player_died)
			hp_comp.health_changed.connect(func(curr, max_hp): if hud: hud.update_player_hp(curr, max_hp))
	
	call_deferred("_spawn_surrounding_trees")
	call_deferred("_spawn_bots")

func _spawn_surrounding_trees() -> void:
	var arena_root := get_tree().current_scene
	if not arena_root:
		return
		
	var trees_parent := arena_root.find_child("Trees", true, false)
	if not trees_parent:
		trees_parent = Node3D.new()
		trees_parent.name = "Trees"
		arena_root.add_child(trees_parent)
		
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 1.4
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
	
	var leaves_mesh := PrismMesh.new()
	leaves_mesh.size = Vector3(2.6, 3.4, 2.6)
	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.25, 0.62, 0.38)
	
	# Create ring of 24 surrounding trees around perimeter
	for i in range(24):
		var angle: float = (float(i) / 24.0) * TAU
		var dist: float = randf_range(22.0, 36.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var tree_node := Node3D.new()
		tree_node.position = pos
		var s := randf_range(0.85, 1.35)
		tree_node.scale = Vector3(s, s, s)
		
		var trunk := MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position = Vector3(0, 0.7, 0)
		trunk.set_surface_override_material(0, trunk_mat)
		tree_node.add_child(trunk)
		
		var leaves := MeshInstance3D.new()
		leaves.mesh = leaves_mesh
		leaves.position = Vector3(0, 2.4, 0)
		leaves.set_surface_override_material(0, leaves_mat)
		tree_node.add_child(leaves)
		
		trees_parent.add_child(tree_node)

func _spawn_bots() -> void:
	if not bot_scene:
		bot_scene = load("res://scenes/bots/bot.tscn")
		
	if not bot_scene:
		push_warning("Bot scene not found!")
		return
		
	for i in range(bot_spawn_count):
		var bot: BotAI = bot_scene.instantiate() as BotAI
		get_tree().current_scene.add_child(bot)
		
		# Place in a ring around the map
		var angle: float = (float(i) / float(bot_spawn_count)) * TAU
		var dist: float = randf_range(10.0, spawn_radius)
		var spawn_pos := Vector3(cos(angle) * dist, 0.8, sin(angle) * dist)
		bot.global_position = spawn_pos
		
		# Listen to bot death
		var hp: HealthComponent = bot.find_child("HealthComponent", true, false) as HealthComponent
		if hp:
			hp.died.connect(_on_bot_died.bind(bot))

func report_elimination(killer_name: String, victim_name: String, is_player_killer: bool) -> void:
	if hud:
		hud.add_kill_feed(killer_name, victim_name, is_player_killer)
		if is_player_killer:
			hud.add_kill()

func _on_bot_died(killer: Node, bot: BotAI) -> void:
	alive_combatants = maxi(1, alive_combatants - 1)
	if hud:
		hud.update_alive_count(alive_combatants, total_combatants)
		if killer and is_instance_valid(killer):
			if killer.is_in_group("player") or killer.is_in_group("players") or killer == player_node or killer.name == "Player":
				hud.add_kill()
		
	if alive_combatants == 1:
		# Player is the last one standing!
		if LevelManager.instance:
			LevelManager.instance.unlock_next_level()
		if hud:
			hud.show_victory()

func _on_player_died(_killer: Node) -> void:
	if hud:
		hud.show_defeat(alive_combatants)
