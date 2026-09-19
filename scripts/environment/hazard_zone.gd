class_name HazardZone
extends Area3D

## Environmental Hazard (e.g. Volcano Lava, Poison Sludge) that damages entities inside it
@export var damage_per_second: float = 20.0
@export var tick_interval: float = 0.5
@export var hazard_name: String = "Lava"

var entities_inside: Array[Node] = []
var tick_timer: float = 0.0

@onready var lava_mesh: MeshInstance3D = find_child("LavaMesh", true, false) as MeshInstance3D

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
		# Instant initial hit
		var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
		if hp:
			hp.take_damage(10.0, self)

func _on_body_exited(body: Node) -> void:
	entities_inside.erase(body)
