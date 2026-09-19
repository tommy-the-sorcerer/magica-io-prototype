class_name WindBurst
extends Node3D

## Wind Burst (Q Ability)
## Premium utility spell: creates space, deals light damage (10),
## radially pushes enemies away with strong knockback (18 force) and 0.2s stagger,
## and deflects enemy projectiles outward without destroying them.

@export var radius: float = 5.0
@export var damage: float = 10.0
@export var knockback_force: float = 18.0
@export var stagger_duration: float = 0.2
@export var vfx_scene: PackedScene = preload("res://scenes/vfx/wind_burst_vfx.tscn")

var caster: Node3D = null

func _ready() -> void:
	# 1. Spawn Visual & Audio Effects at detonation point
	if vfx_scene:
		var vfx: Node3D = vfx_scene.instantiate() as Node3D
		if vfx:
			get_tree().current_scene.add_child(vfx)
			vfx.global_position = global_position
	
	# 2. Camera tactile impulse feedback
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.12)
	
	# 3. Radial Blast & Knockback on Combatants
	_apply_radial_burst()
	
	# 4. Projectile Deflection
	_deflect_projectiles()
	
	# Self clean up
	get_tree().create_timer(0.1).timeout.connect(queue_free)

func _apply_radial_burst() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	for entity in combatants:
		if not is_instance_valid(entity) or entity == caster:
			continue
		
		var dist: float = global_position.distance_to(entity.global_position)
		if dist <= radius:
			# Light damage
			var hp: HealthComponent = entity.find_child("HealthComponent", true, false) as HealthComponent
			if hp and hp.is_alive():
				hp.take_damage(damage, caster)
			
			# Strong radial knockback direction
			var push_dir: Vector3 = (entity.global_position - global_position)
			push_dir.y = 0.0
			if push_dir.length_squared() < 0.001:
				if caster and is_instance_valid(caster):
					push_dir = -caster.global_transform.basis.z
				else:
					push_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			push_dir = push_dir.normalized()
			
			# 18.0 knockback force with slight vertical lift
			var impulse: Vector3 = push_dir * knockback_force + Vector3(0, 2.2, 0)
			if entity.has_method("apply_knockback"):
				entity.call("apply_knockback", impulse, stagger_duration)

func _deflect_projectiles() -> void:
	var projectiles: Array[Node] = get_tree().get_nodes_in_group("projectiles")
	for proj in projectiles:
		if not is_instance_valid(proj) or proj.is_queued_for_deletion():
			continue
		if proj is Projectile:
			var p: Projectile = proj as Projectile
			# Don't deflect caster's own attacks
			if p.caster == caster:
				continue
			
			var dist: float = global_position.distance_to(p.global_position)
			if dist <= radius:
				# Deflect projectile sideways / outward
				var away_dir: Vector3 = (p.global_position - global_position)
				away_dir.y = 0.0
				if away_dir.length_squared() < 0.001:
					away_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
				# Slight wind swirl variance
				away_dir = (away_dir.normalized() + Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))).normalized()
				
				# Rotate projectile to face new flight path
				p.look_at(p.global_position + away_dir, Vector3.UP)
				
				# Transfer caster ownership so it doesn't harm deflector
				p.caster = caster
				
				# Gust acceleration boost
				p.speed *= 1.15
