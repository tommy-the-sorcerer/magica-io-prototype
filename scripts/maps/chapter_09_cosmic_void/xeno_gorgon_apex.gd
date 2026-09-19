class_name XenoGorgonApex
extends BaseBoss

## Chapter 9 Boss: Xeno-Gorgon Apex (Extraterrestrial Dreadnought)
## Bio-mechanical alien titan with orbital laser beams, gravitational singularities, and plasma missile swarms

@export var attack_cooldown: float = 2.0
var attack_timer: float = 1.0
var laser_timer: float = 6.0
var singularity_timer: float = 8.5

@onready var void_ring: Node3D = $Visuals/VoidRing
@onready var left_cannon: Node3D = $Visuals/LeftCannon
@onready var right_cannon: Node3D = $Visuals/RightCannon

func _ready() -> void:
	boss_name = "Xeno-Gorgon Apex — Cosmic Dreadnought"
	max_health = 1400.0
	move_speed = 4.8
	attack_damage = 52.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if void_ring:
		void_ring.rotate_y(1.5 * delta)
		void_ring.rotate_z(0.8 * delta)
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		var dir := (target_player.global_position - global_position).normalized()
		dir.y = 0
		
		look_at_target(target_player.global_position, delta)
		
		var target_vel := calculate_unanticipated_velocity(target_player.global_position, 5.0, delta)
		velocity.x = target_vel.x
		velocity.z = target_vel.z
			
		attack_timer -= delta
		laser_timer -= delta
		singularity_timer -= delta
		
		# Orbital Laser Strike
		if laser_timer <= 0.0 and can_act:
			laser_timer = randf_range(7.0, 9.5) if current_phase < BossPhase.PHASE_4 else 4.0
			_perform_orbital_laser()
			return
			
		# Anti-Gravity Singularity
		if singularity_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			singularity_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_singularity()
			return
			
		# Plasma Missiles or Melee Energy Slam
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.0
			if dist <= 5.5:
				_perform_plasma_slam()
			else:
				_perform_plasma_missiles()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	update_procedural_locomotion(delta)

## 1. Orbital Laser Strike (Targeted Beam from Sky)
func _perform_orbital_laser() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	set_facial_state(FacialState.ATTACK_ROAR, 1.4)
	
	var strike_pos: Vector3 = target_player.global_position
	strike_pos.y = 0.1
	create_telegraph_circle(strike_pos, 4.0, 1.0, Color(0.0, 0.95, 1.0, 0.85))
	
	get_tree().create_timer(1.0).timeout.connect(func():
		_fire_laser_pillar(strike_pos)
		can_act = true
	)

func _fire_laser_pillar(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 2.0)
	
	var laser := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.0
	cyl.bottom_radius = 2.0
	cyl.height = 30.0
	laser.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.9, 1.0, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.95, 1.0, 1.0)
	mat.emission_energy_multiplier = 6.0
	laser.material_override = mat
	
	get_parent().add_child(laser)
	laser.global_position = pos + Vector3(0, 15.0, 0)
	
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = pos.distance_to((c as Node3D).global_position)
			if d <= 4.2:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(55.0, self)
				if c is CharacterBody3D:
					var knock := ((c as Node3D).global_position - pos).normalized()
					(c as CharacterBody3D).velocity += knock * 18.0
					
	var tw := create_tween()
	tw.tween_property(laser, "scale", Vector3(1.4, 1.0, 1.4), 0.15)
	tw.tween_property(laser, "scale", Vector3(0.0, 1.0, 0.0), 0.25)
	tw.tween_callback(laser.queue_free)

## 2. Anti-Gravity Singularity Vortex
func _perform_singularity() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	set_facial_state(FacialState.ATTACK_ROAR, 1.2)
	
	var vortex_pos: Vector3 = target_player.global_position
	vortex_pos.y = 0.1
	create_telegraph_circle(vortex_pos, 5.0, 0.8, Color(0.9, 0.05, 0.8, 0.8))
	
	get_tree().create_timer(0.8).timeout.connect(func():
		_spawn_singularity_field(vortex_pos)
		can_act = true
	)

func _spawn_singularity_field(pos: Vector3) -> void:
	var sphere_node := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 1.2
	s_mesh.height = 2.4
	sphere_node.mesh = s_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.0, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 4.0
	sphere_node.material_override = mat
	
	get_parent().add_child(sphere_node)
	sphere_node.global_position = pos + Vector3(0, 1.5, 0)
	
	for i in range(10):
		get_tree().create_timer(i * 0.35).timeout.connect(func():
			if not is_instance_valid(sphere_node): return
			sphere_node.rotate_y(0.4)
			var combatants := get_tree().get_nodes_in_group("combatants")
			for c in combatants:
				if is_instance_valid(c) and c != self and c is Node3D:
					var d: float = pos.distance_to((c as Node3D).global_position)
					if d <= 5.5:
						var pull_dir := (pos - (c as Node3D).global_position).normalized()
						if c is CharacterBody3D:
							(c as CharacterBody3D).velocity += pull_dir * 4.5
						var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
						if hp:
							hp.take_damage(6.0, self)
		)
		
	get_tree().create_timer(3.6).timeout.connect(func():
		if is_instance_valid(sphere_node):
			sphere_node.queue_free()
	)

## 3. Plasma Missiles Volley
func _perform_plasma_missiles() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	set_facial_state(FacialState.ATTACK_ROAR, 1.0)
	var count: int = 4 if current_phase < BossPhase.PHASE_4 else 7
	var base_pos: Vector3 = target_player.global_position
	
	for i in range(count):
		var offset := Vector3(randf_range(-4.0, 4.0), 0, randf_range(-4.0, 4.0))
		var dest := base_pos + offset
		dest.y = 0.1
		create_telegraph_circle(dest, 2.6, 0.9, Color(0.0, 0.9, 1.0, 0.75))
		
		get_tree().create_timer(0.9 + (i * 0.12)).timeout.connect(func():
			_drop_plasma_blast(dest)
		)

func _drop_plasma_blast(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.2)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = pos.distance_to((c as Node3D).global_position)
			if d <= 2.8:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(32.0, self)

func _perform_plasma_slam() -> void:
	can_act = false
	set_facial_state(FacialState.ATTACK_ROAR, 0.8)
	var hit_pos := global_position + (-global_transform.basis.z * 3.0)
	create_telegraph_circle(hit_pos, 3.8, 0.6, Color(0.0, 0.9, 1.0, 0.85))
	
	get_tree().create_timer(0.5).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.5)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = hit_pos.distance_to((c as Node3D).global_position)
				if d <= 4.0:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
		can_act = true
	)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	match phase:
		2:
			attack_cooldown = 1.8
			attack_damage = 58.0
		3:
			attack_cooldown = 1.4
			move_speed = 5.6
		4:
			# Hyperdrive Overdrive
			attack_cooldown = 0.9
			move_speed = 7.0
			attack_damage = 70.0
			set_facial_state(FacialState.ENRAGE_FLARE, 999.0)
