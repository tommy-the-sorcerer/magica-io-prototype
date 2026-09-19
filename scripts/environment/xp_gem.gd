class_name XPGem
extends Area3D

## Collectible floating crystal with smooth bobbing, rotation, and player/bot magnetism.

@export var xp_value: float = 10.0
@export var magnet_range: float = 4.0
@export var initial_magnet_speed: float = 6.0
@export var max_magnet_speed: float = 24.0
@export var acceleration: float = 35.0

var _base_y: float = 0.4
var _wobble_offset: float = 0.0
var _target: Node3D = null
var _current_speed: float = 0.0
var _is_collected: bool = false
var _initial_spawn_velocity: Vector3 = Vector3.ZERO
var _spawn_arc_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_base_y = position.y
	_wobble_offset = randf_range(0.0, TAU)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

## Called when spawned from an exploding crate with a physics-like pop arc
func launch(impulse: Vector3) -> void:
	_initial_spawn_velocity = impulse
	_spawn_arc_timer = 0.45

func _physics_process(delta: float) -> void:
	if _is_collected:
		return

	# If newly spawned with pop impulse, simulate outward arc
	if _spawn_arc_timer > 0.0:
		_spawn_arc_timer -= delta
		global_position += _initial_spawn_velocity * delta
		_initial_spawn_velocity.y -= 12.0 * delta # Gravity
		if global_position.y < 0.35:
			global_position.y = 0.35
			_initial_spawn_velocity = Vector3.ZERO
			_spawn_arc_timer = 0.0
			_base_y = global_position.y
		return

	# Magnetism logic
	if not is_instance_valid(_target):
		_target = _find_nearest_target()

	if is_instance_valid(_target):
		var target_pos: Vector3 = _target.global_position + Vector3(0, 0.6, 0)
		var dir_to_target: Vector3 = (target_pos - global_position)
		var dist: float = dir_to_target.length()

		if dist <= magnet_range:
			_current_speed = minf(max_magnet_speed, _current_speed + acceleration * delta)
			var move_dir: Vector3 = dir_to_target.normalized()
			global_position += move_dir * _current_speed * delta

			# If extremely close, trigger pickup directly
			if dist < 0.6:
				_collect(_target)
				return
		else:
			# Lost magnetic lock
			_target = null
			_current_speed = initial_magnet_speed
	else:
		# Idle bobbing and spinning
		rotation.y += 2.8 * delta
		position.y = _base_y + sin(Time.get_ticks_msec() * 0.005 + _wobble_offset) * 0.12

func _find_nearest_target() -> Node3D:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	var nearest: Node3D = null
	var min_dist: float = magnet_range

	for c in combatants:
		if not is_instance_valid(c) or not (c is Node3D):
			continue
		var n3d := c as Node3D
		var d: float = global_position.distance_to(n3d.global_position)
		if d < min_dist:
			min_dist = d
			nearest = n3d

	return nearest

func _on_body_entered(body: Node) -> void:
	if _is_collected:
		return
	if body.is_in_group("combatants") or body.is_in_group("player"):
		_collect(body)

func _on_area_entered(area: Area3D) -> void:
	if _is_collected:
		return
	var parent := area.get_parent()
	if parent and (parent.is_in_group("combatants") or parent.is_in_group("player")):
		_collect(parent)

func _collect(collector: Node) -> void:
	if _is_collected:
		return
	_is_collected = true

	# Award XP to collector
	if collector.has_method("add_xp"):
		collector.call("add_xp", xp_value)
	elif collector.is_in_group("player"):
		# Check HUD directly if method not present
		var hud: HUD = get_tree().current_scene.find_child("HUD", true, false) as HUD
		if hud:
			hud.update_player_xp(xp_value, 50.0, 1)

	# Pickup pop scale animation
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.1)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.12)
	tween.chain().tween_callback(queue_free)
