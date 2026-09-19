class_name LordMalakor
extends BaseBoss

## Chapter 8 Boss: Lord Malakor the Gravekeeper (High Necromancer of the Crypt)
## Ethereal necromancer with soul crescent scythe slashes, life drain tethers, and erupting crypt hands

@export var attack_cooldown: float = 2.2
var attack_timer: float = 1.0
var tether_timer: float = 7.0
var crypt_hands_timer: float = 8.5

var is_channeling_drain: bool = false

@onready var scythe_arm: Node3D = $Visuals/RightArmPivot
@onready var soul_orb: Node3D = $Visuals/SoulOrb

func _ready() -> void:
	boss_name = "Lord Malakor — High Necromancer"
	max_health = 1300.0
	move_speed = 4.6
	attack_damage = 48.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	# Floating hover bob
	visuals.position.y = 0.4 + sin(Time.get_ticks_msec() * 0.003) * 0.25
	
	if soul_orb:
		soul_orb.rotate_y(2.0 * delta)
		
	if is_channeling_drain:
		move_and_slide()
		return
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		var dir := (target_player.global_position - global_position).normalized()
		dir.y = 0
		
		look_at_target(target_player.global_position, delta)
		
		if dist > 5.0:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)
			
		attack_timer -= delta
		tether_timer -= delta
		crypt_hands_timer -= delta
		
		# Soul Drain Tether
		if tether_timer <= 0.0 and dist <= 14.0 and can_act:
			tether_timer = randf_range(8.0, 11.0) if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_soul_drain()
			return
			
		# Graveyard Crypt Hands
		if crypt_hands_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			crypt_hands_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.5
			_perform_crypt_hands()
			return
			
		# Scythe Slash or Soul Wave
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.1
			if dist <= 5.5:
				_perform_scythe_reap()
			else:
				_perform_soul_crescents()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Soul Crescent Wave
func _perform_soul_crescents() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var base_dir := (target_player.global_position - global_position).normalized()
	base_dir.y = 0
	
	var angles := [-0.25, 0.0, 0.25] if current_phase < BossPhase.PHASE_4 else [-0.4, -0.2, 0.0, 0.2, 0.4]
	for a in angles:
		var dir := base_dir.rotated(Vector3.UP, a)
		_spawn_soul_blade(dir)
		
	get_tree().create_timer(0.45).timeout.connect(func(): can_act = true)

func _spawn_soul_blade(dir: Vector3) -> void:
	var blade := Area3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 0.5, 0.5)
	col.shape = box
	blade.add_child(col)
	
	var mi := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(2.2, 0.3, 0.3)
	mi.mesh = b_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.2, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.1, 1.0, 1.0)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	blade.add_child(mi)
	
	get_parent().add_child(blade)
	blade.global_position = global_position + Vector3(0, 1.8, 0)
	blade.look_at(blade.global_position + dir, Vector3.UP)
	
	var tw := create_tween()
	tw.tween_property(blade, "global_position", blade.global_position + (dir * 26.0), 1.2)
	tw.tween_callback(blade.queue_free)
	
	blade.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(30.0, self)
				blade.queue_free()
	)

## 2. Soul Drain Tether
func _perform_soul_drain() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	is_channeling_drain = true
	can_act = false
	velocity = Vector3.ZERO
	
	# Create telegraph line / circle under player
	create_telegraph_circle(target_player.global_position, 3.0, 2.5, Color(0.8, 0.1, 0.9, 0.7))
	
	# Channel 5 ticks of drain
	for i in range(5):
		get_tree().create_timer(i * 0.5).timeout.connect(func():
			if not is_channeling_drain or not is_instance_valid(self): return
			if target_player and is_instance_valid(target_player):
				var d := global_position.distance_to(target_player.global_position)
				if d <= 15.0:
					var hp: HealthComponent = target_player.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(12.0, self)
						# Heal boss
						if health_component:
							health_component.heal(15.0)
		)
		
	get_tree().create_timer(2.6).timeout.connect(func():
		is_channeling_drain = false
		can_act = true
	)

## 3. Crypt Hands Hazard
func _perform_crypt_hands() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var p_pos: Vector3 = target_player.global_position
	var count: int = 4 if current_phase < BossPhase.PHASE_4 else 6
	
	for i in range(count):
		var offset := Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.5, 4.5))
		var hand_pos := p_pos + offset
		hand_pos.y = 0.05
		
		create_telegraph_circle(hand_pos, 2.8, 0.8, Color(0.9, 0.1, 0.4, 0.8))
		
		get_tree().create_timer(0.8).timeout.connect(func():
			_erupt_crypt_hand(hand_pos)
		)
		
	get_tree().create_timer(1.2).timeout.connect(func(): can_act = true)

func _erupt_crypt_hand(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.2)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = pos.distance_to((c as Node3D).global_position)
			if d <= 3.0:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(36.0, self)

func _perform_scythe_reap() -> void:
	can_act = false
	var hit_pos := global_position + (-global_transform.basis.z * 3.0)
	create_telegraph_circle(hit_pos, 3.6, 0.6, Color(0.8, 0.1, 1.0, 0.85))
	
	if scythe_arm:
		var tw := create_tween()
		tw.tween_property(scythe_arm, "rotation:y", 2.2, 0.28)
		tw.tween_property(scythe_arm, "rotation:y", -2.0, 0.18)
		tw.tween_property(scythe_arm, "rotation:y", 0.0, 0.2)
		
	get_tree().create_timer(0.46).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.4)
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
			attack_cooldown = 1.9
			attack_damage = 54.0
		3:
			attack_cooldown = 1.5
			move_speed = 5.4
		4:
			# Death Inevitable
			attack_cooldown = 0.95
			move_speed = 6.6
			attack_damage = 64.0
