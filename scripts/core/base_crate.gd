class_name BaseCrate
extends StaticBody3D

## Reusable Destructible Crate with HealthComponent, damage feedback, and coin/loot drops

@export var max_health: float = 25.0
@export var min_coins_dropped: int = 2
@export var max_coins_dropped: int = 4
@export var coin_scene: PackedScene

@onready var health_component: HealthComponent = $HealthComponent
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	add_to_group("destructibles")
	add_to_group("combatants") # Allows projectiles to collide and damage it
	
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		add_child(health_component)
		
	health_component.max_health = max_health
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

func _on_damaged(_amount: float, _source: Node) -> void:
	if mesh_instance:
		var tween := create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.15, 0.85, 1.15), 0.06)
		tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.08)

func _on_died(_killer: Node) -> void:
	# Disable collision immediately
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Spawn dropped coins around the crate
	_spawn_loot()
	
	# Death splinter pop animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 0.3, 1.3), 0.08)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(queue_free)

func _spawn_loot() -> void:
	var coin_res: PackedScene = coin_scene
	if not coin_res:
		coin_res = load("res://scenes/maps/emerald_plains/props/emerald_coin.tscn")
	if not coin_res:
		return
		
	var drop_count := randi_range(min_coins_dropped, max_coins_dropped)
	for i in range(drop_count):
		var coin: Node3D = coin_res.instantiate() as Node3D
		if coin:
			var angle: float = randf_range(0, TAU)
			var dist: float = randf_range(0.8, 2.2)
			var offset := Vector3(cos(angle) * dist, 0.4, sin(angle) * dist)
			get_tree().current_scene.add_child(coin)
			coin.global_position = global_position + offset
