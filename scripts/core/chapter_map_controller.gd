class_name ChapterMapController
extends Node3D

## Universal Map Controller for Chapters 1-10 (Handles Spawns, Camera, Enemies, Bosses, and Pickups)

@export var chapter_name: String = "Chapter"
@export var current_level: int = 1
@export var enemy_count: int = 8
@export var is_boss_level: bool = false
@export var boss_scene: PackedScene

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $Camera3D
@onready var hud: HUD = $HUD

# Spawn Groups
@onready var player_spawns: Node3D = $Gameplay/PlayerSpawns
@onready var enemy_spawns: Node3D = $Gameplay/EnemySpawns

const CHAPTER_BOSS_PATHS := {
	"chapter_02": "res://scenes/maps/chapter_02_desert_mirage/boss/anubis_scythe_lord.tscn",
	"chapter_03": "res://scenes/maps/chapter_03_frostbite_tundra/boss/frost_fiend_ymir.tscn",
	"chapter_04": "res://scenes/maps/chapter_04_magma_core/boss/ignis_molten_overlord.tscn",
	"chapter_05": "res://scenes/maps/chapter_05_mystic_grove/boss/spore_queen_nightshade.tscn",
	"chapter_06": "res://scenes/maps/chapter_06_castle_ruins/boss/warlord_iron_bane.tscn",
	"chapter_07": "res://scenes/maps/chapter_07_pirate_cove/boss/captain_davy_blood_tide.tscn",
	"chapter_08": "res://scenes/maps/chapter_08_cursed_swamp/boss/lord_malakor.tscn",
	"chapter_09": "res://scenes/maps/chapter_09_cosmic_void/boss/xeno_gorgon_apex.tscn",
	"chapter_10": "res://scenes/maps/chapter_10_celestial_peak/boss/judgment_seraph.tscn",
	"emerald_plains": "res://scenes/maps/emerald_plains/boss/gorgon_treant_king.tscn",
}

var player_instance: Node3D = null
var active_combatants: int = 1
var total_combatants: int = 1

func _ready() -> void:
	_resolve_boss_scene()
	_spawn_player()
	
	if (is_boss_level or current_level == 10) and boss_scene:
		_setup_boss_encounter()
	else:
		_spawn_enemies()

func _resolve_boss_scene() -> void:
	if boss_scene:
		return
	var scene_path: String = scene_file_path.to_lower()
	for key in CHAPTER_BOSS_PATHS:
		if key in scene_path or key in chapter_name.to_lower():
			var p: String = CHAPTER_BOSS_PATHS[key]
			if ResourceLoader.exists(p):
				boss_scene = load(p) as PackedScene
				break

func _spawn_player() -> void:
	var player_scene := load("res://scenes/player/player.tscn")
	if not player_scene:
		return
		
	player_instance = player_scene.instantiate() as Node3D
	add_child(player_instance)
	
	var spawn_pos := Vector3(0, 0.2, 0)
	if player_spawns and player_spawns.get_child_count() > 0:
		var marker := player_spawns.get_child(0) as Marker3D
		if marker:
			spawn_pos = marker.global_position
			
	player_instance.global_position = spawn_pos
	
	if camera and camera.has_method("set"):
		camera.set("target", player_instance)
		
	var hp: HealthComponent = player_instance.find_child("HealthComponent", true, false) as HealthComponent
	if hp:
		hp.died.connect(_on_player_died)
		hp.health_changed.connect(func(curr, max_hp): if hud: hud.update_player_hp(curr, max_hp))

func _spawn_enemies() -> void:
	var bot_scene := load("res://scenes/bots/bot.tscn")
	if not bot_scene:
		return
		
	total_combatants = enemy_count + 1
	active_combatants = total_combatants
	
	if hud:
		hud.update_alive_count(active_combatants, total_combatants)
		
	var spawn_markers: Array[Node] = []
	if enemy_spawns:
		spawn_markers = enemy_spawns.get_children()
		
	for i in range(enemy_count):
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

func _setup_boss_encounter() -> void:
	total_combatants = 2
	active_combatants = 2
	if hud:
		hud.update_alive_count(active_combatants, total_combatants)
		
	var boss: Node3D = boss_scene.instantiate() as Node3D
	add_child(boss)
	boss.global_position = Vector3(0, 0.2, 0)
	
	var hp: HealthComponent = boss.find_child("HealthComponent", true, false) as HealthComponent
	if hp:
		hp.died.connect(func(_killer): 
			if hud: hud.show_victory()
		)

func _physics_process(_delta: float) -> void:
	_check_fall_bounds()

func _check_fall_bounds() -> void:
	if player_instance and is_instance_valid(player_instance):
		if player_instance.global_position.y < -22.0:
			var hp: HealthComponent = player_instance.find_child("HealthComponent", true, false) as HealthComponent
			if hp and not hp.is_dead:
				hp.take_damage(99999, null)
				if hud:
					hud.show_defeat(active_combatants, "☁️ FELL INTO THE VOID ☁️")
	
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
