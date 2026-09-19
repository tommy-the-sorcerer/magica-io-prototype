class_name LootCrate
extends StaticBody3D

## Destructible wooden voxel loot crate.
## Contains 20 HP, takes spell/attack damage, and bursts into 3-5 XP gems + debris upon destruction.

@export var gem_scene: PackedScene = preload("res://scenes/environment/xp_gem.tscn")
@export var min_gems: int = 3
@export var max_gems: int = 5

@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node3D = $Visuals
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	add_to_group("destructibles")
	add_to_group("crates")
	
	if health_component:
		health_component.max_health = 20.0
		health_component.current_health = 20.0
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)

func _on_damaged(amount: float, _source: Node) -> void:
	# Impact shake animation
	if visuals:
		var tween := create_tween()
		var shake_rot := Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), randf_range(-0.15, 0.15))
		tween.tween_property(visuals, "rotation", shake_rot, 0.04)
		tween.tween_property(visuals, "rotation", Vector3.ZERO, 0.08)

func _on_died(_killer: Node) -> void:
	# Disable collision immediately
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	_spawn_loot_gems()
	_spawn_destruction_debris()

	# Hide crate mesh and clean up after debris burst
	if visuals:
		visuals.visible = false

	# Short defer before cleanup to allow particles / sounds to instantiate cleanly
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _spawn_loot_gems() -> void:
	if not gem_scene:
		return

	var gem_count: int = randi_range(min_gems, max_gems)
	var parent_scene: Node = get_tree().current_scene

	for i in range(gem_count):
		var gem: Node3D = gem_scene.instantiate() as Node3D
		parent_scene.add_child(gem)
		gem.global_position = global_position + Vector3(0, 0.6, 0)

		# Random outward radial angle + upward pop
		var angle: float = (float(i) / float(gem_count)) * TAU + randf_range(-0.3, 0.3)
		var speed: float = randf_range(3.5, 6.0)
		var pop_velocity := Vector3(cos(angle) * speed, randf_range(4.0, 6.5), sin(angle) * speed)

		if gem.has_method("launch"):
			gem.call("launch", pop_velocity)

func _spawn_destruction_debris() -> void:
	var parent_scene: Node = get_tree().current_scene
	var wood_colors: Array[Color] = [
		Color(0.55, 0.35, 0.2),
		Color(0.45, 0.28, 0.15),
		Color(0.65, 0.42, 0.25),
		Color(0.35, 0.22, 0.12)
	]

	# Spawn 6-8 small physics voxel wood shards
	var shard_count: int = randi_range(6, 8)
	for i in range(shard_count):
		var shard := RigidBody3D.new()
		var mesh_inst := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		var s: float = randf_range(0.18, 0.32)
		box_mesh.size = Vector3(s, s, s)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = wood_colors.pick_random()
		mat.roughness = 0.8
		mesh_inst.mesh = box_mesh
		mesh_inst.material_override = mat

		var col_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = box_mesh.size
		col_shape.shape = box_shape

		shard.add_child(mesh_inst)
		shard.add_child(col_shape)
		parent_scene.add_child(shard)

		shard.global_position = global_position + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.7), randf_range(-0.3, 0.3))
		
		# Outward blast impulse
		var blast_dir := Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 2.5), randf_range(-1.0, 1.0)).normalized()
		shard.apply_central_impulse(blast_dir * randf_range(4.0, 8.0))
		shard.apply_torque_impulse(Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)))

		# Auto-fade and destroy shard after 1.5s
		var tween := shard.create_tween()
		tween.tween_interval(1.2)
		tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(shard.queue_free)
