class_name FrostFiendYmir
extends BaseBoss

## Chapter 3 Boss: Ymir the Frost Fiend (Glacial Berserker)
## Massive ice colossus with Glacial Leap Slam, 360 icicle barrage, and chilling permafrost waves

@export var attack_cooldown: float = 2.5
var attack_timer: float = 1.0
var leap_timer: float = 6.0
var barrage_timer: float = 8.0

var is_leaping: bool = false

@onready var mace_arm: Node3D = $Visuals/RightArmPivot

func _ready() -> void:
	boss_name = "Ymir — The Glacial Berserker"
	max_health = 950.0
	move_speed = 4.2
	attack_damage = 42.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if is_leaping:
		# Air physics handled by tween/leap sequence
		move_and_slide()
		return
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		
		# Rotate toward player
		look_at_target(target_player.global_position, delta)
		
		# Erratic unanticipated AI navigation
		velocity = calculate_unanticipated_velocity(target_player.global_position, 4.2, delta)
		
		# Heavy glacial stomping stride, leg pendulum, forward lean & bank
		update_procedural_locomotion(delta)
			
		attack_timer -= delta
		leap_timer -= delta
		barrage_timer -= delta
		
		# Glacial Leap Slam if player is far away or on timer
		if leap_timer <= 0.0 and can_act and dist > 7.0:
			leap_timer = randf_range(7.0, 10.0) if current_phase < BossPhase.PHASE_4 else 4.5
			_perform_glacial_leap()
			return
			
		# 360-degree Icicle Ring Barrage
		if barrage_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			barrage_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_icicle_barrage()
			return
			
		# Melee Glacial Mace Slam
		if attack_timer <= 0.0 and dist <= 6.5 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.3
			_perform_mace_slam()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Glacial Leap Slam
func _perform_glacial_leap() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
		
	can_act = false
	is_leaping = true
	velocity = Vector3.ZERO
	set_facial_state(FacialState.ATTACK_ROAR, 1.2)
	
	var landing_pos: Vector3 = target_player.global_position
	landing_pos.y = 0.2
	
	# Massive 5.2m Red Danger Telegraph
	create_telegraph_circle(landing_pos, 5.2, 1.2, Color(0.2, 0.6, 1.0, 0.8))
	create_telegraph_circle(landing_pos, 4.0, 1.2, Color(1.0, 0.2, 0.1, 0.7))
	
	# Jump into the air
	var tw := create_tween()
	tw.set_parallel(false)
	tw.tween_property(self, "global_position:y", 9.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		global_position.x = landing_pos.x
		global_position.z = landing_pos.z
	)
	tw.tween_property(self, "global_position:y", 0.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_on_leap_crash(landing_pos)
		is_leaping = false
		can_act = true
	)

func _on_leap_crash(crash_pos: Vector3) -> void:
	boss_attack_slammed.emit(crash_pos, 2.0)
	
	# Shockwave damage
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = crash_pos.distance_to((c as Node3D).global_position)
			if d <= 5.5:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(50.0, self)
				if c is CharacterBody3D:
					var knock_dir := ((c as Node3D).global_position - crash_pos).normalized()
					(c as CharacterBody3D).velocity += knock_dir * 12.0

## 2. 360° Icicle Ring Barrage
func _perform_icicle_barrage() -> void:
	can_act = false
	velocity = Vector3.ZERO
	
	# Stomp windup
	var tw := create_tween()
	tw.tween_property(visuals, "scale", Vector3(1.3, 0.8, 1.3), 0.3)
	tw.tween_property(visuals, "scale", Vector3.ONE, 0.2)
	
	create_telegraph_circle(global_position, 6.5, 0.6, Color(0.1, 0.8, 1.0, 0.8))
	
	get_tree().create_timer(0.55).timeout.connect(func():
		_fire_icicle_ring()
		can_act = true
	)

func _fire_icicle_ring() -> void:
	var count: int = 10 if current_phase < BossPhase.PHASE_4 else 14
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU
		var dir := Vector3(cos(angle), 0, sin(angle))
		_spawn_icicle(dir)

func _spawn_icicle(dir: Vector3) -> void:
	var icicle := Area3D.new()
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	col.shape = sphere
	icicle.add_child(col)
	
	var mi := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.35
	cone.height = 1.6
	mi.mesh = cone
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.9, 1.0, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.8, 1.0, 1.0)
	mat.emission_energy_multiplier = 3.5
	mi.material_override = mat
	icicle.add_child(mi)
	
	get_parent().add_child(icicle)
	icicle.global_position = global_position + Vector3(0, 1.5, 0)
	icicle.look_at(icicle.global_position + dir, Vector3.UP)
	mi.rotate_x(deg_to_rad(90))
	
	var tw := create_tween()
	tw.tween_property(icicle, "global_position", icicle.global_position + (dir * 24.0), 1.4)
	tw.tween_callback(icicle.queue_free)
	
	icicle.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(28.0, self)
				icicle.queue_free()
	)

## 3. Glacial Mace Slam
func _perform_mace_slam() -> void:
	can_act = false
	var strike_pos := global_position + (-global_transform.basis.z * 3.2)
	create_telegraph_circle(strike_pos, 3.8, 0.65, Color(1.0, 0.2, 0.1, 0.75))
	
	if mace_arm:
		var tw := create_tween()
		tw.tween_property(mace_arm, "rotation:x", -1.8, 0.3)
		tw.tween_property(mace_arm, "rotation:x", 0.4, 0.15)
		tw.tween_property(mace_arm, "rotation:x", 0.0, 0.2)
		
	get_tree().create_timer(0.5).timeout.connect(func():
		boss_attack_slammed.emit(strike_pos, 1.4)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = strike_pos.distance_to((c as Node3D).global_position)
				if d <= 4.0:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
		can_act = true
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 2.1
			attack_damage = 48.0
		3:
			attack_cooldown = 1.7
			move_speed = 5.0
		4:
			# Blizzard Berserk
			attack_cooldown = 1.1
			move_speed = 6.4
			attack_damage = 56.0
