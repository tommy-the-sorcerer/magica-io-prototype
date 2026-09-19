extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 10.5, 9.5)
@export var follow_speed: float = 6.0

func _ready() -> void:
	if not target and get_tree() and get_tree().current_scene:
		target = get_tree().current_scene.find_child("Player", true, false) as Node3D

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		if get_tree() and get_tree().current_scene:
			target = get_tree().current_scene.find_child("Player", true, false) as Node3D
		return
	
	var desired_pos := target.global_position + offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
