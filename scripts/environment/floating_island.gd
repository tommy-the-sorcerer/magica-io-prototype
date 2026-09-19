class_name FloatingIsland
extends Node3D

## Floating rock island hovering in an antigravity field with gentle bobbing,
## orbiting debris fragments, and lush grass on top.

@export var bob_amplitude: float = 0.25
@export var bob_speed: float = 1.2
@export var rotation_speed: float = 0.15
@export var debris_orbit_speed: float = 0.8

var _base_y: float = 0.0
var _time_offset: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var debris_group: Node3D = get_node_or_null("Visuals/Debris") as Node3D

func _ready() -> void:
	_base_y = position.y
	_time_offset = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if visuals:
		visuals.rotation.y += rotation_speed * delta
		position.y = _base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed + _time_offset) * bob_amplitude
		
	if debris_group:
		debris_group.rotation.y += debris_orbit_speed * delta
