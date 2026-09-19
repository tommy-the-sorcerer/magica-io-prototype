class_name JudgmentSeraph
extends BaseBoss

## Chapter 10 Boss: Judgment Seraph (Fallen Archangel of Retribution)
## Final chapter supreme boss with holy spear rain, divine sunbursts, and sacred blade shockwaves

@export var attack_cooldown: float = 2.0
var attack_timer: float = 1.0
var sunburst_timer: float = 7.5
var spear_rain_timer: float = 8.5

var is_charging_sunburst: bool = false

@onready var sword_arm: Node3D = $Visuals/RightArmPivot
@onready var halo: Node3D = $Visuals/Halo

func _ready() -> void:
	boss_name = "Judgment Seraph — Archangel of Retribution"
	max_health = 1500.0
	move_speed = 5.0
	attack_damage = 55.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if halo:
		halo.rotate_z(1.8 * delta)
		
	if is_charging_sunburst:
		move_and_slide()
		return
		
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		look_at_target(target_player.global_position, delta)
		
		var target_vel := calculate_unanticipated_velocity(target_player.global_position, 4.5, delta)
		velocity.x = target_vel.x
		velocity.z = target_vel.z
			
		attack_timer -= delta
		sunburst_timer -= delta
		spear_rain_timer -= delta
		
		# Divine Retribution Sunburst
		if sunburst_timer <= 0.0 and can_act:
			sunburst_timer = randf_range(8.5, 11.5) if current_phase < BossPhase.PHASE_4 else 5.5
			_perform_sunburst()
			return
			
		# Rain of Sacred Spears
		if spear_rain_timer <= 0.0 and can_act and current_phase >= BossPhase.PHASE_2:
			spear_rain_timer = 9.0 if current_phase < BossPhase.PHASE_4 else 5.0
			_perform_spear_rain()
			return
			
		# Sacred Waves or Melee Holy Cleave
		if attack_timer <= 0.0 and can_act:
			attack_timer = attack_cooldown if current_phase < BossPhase.PHASE_4 else 0.95
			if dist <= 5.5:
				_perform_holy_cleave()
			else:
				_perform_sacred_waves()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	base_visual_y = 0.5 + sin(Time.get_ticks_msec() * 0.0035) * 0.25
	update_procedural_locomotion(delta)

## 1. Divine Retribution Sunburst (Massive 8m expanding blast)
func _perform_sunburst() -> void:
	can_act = false
	is_charging_sunburst = true
	velocity = Vector3.ZERO
	set_facial_state(FacialState.ATTACK_ROAR, 1.8)
	
	# Massive 8.0m Red Danger Warning
	create_telegraph_circle(global_position, 8.0, 1.4, Color(1.0, 0.8, 0.1, 0.85))
	create_telegraph_circle(global_position, 6.0, 1.4, Color(1.0, 0.2, 0.05, 0.8))
	
	# Ascend and charge
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", 2.5, 0.6)
	tw.tween_property(visuals, "scale", Vector3(1.35, 1.35, 1.35), 0.6)
	
	get_tree().create_timer(1.4).timeout.connect(func():
		_detonate_sunburst()
		is_charging_sunburst = false
		can_act = true
	)

func _detonate_sunburst() -> void:
	boss_attack_slammed.emit(global_position, 2.5)
	
	# Sunburst flash mesh
	var flash := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 8.0
	s_mesh.height = 16.0
	flash.mesh = s_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2, 1.0)
	mat.emission_energy_multiplier = 6.0
	flash.material_override = mat
	
	get_parent().add_child(flash)
	flash.global_position = global_position
	
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = global_position.distance_to((c as Node3D).global_position)
			if d <= 8.2:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(65.0, self)
				if c is CharacterBody3D:
					var knock := ((c as Node3D).global_position - global_position).normalized()
					(c as CharacterBody3D).velocity += knock * 20.0
					
	var tw := create_tween()
	tw.tween_property(flash, "scale", Vector3.ZERO, 0.3)
	tw.tween_callback(flash.queue_free)
	
	var land_tw := create_tween()
	land_tw.tween_property(self, "global_position:y", 0.2, 0.3)
	land_tw.tween_property(visuals, "scale", Vector3.ONE, 0.2)

## 2. Rain of Sacred Spears
func _perform_spear_rain() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	can_act = false
	set_facial_state(FacialState.ATTACK_ROAR, 1.4)
	
	var base_pos: Vector3 = target_player.global_position
	var count: int = 5 if current_phase < BossPhase.PHASE_4 else 8
	
	for i in range(count):
		var offset := Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
		var impact_pos := base_pos + offset
		impact_pos.y = 0.1
		
		create_telegraph_circle(impact_pos, 3.2, 0.9, Color(1.0, 0.85, 0.2, 0.85))
		
		get_tree().create_timer(0.9 + (i * 0.12)).timeout.connect(func():
			_drop_sacred_spear(impact_pos)
		)
		
	get_tree().create_timer(1.8).timeout.connect(func(): can_act = true)

func _drop_sacred_spear(pos: Vector3) -> void:
	boss_attack_slammed.emit(pos, 1.4)
	
	var spear := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.25
	cyl.height = 3.8
	spear.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.4, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2, 1.0)
	mat.emission_energy_multiplier = 5.0
	spear.material_override = mat
	
	get_parent().add_child(spear)
	spear.global_position = pos + Vector3(0, 15.0, 0)
	
	var tw := create_tween()
	tw.tween_property(spear, "global_position:y", pos.y + 1.9, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = pos.distance_to((c as Node3D).global_position)
				if d <= 3.4:
					var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
					if hp:
						hp.take_damage(44.0, self)
		spear.queue_free()
	)

## 3. Sacred Light Waves
func _perform_sacred_waves() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	set_facial_state(FacialState.ATTACK_ROAR, 0.8)
	var fwd := (target_player.global_position - global_position).normalized()
	fwd.y = 0
	
	var angles := [-0.2, 0.2] if current_phase < BossPhase.PHASE_4 else [-0.35, 0.0, 0.35]
	for a in angles:
		var dir := fwd.rotated(Vector3.UP, a)
		_spawn_sacred_blade(dir)

func _spawn_sacred_blade(dir: Vector3) -> void:
	var blade := Area3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 0.6, 0.6)
	col.shape = box
	blade.add_child(col)
	
	var mi := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(2.5, 0.4, 0.4)
	mi.mesh = b_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.6, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3, 1.0)
	mat.emission_energy_multiplier = 4.5
	mi.material_override = mat
	blade.add_child(mi)
	
	get_parent().add_child(blade)
	blade.global_position = global_position + Vector3(0, 1.8, 0)
	blade.look_at(blade.global_position + dir, Vector3.UP)
	
	var tw := create_tween()
	tw.tween_property(blade, "global_position", blade.global_position + (dir * 28.0), 1.2)
	tw.tween_callback(blade.queue_free)
	
	blade.body_entered.connect(func(body: Node):
		if body != self and body is Node3D:
			var hp: HealthComponent = body.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(35.0, self)
				blade.queue_free()
	)

func _perform_holy_cleave() -> void:
	can_act = false
	set_facial_state(FacialState.ATTACK_ROAR, 0.7)
	var hit_pos := global_position + (-global_transform.basis.z * 3.2)
	create_telegraph_circle(hit_pos, 4.0, 0.55, Color(1.0, 0.8, 0.1, 0.85))
	
	if sword_arm:
		var tw := create_tween()
		tw.tween_property(sword_arm, "rotation:y", 2.2, 0.25)
		tw.tween_property(sword_arm, "rotation:y", -2.0, 0.18)
		tw.tween_property(sword_arm, "rotation:y", 0.0, 0.2)
		
	get_tree().create_timer(0.45).timeout.connect(func():
		boss_attack_slammed.emit(hit_pos, 1.5)
		var combatants := get_tree().get_nodes_in_group("combatants")
		for c in combatants:
			if is_instance_valid(c) and c != self and c is Node3D:
				var d: float = hit_pos.distance_to((c as Node3D).global_position)
				if d <= 4.2:
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
			attack_damage = 62.0
		3:
			attack_cooldown = 1.4
			move_speed = 5.8
		4:
			# Wrath of the Heavens (Full Divine Ascendance)
			attack_cooldown = 0.85
			move_speed = 7.2
			attack_damage = 75.0
			set_facial_state(FacialState.ENRAGE_FLARE, 999.0)
			if visuals:
				var tw := create_tween()
				tw.tween_property(visuals, "scale", Vector3(1.3, 1.3, 1.3), 0.4)
