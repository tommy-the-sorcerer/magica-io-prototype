class_name SporeQueenNightshade
extends BaseBoss

## Chapter 5 Boss: Spore-Queen Nightshade (Toxic Broodmother)
## Sinister fungal broodmother with acid spore clusters, noxious puddles, and venom pounces

@export var attack_cooldown: float = 2.2
var attack_timer: float = 1.0
var pool_timer: float = 6.5
var pounce_timer: float = 8.0

@onready var head_mandibles: Node3D = $Visuals/Head/LeftMandible

func _ready() -> void:
	boss_name = "Nightshade — Spore Queen of the Grove"
	max_health = 1100.0
	move_speed = 4.5
	attack_damage = 40.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		
		# Rotate toward player
		look_at_target(target_player.global_position, delta)
		
		# Erratic predatory skittering (stalking orbit, zig-zag rush, sudden pounce feints)
		velocity = calculate_unanticipated_velocity(target_player.global_position, 4.0, delta)
		
		# Multi-legged skittering kinematics, abdomen bobbing, forward charge lean
		update_procedural_locomotion(delta)
			
		attack_timer -= delta
		pool_timer -= delta
		pounce_timer -= delta
		
		# Venom Pounce if at medium/long distance
		if pounce_timer <= 0.0 and dist > 6.0 and can_act:
			pounce_timer = randf_range(7.0, 10.0) if current_phase < BossPhase.PHASE_4 else 4.5
			_perform_venom_pounce()
			return
			
		# Noxious Pool Eruption
		if pool_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			pool_timer = 8.5 if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_noxious_pools()
			return
			
		# Spore Cluster Shot or Mandible Cleave
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.2
			if dist <= 5.0:
				_perform_mandible_cleave()
			else:
				_perform_spore_cluster()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Noxious Pool Eruptions
func _perform_noxious_pools() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var target_base: Vector3 = target_player.global_position
	var count: int = 3 if current_phase < BossPhase.PHASE_4 else 5
	
	for i in range(count):
		var offset := Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
		var pool_pos := target_base + offset
		pool_pos.y = 0.05
		
		create_telegraph_circle(pool_pos, 3.2, 0.8, Color(0.7, 0.1, 0.9, 0.8))
		
		get_tree().create_timer(0.8).timeout.connect(func():
			_spawn_acid_puddle(pool_pos)
		)
		
	get_tree().create_timer(1.2).timeout.connect(func(): can_act = true)

func _spawn_acid_puddle(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.2)
	var puddle := Area3D.new()
	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 3.2
	cyl_shape.height = 0.5
	col.shape = cyl_shape
	puddle.add_child(col)
	
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.2
	cyl.bottom_radius = 3.2
	cyl.height = 0.1
	mi.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.1, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.85, 0.1, 1.0)
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat
	puddle.add_child(mi)
	
	get_parent().add_child(puddle)
	puddle.global_position = pos
	
	# Lingers for 4 seconds, ticking damage
	for step in range(8):
		get_tree().create_timer(step * 0.5).timeout.connect(func():
			if not is_instance_valid(puddle):
				return
			var combatants := get_tree().get_nodes_in_group("combatants")
			for c in combatants:
				if is_instance_valid(c) and c != self and c is Node3D:
					var d: float = pos.distance_to((c as Node3D).global_position)
					if d <= 3.4:
						var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
						if hp:
							hp.take_damage(6.0, self)
		)
		
	get_tree().create_timer(4.2).timeout.connect(func():
		if is_instance_valid(puddle):
			puddle.queue_free()
	)

## 2. Venom Pounce (Forward Leap Strike)
func _perform_venom_pounce() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var target_pos: Vector3 = target_player.global_position
	create_telegraph_circle(target_pos, 3.8, 0.7, Color(1.0, 0.15, 0.2, 0.8))
	
	var fwd := (target_pos - global_position).normalized()
	fwd.y = 0
	
	var tw := create_tween()
	tw.set_parallel(false)
	tw.tween_property(self, "global_position", global_position + (fwd * 2.0) + Vector3(0, 3.0, 0), 0.3)
	tw.tween_property(self, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		boss_attack_slammed.emit(target_pos, 1.6)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = target_pos.distance_to((c as Node3D).global_position)
				if d <= 4.2:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(44.0, self)
		can_act = true
	)

## 3. Spore Cluster Projectiles
func _perform_spore_cluster() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	var base_dir := (target_player.global_position - global_position).normalized()
	base_dir.y = 0
	
	var angles := [-0.3, 0.0, 0.3] if current_phase < BossPhase.PHASE_4 else [-0.5, -0.25, 0.0, 0.25, 0.5]
	for a in angles:
		var dir := base_dir.rotated(Vector3.UP, a)
		_spawn_spore(dir)

func _spawn_spore(dir: Vector3) -> void:
	var spore := Area3D.new()
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	col.shape = sphere
	spore.add_child(col)
	
	var mi := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.45
	s_mesh.height = 0.9
	mi.mesh = s_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.1, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.0, 0.85, 1.0)
	mat.emission_energy_multiplier = 3.5
	mi.material_override = mat
	spore.add_child(mi)
	
	get_parent().add_child(spore)
	spore.global_position = global_position + Vector3(0, 1.8, 0)
	
	var tw := create_tween()
	tw.tween_property(spore, "global_position", spore.global_position + (dir * 22.0), 1.2)
	tw.tween_callback(spore.queue_free)
	
	spore.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(26.0, self)
				spore.queue_free()
	)

func _perform_mandible_cleave() -> void:
	can_act = false
	var hit_pos := global_position + (-global_transform.basis.z * 2.6)
	create_telegraph_circle(hit_pos, 3.2, 0.55, Color(0.9, 0.1, 0.4, 0.8))
	
	get_tree().create_timer(0.5).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.2)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = hit_pos.distance_to((c as Node3D).global_position)
				if d <= 3.5:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
		can_act = true
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 1.9
			attack_damage = 45.0
		3:
			attack_cooldown = 1.5
			move_speed = 5.2
		4:
			# Toxic Bloom Frenzy
			attack_cooldown = 1.0
			move_speed = 6.4
			attack_damage = 54.0
