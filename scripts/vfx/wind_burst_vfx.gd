class_name WindBurstVFX
extends Node3D

## Premium AAA Wind Burst Visual & Audio Effects
## Features an expanding cyan shockwave ring, rotating celestial ground rune,
## spiraling wind ribbons, floating white feathers, dust ripple, and layered procedural audio.

@onready var ground_rune: MeshInstance3D = $GroundRune
@onready var shockwave_ring: MeshInstance3D = $ShockwaveRing
@onready var dust_ripple: MeshInstance3D = $DustRipple
@onready var feather_particles: GPUParticles3D = $FeatherParticles
@onready var sparkle_particles: GPUParticles3D = $SparkleParticles
@onready var burst_light: OmniLight3D = $BurstLight
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var ribbons_parent: Node3D = $RibbonsParent

var _rune_material: StandardMaterial3D = null
var _shockwave_material: StandardMaterial3D = null
var _dust_material: StandardMaterial3D = null
var _is_spinning_rune: bool = true

func _ready() -> void:
	# Clone materials for independent alpha tweening
	if ground_rune and ground_rune.mesh and ground_rune.mesh.material:
		_rune_material = ground_rune.mesh.material.duplicate() as StandardMaterial3D
		ground_rune.material_override = _rune_material
	
	if shockwave_ring and shockwave_ring.mesh and shockwave_ring.mesh.material:
		_shockwave_material = shockwave_ring.mesh.material.duplicate() as StandardMaterial3D
		shockwave_ring.material_override = _shockwave_material

	if dust_ripple and dust_ripple.mesh and dust_ripple.mesh.material:
		_dust_material = dust_ripple.mesh.material.duplicate() as StandardMaterial3D
		dust_ripple.material_override = _dust_material

	# 1. Play Sound
	if audio_player:
		audio_player.pitch_scale = randf_range(0.96, 1.05)
		audio_player.play()

	# 2. Ground Rune Animation
	if ground_rune:
		ground_rune.scale = Vector3(0.01, 0.01, 0.01)
		var rune_tween := create_tween()
		rune_tween.tween_property(ground_rune, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rune_tween.tween_interval(0.12)
		if _rune_material:
			rune_tween.parallel().tween_property(_rune_material, "albedo_color:a", 0.0, 0.35)
		rune_tween.tween_callback(func(): _is_spinning_rune = false)

	# 3. Expanding Shockwave Ring (expands rapidly outward to 5.0m)
	if shockwave_ring:
		shockwave_ring.scale = Vector3(0.1, 0.1, 0.1)
		var ring_tween := create_tween()
		ring_tween.tween_property(shockwave_ring, "scale", Vector3(9.6, 1.0, 9.6), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _shockwave_material:
			ring_tween.parallel().tween_property(_shockwave_material, "albedo_color:a", 0.0, 0.32)

	# 4. Floor Dust Ripple
	if dust_ripple:
		dust_ripple.scale = Vector3(0.2, 0.2, 0.2)
		var dust_tween := create_tween()
		dust_tween.tween_property(dust_ripple, "scale", Vector3(9.2, 1.0, 9.2), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _dust_material:
			dust_tween.parallel().tween_property(_dust_material, "albedo_color:a", 0.0, 0.38)

	# 5. Burst Light Flash
	if burst_light:
		burst_light.light_energy = 4.8
		var light_tween := create_tween()
		light_tween.tween_property(burst_light, "light_energy", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 6. Particles
	if feather_particles:
		feather_particles.restart()
		feather_particles.emitting = true
	if sparkle_particles:
		sparkle_particles.restart()
		sparkle_particles.emitting = true

	# 7. Self cleanup after animation finishes
	get_tree().create_timer(1.2).timeout.connect(queue_free)

func _process(delta: float) -> void:
	# Spin ground rune
	if _is_spinning_rune and ground_rune and is_instance_valid(ground_rune):
		ground_rune.rotate_object_local(Vector3(0, 0, 1), 2.2 * delta)

	# Spin spiral wind ribbons
	if ribbons_parent and is_instance_valid(ribbons_parent):
		ribbons_parent.rotation.y += 8.0 * delta
		ribbons_parent.scale = ribbons_parent.scale.move_toward(Vector3(6.5, 1.2, 6.5), 16.0 * delta)
