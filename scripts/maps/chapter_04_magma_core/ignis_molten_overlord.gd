class_name IgnisMoltenOverlord
extends BaseBoss

## Chapter 4 Boss: Ignis the Molten Overlord (Titan of Burning Caldera)
## Devastating magma titan with Caldera Bombardment, molten shockwaves, and lava spit

@export var attack_cooldown: float = 2.4
var attack_timer: float = 1.0
var bombard_timer: float = 6.0
var stomp_timer: float = 8.5

@onready var core_chest: MeshInstance3D = $Visuals/Torso/MagmaCore

func _ready() -> void:
	boss_name = "Ignis — Molten Overlord of Caldera"
	max_health = 1050.0
	move_speed = 4.0
	attack_damage = 45.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		var dir := (target_player.global_position - global_position).normalized()
		dir.y = 0
		
		look_at_target(target_player.global_position, delta)
		
		if dist > 4.5:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)
			
		attack_timer -= delta
		bombard_timer -= delta
		stomp_timer -= delta
		
		# Caldera Bombardment
		if bombard_timer <= 0.0 and can_act:
			bombard_timer = randf_range(6.5, 9.0) if current_phase < BossPhase.PHASE_4 else 4.0
			_perform_caldera_bombardment()
			return
			
		# Molten Shockwave Stomp in Phase 2+
		if stomp_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			stomp_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.5
			_perform_molten_stomp()
			return
			
		# Fireball Spits or Melee Slam
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.2
			if dist <= 5.5:
				_perform_magma_slam()
			else:
				_perform_fireball_burst()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Caldera Bombardment (3-4 Ground Telegraph Circles + Meteors)
func _perform_caldera_bombardment() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	# Pulse chest core
	if core_chest:
		var tw := create_tween()
		tw.tween_property(core_chest, "scale", Vector3(1.6, 1.6, 1.6), 0.3)
		tw.tween_property(core_chest, "scale", Vector3.ONE, 0.2)
		
	var target_base: Vector3 = target_player.global_position
	var meteor_count: int = 3 if current_phase < BossPhase.PHASE_4 else 5
	
	for i in range(meteor_count):
		var offset := Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.5, 4.5))
		var impact_pos := target_base + offset
		impact_pos.y = 0.1
		
		# Red danger warning decal
		create_telegraph_circle(impact_pos, 3.2, 1.0, Color(1.0, 0.2, 0.05, 0.8))
		
		# Delay meteor spawn slightly per impact
		get_tree().create_timer(1.0 + (i * 0.15)).timeout.connect(func():
			_drop_magma_meteor(impact_pos)
		)
		
	get_tree().create_timer(1.6).timeout.connect(func(): can_act = true)

func _drop_magma_meteor(impact_pos: Vector3) -> void:
	var meteor := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	meteor.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.05, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0, 1.0)
	mat.emission_energy_multiplier = 4.0
	meteor.material_override = mat
	
	get_parent().add_child(meteor)
	meteor.global_position = impact_pos + Vector3(0, 15.0, 0)
	
	var tw := create_tween()
	tw.tween_property(meteor, "global_position:y", impact_pos.y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_explode_meteor(impact_pos)
		meteor.queue_free()
	)

func _explode_meteor(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.5)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = pos.distance_to((c as Node3D).global_position)
			if d <= 3.4:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(38.0, self)

## 2. Molten Stomp Shockwave
func _perform_molten_stomp() -> void:
	can_act = false
	create_telegraph_circle(global_position, 6.0, 0.7, Color(1.0, 0.35, 0.0, 0.8))
	
	var tw := create_tween()
	tw.tween_property(visuals, "position:y", 1.8, 0.3)
	tw.tween_property(visuals, "position:y", 0.0, 0.2)
	
	get_tree().create_timer(0.55).timeout.connect(func():
		boss_attack_slammed.emit(global_position, 2.0)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = global_position.distance_to((c as Node3D).global_position)
				if d <= 6.2:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(40.0, self)
		can_act = true
	)

## 3. Magma Fireball Burst
func _perform_fireball_burst() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	var fwd := (target_player.global_position - global_position).normalized()
	fwd.y = 0
	
	for i in range(3):
		get_tree().create_timer(i * 0.18).timeout.connect(func():
			if is_instance_valid(self) and target_player and is_instance_valid(target_player):
				var shot_dir := (target_player.global_position - global_position).normalized()
				shot_dir.y = 0
				_spawn_magma_bullet(shot_dir)
		)

func _spawn_magma_bullet(dir: Vector3) -> void:
	var bullet := Area3D.new()
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	col.shape = sphere
	bullet.add_child(col)
	
	var mi := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.5
	s_mesh.height = 1.0
	mi.mesh = s_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0, 1.0)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	bullet.add_child(mi)
	
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 2.2, 0)
	
	var tw := create_tween()
	tw.tween_property(bullet, "global_position", bullet.global_position + (dir * 25.0), 1.2)
	tw.tween_callback(bullet.queue_free)
	
	bullet.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(26.0, self)
				bullet.queue_free()
	)

func _perform_magma_slam() -> void:
	can_act = false
	var hit_pos := global_position + (-global_transform.basis.z * 2.8)
	create_telegraph_circle(hit_pos, 3.5, 0.6, Color(1.0, 0.1, 0.0, 0.85))
	
	get_tree().create_timer(0.5).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.5)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = hit_pos.distance_to((c as Node3D).global_position)
				if d <= 3.8:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
		can_act = true
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 2.0
			attack_damage = 50.0
		3:
			attack_cooldown = 1.6
			move_speed = 4.8
		4:
			# Supernova Meltdown
			attack_cooldown = 1.0
			move_speed = 6.2
			attack_damage = 60.0
