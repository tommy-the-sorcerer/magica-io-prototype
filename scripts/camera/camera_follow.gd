class_name CameraFollow
extends Camera3D

## Isometric Follow Camera for Magica.io

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 10.5, 9.5)
@export var follow_speed: float = 6.0

func _ready() -> void:
	_find_target()

func _find_target() -> void:
	if not target:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D
	if not target:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_find_target()
		return
	
	var desired_pos := target.global_position + offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
