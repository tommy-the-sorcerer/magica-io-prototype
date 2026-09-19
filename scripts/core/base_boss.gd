class_name BaseBoss
extends CharacterBody3D

## Reusable 4-Phase Boss Controller with health tracking, phase triggers, and lethal telegraphed attacks

signal phase_changed(new_phase: int)
signal boss_defeated
signal boss_attack_slammed(pos: Vector3, strength: float)

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3, PHASE_4 = 4 }
enum AIMovementState { DIRECT_RUSH, ZIGZAG_STRIKE, CIRCLING_STALK, FEINT_BURST, SIDE_DASH }
enum FacialState { SCOWL_IDLE, ATTACK_ROAR, ENRAGE_FLARE }

@export var boss_name: String = "Boss Guardian"
@export var max_health: float = 750.0
@export var move_speed: float = 4.2
@export var attack_range: float = 4.5
@export var attack_damage: float = 35.0

var current_phase: BossPhase = BossPhase.PHASE_1
var is_active: bool = false
var can_act: bool = true
var target_player: Node3D = null

# Procedural Locomotion State
var base_visual_y: float = 0.0
var stride_cycle: float = 0.0
var prev_yaw: float = 0.0
var yaw_velocity: float = 0.0
var is_attacking_anim: bool = false

# Unanticipated AI Movement State
var ai_move_state: AIMovementState = AIMovementState.ZIGZAG_STRIKE
var ai_state_timer: float = 2.0
var orbit_direction: float = 1.0 # 1.0 = clockwise, -1.0 = counter-clockwise
var feint_timer: float = 0.0
var burst_speed_mult: float = 1.0

# Node References
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node3D = $Visuals
@onready var nameplate: Label3D = $Nameplate3D

var left_leg_node: Node3D = null
var right_leg_node: Node3D = null
var left_arm_node: Node3D = null
var right_arm_node: Node3D = null
var head_node: Node3D = null
var jaw_node: Node3D = null
var eye_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("bosses")
	
	if visuals:
		base_visual_y = visuals.position.y
		_discover_body_parts()
	
	if not health_component:
		health_component = find_child("HealthComponent", true, false) as HealthComponent
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		add_child(health_component)
		
	health_component.max_health = max_health
	health_component.current_health = max_health
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
	
	_update_nameplate(health_component.current_health, health_component.max_health)
	activate_boss()

func _discover_body_parts() -> void:
	if not visuals:
		return
	left_leg_node = visuals.find_child("*LeftLeg*", true, false) as Node3D
	right_leg_node = visuals.find_child("*RightLeg*", true, false) as Node3D
	left_arm_node = visuals.find_child("*LeftArm*", true, false) as Node3D
	right_arm_node = visuals.find_child("*RightArm*", true, false) as Node3D
	head_node = visuals.find_child("*Head*", true, false) as Node3D
	jaw_node = visuals.find_child("*Jaw*", true, false) as Node3D
	if not jaw_node:
		jaw_node = visuals.find_child("*Mouth*", true, false) as Node3D
	if not jaw_node:
		jaw_node = visuals.find_child("*Snout*", true, false) as Node3D
		
	# Find eyes for emission animations
	for child in visuals.find_children("*Eye*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			eye_nodes.append(child as MeshInstance3D)

func activate_boss() -> void:
	is_active = true
	_find_player()
	_enter_phase(BossPhase.PHASE_1)

func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	var players := tree.get_nodes_in_group("players")
	if players.is_empty():
		players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Node3D

func _enter_phase(phase: BossPhase) -> void:
	current_phase = phase
	phase_changed.emit(int(current_phase))
	
	# Phase 4 Enrage Buff
	if current_phase == BossPhase.PHASE_4:
		move_speed *= 1.35
		attack_damage *= 1.4
		set_facial_state(FacialState.ENRAGE_FLARE, 99999.0)
		if visuals:
			var tween := create_tween()
			if tween:
				tween.tween_property(visuals, "scale", visuals.scale * 1.15, 0.4).set_trans(Tween.TRANS_BACK)
			
	_on_phase_entered(int(current_phase))

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
	var hp_pct: float = curr / maxf(max_hp, 1.0)
	
	if hp_pct <= 0.25 and current_phase < BossPhase.PHASE_4:
		_enter_phase(BossPhase.PHASE_4)
	elif hp_pct <= 0.50 and current_phase < BossPhase.PHASE_3:
		_enter_phase(BossPhase.PHASE_3)
	elif hp_pct <= 0.75 and current_phase < BossPhase.PHASE_2:
		_enter_phase(BossPhase.PHASE_2)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if not nameplate:
		return
	var hp_pct: float = clampf(curr / maxf(max_hp, 1.0), 0.0, 1.0)
	var bar_len: int = 14
	var filled: int = int(hp_pct * bar_len)
	var bar_str: String = "█".repeat(filled) + "░".repeat(bar_len - filled)
	nameplate.text = "👑 %s (PHASE %d)\n[%s] %d / %d" % [boss_name, int(current_phase), bar_str, int(curr), int(max_hp)]
	nameplate.modulate = Color(1.0, 0.15, 0.1) if current_phase == BossPhase.PHASE_4 else (Color(1.0, 0.55, 0.1) if current_phase >= BossPhase.PHASE_2 else Color(1.0, 0.9, 0.2))

func _on_died(_killer: Node) -> void:
	boss_defeated.emit()
	_on_boss_death()
	
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector3(1.4, 0.1, 1.4), 0.3).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(self, "scale", Vector3.ZERO, 0.4)
		tween.tween_callback(queue_free)

## Helper: Creates a ground telegraph circle indicating where a violent attack will hit
func create_telegraph_circle(pos: Vector3, radius: float, duration: float, color: Color = Color(1, 0.2, 0.1, 0.6)) -> MeshInstance3D:
	var circle := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.08
	circle.mesh = cylinder
	
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	circle.material_override = mat
	
	var parent_node: Node = get_parent() if get_parent() else self
	parent_node.add_child(circle)
	if is_inside_tree() and parent_node.is_inside_tree():
		circle.global_position = Vector3(pos.x, 0.05, pos.z)
	else:
		circle.position = Vector3(pos.x, 0.05, pos.z)
	
	# Expanding animation
	circle.scale = Vector3(0.1, 1.0, 0.1)
	var tween := create_tween()
	if tween:
		tween.tween_property(circle, "scale", Vector3(1.0, 1.0, 1.0), duration)
		tween.tween_callback(circle.queue_free)
	
	return circle

## Helper: Face target smoothly
func look_at_target(target_pos: Vector3, delta: float) -> void:
	var dir := (target_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 8.0 * delta)

## Procedural Locomotion System: Swings legs/arms, bobs body, leans into sprints, banks into turns
func update_procedural_locomotion(delta: float) -> void:
	if not visuals:
		return
		
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	
	if horiz_vel > 0.2:
		# Stride frequency scales with movement speed
		stride_cycle += horiz_vel * 3.6 * delta
		
		# Pendulum leg swings
		if left_leg_node:
			left_leg_node.rotation.x = sin(stride_cycle) * 0.6
		if right_leg_node:
			right_leg_node.rotation.x = -sin(stride_cycle) * 0.6
			
		# Counter arm swings if not executing attack animation
		if not is_attacking_anim:
			if left_arm_node:
				left_arm_node.rotation.x = -sin(stride_cycle) * 0.45
			if right_arm_node:
				right_arm_node.rotation.x = sin(stride_cycle) * 0.45
				
		# Heavy footstep body dip and bounce
		visuals.position.y = base_visual_y + abs(sin(stride_cycle)) * 0.16
		
		# Forward lean proportional to speed
		var speed_factor: float = clampf(horiz_vel / maxf(move_speed, 1.0), 0.0, 1.5)
		visuals.rotation.x = lerp_angle(visuals.rotation.x, speed_factor * 0.22, 10.0 * delta)
		
		# Banking/tilt when steering
		var yaw_delta := wrapf(rotation.y - prev_yaw, -PI, PI)
		yaw_velocity = lerp(yaw_velocity, yaw_delta / maxf(delta, 0.001), 10.0 * delta)
		visuals.rotation.z = lerp_angle(visuals.rotation.z, clampf(-yaw_velocity * 0.06, -0.22, 0.22), 8.0 * delta)
		prev_yaw = rotation.y
	else:
		# Settle limbs back to resting position
		if left_leg_node:
			left_leg_node.rotation.x = lerp_angle(left_leg_node.rotation.x, 0.0, 10.0 * delta)
		if right_leg_node:
			right_leg_node.rotation.x = lerp_angle(right_leg_node.rotation.x, 0.0, 10.0 * delta)
		if not is_attacking_anim:
			if left_arm_node:
				left_arm_node.rotation.x = lerp_angle(left_arm_node.rotation.x, 0.0, 8.0 * delta)
			if right_arm_node:
				right_arm_node.rotation.x = lerp_angle(right_arm_node.rotation.x, 0.0, 8.0 * delta)
				
		# Idle breathing bob
		visuals.position.y = base_visual_y + sin(Time.get_ticks_msec() * 0.003) * 0.04
		visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, 8.0 * delta)
		visuals.rotation.z = lerp_angle(visuals.rotation.z, 0.0, 8.0 * delta)
		prev_yaw = rotation.y

## Unanticipated AI Navigation: Generates erratic, tactical, predatory movement vectors
func calculate_unanticipated_velocity(target_pos: Vector3, min_range: float, delta: float) -> Vector3:
	var my_pos: Vector3 = global_position if is_inside_tree() else position
	var dist := my_pos.distance_to(target_pos)
	if dist <= min_range:
		# Close range: slow down smoothly for melee engagement
		return Vector3(
			move_toward(velocity.x, 0.0, delta * 12.0),
			0.0,
			move_toward(velocity.z, 0.0, delta * 12.0)
		)
		
	# Update unpredictable state timer
	ai_state_timer -= delta
	feint_timer += delta
	
	if ai_state_timer <= 0.0:
		# Pick random tactical mode:
		var roll := randf()
		if roll < 0.35:
			ai_move_state = AIMovementState.CIRCLING_STALK
			orbit_direction = 1.0 if randf() > 0.5 else -1.0
			ai_state_timer = randf_range(1.6, 2.8)
		elif roll < 0.70:
			ai_move_state = AIMovementState.ZIGZAG_STRIKE
			ai_state_timer = randf_range(1.8, 3.0)
		else:
			ai_move_state = AIMovementState.FEINT_BURST
			feint_timer = 0.0
			ai_state_timer = randf_range(1.2, 2.0)
			
	var fwd := (target_pos - my_pos).normalized()
	fwd.y = 0.0
	
	var desired_dir := fwd
	var current_spd := move_speed
	
	match ai_move_state:
		AIMovementState.CIRCLING_STALK:
			# Stalks and orbits around player while gradually closing in
			var tangent := fwd.rotated(Vector3.UP, (PI * 0.45) * orbit_direction)
			desired_dir = (tangent * 0.85 + fwd * 0.35).normalized()
			current_spd = move_speed * 1.05
			
		AIMovementState.ZIGZAG_STRIKE:
			# Serpentine weave to dodge player shots and confuse target
			var lateral := fwd.rotated(Vector3.UP, PI * 0.5) * (sin(Time.get_ticks_msec() * 0.007) * 0.75)
			desired_dir = (fwd + lateral).normalized()
			current_spd = move_speed * 1.25
			
		AIMovementState.FEINT_BURST:
			if feint_timer < 0.35:
				# Stutter-step back to bait player
				desired_dir = -fwd * 0.4
				current_spd = move_speed * 0.5
			else:
				# Explosive forward burst!
				desired_dir = fwd
				current_spd = move_speed * (1.8 if current_phase < BossPhase.PHASE_4 else 2.2)
				
		AIMovementState.DIRECT_RUSH:
			desired_dir = fwd
			current_spd = move_speed
			
	return Vector3(desired_dir.x * current_spd, 0.0, desired_dir.z * current_spd)

## Dynamic Facial State Controller: Animates jaws and flares eyes with high emission
func set_facial_state(state: FacialState, duration: float = 0.6) -> void:
	match state:
		FacialState.ATTACK_ROAR:
			if jaw_node:
				var tw := create_tween()
				if tw:
					tw.tween_property(jaw_node, "position:y", -0.22, 0.15)
					tw.tween_property(jaw_node, "rotation:x", 0.4, 0.15)
			for eye in eye_nodes:
				if eye and eye.material_override:
					var mat: StandardMaterial3D = eye.material_override as StandardMaterial3D
					if mat:
						mat.emission_energy_multiplier = 8.0
						
			if is_inside_tree() and get_tree():
				get_tree().create_timer(duration).timeout.connect(func():
					set_facial_state(FacialState.SCOWL_IDLE)
				)
			
		FacialState.ENRAGE_FLARE:
			if jaw_node:
				jaw_node.position.y = -0.18
			for eye in eye_nodes:
				if eye and eye.material_override:
					var mat: StandardMaterial3D = eye.material_override as StandardMaterial3D
					if mat:
						mat.albedo_color = Color(1.0, 0.05, 0.05, 1.0)
						mat.emission = Color(1.0, 0.0, 0.0, 1.0)
						mat.emission_energy_multiplier = 10.0
						
		FacialState.SCOWL_IDLE:
			if jaw_node:
				var tw := create_tween()
				if tw:
					tw.tween_property(jaw_node, "position:y", 0.0, 0.2)
					tw.tween_property(jaw_node, "rotation:x", 0.0, 0.2)
			for eye in eye_nodes:
				if eye and eye.material_override:
					var mat: StandardMaterial3D = eye.material_override as StandardMaterial3D
					if mat:
						mat.emission_energy_multiplier = 4.0

# Virtual methods for chapter boss implementations to override
func _on_phase_entered(_phase: int) -> void:
	pass

func _on_boss_death() -> void:
	pass

