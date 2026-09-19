class_name SlowZone
extends Area3D

## Reusable zone that reduces the movement speed of entities inside it (Quicksand, Mud, Deep Water)
@export var speed_multiplier: float = 0.45
@export var zone_name: String = "Slow Terrain"

var slowed_entities: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("combatants"):
		if "move_speed" in body:
			slowed_entities[body] = body.move_speed
			body.move_speed *= speed_multiplier
		elif "speed" in body:
			slowed_entities[body] = body.speed
			body.speed *= speed_multiplier

func _on_body_exited(body: Node) -> void:
	if slowed_entities.has(body):
		var orig_speed: float = slowed_entities[body]
		if is_instance_valid(body):
			if "move_speed" in body:
				body.move_speed = orig_speed
			elif "speed" in body:
				body.speed = orig_speed
		slowed_entities.erase(body)
