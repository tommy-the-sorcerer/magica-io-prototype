class_name BotAI
extends CharacterBody3D

## Intelligent Simulated Mobile Opponent with realistic gamer tags, flags, and human quirks
enum State { MATCH_START, ROAM, CHASE_XP, ATTACK_TARGET, PANIC_FLEE, FLEE_STORM }

@export var move_speed: float = 7.5
@export var acceleration: float = 35.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 720.0
@export var attack_range: float = 12.0
@export var attack_cooldown: float = 1.6

var current_state: State = State.MATCH_START
var gamer_tag: String = "Bot"
var country_flag: String = "🌐"
var display_name: String = ""

var current_target: Node3D = null
var can_attack: bool = true
var match_start_timer: float = 1.5

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

# Pool of realistic gamer tags and country flags
const NAMES: Array[String] = [
	"ShadowNinja_99", "DragonSlayer", "ProGamer_BR", "SakuraMage", "CyberWizard",
	"Viper_007", "Alex_FR", "FrostByte", "Ghost_Rider", "AlphaWolf", "Kira_Death",
	"Speedy_01", "ThunderGod", "NoobSlayer", "Phoenix_X", "DarkSorcerer", "BlazeKing"
]

const FLAGS: Array[String] = [
	"🇺🇸", "🇮🇳", "🇧🇷", "🇩🇪", "🇯🇵", "🇬🇧", "🇫🇷", "🇰🇷", "🇨🇦", "🇦🇺", "🇪🇸", "🇲🇽"
]

const ROBE_COLORS: Array[Color] = [
	Color(0.85, 0.25, 0.25), # Red
	Color(0.25, 0.55, 0.85), # Blue
	Color(0.25, 0.75, 0.35), # Green
	Color(0.75, 0.35, 0.85), # Purple
	Color(0.95, 0.75, 0.15), # Gold
	Color(0.15, 0.85, 0.85)  # Cyan
]

var _original_robe_material: Material = null

func _ready() -> void:
	add_to_group("combatants")
	_generate_identity()
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		health_component.damaged.connect(_on_damaged)

func _generate_identity() -> void:
	gamer_tag = NAMES.pick_random()
	country_flag = FLAGS.pick_random()
	display_name = "%s %s" % [country_flag, gamer_tag]
	_update_nameplate(health_component.current_health, health_component.max_health)
	
	# Randomize robe color
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
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		if global_position.y < -22.0:
			if health_component and not health_component.is_dead:
				health_component.take_damage(99999, null)
			return

	# Slow debuff timer
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_modifier = 1.0
			_is_slowed = false
			_apply_frost_visual(false)
			if health_component:
				_update_nameplate(health_component.current_health, health_component.max_health)

	# Knockback impulse handling with fast decay friction
	if _knockback_velocity.length_squared() > 0.01:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 38.0 * delta)
		move_and_slide()
	
	# Stagger state locks decision making
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		_animate_wobble(delta)
		return

	match current_state:
		State.MATCH_START:
			_process_match_start(delta)
		State.ROAM:
			_process_roam(delta)
		State.ATTACK_TARGET:
			_process_attack_target(delta)
		State.PANIC_FLEE:
			_process_panic_flee(delta)
		State.FLEE_STORM:
			_process_flee_storm(delta)

	if _knockback_velocity.length_squared() <= 0.01:
		move_and_slide()
	_animate_wobble(delta)

func _process_match_start(delta: float) -> void:
	match_start_timer -= delta
	visuals.rotation.y += sin(match_start_timer * 15.0) * 0.1
	if match_start_timer <= 0:
		current_state = State.ROAM
		_pick_new_roam_target()

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

func _process_roam(delta: float) -> void:
	_scan_for_targets()
	if nav_agent.is_navigation_finished():
		_pick_new_roam_target()
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		return
		
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	var effective_speed: float = move_speed * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _process_attack_target(delta: float) -> void:
	if not is_instance_valid(current_target):
		current_state = State.ROAM
		current_target = null
		return
		
	var dist: float = global_position.distance_to(current_target.global_position)
	if dist > attack_range * 1.3:
		current_state = State.ROAM
		current_target = null
		return
		
	var aim_dir: Vector3 = (current_target.global_position - global_position).normalized()
	aim_dir.y = 0
	_rotate_visuals_toward(aim_dir, delta)
	
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	
	if can_attack:
		_cast_spell(aim_dir)

func _process_panic_flee(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		current_state = State.ROAM
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	var effective_speed: float = (move_speed * 1.25) * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _process_flee_storm(delta: float) -> void:
	nav_agent.target_position = Vector3.ZERO
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	var effective_speed: float = move_speed * _speed_modifier
	velocity.x = move_toward(velocity.x, dir.x * effective_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * effective_speed, acceleration * delta)
	_rotate_visuals_toward(dir, delta)

func _scan_for_targets() -> void:
	var combatants: Array[Node] = get_tree().get_nodes_in_group("combatants")
	var closest_dist: float = attack_range
	var best_target: Node3D = null
	
	for c in combatants:
		if c == self or not is_instance_valid(c) or not (c is Node3D):
			continue
		var dist: float = global_position.distance_to(c.global_position)
		if dist < closest_dist:
			closest_dist = dist
			best_target = c as Node3D
			
	if best_target:
		current_target = best_target
		current_state = State.ATTACK_TARGET

func _pick_new_roam_target() -> void:
	var random_offset := Vector3(randf_range(-18, 18), 0, randf_range(-18, 18))
	nav_agent.target_position = global_position + random_offset

## Follows Attack Release Standards: 0.20s release time after attack start
func _cast_spell(base_dir: Vector3) -> void:
	can_attack = false
	
	# Attack Release Standards: 0.20s Cast delay before releasing projectile
	await get_tree().create_timer(0.20).timeout
	if not is_instance_valid(self) or not health_component.is_alive():
		return
	
	var angle_offset: float = deg_to_rad(randf_range(-8.0, 8.0))
	var aim_dir: Vector3 = base_dir.rotated(Vector3.UP, angle_offset)
	
	# Alternate spells: Fireball, Ice Lance, or Heaven's Ascendant Solar projectile
	var spell_path: String = "res://scenes/spells/fireball.tscn"
	var roll: float = randf()
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
		proj.global_position = cast_point.global_position if cast_point else global_position + aim_dir
		proj.look_at(proj.global_position + aim_dir, Vector3.UP)
	
	# 0.18s recovery + cooldown
	var cd: float = maxf(attack_cooldown - 0.20, 0.18) + randf_range(-0.1, 0.2)
	await get_tree().create_timer(cd).timeout
	can_attack = true

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
	if health_component.current_health < health_component.max_health * 0.3:
		current_state = State.PANIC_FLEE
		if source and is_instance_valid(source) and (source is Node3D):
			var flee_dir: Vector3 = (global_position - (source as Node3D).global_position).normalized()
			nav_agent.target_position = global_position + flee_dir * 16.0
	elif current_state != State.ATTACK_TARGET and source and is_instance_valid(source) and (source is Node3D):
		current_target = source as Node3D
		current_state = State.ATTACK_TARGET

func _on_died(killer: Node) -> void:
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
