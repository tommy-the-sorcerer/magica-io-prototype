class_name DamageZone
extends Area3D

## Reusable environmental zone that applies direct or repeating damage to combatants
@export var damage_per_second: float = 25.0
@export var tick_interval: float = 0.5
@export var initial_hit_damage: float = 10.0
@export var hazard_name: String = "Hazard"

var entities_inside: Array[Node] = []
var tick_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if entities_inside.is_empty():
		return
		
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_damage()

func _apply_damage() -> void:
	var dmg: float = damage_per_second * tick_interval
	for entity in entities_inside:
		if is_instance_valid(entity):
			var hp: HealthComponent = entity.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(dmg, self)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("combatants") and not entities_inside.has(body):
		entities_inside.append(body)
		if initial_hit_damage > 0.0:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(initial_hit_damage, self)

func _on_body_exited(body: Node) -> void:
	entities_inside.erase(body)
