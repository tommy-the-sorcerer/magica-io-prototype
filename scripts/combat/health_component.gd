class_name HealthComponent
extends Node

## Reusable Health & Damage Component for Players, Bots, Crates, and Destructibles
## Manages health values, damage calculation, floating combat flash visual effects, and death signals.

signal health_changed(current: float, max_health: float)
signal damaged(amount: float, source: Node)
signal died(killer: Node)

@export_group("Health Configuration")
@export var max_health: float = 100.0
@export var invulnerable: bool = false

@export_group("Damage Feedback")
@export var enable_flash: bool = true
@export var flash_color: Color = Color(1.0, 0.2, 0.2, 1.0) # Bright Red/White flash
@export var flash_duration: float = 0.12

var current_health: float = 100.0
var _active_flash_tween: Tween = null
var _original_materials: Dictionary = {}

func _ready() -> void:
	current_health = max_health
	# Defer initial signal so connected UI/parent listeners are ready
	health_changed.emit.call_deferred(current_health, max_health)

## Inflicts damage, emits signals, triggers combat flash, and handles death.
func take_damage(amount: float, source: Variant = null) -> void:
	if invulnerable or current_health <= 0.0 or amount <= 0.0:
		return
	
	var valid_source: Node = source as Node if (source != null and is_instance_valid(source) and source is Node) else null
	
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, valid_source)
	
	# Trigger visual combat flash on parent mesh
	if enable_flash:
		_flash_mesh()
	
	if current_health <= 0.0:
		died.emit(valid_source)

## Restores health up to max_health and notifies listeners.
func heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

## Sets a new maximum health value.
func set_max_health(new_max: float, reset_current: bool = false) -> void:
	max_health = maxf(1.0, new_max)
	if reset_current:
		current_health = max_health
	else:
		current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)

## Checks whether the entity is still alive.
func is_alive() -> bool:
	return current_health > 0.0

## Returns normalized health percentage (0.0 to 1.0).
func get_health_percent() -> float:
	return clampf(current_health / maxf(max_health, 1.0), 0.0, 1.0)

## Briefly flashes all parent mesh instances white/red upon taking damage.
func _flash_mesh() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
	
	# Cancel any running flash animation
	if _active_flash_tween and _active_flash_tween.is_valid():
		_active_flash_tween.kill()
		_restore_mesh_materials(parent_node)
	
	# Find all MeshInstance3D nodes under the parent
	var mesh_instances: Array[Node] = parent_node.find_children("*", "MeshInstance3D", true, false)
	if mesh_instances.is_empty():
		return
	
	# Create glowing flash material
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = flash_color
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material override
	for mesh in mesh_instances:
		if mesh is MeshInstance3D:
			mesh.material_override = flash_mat
	
	# Animate fade out and reset
	_active_flash_tween = create_tween()
	_active_flash_tween.tween_property(flash_mat, "albedo_color:a", 0.0, flash_duration)
	_active_flash_tween.tween_callback(func():
		for mesh in mesh_instances:
			if is_instance_valid(mesh) and mesh is MeshInstance3D:
				mesh.material_override = null
	)

func _restore_mesh_materials(parent_node: Node) -> void:
	var mesh_instances: Array[Node] = parent_node.find_children("*", "MeshInstance3D", true, false)
	for mesh in mesh_instances:
		if is_instance_valid(mesh) and mesh is MeshInstance3D:
			mesh.material_override = null
