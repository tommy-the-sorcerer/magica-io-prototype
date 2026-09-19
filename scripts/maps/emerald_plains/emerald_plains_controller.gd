class_name EmeraldPlainsController
extends Node3D

## Master Controller for Chapter 1: Emerald Plains (Levels 1-10)

@export var current_level: int = 1
@export var is_boss_level: bool = false
@export var level_data: ChapterLevelData

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $Camera3D
@onready var storm: ForestStorm = $Storm/ForestStorm
@onready var hud: HUD = $HUD

# Spawn Groups
@onready var player_spawns: Node3D = $Gameplay/PlayerSpawns
@onready var enemy_spawns: Node3D = $Gameplay/EnemySpawns
@onready var coin_locations: Node3D = $Gameplay/CoinLocations

var player_instance: Node3D = null
var active_combatants: int = 1
var total_combatants: int = 1

func _ready() -> void:
	_load_level_data()
	_apply_environment_settings()
	_spawn_player()
	
	if is_boss_level or current_level == 10 or (level_data and level_data.is_boss_level):
		_setup_boss_arena()
	else:
		_spawn_enemies()
		
	_start_storm()

func _load_level_data() -> void:
	if not level_data:
		var path := "res://scripts/maps/emerald_plains/levels/level_%02d.tres" % current_level
		if ResourceLoader.exists(path):
			level_data = load(path) as ChapterLevelData
			
	if not level_data:
		# Default fallback data
		level_data = ChapterLevelData.new()
		level_data.level_number = current_level
		level_data.enemy_count = 8
		level_data.storm_shrink_duration = 140.0

func _apply_environment_settings() -> void:
	if not level_data:
		return
		
	if sun:
		sun.light_color = level_data.sun_color
		sun.light_energy = level_data.sun_energy
		
	if world_env and world_env.environment:
		var env := world_env.environment
		env.ambient_light_color = level_data.ambient_color
		env.ambient_light_energy = level_data.ambient_energy
		env.volumetric_fog_density = level_data.fog_density

func _spawn_player() -> void:
	var player_scene := load("res://scenes/player/player.tscn")
	if not player_scene:
		return
		
	player_instance = player_scene.instantiate() as Node3D
	add_child(player_instance)
	
	# Pick first player spawn or default origin
	var spawn_pos := Vector3(0, 0.2, 0)
	if player_spawns and player_spawns.get_child_count() > 0:
		var spawn_marker := player_spawns.get_child(0) as Marker3D
		if spawn_marker:
			spawn_pos = spawn_marker.global_position
			
	player_instance.global_position = spawn_pos
	
	# Hook camera to follow player
	if camera and camera.has_method("set"):
		camera.set("target", player_instance)
		
	# Hook player health to HUD
	var hp: HealthComponent = player_instance.find_child("HealthComponent", true, false) as HealthComponent
	if hp:
		hp.died.connect(_on_player_died)
		hp.health_changed.connect(func(curr, max_hp): if hud: hud.update_player_hp(curr, max_hp))

func _spawn_enemies() -> void:
	var bot_scene := load("res://scenes/bots/bot.tscn")
	if not bot_scene or not level_data:
		return
		
	var count: int = level_data.enemy_count
	total_combatants = count + 1
	active_combatants = total_combatants
	
	if hud:
		hud.update_alive_count(active_combatants, total_combatants)
		
	var spawn_markers: Array[Node] = []
	if enemy_spawns:
		spawn_markers = enemy_spawns.get_children()
		
	for i in range(count):
		var bot: Node3D = bot_scene.instantiate() as Node3D
		add_child(bot)
		
		var spawn_pos := Vector3(randf_range(-22, 22), 0.2, randf_range(-22, 22))
		if not spawn_markers.is_empty():
			var marker: Marker3D = spawn_markers[i % spawn_markers.size()] as Marker3D
			if marker:
				var jitter := Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				spawn_pos = marker.global_position + jitter
				
		bot.global_position = spawn_pos
		
		var hp: HealthComponent = bot.find_child("HealthComponent", true, false) as HealthComponent
		if hp:
			hp.died.connect(_on_enemy_died)

func _setup_boss_arena() -> void:
	total_combatants = 2
	active_combatants = 2
	if hud:
		hud.update_alive_count(active_combatants, total_combatants)
		
	var boss_scene := load("res://scenes/maps/emerald_plains/boss/gorgon_treant_king.tscn")
	if boss_scene:
		var boss: Node3D = boss_scene.instantiate() as Node3D
		add_child(boss)
		boss.global_position = Vector3(0, 0.2, 0)
		
		var hp: HealthComponent = boss.find_child("HealthComponent", true, false) as HealthComponent
		if hp:
			hp.died.connect(func(_killer): 
				if hud: hud.show_victory()
			)

func _start_storm() -> void:
	if not storm or not level_data:
		return
	storm.start_radius = level_data.storm_start_radius
	storm.min_radius = level_data.storm_end_radius
	storm.damage_per_second = level_data.storm_dps
	storm.start_shrink(level_data.storm_end_radius, level_data.storm_shrink_duration)

func _physics_process(_delta: float) -> void:
	_check_fall_bounds()

func _check_fall_bounds() -> void:
	if player_instance and is_instance_valid(player_instance):
		if player_instance.global_position.y < -22.0:
			var hp: HealthComponent = player_instance.find_child("HealthComponent", true, false) as HealthComponent
			if hp and not hp.is_dead:
				hp.take_damage(99999, null)
				if hud:
					hud.show_defeat(active_combatants, "☁️ FELL FROM THE CLOUDS ☁️")
	
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != player_instance and c is Node3D:
			if c.global_position.y < -22.0:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp and not hp.is_dead:
					hp.take_damage(99999, null)

func _on_enemy_died(_killer: Node) -> void:
	active_combatants = maxi(1, active_combatants - 1)
	if hud:
		hud.update_alive_count(active_combatants, total_combatants)
		if active_combatants == 1:
			hud.show_victory()

func _on_player_died(_killer: Node) -> void:
	if hud:
		hud.show_defeat(active_combatants)
