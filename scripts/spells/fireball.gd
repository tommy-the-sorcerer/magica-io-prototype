class_name FireballSpell
extends Area3D

## Glowing Fireball Projectile that damages players, bots, and destructible crates

@export var speed: float = 16.0
@export var damage: float = 25.0
@export var lifetime: float = 3.0

var caster: Node = null
var _velocity: Vector3 = Vector3.ZERO

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self): queue_free())

func _physics_process(delta: float) -> void:
	# Fly in forward direction
	var forward: Vector3 = -global_transform.basis.z.normalized()
	global_position += forward * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == caster:
		return
	
	_hit(body)

func _on_area_entered(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent and parent != caster:
		_hit(parent)

func _hit(target: Node) -> void:
	# Deal damage if target has HealthComponent
	var hp: HealthComponent = target.find_child("HealthComponent", true, false) as HealthComponent
	if hp and hp.current_health > 0:
		hp.take_damage(damage, caster)
		
	# Explosion VFX scale pop
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.08)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.08)
	tween.chain().tween_callback(queue_free)
