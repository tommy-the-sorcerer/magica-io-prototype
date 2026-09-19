class_name GorgonTreantKing
extends BaseBoss

## Chapter 1 Boss: Gorgon the Treant King with 4 escalating combat phases and root eruptions

@export var melee_range: float = 4.5
@export var attack_cooldown: float = 2.4

var attack_timer: float = 1.0

@onready var left_arm: Node3D = $Visuals/LeftBranchArm
@onready var right_arm: Node3D = $Visuals/RightBranchArm

func _ready() -> void:
	boss_name = "Gorgon — The Treant King"
	max_health = 750.0
	move_speed = 3.8
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	# Find target player if not assigned
	if not target_player or not is_instance_valid(target_player):
		_find_player()
			
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		
		# Smoothly rotate toward player
		look_at_target(target_player.global_position, delta)
		
		# Dynamic, erratic, unanticipated predator movement (circling, zig-zag, feints)
		velocity = calculate_unanticipated_velocity(target_player.global_position, melee_range, delta)
		
		# Heavy footstep kinematics, leg swings, forward lean, banking
		update_procedural_locomotion(delta)
			
		# Attack timer
		attack_timer -= delta
		if attack_timer <= 0.0 and dist <= 12.0 and can_act:
			attack_timer = attack_cooldown
			_perform_treant_attack()
	else:
		velocity.x = 0
		velocity.z = 0
		update_procedural_locomotion(delta)

	move_and_slide()

func _perform_treant_attack() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	
	# Attack roar: opens jaw wide and flares eyes with high emission
	set_facial_state(FacialState.ATTACK_ROAR, 0.8)
	
	# Telegraph ground impact ahead
	var target_pos: Vector3 = target_player.global_position
	create_telegraph_circle(target_pos, 3.5, 0.7, Color(0.95, 0.2, 0.1, 0.7))
	
	# Arm windup animation
	is_attacking_anim = true
	if right_arm:
		var tween := create_tween()
		tween.tween_property(right_arm, "rotation:x", -1.5, 0.3)
		tween.tween_property(right_arm, "rotation:x", 0.3, 0.15)
		tween.tween_property(right_arm, "rotation:x", 0.0, 0.25)
		tween.tween_callback(func(): is_attacking_anim = false)
		
	get_tree().create_timer(0.7).timeout.connect(func(): _on_slam_impact(target_pos))

func _on_slam_impact(hit_pos: Vector3) -> void:
	# Shockwave damage at telegraphed position
	boss_attack_slammed.emit(hit_pos, 1.0)
	var combatants := get_tree().get_nodes_in_group("combatants")
	for c in combatants:
		if is_instance_valid(c) and c != self and c is Node3D:
			var d: float = hit_pos.distance_to((c as Node3D).global_position)
			if d <= 3.8:
				var hp: HealthComponent = c.find_child("HealthComponent", true, false) as HealthComponent
				if hp:
					hp.take_damage(attack_damage, self)

func _on_phase_entered(phase: int) -> void:
	if not is_inside_tree():
		return
	match phase:
		2:
			# Phase 2: Erupt roots from the earth!
			_spawn_root_hazards()
			move_speed = 4.2
		3:
			# Phase 3: Storm surge, accelerate wind
			attack_cooldown = 1.8
			move_speed = 4.8
			var tree := get_tree()
			if tree and tree.current_scene:
				var storm := tree.current_scene.find_child("ForestStorm", true, false) as BaseStorm
				if storm:
					storm.start_shrink(16.0, 30.0)
		4:
			# Phase 4: Final confrontation, berserk speed
			attack_cooldown = 1.2
			move_speed = 5.5
			var tree := get_tree()
			if tree and tree.current_scene:
				var storm := tree.current_scene.find_child("ForestStorm", true, false) as BaseStorm
				if storm:
					storm.start_shrink(8.0, 20.0)

func _spawn_root_hazards() -> void:
	if not is_inside_tree():
		return
	var root_scene := load("res://scenes/maps/emerald_plains/boss/treant_root_hazard.tscn")
	var tree := get_tree()
	if not root_scene or not tree or not tree.current_scene:
		return
		
	for i in range(6):
		var angle: float = (float(i) / 6.0) * TAU
		var offset := Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
		var root: Node3D = root_scene.instantiate() as Node3D
		tree.current_scene.add_child(root)
		root.global_position = global_position + offset

func _on_boss_death() -> void:
	# Victory notification to HUD
	var hud := get_tree().current_scene.find_child("HUD", true, false)
	if hud and hud.has_method("show_victory"):
		hud.call("show_victory")
