class_name DragonAegis
extends Node3D

## Draconic Obsidian Aegis [R]
## Orbiting barrier of jagged obsidian dragon scales with molten magma fissures and hellfire.

signal shield_broken
signal shield_expired

@export var duration: float = 6.0
@export var max_hits: int = 6

var caster: Node3D = null
var _time_remaining: float = 6.0
var _hits_left: int = 6
var _is_fading: bool = false

@onready var shield_area: Area3D = $HitArea
@onready var shield_pivot: Node3D = $ShieldPivot
@onready var shield_light: OmniLight3D = $ShieldLight
@onready var sparks: GPUParticles3D = $Sparks

func _ready() -> void:
	_time_remaining = duration
	_hits_left = max_hits
	
	if shield_area:
		shield_area.area_entered.connect(_on_area_entered)
		shield_area.body_entered.connect(_on_body_entered)
	
	# Scale expansion animation
	scale = Vector3(0.01, 0.01, 0.01)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.18)

func _physics_process(delta: float) -> void:
	if _is_fading:
		return
	
	var time_ms := Time.get_ticks_msec()
	
	# Anchor to caster position
	if caster and is_instance_valid(caster):
		var hover_y: float = sin(time_ms * 0.005) * 0.05
		var target_pos: Vector3 = caster.global_position + Vector3(0, 0.85 + hover_y, 0)
		global_position = global_position.lerp(target_pos, 24.0 * delta)
	
	# Continuous rotation of the orbiting dragon scale fortress
	if shield_pivot:
		shield_pivot.rotation.y += 2.2 * delta
	
	# Molten light pulsation
	if shield_light:
		shield_light.light_energy = 2.4 + sin(time_ms * 0.01) * 0.5
	
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		fade_out()

func _on_area_entered(area: Area3D) -> void:
	if _is_fading or _hits_left <= 0:
		return
	if area is Projectile:
		var proj: Projectile = area as Projectile
		if _is_caster_or_self(proj.caster):
			return
		_block_projectile(proj)
	elif area.get_parent() is Projectile:
		var parent_proj: Projectile = area.get_parent() as Projectile
		if _is_caster_or_self(parent_proj.caster):
			return
		_block_projectile(parent_proj)

func _on_body_entered(body: Node3D) -> void:
	if _is_fading or _hits_left <= 0:
		return
	if body is Projectile:
		var proj: Projectile = body as Projectile
		if _is_caster_or_self(proj.caster):
			return
		_block_projectile(proj)

func _block_projectile(proj: Node3D) -> void:
	_hits_left -= 1
	
	if shield_light:
		shield_light.light_energy = 5.0
		var lt := create_tween()
		lt.tween_property(shield_light, "light_energy", 2.4, 0.2)
	
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	if shield_pivot:
		var pt := create_tween()
		pt.tween_property(shield_pivot, "scale", Vector3(1.2, 1.2, 1.2), 0.06)
		pt.tween_property(shield_pivot, "scale", Vector3.ONE, 0.14)
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.15)
	
	if proj and is_instance_valid(proj):
		if proj.has_method("_spawn_impact_vfx"):
			proj.call("_spawn_impact_vfx", proj.global_position)
		proj.queue_free()
	
	if _hits_left <= 0:
		shield_broken.emit()
		fade_out()

func fade_out() -> void:
	if _is_fading:
		return
	_is_fading = true
	shield_expired.emit()
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _is_caster_or_self(other_node: Node) -> bool:
	if other_node == null or caster == null:
		return false
	if other_node == caster or other_node == self:
		return true
	if caster.is_ancestor_of(other_node) or other_node.is_ancestor_of(caster):
		return true
	return false
