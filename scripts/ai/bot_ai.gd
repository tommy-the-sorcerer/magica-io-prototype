class_name BotAI
extends CharacterBody3D

## Intelligent Simulated Mobile Opponent with realistic gamer tags, flags, and human quirks
enum State { MATCH_START, ROAM, CHASE_XP, ATTACK_TARGET, PANIC_FLEE, FLEE_STORM }

@export var move_speed: float = 5.5
@export var attack_range: float = 12.0
@export var attack_cooldown: float = 1.6

var current_state: State = State.MATCH_START
var gamer_tag: String = "Bot"
var country_flag: String = "🌐"
var display_name: String = ""

var current_target: Node3D = null
var can_attack: bool = true
var match_start_timer: float = 1.5

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

func _update_nameplate(current_hp: float, max_hp: float) -> void:
	if not nameplate:
		return
	var hp_pct: float = clampf(current_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var bar_length: int = 8
	var filled: int = int(hp_pct * bar_length)
	var bar_str: String = "█".repeat(filled) + "░".repeat(bar_length - filled)
	nameplate.text = "%s\n[%s]" % [display_name, bar_str]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

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

	move_and_slide()
	_animate_wobble(delta)

func _process_match_start(delta: float) -> void:
	match_start_timer -= delta
	# Simulate impatient mobile player fidgeting (small jitter spins)
	visuals.rotation.y += sin(match_start_timer * 15.0) * 0.1
	if match_start_timer <= 0:
		current_state = State.ROAM
		_pick_new_roam_target()

func _process_roam(_delta: float) -> void:
	_scan_for_targets()
	if nav_agent.is_navigation_finished():
		_pick_new_roam_target()
		return
		
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	
	if dir.length_squared() > 0.01:
		visuals.look_at(global_position + dir, Vector3.UP)

func _process_attack_target(_delta: float) -> void:
	if not is_instance_valid(current_target):
		current_state = State.ROAM
		current_target = null
		return
		
	var dist: float = global_position.distance_to(current_target.global_position)
	if dist > attack_range * 1.3:
		current_state = State.ROAM
		current_target = null
		return
		
	# Look at target with human-like slight aim variance
	var aim_dir: Vector3 = (current_target.global_position - global_position).normalized()
	aim_dir.y = 0
	if aim_dir.length_squared() > 0.01:
		visuals.look_at(global_position + aim_dir, Vector3.UP)
	
	# Stop moving while casting
	velocity.x = move_toward(velocity.x, 0, 15.0 * _delta)
	velocity.z = move_toward(velocity.z, 0, 15.0 * _delta)
	
	if can_attack:
		_cast_spell(aim_dir)

func _process_panic_flee(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		current_state = State.ROAM
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	velocity.x = dir.x * (move_speed * 1.25)
	velocity.z = dir.z * (move_speed * 1.25)
	if dir.length_squared() > 0.01:
		visuals.look_at(global_position + dir, Vector3.UP)

func _process_flee_storm(_delta: float) -> void:
	# Run towards center (0, 0, 0)
	nav_agent.target_position = Vector3.ZERO
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	dir.y = 0
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	if dir.length_squared() > 0.01:
		visuals.look_at(global_position + dir, Vector3.UP)

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

func _cast_spell(base_dir: Vector3) -> void:
	can_attack = false
	
	# Human inaccuracy (±8 degree aim offset)
	var angle_offset: float = deg_to_rad(randf_range(-8.0, 8.0))
	var aim_dir: Vector3 = base_dir.rotated(Vector3.UP, angle_offset)
	
	# Spawn fireball projectile if scene exists
	var fireball_scene := load("res://scenes/spells/fireball.tscn")
	if fireball_scene:
		var proj: Node3D = fireball_scene.instantiate() as Node3D
		proj.set("caster", self)
		get_tree().current_scene.add_child(proj)
		proj.global_position = cast_point.global_position if cast_point else global_position + aim_dir
		proj.look_at(proj.global_position + aim_dir, Vector3.UP)
	
	# Cooldown with slight randomness
	var cd: float = attack_cooldown + randf_range(-0.2, 0.3)
	await get_tree().create_timer(cd).timeout
	can_attack = true

func _animate_wobble(_delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.5:
		var wobble := sin(Time.get_ticks_msec() * 0.012) * 0.12
		visuals.rotation.z = wobble
	else:
		visuals.rotation.z = move_toward(visuals.rotation.z, 0, 5.0 * _delta)

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)

func _on_damaged(_amount: float, source: Node) -> void:
	# Panic flee if critically injured (< 30% HP)
	if health_component.current_health < health_component.max_health * 0.3:
		current_state = State.PANIC_FLEE
		if source and is_instance_valid(source) and (source is Node3D):
			var flee_dir: Vector3 = (global_position - (source as Node3D).global_position).normalized()
			nav_agent.target_position = global_position + flee_dir * 16.0
	elif current_state != State.ATTACK_TARGET and source and is_instance_valid(source) and (source is Node3D):
		# Retaliate
		current_target = source as Node3D
		current_state = State.ATTACK_TARGET

func _on_died(killer: Node) -> void:
	# Notify GameManager for Kill Feed
	var killer_name: String = "Storm"
	var is_player: bool = false
	if killer and is_instance_valid(killer):
		if killer.get("display_name"):
			killer_name = killer.get("display_name")
		elif killer.is_in_group("player"):
			killer_name = "👑 YOU"
			is_player = true
			
	var gm := get_tree().root.find_child("GameManager", true, false)
	if gm and gm.has_method("report_elimination"):
		gm.call("report_elimination", killer_name, display_name, is_player)
		
	# Death shrink animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
