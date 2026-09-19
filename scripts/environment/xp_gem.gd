class_name XPGem
extends Area3D

## Collectible XP Gem that floats and rotates
func _process(delta: float) -> void:
	rotation.y += 2.0 * delta
	position.y = 0.4 + sin(Time.get_ticks_msec() * 0.005 + get_instance_id()) * 0.1
