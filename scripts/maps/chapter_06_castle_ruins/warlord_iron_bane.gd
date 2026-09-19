class_name WarlordIronBane
extends BaseBoss

## Chapter 6 Boss: Warlord Iron-Bane (Cursed Executioner Knight)
## Heavy armored juggernaut with executioner cleave, shield charges, and catapult boulder barrages

@export var attack_cooldown: float = 2.4
var attack_timer: float = 1.0
var charge_timer: float = 7.0
var barrage_timer: float = 9.0

var is_charging: bool = false

@onready var sword_arm: Node3D = $Visuals/RightArmPivot
@onready var shield_arm: Node3D = $Visuals/LeftArmPivot

func _ready() -> void:
	boss_name = "Warlord Iron-Bane — The Executioner"
	max_health = 1200.0
	move_speed = 4.4
	attack_damage = 48.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if is_charging:
		move_and_slide()
		return
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		
		# Rotate smoothly to target
		look_at_target(target_player.global_position, delta)
		
		# Erratic unpredictable navigation (orbiting, zig-zag closing, sudden charge feints)
		velocity = calculate_unanticipated_velocity(target_player.global_position, 4.2, delta)
		
		# Heavy armored juggernaut strides, pendulum legs, forward charge lean, and banking
		update_procedural_locomotion(delta)
			
		attack_timer -= delta
		charge_timer -= delta
		barrage_timer -= delta
		
		# Juggernaut Shield Charge
		if charge_timer <= 0.0 and dist > 7.0 and can_act:
			charge_timer = randf_range(7.5, 10.5) if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_shield_charge()
			return
			
		# Catapult Siege Barrage
		if barrage_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			barrage_timer = 9.5 if current_phase < BossPhase.PHASE_4 else 5.5
			_perform_catapult_barrage()
			return
			
		# Executioner Cleave
		if attack_timer <= 0.0 and dist <= 6.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 1.1
			_perform_executioner_cleave()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

## 1. Executioner Cleave
func _perform_executioner_cleave() -> void:
	can_act = false
	var strike_pos := global_position + (-global_transform.basis.z * 3.0)
	create_telegraph_circle(strike_pos, 4.2, 0.65, Color(1.0, 0.1, 0.1, 0.8))
	
	if sword_arm:
		var tw := create_tween()
		tw.tween_property(sword_arm, "rotation:y", 2.2, 0.3)
		tw.tween_property(sword_arm, "rotation:y", -2.0, 0.18)
		tw.tween_property(sword_arm, "rotation:y", 0.0, 0.2)
		
	get_tree().create_timer(0.48).timeout.connect(func():
		boss_attack_slammed.emit(strike_pos, 1.5)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = strike_pos.distance_to((c as Node3D).global_position)
				if d <= 4.4:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(attack_damage, self)
					if c is CharacterBody3D:
						var knock := ((c as Node3D).global_position - global_position).normalized()
						(c as CharacterBody3D).velocity += knock * 14.0
		can_act = true
	)

## 2. Juggernaut Shield Charge
func _perform_shield_charge() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	is_charging = true
	
	var charge_dir := (target_player.global_position - global_position).normalized()
	charge_dir.y = 0
	
	var end_point := global_position + (charge_dir * 18.0)
	create_telegraph_circle(end_point, 3.0, 0.8, Color(1.0, 0.5, 0.0, 0.8))
	
	# Telegraph path
	for step in range(3):
		var mid_point := global_position + (charge_dir * (5.0 * (step + 1)))
		create_telegraph_circle(mid_point, 2.5, 0.8, Color(1.0, 0.2, 0.1, 0.6))
		
	velocity = Vector3.ZERO
	
	get_tree().create_timer(0.7).timeout.connect(func():
		velocity = charge_dir * 18.0
		
		# Collision check while rushing
		for check in range(6):
			get_tree().create_timer(check * 0.15).timeout.connect(func():
				if not is_charging: return
				var combatants := get_tree().get_nodes_in_group("combatants")
				for c in combatants:
					if is_instance_valid(c) and c != self and c is Node3D:
						var d: float = global_position.distance_to((c as Node3D).global_position)
						if d <= 3.2:
							var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
							if hp:
								hp.take_damage(40.0, self)
							if c is CharacterBody3D:
								(c as CharacterBody3D).velocity += charge_dir * 16.0
			)
			
		get_tree().create_timer(0.95).timeout.connect(func():
			velocity = Vector3.ZERO
			is_charging = false
			can_act = true
		)
	)

## 3. Catapult Siege Boulder Barrage
func _perform_catapult_barrage() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	
	var target_base: Vector3 = target_player.global_position
	var boulder_count: int = 3 if current_phase < BossPhase.PHASE_4 else 5
	
	for i in range(boulder_count):
		var offset := Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.5, 4.5))
		var impact_pos := target_base + offset
		impact_pos.y = 0.1
		
		create_telegraph_circle(impact_pos, 3.4, 0.9, Color(1.0, 0.2, 0.05, 0.8))
		
		get_tree().create_timer(0.9 + (i * 0.2)).timeout.connect(func():
			_drop_boulder(impact_pos)
		)
		
	get_tree().create_timer(1.6).timeout.connect(func(): can_act = true)

func _drop_boulder(impact_pos: Vector3) -> void:
	var rock := MeshInstance3D.new()
	var b_mesh := SphereMesh.new()
	b_mesh.radius = 1.0
	b_mesh.height = 2.0
	rock.mesh = b_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.32, 0.3, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.3, 0.0, 1.0)
	mat.emission_energy_multiplier = 2.0
	rock.material_override = mat
	
	get_parent().add_child(rock)
	rock.global_position = impact_pos + Vector3(0, 16.0, 0)
	
	var tw := create_tween()
	tw.tween_property(rock, "global_position:y", impact_pos.y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		boss_attack_slammed.emit(impact_pos, 1.6)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = impact_pos.distance_to((c as Node3D).global_position)
				if d <= 3.6:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(42.0, self)
		rock.queue_free()
	)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			attack_cooldown = 2.0
			attack_damage = 54.0
		3:
			attack_cooldown = 1.6
			move_speed = 5.2
		4:
			# Blood Knight Awakening (Drops shield, full two-hand berserk)
			attack_cooldown = 0.95
			move_speed = 6.4
			attack_damage = 65.0
			if shield_arm:
				var tw := create_tween()
				tw.tween_property(shield_arm, "scale", Vector3.ZERO, 0.3)
