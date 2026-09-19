class_name AnubisScytheLord
extends BaseBoss

## Chapter 2 Boss: Anubis Scythe-Lord (Dune Reaper & Desert God)
## Deadly desert deity with teleport strike, quicksand vortices, and crescent scythe slashes

@export var attack_cooldown: float = 2.2
var attack_timer: float = 1.0
var teleport_timer: float = 5.0
var vortex_timer: float = 7.0

@onready var scythe_arm: Node3D = $Visuals/RightArmPivot
@onready var scythe_blade: Node3D = $Visuals/RightArmPivot/ScytheBlade

func _ready() -> void:
	boss_name = "Anubis — Scythe Lord of the Dunes"
	max_health = 850.0
	move_speed = 4.8
	attack_damage = 38.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		
		# Rotate smoothly to target
		look_at_target(target_player.global_position, delta)
		
		# Dynamic erratic movement (orbiting, zig-zag rushes, feint steps)
		velocity = calculate_unanticipated_velocity(target_player.global_position, 3.8, delta)
		
		# Procedural footstep strides, pendulum legs, forward sprint lean, and banking
		update_procedural_locomotion(delta)
			
		# Ability Timers
		attack_timer -= delta
		teleport_timer -= delta
		vortex_timer -= delta
		
		# Teleport behind player if far away
		if teleport_timer <= 0.0 and dist > 8.0 and can_act:
			teleport_timer = randf_range(6.0, 9.0) if current_phase < BossPhase.PHASE_4 else 4.0
			_perform_mirage_teleport()
			return
			
		# Spawn quicksand vortex in Phase 2+
		if vortex_timer <= 0.0 and current_phase >= BossPhase.PHASE_2 and can_act:
			vortex_timer = 8.5
			_perform_quicksand_vortex()
			
		# Melee Scythe Cleave
		if attack_timer <= 0.0 and dist <= 6.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.2
			_perform_scythe_cleave()
	else:
		velocity.x = 0
		velocity.z = 0
		update_procedural_locomotion(delta)

	move_and_slide()

## 1. Scythe Cleave with Red Crescent Telegraph
func _perform_scythe_cleave() -> void:
	can_act = false
	is_attacking_anim = true
	set_facial_state(FacialState.ATTACK_ROAR, 0.7)
	
	var strike_pos := global_position + (-global_transform.basis.z * 2.5)
	create_telegraph_circle(strike_pos, 3.2, 0.6, Color(1.0, 0.25, 0.1, 0.75))
	
	# Scythe swing animation
	if scythe_arm:
		var tw := create_tween()
		tw.tween_property(scythe_arm, "rotation:y", 1.8, 0.25)
		tw.tween_property(scythe_arm, "rotation:y", -1.8, 0.18)
		tw.tween_property(scythe_arm, "rotation:y", 0.0, 0.2)
		tw.tween_callback(func(): is_attacking_anim = false)
		
	get_tree().create_timer(0.45).timeout.connect(func():
		_execute_scythe_damage(strike_pos)
		can_act = true
	)

func _execute_scythe_damage(hit_pos: Vector3) -> void:
	boss_attack_slammed.emit(hit_pos, 1.2)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = hit_pos.distance_to((c as Node3D).global_position)
			if d <= 3.6:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(attack_damage, self)
					
	# In Phase 4, release flying sand-scythe wave
	if current_phase == BossPhase.PHASE_4:
		_spawn_sand_wave()

## 2. Mirage Shadow Step (Teleport Behind Player)
func _perform_mirage_teleport() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	# Disappear in sand poof
	var tw := create_tween()
	tw.tween_property(visuals, "scale", Vector3(0.1, 2.0, 0.1), 0.2)
	tw.tween_property(visuals, "scale", Vector3.ZERO, 0.1)
	
	# Calculate position behind player
	var p_fwd: Vector3 = -target_player.global_transform.basis.z.normalized()
	var dest_pos: Vector3 = target_player.global_position - (p_fwd * 2.8)
	dest_pos.y = 0.2
	
	create_telegraph_circle(dest_pos, 2.8, 0.6, Color(1.0, 0.8, 0.1, 0.8))
	
	get_tree().create_timer(0.45).timeout.connect(func():
		global_position = dest_pos
		look_at_target(target_player.global_position, 1.0)
		var appear_tw := create_tween()
		appear_tw.tween_property(visuals, "scale", Vector3(1.2, 1.2, 1.2), 0.15)
		appear_tw.tween_property(visuals, "scale", Vector3.ONE, 0.1)
		
		# Immediate ambush slash!
		_perform_scythe_cleave()
	)

## 3. Quicksand Vortex Hazard
func _perform_quicksand_vortex() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	var vortex_pos: Vector3 = target_player.global_position
	vortex_pos.y = 0.05
	
	# Red/amber warning ring
	create_telegraph_circle(vortex_pos, 4.0, 0.8, Color(0.9, 0.5, 0.1, 0.7))
	
	get_tree().create_timer(0.8).timeout.connect(func():
		_spawn_vortex_area(vortex_pos)
	)

func _spawn_vortex_area(pos: Vector3) -> void:
	var vortex := Area3D.new()
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 4.0
	col.shape = sphere
	vortex.add_child(col)
	
	# Visual mesh for swirling sand
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.8
	cyl.bottom_radius = 3.8
	cyl.height = 0.15
	mesh_inst.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.65, 0.25, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.5, 0.1, 1.0)
	mat.emission_energy_multiplier = 1.5
	mesh_inst.material_override = mat
	vortex.add_child(mesh_inst)
	
	get_parent().add_child(vortex)
	vortex.global_position = pos
	
	# Vortex pull and damage over 4.5 seconds
	var elapsed := 0.0
	var timer := get_tree().create_timer(4.5)
	
	var check_tree = get_tree()
	var update_callable = func():
		if not is_instance_valid(vortex):
			return
		mesh_inst.rotate_y(0.12)
		if target_player and is_instance_valid(target_player):
			var dist := pos.distance_to(target_player.global_position)
			if dist <= 4.2:
				# Pull player inward
				var pull_dir := (pos - target_player.global_position).normalized()
				if target_player is CharacterBody3D:
					(target_player as CharacterBody3D).velocity += pull_dir * 3.5
				var hp: HealthComponent = target_player.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(2.5, self)
					
	# Process pull with timer loop
	for i in range(18):
		check_tree.create_timer(i * 0.25).timeout.connect(update_callable)
		
	timer.timeout.connect(func():
		if is_instance_valid(vortex):
			vortex.queue_free()
	)

func _spawn_sand_wave() -> void:
	var proj_mesh := BoxMesh.new()
	proj_mesh.size = Vector3(2.5, 0.4, 0.4)
	
	var wave := Area3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 0.6, 0.6)
	col.shape = box
	wave.add_child(col)
	
	var mi := MeshInstance3D.new()
	mi.mesh = proj_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1, 1.0)
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	wave.add_child(mi)
	
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector3(0, 1.2, 0)
	wave.rotation.y = rotation.y
	
	var fwd := -global_transform.basis.z.normalized()
	var tw := create_tween()
	tw.tween_property(wave, "global_position", wave.global_position + (fwd * 25.0), 1.2)
	tw.tween_callback(wave.queue_free)
	
	wave.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(30.0, self)
				wave.queue_free()
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 1.9
			attack_damage = 42.0
		3:
			attack_cooldown = 1.5
			move_speed = 5.6
		4:
			# Sandstorm Frenzy
			attack_cooldown = 1.1
			move_speed = 6.8
			attack_damage = 50.0
