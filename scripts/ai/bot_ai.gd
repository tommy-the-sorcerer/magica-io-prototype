class_name BotAI
extends CharacterBody3D

## Intelligent Mobile Battle Royale Bot Opponent
## Features responsive AI State Machine: IDLE, SEARCHING, CHASING, COMBAT, ATTACKING, REPOSITIONING, DEAD
## Includes periodic target acquisition, distance management, combat strafing, lead-aim prediction, and spell attacks.

enum State { IDLE, SEARCHING, CHASING, COMBAT, ATTACKING, REPOSITIONING, DEAD, PANIC_FLEE, FLEE_STORM }

@export_group("AI Movement")
@export var move_speed: float = 7.5
@export var acceleration: float = 35.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 720.0

@export_group("AI Combat Tuning")
@export var minimum_attack_distance: float = 4.0
@export var preferred_attack_distance: float = 8.0
@export var maximum_attack_distance: float = 12.0
@export var attack_range: float = 12.0
@export var attack_cooldown: float = 1.6
@export var target_scan_interval: float = 0.25

var current_state: State = State.IDLE
var gamer_tag: String = "Bot"
var country_flag: String = "🌐"
var display_name: String = ""

var current_target: Node3D = null
var can_attack: bool = true
var match_start_timer: float = 1.2
var _scan_timer: float = 0.0

var _strafe_dir: float = 1.0
var _strafe_timer: float = 0.0
var _reposition_timer: float = 0.0
var _reposition_dir: Vector3 = Vector3.ZERO

var _speed_modifier: float = 1.0
var _slow_timer: float = 0.0
var _is_slowed: bool = false
var _stagger_timer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var nameplate: Label3D = $Nameplate3D
@onready var visuals: Node3D = $Visuals
@onready var cast_point: Marker3D = $Visuals/CastPoint

const NAMES: Array[String] = [
	"ShadowNinja_99", "DragonSlayer", "ProGamer_BR", "SakuraMage", "CyberWizard",
	"Viper_007", "Alex_FR", "FrostByte", "Ghost_Rider", "AlphaWolf", "Kira_Death",
	"Speedy_01", "ThunderGod", "NoobSlayer", "Phoenix_X", "DarkSorcerer", "BlazeKing"
]

const FLAGS: Array[String] = [
	"🇺🇸", "🇮🇳", "🇧🇷", "🇩🇪", "🇯🇵", "🇬🇧", "🇫🇷", "🇰🇷", "🇨🇦", "🇦🇺", "🇪🇸", "🇲🇽"
]

const ROBE_COLORS: Array[Color] = [
	Color(0.85, 0.25, 0.25),
	Color(0.25, 0.55, 0.85),
	Color(0.25, 0.75, 0.35),
	Color(0.75, 0.35, 0.85),
	Color(0.95, 0.75, 0.15),
	Color(0.15, 0.85, 0.85)
]

var _original_robe_material: Material = null

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("bots")
	_generate_identity()
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		health_component.damaged.connect(_on_damaged)
	
	# Random initial strafe direction
	_strafe_dir = 1.0 if randf() > 0.5 else -1.0
	_strafe_timer = randf_range(1.5, 3.0)

func _generate_identity() -> void:
	gamer_tag = NAMES.pick_random()
	country_flag = FLAGS.pick_random()
	display_name = "%s %s" % [country_flag, gamer_tag]
	_update_nameplate(health_component.current_health, health_component.max_health)
	
	var robe_mesh: MeshInstance3D = visuals.find_child("BodyMesh", true, false) as MeshInstance3D
	if robe_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ROBE_COLORS.pick_random()
		mat.roughness = 0.4
		robe_mesh.material_override = mat
		_original_robe_material = mat

func _update_nameplate(current_hp: float, max_hp: float) -> void:
	if not nameplate:
		return
	var hp_pct: float = clampf(current_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var bar_length: int = 8
	var filled: int = int(hp_pct * bar_length)
	var bar_str: String = "█".repeat(filled) + "░".repeat(bar_length - filled)
	var slow_icon: String = " ❄️" if _is_slowed else ""
	nameplate.text = "%s%s\n[%s]" % [display_name, slow_icon, bar_str]

func apply_slow(multiplier: float, duration: float) -> void:
	_speed_modifier = clampf(1.0 - multiplier, 0.2, 0.85)
	_slow_timer = duration
	_is_slowed = true
	_apply_frost_visual(true)
	if health_component:
		_update_nameplate(health_component.current_health, health_component.max_health)

func _apply_frost_visual(active: bool) -> void:
	if not visuals:
		return
	var mesh_instances: Array[Node] = visuals.find_children("*", "MeshInstance3D", true, false)
	for m in mesh_instances:
		if m is MeshInstance3D:
			if active:
				var frost_mat := StandardMaterial3D.new()
				frost_mat.albedo_color = Color(0.4, 0.88, 1.0, 0.9)
				frost_mat.roughness = 0.15
				frost_mat.emission_enabled = true
				frost_mat.emission = Color(0.25, 0.75, 1.0)
				frost_mat.emission_energy_multiplier = 0.5
				m.material_override = frost_mat
			else:
				if m.name == "BodyMesh" and _original_robe_material:
					m.material_override = _original_robe_material
				else:
					m.material_override = null

func apply_knockback(impulse: Vector3, stagger_duration: float = 0.2) -> void:
	_knockback_velocity = impulse
	_stagger_timer = stagger_duration
	can_attack = false
	get_tree().create_timer(stagger_duration).timeout.connect(func(): can_attack = true)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= 14.0 * delta
		if global_position.y < -22.0:
			if health_component and not health_component.is_dead:
				health_component.take_damage(99999, null)
			return
	else:
		velocity.y = 0.0

	# Debuffs and timers
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_modifier = 1.0
			_is_slowed = false
			_apply_frost_visual(false)
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)

	# Knockback impulse handling
	if _knockback_velocity.length_squared() > 0.01:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 38.0 * delta)
		move_and_slide()
		return
	
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		_animate_wobble(delta)
		return

	# Periodic target scan interval
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = target_scan_interval
		_scan_for_targets()

	# Execute State Machine
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.SEARCHING:
			_process_searching(delta)
		State.CHASING:
			_process_chasing(delta)
		State.COMBAT:
			_process_combat(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.REPOSITIONING:
			_process_repositioning(delta)
		State.PANIC_FLEE:
			_process_panic_flee(delta)
		State.FLEE_STORM:
			_process_flee_storm(delta)

	# Physical movement
	move_and_slide()

	# Arena Horizontal Boundary Clamp
	var horiz_pos := Vector2(global_position.x, global_position.z)
	const ARENA_RADIUS: float = 48.0
	if horiz_pos.length() > ARENA_RADIUS:
		var clamped := horiz_pos.normalized() * ARENA_RADIUS
		global_position.x = clamped.x
		global_position.z = clamped.y
		velocity.x = 0.0
		velocity.z = 0.0

	_animate_wobble(delta)

func _process_idle(delta: float) -> void:
	match_start_timer -= delta
	visuals.rotation.y += sin(match_start_timer * 15.0) * 0.1
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	if match_start_timer <= 0.0:
		current_state = State.SEARCHING
		_pick_new_roam_target()

func _process_searching(delta: float) -> void:
	if _is_target_valid(current_target):
		current_state = State.CHASING
		return

	if nav_agent.is_navigation_finished():
		_pick_new_roam_target()
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		return
		
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0.0
	var effective_speed: float = (move_speed * 0.85) * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _process_chasing(delta: float) -> void:
	if not _is_target_valid(current_target):
		current_target = null
		current_state = State.SEARCHING
		_pick_new_roam_target()
		return

	var to_target: Vector3 = current_target.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	# If reached combat distance, enter COMBAT
	if dist <= maximum_attack_distance:
		current_state = State.COMBAT
		return

	# Navigate actively towards enemy
	nav_agent.target_position = current_target.global_position
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0.0
	var effective_speed: float = move_speed * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _process_combat(delta: float) -> void:
	if not _is_target_valid(current_target):
		current_target = null
		current_state = State.SEARCHING
		_pick_new_roam_target()
		return

	var to_target: Vector3 = current_target.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	# Target moved out of range -> Chase
	if dist > maximum_attack_distance * 1.25:
		current_state = State.CHASING
		return

	# Always face target smoothly during combat
	var aim_dir: Vector3 = to_target.normalized()
	_rotate_visuals_toward(aim_dir, delta)

	# Alternate strafe timer
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_dir = -_strafe_dir
		_strafe_timer = randf_range(1.4, 2.8)

	# Compute combat strafe direction (perpendicular to target vector)
	var right_vec := Vector3(-aim_dir.z, 0.0, aim_dir.x) * _strafe_dir
	var combat_move_dir := right_vec

	# Maintain preferred attack distance
	if dist < minimum_attack_distance:
		# Too close: back up while strafing
		combat_move_dir = (combat_move_dir - aim_dir * 1.2).normalized()
	elif dist > preferred_attack_distance + 1.0:
		# Slightly too far: advance forward while strafing
		combat_move_dir = (combat_move_dir + aim_dir * 0.8).normalized()
	else:
		combat_move_dir = combat_move_dir.normalized()

	var effective_speed: float = (move_speed * 0.75) * _speed_modifier
	var target_vel := combat_move_dir * effective_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	# Ready to attack
	if can_attack:
		current_state = State.ATTACKING
		_execute_attack_sequence(aim_dir)

func _process_attacking(delta: float) -> void:
	if _is_target_valid(current_target):
		var aim_dir := (current_target.global_position - global_position).normalized()
		aim_dir.y = 0.0
		_rotate_visuals_toward(aim_dir, delta)
	
	# Decelerate smoothly during cast release
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

func _process_repositioning(delta: float) -> void:
	_reposition_timer -= delta
	if _reposition_timer <= 0.0 or not _is_target_valid(current_target):
		current_state = State.COMBAT
		return

	# Face the enemy even while repositioning laterally
	if _is_target_valid(current_target):
		var aim_dir := (current_target.global_position - global_position).normalized()
		aim_dir.y = 0.0
		_rotate_visuals_toward(aim_dir, delta)

	var effective_speed: float = (move_speed * 0.85) * _speed_modifier
	var target_vel := _reposition_dir * effective_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

func _execute_attack_sequence(base_dir: Vector3) -> void:
	can_attack = false

	# Attack Release Standards: 0.20s cast preparation
	await get_tree().create_timer(0.20).timeout
	if not is_instance_valid(self) or current_state == State.DEAD or not health_component.is_alive():
		return

	if _is_target_valid(current_target):
		# Predictive aiming using target velocity
		var target_vel := Vector3.ZERO
		if current_target is CharacterBody3D:
			target_vel = (current_target as CharacterBody3D).velocity
		var dist: float = global_position.distance_to(current_target.global_position)
		const PROJ_SPEED: float = 22.0
		var flight_time: float = clampf(dist / PROJ_SPEED, 0.05, 0.6)
		var predicted_pos: Vector3 = current_target.global_position + (target_vel * flight_time)
		var lead_dir: Vector3 = (predicted_pos - global_position).normalized()
		lead_dir.y = 0.0
		
		# Slight human inaccuracy jitter
		var angle_offset: float = deg_to_rad(randf_range(-4.0, 4.0))
		base_dir = lead_dir.rotated(Vector3.UP, angle_offset)

	_spawn_projectile(base_dir)

	# Enter brief repositioning state after attack
	var right_vec := Vector3(-base_dir.z, 0.0, base_dir.x)
	var strafe_side: float = 1.0 if randf() > 0.5 else -1.0
	_reposition_dir = (right_vec * strafe_side + base_dir * randf_range(-0.3, 0.2)).normalized()
	_reposition_timer = randf_range(0.6, 1.0)
	current_state = State.REPOSITIONING

	# Cooldown recovery timer
	var cd: float = maxf(attack_cooldown - 0.20, 0.25) + randf_range(-0.15, 0.25)
	await get_tree().create_timer(cd).timeout
	can_attack = true

func _spawn_projectile(aim_dir: Vector3) -> void:
	var roll: float = randf()
	var spell_path: String = "res://scenes/spells/fireball.tscn"
	if roll < 0.5:
		spell_path = "res://scenes/spells/fireball.tscn"
	elif roll < 0.8:
		spell_path = "res://scenes/spells/ice_lance.tscn"
	else:
		spell_path = "res://scenes/spells/celestial_beam.tscn"
	
	var spell_scene: PackedScene = load(spell_path)
	if spell_scene:
		var proj: Node3D = spell_scene.instantiate() as Node3D
		proj.set("caster", self)
		get_tree().current_scene.add_child(proj)
		var spawn_pos: Vector3 = cast_point.global_position if cast_point else global_position + Vector3(0, 0.8, 0) + aim_dir
		proj.global_position = spawn_pos
		proj.look_at(spawn_pos + aim_dir, Vector3.UP)

func _is_target_valid(t: Node3D) -> bool:
	if not t or not is_instance_valid(t):
		return false
	if t == self:
		return false
	var hp: HealthComponent = t.find_child("HealthComponent", true, false) as HealthComponent
	if hp and not hp.is_alive():
		return false
	return true

func _scan_for_targets() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	var closest_dist: float = 999.0
	var best_target: Node3D = null
	
	for c in combatants:
		if c == self or not is_instance_valid(c) or not (c is Node3D):
			continue
		var hp: HealthComponent = (c as Node).find_child("HealthComponent", true, false) as HealthComponent
		if hp and not hp.is_alive():
			continue
		var dist: float = global_position.distance_to((c as Node3D).global_position)
		if dist < closest_dist:
			closest_dist = dist
			best_target = c as Node3D
			
	if best_target:
		current_target = best_target
		if current_state == State.SEARCHING or current_state == State.IDLE:
			var d: float = global_position.distance_to(current_target.global_position)
			if d <= maximum_attack_distance:
				current_state = State.COMBAT
			else:
				current_state = State.CHASING

func _rotate_visuals_toward(dir: Vector3, delta: float) -> void:
	if dir.length_squared() <= 0.01:
		return
	var target_rot_y: float = atan2(-dir.x, -dir.z)
	var angle_diff: float = wrapf(target_rot_y - visuals.rotation.y, -PI, PI)
	var max_rot: float = deg_to_rad(rotation_speed) * delta
	if absf(angle_diff) <= max_rot:
		visuals.rotation.y = target_rot_y
	else:
		visuals.rotation.y += signf(angle_diff) * max_rot
	visuals.rotation.y = wrapf(visuals.rotation.y, -PI, PI)

func _pick_new_roam_target() -> void:
	var random_offset := Vector3(randf_range(-16, 16), 0, randf_range(-16, 16))
	nav_agent.target_position = global_position + random_offset

func _process_panic_flee(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		current_state = State.SEARCHING
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0.0
	var effective_speed: float = (move_speed * 1.2) * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _process_flee_storm(delta: float) -> void:
	nav_agent.target_position = Vector3.ZERO
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0.0
	var effective_speed: float = move_speed * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _animate_wobble(_delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.5:
		var wobble: float = sin(Time.get_ticks_msec() * 0.012) * 0.12
		visuals.rotation.z = wobble
	else:
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 5.0 * _delta)

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_damaged(_amount: float, source: Node) -> void:
	if health_component.current_health < health_component.max_health * 0.25:
		current_state = State.PANIC_FLEE
		if source and is_instance_valid(source) and (source is Node3D):
			var flee_dir: Vector3 = (global_position - (source as Node3D).global_position).normalized()
			nav_agent.target_position = global_position + flee_dir * 16.0
	elif not _is_target_valid(current_target) and source and is_instance_valid(source) and (source is Node3D):
		current_target = source as Node3D
		current_state = State.COMBAT

func _on_died(killer: Node) -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0

	var killer_name: String = "Storm"
	var is_player: bool = false
	if killer and is_instance_valid(killer):
		if killer.is_in_group("player") or killer.is_in_group("players") or killer.name == "Player":
			killer_name = "👑 YOU"
			is_player = true
		elif killer.get("display_name"):
			killer_name = killer.get("display_name")
			
	var hud_node: HUD = null
	if get_tree() and get_tree().current_scene:
		hud_node = get_tree().current_scene.find_child("HUD", true, false) as HUD
	if not hud_node and get_tree() and get_tree().root:
		hud_node = get_tree().root.find_child("HUD", true, false) as HUD

	if hud_node:
		hud_node.add_kill_feed(killer_name, display_name, is_player)
		if is_player:
			hud_node.add_kill()
		
	var gm: Node = get_tree().root.find_child("GameManager", true, false) if get_tree() and get_tree().root else null
	if gm and gm.has_method("report_elimination") and not hud_node:
		gm.call("report_elimination", killer_name, display_name, is_player)
		
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
