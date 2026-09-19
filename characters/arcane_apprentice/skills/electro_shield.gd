class_name ElectroShieldSpell
extends Node3D

## Ornate Medieval Round Shield with Electric Blue Steel & Gold Filigree
signal shield_broken
signal shield_expired

@export var duration: float = 5.0
@export var max_hits: int = 5

var caster: Node3D = null
var _time_remaining: float = 5.0
var _hits_left: int = 5
var _is_fading: bool = false

@onready var shield_area: Area3D = $HitArea
@onready var shield_pivot: Node3D = get_node_or_null("ShieldPivot")
@onready var electric_aura: MeshInstance3D = find_child("ElectricAura", true, false) as MeshInstance3D
@onready var shield_light: OmniLight3D = $ShieldLight
@onready var sparks: GPUParticles3D = $Sparks

func _ready() -> void:
	_time_remaining = duration
	_hits_left = max_hits
	
	if shield_area:
		shield_area.area_entered.connect(_on_area_entered)
		shield_area.body_entered.connect(_on_body_entered)
	
	# Pop-in scale animation
	scale = Vector3(0.01, 0.01, 0.01)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.12)

func _physics_process(delta: float) -> void:
	if _is_fading:
		return
	
	var time_ms := Time.get_ticks_msec()
	
	# Anchor to caster position and face aiming direction
	if caster and is_instance_valid(caster):
		var aim_dir := Vector3.FORWARD
		if caster.has_method("_get_mouse_aim_direction"):
			aim_dir = caster.call("_get_mouse_aim_direction")
		else:
			aim_dir = -caster.global_transform.basis.z
			aim_dir.y = 0.0
		
		if aim_dir.length_squared() > 0.01:
			aim_dir = aim_dir.normalized()
			# Smoothly orient shield towards aim (QuadMesh front face is +Z)
			var target_rot_y := atan2(aim_dir.x, aim_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, 22.0 * delta)
		
		# Position floating protectively in front of caster with ample distance (1.75m)
		var hover_y: float = sin(time_ms * 0.006) * 0.04
		var target_pos: Vector3 = caster.global_position + Vector3(0, 0.95 + hover_y, 0) + aim_dir * 1.75
		global_position = global_position.lerp(target_pos, 24.0 * delta)
	
	# Rotate subtle electric aura ring
	if electric_aura:
		electric_aura.rotation.z += 2.5 * delta
		
	# Subtle gentle backlight pulse (soft ambient illumination)
	if shield_light:
		shield_light.light_energy = 0.8 + sin(time_ms * 0.005) * 0.15
	
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
	
	# Flash light & sparks
	if shield_light:
		shield_light.light_energy = 2.2
		var lt := create_tween()
		lt.tween_property(shield_light, "light_energy", 0.8, 0.2)
	
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	# Metallic impact punch scale recoil
	if shield_pivot:
		var pt := create_tween()
		pt.tween_property(shield_pivot, "scale", Vector3(1.18, 1.18, 1.18), 0.05)
		pt.tween_property(shield_pivot, "scale", Vector3.ONE, 0.12)
	
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.14)
	
	# Disarm projectile
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
