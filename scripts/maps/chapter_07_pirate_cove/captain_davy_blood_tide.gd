class_name CaptainDavyBloodTide
extends BaseBoss

## Chapter 7 Boss: Captain Davy Blood-Tide (Cursed Scourge of the Seven Seas)
## Spectral pirate captain with flintlock cannonades, ghost anchor slams, and broadside artillery

@export var attack_cooldown: float = 2.2
var attack_timer: float = 1.0
var anchor_timer: float = 6.5
var broadside_timer: float = 8.5

@onready var cutlass_arm: Node3D = $Visuals/RightArmPivot

func _ready() -> void:
	boss_name = "Captain Davy Blood-Tide — Cursed Scourge"
	max_health = 1250.0
	move_speed = 4.8
	attack_damage = 46.0
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
		anchor_timer -= delta
		broadside_timer -= delta
		
		# Cursed Ghost Anchor Slam
		if anchor_timer <= 0.0 and dist > 6.0 and can_act:
			anchor_timer = randf_range(7.0, 9.5) if current_phase < BossPhase.PHASE_4 else 4.5
			_perform_anchor_slam()
			return
			
		# Ghost Ship Broadside Volley
		if broadside_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			broadside_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_broadside_volley()
			return
			
		# Flintlock Shot or Cutlass Slash
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.1
			if dist <= 5.0:
				_perform_cutlass_slash()
			else:
				_perform_flintlock_cannonade()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Dual Flintlock Grapeshot Burst
func _perform_flintlock_cannonade() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var fwd := (target_player.global_position - global_position).normalized()
	fwd.y = 0
	
	for i in range(4):
		var spread_angle: float = randf_range(-0.35, 0.35)
		var dir := fwd.rotated(Vector3.UP, spread_angle)
		_spawn_cannon_shot(dir)
		
	get_tree().create_timer(0.4).timeout.connect(func(): can_act = true)

func _spawn_cannon_shot(dir: Vector3) -> void:
	var shot := Area3D.new()
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	col.shape = sphere
	shot.add_child(col)
	
	var mi := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.4
	s_mesh.height = 0.8
	mi.mesh = s_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.5, 1.0)
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	shot.add_child(mi)
	
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector3(0, 1.6, 0)
	
	var tw := create_tween()
	tw.tween_property(shot, "global_position", shot.global_position + (dir * 26.0), 1.0)
	tw.tween_callback(shot.queue_free)
	
	shot.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(28.0, self)
				shot.queue_free()
	)

## 2. Cursed Ghost Anchor Slam
func _perform_anchor_slam() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var target_pos: Vector3 = target_player.global_position
	create_telegraph_circle(target_pos, 3.8, 0.75, Color(0.1, 0.9, 0.6, 0.85))
	
	# Jump and slam anchor down
	var tw := create_tween()
	tw.tween_property(visuals, "position:y", 2.2, 0.3)
	tw.tween_property(visuals, "position:y", 0.0, 0.2)
	
	get_tree().create_timer(0.55).timeout.connect(func():
		boss_attack_slammed.emit(target_pos, 1.6)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = target_pos.distance_to((c as Node3D).global_position)
				if d <= 4.0:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(48.0, self)
					if c is CharacterBody3D:
						var pull_dir := (global_position - (c as Node3D).global_position).normalized()
						(c as CharacterBody3D).velocity += pull_dir * 12.0
		can_act = true
	)

## 3. Ghost Ship Broadside Volley
func _perform_broadside_volley() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var p_pos: Vector3 = target_player.global_position
	var count: int = 4 if current_phase < BossPhase.PHASE_4 else 6
	
	for i in range(count):
		var offset := Vector3((i - count/2.0) * 3.5, 0, randf_range(-3.0, 3.0))
		var impact_pos := p_pos + offset
		impact_pos.y = 0.1
		
		create_telegraph_circle(impact_pos, 3.2, 0.85, Color(1.0, 0.2, 0.1, 0.8))
		
		get_tree().create_timer(0.85 + (i * 0.12)).timeout.connect(func():
			_drop_cannonball(impact_pos)
		)
		
	get_tree().create_timer(1.6).timeout.connect(func(): can_act = true)

func _drop_cannonball(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.4)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = pos.distance_to((c as Node3D).global_position)
			if d <= 3.5:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(40.0, self)

func _perform_cutlass_slash() -> void:
	can_act = false
	var hit_pos := global_position + (-global_transform.basis.z * 2.8)
	create_telegraph_circle(hit_pos, 3.4, 0.55, Color(0.2, 1.0, 0.6, 0.8))
	
	if cutlass_arm:
		var tw := create_tween()
		tw.tween_property(cutlass_arm, "rotation:y", 2.0, 0.25)
		tw.tween_property(cutlass_arm, "rotation:y", -1.8, 0.16)
		tw.tween_property(cutlass_arm, "rotation:y", 0.0, 0.18)
		
	get_tree().create_timer(0.45).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.2)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = hit_pos.distance_to((c as Node3D).global_position)
				if d <= 3.6:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
		can_act = true
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 1.9
			attack_damage = 52.0
		3:
			attack_cooldown = 1.5
			move_speed = 5.6
		4:
			# Davy Jones' Retribution
			attack_cooldown = 1.0
			move_speed = 6.8
			attack_damage = 62.0
