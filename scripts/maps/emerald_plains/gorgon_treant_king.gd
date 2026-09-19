class_name GorgonTreantKing
extends BaseBoss

## Chapter 1 Boss: Gorgon the Treant King with 4 escalating combat phases and root eruptions

@export var attack_range: float = 14.0
@export var attack_cooldown: float = 2.4

var attack_timer: float = 1.0
var target_player: Node3D = null

@onready var left_arm: Node3D = $Visuals/LeftBranchArm
@onready var right_arm: Node3D = $Visuals/RightBranchArm

func _ready() -> void:
	boss_name = "Gorgon — The Treant King"
	max_health = 650.0
	move_speed = 3.8
	super._ready()
	activate_boss()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	# Find target player if not assigned
	if not target_player or not is_instance_valid(target_player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0] as Node3D
			
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		var dir := (target_player.global_position - global_position).normalized()
		dir.y = 0
		
		# Face the player
		if dir.length_squared() > 0.01:
			visuals.look_at(global_position + dir, Vector3.UP)
			
		# Movement toward player if outside close melee range
		if dist > 4.5:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)
			
		# Attack timer
		attack_timer -= delta
		if attack_timer <= 0.0 and dist <= attack_range:
			attack_timer = attack_cooldown
			_perform_treant_attack()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _perform_treant_attack() -> void:
	# Arm slam animation
	if right_arm:
		var tween := create_tween()
		tween.tween_property(right_arm, "rotation:x", -1.4, 0.2)
		tween.tween_property(right_arm, "rotation:x", 0.0, 0.25)
		tween.tween_callback(_on_slam_impact)

func _on_slam_impact() -> void:
	# Shockwave damage in front of boss
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if dist <= 5.5:
			var hp: HealthComponent = target_player.find_child("HealthComponent", true, false) as HealthComponent
			if hp:
				hp.take_damage(25.0, self)

func _on_phase_entered(phase: int) -> void:
	match phase:
		2:
			# Phase 2: Erupt roots from the earth!
			_spawn_root_hazards()
			move_speed = 4.2
		3:
			# Phase 3: Storm surge, accelerate wind
			attack_cooldown = 1.8
			move_speed = 4.8
			var storm := get_tree().current_scene.find_child("ForestStorm", true, false) as BaseStorm
			if storm:
				storm.start_shrink(16.0, 30.0)
		4:
			# Phase 4: Final confrontation, berserk speed
			attack_cooldown = 1.2
			move_speed = 5.5
			var storm := get_tree().current_scene.find_child("ForestStorm", true, false) as BaseStorm
			if storm:
				storm.start_shrink(8.0, 20.0)

func _spawn_root_hazards() -> void:
	var root_scene := load("res://scenes/maps/emerald_plains/boss/treant_root_hazard.tscn")
	if not root_scene:
		return
		
	for i in range(6):
		var angle: float = (float(i) / 6.0) * TAU
		var offset := Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
		var root: Node3D = root_scene.instantiate() as Node3D
		get_tree().current_scene.add_child(root)
		root.global_position = global_position + offset

func _on_boss_death() -> void:
	# Victory notification to HUD
	var hud := get_tree().current_scene.find_child("HUD", true, false)
	if hud and hud.has_method("show_victory"):
		hud.call("show_victory")
