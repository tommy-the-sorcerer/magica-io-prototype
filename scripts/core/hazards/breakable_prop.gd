class_name BreakableProp
extends StaticBody3D

## Reusable destructible object that can be damaged by player/bot spells and shatters with effects
signal broken(attacker: Node)

@export var max_health: float = 30.0
@export var gem_drop_scene: PackedScene
@export var gem_drop_chance: float = 0.5
@export var explosion_on_break: bool = false
@export var explosion_damage: float = 35.0
@export var explosion_radius: float = 5.0

var current_health: float = 30.0
var is_broken: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("destructible")

func take_damage(amount: float, attacker: Node = null) -> void:
	if is_broken:
		return
		
	current_health -= amount
	# Visual flicker or scale hit reaction
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.08, 0.06)
	tw.tween_property(self, "scale", scale, 0.06)
	
	if current_health <= 0.0:
		_shatter(attacker)

func _shatter(attacker: Node) -> void:
	is_broken = true
	broken.emit(attacker)
	
	if explosion_on_break:
		_explode()
		
	if gem_drop_scene and randf() < gem_drop_chance:
		var gem = gem_drop_scene.instantiate()
		get_parent().add_child(gem)
		gem.global_position = global_position + Vector3(0, 0.3, 0)
		
	queue_free()

func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = explosion_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 2 # Combatants
	
	var results := space.intersect_shape(query, 16)
	for res in results:
		var collider = res.collider
		if collider and collider.is_in_group("combatants"):
			var hp: HealthComponent = collider.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(explosion_damage, self)
			if "velocity" in collider:
				var push_dir: Vector3 = (collider.global_position - global_position).normalized()
				collider.velocity += push_dir * 12.0 + Vector3.UP * 5.0
