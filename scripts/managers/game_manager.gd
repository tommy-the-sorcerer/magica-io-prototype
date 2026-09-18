class_name GameManager
extends Node

## Manages Match Spawns, Combatant Tracking, Kill Feed, and Victory/Defeat Conditions

@export var bot_scene: PackedScene
@export var bot_spawn_count: int = 14
@export var spawn_radius: float = 24.0

var total_combatants: int = 15
var alive_combatants: int = 15
var player_node: Node3D = null
var hud: HUD = null

func _ready() -> void:
	total_combatants = bot_spawn_count + 1
	alive_combatants = total_combatants
	
	# Find HUD
	hud = get_tree().current_scene.find_child("HUD", true, false) as HUD
	if hud:
		hud.update_alive_count(alive_combatants, total_combatants)
		
	# Find Player
	player_node = get_tree().current_scene.find_child("Player", true, false) as Node3D
	if player_node:
		var hp_comp: HealthComponent = player_node.find_child("HealthComponent", true, false) as HealthComponent
		if hp_comp:
			hp_comp.died.connect(_on_player_died)
			hp_comp.health_changed.connect(func(curr, max_hp): if hud: hud.update_player_hp(curr, max_hp))
	
	# Spawn Bots
	call_deferred("_spawn_bots")

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
		var dist: float = randf_range(spawn_radius * 0.5, spawn_radius)
		var spawn_pos := Vector3(cos(angle) * dist, 1.0, sin(angle) * dist)
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
		
	if alive_combatants == 1:
		# Player is the last one standing!
		if hud:
			hud.show_victory()

func _on_player_died(_killer: Node) -> void:
	if hud:
		hud.show_defeat(alive_combatants)
