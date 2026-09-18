class_name CactusHazard
extends StaticBody3D

## Cactus with prickly spines that inflicts contact damage when bumped into
@export var contact_damage: float = 12.0
@export var damage_cooldown: float = 0.8

var last_damage_time: Dictionary = {}

func _ready() -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 3.2
	col.shape = shape
	col.position.y = 1.6
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("combatants"):
		var now := Time.get_ticks_msec() / 1000.0
		if not last_damage_time.has(body) or (now - last_damage_time[body]) >= damage_cooldown:
			last_damage_time[body] = now
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(contact_damage, self)
			if "velocity" in body:
				var push_dir: Vector3 = (body.global_position - global_position).normalized()
				push_dir.y = 0.0
				body.velocity += push_dir * 5.0
