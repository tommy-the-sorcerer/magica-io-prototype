class_name ArcaneBolt
extends Area3D

## Blue Arcane Projectile
## Fired from the Arcane Apprentice's staff crystal with bright cyan/blue magical energy,
## spark trail, and impact burst against players, bots, and destructible crates.

@export var speed: float = 18.0
@export var damage: float = 30.0
@export var lifetime: float = 2.5

var caster: Node = null
var _is_exploding: bool = false

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var core_mesh: MeshInstance3D = $Visuals/CoreMesh
@onready var aura_mesh: MeshInstance3D = $Visuals/AuraMesh
@onready var light: OmniLight3D = $Visuals/OmniLight3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Auto cleanup after lifetime
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self) and not _is_exploding: queue_free())

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
		
	# Fly in forward trajectory
	var forward: Vector3 = -global_transform.basis.z.normalized()
	global_position += forward * speed * delta
	
	# Core rotation and subtle pulsing
	if core_mesh:
		core_mesh.rotation.z += 12.0 * delta
	if aura_mesh:
		aura_mesh.rotation.y -= 8.0 * delta
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.15
		aura_mesh.scale = Vector3(pulse, pulse, pulse)

func _on_body_entered(body: Node) -> void:
	if body == caster or _is_exploding:
		return
	_hit(body)

func _on_area_entered(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent and parent != caster and not _is_exploding:
		_hit(parent)

func _hit(target: Node) -> void:
	if _is_exploding:
		return
	_is_exploding = true
	
	# Damage target if HealthComponent exists
	var hp: HealthComponent = target.find_child("HealthComponent", true, false) as HealthComponent
	if hp and hp.current_health > 0:
		hp.take_damage(damage, caster)
		
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	set_physics_process(false)
	
	# Magical arcane burst animation
	if light:
		light.light_energy = 4.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	if core_mesh:
		tween.tween_property(core_mesh, "scale", Vector3(2.5, 2.5, 2.5), 0.08)
	if aura_mesh:
		tween.tween_property(aura_mesh, "scale", Vector3(3.2, 3.2, 3.2), 0.08)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.08)
	tween.chain().tween_callback(queue_free)
