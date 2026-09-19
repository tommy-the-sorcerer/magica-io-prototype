class_name DragonBreath
extends Projectile

## Abyssal Dragon Breath - Cataclysmic Hellfire Beam [E]
## Flying colossal dragonfire wyrm head with trailing 16m black & crimson hellfire column!

@onready var dragon_head: Node3D = find_child("DragonHead", true, false) as Node3D
@onready var flame_column: MeshInstance3D = find_child("FlameColumn", true, false) as MeshInstance3D
@onready var flame_light: OmniLight3D = find_child("FlameLight", true, false) as OmniLight3D

func _ready() -> void:
	super._ready()
	speed = 30.0
	lifetime = 0.95
	pierces_targets = true
	max_pierces = 6
	damage = 55.0
	is_aoe = true
	aoe_radius = 5.2
	knockback_force = 22.0
	
	if not explosion_vfx_scene:
		explosion_vfx_scene = load("res://characters/dragonbound/vfx/dragon_impact.tscn")
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.28)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _has_exploded:
		return
	
	var time_ms := Time.get_ticks_msec()
	
	# Serpentine undulation of the dragon wyrm head
	if dragon_head:
		dragon_head.rotation.z = sin(time_ms * 0.02) * 0.25
		dragon_head.position.y = sin(time_ms * 0.015) * 0.1
	
	# Pulsating flame column
	if flame_column:
		var pulse: float = 1.0 + sin(time_ms * 0.025) * 0.18
		flame_column.scale = Vector3(pulse, pulse, 1.0)
	
	if flame_light:
		flame_light.light_energy = 5.5 + sin(time_ms * 0.03) * 1.2
