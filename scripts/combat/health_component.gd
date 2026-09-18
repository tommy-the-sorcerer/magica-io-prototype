class_name HealthComponent
extends Node

## Reusable Health Component for Players, Bots, and Crates
signal health_changed(current: float, max_health: float)
signal damaged(amount: float, source: Node)
signal died(killer: Node)

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float, source: Node = null) -> void:
	if current_health <= 0:
		return
	
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, source)
	
	# Flash parent mesh if visual exists
	_flash_mesh()
	
	if current_health <= 0:
		died.emit(source)

func heal(amount: float) -> void:
	if current_health <= 0:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func _flash_mesh() -> void:
	var parent := get_parent()
	if not parent:
		return
	var mesh: GeometryInstance3D = parent.find_child("Visuals", true, false) as GeometryInstance3D
	if not mesh:
		mesh = parent.find_child("MeshInstance3D", true, false) as GeometryInstance3D
	if mesh:
		var tween := create_tween()
		tween.tween_property(mesh, "transparency", 0.5, 0.08)
		tween.tween_property(mesh, "transparency", 0.0, 0.08)
