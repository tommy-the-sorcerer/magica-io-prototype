class_name VolcanoController
extends EruptingProp

## Controls the active volcano: periodic warning and meteor barrage launching from crater
@export var falling_rock_scene: PackedScene
@export var eruption_rock_count: int = 5
@export var arena_spread_radius: float = 24.0

@onready var lava_light: OmniLight3D = $LavaLight

func _on_warning() -> void:
	# Warning: Pulsing light and intense smoke
	if lava_light:
		var tw := create_tween()
		tw.set_loops(3)
		tw.tween_property(lava_light, "light_energy", 4.0, 0.4)
		tw.tween_property(lava_light, "light_energy", 1.8, 0.4)

func _on_eruption() -> void:
	# Major Eruption: Bright flare & launch volcanic bombs
	if lava_light:
		lava_light.light_energy = 5.5
		
	if falling_rock_scene:
		for i in range(eruption_rock_count):
			_spawn_falling_rock(i * 0.35)

func _spawn_falling_rock(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self):
		return
		
	var rock = falling_rock_scene.instantiate()
	get_parent().add_child(rock)
	
	# Random target spot in the arena
	var angle := randf() * TAU
	var dist := randf_range(13.0, arena_spread_radius) # Keep outside the volcano base cone (r=11.0)
	var target_pos := Vector3(cos(angle) * dist, 0.1, sin(angle) * dist)
	
	var crater_mouth := global_position + Vector3(0, 6.5, 0)
	if rock.has_method("launch_arc"):
		rock.launch_arc(crater_mouth, target_pos)
	elif rock.has_method("launch_toward"):
		rock.launch_toward(target_pos)
	else:
		rock.global_position = target_pos + Vector3(0, 20.0, 0)

func _on_cooldown() -> void:
	if lava_light:
		var tw := create_tween()
		tw.tween_property(lava_light, "light_energy", 2.2, 1.5)
