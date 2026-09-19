class_name StormZone
extends Node3D

## Battle Royale Shrinking Storm / Safe Zone Ring
## Periodic 3-phase contraction with continuous out-of-bounds damage tick logic.

signal phase_started(phase_index: int, target_radius: float, duration: float)
signal phase_shrink_ended(phase_index: int)

@export var initial_radius: float = 45.0
@export var min_radius: float = 5.0
@export var total_match_duration: float = 180.0
@export var tick_interval: float = 0.5
@export var damage_per_tick: float = 5.0

# Storm center point (defaults to arena origin Vector3.ZERO)
@export var storm_center: Vector3 = Vector3.ZERO

var current_radius: float = 45.0
var _tick_timer: float = 0.0
var _match_elapsed: float = 0.0
var _current_phase: int = 0
var _is_shrinking: bool = false
var _phase_timer: float = 0.0
var _phase_duration: float = 0.0
var _phase_start_radius: float = 45.0
var _phase_target_radius: float = 45.0

# Visual node references
@onready var storm_mesh: MeshInstance3D = $MeshInstance3D
@onready var ground_ring: MeshInstance3D = get_node_or_null("GroundRing") as MeshInstance3D
@onready var upper_arc_ring: MeshInstance3D = get_node_or_null("UpperArcRing") as MeshInstance3D

## 3 Phase Schedule (Wait Time before shrink, Shrink Duration, Target Radius)
const PHASES: Array[Dictionary] = [
	{"wait": 15.0, "shrink_time": 35.0, "target_radius": 28.0},
	{"wait": 20.0, "shrink_time": 40.0, "target_radius": 14.0},
	{"wait": 20.0, "shrink_time": 45.0, "target_radius": 5.0}
]

func _ready() -> void:
	current_radius = initial_radius
	_update_visuals()
	_start_next_phase()

func _physics_process(delta: float) -> void:
	_match_elapsed += delta
	_tick_timer += delta

	# Subtle ring rotation for electric energy effect
	if ground_ring:
		ground_ring.rotation.y += 0.8 * delta
	if upper_arc_ring:
		upper_arc_ring.rotation.y -= 1.2 * delta

	# Process shrinking timeline
	_process_phases(delta)

	# Process 0.5s damage tick to combatants outside current radius
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_apply_storm_damage()

func _process_phases(delta: float) -> void:
	if _current_phase >= PHASES.size():
		return

	var phase_info: Dictionary = PHASES[_current_phase]

	if not _is_shrinking:
		_phase_timer += delta
		if _phase_timer >= phase_info["wait"]:
			_is_shrinking = true
			_phase_timer = 0.0
			_phase_start_radius = current_radius
			_phase_target_radius = phase_info["target_radius"]
			_phase_duration = phase_info["shrink_time"]
			phase_started.emit(_current_phase, _phase_target_radius, _phase_duration)
	else:
		_phase_timer += delta
		var t: float = clampf(_phase_timer / _phase_duration, 0.0, 1.0)
		var smooth_t: float = 0.5 - 0.5 * cos(t * PI)
		current_radius = lerpf(_phase_start_radius, _phase_target_radius, smooth_t)
		_update_visuals()

		if t >= 1.0:
			current_radius = _phase_target_radius
			_is_shrinking = false
			_phase_timer = 0.0
			phase_shrink_ended.emit(_current_phase)
			_current_phase += 1

func _start_next_phase() -> void:
	_is_shrinking = false
	_phase_timer = 0.0

func _update_visuals() -> void:
	if not storm_mesh:
		return

	storm_mesh.scale = Vector3(current_radius, 1.0, current_radius)
	if ground_ring:
		ground_ring.scale = Vector3(current_radius, 1.0, current_radius)
	if upper_arc_ring:
		upper_arc_ring.scale = Vector3(current_radius, 1.0, current_radius)

func _apply_storm_damage() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	for entity in combatants:
		if not is_instance_valid(entity) or not (entity is Node3D):
			continue
		
		var node3d := entity as Node3D
		# 2D horizontal distance from storm center
		var horizontal_dist := Vector2(
			node3d.global_position.x - storm_center.x,
			node3d.global_position.z - storm_center.z
		).length()

		if horizontal_dist > current_radius:
			var hp: HealthComponent = node3d.find_child("HealthComponent", true, false) as HealthComponent
			if hp and hp.current_health > 0:
				hp.take_damage(damage_per_tick, self)

## Returns true if the position is safely within the safe zone
func is_position_safe(pos: Vector3) -> bool:
	var horizontal_dist := Vector2(pos.x - storm_center.x, pos.z - storm_center.z).length()
	return horizontal_dist <= current_radius

## Returns current storm progress fraction (0.0 = match start, 1.0 = final circle)
func get_storm_shrink_progress() -> float:
	return clampf((initial_radius - current_radius) / (initial_radius - min_radius), 0.0, 1.0)
