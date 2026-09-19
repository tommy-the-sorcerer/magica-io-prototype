class_name Projectile
extends Area3D

## Base Spell Projectile for Magica.io
## Handles 3D movement, caster exemption, impact detection, AoE blast radius, knockback, and status debuffs.

signal impacted(impact_position: Vector3, hit_node: Node)

@export_group("Flight Physics")
## Forward velocity in meters per second
@export var speed: float = 22.0
## Maximum time before automatic explosion
@export var lifetime: float = 0.75
## If true, does not explode on first target hit
@export var pierces_targets: bool = false
@export var max_pierces: int = 1

@export_group("Combat & Damage")
## Base damage dealt on impact or within blast radius
@export var damage: float = 25.0
## Whether this spell deals area-of-effect splash damage
@export var is_aoe: bool = true
## Blast radius in meters for AoE damage
@export var aoe_radius: float = 3.0
var blast_radius: float:
	get: return aoe_radius
	set(v): aoe_radius = v
## Magnitude of impulse applied to targets away from blast center
@export var knockback_force: float = 12.0
## Movement speed reduction fraction (e.g., 0.4 = 40% slow)
@export_range(0.0, 1.0) var slow_multiplier: float = 0.0
## Duration of slow debuff in seconds
@export var slow_duration: float = 0.0

@export_group("VFX & Audio")
## Visual effect scene spawned upon impact/explosion
@export var explosion_vfx_scene: PackedScene
## Optional sound effect played on impact
@export var impact_sound: AudioStream

## Reference to the character who cast this projectile (ignored in collisions)
var caster: Node = null

var _lifetime_timer: float = 0.0
var _has_exploded: bool = false
var _pierce_count: int = 0
var _hit_entities: Array[Node] = []

func _ready() -> void:
	add_to_group("projectiles")
	_lifetime_timer = lifetime
	
	# Configure collision layers: Layer 3 (Spells) colliding with Layer 1 (World) & Layer 2 (Combatants)
	collision_layer = 4
	collision_mask = 1 | 2
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _has_exploded:
		return
	
	# Move forward along negative Z axis in local/global space
	global_position += -global_transform.basis.z * speed * delta
	
	# Lifetime countdown
	_lifetime_timer -= delta
	if _lifetime_timer <= 0.0:
		explode()

## Called when colliding with a physical body (Player, Bot, Wall, Floor, Prop)
func _on_body_entered(body: Node3D) -> void:
	if _has_exploded or not is_instance_valid(body):
		return
	
	# Ignore caster and caster's descendants/ancestors
	if _is_caster_or_self(body):
		return
	
	# Ignore already hit entities during piercing flight
	if body in _hit_entities:
		return
	
	_hit_entities.append(body)
	
	# Terrain/obstacle hit -> explode immediately
	if body is StaticBody3D or body is CSGShape3D:
		explode(body)
		return
	
	# Combatant hit
	if is_aoe:
		explode(body)
	else:
		_apply_direct_hit(body)
		if pierces_targets and _pierce_count < max_pierces:
			_pierce_count += 1
			_spawn_impact_vfx(global_position)
		else:
			explode(body)

## Called when colliding with another Area3D (Hurtbox, Zone, etc.)
func _on_area_entered(area: Area3D) -> void:
	if _has_exploded or not is_instance_valid(area):
		return
	
	if _is_caster_or_self(area):
		return
	
	# If this area belongs to a damageable entity
	var parent_entity: Node = area.get_parent()
	if parent_entity and not _is_caster_or_self(parent_entity):
		if parent_entity.has_node("HealthComponent") or parent_entity.is_in_group("combatants"):
			if parent_entity not in _hit_entities:
				_hit_entities.append(parent_entity)
				if is_aoe:
					explode(parent_entity)
				else:
					_apply_direct_hit(parent_entity)
					if pierces_targets and _pierce_count < max_pierces:
						_pierce_count += 1
					else:
						explode(parent_entity)

## Handles direct single-target impact (for non-AoE projectiles like Ice Lance)
func _apply_direct_hit(target: Node) -> void:
	impacted.emit(global_position, target)
	
	# Deal damage via HealthComponent
	var hp: HealthComponent = target.find_child("HealthComponent", true, false) as HealthComponent
	if hp:
		var valid_caster: Node = caster if (caster != null and is_instance_valid(caster)) else null
		hp.take_damage(damage, valid_caster)
	
	# Apply knockback with explicit typing
	if knockback_force > 0.0 and target is CharacterBody3D:
		var char_body: CharacterBody3D = target as CharacterBody3D
		var knock_dir: Vector3 = (char_body.global_position - global_position).normalized()
		knock_dir.y = 0.2
		char_body.velocity += knock_dir.normalized() * knockback_force
	
	# Apply slow status effect
	if slow_duration > 0.0 and slow_multiplier > 0.0:
		_apply_slow(target, slow_multiplier, slow_duration)

## Triggers explosion, AoE blast damage, spawns VFX, and frees projectile
func explode(direct_hit_target: Node = null) -> void:
	if _has_exploded:
		return
	_has_exploded = true
	
	impacted.emit(global_position, direct_hit_target)
	
	# Spawn explosion particles
	_spawn_impact_vfx(global_position)
	
	# Process AoE Blast Radius Damage & Knockback
	if is_aoe:
		_process_aoe_damage()
	
	# Clean up projectile
	queue_free()

## Finds all damageable combatants within AoE radius and applies damage + knockback
func _process_aoe_damage() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	var blast_pos: Vector3 = global_position
	
	for entity in combatants:
		if not is_instance_valid(entity) or not (entity is Node3D):
			continue
		
		# Skip caster if self-damage is disabled
		if _is_caster_or_self(entity):
			continue
		
		var node_3d: Node3D = entity as Node3D
		var dist: float = blast_pos.distance_to(node_3d.global_position)
		if dist <= aoe_radius:
			# Damage falloff: 100% at center down to 50% at edge
			var falloff: float = clampf(1.0 - (dist / (aoe_radius * 2.0)), 0.5, 1.0)
			var effective_damage: float = damage * falloff
			
			var hp: HealthComponent = node_3d.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				var valid_caster: Node = caster if (caster != null and is_instance_valid(caster)) else null
				hp.take_damage(effective_damage, valid_caster)
			
			# Knockback away from explosion epicenter with explicit types
			if knockback_force > 0.0 and node_3d is CharacterBody3D:
				var char_body: CharacterBody3D = node_3d as CharacterBody3D
				var knock_dir: Vector3 = (char_body.global_position - blast_pos).normalized()
				if knock_dir.length_squared() < 0.01:
					knock_dir = Vector3.UP
				knock_dir.y = 0.35 # Pop upward
				var force: float = knockback_force * (1.0 - (dist / aoe_radius) * 0.4)
				char_body.velocity += knock_dir.normalized() * force
			
			# Apply slow debuff if configured
			if slow_duration > 0.0 and slow_multiplier > 0.0:
				_apply_slow(node_3d, slow_multiplier, slow_duration)

## Instantiates impact VFX in scene tree
func _spawn_impact_vfx(pos: Vector3) -> void:
	if not explosion_vfx_scene:
		return
	
	var vfx: Node3D = explosion_vfx_scene.instantiate() as Node3D
	if vfx:
		var scene_root: Node = get_tree().current_scene
		if scene_root:
			scene_root.add_child(vfx)
		elif get_parent():
			get_parent().add_child(vfx)
		vfx.global_position = pos

## Applies slow debuff to the target if supported
func _apply_slow(target: Node, multiplier: float, duration: float) -> void:
	if target.has_method("apply_slow"):
		target.call("apply_slow", multiplier, duration)
	elif "move_speed" in target:
		# Fallback: directly modify move_speed with timer
		var orig_speed: float = target.get("move_speed")
		target.set("move_speed", orig_speed * (1.0 - multiplier))
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(target):
				target.set("move_speed", orig_speed)
		)

## Helper to verify if a node is the caster
func _is_caster_or_self(node: Node) -> bool:
	if node == self:
		return true
	if caster == null or not is_instance_valid(caster):
		return false
	if node == caster:
		return true
	if is_instance_valid(caster) and (caster.is_ancestor_of(node) or node.is_ancestor_of(caster)):
		return true
	return false

## Alias for backward compatibility
func _explode() -> void:
	explode()
