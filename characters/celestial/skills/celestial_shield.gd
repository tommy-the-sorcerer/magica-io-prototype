class_name CelestialShieldSpell
extends Node3D

## 4-Sided Divine Aegis Celestial Shield
## Spawns 4 independent barrier shields around the player (Front, Back, Left, Right).
## Each shield features a luminous 3D Heaven Sign emblem (Holy Cross, Halo Ring, Angel Wings).
## Each shield independently intercepts and blocks incoming enemy attacks/projectiles.

signal shield_broken(side: String)
signal shield_expired

@export var duration: float = 6.0
@export var hits_per_shield: int = 3

var caster: Node3D = null
var _time_remaining: float = 6.0
var _is_fading: bool = false

# Durability per side
var _shield_durability: Dictionary = {
	"Front": 3,
	"Back": 3,
	"Left": 3,
	"Right": 3
}

var _shield_nodes: Dictionary = {}
var _shield_areas: Dictionary = {}
var _sparks_particles: Dictionary = {}

var ground_rune: MeshInstance3D = null
var rune_light: OmniLight3D = null

func _ready() -> void:
	_time_remaining = duration
	
	# Register the ground arcane symbol seal
	ground_rune = find_child("GroundRune", true, false) as MeshInstance3D
	rune_light = find_child("RuneLight", true, false) as OmniLight3D
	if ground_rune:
		ground_rune.scale = Vector3(0.01, 0.01, 0.01)
		var rune_tween := create_tween()
		rune_tween.tween_property(ground_rune, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Register the 4 sides
	var sides := ["Front", "Back", "Left", "Right"]
	for s in sides:
		var node: Node3D = find_child("Shield" + s, true, false) as Node3D
		if node:
			_shield_nodes[s] = node
			_shield_durability[s] = hits_per_shield
			
			var area: Area3D = node.find_child("HitArea", true, false) as Area3D
			if area:
				_shield_areas[s] = area
				area.area_entered.connect(_on_shield_area_entered.bind(s))
				area.body_entered.connect(_on_shield_body_entered.bind(s))
			
			var sparks: GPUParticles3D = node.find_child("BlockSparks", true, false) as GPUParticles3D
			if sparks:
				_sparks_particles[s] = sparks
			
			# Materialization pop animation
			node.scale = Vector3(0.01, 0.01, 0.01)
			var tween := create_tween()
			tween.tween_property(node, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Play summon camera pulse
	var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
	if cam:
		cam.add_shake(0.18)

func _physics_process(delta: float) -> void:
	if _is_fading:
		return
	
	# Anchor to caster position if caster exists
	if caster and is_instance_valid(caster):
		global_position = caster.global_position
		# Match caster yaw rotation gently
		global_rotation.y = caster.global_rotation.y
	
	# Gentle celestial levitation bobbing
	var time_ms := Time.get_ticks_msec()
	var bob: float = sin(time_ms * 0.003) * 0.04
	for s in _shield_nodes:
		var node: Node3D = _shield_nodes[s]
		if is_instance_valid(node):
			node.position.y = 0.6 + bob
	
	# Rotate ground arcane rune seal gracefully on the floor beneath the hero
	if ground_rune and is_instance_valid(ground_rune):
		ground_rune.rotate_object_local(Vector3(0, 0, 1), 0.35 * delta)
	if rune_light and is_instance_valid(rune_light):
		rune_light.light_energy = 2.2 + sin(time_ms * 0.005) * 0.45
	
	# Lifetime countdown
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		fade_out()

## Intercepts Area3D projectiles (Spells like Fireball, Ice Lance, Solar Beam)
func _on_shield_area_entered(area: Area3D, side: String) -> void:
	if _is_fading or not _shield_durability.has(side) or _shield_durability[side] <= 0:
		return
	
	# If this area is a projectile
	if area is Projectile:
		var proj: Projectile = area as Projectile
		# Don't block caster's own attacks
		if _is_caster_or_self(proj.caster):
			return
		_block_projectile(proj, side)
	elif area.get_parent() is Projectile:
		var parent_proj: Projectile = area.get_parent() as Projectile
		if _is_caster_or_self(parent_proj.caster):
			return
		_block_projectile(parent_proj, side)

## Intercepts physical body collisions
func _on_shield_body_entered(body: Node3D, side: String) -> void:
	if _is_fading or not _shield_durability.has(side) or _shield_durability[side] <= 0:
		return
	
	if body is Projectile:
		var proj: Projectile = body as Projectile
		if _is_caster_or_self(proj.caster):
			return
		_block_projectile(proj, side)

## Blocks and absorbs an incoming attack on a specific shield side
func _block_projectile(proj: Node3D, side: String) -> void:
	if not _shield_durability.has(side) or _shield_durability[side] <= 0:
		return
	
	_shield_durability[side] -= 1
	var remaining: int = _shield_durability[side]
	
	var node: Node3D = _shield_nodes.get(side, null)
	if node and is_instance_valid(node):
		# Burst golden deflection sparks
		var sparks: GPUParticles3D = _sparks_particles.get(side, null)
		if sparks and is_instance_valid(sparks):
			sparks.restart()
			sparks.emitting = true
		
		# Flash Heaven Sign and shield plate
		_flash_shield(node)
		
		# Camera tactile impact feedback
		var cam: CameraFollow = get_viewport().get_camera_3d() as CameraFollow
		if cam:
			cam.add_shake(0.14)
	
	# Disarm and cleanly neutralize projectile so it doesn't harm caster
	if proj and is_instance_valid(proj):
		if proj.has_method("_spawn_impact_vfx"):
			proj.call("_spawn_impact_vfx", proj.global_position)
		proj.queue_free()
	
	# Check if this side shield is shattered
	if remaining <= 0:
		_shatter_shield(side)

## Flashes the shield and Heaven Sign with intense golden celestial radiance
func _flash_shield(shield_node: Node3D) -> void:
	var light: OmniLight3D = shield_node.find_child("ShieldLight", true, false) as OmniLight3D
	if light:
		light.light_energy = 5.0
		var lt: Tween = create_tween()
		lt.tween_property(light, "light_energy", 1.2, 0.25)
	
	# Punch scale on impact
	var orig_scale: Vector3 = shield_node.scale
	var st: Tween = create_tween()
	st.tween_property(shield_node, "scale", orig_scale * 1.12, 0.06)
	st.tween_property(shield_node, "scale", orig_scale, 0.12)

## Shatters an individual side shield when its durability is depleted
func _shatter_shield(side: String) -> void:
	shield_broken.emit(side)
	
	var node: Node3D = _shield_nodes.get(side, null)
	if node and is_instance_valid(node):
		# Disable collision
		var area: Area3D = _shield_areas.get(side, null)
		if area and is_instance_valid(area):
			area.set_deferred("monitoring", false)
			area.set_deferred("monitorable", false)
		
		# Golden shatter burst
		var tween := create_tween()
		tween.tween_property(node, "scale", Vector3(1.3, 1.3, 1.3), 0.08)
		tween.parallel().tween_property(node, "position:y", node.position.y - 0.2, 0.2)
		tween.tween_property(node, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
		tween.tween_callback(func():
			if is_instance_valid(node):
				node.visible = false
		)
	
	# Check if all shields are destroyed
	var any_alive: bool = false
	for s in _shield_durability:
		if _shield_durability[s] > 0:
			any_alive = true
			break
	
	if not any_alive:
		fade_out()

## Gracefully fades out any remaining shields and destroys the barrier
func fade_out() -> void:
	if _is_fading:
		return
	_is_fading = true
	shield_expired.emit()
	
	for s in _shield_nodes:
		var node: Node3D = _shield_nodes[s]
		if is_instance_valid(node) and node.visible:
			var tween := create_tween()
			tween.tween_property(node, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	
	if ground_rune and is_instance_valid(ground_rune):
		var rt := create_tween()
		rt.tween_property(ground_rune, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	if rune_light and is_instance_valid(rune_light):
		var lt := create_tween()
		lt.tween_property(rune_light, "light_energy", 0.0, 0.25)
	
	get_tree().create_timer(0.3).timeout.connect(queue_free)

func _is_caster_or_self(other_node: Node) -> bool:
	if other_node == null or caster == null:
		return false
	if other_node == caster or other_node == self:
		return true
	if caster.is_ancestor_of(other_node) or other_node.is_ancestor_of(caster):
		return true
	return false
