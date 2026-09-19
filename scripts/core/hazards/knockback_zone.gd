class_name KnockbackZone
extends Area3D

## Reusable component that launches or pushes combatants (Sand Geysers, Magma Vents, Explosions)
@export var knockback_force: float = 14.0
@export var vertical_lift: float = 8.0
@export var damage_on_launch: float = 15.0

func trigger_knockback(epicenter: Vector3 = global_position) -> void:
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("combatants"):
			var dir: Vector3 = (body.global_position - epicenter)
			dir.y = 0.0
			if dir.length_squared() < 0.01:
				dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			dir = dir.normalized()
			
			var impulse: Vector3 = dir * knockback_force + Vector3.UP * vertical_lift
			if "velocity" in body:
				body.velocity += impulse
			
			if damage_on_launch > 0.0:
				var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(damage_on_launch, self)
