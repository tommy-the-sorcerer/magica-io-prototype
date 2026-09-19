class_name HellfireSlash
extends Projectile

## Crescent Dragon Hellfire Slash Projectile
## Fired from Dragonbound's molten dragonfang blade. Pierces enemies in a burning arc.

@onready var visual_pivot: Node3D = find_child("VisualPivot", true, false) as Node3D
@onready var blade_light: OmniLight3D = find_child("BladeLight", true, false) as OmniLight3D

func _ready() -> void:
	super._ready()
	speed = 26.0
	lifetime = 0.85
	pierces_targets = true
	max_pierces = 2
	damage = 28.0
	knockback_force = 14.0
	
	if not explosion_vfx_scene:
		explosion_vfx_scene = load("res://characters/dragonbound/vfx/dragon_impact.tscn")

func _process(delta: float) -> void:
	# Subtle spin and vibration of the crescent blade wave
	if visual_pivot:
		visual_pivot.rotation.z += 12.0 * delta
	if blade_light:
		blade_light.light_energy = 3.5 + sin(Time.get_ticks_msec() * 0.02) * 0.8
