class_name HeatZone
extends Area3D

## Proximity-based radial heat damage zone (e.g. Volcano caldera or massive lava fissure)
## Far away: Low warning heat
## Close: High damage
## Inside core: Extreme damage

@export var max_heat_radius: float = 25.0
@export var core_radius: float = 6.0
@export var max_dps: float = 40.0
@export var min_dps: float = 5.0
@export var tick_interval: float = 0.5

var combatants: Array[Node] = []
var tick_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if combatants.is_empty():
		return
		
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_process_heat_damage()

func _process_heat_damage() -> void:
	var center := global_position
	for body in combatants:
		if not is_instance_valid(body):
			continue
			
		var dist := center.distance_to(body.global_position)
		if dist > max_heat_radius:
			continue
			
		var factor: float = 1.0 - clampf((dist - core_radius) / (max_heat_radius - core_radius), 0.0, 1.0)
		var dps := lerpf(min_dps, max_dps, factor)
		var dmg := dps * tick_interval
		
		var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
		if hp:
			hp.take_damage(dmg, self)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("combatants") and not combatants.has(body):
		combatants.append(body)

func _on_body_exited(body: Node) -> void:
	combatants.erase(body)
