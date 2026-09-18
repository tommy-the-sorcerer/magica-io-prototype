class_name Projectile
extends Area3D

## Magic Projectile (e.g. Fireball) that moves forward, collides with entities/walls, deals AoE damage, and explodes

@export var speed: float = 20.0
@export var damage: float = 35.0
@export var blast_radius: float = 3.5
@export var lifetime: float = 2.5

var caster: Node = null
var elapsed: float = 0.0
var _exploded: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _exploded:
		return
	# Move along forward vector
	global_position += -global_transform.basis.z * speed * delta
	
	elapsed += delta
	if elapsed >= lifetime:
		_explode()

func _on_body_entered(body: Node) -> void:
	if is_instance_valid(caster) and body == caster:
		return
	_explode()

func _on_area_entered(area: Area3D) -> void:
	if is_instance_valid(caster) and (area == caster or area.get_parent() == caster):
		return
	if area.is_in_group("combatants"):
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	var valid_caster: Node = caster if is_instance_valid(caster) else null

	# AoE blast damage
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != valid_caster and (c is Node3D):
			var dist: float = global_position.distance_to((c as Node3D).global_position)
			if dist <= blast_radius:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(damage, valid_caster)
					
	# Visual pop / flash
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(2.5, 2.5, 2.5), 0.08)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.08)
	tween.tween_callback(queue_free)
